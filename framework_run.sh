#!/usr/bin/env bash
set -euo pipefail

# ───────────────────────────────────────────────────────────────────
# Run all SustainML nodes + sustainml CLI, y detiene todo al salir
# ───────────────────────────────────────────────────────────────────

# Ruta donde están tus nodos Python compilados
BASE_DIR="$HOME/SustainML/SustainML_ws"

# Comprueba que existe
if [ ! -d "$BASE_DIR" ]; then
  echo "❌ ERROR: no encontré el directorio de nodos en: $BASE_DIR"
  exit 1
fi

cd "$BASE_DIR"

cd "build/sustainml_modules/lib/sustainml_modules"

# Array para guardar PIDs
pids=()

# Función para lanzar en background y guardar PID
start_node() {
  echo "▶️  Iniciando: $*"
  "$@" &
  pids+=($!)
}

# Función de limpieza
cleanup() {
  echo
  echo "🛑 Deteniendo todos los procesos..."
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait >/dev/null 2>&1 || true
  echo "✅ Procesos detenidos. Saliendo."
}
trap cleanup EXIT SIGINT SIGTERM

# ─────────────────────────────────────────────────
# 1) Lanza cada nodo Python
# ─────────────────────────────────────────────────
start_node python3 sustainml-wp1/app_requirements_node.py
start_node python3 sustainml-wp1/ml_model_metadata_node.py
start_node python3 sustainml-wp1/ml_model_provider_node.py
start_node python3 sustainml-wp2/hw_constraints_node.py
start_node python3 sustainml-wp2/hw_resources_provider_node.py
start_node python3 sustainml-wp3/carbon_footprint_node.py
start_node python3 sustainml-wp5/backend_node.py

# ─────────────────────────────────────────────────
# 2) Finalmente, ejecuta el binario principal en primer plano
#    Cuando éste termine (o se reciba SIGINT/SIGTERM) se invoca cleanup()
# ─────────────────────────────────────────────────
echo "▶️  Lanzando sustainml CLI"
sustainml
