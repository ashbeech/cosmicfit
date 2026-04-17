# Palette Engine Rework Spec — Astrological Fidelity Pass

> **Version:** v1.1 (amended — see §0 changelog)  
> **Phase:** A of the Palette Rework programme  
> **Hard prerequisite:** `docs/repo_rename_spec_v1.md` (Phase 0) **merged** — confirmed. All paths use `docs/...`.  
> **Downstream consumer:** `docs/palette_grid_spec_v1.md` (Phase B). That work is gated on this spec landing.

---

## 0. Changelog

### v1.1 — Narrative / display split

**Scope change:** narrative vocabulary does NOT extend to 4 accents. Narrative stays at 2 accent placeholders. Resolver still produces 4 accent anchors, but narrative context exposes only the top 2 (by contributor rank). UI grid consumes all 4 uniformly.

**Removed from scope (previously §9, §10):**
- `NarrativeTemplateRenderer.swift:28` vocabulary extension to `1...4`.
- `backfill_narratives.py` prompt / allowlist edits (lines 210, 221, 345).
- `README.md:766` placeholder documentation update.
- Full `blueprint_narrative_cache.json` regeneration (~112 Gemini calls avoided).

**Added to scope:**
- Explicit **narrative-exposure rule**: `NarrativeTemplateRenderer.buildContext` maps only `accentColours[0]` and `accentColours[1]` to `accent_colour_1` / `accent_colour_2`. Accents at indices 2 and 3 are never written to the context dictionary.
- A test that asserts this rule (§12.5).
- Ordering guarantee on `PaletteSection.accentColours`: entries are sorted by contributor rank ascending (0 = highest-signal). The first 2 are the "narrative-exposed" accents.

**Unchanged:**
- Token fidelity (§5), resolver two-pass selection (§6), provenance (§7), token-supply pre-req gate (§8), fixture regeneration (§11), existing WP2 test assertion tightening (§12.1).
- `PaletteSection.accentColours.count == 4` final shape.
- Phase B contract: still reads all 4 accents.

**Rationale:** the 2-accent narrative prompt is well-tuned; two named accents read better than four in prose; astrological breadth is served by the palette grid display, not by prose enumeration. The existing uncommitted cache additions under the 2-accent prompt remain spec-legal under v1.1 — no stash/revert required.

### v1.1 revision 2 — §8.3 / §12.2 alignment

**Surfaced by Phase A Dev during fixture regeneration:** Maria's fixture produced 2 accents with `.crossPoolEscalation` provenance, which satisfied §8.3's "zero library fallback" gate but violated §12.2's stricter "all anchors chart-derived" assertion. The contradiction was in the spec, not the implementation. Root cause: the token-supply diagnostic counts distinct hues per pool independently and does NOT model cross-band interference, so a chart can pass the per-pool gate and still legitimately need cross-pool escalation at resolve time.

**Resolution:** relax §12.2 to match §8.3 — `.libraryFallback` remains forbidden for fixture users (hard gate), `.crossPoolEscalation` is permitted (soft path) and documented in the PR + `docs/fixtures/CHANGELOG.md`. Also added §8.3.1 flagging the diagnostic's per-pool limitation and pointing at a future tightening as a non-blocker follow-up.

**Impact:** `PaletteRework_Tests.swift` `provenanceAllChartDerived` must be renamed / relaxed to `provenanceNoLibraryFallback` with the new core / accent chart-derived-floor checks (at least 3/4 core and 2/4 accent are `.chartDerived`). No resolver, models, or token-generator code changes.

---

---

## 1. Primary Goal

**Make the selected anchor colours more astrologically faithful to the individual user.** Capacity expansion (from `max 6 total, 2 accents` to `max 8 total, 4 accents`) is a **consequence** of preserving dataset semantics end-to-end, not the goal itself.

A palette that is 4-accents-wide but full of weakly-connected or library-fallback colours is worse than a palette that is 2-accents-wide but chart-grounded. Quality first, then breadth.

## 2. Background — Where Astrological Signal Is Currently Lost

The pipeline today already pulls colour candidates from chart-relevant dataset entries, but at two points it discards information the dataset provides:

### 2.1 Token emit — `BlueprintTokenGenerator.swift`

```swift
// Cosmic Fit/InterpretationEngine/BlueprintTokenGenerator.swift (line 351)
for colour in entry.colours.primary + entry.colours.accent {
    tokens.append(BlueprintToken(
        name: colour.name, category: .colour, weight: rawWeight,
        planetarySource: planetarySource, signSource: signSource,
        houseSource: houseSource, aspectSource: aspectSource
    ))
}
```

`entry.colours.primary + entry.colours.accent` is a concatenation. Every colour from either array becomes a `.colour` token with **identical category, identical weight, no record of whether the dataset called it a primary or subordinate accent**. The dataset knows "Venus-in-Taurus primary colours are [...]; accent colours are [...]" — the token layer throws it all into one bucket.

### 2.2 Resolver selection — `DeterministicResolver.swift`

