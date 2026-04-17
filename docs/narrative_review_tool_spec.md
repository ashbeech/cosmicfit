# Narrative Review Tool — Interface Specification

> **Owner:** WP2 (this document defines the contract).
> **Builder:** WP3 (builds the tool and the backfill script that integrates with it).
>
> **This document is a specification only.** WP2 does not build the review tool.
> WP3 must build a tool that conforms to the JSON schemas and behaviour
> requirements defined here.

---

## Purpose

The narrative review tool is a local-only web UI that allows a human reviewer to:

1. Read every AI-generated paragraph from the backfill script output.
2. Validate each paragraph against quality rules.
3. Approve, flag for revision, or reject each paragraph.
4. Export review notes that the backfill script consumes on re-run.

---

## 1. Narrative Cache JSON Schema

### File: `blueprint_narrative_cache.json`

This is the primary output of the WP3 backfill script and the primary input for
the review tool. The WP3 engine also loads this file at runtime.

```json
{
  "<archetype_cluster_key>": {
    "style_core": "<paragraph text>",
    "textures_good": "<paragraph text>",
    "textures_bad": "<paragraph text>",
    "textures_sweet_spot": "<paragraph text>",
    "palette_narrative": "<paragraph text>",
    "occasions_work": "<paragraph text>",
    "occasions_intimate": "<paragraph text>",
    "occasions_daily": "<paragraph text>",
    "hardware_metals": "<paragraph text>",
    "hardware_stones": "<paragraph text>",
    "hardware_tip": "<paragraph text>",
    "accessory_1": "<paragraph text>",
    "accessory_2": "<paragraph text>",
    "accessory_3": "<paragraph text>",
    "pattern_narrative": "<paragraph text>",
    "pattern_tip": "<paragraph text>"
  }
}
```

### Rules

- Each top-level key is an archetype cluster key (e.g.
  `"venus_scorpio__moon_capricorn__fire_dominant"`).
- Each cluster entry **must** contain all 16 `BlueprintSection` keys listed above.
  Missing keys indicate an incomplete backfill run.
- Each value is a string containing the AI-generated paragraph (plain text, no
  markdown formatting).
- The 16 section keys are the canonical `BlueprintSection.rawValue` values
  defined in `BlueprintModels.swift`. They must not be renamed or aliased.

### Archetype Cluster Key Format

```
<venus_sign>__<moon_sign>__<element_group>
```

- Components are separated by double underscores (`__`).
- Each component is `snake_case` lowercase.
- Examples:
  - `venus_scorpio__moon_capricorn__fire_dominant`
  - `venus_taurus__moon_cancer__earth_dominant`
  - `venus_leo__moon_aquarius__air_dominant`

---

## 2. Review Notes JSON Schema

### File: `review_notes.json`

Written by the review tool. Read by the backfill script on re-run to determine
which paragraphs need regeneration.

```json
{
  "<archetype_cluster_key>": {
    "<section_key>": {
      "status": "approved | needs_revision | rejected",
      "note": "<free-text reviewer note or empty string>",
      "reviewed_at": "<ISO 8601 timestamp>"
    }
  }
}
```

### Rules

- The outer key matches the archetype cluster key in the narrative cache.
- The inner key is one of the 16 `BlueprintSection` raw values.
- `status` must be exactly one of: `"approved"`, `"needs_revision"`, `"rejected"`.
- `note` is optional free text. An empty string `""` is valid.
- `reviewed_at` is an ISO 8601 UTC timestamp (e.g. `"2026-04-12T14:30:00Z"`).

### Backfill Script Integration

On re-run, the backfill script must:

1. Load `review_notes.json` if it exists.
2. For each paragraph:
   - If `status == "approved"` → skip (do not regenerate).
   - If `status == "needs_revision"` → regenerate with the `note` appended to the
     prompt as additional guidance.
   - If `status == "rejected"` → regenerate from scratch (ignore note).
   - If no review entry exists → treat as unreviewed and skip regeneration
     (preserve existing content from prior run).

---

## 3. Paragraph Validation Rules

The review tool must automatically validate each paragraph and display results
alongside the text. These rules come from the v2.3 spec (§3e).

### Length

| Check | Rule |
|-------|------|
| Minimum | ≥ 50 words |
| Maximum | ≤ 150 words |

