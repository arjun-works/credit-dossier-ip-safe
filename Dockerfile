# ── Stage 1: Build Frontend (TanStack Start / React) ─────────────
FROM node:22-bookworm-slim AS frontend-builder
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm install

COPY frontend/ ./
RUN npm run build

# ── Stage 2: Final All-in-One Container ──────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Install system libraries, Node.js 22 runtime, and cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libpq-dev \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copy official Caddy static binary directly
COPY --from=caddy:2-alpine /usr/bin/caddy /usr/bin/caddy

# Install combined Python dependencies for both backend and mcp
COPY backend/requirements.txt /tmp/backend-reqs.txt
COPY mcp/requirements.txt /tmp/mcp-reqs.txt
RUN pip install --no-cache-dir -r /tmp/backend-reqs.txt -r /tmp/mcp-reqs.txt

# Copy source trees
COPY backend/ ./backend
COPY mcp/ ./mcp
COPY --from=frontend-builder /app/frontend ./frontend
COPY Caddyfile ./
COPY entrypoint.sh ./

RUN chmod +x /app/entrypoint.sh

# Default environment settings inside container
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV MCP_SSE_URL=http://127.0.0.1:8001/sse
ENV MCP_HOST=127.0.0.1
ENV MCP_PORT=8001
ENV PORT=8080
EXPOSE 8080

CMD ["/app/entrypoint.sh"]