```swift
// Cosmic Fit/InterpretationEngine/DeterministicResolver.swift (line 85–128)
for token in colourTokens {
    guard selected.count < 6 else { break }
    // ... hex lookup, 15° hue gap filter ...
    let role: ColourRole = selected.count < 4 ? .core : .accent
    selected.append(BlueprintColour(name: token.name, hexValue: hex, role: role))
}

selected = applyFallbackIfNeeded(
    selected: selected,
    minCore: 3, minAccent: 2,
    // ...
)
```

`.core` vs `.accent` is assigned **by position in the weight-sorted list**, not by whether the dataset called the colour primary or accent. The first four tokens that survive the hue filter become core; the next two become accent. A Venus-in-Taurus *accent* colour can end up in the user's core band just because it happened to have a high weight, while a Venus-in-Taurus *primary* that scored lower drops into the accent slot.

### 2.3 Consequence

- Core and accent bands aren't semantically core and accent — they're "top 4 by weight" and "next 2 by weight".
- Every anchor's record (`BlueprintColour`) loses the provenance needed to audit fit after the fact.
- Fallback from the curated library is treated as equivalent to chart-derived colours — no flag, no log, no way to distinguish "this midnight came from your chart" from "this midnight was padded in because we didn't have enough distinct hues".

Phase A fixes all three before expanding capacity.

## 3. Scope

**In scope:**

- `BlueprintToken` struct extension and all emit sites.
- `BlueprintColour` struct extension (new `provenance` field).
- `DeterministicResolver.resolvePalette` — complete rewrite as a multi-pass selector.
- Rank-sorted output on both `coreColours` and `accentColours`.
- Fallback escalation ladder (stepwise, logged).
- `NarrativeTemplateRenderer.buildContext` — narrative-exposure rule (top-2 accents only; v1.1 §9.1).
- Fixture regeneration (`docs/fixtures/blueprint_input_user_1.json` and `_user_2.json`).
- WP2 contract tests — new assertions (narrative-exposure, rank-ordering) and tightening of existing ones.
- Qualitative fit checklist — new reviewer doc.

**Explicitly NOT in scope (v1.1 narrowing):**

- Narrative placeholder vocabulary extension — the template vocabulary stays at `accent_colour_1..2`. See v1.1 changelog and §9 for why.
- `blueprint_narrative_cache.json` regeneration — not required.
- `backfill_narratives.py` edits.
- `README.md:766` placeholder documentation edits.

**Out of scope (explicit non-goals):**

- `PaletteSwatchGenerator` — per-family tone counts (3 core / 2 accent) stay. Not touched.
- UI / grid work — all of that is Phase B.
- Palette editing / sharing features — not part of this programme.
- Daily Fit palette (`DailyColourPaletteView`) — separate component, separate data path.
- Dataset file additions beyond a named fallback pool (see §7.4).
- Changing the 15° hue-gap constant as a hard-coded rule. The fallback ladder loosens it stepwise and only when selection underflows.

## 4. Deliverables

At PR time, the following must all be true:

1. `BlueprintToken` has a new field `sourceColourRole: DatasetColourRole?`.
2. `BlueprintTokenGenerator.generateTokensFromEntry` emits primaries and accents with that field populated.
3. `BlueprintColour` has a new field `provenance: ColourProvenance`.
4. `DeterministicResolver.resolvePalette` uses multi-pass selection with provenance recorded.
5. Both `coreColours` and `accentColours` sorted by `provenance.contributorRank` ascending; escalated/fallback entries at end.
6. `NarrativeTemplateRenderer.buildContext` uses `.prefix(2)` on `accentColours` so only `accent_colour_1..2` are ever populated. Indices 3 and 4 are NOT written to context.
7. Narrative placeholder vocabulary, `backfill_narratives.py`, and README **UNCHANGED** (explicit v1.1 non-goals).
8. `blueprint_narrative_cache.json` **NOT regenerated** as part of Phase A.
9. Fixtures regenerated and re-committed; `docs/fixtures/CHANGELOG.md` entry added.
10. Shape checklist updated.
11. Existing WP2 test assertions tightened.
12. Qualitative fit checklist added and signed off for both fixture users.
13. Token-supply diagnostic output included as an appendix in the PR description.

---

## 5. Token-Layer Fidelity

### 5.1 New type — `DatasetColourRole`

Add to `Cosmic Fit/InterpretationEngine/BlueprintModels.swift`, somewhere near `ColourRole` (line 139). This captures the **dataset's own** classification of a colour, distinct from `ColourRole` which records the **resolved** role after selection.

```swift
/// Dataset-side classification — which sub-array of a PlanetSignEntry's `colours`
/// yielded this colour. Preserved through the token layer so the resolver can
/// honour the dataset's own primary vs accent semantics when assigning core / accent.
enum DatasetColourRole: String, Codable, CaseIterable {
    case primary
    case accent
}
```

### 5.2 Extend `BlueprintToken`

At `Cosmic Fit/InterpretationEngine/BlueprintModels.swift` line 220, add one optional field:

