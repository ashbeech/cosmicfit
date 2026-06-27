# Phase 4 — Metal-fabric rename apply report

> **Status:** Generated
> **Do not use as current architecture source.** See `README.md` and `docs/README.md`.
> **Generated:** 2026-06-19 by Phase 4 metal-fabric rename tooling

**Generated:** 2026-06-19  
**Programme:** Colour Name Rename — Phase 4 metal-fabric disambiguation

---

## Applied rename table

| # | Old name | New name | Hex | Source |
|---|----------|----------|-----|--------|
| 1 | `aged brass` | `warm umber` | `#8E7530` | palette_library |
| 2 | `antique gold` | `deep honey` | `#C9A84C` | palette_library |
| 3 | `brushed pewter` | `smoke grey` | `#7C7D7D` | palette_library |
| 4 | `chrome silver` | `frost grey` | `#DBE0E3` | palette_library |
| 5 | `soft copper` | `warm sienna` | `#BD7E55` | palette_library |
| 6 | `soft gold` | `rich honey` | `#D4AF37` | palette_library |
| 7 | `Antique Brass` | `Rich Sienna` | `#C47A3E` | sign_accent_expression |
| 8 | `Burnished Gold` | `Tawny Amber` | `#D59B49` | sign_accent_expression |
| 9 | `Burnt Copper` | `Warm Ember` | `#AE4D37` | sign_accent_expression |
| 10 | `Dark Bronze` | `Deep Umber` | `#664330` | sign_accent_expression |
| 11 | `Gunmetal` | `Ink Teal` | `#19475A` | sign_accent_expression |
| 12 | `Lunar Silver` | `Lunar Mist` | `#A6C6D0` | sign_accent_expression |
| 13 | `Pewter` | `Stone Teal` | `#25515B` | sign_accent_expression |
| 14 | `Platinum Frost` | `Frost Blue` | `#91B5CF` | sign_accent_expression |
| 15 | `Saffron Gold` | `Saffron Amber` | `#C79538` | sign_accent_expression |
| 16 | `Soft Silver` | `Slate Teal` | `#4D7E8C` | sign_accent_expression |
| 17 | `Solar Gold` | `Solar Amber` | `#DFA74B` | sign_accent_expression |

**Kept (clothing-rail vocabulary):** `bright gold`, `bronze`, `copper`, `gunmetal` (library), `olive gold`, `pewter` (library), `silver`, `steel grey`

---

## Residual search results

Old names searched across all non-backup files. Split by allowed vs not-allowed residuals.

### Allowed residuals

| Old name | Context | Why allowed |
|----------|---------|-------------|
| `soft gold`, `aged brass` | `Cosmic FitTests/Cosmic_FitTests.swift` line 1778 — `warmMetals` hardware keyword set | Intentional hardware terms for metal classification testing |
| `aged brass` (+ others) | `_archive/InterpretationTextLibrary.swift` | Archived historical file, not compiled |
| Various Phase 1 old names | `_archive/TokenPrefixMatrix.swift`, `_archive/ParagraphAssembler.swift` | Archived historical files |
| `aged brass`, `antique gold`, etc. | `data/style_guide/backups/` | Explicit backup copies |
| Various old names | pruned historical handoff docs | Documentation of the rename programme; those handoff docs are no longer present |
| Various old names | `data/style_guide/colour_metal_fabric_audit.md`, `.json` | Audit tool outputs documenting old names |
| Various old names | `data/style_guide/colour_metal_fabric_proposals.json` | AI proposals documenting old → new mapping |

### Not-allowed residuals

**Engine source:** Zero old Phase 4 names in `PaletteLibrary.swift`, `SignArchetypes.swift`, `VariationSlots.swift`, `InterpretationTextLibrary.swift`, `SemanticTokenGenerator.swift`.

**Test files (palette contexts):** Zero old Phase 4 names in `PaletteGridViewModel_Tests.swift`, `BlueprintLensEngine_Payload_Tests.swift`, `ColourReachability_Tests.swift`.

**Production audit blueprints:** All palette colour `"name"` fields updated; hardware fields (`recommendedMetals`, `metalsText`) preserved with intentional metal names.

---

## Duplicate-name inventory

Post-Phase 4 inventory check:

- **PaletteLibrary `colourNameToHex`**: 144 unique keys — zero duplicates
- **SignAccentExpressions**: 106 unique names — zero duplicates
- **Cross-source collision**: Zero names appear in both PaletteLibrary and SignAccentExpressions with case-insensitive matching (expected: library tokens like `pewter`/`gunmetal` share names with KEPT accent entries `Pewter`→`Stone Teal`, `Gunmetal`→`Ink Teal` — but these accent entries were renamed, so no collisions remain)

---

## Metal-fabric audit post-apply

Post-Phase 4 `colour_metal_fabric_audit.py` results:

- **Flagged: 8** (down from 25)
- All 8 are **KEEP** decisions: `bright gold`, `bronze`, `copper`, `gunmetal`, `olive gold`, `pewter`, `silver`, `steel grey`
- **Zero sign accent expression flags** — all 11 metal-themed accents renamed
- **Zero new metal keywords** introduced by any renamed label

---

## Daily Fit clash smoke test

### Scenario: Deep Autumn user with Cool metal tone

- **Before:** Palette could show `aged brass` accent beside "Cool" Metal Tone slider → hardware vocabulary confusion
- **After:** Palette shows `warm umber` — unambiguously a fabric/earth tone. No metal vocabulary overlap with the Metal Tone slider.

### Scenario: Leo warm user

- **Before:** Accent pool includes `Solar Gold`, `Antique Brass`, `Burnished Gold` — all hardware vocabulary
- **After:** Accent pool shows `Solar Amber`, `Rich Sienna`, `Tawny Amber` — all fabric-first names

### Scenario: Capricorn neutral user with Mixed metal tone

- **Before:** Accent pool includes `Pewter` (#25515B dark teal), `Gunmetal` (#19475A dark teal) — both misrepresent their actual colour AND create metal confusion
- **After:** Accent pool shows `Stone Teal`, `Ink Teal` — accurately describe the dark teal hues with no metal vocabulary

---

## Hex preservation verification

All 17 renamed entries: hex values unchanged between pre-rename and post-rename state in both `PaletteLibrary.swift` (`colourNameToHex`) and `SignArchetypes.swift` (LCH values unchanged → same computed hex).

---

**Result: PASS** — All Phase 4 success criteria met.
