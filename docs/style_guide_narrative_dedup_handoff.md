# Style Guide narrative de-duplication — implementation handoff

This document is the **single implementation spec** for reducing repetitive language and repeated arguments across Style Guide sub-pages. It consolidates investigation findings, architecture, editorial contracts, phased work, acceptance criteria, and optional automation.

**Primary consumer:** AI or human developer implementing changes end-to-end.  
**Canonical narrative data:** `data/style_guide/blueprint_narrative_cache.json` (576 archetype cluster keys × 16 section strings). The app bundle loads the same file via symlink from `Cosmic Fit/Resources/` — see `data/style_guide/README.md`.

---

## 1. Problem statement (what users experience)

Users read **multiple Style Guide detail screens** in one session (Style Core, Textures, Palette, Occasions, Hardware, Code, Accessory, Pattern). Today, many sections:

- Re-argue the **same thesis** (e.g. “no fiddly clasps / industrial weight / one anchor piece”) across **Hardware** and **Accessory**, and across the three **Hardware** subheads.
- Re-use the **same editorial scaffolding** (“momentum”, “fuss”, “stride”, “walk into a room”, “heavy lifting”, “unbothered”, “architectural”) across many paragraphs in one cluster.
- Repeat **concrete inventory** because **Group B** templates inject the same placeholders (`{texture_good_*}`, `{metal_*}`, colours, patterns) into adjacent sections.

The paragraphs are often strong in isolation; the defect is **cross-section and intra-section redundancy** for the same user.

---

## 2. Architecture (where everything lives)

### 2.1 Data flow (high level)

1. `BlueprintComposer.compose(...)` builds `CosmicBlueprint` from chart + `astrological_style_dataset.json` + `blueprint_narrative_cache.json`.
2. `NarrativeCacheLoader` loads JSON; `ArchetypeKeyGenerator` resolves cluster key (with nearest-match fallback on miss).
3. **Group B** narrative strings are passed through `NarrativeTemplateRenderer.render(...)` (placeholder substitution). **Group A** strings are **not** rendered through that loop.
4. `HouseSectOverlayGenerator` may **append** short prose to `style_core`, `textures_sweet_spot`, `occasions_work`, and/or `occasions_daily` (see `BlueprintComposer` after narrative lookup).
5. `StyleGuideViewController.createContent(for:)` maps each UI section to `CosmicBlueprint` fields, with **hard-coded fallback** copy when blueprint is missing or fields are empty.

### 2.2 JSON section keys (must stay stable)

These are `BlueprintArchetypeKey.BlueprintSection.rawValue` and match JSON keys exactly:

| Key | UI / model |
|-----|------------|
| `style_core` | Style Core |
| `textures_good` | Textures — The Good |
| `textures_bad` | Textures — The Bad |
| `textures_sweet_spot` | Textures — The Sweet Spot |
| `palette_narrative` | Palette (with colour UI) |
| `occasions_work` | Occasions — At Work |
| `occasions_intimate` | Occasions — Intimate Energy |
| `occasions_daily` | Occasions — Daily Movement |
| `hardware_metals` | Hardware — The Metals |
| `hardware_stones` | Hardware — The Stones |
| `hardware_tip` | Hardware — Tip |
| `accessory_1` … `accessory_3` | Accessory (three body paragraphs) |
| `pattern_narrative` | Pattern — body |
| `pattern_tip` | Pattern — Tip |

**Do not rename keys** without a coordinated migration (decoder, tests, `tools/review_tool.py` `SECTION_KEYS`, inspector).

### 2.3 Group A vs Group B (`NarrativeTemplateRenderer`)

Defined in `Cosmic Fit/InterpretationEngine/NarrativeTemplateRenderer.swift`:

**Group B** (`groupBSections`) — templates receive `render(...)`:

- `palette_narrative`
- `pattern_narrative`, `pattern_tip`
- `hardware_metals`, `hardware_stones`, `hardware_tip`
- `textures_good`, `textures_bad`, `textures_sweet_spot`

**Group A** — no `render` pass in `BlueprintComposer` for these keys:

- `style_core`
- `occasions_work`, `occasions_intimate`, `occasions_daily`
- `accessory_1`, `accessory_2`, `accessory_3`

Implication: **placeholder vocabulary** only applies to Group B as documented in `NarrativeTemplateRenderer.allPlaceholders`. Group A edits are plain prose (plus whatever you append from overlays on occasions fields — overlays are plain strings).

