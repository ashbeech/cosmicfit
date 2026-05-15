#!/usr/bin/env python3
"""
Quality-first SynthID remover using full img2img diffusion denoising.

Uses a real Stable Diffusion img2img pipeline (not just the VAE) to add a tiny
amount of scheduled noise and then denoise with the full UNet. This is the
technique proven to remove SynthID in a single step while preserving visual
quality:
  https://blog.return.moe/en/2025/12/21/watermark-removal-as-a-denoising-task/

Pipeline: baseline -> candidate -> promoted (with quality gates).
"""

from __future__ import annotations

import argparse
import datetime as dt
import glob
import json
import os
import shutil
import sys
from dataclasses import dataclass
from typing import Any

import cv2
import numpy as np
import torch
from PIL import Image


_pipe = None
_device: torch.device | None = None

SD_MODEL_ID = "stable-diffusion-v1-5/stable-diffusion-v1-5"


def _get_pipeline():
    """Load the SD 1.5 img2img pipeline once and cache it."""
    global _pipe, _device

    if _pipe is not None:
        return _pipe, _device

    from diffusers import StableDiffusionImg2ImgPipeline

    if torch.backends.mps.is_available():
        device = torch.device("mps")
    elif torch.cuda.is_available():
        device = torch.device("cuda")
    else:
        device = torch.device("cpu")

    print(f"Loading SD 1.5 img2img pipeline ({SD_MODEL_ID}) on {device}...")
    pipe = StableDiffusionImg2ImgPipeline.from_pretrained(
        SD_MODEL_ID,
        torch_dtype=torch.float32,
        safety_checker=None,
        requires_safety_checker=False,
    )
    pipe = pipe.to(device)

    _pipe = pipe
    _device = device
    return pipe, device


DEFAULT_ASSETS_DIR = (
    "/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Resources/Assets.xcassets"
)
DEFAULT_RESOURCES_DIR = os.path.dirname(DEFAULT_ASSETS_DIR)
DEFAULT_BACKUP_DIR = os.path.join(DEFAULT_RESOURCES_DIR, ".synthid_backups")
DEFAULT_BASELINE_DIR = os.path.join(DEFAULT_RESOURCES_DIR, ".synthid_baseline")
DEFAULT_CANDIDATE_DIR = os.path.join(DEFAULT_RESOURCES_DIR, ".synthid_candidates")
DEFAULT_REPORT_PATH = (
    "/Users/ash/dev/mobile_apps/cosmicfit/scripts/reports/synthid_run_report.json"
)
DEFAULT_CANARY_PATH = (
    "/Users/ash/dev/mobile_apps/cosmicfit/scripts/config/synthid_canary.txt"
)


@dataclass
class QualityMetrics:
    psnr: float
    ssim: float


def find_card_images(assets_dir: str) -> list[str]:
    cards_dir = os.path.join(assets_dir, "Cards")
    if not os.path.isdir(cards_dir):
        raise FileNotFoundError(f"Cards directory not found: {cards_dir}")

    images: list[str] = []
    for imageset_dir in sorted(glob.glob(os.path.join(cards_dir, "*.imageset"))):
        for png in sorted(glob.glob(os.path.join(imageset_dir, "*.png"))):
            images.append(png)
    return images


