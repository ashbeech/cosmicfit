# Palette Engine & Wardrobe Roles — Handoff Snapshot

**Audience:** AI developer or engineer picking up palette UX and **wardrobe-role metadata** after this checkpoint.  
**Status:** Engine and blueprint palette work is largely in place; **wardrobe roles for colours are not implemented** (see §8).  
**Snapshot intent:** Time-capture of decisions, code paths, bugs fixed, and the agreed direction so continuation does not depend on chat history.

---

## 1. Purpose of this document

1. Record **what was built**, **why**, and **where it lives** in the repo.  
2. Record **bugs discovered and fixes** (especially the palette-name-vs-hex issue).  
3. Provide a **decision trail** from the original colour-engine plan to current behaviour.  
4. Specify **exactly what remains** for wardrobe roles: metadata strategy, data threading, UI (tap + slide-in panel), and copy approach — without assuming prior conversation context.

---

## 2. Original plan reference

The authoritative phased plan lived in a Cursor plan file: **`colour_engine_analysis_report_5e6d27da.plan.md`** (user’s Cursor plans folder). Key phases:

| Phase | Topic | Intended scope |
|-------|--------|----------------|
| **1** | Accent rework | Chart-derived accents (`AccentResolver`), `AccentSlot`, diversity guards, `BlueprintComposer`, schema bump, tests/fixtures. |
| **2** | Progressed palette | Age-based progressed colours, separate from Daily Fit initially; generator + UI section. |
| **3** | UX polish (low priority) | **Wardrobe role labels** mapped to bands for tooltips; wire into palette tap interaction. |

**Phase 3 was deliberately deferred** — engine correctness and accents took priority.

---

## 3. Current architecture (high level)

- **V4 colour engine** (`Cosmic Fit/InterpretationEngine/ColourEngineV4/`): family classification → template palette → chart signatures → **accent resolution** → passive validation.
- **Blueprint** persists `PaletteSection` + narrative; **Style Guide** shows **Core Palette** (grid), **Accent Colours**, **Current Phase** (progressed).
- **Daily Fit** is intended to be derived from blueprint palette later; not the focus of recent work.

Flow summary:

```text
BirthChartColourInput → ColourEngine.evaluate… → PaletteTriadV4 + luminary/ruler signatures + accentSlots
       → BlueprintComposer → PaletteSection (+ progressed colours) → Blueprint JSON → UI
```

---

## 4. What has been implemented (since / including this initiative)

### 4.1 Engine & data

- **`AccentResolver.swift`** — Four functional accent slots (Signature, Contrast, Depth, Lift); chart grounding; `accentPop` projection via `SignArchetypes`; saturation override when element &lt; 10%; diversity guard between accents.
- **`SignArchetypes.swift`** — Shared projection; `accentPop` widens L/C/h behaviour vs envelope-only signatures.
- **`PaletteValidator.swift`** — Post-assembly diagnostics (accent pairwise ΔE ≥ 8; global pairwise ΔE ≥ 5); **logging only** for global pairs.
- **`ProgressedPaletteGenerator.swift`** — Secondary-progression-based “growth” colours; **`accentPop: true`** so hues are not crushed by family envelope; deduplication vs natal palette.
- **`Domain.swift`** — `AccentSlot`, `AccentRole`, `ColourEngineResult.accentSlots`.
- **`BlueprintModels.swift`** — `ColourProvenance.chartDerivedAccent(...)` (and existing roles).
- **`BlueprintStorage.schemaVersion`** — Incremented as palette shape evolved (check repo for current integer).

### 4.2 Critical fix: personal palette hex vs colour **names**

**Problem:** `PaletteTriadV4` stores **template colour names** (e.g. `"forest green"`), not `#hex`, for neutrals, core, support, anchors.  

**Accent diversity** and **`ColourMath.labDistanceSquared`** expect **hex strings**. Passing names caused `hexToLab` to fail → distance treated as **infinity** → **cross-palette guard never fired** (accents could sit nearly identical to core greens).

**Fix (must remain in place):**

- In **`ColourEngine.swift`**, when building `personalPaletteHexes` for `AccentResolver`, map template fields through **`PaletteLibrary.hex(for:)`** for neutrals, core, support, light/deep anchors. Luminary and ruler signatures are already hex from `ChartSignatureResolver`.
- In **`BlueprintComposer.swift`**, when passing **`natalPaletteHexes`** to `ProgressedPaletteGenerator`, same mapping for name-based bands; accent slots in `colourResult.palette.accentColours` are already hex after engine step.

### 4.3 Accent diversity vs “personal palette”

