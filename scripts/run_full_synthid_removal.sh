#!/usr/bin/env bash
#
# Full SynthID removal: originals (27 images) + cards (79 images)
# Proven settings: 0.04 × 3 passes, 768 tiles, 128 overlap, 28 steps
#
# Usage:
#   cd /Users/ash/dev/mobile_apps/cosmicfit/scripts
#   ./run_full_synthid_removal.sh 2>&1 | tee full_run.log
#
# Or background for overnight:
#   nohup ./run_full_synthid_removal.sh >> full_run.log 2>&1 &
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
source .venv/bin/activate

STRENGTH="0.04"
PASSES=3
STEPS=28
MAX_TILE=768
TILE_OVERLAP=128

ORIGINALS_BACKUP="/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Resources/.synthid_originals_backup"
ORIGINALS_OUTPUT="/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Resources/originals_desynthid"

echo "============================================================"
echo "FULL SYNTHID REMOVAL"
echo "Settings: strength=${STRENGTH} × ${PASSES} passes, steps=${STEPS}, tile=${MAX_TILE}, overlap=${TILE_OVERLAP}"
echo "Started: $(date)"
echo "============================================================"

# ── Phase 1: Originals (all 27 images including silks) ─────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo "PHASE 1: ORIGINALS (from backup → ${ORIGINALS_OUTPUT})"
echo "════════════════════════════════════════════════════════════"
mkdir -p "$ORIGINALS_OUTPUT"

python remove_synthid_originals.py \
  --originals-dir "$ORIGINALS_BACKUP" \
  --strength $STRENGTH $STRENGTH $STRENGTH \
  --steps $STEPS \
  --max-tile $MAX_TILE \
  --tile-overlap $TILE_OVERLAP \
  --output-dir "$ORIGINALS_OUTPUT"

echo ""
echo "Phase 1 complete: originals written to ${ORIGINALS_OUTPUT}"
echo "Time: $(date)"

# ── Phase 2: Cards (79 images, processed in-place in imagesets) ─
echo ""
echo "════════════════════════════════════════════════════════════"
echo "PHASE 2: CARDS (restore from backup → process → promote in-place)"
echo "════════════════════════════════════════════════════════════"

python remove_synthid_diffusion.py \
  --restore-first \
  --approve-full \
  --strength $STRENGTH \
  --passes $PASSES \
  --steps $STEPS \
  --max-tile $MAX_TILE \
  --tile-overlap $TILE_OVERLAP \
  --min-psnr 20.0 \
  --min-ssim 0.50

echo ""
echo "Phase 2 complete: cards promoted in-place to their imagesets"
echo "Time: $(date)"

echo ""
echo "============================================================"
echo "ALL DONE"
echo "Finished: $(date)"
echo "============================================================"
