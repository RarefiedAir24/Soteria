#!/bin/bash

# Start Soteria Local Development Server
# This script starts the local Plaid development server

cd "$(dirname "$0")/local-dev-server"

echo "🚀 Starting Soteria Local Development Server..."
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "   Please copy .env.example to .env and add your Plaid credentials"
    exit 1
fi

# Check if node_modules exists
if [ ! -d node_modules ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if port 8000 is in use
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 8000 is already in use"
    echo "   Server may already be running"
    echo "   To stop: pkill -f 'node server.js'"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ Starting server on http://localhost:8000"
echo ""
echo "📡 Available endpoints:"
echo "   POST /soteria/plaid/create-link-token"
echo "   POST /soteria/plaid/exchange-public-token"
echo "   POST /soteria/plaid/get-accounts"
echo "   POST /soteria/plaid/get-balance"
echo "   POST /soteria/plaid/transfer"
echo "   GET  /health"
echo ""
echo "💡 To stop the server: Press Ctrl+C"
echo "════════════════════════════════════════"
echo ""

# Start server
node server.js

