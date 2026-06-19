# Style Guide Content — Current State Handoff

**Date:** 2026-06-17  
**Audience:** AI developer or engineer with **no prior context** on this project  
**Purpose:** Exact snapshot of Style Guide content quality, what was fixed, what audit numbers mean, and what still needs action

---

## TL;DR

| Question | Answer |
|----------|--------|
| Is the **single-word Avoid bullet bug** fixed at source? | **Yes.** All 479 `opposites.mood` entries are full sentences. Runtime guard blocks short tokens. |
| Can a **fresh compose** still show `"invisible"`, `"safe"`, etc. in The Code → Avoid? | **No** — not from current dataset + resolver. |
| Why does a full audit still report **185 critical** issues? | Mostly **stale composed blueprint fixtures** generated before the mood fix. Not live source. |
| Is the **dataset** clean? | **Yes — 0 issues** on 5,305 items (`python3 tools/content_audit.py --sources dataset`). |
| Is the **entire Style Guide surface** audit-clean (26,910 items)? | **No** — narrative cache has quality heuristics flags; fixtures are stale; some audit false positives. |
| Can **existing users** still see old single-word bullets? | **Yes**, if their blueprint was composed before remediation and never regenerated. |
| Are **editorial tag leaks** (`# Suit of …`, `{placeholder}` in UI) present in runtime source? | **No** in live source. Tarot `# Suit of …` tags were removed. `{domain}` / `{modifier}` in Swift are runtime templates, not leaks. |

**Do not use** `docs/style_guide_content_audit_handoff.md` for current state — it predates the mood remediation pass and says mood tokens were unchanged. **This document supersedes it** for prod-readiness questions.

---

## 1. The bug everyone cared about

### Symptom

In **The Code → Avoid**, users sometimes saw bare single-word bullets mixed with proper sentences:

```json
"avoid": [
  "Deliberately fading into the background to make others comfortable…",
  "Dull invisible clothing that treats style as a neutral act…",
  "invisible",
  "dimmed",
  "unnoticed"
]
```

### Root cause

1. **Source data:** `opposites.mood` in `astrological_style_dataset.json` stored short anti-mood tokens (`"invisible"`, `"safe"`, `"rushed"`, etc.).
2. **Runtime injection:** `DeterministicResolver.resolveCode()` appended those tokens into the Avoid list alongside real `code_avoid` sentences.
3. **Audit gap (now fixed):** The audit classified `opposites.mood` as `KEYWORD`, so short tokens were never flagged in the dataset layer — only in composed blueprint snapshots.

### What was fixed (2026-06-17)

**A. Dataset rewrite** — all 479 `opposites.mood` entries expanded to full sentences (≥5 words, terminal punctuation). Verified: **0 short fragments** remain in live dataset.

Example (Leo cluster, live data):

- *"Refuse to be invisible by rejecting muted tones that shrink your natural star power."*
- *"Never wear anything dimmed or dull that forces you to hide in the background."*
- *"Avoid wallflower dressing and garments that let you slip entirely unnoticed into a room."*

Backup before mood pass: `data/style_guide/backups/pre_correction_pre-mood-remediation-2026-06-17/`

**B. Runtime guard** — `DeterministicResolver.swift` now skips mood tokens unless ≥5 words **and** terminal `.` / `!` / `?`:

```swift
// Cosmic Fit/InterpretationEngine/DeterministicResolver.swift (~1003–1007)
for oppMood in entry.opposites.mood {
    let wordCount = oppMood.split(separator: " ").count
    let hasTerminal = oppMood.hasSuffix(".") || oppMood.hasSuffix("!") || oppMood.hasSuffix("?")
    guard wordCount >= 5 && hasTerminal else { continue }
    avoidItems.append((oppMood, combo.aggregateWeight * 0.5))
}
```

**C. Audit reclassification** — `opposites.mood` is now `MOOD_AVOID_TOKEN` (same rules as code bullets) in `tools/content_audit_inventory.py` and included in `CODE_INJECTION_FIELD_KINDS`.

**D. Apply pass** — `data/style_guide/audit_apply_log.json`: **986 applied**, 33 failed, 3 skipped. All **479 mood rewrites applied**. Failures are stale Swift string targets in `HouseSectOverlayGenerator.swift` (strings already manually updated — not live UI problems).

