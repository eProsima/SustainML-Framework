#!/usr/bin/env bash
set -euo pipefail

# ───────────────────────────────────────────────────────────────────
# Run all SustainML nodes + sustainml CLI, and kill after closing
# ───────────────────────────────────────────────────────────────────

BASE_DIR="$HOME/SustainML/SustainML_ws"

if [ ! -d "$BASE_DIR" ]; then
    echo "❌ ERROR: wasn't able to find the node's directory on: $BASE_DIR"
    exit 1
fi

echo "▶️  Starting Neo4j"
if command -v systemctl >/dev/null 2>&1; then
    # Entorno local
    sudo systemctl start neo4j
else
    # Docker u otro sin systemd
    neo4j start
fi


cd "$BASE_DIR"
cd "build/sustainml_modules/lib/sustainml_modules"

pids=()

start_node() {
    echo "▶️  Running: $*"
    "$@" &
    pids+=($!)
}

cleanup() {
    echo
    echo "🛑 Killing all processes..."
    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait >/dev/null 2>&1 || true
    echo "✅ All processes killed."

    echo "🛑 Stopping Neo4j"
    if command -v systemctl >/dev/null 2>&1; then
        # Entorno local con systemd
        sudo systemctl stop neo4j
    else
        # Docker u otro sin systemd
        neo4j stop
    fi
}
trap cleanup EXIT SIGINT SIGTERM

start_node python3 sustainml-wp1/app_requirements_node.py
start_node python3 sustainml-wp1/ml_model_metadata_node.py
start_node python3 sustainml-wp1/ml_model_provider_node.py
start_node python3 sustainml-wp2/hw_constraints_node.py
start_node python3 sustainml-wp2/hw_resources_provider_node.py
start_node python3 sustainml-wp3/carbon_footprint_node.py
start_node python3 sustainml-wp5/backend_node.py

echo "▶️  Running sustainml CLI"
sustainml
