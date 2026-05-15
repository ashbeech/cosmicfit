#!/usr/bin/env python3
"""
Legacy SynthID remover (fallback mode).
Kept for compatibility; diffusion mode is the primary production path.
"""

from __future__ import annotations

import argparse
import glob
import os
import shutil
import sys

import cv2
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, map_coordinates


DEFAULT_ASSETS_DIR = (
    "/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Resources/Assets.xcassets"
)
DEFAULT_BACKUP_DIR = (
    "/Users/ash/dev/mobile_apps/cosmicfit/Cosmic Fit/Resources/.synthid_backups"
)


def find_card_images(assets_dir: str) -> list[str]:
    cards_dir = os.path.join(assets_dir, "Cards")
    images: list[str] = []
    for imageset_dir in sorted(glob.glob(os.path.join(cards_dir, "*.imageset"))):
        images.extend(sorted(glob.glob(os.path.join(imageset_dir, "*.png"))))
    return images


def restore_first(images: list[str], backup_dir: str) -> int:
    restored = 0
    for image_path in images:
        src = os.path.join(backup_dir, os.path.basename(image_path))
        if os.path.exists(src):
            shutil.copy2(src, image_path)
            restored += 1
    return restored


def process_one(path: str) -> None:
    arr = np.array(Image.open(path).convert("RGBA"))
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]

    # Legacy 3-pass transform (kept intentionally similar to prior behavior).
    for idx in range(3):
        np.random.seed(42 + idx * 7919)
        h, w = rgb.shape[:2]
        dx = gaussian_filter(np.random.randn(h, w), 48) * 1.8
        dy = gaussian_filter(np.random.randn(h, w), 48) * 1.8
        y, x = np.meshgrid(np.arange(h), np.arange(w), indexing="ij")
        ny = np.clip(y + dy, 0, h - 1)
        nx = np.clip(x + dx, 0, w - 1)
        warped = np.zeros_like(rgb)
        for c in range(3):
            warped[:, :, c] = map_coordinates(
                rgb[:, :, c].astype(np.float64), [ny, nx], order=1, mode="reflect"
            ).astype(np.uint8)
        rgb = cv2.fastNlMeansDenoisingColored(warped, None, 2, 2, 7, 21)
        small = cv2.resize(rgb, (int(w * 0.95), int(h * 0.95)), interpolation=cv2.INTER_AREA)
        rgb = cv2.resize(small, (w, h), interpolation=cv2.INTER_LANCZOS4)

    out = np.dstack([rgb, alpha]).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(path, "PNG", optimize=True)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Legacy SynthID remover")
    parser.add_argument("--assets-dir", default=DEFAULT_ASSETS_DIR)
    parser.add_argument("--backup-dir", default=DEFAULT_BACKUP_DIR)
    parser.add_argument("--restore-first", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    images = find_card_images(args.assets_dir)
    if args.restore_first:
        restored = restore_first(images, args.backup_dir)
        print(f"Legacy: restored {restored} images from backup.")
    if args.dry_run:
        print(f"Legacy dry-run: {len(images)} images")
        return 0

    ok = 0
    for idx, image_path in enumerate(images, 1):
        name = os.path.basename(image_path)
        try:
            process_one(image_path)
            ok += 1
            print(f"[{idx:3d}/{len(images)}] {name} done")
        except Exception as exc:  # noqa: BLE001
            print(f"[{idx:3d}/{len(images)}] {name} FAILED: {exc}")
    print(f"Legacy complete: {ok}/{len(images)} processed")
    return 0 if ok == len(images) else 1


if __name__ == "__main__":
    sys.exit(main())
