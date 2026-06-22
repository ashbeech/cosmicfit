# Colour Name Rename — Full Handoff

**Date:** 2026-06-19  
**Audience:** AI developer or engineer implementing a display-name refactor  
**Repo:** `/Users/ash/dev/mobile_apps/cosmicfit`  
**Status:** Investigation complete — **rename only, keep hex values** (unless product explicitly approves hex changes later)

---

## 1. Executive summary

Cosmic Fit’s Style Guide shows **colour name + hex swatch** pairs. Partner testing found that many labels **do not match what users logically expect from the words** — e.g. **“Magenta Red”** displays a bright pink-magenta (`#CC0066`), and **“Steel Blue”** displays a dark petrol-teal (`#085267`), not a grey-based steel blue.

This is **not a broken colour engine** and **not a Pantone compliance issue**. The engine chose hex values for **wardrobe coherence and chart personalisation**; names were **internal shorthand** never validated against plain-English colour logic.

**Approved direction:** Refactor **display names only**. Keep all hex values unless product decides otherwise.

**Do not:** Re-label swatches with Pantone numbers/names without a Pantone license (see §8).

---

## 2. Partner feedback (verbatim intent)

> “I’m not comparing it to a Pantone swatch though, I’m comparing it to logic. Magenta ‘red’ is super pink, steel blue is teal when logically we all know it’s more grey based. Just saying it won’t make sense to the user to see magenta red and see a bright pink colour.”

**What this means for implementation:**

| Dimension | Partner expectation | Current app behaviour |
|-----------|--------------------|-----------------------|
| Label | Words match what you see | Words describe internal/astrological “role” or borrowed fashion jargon |
| Hex | (Not asking to change) | Chosen for seasonal family + chart accent logic |
| Pass/fail for QA | “Would I look for this name in a shop?” | Do **not** use “matches Pantone X on Google” |

---

## 3. How the colour engine works (why names ≠ external standards)

### 3.1 Two independent pipelines

```
┌─────────────────────────────────────────────────────────────────┐
│ TEMPLATE COLOURS (neutrals, core, accent templates, support,    │
│ light/deep anchors)                                               │
│   PaletteFamily → PaletteLibrary.library (name keys)            │
│   → PaletteLibrary.colourNameToHex[name] → fixed hex            │
│   Direction: NAME → HEX (name is primary key)                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    BlueprintComposer → Style Guide UI

┌─────────────────────────────────────────────────────────────────┐
│ CHART-DERIVED COLOURS (accents, MC visibility, depth overlays,  │
│ luminary/ruler signatures)                                        │
│   Sign + temperature → SignAccentExpressions (L, C, h, name)    │
│   → ColourMath.lchToHex(L,C,h) → computed hex                   │
│   Direction: LCH first, NAME bolted on for UI/copy              │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Engine reasoning (what it optimises for)

The V4 pipeline (`ColourEngine.evaluateProduction`) answers:

> **“Given this birth chart, what coherent wardrobe palette fits this person?”**

**Not:** “What is the official name for this hex in Pantone/CSS?”

**Pipeline order (locked):**

1. Normalise eight weighted chart drivers (`Normalizer`, `DriverWeights`)
2. Raw scores + modifiers (`Scoring`, `Modifiers`)
3. Classify **PaletteFamily** (12 seasonal families: Light Spring … Bright Winter)
4. Canonical variables + cluster from family
5. Load **template** from `PaletteLibrary.library(for:)`
6. Optional depth/black/MC overlays
7. **Chart signatures** — Sun + Ascendant ruler via `ChartSignatureResolver` (LCH archetypes projected into family envelope)
8. **Accent slots** — `AccentResolver` picks from `SignAccentExpressions` by spike scoring vs personal palette hexes
9. `BlueprintComposer.buildV4PaletteSection` assembles `PaletteSection` for UI + persistence

**Design goals:**

- Perceptual coherence within the seasonal family
- Deterministic output (same chart → same palette)
- Chart individuation (accents/signatures differ by placements)
- Readable copy labels (currently **underspecified** for plain English)

### 3.3 Key files

| File | Role |
|------|------|
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/PaletteLibrary.swift` | 144 `colourNameToHex` entries + 12 family templates |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/SignArchetypes.swift` | `SignAccentExpressions` — 106 accent candidates (L,C,h,name) |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/ChartSignatureResolver.swift` | Luminary/ruler LCH archetypes (names resolved via `nearestColourName`) |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/AccentResolver.swift` | Uses `SignExpression.name` as `displayName` |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/VisibilityAccentResolver.swift` | Same name passthrough |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/ColourEngine.swift` | Orchestrator |
| `Cosmic Fit/InterpretationEngine/BlueprintComposer.swift` | Builds `BlueprintColour` rows for UI/storage |
| `Cosmic Fit/UI/Views/Palette/ColourMath.swift` | Lab/LCH/hex utilities |
| `Cosmic Fit/InterpretationEngine/ColourEngineV4/VariationSlots.swift` | Curated substitution map keyed by **colour name strings** (currently not invoked in engine step 11, but tests + map must stay consistent) |

### 3.4 Canonical examples (partner-reported)

#### Magenta Red — template (`palette_library`)

- **Family:** Bright Winter core slot
- **Current name:** `magenta red`
- **Hex:** `#CC0066` (unchanged)
- **What users expect:** Red leaning magenta, or at least “red”
- **What they see:** Bright pink-magenta
- **Why it exists:** In-house Bright Winter token; docs reference substitution from True Winter `blue-red` slot (`docs/archive/v4_per_user_variation_spec.md`). Never sourced from Pantone Viva Magenta (`#BE3455`, ΔE ~15) or CSS magenta (`#FF00FF`, ΔE ~71).

