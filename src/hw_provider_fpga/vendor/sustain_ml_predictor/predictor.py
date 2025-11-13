import argparse
import os
import numpy as np
import networkx as nx
import json
import onnx
import onnxruntime
from collections import defaultdict

VISUALIZE_MODEL=False

def arch_encoding_unet(arch):

    input_channels = arch['input_channels'] # Is not used - the same for all models
    depth = arch['depth']
    initial_channels = arch['initial_channels']
    input_size = arch['input_size']
    kernel_sizes = arch['kernel_sizes']

    # Define possible values
    input_channel_options = [3] # Is not used - the same for all models
    depth_options = [1, 2, 3, 4]
    channels_options = [8, 16, 32, 64]
    input_size_options = [64, 128, 256, 512]

    # One-hot encodings
    depth_vec = [int(depth == d) for d in depth_options]
    channels_vec = [int(initial_channels == ch) for ch in channels_options]
    input_size_vec = [int(input_size == sz) for sz in input_size_options]

    # Kernel encoding (each of 5 slots encoded as 2-bit one-hot)
    # "kernel_sizes": [5, 5, 3, 3, 3] -> [01 01 10 10 10]
    kernel_encoding = []
    padded_kernels = kernel_sizes[:5] + [0] * (5 - len(kernel_sizes))
    for ks in padded_kernels:
        if ks == 3:
            kernel_encoding += [1, 0]
        elif ks == 5:
            kernel_encoding += [0, 1]
        else:
            kernel_encoding += [0, 0]  # padding

    return np.array(depth_vec + channels_vec + input_size_vec + kernel_encoding)

