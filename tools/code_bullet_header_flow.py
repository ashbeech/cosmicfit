#!/usr/bin/env python3
"""
Mechanically fix Code bullet section header flow in astrological_style_dataset.json
and optionally mirror replacements into generate_dataset.py and Swift fallbacks.

Usage:
  python3 tools/code_bullet_header_flow.py --apply
  python3 tools/code_bullet_header_flow.py --apply --mirror-generate-dataset
  python3 tools/code_bullet_header_flow.py --report-only
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DATASET_PATH = REPO_ROOT / "data" / "style_guide" / "astrological_style_dataset.json"
GENERATE_DATASET_PATH = REPO_ROOT / "tools" / "generate_dataset.py"
SWIFT_FALLBACK_PATH = REPO_ROOT / "Cosmic Fit" / "UI" / "ViewControllers" / "StyleGuideViewController.swift"
REPORT_PATH = REPO_ROOT / "docs" / "fixtures" / "code_header_flow_report.json"
BACKUP_DIR = REPO_ROOT / "data" / "style_guide" / "backups"

sys.path.insert(0, str(REPO_ROOT / "tools"))
from code_header_flow_rules import (  # noqa: E402
    auto_fix,
    header_flow_violation,
    section_kind_from_item,
)

# Manual overrides for edge cases mechanical transform cannot handle cleanly.
MANUAL_AVOID_FIXES: dict[str, str] = {
    "Refuse to disappear into safe, flat neutrals that make you blend into the walls, as head-to-toe beige is strictly for people who hate being seen.": (
        "Safe, flat neutrals that make you blend into the walls, as head-to-toe beige is strictly for people who hate being seen."
    ),
    "Stop trend-chasing at the expense of quality or longevity, because if a piece looks dated in two seasons, it was never worth buying.": (
        "Trend-chasing at the expense of quality or longevity, because if a piece looks dated in two seasons, it was never worth buying."
    ),
    "Stop obsessively overthinking the balance between beauty and strength, and simply trust your innate eye for proportion.": (
        "Obsessively overthinking the balance between beauty and strength instead of trusting your innate eye for proportion."
    ),
    "Stop swinging wildly between extreme sartorial indulgence and total deprivation when building out your core daily wardrobe.": (
        "Swinging wildly between extreme sartorial indulgence and total deprivation when building out your core daily wardrobe."
    ),
    "Stop letting pure idealism prevent you from acquiring the practical, sharply tailored outerwear you actually need.": (
        "Letting pure idealism prevent you from acquiring the practical, sharply tailored outerwear you actually need."
    ),
    "Stop your highly experimental styling from degrading into a visually confusing mess of poorly matched, clashing fabrics.": (
        "Highly experimental styling that degrades into a visually confusing mess of poorly matched, clashing fabrics."
    ),
    "Stop deliberately dressing down to fit in or avoid attention, because dimming your personal style to match the room always backfires emotionally.": (
        "Deliberately dressing down to fit in or avoid attention, because dimming your personal style to match the room always backfires emotionally."
    ),
    "Stop playing it safe with an invisible outfit when you were born to wear the boldest statement pieces.": (
        "Playing it safe with an invisible outfit when you were born to wear the boldest statement pieces."
    ),
    "Stop forcing a false choice between rigid tailoring and fluid beauty when your style demands both elements.": (
        "Forcing a false choice between rigid tailoring and fluid beauty when your style demands both elements."
    ),
    "Stop trend-chasing and focus entirely on building an edited rotation of luxurious, perfectly cut staples.": (
        "Trend-chasing instead of building an edited rotation of luxurious, perfectly cut staples."
    ),
    "Skip the disposable trends and invest your budget into beautiful, enduring pieces crafted from premium fabrics.": (
        "Disposable trends that divert your budget from beautiful, enduring pieces crafted from premium fabrics."
    ),
    "Walk away from cheap impulse purchases and fast-fashion trend-chasing that ultimately dilute your carefully built sartorial authority.": (
        "Cheap impulse purchases and fast-fashion trend-chasing that ultimately dilute your carefully built sartorial authority."
    ),
    "Halt the habit of wasting your budget on flimsy impulse purchases and fleeting micro-trends that lose their silhouette instantly.": (
        "The habit of wasting your budget on flimsy impulse purchases and fleeting micro-trends that lose their silhouette instantly."
    ),
    "Never wear anything dimmed or dull that forces you to hide in the background.": (
        "Anything dimmed or dull that forces you to hide in the background."
    ),
    "Quit hiding your most dramatic, beautifully constructed tailored pieces at the back of the wardrobe out of misplaced modesty.": (
        "Hiding your most dramatic, beautifully constructed tailored pieces at the back of the wardrobe out of misplaced modesty."
    ),
    "Eliminate any restrictive mindset that prevents you from wearing your most spectacular, voluminous pieces every single day.": (
        "Any restrictive mindset that prevents you from wearing your most spectacular, voluminous pieces every single day."
    ),
    "Drop those predictable, overwhelmingly safe clothing choices that completely stifle your natural instinct for sharp sartorial rebellion.": (
        "Predictable, overwhelmingly safe clothing choices that completely stifle your natural instinct for sharp sartorial rebellion."
    ),
    "Defend your wardrobe by refusing to compromise on garment construction and fabric finish simply for the sake of convenience.": (
        "Compromising on garment construction and fabric finish simply for the sake of convenience."
    ),
    "Prevent your contrasting textures from looking like unresolved, accidental styling mistakes by ensuring every clash is deliberate.": (
        "Contrasting textures that look like unresolved, accidental styling mistakes rather than deliberate clashes."
    ),
    "Refuse to dilute your outfits by failing to commit fully to either strict tailoring or soft fluidity.": (
        "Outfits diluted by failing to commit fully to either strict tailoring or soft fluidity."
    ),
    "Refuse to blend into the background for the sake of social ease, because stylistic conformity drains your energy far more than commanding attention ever could.": (
        "Blending into the background for the sake of social ease, because stylistic conformity drains your energy far more than commanding attention ever could."
    ),
    "Refuse to rush through any purchases without actually touching the fabric first. Your hands instinctively know infinitely more about genuine construction quality than any woven designer label.": (
        "Rushing through purchases without actually touching the fabric first, when your hands know more about construction quality than any woven designer label."
    ),
    "Refuse to wear rushed, thrown-together outfits that lack the tactile indulgence you truly crave.": (
        "Rushed, thrown-together outfits that lack the tactile indulgence you truly crave."
    ),
    "Refuse to tolerate careless finishing, missing buttons, or loose threads on any of your garments.": (
        "Careless finishing, missing buttons, or loose threads on any of your garments."
    ),
    "Refuse to buy into intentionally ugly fashion trends that sacrifice true beauty for sheer irony.": (
        "Intentionally ugly fashion trends that sacrifice true beauty for sheer irony."
    ),
    "Refuse to be invisible by rejecting muted tones that shrink your natural star power.": (
        "Muted tones that shrink your natural star power and leave you invisible in a crowded room."
    ),
    "Refuse sloppy finishes and poor tailoring that offend your incredibly sharp eye for pristine details.": (
        "Sloppy finishes and poor tailoring that offend your incredibly sharp eye for pristine details."
    ),
    "Refuse totally predictable twinsets and safe styling; inject some bold, well-travelled energy into your daily look.": (
        "Totally predictable twinsets and safe styling that drain the bold, well-travelled energy from your daily look."
    ),
    "Refuse trend pieces that sacrifice physical comfort for sheer novelty. Your body violently rejects restrictive construction much faster than your mind accepts a bargain.": (
        "Trend pieces that sacrifice physical comfort for sheer novelty, because your body rejects restrictive construction faster than your mind accepts a bargain."
    ),
}

LEAN_INTO_MANUAL: dict[str, str] = {
    "Collect authentic textile pieces from your global travels and wear their stories, as a rough indigo scarf from Kyoto carries more weight than any logo ever could.": (
        "Collecting authentic textile pieces from your global travels and wearing their stories, as a rough indigo scarf from Kyoto carries more weight than any logo ever could."
    ),
    "Combine your global textile references with absolute confidence. Bridge the continents in one outfit and own the cultural conversation.": (
        "Combining your global textile references with absolute confidence, bridging the continents in one outfit and owning the cultural conversation."
    ),
    "Control exactly what others see of your silhouette through highly deliberate wardrobe choices that reveal and conceal with surgical precision.": (
        "Controlling exactly what others see of your silhouette through highly deliberate wardrobe choices that reveal and conceal with surgical precision."
    ),
    "Designate a single, strategically chosen point of physical exposure. The severe thigh slit or the open collar should feel like a decision, not an accident.": (
        "Designating a single, strategically chosen point of physical exposure, whether a severe thigh slit or an open collar that feels like a decision, not an accident."
    ),
    "Include one piece of absolute drama in every outfit, even on quiet days, letting a velvet collar or a heavy chain do the talking.": (
        "Including one piece of absolute drama in every outfit, even on quiet days, letting a velvet collar or a heavy chain do the talking."
    ),
    "Treat sartorial innovation as a vital daily practice by experimenting with an exaggerated silhouette or a highly technical fabric to instantly shift your mood.": (
        "Treating sartorial innovation as a vital daily practice by experimenting with an exaggerated silhouette or a highly technical fabric to instantly shift your mood."
    ),
    "Choose intellectually stimulating pieces that reflect your ideas through unusual asymmetric construction and brilliantly clever hardware details.": (
        "Choosing intellectually stimulating pieces that reflect your ideas through unusual asymmetric construction and brilliantly clever hardware details."
    ),
    "Dress with passionate intention by clashing bold colours and embracing sharply cut silhouettes that demand attention.": (
        "Dressing with passionate intention by clashing bold colours and embracing sharply cut silhouettes that demand attention."
    ),
    "Exploit the creative visual tension between soft drapery and uncompromising, aggressively tailored hardware in your daily wardrobe.": (
        "Exploiting the creative visual tension between soft drapery and uncompromising, aggressively tailored hardware in your daily wardrobe."
    ),
    "Integrate fluid beauty and kinetic energy by choosing sharply tailored pieces that actually allow you to move.": (
        "Integrating fluid beauty and kinetic energy by choosing sharply tailored pieces that actually allow you to move."
    ),
    "Find genuine elegance by working within strict stylistic constraints to define your absolute sharpest and finest silhouette.": (
        "Finding genuine elegance by working within strict stylistic constraints to define your absolute sharpest and finest silhouette."
    ),
    "Express your inherent sartorial generosity through luxurious, tactile fabrics that bring joy to your daily interactions.": (
        "Expressing your inherent sartorial generosity through luxurious, tactile fabrics that bring joy to your daily interactions."
    ),
    "Trust your sudden style impulses and experiment confidently with unconventional silhouettes and unexpected metallic hardware.": (
        "Trusting your sudden style impulses and experimenting confidently with unconventional silhouettes and unexpected metallic hardware."
    ),
    "Channel your stylistic unpredictability into a distinct signature look completely grounded by brilliant, exacting tailoring.": (
        "Channeling your stylistic unpredictability into a distinct signature look completely grounded by brilliant, exacting tailoring."
    ),
    "Dress exclusively for the absolute dream version of yourself using ethereal, beautifully fluid silk fabrics.": (
        "Dressing exclusively for the absolute dream version of yourself using ethereal, beautifully fluid silk fabrics."
    ),
    "Edit your closet ruthlessly to ensure every single remaining garment delivers intentional, unashamed structural abundance.": (
        "Editing your closet ruthlessly to ensure every single remaining garment delivers intentional, unashamed structural abundance."
    ),
    "Embrace generous proportions, premium silk textiles, and intensely saturated colours that command immediate attention.": (
        "Embracing generous proportions, premium silk textiles, and intensely saturated colours that command immediate attention."
    ),
    "Let structural strength and a delicate beauty coexist by pairing heavy leather with your whisper-thin silk layers.": (
        "Letting structural strength and a delicate beauty coexist by pairing heavy leather with your whisper-thin silk layers."
    ),
    "Prioritise impeccable tailoring and enduring fabrics over a high volume of poorly constructed fast fashion.": (
        "Prioritising impeccable tailoring and enduring fabrics over a high volume of poorly constructed fast fashion."
    ),
}

CONSIDER_MANUAL: dict[str, str] = {
    "Adopt a signature comfort layer you return to daily. Make a heavy heritage cardigan or a worn leather jacket your emotional anchor piece.": (
        "Adopting a signature comfort layer you return to daily, whether a heavy heritage cardigan or a worn leather jacket as your emotional anchor piece."
    ),
    "Look for activewear-inspired details in your real clothes, like a technical zip or a stretch panel that signals movement without looking gym-ready.": (
        "Looking for activewear-inspired details in your real clothes, like a technical zip or a stretch panel that signals movement without looking gym-ready."
    ),
    "Conceal vibrant pops of colour in unexpected places. A bright silk jacket lining or a vivid sock peeking out adds depth without shouting.": (
        "Concealing vibrant pops of colour in unexpected places, like a bright silk jacket lining or a vivid sock peeking out that adds depth without shouting."
    ),
}


def _walk_dataset_fields(dataset: dict):
    for ps_key, entry in dataset.get("planet_sign", {}).items():
        if not isinstance(entry, dict):
            continue
        for field in ("code_leaninto", "code_avoid", "code_consider"):
            for i, text in enumerate(entry.get(field, []) or []):
                yield f"planet_sign.{ps_key}.{field}[{i}]", field, text
        for i, text in enumerate(entry.get("opposites", {}).get("mood", []) or []):
            yield f"planet_sign.{ps_key}.opposites.mood[{i}]", "opposites_mood", text

    for hp_key, entry in dataset.get("house_placements", {}).items():
        if not isinstance(entry, dict):
            continue
        for field in ("lean_into_bias", "code_consider_bias"):
            for i, text in enumerate(entry.get(field, []) or []):
                yield f"house_placements.{hp_key}.{field}[{i}]", field, text

    for asp_key, entry in dataset.get("aspects", {}).items():
        if not isinstance(entry, dict):
            continue
        for field in ("code_addition_leaninto", "code_addition_avoid"):
            val = entry.get(field, "")
            if val:
                yield f"aspects.{asp_key}.{field}", field, val


def _apply_manual_lookup(text: str, section: str) -> str | None:
    t = text.strip()
    if section == "avoid":
        return MANUAL_AVOID_FIXES.get(t)
    if section == "lean_into":
        return LEAN_INTO_MANUAL.get(t)
    if section == "consider":
        return CONSIDER_MANUAL.get(t)
    return None


def _fix_text(text: str, field_kind: str) -> tuple[str, str]:
    section = section_kind_from_item(field_kind, "")
    if section is None:
        return text, "skipped"

    manual = _apply_manual_lookup(text, section)
    if manual:
        return manual, "manual_map"

    new, changed, status = auto_fix(text, section)
    if status == "fixed" and changed:
        return new, "mechanical"
    if status == "ok":
        return text, "ok"
    # Retry avoid strip for edge phrase patterns
    if section == "avoid":
        from code_header_flow_rules import strip_avoid_redundant
        stripped, _ = strip_avoid_redundant(text)
        if header_flow_violation(stripped, section) is None:
            return stripped, "mechanical_phrase"
    return text, "unresolved"


def process_dataset(dataset: dict, *, apply: bool = False) -> tuple[dict, list[dict]]:
    changes: list[dict] = []
    unresolved: list[dict] = []

    for path, field_kind, old in _walk_dataset_fields(dataset):
        section = section_kind_from_item(field_kind, "")
        if section is None:
            continue
        if header_flow_violation(old, section) is None:
            continue

        new, method = _fix_text(old, field_kind)
        if new != old and header_flow_violation(new, section) is None:
            if apply:
                _set_path(dataset, path, new)
            changes.append({"path": path, "section": section, "method": method, "old": old, "new": new})
        else:
            unresolved.append({"path": path, "section": section, "text": old})

    return dataset, changes + [{"unresolved": unresolved}]


def _set_path(dataset: dict, path: str, value: str):
    parts = path.split(".")
    if parts[0] == "aspects":
        key = parts[1]
        field = parts[2]
        dataset["aspects"][key][field] = value
        return

    obj = dataset
    for part in parts[:-1]:
        if "[" in part:
            name, idx = part[:-1].split("[")
            obj = obj[name][int(idx)]
        else:
            obj = obj[part]
    last = parts[-1]
    if "[" in last:
        name, idx = last[:-1].split("[")
        obj[name][int(idx)] = value
    else:
        obj[last] = value


def mirror_replacements_to_file(file_path: Path, replacements: list[tuple[str, str]]) -> int:
    if not file_path.exists():
        return 0
    content = file_path.read_text(encoding="utf-8")
    count = 0
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            count += 1
    if count:
        file_path.write_text(content, encoding="utf-8")
    return count


def fix_swift_fallbacks() -> list[dict]:
    """Apply known fallback fixes per plan."""
    fixes = [
        (
            "Reject flimsy, disposable synthetic fabrics that completely lack structural integrity or a decent tactile finish.",
            "Flimsy, disposable synthetic fabrics that completely lack structural integrity or a decent tactile finish.",
        ),
        (
            "Introduce heavy statement hardware and exaggerated silhouettes to act as immediate conversation starters in your daily routine.",
            "Introducing heavy statement hardware and exaggerated silhouettes to act as immediate conversation starters in your daily routine.",
        ),
        (
            "Dress your physical living space in the exact same rich, tactile fabrics you wear to fuel your creative output.",
            "Dressing your physical living space in the exact same rich, tactile fabrics you wear to fuel your creative output.",
        ),
    ]
    changes = []
    content = SWIFT_FALLBACK_PATH.read_text(encoding="utf-8")
    for old, new in fixes:
        if old in content:
            content = content.replace(old, new)
            changes.append({"old": old, "new": new})
    if changes:
        SWIFT_FALLBACK_PATH.write_text(content, encoding="utf-8")
    return changes


def backup_dataset():
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%SZ")
    dest = BACKUP_DIR / f"pre_header_flow_{ts}"
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(DATASET_PATH, dest / "astrological_style_dataset.json")
    print(f"Backup: {dest / 'astrological_style_dataset.json'}")


def main():
    parser = argparse.ArgumentParser(description="Fix Code bullet section header flow")
    parser.add_argument("--apply", action="store_true", help="Write fixes to dataset")
    parser.add_argument("--mirror-generate-dataset", action="store_true")
    parser.add_argument("--fix-swift", action="store_true")
    parser.add_argument("--report-only", action="store_true")
    args = parser.parse_args()

    with open(DATASET_PATH, encoding="utf-8") as f:
        dataset = json.load(f)

    if args.apply:
        backup_dataset()

    _, results = process_dataset(dataset, apply=args.apply)
    unresolved = results[-1].get("unresolved", [])
    changes = [r for r in results if "path" in r]

    # Second pass for remaining unresolved
    if unresolved and args.apply:
        for item in list(unresolved):
            path = item["path"]
            if "opposites.mood" in path:
                fk = "opposites_mood"
            elif "lean_into_bias" in path:
                fk = "lean_into_bias"
            elif "code_consider_bias" in path:
                fk = "code_consider_bias"
            elif "code_addition_leaninto" in path:
                fk = "code_addition_leaninto"
            elif "code_addition_avoid" in path:
                fk = "code_addition_avoid"
            elif "code_leaninto" in path:
                fk = "code_leaninto"
            elif "code_avoid" in path:
                fk = "code_avoid"
            else:
                fk = "code_consider"

            new, method = _fix_text(item["text"], fk)
            section = item["section"]
            if new != item["text"] and header_flow_violation(new, section) is None:
                _set_path(dataset, path, new)
                changes.append({"path": path, "section": section, "method": method, "old": item["text"], "new": new})
                unresolved.remove(item)

    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "changes_count": len(changes),
        "unresolved_count": len(unresolved),
        "changes": changes,
        "unresolved": unresolved,
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"Changes: {len(changes)}, Unresolved: {len(unresolved)}")
    print(f"Report: {REPORT_PATH}")

    if args.apply:
        with open(DATASET_PATH, "w", encoding="utf-8") as f:
            json.dump(dataset, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"Updated {DATASET_PATH}")

        if args.mirror_generate_dataset:
            pairs = [(c["old"], c["new"]) for c in changes]
            n = mirror_replacements_to_file(GENERATE_DATASET_PATH, pairs)
            print(f"Mirrored {n} replacements into generate_dataset.py")

    if args.fix_swift or args.apply:
        swift_changes = fix_swift_fallbacks()
        print(f"Swift fallback fixes: {len(swift_changes)}")

    if unresolved:
        print("\nUnresolved samples:")
        for u in unresolved[:10]:
            print(f"  {u['path']}: {u['text'][:70]}…")
        if args.apply:
            sys.exit(1)

    return 0


if __name__ == "__main__":
    sys.exit(main())