def read_canary_manifest(path: str) -> list[str]:
    if not os.path.exists(path):
        raise FileNotFoundError(f"Canary manifest missing: {path}")

    selected: list[str] = []
    with open(path, "r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            selected.append(line)
    return selected


def load_rgba(path: str) -> tuple[np.ndarray, np.ndarray]:
    arr = np.array(Image.open(path).convert("RGBA"))
    return arr[:, :, :3], arr[:, :, 3]


def save_rgba(path: str, rgb: np.ndarray, alpha: np.ndarray) -> None:
    out = np.dstack([rgb, alpha]).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(path, "PNG", optimize=True)


def _denoise_tile(
    pipe,
    tile_rgb: np.ndarray,
    strength: float,
    num_steps: int,
    guidance_scale: float,
) -> np.ndarray:
    """Run img2img on a single tile that fits in memory."""
    h, w = tile_rgb.shape[:2]
    h_pad = ((h + 7) // 8) * 8
    w_pad = ((w + 7) // 8) * 8
    pil_tile = Image.fromarray(tile_rgb).resize((w_pad, h_pad), Image.LANCZOS)

    with torch.no_grad():
        result = pipe(
            prompt="",
            image=pil_tile,
            strength=strength,
            num_inference_steps=num_steps,
            guidance_scale=guidance_scale,
        )

    out = np.array(result.images[0])
    if (h_pad, w_pad) != (h, w):
        out = cv2.resize(out, (w, h), interpolation=cv2.INTER_LANCZOS4)
    return out.astype(np.uint8)


def _tiled_denoise_pass(
    pipe,
    image_rgb: np.ndarray,
    strength: float,
    num_steps: int,
    guidance_scale: float,
    max_tile: int,
    overlap: int,
    pass_label: str = "",
) -> np.ndarray:
    """Single tiled img2img pass over the full image."""
    h_orig, w_orig = image_rgb.shape[:2]

    if h_orig <= max_tile and w_orig <= max_tile:
        return _denoise_tile(pipe, image_rgb, strength, num_steps, guidance_scale)

    step = max_tile - overlap
    output = np.zeros_like(image_rgb, dtype=np.float64)
    weights = np.zeros((h_orig, w_orig), dtype=np.float64)

    tiles_y = list(range(0, h_orig, step))
    tiles_x = list(range(0, w_orig, step))

    total_tiles = len(tiles_y) * len(tiles_x)
    tile_idx = 0

    for ty in tiles_y:
        for tx in tiles_x:
            tile_idx += 1
            y1 = ty
            x1 = tx
            y2 = min(ty + max_tile, h_orig)
            x2 = min(tx + max_tile, w_orig)

            tile = image_rgb[y1:y2, x1:x2].copy()
            label = f"{pass_label}tile {tile_idx}/{total_tiles} ({y1}:{y2}, {x1}:{x2})"
            print(f"{label}...", end=" ", flush=True)
            denoised_tile = _denoise_tile(pipe, tile, strength, num_steps, guidance_scale)

            # Build feathering weight mask for blending overlaps.
            th, tw = denoised_tile.shape[:2]
            mask = np.ones((th, tw), dtype=np.float64)

            # Cosine ramps in overlap zones (smoother than linear; fewer tile seams).
            if y1 > 0:
                n = min(overlap, th)
                ramp = 0.5 - 0.5 * np.cos(np.linspace(0.0, np.pi, n, dtype=np.float64))
                mask[:n, :] *= ramp[:, None]
            if y2 < h_orig:
                n = min(overlap, th)
                ramp = 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, n, dtype=np.float64))
                mask[-n:, :] *= ramp[:, None]
            if x1 > 0:
                n = min(overlap, tw)
                ramp = 0.5 - 0.5 * np.cos(np.linspace(0.0, np.pi, n, dtype=np.float64))
                mask[:, :n] *= ramp[None, :]
            if x2 < w_orig:
                n = min(overlap, tw)
                ramp = 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, n, dtype=np.float64))
                mask[:, -n:] *= ramp[None, :]

            for c in range(3):
                output[y1:y2, x1:x2, c] += denoised_tile[:, :, c].astype(np.float64) * mask
            weights[y1:y2, x1:x2] += mask

    # Normalise by accumulated weights.
    weights = np.maximum(weights, 1e-8)
    for c in range(3):
        output[:, :, c] /= weights

    return np.clip(output, 0, 255).astype(np.uint8)


def img2img_denoise(
    image_rgb: np.ndarray,
    strength: float | list[float] = 0.05,
    num_steps: int = 28,
    guidance_scale: float = 1.0,
    passes: int = 2,
    max_tile: int = 512,
    overlap: int = 96,
) -> np.ndarray:
    """
    Full SD 1.5 img2img denoise with tiling and multi-pass support.

    strength can be a single float (used for every pass) or a list of
    per-pass floats (length must match passes).

    Each pass runs a complete tiled img2img cycle over the whole image.
    Unlike VAE-only round-trips, img2img at low strength only adds a small
    amount of scheduled noise each time, so multiple passes are safe and
    additive in watermark removal without catastrophic quality loss.
    """
    pipe, _ = _get_pipeline()
    result = image_rgb.copy()

    if isinstance(strength, (list, tuple)):
        strengths = list(strength)
        passes = len(strengths)
    else:
        strengths = [strength] * passes

    for p in range(passes):
        pass_label = f"[pass {p + 1}/{passes} s={strengths[p]}] " if passes > 1 else ""
        result = _tiled_denoise_pass(
            pipe, result, strengths[p], num_steps, guidance_scale,
            max_tile, overlap, pass_label,
        )

    return result


def compute_psnr(a: np.ndarray, b: np.ndarray) -> float:
    mse = np.mean((a.astype(np.float64) - b.astype(np.float64)) ** 2)
    if mse == 0:
        return 99.0
    return float(20.0 * np.log10(255.0 / np.sqrt(mse)))


