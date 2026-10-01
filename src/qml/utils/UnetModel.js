.pragma library

// U-Net model structure, derived from one entry of unet_models_info.jsonl.
//
// Shared by the in-app U-Net graph (SmlUnetGraph.qml) and the browser page
// (src/html/unet_visualizer.html, where Engine::write_unet_visualizer() inlines
// this file without the .pragma line), so it is plain ES5.
//
// The rule below was verified against the ONNX graphs of all 217 models (every
// Conv / ConvTranspose weight shape and the total parameter count match):
//
//   encoder level i (1..depth): 2 x [Conv k_i, ReLU], C*2^i channels, then MaxPool 2x2
//   bottleneck:                 2 x [Conv k_depth, ReLU], C*2^depth channels
//   decoder level i (depth..1): ConvTranspose 2x2 s2 (C*2^i -> C*2^i),
//                               Concat with encoder level i,
//                               2 x [Conv k_i, ReLU], C*2^(i-1) channels
//   output:                     Conv 1x1 -> 1 channel (no activation)
//
// where C = initial_channels and k = kernel_sizes. All convs use "same" padding.

// Original U-Net (Ronneberger et al., 2015, Fig. 1). Parameter count computed from the figure's layer sizes.
var ORIGINAL = {
    input: "572×572×1",
    output: "388×388×2",
    levels: 4,
    kernels: "3×3 everywhere",
    channels: "64 → 128 → 256 → 512",
    bottleneck: "1024 (doubled)",
    convLayers: 23,
    params: 31030658
};

function fmtCount(n) {
    if (n >= 1e9) return (n / 1e9).toFixed(2) + " G";
    if (n >= 1e6) return (n / 1e6).toFixed(n >= 1e8 ? 0 : 2) + " M";
    if (n >= 1e3) return (n / 1e3).toFixed(1) + " k";
    return String(n);
}

function fmtBytes(b) {
    if (b >= 1024 * 1024) return (b / 1024 / 1024).toFixed(1) + " MB";
    if (b >= 1024) return (b / 1024).toFixed(1) + " kB";
    return b + " B";
}

// Thousands separators. Not a regex: Qt 5.15's JS engine mishandles the usual lookahead one ("2,,320").
function fmtInt(n) {
    var str = String(Math.round(n)), out = "";
    for (var i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 === 0) out += ",";
        out += str.charAt(i);
    }
    return out;
}

function kx(k) {
    return k + "×" + k;
}

function shapeStr(c, s) {
    return c + " × " + s + " × " + s;
}

function modelName(info) {
    return String(info.model_file || "").replace(/\.onnx$/, "");
}

function isValid(info) {
    return !!info && typeof info.model_file === "string" && Array.isArray(info.kernel_sizes) &&
        info.kernel_sizes.length === info.depth + 1 && info.input_size > 0 && info.initial_channels > 0;
}

function extend(dst, src) {
    for (var key in src) dst[key] = src[key];
    return dst;
}

