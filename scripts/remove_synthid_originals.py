#!/usr/bin/env python3
"""
SynthID remover for the flat originals directory.

Backs up all images, then processes each in-place using the same SD 1.5
img2img pipeline as remove_synthid_diffusion.py.

With --output-dir, writes copies there only (does not modify originals;
skips backup step).

Usage:
    python remove_synthid_originals.py [--strength 0.04 0.04] [--output-dir DIR]
"""

from __future__ import annotations

import os
import shutil
import sys

import numpy as np
from PIL import Image

from remove_synthid_diffusion import (
    _get_pipeline,
    img2img_denoise,
)
from synthid_profiles import profile_for_image, profile_summary

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGINALS_DIR = os.path.join(REPO_ROOT, "Resources", "originals")
BACKUP_DIR = os.path.join(REPO_ROOT, "Resources", ".synthid_originals_backup")
ORIGINALS_CANDIDATES_DIR = os.path.join(REPO_ROOT, "Resources", ".synthid_originals_candidates")

SUPPORTED_EXTS = {".png", ".jpg", ".jpeg"}


def collect_images(directory: str) -> list[str]:
    files = []
    for name in sorted(os.listdir(directory)):
        if os.path.splitext(name)[1].lower() in SUPPORTED_EXTS:
            files.append(os.path.join(directory, name))
    return files


def backup_all(images: list[str], backup_dir: str) -> None:
    os.makedirs(backup_dir, exist_ok=True)
    for path in images:
        dst = os.path.join(backup_dir, os.path.basename(path))
        if not os.path.exists(dst):
            shutil.copy2(path, dst)
    print(f"Backed up {len(images)} images to {backup_dir}")


def load_image(path: str) -> tuple[np.ndarray, np.ndarray | None, str]:
    """Load image, return (rgb, alpha_or_None, mode)."""
    img = Image.open(path)
    if img.mode == "RGBA":
        arr = np.array(img)
        return arr[:, :, :3], arr[:, :, 3], "RGBA"
    rgb = np.array(img.convert("RGB"))
    return rgb, None, img.mode


def save_image(
    path: str, rgb: np.ndarray, alpha: np.ndarray | None, orig_mode: str
) -> None:
    ext = os.path.splitext(path)[1].lower()
    if alpha is not None:
        out = np.dstack([rgb, alpha]).astype(np.uint8)
        Image.fromarray(out, "RGBA").save(path, "PNG", optimize=True)
    elif ext in (".jpg", ".jpeg"):
        img = Image.fromarray(rgb.astype(np.uint8), "RGB")
        img.save(path, "JPEG", quality=95)
    else:
        Image.fromarray(rgb.astype(np.uint8), "RGB").save(path, "PNG", optimize=True)


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="De-SynthID the originals directory")
    parser.add_argument(
        "--profile",
        default="auto",
        choices=["auto", "large_original", "batch_legacy", "card", "silk"],
        help="Image-adaptive profile (default: auto). Manual flags below override when profile is not auto.",
    )
    parser.add_argument(
        "--strength", type=float, nargs="+", default=None,
        help="Per-pass strength values (overrides profile when set)",
    )
    parser.add_argument("--steps", type=int, default=None)
    parser.add_argument("--guidance-scale", type=float, default=None)
    parser.add_argument("--max-tile", type=int, default=None,
                        help="Tile size in px (overrides profile when set)")
    parser.add_argument("--tile-overlap", type=int, default=None,
                        help="Tile overlap in px (overrides profile when set)")
    parser.add_argument("--originals-dir", default=ORIGINALS_DIR)
    parser.add_argument("--backup-dir", default=BACKUP_DIR)
    parser.add_argument(
        "--only", nargs="+", default=None,
        help="Process only these filenames (basenames)",
    )
    parser.add_argument(
        "--exclude", nargs="+", default=None,
        help="Skip these filenames (basenames)",
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help=(
            "Write outputs here (same basenames). Does not modify originals; "
            f"skips backup. The directory is created if missing. "
            f"Typical test path: {ORIGINALS_CANDIDATES_DIR}/<run_name>"
        ),
    )
    args = parser.parse_args()

    images = collect_images(args.originals_dir)
    if args.only:
        only_set = set(args.only)
        images = [p for p in images if os.path.basename(p) in only_set]
    if args.exclude:
        excl_set = set(args.exclude)
        images = [p for p in images if os.path.basename(p) not in excl_set]
    if not images:
        print(f"No images matched in {args.originals_dir}")
        return 1

    out_root: str | None = args.output_dir

    print(f"Processing {len(images)} images in {args.originals_dir}")
    print(f"Profile mode: {args.profile}")
    if out_root:
        os.makedirs(out_root, exist_ok=True)
        print(f"Output directory: {out_root}")
    else:
        print("Output: in-place (originals overwritten after each image)")

    if not out_root:
        backup_all(images, args.backup_dir)

    _get_pipeline()

    for idx, path in enumerate(images, 1):
        basename = os.path.basename(path)
        print(f"\n[{idx:2d}/{len(images)}] {basename}...", flush=True)

        rgb, alpha, orig_mode = load_image(path)
        h, w = rgb.shape[:2]
        profile = profile_for_image(w, h, basename=basename, profile_name=args.profile)
        summary = profile_summary(profile, w, h)
        strength = args.strength if args.strength is not None else profile.strength
        steps = args.steps if args.steps is not None else profile.steps
        guidance = args.guidance_scale if args.guidance_scale is not None else profile.guidance_scale
        max_tile = args.max_tile if args.max_tile is not None else profile.max_tile
        overlap = args.tile_overlap if args.tile_overlap is not None else profile.tile_overlap
        print(
            f"  profile={summary['name']} strength={strength} steps={steps} "
            f"tile={max_tile} overlap={overlap} (~{summary['estimated_total_tile_runs']} runs)",
            flush=True,
        )
        out_rgb = img2img_denoise(
            rgb,
            strength=strength,
            num_steps=steps,
            guidance_scale=guidance,
            max_tile=max_tile,
            overlap=overlap,
        )
        dest = os.path.join(out_root, basename) if out_root else path
        if out_root:
            os.makedirs(out_root, exist_ok=True)
        save_image(dest, out_rgb, alpha, orig_mode)
        print(f"  done ({rgb.shape[1]}x{rgb.shape[0]}) -> {dest}")

    print(f"\n{'=' * 60}")
    if out_root:
        print(f"Finished processing {len(images)} image(s) into:\n{out_root}")
    else:
        print(f"Finished processing {len(images)} originals in-place.")
        print(f"Backups at: {args.backup_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