def _ssim_single_channel(a: np.ndarray, b: np.ndarray) -> float:
    a = a.astype(np.float64)
    b = b.astype(np.float64)
    c1 = (0.01 * 255) ** 2
    c2 = (0.03 * 255) ** 2

    mu_a = cv2.GaussianBlur(a, (11, 11), 1.5)
    mu_b = cv2.GaussianBlur(b, (11, 11), 1.5)

    mu_a2 = mu_a * mu_a
    mu_b2 = mu_b * mu_b
    mu_ab = mu_a * mu_b

    sigma_a2 = cv2.GaussianBlur(a * a, (11, 11), 1.5) - mu_a2
    sigma_b2 = cv2.GaussianBlur(b * b, (11, 11), 1.5) - mu_b2
    sigma_ab = cv2.GaussianBlur(a * b, (11, 11), 1.5) - mu_ab

    num = (2 * mu_ab + c1) * (2 * sigma_ab + c2)
    den = (mu_a2 + mu_b2 + c1) * (sigma_a2 + sigma_b2 + c2)
    ssim_map = num / (den + 1e-12)
    return float(np.mean(ssim_map))


def compute_ssim(a: np.ndarray, b: np.ndarray) -> float:
    channels = [_ssim_single_channel(a[:, :, c], b[:, :, c]) for c in range(3)]
    return float(np.mean(channels))


def ensure_baseline(images: list[str], baseline_dir: str, backup_dir: str) -> None:
    os.makedirs(baseline_dir, exist_ok=True)
    for img_path in images:
        basename = os.path.basename(img_path)
        baseline_path = os.path.join(baseline_dir, basename)
        if os.path.exists(baseline_path):
            continue
        backup_path = os.path.join(backup_dir, basename)
        if not os.path.exists(backup_path):
            raise FileNotFoundError(
                f"Missing source for baseline: {basename} in {backup_dir}"
            )
        shutil.copy2(backup_path, baseline_path)


def restore_from_backup(images: list[str], backup_dir: str) -> int:
    restored = 0
    for img_path in images:
        basename = os.path.basename(img_path)
        src = os.path.join(backup_dir, basename)
        if not os.path.exists(src):
            continue
        shutil.copy2(src, img_path)
        restored += 1
    return restored