#### Steel Blue — chart accent (`sign_accent_expression`)

- **Source:** Capricorn / cool / `SignAccentExpressions`
- **LCH:** L=32, C=22, h=235
- **Computed hex:** `#085267`
- **Current name:** `Steel Blue`
- **What users expect:** Grey-based muted blue (everyday “steel blue”)
- **What they see:** Dark petrol / blue-teal
- **Why it exists:** “Saturnine / steely” evocative label on a Capricorn cool candidate; **not** CSS `steelblue` `#4682B4` (ΔE ~26)

---

## 4. What we are NOT doing

| Item | Reason |
|------|--------|
| Pantone labelling in UI | No Pantone in app today; adding it requires licensing + official colour data |
| Changing hex “to match Pantone” | Out of scope unless product approves; breaks calibration regression |
| Expecting users to learn engine vocabulary | Partner feedback rejects this |
| Renaming only in UI layer while keeping broken internal keys | Possible but **discouraged** — names are keys in `PaletteLibrary`, `VariationSlots`, fixtures, narratives |

---

## 5. Audit tooling (already built)

### 5.1 Script

```bash
python3 tools/colour_name_hex_audit.py
python3 tools/colour_name_hex_audit.py --delta-e 8 --css-warn-delta-e 3
```

### 5.2 Outputs

| Path | Contents |
|------|----------|
| `data/style_guide/colour_name_hex_audit.json` | Full 262-pair inventory + flags |
| `data/style_guide/colour_name_hex_audit.md` | Tier 1/2/3 human summary |

### 5.3 Metal-fabric vocabulary audit (Phase 4)

```bash
python3 tools/colour_metal_fabric_audit.py
python3 tools/colour_metal_fabric_audit.py --validate-proposals data/style_guide/colour_metal_fabric_proposals.json
```

| Path | Contents |
|------|----------|
| `data/style_guide/colour_metal_fabric_audit.json` | 25 flagged metal-themed palette names with reachability maps |
| `data/style_guide/colour_metal_fabric_audit.md` | Flagged list with context and nearest-neighbour data |
| `data/style_guide/colour_metal_fabric_proposals.json` | AI inference proposals (17 renames, 8 keeps) |

