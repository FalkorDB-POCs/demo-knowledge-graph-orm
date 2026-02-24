#!/bin/bash

# Knowledge Graph - Complete Demo Setup Script
# This script loads all data (Production, RBAC, Graphiti) and starts the API/UI
# Usage: ./run_demo.sh [--skip-data]

set -e  # Exit on any error

# Set the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo ""
    echo "======================================================================"
    echo -e "${BLUE}$1${NC}"
    echo "======================================================================"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Parse command line arguments
SKIP_DATA=false
if [[ "$1" == "--skip-data" ]]; then
    SKIP_DATA=true
fi

print_header "Knowledge Graph Demo Setup"

# Step 1: Check Prerequisites
print_header "Step 1: Checking Prerequisites"

# Check Python
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
print_success "Found $PYTHON_VERSION"

# Check FalkorDB/Redis
print_info "Checking FalkorDB/Redis..."
if ! redis-cli ping > /dev/null 2>&1; then
    print_error "FalkorDB/Redis is not running!"
    echo ""
    print_info "Please start FalkorDB first:"
    echo "  docker run -p 6379:6379 -it --rm falkordb/falkordb"
    echo "  OR"
    echo "  redis-server --loadmodule /path/to/falkordb.so"
    exit 1
fi
print_success "FalkorDB/Redis is running"

# Check OpenAI API key
if [ -z "$OPENAI_API_KEY" ]; then
    print_warning "OPENAI_API_KEY not set in environment"
    print_info "Checking config/config.yaml..."
    
    if [ -f "config/config.yaml" ]; then
        if grep -q "api_key:" config/config.yaml && ! grep -q "api_key: null" config/config.yaml; then
            print_success "OpenAI API key found in config/config.yaml"
        else
            print_warning "OpenAI API key not configured"
            print_info "Graphiti semantic search will be disabled"
            print_info "To enable, set OPENAI_API_KEY environment variable or edit config/config.yaml"
        fi
    else
        print_warning "config/config.yaml not found"
        print_info "Creating from example..."
        if [ -f "config/config.example.yaml" ]; then
            cp config/config.example.yaml config/config.yaml
            print_info "Please edit config/config.yaml to add your OpenAI API key"
        fi
    fi
else
    print_success "OpenAI API key found in environment"
fi

# Check if Python dependencies are installed
print_info "Checking Python dependencies..."
if ! python3 -c "import falkordb" 2>/dev/null; then
    print_warning "FalkorDB Python package not found"
    print_info "Installing dependencies from requirements.txt..."
    pip3 install -r requirements.txt
    print_success "Dependencies installed"
else
    print_success "Python dependencies are installed"
fi

# Step 2: Stop existing services
print_header "Step 2: Stopping Existing Services"

if lsof -Pi :8080 -sTCP:LISTEN -t > /dev/null 2>&1; then
    print_info "Stopping service on port 8080..."
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    sleep 2
    print_success "Existing service stopped"
else
    print_info "No existing service on port 8080"
fi

# Step 3: Load Data (unless --skip-data flag is set)
if [ "$SKIP_DATA" = false ]; then
    print_header "Step 3: Loading Data"
    
# Load Production structured data
    print_info "Loading Production structured data (3,444 nodes, 14,714 relationships)..."
    if python3 populate_demo_data.py; then
        print_success "Production data loaded successfully"
    else
        print_error "Failed to load Production data"
        exit 1
    fi
    
    # Load RBAC data
    print_info "Loading RBAC users, roles, and permissions..."
    if python3 scripts/init_rbac.py; then
        print_success "RBAC data loaded successfully"
    else
        print_error "Failed to load RBAC data"
        exit 1
    fi
    
    # Setup restricted user (emma_restricted)
    print_info "Setting up restricted user demo (emma_restricted)..."
    if python3 scripts/setup_emma_restricted.py; then
        print_success "Restricted user configured"
    else
        print_warning "Failed to setup restricted user (non-critical)"
    fi
    
    # Load Graphiti episodes
    print_info "Loading Graphiti semantic embeddings..."
    if python3 scripts/demo/load_demo_graphiti.py; then
        print_success "Graphiti data loaded successfully"
    else
        print_warning "Failed to load Graphiti data (may be due to missing OpenAI key)"
        print_info "Natural language queries will work with reduced semantic capabilities"
    fi
    
else
    print_header "Step 3: Skipping Data Load (--skip-data flag set)"
    print_info "Using existing data in FalkorDB"
fi

# Step 4: Start API Server
print_header "Step 4: Starting API Server"

# Set Python path
export PYTHONPATH="$PROJECT_DIR"

print_info "Starting Knowledge Graph API server..."
   print_info "  - API URL: http://localhost:8080"
   print_info "  - Web UI: http://localhost:8080"
   print_info "  - Graph: production_graph (FalkorDB)"
   print_info "  - RBAC: rbac_graph (FalkorDB)"
print_info "  - Graphiti: graphiti (FalkorDB + OpenAI)"

# Start server in background
nohup python3 -m uvicorn api.main:app --host 0.0.0.0 --port 8080 > api.log 2>&1 &
PID=$!

print_info "Server starting with PID: $PID"
print_info "Logs: $PROJECT_DIR/api.log"

# Wait for server to start
print_info "Waiting for server to start..."
sleep 5

# Check if server is running
if ps -p $PID > /dev/null 2>&1; then
    # Verify with health check
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        print_success "Server started successfully!"
    else
        print_warning "Server process is running but health check failed"
        print_info "Check logs: tail -f $PROJECT_DIR/api.log"
    fi
else
    print_error "Server failed to start"
    print_info "Check logs: tail -50 $PROJECT_DIR/api.log"
    exit 1
fi

# Step 5: Summary
print_header "🎉 Knowledge Graph Demo is Ready!"

echo ""
echo "Access the system:"
echo "  🌐 Web UI:      http://localhost:8080"
echo "  📊 API Docs:    http://localhost:8080/docs"
echo "  ❤️  Health:      http://localhost:8080/health"
echo ""

if [ "$SKIP_DATA" = false ]; then
    echo "Demo users (login at http://localhost:8080/login.html):"
    echo "  👤 admin / admin123          - Full access (superuser)"
    echo "  👤 emma_restricted / emma123 - Restricted access (no France/Cotton)"
    echo "  👤 alice_analyst / password  - Analyst role"
    echo "  👤 bob_trader / password     - Trader role"
    echo ""
fi

echo "Quick actions:"
echo "  📈 View stats:     curl http://localhost:8080/stats"
echo "  🔍 Test query:     curl -X POST http://localhost:8080/auth/login -F username=admin -F password=admin123"
echo "  📋 View logs:      tail -f api.log"
echo "  🛑 Stop server:    lsof -ti:8080 | xargs kill -9"
echo ""

echo "Tab features in Web UI:"
echo "  1. 🤖 Trading Copilot    - Ask questions in natural language"
echo "  2. 📊 Data Analytics     - Run graph algorithms and Cypher queries"
echo "  3. 📤 Data Ingestion     - Upload new data"
echo "  4. 🌍 Impact Analysis    - Analyze geographic impacts"
echo "  5. 🔍 Data Discovery     - Explore the graph"
echo "  6. 🗺️  Schema Explorer    - View graph schema"
echo "  7. 📈 Statistics         - Graph metrics"
echo ""

print_success "Demo setup complete!"
print_info "Press Ctrl+C to stop the server or run: lsof -ti:8080 | xargs kill -9"

echo ""
echo "======================================================================"
