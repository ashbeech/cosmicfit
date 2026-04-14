#!/usr/bin/env python3
"""
WP4, Astrological Style Dataset Generator

Builds the complete astrological_style_dataset.json consumed by WP3.
This script contains all astrological-to-fashion mapping data authored
for the Cosmic Fit Blueprint system.

Output: astrological_style_dataset.json
"""

import json
import sys
from collections import OrderedDict

# ═══════════════════════════════════════════════════════════════
# PLANET-SIGN ENTRIES (132 total: 11 bodies × 12 signs)
# ═══════════════════════════════════════════════════════════════

SIGNS = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"
]

BODIES = [
    "sun", "moon", "mercury", "venus", "mars",
    "jupiter", "saturn", "uranus", "neptune", "pluto", "ascendant"
]

# ═══════════════════════════════════════════════════════════════
# QUALITY STANDARDS — Directive Voice Grammar & Pattern Specificity
# ═══════════════════════════════════════════════════════════════
#
# CODE DIRECTIVES must read as finished user-facing copy, not compressed
# internal tokens. Every directive follows a two-part structure:
#
#   Part 1 — The Principle (declarative statement of what to do/avoid/consider)
#   Part 2 — The Proof (vivid test, consequence, or sensory detail)
#
# Example: "Buying for the ten-year test. If it still feels powerful in a
#           decade, it belongs in your collection."
#
# Voice rules:
#   - Gerund opening ("Checking...", "Investing...") or imperative-then-test.
#     Never bare noun phrases like "quality over quantity".
#   - Fashion-insider register. Direct, confident, second-person. No hedging.
#   - Each directive must reference a concrete garment, fabric, shopping
#     scenario, or physical sensation. No abstract-only statements.
#   - Must be astrologically distinct: Virgo precision ≠ Capricorn discipline;
#     Scorpio control ≠ Aquarius detachment.
#   - Must be wearable advice a sharp stylist would actually give.
#
# PATTERN NAMES must pass the "textile printer test": could a fabric
# designer produce a swatch from the name alone? Vague entries like
# "bark-effect weave" or "micro-houndstooth" fail. Concrete entries like
# "dark-on-dark jacquard" or "micro-houndstooth" pass.
#
# Pattern names also need archetype fit — the swatch must belong to that
# chart's aesthetic world, not just be technically specific.

DIRECTIVE_MIN_WORDS = {
    "venus": 12, "moon": 12, "sun": 12,
    "ascendant": 10, "mars": 10, "saturn": 10,
    "jupiter": 8, "mercury": 8, "uranus": 8, "neptune": 8, "pluto": 8
}

DIRECTIVE_MIN_COUNTS = {
    "venus": (4, 3, 2),
    "moon": (4, 3, 2),
    "sun": (4, 3, 2),
    "ascendant": (3, 2, 2),
    "mars": (3, 2, 2),
    "saturn": (3, 2, 2),
    "jupiter": (3, 3, 2),
    "mercury": (3, 3, 2),
    "uranus": (3, 3, 2),
    "neptune": (3, 3, 2),
    "pluto": (3, 3, 2),
}

# ─── VENUS (12 entries, most detail, primary fashion planet) ─────────

VENUS_ENTRIES = {
    "venus_aries": {
        "style_philosophy": "spontaneous, direct, bold first impressions",
        "textures": {
            "good": ["lightweight cotton", "crisp poplin", "tech fabrics", "raw denim", "ponte knit"],
            "bad": ["heavy brocade", "stiff formal fabrics", "overly delicate lace"],
            "sweet_spot_keywords": ["movement", "freedom", "athletic"]
        },
        "colours": {
            "primary": [
                {"name": "coral", "hex": "#FF6F61"},
                {"name": "fire red", "hex": "#B22222"}
            ],
            "accent": [
                {"name": "warm white", "hex": "#FAF0E6"},
                {"name": "tangerine", "hex": "#FF9966"}
            ],
            "avoid": ["muted pastels", "grey-heavy palettes"]
        },
        "metals": ["rose gold", "polished brass", "bright copper"],
        "stones": ["carnelian", "red jasper", "garnet"],
        "patterns": {
            "recommended": ["bold stripes", "colour blocking", "contrast-piped racing stripe", "pop-art colour block"],
            "avoid": ["tiny florals", "paisley", "fussy prints"]
        },
        "silhouette_keywords": ["sharp shoulders", "cropped", "streamlined", "athletic cut"],
        "occasion_modifiers": {
            "work": "decisive, sharp, no-nonsense power dressing",
            "intimate": "direct, warm, confident minimalism",
            "daily": "athletic, purposeful, ready to move"
        },
        "code_leaninto": [
            "Dressing for the first three seconds. If the outfit does not make an instant impression, it is not doing its job.",
            "Choosing bold colour over safe neutral every single time. A sharp coral blazer outperforms a beige one in any room.",
            "Letting one hero piece carry the entire outfit. A striking jacket or a perfect pair of trainers is all you need.",
            "Prioritising silhouettes that let you move. If a garment restricts your stride or your shoulders, leave it on the rack.",
        ],
        "code_avoid": [
            "Anything that requires constant fussing or adjusting. If you have to think about it once you have left the house, it has failed.",
            "Overly delicate pieces that cannot keep up with your energy. Fragile fabrics and fiddly closures are a mismatch.",
            "Complicated layering systems that slow down your morning. You should be dressed and out the door in minutes, not negotiating with your wardrobe.",
        ],
        "code_consider": [
            "One statement piece rather than layered complexity. Edit down until the outfit has a single clear focal point.",
            "Sportswear details in elevated fabrics. A technical zip on a wool jacket or a mesh panel on a silk top bridges your worlds.",
        ],
        "opposites": {
            "textures": ["heavy brocade", "stiff formal fabrics", "delicate lace"],
            "colours": ["muted pastels", "grey-heavy palettes", "dusty neutrals"],
            "silhouettes": ["restrictive tailoring", "overly layered", "fussy ruffles"],
            "mood": ["cautious", "restrained", "overly deliberate", "fussy"]
        }
    },
    "venus_taurus": {
        "style_philosophy": "luxurious, tactile, quality over quantity",
        "textures": {
            "good": ["cashmere", "heavy silk", "buttery leather", "brushed wool", "suede", "velvet"],
            "bad": ["synthetic jersey", "cheap polyester", "plasticky fabrics"],
            "sweet_spot_keywords": ["weight", "softness", "richness"]
        },
        "colours": {
            "primary": [
                {"name": "buttery cream", "hex": "#FFFDD0"},
                {"name": "deep sage green", "hex": "#4A6741"},
                {"name": "sophisticated caramel", "hex": "#A0722D"}
            ],
            "accent": [
                {"name": "oxidised gold", "hex": "#B08D57"},
                {"name": "dusty rose", "hex": "#DCAE96"},
                {"name": "deep burnt saffron", "hex": "#CC7722"}
            ],
            "avoid": ["neon shades", "harsh electric tones"]
        },
        "metals": ["yellow gold", "rose gold", "warm bronze"],
        "stones": ["emerald", "rose quartz", "jade"],
        "patterns": {
            "recommended": ["subtle herringbone", "bark-effect weave", "tonal knits", "classic plaid"],
            "avoid": ["aggressive graphics", "neon prints", "overly busy patterns"]
        },
        "silhouette_keywords": ["draped", "relaxed structure", "body-conscious", "wrap details"],
        "occasion_modifiers": {
            "work": "polished but comfortable, investment pieces that command respect",
            "intimate": "sensual, touchable fabrics, warm tones that invite closeness",
            "daily": "effortless luxury, well-made basics that feel expensive"
        },
        "code_leaninto": [
            "Investing in fewer, better pieces that you will reach for every week. If it does not earn its place in a small wardrobe, it does not belong.",
            "Touching before you buy. Run the fabric between your fingers. If the texture does not feel like a reward, walk away.",
            "Choosing natural fibres over synthetics as a rule. Cashmere, silk, and cotton age gracefully. Polyester does not.",
            "Building your foundation on warm neutrals. Cream, camel, and sage carry more weight than any trend colour.",
            "Treating your wardrobe like a collection, not a stockpile. Every addition should feel like it was curated, not grabbed.",
        ],
        "code_avoid": [
            "Cheap fast fashion that falls apart after three washes. You feel the difference in quality even if nobody else sees it.",
            "Anything that does not feel good against your skin. If a seam scratches or a waistband digs, the outfit is already ruined.",
            "Harsh synthetic fabrics that trap heat and static. Your body knows the difference even before you check the label.",
        ],
        "code_consider": [
            "Building a capsule wardrobe of quality staples and rotating seasonally. Fewer pieces, better fabric, longer life.",
            "The three-year test before every purchase. If you cannot picture wearing it in 2029, it does not make the cut.",
        ],
        "opposites": {
            "textures": ["synthetic jersey", "stiff plastic-coated fabrics", "scratchy acrylic"],
            "colours": ["neon shades", "harsh electric tones", "cold sterile whites"],
            "silhouettes": ["angular and aggressive", "overly structured armour", "boxy unforgiving shapes"],
            "mood": ["impulsive", "disposable", "trend-chasing", "abrasive"]
        }
    },
    "venus_gemini": {
        "style_philosophy": "eclectic, playful, conversational dressing",
        "textures": {
            "good": ["lightweight linen", "crisp cotton", "mixed-media layers", "silk blends", "jersey"],
            "bad": ["heavy wool", "stiff canvas", "monotone heavy fabrics"],
            "sweet_spot_keywords": ["variety", "lightness", "adaptability"]
        },
        "colours": {
            "primary": [
                {"name": "lemon yellow", "hex": "#FFF44F"},
                {"name": "sky blue", "hex": "#87CEEB"},
                {"name": "crisp white", "hex": "#F8F8FF"}
            ],
            "accent": [
                {"name": "peach", "hex": "#FFDAB9"},
                {"name": "soft lavender", "hex": "#E6E6FA"}
            ],
            "avoid": ["all-black monotone", "dark sombre palettes"]
        },
        "metals": ["mixed metals", "sterling silver", "white gold"],
        "stones": ["citrine", "aquamarine", "agate"],
        "patterns": {
            "recommended": ["mixed-scale print clash", "novelty illustrated prints", "stripes with florals", "geometric mix"],
            "avoid": ["uniform solids", "heavy tartans", "single-pattern monotony"]
        },
        "silhouette_keywords": ["layered", "convertible", "asymmetric", "modular"],
        "occasion_modifiers": {
            "work": "smart and interesting, pieces that start conversations",
            "intimate": "playful, unexpected combinations that keep things fresh",
            "daily": "mix-and-match layers, never the same outfit twice"
        },
        "code_leaninto": [
            "Mixing high and low fearlessly. A vintage market find paired with a designer knit shows range, not confusion.",
            "Embracing pattern clashing with clear intention. Stripes with florals works when the colour story holds together.",
            "Treating accessories as conversation starters. A ring with a story or a bag that prompts a question earns its place.",
            "Choosing reversible and dual-purpose pieces whenever possible. A jacket that works inside-out doubles your wardrobe overnight.",
        ],
        "code_avoid": [
            "Rigid matching sets that remove all surprise. If the outfit looks like it came off a mannequin as one unit, it is too predictable.",
            "Head-to-toe uniform dressing that shuts down your versatility. You need room to remix.",
            "One-note outfits that say only one thing. Your style should carry at least two ideas at once.",
        ],
        "code_consider": [
            "A signature accessory that changes daily. A rotating cast of earrings or scarves keeps your look alive without overhauling everything.",
            "Colour pops in unexpected places. A bright lining, a vivid sock, or a single neon nail says more than a loud top.",
        ],
        "opposites": {
            "textures": ["heavy monotone fabrics", "stiff formal wool", "oppressive layering"],
            "colours": ["all-black palettes", "dark sombre monotone", "muted earth only"],
            "silhouettes": ["rigid uniform silhouettes", "overly structured formality", "restrictive cuts"],
            "mood": ["monotonous", "predictable", "severe", "inflexible"]
        }
    },
    "venus_cancer": {
        "style_philosophy": "nostalgic, nurturing, protective softness",
        "textures": {
            "good": ["soft knits", "washed cotton", "vintage denim", "brushed flannel", "organic jersey"],
            "bad": ["cold metallics", "hard plastic", "scratchy synthetic"],
            "sweet_spot_keywords": ["comfort", "warmth", "familiarity"]
        },
        "colours": {
            "primary": [
                {"name": "pearl white", "hex": "#F0EAD6"},
                {"name": "soft silver", "hex": "#C0C0C0"},
                {"name": "blush", "hex": "#DE5D83"}
            ],
            "accent": [
                {"name": "sea glass", "hex": "#B2D8D8"},
                {"name": "pale blue", "hex": "#AEC6CF"},
                {"name": "seashell pink", "hex": "#FFF5EE"}
            ],
            "avoid": ["harsh neons", "aggressive blacks", "jarring contrasts"]
        },
        "metals": ["sterling silver", "white gold", "antique silver"],
        "stones": ["moonstone", "pearl", "opal"],
        "patterns": {
            "recommended": ["soft florals", "vintage prints", "gingham", "watercolour motifs"],
            "avoid": ["aggressive graphics", "skull prints", "harsh geometric"]
        },
        "silhouette_keywords": ["wrap", "gathered", "soft shoulder", "layered protection"],
        "occasion_modifiers": {
            "work": "approachable and polished, soft structure that still commands respect",
            "intimate": "romantic, enveloping, pieces that feel like home",
            "daily": "cosy layers, lived-in textures, protective comfort"
        },
        "code_leaninto": [
            "Investing in comfort that still looks intentional. A perfectly soft knit that falls beautifully is never lazy dressing.",
            "Layering soft over structured. A washed cotton shirt under a heritage cardigan creates warmth with backbone.",
            "Choosing heirloom-quality pieces worth passing down. If it cannot age into something your future self will treasure, reconsider.",
            "Seeking pieces with personal history. A vintage brooch or a hand-me-down coat carries emotional weight that new things cannot replicate.",
        ],
        "code_avoid": [
            "Cold, austere minimalism that strips away all warmth. If an outfit makes a room feel colder, it is wrong for you.",
            "Overly aggressive silhouettes that feel like armour against people. Your clothes should invite closeness, not repel it.",
            "Anything that feels emotionally detached or clinical. If the outfit has no soul, neither will your presence in it.",
        ],
        "code_consider": [
            "A signature comfort layer you return to daily. A heritage cardigan or a beloved shawl becomes part of your identity.",
            "Mixing vintage finds with modern basics. The tension between old and new reflects how you carry the past into the present.",
        ],
        "opposites": {
            "textures": ["cold metallics", "hard plastic surfaces", "sharp industrial fabrics"],
            "colours": ["harsh neons", "aggressive black", "stark clinical white"],
            "silhouettes": ["severe angular cuts", "exposed and vulnerable designs", "sharp aggressive lines"],
            "mood": ["detached", "clinical", "harsh", "aggressive"]
        }
    },
    "venus_leo": {
        "style_philosophy": "glamorous, expressive, commanding warmth",
        "textures": {
            "good": ["heavy silk", "structured satin", "rich velvet", "gold-thread brocade", "plush faux fur"],
            "bad": ["thin cheap jersey", "lifeless polyester", "anything that looks budget"],
            "sweet_spot_keywords": ["lustre", "drama", "opulence"]
        },
        "colours": {
            "primary": [
                {"name": "gold", "hex": "#FFD700"},
                {"name": "rich amber", "hex": "#FFBF00"},
                {"name": "burnished copper", "hex": "#B87333"}
            ],
            "accent": [
                {"name": "deep red", "hex": "#8B0000"},
                {"name": "royal purple", "hex": "#7851A9"}
            ],
            "avoid": ["washed-out pastels", "grubby neutrals", "anything that looks faded"]
        },
        "metals": ["yellow gold", "polished brass", "gilded finishes"],
        "stones": ["sunstone", "amber", "tiger eye", "citrine"],
        "patterns": {
            "recommended": ["animal print", "bold medallion", "rich damask", "statement florals"],
            "avoid": ["barely-visible micro-weave", "tiny ditsy prints", "wallflower designs"]
        },
        "silhouette_keywords": ["structured shoulder", "fitted waist", "dramatic proportion", "statement sleeve"],
        "occasion_modifiers": {
            "work": "boardroom glamour, polished authority with undeniable presence",
            "intimate": "warm, generous, luxurious fabrics that reward attention",
            "daily": "elevated casual, even basics have a golden warmth"
        },
        "code_leaninto": [
            "Dressing like the lead in your own film. Every outfit should feel like a costume for the most exciting version of you.",
            "Letting one statement piece stop the room. A rich velvet blazer or a gold-thread knit is worth more than ten forgettable basics.",
            "Reaching for warm metals and rich textures in every outfit. Gold hardware, silk linings, and heavy drape are your baseline, not your luxury.",
            "Wearing confidence as your most visible accessory. If the outfit does not make you stand taller, it is not earning its place.",
            "Treating drama as a compliment, not a criticism. A structured shoulder or a bold proportion is how you communicate warmth at scale.",
        ],
        "code_avoid": [
            "Deliberately dressing down when the occasion does not require it. You dim the room when you dim yourself.",
            "Disappearing into safe neutrals that make you blend with the walls. Beige is for people who do not want to be seen.",
            "Apologetic fashion choices that hedge your presence. Half-measures in style always read as uncertainty.",
        ],
        "code_consider": [
            "A signature gold accessory that becomes your personal trademark. People should associate a specific piece with you.",
            "Mixing textures for depth rather than relying on colour alone. Velvet against silk or satin against matte knit adds visual richness.",
        ],
        "opposites": {
            "textures": ["thin lifeless jersey", "budget polyester", "flat matte everything"],
            "colours": ["washed-out pastels", "grubby neutrals", "dull faded tones"],
            "silhouettes": ["shapeless oversized bags", "deliberately dowdy cuts", "invisible minimalism"],
            "mood": ["understated", "self-effacing", "deliberately invisible", "bland"]
        }
    },
    "venus_virgo": {
        "style_philosophy": "refined, precise, understated elegance",
        "textures": {
            "good": ["fine-gauge knit", "crisp poplin", "polished cotton", "pressed linen", "structured crepe"],
            "bad": ["wrinkled unfinished fabrics", "sloppy oversized knits", "cheap synthetic blends"],
            "sweet_spot_keywords": ["precision", "clean finish", "craftsmanship"]
        },
        "colours": {
            "primary": [
                {"name": "soft sage", "hex": "#9CAF88"},
                {"name": "warm taupe", "hex": "#8B8589"},
                {"name": "warm ivory", "hex": "#FFFFF0"}
            ],
            "accent": [
                {"name": "soft navy", "hex": "#3B5998"},
                {"name": "sand", "hex": "#C2B280"},
                {"name": "honey", "hex": "#EB9605"}
            ],
            "avoid": ["loud clashing colours", "garish prints", "neon tones"]
        },
        "metals": ["brushed silver", "white gold", "matte platinum"],
        "stones": ["peridot", "amazonite", "moss agate"],
        "patterns": {
            "recommended": ["fine pinstripe", "subtle check", "micro-houndstooth", "tone-on-tone herringbone"],
            "avoid": ["loud graphics", "chaotic prints", "oversized logos"]
        },
        "silhouette_keywords": ["tailored", "clean line", "precise fit", "uncluttered"],
        "occasion_modifiers": {
            "work": "impeccably groomed, the person whose outfit always looks right",
            "intimate": "understated sensuality, clean lines that reveal through precision",
            "daily": "polished even in casual, every detail considered"
        },
        "code_leaninto": [
            "Checking the construction of every garment before you check the price. The seams, the buttons, and the hem tell you everything.",
            "Prioritising a perfect fit over a perfect trend. A well-tailored basic outperforms a poorly fitting statement piece every time.",
            "Building on neutral foundations with one subtle point of interest. A perfectly pressed shirt with a single beautiful button is your ideal.",
            "Investing in alterations as a core wardrobe strategy. A twenty-pound adjustment turns an off-the-rack piece into something bespoke.",
        ],
        "code_avoid": [
            "Visible logos and heavy branding that do the talking for you. Your precision speaks louder than any label.",
            "Wrinkled or creased presentations that undermine your natural authority. If it is not pressed, it is not ready.",
            "Anything that looks hasty, unconsidered, or thrown together. Each item should look like a deliberate decision.",
        ],
        "code_consider": [
            "A signature wardrobe maintenance ritual. Regular pressing, folding, and seasonal edits keep your collection sharp.",
            "Tonal dressing with texture variation as your secret weapon. A sage knit over a sage poplin reads as sophisticated, not boring.",
        ],
        "opposites": {
            "textures": ["wrinkled linen left unfinished", "sloppy oversized knits", "cheap blends"],
            "colours": ["loud clashing palettes", "garish neons", "chaotic multi-colour"],
            "silhouettes": ["sloppy oversized drape", "intentionally messy deconstructed", "unfinished edges"],
            "mood": ["chaotic", "sloppy", "haphazard", "ostentatious"]
        }
    },
    "venus_libra": {
        "style_philosophy": "balanced, harmonious, effortlessly elegant",
        "textures": {
            "good": ["fluid silk", "soft crepe", "fine wool", "organza", "lightweight cashmere"],
            "bad": ["rough burlap", "stiff heavy canvas", "harsh industrial fabrics"],
            "sweet_spot_keywords": ["balance", "drape", "grace"]
        },
        "colours": {
            "primary": [
                {"name": "rose pink", "hex": "#FF66B2"},
                {"name": "powder blue", "hex": "#B0E0E6"},
                {"name": "soft mauve", "hex": "#E0B0FF"}
            ],
            "accent": [
                {"name": "champagne", "hex": "#F7E7CE"},
                {"name": "dusty rose", "hex": "#DCAE96"},
                {"name": "light copper", "hex": "#D4956A"}
            ],
            "avoid": ["harsh primaries", "aggressive neons", "stark black-and-white contrast"]
        },
        "metals": ["rose gold", "polished copper", "soft gold"],
        "stones": ["rose quartz", "kunzite", "pink tourmaline"],
        "patterns": {
            "recommended": ["art deco motifs", "mirror-image damask", "elegant stripes", "balanced geometric"],
            "avoid": ["chaotic abstract", "aggressive asymmetry", "clashing prints"]
        },
        "silhouette_keywords": ["balanced proportion", "cinched waist", "flowing hem", "symmetrical detail"],
        "occasion_modifiers": {
            "work": "diplomatic elegance, polished without being intimidating",
            "intimate": "graceful, romantic, harmonious beauty that draws people in",
            "daily": "effortlessly put together, looking good without trying too hard"
        },
        "code_leaninto": [
            "Balancing proportions between top and bottom. If the top is voluminous, the bottom should be slim. Harmony is your operating principle.",
            "Building soft colour stories that feel cohesive from head to toe. Every piece should look like it belongs in the same painting.",
            "Choosing elegant simplicity over dramatic statement. A beautifully draped dress does more for you than a hundred loud accessories.",
            "Investing in pieces that transition from day to evening with a single swap. A silk blouse that works under a blazer and over bare shoulders is ideal.",
        ],
        "code_avoid": [
            "Deliberately jarring combinations that create visual conflict. Tension in your outfit creates tension in your body.",
            "Aggressive power dressing that overwhelms your natural grace. Sharp shoulders and hard lines fight your energy rather than channel it.",
            "Anything that feels confrontational or intentionally abrasive. Your style should draw people in, not push them away.",
        ],
        "code_consider": [
            "A rotating collection of beautiful scarves or shawls. They add elegance, frame the face, and give you infinite variation.",
            "Colour harmony as a daily practice. Laying out tomorrow's outfit the night before lets you compose rather than scramble.",
        ],
        "opposites": {
            "textures": ["rough burlap", "stiff heavy canvas", "harsh industrial materials"],
            "colours": ["aggressive neons", "jarring clashing palettes", "severe all-black"],
            "silhouettes": ["aggressively oversized", "deliberately confrontational shapes", "harsh angular cuts"],
            "mood": ["aggressive", "confrontational", "deliberately ugly", "jarring"]
        }
    },
    "venus_scorpio": {
        "style_philosophy": "magnetic, powerful, controlled revelation",
        "textures": {
            "good": ["structured leather", "heavy silk", "dense knit", "raw denim", "matte jersey"],
            "bad": ["fluffy angora", "frilly chiffon", "anything overtly cute"],
            "sweet_spot_keywords": ["weight", "control", "concealment"]
        },
        "colours": {
            "primary": [
                {"name": "midnight", "hex": "#191970"},
                {"name": "shadow", "hex": "#36454F"},
                {"name": "ink", "hex": "#1B1B1B"}
            ],
            "accent": [
                {"name": "deep oxblood", "hex": "#4A0000"},
                {"name": "cold forest green", "hex": "#2C5F2D"},
                {"name": "dark plum", "hex": "#580F41"}
            ],
            "avoid": ["candy pastels", "cheerful brights", "anything see-through"]
        },
        "metals": ["blackened silver", "gunmetal", "oxidised steel"],
        "stones": ["black onyx", "garnet", "obsidian", "smoky quartz"],
        "patterns": {
            "recommended": ["tone-on-tone shadow jacquard", "dark-on-dark jacquard", "pinstripe", "monochromatic tone-on-tone"],
            "avoid": ["cheerful florals", "bright gingham", "whimsical prints"]
        },
        "silhouette_keywords": ["fitted", "elongated", "high neckline", "strategic exposure"],
        "occasion_modifiers": {
            "work": "quiet power, the person everyone notices but nobody can read",
            "intimate": "controlled intensity, revealing through subtraction not addition",
            "daily": "dark, purposeful, armour that moves"
        },
        "code_leaninto": [
            "Investing in the darkest foundations you can find. If a black does not feel bottomless, keep looking.",
            "Placing one strategically chosen point of exposure. A slit, a neckline, a single bare wrist — never more than one.",
            "Letting the cut speak louder than the colour. A sharp shoulder line in ink does more than any bright accent.",
            "Treating quality leather as the structural backbone of your wardrobe. It is armour that ages into something better.",
            "Building dark layers that create depth rather than bulk. Each layer should add a shadow, not a centimetre.",
        ],
        "code_avoid": [
            "Transparent or overly revealing pieces that give everything away. Your power comes from what people cannot see.",
            "Cheerful prints and happy patterns that contradict your intensity. If the fabric looks like it is smiling, it is not for you.",
            "Anything that feels naive or unguarded. Your wardrobe is a controlled environment. Nothing accidental makes it in.",
        ],
        "code_consider": [
            "Dark layering for depth rather than colour variety. Three shades of black create more intrigue than five different colours.",
            "The contrast between matte and shine within your monochrome. A matte knit against a leather with sheen adds dimension without breaking your palette.",
        ],
        "opposites": {
            "textures": ["fluffy angora", "frilly chiffon", "lightweight pastels"],
            "colours": ["candy pastels", "cheerful brights", "sunny yellows"],
            "silhouettes": ["exposed and vulnerable", "cutesy babydoll shapes", "frilly romantic volume"],
            "mood": ["naive", "unguarded", "cheerful", "transparent"]
        }
    },
    "venus_sagittarius": {
        "style_philosophy": "adventurous, expansive, culturally curious",
        "textures": {
            "good": ["waxed cotton", "distressed leather", "global textiles", "relaxed linen", "sturdy denim"],
            "bad": ["stiff formal suiting", "restrictive corsetry", "delicate dry-clean-only fabrics"],
            "sweet_spot_keywords": ["durability", "story", "adventure"]
        },
        "colours": {
            "primary": [
                {"name": "cobalt blue", "hex": "#0047AB"},
                {"name": "burnt sienna", "hex": "#E97451"},
                {"name": "warm ochre", "hex": "#CC7722"}
            ],
            "accent": [
                {"name": "deep teal", "hex": "#008080"},
                {"name": "worn leather", "hex": "#7B5B3A"}
            ],
            "avoid": ["corporate grey", "lifeless beige", "overly safe palettes"]
        },
        "metals": ["aged brass", "hammered gold", "oxidised copper"],
        "stones": ["turquoise", "lapis lazuli", "amber"],
        "patterns": {
            "recommended": ["ethnic-inspired prints", "ikat", "batik", "oversized geometric"],
            "avoid": ["corporate pinstripe", "dainty florals", "safe predictable prints"]
        },
        "silhouette_keywords": ["relaxed", "travel-ready", "layered", "bohemian structure"],
        "occasion_modifiers": {
            "work": "globally-minded professional, clothes that say you have been somewhere",
            "intimate": "warm, generous, culturally rich, dinner party not formal dinner",
            "daily": "adventure-ready, layered for climate shifts, packed and unpacked easily"
        },
        "code_leaninto": [
            "Collecting pieces from your travels and wearing the stories. A jacket bought in a Marrakech souk says more than anything from a high street.",
            "Mixing cultural references with confidence and respect. A batik shirt with tailored trousers bridges continents in a single outfit.",
            "Layering for versatility rather than just warmth. A waxed cotton jacket over a linen shirt handles three climates in one day.",
            "Choosing durability over delicacy in every purchase. If it cannot survive being packed into a bag and pulled out crumpled, it is too precious.",
        ],
        "code_avoid": [
            "Rigid dress codes that flatten your natural range. If a rule says you cannot wear it, that is usually a reason to try.",
            "Overly precious clothing that demands careful handling. Dry-clean-only silk does not belong in a life built around movement.",
            "Anything that restricts your stride, your range, or your ability to change plans mid-afternoon.",
        ],
        "code_consider": [
            "A signature travel piece that tells a story every time you wear it. A worn leather bag or a hand-woven scarf becomes a conversation without words.",
            "Versatile layer combinations designed for climate shifts. The ability to strip down or pile on without losing the look is a superpower.",
        ],
        "opposites": {
            "textures": ["stiff formal suiting", "delicate dry-clean-only fabrics", "restrictive corsetry"],
            "colours": ["corporate grey", "lifeless beige", "muted safe tones"],
            "silhouettes": ["rigid corporate structure", "restrictive fitted cuts", "overly polished formal"],
            "mood": ["corporate", "restricted", "predictable", "cautious"]
        }
    },
    "venus_capricorn": {
        "style_philosophy": "classic, authoritative, investment-minded elegance",
        "textures": {
            "good": ["structured wool", "heavy crepe", "pressed cotton", "quality leather", "dense twill"],
            "bad": ["flimsy synthetic", "cheap stretch fabrics", "anything disposable"],
            "sweet_spot_keywords": ["structure", "longevity", "authority"]
        },
        "colours": {
            "primary": [
                {"name": "deep charcoal", "hex": "#333333"},
                {"name": "cool navy", "hex": "#003153"},
                {"name": "dark camel", "hex": "#A0785A"}
            ],
            "accent": [
                {"name": "burgundy", "hex": "#800020"},
                {"name": "bone white", "hex": "#F9F6F0"},
                {"name": "slate blue", "hex": "#6A5ACD"}
            ],
            "avoid": ["trend-driven neons", "childish brights", "flimsy pastels"]
        },
        "metals": ["polished silver", "white gold", "platinum"],
        "stones": ["garnet", "onyx", "sapphire"],
        "patterns": {
            "recommended": ["classic pinstripe", "houndstooth", "glen check", "herringbone"],
            "avoid": ["novelty prints", "cartoonish patterns", "trend-driven logos"]
        },
        "silhouette_keywords": ["structured shoulder", "tailored", "elongated", "column silhouette"],
        "occasion_modifiers": {
            "work": "authoritative and immaculate, the person who always looks promoted",
            "intimate": "controlled luxury, dark tones and quality fabrics that reward close attention",
            "daily": "even weekend wear has a backbone, structured casual"
        },
        "code_leaninto": [
            "Building a wardrobe that appreciates like an investment portfolio. Every piece should gain authority with age, not lose it.",
            "Anchoring everything on dark, structured foundations. A perfectly tailored charcoal suit is worth more than a wardrobe full of trend pieces.",
            "Treating tailoring as non-negotiable. If the shoulders are not precise and the hem is not exact, the garment is not finished.",
            "Choosing timeless over trendy every single time. A classic you wear for a decade outperforms ten seasonal buys.",
        ],
        "code_avoid": [
            "Fast fashion impulse buys that dilute the quality of your collection. One cheap piece can drag down an entire outfit.",
            "Trend-chasing at the expense of quality or longevity. If it will look dated in two seasons, it was never worth buying.",
            "Anything you will not wear confidently in five years. Apply that test in the changing room and most impulse purchases disappear.",
        ],
        "code_consider": [
            "Cost-per-wear as your primary buying metric. A three-hundred-pound coat worn three hundred times costs less than a thirty-pound jacket worn once.",
            "Seasonal wardrobe audits to maintain discipline. Editing your collection twice a year keeps it sharp and prevents accumulation.",
        ],
        "opposites": {
            "textures": ["flimsy synthetic", "cheap stretch fabrics", "disposable fast fashion"],
            "colours": ["childish brights", "neon trend colours", "frivolous pastels"],
            "silhouettes": ["sloppy unstructured drape", "casual athleisure", "deliberately dishevelled"],
            "mood": ["frivolous", "trendy", "disposable", "immature"]
        }
    },
    "venus_aquarius": {
        "style_philosophy": "unconventional, progressive, intellectually driven",
        "textures": {
            "good": ["technical fabrics", "recycled materials", "metallic knits", "neoprene", "laser-cut"],
            "bad": ["traditional tweed", "conventional formal fabrics", "old-fashioned lace"],
            "sweet_spot_keywords": ["innovation", "future", "individuality"]
        },
        "colours": {
            "primary": [
                {"name": "electric blue", "hex": "#7DF9FF"},
                {"name": "silver grey", "hex": "#C0C0C0"},
                {"name": "crisp white", "hex": "#F8F8FF"}
            ],
            "accent": [
                {"name": "ultraviolet", "hex": "#6B0099"},
                {"name": "neon lime", "hex": "#CCFF00"},
                {"name": "icy blue", "hex": "#D6ECEF"}
            ],
            "avoid": ["traditional heritage palettes", "conventional earth tones", "expected combinations"]
        },
        "metals": ["titanium", "surgical steel", "anodised aluminium"],
        "stones": ["labradorite", "fluorite", "ammolite"],
        "patterns": {
            "recommended": ["digital prints", "circuit-inspired", "abstract geometric", "optical illusion"],
            "avoid": ["traditional florals", "heritage plaid", "conventional paisley"]
        },
        "silhouette_keywords": ["architectural", "asymmetric", "deconstructed", "futuristic"],
        "occasion_modifiers": {
            "work": "forward-thinking professional, the one who redefines the dress code",
            "intimate": "unexpected, cerebral beauty that rewards intellectual curiosity",
            "daily": "wearable experiment, every outfit a small rebellion against boring"
        },
        "code_leaninto": [
            "Wearing what nobody else in the room is wearing. If your outfit could belong to anyone, it does not belong to you.",
            "Making sustainable and ethical choices part of your style identity. Recycled fabrics and deadstock finds are rebellion, not compromise.",
            "Mixing eras and genres freely. A vintage military jacket over a futuristic knit proves that rules are optional.",
            "Integrating technology into your accessories. A smart ring or a solar-charging bag makes a statement about where you are headed.",
        ],
        "code_avoid": [
            "Following trends simply because everyone else does. If it is on every feed, it has already lost its edge for you.",
            "Conventional matching rules that assume everyone wants to blend in. Your coordination should look intentional, not obedient.",
            "Safe, predictable combinations that could be assembled by an algorithm. You are not a lookbook. Surprise is part of the point.",
        ],
        "code_consider": [
            "Mixing vintage technology references with modern minimalism. A retro digital watch with a clean architectural coat creates a time-signature only you occupy.",
            "One deliberately unexpected element in every outfit. An asymmetric hem, a clashing texture, or a single wrong colour that turns out to be right.",
        ],
        "opposites": {
            "textures": ["traditional tweed", "conventional lace", "heritage formal fabrics"],
            "colours": ["traditional earth tones", "expected combinations", "heritage palettes"],
            "silhouettes": ["conventional tailoring", "predictable proportions", "safe standard fits"],
            "mood": ["conventional", "predictable", "traditional", "conformist"]
        }
    },
    "venus_pisces": {
        "style_philosophy": "romantic, fluid, dreamlike beauty",
        "textures": {
            "good": ["flowing chiffon", "soft jersey", "watercolour silk", "gauze", "tulle"],
            "bad": ["stiff structured suiting", "hard leather", "rigid tailoring"],
            "sweet_spot_keywords": ["flow", "softness", "ethereal"]
        },
        "colours": {
            "primary": [
                {"name": "lilac", "hex": "#C8A2C8"},
                {"name": "seafoam", "hex": "#93E9BE"},
                {"name": "pale aqua", "hex": "#ADE8F4"}
            ],
            "accent": [
                {"name": "silver shimmer", "hex": "#D8D8D8"},
                {"name": "blush rose", "hex": "#FFB7C5"},
                {"name": "pale violet", "hex": "#DDA0DD"}
            ],
            "avoid": ["harsh industrial tones", "aggressive blacks", "sterile whites"]
        },
        "metals": ["iridescent finishes", "white gold", "opal-set silver"],
        "stones": ["amethyst", "aquamarine", "moonstone", "opal"],
        "patterns": {
            "recommended": ["watercolour prints", "oceanic motifs", "soft tie-dye", "impressionist florals"],
            "avoid": ["sharp geometric", "harsh stripes", "aggressive graphic prints"]
        },
        "silhouette_keywords": ["flowing", "ethereal", "soft volume", "layered transparency"],
        "occasion_modifiers": {
            "work": "creative professional, soft authority that leads through imagination",
            "intimate": "deeply romantic, flowing fabrics that move with every gesture",
            "daily": "gently layered, comfortable but never shapeless"
        },
        "code_leaninto": [
            "Embracing the flowing and the romantic without apology. If a dress moves like water when you walk, it was made for you.",
            "Layering sheer over opaque for depth and mystery. A chiffon blouse over a silk camisole creates dimension that hard fabrics cannot.",
            "Letting garments move with your body rather than against it. If a piece fights your natural rhythm, it does not belong.",
            "Building colour stories that feel like watercolour paintings. Soft gradients of lilac into seafoam or blush into pearl create your atmosphere.",
        ],
        "code_avoid": [
            "Harsh structured power suits that feel like a costume on you. Your authority comes from presence, not from sharp shoulders.",
            "Aggressive angular silhouettes that cut against your natural fluidity. Hard geometric shapes drain your energy rather than channel it.",
            "Anything that feels militaristic, regimented, or punishing. Your body responds best to softness, not discipline.",
        ],
        "code_consider": [
            "A signature flowing layer as your daily anchor. A wrap, a kimono, or a long scarf becomes your equivalent of a blazer.",
            "Soft colour gradients within a single outfit. Moving from deeper tones at the hem to lighter tones near the face creates a dreamlike effect.",
        ],
        "opposites": {
            "textures": ["stiff structured suiting", "hard leather armour", "rigid tailoring"],
            "colours": ["harsh industrial tones", "aggressive blacks", "stark clinical white"],
            "silhouettes": ["rigid angular structure", "military precision", "hard sharp shoulders"],
            "mood": ["rigid", "aggressive", "confrontational", "clinical"]
        }
    }
}

# ─── MOON (12 entries, high detail, emotional/comfort driver) ────────

MOON_ENTRIES = {
    "moon_aries": {
        "style_philosophy": "emotionally bold, comfort in action, impatient with fuss",
        "textures": {
            "good": ["performance knits", "stretch cotton", "lightweight wool", "washed silk"],
            "bad": ["heavy velvet", "restrictive corsetry", "delicate dry-clean-only"],
            "sweet_spot_keywords": ["speed", "freedom", "energy"]
        },
        "colours": {
            "primary": [{"name": "fire red", "hex": "#B22222"}, {"name": "warm terracotta", "hex": "#E2725B"}],
            "accent": [{"name": "warm ivory", "hex": "#FFFFF0"}],
            "avoid": ["cold greys", "depressing neutrals"]
        },
        "metals": ["rose gold", "polished copper"],
        "stones": ["carnelian", "ruby", "red agate"],
        "patterns": {"recommended": ["bold colour blocks", "racing stripes", "chevron"], "avoid": ["dainty florals", "fussy prints"]},
        "silhouette_keywords": ["athletic", "streamlined", "movement-friendly"],
        "occasion_modifiers": {"work": "energetic and decisive", "intimate": "bold and direct warmth", "daily": "grab-and-go ease"},
        "code_leaninto": [
            "Keeping it simple and fast to put on. If the outfit takes more than five minutes, your patience is already gone.",
            "Choosing comfort that still looks sharp. A perfect stretch trouser and a clean knit lets you move without looking sloppy.",
            "Letting one bold piece carry the emotional weight of the outfit. A standout jacket or a vivid shoe gives you energy all day.",
            "Dressing for how you want to feel, not how you think you should look. Your emotions lead, and the outfit follows.",
        ],
        "code_avoid": [
            "Complicated getting-ready routines that eat into your morning. If the outfit needs a tutorial, it is too much.",
            "Fragile fabrics that need babying through the day. Dry-clean-only silk and easily-snagged knits will frustrate you by noon.",
            "Overthinking combinations that drain your natural momentum. You dress best on instinct, not on planning.",
        ],
        "code_consider": [
            "Activewear-inspired details in real clothes. A technical zip or a stretch panel in tailored trousers bridges your active and polished sides.",
            "A grab-and-go capsule for low-energy mornings. Three pre-planned outfits hanging ready removes all friction from the day.",
        ],
        "opposites": {"textures": ["heavy velvet", "restrictive corsetry"], "colours": ["cold greys", "depressing neutrals"], "silhouettes": ["fussy detailed construction", "rigid structure"], "mood": ["passive", "overthinking", "hesitant"]}
    },
    "moon_taurus": {
        "style_philosophy": "emotionally grounded, comfort in quality, sensory security",
        "textures": {
            "good": ["cashmere", "organic cotton", "buttery leather", "plush terry", "lambswool"],
            "bad": ["scratchy wool", "stiff synthetics", "rough textures"],
            "sweet_spot_keywords": ["touch", "weight", "security"]
        },
        "colours": {
            "primary": [{"name": "worn leather", "hex": "#7B5B3A"}, {"name": "moss green", "hex": "#8A9A5B"}],
            "accent": [{"name": "buttery cream", "hex": "#FFFDD0"}, {"name": "dusky pink", "hex": "#CC8899"}],
            "avoid": ["jarring neons", "cold clinical palettes"]
        },
        "metals": ["yellow gold", "warm bronze"],
        "stones": ["emerald", "rose quartz", "malachite"],
        "patterns": {"recommended": ["soft plaid", "natural grain jacquard", "tone-on-tone cable knit"], "avoid": ["harsh graphics", "chaotic prints"]},
        "silhouette_keywords": ["relaxed", "enveloping", "generous cut"],
        "occasion_modifiers": {"work": "quietly luxurious presence", "intimate": "enveloping warmth and tactile pleasure", "daily": "well-made comfort that looks effortless"},
        "code_leaninto": [
            "Treating softness as a power move, not a concession. The person in cashmere has already won the room.",
            "Investing in loungewear that makes you feel wealthy. A heavy cotton robe or a silk pyjama set is emotional infrastructure.",
            "Prioritising natural materials against your skin at all times. Your body registers the difference before your mind does.",
            "Buying the most expensive basics you can afford. A perfect white T-shirt in organic cotton resets your whole nervous system.",
        ],
        "code_avoid": [
            "Anything scratchy, stiff, or uncomfortable against your skin. If you have to endure a garment, it is already failing.",
            "Trend pieces that sacrifice comfort for novelty. Your body rejects discomfort faster than your mind accepts a bargain.",
            "Rushing through purchases without touching the fabric. Your hands know more about quality than any label.",
        ],
        "code_consider": [
            "A beautiful dressing gown as a wardrobe essential. The first thing you put on each morning sets your emotional tone for the day.",
            "The weight of a garment as a comfort signal. Heavier fabrics often feel more grounding and secure on your body.",
        ],
        "opposites": {"textures": ["scratchy wool", "stiff synthetics", "cold plastics"], "colours": ["jarring neons", "cold clinical palettes"], "silhouettes": ["rigid restrictive shapes", "uncomfortable formal wear"], "mood": ["anxious", "rushed", "uncomfortable", "deprived"]}
    },
    "moon_gemini": {
        "style_philosophy": "emotionally adaptable, comfort in variety, restless style energy",
        "textures": {
            "good": ["lightweight jersey", "crisp cotton", "mixed blends", "reversible fabrics"],
            "bad": ["heavy unchanging wool", "stiff formal fabrics"],
            "sweet_spot_keywords": ["versatility", "lightness", "change"]
        },
        "colours": {
            "primary": [{"name": "pale yellow", "hex": "#FFFF99"}, {"name": "soft grey", "hex": "#B0B0B0"}],
            "accent": [{"name": "mint", "hex": "#98FF98"}, {"name": "peach", "hex": "#FFDAB9"}],
            "avoid": ["heavy dark monotone"]
        },
        "metals": ["mixed metals", "sterling silver"],
        "stones": ["agate", "citrine", "alexandrite"],
        "patterns": {"recommended": ["mixed-scale stripes and florals", "stripes", "illustrated novelty motifs"], "avoid": ["single heavy pattern", "monotone solids"]},
        "silhouette_keywords": ["convertible", "layered", "dual-purpose"],
        "occasion_modifiers": {"work": "clever and engaging presence", "intimate": "animated and unpredictable", "daily": "ever-changing daily moods reflected in clothes"},
        "code_leaninto": [
            "Having multiple outfit options prepared the night before. Your morning mood is unpredictable, and choice is your comfort.",
            "Layering so you can add or remove pieces as your energy shifts. A scarf on, then off. A jacket shed at noon.",
            "Embracing variety as emotional regulation. Wearing something different each day keeps your mind stimulated and your mood buoyant.",
            "Dressing in pieces that serve double duty. A blazer that works over a T-shirt and over a silk top covers two moods in one.",
        ],
        "code_avoid": [
            "The same outfit formula every single day. Repetition drains you faster than it comforts you.",
            "Rigid capsule rules that remove all surprise from your wardrobe. You need room for spontaneity, even in basics.",
            "Heavy, unchanging fabrics that lock you into one mood. If you cannot adapt the outfit mid-day, it will feel like a trap.",
        ],
        "code_consider": [
            "A capsule wardrobe that has surprise built into its structure. Interchangeable layers with one wildcard piece per week.",
            "Accessories as mood-switchers. A different pair of earrings or a swapped belt can make yesterday's outfit feel brand new.",
        ],
        "opposites": {"textures": ["heavy monotone fabrics", "stiff unchanging wool"], "colours": ["heavy dark monotone"], "silhouettes": ["rigid uniform looks", "one-note dressing"], "mood": ["bored", "stuck", "repetitive"]}
    },
    "moon_cancer": {
        "style_philosophy": "emotionally protective, comfort in familiarity, nostalgic warmth",
        "textures": {
            "good": ["washed cotton", "heritage knits", "soft flannel", "vintage silk", "brushed denim"],
            "bad": ["cold metallics", "hard plastics", "synthetic mesh"],
            "sweet_spot_keywords": ["memory", "warmth", "shell"]
        },
        "colours": {
            "primary": [{"name": "pearl", "hex": "#F0EAD6"}, {"name": "soft white", "hex": "#FAFAFA"}],
            "accent": [{"name": "seashell pink", "hex": "#FFF5EE"}, {"name": "pale blue", "hex": "#AEC6CF"}],
            "avoid": ["aggressive reds", "harsh blacks"]
        },
        "metals": ["antique silver", "white gold"],
        "stones": ["moonstone", "pearl", "selenite"],
        "patterns": {"recommended": ["vintage florals", "nautical stripes", "soft gingham"], "avoid": ["aggressive graphics", "harsh geometric"]},
        "silhouette_keywords": ["wrap", "cocoon", "protective layer", "soft shoulder"],
        "occasion_modifiers": {"work": "warmly professional, the trusted colleague", "intimate": "deeply nurturing, enveloping comfort", "daily": "layered protection, emotional armour in soft form"},
        "code_leaninto": [
            "Keeping clothes with emotional history in active rotation. A coat from your mother or a scarf from a trip holds real power.",
            "Wrapping yourself in soft protective layers as a daily practice. A worn-in cardigan or a heritage shawl is emotional armour.",
            "Treating comfort as a non-negotiable, not a luxury. If a garment makes you tense, it is actively working against you.",
            "Choosing pieces that feel like home. If an outfit does not settle your nervous system, it is not earning its place.",
        ],
        "code_avoid": [
            "Anything emotionally cold or sterile that strips warmth from a room. Clinical minimalism is not your language.",
            "Harsh fabric against your skin, especially near your neck and wrists. Those contact points carry emotional weight.",
            "Exposing too much when you feel fragile. Your wardrobe should protect you, not put you on display.",
        ],
        "code_consider": [
            "A comfort garment you return to when the world is too much. A specific jumper or blanket scarf that signals safety.",
            "The emotional temperature of your wardrobe. Warm tones and soft textures near your body help regulate your mood all day.",
        ],
        "opposites": {"textures": ["cold metallics", "hard plastics", "synthetic mesh"], "colours": ["aggressive reds", "harsh blacks"], "silhouettes": ["exposed vulnerable shapes", "cold minimalist structure"], "mood": ["exposed", "vulnerable", "rootless", "sterile"]}
    },
    "moon_leo": {
        "style_philosophy": "emotionally generous, comfort in being seen, warm self-expression",
        "textures": {
            "good": ["rich velvet", "gold-tone knits", "heavy silk", "warm faux fur"],
            "bad": ["dull matte everything", "austere plain fabrics"],
            "sweet_spot_keywords": ["warmth", "recognition", "glow"]
        },
        "colours": {
            "primary": [{"name": "warm gold", "hex": "#DAA520"}, {"name": "sunset orange", "hex": "#FF6347"}],
            "accent": [{"name": "champagne gold", "hex": "#F7E7CE"}],
            "avoid": ["drab earth tones", "invisible neutrals"]
        },
        "metals": ["yellow gold", "gilded bronze"],
        "stones": ["amber", "sunstone", "golden topaz"],
        "patterns": {"recommended": ["bold florals", "medallion motifs", "sun-inspired"], "avoid": ["plain solids", "wallflower prints"]},
        "silhouette_keywords": ["dramatic", "fitted waist", "statement"],
        "occasion_modifiers": {"work": "warm authority, the inspiring leader", "intimate": "generous and dramatic warmth", "daily": "effortless glamour, even in loungewear"},
        "code_leaninto": [
            "Wearing whatever makes you feel like the star of the scene. If the outfit does not lift your mood, it is not pulling its weight.",
            "Keeping warm tones close to your face. Gold, amber, and sunset shades near your neck and cheeks make you glow from the inside.",
            "Including one piece of drama in every outfit, even on quiet days. A velvet scarf or a bold earring keeps your inner light visible.",
            "Dressing for the reaction you want, not the occasion you are given. Your emotional comfort comes from feeling seen and appreciated.",
        ],
        "code_avoid": [
            "Deliberately dressing down to fit in or avoid attention. Dimming yourself to match the room always backfires emotionally.",
            "Dull, invisible clothing that makes you blend with the walls. If an outfit makes you forgettable, it is making you miserable.",
            "Austere colour palettes that starve your warmth. Grey-on-grey leaves you feeling cold from the inside out.",
        ],
        "code_consider": [
            "A signature warm-tone accessory you wear almost daily. A gold chain or a honey-coloured bag becomes part of your emotional identity.",
            "The lighting in your getting-ready space. Warm light helps you dress for warmth. Cold light leads to cold choices.",
        ],
        "opposites": {"textures": ["dull matte fabrics", "austere plain cotton"], "colours": ["drab earth tones", "invisible neutrals"], "silhouettes": ["deliberately understated", "shapeless invisible cuts"], "mood": ["invisible", "unrecognised", "dimmed", "overlooked"]}
    },
    "moon_virgo": {
        "style_philosophy": "emotionally ordered, comfort in precision, calm in details",
        "textures": {
            "good": ["pressed cotton", "fine merino", "structured jersey", "smooth silk"],
            "bad": ["wrinkled linen", "unfinished edges", "pilling fabrics"],
            "sweet_spot_keywords": ["order", "cleanliness", "smoothness"]
        },
        "colours": {
            "primary": [{"name": "soft grey", "hex": "#B0B0B0"}, {"name": "soft sage", "hex": "#9CAF88"}],
            "accent": [{"name": "sand", "hex": "#C2B280"}],
            "avoid": ["messy tie-dye", "chaotic colour combinations"]
        },
        "metals": ["brushed silver", "matte white gold"],
        "stones": ["peridot", "clear quartz", "amazonite"],
        "patterns": {"recommended": ["micro-check", "fine stripe", "tone-on-tone herringbone"], "avoid": ["loud graphics", "chaotic prints"]},
        "silhouette_keywords": ["clean", "fitted", "uncluttered"],
        "occasion_modifiers": {"work": "immaculate and reliable", "intimate": "quietly elegant attention to detail", "daily": "pressed and tidy even on rest days"},
        "code_leaninto": [
            "Treating ironing and pressing as a form of self-care. The ritual of preparing clothes calms your mind before the day begins.",
            "Keeping a minimalist wardrobe with maximum polish. Fewer pieces, all of them perfect, is your emotional sweet spot.",
            "Making sure everything has a place. A tidy wardrobe translates directly into a tidy state of mind for you.",
            "Choosing fabrics that resist wrinkles and hold their shape. Structured jersey and pressed cotton stay neat through your whole day.",
        ],
        "code_avoid": [
            "Visible wrinkles, stains, or pilling anywhere on your body. These small imperfections create disproportionate anxiety for you.",
            "Chaotic layering that lacks a clear logic. If you cannot explain why each piece is there, the outfit will unsettle you.",
            "Buying in a rush without checking the seams and finish. Your eye will catch the flaw later, and it will bother you daily.",
        ],
        "code_consider": [
            "A weekly wardrobe prep session where you press, mend, and plan. This ritual is as important as the clothes themselves.",
            "Organising by colour and type so getting dressed feels orderly. A calm wardrobe produces calm outfit choices.",
        ],
        "opposites": {"textures": ["wrinkled linen", "pilling fabrics", "unfinished hems"], "colours": ["messy tie-dye", "chaotic colour"], "silhouettes": ["sloppy oversized", "deliberately messy"], "mood": ["chaotic", "messy", "careless", "disordered"]}
    },
    "moon_libra": {
        "style_philosophy": "emotionally balanced, comfort in beauty, peace through aesthetics",
        "textures": {
            "good": ["flowing silk", "soft cashmere", "fine cotton voile", "delicate knit"],
            "bad": ["rough workwear", "heavy industrial fabrics"],
            "sweet_spot_keywords": ["harmony", "beauty", "proportion"]
        },
        "colours": {
            "primary": [{"name": "dusty rose", "hex": "#DCAE96"}, {"name": "soft lavender", "hex": "#E6E6FA"}],
            "accent": [{"name": "powder blue", "hex": "#B0E0E6"}],
            "avoid": ["clashing aggressive tones"]
        },
        "metals": ["rose gold", "polished copper"],
        "stones": ["rose quartz", "kunzite", "blue lace agate"],
        "patterns": {"recommended": ["mirror-image Art Nouveau scroll", "balanced stripes", "art nouveau"], "avoid": ["jarring asymmetry", "aggressive patterns"]},
        "silhouette_keywords": ["balanced", "graceful", "symmetrical"],
        "occasion_modifiers": {"work": "elegant diplomatic presence", "intimate": "harmonious and inviting", "daily": "aesthetically pleasing without effort"},
        "code_leaninto": [
            "Honouring beauty as a genuine emotional need, not vanity. When your outfit is beautiful, your whole nervous system relaxes.",
            "Building balanced outfits that keep your mood level throughout the day. Harmonious proportions translate directly into inner calm.",
            "Investing in aesthetically pleasing basics. Even your simplest pieces should look considered and visually composed.",
            "Dressing for visual harmony first. If the colours and proportions feel right, everything else falls into place.",
        ],
        "code_avoid": [
            "Ugly-on-purpose fashion that creates internal discord. Trend-driven deliberate clashing unsettles your equilibrium.",
            "Aggressively mismatched outfits that fight each other visually. You feel the dissonance in your body, not just your eyes.",
            "Harsh or jarring textures against your skin. Roughness creates emotional static you carry all day.",
        ],
        "code_consider": [
            "Colour palette planning for the week ahead. Knowing Monday through Friday's palette removes morning anxiety.",
            "A beautiful mirror and good lighting as wardrobe essentials. How you see yourself getting dressed shapes how you feel dressed.",
        ],
        "opposites": {"textures": ["rough workwear", "heavy industrial fabrics"], "colours": ["clashing aggressive tones"], "silhouettes": ["aggressively asymmetric", "deliberately ugly shapes"], "mood": ["confrontational", "discordant", "ugly", "harsh"]}
    },
    "moon_scorpio": {
        "style_philosophy": "emotionally intense, comfort in control, private power",
        "textures": {
            "good": ["dense knit", "structured leather", "heavy silk", "bonded fabrics"],
            "bad": ["sheer exposing fabrics", "flimsy chiffon", "see-through materials"],
            "sweet_spot_keywords": ["protection", "density", "control"]
        },
        "colours": {
            "primary": [{"name": "deep burgundy", "hex": "#800020"}, {"name": "ink", "hex": "#1B1B1B"}],
            "accent": [{"name": "dark teal", "hex": "#004953"}],
            "avoid": ["pastel pinks", "cheerful yellows"]
        },
        "metals": ["blackened silver", "gunmetal"],
        "stones": ["obsidian", "smoky quartz", "black tourmaline"],
        "patterns": {"recommended": ["dark-on-dark jacquard weave", "subtle jacquard", "monochrome depth"], "avoid": ["cheerful prints", "bright florals"]},
        "silhouette_keywords": ["controlled", "fitted", "concealing", "high-necked"],
        "occasion_modifiers": {"work": "intimidating competence", "intimate": "intense and selective vulnerability", "daily": "dark comfortable armour"},
        "code_leaninto": [
            "Controlling what others see of you through deliberate wardrobe choices. Concealment is your form of emotional power dressing.",
            "Using dark layers as emotional protection on vulnerable days. A black coat over a black knit creates a shield that actually works.",
            "Prioritising quality over visibility. The best piece in your wardrobe should be the one nobody knows about until they get close.",
            "Dressing to feel emotionally contained and secure. If the outfit holds you together, it is doing its most important job.",
        ],
        "code_avoid": [
            "Anything that makes you feel emotionally exposed or readable. If the outfit reveals more than you intend, it is a liability.",
            "Transparent or flimsy fabrics that strip away your sense of privacy. Your body needs density and opacity to feel safe.",
            "Cheerful colours on days when you feel guarded. Forcing brightness when you need shadow creates an exhausting performance.",
        ],
        "code_consider": [
            "A black wardrobe with deliberate tonal depth variation. Five shades of black is not boring — it is an entire emotional landscape.",
            "How the weight of a garment affects your sense of security. Heavier fabrics often ground your emotions when you are spiralling.",
        ],
        "opposites": {"textures": ["sheer fabrics", "flimsy chiffon", "see-through materials"], "colours": ["pastel pinks", "cheerful yellows"], "silhouettes": ["exposed and revealing", "cutesy shapes"], "mood": ["exposed", "naive", "unguarded", "frivolous"]}
    },
    "moon_sagittarius": {
        "style_philosophy": "emotionally expansive, comfort in freedom, adventurous spirit",
        "textures": {
            "good": ["broken-in leather", "travel-worn cotton", "lightweight wool", "adventure-ready fabrics"],
            "bad": ["constricting formal wear", "delicate hand-wash-only"],
            "sweet_spot_keywords": ["freedom", "movement", "adventure"]
        },
        "colours": {
            "primary": [{"name": "indigo", "hex": "#4B0082"}, {"name": "warm sienna", "hex": "#A0522D"}],
            "accent": [{"name": "turquoise", "hex": "#40E0D0"}],
            "avoid": ["corporate grey", "restrictive black"]
        },
        "metals": ["aged brass", "hammered gold"],
        "stones": ["turquoise", "lapis lazuli", "sodalite"],
        "patterns": {"recommended": ["hand-block artisan print", "ikat", "oversized abstract"], "avoid": ["corporate patterns", "fussy small prints"]},
        "silhouette_keywords": ["relaxed", "layered", "movement-ready"],
        "occasion_modifiers": {"work": "worldly and inspiring", "intimate": "warm and adventurous", "daily": "packed for anywhere, ready for anything"},
        "code_leaninto": [
            "Choosing clothes that can handle a spontaneous trip without notice. If the outfit cannot board a plane tonight, it is too fussy.",
            "Layering for unpredictable days and unpredictable moods. A removable jacket or a tied-around-waist shirt mirrors your emotional flexibility.",
            "Wearing pieces with stories attached. A market scarf or a belt from another country lifts your mood by reminding you where you have been.",
            "Dressing in colours that feel expansive. Indigo, turquoise, and warm earth tones open you up when life feels small.",
        ],
        "code_avoid": [
            "Anything that restricts spontaneity or requires advance planning. If the outfit needs an ironing board, it is not for you today.",
            "Fussy high-maintenance pieces that demand careful handling. Your emotional style is adventure, not museum curation.",
            "Corporate dress codes applied to your personal wardrobe. Rigid rules for casual time feel like a cage to your spirit.",
        ],
        "code_consider": [
            "A travel capsule that works across three climates. Five pieces that handle heat, rain, and a restaurant covers ninety percent of life.",
            "How your wardrobe makes you feel about possibility. If opening it feels like opening a suitcase for a trip, you have got it right.",
        ],
        "opposites": {"textures": ["constricting formal wear", "delicate fabrics"], "colours": ["corporate grey", "restrictive palettes"], "silhouettes": ["rigid formal structure", "constricting fits"], "mood": ["restricted", "confined", "routine-bound", "stuck"]}
    },
    "moon_capricorn": {
        "style_philosophy": "emotionally disciplined, comfort in structure, calm in order",
        "textures": {
            "good": ["structured wool", "heavy cotton", "quality denim", "pressed twill"],
            "bad": ["sloppy jersey", "cheap fleece", "anything shapeless"],
            "sweet_spot_keywords": ["backbone", "structure", "reliability"]
        },
        "colours": {
            "primary": [{"name": "slate", "hex": "#708090"}, {"name": "deep charcoal", "hex": "#333333"}],
            "accent": [{"name": "cool navy", "hex": "#003153"}],
            "avoid": ["frivolous pastels", "whimsical brights"]
        },
        "metals": ["polished silver", "platinum"],
        "stones": ["garnet", "onyx", "jet"],
        "patterns": {"recommended": ["classic check", "herringbone", "pinstripe"], "avoid": ["novelty prints", "childish patterns"]},
        "silhouette_keywords": ["structured", "clean", "authoritative"],
        "occasion_modifiers": {"work": "the definition of professional", "intimate": "controlled elegance behind closed doors", "daily": "structured even in leisure"},
        "code_leaninto": [
            "Using structure as emotional stabilisation. A well-tailored blazer on a chaotic day restores your sense of control.",
            "Anchoring your wardrobe on dark, reliable foundations. Charcoal, navy, and slate give you a consistent baseline that never falters.",
            "Investing in quality basics that last years, not seasons. A perfect trouser and a clean white shirt are your emotional bedrock.",
            "Dressing slightly more formally than the occasion requires. Looking prepared helps you feel prepared from the inside out.",
        ],
        "code_avoid": [
            "Clothes that feel unserious or disposable. If a garment communicates casualness, it communicates emotional carelessness to you.",
            "Sloppy casual that undermines your inner composure. Joggers outside the gym feel like a concession you will regret by lunchtime.",
            "Buying based on whim or impulse. Every unplanned purchase disrupts the order of your wardrobe and your peace of mind.",
        ],
        "code_consider": [
            "A uniform approach to dressing. Consistent and reliable outfits reduce decision fatigue and keep your emotional reserves full.",
            "The emotional return on wardrobe maintenance. Pressing, storing properly, and rotating pieces is your version of self-care.",
        ],
        "opposites": {"textures": ["sloppy jersey", "cheap fleece", "shapeless knits"], "colours": ["frivolous pastels", "whimsical brights"], "silhouettes": ["shapeless casual", "sloppy drape"], "mood": ["undisciplined", "frivolous", "unstable", "careless"]}
    },
    "moon_aquarius": {
        "style_philosophy": "emotionally independent, comfort in difference, cerebral expression",
        "textures": {
            "good": ["tech fabrics", "innovative blends", "recycled materials", "metallic knit"],
            "bad": ["traditional formal fabrics", "predictable cotton"],
            "sweet_spot_keywords": ["individuality", "innovation", "difference"]
        },
        "colours": {
            "primary": [{"name": "electric blue", "hex": "#7DF9FF"}, {"name": "cool silver", "hex": "#AAA9AD"}],
            "accent": [{"name": "ultraviolet", "hex": "#6B0099"}],
            "avoid": ["conventional warm neutrals"]
        },
        "metals": ["titanium", "surgical steel"],
        "stones": ["labradorite", "fluorite", "meteorite"],
        "patterns": {"recommended": ["digital abstract", "laser-cut geometric panel", "circuit motifs"], "avoid": ["traditional florals", "heritage prints"]},
        "silhouette_keywords": ["architectural", "unconventional", "forward-looking"],
        "occasion_modifiers": {"work": "the innovator in the room", "intimate": "intellectually stimulating presence", "daily": "wearable individuality"},
        "code_leaninto": [
            "Being the person nobody can easily categorise. Your emotional comfort comes from knowing your style surprises people.",
            "Finding comfort in standing apart from the crowd. If everyone in the room is dressed the same, your difference is your armour.",
            "Treating innovation as a form of self-care. Experimenting with a new silhouette or an unusual fabric lifts your mood like nothing else.",
            "Choosing pieces that reflect your ideas, not just your body. A garment with an unusual construction or a clever detail feeds your mind.",
        ],
        "code_avoid": [
            "Blending in for safety or social ease. Conformity costs you more emotionally than standing out ever could.",
            "Conventional matching rules that assume everyone wants the same thing. Your coordination logic is your own.",
            "Nostalgia-driven dressing that keeps you in the past. Your emotional axis points forward, and your wardrobe should too.",
        ],
        "code_consider": [
            "One conversation-starting piece in every outfit. A sculptural earring, an unusual bag, or a coat with an unexpected detail does it.",
            "Whether your wardrobe reflects your current thinking. If your clothes are a year behind your ideas, it is time for an edit.",
        ],
        "opposites": {"textures": ["traditional formal fabrics", "predictable cotton"], "colours": ["conventional warm neutrals"], "silhouettes": ["safe conventional shapes", "predictable proportions"], "mood": ["conformist", "predictable", "conventional", "bland"]}
    },
    "moon_pisces": {
        "style_philosophy": "emotionally fluid, comfort in softness, intuitive dressing",
        "textures": {
            "good": ["flowing silk", "soft gauze", "organic cotton", "watercolour prints on lightweight base"],
            "bad": ["stiff structured suiting", "hard angular fabrics"],
            "sweet_spot_keywords": ["flow", "intuition", "softness"]
        },
        "colours": {
            "primary": [{"name": "seafoam", "hex": "#93E9BE"}, {"name": "lilac", "hex": "#C8A2C8"}],
            "accent": [{"name": "silver shimmer", "hex": "#D8D8D8"}],
            "avoid": ["harsh industrial tones", "aggressive reds"]
        },
        "metals": ["iridescent finishes", "silver"],
        "stones": ["amethyst", "aquamarine", "rainbow moonstone"],
        "patterns": {"recommended": ["watercolour motifs", "oceanic prints", "soft abstract"], "avoid": ["harsh geometric", "aggressive graphics"]},
        "silhouette_keywords": ["flowing", "layered", "ethereal"],
        "occasion_modifiers": {"work": "gentle creative authority", "intimate": "deeply romantic and empathetic", "daily": "intuitively dressed, guided by feeling"},
        "code_leaninto": [
            "Dressing by feeling rather than formula. If the outfit does not match your emotional temperature this morning, change it.",
            "Reaching for soft layers that respond to your mood. A gauze wrap on an anxious day or a silk shirt on a hopeful one.",
            "Using sea-inspired tones for emotional grounding. Seafoam, lilac, and pale aqua bring you back to centre when life is loud.",
            "Trusting your intuition in the changing room. If your body relaxes when you put something on, that is all the logic you need.",
        ],
        "code_avoid": [
            "Rigid dress codes that ignore your emotional state. Forcing yourself into structure on a fluid day creates real suffering.",
            "Harsh structured formality that makes you feel like you are performing. Your best work happens when you feel free.",
            "Sharp angular silhouettes that cut against your natural softness. Hard lines create tension your body will carry all day.",
        ],
        "code_consider": [
            "A flowing piece that feels like a comfort blanket. A long silk skirt or a draped cardigan that wraps around you like water.",
            "How sound affects your clothing choices. Fabrics that rustle softly or drape silently match your inner world better than stiff crinkly ones.",
        ],
        "opposites": {"textures": ["stiff suiting", "hard angular fabrics"], "colours": ["harsh industrial tones", "aggressive reds"], "silhouettes": ["rigid angular structure", "military precision"], "mood": ["rigid", "harsh", "analytical", "cold"]}
    }
}

# ─── SUN (12 entries, good detail, core identity) ───────────────────

SUN_ENTRIES = {
    "sun_aries": {
        "style_philosophy": "bold, dynamic, leader of first impressions",
        "textures": {"good": ["crisp cotton", "raw denim", "performance knit", "waxed canvas"], "bad": ["heavy brocade", "fussy lace"], "sweet_spot_keywords": ["energy", "impact", "speed"]},
        "colours": {"primary": [{"name": "bright red", "hex": "#CC0000"}, {"name": "hot orange", "hex": "#FF4500"}], "accent": [{"name": "stark white", "hex": "#FFFFFF"}], "avoid": ["muddy neutrals"]},
        "metals": ["polished brass", "rose gold"], "stones": ["diamond", "red jasper", "carnelian"],
        "patterns": {"recommended": ["bold stripes", "chevron", "graphic blocks"], "avoid": ["fussy florals", "tiny prints"]},
        "silhouette_keywords": ["sharp", "athletic", "decisive"],
        "occasion_modifiers": {"work": "commanding and energetic", "intimate": "direct warmth", "daily": "athletic confidence"},
        "code_leaninto": [
            "Leading with colour in every outfit. A vivid red jacket or a bright trainer says more about you than any safe neutral ever could.",
            "Letting one bold statement piece do the talking. If the outfit has a hero, you do not need supporting cast.",
            "Wearing confidence as your primary accessory. Walk into the room as if you chose every piece for exactly this moment.",
            "Dressing with decisive speed. Your best outfits are the ones you commit to in thirty seconds flat.",
        ],
        "code_avoid": [
            "Blending into the background on purpose. You were not built for camouflage and your clothes should not pretend otherwise.",
            "Overthinking outfits until the energy drains out. Trust your instinct and walk out the door. Second-guessing is someone else's problem.",
            "Playing it safe with colour when the occasion calls for presence. Beige is a retreat, and retreating is not your style.",
        ],
        "code_consider": [
            "A power colour signature that people associate with you. Owning a shade of red or orange makes you instantly recognisable.",
            "The speed of your getting-ready routine as a style metric. If it is fast, confident, and decisive, the outfit will be too.",
        ],
        "opposites": {"textures": ["heavy brocade", "fussy lace"], "colours": ["muddy neutrals", "washed-out tones"], "silhouettes": ["shapeless drape", "indecisive layers"], "mood": ["passive", "indecisive", "meek"]}
    },
    "sun_taurus": {
        "style_philosophy": "luxurious, grounded, sensory-driven identity",
        "textures": {"good": ["cashmere", "suede", "heavy cotton", "buttery leather", "brushed wool"], "bad": ["cheap polyester", "scratchy acrylic"], "sweet_spot_keywords": ["quality", "touch", "substance"]},
        "colours": {"primary": [{"name": "deep sage green", "hex": "#4A6741"}, {"name": "sophisticated caramel", "hex": "#A0722D"}], "accent": [{"name": "dusty rose", "hex": "#DCAE96"}], "avoid": ["jarring neons"]},
        "metals": ["yellow gold", "warm bronze"], "stones": ["emerald", "lapis lazuli", "jade"],
        "patterns": {"recommended": ["natural grain jacquard", "herringbone", "tonal weave"], "avoid": ["chaotic graphics", "aggressive prints"]},
        "silhouette_keywords": ["relaxed structure", "body-conscious", "grounded"],
        "occasion_modifiers": {"work": "quietly luxurious authority", "intimate": "sensually inviting", "daily": "comfortable quality"},
        "code_leaninto": [
            "Choosing quality over quantity as a life rule, not just a wardrobe strategy. One perfect cashmere knit beats five mediocre ones.",
            "Making natural fibres your non-negotiable standard. Cotton, wool, silk, and linen are your baseline, not your luxury tier.",
            "Anchoring your wardrobe on earth tones that feel grounded and enduring. Sage, caramel, and stone carry your energy perfectly.",
            "Letting texture do the talking instead of logos or colour. A brushed wool over suede says everything without shouting.",
        ],
        "code_avoid": [
            "Disposable fashion that treats garments as temporary. If a piece is designed to last one season, it was designed for someone else.",
            "Trend-chasing at the expense of quality or tactile pleasure. Your body knows the difference between real and fake before you do.",
            "Rushing through purchases without engaging your senses. Slow shopping that involves touching, trying, and sitting in a garment is your superpower.",
        ],
        "code_consider": [
            "Seasonal fabric rituals. Rotating your heavy knits in autumn and your linens in spring connects your wardrobe to the rhythm of the year.",
            "The weight and hand of a garment as a primary buying criterion. If it does not feel substantial in your hands, it will not feel right on your body.",
        ],
        "opposites": {"textures": ["cheap polyester", "scratchy acrylic"], "colours": ["jarring neons"], "silhouettes": ["angular aggressive cuts", "stiff uncomfortable shapes"], "mood": ["rushed", "disposable", "abrasive"]}
    },
    "sun_gemini": {
        "style_philosophy": "versatile, intellectually playful, dual-natured",
        "textures": {"good": ["lightweight blends", "crisp shirting", "jersey", "reversible fabrics"], "bad": ["heavy monotone wool", "stiff formal"], "sweet_spot_keywords": ["adaptability", "conversation", "variety"]},
        "colours": {"primary": [{"name": "lemon yellow", "hex": "#FFF44F"}, {"name": "sky blue", "hex": "#87CEEB"}], "accent": [{"name": "tangerine", "hex": "#FF9966"}, {"name": "crisp white", "hex": "#F8F8FF"}], "avoid": ["single-colour monotone"]},
        "metals": ["mixed metals", "white gold"], "stones": ["citrine", "aquamarine", "agate"],
        "patterns": {"recommended": ["mixed-scale print clash", "colour blocking", "whimsical illustrated graphics"], "avoid": ["single uniform patterns"]},
        "silhouette_keywords": ["layered", "modular", "transformable"],
        "occasion_modifiers": {"work": "clever and engaging", "intimate": "playful and surprising", "daily": "never the same outfit twice"},
        "code_leaninto": [
            "Embracing the mix as your signature. A striped shirt with a printed trouser looks chaotic on others but looks like you on you.",
            "Prioritising versatility over consistency. A piece that works three ways is worth triple a piece that works one way perfectly.",
            "Ensuring every outfit contains at least one point of interest. A conversation-starting detail keeps your mind engaged with what you are wearing.",
            "Treating your wardrobe as a modular system. Interchangeable pieces that recombine in new ways suit your dual nature.",
        ],
        "code_avoid": [
            "Boring repetition that numbs your creativity. Wearing the same formula every day drains your mental energy instead of conserving it.",
            "Rigid dress codes that shut down your versatility. If a rule cannot bend, it is not designed for you.",
            "Committing to a single aesthetic identity. You contain multitudes and your wardrobe should reflect that range.",
        ],
        "code_consider": [
            "A daily outfit rotation system that guarantees variety. Planning a different silhouette for each day of the week prevents creative stagnation.",
            "Reversible pieces and dual-purpose garments as wardrobe cornerstones. They satisfy your need for change without doubling your closet space.",
        ],
        "opposites": {"textures": ["heavy monotone fabrics"], "colours": ["single-colour monotone"], "silhouettes": ["rigid uniform looks"], "mood": ["boring", "repetitive", "predictable"]}
    },
    "sun_cancer": {
        "style_philosophy": "nurturing, protective, emotionally intelligent style",
        "textures": {"good": ["soft knits", "vintage cotton", "heritage fabrics", "washed silk"], "bad": ["harsh synthetics", "cold metallics"], "sweet_spot_keywords": ["comfort", "memory", "protection"]},
        "colours": {"primary": [{"name": "pearl white", "hex": "#F0EAD6"}, {"name": "soft silver", "hex": "#C0C0C0"}], "accent": [{"name": "pale blue", "hex": "#AEC6CF"}], "avoid": ["harsh neons", "aggressive blacks"]},
        "metals": ["sterling silver", "white gold"], "stones": ["moonstone", "pearl", "selenite"],
        "patterns": {"recommended": ["vintage florals", "nautical motifs", "soft stripes"], "avoid": ["aggressive graphics"]},
        "silhouette_keywords": ["protective", "layered", "soft structure"],
        "occasion_modifiers": {"work": "warmly professional", "intimate": "deeply comforting", "daily": "softly layered protection"},
        "code_leaninto": [
            "Keeping clothes with emotional significance in active rotation. A handed-down coat or a market find carries more power than anything new.",
            "Layering for emotional armour on days the world feels sharp. A soft knit under a structured jacket is your personal shield.",
            "Seeking vintage finds with history built into the fabric. Pieces that have already been loved carry a warmth that new garments lack.",
            "Choosing soft textures near your skin as a daily practice. Washed cotton and heritage knits create an emotional baseline of safety.",
        ],
        "code_avoid": [
            "Emotionally cold fashion that prioritises edge over warmth. If an outfit makes you feel guarded instead of protected, it has missed the point.",
            "Harsh uncomfortable fabrics that create physical tension. Your body interprets discomfort as emotional threat, and dresses accordingly.",
            "Discarding garments that carry memories. Your wardrobe is an emotional archive, and editing it should be done with care.",
        ],
        "code_consider": [
            "A specific comfort piece for hard days. A particular jumper or blanket scarf that signals safety to your nervous system.",
            "How the first garment you touch each morning sets your emotional tone. Reaching for something soft and familiar can change your whole day.",
        ],
        "opposites": {"textures": ["harsh synthetics", "cold metallics"], "colours": ["harsh neons", "aggressive blacks"], "silhouettes": ["exposed and vulnerable", "cold minimalist"], "mood": ["exposed", "cold", "rootless"]}
    },
    "sun_leo": {
        "style_philosophy": "radiant, expressive, centre-stage presence",
        "textures": {"good": ["rich velvet", "structured satin", "gold-thread details", "heavy silk"], "bad": ["dull matte fabrics", "cheap-looking materials"], "sweet_spot_keywords": ["lustre", "drama", "warmth"]},
        "colours": {"primary": [{"name": "gold", "hex": "#FFD700"}, {"name": "warm amber", "hex": "#FFBF00"}], "accent": [{"name": "deep red", "hex": "#8B0000"}], "avoid": ["drab beige", "faded neutrals"]},
        "metals": ["yellow gold", "polished brass"], "stones": ["sunstone", "amber", "tiger eye"],
        "patterns": {"recommended": ["animal print", "bold florals", "medallion"], "avoid": ["subtle minimalist", "invisible patterns"]},
        "silhouette_keywords": ["dramatic", "confident", "warm proportions"],
        "occasion_modifiers": {"work": "charismatic leadership dressing", "intimate": "generous warm glamour", "daily": "everyday radiance"},
        "code_leaninto": [
            "Being the most memorable person in the room, every room, without exception. If they do not remember what you wore, the outfit underperformed.",
            "Reaching for warm metals as a default. Gold hardware, brass buttons, and amber stones are your baseline, not your special occasion.",
            "Treating drama as a compliment to yourself and to others. A velvet jacket or a bold proportion tells the room you showed up on purpose.",
            "Dressing for your audience as much as for yourself. Your generosity shows in how much visual pleasure you give a room.",
        ],
        "code_avoid": [
            "Deliberately fading into the background to make others comfortable. Dimming your presence is a disservice to everyone, including you.",
            "Dull invisible clothing that treats style as a neutral act. For you, getting dressed is a form of self-expression, not a chore.",
            "Underestimating the power of your entrance. If the outfit does not hold up in the first three seconds, it needs more warmth or drama.",
        ],
        "code_consider": [
            "A signature gold piece that people associate with you. A heavy chain, a statement ring, or a gilded bag becomes part of your brand.",
            "How lighting affects your outfit choices. Warm light enhances your natural palette, so dress for the light you will be standing in.",
        ],
        "opposites": {"textures": ["dull matte fabrics", "cheap materials"], "colours": ["drab beige", "faded neutrals"], "silhouettes": ["deliberately invisible cuts", "shapeless drape"], "mood": ["invisible", "dimmed", "unnoticed"]}
    },
    "sun_virgo": {
        "style_philosophy": "refined, meticulous, quietly perfect",
        "textures": {"good": ["fine-gauge knit", "polished cotton", "crisp linen", "smooth silk"], "bad": ["wrinkled fabrics", "pilling knits"], "sweet_spot_keywords": ["precision", "cleanliness", "detail"]},
        "colours": {"primary": [{"name": "warm taupe", "hex": "#8B8589"}, {"name": "soft sage", "hex": "#9CAF88"}], "accent": [{"name": "soft navy", "hex": "#3B5998"}], "avoid": ["loud clashing tones"]},
        "metals": ["brushed silver", "white gold"], "stones": ["peridot", "sapphire", "amazonite"],
        "patterns": {"recommended": ["micro-houndstooth", "fine stripe", "tone-on-tone herringbone"], "avoid": ["chaotic prints", "oversized logos"]},
        "silhouette_keywords": ["precise", "clean", "tailored"],
        "occasion_modifiers": {"work": "the standard of professionalism", "intimate": "detail-oriented elegance", "daily": "polished even in casual"},
        "code_leaninto": [
            "Prioritising perfect fit over perfect trend in every purchase. A well-tailored basic outranks a poorly fitting designer piece.",
            "Noticing the details others miss and making them your strength. A perfect cuff roll, a clean hem, a flawless press — these are your signatures.",
            "Building on neutral excellence as your foundation. Taupe, sage, and navy carry quiet authority that loud colours cannot match.",
            "Investing in alterations as a standard practice. The twenty minutes a tailor spends transforms an off-the-rack piece into something personal.",
        ],
        "code_avoid": [
            "Visible sloppiness in any form. A loose thread, a scuffed shoe, or a wrinkled collar undermines everything else you have built.",
            "Wrinkled presentations that suggest carelessness. If the garment is not pressed, it is not ready to leave the house.",
            "Overcomplicated outfits that try too hard. Your strength is in refinement, not accumulation. Edit until only the essential remains.",
        ],
        "code_consider": [
            "A tailor on speed dial as a core style resource. Knowing someone who can adjust a shoulder or taper a trouser changes everything.",
            "Tonal dressing as your default mode. Sage on sage or navy on navy with texture variation reads as effortlessly polished.",
        ],
        "opposites": {"textures": ["wrinkled fabrics", "pilling knits"], "colours": ["loud clashing tones"], "silhouettes": ["sloppy oversized", "messy deconstruction"], "mood": ["sloppy", "careless", "chaotic"]}
    },
    "sun_libra": {
        "style_philosophy": "harmonious, aesthetically driven, socially graceful",
        "textures": {"good": ["flowing silk", "soft wool", "fine cotton", "lightweight cashmere"], "bad": ["rough industrial fabrics", "stiff canvas"], "sweet_spot_keywords": ["elegance", "balance", "beauty"]},
        "colours": {"primary": [{"name": "rose pink", "hex": "#FF66B2"}, {"name": "powder blue", "hex": "#B0E0E6"}], "accent": [{"name": "champagne", "hex": "#F7E7CE"}], "avoid": ["harsh primaries", "aggressive neons"]},
        "metals": ["rose gold", "copper"], "stones": ["rose quartz", "opal", "pink tourmaline"],
        "patterns": {"recommended": ["art deco", "balanced Greek-key border", "elegant stripe"], "avoid": ["chaotic abstract", "aggressive asymmetry"]},
        "silhouette_keywords": ["balanced", "proportional", "graceful"],
        "occasion_modifiers": {"work": "diplomatically elegant", "intimate": "romantically harmonious", "daily": "effortlessly beautiful"},
        "code_leaninto": [
            "Prioritising proportion over volume. A slim trouser with a fluid blouse or a structured top with a flowing skirt — balance is your operating system.",
            "Building colour harmony into every outfit as a rule. If the colours do not sing together, the outfit is not finished.",
            "Treating beauty as your core identity expression. For you, aesthetics are not superficial — they are how you make sense of the world.",
            "Investing in pieces that transition seamlessly between contexts. A silk shirt that works at lunch and at dinner is your ideal garment.",
        ],
        "code_avoid": [
            "Deliberately jarring combinations that create visual conflict. Dissonance in your outfit creates dissonance in your day.",
            "Aggressive dressing that overwhelms your natural grace. Power for you comes from charm and composition, not from sharp edges.",
            "Ignoring the overall impression of an outfit. Individual pieces must serve the whole, not compete with each other.",
        ],
        "code_consider": [
            "A palette planner for weekly outfits. Mapping your colour stories in advance ensures that every morning produces a harmonious result.",
            "The role of accessories in completing a composition. A perfectly chosen earring or belt acts like the final brushstroke on a painting.",
        ],
        "opposites": {"textures": ["rough industrial fabrics", "stiff canvas"], "colours": ["harsh primaries", "aggressive neons"], "silhouettes": ["aggressively asymmetric", "confrontational shapes"], "mood": ["aggressive", "confrontational", "discordant"]}
    },
    "sun_scorpio": {
        "style_philosophy": "intense, magnetic, strategically powerful",
        "textures": {"good": ["structured leather", "dense knit", "heavy silk", "matte jersey"], "bad": ["frilly chiffon", "cute prints", "flimsy fabrics"], "sweet_spot_keywords": ["power", "control", "intensity"]},
        "colours": {"primary": [{"name": "ink", "hex": "#1B1B1B"}, {"name": "deep oxblood", "hex": "#4A0000"}], "accent": [{"name": "dark plum", "hex": "#580F41"}], "avoid": ["candy pastels", "cheerful brights"]},
        "metals": ["gunmetal", "blackened silver"], "stones": ["obsidian", "garnet", "black tourmaline"],
        "patterns": {"recommended": ["dark-on-dark jacquard", "matte shadow-weave jacquard", "monochrome depth"], "avoid": ["cheerful florals", "whimsical prints"]},
        "silhouette_keywords": ["fitted", "controlled", "sharp"],
        "occasion_modifiers": {"work": "the power behind the scenes", "intimate": "controlled intensity", "daily": "dark purpose in every piece"},
        "code_leaninto": [
            "Understanding that dark is not basic — dark is power. A full ink palette communicates control that colour cannot replicate.",
            "Practising strategic revelation over total exposure. Show one thing at a time: a wrist, a collarbone, a sharp shoulder. Never everything.",
            "Treating quality leather as an extension of your identity. A perfectly aged leather jacket is not an accessory — it is a statement of intent.",
            "Building outfits that reward close inspection. The interest should be in the texture, the cut, and the weight — not in the colour.",
        ],
        "code_avoid": [
            "Anything naive, cutesy, or performatively innocent. These registers contradict your natural intensity and will feel like a costume.",
            "Transparent vulnerability in your clothing. If the outfit makes you feel exposed or readable, it has betrayed your instinct for control.",
            "Cheerful prints or pastel palettes that flatten your magnetic presence. Your depth disappears under sweetness.",
        ],
        "code_consider": [
            "A monochrome dark wardrobe with deliberate tonal depth. Five shades of black and three of charcoal create an entire world.",
            "How matte and shine contrasts within dark palettes add dimension. A leather panel against matte knit is your version of colour blocking.",
        ],
        "opposites": {"textures": ["frilly chiffon", "cute fabrics"], "colours": ["candy pastels", "cheerful brights"], "silhouettes": ["cutesy babydoll", "exposed vulnerable"], "mood": ["naive", "unguarded", "cheerful", "transparent"]}
    },
    "sun_sagittarius": {
        "style_philosophy": "expansive, adventurous, culturally rich",
        "textures": {"good": ["waxed cotton", "distressed leather", "sturdy linen", "global textiles"], "bad": ["stiff formal suiting", "restrictive fabrics"], "sweet_spot_keywords": ["adventure", "freedom", "story"]},
        "colours": {"primary": [{"name": "cobalt blue", "hex": "#0047AB"}, {"name": "burnt sienna", "hex": "#E97451"}], "accent": [{"name": "warm ochre", "hex": "#CC7722"}], "avoid": ["corporate grey", "lifeless beige"]},
        "metals": ["aged brass", "hammered gold"], "stones": ["turquoise", "lapis lazuli", "amber"],
        "patterns": {"recommended": ["ethnic prints", "ikat", "oversized geometric"], "avoid": ["corporate pinstripe", "safe predictable"]},
        "silhouette_keywords": ["relaxed", "travel-ready", "layered"],
        "occasion_modifiers": {"work": "the worldly professional", "intimate": "warm and culturally generous", "daily": "adventure-ready"},
        "code_leaninto": [
            "Dressing with travel inspiration woven into every outfit. A waxed jacket or a hand-woven scarf carries the energy of the road even at home.",
            "Mixing cultural references with respect and confidence. An ikat shirt with tailored chinos bridges worlds in a single outfit.",
            "Choosing movement-ready layers that adapt to the day. A removable jacket, a rolled sleeve, and sturdy boots handle anything the world throws at you.",
            "Buying pieces that tell stories. A belt from a souk or a hat from a market gives your outfit more identity than any designer label.",
        ],
        "code_avoid": [
            "Rigid dress codes that strip away your natural range. If a rule says you cannot wear it, that rule was not written for you.",
            "Movement-restricting pieces that limit your stride or your spontaneity. If you cannot run for a train in it, it does not belong in your life.",
            "Corporate uniformity that flattens your expansive personality. Your style should feel like a passport, not a prison.",
        ],
        "code_consider": [
            "A signature travel accessory that becomes your trademark. A specific bag, watch, or pair of boots that goes everywhere with you.",
            "How your wardrobe makes you feel about possibility. If opening your wardrobe feels like planning a trip, you have built it right.",
        ],
        "opposites": {"textures": ["stiff formal suiting", "restrictive fabrics"], "colours": ["corporate grey", "lifeless beige"], "silhouettes": ["rigid formal", "constricting fits"], "mood": ["confined", "restricted", "routine-bound"]}
    },
    "sun_capricorn": {
        "style_philosophy": "authoritative, structured, timeless discipline",
        "textures": {"good": ["structured wool", "pressed cotton", "quality leather", "heavy crepe"], "bad": ["cheap stretch", "flimsy synthetic", "disposable fabrics"], "sweet_spot_keywords": ["authority", "longevity", "backbone"]},
        "colours": {"primary": [{"name": "deep charcoal", "hex": "#333333"}, {"name": "cool navy", "hex": "#003153"}], "accent": [{"name": "burgundy", "hex": "#800020"}], "avoid": ["childish brights", "trend neons"]},
        "metals": ["polished silver", "platinum"], "stones": ["garnet", "onyx", "sapphire"],
        "patterns": {"recommended": ["pinstripe", "houndstooth", "glen check"], "avoid": ["novelty prints", "cartoon patterns"]},
        "silhouette_keywords": ["tailored", "elongated", "commanding"],
        "occasion_modifiers": {"work": "the definition of authority", "intimate": "dark refined luxury", "daily": "structured even off-duty"},
        "code_leaninto": [
            "Choosing timeless over trendy as your unbreakable rule. A piece that looks just as right in ten years is the only piece worth buying.",
            "Building on dark power foundations. Charcoal, navy, and deep burgundy carry the authority your identity demands.",
            "Treating tailoring as non-negotiable. If the shoulders are not exact and the hem is not precise, the garment has not earned its place.",
            "Investing in fewer pieces at higher quality. Your wardrobe should feel like a curated collection, not an accumulation.",
        ],
        "code_avoid": [
            "Fast fashion that dilutes the integrity of your collection. One cheap piece undermines the authority of everything around it.",
            "Trend pieces with short lifespans that make your wardrobe feel disposable. You do not do temporary.",
            "Casual dressing that suggests a lack of discipline. Even your weekend clothes should carry structural backbone.",
        ],
        "code_consider": [
            "Cost-per-wear as your primary purchasing metric. A quality overcoat worn five hundred times is the cheapest thing you own.",
            "The power of consistency. When people know what to expect from your style, your presence becomes a form of authority.",
        ],
        "opposites": {"textures": ["cheap stretch", "flimsy synthetic"], "colours": ["childish brights", "trend neons"], "silhouettes": ["sloppy casual", "deliberately dishevelled"], "mood": ["frivolous", "immature", "careless"]}
    },
    "sun_aquarius": {
        "style_philosophy": "progressive, individualistic, intellectually bold",
        "textures": {"good": ["tech fabrics", "recycled materials", "metallic weaves", "innovative blends"], "bad": ["traditional tweed", "conventional formal"], "sweet_spot_keywords": ["innovation", "individuality", "future"]},
        "colours": {"primary": [{"name": "electric blue", "hex": "#7DF9FF"}, {"name": "silver", "hex": "#C0C0C0"}], "accent": [{"name": "ultraviolet", "hex": "#6B0099"}], "avoid": ["traditional earth tones"]},
        "metals": ["titanium", "surgical steel"], "stones": ["amethyst", "labradorite", "fluorite"],
        "patterns": {"recommended": ["digital prints", "abstract geometric", "optical illusion"], "avoid": ["traditional florals", "heritage patterns"]},
        "silhouette_keywords": ["architectural", "asymmetric", "futuristic"],
        "occasion_modifiers": {"work": "the disruptor", "intimate": "cerebral fascination", "daily": "walking innovation"},
        "code_leaninto": [
            "Being impossible to categorise. If someone can describe your style in one word, you have not pushed far enough.",
            "Making sustainable choices as a form of quiet rebellion. Recycled fabrics and vintage finds are protest disguised as fashion.",
            "Mixing decades freely and without apology. A seventies collar with a futuristic trouser proves that time is a construct you do not follow.",
            "Dressing to provoke thought, not just compliments. Your outfit should make people think, not just look.",
        ],
        "code_avoid": [
            "Conforming to expected style codes to make others comfortable. Your difference is the point, not the problem.",
            "Predictable combinations that anyone could assemble. If an algorithm could generate your outfit, it has failed your identity.",
            "Nostalgia-driven dressing that roots you in one era. You are interested in where fashion is going, not where it has been.",
        ],
        "code_consider": [
            "One unexpected element in every outfit. An asymmetric cut, a clashing material, or a single wrong colour that turns out to be right.",
            "Whether your wardrobe reflects your current ideas. If your clothes are behind your thinking, it is time for a radical edit.",
        ],
        "opposites": {"textures": ["traditional tweed", "conventional formal"], "colours": ["traditional earth tones"], "silhouettes": ["conventional tailoring", "safe proportions"], "mood": ["conventional", "predictable", "conformist"]}
    },
    "sun_pisces": {
        "style_philosophy": "dreamy, intuitive, boundaryless creativity",
        "textures": {"good": ["flowing chiffon", "soft jersey", "watercolour silk", "gauze"], "bad": ["stiff suiting", "rigid tailoring"], "sweet_spot_keywords": ["flow", "dream", "softness"]},
        "colours": {"primary": [{"name": "seafoam", "hex": "#93E9BE"}, {"name": "lilac", "hex": "#C8A2C8"}], "accent": [{"name": "pale aqua", "hex": "#ADE8F4"}], "avoid": ["harsh blacks", "industrial tones"]},
        "metals": ["silver", "iridescent finishes"], "stones": ["amethyst", "aquamarine", "opal"],
        "patterns": {"recommended": ["watercolour prints", "oceanic motifs", "impressionist florals"], "avoid": ["harsh geometric", "aggressive stripes"]},
        "silhouette_keywords": ["flowing", "ethereal", "layered"],
        "occasion_modifiers": {"work": "creative visionary", "intimate": "deeply romantic", "daily": "intuitively dressed"},
        "code_leaninto": [
            "Dressing by feeling rather than by formula. If the outfit does not match your emotional weather this morning, change it without guilt.",
            "Reaching for soft flowing layers that move with your body. Chiffon, gauze, and light jersey let you breathe and drift through the day.",
            "Building ocean-inspired palettes as your default colour world. Seafoam, lilac, and pale aqua create an atmosphere around you that feels like home.",
            "Trusting your intuition in the changing room. If your body relaxes when you put something on, that is the only approval you need.",
        ],
        "code_avoid": [
            "Rigid formality that makes you feel like you are performing someone else's role. Your authority comes from presence, not from structure.",
            "Harsh structure that fights your natural fluidity. Sharp shoulders and stiff waistbands create tension you will carry all day.",
            "Colour palettes that feel aggressive or confrontational. Your nervous system responds best to softness and tonal depth.",
        ],
        "code_consider": [
            "A signature flowing accessory as your daily anchor. A long silk scarf, a draped shawl, or a soft wrap becomes your equivalent of a blazer.",
            "How fabric movement affects your confidence. Garments that sway and drape when you walk mirror your natural rhythm and put you at ease.",
        ],
        "opposites": {"textures": ["stiff suiting", "rigid tailoring"], "colours": ["harsh blacks", "industrial tones"], "silhouettes": ["rigid angular cuts", "military precision"], "mood": ["rigid", "aggressive", "clinical"]}
    }
}

# ─── MARS (12 entries, moderate detail, energy/approach) ─────────────

def make_mars_entry(sign, philosophy, good_tex, bad_tex, sweet, prim_cols, acc_cols, avoid_cols, metals, stones, pat_rec, pat_avoid, sil, occ, lean, avoid, consider, opp):
    return {
        "style_philosophy": philosophy,
        "textures": {"good": good_tex, "bad": bad_tex, "sweet_spot_keywords": sweet},
        "colours": {"primary": prim_cols, "accent": acc_cols, "avoid": avoid_cols},
        "metals": metals, "stones": stones,
        "patterns": {"recommended": pat_rec, "avoid": pat_avoid},
        "silhouette_keywords": sil,
        "occasion_modifiers": occ,
        "code_leaninto": lean, "code_avoid": avoid, "code_consider": consider,
        "opposites": opp
    }

MARS_ENTRIES = {
    "mars_aries": make_mars_entry("aries", "assertive, competitive, action-first energy",
        ["performance stretch", "raw denim", "waxed canvas"], ["delicate lace", "flimsy chiffon"], ["impact", "speed", "edge"],
        [{"name": "crimson", "hex": "#DC143C"}, {"name": "hot orange", "hex": "#FF4500"}], [{"name": "stark white", "hex": "#FFFFFF"}], ["pastel softness"],
        ["polished steel", "bright copper"], ["ruby", "red jasper", "bloodstone"],
        ["bold stripes", "chevron", "colour blocking"], ["dainty florals"],
        ["sharp", "athletic", "decisive"],
        {"work": "competitive edge", "intimate": "direct and fiery", "daily": "athletic and ready"},
        [
            "Dressing for action, not deliberation. If the outfit is not ready for anything the day throws at you, it is too cautious.",
            "Choosing sharp lines and bold moves over safe, considered choices. A structured shoulder and a clean trouser say you mean business.",
            "Treating speed as a style value. The best outfit is the one you can throw on in three minutes and still command a room.",
        ],
        [
            "Hesitant or timid clothing that undermines your natural force. If the outfit whispers, it is not speaking your language.",
            "Overthinking combinations that drain your momentum. You dress best on impulse, not on planning.",
        ],
        [
            "Competition-inspired details in daily wear. A racing stripe, a technical zip, or a performance fabric keeps your edge visible.",
            "How the first outfit choice of the day sets your tempo. Choose something bold and the rest of the day follows.",
        ],
        {"textures": ["delicate lace", "flimsy fabrics"], "colours": ["pastel softness"], "silhouettes": ["meek and shapeless"], "mood": ["passive", "timid", "hesitant"]}),
    "mars_taurus": make_mars_entry("taurus", "persistent, slow-burn strength, grounded force",
        ["heavy cotton", "dense denim", "thick knit"], ["flimsy synthetics"], ["endurance", "weight", "permanence"],
        [{"name": "rust", "hex": "#B7410E"}, {"name": "deep olive", "hex": "#556B2F"}], [{"name": "worn leather", "hex": "#7B5B3A"}], ["cold sterile tones"],
        ["warm bronze", "antique brass"], ["bloodstone", "tiger eye"],
        ["earth-tone blocks", "slub-weave cotton solid"], ["busy chaotic prints"],
        ["solid", "grounded", "substantial"],
        {"work": "immovable reliable presence", "intimate": "slow sensual confidence", "daily": "built to last"},
        [
            "Treating durability as a form of personal strength. A heavy denim jacket or a dense knit says you are built to last.",
            "Choosing heavy, reliable fabrics that can take a beating. If the garment cannot survive your day, it is too fragile for your life.",
            "Buying pieces that feel solid in your hands. Weight and substance in a garment mirror the weight and substance of your presence.",
        ],
        [
            "Flimsy disposable pieces that fall apart after a few wears. Insubstantial clothing offends your sense of permanence.",
            "Trend-driven purchases that replace substance with novelty. You would rather wear the same jacket for a decade than chase this season's silhouette.",
        ],
        [
            "Workwear-inspired quality in everyday clothing. A chore coat or a sturdy boot built for the field carries your slow-burn energy perfectly.",
            "How the physical weight of a garment affects your confidence. Heavier fabrics ground you and keep your energy steady.",
        ],
        {"textures": ["flimsy synthetics"], "colours": ["cold sterile tones"], "silhouettes": ["insubstantial lightweight"], "mood": ["flimsy", "unstable", "impermanent"]}),
    "mars_gemini": make_mars_entry("gemini", "quick, versatile, mentally agile energy",
        ["lightweight blend", "stretch shirting", "tech knit"], ["heavy restricting fabrics"], ["speed", "wit", "flexibility"],
        [{"name": "bright yellow", "hex": "#FFD700"}, {"name": "teal", "hex": "#008080"}], [{"name": "light grey", "hex": "#D3D3D3"}], ["heavy monotone"],
        ["white gold", "mixed metals"], ["citrine", "agate"],
        ["layered geometric and text graphics", "graphic text", "stripes"], ["heavy single patterns"],
        ["quick", "convertible", "layered"],
        {"work": "mentally sharp presence", "intimate": "playful quick energy", "daily": "adaptable and light"},
        [
            "Keeping it quick and smart. Your energy moves fast, and your wardrobe should keep up without requiring negotiation.",
            "Having multiple outfit options pre-planned for the morning. Your mood shifts quickly, and a backup ready prevents frustration.",
            "Choosing lightweight, adaptable pieces that can be remixed on the fly. A layer added or removed keeps you agile.",
        ],
        [
            "Slow, heavy dressing that feels like wading through mud. If the outfit slows your thinking, it is the wrong outfit.",
            "Single-purpose garments that lock you into one context. You need clothes that work in three settings, not one.",
        ],
        [
            "Convertible pieces that transform with a roll, a fold, or a swap. A shirt that works tucked and untucked doubles its value.",
            "Speed-dressing as a daily practice. Laying out two complete outfits the night before saves your mental energy for what matters.",
        ],
        {"textures": ["heavy restricting fabrics"], "colours": ["heavy monotone"], "silhouettes": ["heavy rigid structure"], "mood": ["slow", "heavy", "ponderous"]}),
    "mars_cancer": make_mars_entry("cancer", "protective, defensive, emotionally fierce",
        ["soft armour knits", "washed cotton", "dense jersey"], ["exposed sheer fabrics"], ["protection", "strength", "comfort"],
        [{"name": "shell white", "hex": "#FFF5EE"}, {"name": "deep blue", "hex": "#00008B"}], [{"name": "soft grey", "hex": "#B0B0B0"}], ["aggressive reds"],
        ["sterling silver", "antique silver"], ["moonstone", "labrimar"],
        ["nautical stripes", "wave motifs"], ["aggressive graphics"],
        ["protective", "layered", "secure"],
        {"work": "protective leadership", "intimate": "fierce tenderness", "daily": "comfortable shield"},
        [
            "Dressing as emotional armour on days when the world feels sharp. A dense jersey layer or a structured jacket holds you together.",
            "Choosing protective layers that shield without restricting. Soft structure around your torso and shoulders creates a sense of safety.",
            "Treating comfort as a strategic choice, not a concession. The person who feels secure in their clothes fights from a position of strength.",
        ],
        [
            "Emotionally exposing clothes on days you feel vulnerable. Sheer fabrics and low necklines strip away protection you actually need.",
            "Harsh fabrics that create friction against your skin. Physical discomfort amplifies emotional vulnerability for you.",
        ],
        [
            "Comfort-armour pieces that you keep for difficult days. A particular coat or a favourite knit that makes you feel held together.",
            "The relationship between physical warmth and emotional security. Layering up when you feel exposed is not overdressing — it is self-care.",
        ],
        {"textures": ["exposed sheer fabrics"], "colours": ["aggressive reds"], "silhouettes": ["vulnerable and exposed"], "mood": ["exposed", "unprotected", "vulnerable"]}),
    "mars_leo": make_mars_entry("leo", "confident, commanding, warm authority",
        ["structured satin", "heavy cotton", "bold weave"], ["dull matte fabrics"], ["command", "presence", "warmth"],
        [{"name": "copper", "hex": "#B87333"}, {"name": "burnt orange", "hex": "#CC5500"}], [{"name": "gold", "hex": "#FFD700"}], ["drab neutrals"],
        ["polished gold", "brass"], ["sunstone", "citrine"],
        ["bold medallion", "animal accents", "oversized bold-scale abstract"], ["invisible minimal patterns"],
        ["commanding", "broad", "powerful"],
        {"work": "natural born leader energy", "intimate": "bold generous warmth", "daily": "effortlessly commanding"},
        [
            "Leading with confidence in every sartorial choice. If the outfit does not make you feel powerful, it is not doing enough.",
            "Incorporating warm metals and bold gestures into your daily uniform. A gold cuff or a brass-buttoned blazer signals your presence before you speak.",
            "Dressing as if the room is yours before you enter it. Your energy is commanding, and your clothes should match that expectation.",
        ],
        [
            "Shrinking or dimming your presence to accommodate others. You lose more by hiding than you gain by fitting in.",
            "Dull, matte, invisible fabrics that absorb your natural warmth. Your clothes should reflect light, not swallow it.",
        ],
        [
            "A signature power piece you reach for on days that matter. A specific jacket, a bold ring, or a pair of commanding boots.",
            "How your outfit affects your posture and energy. The right clothes make you stand taller and move with more authority.",
        ],
        {"textures": ["dull matte fabrics"], "colours": ["drab neutrals"], "silhouettes": ["deliberately small and meek"], "mood": ["meek", "dimmed", "invisible"]}),
    "mars_virgo": make_mars_entry("virgo", "precise, methodical, quietly powerful",
        ["fine tailoring fabric", "pressed cotton", "structured crepe"], ["sloppy fabrics"], ["precision", "method", "efficiency"],
        [{"name": "brick red", "hex": "#CB4154"}, {"name": "warm taupe", "hex": "#8B8589"}], [{"name": "soft navy", "hex": "#3B5998"}], ["chaotic colours"],
        ["brushed silver", "matte steel"], ["sapphire", "clear quartz"],
        ["micro-check", "fine pinstripe"], ["oversized logos"],
        ["precise", "clean", "efficient"],
        {"work": "surgical precision energy", "intimate": "detailed attention", "daily": "every detail matters"},
        [
            "Wielding precision as a form of power. A perfect cuff, an exact hem, and a clean press speak louder than any bold statement.",
            "Noticing details that others miss and using them strategically. The right button, the right stitch, the right finish — these are your weapons.",
            "Applying methodical energy to your wardrobe. A systematic approach to dressing — same quality, same standards, every day — is your strength.",
        ],
        [
            "Sloppy or careless dressing that contradicts your natural precision. Wrinkles and loose threads are not minor — they are signals.",
            "Buying in haste without examining construction. Your eye for detail demands that you check every seam before committing.",
        ],
        [
            "A perfect hem as a power move. The person whose trousers break at exactly the right point is the person paying attention.",
            "Wardrobe maintenance as a form of discipline. Pressing, mending, and auditing your clothes regularly keeps your edge sharp.",
        ],
        {"textures": ["sloppy fabrics"], "colours": ["chaotic colours"], "silhouettes": ["messy oversized"], "mood": ["careless", "sloppy", "imprecise"]}),
    "mars_libra": make_mars_entry("libra", "strategic, diplomatic, charm as weapon",
        ["fluid silk", "fine wool", "soft structured blend"], ["harsh industrial fabric"], ["strategy", "grace", "diplomacy"],
        [{"name": "rose", "hex": "#FF007F"}, {"name": "soft gold", "hex": "#DAA520"}], [{"name": "powder blue", "hex": "#B0E0E6"}], ["harsh aggressive tones"],
        ["rose gold", "soft copper"], ["pink tourmaline", "kunzite"],
        ["balanced geometric", "elegant stripe"], ["aggressive patterns"],
        ["graceful", "strategic", "charming"],
        {"work": "diplomatic power", "intimate": "charming intensity", "daily": "gracefully assertive"},
        [
            "Using charm as a form of strength in your wardrobe. A beautifully cut blazer disarms a room more effectively than a power suit.",
            "Bringing elegance to confrontation. When the day demands toughness, a silk blouse with a sharp trouser says you can do both.",
            "Dressing strategically for the reaction you want. Your clothes are diplomatic tools, and every outfit is a negotiation.",
        ],
        [
            "Blunt, aggressive dressing that shuts down dialogue. Your power comes from persuasion, not intimidation.",
            "Harsh industrial textures that contradict your natural grace. Rough fabrics fight your energy instead of channelling it.",
        ],
        [
            "Strategic colour psychology as a daily practice. Soft pink for approachability, navy for authority, white for neutrality — choose consciously.",
            "The role of proportion in first impressions. Balanced shoulders, a defined waist, and a clean line project confidence without confrontation.",
        ],
        {"textures": ["harsh industrial fabric"], "colours": ["harsh aggressive tones"], "silhouettes": ["blunt aggressive shapes"], "mood": ["blunt", "harsh", "aggressive"]}),
    "mars_scorpio": make_mars_entry("scorpio", "intense, strategic, covert power",
        ["heavy leather", "dense knit", "bonded fabric", "matte stretch"], ["transparent fabrics", "flimsy materials"], ["intensity", "stealth", "power"],
        [{"name": "ink", "hex": "#1B1B1B"}, {"name": "blood red", "hex": "#660000"}], [{"name": "dark plum", "hex": "#580F41"}], ["light pastels"],
        ["blackened steel", "gunmetal"], ["obsidian", "black onyx", "garnet"],
        ["dark-on-dark jacquard weave", "dark embossed crest detail"], ["cheerful prints"],
        ["controlled", "lethal precision", "strategic"],
        {"work": "invisible power", "intimate": "dangerous magnetism", "daily": "dark operational mode"},
        [
            "Treating darkness as your power uniform. A full black palette is not absence of colour — it is presence of control.",
            "Exercising strategic wardrobe control at all times. Every piece in your outfit should be there by deliberate choice, not by accident.",
            "Building outfits with covert intensity. The interest should be felt up close — in the weight of the leather, the texture of the knit, the quality of the finish.",
        ],
        [
            "Vulnerability through transparency or exposure. Sheer fabrics and revealing cuts strip away the control you need to function.",
            "Light, cheerful colours that contradict your operative intensity. Pastels and brights flatten your depth into something ordinary.",
        ],
        [
            "Matte versus shine contrasts within a dark palette. A matte jersey against a leather with sheen creates dimension without breaking your code.",
            "How the cut of a garment communicates intention. A sharp collar, a controlled sleeve, or a precise waistband sends signals before you say a word.",
        ],
        {"textures": ["transparent fabrics", "flimsy materials"], "colours": ["light pastels"], "silhouettes": ["exposed and vulnerable"], "mood": ["exposed", "vulnerable", "naive"]}),
    "mars_sagittarius": make_mars_entry("sagittarius", "adventurous, expansive, freedom-driven",
        ["rugged denim", "waxed cotton", "travel-ready knit"], ["restrictive formal fabrics"], ["freedom", "adventure", "range"],
        [{"name": "deep purple", "hex": "#4B0082"}, {"name": "burnt sienna", "hex": "#E97451"}], [{"name": "turquoise", "hex": "#40E0D0"}], ["corporate restriction"],
        ["hammered brass", "aged gold"], ["turquoise", "amber"],
        ["artisan tile-inspired print", "oversized abstract"], ["corporate pinstripe"],
        ["expansive", "unrestricted", "athletic"],
        {"work": "inspiring and energetic", "intimate": "adventure-fuelled warmth", "daily": "always ready to move"},
        [
            "Dressing for adventure as a daily mindset. Even on a regular Tuesday, your outfit should feel ready for the unexpected.",
            "Choosing clothes that can handle anything the day brings. If the garment cannot survive a rainstorm or a spontaneous detour, it is too delicate.",
            "Treating your wardrobe as expedition gear. Every piece should be as functional as it is stylish, with no compromise on either.",
        ],
        [
            "Restrictive formal codes that pin you to one context. Your energy is expansive, and your clothes should expand with it.",
            "Precious garments that demand careful handling. If you have to think about protecting the outfit, it is protecting itself instead of you.",
        ],
        [
            "Multi-climate layering as a core skill. A system that handles heat, cold, and rain within the same outfit is your ultimate wardrobe achievement.",
            "How your footwear reflects your readiness. A boot that can walk five miles and still look sharp at dinner is worth three pairs of dress shoes.",
        ],
        {"textures": ["restrictive formal fabrics"], "colours": ["corporate restriction"], "silhouettes": ["constricting formal"], "mood": ["confined", "restricted", "static"]}),
    "mars_capricorn": make_mars_entry("capricorn", "disciplined, enduring, strategic authority",
        ["heavy structured wool", "quality leather", "dense twill"], ["cheap disposable fabric"], ["discipline", "endurance", "authority"],
        [{"name": "bitter chocolate", "hex": "#3B1F1F"}, {"name": "deep charcoal", "hex": "#333333"}], [{"name": "dark red", "hex": "#8B0000"}], ["frivolous bright colours"],
        ["polished silver", "steel"], ["garnet", "onyx", "hematite"],
        ["herringbone", "glen check", "classic stripe"], ["novelty patterns"],
        ["authoritative", "structured", "impenetrable"],
        {"work": "the highest standard of professionalism", "intimate": "controlled power behind closed doors", "daily": "structured discipline always"},
        [
            "Wielding discipline as the ultimate power tool. A perfectly maintained wardrobe of dark staples says more than any flashy collection.",
            "Making enduring quality the foundation of your style statement. Pieces that look better with age mirror your own trajectory.",
            "Dressing with the authority of someone who has already arrived. Your wardrobe should project seniority even before you have earned it.",
        ],
        [
            "Frivolous or immature pieces that undermine your natural gravitas. If it looks playful, it is fighting your energy.",
            "Casual dressing that suggests a lack of discipline. Even your weekend clothes should carry structural backbone.",
        ],
        [
            "A signature dark authority item you reach for on important days. A specific overcoat or a pair of flawless trousers that projects control.",
            "The power of wardrobe consistency. When people can predict your quality but never your exact outfit, you have achieved mastery.",
        ],
        {"textures": ["cheap disposable fabric"], "colours": ["frivolous bright colours"], "silhouettes": ["casual sloppy drape"], "mood": ["undisciplined", "frivolous", "weak"]}),
    "mars_aquarius": make_mars_entry("aquarius", "rebellious, innovative, unconventionally forceful",
        ["tech fabric", "recycled denim", "metallic knit"], ["traditional conservative fabrics"], ["rebellion", "innovation", "disruption"],
        [{"name": "neon blue", "hex": "#1B03A3"}, {"name": "electric green", "hex": "#00FF00"}], [{"name": "steel grey", "hex": "#71797E"}], ["traditional palettes"],
        ["titanium", "anodised aluminium"], ["labradorite", "meteorite"],
        ["circuit-inspired", "digital glitch", "asymmetric abstract"], ["traditional heritage prints"],
        ["experimental", "deconstructed", "angular"],
        {"work": "the system disruptor", "intimate": "electrifying and unpredictable", "daily": "walking rebellion"},
        [
            "Breaking the rules intentionally, not accidentally. Every unconventional choice should look like a decision, not a mistake.",
            "Treating technology as fashion and fashion as technology. A technical fabric or an innovative cut is your natural language.",
            "Dressing to disrupt expectations in every room you enter. If nobody looks twice, the outfit has not done its job.",
        ],
        [
            "Conventional approaches that assume everyone wants to blend in. Your forceful energy requires an outlet, and conformity blocks it.",
            "Traditional fabrics and heritage patterns that anchor you to the past. Your axis points forward, always.",
        ],
        [
            "Deliberately challenging one style norm each day. An unexpected proportion, a clashing material, or a colour that does not belong but works.",
            "How your outfit signals your values. Recycled materials, ethical brands, and innovative construction communicate your worldview without a word.",
        ],
        {"textures": ["traditional conservative fabrics"], "colours": ["traditional palettes"], "silhouettes": ["conventional safe shapes"], "mood": ["conventional", "safe", "obedient"]}),
    "mars_pisces": make_mars_entry("pisces", "fluid, intuitive, gentle persistence",
        ["soft stretch", "flowing jersey", "waterproof tech"], ["stiff rigid fabrics"], ["flow", "intuition", "adaptability"],
        [{"name": "sea blue", "hex": "#006994"}, {"name": "misty grey", "hex": "#B0B7BF"}], [{"name": "blush rose", "hex": "#FFB7C5"}], ["harsh aggressive tones"],
        ["silver", "iridescent"], ["amethyst", "aquamarine"],
        ["watercolour wash", "soft abstract"], ["harsh geometric stripes"],
        ["fluid", "adaptable", "gentle"],
        {"work": "creative intuitive force", "intimate": "deeply empathetic warmth", "daily": "guided by feeling"},
        [
            "Letting intuition guide your dressing each morning. If the fabric does not feel right when you reach for it, trust that instinct and reach for something else.",
            "Choosing gentle force over brute strength in your wardrobe. A soft flowing layer communicates more power than a hard structured one ever could for you.",
            "Dressing in a way that reflects your inner fluidity. Fabrics that move and drape mirror the adaptable persistence that defines your energy.",
        ],
        [
            "Rigid harsh structures that pin you into a single shape. Stiff jackets and hard waistbands fight your natural flow.",
            "Aggressive colour palettes that contradict your gentle persistence. Your strength is quiet, and your wardrobe should be too.",
        ],
        [
            "Water-inspired elements as a through-line in your style. Oceanic tones, fluid fabrics, and shimmering finishes connect you to your core energy.",
            "How the movement of a garment affects your confidence. Pieces that sway and settle when you walk put you at ease.",
        ],
        {"textures": ["stiff rigid fabrics"], "colours": ["harsh aggressive tones"], "silhouettes": ["rigid military structure"], "mood": ["rigid", "forceful", "harsh"]})
}

# ─── ASCENDANT (12 entries, moderate detail, presentation style) ─────

def make_asc_entry(sign, philosophy, good_tex, bad_tex, sweet, prim_cols, acc_cols, avoid_cols, metals, stones, pat_rec, pat_avoid, sil, occ, lean, avoid, consider, opp):
    return make_mars_entry(sign, philosophy, good_tex, bad_tex, sweet, prim_cols, acc_cols, avoid_cols, metals, stones, pat_rec, pat_avoid, sil, occ, lean, avoid, consider, opp)

ASC_ENTRIES = {
    "ascendant_aries": make_asc_entry("aries", "first impressions of boldness, immediacy, athleticism",
        ["crisp cotton", "structured jersey", "tech knit"], ["heavy formal fabrics"], ["immediacy", "impact", "boldness"],
        [{"name": "bright red", "hex": "#CC0000"}], [{"name": "warm white", "hex": "#FAF0E6"}], ["subdued neutrals"],
        ["rose gold", "polished brass"], ["carnelian", "red jasper"],
        ["bold stripes", "contrast-stitched athletic panel"], ["fussy prints"], ["sharp", "athletic", "energetic"],
        {"work": "dynamic first impression", "intimate": "bold direct presence", "daily": "ready-to-go energy"},
        [
            "Dressing for the first three seconds of every encounter. If the outfit does not land immediately, it has already lost its window.",
            "Committing to sharp clean lines that communicate decisiveness. A structured shoulder and a streamlined silhouette say everything.",
            "Choosing one bold element that anchors the entire first impression. A vivid jacket or a statement shoe makes you instantly memorable.",
        ],
        [
            "Fussy or indecisive presentations that dilute your natural impact. If the outfit looks like you could not choose, neither can anyone else.",
            "Layers that obscure your natural dynamism. Keep the silhouette clean so your energy reads clearly from across the room.",
        ],
        [
            "A signature bold accessory that becomes your visual handshake. People should associate a specific piece with your entrance.",
            "How speed and decisiveness in getting dressed translates to how you are perceived. A quick, confident outfit choice projects a quick, confident person.",
        ],
        {"textures": ["heavy formal fabrics"], "colours": ["subdued neutrals"], "silhouettes": ["indecisive layers"], "mood": ["timid", "indecisive", "hesitant"]}),
    "ascendant_taurus": make_asc_entry("taurus", "first impressions of quality, calm, sensory richness",
        ["cashmere", "quality leather", "heavy cotton"], ["cheap synthetics"], ["quality", "calm", "substance"],
        [{"name": "deep sage green", "hex": "#4A6741"}, {"name": "buttery cream", "hex": "#FFFDD0"}], [{"name": "sophisticated caramel", "hex": "#A0722D"}], ["cheap-looking fabrics"],
        ["yellow gold", "warm bronze"], ["emerald", "jade"],
        ["tone-on-tone herringbone", "subtle plaid"], ["loud graphics"], ["relaxed structure", "grounded", "quality"],
        {"work": "calmly authoritative", "intimate": "sensuously inviting", "daily": "effortlessly luxurious"},
        [
            "Looking more expensive than you are. The first impression should suggest quality and calm before anyone checks the label.",
            "Making quality visible from across the room. A beautifully structured coat or a heavy silk shirt reads as luxury at any distance.",
            "Projecting calm and substance through your wardrobe. People should feel settled in your presence, and your clothes contribute to that.",
        ],
        [
            "Anything that looks cheap or disposable on first glance. Your entrance should communicate permanence, not impermanence.",
            "Rushed or unconsidered presentations. If the outfit looks thrown together, it contradicts the grounded impression you naturally create.",
        ],
        [
            "One investment accessory as a first-impression anchor. A quality leather bag or a fine watch sets the tone before you say a word.",
            "How texture communicates quality at a distance. Cashmere, heavy cotton, and structured leather read as premium from across any room.",
        ],
        {"textures": ["cheap synthetics"], "colours": ["cheap-looking tones"], "silhouettes": ["flimsy insubstantial"], "mood": ["cheap", "rushed", "disposable"]}),
    "ascendant_gemini": make_asc_entry("gemini", "first impressions of intelligence, wit, adaptability",
        ["lightweight blend", "crisp shirting", "mixed media"], ["heavy monotone wool"], ["conversation", "wit", "lightness"],
        [{"name": "sky blue", "hex": "#87CEEB"}, {"name": "lemon yellow", "hex": "#FFF44F"}], [{"name": "mint", "hex": "#98FF98"}, {"name": "crisp white", "hex": "#F8F8FF"}], ["dour monotone"],
        ["mixed metals", "sterling silver"], ["citrine", "aquamarine"],
        ["mixed-scale print clash", "whimsical illustrated graphics"], ["heavy single pattern"], ["quick", "varied", "interesting"],
        {"work": "engaging and approachable", "intimate": "sparkly and surprising", "daily": "never boring"},
        [
            "Presenting as someone interesting to talk to before you open your mouth. A clever pattern mix or an unexpected colour pop invites conversation.",
            "Rotating your accessories to keep your first impression fresh. Different earrings, a new scarf, or a swapped watch band costs nothing but changes everything.",
            "Dressing with visual wit. A playful detail — a printed lining flashed on purpose, a mismatched button — signals intelligence.",
        ],
        [
            "Monotonous presentations that suggest a single-track mind. Your brain runs on multiple channels, and your wardrobe should too.",
            "Heavy, unchanging outfits that shut down your natural adaptability. Keep it light enough to adjust mid-day.",
        ],
        [
            "Glasses or eyewear as a style signature. The right pair frames your face and broadcasts your intellectual energy before you speak.",
            "How the first layer people see shapes their assumptions. A bright scarf or an interesting collar reads as approachable and curious.",
        ],
        {"textures": ["heavy monotone wool"], "colours": ["dour monotone"], "silhouettes": ["rigid single look"], "mood": ["boring", "monotonous", "dull"]}),
    "ascendant_cancer": make_asc_entry("cancer", "first impressions of warmth, approachability, gentle strength",
        ["soft knits", "washed cotton", "vintage-feel fabrics"], ["cold industrial materials"], ["warmth", "softness", "trust"],
        [{"name": "soft silver", "hex": "#C0C0C0"}, {"name": "pearl white", "hex": "#F0EAD6"}], [{"name": "pale blue", "hex": "#AEC6CF"}], ["harsh cold tones"],
        ["sterling silver", "white gold"], ["moonstone", "pearl"],
        ["soft florals", "gentle stripes"], ["aggressive graphics"], ["approachable", "warm", "soft-structured"],
        {"work": "trusted and warm", "intimate": "deeply inviting", "daily": "gently protective"},
        [
            "Projecting approachability through softness in your first impression. A warm knit or a gentle colour near your face invites trust.",
            "Keeping warm tones near your face to communicate openness. Cream, blush, and soft blue tell people you are safe to approach.",
            "Dressing in a way that makes people feel comfortable around you. Your wardrobe is your first act of care.",
        ],
        [
            "Intimidating first impressions that push people away before they know you. Sharp shoulders and dark palettes fight your natural warmth.",
            "Cold, clinical presentations that suggest emotional distance. Your energy is warm, and your clothes should match.",
        ],
        [
            "A soft scarf or shawl as a signature piece. It frames your face with warmth and gives people something gentle to remember.",
            "How the neckline of your top affects how approachable you seem. Open, soft necklines invite conversation; high stiff collars create distance.",
        ],
        {"textures": ["cold industrial materials"], "colours": ["harsh cold tones"], "silhouettes": ["sharp intimidating cuts"], "mood": ["cold", "intimidating", "distant"]}),
    "ascendant_leo": make_asc_entry("leo", "first impressions of warmth, confidence, star quality",
        ["rich fabrics", "structured satin", "gold-tone materials"], ["dull cheap-looking fabrics"], ["radiance", "confidence", "warmth"],
        [{"name": "gold", "hex": "#FFD700"}, {"name": "warm amber", "hex": "#FFBF00"}], [{"name": "deep red", "hex": "#8B0000"}], ["drab invisible tones"],
        ["yellow gold", "polished brass"], ["sunstone", "amber", "citrine"],
        ["animal print", "bold florals"], ["invisible minimal"], ["dramatic", "broad", "warm"],
        {"work": "magnetic leadership presence", "intimate": "generous warm radiance", "daily": "casual star power"},
        [
            "Walking into every room as if you own it. Your first impression is a performance, and your outfit is the costume.",
            "Leading with warm metals and rich tones. Gold hardware, amber accessories, and warm fabrics near your face make your entrance radiate.",
            "Making your entrance count every single time. If someone does not notice you walk in, the outfit has underperformed.",
        ],
        [
            "Deliberately dimming your entrance to avoid attention. You lose more by hiding your light than by shining it.",
            "Dull, invisible fabrics that swallow your natural warmth. Flat matte grey and lifeless beige contradict your star-quality energy.",
        ],
        [
            "A signature gold piece that becomes synonymous with your arrival. A chain, a cuff, or a gilded bag that people see before they see your face.",
            "How your posture and outfit work together. The right clothes make you stand taller, and standing taller makes the clothes look better.",
        ],
        {"textures": ["dull cheap fabrics"], "colours": ["drab invisible tones"], "silhouettes": ["deliberately small", "invisible cuts"], "mood": ["invisible", "meek", "unnoticed"]}),
    "ascendant_virgo": make_asc_entry("virgo", "first impressions of precision, intelligence, quiet authority",
        ["fine-gauge knit", "pressed cotton", "structured crepe"], ["wrinkled messy fabrics"], ["precision", "polish", "intelligence"],
        [{"name": "warm taupe", "hex": "#8B8589"}, {"name": "soft sage", "hex": "#9CAF88"}], [{"name": "soft navy", "hex": "#3B5998"}], ["loud flashy tones"],
        ["brushed silver", "white gold"], ["peridot", "sapphire"],
        ["fine check", "subtle stripe"], ["loud logos"], ["clean", "precise", "polished"],
        {"work": "the most put-together person in the room", "intimate": "understated elegance", "daily": "polished even in casual"},
        [
            "Letting precision be your first impression. People should notice how well everything fits before they notice what you are wearing.",
            "Making perfect fit the foundation of your presentation. A tailored shoulder and an exact hem project intelligence before you speak.",
            "Keeping every visible detail immaculate. A clean press, a polished shoe, and a neat cuff tell the room you pay attention.",
        ],
        [
            "Messy or unfinished presentations that undermine your natural authority. A wrinkle or a loose thread speaks louder than you want.",
            "Loud, flashy garments that distract from your quiet power. Your strength is in refinement, not in volume.",
        ],
        [
            "A signature detail that others notice on second glance. A perfect cuff link, a beautifully stitched button, or a precisely folded pocket square.",
            "How the quality of your grooming amplifies your outfit. Clean lines in your clothing matched by clean lines everywhere else creates a complete picture.",
        ],
        {"textures": ["wrinkled messy fabrics"], "colours": ["loud flashy tones"], "silhouettes": ["sloppy oversized"], "mood": ["sloppy", "messy", "careless"]}),
    "ascendant_libra": make_asc_entry("libra", "first impressions of grace, beauty, social ease",
        ["flowing silk", "fine cotton", "soft wool"], ["rough harsh fabrics"], ["grace", "beauty", "ease"],
        [{"name": "rose pink", "hex": "#FF66B2"}, {"name": "powder blue", "hex": "#B0E0E6"}], [{"name": "champagne", "hex": "#F7E7CE"}], ["aggressive dark palettes"],
        ["rose gold", "copper"], ["rose quartz", "opal"],
        ["art deco", "elegant symmetry"], ["chaotic prints"], ["balanced", "graceful", "proportional"],
        {"work": "elegantly approachable", "intimate": "romantically beautiful", "daily": "effortlessly aesthetic"},
        [
            "Leading with beauty and grace as your primary communication tool. People should feel aesthetically pleased before they process anything else.",
            "Balancing proportions in every outfit as a non-negotiable. If the top is loose, the bottom is slim. Harmony is how you enter a room.",
            "Dressing for visual pleasure as an act of generosity. Your well-composed outfit is a gift to every room you walk into.",
        ],
        [
            "Aggressive or jarring entrances that create visual conflict. Your natural grace is undermined by hard edges and clashing elements.",
            "Rough textures and harsh colours that contradict your diplomatic energy. You are the peacemaker, and your wardrobe should reflect that.",
        ],
        [
            "A beautiful first-impression accessory. A silk scarf, a delicate necklace, or a perfectly chosen pair of earrings completes your entrance.",
            "How colour near your face affects how people perceive you. Soft rose, powder blue, and champagne make you look approachable and beautiful.",
        ],
        {"textures": ["rough harsh fabrics"], "colours": ["aggressive dark palettes"], "silhouettes": ["aggressively angular"], "mood": ["aggressive", "harsh", "discordant"]}),
    "ascendant_scorpio": make_asc_entry("scorpio", "first impressions of intensity, mystery, magnetic power",
        ["structured leather", "dense knit", "heavy silk"], ["frilly cute fabrics"], ["intensity", "mystery", "control"],
        [{"name": "ink", "hex": "#1B1B1B"}, {"name": "deep oxblood", "hex": "#4A0000"}], [{"name": "dark plum", "hex": "#580F41"}], ["cheerful bright tones"],
        ["gunmetal", "blackened silver"], ["obsidian", "garnet"],
        ["dark-on-dark jacquard weave", "monochrome depth"], ["happy prints"], ["fitted", "sharp", "magnetic"],
        {"work": "intimidating quiet power", "intimate": "dangerous allure", "daily": "mysterious and controlled"},
        [
            "Using mystery as your most powerful first-impression tool. The less people can read from your outfit, the more they want to know.",
            "Wearing dark colours as a shield and a signal. Ink, oxblood, and deep plum communicate control before you say a word.",
            "Letting your presence do the work. A fitted dark outfit with one sharp detail — a collar, a cuff, a boot — says everything.",
        ],
        [
            "Transparent or overly friendly presentations that give away your intentions. Your power comes from what people cannot immediately decode.",
            "Cheerful, bright colours that contradict your magnetic intensity. Pastels flatten the depth that makes your first impression memorable.",
        ],
        [
            "A single dark statement piece as your signature entrance. A structured leather jacket or a perfectly cut dark coat projects instant authority.",
            "How eye contact and outfit work together. Dark, controlled clothing amplifies the intensity of your gaze — use that deliberately.",
        ],
        {"textures": ["frilly cute fabrics"], "colours": ["cheerful bright tones"], "silhouettes": ["cutesy babydoll", "overly open"], "mood": ["naive", "transparent", "overly friendly"]}),
    "ascendant_sagittarius": make_asc_entry("sagittarius", "first impressions of warmth, worldliness, open confidence",
        ["waxed cotton", "quality denim", "global textiles"], ["stiff formal suiting"], ["warmth", "worldliness", "openness"],
        [{"name": "cobalt blue", "hex": "#0047AB"}, {"name": "burnt sienna", "hex": "#E97451"}], [{"name": "turquoise", "hex": "#40E0D0"}], ["corporate grey monotone"],
        ["aged brass", "hammered gold"], ["turquoise", "lapis lazuli"],
        ["hand-block artisan print", "large-scale tribal medallion"], ["conservative corporate"], ["relaxed", "broad", "open"],
        {"work": "inspiring and worldly", "intimate": "warm and generous", "daily": "adventure-ready confidence"},
        [
            "Projecting openness and worldly experience through your wardrobe. A waxed jacket or a hand-woven scarf tells people you have been places.",
            "Incorporating global references into your daily style. An ikat shirt or a hammered brass cuff communicates range and curiosity.",
            "Making your first impression feel like an invitation. Your clothes should say you are warm, open, and ready for whatever comes next.",
        ],
        [
            "Looking closed or corporate in your first impression. Rigid suiting and grey monotone contradict your naturally expansive energy.",
            "Overly polished presentations that feel rehearsed. Your charm is in your spontaneity, and your outfit should feel the same.",
        ],
        [
            "A signature travel-inspired accessory that becomes part of your entrance. A leather bag with a story or a watch from another country.",
            "How your footwear communicates readiness. A sturdy boot or a well-worn travel shoe signals adventure even in a boardroom.",
        ],
        {"textures": ["stiff formal suiting"], "colours": ["corporate grey monotone"], "silhouettes": ["rigid corporate structure"], "mood": ["closed", "rigid", "parochial"]}),
    "ascendant_capricorn": make_asc_entry("capricorn", "first impressions of authority, maturity, quiet power",
        ["structured wool", "quality suiting", "heavy cotton"], ["cheap casual fabrics"], ["authority", "maturity", "seriousness"],
        [{"name": "deep charcoal", "hex": "#333333"}, {"name": "cool navy", "hex": "#003153"}], [{"name": "dark camel", "hex": "#A0785A"}], ["childish or unserious colours"],
        ["polished silver", "platinum"], ["garnet", "onyx"],
        ["pinstripe", "houndstooth"], ["novelty prints"], ["structured", "elongated", "commanding"],
        {"work": "instant authority", "intimate": "quietly impressive", "daily": "mature even in casual"},
        [
            "Projecting authority from the first second of every encounter. Your outfit should communicate seniority before anyone checks your title.",
            "Building your first impression on structured dark foundations. Charcoal, navy, and deep burgundy carry instant gravitas.",
            "Dressing as if you have already been promoted. Your wardrobe should project where you are going, not where you are.",
        ],
        [
            "Looking young or unserious in your first impression. Casual fabrics and playful colours undermine the authority you naturally command.",
            "Sloppy presentations that suggest a lack of discipline. If the outfit is not precise, the first impression is already compromised.",
        ],
        [
            "A signature structured outerwear piece as your entrance statement. A perfectly tailored coat or a sharp blazer sets the tone instantly.",
            "How the fit of your shoulders shapes your perceived authority. Precise, structured shoulders project competence from across any room.",
        ],
        {"textures": ["cheap casual fabrics"], "colours": ["childish colours"], "silhouettes": ["casual sloppy"], "mood": ["immature", "unserious", "casual"]}),
    "ascendant_aquarius": make_asc_entry("aquarius", "first impressions of originality, intelligence, cool detachment",
        ["tech fabrics", "innovative materials", "metallic knit"], ["traditional conservative fabrics"], ["originality", "cool", "innovation"],
        [{"name": "electric blue", "hex": "#7DF9FF"}, {"name": "silver grey", "hex": "#C0C0C0"}], [{"name": "neon lime", "hex": "#CCFF00"}], ["conventional palettes"],
        ["titanium", "surgical steel"], ["labradorite", "fluorite"],
        ["digital abstract", "holographic-foil chevron"], ["heritage traditional"], ["angular", "unconventional", "futuristic"],
        {"work": "the interesting one", "intimate": "intriguing and different", "daily": "walking conversation starter"},
        [
            "Being unforgettable rather than merely presentable. If someone cannot remember what you wore, the outfit did not do its job.",
            "Including one unexpected element in every first impression. An asymmetric cut, an unusual fabric, or a colour that does not belong but works.",
            "Dressing as a walking thesis statement. Your outfit should communicate that you think differently before you open your mouth.",
        ],
        [
            "Looking like everyone else in the room. Conventional dressing erases the originality that defines your first impression.",
            "Safe, predictable presentations that could belong to any person. Your individuality is your greatest asset and your wardrobe should protect it.",
        ],
        [
            "Unconventional glasses or tech accessories as a signature. Eyewear with an unusual frame or a smart ring signals forward-thinking instantly.",
            "How one deliberately wrong element creates intrigue. A clashing texture or an unexpected proportion makes people lean in rather than glance past.",
        ],
        {"textures": ["traditional conservative fabrics"], "colours": ["conventional palettes"], "silhouettes": ["conventional proportions"], "mood": ["conventional", "forgettable", "bland"]}),
    "ascendant_pisces": make_asc_entry("pisces", "first impressions of gentleness, creativity, otherworldly beauty",
        ["flowing chiffon", "soft jersey", "watercolour fabrics"], ["harsh stiff suiting"], ["gentleness", "dream", "ethereal"],
        [{"name": "lilac", "hex": "#C8A2C8"}, {"name": "seafoam", "hex": "#93E9BE"}], [{"name": "silver shimmer", "hex": "#D8D8D8"}], ["harsh industrial tones"],
        ["silver", "iridescent finishes"], ["amethyst", "aquamarine", "moonstone"],
        ["watercolour prints", "soft abstract"], ["harsh geometric"], ["flowing", "ethereal", "soft"],
        {"work": "gently creative authority", "intimate": "dreamlike and romantic", "daily": "quietly enchanting"},
        [
            "Projecting softness as a genuine strength. People should feel calmer in your presence, and your flowing silhouettes contribute to that.",
            "Making flowing silhouettes your signature entrance. A draped cardigan, a long scarf, or an ethereal dress says gentle creative authority.",
            "Dressing in a way that feels like a mood. Your first impression should create an atmosphere, not just a visual.",
        ],
        [
            "Harsh rigid presentations that contradict your gentle creative energy. Stiff suiting and sharp shoulders fight your natural aura.",
            "Industrial or aggressive colour palettes that strip away your dreamy quality. Your softness is your power — do not armour over it.",
        ],
        [
            "Sheer layers as a mood setter for your entrance. A chiffon overlay or a gauze wrap creates depth and mystery that rigid fabrics cannot.",
            "How the colours near your face affect people's first impression of you. Lilac, seafoam, and silver shimmer create an otherworldly quality.",
        ],
        {"textures": ["harsh stiff suiting"], "colours": ["harsh industrial tones"], "silhouettes": ["rigid angular structure"], "mood": ["harsh", "rigid", "cold"]})
}

# ─── SATURN (12 entries, moderate detail) ────────────────────────────

def make_light_entry(philosophy, good_tex, bad_tex, sweet, prim_cols, acc_cols, avoid_cols, metals, stones, pat_rec, pat_avoid, sil, occ, lean, avoid, consider, opp):
    return {
        "style_philosophy": philosophy,
        "textures": {"good": good_tex, "bad": bad_tex, "sweet_spot_keywords": sweet},
        "colours": {"primary": prim_cols, "accent": acc_cols, "avoid": avoid_cols},
        "metals": metals, "stones": stones,
        "patterns": {"recommended": pat_rec, "avoid": pat_avoid},
        "silhouette_keywords": sil,
        "occasion_modifiers": occ,
        "code_leaninto": lean, "code_avoid": avoid, "code_consider": consider,
        "opposites": opp
    }

SATURN_ENTRIES = {}
saturn_data = [
    ("aries", "disciplined impulse, structured boldness", ["structured cotton", "dense denim"], ["flimsy fabrics"], ["discipline", "restraint"],
     [{"name": "dark red", "hex": "#8B0000"}], [{"name": "charcoal", "hex": "#36454F"}], ["frivolous brights"], ["steel", "iron"], ["hematite", "garnet"],
     ["subtle stripe", "officer's-stripe braid trim"], ["chaotic prints"], ["sharp", "contained"], {"work": "controlled authority", "intimate": "restrained power", "daily": "disciplined energy"},
     [
         "Using discipline as your sharpest edge. A structured jacket on a chaotic day restores order before you say a word.",
         "Building on structured foundations that never waver. Dark, reliable staples form the backbone of everything you wear.",
         "Treating restraint as power dressing. The person who holds back the most often communicates the most authority.",
     ],
     [
         "Impulsive fashion choices that undermine your earned composure. If you grab it without thinking, it probably does not belong.",
         "Flimsy, unstructured pieces that suggest a lack of backbone. Your clothes should have the same discipline you do.",
     ],
     [
         "Military-inspired details as a through-line in your wardrobe. Epaulettes, structured shoulders, and clean brass hardware suit your energy.",
         "How a consistent dark palette communicates reliability. When people know what to expect visually, they trust your judgement.",
     ],
     {"textures": ["flimsy fabrics"], "colours": ["frivolous brights"], "silhouettes": ["unstructured casual"], "mood": ["impulsive", "chaotic", "undisciplined"]}),
    ("taurus", "enduring quality, permanent foundations", ["heavy wool", "heritage tweed", "quality leather"], ["disposable fashion"], ["permanence", "heritage"],
     [{"name": "bitter chocolate", "hex": "#3B1F1F"}], [{"name": "deep sage green", "hex": "#4A6741"}], ["trendy fast colours"], ["antique gold", "bronze"], ["sapphire", "jet"],
     ["heritage check", "traditional stripe"], ["novelty prints"], ["solid", "enduring"], {"work": "timeless authority", "intimate": "heritage luxury", "daily": "built to last"},
     [
         "Buying for the decade, not the season. Every purchase should still feel right in ten years or it is not worth your commitment.",
         "Treating heritage as a core part of your identity. Tweed, heavy wool, and quality leather connect you to permanence.",
         "Choosing pieces that grow more beautiful with age. A patina on leather or a softening in wool is a sign of quality, not wear.",
     ],
     [
         "Disposable trend pieces that contradict your instinct for permanence. If it is designed to be discarded, it insults your values.",
         "Cheap construction that betrays itself after a few wears. Your eye for quality means you notice every failing stitch.",
     ],
     [
         "Heirloom-quality purchases as a wardrobe strategy. Pieces worth passing down carry emotional and material weight that fast fashion cannot.",
         "How weight and density in a garment communicate your values. Heavier fabrics project the endurance and substance you embody.",
     ],
     {"textures": ["disposable fashion"], "colours": ["trendy fast colours"], "silhouettes": ["trend-driven shapes"], "mood": ["trendy", "disposable", "temporary"]}),
    ("gemini", "structured communication, disciplined versatility", ["crisp shirting", "structured blend"], ["sloppy jersey"], ["discipline", "structure"],
     [{"name": "steel grey", "hex": "#71797E"}], [{"name": "soft navy", "hex": "#3B5998"}], ["chaotic multi-colour"], ["white gold", "silver"], ["agate", "clear quartz"],
     ["fine stripe", "grid pattern"], ["wild prints"], ["clean", "structured"], {"work": "precise communicator", "intimate": "carefully considered", "daily": "structured variety"},
     [
         "Taking a structured approach to variety. Planning three different looks for the week ensures range without chaos.",
         "Practising disciplined mixing rather than random combination. Every pattern clash and colour pairing should have a reason behind it.",
         "Using constraints as creative fuel. A limited palette or a defined capsule often produces more interesting results than unlimited choice.",
     ],
     [
         "Chaotic unplanned mixing that reads as confused rather than creative. Your versatility is an asset only when it looks intentional.",
         "Sloppy layering that lacks a clear logic. If someone cannot tell it was a choice, it looks like a mistake.",
     ],
     [
         "A structured weekly outfit plan that guarantees variety within order. Map the week in advance and adjust by mood on the day.",
         "How a rotation system keeps your wardrobe feeling fresh. Cycling through combinations methodically prevents creative fatigue.",
     ],
     {"textures": ["sloppy jersey"], "colours": ["chaotic multi-colour"], "silhouettes": ["chaotic layers"], "mood": ["scattered", "chaotic", "unfocused"]}),
    ("cancer", "protective structure, emotional boundaries through style", ["dense knit", "washed wool", "structured cotton"], ["cold metallics"], ["boundary", "protection"],
     [{"name": "slate blue", "hex": "#6A5ACD"}], [{"name": "warm grey", "hex": "#808069"}], ["emotionally jarring tones"], ["antique silver", "white gold"], ["moonstone", "labradorite"],
     ["classic plaid", "traditional check"], ["aggressive prints"], ["protective", "structured"], {"work": "boundaries with warmth", "intimate": "controlled vulnerability", "daily": "structured comfort"},
     [
         "Recognising that boundaries in clothing reflect boundaries in life. A structured coat or a high-necked knit says you choose what to share.",
         "Building structured comfort layers that protect without restricting. A dense cardigan over a soft tee creates a shield that still lets you breathe.",
         "Treating your wardrobe as emotional architecture. The structure in your clothes helps hold the structure in your day.",
     ],
     [
         "Emotionally exposing outfits on days when you need protection. Sheer fabrics and open necklines strip away the boundary you rely on.",
         "Cold, clinical fabrics that create distance instead of warmth. Your boundaries should feel safe, not sterile.",
     ],
     [
         "A signature protective outer layer you reach for instinctively. A particular coat or jacket that feels like a reliable shield.",
         "How the weight of your outermost layer affects your sense of safety. Heavier coats often provide more emotional grounding.",
     ],
     {"textures": ["cold metallics"], "colours": ["emotionally jarring tones"], "silhouettes": ["exposed vulnerable"], "mood": ["exposed", "boundary-less", "unprotected"]}),
    ("leo", "disciplined glamour, structured warmth", ["structured satin", "heavy wool", "quality velvet"], ["cheap sparkly fabrics"], ["discipline", "control"],
     [{"name": "dark gold", "hex": "#B8860B"}], [{"name": "deep burgundy", "hex": "#800020"}], ["cheap glitter tones"], ["polished gold", "brass"], ["tiger eye", "garnet"],
     ["regal stripe", "classic medallion"], ["cheap novelty"], ["controlled drama", "structured warmth"], {"work": "authoritative presence", "intimate": "controlled luxury", "daily": "disciplined glamour"},
     [
         "Exercising glamour with restraint and intention. A velvet blazer or a silk shirt speaks louder than sequins ever could.",
         "Choosing quality over sparkle every time. Real gold and rich fabric outperform costume shimmer because the depth is genuine.",
         "Dressing with controlled drama that feels earned, not performed. One statement piece anchored by clean structure is your ideal.",
     ],
     [
         "Cheap ostentatious display that substitutes surface for substance. Costume jewellery and fast-fashion glitter undermine your natural presence.",
         "Overdone glamour that tips into costume territory. Your warmth is real, and your clothes should reflect that authenticity.",
     ],
     [
         "Investment glamour pieces that earn their place over years. A quality velvet jacket or a silk pocket square belongs in permanent rotation.",
         "How restraint amplifies impact. Holding back one element — a simpler shoe, a quieter colour — makes the statement piece land harder.",
     ],
     {"textures": ["cheap sparkly fabrics"], "colours": ["cheap glitter tones"], "silhouettes": ["flashy without substance"], "mood": ["flashy", "cheap", "ostentatious"]}),
    ("virgo", "exacting precision, mastery of detail", ["pressed fine cotton", "structured silk", "precise tailoring"], ["any imperfect fabric"], ["mastery", "precision"],
     [{"name": "stone grey", "hex": "#928E85"}], [{"name": "soft sage", "hex": "#9CAF88"}], ["messy uncontrolled tones"], ["brushed silver", "platinum"], ["sapphire", "peridot"],
     ["micro-houndstooth", "Swiss-dot pin-tuck grid"], ["messy abstract"], ["immaculate", "precise"], {"work": "standard of excellence", "intimate": "meticulous elegance", "daily": "precision as habit"},
     [
         "Channelling perfectionism directly into your style. A flawless press, a precise hem, and an immaculate collar are your signature.",
         "Prioritising flawless execution over creative experimentation. The person who nails the basics outperforms the person who chases novelty.",
         "Mastering the details that others overlook. A perfect button, a clean stitch, and a smooth finish are your weapons.",
     ],
     [
         "Any visible imperfection in your wardrobe. Pilling, loose threads, and scuffed shoes create disproportionate anxiety for you.",
         "Messy, deconstructed fashion that celebrates imperfection. What others call deliberately undone, you experience as genuinely careless.",
     ],
     [
         "Regular wardrobe maintenance rituals as a form of discipline. Weekly pressing, seasonal mending, and monthly audits keep your collection pristine.",
         "How the condition of your clothes affects your mental clarity. A well-maintained wardrobe supports a well-maintained mind.",
     ],
     {"textures": ["any imperfect fabric"], "colours": ["messy uncontrolled tones"], "silhouettes": ["careless fit"], "mood": ["imprecise", "messy", "careless"]}),
    ("libra", "structured beauty, disciplined aesthetics", ["fine silk blend", "structured crepe", "quality wool"], ["rough ugly fabrics"], ["balance", "order"],
     [{"name": "soft mauve", "hex": "#E0B0FF"}], [{"name": "slate", "hex": "#708090"}], ["ugly discordant tones"], ["rose gold", "silver"], ["rose quartz", "sapphire"],
     ["balanced damask medallion", "balanced stripe"], ["ugly abstract"], ["graceful structure"], {"work": "elegant authority", "intimate": "structured romance", "daily": "disciplined beauty"},
     [
         "Recognising that beauty requires discipline to maintain. A harmonious wardrobe does not happen by accident — it is built and curated.",
         "Maintaining proportional balance in every outfit. A structured top with a flowing bottom, or vice versa, is your operating principle.",
         "Treating elegance as a daily non-negotiable, not a special-occasion performance. Even your simplest outfit should have compositional grace.",
     ],
     [
         "Ugliness adopted as a deliberate style statement. What others call bold deconstruction, you experience as genuine aesthetic pain.",
         "Jarring combinations that create visual discord. Your nervous system registers disharmony in an outfit as a personal offence.",
     ],
     [
         "Colour harmony as a daily practice. Laying out your palette the night before ensures every morning produces a beautiful result.",
         "How your sense of proportion extends beyond your wardrobe into your environment. Beauty in your clothes supports beauty in your life.",
     ],
     {"textures": ["rough ugly fabrics"], "colours": ["ugly discordant tones"], "silhouettes": ["deliberately ugly shapes"], "mood": ["ugly", "discordant", "unbalanced"]}),
    ("scorpio", "deep discipline, controlled intensity", ["bonded fabric", "structured leather", "dense wool"], ["transparent fabrics"], ["control", "depth"],
     [{"name": "ink", "hex": "#1B1B1B"}], [{"name": "dark burgundy", "hex": "#4A0000"}], ["light revealing tones"], ["blackened steel", "titanium"], ["obsidian", "onyx"],
     ["dark tonal herringbone", "dark embossed crest detail"], ["light cheerful prints"], ["controlled", "concealing"], {"work": "formidable presence", "intimate": "deep controlled power", "daily": "disciplined darkness"},
     [
         "Understanding that control is the ultimate form of power in your wardrobe. Every visible element should be there by precise choice.",
         "Building dark structured layers that create an impenetrable visual presence. Three shades of black with varying textures say more than colour.",
         "Dressing to conceal rather than reveal. What you withhold visually becomes a source of intrigue and authority.",
     ],
     [
         "Revealing or transparent choices that expose more than you intend. Opacity and density are your allies, not constraints.",
         "Light or cheerful fabrics that undermine the depth you naturally project. Your darkness is not absence — it is concentration.",
     ],
     [
         "Treating your wardrobe as life armour, maintained and deployed with strategic intent. Every piece serves a protective purpose.",
         "How the density of fabric affects your sense of control. Heavier, more opaque garments reinforce the containment you need.",
     ],
     {"textures": ["transparent fabrics"], "colours": ["light revealing tones"], "silhouettes": ["exposed and revealing"], "mood": ["exposed", "revealed", "uncontrolled"]}),
    ("sagittarius", "disciplined adventure, structured freedom", ["waxed canvas", "quality denim", "structured travel fabric"], ["impractical delicate fabrics"], ["structure", "endurance"],
     [{"name": "deep navy", "hex": "#000080"}], [{"name": "warm brown", "hex": "#8B6914"}], ["impractical tones"], ["hammered bronze", "aged brass"], ["turquoise", "lapis lazuli"],
     ["global geometric", "structured ethnic"], ["dainty small prints"], ["structured but free"], {"work": "experienced authority", "intimate": "wise warmth", "daily": "structured adventure"},
     [
         "Finding freedom within structure rather than abandoning structure entirely. A well-built travel jacket gives you range and backbone simultaneously.",
         "Choosing durable adventure-ready pieces that handle any terrain. If the garment cannot survive a spontaneous trip, it is too fragile for your life.",
         "Building a wardrobe that works across continents without needing to change its DNA. Universal quality that adapts to any context.",
     ],
     [
         "Impractical or fragile choices that limit your spontaneity. Dry-clean-only silk does not belong in a life built around movement.",
         "Precious garments that demand careful handling over the course of a real day. If it needs protection, it is protecting itself instead of you.",
     ],
     [
         "A structured travel wardrobe that works in five climates with five pieces. The discipline of packing light sharpens your style eye.",
         "How your footwear communicates your readiness for anything. A boot that walks five miles and still looks sharp is worth three dress shoes.",
     ],
     {"textures": ["impractical delicate fabrics"], "colours": ["impractical tones"], "silhouettes": ["fragile impractical"], "mood": ["fragile", "impractical", "naive"]}),
    ("capricorn", "ultimate authority, peak discipline, timeless power", ["finest wool", "structured cashmere", "premium leather"], ["anything cheap"], ["authority", "permanence"],
     [{"name": "jet black", "hex": "#0A0A0A"}, {"name": "slate", "hex": "#708090"}], [{"name": "cool navy", "hex": "#003153"}], ["any frivolous colour"], ["platinum", "polished silver"], ["onyx", "garnet", "sapphire"],
     ["pinstripe", "houndstooth", "classic check"], ["anything novelty"], ["commanding", "impeccable"], {"work": "the standard others aspire to", "intimate": "quiet powerful luxury", "daily": "never off-duty"},
     [
         "Embodying the standard that others aspire to. Your wardrobe should look like the definitive version of whatever dress code applies.",
         "Treating timeless pieces as life investments rather than seasonal purchases. A perfect overcoat or a flawless trouser appreciates over decades.",
         "Building an impeccable collection where nothing is accidental, nothing is filler, and every piece earns its place through quality.",
     ],
     [
         "Anything below your standard in fabric, construction, or fit. A single cheap piece drags down the authority of everything around it.",
         "Compromising on quality for convenience or speed. Your wardrobe demands the same rigour and patience that defines the rest of your life.",
     ],
     [
         "A personal uniform system that removes daily decision-making while maintaining absolute quality. Consistent excellence is your signature.",
         "How the longevity of your wardrobe reflects the longevity of your ambition. Pieces that last decades mirror your long-game mindset.",
     ],
     {"textures": ["anything cheap"], "colours": ["any frivolous colour"], "silhouettes": ["sloppy casual"], "mood": ["frivolous", "undisciplined", "common"]}),
    ("aquarius", "structured rebellion, disciplined innovation", ["tech fabric", "recycled innovation", "structural mesh"], ["traditional stuffy fabrics"], ["innovation", "structure"],
     [{"name": "cool silver", "hex": "#AAA9AD"}], [{"name": "electric blue", "hex": "#7DF9FF"}], ["traditional conservative tones"], ["titanium", "surgical steel"], ["labradorite", "meteorite"],
     ["circuit-inspired", "brutalist grid windowpane"], ["heritage traditional"], ["angular", "innovative"], {"work": "the structured rebel", "intimate": "controlled eccentricity", "daily": "disciplined difference"},
     [
         "Understanding that rebellion needs structure to be effective. A carefully deconstructed jacket communicates more than a randomly torn one.",
         "Innovating within constraints rather than discarding all rules. Limits sharpen your creativity and make your unconventional choices land harder.",
         "Using discipline as a foundation for originality. The most memorable disruptors are precise about how they break the rules.",
     ],
     [
         "Convention for convention's sake that serves no creative purpose. Following rules without questioning them is the real failure.",
         "Traditional stuffy fabrics that anchor you to the past. Your creative axis points forward, and your wardrobe should too.",
     ],
     [
         "A structured approach to standing out. Planning your unconventional elements with the same care others plan their conventional ones.",
         "How a signature unconventional detail becomes your trademark. One consistent surprise — an unusual collar, a tech accessory — creates recognition.",
     ],
     {"textures": ["traditional stuffy fabrics"], "colours": ["traditional conservative tones"], "silhouettes": ["conventional safe shapes"], "mood": ["conventional", "traditional", "safe"]}),
    ("pisces", "structured dreaminess, disciplined intuition", ["fluid structured silk", "weighted jersey", "dense chiffon"], ["stiff harsh fabrics"], ["grounding", "flow"],
     [{"name": "deep purple", "hex": "#4B0082"}], [{"name": "seafoam", "hex": "#93E9BE"}], ["harsh jarring tones"], ["silver", "white gold"], ["amethyst", "sapphire"],
     ["subtle watercolour", "structured abstract"], ["harsh geometric"], ["flowing but grounded"], {"work": "grounded creative authority", "intimate": "structured romance", "daily": "disciplined softness"},
     [
         "Grounding the dream with structure underneath. A fitted camisole beneath a flowing dress gives your softness a backbone that holds all day.",
         "Layering structured pieces over flowing base layers to create depth with discipline. The contrast between control and flow is your aesthetic.",
         "Using structure as an anchor for your intuitive dressing. A belt, a tailored jacket, or a defined waist prevents softness from becoming shapelessness.",
     ],
     [
         "Losing structure entirely and letting everything drift. Your dreaminess needs a frame, or it dissolves into something forgettable.",
         "Harsh rigid fabrics that crush your natural softness. The structure should support the flow, not fight it.",
     ],
     [
         "Structured underlayers beneath flowing outer pieces as a daily strategy. A fitted base gives you freedom to drape and wrap on top.",
         "How a single structured element — a belt, a boot, a jacket — transforms a flowing outfit from vague to intentional.",
     ],
     {"textures": ["stiff harsh fabrics"], "colours": ["harsh jarring tones"], "silhouettes": ["rigid harsh structure"], "mood": ["harsh", "rigid", "unfeeling"]})
]

for s_sign, *s_data in saturn_data:
    SATURN_ENTRIES[f"saturn_{s_sign}"] = make_light_entry(*s_data)

# ─── JUPITER, MERCURY, URANUS, NEPTUNE, PLUTO (60 entries, lighter detail) ───

def make_outer_entry(philosophy, sweet_spot, good_tex, bad_tex, prim_cols, acc_cols, avoid_cols, metals, stones, pat_rec, pat_avoid, sil, occ, lean, avoid_list, consider, opp):
    """Constructor for outer planet entries. philosophy must be comma-separated short phrases for WP3 mood-token splitting."""
    return {
        "style_philosophy": philosophy,
        "textures": {"good": good_tex, "bad": bad_tex, "sweet_spot_keywords": sweet_spot},
        "colours": {"primary": prim_cols, "accent": acc_cols, "avoid": avoid_cols},
        "metals": metals, "stones": stones,
        "patterns": {"recommended": pat_rec, "avoid": pat_avoid},
        "silhouette_keywords": sil,
        "occasion_modifiers": occ,
        "code_leaninto": lean, "code_avoid": avoid_list, "code_consider": consider,
        "opposites": opp
    }

OUTER_ENTRIES = {}

# Jupiter entries (12), amplification, expansion, where you go big
jupiter_entries_raw = {
    "jupiter_aries": make_outer_entry(
        "bold, generous, confidently oversized",
        ["abundance", "command", "generous proportions"],
        ["quality stretch jersey", "rich cotton twill", "performance wool"],
        ["cheap synthetics that pill", "thin see-through knits"],
        [{"name": "royal red", "hex": "#B22222"}],
        [{"name": "warm gold", "hex": "#DAA520"}],
        ["washed-out pastels", "timid neutrals that fade into walls"],
        ["gold", "brass"], ["ruby", "garnet"],
        ["bold scale prints", "large geometric"], ["tiny cramped prints", "miniature patterns"],
        ["generous", "broad-shouldered", "full-cut"],
        {"work": "inspiring leadership presence, think big blazer energy", "intimate": "generous warmth, open necklines, inviting colour", "daily": "confident athleisure, bold graphic tees, statement sneakers"},
        ["Letting one bold hero piece carry the entire outfit rather than diluting impact across many quieter ones", "Choosing generous proportions that command space and make you physically larger in the room", "Prioritising quality over quantity, but always in abundant silhouettes that feel expansive"],
        ["Scrimping on fabric quality to save money. You feel the difference in every cheap fibre", "Pinched or undersized garments that make you look like you are apologising for existing", "Playing small with safe basics when you were built for bold, generous statements"],
        ["Oversized tailoring as a power move. A generous shoulder line says you belong in every room", "a single statement coat that announces your arrival"],
        {"textures": ["cheap polyester", "thin clingy jersey", "stiff scratchy blends"], "colours": ["washed-out beige", "pallid grey"], "silhouettes": ["pinched waist", "cramped shoulders", "undersized everything"], "mood": ["confined", "stingy", "apologetic", "timid"]}
    ),
    "jupiter_taurus": make_outer_entry(
        "abundant, tactile, investment luxury",
        ["richness", "weight", "tactile quality"],
        ["rich cashmere", "heavy silk charmeuse", "double-faced wool"],
        ["scratchy acrylic knits", "paper-thin cotton", "shiny cheap satin"],
        [{"name": "rich emerald", "hex": "#046307"}],
        [{"name": "buttery cream", "hex": "#FFFDD0"}],
        ["garish neons", "cold sterile white"],
        ["yellow gold", "bronze"], ["emerald", "jade"],
        ["lush botanical", "oversized florals"], ["busy cluttered prints", "cheap-looking logos"],
        ["luxurious", "generous", "enveloping"],
        {"work": "quietly expensive, investment suiting, touchable fabrics", "intimate": "sumptuous textures, cashmere wraps, silk against skin", "daily": "elevated basics in premium fabrics, the perfect T-shirt"},
        ["Investing in one extraordinary fabric per season that makes everything else feel ordinary by comparison", "tactile richness you want to run your hands over", "Choosing pieces that age beautifully, gaining character and patina rather than wearing out"],
        ["Disposable fast-fashion pieces that insult your instinct for permanence and tactile quality", "Scratchy or uncomfortable fabrics regardless of how they look. If the texture punishes, the piece fails", "Choosing quantity over quality in any purchase. More is never better when less feels richer"],
        ["a cashmere piece so perfect it becomes a daily uniform", "upgrading basics to the best fabric you can afford"],
        {"textures": ["scratchy acrylic", "stiff polyester", "plasticky faux-leather"], "colours": ["garish neons", "cold clinical white"], "silhouettes": ["tight restrictive cuts", "flimsy unsubstantial shapes"], "mood": ["cheap", "disposable", "deprived", "uncomfortable"]}
    ),
    "jupiter_gemini": make_outer_entry(
        "versatile, layered, generously varied",
        ["variety", "reversibility", "multi-use"],
        ["mixed quality blends", "reversible fabrics", "layering-friendly knits"],
        ["stiff single-purpose fabrics", "heavy non-layerable pieces"],
        [{"name": "bright teal", "hex": "#008080"}],
        [{"name": "lemon yellow", "hex": "#FFF44F"}],
        ["monotone head-to-toe", "single-colour severity"],
        ["mixed metals"], ["citrine", "agate"],
        ["diverse mixed prints", "novelty illustrated prints"], ["single-note repetitive prints", "humourless solids"],
        ["varied", "layered", "convertible"],
        {"work": "chameleon professional, different energy for different meetings", "intimate": "playful mixing, unexpected combinations that spark conversation", "daily": "three-outfit-from-one-outfit thinking, reversible pieces"},
        ["Choosing pieces that work three ways. A jacket, a layer, and a blanket in one garment", "Experimenting with unexpected colour or pattern mixing that sparks dialogue wherever you go", "a wardrobe that tells different stories each day"],
        ["A capsule wardrobe so small it bores you within a week and kills your creative energy", "Uniform dressing that removes all variety from your morning and flattens your range", "Rigid outfit formulas that assume you are the same person every day. You are not"],
        ["a jacket that reverses from work to weekend", "Accessories that completely change an outfit's personality with a single swap of earrings or belt"],
        {"textures": ["stiff single-use suiting", "heavy unmixable fabrics"], "colours": ["monotone severity", "colourless minimalism"], "silhouettes": ["rigid unalterable shapes", "single-silhouette uniform"], "mood": ["monotonous", "limited", "repetitive", "boring"]}
    ),
    "jupiter_cancer": make_outer_entry(
        "nurturing, generously soft, emotionally abundant",
        ["softness", "comfort", "heritage warmth"],
        ["soft quality knits", "heritage wool", "washed linen"],
        ["stiff starched fabrics", "cold synthetics against skin", "scratchy formal blends"],
        [{"name": "buttery cream", "hex": "#FFFDD0"}],
        [{"name": "pearl white", "hex": "#F0EAD6"}],
        ["harsh black", "cold industrial tones"],
        ["silver", "white gold"], ["pearl", "moonstone"],
        ["soft generous florals", "heirloom prints"], ["aggressive graphics", "harsh geometric"],
        ["nurturing", "enveloping", "softly generous"],
        {"work": "warm professional authority, approachable leadership in soft power fabrics", "intimate": "wrapped in softness, cocooned comfort, blanket-weight knits", "daily": "the softest sweater you own, elevated loungewear"},
        ["Choosing pieces that feel like a hug when you put them on. If the fabric does not embrace you, keep looking", "Investing in heirloom-quality knits worth passing down to someone you love in twenty years", "Generous wrapping and draping that creates warmth and visual softness around your body"],
        ["anything that feels cold or punishing against skin", "Stiff formal wear that prevents natural movement and cuts off the warmth your body wants to give", "Harsh synthetic athleisure that prioritises performance over emotional comfort and warmth"],
        ["a heritage-quality throw that doubles as a wrap", "Investing in the softest base layers you can find, because the first thing against your skin sets your mood"],
        {"textures": ["cold scratchy synthetics", "stiff formal gabardine", "rigid uncomfortable denim"], "colours": ["stark cold black", "harsh fluorescents"], "silhouettes": ["tight constricting cuts", "angular aggressive tailoring"], "mood": ["cold", "unwelcoming", "stiff", "emotionally shut-down"]}
    ),
    "jupiter_leo": make_outer_entry(
        "magnificent, regal, generously dramatic",
        ["opulence", "gold", "commanding presence"],
        ["rich velvet", "gold-thread brocade", "silk jacquard"],
        ["cheap glitter fabric", "thin costume-quality velvet", "plasticky metallics"],
        [{"name": "royal gold", "hex": "#FFD700"}],
        [{"name": "warm amber", "hex": "#FFBF00"}],
        ["drab olive", "washed-out institutional grey"],
        ["polished gold", "gilded brass"], ["amber", "topaz"],
        ["regal medallion", "bold crest motifs"], ["generic basic stripes", "plain solids with no presence"],
        ["regal", "magnificent", "theatrically generous"],
        {"work": "boardroom royalty, gold accents, commanding silhouettes, main-character energy", "intimate": "golden warmth, generous draping, candlelit luxury", "daily": "even casual looks need a crown piece, statement sunglasses, a gold chain"},
        ["Including one piece that makes you the main character in every scene, no exceptions", "Treating gold accents as your personal signature, not a seasonal trend that comes and goes", "Showing generosity in fabric volume and silhouette breadth. Generous proportions match your generous spirit"],
        ["Blending into the background on purpose when every cell in your body wants to shine", "dressing down when the occasion calls for presence", "Apologising for taking up visual space in any room. You were designed to fill it"],
        ["A gold-threaded knit that elevates everything it touches, turning basics into something regal", "Statement outerwear as daily armour. A bold coat makes every entrance a production"],
        {"textures": ["cheap costume fabric", "thin dull polyester", "limp jersey"], "colours": ["institutional grey", "faded beige"], "silhouettes": ["shrinking silhouettes", "meagre proportions"], "mood": ["meagre", "dull", "invisible", "ordinary"]}
    ),
    "jupiter_virgo": make_outer_entry(
        "precisely abundant, detail-rich, quality-multiplied",
        ["precision", "finish quality", "tailored detail"],
        ["fine gauge cotton", "precision-knit merino", "brushed cotton poplin"],
        ["sloppy loose-weave fabrics", "pilling synthetics", "wrinkle-prone linen blends"],
        [{"name": "olive green", "hex": "#808000"}],
        [{"name": "wheat", "hex": "#F5DEB3"}],
        ["muddy undefined tones", "stained or faded-looking colours"],
        ["brushed silver"], ["peridot", "sapphire"],
        ["fine pinstripe", "micro-houndstooth"], ["loud oversized prints", "chaotic mixed patterns"],
        ["precise", "quality-finished", "perfectly proportioned"],
        {"work": "impeccable detail, the person whose seams are always straight", "intimate": "understated luxury in finish quality, hidden details", "daily": "perfectly pressed basics, thoughtful accessories, nothing out of place"},
        ["Investing in tailoring and alterations as a standard practice, not a special-occasion luxury", "quality visible in the details, buttons, stitching, lining", "Building a wardrobe where every single garment fits perfectly, with no exceptions or compromises"],
        ["Visible pilling, fraying, or wear on any garment you own. Replace or repair before it shows", "Wrinkled or poorly pressed clothing that suggests you did not care enough to prepare", "Sloppy proportions that look accidental rather than intentional. Close-but-not-quite is worse than wrong"],
        ["Finding a tailor who understands your body and can adjust every key piece to your exact proportions", "one perfectly fitting shirt to template every future purchase"],
        {"textures": ["sloppy loose knits", "wrinkled cheap linen", "pilling acrylic"], "colours": ["muddy undefined tones", "visibly faded fabrics"], "silhouettes": ["baggy unfitted shapes", "sloppy proportions"], "mood": ["careless", "sloppy", "imprecise", "wasteful"]}
    ),
    "jupiter_libra": make_outer_entry(
        "harmonious, gracefully abundant, beautifully balanced",
        ["balance", "coordination", "tonal harmony"],
        ["flowing silk", "fine merino wool", "lightweight cashmere blend"],
        ["stiff scratchy formal fabrics", "heavy awkward blends", "clingy cheap jersey"],
        [{"name": "rose gold tone", "hex": "#B76E79"}],
        [{"name": "champagne", "hex": "#F7E7CE"}],
        ["harsh neons", "aggressive clashing combos"],
        ["rose gold", "copper"], ["rose quartz", "kunzite"],
        ["elegant symmetrical", "tonal damask"], ["aggressive asymmetry", "clashing busy prints"],
        ["graceful", "balanced", "beautifully proportioned"],
        {"work": "effortlessly polished, the colleague everyone asks for style advice", "intimate": "romantic abundance, beautiful textures in candlelit tones", "daily": "coordinated beauty in everyday errands, always put-together"},
        ["beauty as a daily practice, not a special-occasion effort", "Practising tonal dressing with deliberate accent placement, where one colour anchors the whole palette", "Maintaining balanced proportions from top to bottom so the eye travels smoothly through the outfit"],
        ["Jarring combinations that create visual noise and disrupt the harmony your eye naturally seeks", "neglecting the overall harmony for one flashy piece", "Beauty that costs comfort in any form. Elegance should feel effortless, never punishing"],
        ["A tonal palette approach across the week, mapping colours in advance to guarantee daily harmony", "One perfect accessory that elevates everything. A silk scarf or a fine watch completes any composition"],
        {"textures": ["stiff uncomfortable formal wear", "harsh scratchy blends"], "colours": ["jarring neons", "aggressively clashing combinations"], "silhouettes": ["awkwardly proportioned cuts", "top-heavy or bottom-heavy imbalance"], "mood": ["discordant", "ugly", "imbalanced", "graceless"]}
    ),
    "jupiter_scorpio": make_outer_entry(
        "deeply abundant, intensely rich, strategically powerful",
        ["density", "depth", "dark richness"],
        ["rich dark silk", "dense wool crepe", "heavyweight jersey"],
        ["sheer transparent fabrics", "flimsy lightweight synthetics", "cheap shiny satin"],
        [{"name": "deep garnet", "hex": "#733635"}],
        [{"name": "burgundy", "hex": "#800020"}],
        ["bright pastels", "cheerful yellows", "light airy tones"],
        ["blackened gold"], ["garnet", "obsidian"],
        ["dark rich jacquard", "tone-on-tone texture"], ["bright cheerful prints", "lighthearted florals"],
        ["deep", "powerful", "densely constructed"],
        {"work": "power presence without a word spoken, dark authority, strategic luxury", "intimate": "intensity expressed through texture and depth, not exposure", "daily": "dark rich layers that project quiet power even in casual settings"},
        ["Choosing depth over breadth in your wardrobe. Fewer pieces, darker tones, richer textures", "Making strategic investments in power pieces that communicate authority without saying a word", "Building tone-on-tone layering that creates gravitas through depth rather than contrast"],
        ["Surface-level trend-chasing that substitutes novelty for the genuine depth your wardrobe demands", "Lighthearted dressing when the situation demands gravitas. Know when the room needs your depth", "Revealing too much too soon through sheer fabrics or open silhouettes that strip away your mystique"],
        ["a dark coat so well-made it becomes a power signature", "investing in blacks that are truly deep, not faded"],
        {"textures": ["sheer flimsy fabrics", "cheap transparent synthetics"], "colours": ["bright pastels", "cheerful primary colours"], "silhouettes": ["flimsy exposed shapes", "lighthearted casual cuts"], "mood": ["shallow", "frivolous", "surface-level", "exposed"]}
    ),
    "jupiter_sagittarius": make_outer_entry(
        "adventurous, globally generous, travel-ready",
        ["movement", "cultural richness", "artisan quality"],
        ["world textiles", "quality travel-weight wool", "artisan-woven linen"],
        ["delicate dry-clean-only pieces", "restrictive formal suiting", "precious fabrics afraid of weather"],
        [{"name": "deep blue", "hex": "#00008B"}],
        [{"name": "warm ochre", "hex": "#CC7722"}],
        ["timid safe neutrals only", "colourless corporate monotone"],
        ["hammered gold", "brass"], ["turquoise", "lapis lazuli"],
        ["artisan tile-inspired print", "artisan ikat", "tribal-inspired geometry"], ["corporate monotone patterns", "safe repetitive stripes"],
        ["expansive", "worldly", "movement-friendly"],
        {"work": "global professional, cultural confidence, worldly polish, artisan details", "intimate": "travel stories worn on your body, collected pieces with history", "daily": "exploration-ready but polished, adventure meets intention"},
        ["pieces collected from travels or inspired by world cultures", "colour that reflects where you have been or want to go", "fabrics that move as freely as you do"],
        ["Precious clothing that restricts your movement or your spontaneity. If it limits you, it does not belong", "A wardrobe that is afraid of weather, spontaneity, or anything outside a controlled environment", "Domestic-only safe choices that suggest a wardrobe afraid of leaving its own postcode"],
        ["one artisan-made piece per season from a different tradition", "Travel-weight layers that perform across climates without sacrificing style for function"],
        {"textures": ["restrictive formal suiting", "delicate dry-clean-only fabrics"], "colours": ["corporate monotone", "colourless safe neutrals"], "silhouettes": ["stiff restrictive tailoring", "movement-limiting shapes"], "mood": ["parochial", "limited", "narrow", "sheltered"]}
    ),
    "jupiter_capricorn": make_outer_entry(
        "strategically abundant, disciplined, investment-grade",
        ["longevity", "structure", "cost-per-wear"],
        ["finest worsted wool", "quality suiting cloth", "dense cotton drill"],
        ["trendy fast-fashion pieces", "cheap imitation luxury", "synthetic suit blends"],
        [{"name": "dark charcoal", "hex": "#333333"}],
        [{"name": "navy", "hex": "#000080"}],
        ["flashy logos", "trend-driven neons"],
        ["platinum", "silver"], ["garnet", "onyx"],
        ["classic pinstripe", "power check"], ["loud novelty prints", "flashy trend patterns"],
        ["structured", "authoritative", "investment-quality"],
        {"work": "boardroom authority built piece by piece over decades", "intimate": "restrained power, quality you feel, not see, in every fibre", "daily": "structured casual that reads as quietly wealthy"},
        ["build a wardrobe like a portfolio, long-term, appreciating assets", "Applying cost-per-wear thinking to every purchase. A three-hundred-pound coat worn daily costs pennies", "classic shapes in the best fabric you can afford"],
        ["trendy impulse purchases that date within a season", "Flashy logos used as a substitute for genuine quality. The label is not the garment", "Disposable fashion of any kind. If it was designed to be discarded, it was designed for someone else"],
        ["one perfect blazer that will look better in ten years", "a classic watch as the only accessory you need"],
        {"textures": ["trendy fast-fashion polyester", "cheap shiny suit fabric"], "colours": ["flashy trend-driven colours", "logo-heavy prints"], "silhouettes": ["trendy oversized shapes that date quickly", "undisciplined baggy cuts"], "mood": ["wasteful", "undisciplined", "flashy", "impermanent"]}
    ),
    "jupiter_aquarius": make_outer_entry(
        "progressive, innovatively generous, forward-thinking",
        ["innovation", "sustainability", "future materials"],
        ["recycled luxury fibres", "innovative sustainable textiles", "tech-forward knits"],
        ["conventional mass-produced fabrics", "environmentally harmful synthetics"],
        [{"name": "neon teal", "hex": "#00B5AD"}],
        [{"name": "electric blue", "hex": "#7DF9FF"}],
        ["conventional safe beige", "establishment navy-and-grey"],
        ["titanium"], ["amethyst", "labradorite"],
        ["futuristic geometric", "digital-inspired motifs"], ["heritage-for-heritage's-sake patterns", "stuffy traditional checks"],
        ["innovative", "progressive", "forward-thinking"],
        {"work": "the futurist in the room, innovation visible in material choices", "intimate": "unusual materials, unexpected luxury, conversation-starting pieces", "daily": "tech-forward athleisure, sustainable innovation as daily uniform"},
        ["invest in materials from the future, recycled, innovative, unexpected", "let your wardrobe reflect the world you want", "Showing generosity toward the planet through conscious material choices in every purchase"],
        ["Conventional luxury that ignores its environmental footprint. Status without ethics is outdated", "Backward-looking accumulation of dead stock that fills a wardrobe without serving a purpose", "Conformist dressing that wastes the creative opportunity every outfit choice represents"],
        ["one truly innovative piece that starts conversations about fashion's future", "Sustainable luxury as the ultimate expression of abundance. Generosity starts with the planet"],
        {"textures": ["conventional mass-produced synthetics", "throwaway fast-fashion fabrics"], "colours": ["establishment beige", "conformist grey"], "silhouettes": ["dated conventional shapes", "predictable safe cuts"], "mood": ["backward", "hoarding", "conformist", "stagnant"]}
    ),
    "jupiter_pisces": make_outer_entry(
        "spiritually abundant, flowing, boundlessly compassionate",
        ["fluidity", "softness", "emotional openness"],
        ["flowing luxury silk", "soft organic cotton", "cloud-weight cashmere"],
        ["rigid structured suiting", "harsh synthetic blends", "stiff formal fabrics"],
        [{"name": "ocean blue", "hex": "#006994"}],
        [{"name": "pale violet", "hex": "#DDA0DD"}],
        ["harsh industrial black", "aggressive red"],
        ["silver", "iridescent"], ["amethyst", "aquamarine"],
        ["oceanic flow", "watercolour print", "impressionist motifs"], ["rigid geometric", "harsh angular graphics"],
        ["flowing", "boundless", "softly expansive"],
        {"work": "compassionate presence, soft authority that listens before it speaks", "intimate": "ethereal abundance, floating fabrics, dream-state dressing", "daily": "flowing layers that move like water, effortlessly spiritual"},
        ["Choosing fabrics that flow rather than constrict, letting your body move with its natural rhythm", "colour that feels like an emotion, not a decision", "generosity of spirit visible in softness and openness"],
        ["Rigid structured dressing that blocks emotional expression and prevents your compassion from showing through", "harsh fabrics that feel like armour against the world", "Material obsession that prioritises status over soulful, emotionally honest dressing"],
        ["one silk piece so fluid it feels like wearing water", "Choosing colour by feeling rather than matching. If it resonates emotionally, it coordinates"],
        {"textures": ["rigid structured suiting", "stiff formal gabardine"], "colours": ["harsh black", "aggressive industrial tones"], "silhouettes": ["tight constricting shapes", "rigid angular tailoring"], "mood": ["materialistic", "rigid", "ungenerous", "closed-off"]}
    ),
}
OUTER_ENTRIES.update(jupiter_entries_raw)

# Mercury entries (12), communication, how you narrate your style
mercury_entries_raw = {
    "mercury_aries": make_outer_entry(
        "decisive, clear, sharp-read",
        ["clarity", "decisiveness", "instant read"],
        ["crisp poplin shirt", "structured cotton twill", "performance jersey"],
        ["fussy multi-layered chiffon", "delicate fabrics requiring constant adjustment"],
        [{"name": "clear red", "hex": "#CC0000"}],
        [{"name": "warm white", "hex": "#FAF0E6"}],
        ["wishy-washy pale tones", "indecisive mixed messages in colour"],
        ["rose gold"], ["carnelian"],
        ["graphic type", "bold slogan prints"], ["fussy floral", "ambiguous abstract"],
        ["sharp", "decisive", "quick-read"],
        {"work": "direct and clear, outfit reads instantly as authority", "intimate": "straightforward confidence, no-games dressing", "daily": "grab-and-go clarity, pieces that require zero deliberation"},
        ["let one strong piece speak instead of many whispering", "Making decisive colour choices over safe hedge-betting. Pick the bold shade and commit fully", "Choosing clarity over complexity in every combination. If the message is not instant, simplify"],
        ["Mixed-message outfits that confuse your own story before anyone else has a chance to read it", "Hedging with too many safe neutrals when a single strong colour would say it all", "fussing over options when the first instinct was right"],
        ["a signature colour that becomes your verbal shorthand", "Pre-decided outfit formulas that give you zero-decision mornings and maximum momentum"],
        {"textures": ["fussy delicate chiffon", "indecisive mixed-texture chaos"], "colours": ["wishy-washy neutrals", "indecisive grey-beige"], "silhouettes": ["overly complicated layering", "ambiguous shapeless forms"], "mood": ["hesitant", "unclear", "muddled", "overthinking"]}
    ),
    "mercury_taurus": make_outer_entry(
        "deliberate, substantial, slowly considered",
        ["substance", "deliberation", "patina"],
        ["heavy cotton oxford", "dense linen blend", "substantial ponte"],
        ["paper-thin disposable fabrics", "flimsy trend pieces that fall apart"],
        [{"name": "muted olive", "hex": "#6B6B3D"}],
        [{"name": "sophisticated caramel", "hex": "#A0722D"}],
        ["cheap-looking bright colours", "anything that reads as rushed or careless"],
        ["warm bronze"], ["emerald"],
        ["slub-weave cotton solid", "woven geometric"], ["flashy novelty prints", "gimmicky fast-fashion graphics"],
        ["substantial", "grounded", "deliberately chosen"],
        {"work": "reliably polished, the person whose outfit always looks considered", "intimate": "tactile quality that invites touch, slow luxury", "daily": "perfectly broken-in favourites that improve with wear"},
        ["pieces that look better with age and use", "Practising deliberate slow wardrobe building, where each addition is considered for weeks before committing", "fabrics with visible quality even from across the room"],
        ["Impulsive trend-chasing that creates regret the moment the novelty fades and the quality disappoints", "Replacing quality pieces with cheaper versions when the original wore out. Upgrade, never downgrade", "Rushing wardrobe decisions under pressure or time constraints. Your best purchases happen slowly"],
        ["a leather bag that patinas beautifully over years", "Heritage denim worn to personal perfection over years, where every fade tells your specific story"],
        {"textures": ["paper-thin disposables", "flimsy trendy synthetics"], "colours": ["garish impulse-buy colours", "cheap-looking brights"], "silhouettes": ["flimsy unsubstantial shapes", "trend-driven extremes"], "mood": ["rushed", "careless", "cheap", "impulsive"]}
    ),
    "mercury_gemini": make_outer_entry(
        "quicksilver, versatile, endlessly remixable",
        ["variety", "remixability", "surprise"],
        ["mixed blends", "lightweight layering knits", "reversible jerseys"],
        ["heavy single-note fabrics", "stiff non-layerable pieces"],
        [{"name": "lemon", "hex": "#FFF44F"}],
        [{"name": "bright teal", "hex": "#008080"}],
        ["boring monotone", "single-colour severity"],
        ["mixed metals"], ["citrine", "agate"],
        ["mixed-scale print clash", "conversational graphics", "dual motifs"], ["humourless solids", "corporate monotony"],
        ["varied", "quick-change", "layered"],
        {"work": "the person with a different brilliant idea every meeting, style to match", "intimate": "playful wit, unexpected details that reward closer looking", "daily": "three different people this week, all authentically you"},
        ["Choosing versatile pieces that remix endlessly, creating new combinations from familiar elements each morning", "Including surprise elements that spark dialogue and give people a reason to engage with your look", "Using colour and pattern as deliberate conversation starters that invite curiosity and connection"],
        ["A single rigid uniform approach that kills the creative variety your mind requires to stay sharp", "style ruts that last longer than a week", "outfit repetition out of laziness rather than intention"],
        ["Trying one pattern-mixing experiment per week to keep your visual vocabulary expanding and alive", "Using accessories as quick personality-changers. A swapped earring or belt transforms yesterday's outfit entirely"],
        {"textures": ["heavy unmixable fabrics", "rigid single-use suiting"], "colours": ["dreary monotone", "colourless boredom"], "silhouettes": ["stiff uniform shapes", "unchangeable silhouettes"], "mood": ["boring", "static", "repetitive", "predictable"]}
    ),
    "mercury_cancer": make_outer_entry(
        "intuitive, soft-signal, emotionally literate",
        ["intuition", "softness", "emotional read"],
        ["soft washed cotton", "brushed silk", "lived-in jersey"],
        ["stiff brand-new fabrics", "scratchy unwashed denim", "cold clinical synthetics"],
        [{"name": "silver grey", "hex": "#C0C0C0"}],
        [{"name": "pale blue", "hex": "#AEC6CF"}],
        ["aggressive neons", "cold stark white"],
        ["silver"], ["moonstone", "pearl"],
        ["soft watercolour", "nature-inspired motifs"], ["aggressive graphic prints", "confrontational slogans"],
        ["soft", "intuitive", "emotionally literate"],
        {"work": "emotionally intelligent presence, approachable authority in soft tones", "intimate": "intuitively chosen pieces that feel like a second skin", "daily": "comfort-first dressing that still communicates care and attention"},
        ["trust your gut when a piece 'feels right'", "Wearing soft colours that put others at ease and signal emotional availability before you speak", "Treating clothing as emotional communication where every choice telegraphs your current state to the room"],
        ["ignoring how a piece makes you feel because it looks 'right'", "Cold formal dressing in warm personal settings where your clothes should invite connection, not create distance", "Dressing to impress rather than to connect. Your strength is warmth, not performance"],
        ["a signature soft piece that people associate with your warmth", "Mood-responsive dressing as an emotional practice where you check in with yourself before opening the wardrobe"],
        {"textures": ["stiff unworn formal fabrics", "cold clinical synthetics"], "colours": ["aggressive neons", "confrontational red"], "silhouettes": ["sharp angular aggressive cuts", "stiff padded shoulders"], "mood": ["cold", "insensitive", "detached", "tone-deaf"]}
    ),
    "mercury_leo": make_outer_entry(
        "expressive, declarative, boldly stated",
        ["boldness", "presence", "declaration"],
        ["rich textured fabrics", "bold-weight silk", "theatrical wool"],
        ["shy retiring fabrics", "mousy lightweight blends", "beige corporate stretch"],
        [{"name": "golden yellow", "hex": "#FFD700"}],
        [{"name": "warm amber", "hex": "#FFBF00"}],
        ["invisible greige", "wallflower neutrals"],
        ["gold"], ["sunstone", "citrine"],
        ["bold typography", "lion-hearted graphics", "oversized bold-scale abstract"], ["tiny timid patterns", "barely-there prints"],
        ["expressive", "bold", "declarative"],
        {"work": "confidence that enters the room before you do", "intimate": "warmth and generosity expressed through golden tones", "daily": "main-character energy even at the grocery store"},
        ["Leading with one statement piece that announces your presence before anyone registers your face", "Wearing bold colour as genuine self-expression rather than costume. The warmth should come from within", "prints that tell your story loudly and proudly"],
        ["Dressing to disappear when everything about your energy demands visibility and warm attention", "Muting yourself for other people's comfort when your natural volume is a gift to every room", "Choosing beige when your soul says gold. Your intuition knows which metal matches your fire"],
        ["a signature bold print that becomes your calling card", "Gold accessories worn as a daily declaration of your creative authority and generous warmth"],
        {"textures": ["mousy thin fabrics", "shy retiring blends"], "colours": ["invisible beige", "disappearing grey"], "silhouettes": ["shrinking minimalist shapes", "self-effacing cuts"], "mood": ["timid", "muted", "invisible", "apologetic"]}
    ),
    "mercury_virgo": make_outer_entry(
        "precise, editorial, immaculately finished",
        ["precision", "finish", "alignment"],
        ["pressed cotton broadcloth", "fine-gauge merino", "precision-knit jersey"],
        ["wrinkle-prone cheap linen", "pilling blend knits", "sloppy oversized sweaters"],
        [{"name": "sand", "hex": "#C2B280"}],
        [{"name": "soft sage", "hex": "#9CAF88"}],
        ["sloppy tie-dye", "chaotic multi-colour clash"],
        ["brushed silver"], ["peridot", "sapphire"],
        ["micro-houndstooth", "fine pinstripe", "precise grid"], ["loud oversized prints", "sloppy abstract splatter"],
        ["precise", "clean-lined", "perfectly proportioned"],
        {"work": "the person whose outfit is always immaculate, effortless precision", "intimate": "quality visible in the smallest detail, rewarding close attention", "daily": "crisp even in casual, pressed jeans, clean sneakers, aligned seams"},
        ["Prioritising perfect fit over perfect fashion. The most stylish garment is the one that fits your body exactly", "Making visible stitch quality and finish your primary standard before considering colour or trend", "Treating alignment and proportion as non-negotiable personal standards that define your visual signature"],
        ["Visible wear, pilling, or fraying on any garment you wear in public. Maintenance is not optional", "Wrinkled clothing that signals carelessness to anyone observant enough to notice. You always notice", "Proportions that are close but not quite right. Almost perfect is worse than deliberately imperfect"],
        ["A dedicated pressing routine as a style ritual that ensures every garment meets your standard daily", "Strategic fit alterations on every key piece so nothing in rotation is merely approximate"],
        {"textures": ["wrinkled cheap linen", "pilling synthetic knits"], "colours": ["muddy undefined colours", "stained-looking tones"], "silhouettes": ["baggy approximate fits", "sloppy proportions"], "mood": ["sloppy", "imprecise", "disordered", "careless"]}
    ),
    "mercury_libra": make_outer_entry(
        "diplomatic, tonally coordinated, harmoniously composed",
        ["balance", "coordination", "harmony"],
        ["silk-wool blend", "fine gauge knit", "draping jersey"],
        ["stiff scratchy formal blends", "confrontational heavy fabrics"],
        [{"name": "pastel pink", "hex": "#FFD1DC"}],
        [{"name": "soft lavender", "hex": "#E6E6FA"}],
        ["confrontational red", "aggressive black-only severity"],
        ["rose gold"], ["rose quartz"],
        ["balanced symmetrical design", "tonal stripe"], ["aggressive asymmetry", "clashing anarchic prints"],
        ["balanced", "graceful", "harmoniously composed"],
        {"work": "diplomatically polished, makes everyone feel at ease", "intimate": "romantic balance, soft coordination, considered pairings", "daily": "effortlessly coordinated, nothing jarring, everything relates"},
        ["Practising tonal coordination as a daily discipline where every colour relates to every other colour", "Building balanced proportions that flatter universally, where the eye moves smoothly from top to bottom", "Cultivating colour relationships that create visual harmony and make every outfit feel composed"],
        ["Jarring mismatched combinations that create visual discord and disrupt the harmony you naturally seek", "Single pieces that overpower the whole outfit instead of serving the composition as a balanced element", "Confrontational style choices in harmonious settings where your role is to create beauty, not tension"],
        ["A colour-wheel approach to weekly outfit planning that maps harmony across all five working days", "One signature balanced combination that becomes your template for how proportion and colour should work"],
        {"textures": ["stiff confrontational fabrics", "harsh scratchy blends"], "colours": ["jarring aggressive tones", "confrontational all-black"], "silhouettes": ["aggressively asymmetric cuts", "top-heavy imbalanced shapes"], "mood": ["jarring", "confrontational", "imbalanced", "graceless"]}
    ),
    "mercury_scorpio": make_outer_entry(
        "strategic, concealed, layered with subtext",
        ["concealment", "strategy", "hidden depth"],
        ["dense structured jersey", "dark matte cotton", "heavyweight silk"],
        ["sheer transparent fabrics", "revealing lightweight synthetics"],
        [{"name": "deep burgundy", "hex": "#800020"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["loud obvious brights", "transparent-intention pastels"],
        ["gunmetal"], ["obsidian"],
        ["concealed tone-on-tone jacquard", "tone-on-tone jacquard"], ["loud obvious prints", "billboard-scale graphics"],
        ["controlled", "strategic", "layered meaning"],
        {"work": "the person who reveals nothing accidentally, strategic opacity", "intimate": "depth through concealment, allure through what stays hidden", "daily": "dark tonal layers that communicate control and intent"},
        ["Practising strategic concealment over obvious display. What you withhold visually becomes your power", "Investing in hidden quality details that reward intimacy. A beautiful lining or a monogram says everything", "Using dark tonal dressing as information control, revealing your depth only to those who look closely"],
        ["Transparent obvious dressing that reveals everything at first glance, leaving nothing for the second look", "Loud prints that broadcast your intentions instead of suggesting them. Subtlety is your stronger language", "Shallow surface-level styling that tells the whole story in one glance and leaves no room for mystery"],
        ["Tone-on-tone dark layering as a deliberate communication strategy that rewards close attention over quick reading", "Hidden details like a quality lining or an interior monogram that only someone close would discover"],
        {"textures": ["sheer obvious fabrics", "transparent lightweight synthetics"], "colours": ["loud obvious primary colours", "attention-demanding brights"], "silhouettes": ["revealing body-conscious cuts", "nothing-to-hide simplicity"], "mood": ["obvious", "transparent", "shallow", "loud"]}
    ),
    "mercury_sagittarius": make_outer_entry(
        "expansive, globally informed, story-rich",
        ["provenance", "cultural breadth", "travel-weight"],
        ["travel-ready wool blend", "breathable cotton", "crease-resistant linen"],
        ["delicate hand-wash-only fabrics", "restrictive dry-clean suiting"],
        [{"name": "deep blue", "hex": "#00008B"}],
        [{"name": "burnt sienna", "hex": "#E97451"}],
        ["timid office grey", "small-world beige"],
        ["brass"], ["turquoise"],
        ["global-inspired motifs", "artisan print"], ["corporate safe stripes", "parochial check"],
        ["expansive", "open", "globally informed"],
        {"work": "the person whose outfit sparks 'where did you get that?'", "intimate": "pieces that carry stories, collected, discovered, meaningful", "daily": "world-citizen dressing, cultural confidence in every combination"},
        ["pieces with provenance, where they came from matters", "Wearing colour and pattern drawn from different cultural traditions with genuine knowledge and respect", "Choosing travel-weight fabrics that perform everywhere, from market to meeting to mountain without compromise"],
        ["a wardrobe that has never left the high street", "dressing as if the world is smaller than it is", "Playing it safe with culturally neutral everything when your worldly experience deserves a wider visual vocabulary"],
        ["one collected piece per trip that joins the rotation", "Globally-sourced accessories as conversation pieces that carry stories from the places you have visited"],
        {"textures": ["restrictive formal-only fabrics", "fragile non-travel-worthy pieces"], "colours": ["timid corporate grey", "small-world beige"], "silhouettes": ["stiff office-only silhouettes", "restricted movement-limiting cuts"], "mood": ["narrow", "parochial", "sheltered", "incurious"]}
    ),
    "mercury_capricorn": make_outer_entry(
        "authoritative, precisely tailored, professionally credentialed",
        ["authority", "precision", "maintenance"],
        ["fine worsted suiting", "pressed cotton broadcloth", "quality gabardine"],
        ["wrinkled casual linen", "sloppy oversized knits", "juvenile graphic tees"],
        [{"name": "deep charcoal", "hex": "#333333"}],
        [{"name": "cool navy", "hex": "#003153"}],
        ["juvenile brights", "unprofessional neons"],
        ["silver"], ["garnet"],
        ["classic regimental stripe", "subtle power check"], ["novelty prints", "juvenile graphics"],
        ["structured", "professional", "precisely tailored"],
        {"work": "the person whose outfit says 'I am ready' before they speak", "intimate": "restrained confidence, precision even in casual moments", "daily": "structured casual that never reads as sloppy"},
        ["dress for the position you want, then exceed it", "precision in fit as a form of professional respect", "Maintaining classic pieces to impeccable standards where the care you show your clothes reflects professional respect"],
        ["casual Friday as an excuse for sloppy dressing", "Juvenile touches in professional settings that undermine the credibility you have carefully built", "Trendy pieces that undermine your credibility by suggesting you follow fashion rather than leading with substance"],
        ["one perfectly fitted dark suit as the foundation of everything", "a pressing and maintenance ritual as professional practice"],
        {"textures": ["wrinkled casual linen", "sloppy oversized knits"], "colours": ["juvenile bright colours", "unprofessional neons"], "silhouettes": ["slouchy informal shapes", "undersized juvenile cuts"], "mood": ["casual", "unprofessional", "immature", "undisciplined"]}
    ),
    "mercury_aquarius": make_outer_entry(
        "progressive, unconventional, forward-signalling",
        ["innovation", "forward-thinking", "unconventionality"],
        ["tech-forward knits", "innovative recycled blends", "smart textiles"],
        ["conventional cotton basics", "backwards-looking traditional weaves"],
        [{"name": "electric blue", "hex": "#7DF9FF"}],
        [{"name": "neon teal", "hex": "#00B5AD"}],
        ["establishment navy", "convention-confirming beige"],
        ["titanium"], ["labradorite"],
        ["digital motifs", "circuit-inspired pattern", "generative geometry"], ["heritage-for-heritage's-sake tartans", "conventional florals"],
        ["unconventional", "forward-looking", "progressive"],
        {"work": "the innovator whose outfit signals new thinking before the pitch begins", "intimate": "unusual materials and unexpected details that provoke curiosity", "daily": "future-citizen dressing, tech, sustainability, originality"},
        ["materials that did not exist five years ago", "style choices that require explaining, that is the point", "Choosing progressive aesthetics over backward-looking convention, because your ideas deserve a forward-facing wardrobe"],
        ["Dressing conventionally just to fit in, when your natural innovation is your greatest professional asset", "Choosing comfort over innovation when a small step into the unfamiliar could transform your whole look", "Heritage pieces worn ironically rather than authentically. If you cannot wear it straight, do not wear it at all"],
        ["Adding one genuinely innovative material per season that nobody in your circle has encountered before", "Accessories that signal forward-thinking values. A smart ring or a recycled-material bag says where you are headed"],
        {"textures": ["conventional cotton basics", "backwards-looking traditional fabrics"], "colours": ["establishment navy-and-grey", "convention-conforming safe tones"], "silhouettes": ["dated conventional cuts", "predictable safe shapes"], "mood": ["conventional", "backward", "stale", "conformist"]}
    ),
    "mercury_pisces": make_outer_entry(
        "poetic, flowing, metaphorically soft",
        ["fluidity", "poetry", "emotional softness"],
        ["soft washed jersey", "flowing silk", "watercolour-print chiffon"],
        ["stiff corporate suiting", "rigid structured denim", "Harsh synthetic athleisure that prioritises performance over emotional comfort and warmth"],
        [{"name": "sea green", "hex": "#2E8B57"}],
        [{"name": "lavender", "hex": "#E6E6FA"}],
        ["harsh primary colours", "blunt corporate black"],
        ["silver"], ["amethyst", "aquamarine"],
        ["watercolour motifs", "impressionist print", "oceanic flow"], ["stark geometric", "aggressive graphic"],
        ["flowing", "poetic", "softly layered"],
        {"work": "empathetic presence, style that listens and absorbs the room", "intimate": "dreamy layers, flowing fabrics, candlelit softness", "daily": "poetry-in-motion dressing, soft, flowing, quietly beautiful"},
        ["Choosing fabrics that move like they are breathing, responding to your body with fluid, living rhythm", "Wearing colour that dissolves rather than declares, creating atmosphere instead of making announcements", "Using soft layering as emotional expression where each added piece adjusts the mood of the whole outfit"],
        ["Blunt literal dressing with no subtext or emotional nuance. Your clothes should whisper, not shout", "aggressive structured shapes that overpower your quiet nature", "Harsh colours that shout when your natural register is a whisper. Match the volume to your soul"],
        ["one silk scarf that changes the emotional temperature of any outfit", "Watercolour prints as personal poetry worn on the body, where every brushstroke mirrors your inner world"],
        {"textures": ["stiff corporate gabardine", "rigid harsh denim"], "colours": ["blunt primary colours", "harsh corporate black"], "silhouettes": ["rigid boxy shapes", "aggressive angular tailoring"], "mood": ["blunt", "literal", "unfeeling", "unpoetic"]}
    ),
}
OUTER_ENTRIES.update(mercury_entries_raw)

# Uranus entries (12), disruption, where you break rules and innovate
uranus_entries_raw = {
    "uranus_aries": make_outer_entry(
        "radical, experimental, deliberately disruptive",
        ["asymmetry", "disruption", "newness"],
        ["tech stretch jersey", "bonded performance knit", "laser-cut neoprene"],
        ["conventional cotton basics", "heritage tweeds", "safe department-store fabrics"],
        [{"name": "electric red", "hex": "#FF003C"}],
        [{"name": "stark white", "hex": "#FFFFFF"}],
        ["safe navy-and-grey", "predictable earth tones"],
        ["titanium"], ["bloodstone"],
        ["disruptive graphic", "deconstructed logo"], ["conventional classic stripes", "safe heritage check"],
        ["sharp", "experimental", "asymmetric"],
        {"work": "the disruptor, your outfit is the pitch deck", "intimate": "electric energy, unexpected materials, tactile surprise", "daily": "sneaker culture meets runway thinking, nothing expected"},
        ["Breaking one convention per outfit deliberately. An unexpected proportion or a clashing material keeps the edge alive", "wear something nobody in the room has seen before", "Choosing silhouettes from the future rather than the archive. If it already existed, it is not radical enough"],
        ["Safe predictable corporate dressing that erases every trace of the originality you were built to express", "Following last season's trend when you should be setting the standard for the next one", "Buying what everyone else is wearing when your entire identity depends on being impossible to categorise"],
        ["one asymmetric or deconstructed piece as a daily signature", "sneakers that are art objects rather than footwear"],
        {"textures": ["conventional cotton", "safe heritage tweed", "predictable department-store fabrics"], "colours": ["safe corporate blue", "predictable earth tones"], "silhouettes": ["conventional tailored shapes", "predictable proportions"], "mood": ["safe", "predictable", "timid", "conventional"]}
    ),
    "uranus_taurus": make_outer_entry(
        "sustainably revolutionary, innovatively grounded",
        ["sustainable innovation", "ethical quality", "new materials"],
        ["sustainable luxury fibre", "innovative plant-based leather", "recycled cashmere"],
        ["mass-produced virgin synthetics", "environmentally harmful fabrics", "conventional fast-fashion cotton"],
        [{"name": "copper tone", "hex": "#B87333"}],
        [{"name": "rich emerald", "hex": "#046307"}],
        ["conventional luxury brown", "traditional-for-tradition's-sake tones"],
        ["recycled gold"], ["moldavite"],
        ["organic abstract", "nature reimagined digitally"], ["conventional heritage patterns", "traditional-only florals"],
        ["grounded innovation", "sustainably constructed"],
        {"work": "the one rewriting what 'quality' means, sustainable authority", "intimate": "innovative natural textures, plant-based luxury against skin", "daily": "conscious luxury as daily practice, new materials, old values"},
        ["Seeking materials that challenge what luxury means, proving that sustainability and quality can be the same thing", "Choosing sustainable innovation over conventional status symbols. The future of luxury is ethical, not exclusive", "quality measured by impact, not just thread count"],
        ["Conventional luxury that ignores its environmental cost, treating quality as separate from responsibility", "Disposable pieces regardless of price point. Fast fashion at designer prices is still fast fashion", "Greenwashing aesthetics without substance behind them. A bamboo label on polyester is not innovation"],
        ["one genuinely innovative sustainable luxury piece per season", "Plant-based leather that outperforms the original in durability, texture, and environmental impact"],
        {"textures": ["mass-produced virgin polyester", "conventional fast-fashion fabrics"], "colours": ["conventional luxury brown", "traditional-only tones"], "silhouettes": ["conventional luxury shapes", "traditional status-symbol cuts"], "mood": ["disposable", "conventional", "wasteful", "complacent"]}
    ),
    "uranus_gemini": make_outer_entry(
        "electrically versatile, modular, multi-form",
        ["modularity", "reconfiguration", "adaptability"],
        ["adaptive tech blends", "shape-memory fabric", "reversible smart knit"],
        ["static single-purpose fabrics", "conventional fixed-form pieces"],
        [{"name": "neon yellow", "hex": "#CCFF00"}],
        [{"name": "electric blue", "hex": "#7DF9FF"}],
        ["monotone convention", "single-colour corporate severity"],
        ["mixed innovative metals"], ["labradorite"],
        ["glitch-inspired", "digital noise", "generative pattern"], ["conventional repeating prints", "static heritage patterns"],
        ["rapid-change", "multi-form", "modular"],
        {"work": "the multi-format communicator, outfit transforms between meetings", "intimate": "surprise reveals, hidden reversible details, multi-mode pieces", "daily": "modular dressing, zip, fold, reverse, transform"},
        ["Investing in modular pieces that reconfigure into entirely different garments with a zip, fold, or snap", "Looking for unexpected tech integration in everyday clothing. A heated liner or a charging pocket changes everything", "pieces that look different depending on how you wear them"],
        ["Fixed-form single-use outfits that can only be worn one way and in one context. Too rigid for you", "A static wardrobe that never recombines into new formations. If it cannot transform, it stagnates", "Predictable daily repetition that wastes the creative potential every morning outfit choice represents"],
        ["a jacket that becomes a vest becomes a bag", "Colour-changing or responsive materials that shift with temperature, light, or movement as a daily experiment"],
        {"textures": ["static conventional cotton", "fixed-form traditional fabrics"], "colours": ["monotone corporate palette", "predictable safe neutrals"], "silhouettes": ["static unalterable shapes", "conventional single-form pieces"], "mood": ["static", "repetitive", "predictable", "fixed"]}
    ),
    "uranus_cancer": make_outer_entry(
        "radically comfortable, innovatively soft",
        ["comfort tech", "temperature regulation", "soft innovation"],
        ["innovative soft-tech jersey", "temperature-regulating knit", "next-gen comfort fibre"],
        ["old-fashioned stiff formal wear", "cold traditional suiting", "uncomfortable heritage pieces"],
        [{"name": "iridescent white", "hex": "#F0F8FF"}],
        [{"name": "pale blue", "hex": "#AEC6CF"}],
        ["cold industrial tones", "harsh institutional colours"],
        ["opal-set silver"], ["rainbow moonstone"],
        ["modern soft abstract", "new-wave organic"], ["stiff traditional patterns", "cold geometric grids"],
        ["protective innovation", "soft-tech cocooning"],
        {"work": "caring authority through innovative comfort, the soft layer that still looks in charge", "intimate": "temperature-responsive softness, cocooning fabrics, close-to-skin comfort", "daily": "comfort-led dressing with smarter fabrics and clean lines"},
        ["Choosing comfort technology over nostalgia, because the future of softness is smarter than the past", "looking for fabrics that regulate temperature before they impress on a hanger", "building softness into the outfit without losing shape"],
        ["Uncomfortable clothing worn for tradition's sake when comfort technology can deliver both style and wellbeing", "cold stiff formal pieces that ignore the body", "Convention that prioritises appearance over physical wellbeing, ignoring what your body actually needs"],
        ["Temperature-regulating base layers for long days that keep your body comfortable without adding visible bulk", "comfort tech that looks polished enough to leave the house in"],
        {"textures": ["stiff formal tradition", "uncomfortable heritage fabrics"], "colours": ["cold institutional grey", "harsh clinical white"], "silhouettes": ["rigid formal shapes", "uncomfortable conventional cuts"], "mood": ["cold", "conventional", "uncomfortable", "detached"]}
    ),
    "uranus_leo": make_outer_entry(
        "electrically visible, radically expressive",
        ["reflectivity", "light-catching", "visibility"],
        ["metallic tech fabric", "reflective material", "LED-embeddable textile"],
        ["shy matte basics", "conventional cotton tees", "fading-into-background blends"],
        [{"name": "electric gold", "hex": "#FFD700"}],
        [{"name": "electric red", "hex": "#FF003C"}],
        ["invisible beige", "conventional corporate tones"],
        ["gilded titanium"], ["sunstone"],
        ["bold futuristic", "reflective graphic", "tech-enhanced print"], ["conventional heritage patterns", "invisible subtle prints"],
        ["dramatically innovative", "electrically visible"],
        {"work": "the creative director who is the brand, innovative authority made visible", "intimate": "electric warmth, metallic glow, radiant unconventionality", "daily": "main-character energy dialled to eleven, reflective, bright, undeniable"},
        ["Using reflective or metallic pieces as daily drama that catches every light source in the room", "be the brightest, strangest, most original thing in any room", "Treating tech-enhanced visibility as a creative statement. LED-embedded or reflective fabric says you are from the future"],
        ["Dimming yourself to fit in when your entire creative identity depends on maximum visibility and light", "Conventional safe dressing in creative settings where bold innovation is the actual dress code", "Muting your volume for someone else's comfort when your radiance is the gift you bring to every space"],
        ["one genuinely reflective or light-catching piece as daily armour", "metallic accessories that announce you from a distance"],
        {"textures": ["shy matte cotton", "invisible basic jersey"], "colours": ["invisible beige", "conformist grey"], "silhouettes": ["shrinking conventional shapes", "self-minimising cuts"], "mood": ["dim", "conformist", "muted", "invisible"]}
    ),
    "uranus_virgo": make_outer_entry(
        "precisely innovative, functionally revolutionary",
        ["performance fabric", "nano-treatment", "functional precision"],
        ["precision-engineered performance fabric", "smart textile with data capability", "nano-treated cotton"],
        ["imprecise loosely-woven blends", "sloppy unfinished hems", "low-tech basics"],
        [{"name": "mineral grey", "hex": "#928E85"}],
        [{"name": "stark white", "hex": "#FFFFFF"}],
        ["sloppy earth tones", "muddy imprecise colours"],
        ["brushed titanium"], ["sapphire"],
        ["precision digital grid", "circuit-pattern detail"], ["sloppy abstract", "imprecise organic splatter"],
        ["precisely innovative", "functionally perfect"],
        {"work": "the systems thinker, precision visible in every innovative seam", "intimate": "hidden tech, functional beauty, innovation in the details", "daily": "optimised dressing, every piece performs, nothing is decorative-only"},
        ["Choosing performance fabrics that improve on their natural predecessors in every measurable dimension", "Embedding functional innovation in every detail, from stain-resistant finishes to wrinkle-recovery construction", "Making precision engineering visible at seam level, where the innovation is as precise as your standards"],
        ["Sloppy creative dressing that sacrifices function for aesthetics. True innovation perfects both simultaneously", "Decorative-only pieces with no performance value. Every element should work as hard as it looks", "Imprecise construction marketed as relaxed when genuine relaxation comes from fabrics engineered to perform flawlessly"],
        ["Nano-treated fabrics that repel stains and wrinkles, keeping your standard of precision effortless all day", "Precision-fit pieces engineered for your exact measurements, where technology replaces guesswork in every garment"],
        {"textures": ["sloppy loose weaves", "imprecise cheap construction"], "colours": ["muddy undefined tones", "sloppy earth-tones"], "silhouettes": ["baggy approximate fits", "sloppy unstructured shapes"], "mood": ["sloppy", "inefficient", "imprecise", "outdated"]}
    ),
    "uranus_libra": make_outer_entry(
        "radically beautiful, innovatively graceful",
        ["iridescence", "holographic finish", "new-generation beauty"],
        ["innovative silk alternative", "tech chiffon", "holographic-finish fabric"],
        ["conventional silk", "traditional formal fabrics", "heritage-for-heritage's-sake materials"],
        [{"name": "holographic pink", "hex": "#FF69B4"}],
        [{"name": "electric violet", "hex": "#8B00FF"}],
        ["conventional pastel pink", "safe traditional rose"],
        ["innovative rose gold"], ["kunzite"],
        ["symmetrical tech motifs", "algorithmically generated pattern"], ["conventional floral", "traditional symmetry"],
        ["radically balanced", "innovatively graceful"],
        {"work": "innovative beauty with clean polish, the look that makes people ask where it is from", "intimate": "iridescent finishes, fluid movement, light caught at close range", "daily": "future-leaning beauty through colour, sheen, and smart fabrication"},
        ["looking for beauty in materials with a new finish or unusual sheen", "using holographic or iridescent pieces as accents rather than costume", "keeping the silhouette elegant even when the fabric does something unexpected"],
        ["Conventional beauty standards in fashion that refuse to evolve or imagine what beauty could become next", "Traditional elegance that refuses innovation, treating the past as the only template for grace", "safe pretty for the sake of safe pretty"],
        ["one holographic or iridescent piece as a focal point", "unusual colour pairings that still feel balanced on the body"],
        {"textures": ["conventional silk and wool", "traditional formal fabrics"], "colours": ["conventional pastel", "safe traditional pink"], "silhouettes": ["conventional graceful shapes", "traditional elegant cuts"], "mood": ["stale", "conventional", "predictable", "unimaginative"]}
    ),
    "uranus_scorpio": make_outer_entry(
        "darkly innovative, intensely experimental",
        ["tech-noir", "bonded construction", "dark innovation"],
        ["bonded tech fabric", "innovative leather alternative", "laser-cut dark material"],
        ["conventional soft cotton", "traditional comfortable knits", "safe lightweight jersey"],
        [{"name": "deep electric", "hex": "#1B03A3"}],
        [{"name": "abyss black", "hex": "#050505"}],
        ["cheerful pastels", "safe conventional brights"],
        ["blackened titanium"], ["obsidian"],
        ["dark circuit-trace embossed", "tech-noir graphics"], ["cheerful conventional prints", "lighthearted florals"],
        ["intense innovation", "darkly experimental"],
        {"work": "the darkly innovative force, tech-noir authority that unsettles and commands", "intimate": "electric intensity through innovative dark materials, tactile surprise", "daily": "tech-noir daily armour, innovative dark materials with hidden depth"},
        ["Seeking dark materials with hidden technical innovation. The blackest fabric with invisible performance is your ideal", "Adopting tech-noir as a personal aesthetic system where darkness and innovation coexist in every garment", "Expressing intensity through material innovation rather than visual volume. Depth beats loudness every time"],
        ["Safe cheerful dressing that ignores the depth and darkness your wardrobe was built to explore", "Conventional comfort that avoids confrontation with the intensity your style naturally demands", "Surface-level trends with no substance beneath their shiny surface. If there is no depth, there is no point"],
        ["innovative dark leather alternatives that outperform the originals", "Hidden tech details that reward close investigation, revealing innovation only to those who look carefully"],
        {"textures": ["safe conventional cotton", "cheerful lightweight jersey"], "colours": ["cheerful pastels", "safe conventional brights"], "silhouettes": ["conventional comfortable shapes", "safe mainstream cuts"], "mood": ["safe", "surface-level", "shallow", "conventional"]}
    ),
    "uranus_sagittarius": make_outer_entry(
        "boundary-crossing, climate-adaptive, radically free",
        ["climate-adaptive", "cross-cultural", "all-terrain"],
        ["adventure-tech fabric", "climate-adaptive textile", "innovative travel-weight material"],
        ["delicate stay-at-home fabrics", "restrictive formal suiting", "fragile location-dependent pieces"],
        [{"name": "electric teal", "hex": "#00FFEF"}],
        [{"name": "neon teal", "hex": "#00B5AD"}],
        ["stay-at-home beige", "restrictive office grey"],
        ["hammered titanium"], ["turquoise"],
        ["cross-cultural tech-woven geometric", "cross-cultural tech-print"], ["parochial local patterns", "conventional travel clichés"],
        ["expansively innovative", "boundary-dissolving"],
        {"work": "the boundary-crosser, global innovation meets professional authority", "intimate": "adventure materials, stories told through tech-enhanced fabrics", "daily": "climate-adaptive dressing that performs across every context"},
        ["Choosing clothing that performs across climates and cultures without sacrificing style or respect", "Investing in tech-enhanced travel pieces that eliminate packing anxiety and perform in any environment", "Practising cultural innovation over cultural appropriation, where respect and creativity coexist in every choice"],
        ["Restrictive formal wear that limits your world to a single climate, culture, or context", "conventional travel clichés, safari jackets and cargo shorts", "Dressing for only one climate or context when your life demands flexibility across all of them"],
        ["Climate-adaptive layers that regulate temperature across hemispheres, making geography irrelevant to your comfort", "one truly innovative travel piece that replaces three conventional ones"],
        {"textures": ["delicate non-travel fabrics", "restrictive formal suiting"], "colours": ["stay-at-home beige", "restrictive corporate grey"], "silhouettes": ["restrictive formal shapes", "movement-limiting cuts"], "mood": ["restrictive", "narrow", "parochial", "afraid"]}
    ),
    "uranus_capricorn": make_outer_entry(
        "structurally innovative, architecturally precise",
        ["3D knit", "structural engineering", "innovative construction"],
        ["structural tech fabric", "innovative suiting material", "3D-knit construction"],
        ["conventional worsted wool", "traditional suiting", "heritage-for-status fabrics"],
        [{"name": "dark steel", "hex": "#4A4A4A"}],
        [{"name": "charcoal", "hex": "#36454F"}],
        ["conventional corporate navy", "establishment dark blue"],
        ["platinum"], ["garnet"],
        ["architectural digital motif", "structural grid pattern"], ["conventional power stripe", "safe heritage check"],
        ["structurally innovative", "architecturally precise"],
        {"work": "the structural innovator, authority through engineering, not tradition", "intimate": "precision construction, architecturally beautiful even in rest", "daily": "engineering-first dressing, 3D knit, structural innovation, precision fit"},
        ["Choosing structural innovation over conventional authority symbols. Engineering earns more respect than heritage alone", "Prioritising engineering-first construction that outperforms traditional tailoring in fit, comfort, and longevity", "authority earned through innovation, not inherited through heritage"],
        ["Conventional power dressing borrowed from the old playbook. Authority needs reinvention, not repetition", "Traditional authority symbols worn without question or thought. Status should be earned through innovation", "Hierarchy expressed through conventional status fabrics that say nothing about who you actually are"],
        ["Exploring 3D-knit suiting that outperforms traditional tailoring in fit, comfort, and environmental impact", "Making structural innovation visible in every seam, so the engineering speaks as loudly as the fabric"],
        {"textures": ["conventional worsted wool", "traditional suiting fabrics"], "colours": ["conventional corporate navy", "establishment dark tones"], "silhouettes": ["conventional suit shapes", "traditional authority silhouettes"], "mood": ["stale", "hierarchical", "conventional", "rigid"]}
    ),
    "uranus_aquarius": make_outer_entry(
        "individually radical, experimentally pure",
        ["experimental material", "category-defying", "pure individuality"],
        ["cutting-edge experimental fabric", "bio-engineered textile", "material that didn't exist last year"],
        ["any conventional fabric worn for convention's sake", "mass-produced basics", "conformist uniforms"],
        [{"name": "electric violet", "hex": "#8B00FF"}],
        [{"name": "neon yellow", "hex": "#CCFF00"}],
        ["any colour chosen to fit in", "conformist safe tones"],
        ["titanium", "surgical steel"], ["meteorite", "labradorite"],
        ["digital glitch", "circuit-board motif", "generative-AI pattern"], ["any conventional repeating pattern", "heritage prints"],
        ["radical", "experimental", "category-defying"],
        {"work": "the person the future sent back, nothing about your outfit has been seen before", "intimate": "materials that provoke curiosity and conversation, tactile impossibility", "daily": "daily individuality, every outfit reflects who you actually are"},
        ["wear something genuinely new, materials or shapes nobody expected", "Wearing materials that challenge the very definition of what clothing can be and do", "Choosing pure individuality over any group affiliation, even the groups that celebrate individuality"],
        ["any outfit chosen to fit in or conform", "dressing to be accepted rather than to be yourself", "Rejecting convention of any kind, including the conventions of alternative and counterculture communities"],
        ["one truly experimental piece that nobody can categorise", "a technical fabric with an unusual finish or structure, cut into a silhouette you already know how to wear"],
        {"textures": ["mass-produced conventional fabrics", "conformist uniform materials"], "colours": ["safe fitting-in tones", "conformist neutral palette"], "silhouettes": ["conventional mainstream shapes", "safe predictable cuts"], "mood": ["conformist", "conventional", "ordinary", "predictable"]}
    ),
    "uranus_pisces": make_outer_entry(
        "transcendently innovative, luminously shifting",
        ["colour-shift", "photochromic", "luminous finish"],
        ["luminous colour-shifting fabric", "photochromic textile", "holographic-finish chiffon"],
        ["rigid conventional fabrics", "materialistic status-symbol materials", "unimaginative basics"],
        [{"name": "aurora green", "hex": "#01796F"}],
        [{"name": "pale violet", "hex": "#DDA0DD"}],
        ["rigid material-world tones", "unimaginative conventional colours"],
        ["iridescent titanium"], ["opal"],
        ["aurora-inspired", "colour-shifting pattern", "dream-state digital"], ["rigid geometric grids", "conventional repeating patterns"],
        ["transcendent", "fluidly innovative", "luminously shifting"],
        {"work": "the visionary, beauty that seems to come from another dimension", "intimate": "colour-shifting, aurora-like, luminous, materials that seem alive", "daily": "daily transcendence, pieces that shift colour with light and movement"},
        ["colour-shifting or photochromic materials for a soft surprise in daylight", "Choosing luminous fabrics that respond to their environment, shifting colour with light and movement", "Pursuing transcendent beauty through material innovation that makes ordinary fabrics feel like relics"],
        ["Rigid materialistic dressing concerned only with status, ignoring the emotional and spiritual dimensions of clothing", "Unimaginative conventional choices that ignore the possibility of clothing as art and experience", "treating clothing as mere function when it could be art"],
        ["one photochromic piece that shifts throughout the day", "Luminous finishes that glow differently under natural light, candlelight, and evening illumination"],
        {"textures": ["rigid conventional fabrics", "unimaginative status-symbol materials"], "colours": ["rigid conventional tones", "unimaginative safe colours"], "silhouettes": ["rigid unmoving shapes", "materialistic status-symbol cuts"], "mood": ["rigid", "materialistic", "unimaginative", "earthbound"]}
    ),
}
OUTER_ENTRIES.update(uranus_entries_raw)

# Neptune entries (12), dreams, illusion, where you idealise and transcend
neptune_entries_raw = {
    "neptune_aries": make_outer_entry(
        "inspired, dream-filtered, softly bold",
        ["soft strength", "washed finish", "dream-filtered colour"],
        ["soft stretch jersey", "fluid performance knit", "washed silk tee"],
        ["harsh stiff cotton", "rigid formal gabardine", "unforgiving structured fabrics"],
        [{"name": "misty red", "hex": "#B5495B"}],
        [{"name": "blush rose", "hex": "#FFB7C5"}],
        ["harsh primary red", "aggressive neon", "blunt unfiltered brights"],
        ["rose gold"], ["red coral"],
        ["watercolour bold stroke", "soft-edged graphic"], ["hard-edged geometric", "aggressive sharp-line print"],
        ["softly strong", "dream-filtered boldness"],
        {"work": "inspired leadership, authority that moves people rather than commands them", "intimate": "bold but tender, directness softened by emotional depth", "daily": "movement-friendly softness with an edge of fire underneath"},
        ["Expressing boldness filtered through beauty, where strength and softness coexist in every piece", "Choosing soft fabrics in strong colours. A washed silk in crimson carries fire without aggression", "directness tempered by empathy in every outfit choice"],
        ["Harsh aggressive dressing that lacks emotional nuance or the softness that makes strength beautiful", "Blunt literal power-dressing with no soul or imagination behind it. Authority needs grace to land", "Force without grace in any garment. Your power needs beauty as much as beauty needs your power"],
        ["a washed-silk tee in a powerful colour, strength and softness unified", "Soft-edged red tones rather than fire-engine primaries. Misty red over harsh crimson every time"],
        {"textures": ["harsh stiff gabardine", "rigid power-suiting"], "colours": ["harsh primary red", "blunt aggressive brights"], "silhouettes": ["aggressive padded shoulders", "rigid power shapes"], "mood": ["harsh", "blunt", "aggressive", "soulless"]}
    ),
    "neptune_taurus": make_outer_entry(
        "enchanted, dream-quality, sensorially transcendent",
        ["cloud-weight", "dream finish", "impossible softness"],
        ["cloud-weight cashmere", "dream-finish silk charmeuse", "brushed alpaca"],
        ["scratchy cheap knits", "synthetic imitation luxury", "plasticky faux-silk"],
        [{"name": "misty green", "hex": "#8FBC8F"}],
        [{"name": "buttery cream", "hex": "#FFFDD0"}],
        ["harsh synthetic colours", "cheap-feeling brights", "cold clinical tones"],
        ["rose gold"], ["jade", "opal"],
        ["impressionist botanical", "soft-focus floral"], ["hard-edged graphic", "stark geometric"],
        ["dreamy luxury", "sensory enchantment"],
        {"work": "quiet luxury so tactile it stops conversation", "intimate": "silk against skin, dreamlike softness, close-range sensory pull", "daily": "the softest version of every basic, elevated through touch"},
        ["prioritising fabrics that feel exceptional before they even look expensive", "choosing pieces that read refined from a distance and indulgent up close", "letting texture do the work instead of piling on detail"],
        ["Harsh cheap fabrics that break the spell of luxury your presence naturally creates around you", "Synthetic imitations of natural luxury that fool the eye but never fool the hand", "Prioritising visual beauty over tactile beauty when your hands know more than your eyes"],
        ["one cashmere piece so soft it feels imaginary", "Silk base layers as daily enchantment. The first thing against your skin should feel like a dream"],
        {"textures": ["scratchy synthetic knits", "plasticky faux-luxury"], "colours": ["harsh synthetic tones", "cold clinical colours"], "silhouettes": ["rigid uncomfortable shapes", "stiff unpleasant cuts"], "mood": ["harsh", "cheap", "unromantic", "synthetic"]}
    ),
    "neptune_gemini": make_outer_entry(
        "imaginative, sheer-layered, shifting",
        ["sheerness", "colour-shift", "impressionist print"],
        ["light flowing blend", "sheer layering fabric", "soft iridescent jersey"],
        ["heavy single-note fabrics", "stiff literal-minded materials", "rigid non-layerable pieces"],
        [{"name": "lavender", "hex": "#E6E6FA"}],
        [{"name": "pale aqua", "hex": "#ADE8F4"}],
        ["blunt primary colours", "stark literal black", "humourless corporate tones"],
        ["silver"], ["amethyst"],
        ["shifting abstract", "dream-logic pattern", "impressionist motif"], ["rigid geometric grids", "literal representational prints"],
        ["layered dream", "sheer and shifting"],
        {"work": "imaginative engagement, ideas communicated through visual poetry", "intimate": "layered sheers, shifting colours, dreamy unreliable beauty", "daily": "everyday impressionism, prints and colours that shift with mood and light"},
        ["Building sheer layers that create shifting colour effects as you move through different lights", "prints that look different up close versus far away", "Choosing colours that change depending on the light, revealing new tones as the day progresses"],
        ["Literal single-meaning outfits that say only one thing. Your imagination deserves more dimensions", "Blunt one-note colour statements that shut down interpretation before it begins", "Humourless functional-only dressing that treats clothing as mere utility rather than poetry"],
        ["sheer overlay that transforms the colour of everything underneath", "Impressionist prints that evoke a feeling rather than depict a literal image. Suggestion over statement"],
        {"textures": ["heavy literal fabrics", "stiff single-meaning materials"], "colours": ["blunt primary colours", "humourless corporate monotone"], "silhouettes": ["rigid literal shapes", "stiff unchanging forms"], "mood": ["blunt", "literal", "humourless", "monotone"]}
    ),
    "neptune_cancer": make_outer_entry(
        "oceanic, deeply intuitive, emotionally translucent",
        ["pearl-tone", "intuitive softness", "oceanic depth"],
        ["flowing organic cotton", "soft pearl-toned silk", "gauze-weight cashmere"],
        ["harsh stiff synthetic", "cold clinical jersey", "uncomfortable formal fabrics"],
        [{"name": "ocean pearl", "hex": "#E8E0D5"}],
        [{"name": "pale blue", "hex": "#AEC6CF"}],
        ["harsh clinical white", "cold institutional tones", "aggressive primary colours"],
        ["silver", "pearl-set"], ["pearl", "moonstone"],
        ["oceanic soft motif", "mother-of-pearl abstract"], ["aggressive angular prints", "confrontational graphics"],
        ["deeply intuitive", "emotionally oceanic"],
        {"work": "psychic warmth, emotional intelligence visible in every soft choice", "intimate": "oceanic depth, pearl-tone softness, the comfort of being deeply known", "daily": "intuitively chosen pieces that feel like they chose you"},
        ["trust the feeling a piece gives you over how it looks in a mirror", "Using pearl and ocean tones as emotional camouflage that protects while remaining beautiful", "Treating softness as emotional intelligence, not weakness. The gentlest fabrics carry the deepest wisdom"],
        ["Dressing that completely ignores your emotional state, forcing you into a mood that does not fit", "Cold clinical choices that shut down feeling when you need warmth and emotional openness", "Uncomfortable clothing worn to meet others' expectations rather than honour your own emotional truth"],
        ["Pearl-tone base layers as your emotional foundation. Start with softness and build from there", "one piece kept because of how it makes you feel, not how it looks"],
        {"textures": ["cold clinical synthetic", "harsh formal gabardine"], "colours": ["harsh clinical white", "cold institutional grey"], "silhouettes": ["sharp aggressive cuts", "rigid uncomfortable shapes"], "mood": ["detached", "cold", "emotionally deaf", "clinical"]}
    ),
    "neptune_leo": make_outer_entry(
        "glamorously inspired, softly radiant",
        ["shimmer", "light-catching", "soft metallics"],
        ["light-catching gold silk", "shimmer-finish chiffon", "soft metallic jersey"],
        ["matte dull basics", "heavy dark formal fabrics", "lifeless corporate blends"],
        [{"name": "champagne gold", "hex": "#F7E7CE"}],
        [{"name": "soft mauve", "hex": "#E0B0FF"}],
        ["dull matte grey", "lifeless beige", "uninspired corporate navy"],
        ["gold"], ["amber"],
        ["glamorous impressionist", "soft-focus theatrical"], ["dull corporate stripe", "lifeless basic check"],
        ["inspired drama", "softly radiant"],
        {"work": "creative star presence, glamour that inspires rather than intimidates", "intimate": "golden candlelit warmth, shimmer silk, dreamy dramatic beauty", "daily": "everyday glamour, a touch of shimmer even in the most casual moment"},
        ["shimmer and light-catching as daily practice, not special-occasion-only", "Treating gold tones as creative fuel that energises your imagination and warms your self-expression", "drama expressed through light and softness, not volume"],
        ["Dull pragmatic dressing that drains your creative energy before the day has even begun", "matte lifeless fabrics that absorb rather than reflect", "treating fashion as merely functional when it could inspire"],
        ["Including one shimmer piece that catches candlelight beautifully and draws the eye with warmth", "Champagne-gold tones as a daily creative catalyst that keeps your imagination fed and glowing"],
        {"textures": ["dull matte basics", "heavy dark formal fabrics"], "colours": ["lifeless grey", "uninspired corporate tones"], "silhouettes": ["dull shapeless forms", "uninspired conventional cuts"], "mood": ["dull", "pragmatic", "uninspired", "lifeless"]}
    ),
    "neptune_virgo": make_outer_entry(
        "mindfully precise, organically refined",
        ["organic fibre", "mindful sourcing", "sustainable detail"],
        ["organic fine cotton", "sustainable silk", "mindfully sourced merino"],
        ["mass-produced synthetics", "chemically treated fabrics", "careless construction"],
        [{"name": "sage mist", "hex": "#9DC183"}],
        [{"name": "warm ivory", "hex": "#FFFFF0"}],
        ["garish synthetic colours", "carelessly dyed fabrics"],
        ["brushed silver"], ["peridot"],
        ["organic abstract", "nature-inspired minimalism"], ["chaotic loud prints", "careless random patterns"],
        ["mindfully precise", "organically refined"],
        {"work": "mindful excellence, every detail handled with care", "intimate": "close attention to weave, finish, and how the fabric settles on the body", "daily": "clean, intentional dressing with natural fibres and no wasted detail"},
        ["noticing weave, finish, and construction before you buy", "choosing natural fibres and careful sourcing over quick convenience", "keeping the look precise without making it feel severe"],
        ["Careless mass-produced consumption that ignores the craft and care behind every garment you own", "Synthetic fabrics chosen without any thought for their environmental or tactile impact on your life", "Chaotic wardrobe entropy where garments accumulate without intention, organisation, or meaningful purpose"],
        ["one sustainably sourced piece chosen with full attention", "a dressing routine that starts with fabric, fit, and finish"],
        {"textures": ["mass-produced synthetics", "carelessly constructed fabrics"], "colours": ["garish synthetic dyes", "carelessly chosen tones"], "silhouettes": ["sloppy careless shapes", "chaotic unintentional forms"], "mood": ["careless", "chaotic", "neglectful", "mindless"]}
    ),
    "neptune_libra": make_outer_entry(
        "enchantingly graceful, dreamlike, romantically soft",
        ["gossamer weight", "chiffon", "romantic drape"],
        ["flowing chiffon", "light silk organza", "gossamer-weight wool"],
        ["heavy coarse fabrics", "stiff graceless blends", "utilitarian workwear"],
        [{"name": "dream pink", "hex": "#FFB7C5"}],
        [{"name": "soft lavender", "hex": "#E6E6FA"}],
        ["harsh utilitarian tones", "graceless industrial colours"],
        ["rose gold"], ["rose quartz", "opal"],
        ["romantic impressionist", "soft-focus floral", "watercolour lace motif"], ["harsh geometric", "utilitarian stripes"],
        ["dreamlike grace", "ethereally balanced"],
        {"work": "soft authority through beauty, the kind of polish that changes the mood of the room", "intimate": "romantic drape, candlelit colour, softness that reads expensive", "daily": "something beautiful in the outfit, even when the day is ordinary"},
        ["treating beauty as part of the function, not an extra", "choosing fabrics that move gently and catch the light softly", "using colour for mood as much as coordination"],
        ["coldly practical choices that flatten the whole look", "Graceless dressing that ignores how line and movement create beauty in a living, breathing body", "harsh fabrics that fight the softness you need"],
        ["one flowing piece that makes ordinary life feel cinematic", "Dream-pink or lavender as an emotional signature colour that communicates your romantic imagination"],
        {"textures": ["heavy coarse utilitarian fabric", "stiff graceless blends"], "colours": ["harsh industrial tones", "graceless utilitarian colours"], "silhouettes": ["clunky graceless shapes", "utilitarian boxy cuts"], "mood": ["ugly", "pragmatic", "graceless", "unromantic"]}
    ),
    "neptune_scorpio": make_outer_entry(
        "mystically intense, darkly veiled, psychically deep",
        ["dark sheer", "smoke-effect", "mystical depth"],
        ["deep flowing silk", "dark sheer layering fabric", "smoke-finish chiffon"],
        ["cheerful lightweight cotton", "bright surface-level fabrics", "shallow shiny synthetics"],
        [{"name": "mystic purple", "hex": "#5C2D91"}],
        [{"name": "deep burgundy", "hex": "#800020"}],
        ["cheerful yellows", "surface-level pastels", "shallow shiny metallics"],
        ["oxidised silver"], ["amethyst", "obsidian"],
        ["dark celestial-map jacquard", "occult-inspired detail", "smoke-effect print"], ["cheerful florals", "bright lighthearted patterns"],
        ["deeply mystical", "veiled and layered"],
        {"work": "psychic power presence, dark authority filtered through otherworldly depth", "intimate": "mystic depth, dark sheer layers, the allure of the unknowable", "daily": "dark layered mystery, even casual carries undertones of the occult"},
        ["Building dark sheer layers that suggest depth without revealing it, creating smoke-like mystery", "Choosing mystical depth over surface-level darkness. Wearing black is easy. Wearing black with meaning is rare", "Weaving occult undertones into colour and detail. A deep plum or a hidden motif carries your intensity"],
        ["Cheerful surface-level dressing that ignores the depths beneath, flattening your complexity into something ordinary", "Shallow shiny status-dressing that substitutes surface glamour for the genuine depth you inhabit", "bright happy pieces worn as a mask over complexity"],
        ["A dark sheer overlay that creates smoke-like depth, adding mystery to whatever you wear underneath", "Mystic purple as an emotional frequency that connects your wardrobe to your inner intensity"],
        {"textures": ["cheerful lightweight cotton", "bright shiny synthetics"], "colours": ["cheerful pastels", "shallow shiny tones"], "silhouettes": ["bright open shapes", "nothing-to-hide simplicity"], "mood": ["shallow", "surface-level", "obvious", "cheerful-as-mask"]}
    ),
    "neptune_sagittarius": make_outer_entry(
        "spiritually adventurous, pilgrimage-inspired, soulfully global",
        ["handwoven artisan", "sacred geometry", "soul-collected"],
        ["global soft textile", "flowing travel-weight silk", "handwoven artisan fabric"],
        ["synthetic mass-produced travel gear", "disposable tourist clothing", "cheap souvenir fabrics"],
        [{"name": "ocean indigo", "hex": "#4B0082"}],
        [{"name": "warm sienna", "hex": "#A0522D"}],
        ["tourist-shop neons", "mass-produced travel-graphic colours"],
        ["hammered silver"], ["lapis lazuli"],
        ["spiritual global motifs", "sacred geometry", "pilgrimage-inspired"], ["mass-produced tourist prints", "cheap cultural clichés"],
        ["spiritually expansive", "pilgrimage-inspired"],
        {"work": "well-travelled ease, pieces that look collected rather than purchased in one go", "intimate": "handwoven texture, storied layers, quiet depth", "daily": "travel-ready dressing with real character in the mix"},
        ["pieces collected on meaningful journeys, not shopping trips", "Choosing handwoven artisan work over machine-produced equivalents. The human hand adds soul to every thread", "Expressing cultural respect through careful curation rather than careless appropriation of global aesthetics"],
        ["Tourist-shop souvenirs worn as global style. Genuine cultural engagement requires more depth than a market purchase", "mass-produced prints that borrow cultural references without any care", "Shallow travel aesthetics with no real cultural engagement or understanding behind the surface look"],
        ["one truly handwoven piece from a meaningful destination", "a patterned scarf or shirt that feels collected rather than souvenir-shop"],
        {"textures": ["synthetic mass-produced travel gear", "disposable tourist fabrics"], "colours": ["tourist-shop neons", "mass-produced graphic tones"], "silhouettes": ["generic tourist shapes", "disposable travel-wear cuts"], "mood": ["narrow", "superficial", "parochial", "tourist-mindset"]}
    ),
    "neptune_capricorn": make_outer_entry(
        "visionarily structured, dream-quality authority",
        ["dream-finish worsted", "midnight-blue", "soft-focus power"],
        ["quality flowing wool", "structured silk suiting", "dream-finish worsted"],
        ["harsh cheap suiting", "rigid uncomfortable formal blends", "soulless corporate polyester"],
        [{"name": "midnight blue", "hex": "#191970"}],
        [{"name": "slate", "hex": "#708090"}],
        ["harsh bright white", "cold fluorescent-lit colours"],
        ["platinum"], ["sapphire"],
        ["classic with dream-quality softness", "soft-focus pinstripe"], ["harsh corporate grid", "rigid sharp-edged check"],
        ["structured dreaming", "soft-focus authority"],
        {"work": "visionary authority, the leader who sees further than the spreadsheet", "intimate": "midnight-blue depth, structured silk, the comfort of beautiful discipline", "daily": "authority with a soul, structured pieces in dream-quality fabrics"},
        ["authority built with beautiful materials, not just serious ones", "Choosing midnight-blue over harsh black for soulful power that carries depth without aggression", "Seeking structure that flows rather than constricts, where discipline and grace coexist in every seam"],
        ["soulless corporate dressing that prioritises image over feeling", "Harsh rigid formality that achieves authority at the cost of all beauty and human warmth", "Cold uninspired authority that lacks vision or soul. Power without imagination is just bureaucracy"],
        ["midnight-blue suiting as a daily act of visionary authority", "structured silk that brings dreamlike quality to power dressing"],
        {"textures": ["harsh cheap suiting", "soulless corporate polyester"], "colours": ["cold fluorescent-friendly colours", "harsh office white"], "silhouettes": ["rigid uncomfortable formal shapes", "soulless corporate cuts"], "mood": ["cold", "soulless", "rigid", "uninspired"]}
    ),
    "neptune_aquarius": make_outer_entry(
        "collectively visionary, luminously progressive",
        ["luminous blend", "bio-luminescent", "collective beauty"],
        ["innovative soft-tech jersey", "luminous recycled blend", "bio-luminescent finish"],
        ["conventional mass-produced basics", "selfish luxury materials", "environmentally unconscious fabrics"],
        [{"name": "aurora blue", "hex": "#0077B6"}],
        [{"name": "electric violet", "hex": "#8B00FF"}],
        ["selfish luxury tones", "conventional establishment colours"],
        ["titanium"], ["labradorite"],
        ["visionary digital", "collective dream motifs", "crystalline lattice weave"], ["selfish status patterns", "conventional establishment prints"],
        ["visionary innovation", "collectively inspired"],
        {"work": "progressive style with a human point of view, polished but unmistakably modern", "intimate": "luminous finishes, unusual fabrics, softness with a futuristic edge", "daily": "forward-looking dressing built from smart materials and clear intention"},
        ["choosing materials that feel genuinely new, not just trend-led", "using luminous or recycled fabrics to make the outfit feel current", "Keeping the look genuinely individual without losing wearability. Innovation should enhance your life, not complicate it"],
        ["Status dressing that hides behind expensive labels instead of earning presence through genuine originality", "establishment style that feels finished before you arrive", "Conformity dressed up as professionalism when you know that real professionalism includes creative courage"],
        ["one luminous piece that changes the mood of the whole look", "aurora tones when you want the outfit to feel optimistic without getting loud"],
        {"textures": ["conventional mass-produced basics", "selfish status fabrics"], "colours": ["selfish luxury tones", "conventional establishment colours"], "silhouettes": ["conventional safe shapes", "establishment-conforming cuts"], "mood": ["selfish", "conventional", "uninspired", "status-obsessed"]}
    ),
    "neptune_pisces": make_outer_entry(
        "purely ethereal, boundlessly imaginative, translucent",
        ["gossamer", "translucence", "watercolour dissolve"],
        ["lightest silk charmeuse", "translucent chiffon", "cloud-weight gauze", "gossamer knit"],
        ["rigid structured suiting", "harsh denim", "heavy earthbound fabrics"],
        [{"name": "pale violet", "hex": "#DDA0DD"}],
        [{"name": "seafoam", "hex": "#93E9BE"}, {"name": "blush rose", "hex": "#FFB7C5"}],
        ["harsh material-world black", "rigid earth tones", "blunt primary colours"],
        ["iridescent silver"], ["amethyst", "aquamarine", "opal"],
        ["watercolour dream", "oceanic flow", "dissolving-edge pattern"], ["rigid geometric", "sharp angular graphics"],
        ["purely ethereal", "floating", "borderless"],
        {"work": "pure imagination, soft focus, presence that shifts the room without forcing it", "intimate": "translucent layers, floating chiffon, closeness without heaviness", "daily": "dressing lightly, with nothing too harsh, rigid, or overworked"},
        ["translucent over opaque, floating over fitted, dreamy over literal", "colour that dissolves at the edges like a watercolour", "fabric so light it barely registers as weight"],
        ["rigid heavy dressing that kills the softness of the look", "harsh literal clothing when you need blur, drape, and air", "treating clothes as pure function when the mood matters"],
        ["one translucent layer that transforms everything underneath into a dream", "Choosing colour by instinct before logic. If your hand reaches for the lilac, trust that impulse completely"],
        {"textures": ["rigid structured suiting", "harsh stiff denim", "heavy earthbound fabrics"], "colours": ["harsh material-world black", "rigid earth tones"], "silhouettes": ["rigid fitted shapes", "heavy earthbound cuts"], "mood": ["rigid", "literal", "earthbound", "unimaginative"]}
    ),
}
OUTER_ENTRIES.update(neptune_entries_raw)

# Pluto entries (12), transformation, power, where you destroy to rebuild
pluto_entries_raw = {
    "pluto_aries": make_outer_entry(
        "primal, armoured, radically reborn",
        ["armour-weight", "bonded construction", "dark intensity"],
        ["heavy tech stretch", "armour-weight knit", "bonded performance jersey"],
        ["soft passive fabrics", "delicate easily-damaged pieces", "timid lightweight blends"],
        [{"name": "magma red", "hex": "#8B0000"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["timid pastels", "passive quiet tones", "surface-level safe colours"],
        ["blackened steel"], ["garnet"],
        ["power graphic", "primal mark-making"], ["pretty florals", "polite conventional patterns"],
        ["primal", "armoured", "radically reborn"],
        {"work": "hard-edged authority, the kind that changes the temperature of the room", "intimate": "raw intensity held in dark, close-fitting layers", "daily": "armour-like dressing with one sharp point of force"},
        ["dressing the version of yourself that takes up more space, not less", "choosing dark intensity over anything too polite or apologetic", "using armour-like layers when you need the outfit to hold you together"],
        ["timid dressing that clings to an old version of yourself", "Surface-level change that avoids real transformation. A new jacket is not reinvention if the mindset stays the same", "safe choices that preserve a self you have outgrown"],
        ["one armour-like piece that changes your posture immediately", "dark intensity as a daily anchor rather than a special-occasion mood"],
        {"textures": ["soft passive fabrics", "delicate timid materials"], "colours": ["timid pastels", "passive beige"], "silhouettes": ["soft unprotected shapes", "timid shrinking cuts"], "mood": ["timid", "passive", "surface-level", "unchanged"]}
    ),
    "pluto_taurus": make_outer_entry(
        "deeply regenerative, ruthlessly curated",
        ["dense organic", "regenerative fibre", "ruthless edit"],
        ["dense organic luxury", "sustainable heavyweight cotton", "regenerative-fibre wool"],
        ["disposable fast-fashion of any kind", "cheap imitation materials", "quantity-over-quality purchases"],
        [{"name": "deep earth", "hex": "#3B2F2F"}],
        [{"name": "rich emerald", "hex": "#046307"}],
        ["cheap-looking brights", "disposable trend colours", "synthetic-looking tones"],
        ["recycled gold"], ["obsidian"],
        ["tectonic texture", "geological-stratum pattern"], ["disposable trend prints", "surface-level decorative"],
        ["deeply grounded", "regenerated", "built to outlast"],
        {"work": "regenerative authority, quality so deep it transforms the room's standards", "intimate": "absolute tactile quality, nothing unworthy touches the skin", "daily": "a ruthlessly edited wardrobe where everything has earned its place"},
        ["ruthless curation, if it does not transform you, it goes", "deep material quality as a form of personal power", "Owning fewer pieces, where each one is so transformatively good it changes how you feel when you wear it"],
        ["Accumulating clothing without clear purpose or intention. Every addition should transform, not just fill space", "Keeping pieces out of guilt or nostalgia when they no longer serve the person you are becoming", "surface-level shopping that avoids the real work of curation"],
        ["a seasonal purge that forces honest evaluation of every piece", "one transformative purchase that replaces five mediocre ones"],
        {"textures": ["disposable fast-fashion synthetics", "cheap imitation materials"], "colours": ["cheap synthetic tones", "disposable trend colours"], "silhouettes": ["flimsy disposable shapes", "cheap mass-produced cuts"], "mood": ["shallow", "disposable", "materialistic", "unexamined"]}
    ),
    "pluto_gemini": make_outer_entry(
        "transformatively expressive, dual-natured, strategically versatile",
        ["dual-face", "shape-memory", "strategic layering"],
        ["innovative bonded blend", "shape-memory fabric", "dual-face technical textile"],
        ["conventional single-layer cotton", "predictable fixed-form fabrics"],
        [{"name": "dark teal", "hex": "#004953"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["safe predictable tones", "cheerful surface-level colours"],
        ["mixed dark metals"], ["labradorite"],
        ["dual-sided print", "transformation-motif graphic"], ["predictable repeating patterns", "safe static prints"],
        ["transforming", "dual-natured", "strategically versatile"],
        {"work": "strategic communication power, every outfit says exactly what you need it to", "intimate": "dual-natured depth, the allure of someone who contains multitudes", "daily": "shape-shifting as power, different people see different versions"},
        ["Treating style as a strategic communication tool that controls the narrative before you speak", "dual-face garments that reveal different sides to different audiences", "Choosing dark versatility over light variety. Depth in your range says more than breadth"],
        ["Static predictable messaging through your wardrobe that tells the same story everyone expects from you", "Safe surface-level communication through clothing that never reveals the complexity underneath", "One-dimensional self-presentation that reduces your multifaceted nature to a single readable signal"],
        ["a reversible piece that shows different faces to different contexts", "Dark tonal versatility as a deliberate communication strategy, saying different things with the same palette"],
        {"textures": ["conventional fixed fabrics", "predictable single-layer cotton"], "colours": ["safe predictable tones", "cheerful single-meaning colours"], "silhouettes": ["predictable fixed shapes", "one-dimensional cuts"], "mood": ["static", "predictable", "one-dimensional", "fixed"]}
    ),
    "pluto_cancer": make_outer_entry(
        "emotionally rebuilt, deeply protective",
        ["protective weight", "dark softness", "emotional armour"],
        ["dense washed organic cotton", "protective heavyweight knit", "dark soft jersey"],
        ["shallow lightweight synthetics", "cold clinical fabrics", "unprotective sheer pieces"],
        [{"name": "deep sea", "hex": "#003545"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["shallow pastel", "surface-level cheerful colours", "cold clinical white"],
        ["antique silver"], ["black pearl"],
        ["deep water motifs", "abyssal abstract"], ["cheerful surface patterns", "shallow decorative florals"],
        ["deeply protective", "emotionally armoured", "rebuilt from within"],
        {"work": "emotional power, the leader whose depth intimidates and inspires", "intimate": "total emotional safety through dark enveloping layers", "daily": "protective cocooning that comes from having survived and rebuilt"},
        ["Building dark protective layers as emotional armour that shields your vulnerability with visible strength", "Choosing deep ocean tones for emotional depth that carries your intensity without broadcasting it", "clothing as a rebuilt shell after emotional transformation"],
        ["Shallow cheerful dressing that masks real feelings behind a performance of brightness", "Surface-level emotional presentation through clothing that hides your true depth behind safe cheerfulness", "Cold clinical clothing that prevents the vulnerability necessary for genuine emotional connection"],
        ["Deep-sea tones as your emotional signature. Ink-blue, deep teal, and midnight carry your truth", "protective layering as a daily ritual of rebuilt safety"],
        {"textures": ["shallow lightweight synthetics", "cold clinical fabrics"], "colours": ["shallow cheerful pastels", "surface-level brights"], "silhouettes": ["exposed unprotected shapes", "shallow flimsy cuts"], "mood": ["shallow", "surface-level", "emotionally avoidant", "unprotected"]}
    ),
    "pluto_leo": make_outer_entry(
        "creatively reborn, darkly radiant, phoenix-like",
        ["transformative metallic", "dark gold", "power-weight velvet"],
        ["transformative metallic fabric", "dense dark silk", "power-weight velvet"],
        ["fading muted fabrics", "dim retiring materials", "invisible bland basics"],
        [{"name": "molten gold", "hex": "#B8860B"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["dim retiring tones", "fading beige", "invisible greige"],
        ["dark gold"], ["tiger eye"],
        ["phoenix motifs", "dark sun imagery", "power-crest graphics"], ["safe simple basics", "invisible minimal patterns"],
        ["powerful reinvention", "darkly radiant"],
        {"work": "magnetic authority, the kind of presence that looks earned", "intimate": "molten gold intensity, dark dramatic power, magnetic presence", "daily": "dark glamour with real heat behind it"},
        ["dressing the version of yourself that can actually hold the attention", "choosing dark gold over bright shine when you want drama with weight", "letting one strong piece carry the whole look"],
        ["Dim safe dressing that hides your transformation behind modesty when you need to be seen shining", "staying visually the same when everything inside has changed", "Dimming your light for others' comfort when your transformation requires full, unapologetic visibility"],
        ["molten gold accents as a signature rather than a full costume", "dark drama that shows confidence without over-explaining it"],
        {"textures": ["fading dim fabrics", "invisible bland basics"], "colours": ["dim retiring tones", "invisible grey-beige"], "silhouettes": ["shrinking invisible shapes", "dim self-effacing cuts"], "mood": ["dim", "static", "unchanged", "invisible"]}
    ),
    "pluto_virgo": make_outer_entry(
        "transformatively precise, surgically refined",
        ["surgical finish", "obsessive detail", "dark precision"],
        ["precision dark fabric", "surgically finished organic cotton", "refined dense knit"],
        ["sloppy unfinished construction", "careless mass-produced fabrics", "superficial quick-fix pieces"],
        [{"name": "obsidian grey", "hex": "#3D3D3D"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["carelessly chosen colours", "sloppy undefined tones"],
        ["brushed dark silver"], ["obsidian", "sapphire"],
        ["precise dark detail", "surgical grid motif"], ["sloppy abstract", "careless random placement"],
        ["deeply refined", "surgically precise"],
        {"work": "transformative precision, the one who finds the flaw everyone missed", "intimate": "obsessive attention to invisible details, quality felt but not seen", "daily": "ruthless editing, nothing imprecise survives in this wardrobe"},
        ["obsessive attention to the details others never see, lining, stitching, inner construction", "Choosing dark precision over bright approximation. A perfect dark garment outperforms a flashy imperfect one", "quality verified at every level, including the ones no one sees"],
        ["Accepting good enough in construction or fit when your standard should be nothing less than flawless", "Surface-level quality that hides poor fundamentals underneath. If the lining is cheap, the garment is cheap", "Careless details in hidden areas. The inside of a garment tells you more about its quality than the outside"],
        ["turning every piece inside-out before purchase to verify construction", "dark tonal precision as a personal diagnostic system"],
        {"textures": ["sloppy mass-produced construction", "careless unfinished fabrics"], "colours": ["carelessly chosen tones", "sloppy undefined colours"], "silhouettes": ["approximate baggy fits", "careless proportions"], "mood": ["superficial", "careless", "sloppy", "approximate"]}
    ),
    "pluto_libra": make_outer_entry(
        "darkly beautiful, radically elegant",
        ["dark silk", "satin-back crepe", "deconstructed beauty"],
        ["dark flowing silk", "power-weight chiffon", "transformative satin-back crepe"],
        ["shallow pretty-pretty fabrics", "superficial decorative materials", "cheap sparkle-for-sparkle's-sake"],
        [{"name": "dark rose", "hex": "#B5495B"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["shallow pretty pastels", "superficial cheerful colours"],
        ["dark rose gold"], ["garnet"],
        ["dark damask rose print", "deconstructed beauty patterns"], ["shallow decorative prints", "superficial pretty patterns"],
        ["transformed beauty", "darkly elegant"],
        {"work": "radical harmony, beauty as a form of power, not decoration", "intimate": "dark romantic intensity, beauty that has survived and deepened", "daily": "beauty with depth, dark rose over bright pink, earned elegance over inherited"},
        ["Treating beauty as power rather than prettiness. Depth and darkness make elegance more compelling, not less", "Choosing dark elegance over superficial sparkle. Genuine refinement does not need to glitter to command", "aesthetics that have been through fire and emerged stronger"],
        ["Shallow surface-level prettiness without depth or meaning. Beauty should make people think, not just look", "Beauty treated as mere decoration rather than a genuine expression of your inner transformation", "Sparkle that distracts from substance rather than enhancing it. If the shimmer is the whole story, it is too thin"],
        ["dark rose tones as a signature of beauty-through-transformation", "Deconstructed elegance that reveals the hidden structure beneath beauty, making the craft visible"],
        {"textures": ["shallow sparkly fabrics", "superficial decorative materials"], "colours": ["shallow pretty pastels", "superficial cheerful colours"], "silhouettes": ["superficially pretty shapes", "decoration-only silhouettes"], "mood": ["shallow", "superficial", "unexamined", "decorative-only"]}
    ),
    "pluto_scorpio": make_outer_entry(
        "absolutely powerful, impenetrably dark, total",
        ["densest construction", "armour-weight", "absolute black"],
        ["densest leather", "bonded armour-weight fabric", "power-construction wool", "blackened silk"],
        ["lightweight vulnerable fabrics", "soft passive materials", "cheerful bright synthetics"],
        [{"name": "abyss black", "hex": "#050505"}],
        [{"name": "oxblood", "hex": "#4A0000"}],
        ["any bright colour", "anything cheerful, light, or surface-level"],
        ["blackened titanium", "dark steel"], ["obsidian", "black diamond"],
        ["power totemic symbols", "dark serpent-and-sigil jacquard", "power sigils"], ["cheerful florals", "lighthearted patterns of any kind"],
        ["absolute power", "impenetrably dark"],
        {"work": "the person whose authority needs no introduction, dark, decisive, unquestionable", "intimate": "total intensity, absolute depth, the power of complete vulnerability through strength", "daily": "daily conviction in the deepest black you own, total, impenetrable, grounded"},
        ["Expressing power through material quality rather than visual volume. Density beats loudness every time", "Choosing the deepest blacks as a daily commitment to intensity. If the black is not bottomless, it is not enough", "Concentrated dressing that leaves nothing accidental. Every seam, every fold, every shade is a deliberate choice"],
        ["Any softness not earned through strength. Vulnerability in your wardrobe must be a choice, not a default", "Vulnerability without purpose in your clothing. If exposure does not serve your power, it weakens it", "Cheerful surface-level dressing that avoids the depths your wardrobe was built to explore"],
        ["one truly well-made dark piece that changes how you carry yourself", "investing in blacks that never fade or wash out"],
        {"textures": ["lightweight vulnerable fabrics", "soft passive materials"], "colours": ["bright cheerful colours", "surface-level pastels"], "silhouettes": ["soft vulnerable shapes", "open exposed cuts"], "mood": ["weak", "passive", "compromising", "surface-level"]}
    ),
    "pluto_sagittarius": make_outer_entry(
        "philosophically transformed, deeply worldly",
        ["dark global textile", "transformed tradition", "deep indigo"],
        ["dark global textile", "transformed traditional weave", "power-weight artisan fabric"],
        ["shallow tourist fabrics", "surface-level cultural cosplay", "cheap mass-produced 'ethnic' prints"],
        [{"name": "deep indigo", "hex": "#130A4F"}],
        [{"name": "deep black", "hex": "#0A0A0A"}],
        ["shallow tourist colours", "surface-level cultural cliché tones"],
        ["aged dark brass"], ["lapis lazuli"],
        ["transformed global motifs", "deconstructed sacred geometry"], ["tourist-shop cultural clichés", "surface-level 'ethnic' prints"],
        ["deeply philosophical", "culturally transformed"],
        {"work": "hard-won style wisdom, the kind that looks lived in rather than performed", "intimate": "deep indigo intensity, pieces collected from meaningful journeys of real change", "daily": "depth in every choice, nothing souvenir-like, nothing surface-level"},
        ["pieces earned through real experience, not purchased as souvenirs", "Seeking cultural depth through genuine engagement rather than surface-level aesthetic borrowing", "deep indigo as the colour of hard-won wisdom"],
        ["Shallow cultural tourism in clothing that reduces entire traditions to decorative accessories", "Surface-level philosophical posturing through accessories that gesture at depth without earning it", "Adopting depth as an aesthetic without real transformation. Looking worldly is not the same as being worldly"],
        ["deep indigo as a steady signature rather than a statement", "one piece from a journey that changed your taste, not just your passport stamp"],
        {"textures": ["shallow tourist fabrics", "surface-level cultural pieces"], "colours": ["shallow tourist-bright colours", "surface-level cultural cliché tones"], "silhouettes": ["generic tourist shapes", "shallow travel-cliché cuts"], "mood": ["shallow", "tourist-minded", "surface-level", "philosophically lazy"]}
    ),
    "pluto_capricorn": make_outer_entry(
        "institutionally powerful, structurally absolute",
        ["power suiting", "armour-weight gabardine", "structural dark"],
        ["power suiting cloth", "structural dark wool", "armour-weight gabardine"],
        ["casual undermining fabrics", "weak lightweight blends", "temporary trendy materials"],
        [{"name": "power black", "hex": "#1C1C1C"}],
        [{"name": "charcoal", "hex": "#36454F"}],
        ["casual undermining colours", "weak washed-out tones", "impermanent trend colours"],
        ["platinum", "dark steel"], ["onyx", "garnet"],
        ["power architecture motifs", "structural grid"], ["casual novelty prints", "weak decorative patterns"],
        ["institutional power", "structurally absolute"],
        {"work": "institutional authority through immaculate structure and exact fit", "intimate": "power held in reserve, clean lines even when the room is private", "daily": "dark structure, repeated until it becomes instinct"},
        ["treating construction as the source of authority, not labels", "Choosing permanence over trends every single time. A piece that lasts decades embodies real power", "keeping the palette dark enough that the cut does the talking"],
        ["Surface-level authority communicated through logos or labels rather than genuine quality and craftsmanship", "Impermanent trend-chasing in professional settings where your wardrobe should project lasting authority", "Casual undermining of your own power through clothes that suggest you take yourself less seriously than you should"],
        ["one perfectly constructed dark suit as the benchmark piece", "power-black when you want the outfit to feel automatic and exact"],
        {"textures": ["casual lightweight blends", "weak trendy materials"], "colours": ["casual undermining colours", "weak washed-out tones"], "silhouettes": ["casual sloppy shapes", "weak unstructured cuts"], "mood": ["weak", "impermanent", "surface-level", "casual-as-avoidance"]}
    ),
    "pluto_aquarius": make_outer_entry(
        "collectively transformative, revolutionary",
        ["revolutionary tech", "experimental dark", "collective innovation"],
        ["revolutionary tech fabric", "experimental dark textile", "collective-production innovative material"],
        ["selfish luxury for luxury's sake", "individual status-symbol fabrics", "conformist mass-production"],
        [{"name": "void purple", "hex": "#36013F"}],
        [{"name": "abyss black", "hex": "#050505"}],
        ["selfish luxury colours", "conformist mainstream tones"],
        ["dark titanium"], ["meteorite"],
        ["revolutionary dark digital", "collective power symbol", "systemic-change motif"], ["individual status patterns", "conformist conventional prints"],
        ["revolutionary", "collectively powerful"],
        {"work": "group-changing presence, the outfit that rewrites the dress code without shouting", "intimate": "void-purple depth, unusual materials, power shared through style intelligence", "daily": "values-first dressing with sharper materials and fewer empty signals"},
        ["choosing materials that feel advanced enough to change the whole outfit", "letting innovation show in construction and finish, not slogans", "using void-purple or near-black tones when you want the look to feel disruptive but controlled"],
        ["Status dressing that is only about exclusivity when your transformation requires accessibility and meaning", "Mainstream conformity presented as professionalism when genuine professionalism includes radical authenticity", "luxury signals that do the thinking for you"],
        ["one void-purple or dark technical piece as the focal point of the look", "a sharply made piece from an innovative label or small-maker production run"],
        {"textures": ["selfish luxury fabrics", "conformist mass-produced materials"], "colours": ["selfish luxury tones", "conformist mainstream colours"], "silhouettes": ["individual status-symbol shapes", "conformist mainstream cuts"], "mood": ["conformist", "selfish", "status-obsessed", "individually hoarding"]}
    ),
    "pluto_pisces": make_outer_entry(
        "spiritually dissolved, transcendently dark, boundaryless",
        ["ethereal dark silk", "deep gauze", "dissolving weight"],
        ["ethereal dark flowing silk", "deep soft gauze", "translucent dark chiffon"],
        ["rigid material-world fabrics", "heavy earthbound materials", "bounded structured pieces"],
        [{"name": "deep violet", "hex": "#5B0A91"}],
        [{"name": "mystic purple", "hex": "#5C2D91"}],
        ["rigid earthbound colours", "harsh material-world tones", "blunt literal primaries"],
        ["iridescent dark silver"], ["amethyst", "black opal"],
        ["dissolving-boundary motifs", "ego-death imagery", "transcendent flow"], ["rigid bounded patterns", "material-world geometric"],
        ["transcendent", "boundaryless", "spiritually dissolved"],
        {"work": "dark softness with real presence, the kind that blurs the edges without disappearing", "intimate": "ethereal layers, low light, closeness built through drape rather than exposure", "daily": "flowing dark pieces that soften the outline and quiet the room"},
        ["using dark sheer or gauze layers when you want depth without hardness", "letting deep violet do the mood-setting instead of adding more detail", "choosing pieces that feel fluid on the body, not boxed in"],
        ["rigid heavy dressing that makes everything feel fixed", "literal practical-only clothing when the outfit needs atmosphere", "anything too hard-edged to move with the rest of you"],
        ["deep violet flowing layers when you want quiet intensity", "one ethereal piece that changes the line of the whole outfit"],
        {"textures": ["rigid structured suiting", "heavy earthbound materials"], "colours": ["rigid material-world tones", "harsh earthbound colours"], "silhouettes": ["rigid bounded shapes", "heavy material-world cuts"], "mood": ["rigid", "materialistic", "bounded", "earthbound"]}
    ),
}
OUTER_ENTRIES.update(pluto_entries_raw)


# ═══════════════════════════════════════════════════════════════
# ASPECTS (~30 entries)
# ═══════════════════════════════════════════════════════════════

ASPECTS = {
    "venus_conjunction_mars": {"effect": "desire and drive fused, passionate style instinct", "texture_modifier": "adds tactile intensity and sensory boldness", "colour_modifier": "deepens warm tones, adds red-spectrum heat", "code_addition_leaninto": "dress with passionate intention", "code_addition_avoid": "bland or passionless choices"},
    "venus_trine_mars": {"effect": "harmonious blend of beauty and energy", "texture_modifier": "balanced tactile interest", "colour_modifier": "warm palette with confident accents", "code_addition_leaninto": "let beauty and strength coexist", "code_addition_avoid": "choosing beauty or strength but never both"},
    "venus_square_mars": {"effect": "tension between aesthetics and aggression", "texture_modifier": "push-pull between soft and hard textures", "colour_modifier": "conflicting warm and cool impulses", "code_addition_leaninto": "use creative tension between soft and strong", "code_addition_avoid": "unresolved style conflicts that look accidental"},
    "venus_opposition_mars": {"effect": "opposing pulls between beauty and raw power", "texture_modifier": "alternating soft and hard texture choices", "colour_modifier": "contrasting palette swings between gentle and bold", "code_addition_leaninto": "embrace contrast as a design principle", "code_addition_avoid": "committing fully to neither soft nor hard"},
    "venus_sextile_mars": {"effect": "easy flow between elegance and energy", "texture_modifier": "natural integration of varied textures", "colour_modifier": "warm balanced palette", "code_addition_leaninto": "integrate beauty and energy effortlessly", "code_addition_avoid": "overthinking the beauty-strength balance"},
    "venus_conjunction_saturn": {"effect": "beauty refined through discipline and restraint", "texture_modifier": "favours structured high-quality textures", "colour_modifier": "darkens and refines palette toward classic tones", "code_addition_leaninto": "invest in fewer perfect pieces", "code_addition_avoid": "impulse purchases or trend-chasing"},
    "venus_square_saturn": {"effect": "tension between desire for beauty and need for restraint", "texture_modifier": "adds structure, reduces flowy", "colour_modifier": "darkens palette, adds formality", "code_addition_leaninto": "investing in fewer, better pieces", "code_addition_avoid": "impulse shopping or trend-chasing"},
    "venus_trine_saturn": {"effect": "natural elegance through discipline", "texture_modifier": "gravitas in fabric choices", "colour_modifier": "naturally refined dark palette", "code_addition_leaninto": "quality over quantity as a life principle", "code_addition_avoid": "compromising quality for convenience"},
    "venus_opposition_saturn": {"effect": "beauty constantly tested by limitation", "texture_modifier": "oscillation between luxurious and austere", "colour_modifier": "warm tones pulled toward cold severity", "code_addition_leaninto": "find beauty within constraints", "code_addition_avoid": "either indulgence or deprivation, find the middle"},
    "venus_conjunction_jupiter": {"effect": "beauty amplified by generosity and abundance", "texture_modifier": "favours rich, generous fabrics", "colour_modifier": "expands palette toward richer tones", "code_addition_leaninto": "go generous with quality and colour", "code_addition_avoid": "scarcity mindset in dressing"},
    "venus_square_jupiter": {"effect": "tension between taste and excess", "texture_modifier": "tendency toward over-the-top textures", "colour_modifier": "risk of palette excess", "code_addition_leaninto": "edit generously, abundance with intention", "code_addition_avoid": "unchecked excess or overdressing"},
    "venus_trine_jupiter": {"effect": "natural abundance of style and beauty", "texture_modifier": "effortlessly rich fabric choices", "colour_modifier": "naturally abundant warm palette", "code_addition_leaninto": "share your style generosity", "code_addition_avoid": "withholding beauty out of false modesty"},
    "venus_conjunction_uranus": {"effect": "electric beauty, sudden style insights", "texture_modifier": "drawn to innovative and unusual textures", "colour_modifier": "unexpected colour combinations", "code_addition_leaninto": "follow sudden style impulses", "code_addition_avoid": "predictable safe choices"},
    "venus_square_uranus": {"effect": "destabilising beauty, unpredictable taste shifts", "texture_modifier": "sudden texture preference changes", "colour_modifier": "volatile palette swings", "code_addition_leaninto": "channel unpredictability into a signature", "code_addition_avoid": "letting instability look like confusion"},
    "venus_conjunction_neptune": {"effect": "dreamlike beauty, idealised aesthetics", "texture_modifier": "drawn to flowing ethereal textures", "colour_modifier": "soft watercolour palette", "code_addition_leaninto": "dress for the dream version of yourself", "code_addition_avoid": "letting idealism prevent practical dressing"},
    "venus_square_neptune": {"effect": "confusion between real and idealised beauty", "texture_modifier": "difficulty committing to texture choices", "colour_modifier": "hazy unfocused palette", "code_addition_leaninto": "ground your dreams in quality basics", "code_addition_avoid": "buying fantasy pieces that never get worn"},
    "moon_conjunction_saturn": {"effect": "emotional control, comfort in discipline", "texture_modifier": "structured comfort textures", "colour_modifier": "muted restrained palette", "code_addition_leaninto": "find comfort in structure", "code_addition_avoid": "chaos in emotional dressing"},
    "moon_square_saturn": {"effect": "tension between emotional needs and self-discipline", "texture_modifier": "conflicted comfort textures", "colour_modifier": "restricts comfortable palette", "code_addition_leaninto": "allow yourself comfort without guilt", "code_addition_avoid": "punishing yourself through uncomfortable clothing"},
    "moon_trine_saturn": {"effect": "natural emotional discipline", "texture_modifier": "naturally structured comfort", "colour_modifier": "calm disciplined palette", "code_addition_leaninto": "structured comfort as a strength", "code_addition_avoid": "mistaking comfort for weakness"},
    "moon_conjunction_venus": {"effect": "emotional beauty, instinctive aesthetics", "texture_modifier": "naturally drawn to beautiful textures", "colour_modifier": "emotionally responsive to colour", "code_addition_leaninto": "trust your aesthetic instinct", "code_addition_avoid": "ignoring your emotional response to clothing"},
    "sun_conjunction_saturn": {"effect": "identity forged through discipline", "texture_modifier": "serious structured fabrics", "colour_modifier": "dark authoritative palette", "code_addition_leaninto": "authority in dressing is identity", "code_addition_avoid": "frivolous choices that undermine your authority"},
    "sun_square_saturn": {"effect": "identity tested by limitation", "texture_modifier": "oscillation between ambition and restraint in fabrics", "colour_modifier": "tension between bold and restrained palette", "code_addition_leaninto": "dress through limitations, not around them", "code_addition_avoid": "letting self-doubt dictate wardrobe choices"},
    "mars_conjunction_saturn": {"effect": "controlled force, disciplined action", "texture_modifier": "heavy durable structured fabrics", "colour_modifier": "dark powerful palette", "code_addition_leaninto": "dress for enduring power, not flash", "code_addition_avoid": "impulsive dressing decisions"},
    "mars_square_saturn": {"effect": "frustrated energy, blocked action expressed through style", "texture_modifier": "tension between heavy and light fabrics", "colour_modifier": "dark frustrated palette", "code_addition_leaninto": "channel frustration into powerful dressing", "code_addition_avoid": "dressing in defeat or giving up on style"},
    "ascendant_conjunction_venus": {"effect": "beauty as first impression, effortless attractiveness", "texture_modifier": "naturally gravitates toward beautiful fabrics", "colour_modifier": "instinctively flattering palette", "code_addition_leaninto": "your first impression IS beauty, lean into it", "code_addition_avoid": "hiding your natural attractiveness"},
    "ascendant_square_venus": {"effect": "tension between true beauty and projected image", "texture_modifier": "disconnect between chosen and ideal textures", "colour_modifier": "palette mismatch between comfort and projection", "code_addition_leaninto": "align your outward style with inner beauty", "code_addition_avoid": "projecting an image that does not match who you are"},
    "ascendant_trine_venus": {"effect": "natural harmony between beauty and presentation", "texture_modifier": "effortlessly appropriate texture choices", "colour_modifier": "naturally flattering colour instinct", "code_addition_leaninto": "trust your presentation instinct", "code_addition_avoid": "overcomplicating what comes naturally"},
    "venus_sextile_saturn": {"effect": "easy discipline in aesthetic choices", "texture_modifier": "naturally refined texture selection", "colour_modifier": "elegant restrained palette", "code_addition_leaninto": "effortless quality choices", "code_addition_avoid": "introducing unnecessary chaos"},
    "moon_sextile_saturn": {"effect": "easy emotional structure", "texture_modifier": "comfortably structured fabric preferences", "colour_modifier": "warm but disciplined palette", "code_addition_leaninto": "structured comfort is your superpower", "code_addition_avoid": "destabilising your emotional foundations"},
    "venus_trine_neptune": {"effect": "inspired beauty, artistic vision", "texture_modifier": "drawn to artistic ethereal textures", "colour_modifier": "impressionist palette tendencies", "code_addition_leaninto": "dress as art", "code_addition_avoid": "purely practical dressing that ignores beauty"},
}

# ═══════════════════════════════════════════════════════════════
# HOUSE PLACEMENTS (48 entries: Venus/Moon/Sun/Mars × 12 houses)
# ═══════════════════════════════════════════════════════════════

HOUSE_PLACEMENTS = {}

HOUSE_MODIFIERS_PER_PLANET = {
    "venus": {
        1: "beauty as first impression, your aesthetic IS your identity",
        2: "investment in beautiful things as self-worth expression, quality over quantity",
        3: "style as social currency, approachable beauty that invites conversation",
        4: "comfort as beauty, nostalgic pieces, heirloom aesthetics, beauty at home first",
        5: "creative joy in dressing, bold romantic expression, date-night dressing as art",
        6: "daily beauty rituals, functional elegance, beautiful workwear, aesthetic routines",
        7: "dressing for partnership, harmonious social presentation, beauty that attracts",
        8: "strategic allure, investment beauty, transformative aesthetics, hidden luxury",
        9: "beauty from around the world, global aesthetic influences, cultural elegance",
        10: "public beauty, polished image, aesthetic reputation, career-enhancing style",
        11: "beauty within community, group-aware style, progressive aesthetics, social elegance",
        12: "private beauty, dreamy personal aesthetics, beauty for the self alone",
    },
    "moon": {
        1: "emotional comfort visible in how you present, your feelings wear you",
        2: "security through tactile quality, fabrics as emotional anchors",
        3: "emotional dressing that communicates, approachable comfort, soft signals",
        4: "deepest comfort zone, nostalgic fabrics, heirloom softness, home-as-wardrobe",
        5: "playful emotional expression, comfort in creativity, joy-driven dressing",
        6: "emotional wellbeing through daily comfort, functional softness, care routines",
        7: "emotional harmony in partnership dressing, soft social presentation",
        8: "emotional protection through layering, transformative comfort, hidden softness",
        9: "emotionally expansive dressing, travel comfort, soft global influences",
        10: "publicly composed emotional presentation, professional comfort, polished calm",
        11: "emotional belonging through group-appropriate comfort, community softness",
        12: "private emotional retreat, the softest, most comforting pieces saved for solitude",
    },
    "sun": {
        1: "identity expressed through style as a core life practice",
        2: "self-worth built through wardrobe quality, you are what you invest in",
        3: "communicating identity through everyday style choices, approachable authority",
        4: "identity rooted in heritage, style that honours where you come from",
        5: "creative identity expression, bold self-expression, joy as identity fuel",
        6: "identity expressed through daily discipline, workwear as self-definition",
        7: "identity refined through partnership, social presentation as self-discovery",
        8: "identity transformation through style reinvention, power as self-knowledge",
        9: "identity expanded through global influence, philosophical dressing, cultural breadth",
        10: "identity as public image, career dressing as purpose expression, visible authority",
        11: "identity within community, progressive self-expression, group-aware individuality",
        12: "hidden identity, private style as inner truth, dressing for the self unseen",
    },
    "mars": {
        1: "assertive presence, your style hits first, asks questions later",
        2: "forceful investment, aggressive pursuit of quality, decisive purchasing",
        3: "bold communicative dressing, sharp local presence, assertive social style",
        4: "protective force at home, defensive comfort, fierce domestic style",
        5: "competitive creative expression, bold romantic pursuit, daring date-night looks",
        6: "driven daily dressing, performance workwear, aggressive functionality",
        7: "assertive partnership dressing, competitive social presentation, bold pairings",
        8: "strategic power through transformation, aggressive investment, dark authority",
        9: "adventurous boldness, aggressive global style, daring travel wardrobe",
        10: "ambitious power dressing, career-driven authority, competitive public image",
        11: "group-galvanising style, bold community presence, activist dressing",
        12: "hidden strength, private power dressing, fierce solitude style",
    },
}

house_contexts = {
    1: "self, identity, appearance",
    2: "values, possessions, self-worth",
    3: "communication, local community",
    4: "home, roots, emotional foundation",
    5: "creativity, pleasure, romance",
    6: "daily work, health, routine",
    7: "partnership, social image",
    8: "transformation, shared resources",
    9: "travel, philosophy, higher learning",
    10: "public image, career, visible identity",
    11: "community, future, friendship",
    12: "inner world, retreat, imagination",
}

HOUSE_EXPANDED_DATA = {
    "venus": {
        1: {
            "keywords": ["identity-driven", "personal", "immediate", "visible"],
            "code_consider_bias": ["let your aesthetic be the first thing people notice", "invest in pieces that feel unmistakably you"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["statement outerwear", "signature accessories"],
            "hardware_bias": {"metals": ["gold", "rose gold"], "stones": ["diamond", "clear quartz"]}
        },
        2: {
            "keywords": ["investment", "quality-focused", "tactile", "enduring"],
            "code_consider_bias": ["prioritize quality over quantity in every purchase", "build a wardrobe of pieces that hold value"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["investment knits", "heritage leather goods"],
            "hardware_bias": {"metals": ["gold", "rose gold"], "stones": ["emerald", "jade"]}
        },
        3: {
            "keywords": ["social", "approachable", "versatile", "communicative"],
            "code_consider_bias": ["dress to invite conversation", "keep outfits adaptable for spontaneous plans"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["conversation-starting accessories", "layerable separates"],
        },
        4: {
            "keywords": ["nostalgic", "comfort-driven", "heirloom", "private"],
            "code_consider_bias": ["honour comfort as a core style value", "seek pieces with sentimental or heirloom quality"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["vintage-inspired silhouettes", "hand-me-down styling"],
        },
        5: {
            "keywords": ["creative", "playful", "romantic", "expressive"],
            "code_consider_bias": ["treat dressing as creative self-expression", "let joy drive your wardrobe choices"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["bold colour pairings", "romantic details"],
            "hardware_bias": {"metals": ["gold", "copper"], "stones": ["ruby", "carnelian"]}
        },
        6: {
            "keywords": ["functional", "elegant", "routine", "refined"],
            "code_consider_bias": ["build daily uniforms that feel beautiful", "choose pieces that perform across your routine"],
            "occasion_bias": ["work", "daily"],
            "lean_into_bias": ["polished workwear", "functional elegance"],
        },
        7: {
            "keywords": ["harmonious", "partnership", "balanced", "social"],
            "code_consider_bias": ["dress for harmony in shared contexts", "balance personal style with social awareness"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["complementary pairings", "elegant date-night looks"],
            "hardware_bias": {"metals": ["silver", "platinum"], "stones": ["rose quartz", "pearl"]}
        },
        8: {
            "keywords": ["strategic", "transformative", "magnetic", "hidden"],
            "code_consider_bias": ["invest in fewer transformative pieces", "let allure build through restraint"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["investment statement pieces", "dark luxe textures"],
            "hardware_bias": {"metals": ["gunmetal", "antiqued silver"], "stones": ["garnet", "black onyx"]}
        },
        9: {
            "keywords": ["global", "cultural", "eclectic", "adventurous"],
            "code_consider_bias": ["draw inspiration from global aesthetics", "let travel broaden your wardrobe vocabulary"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["cultural textiles", "globally sourced accessories"],
        },
        10: {
            "keywords": ["polished", "public-facing", "reputational", "aspirational"],
            "code_consider_bias": ["prioritize polished finishes over distressed pieces", "treat fit precision as a non-negotiable"],
            "occasion_bias": ["work", "public"],
            "lean_into_bias": ["tailored", "elevated"],
            "hardware_bias": {"metals": ["silver", "steel"], "stones": ["onyx"]}
        },
        11: {
            "keywords": ["progressive", "community", "forward-thinking", "social"],
            "code_consider_bias": ["experiment with progressive silhouettes", "let your style signal your values"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["avant-garde details", "ethical fashion"],
        },
        12: {
            "keywords": ["private", "dreamy", "ethereal", "introspective"],
            "code_consider_bias": ["dress for how it makes you feel, not how it looks to others", "seek beauty in softness and simplicity"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["flowing silhouettes", "soft draping"],
            "hardware_bias": {"metals": ["silver", "white gold"], "stones": ["moonstone", "amethyst"]}
        },
    },
    "moon": {
        1: {
            "keywords": ["emotionally visible", "instinctive", "reactive", "personal"],
            "code_consider_bias": ["choose pieces that match your emotional state", "let comfort be visible in your presentation"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["soft-structured layers", "comfort-first tops"],
        },
        2: {
            "keywords": ["security-driven", "tactile", "anchoring", "sensory"],
            "code_consider_bias": ["invest in fabrics that feel like emotional anchors", "choose textures that ground you"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["heavyweight knits", "tactile natural fibres"],
        },
        3: {
            "keywords": ["communicative", "approachable", "soft", "expressive"],
            "code_consider_bias": ["dress to feel emotionally approachable", "keep comfort in pieces that move with you"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["soft layering", "relaxed separates"],
        },
        4: {
            "keywords": ["nostalgic", "heirloom", "deeply comforting", "private"],
            "code_consider_bias": ["seek fabrics with nostalgic or heirloom quality", "let comfort be your non-negotiable foundation"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["heirloom knits", "vintage-soft textures"],
        },
        5: {
            "keywords": ["playful", "joyful", "creatively comforting", "expressive"],
            "code_consider_bias": ["let playfulness guide your comfort choices", "choose pieces that spark emotional joy"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["playful comfort layers", "creative knitwear"],
        },
        6: {
            "keywords": ["functional", "nurturing", "routine", "wellness"],
            "code_consider_bias": ["build routines around comfortable daily uniforms", "choose functional fabrics that nurture"],
            "occasion_bias": ["work", "daily"],
            "lean_into_bias": ["functional softness", "care-routine fabrics"],
        },
        7: {
            "keywords": ["harmonious", "partnership", "emotionally balanced", "social"],
            "code_consider_bias": ["dress for emotional harmony in shared spaces", "balance comfort with social grace"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["soft social dressing", "emotionally balanced layers"],
        },
        8: {
            "keywords": ["protective", "layered", "transformative", "hidden"],
            "code_consider_bias": ["use layers as emotional protection", "let comfort be hidden beneath structure"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["protective layering", "transformative comfort"],
        },
        9: {
            "keywords": ["expansive", "travel-ready", "culturally soft", "philosophical"],
            "code_consider_bias": ["seek comfort in pieces that travel well", "let global softness expand your wardrobe"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["travel-friendly comfort", "global-inspired softness"],
        },
        10: {
            "keywords": ["composed", "professional", "calm", "public"],
            "code_consider_bias": ["maintain emotional composure through polished comfort", "choose professional pieces that still feel soft"],
            "occasion_bias": ["work"],
            "lean_into_bias": ["polished comfort", "composed professional layers"],
        },
        11: {
            "keywords": ["community", "belonging", "group-aware", "progressive"],
            "code_consider_bias": ["dress for emotional belonging in groups", "let comfort signal community"],
            "occasion_bias": ["daily"],
            "lean_into_bias": ["community-conscious comfort", "group-friendly softness"],
        },
        12: {
            "keywords": ["private", "retreating", "deeply soft", "solitary"],
            "code_consider_bias": ["save your softest pieces for private moments", "let solitary comfort be a form of self-care"],
            "occasion_bias": ["intimate"],
            "lean_into_bias": ["ultra-soft loungewear", "private retreat fabrics"],
        },
    },
    "sun": {
        1: {"keywords": ["identity", "visible", "direct", "personal"], "code_consider_bias": ["express identity through signature style", "make your first impression count"], "occasion_bias": ["daily"], "lean_into_bias": ["identity-driven dressing", "signature pieces"]},
        2: {"keywords": ["investment", "quality", "self-worth", "enduring"], "code_consider_bias": ["invest in quality that reflects your self-worth", "choose enduring over trendy"], "occasion_bias": ["daily"], "lean_into_bias": ["investment wardrobe", "quality basics"]},
        3: {"keywords": ["communicative", "social", "versatile", "expressive"], "code_consider_bias": ["let style communicate your personality", "keep versatile options ready"], "occasion_bias": ["daily"], "lean_into_bias": ["expressive everyday", "social versatility"]},
        4: {"keywords": ["rooted", "heritage", "nostalgic", "foundational"], "code_consider_bias": ["honour your roots through style choices", "build on foundational pieces"], "occasion_bias": ["intimate"], "lean_into_bias": ["heritage-inspired", "foundational wardrobe"]},
        5: {"keywords": ["creative", "bold", "joyful", "expressive"], "code_consider_bias": ["lead with creative boldness", "let joy fuel your self-expression"], "occasion_bias": ["daily"], "lean_into_bias": ["bold self-expression", "creative confidence"]},
        6: {"keywords": ["disciplined", "functional", "daily", "purposeful"], "code_consider_bias": ["build discipline into daily dressing", "choose purposeful workwear"], "occasion_bias": ["work"], "lean_into_bias": ["purposeful daily wear", "disciplined elegance"]},
        7: {"keywords": ["refined", "social", "balanced", "partnership"], "code_consider_bias": ["refine style through social awareness", "balance personal and shared taste"], "occasion_bias": ["intimate"], "lean_into_bias": ["socially refined", "balanced presentation"]},
        8: {"keywords": ["transformative", "powerful", "strategic", "deep"], "code_consider_bias": ["use style transformation as self-knowledge", "invest in powerful statement pieces"], "occasion_bias": ["intimate"], "lean_into_bias": ["power dressing", "transformative pieces"]},
        9: {"keywords": ["philosophical", "expansive", "global", "adventurous"], "code_consider_bias": ["expand your style vocabulary globally", "dress with philosophical intention"], "occasion_bias": ["daily"], "lean_into_bias": ["globally inspired", "adventurous dressing"]},
        10: {"keywords": ["authoritative", "visible", "career", "public"], "code_consider_bias": ["dress with visible authority", "align wardrobe with career ambitions"], "occasion_bias": ["work", "public"], "lean_into_bias": ["authoritative dressing", "career-aligned style"]},
        11: {"keywords": ["progressive", "communal", "forward", "group"], "code_consider_bias": ["let style reflect progressive values", "dress for community connection"], "occasion_bias": ["daily"], "lean_into_bias": ["progressive style", "community-conscious"]},
        12: {"keywords": ["private", "inner", "spiritual", "contemplative"], "code_consider_bias": ["dress for inner truth, not external approval", "find beauty in contemplative simplicity"], "occasion_bias": ["intimate"], "lean_into_bias": ["contemplative dressing", "private simplicity"]},
    },
    "mars": {
        1: {"keywords": ["assertive", "bold", "direct", "impactful"], "code_consider_bias": ["lead with bold first impressions", "choose impact over subtlety"], "occasion_bias": ["daily"], "lean_into_bias": ["assertive silhouettes", "impact dressing"]},
        2: {"keywords": ["decisive", "quality-aggressive", "forceful", "investing"], "code_consider_bias": ["be decisive about quality investments", "pursue the best aggressively"], "occasion_bias": ["daily"], "lean_into_bias": ["decisive purchasing", "aggressive quality"]},
        3: {"keywords": ["sharp", "communicative", "bold-social", "direct"], "code_consider_bias": ["sharpen your social presence through style", "communicate boldly through dressing"], "occasion_bias": ["daily"], "lean_into_bias": ["sharp social style", "bold communication"]},
        4: {"keywords": ["protective", "fierce", "grounded", "defensive"], "code_consider_bias": ["protect your comfort zone fiercely", "ground your style in strength"], "occasion_bias": ["intimate"], "lean_into_bias": ["protective comfort", "fierce foundations"]},
        5: {"keywords": ["competitive", "daring", "creative", "bold-romantic"], "code_consider_bias": ["take creative style risks confidently", "dare to stand out"], "occasion_bias": ["intimate"], "lean_into_bias": ["daring expression", "competitive creativity"]},
        6: {"keywords": ["driven", "performance", "functional", "aggressive"], "code_consider_bias": ["choose performance-driven daily wear", "let functionality be fierce"], "occasion_bias": ["work"], "lean_into_bias": ["performance workwear", "driven functionality"]},
        7: {"keywords": ["assertive-social", "competitive", "bold-paired", "dynamic"], "code_consider_bias": ["assert yourself through bold pairings", "let competition sharpen your style"], "occasion_bias": ["intimate"], "lean_into_bias": ["bold partnership dressing", "competitive pairing"]},
        8: {"keywords": ["powerful", "strategic", "dark", "magnetic"], "code_consider_bias": ["use strategic restraint for maximum impact", "invest in powerful dark pieces"], "occasion_bias": ["intimate"], "lean_into_bias": ["strategic power", "dark authority"]},
        9: {"keywords": ["adventurous", "daring-global", "exploratory", "bold-travel"], "code_consider_bias": ["dress for adventure without hesitation", "explore bold global styles"], "occasion_bias": ["daily"], "lean_into_bias": ["adventurous boldness", "global daring"]},
        10: {"keywords": ["ambitious", "authoritative", "competitive-public", "driven"], "code_consider_bias": ["dress with ambitious authority", "let career ambition sharpen your image"], "occasion_bias": ["work", "public"], "lean_into_bias": ["ambitious power", "competitive authority"]},
        11: {"keywords": ["galvanising", "activist", "bold-community", "progressive"], "code_consider_bias": ["let your style galvanise your community", "dress with activist intention"], "occasion_bias": ["daily"], "lean_into_bias": ["activist style", "community boldness"]},
        12: {"keywords": ["hidden-strength", "private-power", "fierce-solitary", "internal"], "code_consider_bias": ["keep your strongest pieces for private power", "let inner strength guide quiet choices"], "occasion_bias": ["intimate"], "lean_into_bias": ["private power", "hidden strength"]},
    },
}

for planet in ["venus", "moon", "sun", "mars"]:
    for house in range(1, 13):
        ctx = house_contexts[house]
        ordinal = {1: "st", 2: "nd", 3: "rd"}.get(house, "th")
        entry = {
            "context": f"{planet.title()} in the {house}{ordinal} house: {ctx}",
            "modifier": HOUSE_MODIFIERS_PER_PLANET[planet][house],
        }
        expanded = HOUSE_EXPANDED_DATA.get(planet, {}).get(house, {})
        if "keywords" in expanded:
            entry["keywords"] = expanded["keywords"]
        if "code_consider_bias" in expanded:
            entry["code_consider_bias"] = expanded["code_consider_bias"]
        if "occasion_bias" in expanded:
            entry["occasion_bias"] = expanded["occasion_bias"]
        if "lean_into_bias" in expanded:
            entry["lean_into_bias"] = expanded["lean_into_bias"]
        if "hardware_bias" in expanded:
            entry["hardware_bias"] = expanded["hardware_bias"]
        HOUSE_PLACEMENTS[f"{planet}_house_{house}"] = entry

# ═══════════════════════════════════════════════════════════════
# ELEMENT / MODALITY BALANCE (7 entries)
# ═══════════════════════════════════════════════════════════════

ELEMENT_BALANCE = {
    "fire_dominant": {
        "overall_energy": "bold, warm, expressive, action-oriented",
        "palette_bias": "warm tones, high contrast, reds, oranges, golds",
        "texture_bias": "lightweight, movement-friendly, performance-oriented"
    },
    "earth_dominant": {
        "overall_energy": "grounded, sensory, quality-driven, tactile",
        "palette_bias": "earth tones, warm neutrals, greens, browns, creams",
        "texture_bias": "heavy, natural fibres, tactile richness, substantial weight"
    },
    "air_dominant": {
        "overall_energy": "intellectual, social, versatile, communicative",
        "palette_bias": "light cool tones, pastels, blues, lavenders, varied palette",
        "texture_bias": "lightweight, layered, mixed textures, breathable"
    },
    "water_dominant": {
        "overall_energy": "emotional, intuitive, protective, flowing",
        "palette_bias": "cool deep tones, blues, purples, silvers, iridescent",
        "texture_bias": "flowing, soft, protective layers, fluid drape"
    },
    "cardinal_dominant": {
        "overall_energy": "initiating, leadership-oriented, decisive, fresh",
        "palette_bias": "clean bold colours, decisive palette choices",
        "texture_bias": "crisp, structured, ready-to-go fabrics"
    },
    "fixed_dominant": {
        "overall_energy": "persistent, reliable, quality-focused, enduring",
        "palette_bias": "deep rich colours, reliable palette foundations",
        "texture_bias": "heavy, durable, investment-quality fabrics"
    },
    "mutable_dominant": {
        "overall_energy": "adaptable, versatile, changeable, flowing",
        "palette_bias": "varied shifting palette, seasonal responsiveness",
        "texture_bias": "adaptable, multi-purpose, transitional fabrics"
    }
}

# ═══════════════════════════════════════════════════════════════
# COLOUR LIBRARY (editorial-grade named colours)
# ═══════════════════════════════════════════════════════════════

COLOUR_LIBRARY = {
    # ── Reds & Warm Accents ──
    "bright red": {"hex": "#CC0000", "associations": ["aries", "mars", "fire"]},
    "fire red": {"hex": "#B22222", "associations": ["aries", "mars"]},
    "crimson": {"hex": "#DC143C", "associations": ["mars", "aries", "scorpio"]},
    "hot orange": {"hex": "#FF4500", "associations": ["aries", "leo", "fire"]},
    "coral": {"hex": "#FF6F61", "associations": ["aries", "venus_aries", "venus"]},
    "tangerine": {"hex": "#FF9966", "associations": ["aries", "leo", "fire"]},
    "burnt orange": {"hex": "#CC5500", "associations": ["leo", "fire", "sun"]},
    "warm amber": {"hex": "#FFBF00", "associations": ["leo", "sun", "jupiter"]},
    "warm terracotta": {"hex": "#E2725B", "associations": ["moon_aries", "fire", "leo"]},
    "soft marigold": {"hex": "#E8A317", "associations": ["leo", "venus_virgo", "sun"]},
    "deep burnt saffron": {"hex": "#CC7722", "associations": ["taurus", "venus_taurus", "earth"]},

    # ── Golds & Yellows ──
    "gold": {"hex": "#FFD700", "associations": ["leo", "sun", "jupiter"]},
    "warm gold": {"hex": "#DAA520", "associations": ["leo", "sun"]},
    "dark gold": {"hex": "#B8860B", "associations": ["leo", "saturn"]},
    "molten gold": {"hex": "#B8860B", "associations": ["pluto", "leo"]},
    "soft gold": {"hex": "#DAA520", "associations": ["mars_libra", "libra", "leo"]},
    "oxidised gold": {"hex": "#B08D57", "associations": ["taurus", "venus_taurus", "saturn"]},
    "honey": {"hex": "#EB9605", "associations": ["leo", "venus_virgo", "sun"]},
    "lemon yellow": {"hex": "#FFF44F", "associations": ["gemini", "mercury", "air"]},
    "pale yellow": {"hex": "#FFFF99", "associations": ["gemini", "mercury"]},
    "golden yellow": {"hex": "#FFD700", "associations": ["leo", "mercury"]},
    "bright yellow": {"hex": "#FFD700", "associations": ["mars_gemini", "gemini"]},
    "electric gold": {"hex": "#FFD700", "associations": ["uranus_leo", "leo"]},
    "royal gold": {"hex": "#FFD700", "associations": ["jupiter_aries", "leo"]},
    "champagne gold": {"hex": "#F7E7CE", "associations": ["neptune_leo", "leo"]},
    "rich amber": {"hex": "#FFBF00", "associations": ["leo", "venus_leo"]},

    # ── Whites & Creams ──
    "buttery cream": {"hex": "#FFFDD0", "associations": ["taurus", "venus_taurus", "earth"]},
    "cream": {"hex": "#FFFDD0", "associations": ["taurus", "venus_taurus", "earth"]},
    "warm ivory": {"hex": "#FFFFF0", "associations": ["virgo", "venus_virgo"]},
    "ivory": {"hex": "#FFFFF0", "associations": ["virgo", "venus_virgo"]},
    "warm white": {"hex": "#FAF0E6", "associations": ["aries", "venus_aries", "leo"]},
    "crisp white": {"hex": "#F8F8FF", "associations": ["gemini", "virgo", "air"]},
    "bone white": {"hex": "#F9F6F0", "associations": ["capricorn", "saturn", "virgo"]},
    "stark white": {"hex": "#FFFFFF", "associations": ["aries", "sun_aries"]},
    "pearl white": {"hex": "#F0EAD6", "associations": ["cancer", "moon", "pearl"]},
    "soft white": {"hex": "#FAFAFA", "associations": ["cancer", "moon"]},
    "shell white": {"hex": "#FFF5EE", "associations": ["cancer", "mars_cancer"]},
    "sand": {"hex": "#C2B280", "associations": ["virgo", "venus_virgo", "earth", "leo"]},
    "champagne": {"hex": "#F7E7CE", "associations": ["libra", "venus_libra"]},

    # ── Pinks & Roses ──
    "blush": {"hex": "#DE5D83", "associations": ["cancer", "venus_cancer"]},
    "blush rose": {"hex": "#FFB7C5", "associations": ["pisces", "venus_pisces"]},
    "dusty rose": {"hex": "#DCAE96", "associations": ["libra", "moon_libra", "taurus"]},
    "dusky pink": {"hex": "#CC8899", "associations": ["taurus", "moon_taurus"]},
    "rose pink": {"hex": "#FF66B2", "associations": ["libra", "venus_libra"]},
    "seashell pink": {"hex": "#FFF5EE", "associations": ["cancer", "moon_cancer"]},
    "pastel pink": {"hex": "#FFD1DC", "associations": ["libra", "mercury_libra"]},
    "dream pink": {"hex": "#FFB7C5", "associations": ["neptune", "libra"]},
    "holographic pink": {"hex": "#FF69B4", "associations": ["uranus", "libra"]},
    "dark rose": {"hex": "#B5495B", "associations": ["pluto", "libra"]},
    "crushed berry": {"hex": "#6D2B50", "associations": ["scorpio", "pluto", "mars"]},
    "rose gold tone": {"hex": "#B76E79", "associations": ["jupiter", "libra"]},
    "rose": {"hex": "#FF007F", "associations": ["mars_libra", "libra"]},

    # ── Purples & Mauves ──
    "soft mauve": {"hex": "#E0B0FF", "associations": ["libra", "venus_libra"]},
    "lavender": {"hex": "#E6E6FA", "associations": ["gemini", "neptune", "air"]},
    "soft lavender": {"hex": "#E6E6FA", "associations": ["libra", "moon_libra"]},
    "lilac": {"hex": "#C8A2C8", "associations": ["pisces", "venus_pisces"]},
    "ultraviolet": {"hex": "#6B0099", "associations": ["aquarius", "uranus"]},
    "royal purple": {"hex": "#7851A9", "associations": ["leo", "jupiter"]},
    "deep purple": {"hex": "#4B0082", "associations": ["sagittarius", "mars_sagittarius"]},
    "dark plum": {"hex": "#580F41", "associations": ["scorpio", "venus_scorpio"]},
    "mystic purple": {"hex": "#5C2D91", "associations": ["neptune", "scorpio"]},
    "deep violet": {"hex": "#5B0A91", "associations": ["pluto", "pisces"]},
    "void purple": {"hex": "#36013F", "associations": ["pluto", "aquarius"]},
    "electric violet": {"hex": "#8B00FF", "associations": ["uranus", "aquarius"]},
    "pale violet": {"hex": "#DDA0DD", "associations": ["neptune_pisces", "pisces"]},

    # ── Blues ──
    "sky blue": {"hex": "#87CEEB", "associations": ["gemini", "air"]},
    "powder blue": {"hex": "#B0E0E6", "associations": ["libra", "venus_libra"]},
    "pale blue": {"hex": "#AEC6CF", "associations": ["cancer", "moon_cancer"]},
    "icy blue": {"hex": "#D6ECEF", "associations": ["aquarius", "gemini", "air"]},
    "pale aqua": {"hex": "#ADE8F4", "associations": ["pisces", "venus_pisces"]},
    "cobalt blue": {"hex": "#0047AB", "associations": ["sagittarius", "venus_sagittarius"]},
    "electric blue": {"hex": "#7DF9FF", "associations": ["aquarius", "uranus"]},
    "neon blue": {"hex": "#1B03A3", "associations": ["mars_aquarius", "uranus"]},
    "deep blue": {"hex": "#00008B", "associations": ["sagittarius", "jupiter", "mars_cancer"]},
    "dusk blue": {"hex": "#1B3A5C", "associations": ["scorpio", "capricorn", "saturn"]},
    "cool navy": {"hex": "#003153", "associations": ["gemini", "capricorn", "saturn"]},
    "soft navy": {"hex": "#3B5998", "associations": ["virgo", "venus_virgo"]},
    "navy": {"hex": "#000080", "associations": ["capricorn", "saturn"]},
    "dark navy": {"hex": "#000080", "associations": ["capricorn", "moon_capricorn"]},
    "deep navy": {"hex": "#000080", "associations": ["capricorn", "saturn_sagittarius"]},
    "midnight": {"hex": "#191970", "associations": ["scorpio", "capricorn", "saturn"]},
    "midnight blue": {"hex": "#191970", "associations": ["neptune", "capricorn"]},
    "slate blue": {"hex": "#6A5ACD", "associations": ["capricorn", "saturn_cancer"]},
    "aurora blue": {"hex": "#0077B6", "associations": ["neptune_aquarius", "aquarius"]},
    "sea blue": {"hex": "#006994", "associations": ["mars_pisces", "pisces"]},
    "ocean blue": {"hex": "#006994", "associations": ["jupiter_pisces", "pisces"]},

    # ── Teals & Greens ──
    "deep teal": {"hex": "#008080", "associations": ["sagittarius", "venus_sagittarius"]},
    "dark teal": {"hex": "#004953", "associations": ["scorpio", "moon_scorpio"]},
    "turquoise": {"hex": "#40E0D0", "associations": ["sagittarius", "moon_sagittarius"]},
    "neon teal": {"hex": "#00B5AD", "associations": ["jupiter", "aquarius"]},
    "electric teal": {"hex": "#00FFEF", "associations": ["uranus", "sagittarius"]},
    "bright teal": {"hex": "#008080", "associations": ["jupiter_gemini", "gemini"]},
    "teal": {"hex": "#008080", "associations": ["sagittarius", "venus_sagittarius"]},
    "seafoam": {"hex": "#93E9BE", "associations": ["pisces", "venus_pisces", "water"]},
    "sea glass": {"hex": "#B2D8D8", "associations": ["cancer", "venus_cancer"]},
    "mint": {"hex": "#98FF98", "associations": ["gemini", "moon_gemini"]},
    "neon lime": {"hex": "#CCFF00", "associations": ["aquarius", "venus_aquarius"]},
    "sage green": {"hex": "#9CAF88", "associations": ["taurus", "venus", "earth", "virgo"]},
    "soft sage": {"hex": "#9CAF88", "associations": ["virgo", "venus_virgo", "earth"]},
    "deep sage green": {"hex": "#4A6741", "associations": ["taurus", "venus_taurus", "earth"]},
    "sage": {"hex": "#9CAF88", "associations": ["virgo", "moon_virgo"]},
    "sage mist": {"hex": "#9DC183", "associations": ["neptune_virgo", "virgo"]},
    "muted olive": {"hex": "#6B6B3D", "associations": ["virgo", "earth", "taurus"]},
    "moss green": {"hex": "#8A9A5B", "associations": ["taurus", "moon_taurus"]},
    "cold forest green": {"hex": "#2C5F2D", "associations": ["scorpio", "taurus", "earth"]},
    "forest green": {"hex": "#228B22", "associations": ["taurus", "venus_taurus"]},
    "deep olive": {"hex": "#556B2F", "associations": ["mars_taurus", "earth"]},
    "olive": {"hex": "#808000", "associations": ["mercury_taurus", "earth"]},
    "olive green": {"hex": "#808000", "associations": ["jupiter_virgo", "virgo"]},
    "rich emerald": {"hex": "#046307", "associations": ["jupiter_taurus", "taurus"]},
    "misty green": {"hex": "#8FBC8F", "associations": ["neptune_taurus", "taurus"]},
    "aurora green": {"hex": "#01796F", "associations": ["uranus_pisces", "pisces"]},
    "sea green": {"hex": "#2E8B57", "associations": ["mercury_pisces", "pisces"]},
    "electric green": {"hex": "#00FF00", "associations": ["mars_aquarius", "aquarius"]},

    # ── Browns, Camels & Earth Tones ──
    "sophisticated caramel": {"hex": "#A0722D", "associations": ["taurus", "venus_taurus", "earth"]},
    "warm camel": {"hex": "#C19A6B", "associations": ["taurus", "venus_taurus"]},
    "dark camel": {"hex": "#A0785A", "associations": ["capricorn", "venus_capricorn"]},
    "warm brown": {"hex": "#8B6914", "associations": ["taurus", "earth"]},
    "worn leather": {"hex": "#7B5B3A", "associations": ["taurus", "mars_taurus", "earth"]},
    "dark brown": {"hex": "#3B2F2F", "associations": ["capricorn", "mars_capricorn", "saturn"]},
    "bitter chocolate": {"hex": "#3B1F1F", "associations": ["venus_taurus", "earth", "saturn"]},
    "chocolate": {"hex": "#3B2F2F", "associations": ["venus_taurus", "earth"]},
    "warm ochre": {"hex": "#CC7722", "associations": ["sagittarius", "venus_sagittarius"]},
    "burnt sienna": {"hex": "#E97451", "associations": ["sagittarius", "venus_sagittarius"]},
    "warm sienna": {"hex": "#A0522D", "associations": ["sagittarius", "moon_sagittarius"]},
    "burnished copper": {"hex": "#B87333", "associations": ["leo", "mars_leo", "fire"]},
    "rust": {"hex": "#B7410E", "associations": ["mars_taurus", "earth"]},
    "copper": {"hex": "#B87333", "associations": ["mars_leo", "leo"]},
    "copper tone": {"hex": "#B87333", "associations": ["uranus", "taurus"]},
    "light copper": {"hex": "#D4956A", "associations": ["libra", "venus_libra"]},
    "deep earth": {"hex": "#3B2F2F", "associations": ["pluto_taurus", "earth"]},
    "warm taupe": {"hex": "#8B8589", "associations": ["virgo", "earth"]},
    "peach": {"hex": "#FFDAB9", "associations": ["gemini", "venus_gemini"]},

    # ── Greys & Neutrals ──
    "light grey": {"hex": "#D3D3D3", "associations": ["gemini", "moon_gemini"]},
    "soft grey": {"hex": "#B0B0B0", "associations": ["moon_virgo", "virgo"]},
    "warm grey": {"hex": "#808069", "associations": ["saturn", "cancer"]},
    "stormy grey": {"hex": "#5F6B6D", "associations": ["scorpio", "saturn", "capricorn"]},
    "silver grey": {"hex": "#C0C0C0", "associations": ["aquarius", "venus_aquarius"]},
    "cool silver": {"hex": "#AAA9AD", "associations": ["aquarius", "moon_aquarius"]},
    "steel grey": {"hex": "#71797E", "associations": ["saturn_gemini", "saturn"]},
    "slate": {"hex": "#708090", "associations": ["moon_capricorn", "saturn", "taurus"]},
    "deep charcoal": {"hex": "#333333", "associations": ["capricorn", "saturn", "scorpio"]},
    "stone grey": {"hex": "#928E85", "associations": ["saturn_virgo", "earth"]},
    "mineral grey": {"hex": "#928E85", "associations": ["uranus_virgo", "virgo"]},
    "dark steel": {"hex": "#4A4A4A", "associations": ["uranus_capricorn", "saturn"]},
    "obsidian grey": {"hex": "#3D3D3D", "associations": ["pluto_virgo", "pluto"]},
    "charcoal": {"hex": "#36454F", "associations": ["capricorn", "saturn", "earth"]},
    "dark charcoal": {"hex": "#333333", "associations": ["jupiter_capricorn", "saturn"]},
    "misty grey": {"hex": "#B0B7BF", "associations": ["mars_pisces", "pisces"]},

    # ── Blacks ──
    "shadow": {"hex": "#36454F", "associations": ["scorpio", "venus_scorpio", "saturn"]},
    "ink": {"hex": "#1B1B1B", "associations": ["scorpio", "venus_scorpio", "pluto"]},
    "deep black": {"hex": "#0A0A0A", "associations": ["scorpio", "venus_scorpio", "pluto"]},
    "black": {"hex": "#0A0A0A", "associations": ["scorpio", "moon_scorpio"]},
    "jet black": {"hex": "#0A0A0A", "associations": ["saturn_capricorn", "saturn"]},
    "ink black": {"hex": "#1C1C1C", "associations": ["saturn_scorpio", "pluto"]},
    "abyss black": {"hex": "#050505", "associations": ["pluto_scorpio", "pluto"]},
    "power black": {"hex": "#1C1C1C", "associations": ["pluto_capricorn", "pluto"]},

    # ── Dark Reds & Burgundies ──
    "deep oxblood": {"hex": "#4A0000", "associations": ["scorpio", "venus_scorpio", "pluto", "mars"]},
    "oxblood": {"hex": "#4A0000", "associations": ["scorpio", "pluto", "mars"]},
    "blood red": {"hex": "#660000", "associations": ["mars_scorpio", "scorpio"]},
    "burgundy": {"hex": "#800020", "associations": ["capricorn", "venus_capricorn"]},
    "deep burgundy": {"hex": "#800020", "associations": ["scorpio", "moon_scorpio"]},
    "dark burgundy": {"hex": "#4A0000", "associations": ["saturn_scorpio", "scorpio"]},
    "garnet red": {"hex": "#733635", "associations": ["scorpio", "venus_scorpio"]},
    "deep garnet": {"hex": "#733635", "associations": ["jupiter_scorpio", "scorpio"]},
    "dark red": {"hex": "#8B0000", "associations": ["saturn_aries", "mars"]},
    "deep red": {"hex": "#8B0000", "associations": ["leo", "venus_leo"]},
    "magma red": {"hex": "#8B0000", "associations": ["pluto_aries", "mars"]},
    "brick red": {"hex": "#CB4154", "associations": ["mars_virgo", "earth"]},
    "misty red": {"hex": "#B5495B", "associations": ["neptune_aries", "aries"]},
    "electric red": {"hex": "#FF003C", "associations": ["uranus_aries", "aries"]},
    "clear red": {"hex": "#CC0000", "associations": ["mercury_aries", "aries"]},
    "royal red": {"hex": "#B22222", "associations": ["jupiter_aries", "aries"]},

    # ── Silvers ──
    "silver shimmer": {"hex": "#D8D8D8", "associations": ["pisces", "venus_pisces"]},
    "soft silver": {"hex": "#C0C0C0", "associations": ["cancer", "sun_cancer"]},
    "silver": {"hex": "#C0C0C0", "associations": ["moon", "cancer", "water"]},

    # ── Deep Blues & Indigos ──
    "indigo": {"hex": "#4B0082", "associations": ["moon_sagittarius", "sagittarius"]},
    "deep indigo": {"hex": "#130A4F", "associations": ["pluto_sagittarius", "sagittarius"]},
    "ocean indigo": {"hex": "#4B0082", "associations": ["neptune_sagittarius", "sagittarius"]},
    "deep electric": {"hex": "#1B03A3", "associations": ["uranus_scorpio", "scorpio"]},

    # ── Ocean Tones ──
    "ocean pearl": {"hex": "#E8E0D5", "associations": ["neptune_cancer", "cancer"]},
    "deep sea": {"hex": "#003545", "associations": ["pluto_cancer", "cancer"]},
    "iridescent white": {"hex": "#F0F8FF", "associations": ["uranus_cancer", "cancer"]},

    # ── Warm Accent Singles ──
    "sunset orange": {"hex": "#FF6347", "associations": ["moon_leo", "leo"]},
    "wheat": {"hex": "#F5DEB3", "associations": ["virgo", "venus_virgo"]},
    "neon yellow": {"hex": "#CCFF00", "associations": ["uranus_gemini", "gemini"]},
    "lemon": {"hex": "#FFF44F", "associations": ["mercury_gemini", "gemini"]},
    "pearl": {"hex": "#F0EAD6", "associations": ["cancer", "moon"]},
}

# ═══════════════════════════════════════════════════════════════
# ASSEMBLY
# ═══════════════════════════════════════════════════════════════

def build_dataset():
    planet_sign = {}
    planet_sign.update(VENUS_ENTRIES)
    planet_sign.update(MOON_ENTRIES)
    planet_sign.update(SUN_ENTRIES)
    planet_sign.update(MARS_ENTRIES)
    planet_sign.update(ASC_ENTRIES)
    planet_sign.update(SATURN_ENTRIES)
    planet_sign.update(OUTER_ENTRIES)

    dataset = {
        "planet_sign": planet_sign,
        "aspects": ASPECTS,
        "house_placements": HOUSE_PLACEMENTS,
        "element_balance": ELEMENT_BALANCE,
        "colour_library": COLOUR_LIBRARY
    }
    return dataset


def validate_dataset(dataset):
    """Enforce quality minimums across the dataset."""
    warnings = []

    for key, entry in dataset["planet_sign"].items():
        planet = key.split("_")[0]

        min_words = DIRECTIVE_MIN_WORDS.get(planet, 8)
        for field in ["code_leaninto", "code_avoid", "code_consider"]:
            for item in entry.get(field, []):
                wc = len(item.split())
                if wc < min_words:
                    warnings.append(
                        f"[{key}] {field}: \"{item[:60]}...\" is {wc} words (min {min_words})"
                    )

        min_lean, min_avoid, min_consider = DIRECTIVE_MIN_COUNTS.get(planet, (3, 2, 1))
        actual_lean = len(entry.get("code_leaninto", []))
        actual_avoid = len(entry.get("code_avoid", []))
        actual_consider = len(entry.get("code_consider", []))
        if actual_lean < min_lean:
            warnings.append(f"[{key}] code_leaninto: {actual_lean} items (min {min_lean})")
        if actual_avoid < min_avoid:
            warnings.append(f"[{key}] code_avoid: {actual_avoid} items (min {min_avoid})")
        if actual_consider < min_consider:
            warnings.append(f"[{key}] code_consider: {actual_consider} items (min {min_consider})")

        generic_nouns = {
            "texture", "textures", "pattern", "patterns", "print",
            "prints", "motif", "motifs", "detail", "details",
            "solid", "solids",
        }
        vague_modifiers = {
            "organic", "tonal", "subtle", "mixed", "various", "simple",
            "micro", "sporty", "athletic", "dark", "global",
            "conversational", "statement", "graphic", "symmetrical",
            "futuristic", "diverse", "architectural", "military",
            "precise", "oversized", "bold", "spiritual", "utopian",
            "collective", "systemic", "power", "deep",
        }
        for ptype in ["recommended", "avoid"]:
            items_lower = [i.lower() for i in entry.get("patterns", {}).get(ptype, [])]
            for item in entry.get("patterns", {}).get(ptype, []):
                words = item.lower().split()
                if len(words) == 1 and words[0] in generic_nouns:
                    warnings.append(
                        f"[{key}] patterns.{ptype}: \"{item}\" is a bare generic noun"
                    )
                if (
                    ptype == "recommended"
                    and len(words) == 2
                    and words[-1] in generic_nouns
                    and words[0] in vague_modifiers
                ):
                    warnings.append(
                        f"[{key}] patterns.{ptype}: \"{item}\" is vague (modifier + generic noun)"
                    )
            if len(items_lower) != len(set(items_lower)):
                warnings.append(f"[{key}] patterns.{ptype}: contains duplicates")
        rec_set = {i.lower() for i in entry.get("patterns", {}).get("recommended", [])}
        avo_set = {i.lower() for i in entry.get("patterns", {}).get("avoid", [])}
        pat_overlap = rec_set & avo_set
        if pat_overlap:
            warnings.append(f"[{key}] patterns recommended ∩ avoid: {pat_overlap}")

        for field in ["code_leaninto", "code_avoid", "code_consider"]:
            items = [i.lower() for i in entry.get(field, [])]
            if len(items) != len(set(items)):
                warnings.append(f"[{key}] {field}: contains duplicates")

        lean_set = {i.lower() for i in entry.get("code_leaninto", [])}
        avoid_set = {i.lower() for i in entry.get("code_avoid", [])}
        overlap = lean_set & avoid_set
        if overlap:
            warnings.append(f"[{key}] lean_into ∩ avoid: {overlap}")

    return warnings


if __name__ == "__main__":
    dataset = build_dataset()

    # Validation counts
    ps_count = len(dataset["planet_sign"])
    asp_count = len(dataset["aspects"])
    hp_count = len(dataset["house_placements"])
    eb_count = len(dataset["element_balance"])
    cl_count = len(dataset["colour_library"])

    print(f"planet_sign:      {ps_count} entries (expected 132)")
    print(f"aspects:          {asp_count} entries (expected ~30)")
    print(f"house_placements: {hp_count} entries (expected 48)")
    print(f"element_balance:  {eb_count} entries (expected 7)")
    print(f"colour_library:   {cl_count} entries (expected 180+)")

    if ps_count != 132:
        print(f"\nWARNING: Expected 132 planet_sign entries, got {ps_count}")
        expected_keys = set()
        for body in BODIES:
            for sign in SIGNS:
                expected_keys.add(f"{body}_{sign}")
        actual_keys = set(dataset["planet_sign"].keys())
        missing = expected_keys - actual_keys
        extra = actual_keys - expected_keys
        if missing:
            print(f"  Missing: {sorted(missing)}")
        if extra:
            print(f"  Extra: {sorted(extra)}")

    # Quality validation
    warnings = validate_dataset(dataset)
    if warnings:
        print(f"\n⚠ {len(warnings)} quality warning(s):")
        for w in warnings:
            print(f"  {w}")
    else:
        print("\n✓ Quality gate passed — zero warnings")

    output_path = "astrological_style_dataset.json"
    with open(output_path, "w") as f:
        json.dump(dataset, f, indent=2, ensure_ascii=False)
    print(f"\nWritten to {output_path}")
