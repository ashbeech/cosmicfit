#!/usr/bin/env python3
"""
Cosmic Fit — Render a composed CosmicBlueprint JSON export as user-facing
markdown (SG-0 Phase 0b baseline snapshots; reused by SG-4 for after
snapshots so before/after diffs compare like with like).

The input JSON is a full composed blueprint as written by the production
pipeline test exports (`HardeningEdgeCaseTests.exportInputAfterFixtures` ->
docs/house_sect_regression/input_after/{id}.json, or the
`FixtureRegeneration` fixtures in docs/fixtures/).

Sections are rendered in the golden-guide order (Blueprint, Palette,
Textures, Occasions, Hardware, Code, Accessory, Pattern) with the same
subheadings the app displays (StyleGuideViewController), so baselines diff
cleanly against the golden ideal structure. Deterministic list data
(palette swatches, recommended metals/stones/patterns) is included beneath
the prose because it is user-visible in the app.

Usage:
  python3 tools/render_blueprint_markdown.py <blueprint.json> <output.md> --title "Maria (pre-overhaul baseline)"
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def colour_list(colours: list[dict]) -> str:
    parts = []
    for c in colours:
        name = c.get("name") or c.get("colourName") or "?"
        hexv = c.get("hex") or c.get("hexValue") or ""
        parts.append(f"{name} ({hexv})" if hexv else name)
    return ", ".join(parts)


def render(bp: dict, title: str, source: str) -> str:
    pal = bp["palette"]
    tex = bp["textures"]
    occ = bp["occasions"]
    hw = bp["hardware"]
    code = bp["code"]
    acc = bp["accessory"]
    pat = bp["pattern"]

    lines: list[str] = []
    a = lines.append

    a(f"# Your Cosmic Style Guide")
    a("")
    a(f"### {title}")
    a("")
    a(f"> Baseline snapshot rendered {datetime.now(timezone.utc).strftime('%Y-%m-%d')} from `{source}` "
      f"(engine {bp.get('engineVersion', '?')}, composed via the production BlueprintComposer pipeline). "
      f"Section order follows the golden-guide contract; subheadings match the app display.")
    a("")

    a("---\n")
    a("## 1. The Blueprint\n")
    a(bp["styleCore"]["narrativeText"].strip())
    a("")

    a("---\n")
    a("## 2. The Palette\n")
    a(pal["narrativeText"].strip())
    a("")
    a(f"**Palette family:** {pal.get('family', '?')}  ")
    variables = pal.get("variables", {})
    if variables:
        a("**Variables:** " + ", ".join(f"{k}={v}" for k, v in sorted(variables.items())) + "  ")
    a(f"**Neutrals:** {colour_list(pal.get('neutrals', []))}  ")
    a(f"**Core:** {colour_list(pal.get('coreColours', []))}  ")
    a(f"**Support:** {colour_list(pal.get('supportColours', []))}  ")
    a(f"**Accents:** {colour_list(pal.get('accentColours', []))}")
    a("")

    a("---\n")
    a("## 3. The Textures\n")
    a("### The Good\n")
    a(tex["goodText"].strip())
    a("")
    a("### The Bad\n")
    a(tex["badText"].strip())
    a("")
    a("### The Sweet Spot\n")
    a(tex["sweetSpotText"].strip())
    a("")
    if tex.get("recommendedTextures"):
        a(f"**Recommended:** {', '.join(tex['recommendedTextures'])}  ")
    if tex.get("avoidTextures"):
        a(f"**Avoid:** {', '.join(tex['avoidTextures'])}")
    a("")

    a("---\n")
    a("## 4. The Occasions\n")
    a("### At Work\n")
    a(occ["workText"].strip())
    a("")
    a("### Intimate Energy\n")
    a(occ["intimateText"].strip())
    a("")
    a("### Daily Movement\n")
    a(occ["dailyText"].strip())
    a("")

    a("---\n")
    a("## 5. The Hardware\n")
    a("### The Metals\n")
    a(hw["metalsText"].strip())
    a("")
    a("### The Stones\n")
    a(hw["stonesText"].strip())
    a("")
    a("### Tip\n")
    a(hw["tipText"].strip())
    a("")
    if hw.get("recommendedMetals"):
        a(f"**Recommended metals:** {', '.join(hw['recommendedMetals'])}  ")
    if hw.get("recommendedStones"):
        a(f"**Recommended stones:** {', '.join(hw['recommendedStones'])}")
    a("")

    a("---\n")
    a("## 6. The Code\n")
    a("### Lean Into\n")
    for item in code.get("leanInto", []):
        a(f"- {item}")
    a("")
    a("### Avoid\n")
    for item in code.get("avoid", []):
        a(f"- {item}")
    a("")
    a("### Consider\n")
    for item in code.get("consider", []):
        a(f"- {item}")
    a("")

    a("---\n")
    a("## 7. The Accessory\n")
    for para in acc.get("paragraphs", []):
        a(para.strip())
        a("")

    a("---\n")
    a("## 8. The Pattern\n")
    a(pat["narrativeText"].strip())
    a("")
    a("### Tip\n")
    a(pat["tipText"].strip())
    a("")
    if pat.get("recommendedPatterns"):
        a(f"**Recommended:** {', '.join(pat['recommendedPatterns'])}  ")
    if pat.get("avoidPatterns"):
        a(f"**Avoid:** {', '.join(pat['avoidPatterns'])}")
    a("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Render composed blueprint JSON to markdown")
    parser.add_argument("input", help="Composed blueprint JSON path")
    parser.add_argument("output", help="Output markdown path")
    parser.add_argument("--title", required=True, help="Display title for the snapshot")
    args = parser.parse_args()

    bp = json.loads(Path(args.input).read_text(encoding="utf-8"))
    md = render(bp, args.title, args.input)
    Path(args.output).write_text(md, encoding="utf-8")
    print(f"Wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