// Build the full layer list of one model from its metadata.
function buildModel(info) {
    var d = info.depth, C = info.initial_channels, S = info.input_size, K = info.kernel_sizes;
    var inC = info.input_channels;
    var ops = [];     // every ONNX-level operation, in order
    var maps = [];    // feature maps to draw
    var stage = "";
    var i, j, c;

    function conv(cin, cout, k, res, role) {
        var params = cout * cin * k * k + cout;
        var macs = cout * res * res * cin * k * k;
        ops.push({ stage: stage, op: "Conv " + kx(k) + (role === "output" ? "" : " + ReLU"), k: k, cin: cin, cout: cout, res: res, params: params, macs: macs });
        return { params: params, macs: macs };
    }

    // Input
    maps.push({ kind: "input", level: 0, ch: inC, res: S, title: "Input image", op: "RGB input tile" });

    // Encoder
    var cin = inC;
    for (i = 1; i <= d; i++) {
        stage = "Encoder level " + i;
        var eres = S >> (i - 1), ech = C << i, ek = K[i - 1];
        for (j = 0; j < 2; j++) {
            c = conv(j ? ech : cin, ech, ek, eres);
            maps.push(extend({ kind: "enc", level: i - 1, ch: ech, res: eres, k: ek, stage: stage, title: stage + ", conv " + (j + 1), op: "Conv " + kx(ek) + " + ReLU" }, c));
        }
        cin = ech;
        ops.push({ stage: stage, op: "MaxPool 2×2, stride 2", k: 2, cin: ech, cout: ech, res: eres >> 1, params: 0, macs: 0 });
    }

    // Bottleneck
    stage = "Bottleneck";
    var bres = S >> d, bch = C << d, bk = K[d];
    for (j = 0; j < 2; j++) {
        c = conv(bch, bch, bk, bres);
        maps.push(extend({ kind: "bottleneck", level: d, ch: bch, res: bres, k: bk, stage: stage, title: "Bottleneck, conv " + (j + 1), op: "Conv " + kx(bk) + " + ReLU" }, c));
    }

    // Decoder
    for (i = d; i >= 1; i--) {
        stage = "Decoder level " + i;
        var dres = S >> (i - 1), up = C << i, skip = C << i, out = C << (i - 1), dk = K[i - 1];
        var upParams = up * up * 4 + up, upMacs = up * up * 4 * (dres >> 1) * (dres >> 1);
        ops.push({ stage: stage, op: "ConvTranspose 2×2, stride 2", k: 2, cin: up, cout: up, res: dres, params: upParams, macs: upMacs });
        ops.push({ stage: stage, op: "Concat with encoder level " + i, k: 0, cin: up + skip, cout: up + skip, res: dres, params: 0, macs: 0 });
        maps.push({
            kind: "concat", level: i - 1, ch: up + skip, upCh: up, skipCh: skip, res: dres, stage: stage,
            title: stage + ", upsample + skip", op: "ConvTranspose 2×2 (" + up + " ch) + copy of encoder level " + i + " (" + skip + " ch)",
            params: upParams, macs: upMacs
        });
        for (j = 0; j < 2; j++) {
            c = conv(j ? out : up + skip, out, dk, dres);
            maps.push(extend({ kind: "dec", level: i - 1, ch: out, res: dres, k: dk, stage: stage, title: stage + ", conv " + (j + 1), op: "Conv " + kx(dk) + " + ReLU" }, c));
        }
    }

    // Output
    stage = "Output";
    c = conv(C, 1, 1, S, "output");
    maps.push(extend({ kind: "output", level: 0, ch: 1, res: S, stage: stage, title: "Output mask", op: "Conv 1×1, no activation (raw scores)" }, c));

    var params = 0, macs = 0, convCount = 0;
    for (i = 0; i < ops.length; i++) {
        params += ops[i].params;
        macs += ops[i].macs;
        if (ops[i].op.indexOf("Conv ") === 0) convCount++;
    }

    // Theoretical receptive field along the deepest path (input -> bottleneck -> output),
    // confirmed by measurement on the ONNX models.
    // Conv k: rf += (k-1)*jump. MaxPool 2/2: rf += jump, jump *= 2.
    // ConvTranspose 2/2 with stride == kernel maps each output pixel to one input pixel: jump /= 2.
    var rf = 1, jump = 1;
    for (i = 1; i <= d; i++) { rf += 2 * (K[i - 1] - 1) * jump; rf += jump; jump *= 2; }
    rf += 2 * (K[d] - 1) * jump;
    for (i = d; i >= 1; i--) { jump /= 2; rf += 2 * (K[i - 1] - 1) * jump; }

    // Largest single activation tensor (float32)
    var peak = 0;
    for (i = 0; i < maps.length; i++) peak = Math.max(peak, maps[i].ch * maps[i].res * maps[i].res * 4);

    // Compute share per stage
    var stages = [], byName = {};
    for (i = 0; i < ops.length; i++) {
        var s = byName[ops[i].stage];
        if (!s) { s = { name: ops[i].stage, macs: 0, params: 0 }; byName[s.name] = s; stages.push(s); }
        s.macs += ops[i].macs;
        s.params += ops[i].params;
    }

    var encCh = [];
    for (i = 1; i <= d; i++) encCh.push(C << i);

    return {
        info: info, name: modelName(info), ops: ops, maps: maps, params: params, macs: macs,
        convCount: convCount, rf: rf, peak: peak, stages: stages, encCh: encCh,
        paramsMatch: Math.abs(params / 1e6 - info.Mparams) < 1e-6
    };
}