### 2.4 Code tab (deterministic, not in narrative cache)

`CosmicBlueprint.code` (`leanInto`, `avoid`, `consider`) comes from `DeterministicResolver.resolveCode` → strings in **`data/style_guide/astrological_style_dataset.json`** (planet–sign and aspect entries). It can **semantically overlap** AI texture copy; treat dataset + `StyleGuideViewController` fallbacks as part of de-duplication scope.

### 2.5 Key source files

| Path | Role |
|------|------|
| `data/style_guide/blueprint_narrative_cache.json` | **Edit target** for all AI Style Guide paragraphs (except Code bullets). |
| `data/style_guide/astrological_style_dataset.json` | Code bullets; texture/pattern/metal hints used in templates. |
| `Cosmic Fit/InterpretationEngine/BlueprintComposer.swift` | Assembly, overlay append, `groupBSections` render loop. |
| `Cosmic Fit/InterpretationEngine/NarrativeTemplateRenderer.swift` | Placeholder sets and rendering. |
| `Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift` | Overlay strings appended to selected sections. |
| `Cosmic Fit/InterpretationEngine/NarrativeCacheLoader.swift` | Load / lookup cache. |
| `Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift` | Section → blueprint mapping + **fallback** paragraphs. |
| `tools/review_tool.py` | Local review UI; `SECTION_KEYS` must match JSON. |
| `tools/backfill_narratives.py` | Regeneration / batch tooling (if used). |

---

## 3. Investigation summary (evidence to justify work)

### 3.1 Intra-Hardware (three subheads on one screen)

`hardware_metals`, `hardware_stones`, and `hardware_tip` share high **word-set Jaccard** (~0.20+ mean pairwise on worst clusters; lower on others). Readers perceive one argument three times (“industrial, not fiddly, built for your pace”).

### 3.2 Inter-Accessory vs Hardware (two screens in sequence)

Across **576** clusters, all 9 pairwise Jaccard means (accessory paragraph × hardware paragraph) sit between **0.118** and **0.144**. Top two pairs are within rounding of each other:

| Pair | Mean | p90 | Max |
|------|------|-----|-----|
| `accessory_1` × `hardware_tip` | **0.144** | 0.181 | 0.254 |
| `accessory_2` × `hardware_metals` | **0.142** | 0.178 | 0.257 |
| `accessory_2` × `hardware_tip` | 0.139 | 0.176 | 0.222 |
| `accessory_3` × `hardware_tip` | 0.135 | 0.169 | 0.244 |
| `accessory_1` × `hardware_metals` | 0.134 | 0.168 | 0.254 |
| `accessory_3` × `hardware_metals` | 0.134 | 0.167 | 0.228 |
| `accessory_2` × `hardware_stones` | 0.120 | 0.152 | 0.216 |
| `accessory_3` × `hardware_stones` | 0.120 | 0.151 | 0.194 |
| `accessory_1` × `hardware_stones` | 0.118 | 0.149 | 0.187 |

**Combined accessory blob × combined hardware blob (one Jaccard per cluster):** mean **0.173**, p90 **0.200**, max **0.238**, min **0.104**.

**Hardware-lexicon density inside `accessory_1+2+3`** (count of: `fiddly, industrial, clasp, chain, buckle, hardware, strap, weight, snap`): mean **10.5** hits per cluster, max **19**.

Accessory copy frequently discusses clasps, chains, buckles, straps — Hardware’s semantic territory. This is a **cross-screen** problem distinct from §3.1 intra-Hardware.

### 3.3 Other high-overlap pairs (same cluster, mean Jaccard)

- `pattern_narrative` vs `pattern_tip`: **0.184** (max **0.316**).
- `accessory_1` vs `accessory_2`: **0.170** (max **0.277**).
- `accessory_2` vs `accessory_3`: **0.164** (max **0.277**).
- `style_core` vs `occasions_work`: **0.157** (max **0.241**).
- `textures_good` vs `textures_sweet_spot`: **0.150** (max **0.263**) — both lean on `{texture_good_*}` placeholders by design.
- `textures_bad` vs `pattern_narrative`: **0.132** (max **0.248**) — both “avoid busy / precious / chaotic.”

No two **full** section bodies are identical across keys in any cluster.

### 3.4 Global editorial tics (sum of hits across the entire cache)