---

## 2. Why audit numbers disagree

You will see conflicting numbers depending on **which audit was run** and **which layers were included**. This is expected.

### Dataset-only audit (source of truth for Code bullets)

```bash
python3 tools/content_audit.py --sources dataset --format json
```

| Metric | Result |
|--------|--------|
| Items | 5,305 |
| Flagged items | **0** |
| Total issues | **0** |

This is the correct gate for "are Code bullet sources clean?"

### Full-surface audit (all layers — misleading headline number)

When run with `--sources dataset,blueprints,cache,runtime,rendered` (or equivalent full scan), expect roughly:

| Layer | Items (approx) | Critical issues | Notes |
|-------|----------------|-----------------|-------|
| `astrological_style_dataset.json` | 5,305 | **0** | Clean |
| `blueprint_narrative_cache.json` | 9,216 | **0** | Quality heuristics only (HIGH/MEDIUM) |
| Composed blueprint fixtures | 7,136 | **~178** | **Stale snapshots** — see below |
| Runtime strings | 69 | 0 critical | `{domain}` template false positives |
| Rendered templates | 5,184 | 0 critical | Mostly `pidgin_english` heuristics on valid prose |

The **185 critical** count from a prior full run is almost entirely **`nonsense_fragment`** hits on **single-word Avoid bullets in stale fixtures** — not on live dataset text.

### Where stale fixtures live

```
docs/fixtures/production_audit/blueprints/*.json
```

Verified counts in those files (as of 2026-06-17):

- **181** Avoid bullets under 5 words
- **173** single-word Avoid bullets (e.g. `"invisible"`, `"aggressive"`, `"conventional"`)

These files were composed **before** mood remediation. The audit scans them; the apply tool **does not patch them** (derived artifacts, not canonical source).

**To refresh:** regenerate via production audit harness (requires inspector server on port 7777):

```bash
python3 tools/production_audit_harness.py
```

Until regen, any full audit will keep reporting ghost criticals.

### Narrative cache (separate quality bucket)

```bash
python3 tools/content_audit.py --sources cache --format json
```

Recent run: **94 flagged items**, **1,739 issues** — almost all:

- `intra_cluster_repetition` (1,617) — aggregate/corpus check, not a single bad string
- `pidgin_english` (92) — many false positives on intentional editorial voice
- `corpus_overuse`, `keyword_stuffing` — low severity

These are **writing-quality heuristics**, not "internal tag leaked to UI" class bugs. Narrative paragraphs were largely rewritten in prior passes (~507 + 111 cache rewrites in apply log).

---

## 3. How Style Guide content reaches the UI

Understanding this is essential — **fixing bundled JSON does not automatically update what users see**.

```
NatalChart
  → BlueprintTokenGenerator
  → DeterministicResolver.resolveCode()     ← reads astrological_style_dataset.json
  → BlueprintComposer
  → NarrativeCacheLoader                  ← reads blueprint_narrative_cache.json
  → HouseSectOverlayGenerator             ← Swift overlay strings
  → NarrativeTemplateRenderer             ← substitutes {placeholders}
  → CosmicBlueprint
  → BlueprintStorage.save()               ← Documents/cosmic_fit_blueprint.json
  → StyleGuideViewController              ← reads persisted blueprint, NOT live JSON
```

### One-per-life compose

```swift
// Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift (~754–758)
if BlueprintStorage.shared.load() == nil {
    generateAndPersistBlueprint()
} else {
    print("✅ Style Guide already persisted, skipping generation")
}
```

### Implications

| User scenario | Sees fixed Avoid bullets? |
|---------------|---------------------------|
| New install / no saved blueprint | **Yes** (compose from fixed dataset) |
| Deleted app data / forced recompose | **Yes** |
| Existing install with old persisted blueprint | **Maybe not** — old Avoid list frozen on disk |
| Authenticated user with old Supabase blueprint | **Maybe not** — remote pull can overwrite local |

### Schema version

`BlueprintStorage.schemaVersion` is currently **4**. It wipes local blueprint when incremented. **Mood remediation did not bump schema version** — existing users are not auto-recomposed.