- **`AccentResolver.resolve(..., personalPaletteHexes:)`** — After building initial slots, diversity guard:
  - Flags accents too close to **personal palette** swatches (threshold: squared Lab distance &lt; 100 → ΔE ≈ &lt; 10 trigger — verify constants in code).
  - Replaces via **`findAlternative`** using other drivers’ signs; **`avoiding`** list includes resolved accent hexes **and** personal palette hexes.
  - Existing accent-vs-accent guard (ΔE ≥ 8) remains.

**Note:** If no alternative satisfies constraints, original accent may remain (graceful degradation).

### 4.4 Progressed (“Current Phase”)

- Uses **`accentPop`** projection.
- **Dedupes** against full natal set (template-derived hexes + accent hexes + anchors + signatures).
- **Dropped duplicates** are omitted entirely (e.g. progressed Moon same hex as ruler signature → user may see fewer than four progressed rows).

### 4.5 UI / copy renames (non–wardrobe-role)

- Section title **“Personal Palette” → “Core Palette”** (`PaletteGridViewModel`, tests, golden fixtures under `docs/fixtures/`).
- **“Colours of the Moment” → “Current Phase”** (`ProgressedColourPaletteView`).
- Progressed header uses **centred divider** styling aligned with **`ColourPaletteView`** section headers (theme typography/colour).
- **Removed visible labels** under progressed swatches (names kept for accessibility where implemented).
- **Grid spacing** in **`ColourPaletteView`**: `cellSpacing` increased (e.g. 2 → 6 pt — verify in file).

### 4.6 Tests / fixtures

- **`V4CalibrationRegression_Tests`** palette gate may need **`REGENERATE_V4_PALETTE_EXPECTATIONS=1`** after accent logic changes.
- Golden palette grid JSON titles updated for **Core Palette** naming.

---

## 5. Decision tree (how we got here)

```text
Goal: Blueprint-first palette as foundation; Daily Fit derived later.

├── Phase 1 accents (plan)
│   └── Implemented: AccentResolver, schema, composer, tests/fixtures as feasible.
│
├── Phase 2 progressed (plan)
│   └── Implemented: generator + blueprint wiring + Style Guide section; Daily Fit not primary surface.
│
├── Phase 3 wardrobe roles (plan)
│   └── NOT implemented — deferred.
│
├── User feedback: progressed Moon looked “crushed” / duplicate of signature
│   └── Decision: use accentPop for progressed; dedupe vs full natal hex list.
│
├── User feedback: accent too close to core green
│   └── Decision: diversity guard vs personal palette + alternatives.
│       └── Bug found: names passed instead of hex → guard no-op.
│           └── Fix: PaletteLibrary.hex(for:) everywhere personal/natal hex lists are built.
│
└── Wardrobe roles (future)
    └── Decision (conversation): deterministic composition from role + slot + provenance;
        NOT full narrative-style cluster matrix per colour unless product demands it.
```

---

## 6. Audit notes (for maintainers)

These came from a code review pass; **not all need immediate action**.

| Item | Severity | Summary |
|------|----------|---------|
| Trigger vs replacement thresholds in `findAlternative` | Medium | Cross-palette trigger uses one squared threshold; replacement uses fixed ΔE ≥ 8 vs avoidance set — align semantics if QA finds edge cases. |
| `PaletteValidator` accent pair check | Low | Partially redundant after resolver guard; global ΔE ≥ 5 diagnostic still useful. |
| `PaletteValidator` `allHexes` | Low | Confirm luminary/ruler signatures included if “20 colours” diagnostic should be complete (verify current `ColourEngine` assembly). |
| `SignArchetypes` header comment | Cosmetic | ChartSignatureResolver does not delegate to SignArchetypes for its own hex path — comment may overstate sharing. |
| `VariationSlots` | Inventory | Retained but not invoked; large substitution map unused at runtime. |

---

## 7. Key files (quick index)

| Area | Files |
|------|--------|
| Engine pipeline | `ColourEngineV4/ColourEngine.swift`, `AccentResolver.swift`, `SignArchetypes.swift`, `PaletteValidator.swift`, `ProgressedPaletteGenerator.swift`, `ChartSignatureResolver.swift`, `PaletteLibrary.swift`, `Domain.swift` |
| Blueprint | `BlueprintComposer.swift`, `BlueprintModels.swift`, `BlueprintStorage.swift` |
| Narrative | `NarrativeTemplateRenderer.swift` (accent names in templates) |
| Grid UI | `UI/Views/ColourPaletteView.swift`, `UI/Views/Palette/PaletteGrid.swift`, `PaletteGridViewModel.swift`, `ColourCell.swift` |
| Progressed UI | `UI/Views/ProgressedColourPaletteView.swift`, `StyleGuideViewController.swift` (wiring) |
| Tests | `ColourEngineV4_UnitTests`, `MariaAshLocked_Tests`, `V4CalibrationRegression_Tests`, `PaletteGridViewModel_Tests`, golden fixtures in `docs/fixtures/` |