### 5.4 Audit counts (2026-06-19 run, post-Phase 1)

| Metric | Count |
|--------|------:|
| Total `(name, hex)` pairs | 262 |
| PaletteLibrary tokens | 144 |
| SignAccentExpressions | 106 |
| Chart signature archetypes | 12 |
| **Tier 1** — label implies standard colour, ΔE > 5 | **2** (down from 12; remaining are intentional Phase 1 renames) |
| **Tier 2** — near-duplicate of library token (ΔE ≤ 5) | **9** |
| **Tier 3** — weaker CSS token overlap | **13** |

**Tier 1** original 12 items resolved by Phase 1 renames. 2 auto-matched residuals (`hot pink` ↔ CSS `hotpink`, `Dark Cyan` ↔ CSS `darkcyan`) are accepted deviations.  
**Tier 2** = Phase 2 consolidation (optional).  
**Tier 3** = Phase 3 if partner flags more in testing.

### 5.4 Naming rule for new labels

> **“Would someone shopping for this exact swatch use this word?”**

If not → rename. Prefer **plain English** over fashion jargon. Avoid words that imply a specific standard (steel, magenta, cerulean) unless the swatch matches common understanding.

---

## 6. Phase 1 — Tier 1 rename table (PROPOSED — product review required)

**Policy:** Keep hex. Change name in source files. Update all string references to old name.

| # | Current name | Hex (KEEP) | Source | Context | What user sees | Proposed plain-English name | Rationale |
|---|--------------|------------|--------|---------|----------------|----------------------------|-----------|
| 1 | **magenta red** | `#CC0066` | `palette_library` | Bright Winter core | Hot pink-magenta | **hot pink** | Partner case; “red” misleads |
| 2 | **Steel Blue** | `#085267` | `sign_accent_expression` | capricorn/cool | Dark petrol-teal | **deep petrol** | Removes false “steel/grey-blue” expectation |
| 3 | **lime** | `#A4C639` | `palette_library` | Light Spring core | Yellow-green / apple | **apple green** | Not CSS neon lime |
| 4 | **fuchsia red** | `#C81585` | `palette_library` | True Winter accent | Deep magenta-rose | **deep magenta** | Near `mediumvioletred`; “fuchsia” implies `#FF00FF` |
| 5 | **forest green** | `#254D32` | `palette_library` | Deep Autumn core | Very dark green | **dark pine** | “Forest green” implies brighter `#228B22` |
| 6 | **Regal Blue** | `#5485C8` | `sign_accent_expression` | leo/cool | Medium dusty blue | **soft cornflower** | Not royal blue `#4169E1` |
| 7 | **Cerulean** | `#007788` | `sign_accent_expression` | aquarius/neutral | Dark cyan-teal | **dark cyan** | Cerulean implies brighter blue |
| 8 | **Arctic Blue** | `#008ABE` | `sign_accent_expression` | aquarius/cool | Bright cyan-blue | **bright cyan** | Less geographic, matches appearance |
| 9 | **true red** | `#CC0000` | `palette_library` | Bright Winter accent | Deep red (not `#FF0000`) | **deep red** | “True red” over-promises pure red |
| 10 | **electric blue** | `#0080FF` | `palette_library` | Bright Spring core | Bright blue | **bright blue** | Neutral; close to dodger but not exact |
| 11 | **peach** | `#FFCBA4` | `palette_library` | Light Spring core | Light peach | **light peach** | Minor ΔE; clarifies lightness |
| 12 | **clear turquoise** | `#08E8DE` | `palette_library` | True Spring accent | Bright aqua | **bright aqua** | “Turquoise” implies `#40E0D0` |

**Alternative names** (if product prefers slightly more fashion tone):

| Current | Alt A | Alt B |
|---------|-------|-------|
| magenta red | vivid magenta | raspberry |
| Steel Blue | dark teal | saturn teal |
| forest green | deep forest | pine green |
| fuchsia red | rose magenta | plum rose |