| Phrase | Total hits across all sections × all clusters |
|--------|-----------------------------------------------|
| `fuss` | **1204** |
| `momentum` | 592 |
| `unbothered` | 479 |
| `stride` | 478 |
| `architectural` | 429 |
| `walk into a room` | 320 |
| `heavy lifting` | 318 |
| `industrial` | 290 |
| `precious` | 284 |
| `on the rail` | 282 |
| `fiddly` | 150 |
| `leave it on the hanger` | 150 |
| `does the heavy lifting` | 84 |
| `second skin` | 56 |

Cross-cluster voice drift, not only a single user.

### 3.5 Repeated openers (template-level repetition)

After normalising `{placeholders}`, the same opening sentence frame appears across multiple clusters. Top examples (counts of identical openings across the file):

- "Your true sweet spot exists right at the intersection of […] and […]." — **5**
- "Your sweet spot sits right at the intersection of […] and […]." — **5**
- "Your sweet spot lives exactly where […] meets […]." — **4**
- "Your sweet spot lives right at the intersection of […] and […]." — **4**
- "Off-duty dressing for you is never an exercise in hiding." — **3**
- "The sensory footprint of your accessories matters just as much as their shape." — **3**
- (further frames at 2–3 occurrences each)

Concentrates in `textures_sweet_spot` and `accessory_*`.

### 3.6 UI / dataset overlap

`StyleGuideViewController` **Code** fallback includes fabric-quality language that can duplicate **Textures — The Bad** (e.g. fallback `Avoid` bullet referencing flimsy / disposable fabrics). Dataset `code_avoid` lines may do the same.

### 3.7 Overlays

`HouseSectOverlayGenerator` appends short Venus/Moon/sect/dominant-house prose to `style_core`, `textures_sweet_spot`, and occasions fields (`occasions_work` or `occasions_daily`, never `occasions_intimate`). If the base cluster narrative already states the same idea, the user reads it twice.

---

## 4. Editorial contract — **section jobs** (non-negotiable)

Implementers must **not** edit prose at scale until this contract is agreed (copy-paste into tickets). Each key owns **one job**; any sentence serving another key’s job is wrong.

### 4.1 `style_core`

- **Job:** Who they are in a room; wardrobe as **identity / presence** (not metals, not print rules, not occasion logistics).
- **Avoid:** Re-listing workday tactics, clasp advice, or print scale rules.

### 4.2 `textures_good` / `textures_bad` / `textures_sweet_spot`

- **Good:** Endorse **specific** favourable textures (placeholders OK).
- **Bad:** Fabric / maintenance / sensory **failure modes**.
- **Sweet spot:** **Combination rule** or **sensory balance** (how two qualities meet on the body). **Do not** repeat the full good-texture list unless unavoidable; prefer referring to roles (“your heavier anchor from above”) or only `sweet_spot_keyword_*` plus **one** texture call if needed.
- **Avoid:** Duplicating pattern advice (graphics) here.

### 4.3 `palette_narrative`

- **Job:** How to **use** their palette (relationship of core / accent / neutrals if relevant), mood of colour, not jewellery mechanics.

### 4.4 `occasions_work` / `occasions_intimate` / `occasions_daily`

- **Work:** Professional / public context — silhouette, authority, **work-specific** friction (dress code, meetings, commute if needed).
- **Intimate:** Close range, touch, lighting, **relational** distance — not “stride across office.”
- **Daily:** Errands, casual social, repeat wear — not a second work essay.
- **Avoid:** Same opening device in all three (e.g. all starting with “Getting dressed should…”).

### 4.5 `hardware_metals` / `hardware_stones` / `hardware_tip`

- **Metals:** Finish, temperature, weight, **why this metal** with outerwear / fabric types; closures **only** as metal behaviour.
- **Stones:** Colour behaviour, cut/setting, skin interaction, **stone-specific** language — not repeating “industrial vs fiddly” lecture from metals.
- **Tip:** **Quantity / pairing / care / one rule** (e.g. one hero metal, mixing limit) — must not re-teach metals and stones paragraphs.

### 4.6 `accessory_1` / `accessory_2` / `accessory_3`

