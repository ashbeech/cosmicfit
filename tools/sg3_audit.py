#!/usr/bin/env python3
"""
Cosmic Fit — SG-3 deep quality audit (post-run defect hunt).

Goes far beyond the write gate. Scans a regenerated cache-v2 file for EVERY
class of defect we care about before the gate, reporting counts + examples per
category so we can drive the output toward flawless. Categories:

  A. Group-B literal-name leakage (colours / fibres / patterns / metals / stones
     appearing as literal words outside placeholders) — the class that slipped
     past the original gate.
  B. Placeholder correctness (required placeholders present, Group-A purity,
     unknown tokens).
  C. Cross-cluster phrase stamping (n-grams appearing in a high fraction of
     clusters = candidate new tics).
  D. Example copying (a section reproducing a golden section_examples excerpt).
  E. Formula placement (verbatim in blueprint/occasions_daily, final term in
     accessory_1, closing ends with formula).
  F. Palette temperature-word agreement.
  G. British-spelling violations (matte/color/gray/jewelry...).
  H. Length outliers, concrete-noun floor, filler over cap.
  I. Accessory omitted-category leakage.
  J. Duplicate identical section text across clusters.

Usage: python3 tools/sg3_audit.py --cache <cache.json> [--json]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sg_validation as V
import sg_generate as G
from sg_profile import coarse_profile_from_key
from sg_accessory_plan import accessory_plan

REPO_ROOT = Path(__file__).resolve().parent.parent
RT = json.loads((REPO_ROOT / "data" / "style_guide" / "ranked_domain_tables.json").read_text())
EX = json.loads((REPO_ROOT / "data" / "style_guide" / "section_examples.json").read_text())["section_examples"]

_PH = re.compile(r"\{[a-z_0-9]+\}")
AMERICAN = ["matte", "color", "colored", "center", "gray", "jewelry", "organize",
            "realize", "recognize", "favorite", "flavor", "behavior", "traveler"]


def _colour_names() -> set[str]:
    names = set()
    for tbl in RT["colours_by_role"].values():
        for grp in ("neutrals", "accents", "relief"):
            for x in tbl.get(grp, []):
                names.add(x["name"].lower())
    return names


def _fibre_names() -> set[str]:
    return {x["name"].lower() for tbl in RT["textures"].values() for x in tbl}


COLOUR_NAMES = _colour_names()
FIBRE_NAMES = _fibre_names()


def _strip_ph(text: str) -> str:
    return _PH.sub(" ", text.lower())


def _leak(text: str, names: set[str]) -> list[str]:
    low = _strip_ph(text)
    return sorted({n for n in names if re.search(r"\b" + re.escape(n) + r"\b", low)})


def audit(cache: dict) -> dict:
    keys = [k for k in cache if k != "schema_version" and isinstance(cache[k], dict)
            and cache[k].get("closing")]
    findings: dict = defaultdict(list)
    # For stamping / duplicates
    section_texts: dict[str, list[tuple[str, str]]] = defaultdict(list)  # section -> [(cluster,text)]
    intro_counter: Counter = Counter()
    ngram_cluster: dict[str, set[str]] = defaultdict(set)
    ngram_by_reg: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    reg_counts: Counter = Counter()

    for k in keys:
        prof = coarse_profile_from_key(k)
        obj = cache[k]
        for sk, sec in obj.items():
            if sk in ("coreFormula", "closing") or not isinstance(sec, dict):
                continue
            text = sec.get("text", "")
            section_texts[sk].append((k, text))
            intro = sec.get("sectionIntro", "")
            if intro:
                intro_counter[intro.strip()] += 1

            # A. literal leakage — ALL Group B sections, via the SAME gate
            # function (pass-over-aware for palette), so the audit is never
            # weaker than the write gate.
            allowed = G.pass_over_for_palette(prof) if sk == "palette_narrative" else []
            lk = V.find_literal_leaks(text, sk, allowed)
            if lk:
                findings["A_literal_leak"].append((k, sk, lk[:6]))

            # B. placeholder correctness
            toks = re.findall(r"\{([a-z_0-9]+)\}", text)
            if sk in V.GROUP_A_SECTIONS and toks:
                findings["B_groupA_has_placeholder"].append((k, sk, toks[:4]))
            unknown = [t for t in toks if t not in V.ALLOWED_PLACEHOLDERS]
            if unknown:
                findings["B_unknown_placeholder"].append((k, sk, unknown))
            if sk in V.GROUP_B_SECTIONS and not toks:
                findings["B_groupB_no_placeholder"].append((k, sk))

            # G. spelling
            low = text.lower()
            am = [w for w in AMERICAN if re.search(r"\b" + w + r"\b", low)]
            if am:
                findings["G_american_spelling"].append((k, sk, am))

            # H. length + concreteness
            wc = len(text.split())
            if wc < 40:
                findings["H_too_short"].append((k, sk, wc))
            if wc > 220:
                findings["H_too_long"].append((k, sk, wc))
            nfill, hits = V.filler_count(text)
            if nfill > V.load_rules()["filler_lexicon"]["cap_per_section"]:
                findings["H_filler_over_cap"].append((k, sk, hits))

            # intro hygiene (intros are cached + displayed; gate them too)
            if intro:
                for nm, fn in [("dash", V.find_dashes), ("tic", V.find_banned_tics),
                               ("us_spelling", V.find_american_spellings)]:
                    if fn(intro):
                        findings["K_intro_hygiene"].append((k, sk, nm, fn(intro)[:3]))
                if sk == "palette_narrative" and V.find_season_words(intro):
                    findings["K_intro_hygiene"].append((k, sk, "season", V.find_season_words(intro)[:3]))
                il = V.find_literal_leaks(intro, sk, allowed)
                if il:
                    findings["K_intro_leak"].append((k, sk, il[:4]))

            # C. n-gram stamping (6-grams), placeholder-stripped, tracked per
            # distinct cluster globally AND per register.
            stripped = _PH.sub(" ", text)
            for g in set(V.ngrams(stripped, 6)):
                if V._is_content_phrase(g):
                    ngram_cluster[g].add(k)
                    ngram_by_reg[prof.aesthetic_register][g].add(k)

            # D. example copying
            for ex in EX.get(sk, []):
                # near-verbatim: 12+ word shared run
                exg = set(V.ngrams(ex, 12))
                if exg and (set(V.ngrams(text, 12)) & exg):
                    findings["D_example_copy"].append((k, sk))
                    break

        reg_counts[prof.aesthetic_register] += 1

        # E. formula placement (case-insensitive, matching the gate)
        fml = prof.core_formula.lower()
        sc = obj.get("style_core", {}).get("text", "") if isinstance(obj.get("style_core"), dict) else ""
        if fml not in sc.lower():
            findings["E_blueprint_formula_missing"].append(k)
        od = obj.get("occasions_daily", {}).get("text", "") if isinstance(obj.get("occasions_daily"), dict) else ""
        if fml not in od.lower():
            findings["E_occasions_formula_missing"].append(k)
        a1 = obj.get("accessory_1", {}).get("text", "") if isinstance(obj.get("accessory_1"), dict) else ""
        if prof.core_keywords[2].lower() not in a1.lower():
            findings["E_accessory_final_term_missing"].append(k)
        closing = obj.get("closing", "")
        if not closing.rstrip(".").lower().endswith(fml):
            findings["E_closing_bad"].append(k)

        # F. palette temperature word
        pal = obj.get("palette_narrative", {}).get("text", "").lower() if isinstance(obj.get("palette_narrative"), dict) else ""
        if prof.temperature == "warm" and "cool" in pal and "warm" not in pal:
            findings["F_palette_temp_mismatch"].append((k, "warm-profile reads cool"))
        if prof.temperature == "cool" and "warm" in pal and "cool" not in pal:
            findings["F_palette_temp_mismatch"].append((k, "cool-profile reads warm"))

        # I. accessory omit leakage
        plan = accessory_plan(prof.aesthetic_register, prof.orientation, prof.finish_lane)
        omit = [o["category"].lower() for o in plan["omit"]]
        acc_all = " ".join(obj.get(f"accessory_{i}", {}).get("text", "").lower()
                           for i in (1, 2, 3) if isinstance(obj.get(f"accessory_{i}"), dict))
        for cat in omit:
            head = cat.split()[0]  # e.g. "scarves"
            if re.search(r"\b" + re.escape(head) + r"\b", acc_all):
                findings["I_omit_category_named"].append((k, cat))

    # C. finalize stamping: 6-grams in >= 40% of ALL clusters ...
    n = len(keys)
    for g, cl in ngram_cluster.items():
        if len(cl) >= max(3, int(0.40 * n)):
            findings["C_phrase_stamped"].append((g, len(cl)))
    findings["C_phrase_stamped"].sort(key=lambda x: -x[1])
    # ... and register-conditional stamping: a phrase in >= 60% of one
    # register's clusters that the global threshold would miss.
    global_stamped = {g for g, _ in findings["C_phrase_stamped"]}
    for reg, grams in ngram_by_reg.items():
        rn = reg_counts[reg]
        for g, cl in grams.items():
            if len(cl) >= max(3, int(0.60 * rn)) and g not in global_stamped:
                findings["C_phrase_stamped_by_register"].append((reg, g, len(cl), rn))
    findings["C_phrase_stamped_by_register"].sort(key=lambda x: -x[2])

    # J. duplicate identical section text
    for sk, items in section_texts.items():
        seen: dict[str, str] = {}
        for cl, text in items:
            norm = re.sub(r"\s+", " ", text.strip())
            if norm and norm in seen:
                findings["J_duplicate_section"].append((sk, seen[norm], cl))
            else:
                seen[norm] = cl

    # intro stamping
    for intro, cnt in intro_counter.items():
        if cnt >= max(3, int(0.30 * n)):
            findings["C_intro_stamped"].append((intro, cnt))
    findings.setdefault("C_intro_stamped", [])
    findings["C_intro_stamped"].sort(key=lambda x: -x[1])

    return {"clusters": n, "findings": findings}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=str(REPO_ROOT / "data" / "style_guide" / "blueprint_narrative_cache_sg3.json"))
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    cache = json.loads(Path(args.cache).read_text())
    res = audit(cache)
    if args.json:
        # make tuples serialisable
        out = {"clusters": res["clusters"],
               "findings": {k: [list(x) if isinstance(x, tuple) else x for x in v]
                            for k, v in res["findings"].items()}}
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return
    f = res["findings"]
    print(f"# SG-3 Deep Audit — {res['clusters']} clusters\n")
    order = sorted(f.keys())
    if not order:
        print("No findings.")
    for cat in order:
        items = f[cat]
        if not items:
            continue
        print(f"## {cat}: {len(items)}")
        for x in items[:8]:
            print(f"   - {x}")
        if len(items) > 8:
            print(f"   ... +{len(items)-8} more")
        print()


if __name__ == "__main__":
    main()