**Product must sign off** on final strings before merge.

---

## 7. Phase 2 — Tier 2 near-duplicate renames (optional)

Chart-derived accent labels that are perceptually almost identical to an existing `PaletteLibrary` token. Consider **aligning accent display name to library name** for consistency (hex already matches or is very close).

| Accent name | Accent hex | Library token | Library hex | ΔE | Suggested action |
|-------------|------------|---------------|-------------|-----|------------------|
| Dusty Fern | `#7B8967` | moss sage | `#7A8B6A` | 1.5 | Rename accent → **moss sage** OR keep distinct “dusty fern” |
| Dark Slate | `#263E4F` | petrol | `#1B3A4B` | 2.8 | Rename → **deep petrol** (avoid “slate” if not grey) |
| Saturn Slate | `#273E51` | petrol | `#1B3A4B` | 3.5 | Rename → **deep petrol** or **saturn blue** |
| Warm Slate | `#5B3A31` | bark brown | `#5C4033` | 3.8 | Rename → **warm bark** |
| Moonstone | `#5E8B91` | muted teal | `#5E8E8E` | 3.9 | Rename → **muted teal** (unify) |
| Antique Brass | `#C47A3E` | copper | `#B87333` | 4.0 | Rename → **warm copper** |
| Burnt Sienna | `#CB674C` | terracotta | `#CC6644` | 4.3 | Rename → **terracotta** (unify) or **burnt terracotta** |
| Opal Teal | `#5C8383` | muted teal | `#5E8E8E` | 4.7 | Rename → **muted teal** or **opal grey-teal** |
| Fertile Moss | `#4E6B39` | moss | `#5B7744` | 4.9 | Rename → **deep moss** |

---

## 8. Phase 3 — Tier 3 (weaker signal, partner-driven)

Compound names where one word overlaps CSS vocabulary but full phrase is wardrobe-specific. Rename only if partner/user testing flags confusion.

| Current name | Hex | Issue |
|--------------|-----|-------|
| black cherry | `#4D0F28` | “Black” suggests `#000000` |
| blue-black | `#0D1B2A` | Same |
| soft black / clear black / black brown | various | Same |
| olive gold | `#A28C3A` | “Olive” suggests `#808000` |
| Iced Plum | `#9665A3` | “Plum” much lighter than CSS plum |
| Teal Moss, Teal Sage, Burnished Teal, etc. | various | “Teal” implies `#008080` but swatches vary |

Full list: `data/style_guide/colour_name_hex_audit.md` § Tier 3.

---

## 9. Pantone / legal (for context — do not implement without license)

- The app **does not currently use Pantone** anywhere in `Cosmic Fit/**/*.swift`.
- Pantone references exist **only** in `tools/colour_name_hex_audit.py` (offline nearest-match analysis).
- Pantone LLC claims trademark/copyright over **PANTONE** mark, colour numbers, names, and **cross-referencing** as equivalent without permission.
- **Safe:** plain English names, W3C/CSS names where visually accurate.
- **Unsafe without license:** displaying “Pantone 18-1750”, “PMS 185 C”, or “Pantone equivalent” in consumer UI.

---

## 10. Authorship / provenance (why names are idiosyncratic)

| Fact | Detail |
|------|--------|
| Git author | Ash Beech (`ash@bullish.design`) on all palette commits |
| `magenta red` introduced | 2026-04-19 commit `98acf51` (V4 engine) |
| `Steel Blue` introduced | 2026-05-08 commit `1a07eeb` (`SignArchetypes.swift` created) |
| AI assistance | V4 commit message: “Made-with: Cursor” |
| External colour standard | **None** — names are Cosmic Fit wardrobe tokens |

---

## 11. Implementation guide

### 11.1 PaletteLibrary renames (template tokens)

For each rename (e.g. `magenta red` → `hot pink`):

1. **`PaletteLibrary.swift`**
   - Rename key in `colourNameToHex` (preserve hex value).
   - Update every occurrence in `library` template arrays (`coreColours`, `accentColours`, etc.).
   - Update `supportLibrary` if present.
