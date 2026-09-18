#!/usr/bin/env bash
# Serve the web export locally and open a Cloudflare quick tunnel.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8088}"
cd "$ROOT"
if [[ ! -f "../holygems-web/index.html" ]]; then
  echo "Exporting Web build..."
  mkdir -p ../holygems-web
  godot --headless --export-release "Web" "../holygems-web/index.html"
fi
exec python3 "$ROOT/tools/serve_web.py" --host "$HOST" --port "$PORT"
