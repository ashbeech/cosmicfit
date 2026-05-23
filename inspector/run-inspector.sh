#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PORT=7777
BUILD_STAMP_FILE="Sources/CosmicFitInspectorServer/BuildStamp.swift"

# ── 1. Kill any existing inspector on the port ──────────────────────────
OLD_PID=$(lsof -ti tcp:$PORT 2>/dev/null || true)
if [ -n "$OLD_PID" ]; then
    echo "⤷ Killing existing inspector (PID $OLD_PID) on port $PORT"
    kill "$OLD_PID" 2>/dev/null || true
    sleep 0.5
fi

# ── 2. Generate BuildStamp.swift with current timestamp ─────────────────
STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$BUILD_STAMP_FILE" <<SWIFT
enum BuildStamp {
    static let timestamp = "$STAMP"
}
SWIFT
echo "⤷ Build stamp: $STAMP"

# ── 3. Invalidate SPM's build manifest to force symlink re-evaluation ──
if [ -f .build/build.db ]; then
    rm .build/build.db
    echo "⤷ Invalidated SPM build cache (build.db)"
fi

# ── 4. Build ────────────────────────────────────────────────────────────
echo "⤷ Building..."
swift build 2>&1 | tail -3

# ── 5. Run ──────────────────────────────────────────────────────────────
echo ""
exec .build/arm64-apple-macosx/debug/cosmicfit-inspector