2. **`VariationSlots.swift`**
   - Grep `sourceColourName:` and substitution map for old string.
3. **`docs/fixtures/v4_dataset.json`** (if palette gate compares colour **names**)
   - Regenerate via `V4CalibrationRegression_Tests` if documented in test file.
4. **Grep repo** for old string:
   ```bash
   rg -n "magenta red" --glob '*.{swift,json,md,py}'
   ```
5. **Narrative / audit fixtures**
   - `docs/fixtures/production_audit/blueprints/*.json` embed colour names in `name` fields and `narrativeText`. Bulk-update or regenerate if narratives must stay in sync.
   - `data/style_guide/blueprint_narrative_cache.json` — grep for old names.

**Important:** Template names are **lookup keys**. Renaming is a **breaking change** for any code, test, or cached blueprint that stores the old string.

### 11.2 SignAccentExpressions renames (accent labels)

For each rename (e.g. `Steel Blue` → `deep petrol`):

1. **`SignArchetypes.swift`** — change only the `name:` field on the `SignExpression` line; **do not change L, C, h**.
2. No `PaletteLibrary` change unless unifying with a library token (Tier 2).
3. Grep tests and fixtures for old display name.

### 11.3 Display vs internal key (discouraged)

Could add a `displayName` map separate from engine keys — **more complexity**, two sources of truth. **Prefer renaming at source** unless persistence migration is too costly.

### 11.4 Persisted blueprints

`BlueprintStorage` saves `BlueprintColour.name` + `hexValue`. Users with cached Style Guides will show **old names** until blueprint regeneration (re-onboard, clear cache, or bump schema + migration). Consider:

- Bump `BlueprintStorage.schemaVersion` if adding migration shim
- Or document “existing users regenerate blueprint on next app update” if engine re-runs on launch

Check `Cosmic Fit/Core/Utilities/BlueprintStorage.swift` for current schema version policy.

### 11.5 Tests to run after renames

```bash
# Core engine
xcodebuild test -scheme "Cosmic Fit" -only-testing:CosmicFitTests/ColourEngineV4_UnitTests
xcodebuild test -scheme "Cosmic Fit" -only-testing:CosmicFitTests/V4CalibrationRegression_Tests
xcodebuild test -scheme "Cosmic Fit" -only-testing:CosmicFitTests/MariaAshLocked_Tests
xcodebuild test -scheme "Cosmic Fit" -only-testing:CosmicFitTests/VariationSlots_Tests
xcodebuild test -scheme "Cosmic Fit" -only-testing:CosmicFitTests/PaletteGridViewModel_Tests

# Re-run audit
python3 tools/colour_name_hex_audit.py
```

**Known test debt:** `Cosmic FitTests/BlueprintLensEngine_Payload_Tests.swift` line ~70 uses `Steel Blue` with `#4682B4` (CSS value) — inconsistent with production `#085267`. Fix during rename pass.

### 11.6 CI guard (recommended)

Add a test or script assertion:

```bash
rg -n "Pantone|PMS " "Cosmic Fit/" && exit 1 || exit 0
```

Prevent accidental Pantone labelling in app code.

---

## 12. Suggested PR sequence

| PR | Phase | Scope | Risk |
|----|-------|-------|------|
| **PR1** | 1 | PaletteLibrary Tier 1 renames (8 tokens) + VariationSlots + downstream | Medium |
| **PR2** | 1 | SignAccentExpressions Tier 1 renames (4 tokens) + test debt fix | Low |
| **PR3** | 2–3 | Optional Tier 2/3 + blueprint fixture sweep | Medium |
| **PR4** | 1–3 | Audit refresh + optional Pantone CI guard | Low |
| **PR5 prep** | 4 | Metal-fabric audit tool + AI proposals + validators | Low |
| **PR5** | 4 | Apply Phase 4 metal-fabric renames (17) + context-aware fixture sweep | Medium |
| **PR6** | All | Final test suite + both audits + apply report | Low |

