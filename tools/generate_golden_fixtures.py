#!/usr/bin/env python3
"""Generate synthetic ChartAnalysis fixtures for the golden archetype charts.

SG-1 deliverable (Style Guide Quality Overhaul, Phase 1a fifth-pass).

Emits docs/style_guide/golden/fixtures/{archetype}_chart.json for the 15
non-Slate golden charts. Slate has a real natal export
(docs/style_guide/golden/cosmicfit_slate_natal_2026-06-29_to_2026-07-12_14d.md)
and is exercised through the live pipeline, not a synthetic fixture.

Each fixture is constructed directly from the golden guide's metadata block
(Venus sign, Moon sign, dominant element, sect, stellium) — no ephemeris
work. Remaining placements are sensible fillers chosen so that:

- the element balance (Sun..Saturn + Ascendant, mirroring
  ChartAnalyser.computeElementBalance) reproduces the guide's dominant
  element with the intended margin (Loom's margin is deliberately 1 to
  force confidence=LOW; everyone else has margin >= 2),
- stellium constraints hold across all ten bodies (exactly the stelliums
  named in the guides; no accidental 3-in-a-sign elsewhere),
- the Moon house lands the guide's orientation lane given the fine
  Moon-house adjustment (see ChartAestheticProfile.swift).

Consumed by Swift unit tests (Cosmic FitTests) and, from SG-3, by the
Python coarse-profile parity check in backfill_narratives.py. The expected
outputs live in docs/style_guide/golden/profile_expectations.json.
"""

import json
import pathlib

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURES_DIR = REPO_ROOT / "docs" / "style_guide" / "golden" / "fixtures"

