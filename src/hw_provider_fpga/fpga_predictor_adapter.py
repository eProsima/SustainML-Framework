import os, json, hashlib
import numpy as np
from .vendor.sustain_ml_predictor.predictor import predict  # vendored DFKI code

HERE = os.path.dirname(__file__)
PREDICTOR_HOME = os.path.join(HERE, "vendor", "sustain_ml_predictor")
DEFAULT_DEVICE = "xczu19eg-ffvb1517-2-i"
DEFAULT_STATS  = os.path.join(PREDICTOR_HOME, "unet_models_stats.json")
DEFAULT_DEVICE_DIR = os.path.join(PREDICTOR_HOME, DEFAULT_DEVICE)

def _hash_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    return h.hexdigest()

def predict_latency_power(onnx_model_path: str,
                          device: str = DEFAULT_DEVICE,
                          stats_file: str = DEFAULT_STATS) -> dict:
    if not os.path.isfile(onnx_model_path):
        raise FileNotFoundError(f"ONNX model not found: {onnx_model_path}")

    device_dir = DEFAULT_DEVICE_DIR if device == DEFAULT_DEVICE else os.path.join(PREDICTOR_HOME, device)
    lat_path = os.path.join(device_dir, "predictor_model_latency.onnx")
    pow_path = os.path.join(device_dir, "predictor_model_power.onnx")

    for p in (stats_file, lat_path, pow_path):
        if not os.path.isfile(p):
            raise FileNotFoundError(f"Missing predictor asset: {p}")

    model_hash = _hash_file(onnx_model_path)

    lat_pred = predict(onnx_model_file=onnx_model_path,
                       models_stats_file=stats_file,
                       prediction_model_file=lat_path)
    pow_pred = predict(onnx_model_file=onnx_model_path,
                       models_stats_file=stats_file,
                       prediction_model_file=pow_path)

    lat_ms = float(np.array(lat_pred).reshape(-1)[0])
    pow_w  = float(np.array(pow_pred).reshape(-1)[0])

    return {
        "device": device,
        "latency_ms": lat_ms,
        "power_w": pow_w,
        "energy_j": (lat_ms / 1000.0) * pow_w,
        "provenance": {
            "stats_file": os.path.relpath(stats_file, HERE),
            "predictors": ["latency", "power"],
            "model_sha256": model_hash,
            "assets_dir": os.path.relpath(device_dir, HERE),
        }
    }

