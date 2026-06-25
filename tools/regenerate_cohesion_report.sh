#!/usr/bin/env bash
# Regenerate docs/fixtures/narrative_cohesion_report.{json,txt} and slider_range_report.json
# by running the Swift cohesion harness and copying from the simulator app container.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="com.thisisbullish.cosmicfit"
DEST="$ROOT/docs/fixtures"
RESULT="/tmp/cosmicfit_cohesion_report.xcresult"

echo "Running NarrativeCohesionReport_Tests/generateCohesionReport …"
xcrun simctl shutdown all 2>/dev/null || true
rm -rf "$RESULT"

xcodebuild test \
  -workspace "Cosmic Fit.xcworkspace" \
  -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests/NarrativeCohesionReport_Tests/generateCohesionReport" \
  -resultBundlePath "$RESULT" \
  -parallel-testing-enabled NO \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 1800

# Prefer direct repo write (works from Xcode GUI); fall back to simulator Documents export.
if [[ -f "$DEST/narrative_cohesion_report.txt" ]]; then
  MTIME=$(stat -f "%m" "$DEST/narrative_cohesion_report.txt" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if (( NOW - MTIME < 120 )); then
    echo "Fixtures updated in $DEST"
    exit 0
  fi
fi

BOOTED=$(xcrun simctl list devices booted -j | python3 -c "import json,sys; d=json.load(sys.stdin); print(next((u['udid'] for r in d['devices'].values() for u in r if u.get('state')=='Booted'), ''))" 2>/dev/null || true)
if [[ -z "$BOOTED" ]]; then
  echo "Warning: no booted simulator; fixtures may be stale. Run from Xcode (Product → Test) to update $DEST"
  exit 0
fi

CONTAINER=$(xcrun simctl get_app_container "$BOOTED" "$BUNDLE_ID" data 2>/dev/null || true)
EXPORT="$CONTAINER/Documents/cohesion_fixtures"
if [[ -d "$EXPORT" ]]; then
  cp "$EXPORT/narrative_cohesion_report.json" "$DEST/"
  cp "$EXPORT/narrative_cohesion_report.txt" "$DEST/"
  cp "$EXPORT/slider_range_report.json" "$DEST/"
  echo "Copied fixtures from simulator → $DEST"
else
  echo "Warning: $EXPORT not found. Run from Xcode (Product → Test) to update $DEST"
fi