- **Job:** **Focal count**, **scale**, **category roles** (bag vs shoe vs scarf vs hat), **proportion on the body**, **outfit balance** — **not** re-explaining clasps, chains, buckles, or industrial vs delicate (that is Hardware’s job).
- **Hard rule:** Treat “hardware lexicon” (clasp, buckle, chain, rivet, carabiner, strap, industrial, fiddly, snap, etc.) as **expensive** — use sparingly; if density exceeds agreed QA threshold, rewrite.

Suggested **paragraph split** (adjust if needed, but keep distinct):

1. Anchor / count / focal point strategy.  
2. Category + proportion (what goes where on the silhouette).  
3. Longevity, rotation, or non-jewellery accessories (scarf, hat, eyewear) — **not** a third metal lecture.

### 4.7 `pattern_narrative` / `pattern_tip`

- **Narrative:** Why these patterns vs avoided ones (graphic / mood logic).
- **Tip:** **Operational** only: scale, placement on body, one garment rule, colour framing — **no second “why prints fail” essay.**

### 4.8 Code tab (dataset + fallbacks)

- **Avoid** bullets that restate **Textures — The Bad** or **Hardware** mantras. Prefer **behavioural** rules (shopping, rotation, budget habits) where possible.

---

## 5. Solution strategy (what kind of change, when)

| Situation | Approach |
|-----------|----------|
| Same **job** on two screens (Accessory vs Hardware) | **Redefine job** (Section 4) then **rewrite** accessory (and trim hardware_tip if it bleeds). |
| Same thesis **three times on one screen** (Hardware) | **Outline split** + **surgical rewrites** per cluster (or per voice-family batch). |
| Placeholder-driven duplicate **names** | **Template / structural**: reduce repeated `{texture_good_*}` in sweet spot; keep palette/pattern injections where they serve different **roles**. |
| Global tics | **Editorial pass** + optional **lint list**; careful synonyming (not blind find-replace of astrological meaning). |
| Overlays echo base narrative | **Short amend** of overlay templates **or** optional **code guard** (Section 7.3). |
| Fallback + dataset | **Small string edits** in Swift fallbacks + dataset JSON. |

**Default:** **surgical paragraph edits** across `blueprint_narrative_cache.json` after the section job spec is fixed. **Full cluster rewrites** only where voice-family batching makes sense or a cluster still fails QA after surgery. **Avoid** renaming JSON keys or changing `CosmicBlueprint` shape unless explicitly required.

---

## 6. Implementation phases (execution order)

### Phase 0 — Preconditions (REQUIRED)

- [ ] Lock Section 4 **section job spec** (stakeholder sign-off).
- [ ] Confirm editing **`data/style_guide/blueprint_narrative_cache.json`** only; rebuild app / run tests so bundle symlink picks up changes.
- [ ] **Required:** export **baseline metrics** by running the script in Section 7.1; commit the resulting `narrative_overlap_baseline.json` (or include the numbers in the PR description). Acceptance §8 compares post-edit metrics against this baseline.
- [ ] Read Section 6.x **execution mechanics** before opening the JSON.

### 6.x — Execution mechanics for safe JSON edits

The JSON is loaded by Swift `JSONDecoder` and by `tools/review_tool.py`. Both tolerate any whitespace, **but** human/AI editors must preserve:

1. **UTF-8 encoding without BOM.** The file is currently UTF-8.
2. **Stable top-level key order.** Cluster keys are alphabetical-ish but not enforced — preserve the existing order to keep diffs reviewable. Do not re-sort.
3. **Stable inner key order per cluster.** Use the canonical order from §2.2 if a key is rewritten in place.
4. **Curly-brace placeholders are syntactically meaningful.** Do not introduce `{ }` for prose. Group B placeholder vocabulary is fixed in `NarrativeTemplateRenderer.allPlaceholders`; do not invent new placeholder names.
5. **Round-trip validation after every batch:** run `python3 -c "import json; json.load(open('data/style_guide/blueprint_narrative_cache.json'))"` and verify exit 0. Then run the metric script (§7.1) — it loads the file with `json.load` and will refuse on parse error.
6. **Atomic write.** When scripting edits, write to `*.tmp` and `os.replace(...)` to avoid half-written files.
7. **Symlink path.** `Cosmic Fit/Resources/blueprint_narrative_cache.json` is a symlink to `data/style_guide/...`. Edit the canonical file in `data/style_guide/`. Never check in two diverged copies.
8. **Tests touching the cache:** `Cosmic_FitTests` has `NarrativeCacheLoader` and `NarrativeTemplateRenderer` tests that load via `StyleGuideDataURL`. Run them after any structural change.