# archetype -> fixture definition.
# planet_signs covers all ten bodies (stellium computation spans all ten).
# element_balance mirrors the 8-slot tally (7 classical planets + Asc).
FIXTURES = {
    "ember": {
        "cluster_key": "venus_aries__moon_sagittarius__fire_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 5, "earth": 1, "air": 1, "water": 1},
        "chart_ruler": "Sun",
        "ascendant_sign": "Leo",
        "midheaven_sign": "Sagittarius",  # bold chart: MC Sag retention test
        "planet_signs": {
            "Sun": "Aries", "Moon": "Sagittarius", "Mercury": "Taurus",
            "Venus": "Aries", "Mars": "Leo", "Jupiter": "Gemini",
            "Saturn": "Cancer", "Uranus": "Capricorn",
            "Neptune": "Capricorn", "Pluto": "Scorpio",
        },
        "planet_houses": {
            "Sun": 1, "Moon": 5, "Mercury": 2, "Venus": 1, "Mars": 10,
            "Jupiter": 9, "Saturn": 6, "Uranus": 3, "Neptune": 4, "Pluto": 8,
        },
    },
    "blaze": {
        "cluster_key": "venus_sagittarius__moon_leo__fire_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 5, "earth": 1, "air": 1, "water": 1},
        "chart_ruler": "Mars",
        "ascendant_sign": "Aries",
        "midheaven_sign": "Sagittarius",
        # Sagittarius stellium (Sun, Mercury, Venus) per the guide.
        "planet_signs": {
            "Sun": "Sagittarius", "Moon": "Leo", "Mercury": "Sagittarius",
            "Venus": "Sagittarius", "Mars": "Virgo", "Jupiter": "Libra",
            "Saturn": "Scorpio", "Uranus": "Aquarius",
            "Neptune": "Capricorn", "Pluto": "Scorpio",
        },
        "planet_houses": {
            "Sun": 9, "Moon": 9, "Mercury": 8, "Venus": 9, "Mars": 6,
            "Jupiter": 7, "Saturn": 8, "Uranus": 11, "Neptune": 10, "Pluto": 8,
        },
    },
    "cinder": {
        "cluster_key": "venus_leo__moon_aries__fire_dominant",
        "chart_sect": "night",
        "element_balance": {"fire": 5, "earth": 1, "air": 1, "water": 1},
        "chart_ruler": "Jupiter",
        "ascendant_sign": "Sagittarius",
        "midheaven_sign": "Scorpio",
        "planet_signs": {
            "Sun": "Leo", "Moon": "Aries", "Mercury": "Virgo",
            "Venus": "Leo", "Mars": "Sagittarius", "Jupiter": "Aquarius",
            "Saturn": "Pisces", "Uranus": "Capricorn",
            "Neptune": "Capricorn", "Pluto": "Scorpio",
        },
        "planet_houses": {
            "Sun": 8, "Moon": 1, "Mercury": 9, "Venus": 8, "Mars": 12,
            "Jupiter": 2, "Saturn": 3, "Uranus": 1, "Neptune": 2, "Pluto": 11,
        },
    },
    "cove": {
        "cluster_key": "venus_cancer__moon_scorpio__water_dominant",
        "chart_sect": "night",
        "element_balance": {"fire": 1, "earth": 1, "air": 1, "water": 5},
        "chart_ruler": "Moon",
        "ascendant_sign": "Cancer",
        "midheaven_sign": "Pisces",
        "planet_signs": {
            "Sun": "Cancer", "Moon": "Scorpio", "Mercury": "Taurus",
            "Venus": "Cancer", "Mars": "Aries", "Jupiter": "Gemini",
            "Saturn": "Pisces", "Uranus": "Sagittarius",
            "Neptune": "Capricorn", "Pluto": "Libra",
        },
        "planet_houses": {
            "Sun": 1, "Moon": 4, "Mercury": 12, "Venus": 12, "Mars": 10,
            "Jupiter": 11, "Saturn": 9, "Uranus": 6, "Neptune": 7, "Pluto": 4,
        },
    },
    "flint": {
        "cluster_key": "venus_virgo__moon_virgo__earth_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 1, "earth": 5, "air": 1, "water": 1},
        "chart_ruler": "Saturn",
        "ascendant_sign": "Capricorn",
        "midheaven_sign": "Virgo",
        # Virgo carries exactly Venus + Moon (no stellium per guide).
        "planet_signs": {
            "Sun": "Taurus", "Moon": "Virgo", "Mercury": "Capricorn",
            "Venus": "Virgo", "Mars": "Aries", "Jupiter": "Gemini",
            "Saturn": "Cancer", "Uranus": "Scorpio",
            "Neptune": "Sagittarius", "Pluto": "Libra",
        },
        "planet_houses": {
            "Sun": 5, "Moon": 6, "Mercury": 1, "Venus": 6, "Mars": 4,
            "Jupiter": 6, "Saturn": 7, "Uranus": 10, "Neptune": 11, "Pluto": 9,
        },
    },
    "frost": {
        "cluster_key": "venus_aquarius__moon_libra__air_dominant",
        "chart_sect": "night",
        "element_balance": {"fire": 1, "earth": 1, "air": 5, "water": 1},
        "chart_ruler": "Venus",
        "ascendant_sign": "Libra",
        "midheaven_sign": "Libra",
        "planet_signs": {
            "Sun": "Aquarius", "Moon": "Libra", "Mercury": "Gemini",
            "Venus": "Aquarius", "Mars": "Capricorn", "Jupiter": "Sagittarius",
            "Saturn": "Scorpio", "Uranus": "Sagittarius",
            "Neptune": "Capricorn", "Pluto": "Virgo",
        },
        "planet_houses": {
            "Sun": 5, "Moon": 2, "Mercury": 9, "Venus": 5, "Mars": 4,
            "Jupiter": 3, "Saturn": 2, "Uranus": 3, "Neptune": 4, "Pluto": 12,
        },
    },
    "hearth": {
        "cluster_key": "venus_leo__moon_capricorn__earth_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 1, "earth": 5, "air": 1, "water": 1},
        "chart_ruler": "Mercury",
        "ascendant_sign": "Virgo",
        "midheaven_sign": "Taurus",
        "planet_signs": {
            "Sun": "Taurus", "Moon": "Capricorn", "Mercury": "Taurus",
            "Venus": "Leo", "Mars": "Gemini", "Jupiter": "Cancer",
            "Saturn": "Virgo", "Uranus": "Scorpio",
            "Neptune": "Sagittarius", "Pluto": "Libra",
        },
        "planet_houses": {
            "Sun": 9, "Moon": 10, "Mercury": 9, "Venus": 12, "Mars": 10,
            "Jupiter": 11, "Saturn": 1, "Uranus": 3, "Neptune": 4, "Pluto": 2,
        },
    },
    "loom": {
        "cluster_key": "venus_pisces__moon_virgo__air_dominant",
        "chart_sect": "day",
        # Slimmest possible margin (3 air vs 2 earth / 2 water):
        # dominant stays air but confidence must resolve LOW.
        "element_balance": {"fire": 1, "earth": 2, "air": 3, "water": 2},
        "chart_ruler": "Venus",
        "ascendant_sign": "Libra",
        "midheaven_sign": "Pisces",
        "planet_signs": {
            "Sun": "Gemini", "Moon": "Virgo", "Mercury": "Aquarius",
            "Venus": "Pisces", "Mars": "Aries", "Jupiter": "Taurus",
            "Saturn": "Cancer", "Uranus": "Sagittarius",
            "Neptune": "Capricorn", "Pluto": "Scorpio",
        },
        "planet_houses": {
            "Sun": 9, "Moon": 6, "Mercury": 5, "Venus": 6, "Mars": 7,
            "Jupiter": 8, "Saturn": 10, "Uranus": 3, "Neptune": 4, "Pluto": 2,
        },
    },
    "mist": {
        "cluster_key": "venus_pisces__moon_pisces__water_dominant",
        "chart_sect": "night",
        "element_balance": {"fire": 1, "earth": 1, "air": 1, "water": 5},
        "chart_ruler": "Moon",
        "ascendant_sign": "Cancer",
        "midheaven_sign": "Pisces",
        # Pisces stellium (Sun, Moon, Venus) per the guide.
        "planet_signs": {
            "Sun": "Pisces", "Moon": "Pisces", "Mercury": "Aquarius",
            "Venus": "Pisces", "Mars": "Aries", "Jupiter": "Capricorn",
            "Saturn": "Scorpio", "Uranus": "Sagittarius",
            "Neptune": "Capricorn", "Pluto": "Libra",
        },
        "planet_houses": {
            "Sun": 12, "Moon": 12, "Mercury": 8, "Venus": 9, "Mars": 10,
            "Jupiter": 7, "Saturn": 5, "Uranus": 6, "Neptune": 7, "Pluto": 4,
        },
    },
    "moss": {
        "cluster_key": "venus_capricorn__moon_taurus__earth_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 1, "earth": 5, "air": 1, "water": 1},
        "chart_ruler": "Venus",
        "ascendant_sign": "Taurus",
        "midheaven_sign": "Capricorn",
        "planet_signs": {
            "Sun": "Virgo", "Moon": "Taurus", "Mercury": "Virgo",
            "Venus": "Capricorn", "Mars": "Leo", "Jupiter": "Aquarius",
            "Saturn": "Cancer", "Uranus": "Scorpio",
            "Neptune": "Sagittarius", "Pluto": "Libra",
        },
        "planet_houses": {
            "Sun": 5, "Moon": 2, "Mercury": 5, "Venus": 9, "Mars": 4,
            "Jupiter": 10, "Saturn": 3, "Uranus": 7, "Neptune": 8, "Pluto": 6,
        },
    },
    "ripple": {
        "cluster_key": "venus_taurus__moon_pisces__water_dominant",
        "chart_sect": "night",
        "element_balance": {"fire": 1, "earth": 1, "air": 1, "water": 5},
        "chart_ruler": "Jupiter",
        "ascendant_sign": "Pisces",
        "midheaven_sign": "Taurus",
        "planet_signs": {
            "Sun": "Cancer", "Moon": "Pisces", "Mercury": "Cancer",
            "Venus": "Taurus", "Mars": "Aries", "Jupiter": "Libra",
            "Saturn": "Scorpio", "Uranus": "Sagittarius",
            "Neptune": "Capricorn", "Pluto": "Virgo",
        },
        "planet_houses": {
            "Sun": 4, "Moon": 4, "Mercury": 5, "Venus": 2, "Mars": 1,
            "Jupiter": 7, "Saturn": 8, "Uranus": 9, "Neptune": 10, "Pluto": 6,
        },
    },
    "tide": {
        "cluster_key": "venus_scorpio__moon_cancer__water_dominant",
        "chart_sect": "night",
        "element_balance": {"fire": 1, "earth": 1, "air": 1, "water": 5},
        "chart_ruler": "Mars",
        "ascendant_sign": "Scorpio",
        "midheaven_sign": "Scorpio",
        "planet_signs": {
            "Sun": "Pisces", "Moon": "Cancer", "Mercury": "Scorpio",
            "Venus": "Scorpio", "Mars": "Capricorn", "Jupiter": "Sagittarius",
            "Saturn": "Aquarius", "Uranus": "Virgo",
            "Neptune": "Capricorn", "Pluto": "Leo",
        },
        "planet_houses": {
            "Sun": 4, "Moon": 8, "Mercury": 1, "Venus": 12, "Mars": 2,
            "Jupiter": 1, "Saturn": 3, "Uranus": 10, "Neptune": 2, "Pluto": 9,
        },
    },
    "wren": {
        "cluster_key": "venus_cancer__moon_gemini__fire_dominant",
        "chart_sect": "day",
        # Fire dominant with margin 2 (4 fire vs 2 air); the register
        # conflict comes from the vote split, not the margin.
        "element_balance": {"fire": 4, "earth": 1, "air": 2, "water": 1},
        "chart_ruler": "Sun",
        "ascendant_sign": "Leo",
        "midheaven_sign": "Aries",
        # Aries stellium (Sun, Mercury, Mars) — fine-profile signal only.
        "planet_signs": {
            "Sun": "Aries", "Moon": "Gemini", "Mercury": "Aries",
            "Venus": "Cancer", "Mars": "Aries", "Jupiter": "Libra",
            "Saturn": "Capricorn", "Uranus": "Sagittarius",
            "Neptune": "Capricorn", "Pluto": "Scorpio",
        },
        "planet_houses": {
            "Sun": 9, "Moon": 6, "Mercury": 9, "Venus": 12, "Mars": 10,
            "Jupiter": 3, "Saturn": 6, "Uranus": 5, "Neptune": 6, "Pluto": 4,
        },
    },
    "zephyr": {
        "cluster_key": "venus_gemini__moon_aquarius__air_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 1, "earth": 1, "air": 5, "water": 1},
        "chart_ruler": "Mercury",
        "ascendant_sign": "Gemini",
        "midheaven_sign": "Gemini",
        "planet_signs": {
            "Sun": "Libra", "Moon": "Aquarius", "Mercury": "Libra",
            "Venus": "Gemini", "Mars": "Sagittarius", "Jupiter": "Cancer",
            "Saturn": "Taurus", "Uranus": "Aries",
            "Neptune": "Pisces", "Pluto": "Capricorn",
        },
        "planet_houses": {
            "Sun": 5, "Moon": 11, "Mercury": 5, "Venus": 1, "Mars": 7,
            "Jupiter": 2, "Saturn": 12, "Uranus": 11, "Neptune": 10, "Pluto": 8,
        },
    },
    "breeze": {
        "cluster_key": "venus_libra__moon_gemini__air_dominant",
        "chart_sect": "day",
        "element_balance": {"fire": 1, "earth": 1, "air": 5, "water": 1},
        "chart_ruler": "Venus",
        "ascendant_sign": "Libra",
        "midheaven_sign": "Libra",
        "planet_signs": {
            "Sun": "Aquarius", "Moon": "Gemini", "Mercury": "Aquarius",
            "Venus": "Libra", "Mars": "Leo", "Jupiter": "Pisces",
            "Saturn": "Capricorn", "Uranus": "Taurus",
            "Neptune": "Scorpio", "Pluto": "Virgo",
        },
        "planet_houses": {
            "Sun": 5, "Moon": 7, "Mercury": 5, "Venus": 1, "Mars": 11,
            "Jupiter": 6, "Saturn": 4, "Uranus": 8, "Neptune": 2, "Pluto": 12,
        },
    },
}