---

## 8. Wardrobe roles — **NOT DONE** (work for next developer)

### 8.1 Product goal

When the user **taps a colour**, show a **module that slides in from the right** with **wardrobe-oriented metadata**: what role that colour plays (foundation, identity, accent function, etc.), plus supporting lines (name, optional chart/source, optional hex).

### 8.2 What already exists in the model (no UI consumption yet)

- **`BlueprintColour`**: `name`, `hexValue`, **`ColourRole`** (`neutral`, `core`, `accent`, `statement`, `support`, `anchor`, `signature`), **`ColourProvenance`** (template band, chart-derived accent with planet/sign, etc.).
- **`AccentSlot`** (engine): functional **`AccentRole`** + planet/sign — **not surfaced on grid cells today**.
- **`PaletteCell`** currently only: **`filled(hex:anchorName:)`** — `anchorName` is the colour display **name**, not a wardrobe label.

**Gap:** UI layer discards role and provenance when building the grid.

### 8.3 Recommended metadata strategy (from design discussion)

**Avoid:** Generating unique wardrobe essays per hex via script from RGB alone, or a full second “narrative cluster” system per colour (combinatorial maintenance).

**Prefer:**

1. **Deterministic assembly** — Headline + body from:
   - **`ColourRole`** (and distinguish light anchor vs deep anchor vs luminary vs ruler in the **view model**, since grid order alone may not encode slot kind).
   - **Accent row:** merge **`AccentRole`** + **`ColourProvenance.chartDerivedAccent`** into templated strings.
   - **Template colours:** optional curated one-liner keyed by **`PaletteLibrary`** **name** or **(family, band, index)**.

2. **Optional script** — Walk `PaletteLibrary` name→hex table for **coverage QA** and optional CSV/JSON for writers (`wardrobeShortLine` per token), **not** automatic meaning from hex.

3. **Personalisation depth** — Increase copy variance only if needed (e.g. **`PaletteFamily`** flavour line); avoid per-archetype-key matrices unless product explicitly requires it.

### 8.4 Implementation checklist (for next session)

1. **Copy deck** — Approve wardrobe headlines/subheads per band, per accent role, per progressed context; approve templates for provenance fill-ins (“Derived from Venus in …”).
2. **Presentation model** — e.g. `WardrobeColourDetail` or `WardrobeColourPresentation` with: `title`, `body`, `subtitle`/`sourceLine`, `hex`, `accessibilitySummary`.
3. **`PaletteGridViewModel.build`** — Emit rich cell payload (or parallel array keyed by `IndexPath`) including role, provenance, accent slot when applicable; **preserve determinism**.
4. **`ColourPaletteView`** — Selection enabled; pass tap to coordinator; **slide-in panel** from trailing edge (custom container / transition — not necessarily system sheet).
5. **`ProgressedColourPaletteView`** — Same interaction model + **Current Phase**-specific copy builder.
6. **Persistence** — If new optional fields are added to `BlueprintColour`, bump **`BlueprintStorage.schemaVersion`** and document migration.
7. **Tests** — Unit tests for mapping `(BlueprintColour, AccentSlot?) → WardrobeColourPresentation` from fixture JSON.

### 8.5 UX notes captured from product discussion

- Tap colour → detail opens **from the right** (slide-in module).
- Tap same colour again or another colour → dismiss or switch selection (exact behaviour to confirm with design).
- Earlier idea: expanded cell + info region — **current direction favours slide-in panel**; reconcile with design if both mentioned.

---

## 9. Regression safeguards (when touching wardrobe work)

- **`V4CalibrationRegression_Tests`** classification gate (family, cluster, variables, secondary pull) should stay **100/100** if engine weights untouched.
- **`MariaAshLocked_Tests`** — follow existing patterns for locked users.
- After accent/palette changes: regenerate palette expectations if test docs describe that workflow.
- Always pass **hex** (via **`PaletteLibrary.hex(for:)`** for name-based template fields) into any **Lab distance** or colour comparison.

---

## 10. Related docs in repo

- `docs/v4_accent_progressed_handoff.md` — Earlier accent/progressed implementation notes.
- `docs/v4_engine_handoff_to_next_dev.md`, `docs/palette_engine_v4_spec.md` — Engine context.
- `docs/palette_grid_4x4_handoff.md` — Grid layout spec (if present).

---

## 11. Snapshot metadata

- **Document purpose:** Single handoff artifact for **wardrobe roles + palette context** at the time this file was added.
- **Next owner:** Should read §4 (especially **4.2**), §5, §8 before implementing UI or copy pipelines.

---

*End of handoff snapshot.*