---

## 13. Copy for testers (include in TestFlight notes)

> Colour names in the Style Guide describe what you’re seeing, not Pantone or paint-chip codes. We recently renamed some swatches where the old label didn’t match the colour (e.g. “Steel Blue” that looked teal). If a **name still doesn’t match what you see**, please screenshot **name + swatch** — that’s exactly the feedback we want.

---

## 14. Related documents in repo

| Path | Relevance |
|------|-----------|
| `data/style_guide/colour_name_hex_audit.md` | Machine-generated audit tiers |
| `data/style_guide/colour_name_hex_audit.json` | Full audit data |
| `tools/colour_name_hex_audit.py` | Audit script |
| `docs/archive/v4_engine_handoff_to_next_dev.md` | V4 engine architecture |
| `docs/archive/v4_accent_refactor_handoff_next_steps.md` | SignAccentExpressions design |
| `docs/archive/v4_per_user_variation_spec.md` | `magenta red` substitution context |
| `docs/archive/palette_wardrobe_roles_handoff.md` | Naming metadata strategy |

---

## 15. Conversation decisions log

| Date | Decision |
|------|----------|
| 2026-06-19 | Investigated name/hex derivation — two pipelines, no external standard |
| 2026-06-19 | Built systematic audit (`colour_name_hex_audit.py`) |
| 2026-06-19 | Partner feedback: plain-English logic beats Pantone comparison |
| 2026-06-19 | Confirmed app does **not** use Pantone labelling today |
| 2026-06-19 | **Approved direction:** rename labels, **keep hexes** |
| 2026-06-19 | Phase 1 = Tier 1 audit (12 rows); product sign-off on proposed names |

---

## 16. Checklist for implementing developer