SIGN_ELEMENTS = {
    "Aries": "fire", "Taurus": "earth", "Gemini": "air", "Cancer": "water",
    "Leo": "fire", "Virgo": "earth", "Libra": "air", "Scorpio": "water",
    "Sagittarius": "fire", "Capricorn": "earth", "Aquarius": "air",
    "Pisces": "water",
}
BALANCE_PLANETS = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn"]


def validate(name, fx):
    """Internal consistency checks before writing anything."""
    signs = fx["planet_signs"]
    venus, moon = signs["Venus"], signs["Moon"]
    key = fx["cluster_key"]
    expected_key = (
        f"venus_{venus.lower()}__moon_{moon.lower()}__"
        f"{max(fx['element_balance'], key=fx['element_balance'].get)}_dominant"
    )
    assert key == expected_key, f"{name}: key {key} != derived {expected_key}"

    # Element balance must mirror the ChartAnalyser 8-slot tally.
    tally = {"fire": 0, "earth": 0, "air": 0, "water": 0}
    for planet in BALANCE_PLANETS:
        tally[SIGN_ELEMENTS[signs[planet]]] += 1
    tally[SIGN_ELEMENTS[fx["ascendant_sign"]]] += 1
    assert tally == fx["element_balance"], (
        f"{name}: element_balance {fx['element_balance']} != tally {tally}"
    )

    # Stellium tally across all ten bodies.
    counts = {}
    for sign in signs.values():
        counts[sign] = counts.get(sign, 0) + 1
    fx["_stelliums"] = sorted(s for s, c in counts.items() if c >= 3)


