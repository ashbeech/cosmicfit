# Style Guide Content Audit — Developer Handoff

**Date:** 2026-06-17  
**Status:** Correction pass incomplete for full user-visible surface  
**Audience:** Next AI developer / engineer continuing Style Guide content quality work

---

## 1. Goal

Every string that can appear in the Style Guide UI must:

1. Be **audited** against Cosmic Fit voice and quality standards
2. Be **flagged** when it fails (single-word bullets, platitudes, fragments, weak grammar, missing second person where required, etc.)
3. Be **amended** to actionable, astrology-grounded, user-valuable copy
4. Be **verifiable** in the audit web tool with before/after history

**Current state:** Narrative paragraphs in `blueprint_narrative_cache.json` were largely corrected (~507 Gemini rewrites). **Deterministic Code assembly** (Lean Into / Avoid / Consider) and **runtime composition** still allow low-value tokens (e.g. bare `"safe"`) to reach users. The audit engine **detects some of these in composed fixtures** but does **not block them at the source** or auto-fix the runtime merge path.

---

## 2. What actually appears in the UI

The Style Guide is not one JSON file. User-visible text comes from **multiple layers merged at runtime**.

| UI section | Primary source | Storage | Audited? | Apply-fixed? |
|------------|----------------|---------|----------|--------------|
| The Blueprint, Textures, Occasions, Hardware, Accessory, Pattern (paragraphs) | AI narrative cache + overlays | `blueprint_narrative_cache.json` + `HouseSectOverlayGenerator.swift` | Yes | Cache: yes; Swift overlays: partial/failed |
| The Code — Lean Into / Avoid / Consider | **Runtime composition** from dataset | `astrological_style_dataset.json` via `DeterministicResolver` | Partial | Partial (~189 `planet_sign.code_*` rewrites) |
| The Code — Avoid (leaked mood tokens) | `opposites.mood` injected at runtime | Same dataset, **not** in `code_avoid` arrays | **Misclassified** | **No** |
| Palette colours, pattern lists, hardware metals/stones | Deterministic resolver | Dataset keywords | As keywords only | N/A (keywords) |
| Swift fallbacks (no blueprint loaded) | `StyleGuideViewController.swift` | Swift literals | Snapshot only | Failed (string not found) |
| Group B rendered narratives | Cache templates + placeholder fixture | Cache + `placeholder_fixture.json` | If `rendered` source enabled | Cache only |

**Critical insight:** The UI reads `bp?.code.leanInto` / `avoid` / `consider` from the **composed blueprint** (`BlueprintComposer` → `DeterministicResolver.resolveCode`). That is **not** the narrative cache. Amending cache paragraphs does **not** fix Code bullets.

```swift
// DeterministicResolver.swift — mood anti-tokens become Avoid bullets
for oppMood in entry.opposites.mood {
    avoidItems.append((oppMood, combo.aggregateWeight * 0.5))
}
```

---

## 3. What the correction pass accomplished

| Metric | Result |
|--------|--------|
| Narrative rewrites applied | ~507 (`audit_apply_log.json`) |
| Dataset `planet_sign.code_*` rewrites | ~189 |
| Mechanical fixes (em-dash, etc.) | ~3 on cache |
| Swift template rewrites | 0 applied (36 failed — interpolation / stale literals) |
| `opposites.mood` tokens (e.g. `"safe"`) | **0 changed** |

Backup snapshot: `data/style_guide/backups/pre_correction_2026-06-16/`

---

## 4. Root cause analysis — why the standard was not fully enforced

### 4.1 Audit treats `opposites.mood` as keywords, not user-facing bullets

**File:** `tools/content_audit_inventory.py`

- `planet_sign.*.code_leaninto` / `code_avoid` / `code_consider` → `CODE_BULLET` (min 8 words, sparse check)
- `planet_sign.*.opposites.mood[*]` → `KEYWORD` with `checks_enabled=("empty_content", "garbled_text", "capitalisation", "double_space")`

**All 479 `opposites.mood` entries are ≤3 words. Zero are flagged** because `check_sparse_code_bullet` and `check_nonsense_fragment` **skip** `keyword` and `phrase` formats.

Yet these strings are **injected into Avoid** and shown as full bullets in the UI.

### 4.2 Runtime merge is not audited as user-visible output

The audit has a **composed blueprints** layer (`walk_composed_blueprints`) that **does flag** leaked `"safe"` in `code.avoid` (`sparse_code_bullet` + `nonsense_fragment`, critical/high).

**But:**

- Composed fixtures live under `docs/fixtures/production_audit/blueprints/` (derived)
- `content_audit_apply.py` `filter_canonical()` **excludes** composed files — only `astrological_style_dataset.json`, `blueprint_narrative_cache.json`, and `.swift` are patched
- Flagged composed issues **never drive fixes** to the dataset or resolver

### 4.3 Handoff / apply scope was narrower than “all UI content”

The apply pipeline used `audit_handoff_pack.json` filtered to **canonical sources** (~549 actions in the second wave). That set was dominated by **narrative cache** flags (`pidgin_english`, `not_a_sentence`), not:

