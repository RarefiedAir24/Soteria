#!/bin/bash

# Stop Soteria Local Development Server

echo "🛑 Stopping Soteria Local Development Server..."

# Try to kill by PID file first
if [ -f local-dev-server/server.pid ]; then
    PID=$(cat local-dev-server/server.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "   Stopping process $PID..."
        kill $PID
        rm local-dev-server/server.pid
        echo "✅ Server stopped"
        exit 0
    fi
fi

# Fallback: kill by process name
if pkill -f "node server.js"; then
    echo "✅ Server stopped"
else
    echo "⚠️  No server process found"
fi