```swift
struct BlueprintToken: Codable, Equatable {
    let name: String
    let category: TokenCategory
    let weight: Double
    let planetarySource: String?
    let signSource: String?
    let houseSource: Int?
    let aspectSource: String?
    let sourceColourRole: DatasetColourRole?   // NEW — non-nil only for .colour tokens

    // ... existing enums ...
}
```

**Codable migration:** `sourceColourRole` is optional and decodes to `nil` for pre-existing serialised tokens. This is additive — no breakage.

### 5.3 Rewrite the emit site

Replace `BlueprintTokenGenerator.swift` lines 351–357 with **two** loops:

```swift
// Primary colours — dataset's main expression for this combo.
for colour in entry.colours.primary {
    tokens.append(BlueprintToken(
        name: colour.name,
        category: .colour,
        weight: rawWeight,
        planetarySource: planetarySource,
        signSource: signSource,
        houseSource: houseSource,
        aspectSource: aspectSource,
        sourceColourRole: .primary
    ))
}

// Accent colours — dataset's subordinate / flash colours for this combo.
for colour in entry.colours.accent {
    tokens.append(BlueprintToken(
        name: colour.name,
        category: .colour,
        weight: rawWeight,
        planetarySource: planetarySource,
        signSource: signSource,
        houseSource: houseSource,
        aspectSource: aspectSource,
        sourceColourRole: .accent
    ))
}
```

**No weight differential.** The signal is carried structurally (the field), not by weight fudging. Weight still reflects combo relevance alone.

### 5.4 Other emit sites

Run `rg -n 'category: \.colour' 'Cosmic Fit/InterpretationEngine/'` to find any other places where a `.colour` token is emitted. The fallback / dataset-pool paths should emit with `sourceColourRole: nil` (unknown). Update them accordingly.

---

## 6. Resolver Two-Pass Selection

### 6.1 Contract

`resolvePalette` continues to return a `PaletteResult` with `core` and `accent` arrays. The implementation changes completely.

- **Core pass:** up to 4 core slots filled preferring `.primary`-sourced tokens.
- **Accent pass:** up to 4 accent slots filled preferring `.accent`-sourced tokens.
- **Cross-pool escalation:** if a pass underflows its minimum (core < 3 or accent < 4), pull from the opposite source pool, flagged with provenance.
- **Library fallback:** only if escalation still underflows, pad from a named curated pool, flagged with provenance.
- **Hue-gap escalation:** 15° → 12° → 10°, stepwise, only when a pass underflows.

### 6.2 Rewrite target — full replacement for `resolvePalette`

Replace `DeterministicResolver.swift` lines 85–128 with the following (pseudocode — adapt to your implementation style; the struct shape and return contract are fixed):

```swift
private static func resolvePalette(
    tokens: [BlueprintToken],
    colourLibrary: [String: ColourLibraryEntry]
) -> PaletteResult {
    let colourTokens = tokens
        .filter { $0.category == .colour }
        .sorted { tieBreakSort($0, $1) }

    // Partition by dataset-side semantics.
    let primaryPool = colourTokens.filter { $0.sourceColourRole == .primary }
    let accentPool  = colourTokens.filter { $0.sourceColourRole == .accent }
    // Tokens with nil sourceColourRole (e.g. legacy or fallback-emitted) are
    // treated as equal-priority pad material for either slot, but only via
    // explicit escalation (not the primary paths).

    var selected: [BlueprintColour] = []
    var selectedHues: [Double] = []

    // Pass 1: fill up to 4 core slots from primary pool.
    selected += selectAnchors(
        from: primaryPool,
        desiredCount: 4,
        role: .core,
        sourceRole: .primary,
        colourLibrary: colourLibrary,
        selectedHues: &selectedHues,
        hueGapLadder: [15.0, 12.0, 10.0]
    )

    // Pass 2: fill up to 4 accent slots from accent pool.
    selected += selectAnchors(
        from: accentPool,
        desiredCount: 4,
        role: .accent,
        sourceRole: .accent,
        colourLibrary: colourLibrary,
        selectedHues: &selectedHues,
        hueGapLadder: [15.0, 12.0, 10.0]
    )

    // Pass 3: cross-pool escalation if either band underflows its minimum.
    selected = applyCrossPoolEscalation(
        selected: selected,
        primaryPool: primaryPool,
        accentPool: accentPool,
        minCore: 3, minAccent: 4,
        colourLibrary: colourLibrary,
        selectedHues: &selectedHues
    )

    // Pass 4: library fallback — final padding from named curated pool.
    selected = applyLibraryFallback(
        selected: selected,
        minCore: 3, minAccent: 4,
        colourLibrary: colourLibrary,
        selectedHues: &selectedHues
    )

    let core   = selected.filter { $0.role == .core }
    let accent = selected.filter { $0.role == .accent }
    return PaletteResult(core: core, accent: accent)
}
```

### 6.3 `selectAnchors` — the hue-gap escalation helper

Pseudocode:

