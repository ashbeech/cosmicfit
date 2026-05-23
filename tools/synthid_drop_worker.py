#!/usr/bin/env python3
"""
Worker subprocess for synthid_drop_tool.py.
Loads the ML pipeline and processes one image; writes status + log to disk.
Uses image-adaptive profiles from scripts/synthid_profiles.py (auto by default).
"""

from __future__ import annotations

import argparse
import json
import sys
import traceback
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

from remove_synthid_diffusion import _get_pipeline, img2img_denoise  # noqa: E402
from remove_synthid_originals import load_image, save_image  # noqa: E402
from synthid_profiles import profile_for_image, profile_summary  # noqa: E402


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _read_job(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def _write_status(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def _log(log_path: Path, line: str) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as f:
        f.write(line.rstrip() + "\n")
        f.flush()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inbox", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--job-file", required=True)
    parser.add_argument("--log-file", required=True)
    parser.add_argument("--job-id", required=True)
    parser.add_argument(
        "--profile",
        default="auto",
        help="Profile name: auto (default), large_original, batch_legacy, card, silk",
    )
    args = parser.parse_args()

    job_path = Path(args.job_file)
    log_path = Path(args.log_file)
    inbox = Path(args.inbox)
    output = Path(args.output)

    def update(status: str, message: str, **extra) -> None:
        payload = {
            **_read_job(job_path),
            "id": args.job_id,
            "status": status,
            "message": message,
            "basename": inbox.name,
            "inbox_basename": inbox.name,
            "output_basename": output.name,
            "inbox_path": str(inbox),
            "output_path": str(output),
            "log_path": str(log_path),
            "updated_at": _utc_now(),
            **extra,
        }
        _write_status(job_path, payload)

    log_path.write_text("", encoding="utf-8")
    update("loading_model", "Loading SD 1.5 img2img pipeline…")
    _log(log_path, f"[{_utc_now()}] Loading pipeline…")

    try:
        rgb, alpha, orig_mode = load_image(str(inbox))
        h, w = rgb.shape[:2]
        profile = profile_for_image(w, h, basename=inbox.name, profile_name=args.profile)
        summary = profile_summary(profile, w, h)
        update(
            "loading_model",
            f"Profile: {profile.name} — {profile.max_tile}px tiles, "
            f"{profile.passes} passes, {profile.steps} steps",
            profile=summary,
        )
        _log(log_path, f"[{_utc_now()}] {profile.description}")
        _log(
            log_path,
            f"[{_utc_now()}] ~{summary['estimated_total_tile_runs']} tile runs total "
            f"({summary['estimated_tiles_per_pass']} tiles × {profile.passes} passes)",
        )

        _get_pipeline()
        update(
            "processing",
            f"Pass 1/{profile.passes} starting…",
            progress={"percent": 0, "passes": profile.passes},
        )

        def on_progress(pass_num: int, pass_total: int, tile_num: int, tile_total: int) -> None:
            done = (pass_num - 1) * tile_total + tile_num
            total = pass_total * tile_total
            pct = round(100.0 * done / max(total, 1), 1)
            msg = f"Pass {pass_num}/{pass_total} · tile {tile_num}/{tile_total} ({pct}%)"
            progress = {
                "pass": pass_num,
                "passes": pass_total,
                "tile": tile_num,
                "tiles": tile_total,
                "percent": pct,
            }
            update("processing", msg, progress=progress, profile=summary)
            _log(log_path, f"[{_utc_now()}] {msg}")

        out_rgb = img2img_denoise(
            rgb,
            strength=profile.strength,
            num_steps=profile.steps,
            guidance_scale=profile.guidance_scale,
            max_tile=profile.max_tile,
            overlap=profile.tile_overlap,
            on_progress=on_progress,
        )
        save_image(str(output), out_rgb, alpha, orig_mode)
        _log(log_path, f"[{_utc_now()}] Saved → {output}")

        update(
            "done",
            "Complete",
            finished_at=_utc_now(),
            progress={"percent": 100},
            profile=summary,
        )
        _log(log_path, f"[{_utc_now()}] Done")
        return 0
    except Exception as exc:
        tb = traceback.format_exc()
        _log(log_path, f"[{_utc_now()}] ERROR: {exc}\n{tb}")
        update("error", str(exc), error_detail=tb, finished_at=_utc_now())
        return 1


if __name__ == "__main__":
    sys.exit(main())
