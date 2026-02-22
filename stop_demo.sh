#!/bin/bash

# LDC Knowledge Graph - Demo Teardown Script
# Opposite of run_demo.sh: stops API/UI process and clears demo graphs from FalkorDB.
# Usage: ./stop_demo.sh [--yes]

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo "======================================================================"
    echo -e "${BLUE}$1${NC}"
    echo "======================================================================"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

ASSUME_YES=false
if [[ "${1:-}" == "--yes" ]]; then
    ASSUME_YES=true
fi

pick_python() {
    if [[ -x "$PROJECT_DIR/.venv/bin/python" ]]; then
        echo "$PROJECT_DIR/.venv/bin/python"
        return 0
    fi
    if [[ -x "$PROJECT_DIR/config/.venv/bin/python" ]]; then
        echo "$PROJECT_DIR/config/.venv/bin/python"
        return 0
    fi
    echo "python3"
}

PYTHON_BIN="$(pick_python)"

# Read graph names from config/config.yaml if available; fall back to defaults.
read_graph_names() {
    local config_path="config/config.yaml"
    if [[ ! -f "$config_path" ]]; then
        echo "ldc_graph" "tijara_rbac" "graphiti"
        return 0
    fi

    local out
    out=$("$PYTHON_BIN" - <<'PY' "$config_path" 2>/dev/null || true
import sys
import yaml
from collections import OrderedDict

path = sys.argv[1]
with open(path, 'r') as f:
    cfg = yaml.safe_load(f) or {}

def get(dct, keys, default=None):
    cur = dct
    for k in keys:
        if not isinstance(cur, dict) or k not in cur:
            return default
        cur = cur[k]
    return cur

names = []
for keypath in (
    ("falkordb", "graph_name"),
    ("rbac", "graph_name"),
    ("graphiti", "falkordb_connection", "graph_name"),
):
    val = get(cfg, keypath)
    if isinstance(val, str) and val.strip():
        names.append(val.strip())

# De-dupe while preserving order
seen = set()
out = []
for n in names:
    if n not in seen:
        seen.add(n)
        out.append(n)

if not out:
    out = ["ldc_graph", "tijara_rbac", "graphiti"]

print(" ".join(out))
PY

)

    if [[ -n "$out" ]]; then
        echo "$out"
    else
        # If YAML parsing fails (e.g. PyYAML not installed), fall back to defaults.
        echo "ldc_graph" "tijara_rbac" "graphiti"
    fi
}

GRAPHS=()
read -r -a GRAPHS <<<"$(read_graph_names)"
if [[ ${#GRAPHS[@]} -eq 0 ]]; then
    GRAPHS=("ldc_graph" "tijara_rbac" "graphiti")
fi

print_header "Stop Demo + Clear Graphs"
print_info "Project: $PROJECT_DIR"
print_info "Graphs to delete: ${GRAPHS[*]}"

if [[ "$ASSUME_YES" == "false" ]]; then
    echo ""
    echo "This will:"
    echo "  1) Stop any API process listening on port 8080"
    echo "  2) Delete the FalkorDB graphs listed above (DATA LOSS)"
    echo ""
    read -r -p "Continue? (y/N) " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        print_info "Aborted."
        exit 0
    fi
fi

print_header "Step 1: Stopping API/UI processes"

# Kill by port (preferred)
if command -v lsof >/dev/null 2>&1 && lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    PIDS=$(lsof -ti:8080 || true)
    if [[ -n "$PIDS" ]]; then
        print_info "Stopping service on port 8080 (PIDs: $PIDS)..."
        # Try graceful then force
        kill $PIDS 2>/dev/null || true
        sleep 2
        kill -9 $PIDS 2>/dev/null || true
        print_success "Stopped processes on port 8080"
    fi
else
    print_info "No service listening on port 8080"
fi

# Extra safety: kill uvicorn api.main processes even if not bound to 8080 anymore
if command -v pkill >/dev/null 2>&1; then
    pkill -f "uvicorn api.main" >/dev/null 2>&1 || true
fi

print_header "Step 2: Clearing FalkorDB graphs"

if ! command -v redis-cli >/dev/null 2>&1; then
    print_error "redis-cli not found; can’t clear graphs automatically"
    print_info "Install Redis CLI (or run inside your FalkorDB container) and re-run this script."
    exit 1
fi

if ! redis-cli ping >/dev/null 2>&1; then
    print_error "FalkorDB/Redis is not running; can’t clear graphs"
    print_info "Start FalkorDB (e.g. docker run -p 6379:6379 -it --rm falkordb/falkordb) and re-run."
    exit 1
fi

for g in "${GRAPHS[@]}"; do
    if [[ -z "$g" ]]; then
        continue
    fi

    print_info "Deleting graph key: $g"
    # DEL works for any Redis key type (including FalkorDB graph keys).
    DEL_OUT=$(redis-cli DEL "$g" 2>/dev/null || true)
    if [[ "$DEL_OUT" =~ ^[0-9]+$ ]] && [[ "$DEL_OUT" -gt 0 ]]; then
        print_success "Deleted '$g'"
    else
        print_info "Graph '$g' not found (or already empty)"
    fi
done

print_header "Step 3: Cleaning local artifacts"

if [[ -f "api.log" ]]; then
    rm -f api.log
    print_success "Removed api.log"
fi

if [[ -f "server.pid" ]]; then
    rm -f server.pid
    print_success "Removed server.pid"
fi

print_success "Demo teardown complete"