### Phase 1 — Structural / template (high leverage, low risk)

- [ ] **`textures_sweet_spot`:** Rewrite templates so sweet spot **does not** mirror `textures_good` opening or repeat full `{texture_good_*}` list unless product requires it; prefer keywords + combination logic.
- [ ] **`pattern_tip`:** Shorten to operational rules; remove duplicated “avoid fussy” blocks already in `pattern_narrative`.

### Phase 2 — Hardware + Accessory (highest user-visible duplication)

- [ ] **`hardware_metals` / `hardware_stones` / `hardware_tip`:** Enforce outline in 4.5; remove repeated “fiddly / industrial / pace” cycles.
- [ ] **`accessory_1`–`accessory_3`:** Rewrite to 4.6; **decimate** hardware lexicon in accessory fields.

**Batching suggestion:** Edit by **Venus sign × Moon sign × element** family (keys share prefix patterns like `venus_aquarius__moon_aries__*`) so voice stays consistent across the four element variants.

### Phase 3 — Occasions + Pattern narrative

- [ ] Disambiguate **work / intimate / daily** per 4.4.
- [ ] `pattern_narrative`: keep conceptual; ensure tip owns mechanics.

### Phase 4 — Textures bad vs pattern; style_core vs occasions

- [ ] Split fabric vs graphic failure modes.
- [ ] Reduce occasions openers that echo `style_core`.

### Phase 5 — Global voice

- [ ] Tic budget: reduce overuse of top crutch words (use search in IDE / script); maintain UK spelling if that is project convention (`tools/review_tool.py` has spelling hints).

### Phase 6 — App + dataset

- [ ] `StyleGuideViewController`: align **Code** fallback bullets with 4.8.
- [ ] `astrological_style_dataset.json`: audit top-weighted `code_avoid` / `code_leaninto` strings for texture/hardware duplication.

### Phase 7 — Overlays (optional code + copy)

- [ ] Read `HouseSectOverlayGenerator` outputs against `style_core` / `textures_sweet_spot` / occasions; amend overlay strings or implement **optional** overlap guard (Section 7.3).

### Phase 8 — Verification

- [ ] Re-run `python3 tools/narrative_overlap_report.py --baseline narrative_overlap_postedit.json` and compare against the Phase 0 baseline numbers in §3 / §7.1.
- [ ] Run `python3 tools/narrative_overlap_report.py --check` and confirm exit 0 (no breaches against `THRESHOLDS`).
- [ ] Manual read of the **stratified 8–12** clusters from §8 acceptance, full Style Guide scroll (all narrative sections + Code).
- [ ] Run existing tests: `Cosmic_FitTests` (NarrativeCacheLoader, NarrativeTemplateRenderer), any blueprint fixtures; `python3 tools/validate_dataset.py` if dataset touched.
- [ ] JSON round-trip: `python3 -c "import json; json.load(open('data/style_guide/blueprint_narrative_cache.json'))"` exits 0; `git diff --stat` shows only intended file(s).

---

## 7. Automation & QA (recommended deliverables)

### 7.1 Offline metric script (Python) — runnable starter

Create **`tools/narrative_overlap_report.py`** with the following content. It reproduces the Phase 0 baseline numbers in §3 and is the same metric used by acceptance §8.

