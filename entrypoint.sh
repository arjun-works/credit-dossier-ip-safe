#!/bin/bash
set -e

echo "========================================================="
echo "   Starting Credit Dossier All-in-One Container Stack    "
echo "========================================================="

# Clean shutdown handler for SIGINT/SIGTERM
cleanup() {
    echo "Shutting down child processes..."
    kill $(jobs -p) 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# ── 1. Start Local FastMCP Server (Internal: 127.0.0.1:8001) ──
echo "[1/4] Starting Local Credit Intelligence MCP on 127.0.0.1:8001..."
(cd /app/mcp && python server.py) &
sleep 2

# ── 2. Start FastAPI Backend (Internal: 127.0.0.1:8000) ────────
echo "[2/4] Starting FastAPI Backend on 127.0.0.1:8000..."
(cd /app/backend && python -m uvicorn app.main:app --host 127.0.0.1 --port 8000) &

# ── 3. Start Frontend SSR Server (Internal: 127.0.0.1:3000) ────
echo "[3/4] Starting TanStack Start Frontend on 127.0.0.1:3000..."
(cd /app/frontend && npm run preview -- --port 3000 --host 127.0.0.1) &

# ── 4. Start Caddy Gateway (Public: $PORT) ─────────────────────
echo "[4/4] Starting Caddy Edge Gateway on port ${PORT:-8080}..."
exec caddy run --config /app/Caddyfile --adapter caddyfile
