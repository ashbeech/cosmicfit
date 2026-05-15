#!/usr/bin/env python3
"""
SynthID remover dispatcher.

Modes:
- diffusion (default): quality-first production path
- legacy: previous multi-transform fallback
"""

from __future__ import annotations

import argparse
import sys

import remove_synthid_diffusion
import remove_synthid_legacy


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Dispatch SynthID removal to diffusion or legacy mode"
    )
    parser.add_argument(
        "--mode",
        choices=["diffusion", "legacy"],
        default="diffusion",
        help="Processing mode (default: diffusion)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    mode_args, passthrough = build_parser().parse_known_args(argv)

    if mode_args.mode == "diffusion":
        return remove_synthid_diffusion.main(passthrough)
    return remove_synthid_legacy.main(passthrough)


if __name__ == "__main__":
    sys.exit(main())
