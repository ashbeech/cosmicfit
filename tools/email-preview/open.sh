#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

deno run --allow-read --allow-write --allow-env generate.ts

PORT="${PORT:-8765}"
echo "Email previews → http://localhost:$PORT"
echo "Press Ctrl+C to stop."

if command -v open >/dev/null 2>&1; then
  (sleep 0.5 && open "http://localhost:$PORT") &
fi

python3 -m http.server "$PORT"