```swift
private static func selectAnchors(
    from pool: [BlueprintToken],
    desiredCount: Int,
    role: ColourRole,
    sourceRole: DatasetColourRole,
    colourLibrary: [String: ColourLibraryEntry],
    selectedHues: inout [Double],
    hueGapLadder: [Double]
) -> [BlueprintColour] {
    var picked: [BlueprintColour] = []
    var usedTokens: Set<String> = []
    var ladderIndex = 0
    var currentGap = hueGapLadder[ladderIndex]

    while picked.count < desiredCount {
        var madeProgress = false

        for token in pool where !usedTokens.contains(token.name) {
            let hex = resolveHex(token: token, library: colourLibrary)
            let hue = hueFromHex(hex)

            let tooClose = selectedHues.contains { existing in
                hueDistance(hue, existing) < currentGap
            }
            if tooClose { continue }

            let provenance: ColourProvenance = .chartDerived(
                comboKey: token.comboKey,        // derive from planetary+sign sources
                contributorRank: token.contributorRank, // derive from weight ordering
                sourceRole: sourceRole,
                hueGapApplied: currentGap
            )

            picked.append(BlueprintColour(
                name: token.name,
                hexValue: hex,
                role: role,
                provenance: provenance
            ))
            selectedHues.append(hue)
            usedTokens.insert(token.name)
            madeProgress = true

            if picked.count == desiredCount { break }
        }

        if picked.count == desiredCount { break }

        // Ran out of eligible tokens at this gap — loosen or stop.
        if !madeProgress {
            ladderIndex += 1
            if ladderIndex >= hueGapLadder.count {
                break  // Ladder exhausted; caller's escalation passes take over.
            }
            currentGap = hueGapLadder[ladderIndex]
        }
    }

    return picked
}
```

Notes:

- `token.comboKey`, `token.contributorRank` — derive from `planetarySource` + `signSource` (e.g. `"venus_taurus"`) and the token's position in the sorted input. You may need a small helper to compute rank. Keep this deterministic.
- `ColourProvenance` records which hue-gap step fired so PR reviewers can see "all 4 accents picked at 15°, no loosening needed".

### 6.4 `applyCrossPoolEscalation`

If `core` ended up with < 3 entries, pull additional anchors from the *accent* pool (or vice versa), tagged as `ColourRole.core` but with `provenance: .crossPoolEscalation(originalRole: .accent, reason: "core underflow at step N")`. Same hue-gap ladder applies. Never reorder already-selected entries.

### 6.5 `applyLibraryFallback`

Replaces the current `applyFallbackIfNeeded` (line 473+). Only fires if passes 1–3 still leave core < 3 or accent < 4.

**Library fallback source:** rather than the ad-hoc `defaults` array in the current implementation (charcoal, slate, etc.), introduce a **named curated pool** in the dataset. Two options:

- **Option A (preferred):** add a new top-level key `fallback_palette_pool` to `astrological_style_dataset.json` containing an ordered list of `{name, hex}` entries chosen for graceful universal applicability. The resolver pulls from this named pool.
- **Option B:** keep the in-code `defaults` list but expose it as a named constant (`fallbackPaletteDefaults`) clearly labelled as the fallback source.

Option A is cleaner because it moves the data out of code; Option B is smaller blast radius. Dev's choice; record rationale in PR.

Each fallback anchor carries `provenance: .libraryFallback(reason: "...")`.

### 6.6 Updated fallback function signatures

The `minCore: 3, minAccent: 2` call at line 118–123 becomes:

```swift
// Note: passes 3 and 4 replace applyFallbackIfNeeded entirely.
// The new minAccent is 4, not 2.
```

---

## 7. `BlueprintColour` Provenance

### 7.1 New type

Add to `BlueprintModels.swift`, near `BlueprintColour` (line 133):

```swift
enum ColourProvenance: Codable, Equatable {
    /// The colour was selected from a chart-derived token that matched the
    /// expected dataset source role for its resolved band.
    case chartDerived(
        comboKey: String,             // e.g. "venus_taurus"
        contributorRank: Int,         // 0-based rank in contributing combos
        sourceRole: DatasetColourRole,// what the dataset called this colour
        hueGapApplied: Double         // which hue-gap step picked it (15, 12, 10)
    )

    /// The colour was pulled from the opposite dataset source role because
    /// the expected pool underflowed. Tagged with its original role.
    case crossPoolEscalation(
        originalRole: DatasetColourRole,
        reason: String
    )

    /// The colour came from the library fallback pool, not from the user's chart.
    case libraryFallback(reason: String)
}
```

### 7.2 Extend `BlueprintColour`

```swift
struct BlueprintColour: Codable, Equatable {
    let name: String
    let hexValue: String
    let role: ColourRole
    let provenance: ColourProvenance   // NEW — non-optional
}
```

### 7.3 Codable migration strategy

`provenance` is **non-optional** in the new contract, but to keep WP2 tests and any persisted fixtures from old runs working, implement a decode-tolerant init that synthesises a default provenance for pre-existing data:

