#!/bin/bash
# Start Tijara API with Graphiti enabled

# Get OpenAI API key from config
OPENAI_KEY=$(python3 -c "import yaml; c=yaml.safe_load(open('config/config.yaml')); print(c['openai']['api_key'])")

# Export environment variable
export OPENAI_API_KEY="$OPENAI_KEY"

echo "🔑 OpenAI API key set from config"
echo "🛑 Stopping any existing API server..."
pkill -f "uvicorn api.main"
sleep 2

echo "🚀 Starting API server with Graphiti and ORM enabled..."
python3 -m uvicorn api.main:app --host 0.0.0.0 --port 8080 &

sleep 3

echo ""
echo "✅ API server started with Graphiti and ORM support"
echo "📊 Access UI at: http://localhost:8080"
echo "🔍 Health check: curl http://localhost:8080/health"
echo ""
echo "To load Demo data into Graphiti for semantic search, run:"
echo "  python3 populate_demo_graphiti.py"
