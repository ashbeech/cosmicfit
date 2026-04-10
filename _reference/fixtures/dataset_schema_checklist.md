# WP4 Astrological Style Dataset — Schema Checklist

> **Purpose:** Defines the expected keys, cardinality, and structure for
> `astrological_style_dataset.json`. WP4 must validate its dataset against this
> checklist before handoff.
>
> **Audience:** WP4 (dataset author), WP3 (engine consumer).

---

## Top-Level Sections

| Key | Type | Description |
|-----|------|-------------|
| `planet_sign` | object | 132 planet-sign entries |
| `aspects` | object | ~30 key aspect entries |
| `house_placements` | object | 48 house placement entries (4 planets × 12 houses) |
| `element_balance` | object | 4 element dominance entries + 3 modality entries |
| `colour_library` | object | 60–80 named colours with hex values |

---

## `planet_sign` — 132 Entries

### Cardinality

11 chart bodies × 12 zodiac signs = **132 entries**.

| Body | Key Prefix | Count | Data Richness |
|------|-----------|-------|---------------|
| Sun | `sun_*` | 12 | Good detail |
| Moon | `moon_*` | 12 | High detail |
| Mercury | `mercury_*` | 12 | Light detail |
| Venus | `venus_*` | 12 | Most detail |
| Mars | `mars_*` | 12 | Moderate detail |
| Jupiter | `jupiter_*` | 12 | Light detail |
| Saturn | `saturn_*` | 12 | Moderate detail |
| Uranus | `uranus_*` | 12 | Light detail |
| Neptune | `neptune_*` | 12 | Light detail |
| Pluto | `pluto_*` | 12 | Light detail |
| Ascendant | `ascendant_*` | 12 | Moderate detail |

### Required Fields per Entry

| Field | Type | Required | Maps to `TokenCategory` |
|-------|------|----------|------------------------|
| `style_philosophy` | string | Yes | `mood`, `expression` |
| `textures` | object | Yes | `texture` |
| `textures.good` | `[string]` | Yes | `texture` |
| `textures.bad` | `[string]` | Yes | `texture` |
| `textures.sweet_spot_keywords` | `[string]` | Yes | `texture`, `structure` |
| `colours` | object | Yes | `colour` |
| `colours.primary` | `[{name, hex}]` | Yes | `colour` |
| `colours.accent` | `[{name, hex}]` | Yes | `colour` |
| `colours.avoid` | `[string]` | Yes | — |
| `metals` | `[string]` | Yes | `metal` |
| `stones` | `[string]` | Yes | `stone` |
| `patterns` | object | Yes | `pattern` |
| `patterns.recommended` | `[string]` | Yes | `pattern` |
| `patterns.avoid` | `[string]` | Yes | `pattern` |
| `silhouette_keywords` | `[string]` | Yes | `silhouette` |
| `occasion_modifiers` | object | Yes | `mood`, `silhouette` |
| `occasion_modifiers.work` | string | Yes | — |
| `occasion_modifiers.intimate` | string | Yes | — |
| `occasion_modifiers.daily` | string | Yes | — |
| `code_leaninto` | `[string]` | Yes | `structure`, `silhouette` |
| `code_avoid` | `[string]` | Yes | `structure`, `silhouette` |
| `code_consider` | `[string]` | Yes | `structure`, `silhouette` |
| **`opposites`** | object | **Yes** | Used for anti-token generation |
| `opposites.textures` | `[string]` | Yes | — |
| `opposites.colours` | `[string]` | Yes | — |
| `opposites.silhouettes` | `[string]` | Yes | — |
| `opposites.mood` | `[string]` | Yes | — |

---

## `aspects` — ~30 Entries

### Key Format

`<planet1>_<aspect_type>_<planet2>` — e.g. `venus_square_saturn`

### Priority Aspects (must be present)

- `venus_*_saturn` (all major aspect types)
- `venus_*_jupiter`
- `venus_*_mars`
- `venus_*_uranus`
- `venus_*_neptune`
- `moon_*_saturn`
- `moon_*_venus`
- `sun_*_saturn`
- `mars_*_saturn`
- `ascendant_*_venus`

### Required Fields per Entry

| Field | Type | Required |
|-------|------|----------|
| `effect` | string | Yes |
| `texture_modifier` | string | Yes |
| `colour_modifier` | string | Yes |
| `code_addition_leaninto` | string | Yes |
| `code_addition_avoid` | string | Yes |

---

## `house_placements` — 48 Entries

### Key Format

`<planet>_house_<number>` — e.g. `venus_house_2`

### Cardinality

4 key planets (Venus, Moon, Sun, Mars) × 12 houses = **48 entries**.

### Required Fields per Entry

| Field | Type | Required |
|-------|------|----------|
| `context` | string | Yes |
| `modifier` | string | Yes |

---

## `element_balance` — 7 Entries

### Required Entries

| Key | Type |
|-----|------|
| `fire_dominant` | Element dominance entry |
| `earth_dominant` | Element dominance entry |
| `air_dominant` | Element dominance entry |
| `water_dominant` | Element dominance entry |
| `cardinal_dominant` | Modality dominance entry |
| `fixed_dominant` | Modality dominance entry |
| `mutable_dominant` | Modality dominance entry |

### Required Fields per Entry

| Field | Type | Required |
|-------|------|----------|
| `overall_energy` | string | Yes |
| `palette_bias` | string | Yes |
| `texture_bias` | string | Yes |

---

## `colour_library` — 60–80 Entries

### Key Format

Colour name as key — e.g. `"midnight"`, `"sage green"`

### Required Fields per Entry

| Field | Type | Required |
|-------|------|----------|
| `hex` | string (e.g. `"#191970"`) | Yes |
| `associations` | `[string]` | Yes |

### Validation Rules

- Each hex value must match `#[0-9A-Fa-f]{6}`.
- Associations should reference zodiac signs, planets, or element groups.
- Total count must be ≥ 60.