```swift
extension BlueprintColour {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.hexValue = try container.decode(String.self, forKey: .hexValue)
        self.role = try container.decode(ColourRole.self, forKey: .role)
        self.provenance = try container.decodeIfPresent(ColourProvenance.self, forKey: .provenance)
            ?? .libraryFallback(reason: "legacy data — provenance unknown")
    }
}
```

New data produced by this work MUST have a real provenance (not the legacy fallback). The decode-tolerant init is only for back-compat reading.

### 7.4 Consumers

- Tests: assert provenance contents (see §11).
- Logs: `DeterministicResolver` prints a one-line provenance summary per user palette when compiled with debug logging, e.g.:

  ```
  [Palette] core: 4 chart-derived (ranks 0–3, hue-gap 15°); accent: 4 chart-derived (ranks 1–5, hue-gap 15°); 0 escalations; 0 fallbacks.
  ```

- UI (Phase B): **does not consume provenance in v1**. Do not expose it through any UI surface. It exists for tests, logs, and future narrative enrichment.

---

## 8. Token-Supply Pre-Req Gate (Blocking)

This is a gate, not a deliverable — run it **before** touching resolver code. Its output determines whether the rest of Phase A is viable.

### 8.1 Method

Write a small diagnostic script (Swift or Python — choose what's fastest for you; keep it out of the shipping bundle). The script:

1. Reads `docs/fixtures/blueprint_input_user_1.json` and `_user_2.json`. **The relevant input in each file is `userInfo.birthDate` + `userInfo.birthLocation`.** The top-level sections (`palette`, `textures`, etc.) are resolved outputs from the old pipeline — ignore them.
2. Generates a `NatalChart` / chart analysis from each `userInfo` using the production pipeline's chart-generation path.
3. Runs the (new, post-§5) `BlueprintTokenGenerator` to emit tokens with `sourceColourRole` populated.
4. Partitions colour tokens by `sourceColourRole` and runs the hue-gap filter (15°) separately on each pool.
5. Outputs, per fixture:
   - Count of distinct-hue `.primary` tokens (after 15° gap).
   - Count of distinct-hue `.accent` tokens (after 15° gap).
   - Would the new resolver require escalation? At which step?

### 8.2 Synthetic chart spread

Extend the diagnostic with at least **10 synthetic charts** covering:

- Strong air emphasis (e.g. Sun/Venus/Moon in air signs).
- Strong earth emphasis.
- Strong water emphasis.
- Strong fire emphasis.
- Mixed-modality cases (cardinal/fixed/mutable blends).

Goal: confirm that escalation to library fallback is **not** commonplace. If it fires for any synthetic chart, dataset expansion / hue-gap tuning may be needed before Phase A ships.

### 8.3 Pass criteria

- **Hard:** both fixture users and 100% of synthetic charts have **zero** `.libraryFallback` entries in either band.
- **Soft:** cross-pool escalation is permitted and not a failure. `crossPoolEscalation` is a designed resolver feature (§6.4) — when a chart genuinely cannot supply 4 hue-distinct accents from its own-pool, the resolver borrows from the opposite pool. Provenance records this transparently.
- Any chart requiring library fallback must be documented in the appendix with the step that fired and the root cause (e.g. "dataset has only 2 primaries for Saturn-in-Pisces").
- Any fixture user requiring **cross-pool escalation** must be flagged in the PR body and in `docs/fixtures/CHANGELOG.md` — not as a failure, but so reviewers can see which accents came from the primary pool and decide whether to accept the degradation or file a dataset-expansion follow-up ticket.

### 8.3.1 Diagnostic limitation (informational)

The token-supply diagnostic computes distinct-hue counts **per pool independently** (primary vs accent). It does NOT model cross-band interference — i.e. it cannot tell you that after the core band consumes N hue-slots, the accent pool's *effective* distinct-hue count may drop below 4. A chart can therefore pass the per-pool gate and still legitimately require cross-pool escalation at resolve time.

Tightening the diagnostic to model cross-band interference is a reasonable follow-up ticket but NOT a Phase A blocker. Flag any surprise cross-pool cases in the PR body.

### 8.4 Fail action

If pass criteria are not met, stop and escalate to the programme owner before writing resolver code. The fix is likely one of:

- Dataset expansion — add more `colours.primary` / `colours.accent` entries per planet-sign combo.
- Reviewing existing primary/accent assignments — some may be in the wrong sub-array.
- Tuning the hue-gap ladder.

None of those fit in Phase A scope as currently written; they become a Phase A-prime conversation.

### 8.5 Appendix exhibit

Include the diagnostic output as an appendix in your PR description. Reviewers need to see it.

---

## 9. Narrative Vocabulary — UNCHANGED (v1.1)

**This section was removed in v1.1.**

The narrative placeholder vocabulary stays at 2 accent placeholders. Do **not** edit:

- `Cosmic Fit/InterpretationEngine/NarrativeTemplateRenderer.swift:28`
- `backfill_narratives.py` (lines 210, 221, 345)
- `README.md:766`

### 9.1 Narrative-exposure rule (new)

`NarrativeTemplateRenderer.buildContext` at `Cosmic Fit/InterpretationEngine/NarrativeTemplateRenderer.swift:80` currently iterates `resolved.accentColours.enumerated()` and writes every accent to the context dictionary:

```swift
// Current implementation — lines 86–88
for (i, c) in resolved.accentColours.enumerated() {
    ctx["accent_colour_\(i + 1)"] = c.name
}
```

When `accentColours.count == 4`, this silently populates `accent_colour_3` and `accent_colour_4` in the context. Since the template vocabulary (line 28) only whitelists `accent_colour_1..2`, any template referencing `{accent_colour_3}` or `{accent_colour_4}` would hit the unrecognised-placeholder warning path at line 65 — but no template does, because no backfill run has ever produced one. The result is that indices 3 and 4 are **silently ignored** by the renderer.

v1.1 makes this explicit and deliberate. Replace lines 86–88 with:

```swift
// Narrative exposes only the top 2 accents by contributor rank.
// Accents 3 and 4 exist in resolved.accentColours for the palette grid,
// but are deliberately NOT written to the template context.
for (i, c) in resolved.accentColours.prefix(2).enumerated() {
    ctx["accent_colour_\(i + 1)"] = c.name
}
```

The `.prefix(2)` makes the intent readable and guards against future changes to `allPlaceholders` accidentally enabling accent 3/4 templates without a context source.

### 9.2 Ordering guarantee (new)

The resolver MUST produce `PaletteSection.accentColours` sorted by contributor rank ascending — i.e., `accentColours[0]` is the accent with the highest-weighted contributing combo, `accentColours[1]` second, and so on. Provenance `.chartDerived(contributorRank: n, ...)` must satisfy:

```swift
accentColours[0].provenance.contributorRank <= accentColours[1].provenance.contributorRank <= ... <= accentColours[3].provenance.contributorRank
```

Cross-pool-escalated and library-fallback accents sort to the end (rank treated as `Int.max`). This keeps the narrative-exposed first-two always chart-derived when possible.

The same rank-ascending ordering MUST apply to `coreColours`, for consistency (not for narrative — core narrative already uses all 4).

---

## 10. Narrative Cache — NO REGENERATION (v1.1)

**This section was removed in v1.1.** Do not regenerate `blueprint_narrative_cache.json`. The existing cache (including the ~573 uncommitted additions that were generated under the 2-accent prompt) remains spec-legal.

Any cache changes the Dev encounters as uncommitted in the working tree may be:

- **Committed as-is** if they are otherwise desired narrative improvements (Dev's judgement / PR review).
- **Stashed and set aside** if unrelated to Phase A.
- **Reverted** if they introduce inconsistency.

This is a PR-hygiene call, not an engine-correctness call. No regeneration work is required for Phase A.

### 10.1 Commit structure (revised)

Suggested within Phase A:

1. `feat(models): add DatasetColourRole + sourceColourRole on BlueprintToken`
2. `feat(engine): BlueprintTokenGenerator preserves primary/accent semantics on emit`
3. `feat(models): add ColourProvenance + provenance on BlueprintColour`
4. `feat(engine): resolvePalette multi-pass selection with provenance; rank-sorted output`
5. `feat(engine): NarrativeTemplateRenderer exposes only top-2 accents by rank`
6. `chore(fixtures): regenerate blueprint_input_user_1/_2 against new resolver`
7. `test: tighten WP2 palette assertions; add provenance, rank, and narrative-exposure tests`

(Commits 5 and 6 of v1 — vocab extension and cache regen — are gone.)

---

## 11. Fixture Regeneration

### 11.1 Method

For each fixture (`docs/fixtures/blueprint_input_user_1.json`, `_user_2.json`):

1. Preserve `userInfo` exactly — the input is the user, that doesn't change.
2. Re-run the production pipeline end-to-end against the preserved `userInfo`.
3. Replace every resolved section (`palette`, `textures`, `occasions`, `hardware`, `code`, `accessory`, `pattern`) with the new output.
4. Serialise; commit.

### 11.2 Expected diff

- `palette.accentColours.length` grows from 2 to 4.
- Every `BlueprintColour` gains a `provenance` object.
- `palette.accentColours` is rank-sorted; first 2 entries are the narrative-exposed accents.
- `palette.narrativeText` **does NOT change from the cache-regen**, because there is no cache regen in v1.1. It may change minimally if the resolver's rank-sorted top-2 accents differ in name from whatever the previous resolver put in positions 0–1 — but the *template* is unchanged.
- `swatchFamilies` length equals `coreColours.length + accentColours.length` (6 or 8 entries, not the old 5 or 6).
- Other sections may also shift slightly if they consumed the old `accentColours.count == 2` anywhere — audit.

### 11.3 CHANGELOG

Add an entry to `docs/fixtures/CHANGELOG.md`:

```markdown
## 2026-XX-XX — Palette engine rework (Phase A)

- Regenerated against new resolver: 4-accent bands, provenance on every anchor.
- No change to `userInfo` inputs. All downstream sections re-derived.
- Shape checklist updated; accentColours.count is now exactly 4 (previously 2).
```

### 11.4 Shape checklist

Update `docs/fixtures/blueprint_expected_shape_checklist.md`:

- `palette.accentColours.count == 4` (was `>= 2`).
- `palette.coreColours.count ∈ [3, 4]` (unchanged).
- `palette.coreColours[*].provenance` exists and is a valid `ColourProvenance`.
- `palette.accentColours[*].provenance` same.
- Zero `.libraryFallback` entries expected for both fixture users.

---

## 12. Tests

### 12.1 Tighten existing assertions

`Cosmic FitTests/Cosmic_FitTests.swift`:

```diff
-        #expect(bp.palette.accentColours.count >= 2)
+        #expect(bp.palette.accentColours.count >= 4)
```

Both occurrences (lines 88 and 122). Core assertion stays `>= 3`.

### 12.2 New quantitative tests

Add to the WP2 contract suite:

- **Exact accent count:** `accentColours.count == 4` for both fixture users (not just `>= 4`).
- **Provenance shape:** every `BlueprintColour.provenance` decodes/encodes losslessly.
- **Provenance content (fixture users) — relaxed in v1.1 revision 2:**
  - **No** anchor in either band has `provenance` of `.libraryFallback`. This is the hard gate and matches §8.3.
  - `.chartDerived` is preferred; `.crossPoolEscalation` is permitted. The resolver is designed to degrade to cross-pool borrowing when an own-pool underflows (§6.4), and the provenance system keeps this auditable. A fixture producing cross-pool accents is not a test failure — but see §8.3 for the PR-body / CHANGELOG callout requirement.
  - Core band: at least 3 of 4 core anchors are `.chartDerived` (core is the strongest-signal band; escalation here is allowed but should be rare).
  - Accent band: at least 2 of 4 accent anchors are `.chartDerived`. The remaining 2 may be `.crossPoolEscalation`.
  - At least 2 of 4 accents have `contributorRank` in top 5 contributors (applies across `.chartDerived` and `.crossPoolEscalation` since both record a real rank). The original v1.1 wording here was "3 of 4," but once cross-pool is accepted as a legitimate fallback the top-2 pair (`.chartDerived` from the own-pool) is the meaningful quality floor; the remaining two slots by construction may land at any rank in the opposite pool's combo ordering. See the v1.1 rev 2 note below.
- **Hue-gap invariant:** after resolving, all pairs of anchors in `coreColours` have hue distance ≥ the `hueGapApplied` recorded in their provenance. Same for `accentColours`. Cross-band pairs use the tightest gap applied.
- **Determinism:** resolve both fixture users 10 times; byte-identical `PaletteSection` each time.

> **v1.1 revision 2 note:** v1.1 originally required "all anchors are `.chartDerived`" for fixture users, which contradicted §8.3's library-fallback-only gate. Maria's regenerated fixture surfaced the inconsistency: her accent band underflows at 15° once cross-band hue interference is accounted for, so the resolver correctly borrows `teal` (mars_gemini) and `midnight blue` (neptune_capricorn) from the primary pool. Relaxing §12.2 to align with §8.3 resolves the contradiction without softening the genuine correctness gate (zero library fallback).

### 12.3 New qualitative checklist

Create `docs/fixtures/palette_fit_review_checklist.md`:

```markdown
# Palette Fit Review Checklist

For each fixture user, a human reviewer (not just a linter) must verify and sign off:

## Fixture user 1

- [ ] At least 3 of 4 core colours trace to a combo in the top 3 contributors.
- [ ] No anchor has `provenance` of `.libraryFallback`.
- [ ] The accent palette reads as coherent flashes against the core band — not a
      second core band in disguise.
- [ ] `accentColours[0]` and `accentColours[1]` (the narrative-exposed pair) read
      as the strongest, most chart-characteristic accents for this user.
- [ ] Rendered `palette.narrativeText` names exactly 2 accents (the top-ranked
      pair). Accents 3 and 4 are visible in the grid but absent from prose.
- [ ] Narrative voice matches `docs/blueprint_examples.md` — no mechanical feel.

Signed off by: _____

## Fixture user 2

(Same list.)

Signed off by: _____
```

Reviewer (can be the Dev themselves if no human reviewer is available; note in PR).

### 12.4 Narrative-exposure test (new)

Add a small unit test that:

1. Constructs a `DeterministicResolverResult` with 4 accents of known names `A`, `B`, `C`, `D` (in that order).
2. Calls `NarrativeTemplateRenderer.buildContext(resolved:)`.
3. Asserts:
   - `ctx["accent_colour_1"] == "A"`
   - `ctx["accent_colour_2"] == "B"`
   - `ctx["accent_colour_3"] == nil`
   - `ctx["accent_colour_4"] == nil`

This locks v1.1's narrative-exposure rule in place.

### 12.5 Rank-ordering test (new)

Add a test that asserts `accentColours` is sorted by `provenance.contributorRank` ascending, with escalated / fallback entries at the end. Same for `coreColours`. Fixture-driven; both users.

---

## 13. Acceptance Criteria

Every one must be green before merging.

- [ ] `BlueprintToken.sourceColourRole` field added; emit sites updated; other non-colour categories unaffected.
- [ ] `BlueprintColour.provenance` field added; decode-tolerant init implemented; all new data carries a real (non-legacy-fallback) provenance.
- [ ] `resolvePalette` reworked to multi-pass; hue-gap escalation ladder + cross-pool escalation + library fallback all exercise in the diagnostic.
- [ ] `coreColours` and `accentColours` both sorted by `provenance.contributorRank` ascending; escalated/fallback entries sort to end.
- [ ] `NarrativeTemplateRenderer.buildContext` exposes only top-2 accents (`accent_colour_1..2`). Indices 3 and 4 are NOT written to context.
- [ ] `NarrativeTemplateRenderer.allPlaceholders`, `backfill_narratives.py`, and `README.md` placeholder documentation are **UNCHANGED** (verify via `git diff` — these must show no lines touched in Phase A).
- [ ] `blueprint_narrative_cache.json` is **NOT regenerated** as part of Phase A. Any cache edits committed in Phase A must come from unrelated hygiene only.
- [ ] Token-supply diagnostic appendix included in PR; pass criteria (§8.3) met.
- [ ] Fixtures regenerated against new resolver; CHANGELOG and shape checklist updated.
- [ ] Existing WP2 `accentColours.count >= 2` assertions bumped to `>= 4`.
- [ ] New quantitative tests added and green (provenance shape/content, hue-gap invariant, determinism, **narrative-exposure (§12.4)**, **rank ordering (§12.5)**).
- [ ] Qualitative fit checklist signed off for both fixtures.
- [ ] `swift test` green.
- [ ] `python3 validate_dataset.py` green.
- [ ] No `PaletteSwatchGenerator` changes.
- [ ] No UI / grid work.

---

## 14. Risks

- **Token supply insufficient.** Mitigation: §8 pre-req gate. If the gate fails, Phase A does not ship until the dataset is expanded or hue-gap tuned. Escalation is expected, not exceptional.
- **Narrative appears to underuse the new accents.** v1.1 deliberately names only 2 of 4 accents in prose. Reviewers may ask "why aren't all 4 named?" — answer is in §0 changelog: prose stays tight at 2, grid shows 4. Not a bug.
- **Resolver rank-sort changes accent order vs pre-Phase-A fixtures.** If the same user previously had accents `[A, B]` in that order and the new resolver ranks them `[B, A]`, `palette.narrativeText` names may swap. Expected; fixture CHANGELOG must call this out.
- **Contract migration pain for downstream consumers.** `provenance` is additive and the decode is tolerant of legacy fixtures lacking the field. Any in-flight PR that constructs `BlueprintColour` directly will need a trivial update.
- **Reviewer subjectivity on qualitative checklist.** Mitigation: checklist items are concrete and quote-specific, not vibes ("references all 4 accents by name", "trace to top 3 contributors").
- **Performance.** Multi-pass resolver does more work than the old single-loop version. Negligible on 6–8 tokens. No action.

## 15. Non-Goals (Re-stated for Clarity)

- Per-family tone count changes in `PaletteSwatchGenerator` (core=3, accent=2 stays).
- Grid UI work.
- Palette editing / sharing features.
- Daily Fit integration.
- Dataset restructuring beyond adding `fallback_palette_pool` (optional §6.5 Option A).
- Changing the 15° hue-gap as an absolute rule — it becomes the first rung of a stepwise ladder.

## 16. Companion Notice

The UI for the Personal Palette Grid (Phase B) is the downstream consumer of this work. It is specified in `docs/palette_grid_spec_v1.md`. **Notify the Phase B Dev as soon as this PR merges.** The UI Dev:

- Will read `PaletteSection.coreColours` and `accentColours` directly.
- Will **not** read `provenance` in v1 — it exists for tests and logs.
- Will expect exactly 4 accents. If your rework produces fewer (e.g. you shipped with relaxed criteria), UI Dev will halt and escalate.

## 17. Rollback

If this PR is reverted post-merge:

- `BlueprintToken.sourceColourRole` and `BlueprintColour.provenance` fields become orphan data in any persisted caches/fixtures. The decode-tolerant init on `BlueprintColour` handles absence, but additive fields in `BlueprintToken` may need a migration if deserialised elsewhere — check the cache layer.
- Narrative cache must be reverted in the same revert to avoid prompts rendering with missing tokens.
- Fixture regeneration is revertable via the same git revert.

---

*Authored as part of the Palette Rework programme. Phase 0 (`repo_rename_spec_v1.md`) is a hard prerequisite. Phase B (`palette_grid_spec_v1.md`) is the downstream consumer.*