def process_images(args: argparse.Namespace) -> dict[str, Any]:
    images = find_card_images(args.assets_dir)
    if not images:
        raise RuntimeError("No card images found")

    ensure_baseline(images, args.baseline_dir, args.backup_dir)

    if args.restore_first:
        restored = restore_from_backup(images, args.backup_dir)
        print(f"Restored {restored} images from backup.")

    selected_images = images
    run_scope = "full"
    if args.canary:
        run_scope = "canary"
        wanted = set(read_canary_manifest(args.canary_manifest))
        selected_images = [p for p in images if os.path.basename(p) in wanted]
        if not selected_images:
            raise RuntimeError("Canary mode selected but no files matched manifest")
    elif not args.approve_full:
        raise RuntimeError(
            "Full run blocked. Use --canary for canary set or pass --approve-full."
        )

    run_id = dt.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    candidate_dir = os.path.join(args.candidate_dir, run_id)
    os.makedirs(candidate_dir, exist_ok=True)
    os.makedirs(os.path.dirname(args.report_path), exist_ok=True)

    records: list[dict[str, Any]] = []
    promoted = 0
    skipped = 0
    failed = 0

    print(
        f"Processing {len(selected_images)} images in {run_scope} mode "
        f"(strength={args.strength}, steps={args.steps}, passes={args.passes}, "
        f"max_tile={args.max_tile}, overlap={args.tile_overlap}, "
        f"min_psnr={args.min_psnr}, min_ssim={args.min_ssim})"
    )

    for idx, image_path in enumerate(selected_images, 1):
        basename = os.path.basename(image_path)
        baseline_path = os.path.join(args.baseline_dir, basename)
        candidate_path = os.path.join(candidate_dir, basename)
        entry: dict[str, Any] = {
            "image": basename,
            "asset_path": image_path,
            "baseline_path": baseline_path,
            "candidate_path": candidate_path,
            "status": "pending",
        }

        try:
            print(f"[{idx:3d}/{len(selected_images)}] {basename}...", end=" ", flush=True)
            baseline_rgb, baseline_alpha = load_rgba(baseline_path)
            out_rgb = img2img_denoise(
                baseline_rgb,
                strength=args.strength,
                num_steps=args.steps,
                guidance_scale=args.guidance_scale,
                passes=args.passes,
                max_tile=args.max_tile,
                overlap=args.tile_overlap,
            )
            save_rgba(candidate_path, out_rgb, baseline_alpha)

            metrics = QualityMetrics(
                psnr=compute_psnr(baseline_rgb, out_rgb),
                ssim=compute_ssim(baseline_rgb, out_rgb),
            )
            entry["metrics"] = {"psnr": metrics.psnr, "ssim": metrics.ssim}

            if metrics.psnr < args.min_psnr or metrics.ssim < args.min_ssim:
                entry["status"] = "skipped_quality_gate"
                skipped += 1
                print(
                    f"SKIP (psnr={metrics.psnr:.2f}, ssim={metrics.ssim:.4f})"
                )
            else:
                entry["status"] = "candidate_ready" if args.dry_run else "promoted"
                if not args.dry_run:
                    shutil.copy2(candidate_path, image_path)
                    promoted += 1
                    print(
                        f"PROMOTED (psnr={metrics.psnr:.2f}, ssim={metrics.ssim:.4f})"
                    )
                else:
                    print(
                        f"CANDIDATE (psnr={metrics.psnr:.2f}, ssim={metrics.ssim:.4f})"
                    )
        except Exception as exc:  # noqa: BLE001
            entry["status"] = "failed"
            entry["error"] = str(exc)
            failed += 1
            print(f"FAILED ({exc})")

        records.append(entry)

    report: dict[str, Any] = {
        "run_id": run_id,
        "timestamp_utc": dt.datetime.utcnow().isoformat() + "Z",
        "mode": "img2img_diffusion",
        "scope": run_scope,
        "config": {
            "model": SD_MODEL_ID,
            "assets_dir": args.assets_dir,
            "baseline_dir": args.baseline_dir,
            "backup_dir": args.backup_dir,
            "candidate_dir": candidate_dir,
            "strength": args.strength,
            "steps": args.steps,
            "passes": args.passes,
            "guidance_scale": args.guidance_scale,
            "max_tile": args.max_tile,
            "tile_overlap": args.tile_overlap,
            "min_psnr": args.min_psnr,
            "min_ssim": args.min_ssim,
            "dry_run": args.dry_run,
            "canary_manifest": args.canary_manifest if args.canary else None,
        },
        "summary": {
            "total_selected": len(selected_images),
            "promoted": promoted,
            "skipped_quality_gate": skipped,
            "failed": failed,
        },
        "google_checker_validation": {
            "status": "pending_manual_validation",
            "note": (
                "Upload canary outputs to Google checker and update results in the "
                "report before approving full run."
            ),
        },
        "records": records,
    }

    with open(args.report_path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)
        fh.write("\n")

    print("=" * 60)
    print(
        f"Done. promoted={promoted}, skipped_quality_gate={skipped}, failed={failed}\n"
        f"Report: {args.report_path}\nCandidates: {candidate_dir}"
    )
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="img2img diffusion SynthID remover (quality-first)"
    )
    parser.add_argument("--assets-dir", default=DEFAULT_ASSETS_DIR)
    parser.add_argument("--backup-dir", default=DEFAULT_BACKUP_DIR)
    parser.add_argument("--baseline-dir", default=DEFAULT_BASELINE_DIR)
    parser.add_argument("--candidate-dir", default=DEFAULT_CANDIDATE_DIR)
    parser.add_argument("--report-path", default=DEFAULT_REPORT_PATH)

    parser.add_argument(
        "--strength",
        type=float,
        default=0.02,
        help=(
            "img2img strength: scheduled noise fraction per pass "
            "(0.02 ≈ ~1.1 steps at 28 total; lower = closer to original)"
        ),
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=28,
        help="Total scheduler steps (only strength * steps actually run)",
    )
    parser.add_argument(
        "--passes",
        type=int,
        default=2,
        help="Number of full img2img passes over the image (default: 2)",
    )
    parser.add_argument(
        "--guidance-scale",
        type=float,
        default=1.0,
        help="CFG scale (1.0 = unconditional, no prompt influence)",
    )
    parser.add_argument(
        "--max-tile",
        type=int,
        default=512,
        help="Max tile side length in pixels (512 is safest on 16GB MPS)",
    )
    parser.add_argument(
        "--tile-overlap",
        type=int,
        default=96,
        help="Tile overlap in pixels (wider = softer seams, slower)",
    )

    parser.add_argument(
        "--min-psnr",
        type=float,
        default=23.0,
        help="Minimum PSNR vs baseline to promote",
    )
    parser.add_argument(
        "--min-ssim",
        type=float,
        default=0.56,
        help="Minimum SSIM vs baseline to promote",
    )

    parser.add_argument("--restore-first", action="store_true")
    parser.add_argument("--dry-run", action="store_true")

    parser.add_argument("--canary", action="store_true")
    parser.add_argument("--canary-manifest", default=DEFAULT_CANARY_PATH)
    parser.add_argument(
        "--approve-full",
        action="store_true",
        help="Required to process full set when --canary is not used",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        process_images(args)
        return 0
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