def main():
    FIXTURES_DIR.mkdir(parents=True, exist_ok=True)
    for name, fx in FIXTURES.items():
        validate(name, fx)
        signs = fx["planet_signs"]
        doc = {
            "archetype": name,
            "source": f"docs/style_guide/golden/{name}_ideal.md metadata block",
            "cluster_key": fx["cluster_key"],
            "chart_sect": fx["chart_sect"],
            "element_balance": fx["element_balance"],
            "modality_balance": {"cardinal": 3, "fixed": 3, "mutable": 2},
            "chart_ruler": fx["chart_ruler"],
            "sun_sign": signs["Sun"],
            "moon_sign": signs["Moon"],
            "venus_sign": signs["Venus"],
            "mars_sign": signs["Mars"],
            "ascendant_sign": fx["ascendant_sign"],
            "midheaven_sign": fx["midheaven_sign"],
            "planet_signs": signs,
            "planet_houses": fx["planet_houses"],
            "stellium_signs": fx["_stelliums"],
        }
        path = FIXTURES_DIR / f"{name}_chart.json"
        path.write_text(json.dumps(doc, indent=2) + "\n")
        print(f"wrote {path.relative_to(REPO_ROOT)}  stelliums={fx['_stelliums']}")


if __name__ == "__main__":
    main()