**Open product decision:** bump schema to force wipe/recompose on next launch, and optionally sync fresh blueprint to Supabase for authenticated users.

### Bundled resources

JSON in `data/style_guide/` is symlinked into `Cosmic Fit/Resources/`. App rebuild picks up dataset/cache changes, but **only affects the next compose**, not existing persisted blueprints.

---

## 4. UI section → source mapping

| UI section | Source | User-facing? |
|------------|--------|--------------|
| The Blueprint, Textures, Occasions, Hardware, Accessory, Pattern (paragraphs) | `blueprint_narrative_cache.json` + `HouseSectOverlayGenerator.swift` overlays | Yes |
| **The Code — Lean Into / Avoid / Consider** | **`DeterministicResolver`** from `astrological_style_dataset.json` | Yes |
| The Code — Avoid (mood anti-tokens) | `opposites.mood` via resolver (now filtered) | Yes |
| Palette colours, pattern lists, hardware metals/stones | Dataset keywords via resolver | Yes (keywords capitalised at render) |
| Swift fallbacks (no blueprint) | `StyleGuideViewController.swift` literals | Yes (edge case) |

**Critical:** Amending narrative cache paragraphs does **not** fix Code bullets. Code bullets come only from dataset + resolver composition.

---

## 5. Editorial leak scan (separate from mood bug)

A broader content scan was run on runtime sources:

| Source | Editorial leaks |
|--------|-----------------|
| `TarotCards.json` | **0** — four `# Suit of …` tags removed |
| `astrological_style_dataset.json` | **0** |
| `blueprint_narrative_cache.json` (composed) | **0** |
| Composed blueprint fixtures | **0** editorial tags (but stale mood tokens remain) |
| `HouseSectOverlayGenerator.swift` | **0** — `{domain}` / `{modifier}` are Swift interpolation templates filled at runtime |

No `TODO`/`FIXME` markers or literal unfilled `{placeholder}` leaks in shipped content.

`data/style_guide/extracted_runtime_strings.json` is an **audit inventory file**, not user-facing.

### Minor tarot cosmetic (not blocking)

6 tarot style-edit strings have double spaces (Wheel of Fortune III, Four of Cups, etc.). Cosmetic only.

---

## 6. What “prod ready” means in practice

### Ready for prod ✅

- **Code bullet source data** — dataset audit passes at 0 issues
- **Runtime path** — resolver blocks short mood tokens even if dataset regresses
- **Editorial tag leaks** — none in live runtime source
- **Fresh compose** — produces full-sentence Avoid bullets from mood opposites

### Not prod-ready if interpreted as “full audit zero” ❌

- Stale composed fixtures still trigger 178 critical `nonsense_fragment` in full scans
- Narrative cache has heuristic quality flags (mostly non-blocking)
- Existing persisted blueprints may show pre-remediation Avoid bullets until regenerated

### Recommended ship checklist

1. **Dataset audit:** `--sources dataset` → 0 issues ✅ (done)
2. **Manual spot-check:** Force refresh / wipe blueprint, open Style Guide → The Code → Avoid — no single-word bullets
3. **Decide on schema bump** for existing users (see §3)
4. **Optional:** Regenerate `docs/fixtures/production_audit/blueprints/` so CI/audit reflects current compose
5. **Optional:** Bump schema + Supabase sync for authenticated cohort

---

## 7. Key files and tools

### Canonical content (patch these)

| File | Role |
|------|------|
| `data/style_guide/astrological_style_dataset.json` | Code bullets, mood opposites, keywords, biases |
| `data/style_guide/blueprint_narrative_cache.json` | AI narrative paragraph templates |
| `Cosmic Fit/InterpretationEngine/DeterministicResolver.swift` | Code merge + mood filter |
| `Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift` | House/sect overlay copy |
| `Cosmic Fit/Resources/*.json` | Symlinks to dataset/cache — app bundle |

### Derived / audit artifacts (do not treat as source)

| File | Role |
|------|------|
| `docs/fixtures/production_audit/blueprints/*.json` | **Stale** composed snapshots |
| `data/style_guide/audit_report.json` | Last audit run output — **overwritten per run** |
| `data/style_guide/extracted_runtime_strings.json` | Audit inventory |
| `data/style_guide/audit_apply_log.json` | Rewrite history (986 applied) |