- [x] Product sign-off on §6 proposed names
- [x] Implement Phase 1 PaletteLibrary key renames (8 tokens) + hex unchanged
- [x] Implement Phase 1 SignAccentExpressions `name` field renames (4 tokens)
- [x] Update `VariationSlots.swift` references
- [x] Update tests, fixtures, narrative JSON for Phase 1
- [x] Fix `BlueprintLensEngine_Payload_Tests` Steel Blue hex mismatch (#4682B4 → #085267)
- [x] Re-run `colour_name_hex_audit.py` — Tier 1: 12 → 2 (auto-catch only)
- [x] Build `tools/colour_metal_fabric_audit.py` — 25 flagged (14 palette, 11 accents)
- [x] AI inference pass → `colour_metal_fabric_proposals.json` (17 renames, 8 keeps)
- [x] Run `--validate-proposals` — 0 issues (0 BLOCK, 0 WARN)
- [x] Risk audit: hardware-copy bleed check (warmMetals in Cosmic_FitTests preserved)
- [x] Phase 4 sign-off on §17 rename table
- [x] Apply Phase 4 renames in PaletteLibrary + SignArchetypes + VariationSlots
- [x] Update InterpretationTextLibrary narrative `dailyColours` references
- [x] Context-aware fixture sweep (palette fields only, hardware fields preserved)
- [ ] Decide blueprint migration strategy for cached users
- [ ] Manual QA: Bright Winter profile shows `hot pink` (not `magenta red`) at `#CC0066`
- [ ] Manual QA: Capricorn-cool accent shows `Deep Petrol` (not `Steel Blue`) at `#085267`
- [ ] Manual QA: Deep Autumn accent shows `warm umber` (not `aged brass`) beside Cool metal tone
- [ ] Partner re-test with §13 tester copy

---

## 17. Phase 4 — Metal-fabric disambiguation

### 17.1 Problem

Daily Fit shows **Style Palette swatches** (fabric colours) beside a **Metal Tone** slider (Cool / Mixed / Warm for jewellery/hardware). Names like `aged brass`, `Antique Brass`, `Burnt Copper` share vocabulary with `recommendedMetals` but are **not engine-linked** — they are naming friction.

### 17.2 Decision test

> **"Would I look for this name in the clothing rail, or only at a hardware counter?"**

- **Hardware counter** → rename to fabric-first plain English (hex unchanged)
- **Clothing rail** → KEEP (document rationale)

### 17.3 Tooling

| Tool | Command |
|------|---------|
| Flag audit | `python3 tools/colour_metal_fabric_audit.py` |
| Validate proposals | `python3 tools/colour_metal_fabric_audit.py --validate-proposals data/style_guide/colour_metal_fabric_proposals.json` |

### 17.4 Phase 4 rename table (approved)

| # | Current | Hex | Source | Verdict | Proposed | Rationale |
|---|---------|-----|--------|---------|----------|-----------|
| 1 | `aged brass` | `#8E7530` | palette_library | rename | **warm umber** | Hardware-counter; swatch is dark olive-brown |
| 2 | `antique gold` | `#C9A84C` | palette_library | rename | **deep honey** | Hardware-counter; swatch is warm golden-brown |
| 3 | `brushed pewter` | `#7C7D7D` | palette_library | rename | **smoke grey** | "Brushed" is a metal-finish descriptor |
| 4 | `chrome silver` | `#DBE0E3` | palette_library | rename | **frost grey** | "Chrome" is unambiguously hardware |
| 5 | `soft copper` | `#BD7E55` | palette_library | rename | **warm sienna** | "Soft copper" reads as metal patina |
| 6 | `soft gold` | `#D4AF37` | palette_library | rename | **rich honey** | "Soft gold" reads as jewellery beside Metal Tone slider |
| 7 | `Antique Brass` | `#C47A3E` | sign_accent | rename | **Rich Sienna** | Hardware-counter; warm orange-brown |
| 8 | `Burnished Gold` | `#D59B49` | sign_accent | rename | **Tawny Amber** | "Burnished" is metal-finish + "gold" is metal |
| 9 | `Burnt Copper` | `#AE4D37` | sign_accent | rename | **Warm Ember** | Hardware-counter; warm rust-red |
| 10 | `Dark Bronze` | `#664330` | sign_accent | rename | **Deep Umber** | Hardware-counter; deep brown |
| 11 | `Gunmetal` | `#19475A` | sign_accent | rename | **Ink Teal** | LCH produces dark teal, not grey; misnamed |
| 12 | `Lunar Silver` | `#A6C6D0` | sign_accent | rename | **Lunar Mist** | "Silver" creates metal association; swatch is cool blue-grey |
| 13 | `Pewter` | `#25515B` | sign_accent | rename | **Stone Teal** | LCH produces dark teal, not grey; misnamed |
| 14 | `Platinum Frost` | `#91B5CF` | sign_accent | rename | **Frost Blue** | "Platinum" is unambiguously precious metal |
| 15 | `Saffron Gold` | `#C79538` | sign_accent | rename | **Saffron Amber** | Keeps saffron warmth, removes gold |
| 16 | `Soft Silver` | `#4D7E8C` | sign_accent | rename | **Slate Teal** | LCH produces teal, not silver; misnamed |
| 17 | `Solar Gold` | `#DFA74B` | sign_accent | rename | **Solar Amber** | Keeps solar (Leo), removes gold |

**Kept (clothing-rail vocabulary):** `bright gold`, `bronze`, `copper`, `gunmetal` (library), `olive gold`, `pewter` (library), `silver`, `steel grey`

### 17.5 Allowed residuals after Phase 4

Old metal-themed names may legitimately remain in:
- `recommendedMetals` / hardware copy (`DeterministicResolver.swift`)
- Hardware keyword sets (`warmMetals`, `coolMetals` in tests and engine)
- Handoff docs, audit reports, backups
- Narrative text where the term means jewellery metal, not fabric

### 17.6 Collision report

Zero duplicate names in PaletteLibrary + SignAccentExpressions + chart signature display labels after Phase 4.

---

*End of handoff.*
