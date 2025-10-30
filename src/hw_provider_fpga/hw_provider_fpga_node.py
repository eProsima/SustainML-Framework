import os, sys, json, threading, time, signal

HERE = os.path.dirname(__file__)
sys.path.insert(0, os.path.abspath(os.path.join(HERE, "..")))  # framework/src
sys.path.insert(0, os.path.expanduser("~/SustainML/SustainML_ws/src/sustainml_lib"))  # library

try:
    from sustainml_py.sustainml_py.nodes.HardwareResourcesNode import HardwareResourcesNode
    _USING_DUMMY = False
except Exception as e:
    print(f"⚠️  sustainml_swig not available ({e}); using dummy HardwareResourcesNode for testing.")
    _USING_DUMMY = True

    class HardwareResourcesNode:
        """Minimal stub to mimic SustainML HardwareResourcesNode when native bindings are absent."""
        def __init__(self, callback=None, service_callback=None):
            self.callback = callback
            self.service_callback = service_callback

        def spin(self):
            print("⚙️  Dummy HardwareResourcesNode started (no native bindings).")

            #  Auto-discover a test ONNX model to use
            class DummyModel:
                def model_path(self):
                    # Check vendored path first
                    vendored = os.path.join(HERE, "vendor", "sustain_ml_predictor", "unet_models")
                    if os.path.isdir(vendored):
                        for f in os.listdir(vendored):
                            if f.endswith(".onnx"):
                                p = os.path.join(vendored, f)
                                print(f"[DummyModel] Using ONNX: {p}")
                                return p

                    # Fallback to user’s cloned repo
                    external = os.path.expanduser("~/Hardware_Exploration_Framework/sustain_ml_predictor/unet_models")
                    if os.path.isdir(external):
                        for f in os.listdir(external):
                            if f.endswith(".onnx"):
                                p = os.path.join(external, f)
                                print(f"[DummyModel] Using ONNX: {p}")
                                return p

                    raise FileNotFoundError(
                        "No .onnx model found in either:\n"
                        f" - {vendored}\n"
                        f" - {external}\n"
                        "Copy any .onnx file into one of these folders and rerun."
                    )

            class DummyStatus:
                def status(self, msg): print(f"[NodeStatus] {msg}")
                def progress(self, val): print(f"[Progress] {val*100:.0f}%")

            class DummyHW:
                def name(self, *a, **kw): pass
                def type(self, *a, **kw): pass
                def vendor(self, *a, **kw): pass
                def device(self, *a, **kw): pass
                def latency_ms(self, *a, **kw): pass
                def power_w(self, *a, **kw): pass
                def energy_j(self, *a, **kw): pass
                def extra_data(self, *a, **kw): print("[HW] extra_data set")

            try:
                self.callback(DummyModel(), None, None, DummyStatus(), DummyHW())
            except Exception as e:
                print(f"❌ Callback raised error: {e}")

        @staticmethod
        def terminate():
            print("Dummy HardwareResourcesNode terminated.")

#  Import FPGA predictor adapter
from hw_provider_fpga.fpga_predictor_adapter import predict_latency_power

_running = False


#  Node callback logic
def task_callback(ml_model, app_requirements, hw_constraints, node_status, hw):
    try:
        node_status.status("FPGA predictor: starting")
        node_status.progress(0.1)

        onnx_path = ml_model.model_path()
        if isinstance(onnx_path, (bytes, bytearray)):
            onnx_path = onnx_path.decode("utf-8")

        if not os.path.isfile(onnx_path):
            raise FileNotFoundError(f"ONNX model not found: {onnx_path}")

        pred = predict_latency_power(onnx_path)

        # DEBUG MARKER: proves the FPGA node ran and with which model/output
        try:
            out = {
                "onnx_model": onnx_path,
                "prediction": pred,
                "ts": time.time(),
            }
            os.makedirs("/tmp/sustainml", exist_ok=True)
            with open("/tmp/sustainml/fpga_predict_calls.jsonl", "a") as f:
                f.write(json.dumps(out) + "\n")
            print("[FPGA] wrote DEBUG marker to /tmp/sustainml/fpga_predict_calls.jsonl")
        except Exception:
            pass

        hw.name("FPGA")
        hw.type("FPGA")
        if hasattr(hw, "vendor"): hw.vendor("AMD/Xilinx")
        if hasattr(hw, "device"): hw.device(pred["device"])
        if hasattr(hw, "latency_ms"): hw.latency_ms(pred["latency_ms"])
        if hasattr(hw, "power_w"): hw.power_w(pred["power_w"])
        if hasattr(hw, "energy_j"): hw.energy_j(pred["energy_j"])
        hw.extra_data(json.dumps(pred).encode("utf-8"))

        node_status.progress(1.0)
        node_status.status("OK")

    except Exception as e:
        node_status.progress(1.0)
        node_status.status(f"Error: {e}")
        hw.name("Error")
        hw.type("Error")
        hw.extra_data(json.dumps({"error": str(e)}).encode("utf-8"))


def configuration_callback(req, res):
    res.node_id(req.node_id())
    res.transaction_id(req.transaction_id())
    res.success(True)
    res.err_code(0)
    res.configuration(json.dumps({"mode": "predictor"}))


#  Node runner
def run():
    node = HardwareResourcesNode(callback=task_callback, service_callback=configuration_callback)
    global _running
    _running = True
    node.spin()


def _sig_handler(sig, frame):
    if not _USING_DUMMY:
        from sustainml_py.sustainml_py.nodes.HardwareResourcesNode import HardwareResourcesNode as HRN
        HRN.terminate()
    global _running
    _running = False


if __name__ == "__main__":
    signal.signal(signal.SIGINT, _sig_handler)
    t = threading.Thread(target=run)
    t.start()
    while _running:
        time.sleep(0.2)
    t.join()