# FLOPs Estimation Functions
def flops_conv(input_shape, output_shape, kernel_shape, groups=1):
    N, Cin, Hin, Win = input_shape
    N, Cout, Hout, Wout = output_shape
    K_h, K_w = kernel_shape
    flops_per_instance = 2 * (Cin // groups) * K_h * K_w
    total_flops = N * Cout * Hout * Wout * flops_per_instance
    return total_flops

def flops_conv_transpose(input_shape, output_shape, kernel_shape, groups=1):
    return flops_conv(input_shape, output_shape, kernel_shape, groups)

def flops_relu(output_shape):
    return int(np.prod(output_shape))

def flops_maxpool(output_shape, kernel_shape):
    K_h, K_w = kernel_shape
    return int(np.prod(output_shape)) * (K_h * K_w - 1)

def flops_concat(input_shapes):
    return sum([int(np.prod(s)) for s in input_shapes])  # or return 0

# Utility: Get shape from ValueInfoProto
def get_shape(value_info):
    return [dim.dim_value for dim in value_info.type.tensor_type.shape.dim]

def extract_conv_metadata(node, initializer_map):
    """Extracts in_channels, out_channels, kernel_size from Conv node."""
    weight_name = node.input[1] if len(node.input) > 1 else None
    if weight_name and weight_name in initializer_map:
        weight_tensor = onnx.numpy_helper.to_array(initializer_map[weight_name])
        out_channels, in_channels, *kernel_size = weight_tensor.shape
    else:
        out_channels, in_channels, kernel_size = "?", "?", ["?"]
    return in_channels, out_channels, kernel_size

def count_params(node, initializer_map):
    params = 0
    for input_name in node.input:
        if input_name in initializer_map:
            tensor = initializer_map[input_name]
            shape = list(tensor.dims)  # Use .dims instead of .type.tensor_type.shape.dim
            params += int(np.prod(shape))
    params = params / 1e6
    return params

def count_flops(node, value_map, initializer_map):

    try:
        if node.op_type == "Conv":
            input_shape = value_map[node.input[0]]
            output_shape = value_map[node.output[0]]
            weight_name = node.input[1]
            weight_tensor = initializer_map[weight_name]
            weight_shape = list(weight_tensor.dims)  # [Cout, Cin, Kh, Kw]
            kernel_shape = weight_shape[2:]

            groups = 1
            for attr in node.attribute:
                if attr.name == "group":
                    groups = attr.i

            flops = flops_conv(input_shape, output_shape, kernel_shape, groups) / 2

        elif node.op_type == "ConvTranspose":
            input_shape = value_map[node.input[0]]
            output_shape = value_map[node.output[0]]
            weight_name = node.input[1]
            weight_tensor = initializer_map[weight_name]
            weight_shape = list(weight_tensor.dims)
            kernel_shape = weight_shape[2:]

            groups = 1
            for attr in node.attribute:
                if attr.name == "group":
                    groups = attr.i

            flops = flops_conv_transpose(input_shape, output_shape, kernel_shape, groups) / 2

        elif node.op_type == "Relu":
            output_shape = value_map[node.output[0]]
            flops = flops_relu(output_shape)

        elif node.op_type == "MaxPool":
            output_shape = value_map[node.output[0]]
            kernel_shape = [1, 1]
            for attr in node.attribute:
                if attr.name == "kernel_shape":
                    kernel_shape = list(attr.ints)
            flops = flops_maxpool(output_shape, kernel_shape)

        elif node.op_type == "Concat":
            input_shapes = [value_map[inp] for inp in node.input if inp in value_map]
            flops = flops_concat(input_shapes)

    except Exception as e:
        print(f"{node.op_type:<15} [Skipped] Error: {e}")

    flops = flops / 1e6
    return flops

def adj_matrix_node_features_from_onnx(onnx_model_path, visualize=False):
    """
    Loads an ONNX model and generates:
        - A directed graph adjacency matrix representing node connectivity.
        - Node-level features including operation type, FLOPs, and number of parameters.
        - List of unique operation types in the model.

    Args:
        onnx_model_path (str): Path to the ONNX model file.
        visualize (bool): If True, generate a PNG visualization of the model graph.

    Returns:
        adj_matrix (np.ndarray): Adjacency matrix of the graph (shape: [num_nodes, num_nodes]).
        node_features (list[dict]): Features for each node with 'op_type', 'flops', 'params'.
        op_types (list[str]): Sorted list of unique operation types in the model.
    """

    # Load the ONNX model from file
    onnx_model = onnx.load(onnx_model_path)
    # Check that the model is valid
    onnx.checker.check_model(onnx_model)

    # Access the main computation graph of the model
    graph = onnx_model.graph

    # Create a mapping from initializer name to tensor object.
    # Initializers are the fixed tensors in the model (weights, biases, etc.).
    initializer_map = {init.name: init for init in graph.initializer}

    # Build a mapping from tensor name to its shape
    value_map = {}
    # graph.value_info contains intermediate tensors metadata
    # graph.input contains model inputs
    # graph.output contains model outputs
    for vi in list(graph.value_info) + list(graph.input) + list(graph.output):
        value_map[vi.name] = get_shape(vi)

    # Create an empty directed graph to represent node connectivity
    nx_graph = nx.DiGraph()
    # Maps tensor outputs to the node index that produces them
    node_output_map = {}
    # List to store per-node features
    node_features = []

    # Add nodes to the graph and compute node-level features
    for i, node in enumerate(graph.node):
        # Create a unique node name using operation type and index
        node_name = f"{node.op_type}_{i}"

        if visualize:
            if node.op_type == "Conv":
                in_ch, out_ch, ksize = extract_conv_metadata(node, initializer_map)
                node_name = f"{node_name}\nin={in_ch}\nout={out_ch}\nk={ksize}"

        # Add node to NetworkX graph with a label
        nx_graph.add_node(i, label=node_name)

        # Record which node produces each output tensor
        for output in node.output:
            node_output_map[output] = i

        # Compute the number of trainable parameters and FLOPs for the node
        params = count_params(node, initializer_map)
        flops = count_flops(node, value_map, initializer_map)
        # Append features as a dictionary
        node_features.append({'op_type': node.op_type, 'flops': flops, 'params': params})

    # Add edges based on tensor flow: connect producer node to consumer node
    for i, node in enumerate(graph.node):
        for input_name in node.input:
            if input_name in node_output_map:
                src = node_output_map[input_name]  # producer node index
                dst = i  # current node index
                nx_graph.add_edge(src, dst)

    # Optional: visualize the model graph and save as PNG
    if visualize:
        from networkx.drawing.nx_pydot import to_pydot
        pydot_graph = to_pydot(nx_graph)
        pydot_graph.set_rankdir("TB")  # Top-to-bottom layout
        output_file_name = "unet_model.png"
        pydot_graph.write_png(output_file_name)

    # Create a mapping from node to index for adjacency matrix construction
    node_list = list(nx_graph.nodes())
    index_map = {node: idx for idx, node in enumerate(node_list)}
    N = len(node_list)

    # Initialize an empty adjacency matrix (NxN)
    adj_matrix = np.zeros((N, N), dtype=np.int8)

    # Fill the adjacency matrix based on edges in the graph
    for src, dst in nx_graph.edges():
        i = index_map[src]
        j = index_map[dst]
        adj_matrix[i][j] = 1  # 1 indicates a directed edge from i → j

    # Extract all unique operation types used in the model
    op_types = sorted({node.op_type for node in graph.node})

    return adj_matrix, node_features, op_types

def update_adj_matrix(input_adj_matrix, stats):

    # +1 due to the Global node
    N = stats["max_seq_len"] + 1

    # Create an empty adjacency matrix
    adj_matrix = np.zeros((N, N), dtype=np.int8)

    for i in range(N-1):
        for j in range(N-1):
            try:
                adj_matrix[i+1][j+1] = input_adj_matrix[i][j]
            except:
                pass

    # Add the Global node
    for j in range(N):
        adj_matrix[0][j] = 1.0

    # Add self-loops
    for i in range(N):
        adj_matrix[i][i] = 1.0

    return adj_matrix

def update_node_features(input_node_features, stats):

    node_features = []
    all_op_types = ['Global'] + stats["all_op_types"]

    def one_hot_encoded(op_type, all_op_types):
        dict_op_types = ['None']
        dict_op_types.extend(all_op_types)
        return [int(op_type == op) for op in dict_op_types]

    for node in input_node_features:
        temp = one_hot_encoded(node['op_type'], all_op_types)
        temp.append((np.log1p(node['flops']) - stats["mean_flops"]) / stats["std_flops"])
        temp.append((np.log1p(node['params']) - stats["mean_params"]) / stats["std_params"])
        node_features.append(temp)

    # Add Global node
    global_node = one_hot_encoded('Global', all_op_types)
    global_node.append(0.0)
    global_node.append(0.0)
    node_features = [global_node] + node_features

    # Padding
    while len(node_features) < (stats["max_seq_len"] + 1):
        temp = one_hot_encoded(None, all_op_types)
        temp.append(0)
        temp.append(0)
        node_features.append(temp)

    return np.array(node_features)

def extract_unet_info(onnx_model_path):
    model = onnx.load(onnx_model_path)
    graph = model.graph

    # Initialize info
    input_channels = None
    input_size = None
    initial_channels = None
    kernel_sizes_per_level = defaultdict(list)  # {level: [kernel1, kernel2,...]}

    # Extract input information
    if len(graph.input) > 0:
        input_tensor = graph.input[0]
        shape = [dim.dim_value for dim in input_tensor.type.tensor_type.shape.dim]
        # ONNX usually: [N, C, H, W]
        input_channels = shape[1]
        input_size = shape[2]  # assuming square input

    # Parse Conv and ConvTranspose nodes
    conv_nodes = [n for n in graph.node if n.op_type == "Conv"]
    convtranspose_nodes = [n for n in graph.node if n.op_type == "ConvTranspose"]

    # Estimate depth from ConvTranspose layers
    depth = len(convtranspose_nodes)  # one ConvTranspose per level

    # Group Conv layers per level
    # Approach: U-Net encoder typically has 2 Conv per level before downsampling
    level = 0
    convs_in_level = 2  # adjust if your U-Net has different structure
    for idx, node in enumerate(conv_nodes):
        # Extract kernel size
        for attr in node.attribute:
            if attr.name == "kernel_shape":
                kernel_sizes_per_level[level].append(list(attr.ints))

        # Extract initial_channels from first Conv
        if idx == 0:
            weight_name = node.input[1]
            weight_initializer = [init for init in graph.initializer if init.name == weight_name]
            if weight_initializer:
                weight_tensor = weight_initializer[0]
                # For Conv weights: [Cout, Cin, Kh, Kw]
                initial_channels = weight_tensor.dims[0]

        # Move to next level after `convs_in_level` Conv layers
        if (idx + 1) % convs_in_level == 0:
            level += 1

    # Convert defaultdict to regular dict
    kernel_sizes_per_level = dict(kernel_sizes_per_level)

    # Verify that all Conv layers in the same U-Net level have the same kernel size
    kernel_size_value_per_level = {}
    for level, kernels in kernel_sizes_per_level.items():
        # Convert each kernel list to tuple for easy comparison
        kernel_tuples = [tuple(k) for k in kernels]

        if len(set(kernel_tuples)) == 1:
            kernel_size_value_per_level[level] = kernel_tuples[0][0]
        else:
            raise Exception(f"Level {level}: Conv layers have different kernel sizes {kernel_tuples}")

    # Extract kernel values
    kernel_sizes = []
    for level in range(depth+1):
        kernel_sizes.append(kernel_size_value_per_level[level])

    # Compute flops and params
    initializer_map = {init.name: init for init in graph.initializer}
    value_map = {}
    for vi in list(graph.value_info) + list(graph.input) + list(graph.output):
        value_map[vi.name] = get_shape(vi)

    total_params, total_flops = 0, 0
    for i, node in enumerate(graph.node):
        total_params += count_params(node, initializer_map)
        total_flops += count_flops(node, value_map, initializer_map)

    return {
        "input_channels": input_channels,
        "input_size": input_size,
        "initial_channels": int(initial_channels / 2), # TODO: Fix search space generator
        "depth": depth,
        "kernel_sizes": kernel_sizes,
        "flops": total_flops,
        "params": total_params
    }

def predict(onnx_model_file, models_stats_file, prediction_model_file):

    predictor = onnxruntime.InferenceSession(prediction_model_file, providers=['CPUExecutionProvider'])

    with open(models_stats_file, "r") as f:
        stats = json.load(f)
    print(f"[DFKI predictor] using stats file: {os.path.abspath(models_stats_file)}  "
      f"(max_seq_len={stats.get('max_seq_len')}, exp_N_from_stats={stats.get('max_seq_len', -1)+1})")

    arch = extract_unet_info(onnx_model_file)
    arch_encoding = arch_encoding_unet(arch)

    adj_matrix, node_features, op_types = adj_matrix_node_features_from_onnx(onnx_model_file, visualize=VISUALIZE_MODEL)

    # Have to be updated considering the statistics of the complete design space (all topologies)
    # The adjacency matrix and the node features are used as an input to Graph Convolutional Networks (GCN)
    adj_matrix = update_adj_matrix(adj_matrix, stats)
    node_features = update_node_features(node_features, stats)

    adj_matrix = adj_matrix.astype(np.float32)
    node_features = node_features.astype(np.float32)
    arch_encoding = arch_encoding.astype(np.float32)

    # Add batch dimension
    adj_matrix = np.expand_dims(adj_matrix, axis=0)       # [1, N, N]
    node_features = np.expand_dims(node_features, axis=0) # [1, N, F]
    arch_encoding = np.expand_dims(arch_encoding, axis=0) # [1, D]

    # Build inputs and run
    data = [adj_matrix, node_features, arch_encoding]
    inputs = {inp.name: data[idx] for idx, inp in enumerate(predictor.get_inputs())} # Multiple inputs
    output_name = predictor.get_outputs()[0].name  # Single output
    pred = predictor.run([output_name], inputs)[0]

    return pred

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='PyTorch, Onnx and HiL (onnx, tflite, armnn) MNIST Example')
    parser.add_argument('--device', type=str, default="xczu19eg-ffvb1517-2-i", help='Path to a directory containing FPGA-dependant data')
    parser.add_argument('--model_file', type=str, help='Path to an onnx file containing U-Net models')
    parser.add_argument('--models_stats_file', type=str, default="unet_models_stats.json", help='Path to a file containing statistics of the U-Net models')
    parser.add_argument('--metric', type=str, help='Metric to be predicted')
    args = parser.parse_args()

    predictors = {
        "xczu19eg-ffvb1517-2-i": {
            "latency": "predictor_model_latency.onnx",
            "power": "predictor_model_power.onnx"
            }
    }
    prediction_model_file = os.path.join(args.device, predictors[args.device][args.metric])
    pred = predict(args.model_file, args.models_stats_file, prediction_model_file)

    print(f"Prediction of {args.metric} for {args.device}: {pred[0]}")
