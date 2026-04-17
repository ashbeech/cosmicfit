# Palette Fit Review Checklist

> **Purpose:** Phase A of the Palette Rework programme (v1.1 §12.3) requires
> human sign-off on how well the regenerated fixtures read as an
> astrologically faithful palette. Linter-green ≠ astrologically coherent;
> this checklist is the final human gate before the PR merges.
>
> **How to use:** open the fixture JSON, look at `palette.coreColours`,
> `palette.accentColours`, and `palette.narrativeText`. Tick every box or
> escalate.

---

## Fixture user 1 — `blueprint_input_user_1.json` (Ash)

- [ ] At least 3 of 4 core colours trace to a combo in the top 3
      contributors (check `provenance.comboKey` + top-combos line in
      `token_supply_diagnostic.txt`).
- [ ] No anchor has `provenance.kind == "libraryFallback"`.
- [ ] No anchor has `provenance.kind == "crossPoolEscalation"` unless
      called out in the PR with a dataset gap explanation.
- [ ] The accent palette reads as coherent flashes against the core band —
      not a second core band in disguise.
- [ ] `accentColours[0]` and `accentColours[1]` (the narrative-exposed pair)
      read as the strongest, most chart-characteristic accents for this
      user. Accents at indices 2 and 3 feel like supporting material, not
      the headliners.
- [ ] Rendered `palette.narrativeText` names **exactly 2 accents** (the
      top-ranked pair). Accents 3 and 4 are visible in the grid but absent
      from prose. Verify by reading the prose and counting named accent
      colours; should equal `accentColours[0].name` and
      `accentColours[1].name`.
- [ ] Narrative voice matches `docs/blueprint_examples.md` — no mechanical
      feel, no enumeration style, no placeholder leakage (`{...}`).

**Signed off by:** ______________  **Date:** ____________

**Notes / concerns:**

---

## Fixture user 2 — `blueprint_input_user_2.json` (Maria)

- [ ] At least 3 of 4 core colours trace to a combo in the top 3
      contributors (check `provenance.comboKey` + top-combos line in
      `token_supply_diagnostic.txt`).
- [ ] No anchor has `provenance.kind == "libraryFallback"`.
- [ ] No anchor has `provenance.kind == "crossPoolEscalation"` unless
      called out in the PR with a dataset gap explanation.
- [ ] The accent palette reads as coherent flashes against the core band —
      not a second core band in disguise.
- [ ] `accentColours[0]` and `accentColours[1]` (the narrative-exposed pair)
      read as the strongest, most chart-characteristic accents for this
      user. Accents at indices 2 and 3 feel like supporting material, not
      the headliners.
- [ ] Rendered `palette.narrativeText` names **exactly 2 accents** (the
      top-ranked pair). Accents 3 and 4 are visible in the grid but absent
      from prose.
- [ ] Narrative voice matches `docs/blueprint_examples.md` — no mechanical
      feel, no enumeration style, no placeholder leakage (`{...}`).

**Signed off by:** ______________  **Date:** ____________

**Notes / concerns:**

---

## Notes for the reviewer

- If no separate human reviewer is available, the Phase A Dev can sign
  off both users and note that fact in the PR body.
- Concerns about narrative voice are not a spec violation but worth
  flagging — they may need a Phase A-prime narrative refresh.
- Library-fallback hits are a **hard stop**: escalate to the programme
  owner per §8.4. The diagnostic appendix
  (`docs/fixtures/token_supply_diagnostic.txt`) confirms zero fallback on
  both fixtures as of this commit; if a regeneration flips that state,
  something in the dataset or resolver has regressed.
