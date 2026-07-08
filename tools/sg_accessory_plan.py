#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 accessoryCategoryPlan (Phase 3e).

Turns the frozen ranked `accessory_specs` table (keyed by
<register>_<orientation>_<finishLane>) into a per-chart plan that maps the
chart's INCLUDE categories onto the 3 accessory cache slots
(accessory_1/2/3) in priority order, MERGING the lowest-priority pair into
one slot when a profile justifies more than 3 categories, and never naming
OMIT categories.

Default overflow policy is MERGE (fold the 4th category into slot 3), chosen
over extending the cache keys so the SG-2 injection-contract freeze stays
closed (documented in the SG-3 human-review notes).

The plan is chart-conditional by construction: Slate (quietLuxury /
selfContained / muted) gets Handbags + Scarves + Belts + Keepsake jewellery;
a boldExpression / polished chart gets Statement jewellery + Footwear +
Structured bags and OMITS Scarves; etc.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RANKED_TABLES = REPO_ROOT / "data" / "style_guide" / "ranked_domain_tables.json"

_TABLES_CACHE: dict | None = None


def _accessory_specs(path: Path = RANKED_TABLES) -> dict:
    global _TABLES_CACHE
    if _TABLES_CACHE is None:
        with open(path) as f:
            _TABLES_CACHE = json.load(f)["accessory_specs"]
    return _TABLES_CACHE


def accessory_plan(register: str, orientation: str, finish_lane: str,
                   path: Path = RANKED_TABLES) -> dict:
    """Returns the accessoryCategoryPlan for a coarse profile.

    Shape:
      {
        "table_key": "...",
        "slots": [ {slot:1, categories:[{category,material,finish,reason,merged:bool}]}, ... ],
        "include": [ {category, slot, material, finish, reason, decision} ],
        "omit":    [ {category, decision:"omit", reason} ],
        "overflow_merged": bool
      }
    """
    key = f"{register}_{orientation}_{finish_lane}"
    specs = _accessory_specs(path)
    table = specs.get(key)
    if table is None:
        raise KeyError(f"no accessory_specs table for {key!r}")

    categories = table["categories"]
    includes = [c for c in categories if c["decision"] == "include"]
    omits = [c for c in categories if c["decision"] == "omit"]

    # Slot assignment (priority = table order).
    slots: list[dict] = []
    overflow_merged = False
    if len(includes) <= 3:
        for i, cat in enumerate(includes):
            slots.append({"slot": i + 1, "categories": [_cat_entry(cat, merged=False)]})
        # Pad to 3 slots only if fewer than 3 includes (defensive; table min is 3).
    else:
        # First two categories occupy slots 1 and 2 solo; remaining categories
        # (>=2) merge into slot 3.
        slots.append({"slot": 1, "categories": [_cat_entry(includes[0], merged=False)]})
        slots.append({"slot": 2, "categories": [_cat_entry(includes[1], merged=False)]})
        merged = [_cat_entry(c, merged=True) for c in includes[2:]]
        slots.append({"slot": 3, "categories": merged})
        overflow_merged = True

    # Flat include/omit views for prompt + validation.
    include_flat: list[dict] = []
    for s in slots:
        for cat in s["categories"]:
            include_flat.append({
                "category": cat["category"],
                "slot": s["slot"],
                "material": cat["material"],
                "finish": cat["finish"],
                "reason": cat["reason"],
                "decision": "merge" if cat["merged"] else "include",
            })
    omit_flat = [{"category": c["category"], "decision": "omit",
                  "reason": c.get("reason", "off-lane for this chart")} for c in omits]

    return {
        "table_key": key,
        "slots": slots,
        "include": include_flat,
        "omit": omit_flat,
        "overflow_merged": overflow_merged,
    }


def _cat_entry(cat: dict, merged: bool) -> dict:
    return {
        "category": cat["category"],
        "material": cat.get("material", ""),
        "finish": cat.get("finish", ""),
        "reason": cat.get("reason", ""),
        "merged": merged,
    }


def plan_for_slot(plan: dict, slot: int) -> list[dict]:
    """Categories assigned to a given accessory cache slot (1, 2 or 3)."""
    for s in plan["slots"]:
        if s["slot"] == slot:
            return s["categories"]
    return []


if __name__ == "__main__":
    import sys
    sys.path.insert(0, str(REPO_ROOT / "tools"))
    from sg_profile import coarse_profile_from_key

    demo_keys = {
        "Slate (quiet/self/muted)": "venus_taurus__moon_capricorn__earth_dominant",
        "Cinder (bold/self/polished)": "venus_leo__moon_aries__fire_dominant",
        "Zephyr (versatile/community/mixed)": "venus_gemini__moon_aquarius__air_dominant",
        "Cove (quiet/self/muted, water)": "venus_cancer__moon_scorpio__water_dominant",
    }
    for label, key in demo_keys.items():
        prof = coarse_profile_from_key(key)
        plan = accessory_plan(prof.aesthetic_register, prof.orientation, prof.finish_lane)
        cats = [f"{i['category']}(s{i['slot']},{i['decision']})" for i in plan["include"]]
        omits = [o["category"] for o in plan["omit"]]
        print(f"{label}: key={plan['table_key']} merged={plan['overflow_merged']}")
        print(f"    include: {cats}")
        print(f"    omit:    {omits}")
