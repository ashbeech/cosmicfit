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

ORIGINALS_DIR = (
    "/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Resources/originals"
)
BACKUP_DIR = os.path.join(os.path.dirname(ORIGINALS_DIR), ".synthid_originals_backup")

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
        "--strength", type=float, nargs="+", default=[0.04, 0.05],
        help="Per-pass strength values (e.g. --strength 0.04 0.05)",
    )
    parser.add_argument("--steps", type=int, default=28)
    parser.add_argument("--guidance-scale", type=float, default=1.0)
    parser.add_argument("--max-tile", type=int, default=768,
                        help="Tile size in px (768 for large originals)")
    parser.add_argument("--tile-overlap", type=int, default=128,
                        help="Tile overlap in px")
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
            "skips backup. The directory is created if missing."
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
    print(f"Settings: strength={args.strength}, steps={args.steps}, "
          f"max_tile={args.max_tile}, overlap={args.tile_overlap}")
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
        out_rgb = img2img_denoise(
            rgb,
            strength=args.strength,
            num_steps=args.steps,
            guidance_scale=args.guidance_scale,
            max_tile=args.max_tile,
            overlap=args.tile_overlap,
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
