#!/usr/bin/env python3
"""
Cosmic Fit — JSON dot-path utilities for the content audit pipeline.

Parses paths like "house_placements.venus_house_1.lean_into_bias[0]"
and provides get/set/exists operations on nested dicts/lists.
"""

from __future__ import annotations

import re
from typing import Any

_INDEX_RE = re.compile(r"^(.+?)\[(\d+)\]$")


def parse_path(path: str) -> list[str | int]:
    """Parse a dot-path into a list of string keys and integer indices.

    Examples:
        "planet_sign.venus_aries.textures.good[0]"
        → ["planet_sign", "venus_aries", "textures", "good", 0]

        "house_placements.venus_house_1.lean_into_bias[0]"
        → ["house_placements", "venus_house_1", "lean_into_bias", 0]
    """
    tokens: list[str | int] = []
    for segment in path.split("."):
        m = _INDEX_RE.match(segment)
        if m:
            tokens.append(m.group(1))
            tokens.append(int(m.group(2)))
        else:
            tokens.append(segment)
    return tokens


def get_at_path(obj: Any, path: str) -> Any:
    """Retrieve the value at a dot-path. Returns _MISSING sentinel on failure."""
    tokens = parse_path(path)
    cur = obj
    for token in tokens:
        try:
            if isinstance(token, int):
                cur = cur[token]
            else:
                cur = cur[token]
        except (KeyError, IndexError, TypeError):
            return _MISSING
    return cur


def set_at_path(obj: Any, path: str, value: Any) -> bool:
    """Set the value at a dot-path. Returns True on success, False if path is invalid."""
    tokens = parse_path(path)
    if not tokens:
        return False
    cur = obj
    for token in tokens[:-1]:
        try:
            if isinstance(token, int):
                cur = cur[token]
            else:
                cur = cur[token]
        except (KeyError, IndexError, TypeError):
            return False
    last = tokens[-1]
    try:
        if isinstance(last, int):
            cur[last] = value
        else:
            cur[last] = value
        return True
    except (IndexError, TypeError):
        return False


def path_exists(obj: Any, path: str) -> bool:
    """Return True if the path resolves to a value (including None)."""
    return get_at_path(obj, path) is not _MISSING


class _MissingSentinel:
    """Sentinel for missing values distinct from None."""
    def __repr__(self) -> str:
        return "<MISSING>"
    def __bool__(self) -> bool:
        return False


_MISSING = _MissingSentinel()
