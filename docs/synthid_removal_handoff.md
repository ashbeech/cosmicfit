# SynthID Removal — Handoff Document

## Goal

Programmatically remove Google's SynthID watermark from image assets so they no longer trigger Google's SynthID detector ("Based on the detection of a SynthID watermark..."), while preserving production-ready visual quality.

## Current State

### What Works (Cards — 79 images)

The **Cards** pipeline (`remove_synthid_diffusion.py`) successfully removes SynthID from the 79 card images in:

```
Cosmic Fit/Resources/Assets.xcassets/Cards/<name>.imageset/<name>.png
```

**Confirmed passing settings:** `strength=0.04, passes=2, steps=28, max_tile=512, overlap=96`

- Card images are **1041×1741 RGBA** (~12 tiles per image at 512px tiles)
- Processing takes ~40s per image
- The full 79-image batch was run but interrupted at 57/79. Needs completing.
- Backups: `Resources/.synthid_backups/` and `Resources/.synthid_baseline/`

### What Doesn't Work Yet (Originals — 27 images)

The **originals** in `Resources/originals/` are **larger** (mostly 1696×2528 RGB, some 2048×2048) and the same settings fail Gemini's SynthID check.

**Tested and failed on originals:**

| Settings | Gemini Result | Quality |
|---|---|---|
| `0.04 × 2, 512px tiles` | Failed | OK |
| `0.05 × 2, 512px tiles` | Failed | OK |
| `0.06 × 2, 512px tiles` | Failed (some pass, some don't) | OK |
| `0.04/0.05 split, 512px tiles` | Failed (some pass, some don't) | OK |
| `0.09 × 2, 512px tiles` | — (not fully tested) | Too destructive |
| `0.05 × 2, 768px tiles` | Failed | OK but very slow (~103 min/image) |

**Silk images pass easily** (simple textures). The 5 Silks are done at `0.06 × 2`:
- `BlueSilk.png`, `BurgundySilk.png`, `GoldSilk.png`, `GreenSilk.png`, `TealSilk.png`
- These are already processed in `originals/` and confirmed passing.

The remaining **22 non-Silk originals** still need processing.

### Why Originals Are Harder

Cards are 1041×1741 (~1.8M pixels). Originals are 1696×2528 (~4.3M pixels) — **2.4× larger**. At 512px tiles, the UNet only sees ~6% of the image per tile. The SynthID watermark operates at a semi-global spectral level, so small tiles can't disrupt it effectively without cranking strength so high that quality is destroyed.

## Scripts

All scripts are in `/Users/ash/dev/mobile_apps/cosmicfit/scripts/` and use a venv at `scripts/.venv/`.

### `remove_synthid.py`
Dispatcher — delegates to `remove_synthid_diffusion.py` (default) or `remove_synthid_legacy.py` via `--mode`.

### `remove_synthid_diffusion.py`
Main pipeline for Cards. Uses SD 1.5 `img2img` via `StableDiffusionImg2ImgPipeline` on MPS (Apple Silicon). Key functions:
- `_get_pipeline()` — loads/caches the SD 1.5 model
- `_denoise_tile()` — processes one tile
- `_tiled_denoise_pass()` — one full tiled pass with cosine-feathered overlap blending
- `img2img_denoise()` — multi-pass wrapper; `strength` can be a float or list of per-pass floats

Supports `--canary`, `--dry-run`, `--approve-full`, `--restore-first`, quality gates (`--min-psnr`, `--min-ssim`).

### `remove_synthid_originals.py`
Wrapper for the flat `originals/` directory. Imports `img2img_denoise` from the diffusion script. Supports:
- `--strength 0.04 0.05` (per-pass strengths)
- `--max-tile 768`, `--tile-overlap 128`
- `--only` / `--exclude` (filter by filename)
- `--output-dir` (write to separate folder instead of in-place)

### Config / Reports
- `scripts/config/synthid_canary.txt` — canary manifest (5 Major Arcana cards)
- `scripts/reports/synthid_run_report.json` — last run report

### Backups (repo root `Resources/`, outside Xcode bundle)

- `Resources/.synthid_backups/` — original card backups (restore source for `--restore-first`)
- `Resources/.synthid_baseline/` — immutable baseline for PSNR/SSIM
- `Resources/.synthid_candidates/` — card candidate runs (timestamped subdirs)
- `Resources/.synthid_originals_backup/` — original originals backups
- `Resources/.synthid_originals_candidates/` — originals test runs (`--output-dir`)

## Three Options to Try Next

### Option 1: Downscale → Process → Upscale (Most Promising)

The theory: Cards pass at 1041×1741 because each 512px tile covers ~22% of the image width. At 1696×2528, a tile only covers ~13%. By downscaling originals to Card-like dimensions before processing, the UNet sees the same proportion of the image that worked for Cards.

**Implementation:**
1. In `remove_synthid_originals.py`, before calling `img2img_denoise`:
   - Downscale the image to ~1040px wide (maintain aspect ratio) using `cv2.resize(..., interpolation=cv2.INTER_LANCZOS4)`
   - Run `img2img_denoise` at `strength=0.04, passes=2, max_tile=512, overlap=96` (exact Card settings)
   - Upscale back to original dimensions using `cv2.resize(..., interpolation=cv2.INTER_LANCZOS4)`
2. Test on `Death-final.png` with `--output-dir` first
3. This should be much faster (~1-2 min per image instead of ~100 min)

**Risk:** Upscaling may introduce softness. But since the originals are high-res to begin with, Lanczos upscale from ~1040px should be acceptable.

### Option 2: 3 Passes at 0.05

Simply add a third pass. Each pass adds incremental watermark disruption.

**Command:**
```bash
cd scripts && source .venv/bin/activate
python remove_synthid_originals.py \
  --only Death-final.png \
  --output-dir "/path/to/test/output" \
  --strength 0.05 0.05 0.05 \
  --max-tile 512 --tile-overlap 96
```

**Risk:** 3 passes at 512px tiles may still not be enough for global watermark disruption. Quality impact is additive but moderate at 0.05.

### Option 3: More Scheduler Steps

Increase `--steps` from 28 to 50. With `strength=0.05`, `floor(0.05 × 50) = 2` actual denoise steps per pass (vs `floor(0.05 × 28) = 1`). This makes each pass more aggressive without changing the noise fraction.

**Command:**
```bash
cd scripts && source .venv/bin/activate
python remove_synthid_originals.py \
  --only Death-final.png \
  --output-dir "/path/to/test/output" \
  --strength 0.05 0.05 \
  --steps 50 \
  --max-tile 512 --tile-overlap 96
```

**Risk:** More steps = more compute per tile. Quality impact is moderate — the extra denoise step per pass adds more SD prior influence.

## Recommended Testing Flow

1. Always restore from backup before a new test:
   ```bash
   cp "Resources/.synthid_originals_backup/Death-final.png" \
      "Resources/originals/Death-final.png"
   ```

2. Use `--output-dir` so originals stay untouched:
   ```bash
   python remove_synthid_originals.py \
     --only Death-final.png \
     --output-dir "Resources/.synthid_originals_candidates/test_name"
   ```

3. Upload the output to Google's SynthID checker

4. If it passes, run on all 22 non-Silk originals (exclude the 5 Silks which are done)

## Remaining Work

1. **Originals (22 non-Silk images):** Find settings that pass Gemini using one of the 3 options above, then batch-process all 22
2. **Cards (79 images):** Re-run full batch with `--strength 0.04 --passes 2 --approve-full` — the previous run was interrupted at 57/79. Consider restoring all from baseline first and doing a clean run.

## Environment

- macOS (Apple Silicon M1 Pro, 16GB)
- Python 3.13 in `scripts/.venv/`
- PyTorch with MPS backend
- SD 1.5 model: `stable-diffusion-v1-5/stable-diffusion-v1-5` (cached by HuggingFace)
- Dependencies: `torch`, `diffusers`, `transformers`, `accelerate`, `safetensors`, `opencv-python`, `Pillow`, `numpy`

## Key Reference

Blog post that inspired the diffusion approach:
https://blog.return.moe/en/2025/12/21/watermark-removal-as-a-denoising-task/
