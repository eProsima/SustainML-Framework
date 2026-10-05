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

# Polls 127.0.0.1:$1 until something accepts a connection, up to 60s.
wait_for_port() {
    local port="$1" description="$2"
    echo "⏳ Waiting for $description to accept connections on port $port..."
    for i in $(seq 1 60); do
        if (exec 3<>/dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
            exec 3>&- 3<&-
            echo "✅ $description is ready (after ${i}s)"
            return 0
        fi
        sleep 1
    done
    echo "❌ ERROR: $description did not become ready within 60s"
    exit 1
}

echo "▶️  Starting Neo4j"
if command -v systemctl >/dev/null 2>&1; then
    # Entorno local
    sudo systemctl start neo4j
else
    # Docker u otro sin systemd
    neo4j start
fi

wait_for_port 7687 "Neo4j"

cd "$BASE_DIR"
cd "build/sustainml_modules/lib/sustainml_modules"

pids=()

# Hide only the "pynvml package is deprecated" FutureWarning: carbontracker (and torch)
# import the old pynvml name, whose v13 package is just a wrapper over the already
# installed nvidia-ml-py that warns on every import. Other warnings are still shown.
export PYTHONWARNINGS="${PYTHONWARNINGS:+$PYTHONWARNINGS,}ignore:The pynvml package is deprecated:FutureWarning"

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

# Start backend_node first: it hosts the orchestrator that listens for every
# other node's status over DDS, and serves the GUI's REST API. If it starts
# after the other nodes, a node that reaches IDLE before backend_node's
# listener has discovered it will have that status broadcast missed
# permanently (nothing re-sends it), which silently blocks the GUI's
# "all nodes ready" check and every dropdown that depends on it.
start_node python3 sustainml-wp5/backend_node.py

wait_for_port 5001 "Backend node"

start_node python3 sustainml-wp1/app_requirements_node.py
start_node python3 sustainml-wp1/ml_model_metadata_node.py
start_node python3 sustainml-wp1/ml_model_provider_node.py
start_node python3 sustainml-wp2/hw_constraints_node.py
start_node python3 sustainml-wp2/hw_resources_provider_node.py
start_node python3 sustainml-wp3/carbon_footprint_node.py

echo "▶️  Running sustainml CLI"
sustainml