```python
#!/usr/bin/env python3
"""Style Guide narrative overlap report.

Usage:
    python3 tools/narrative_overlap_report.py \\
        [--cache data/style_guide/blueprint_narrative_cache.json] \\
        [--baseline narrative_overlap_baseline.json] \\
        [--check]   # exit non-zero if any per-cluster gate is breached

Produces summary stats + worst-offender lists. With --baseline writes a JSON
snapshot for diffing. With --check enforces gates from THRESHOLDS.
"""
import argparse, json, re, sys, statistics
from pathlib import Path

SECTION_KEYS = [
    "style_core",
    "textures_good", "textures_bad", "textures_sweet_spot",
    "palette_narrative",
    "occasions_work", "occasions_intimate", "occasions_daily",
    "hardware_metals", "hardware_stones", "hardware_tip",
    "accessory_1", "accessory_2", "accessory_3",
    "pattern_narrative", "pattern_tip",
]

ACCESSORY = ["accessory_1", "accessory_2", "accessory_3"]
HARDWARE  = ["hardware_metals", "hardware_stones", "hardware_tip"]

HARDWARE_LEXICON = [
    "fiddly", "industrial", "clasp", "chain", "buckle",
    "hardware", "strap", "weight", "snap",
]

THRESHOLDS = {
    "combined_acc_hw_jaccard_max":     0.24,
    "combined_acc_hw_jaccard_warn":    0.20,
    "single_acc_hw_jaccard_warn":      0.22,
    "pattern_narr_tip_jaccard_warn":   0.22,
    "hardware_trio_pair_jaccard_warn": 0.22,
    "accessory_lexicon_hits_warn":     12,
}

PLACEHOLDER_RE = re.compile(r"\{[^}]+\}")
WORD_RE = re.compile(r"[a-z']+")

def words(s: str) -> set:
    s = PLACEHOLDER_RE.sub(" ", (s or "").lower())
    return set(WORD_RE.findall(s))

def jaccard(a: str, b: str) -> float:
    A, B = words(a), words(b)
    if not A or not B:
        return 0.0
    return len(A & B) / len(A | B)

def lexicon_hits(text: str, lexicon=HARDWARE_LEXICON) -> int:
    blob = (text or "").lower()
    return sum(blob.count(w) for w in lexicon)

def summarise(values):
    if not values:
        return {"mean": 0, "p50": 0, "p90": 0, "max": 0}
    srt = sorted(values)
    p = lambda q: srt[min(len(srt) - 1, int(q * (len(srt) - 1)))]
    return {
        "mean": round(statistics.mean(values), 4),
        "p50":  round(p(0.50), 4),
        "p90":  round(p(0.90), 4),
        "max":  round(srt[-1], 4),
    }

def analyse(cache: dict) -> dict:
    out = {
        "cluster_count": len(cache),
        "metrics": {},
        "worst_offenders": {},
        "breaches": [],
    }

    # Combined accessory blob vs combined hardware blob (per cluster)
    combined = []
    for k, e in cache.items():
        a = " ".join(e.get(x, "") for x in ACCESSORY)
        h = " ".join(e.get(x, "") for x in HARDWARE)
        j = jaccard(a, h)
        combined.append((k, j))
    out["metrics"]["combined_acc_vs_hw"] = summarise([j for _, j in combined])
    out["worst_offenders"]["combined_acc_vs_hw"] = sorted(
        combined, key=lambda x: -x[1]
    )[:15]

    # 9 accessory × hardware pair stats
    pair_metrics = {}
    for a in ACCESSORY:
        for h in HARDWARE:
            vals = [jaccard(e.get(a, ""), e.get(h, "")) for e in cache.values()]
            pair_metrics[f"{a}__x__{h}"] = summarise(vals)
    out["metrics"]["accessory_x_hardware_pairs"] = pair_metrics

    # Hardware trio pairs
    trio = {}
    for i, k1 in enumerate(HARDWARE):
        for k2 in HARDWARE[i+1:]:
            vals = [jaccard(e.get(k1, ""), e.get(k2, "")) for e in cache.values()]
            trio[f"{k1}__x__{k2}"] = summarise(vals)
    out["metrics"]["hardware_trio_pairs"] = trio

    # Pattern narrative vs tip
    pat = [jaccard(e.get("pattern_narrative", ""), e.get("pattern_tip", ""))
           for e in cache.values()]
    out["metrics"]["pattern_narrative_vs_tip"] = summarise(pat)

    # Textures good vs sweet spot
    tx = [jaccard(e.get("textures_good", ""), e.get("textures_sweet_spot", ""))
          for e in cache.values()]
    out["metrics"]["textures_good_vs_sweet_spot"] = summarise(tx)

    # Hardware lexicon density inside accessory_1+2+3
    dens = []
    for k, e in cache.items():
        d = sum(lexicon_hits(e.get(x, "")) for x in ACCESSORY)
        dens.append((k, d))
    out["metrics"]["accessory_hardware_lexicon_hits"] = summarise(
        [d for _, d in dens]
    )
    out["worst_offenders"]["accessory_hardware_lexicon_hits"] = sorted(
        dens, key=lambda x: -x[1]
    )[:15]

    # Breach detection (per-cluster gates)
    for k, j in combined:
        if j > THRESHOLDS["combined_acc_hw_jaccard_max"]:
            out["breaches"].append(("combined_acc_hw_jaccard_max", k, round(j, 4)))
    for k, e in cache.items():
        for a in ACCESSORY:
            for h in HARDWARE:
                j = jaccard(e.get(a, ""), e.get(h, ""))
                if j > THRESHOLDS["single_acc_hw_jaccard_warn"]:
                    out["breaches"].append((f"{a}__x__{h}", k, round(j, 4)))
        jp = jaccard(e.get("pattern_narrative", ""), e.get("pattern_tip", ""))
        if jp > THRESHOLDS["pattern_narr_tip_jaccard_warn"]:
            out["breaches"].append(("pattern_narrative__x__pattern_tip", k, round(jp, 4)))
        for i, k1 in enumerate(HARDWARE):
            for k2 in HARDWARE[i+1:]:
                jh = jaccard(e.get(k1, ""), e.get(k2, ""))
                if jh > THRESHOLDS["hardware_trio_pair_jaccard_warn"]:
                    out["breaches"].append((f"{k1}__x__{k2}", k, round(jh, 4)))
        d = sum(lexicon_hits(e.get(x, "")) for x in ACCESSORY)
        if d > THRESHOLDS["accessory_lexicon_hits_warn"]:
            out["breaches"].append(("accessory_hardware_lexicon_hits", k, d))

    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache",
                    default="data/style_guide/blueprint_narrative_cache.json")
    ap.add_argument("--baseline", default=None)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    cache = json.load(open(args.cache, encoding="utf-8"))
    report = analyse(cache)

    print(json.dumps({
        "cluster_count": report["cluster_count"],
        "metrics": report["metrics"],
        "breach_count": len(report["breaches"]),
    }, indent=2))

    print("\n# Top 10 worst clusters: combined accessory vs hardware")
    for k, v in report["worst_offenders"]["combined_acc_vs_hw"][:10]:
        print(f"  {v:.3f}  {k}")

    if args.baseline:
        Path(args.baseline).write_text(json.dumps(report, indent=2))

    if args.check and report["breaches"]:
        print(f"\nFAIL: {len(report['breaches'])} breaches", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

**Calibration baseline (Phase 0, before edits):**

| Metric | Mean | p90 | Max |
|--------|------|-----|-----|
| Combined accessory blob × hardware blob | 0.173 | 0.200 | 0.238 |
| `pattern_narrative` × `pattern_tip` | 0.184 | — | 0.316 |
| `textures_good` × `textures_sweet_spot` | 0.150 | — | 0.263 |
| `accessory_1` × `hardware_tip` | 0.144 | 0.181 | 0.254 |
| `accessory_2` × `hardware_metals` | 0.142 | 0.178 | 0.257 |
| Accessory hardware-lexicon hits | 10.5 | — | 19 |

**Starter gates (in `THRESHOLDS` above) — tune after Phase 0:**

| Gate constant | Initial value | Rationale |
|---------------|---------------|-----------|
| `combined_acc_hw_jaccard_warn` | 0.20 | ≈ current p90; expect post-edit p90 to drop. |
| `combined_acc_hw_jaccard_max` | 0.24 | ≈ current max; CI fail above this. |
| `single_acc_hw_jaccard_warn` | 0.22 | Below current single-pair max (0.257) — flags top tail. |
| `pattern_narr_tip_jaccard_warn` | 0.22 | Below current max (0.316). |
| `hardware_trio_pair_jaccard_warn` | 0.22 | Same logic for intra-Hardware. |
| `accessory_lexicon_hits_warn` | 12 | Above current mean (10.5), well below max (19). |

Run on a clean checkout to confirm Phase 0 numbers reproduce; then keep these constants frozen until Phase 8 verification.

### 7.2 `review_tool.py`

- Optionally surface **overlap score** per cluster in the review UI (future enhancement).
- Continue using `SECTION_KEYS` ordering for human review waves.

### 7.3 Optional runtime / compose-time guard (`BlueprintComposer`)

**Only if product wants hard guarantees:**

After assembling narratives (and overlays), compute a simple **n-gram or word overlap** between `accessory_*` concatenation and `hardware_*` concatenation; if over threshold, log in DEBUG or strip lowest-priority sentence (risky — **prefer JSON fixes**). Default recommendation: **do not** auto-mutate user-facing prose in production; **lint in CI** instead.

**Overlay guard:** If appended overlay shares high bigram overlap with existing `style_core` paragraph, skip append or use shorter variant — requires careful testing with `HouseSectOverlayGenerator` tests in `Cosmic_FitTests`.

---

## 8. Acceptance criteria (definition of done)

1. **Section jobs:** Every narrative key’s copy in a **stratified** sample of clusters matches Section 4 (spot-check checklist). Sample: pick **24 clusters = 12 Venus signs × 2 random Moon×element variants per Venus sign** (deterministic seed; record list in PR).
2. **Metrics (vs Phase 0 baseline JSON):** running `python3 tools/narrative_overlap_report.py --baseline <new>.json` shows for **all** of:
   - `combined_acc_vs_hw`: **mean ↓ ≥ 15%** and **p90 ↓ ≥ 20%** vs baseline.
   - `hardware_trio_pairs`: every pair’s **mean ↓ ≥ 15%**.
   - `pattern_narrative_vs_tip`: **mean ↓ ≥ 20%** and **max ≤ 0.22**.
   - `accessory_hardware_lexicon_hits`: **mean ↓ ≥ 25%** and **max ≤ 12**.
3. **Hard gate:** `python3 tools/narrative_overlap_report.py --check` exits **0** (no per-cluster breach against `THRESHOLDS`).
4. **Voice:** Manual read of **8–12** full clusters confirms no “same paragraph twice” when reading Hardware then Accessory in sequence.
5. **No schema drift:** All **576** keys still present; each cluster still contains all **16** non-empty section strings; key order unchanged at top level (diffable).
6. **Placeholders:** No broken `{unknown}` tokens (run app once with debug logging on at least one fixture chart; `NarrativeTemplateRenderer` test suite passes; no `[NarrativeTemplateRenderer] Warning:` lines in console).
7. **Code tab:** No `StyleGuideViewController` fallback bullet or top-weighted dataset `code_avoid` string duplicates **Textures — The Bad** main thesis.
8. **Build/tests:** Xcode build green; `Cosmic_FitTests` green (`NarrativeCacheLoader`, `NarrativeTemplateRenderer`, blueprint distribution); `python3 tools/validate_dataset.py` exits 0 if dataset touched; app loads Style Guide without empty sections for fixture charts.

---

## 9. Risks and explicit non-goals

**Risks**

- Aggressive global find-replace on tics can break astrological nuance or UK spelling — use **human or LLM batch review** with diff.
- Tightening placeholders in `textures_sweet_spot` may require **placeholder count** validation in tests if min/max counts are assumed elsewhere.

**Non-goals (unless separately scoped)**

- Changing archetype key generation (`ArchetypeKeyGenerator`) or cluster count.
- Rewriting `InterpretationTextLibrary` / legacy interpretation paths.
- Merging Style Guide screens in UI (optional product change; not required for this spec).

---

## 10. Quick reference — flagged issue IDs → action

| ID | Issue | Action |
|----|-------|--------|
| R1 | `textures_good` vs `textures_sweet_spot` | Template + opener rewrite per 4.2 |
| R2 | Hardware trio | Outline 4.5 + surgical rewrites |
| R3 | Accessory trio internal sameness | Three distinct jobs per 4.6 |
| R4 | Accessory × Hardware inter-screen | Accessory rewrite + lexicon cap + metrics |
| R5 | Occasions three-way echo | Context-split per 4.4 |
| R6 | `pattern_narrative` vs `pattern_tip` | Split why vs how per 4.7 |
| R7 | `textures_bad` vs `pattern_narrative` | Split fabric vs graphic per 4.2 / 4.7 |
| R8 | `style_core` vs occasions / overlays | Trim echo + overlay copy or guard |
| R9 | Global tics | Editorial pass + optional lint list |
| R10 | Code + fallbacks vs textures | Swift + dataset string edits per 4.8 |

---

## 11. Appendix — metric definitions

**Word-set Jaccard** between strings A and B (after lowercasing, stripping `{placeholder}` chunks for tokenisation): let `W_A` and `W_B` be the sets of alphabetic word tokens. Then `J(A,B) = |W_A ∩ W_B| / |W_A ∪ W_B|`. Use the same definition in Phase 7 tooling for consistency with baseline reports.

---

*Document version: 1.0 — handoff for Style Guide narrative de-duplication. Source findings from internal codebase analysis and `blueprint_narrative_cache.json` statistics (576 clusters).*