- Composed Code output (3,568 composed code items in full audit inventory)
- Full dataset inventory (5,305 items) when re-audit ran **runtime-only**

### 4.4 Partial re-audits produced misleading UI state

Latest `audit_report.json` (at time of handoff) contained **only 69 runtime items** (`sources_audited: ["runtime_strings"]`), not dataset/cache/composed.

The web tool labels text as “from latest audit scan” but **runtime layer uses stale** `extracted_runtime_strings.json` unless re-extracted after Swift edits.

### 4.5 Swift patching cannot update many runtime strings

Apply uses exact literal find/replace in Swift. Fails for:

- Interpolation templates (`\(domainPhrase(domain))`) — audit shows `{domain}` placeholders
- Stale snapshots (handoff `current_value` ≠ file after prior edits)

These appear as `REWRITE FAILED — Swift string not found` in the UI; **they are not proof the app is broken** — often the Swift file already has newer copy.

### 4.6 “Safe” case study (confirmed still possible in UI)

| Layer | Text |
|-------|------|
| Audit snapshot / composed fixture | `"safe"` as Avoid bullet |
| Dataset `opposites.mood` | Still `"safe"` in `mars_aquarius`, `saturn_aquarius`, `uranus_aries`, `uranus_scorpio` |
| Live Swift `code_avoid` sentences | Rewritten (full sentences) — **not** the source of lone `"safe"` |
| **What users can still see** | Bare **"safe"** when top-3 lean-into combos include those signs |

**The correction pass did not remove this.** Resolver logic unchanged; mood tokens unchanged.

---

## 5. Audit inventory coverage (full run)

When running:

```bash
python3 tools/content_audit.py --format all
# default sources: cache,dataset,blueprints,runtime,rendered
```

Approximate item counts:

| Source | Items | Notes |
|--------|-------|-------|
| `blueprint_narrative_cache.json` | ~9,216 | AI paragraphs — **corrected** |
| `astrological_style_dataset.json` | ~5,305 | Includes code bullets, mood tokens, house biases |
| Composed blueprints (`docs/fixtures/...`) | ~7,136 | **True user-visible Code merge** for fixtures |
| Runtime extracted strings | ~69 | Stale until re-extracted |
| Rendered Group B templates | varies | Needs `rendered` source |

**Recommended audit command for ongoing work:**

```bash
python3 tools/extract_runtime_style_guide_strings.py
python3 tools/production_audit_harness.py   # regenerate composed fixtures
python3 tools/content_audit.py --sources dataset,blueprints,cache,runtime,rendered --format all
```

---

## 6. Check gaps relevant to Lean Into / Avoid quality

| Check | Applies to `CODE_BULLET` | Applies to `opposites.mood` (KEYWORD) | Applies to composed `code.avoid` |
|-------|--------------------------|--------------------------------------|----------------------------------|
| `sparse_code_bullet` | Yes (min 8 words) | **No** | Yes (min 5 words) |
| `nonsense_fragment` | Yes (<3 words) | **No** (skipped for keyword) | Yes |
| `not_a_sentence` | Yes | **No** | Yes |
| `vague_direction` | Yes | **No** | Yes |
| `wrong_format_for_field` | For injection field_kinds only | **No** | — |

**House placement biases** (`lean_into_bias`, `code_consider_bias`): use shorter min word counts (5); 54/192 flagged in sample run — some still need rewrite.

**Aspect `code_addition_*`:** 23/60 flagged — needs apply pass if not already done.

---

## 7. Recommended remediation plan

### Phase A — Stop garbage reaching the UI (code changes, no Gemini)

**Priority: P0**

1. **`DeterministicResolver.resolveCode`** — Filter or expand injected mood tokens:
   - Option A: Drop any `avoidItems` entry with &lt;5 words or no terminal punctuation
   - Option B: Map single-word moods to full Avoid sentences (dataset change)
   - **Recommended:** A + expand the 4 `"safe"` entries in dataset as part of Phase B

2. **`content_audit_inventory.py`** — Classify `opposites.mood` as user-facing when used for Avoid:
   - New rule: `MOOD_AVOID_TOKEN` with `expected_format=actionable_bullet`, `min_words=8`
   - Or tag with `field_kind` and run `wrong_format_for_field` / `sparse_code_bullet`

3. **`check_nonsense_fragment`** — Consider flagging KEYWORD format when `ui_section` contains `"Avoid (anti-token)"`

**Files:**  
`Cosmic Fit/InterpretationEngine/DeterministicResolver.swift`  
`tools/content_audit_inventory.py`  
`tools/content_audit_checks.py`

### Phase B — Dataset correction for Code + injections

**Priority: P0**

1. Expand all short `opposites.mood` tokens that can surface in Avoid (479 entries — many multi-word but still not full sentences; audit each)
2. Rewrite flagged `house_placements.*.lean_into_bias` / `code_consider_bias` (54+ flagged)
3. Rewrite flagged `aspects.*.code_addition_*` (23+ flagged)
4. Verify all `planet_sign.*.code_*` bullets meet 8-word actionable standard (0 below min in current dataset — good)

