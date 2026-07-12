#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 cluster renderer (review aid, NOT the production path).

Renders a cache-v2 cluster into a readable composed style guide for the SG-3
human-review diff pack. Group B placeholder tokens are filled with the bucket's
REPRESENTATIVE resolved values (ranked-table colours/textures + strategy-based
metal/stone/pattern defaults) so the prose reads naturally. The real app fills
these per-user via NarrativeTemplateRenderer; this approximation is honest at the
coarse-bucket level and is for review only.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sg_profile import coarse_profile_from_key
import sg_generate as G

REPO_ROOT = Path(__file__).resolve().parent.parent
RANKED = json.loads((REPO_ROOT / "data" / "style_guide" / "ranked_domain_tables.json").read_text())

_PH = re.compile(r"\{([a-z_0-9]+)\}")

_BAD_TEXTURES = ["stiff polyester", "cheap acrylic", "low-grade viscose"]
_SWEET = ["structure", "softness"]
_METALS_BY_STRATEGY = {
    "warmDominant": ["aged brass", "antique gold", "warm bronze"],
    "coolDominant": ["matt silver", "gunmetal", "pewter"],
    "dualRegister": ["yellow gold", "rose gold", "matt silver"],
    "mixedFree": ["mixed gold and silver", "brushed steel", "brass"],
}
_PERSONAL = ["yellow gold", "rose gold"]
_STRUCTURAL = ["matt silver", "gunmetal"]
_EXCLUDED_FINISH = "high-shine polished chrome"
_STONES = ["deep garnet", "smoky quartz", "black onyx"]
_PATTERNS_BY_REG = {
    "quietLuxury": ["herringbone", "subtle houndstooth", "fine check", "tonal watercolour"],
    "boldExpression": ["bold stripe", "graphic check", "large geometric", "high-contrast print"],
    "versatileAdaptive": ["fine pinstripe", "small geometric", "tonal grid", "micro-check"],
}
_AVOID_PATTERN = ["novelty print", "loud animal print"]


def _fill_map(p) -> dict:
    lane = "water_dominant" if p.dominant_element == "water" else p.aesthetic_register
    ck = f"{p.temperature}_{lane}"
    colours = RANKED["colours_by_role"].get(ck, {})
    neutrals = [c["name"] for c in colours.get("neutrals", [])]
    accents = [c["name"] for c in colours.get("accents", [])]
    relief = [c["name"] for c in colours.get("relief", [])]
    textures = [t["name"] for t in sorted(RANKED["textures"].get(lane, []), key=lambda r: r.get("rank", 99))]
    metals = _METALS_BY_STRATEGY.get(p.metal_strategy, _METALS_BY_STRATEGY["coolDominant"])
    patterns = _PATTERNS_BY_REG.get(p.aesthetic_register, _PATTERNS_BY_REG["versatileAdaptive"])

    m: dict[str, str] = {}
    for i in range(1, 5):
        m[f"core_colour_{i}"] = neutrals[i - 1] if i - 1 < len(neutrals) else (neutrals[-1] if neutrals else "neutral")
        m[f"neutral_colour_{i}"] = m[f"core_colour_{i}"]
        m[f"texture_good_{i}"] = textures[i - 1] if i - 1 < len(textures) else (textures[-1] if textures else "wool")
        m[f"recommended_pattern_{i}"] = patterns[i - 1] if i - 1 < len(patterns) else patterns[-1]
    for i in range(1, 5):
        m[f"accent_colour_{i}"] = accents[(i - 1) % len(accents)] if accents else "accent"
    for i in range(1, 4):
        m[f"texture_bad_{i}"] = _BAD_TEXTURES[(i - 1) % len(_BAD_TEXTURES)]
        m[f"metal_{i}"] = metals[(i - 1) % len(metals)]
        m[f"stone_{i}"] = _STONES[(i - 1) % len(_STONES)]
    for i in range(1, 3):
        m[f"avoid_pattern_{i}"] = _AVOID_PATTERN[(i - 1) % len(_AVOID_PATTERN)]
        m[f"personal_metal_{i}"] = _PERSONAL[(i - 1) % len(_PERSONAL)]
        m[f"structural_metal_{i}"] = _STRUCTURAL[(i - 1) % len(_STRUCTURAL)]
        m[f"sweet_spot_keyword_{i}"] = _SWEET[(i - 1) % len(_SWEET)]
    m["excluded_finish"] = _EXCLUDED_FINISH
    m["temperature"] = p.temperature
    for extra in ("family", "cluster", "depth", "saturation", "contrast", "surface"):
        m.setdefault(extra, extra)
    m["relief_colour"] = relief[0] if relief else "a soft relief tone"
    return m


def _fill(text: str, fills: dict) -> str:
    return _PH.sub(lambda mo: fills.get(mo.group(1), f"[{mo.group(1)}]"), text)


COMPOSED = [
    ("1. The Blueprint", ["style_core"]),
    ("2. The Palette", ["palette_narrative"]),
    ("3. The Textures", ["textures_good", "textures_bad", "textures_sweet_spot"]),
    ("4. The Occasions", ["occasions_work", "occasions_intimate", "occasions_daily"]),
    ("5. The Hardware", ["hardware_metals", "hardware_stones", "hardware_tip"]),
    ("7. The Accessory", ["accessory_1", "accessory_2", "accessory_3"]),
    ("8. The Pattern", ["pattern_narrative", "pattern_tip"]),
]


def render(cache: dict, cluster_key: str, filled: bool = True) -> str:
    p = coarse_profile_from_key(cluster_key)
    obj = cache[cluster_key]
    fills = _fill_map(p) if filled else {}
    out: list[str] = [f"# Composed Style Guide — {cluster_key}",
                      f"_register={p.aesthetic_register} | temperature={p.temperature} | "
                      f"metals={p.metal_strategy} | finish={p.finish_lane} | "
                      f"orientation={p.orientation}_",
                      f"**coreFormula:** {obj.get('coreFormula','(none)')}\n"]
    for title, keys in COMPOSED:
        out.append(f"\n## {title}\n")
        for k in keys:
            sec = obj.get(k)
            if not isinstance(sec, dict):
                out.append(f"_[missing: {k}]_\n")
                continue
            if sec.get("sectionIntro"):
                out.append(f"_{_fill(sec['sectionIntro'], fills)}_\n")
            out.append(_fill(sec.get("text", ""), fills) + "\n")
            if sec.get("rankedItems"):
                for r in sec["rankedItems"]:
                    uc = f": {r['useCase']}" if r.get("useCase") else ""
                    out.append(f"- **{r['name']}** ({r['role']}){uc}")
                out.append("")
            for t in sec.get("tests", []):
                out.append(f"> Test: {t}")
            for tr in sec.get("traps", []):
                out.append(f"> Trap: {tr['failure']} → Fix: {tr['fix']}")
    if obj.get("closing"):
        out.append(f"\n---\n\n_{_fill(obj['closing'], fills)}_")
    return "\n".join(out)


if __name__ == "__main__":
    cache_path = Path(sys.argv[1])
    cluster_key = sys.argv[2]
    cache = json.loads(cache_path.read_text())
    print(render(cache, cluster_key))
