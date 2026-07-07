#!/usr/bin/env python3
"""SG-2 Phase 2a: migrate `planet_sign[*].metals` from plain strings to objects.

Each metal string becomes `{"name", "register", "finish"}`:
  register ∈ {personal, structural, either}
  finish   ∈ {polished, matte, brushed, aged}

Classification is a pure, deterministic keyword function (recorded here so the
migration is reproducible and auditable for the SG-2 freeze). Human-readable
names are preserved verbatim as `name`. Idempotent: entries already in object
form are passed through unchanged.

Usage:
    python3 tools/migrate_metals.py            # rewrite the dataset in place
    python3 tools/migrate_metals.py --report   # print the classification, no write
"""
import json
import sys
from pathlib import Path

DATASET = Path(__file__).resolve().parent.parent / "data/style_guide/astrological_style_dataset.json"

EITHER_KW = ["mixed", "iridescent", "pearl", "opal", "anodised"]
STRUCTURAL_KW = ["silver", "platinum", "steel", "titanium", "gunmetal",
                 "white gold", "aluminium", "iron", "pewter", "chrome"]
PERSONAL_KW = ["gold", "brass", "bronze", "copper", "honey", "sienna", "umber"]

AGED_KW = ["aged", "antique", "oxidis", "oxidiz", "blackened", "hammered", "dark ", "deep "]
BRUSHED_KW = ["brushed"]
POLISHED_KW = ["polished", "bright", "gilded", "sterling", "recycled",
               "innovative", "surgical", "iridescent"]


def classify(name: str):
    l = name.lower()
    # Register — either > white-gold guard > structural > personal > either.
    if any(k in l for k in EITHER_KW):
        register = "either"
    elif "white gold" in l:
        register = "structural"
    elif any(k in l for k in STRUCTURAL_KW):
        register = "structural"
    elif any(k in l for k in PERSONAL_KW):
        register = "personal"
    else:
        register = "either"
    # Finish — aged > brushed > polished > matte (default).
    if any(k in l for k in AGED_KW):
        finish = "aged"
    elif any(k in l for k in BRUSHED_KW):
        finish = "brushed"
    elif any(k in l for k in POLISHED_KW):
        finish = "polished"
    else:
        finish = "matte"
    return register, finish


def migrate_entry(metals):
    out = []
    for m in metals:
        if isinstance(m, dict):
            out.append(m)  # already migrated
            continue
        register, finish = classify(m)
        out.append({"name": m, "register": register, "finish": finish})
    return out


def main():
    report_only = "--report" in sys.argv
    data = json.loads(DATASET.read_text())
    ps = data["planet_sign"]

    distinct = {}
    changed = 0
    for key, entry in ps.items():
        metals = entry.get("metals", [])
        for m in metals:
            if isinstance(m, str):
                distinct[m] = classify(m)
        new_metals = migrate_entry(metals)
        if new_metals != metals:
            changed += 1
        entry["metals"] = new_metals

    if report_only:
        for name in sorted(distinct):
            reg, fin = distinct[name]
            print(f"  {name:24s} -> register={reg:11s} finish={fin}")
        print(f"\n{len(distinct)} distinct metals; {changed} planet_sign entries updated.")
        return

    DATASET.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"Migrated {len(distinct)} distinct metals across {changed} planet_sign entries.")
    print(f"Wrote {DATASET}")


if __name__ == "__main__":
    main()
