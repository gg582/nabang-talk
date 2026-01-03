#!/usr/bin/env bash
set -euo pipefail

APP_DIR=${APP_DIR:-/opt/nabangtalk}
TCP_ADDR=${TCP_ADDR:-127.0.0.1:34567}
WS_ADDR=${WS_ADDR:-0.0.0.0:5174}
WEB_PORT=${WEB_PORT:-5173}

cd "$APP_DIR"

node scripts/ws-proxy.js --tcp "$TCP_ADDR" --ws "$WS_ADDR" &
PROXY_PID=$!

cleanup() {
  kill "$PROXY_PID" 2>/dev/null || true
}
trap cleanup EXIT

exec npm run preview -- --host 0.0.0.0 --port "$WEB_PORT"