### Banned Words

The following words are common AI tells and must not appear in any paragraph:

```
delve, tapestry, resonate, elevate, curate, embark, multifaceted, realm,
robust, leverage, utilize, harness, holistic, synergy, paradigm,
landscape (metaphorical), nuanced, myriad
```

**Note on "landscape":** The word "landscape" is banned only in metaphorical use
(e.g. "the landscape of fashion"). Literal use referring to actual visual
landscapes in palette descriptions is acceptable. The automated check should flag
all occurrences; the human reviewer decides if the usage is acceptable.

### Required Style Markers

| Check | Rule |
|-------|------|
| Second-person address | Must contain at least one of: "You", "Your", "you", "your" |
| No hedging | Must not contain: "you might", "perhaps", "maybe", "possibly" |
| Direct statements | Must contain at least one declarative sentence (not a question or conditional) |

### Spelling Preference

British English spelling is preferred (e.g. "colour" not "color", "centre" not
"center"). The tool should flag obvious American English spellings but not
block approval.

### Validation Display

For each paragraph, the tool should display:

- Word count
- Pass/fail for each rule above
- Any banned words found (highlighted)
- Any hedging phrases found (highlighted)

---

## 4. Review Tool Requirements

### Stack

- **Server:** Python (Flask or FastAPI), local-only.
- **Port:** `localhost:8420`
- **State:** Stateless server. All persistent state lives in the JSON files
  (`blueprint_narrative_cache.json` and `review_notes.json`).
- **Theme:** Dark theme UI.

### Display Layout

1. **Left sidebar:** List of archetype clusters, grouped alphabetically.
   Show a progress badge (e.g. "12/16 approved") per cluster.
2. **Main panel:** When a cluster is selected, show all 16 sections vertically.
   Each section displays:
   - Section name (e.g. "Style Core", "Textures — Good")
   - The paragraph text
   - Automated validation results (pass/fail indicators)
   - Review controls (see below)
3. **Top bar:** Global stats (total paragraphs, approved, needs revision,
   rejected, unreviewed). Pipeline halt button.

### Per-Paragraph Controls

| Control | Action |
|---------|--------|
| **Approve** | Sets `status: "approved"` |
| **Needs Revision** | Sets `status: "needs_revision"`, opens note field |
| **Reject** | Sets `status: "rejected"`, opens note field |
| **Note field** | Free-text input, saved with the review entry |

### Pipeline Halt

- A "Pause Pipeline" button in the top bar.
- When clicked, the tool writes a `pause_signal.json` file in the same directory
  as the narrative cache:
  ```json
  { "paused": true, "paused_at": "<ISO 8601 timestamp>", "reason": "manual halt" }
  ```
- The backfill script must check for `pause_signal.json` before each API call.
  If `paused == true`, the script stops and logs the reason.
- A "Resume Pipeline" button removes the file (or sets `paused: false`).

### Export

- The tool writes `review_notes.json` on every status change (auto-save).
- No manual export step needed.

### Keyboard Shortcuts (recommended)

| Key | Action |
|-----|--------|
| `a` | Approve current paragraph |
| `r` | Mark needs revision |
| `x` | Reject |
| `↓` / `j` | Next section |
| `↑` / `k` | Previous section |
| `]` | Next cluster |
| `[` | Previous cluster |

---

## 5. Section Display Name Mapping

For human readability, the tool should display friendly names:

| `BlueprintSection` Raw Value | Display Name |
|------------------------------|--------------|
| `style_core` | Style Core |
| `textures_good` | Textures — Good |
| `textures_bad` | Textures — Bad |
| `textures_sweet_spot` | Textures — Sweet Spot |
| `palette_narrative` | Palette |
| `occasions_work` | Occasions — Work |
| `occasions_intimate` | Occasions — Intimate |
| `occasions_daily` | Occasions — Daily |
| `hardware_metals` | Hardware — Metals |
| `hardware_stones` | Hardware — Stones |
| `hardware_tip` | Hardware — Tip |
| `accessory_1` | Accessory — Paragraph 1 |
| `accessory_2` | Accessory — Paragraph 2 |
| `accessory_3` | Accessory — Paragraph 3 |
| `pattern_narrative` | Pattern |
| `pattern_tip` | Pattern — Tip |
