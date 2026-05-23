#!/usr/bin/env python3
"""
Image-adaptive SynthID removal profiles.

Picks strength/steps/tile settings from image dimensions — no downscale/upscale.
Large production originals get bigger tiles + wider overlap (fewer seams, more
context per forward pass) and 50 scheduler steps with a gentle 3-pass ramp.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

# 1024px img2img tiles can request ~8 GiB on MPS (16 GB unified Macs fail).
# Override with SYNTHID_MAX_TILE=896 only if you have headroom and want to experiment.
_DEFAULT_MAX_TILE = int(os.environ.get("SYNTHID_MAX_TILE", "768"))


@dataclass(frozen=True)
class SynthIDProfile:
    name: str
    strength: list[float]
    steps: int
    max_tile: int
    tile_overlap: int
    guidance_scale: float
    description: str

    @property
    def passes(self) -> int:
        return len(self.strength)


# Cards — confirmed passing on Google checker (handoff doc).
CARD_PROFILE = SynthIDProfile(
    name="card",
    strength=[0.04, 0.04],
    steps=28,
    max_tile=512,
    tile_overlap=96,
    guidance_scale=1.0,
    description="Card-sized assets (~1041×1741): 2 passes, 512px tiles",
)

# Flat / simple textures — quick to denoise.
SILK_PROFILE = SynthIDProfile(
    name="silk",
    strength=[0.06, 0.06],
    steps=28,
    max_tile=768,
    tile_overlap=128,
    guidance_scale=1.0,
    description="Simple texture originals (Silks): 2 passes at 0.06",
)

# Previous full-batch defaults (kept for explicit override).
BATCH_LEGACY_PROFILE = SynthIDProfile(
    name="batch_legacy",
    strength=[0.04, 0.04, 0.04],
    steps=28,
    max_tile=768,
    tile_overlap=128,
    guidance_scale=1.0,
    description="Legacy batch: uniform 0.04 × 3, 768px tiles, 28 steps",
)

PROFILE_BY_NAME = {
    "auto": None,
    "card": CARD_PROFILE,
    "silk": SILK_PROFILE,
    "batch_legacy": BATCH_LEGACY_PROFILE,
    "large_original": None,  # resolved dynamically
}


def _tile_grid_count(width: int, height: int, max_tile: int, overlap: int) -> int:
    step = max(max_tile - overlap, 1)
    ny = len(list(range(0, height, step)))
    nx = len(list(range(0, width, step)))
    return ny * nx


def _large_original_profile(width: int, height: int) -> SynthIDProfile:
    """
    Large originals on Apple Silicon: cap tile size at 768px (1024px can OOM with
    ~8 GiB MPS allocations on 16 GB machines). Wider overlap + 50 steps + gentle
    strength ramp; still 3 passes only.
    """
    strength = [0.04, 0.05, 0.05]
    steps = 50
    long_edge = max(width, height)

    cap = min(_DEFAULT_MAX_TILE, 768)
    candidates = tuple(t for t in (768, 640, 512) if t <= cap)
    if not candidates:
        candidates = (768,)

    best_tile = candidates[-1]
    best_overlap = max(128, int(best_tile * 0.19))
    for candidate in candidates:
        overlap = max(128, int(candidate * 0.19))
        tiles = _tile_grid_count(width, height, candidate, overlap)
        if tiles <= 18:
            best_tile = candidate
            best_overlap = overlap
            break

    return SynthIDProfile(
        name="large_original",
        strength=strength,
        steps=steps,
        max_tile=best_tile,
        tile_overlap=best_overlap,
        guidance_scale=1.0,
        description=(
            f"Large original ({width}×{height}, long edge {long_edge}px): "
            f"{best_tile}px tiles, {best_overlap}px overlap, "
            f"50 steps, strength {strength[0]}/{strength[1]}/{strength[2]} "
            f"(768px cap for 16 GB Mac VRAM)"
        ),
    )


def is_silk_basename(basename: str) -> bool:
    return basename.endswith("Silk.png") or basename.endswith("Silk.jpg")


def profile_for_image(
    width: int,
    height: int,
    *,
    basename: str | None = None,
    profile_name: str = "auto",
) -> SynthIDProfile:
    """Resolve processing profile from image geometry (and optional filename)."""
    if profile_name != "auto":
        named = PROFILE_BY_NAME.get(profile_name)
        if named is None and profile_name == "large_original":
            return _large_original_profile(width, height)
        if named is not None:
            return named
        raise ValueError(f"Unknown profile: {profile_name}")

    if basename and is_silk_basename(basename):
        return SILK_PROFILE

    pixels = width * height
    long_edge = max(width, height)
    short_edge = min(width, height)

    # Card-like (~1041×1741): tall narrow assets, under ~2MP.
    if pixels < 2_200_000 and short_edge <= 1100:
        return CARD_PROFILE

    # Large production originals (Major Arcana full-res, etc.).
    if long_edge >= 1400 or pixels >= 3_000_000:
        return _large_original_profile(width, height)

    return _large_original_profile(width, height)


def profile_summary(profile: SynthIDProfile, width: int, height: int) -> dict:
    tiles = _tile_grid_count(width, height, profile.max_tile, profile.tile_overlap)
    return {
        "name": profile.name,
        "description": profile.description,
        "strength": profile.strength,
        "passes": profile.passes,
        "steps": profile.steps,
        "max_tile": profile.max_tile,
        "tile_overlap": profile.tile_overlap,
        "guidance_scale": profile.guidance_scale,
        "estimated_tiles_per_pass": tiles,
        "estimated_total_tile_runs": tiles * profile.passes,
        "width": width,
        "height": height,
    }