**Apply:**

```bash
python3 tools/backup_style_guide_sources.py backup --label pre-code-pass
python3 tools/content_audit.py --sources dataset --format all
# Build handoff from report; apply dataset-only actions
python3 tools/content_audit_apply.py --phase rewrite --priority critical,high,medium,low --resume
```

### Phase C — Composed-output gate (regression)

**Priority: P1**

1. After Phase A+B, regenerate fixtures: `python3 tools/production_audit_harness.py`
2. Full audit with `blueprints` source
3. **Zero tolerance:** no composed `code.avoid` / `code.leanInto` item with &lt;5 words or `sparse_code_bullet` / `nonsense_fragment` critical
4. Add CI script (optional): fail if composed code bullets contain entries matching `/^[a-z]+$/` (single token)

### Phase D — Swift fallbacks + overlays

**Priority: P2**

1. Re-extract runtime strings; re-audit `runtime` layer
2. Manual or template-aware patch for overlay interpolation strings
3. Triage overlay `{domain}` flags as false positive **or** fix audit to understand Swift interpolation
4. Expand `fallback:pattern_tip` (critical `narrative_too_short`)

### Phase E — Web tool + workflow

**Priority: P1** (partially done)

- Web tool now loads `audit_apply_log.json` for before/after diffs
- Ensure **full audit** is run after each correction wave
- Document: “Current text” for runtime = extracted snapshot; trust Swift file for overlays

---

## 8. Definition of done

- [ ] No composed blueprint fixture has `code.avoid` / `code.leanInto` / `code.consider` bullets with &lt;8 words (except intentional keyword lists elsewhere)
- [ ] No bare mood token (`"safe"`, `"conventional"`, etc.) can appear in live `resolveCode` output
- [ ] Full audit (`dataset,blueprints,cache,runtime,rendered`) → **0 critical** on user-facing layers (or all triaged false positive with notes)
- [ ] `audit_apply_log.json` shows applied fixes for all dataset code injection paths flagged
- [ ] `extract_runtime_style_guide_strings.py` run date ≥ last Swift edit date
- [ ] Manual smoke: load Style Guide for fixture users (ash, maria, synth charts with prior `"safe"` issue) — Code sections read as full valuable sentences

---

## 9. Key files reference

| File | Role |
|------|------|
| `tools/content_audit_inventory.py` | What gets audited; field rules |
| `tools/content_audit_checks.py` | Quality checks |
| `tools/content_audit.py` | Audit CLI |
| `tools/content_audit_apply.py` | Mechanical + Gemini apply (canonical only) |
| `tools/content_audit_tool.py` | Web UI (localhost:8422) |
| `tools/extract_runtime_style_guide_strings.py` | Swift → audit snapshot |
| `tools/production_audit_harness.py` | Regenerate composed blueprint fixtures |
| `data/style_guide/astrological_style_dataset.json` | Code bullets, mood opposites, house biases |
| `data/style_guide/blueprint_narrative_cache.json` | AI narratives |
| `Cosmic Fit/InterpretationEngine/DeterministicResolver.swift` | **Code merge logic** |
| `Cosmic Fit/InterpretationEngine/BlueprintComposer.swift` | Assembles blueprint for UI |
| `Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift` | Fallback copy |
| `Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift` | Overlay append strings |
| `data/style_guide/audit_apply_log.json` | Correction history |
| `docs/fixtures/production_audit/blueprints/*.json` | Composed output snapshots |

---

## 10. Commands cheat sheet

```bash
# Setup
source .venv/bin/activate
pip install -r tools/requirements.txt

# Full quality loop
python3 tools/extract_runtime_style_guide_strings.py
python3 tools/production_audit_harness.py
python3 tools/content_audit.py --sources dataset,blueprints,cache,runtime,rendered --format all

# Review + amendments UI
python3 tools/content_audit_tool.py --port 8422

# Apply fixes (dataset + cache; not composed)
python3 tools/backup_style_guide_sources.py backup --label YYYY-MM-DD
python3 tools/content_audit_apply.py --handoff data/style_guide/audit_handoff_pack.json \
  --report data/style_guide/audit_report.json --phase all --resume

# Verify composed code has no junk
python3 -c "
import json, glob
bad=[]
for f in glob.glob('docs/fixtures/production_audit/blueprints/*.json'):
    bp=json.load(open(f))
    for section in ('leanInto','avoid','consider'):
        for i,b in enumerate(bp.get('code',{}).get(section,[])):
            if len(str(b).split())<5: bad.append((f,section,i,b))
print('short code bullets:', len(bad))
for x in bad[:20]: print(x)
"
```

---

## 11. Summary for product owner

**You were right to expect Lean Into / Avoid to be audited and fixed.** The pipeline **did audit and rewrite full `code_avoid` / `code_leaninto` sentences in the dataset**, but **a separate runtime path injects short mood keywords into Avoid** without the same quality gate. That is why `"safe"` could appear before amends and **can still appear now**.

Fixing this requires **engine + dataset + audit rule changes**, not another narrative-cache rewrite pass alone.

---

*End of handoff. Update this document when phases complete.*