### Tools

```bash
# Source truth — Code bullets (expect 0)
python3 tools/content_audit.py --sources dataset --format json

# Narrative cache quality
python3 tools/content_audit.py --sources cache --format json

# Full surface (expect stale fixture criticals + heuristics)
python3 tools/extract_runtime_style_guide_strings.py
python3 tools/content_audit.py --sources dataset,blueprints,cache,runtime,rendered --format all

# Apply rewrites (requires Gemini API key in .env)
python3 tools/content_audit_apply.py --help

# Regenerate composed fixtures (needs inspector on :7777)
python3 tools/production_audit_harness.py
```

Audit web UI and report paths: `data/style_guide/audit_report.json`, `data/style_guide/audit_report.md`

---

## 8. Remaining work (prioritised)

### P0 — Product decision

- [ ] **Schema bump** (`BlueprintStorage.schemaVersion` 4 → 5) to force recompose for existing users?
- [ ] **Supabase blueprint sync** after recompose for authenticated users?

### P1 — Audit hygiene

- [ ] Regenerate `docs/fixtures/production_audit/blueprints/` via `production_audit_harness.py`
- [ ] Re-run full audit after fixture regen — critical count should drop ~178

### P2 — Quality (non-blocking for Code bullet ship)

- [ ] Tune `pidgin_english` checks to reduce false positives on narrative cache
- [ ] Address `intra_cluster_repetition` at corpus level (editorial, not mechanical)
- [ ] Fix 6 tarot double-space strings
- [ ] Regenerate `docs/fixtures/production_audit/raw/*.jsonl` tarot snapshots (frozen pre-fix copies)

### P3 — Documentation

- [ ] Archive or add deprecation banner to `docs/style_guide_content_audit_handoff.md`

---

## 9. Quick verification scripts

```bash
# Confirm zero short mood tokens in live dataset
python3 - <<'PY'
import json
ds = json.load(open("data/style_guide/astrological_style_dataset.json"))
short = sum(
    1 for e in ds.get("planet_sign", {}).values()
    for m in e.get("opposites", {}).get("mood", [])
    if len(m.split()) < 5
)
print(f"short mood tokens: {short}")  # expect 0
PY

# Count stale single-word Avoid bullets in fixtures
python3 - <<'PY'
import json, glob
single = 0
for f in glob.glob("docs/fixtures/production_audit/blueprints/*.json"):
    for item in json.load(open(f)).get("code", {}).get("avoid", []):
        if len(str(item).split()) == 1:
            single += 1
print(f"fixture single-word avoid bullets: {single}")  # expect ~173 until regen
PY
```

---

## 10. Glossary

| Term | Meaning |
|------|---------|
| **Composed blueprint** | Per-user `CosmicBlueprint` JSON saved after chart + dataset + cache merge |
| **Dataset** | `astrological_style_dataset.json` — deterministic style rules |
| **Mood anti-token** | Entry in `opposites.mood` injected into Avoid as opposite of lean-into mood |
| **Fixture** | Frozen test snapshot under `docs/fixtures/` — not live source |
| **MOOD_AVOID_TOKEN** | Audit field kind treating mood strings as user-facing Avoid bullets |
| **Fresh compose** | Running `BlueprintComposer` with current bundled JSON on empty/missing storage |

---

## 11. Contact points in codebase

- Compose entry: `CosmicFitTabBarController.generateAndPersistBlueprint()`
- Code resolution: `DeterministicResolver.resolveCode()`
- Persistence: `BlueprintStorage.swift` (`schemaVersion = 4`)
- Style Guide UI: `StyleGuideViewController.swift`
- Code bullet rendering: `DosAndDontsSectionView.swift` (displays strings as-is — no auto-sentence expansion)
- Audit inventory rules: `tools/content_audit_inventory.py`
- Audit checks: `tools/content_audit_checks.py`
- Rewrite apply: `tools/content_audit_apply.py`

---

*Generated from verified repo state on 2026-06-17. Re-run dataset audit and fixture counts before acting on stale numbers.*
