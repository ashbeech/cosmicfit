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
                {"name": "bright red", "hex": "#CC0000"}
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
            "recommended": ["bold stripes", "colour blocking", "athletic details", "graphic prints"],
            "avoid": ["tiny florals", "paisley", "fussy prints"]
        },
        "silhouette_keywords": ["sharp shoulders", "cropped", "streamlined", "athletic cut"],
        "occasion_modifiers": {
            "work": "decisive, sharp, no-nonsense power dressing",
            "intimate": "direct, warm, confident minimalism",
            "daily": "athletic, purposeful, ready to move"
        },
        "code_leaninto": ["first impressions matter, dress for impact", "bold colour over safe neutral", "one hero piece per outfit", "movement-friendly silhouettes"],
        "code_avoid": ["anything that requires fussing or adjusting", "overly delicate pieces", "complicated layering systems"],
        "code_consider": ["one statement piece rather than layered complexity", "sportswear details in elevated fabrics"],
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
                {"name": "cream", "hex": "#FFFDD0"},
                {"name": "forest green", "hex": "#228B22"},
                {"name": "warm camel", "hex": "#C19A6B"}
            ],
            "accent": [
                {"name": "dusty rose", "hex": "#DCAE96"},
                {"name": "chocolate", "hex": "#3B2F2F"}
            ],
            "avoid": ["neon shades", "harsh electric tones"]
        },
        "metals": ["yellow gold", "rose gold", "warm bronze"],
        "stones": ["emerald", "rose quartz", "jade"],
        "patterns": {
            "recommended": ["subtle herringbone", "organic textures", "tonal knits", "classic plaid"],
            "avoid": ["aggressive graphics", "neon prints", "overly busy patterns"]
        },
        "silhouette_keywords": ["draped", "relaxed structure", "body-conscious", "wrap details"],
        "occasion_modifiers": {
            "work": "polished but comfortable, investment pieces that command respect",
            "intimate": "sensual, touchable fabrics, warm tones that invite closeness",
            "daily": "effortless luxury, well-made basics that feel expensive"
        },
        "code_leaninto": ["invest in fewer, better pieces", "touch before you buy, texture is everything", "natural fibres over synthetics", "warm neutrals as your foundation"],
        "code_avoid": ["cheap fast fashion", "anything that does not feel good against skin", "harsh synthetic fabrics"],
        "code_consider": ["building a capsule wardrobe of quality staples", "seasonal fabric rotation"],
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
                {"name": "sky blue", "hex": "#87CEEB"}
            ],
            "accent": [
                {"name": "peach", "hex": "#FFDAB9"},
                {"name": "lavender", "hex": "#E6E6FA"}
            ],
            "avoid": ["all-black monotone", "dark sombre palettes"]
        },
        "metals": ["mixed metals", "sterling silver", "white gold"],
        "stones": ["citrine", "aquamarine", "agate"],
        "patterns": {
            "recommended": ["mixed prints", "conversational patterns", "stripes with florals", "geometric mix"],
            "avoid": ["uniform solids", "heavy tartans", "single-pattern monotony"]
        },
        "silhouette_keywords": ["layered", "convertible", "asymmetric", "modular"],
        "occasion_modifiers": {
            "work": "smart and interesting, pieces that start conversations",
            "intimate": "playful, unexpected combinations that keep things fresh",
            "daily": "mix-and-match layers, never the same outfit twice"
        },
        "code_leaninto": ["mix high and low pieces", "embrace pattern clashing with intention", "accessories that double as conversation starters", "reversible and dual-purpose pieces"],
        "code_avoid": ["rigid matching sets", "head-to-toe uniform looks", "one-note dressing"],
        "code_consider": ["a signature accessory that changes daily", "colour pops in unexpected places"],
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
                {"name": "pale blue", "hex": "#AEC6CF"}
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
        "code_leaninto": ["invest in comfort that still looks intentional", "soft layers over hard structure", "heirloom-quality pieces worth passing down", "pieces with personal history or vintage finds"],
        "code_avoid": ["cold austere minimalism", "overly aggressive silhouettes", "anything that feels emotionally detached"],
        "code_consider": ["a signature comfort layer like a heritage cardigan", "mixing vintage with modern basics"],
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
                {"name": "burnt orange", "hex": "#CC5500"}
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
            "avoid": ["subtle minimalist patterns", "tiny ditsy prints", "wallflower designs"]
        },
        "silhouette_keywords": ["structured shoulder", "fitted waist", "dramatic proportion", "statement sleeve"],
        "occasion_modifiers": {
            "work": "boardroom glamour, polished authority with undeniable presence",
            "intimate": "warm, generous, luxurious fabrics that reward attention",
            "daily": "elevated casual, even basics have a golden warmth"
        },
        "code_leaninto": ["dress like the lead in your own film", "one statement piece that stops the room", "warm metals and rich textures always", "confidence is the best accessory, wear it loudly"],
        "code_avoid": ["deliberately dressing down", "disappearing into safe neutrals", "apologetic fashion choices"],
        "code_consider": ["a signature gold accessory that becomes your trademark", "mixing textures for depth"],
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
                {"name": "sage green", "hex": "#9CAF88"},
                {"name": "warm taupe", "hex": "#8B8589"},
                {"name": "ivory", "hex": "#FFFFF0"}
            ],
            "accent": [
                {"name": "soft navy", "hex": "#3B5998"},
                {"name": "wheat", "hex": "#F5DEB3"}
            ],
            "avoid": ["loud clashing colours", "garish prints", "neon tones"]
        },
        "metals": ["brushed silver", "white gold", "matte platinum"],
        "stones": ["peridot", "amazonite", "moss agate"],
        "patterns": {
            "recommended": ["fine pinstripe", "subtle check", "micro-pattern", "tonal texture"],
            "avoid": ["loud graphics", "chaotic prints", "oversized logos"]
        },
        "silhouette_keywords": ["tailored", "clean line", "precise fit", "uncluttered"],
        "occasion_modifiers": {
            "work": "impeccably groomed, the person whose outfit always looks right",
            "intimate": "understated sensuality, clean lines that reveal through precision",
            "daily": "polished even in casual, every detail considered"
        },
        "code_leaninto": ["quality tailoring over quantity", "details matter, a perfect hem, a clean press", "neutral foundations with one subtle point of interest", "invest in alterations"],
        "code_avoid": ["visible logos and branding", "wrinkled or creased presentations", "anything that looks hasty or unconsidered"],
        "code_consider": ["a signature wardrobe maintenance ritual", "tonal dressing with texture variation"],
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
                {"name": "light copper", "hex": "#D4956A"}
            ],
            "avoid": ["harsh primaries", "aggressive neons", "stark black-and-white contrast"]
        },
        "metals": ["rose gold", "polished copper", "soft gold"],
        "stones": ["rose quartz", "kunzite", "pink tourmaline"],
        "patterns": {
            "recommended": ["art deco motifs", "symmetrical prints", "elegant stripes", "balanced geometric"],
            "avoid": ["chaotic abstract", "aggressive asymmetry", "clashing prints"]
        },
        "silhouette_keywords": ["balanced proportion", "cinched waist", "flowing hem", "symmetrical detail"],
        "occasion_modifiers": {
            "work": "diplomatic elegance, polished without being intimidating",
            "intimate": "graceful, romantic, harmonious beauty that draws people in",
            "daily": "effortlessly put together, looking good without trying too hard"
        },
        "code_leaninto": ["proportional dressing, balance top and bottom", "soft colour stories that feel cohesive", "elegant simplicity over dramatic statement", "invest in pieces that transition day to evening"],
        "code_avoid": ["deliberately jarring combinations", "aggressive power dressing", "anything that feels confrontational"],
        "code_consider": ["a rotating collection of beautiful scarves or shawls", "colour harmony charts for outfit planning"],
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
                {"name": "oxblood", "hex": "#4A0000"},
                {"name": "deep black", "hex": "#0A0A0A"}
            ],
            "accent": [
                {"name": "dark plum", "hex": "#580F41"},
                {"name": "garnet red", "hex": "#733635"}
            ],
            "avoid": ["candy pastels", "cheerful brights", "anything see-through"]
        },
        "metals": ["blackened silver", "gunmetal", "oxidised steel"],
        "stones": ["black onyx", "garnet", "obsidian", "smoky quartz"],
        "patterns": {
            "recommended": ["subtle texture patterns", "dark-on-dark jacquard", "pinstripe", "monochromatic tone-on-tone"],
            "avoid": ["cheerful florals", "bright gingham", "whimsical prints"]
        },
        "silhouette_keywords": ["fitted", "elongated", "high neckline", "strategic exposure"],
        "occasion_modifiers": {
            "work": "quiet power, the person everyone notices but nobody can read",
            "intimate": "controlled intensity, revealing through subtraction not addition",
            "daily": "dark, purposeful, armour that moves"
        },
        "code_leaninto": ["invest in dark foundations", "one strategically placed point of exposure", "let the cut speak louder than the colour", "quality leather as a wardrobe backbone"],
        "code_avoid": ["transparent or overly revealing pieces", "cheerful happy prints", "anything that feels naive or unguarded"],
        "code_consider": ["dark layering for depth rather than colour variety", "matte vs shine contrast within monochrome"],
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
                {"name": "burnt sienna", "hex": "#E97451"}
            ],
            "accent": [
                {"name": "deep teal", "hex": "#008080"},
                {"name": "warm ochre", "hex": "#CC7722"}
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
        "code_leaninto": ["collect pieces from your travels", "mix cultural references with confidence", "layer for versatility not just warmth", "durability over delicacy"],
        "code_avoid": ["rigid dress codes", "overly precious clothing", "anything that restricts movement"],
        "code_consider": ["a signature travel piece that tells a story", "versatile layer combinations for climate shifts"],
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
                {"name": "charcoal", "hex": "#36454F"},
                {"name": "navy", "hex": "#000080"},
                {"name": "dark camel", "hex": "#A0785A"}
            ],
            "accent": [
                {"name": "burgundy", "hex": "#800020"},
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
        "code_leaninto": ["build a wardrobe that appreciates like an investment", "dark foundations with quality accents", "tailoring is non-negotiable", "timeless over trendy every single time"],
        "code_avoid": ["fast fashion impulse buys", "trend-chasing at the expense of quality", "anything you will not wear in five years"],
        "code_consider": ["cost-per-wear calculations before purchasing", "seasonal wardrobe audits"],
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
                {"name": "silver grey", "hex": "#C0C0C0"}
            ],
            "accent": [
                {"name": "ultraviolet", "hex": "#6B0099"},
                {"name": "neon lime", "hex": "#CCFF00"}
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
        "code_leaninto": ["wear what nobody else is wearing", "sustainable and ethical as a style statement", "mix eras and genres freely", "technology-integrated accessories"],
        "code_avoid": ["following trends because everyone else does", "conventional matching rules", "safe predictable combinations"],
        "code_consider": ["vintage tech mixed with modern minimalism", "one deliberately unexpected element per outfit"],
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
                {"name": "blush rose", "hex": "#FFB7C5"}
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
        "code_leaninto": ["embrace the flowing and the romantic", "layer sheer over opaque for depth", "let garments move with your body", "colour stories that feel like watercolour paintings"],
        "code_avoid": ["harsh structured power suits", "aggressive angular silhouettes", "anything that feels militaristic"],
        "code_consider": ["a signature flowing layer, a scarf, a wrap, a kimono", "soft colour gradients within one outfit"],
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
            "accent": [{"name": "ivory", "hex": "#FFFFF0"}],
            "avoid": ["cold greys", "depressing neutrals"]
        },
        "metals": ["rose gold", "polished copper"],
        "stones": ["carnelian", "ruby", "red agate"],
        "patterns": {"recommended": ["bold colour blocks", "racing stripes", "chevron"], "avoid": ["dainty florals", "fussy prints"]},
        "silhouette_keywords": ["athletic", "streamlined", "movement-friendly"],
        "occasion_modifiers": {"work": "energetic and decisive", "intimate": "bold and direct warmth", "daily": "grab-and-go ease"},
        "code_leaninto": ["keep it simple and fast to put on", "comfort that still looks sharp", "one bold piece per outfit"],
        "code_avoid": ["complicated getting-ready routines", "fragile fabrics that need babying"],
        "code_consider": ["activewear-inspired details in real clothes"],
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
            "primary": [{"name": "warm brown", "hex": "#8B6914"}, {"name": "moss green", "hex": "#8A9A5B"}],
            "accent": [{"name": "cream", "hex": "#FFFDD0"}, {"name": "dusky pink", "hex": "#CC8899"}],
            "avoid": ["jarring neons", "cold clinical palettes"]
        },
        "metals": ["yellow gold", "warm bronze"],
        "stones": ["emerald", "rose quartz", "malachite"],
        "patterns": {"recommended": ["soft plaid", "organic texture", "tonal knit"], "avoid": ["harsh graphics", "chaotic prints"]},
        "silhouette_keywords": ["relaxed", "enveloping", "generous cut"],
        "occasion_modifiers": {"work": "quietly luxurious presence", "intimate": "enveloping warmth and tactile pleasure", "daily": "well-made comfort that looks effortless"},
        "code_leaninto": ["softness is not weakness, it is a power move", "invest in loungewear that makes you feel wealthy", "natural materials against skin"],
        "code_avoid": ["anything scratchy or uncomfortable", "trend pieces that sacrifice comfort"],
        "code_consider": ["a beautiful dressing gown as a wardrobe essential"],
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
            "primary": [{"name": "pale yellow", "hex": "#FFFF99"}, {"name": "light grey", "hex": "#D3D3D3"}],
            "accent": [{"name": "mint", "hex": "#98FF98"}, {"name": "peach", "hex": "#FFDAB9"}],
            "avoid": ["heavy dark monotone"]
        },
        "metals": ["mixed metals", "sterling silver"],
        "stones": ["agate", "citrine", "alexandrite"],
        "patterns": {"recommended": ["mixed patterns", "stripes", "conversational prints"], "avoid": ["single heavy pattern", "monotone solids"]},
        "silhouette_keywords": ["convertible", "layered", "dual-purpose"],
        "occasion_modifiers": {"work": "clever and engaging presence", "intimate": "animated and unpredictable", "daily": "ever-changing daily moods reflected in clothes"},
        "code_leaninto": ["have multiple outfit options ready", "layers you can add or remove", "variety keeps you emotionally stable"],
        "code_avoid": ["the same outfit every day", "rigid capsule rules that bore you"],
        "code_consider": ["a capsule that has surprise built in"],
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
        "code_leaninto": ["clothes with emotional history", "soft protective layers", "comfort as a daily non-negotiable"],
        "code_avoid": ["anything emotionally cold or sterile", "harsh fabric against skin"],
        "code_consider": ["a comfort garment you return to when the world is too much"],
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
            "accent": [{"name": "champagne", "hex": "#F7E7CE"}],
            "avoid": ["drab earth tones", "invisible neutrals"]
        },
        "metals": ["yellow gold", "gilded bronze"],
        "stones": ["amber", "sunstone", "golden topaz"],
        "patterns": {"recommended": ["bold florals", "medallion motifs", "sun-inspired"], "avoid": ["plain solids", "wallflower prints"]},
        "silhouette_keywords": ["dramatic", "fitted waist", "statement"],
        "occasion_modifiers": {"work": "warm authority, the inspiring leader", "intimate": "generous and dramatic warmth", "daily": "effortless glamour, even in loungewear"},
        "code_leaninto": ["wear what makes you feel like the star", "warm tones close to your face", "one piece of drama per outfit"],
        "code_avoid": ["deliberately dressing down to fit in", "dull invisible clothing"],
        "code_consider": ["a signature warm-tone accessory"],
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
            "primary": [{"name": "soft grey", "hex": "#B0B0B0"}, {"name": "sage", "hex": "#9CAF88"}],
            "accent": [{"name": "wheat", "hex": "#F5DEB3"}],
            "avoid": ["messy tie-dye", "chaotic colour combinations"]
        },
        "metals": ["brushed silver", "matte white gold"],
        "stones": ["peridot", "clear quartz", "amazonite"],
        "patterns": {"recommended": ["micro-check", "fine stripe", "tonal texture"], "avoid": ["loud graphics", "chaotic prints"]},
        "silhouette_keywords": ["clean", "fitted", "uncluttered"],
        "occasion_modifiers": {"work": "immaculate and reliable", "intimate": "quietly elegant attention to detail", "daily": "pressed and tidy even on rest days"},
        "code_leaninto": ["ironing is a form of self-care", "minimalist wardrobe, maximum polish", "everything in its place"],
        "code_avoid": ["visible wrinkles or stains", "chaotic layering"],
        "code_consider": ["a weekly wardrobe prep session"],
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
        "patterns": {"recommended": ["symmetrical motifs", "balanced stripes", "art nouveau"], "avoid": ["jarring asymmetry", "aggressive patterns"]},
        "silhouette_keywords": ["balanced", "graceful", "symmetrical"],
        "occasion_modifiers": {"work": "elegant diplomatic presence", "intimate": "harmonious and inviting", "daily": "aesthetically pleasing without effort"},
        "code_leaninto": ["beauty is an emotional need, honour it", "balanced outfits keep your mood level", "invest in aesthetically pleasing basics"],
        "code_avoid": ["ugly-on-purpose fashion", "aggressively mismatched outfits"],
        "code_consider": ["colour palette planning for the week ahead"],
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
            "primary": [{"name": "deep burgundy", "hex": "#800020"}, {"name": "black", "hex": "#0A0A0A"}],
            "accent": [{"name": "dark teal", "hex": "#004953"}],
            "avoid": ["pastel pinks", "cheerful yellows"]
        },
        "metals": ["blackened silver", "gunmetal"],
        "stones": ["obsidian", "smoky quartz", "black tourmaline"],
        "patterns": {"recommended": ["dark-on-dark texture", "subtle jacquard", "monochrome depth"], "avoid": ["cheerful prints", "bright florals"]},
        "silhouette_keywords": ["controlled", "fitted", "concealing", "high-necked"],
        "occasion_modifiers": {"work": "intimidating competence", "intimate": "intense and selective vulnerability", "daily": "dark comfortable armour"},
        "code_leaninto": ["control what others see of you", "dark layers as emotional protection", "quality over visibility"],
        "code_avoid": ["anything that makes you feel emotionally exposed", "transparent or flimsy fabrics"],
        "code_consider": ["a black wardrobe with tonal depth variation"],
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
        "patterns": {"recommended": ["global prints", "ikat", "oversized abstract"], "avoid": ["corporate patterns", "fussy small prints"]},
        "silhouette_keywords": ["relaxed", "layered", "movement-ready"],
        "occasion_modifiers": {"work": "worldly and inspiring", "intimate": "warm and adventurous", "daily": "packed for anywhere, ready for anything"},
        "code_leaninto": ["clothes that can handle a spontaneous trip", "layering for unpredictable days", "pieces with stories attached"],
        "code_avoid": ["anything that restricts spontaneity", "fussy high-maintenance pieces"],
        "code_consider": ["a travel capsule that works across climates"],
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
            "primary": [{"name": "slate", "hex": "#708090"}, {"name": "charcoal", "hex": "#36454F"}],
            "accent": [{"name": "dark navy", "hex": "#000080"}],
            "avoid": ["frivolous pastels", "whimsical brights"]
        },
        "metals": ["polished silver", "platinum"],
        "stones": ["garnet", "onyx", "jet"],
        "patterns": {"recommended": ["classic check", "herringbone", "pinstripe"], "avoid": ["novelty prints", "childish patterns"]},
        "silhouette_keywords": ["structured", "clean", "authoritative"],
        "occasion_modifiers": {"work": "the definition of professional", "intimate": "controlled elegance behind closed doors", "daily": "structured even in leisure"},
        "code_leaninto": ["structure is emotionally stabilising", "dark reliable foundations", "quality basics that last"],
        "code_avoid": ["clothes that feel unserious", "sloppy casual that undermines your composure"],
        "code_consider": ["a uniform approach to dressing, consistent and reliable"],
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
        "patterns": {"recommended": ["digital abstract", "futuristic print", "circuit motifs"], "avoid": ["traditional florals", "heritage prints"]},
        "silhouette_keywords": ["architectural", "unconventional", "forward-looking"],
        "occasion_modifiers": {"work": "the innovator in the room", "intimate": "intellectually stimulating presence", "daily": "wearable individuality"},
        "code_leaninto": ["be the person nobody can categorise", "comfort in standing apart", "innovation as self-care"],
        "code_avoid": ["blending in for safety", "conventional matching rules"],
        "code_consider": ["one conversation-starting piece daily"],
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
        "code_leaninto": ["dress by feeling, not formula", "soft layers that respond to mood", "sea-inspired tones for emotional grounding"],
        "code_avoid": ["rigid dress codes that ignore emotional state", "harsh structured formality"],
        "code_consider": ["a flowing piece that feels like a comfort blanket"],
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
        "code_leaninto": ["lead with colour", "one bold statement piece", "confidence is the best accessory"],
        "code_avoid": ["blending into the background", "overthinking outfits"], "code_consider": ["a power colour signature"],
        "opposites": {"textures": ["heavy brocade", "fussy lace"], "colours": ["muddy neutrals", "washed-out tones"], "silhouettes": ["shapeless drape", "indecisive layers"], "mood": ["passive", "indecisive", "meek"]}
    },
    "sun_taurus": {
        "style_philosophy": "luxurious, grounded, sensory-driven identity",
        "textures": {"good": ["cashmere", "suede", "heavy cotton", "buttery leather", "brushed wool"], "bad": ["cheap polyester", "scratchy acrylic"], "sweet_spot_keywords": ["quality", "touch", "substance"]},
        "colours": {"primary": [{"name": "sage green", "hex": "#9CAF88"}, {"name": "warm brown", "hex": "#8B6914"}], "accent": [{"name": "blush", "hex": "#DE5D83"}], "avoid": ["jarring neons"]},
        "metals": ["yellow gold", "warm bronze"], "stones": ["emerald", "lapis lazuli", "jade"],
        "patterns": {"recommended": ["organic texture", "herringbone", "tonal weave"], "avoid": ["chaotic graphics", "aggressive prints"]},
        "silhouette_keywords": ["relaxed structure", "body-conscious", "grounded"],
        "occasion_modifiers": {"work": "quietly luxurious authority", "intimate": "sensually inviting", "daily": "comfortable quality"},
        "code_leaninto": ["quality over quantity always", "natural fibres as a rule", "earth tones as a foundation"],
        "code_avoid": ["disposable fashion", "trend-chasing at quality's expense"], "code_consider": ["seasonal fabric rituals"],
        "opposites": {"textures": ["cheap polyester", "scratchy acrylic"], "colours": ["jarring neons"], "silhouettes": ["angular aggressive cuts", "stiff uncomfortable shapes"], "mood": ["rushed", "disposable", "abrasive"]}
    },
    "sun_gemini": {
        "style_philosophy": "versatile, intellectually playful, dual-natured",
        "textures": {"good": ["lightweight blends", "crisp shirting", "jersey", "reversible fabrics"], "bad": ["heavy monotone wool", "stiff formal"], "sweet_spot_keywords": ["adaptability", "conversation", "variety"]},
        "colours": {"primary": [{"name": "lemon yellow", "hex": "#FFF44F"}, {"name": "sky blue", "hex": "#87CEEB"}], "accent": [{"name": "tangerine", "hex": "#FF9966"}], "avoid": ["single-colour monotone"]},
        "metals": ["mixed metals", "white gold"], "stones": ["citrine", "aquamarine", "agate"],
        "patterns": {"recommended": ["mixed prints", "colour blocking", "conversational motifs"], "avoid": ["single uniform patterns"]},
        "silhouette_keywords": ["layered", "modular", "transformable"],
        "occasion_modifiers": {"work": "clever and engaging", "intimate": "playful and surprising", "daily": "never the same outfit twice"},
        "code_leaninto": ["embrace the mix", "versatility over consistency", "interest in every outfit"],
        "code_avoid": ["boring repetition", "rigid dress codes"], "code_consider": ["daily outfit rotation systems"],
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
        "code_leaninto": ["clothes with emotional significance", "layering for emotional armour", "vintage finds with history"],
        "code_avoid": ["emotionally cold fashion", "harsh uncomfortable fabrics"], "code_consider": ["a comfort piece for hard days"],
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
        "code_leaninto": ["be the most memorable person in the room", "warm metals always", "drama is a compliment"],
        "code_avoid": ["deliberately fading into the background", "dull invisible clothing"], "code_consider": ["a signature gold piece"],
        "opposites": {"textures": ["dull matte fabrics", "cheap materials"], "colours": ["drab beige", "faded neutrals"], "silhouettes": ["deliberately invisible cuts", "shapeless drape"], "mood": ["invisible", "dimmed", "unnoticed"]}
    },
    "sun_virgo": {
        "style_philosophy": "refined, meticulous, quietly perfect",
        "textures": {"good": ["fine-gauge knit", "polished cotton", "crisp linen", "smooth silk"], "bad": ["wrinkled fabrics", "pilling knits"], "sweet_spot_keywords": ["precision", "cleanliness", "detail"]},
        "colours": {"primary": [{"name": "warm taupe", "hex": "#8B8589"}, {"name": "sage green", "hex": "#9CAF88"}], "accent": [{"name": "soft navy", "hex": "#3B5998"}], "avoid": ["loud clashing tones"]},
        "metals": ["brushed silver", "white gold"], "stones": ["peridot", "sapphire", "amazonite"],
        "patterns": {"recommended": ["micro-pattern", "fine stripe", "tonal texture"], "avoid": ["chaotic prints", "oversized logos"]},
        "silhouette_keywords": ["precise", "clean", "tailored"],
        "occasion_modifiers": {"work": "the standard of professionalism", "intimate": "detail-oriented elegance", "daily": "polished even in casual"},
        "code_leaninto": ["perfect fit over perfect trend", "details others miss", "neutral excellence"],
        "code_avoid": ["visible sloppiness", "wrinkled presentations"], "code_consider": ["a tailor on speed dial"],
        "opposites": {"textures": ["wrinkled fabrics", "pilling knits"], "colours": ["loud clashing tones"], "silhouettes": ["sloppy oversized", "messy deconstruction"], "mood": ["sloppy", "careless", "chaotic"]}
    },
    "sun_libra": {
        "style_philosophy": "harmonious, aesthetically driven, socially graceful",
        "textures": {"good": ["flowing silk", "soft wool", "fine cotton", "lightweight cashmere"], "bad": ["rough industrial fabrics", "stiff canvas"], "sweet_spot_keywords": ["elegance", "balance", "beauty"]},
        "colours": {"primary": [{"name": "rose pink", "hex": "#FF66B2"}, {"name": "powder blue", "hex": "#B0E0E6"}], "accent": [{"name": "champagne", "hex": "#F7E7CE"}], "avoid": ["harsh primaries", "aggressive neons"]},
        "metals": ["rose gold", "copper"], "stones": ["rose quartz", "opal", "pink tourmaline"],
        "patterns": {"recommended": ["art deco", "symmetrical prints", "elegant stripe"], "avoid": ["chaotic abstract", "aggressive asymmetry"]},
        "silhouette_keywords": ["balanced", "proportional", "graceful"],
        "occasion_modifiers": {"work": "diplomatically elegant", "intimate": "romantically harmonious", "daily": "effortlessly beautiful"},
        "code_leaninto": ["proportion over volume", "colour harmony in every outfit", "beauty as identity"],
        "code_avoid": ["deliberately jarring combinations", "aggressive dressing"], "code_consider": ["a palette planner for weekly outfits"],
        "opposites": {"textures": ["rough industrial fabrics", "stiff canvas"], "colours": ["harsh primaries", "aggressive neons"], "silhouettes": ["aggressively asymmetric", "confrontational shapes"], "mood": ["aggressive", "confrontational", "discordant"]}
    },
    "sun_scorpio": {
        "style_philosophy": "intense, magnetic, strategically powerful",
        "textures": {"good": ["structured leather", "dense knit", "heavy silk", "matte jersey"], "bad": ["frilly chiffon", "cute prints", "flimsy fabrics"], "sweet_spot_keywords": ["power", "control", "intensity"]},
        "colours": {"primary": [{"name": "deep black", "hex": "#0A0A0A"}, {"name": "oxblood", "hex": "#4A0000"}], "accent": [{"name": "dark plum", "hex": "#580F41"}], "avoid": ["candy pastels", "cheerful brights"]},
        "metals": ["gunmetal", "blackened silver"], "stones": ["obsidian", "garnet", "black tourmaline"],
        "patterns": {"recommended": ["dark-on-dark jacquard", "subtle texture", "monochrome depth"], "avoid": ["cheerful florals", "whimsical prints"]},
        "silhouette_keywords": ["fitted", "controlled", "sharp"],
        "occasion_modifiers": {"work": "the power behind the scenes", "intimate": "controlled intensity", "daily": "dark purpose in every piece"},
        "code_leaninto": ["dark is not basic, dark is power", "strategic revelation over total exposure", "quality leather as identity"],
        "code_avoid": ["anything naive or cutesy", "transparent vulnerability"], "code_consider": ["monochrome dark wardrobe with tonal depth"],
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
        "code_leaninto": ["travel-inspired dressing", "cultural mixing with respect", "movement-ready layers"],
        "code_avoid": ["rigid dress codes", "movement-restricting pieces"], "code_consider": ["a signature travel accessory"],
        "opposites": {"textures": ["stiff formal suiting", "restrictive fabrics"], "colours": ["corporate grey", "lifeless beige"], "silhouettes": ["rigid formal", "constricting fits"], "mood": ["confined", "restricted", "routine-bound"]}
    },
    "sun_capricorn": {
        "style_philosophy": "authoritative, structured, timeless discipline",
        "textures": {"good": ["structured wool", "pressed cotton", "quality leather", "heavy crepe"], "bad": ["cheap stretch", "flimsy synthetic", "disposable fabrics"], "sweet_spot_keywords": ["authority", "longevity", "backbone"]},
        "colours": {"primary": [{"name": "charcoal", "hex": "#36454F"}, {"name": "navy", "hex": "#000080"}], "accent": [{"name": "burgundy", "hex": "#800020"}], "avoid": ["childish brights", "trend neons"]},
        "metals": ["polished silver", "platinum"], "stones": ["garnet", "onyx", "sapphire"],
        "patterns": {"recommended": ["pinstripe", "houndstooth", "glen check"], "avoid": ["novelty prints", "cartoon patterns"]},
        "silhouette_keywords": ["tailored", "elongated", "commanding"],
        "occasion_modifiers": {"work": "the definition of authority", "intimate": "dark refined luxury", "daily": "structured even off-duty"},
        "code_leaninto": ["timeless over trendy", "dark power foundations", "tailoring as non-negotiable"],
        "code_avoid": ["fast fashion", "trend pieces with short lifespans"], "code_consider": ["cost-per-wear as a buying metric"],
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
        "code_leaninto": ["be impossible to categorise", "sustainable choices as rebellion", "mix decades freely"],
        "code_avoid": ["conforming to expected style codes", "predictable combinations"], "code_consider": ["one unexpected element daily"],
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
        "code_leaninto": ["dress by feeling", "soft flowing layers", "ocean-inspired palettes"],
        "code_avoid": ["rigid formality", "harsh structure"], "code_consider": ["a signature flowing accessory"],
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
        ["dress for action", "sharp lines and bold moves"], ["hesitant or timid clothing"], ["competition-inspired details"],
        {"textures": ["delicate lace", "flimsy fabrics"], "colours": ["pastel softness"], "silhouettes": ["meek and shapeless"], "mood": ["passive", "timid", "hesitant"]}),
    "mars_taurus": make_mars_entry("taurus", "persistent, slow-burn strength, grounded force",
        ["heavy cotton", "dense denim", "thick knit"], ["flimsy synthetics"], ["endurance", "weight", "permanence"],
        [{"name": "rust", "hex": "#B7410E"}, {"name": "deep olive", "hex": "#556B2F"}], [{"name": "warm brown", "hex": "#8B6914"}], ["cold sterile tones"],
        ["warm bronze", "antique brass"], ["bloodstone", "tiger eye"],
        ["earth-tone blocks", "textured solids"], ["busy chaotic prints"],
        ["solid", "grounded", "substantial"],
        {"work": "immovable reliable presence", "intimate": "slow sensual confidence", "daily": "built to last"},
        ["durability as strength", "heavy reliable fabrics"], ["flimsy disposable pieces"], ["workwear-inspired quality"],
        {"textures": ["flimsy synthetics"], "colours": ["cold sterile tones"], "silhouettes": ["insubstantial lightweight"], "mood": ["flimsy", "unstable", "impermanent"]}),
    "mars_gemini": make_mars_entry("gemini", "quick, versatile, mentally agile energy",
        ["lightweight blend", "stretch shirting", "tech knit"], ["heavy restricting fabrics"], ["speed", "wit", "flexibility"],
        [{"name": "bright yellow", "hex": "#FFD700"}, {"name": "teal", "hex": "#008080"}], [{"name": "light grey", "hex": "#D3D3D3"}], ["heavy monotone"],
        ["white gold", "mixed metals"], ["citrine", "agate"],
        ["mixed motifs", "graphic text", "stripes"], ["heavy single patterns"],
        ["quick", "convertible", "layered"],
        {"work": "mentally sharp presence", "intimate": "playful quick energy", "daily": "adaptable and light"},
        ["keep it quick and smart", "multiple options ready"], ["slow heavy dressing"], ["convertible pieces"],
        {"textures": ["heavy restricting fabrics"], "colours": ["heavy monotone"], "silhouettes": ["heavy rigid structure"], "mood": ["slow", "heavy", "ponderous"]}),
    "mars_cancer": make_mars_entry("cancer", "protective, defensive, emotionally fierce",
        ["soft armour knits", "washed cotton", "dense jersey"], ["exposed sheer fabrics"], ["protection", "strength", "comfort"],
        [{"name": "shell white", "hex": "#FFF5EE"}, {"name": "deep blue", "hex": "#00008B"}], [{"name": "soft grey", "hex": "#B0B0B0"}], ["aggressive reds"],
        ["sterling silver", "antique silver"], ["moonstone", "labrimar"],
        ["nautical stripes", "wave motifs"], ["aggressive graphics"],
        ["protective", "layered", "secure"],
        {"work": "protective leadership", "intimate": "fierce tenderness", "daily": "comfortable shield"},
        ["dress as emotional armour", "protective layers"], ["emotionally exposing clothes"], ["comfort-armour pieces"],
        {"textures": ["exposed sheer fabrics"], "colours": ["aggressive reds"], "silhouettes": ["vulnerable and exposed"], "mood": ["exposed", "unprotected", "vulnerable"]}),
    "mars_leo": make_mars_entry("leo", "confident, commanding, warm authority",
        ["structured satin", "heavy cotton", "bold weave"], ["dull matte fabrics"], ["command", "presence", "warmth"],
        [{"name": "copper", "hex": "#B87333"}, {"name": "burnt orange", "hex": "#CC5500"}], [{"name": "gold", "hex": "#FFD700"}], ["drab neutrals"],
        ["polished gold", "brass"], ["sunstone", "citrine"],
        ["bold medallion", "animal accents", "statement prints"], ["invisible minimal patterns"],
        ["commanding", "broad", "powerful"],
        {"work": "natural born leader energy", "intimate": "bold generous warmth", "daily": "effortlessly commanding"},
        ["lead with confidence", "warm metals and bold moves"], ["shrinking or dimming your presence"], ["a signature power piece"],
        {"textures": ["dull matte fabrics"], "colours": ["drab neutrals"], "silhouettes": ["deliberately small and meek"], "mood": ["meek", "dimmed", "invisible"]}),
    "mars_virgo": make_mars_entry("virgo", "precise, methodical, quietly powerful",
        ["fine tailoring fabric", "pressed cotton", "structured crepe"], ["sloppy fabrics"], ["precision", "method", "efficiency"],
        [{"name": "brick red", "hex": "#CB4154"}, {"name": "warm taupe", "hex": "#8B8589"}], [{"name": "navy", "hex": "#000080"}], ["chaotic colours"],
        ["brushed silver", "matte steel"], ["sapphire", "clear quartz"],
        ["micro-check", "fine pinstripe"], ["oversized logos"],
        ["precise", "clean", "efficient"],
        {"work": "surgical precision energy", "intimate": "detailed attention", "daily": "every detail matters"},
        ["precision as power", "details that others miss"], ["sloppy or careless dressing"], ["a perfect hem as a power move"],
        {"textures": ["sloppy fabrics"], "colours": ["chaotic colours"], "silhouettes": ["messy oversized"], "mood": ["careless", "sloppy", "imprecise"]}),
    "mars_libra": make_mars_entry("libra", "strategic, diplomatic, charm as weapon",
        ["fluid silk", "fine wool", "soft structured blend"], ["harsh industrial fabric"], ["strategy", "grace", "diplomacy"],
        [{"name": "rose", "hex": "#FF007F"}, {"name": "soft gold", "hex": "#DAA520"}], [{"name": "powder blue", "hex": "#B0E0E6"}], ["harsh aggressive tones"],
        ["rose gold", "soft copper"], ["pink tourmaline", "kunzite"],
        ["balanced geometric", "elegant stripe"], ["aggressive patterns"],
        ["graceful", "strategic", "charming"],
        {"work": "diplomatic power", "intimate": "charming intensity", "daily": "gracefully assertive"},
        ["charm as a form of strength", "elegance in confrontation"], ["blunt aggressive dressing"], ["strategic colour psychology"],
        {"textures": ["harsh industrial fabric"], "colours": ["harsh aggressive tones"], "silhouettes": ["blunt aggressive shapes"], "mood": ["blunt", "harsh", "aggressive"]}),
    "mars_scorpio": make_mars_entry("scorpio", "intense, strategic, covert power",
        ["heavy leather", "dense knit", "bonded fabric", "matte stretch"], ["transparent fabrics", "flimsy materials"], ["intensity", "stealth", "power"],
        [{"name": "deep black", "hex": "#0A0A0A"}, {"name": "blood red", "hex": "#660000"}], [{"name": "dark plum", "hex": "#580F41"}], ["light pastels"],
        ["blackened steel", "gunmetal"], ["obsidian", "black onyx", "garnet"],
        ["dark-on-dark texture", "subtle power motifs"], ["cheerful prints"],
        ["controlled", "lethal precision", "strategic"],
        {"work": "invisible power", "intimate": "dangerous magnetism", "daily": "dark operational mode"},
        ["darkness as power uniform", "strategic wardrobe control"], ["vulnerability through transparency"], ["matte versus shine contrasts"],
        {"textures": ["transparent fabrics", "flimsy materials"], "colours": ["light pastels"], "silhouettes": ["exposed and vulnerable"], "mood": ["exposed", "vulnerable", "naive"]}),
    "mars_sagittarius": make_mars_entry("sagittarius", "adventurous, expansive, freedom-driven",
        ["rugged denim", "waxed cotton", "travel-ready knit"], ["restrictive formal fabrics"], ["freedom", "adventure", "range"],
        [{"name": "deep purple", "hex": "#4B0082"}, {"name": "burnt sienna", "hex": "#E97451"}], [{"name": "turquoise", "hex": "#40E0D0"}], ["corporate restriction"],
        ["hammered brass", "aged gold"], ["turquoise", "amber"],
        ["global motifs", "oversized abstract"], ["corporate pinstripe"],
        ["expansive", "unrestricted", "athletic"],
        {"work": "inspiring and energetic", "intimate": "adventure-fuelled warmth", "daily": "always ready to move"},
        ["dress for adventure", "clothes that can handle anything"], ["restrictive formal codes"], ["multi-climate layering"],
        {"textures": ["restrictive formal fabrics"], "colours": ["corporate restriction"], "silhouettes": ["constricting formal"], "mood": ["confined", "restricted", "static"]}),
    "mars_capricorn": make_mars_entry("capricorn", "disciplined, enduring, strategic authority",
        ["heavy structured wool", "quality leather", "dense twill"], ["cheap disposable fabric"], ["discipline", "endurance", "authority"],
        [{"name": "dark brown", "hex": "#3B2F2F"}, {"name": "charcoal", "hex": "#36454F"}], [{"name": "dark red", "hex": "#8B0000"}], ["frivolous bright colours"],
        ["polished silver", "steel"], ["garnet", "onyx", "hematite"],
        ["herringbone", "glen check", "classic stripe"], ["novelty patterns"],
        ["authoritative", "structured", "impenetrable"],
        {"work": "the highest standard of professionalism", "intimate": "controlled power behind closed doors", "daily": "structured discipline always"},
        ["discipline as the ultimate power tool", "enduring quality as style statement"], ["frivolous or immature pieces"], ["a signature dark authority item"],
        {"textures": ["cheap disposable fabric"], "colours": ["frivolous bright colours"], "silhouettes": ["casual sloppy drape"], "mood": ["undisciplined", "frivolous", "weak"]}),
    "mars_aquarius": make_mars_entry("aquarius", "rebellious, innovative, unconventionally forceful",
        ["tech fabric", "recycled denim", "metallic knit"], ["traditional conservative fabrics"], ["rebellion", "innovation", "disruption"],
        [{"name": "neon blue", "hex": "#1B03A3"}, {"name": "electric green", "hex": "#00FF00"}], [{"name": "steel grey", "hex": "#71797E"}], ["traditional palettes"],
        ["titanium", "anodised aluminium"], ["labradorite", "meteorite"],
        ["circuit-inspired", "digital glitch", "asymmetric abstract"], ["traditional heritage prints"],
        ["experimental", "deconstructed", "angular"],
        {"work": "the system disruptor", "intimate": "electrifying and unpredictable", "daily": "walking rebellion"},
        ["break the rules intentionally", "technology as fashion"], ["conventional approaches"], ["deliberately challenging one style norm daily"],
        {"textures": ["traditional conservative fabrics"], "colours": ["traditional palettes"], "silhouettes": ["conventional safe shapes"], "mood": ["conventional", "safe", "obedient"]}),
    "mars_pisces": make_mars_entry("pisces", "fluid, intuitive, gentle persistence",
        ["soft stretch", "flowing jersey", "waterproof tech"], ["stiff rigid fabrics"], ["flow", "intuition", "adaptability"],
        [{"name": "sea blue", "hex": "#006994"}, {"name": "misty grey", "hex": "#B0B7BF"}], [{"name": "blush rose", "hex": "#FFB7C5"}], ["harsh aggressive tones"],
        ["silver", "iridescent"], ["amethyst", "aquamarine"],
        ["watercolour wash", "soft abstract"], ["harsh geometric stripes"],
        ["fluid", "adaptable", "gentle"],
        {"work": "creative intuitive force", "intimate": "deeply empathetic warmth", "daily": "guided by feeling"},
        ["let intuition guide dressing", "gentle force over brute strength"], ["rigid harsh structures"], ["water-inspired elements"],
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
        ["bold stripes", "sporty details"], ["fussy prints"], ["sharp", "athletic", "energetic"],
        {"work": "dynamic first impression", "intimate": "bold direct presence", "daily": "ready-to-go energy"},
        ["dress for the first three seconds", "sharp clean lines"], ["fussy or indecisive presentations"], ["a signature bold accessory"],
        {"textures": ["heavy formal fabrics"], "colours": ["subdued neutrals"], "silhouettes": ["indecisive layers"], "mood": ["timid", "indecisive", "hesitant"]}),
    "ascendant_taurus": make_asc_entry("taurus", "first impressions of quality, calm, sensory richness",
        ["cashmere", "quality leather", "heavy cotton"], ["cheap synthetics"], ["quality", "calm", "substance"],
        [{"name": "forest green", "hex": "#228B22"}, {"name": "cream", "hex": "#FFFDD0"}], [{"name": "warm camel", "hex": "#C19A6B"}], ["cheap-looking fabrics"],
        ["yellow gold", "warm bronze"], ["emerald", "jade"],
        ["tonal texture", "subtle plaid"], ["loud graphics"], ["relaxed structure", "grounded", "quality"],
        {"work": "calmly authoritative", "intimate": "sensuously inviting", "daily": "effortlessly luxurious"},
        ["look more expensive than you are", "quality visible from across the room"], ["anything that looks cheap"], ["one investment accessory as a first-impression anchor"],
        {"textures": ["cheap synthetics"], "colours": ["cheap-looking tones"], "silhouettes": ["flimsy insubstantial"], "mood": ["cheap", "rushed", "disposable"]}),
    "ascendant_gemini": make_asc_entry("gemini", "first impressions of intelligence, wit, adaptability",
        ["lightweight blend", "crisp shirting", "mixed media"], ["heavy monotone wool"], ["conversation", "wit", "lightness"],
        [{"name": "sky blue", "hex": "#87CEEB"}, {"name": "lemon yellow", "hex": "#FFF44F"}], [{"name": "mint", "hex": "#98FF98"}], ["dour monotone"],
        ["mixed metals", "sterling silver"], ["citrine", "aquamarine"],
        ["mixed prints", "conversational motifs"], ["heavy single pattern"], ["quick", "varied", "interesting"],
        {"work": "engaging and approachable", "intimate": "sparkly and surprising", "daily": "never boring"},
        ["present as someone interesting to talk to", "variety in accessories"], ["monotonous presentations"], ["glasses as a style signature"],
        {"textures": ["heavy monotone wool"], "colours": ["dour monotone"], "silhouettes": ["rigid single look"], "mood": ["boring", "monotonous", "dull"]}),
    "ascendant_cancer": make_asc_entry("cancer", "first impressions of warmth, approachability, gentle strength",
        ["soft knits", "washed cotton", "vintage-feel fabrics"], ["cold industrial materials"], ["warmth", "softness", "trust"],
        [{"name": "soft silver", "hex": "#C0C0C0"}, {"name": "pearl white", "hex": "#F0EAD6"}], [{"name": "pale blue", "hex": "#AEC6CF"}], ["harsh cold tones"],
        ["sterling silver", "white gold"], ["moonstone", "pearl"],
        ["soft florals", "gentle stripes"], ["aggressive graphics"], ["approachable", "warm", "soft-structured"],
        {"work": "trusted and warm", "intimate": "deeply inviting", "daily": "gently protective"},
        ["project approachability through softness", "warm tones near the face"], ["intimidating first impressions"], ["a soft scarf or shawl as a signature"],
        {"textures": ["cold industrial materials"], "colours": ["harsh cold tones"], "silhouettes": ["sharp intimidating cuts"], "mood": ["cold", "intimidating", "distant"]}),
    "ascendant_leo": make_asc_entry("leo", "first impressions of warmth, confidence, star quality",
        ["rich fabrics", "structured satin", "gold-tone materials"], ["dull cheap-looking fabrics"], ["radiance", "confidence", "warmth"],
        [{"name": "gold", "hex": "#FFD700"}, {"name": "warm amber", "hex": "#FFBF00"}], [{"name": "deep red", "hex": "#8B0000"}], ["drab invisible tones"],
        ["yellow gold", "polished brass"], ["sunstone", "amber", "citrine"],
        ["animal print", "bold florals"], ["invisible minimal"], ["dramatic", "broad", "warm"],
        {"work": "magnetic leadership presence", "intimate": "generous warm radiance", "daily": "casual star power"},
        ["walk in like you own the room", "warm metals and rich tones first"], ["deliberately dimming your entrance"], ["a signature gold piece"],
        {"textures": ["dull cheap fabrics"], "colours": ["drab invisible tones"], "silhouettes": ["deliberately small", "invisible cuts"], "mood": ["invisible", "meek", "unnoticed"]}),
    "ascendant_virgo": make_asc_entry("virgo", "first impressions of precision, intelligence, quiet authority",
        ["fine-gauge knit", "pressed cotton", "structured crepe"], ["wrinkled messy fabrics"], ["precision", "polish", "intelligence"],
        [{"name": "warm taupe", "hex": "#8B8589"}, {"name": "sage green", "hex": "#9CAF88"}], [{"name": "soft navy", "hex": "#3B5998"}], ["loud flashy tones"],
        ["brushed silver", "white gold"], ["peridot", "sapphire"],
        ["fine check", "subtle stripe"], ["loud logos"], ["clean", "precise", "polished"],
        {"work": "the most put-together person in the room", "intimate": "understated elegance", "daily": "polished even in casual"},
        ["let precision be your first impression", "perfect fit matters most"], ["messy or unfinished presentations"], ["a signature detail others notice second"],
        {"textures": ["wrinkled messy fabrics"], "colours": ["loud flashy tones"], "silhouettes": ["sloppy oversized"], "mood": ["sloppy", "messy", "careless"]}),
    "ascendant_libra": make_asc_entry("libra", "first impressions of grace, beauty, social ease",
        ["flowing silk", "fine cotton", "soft wool"], ["rough harsh fabrics"], ["grace", "beauty", "ease"],
        [{"name": "rose pink", "hex": "#FF66B2"}, {"name": "powder blue", "hex": "#B0E0E6"}], [{"name": "champagne", "hex": "#F7E7CE"}], ["aggressive dark palettes"],
        ["rose gold", "copper"], ["rose quartz", "opal"],
        ["art deco", "elegant symmetry"], ["chaotic prints"], ["balanced", "graceful", "proportional"],
        {"work": "elegantly approachable", "intimate": "romantically beautiful", "daily": "effortlessly aesthetic"},
        ["lead with beauty and grace", "balanced proportions always"], ["aggressive or jarring entrances"], ["a beautiful first-impression accessory"],
        {"textures": ["rough harsh fabrics"], "colours": ["aggressive dark palettes"], "silhouettes": ["aggressively angular"], "mood": ["aggressive", "harsh", "discordant"]}),
    "ascendant_scorpio": make_asc_entry("scorpio", "first impressions of intensity, mystery, magnetic power",
        ["structured leather", "dense knit", "heavy silk"], ["frilly cute fabrics"], ["intensity", "mystery", "control"],
        [{"name": "deep black", "hex": "#0A0A0A"}, {"name": "oxblood", "hex": "#4A0000"}], [{"name": "dark plum", "hex": "#580F41"}], ["cheerful bright tones"],
        ["gunmetal", "blackened silver"], ["obsidian", "garnet"],
        ["dark-on-dark texture", "monochrome depth"], ["happy prints"], ["fitted", "sharp", "magnetic"],
        {"work": "intimidating quiet power", "intimate": "dangerous allure", "daily": "mysterious and controlled"},
        ["mystery is your most powerful tool", "dark colours as a shield"], ["transparent or overly friendly presentations"], ["a single dark statement piece"],
        {"textures": ["frilly cute fabrics"], "colours": ["cheerful bright tones"], "silhouettes": ["cutesy babydoll", "overly open"], "mood": ["naive", "transparent", "overly friendly"]}),
    "ascendant_sagittarius": make_asc_entry("sagittarius", "first impressions of warmth, worldliness, open confidence",
        ["waxed cotton", "quality denim", "global textiles"], ["stiff formal suiting"], ["warmth", "worldliness", "openness"],
        [{"name": "cobalt blue", "hex": "#0047AB"}, {"name": "burnt sienna", "hex": "#E97451"}], [{"name": "turquoise", "hex": "#40E0D0"}], ["corporate grey monotone"],
        ["aged brass", "hammered gold"], ["turquoise", "lapis lazuli"],
        ["global prints", "oversized motifs"], ["conservative corporate"], ["relaxed", "broad", "open"],
        {"work": "inspiring and worldly", "intimate": "warm and generous", "daily": "adventure-ready confidence"},
        ["project openness and experience", "global references in your style"], ["looking closed or corporate"], ["a signature travel-inspired accessory"],
        {"textures": ["stiff formal suiting"], "colours": ["corporate grey monotone"], "silhouettes": ["rigid corporate structure"], "mood": ["closed", "rigid", "parochial"]}),
    "ascendant_capricorn": make_asc_entry("capricorn", "first impressions of authority, maturity, quiet power",
        ["structured wool", "quality suiting", "heavy cotton"], ["cheap casual fabrics"], ["authority", "maturity", "seriousness"],
        [{"name": "charcoal", "hex": "#36454F"}, {"name": "navy", "hex": "#000080"}], [{"name": "dark camel", "hex": "#A0785A"}], ["childish or unserious colours"],
        ["polished silver", "platinum"], ["garnet", "onyx"],
        ["pinstripe", "houndstooth"], ["novelty prints"], ["structured", "elongated", "commanding"],
        {"work": "instant authority", "intimate": "quietly impressive", "daily": "mature even in casual"},
        ["project authority from the first second", "structured dark foundations"], ["looking young or unserious"], ["a signature structured outerwear piece"],
        {"textures": ["cheap casual fabrics"], "colours": ["childish colours"], "silhouettes": ["casual sloppy"], "mood": ["immature", "unserious", "casual"]}),
    "ascendant_aquarius": make_asc_entry("aquarius", "first impressions of originality, intelligence, cool detachment",
        ["tech fabrics", "innovative materials", "metallic knit"], ["traditional conservative fabrics"], ["originality", "cool", "innovation"],
        [{"name": "electric blue", "hex": "#7DF9FF"}, {"name": "silver grey", "hex": "#C0C0C0"}], [{"name": "neon lime", "hex": "#CCFF00"}], ["conventional palettes"],
        ["titanium", "surgical steel"], ["labradorite", "fluorite"],
        ["digital abstract", "futuristic motifs"], ["heritage traditional"], ["angular", "unconventional", "futuristic"],
        {"work": "the interesting one", "intimate": "intriguing and different", "daily": "walking conversation starter"},
        ["be unforgettable, not conventional", "one unexpected element always"], ["looking like everyone else"], ["unconventional glasses or tech accessories"],
        {"textures": ["traditional conservative fabrics"], "colours": ["conventional palettes"], "silhouettes": ["conventional proportions"], "mood": ["conventional", "forgettable", "bland"]}),
    "ascendant_pisces": make_asc_entry("pisces", "first impressions of gentleness, creativity, otherworldly beauty",
        ["flowing chiffon", "soft jersey", "watercolour fabrics"], ["harsh stiff suiting"], ["gentleness", "dream", "ethereal"],
        [{"name": "lilac", "hex": "#C8A2C8"}, {"name": "seafoam", "hex": "#93E9BE"}], [{"name": "silver shimmer", "hex": "#D8D8D8"}], ["harsh industrial tones"],
        ["silver", "iridescent finishes"], ["amethyst", "aquamarine", "moonstone"],
        ["watercolour prints", "soft abstract"], ["harsh geometric"], ["flowing", "ethereal", "soft"],
        {"work": "gently creative authority", "intimate": "dreamlike and romantic", "daily": "quietly enchanting"},
        ["project softness as a strength", "flowing silhouettes as your signature"], ["harsh rigid presentations"], ["sheer layers as a mood setter"],
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
     ["subtle stripe", "military detail"], ["chaotic prints"], ["sharp", "contained"], {"work": "controlled authority", "intimate": "restrained power", "daily": "disciplined energy"},
     ["discipline is your edge", "structured foundations"], ["impulsive choices"], ["military-inspired details"],
     {"textures": ["flimsy fabrics"], "colours": ["frivolous brights"], "silhouettes": ["unstructured casual"], "mood": ["impulsive", "chaotic", "undisciplined"]}),
    ("taurus", "enduring quality, permanent foundations", ["heavy wool", "heritage tweed", "quality leather"], ["disposable fashion"], ["permanence", "heritage"],
     [{"name": "dark brown", "hex": "#3B2F2F"}], [{"name": "forest green", "hex": "#228B22"}], ["trendy fast colours"], ["antique gold", "bronze"], ["sapphire", "jet"],
     ["heritage check", "traditional stripe"], ["novelty prints"], ["solid", "enduring"], {"work": "timeless authority", "intimate": "heritage luxury", "daily": "built to last"},
     ["buy for the decade not the season", "heritage as identity"], ["disposable trend pieces"], ["heirloom-quality purchases"],
     {"textures": ["disposable fashion"], "colours": ["trendy fast colours"], "silhouettes": ["trend-driven shapes"], "mood": ["trendy", "disposable", "temporary"]}),
    ("gemini", "structured communication, disciplined versatility", ["crisp shirting", "structured blend"], ["sloppy jersey"], ["discipline", "structure"],
     [{"name": "steel grey", "hex": "#71797E"}], [{"name": "soft navy", "hex": "#3B5998"}], ["chaotic multi-colour"], ["white gold", "silver"], ["agate", "clear quartz"],
     ["fine stripe", "grid pattern"], ["wild prints"], ["clean", "structured"], {"work": "precise communicator", "intimate": "carefully considered", "daily": "structured variety"},
     ["structured approach to variety", "disciplined mixing"], ["chaotic unplanned mixing"], ["a structured weekly outfit plan"],
     {"textures": ["sloppy jersey"], "colours": ["chaotic multi-colour"], "silhouettes": ["chaotic layers"], "mood": ["scattered", "chaotic", "unfocused"]}),
    ("cancer", "protective structure, emotional boundaries through style", ["dense knit", "washed wool", "structured cotton"], ["cold metallics"], ["boundary", "protection"],
     [{"name": "slate blue", "hex": "#6A5ACD"}], [{"name": "warm grey", "hex": "#808069"}], ["emotionally jarring tones"], ["antique silver", "white gold"], ["moonstone", "labradorite"],
     ["classic plaid", "traditional check"], ["aggressive prints"], ["protective", "structured"], {"work": "boundaries with warmth", "intimate": "controlled vulnerability", "daily": "structured comfort"},
     ["boundaries in clothing reflect boundaries in life", "structured comfort layers"], ["emotionally exposing outfits"], ["a signature protective outer layer"],
     {"textures": ["cold metallics"], "colours": ["emotionally jarring tones"], "silhouettes": ["exposed vulnerable"], "mood": ["exposed", "boundary-less", "unprotected"]}),
    ("leo", "disciplined glamour, structured warmth", ["structured satin", "heavy wool", "quality velvet"], ["cheap sparkly fabrics"], ["discipline", "control"],
     [{"name": "dark gold", "hex": "#B8860B"}], [{"name": "deep burgundy", "hex": "#800020"}], ["cheap glitter tones"], ["polished gold", "brass"], ["tiger eye", "garnet"],
     ["regal stripe", "classic medallion"], ["cheap novelty"], ["controlled drama", "structured warmth"], {"work": "authoritative presence", "intimate": "controlled luxury", "daily": "disciplined glamour"},
     ["glamour with restraint", "quality over sparkle"], ["cheap ostentatious display"], ["investment glamour pieces"],
     {"textures": ["cheap sparkly fabrics"], "colours": ["cheap glitter tones"], "silhouettes": ["flashy without substance"], "mood": ["flashy", "cheap", "ostentatious"]}),
    ("virgo", "exacting precision, mastery of detail", ["pressed fine cotton", "structured silk", "precise tailoring"], ["any imperfect fabric"], ["mastery", "precision"],
     [{"name": "stone grey", "hex": "#928E85"}], [{"name": "sage", "hex": "#9CAF88"}], ["messy uncontrolled tones"], ["brushed silver", "platinum"], ["sapphire", "peridot"],
     ["micro-pattern", "precise detail"], ["messy abstract"], ["immaculate", "precise"], {"work": "standard of excellence", "intimate": "meticulous elegance", "daily": "precision as habit"},
     ["perfectionism as style", "flawless execution over creativity"], ["any visible imperfection"], ["regular wardrobe maintenance rituals"],
     {"textures": ["any imperfect fabric"], "colours": ["messy uncontrolled tones"], "silhouettes": ["careless fit"], "mood": ["imprecise", "messy", "careless"]}),
    ("libra", "structured beauty, disciplined aesthetics", ["fine silk blend", "structured crepe", "quality wool"], ["rough ugly fabrics"], ["balance", "order"],
     [{"name": "soft mauve", "hex": "#E0B0FF"}], [{"name": "slate", "hex": "#708090"}], ["ugly discordant tones"], ["rose gold", "silver"], ["rose quartz", "sapphire"],
     ["symmetrical motif", "balanced stripe"], ["ugly abstract"], ["graceful structure"], {"work": "elegant authority", "intimate": "structured romance", "daily": "disciplined beauty"},
     ["beauty requires discipline", "proportional balance always"], ["ugliness as a style statement"], ["colour harmony as a daily practice"],
     {"textures": ["rough ugly fabrics"], "colours": ["ugly discordant tones"], "silhouettes": ["deliberately ugly shapes"], "mood": ["ugly", "discordant", "unbalanced"]}),
    ("scorpio", "deep discipline, controlled intensity", ["bonded fabric", "structured leather", "dense wool"], ["transparent fabrics"], ["control", "depth"],
     [{"name": "ink black", "hex": "#1C1C1C"}], [{"name": "dark burgundy", "hex": "#4A0000"}], ["light revealing tones"], ["blackened steel", "titanium"], ["obsidian", "onyx"],
     ["dark texture", "subtle power motifs"], ["light cheerful prints"], ["controlled", "concealing"], {"work": "formidable presence", "intimate": "deep controlled power", "daily": "disciplined darkness"},
     ["control is the ultimate power", "dark structured layers"], ["revealing or transparent choices"], ["strategic wardrobe as life armour"],
     {"textures": ["transparent fabrics"], "colours": ["light revealing tones"], "silhouettes": ["exposed and revealing"], "mood": ["exposed", "revealed", "uncontrolled"]}),
    ("sagittarius", "disciplined adventure, structured freedom", ["waxed canvas", "quality denim", "structured travel fabric"], ["impractical delicate fabrics"], ["structure", "endurance"],
     [{"name": "deep navy", "hex": "#000080"}], [{"name": "warm brown", "hex": "#8B6914"}], ["impractical tones"], ["hammered bronze", "aged brass"], ["turquoise", "lapis lazuli"],
     ["global geometric", "structured ethnic"], ["dainty small prints"], ["structured but free"], {"work": "experienced authority", "intimate": "wise warmth", "daily": "structured adventure"},
     ["freedom within structure", "durable adventure-ready pieces"], ["impractical or fragile choices"], ["a structured travel wardrobe"],
     {"textures": ["impractical delicate fabrics"], "colours": ["impractical tones"], "silhouettes": ["fragile impractical"], "mood": ["fragile", "impractical", "naive"]}),
    ("capricorn", "ultimate authority, peak discipline, timeless power", ["finest wool", "structured cashmere", "premium leather"], ["anything cheap"], ["authority", "permanence"],
     [{"name": "jet black", "hex": "#0A0A0A"}, {"name": "slate", "hex": "#708090"}], [{"name": "dark navy", "hex": "#000080"}], ["any frivolous colour"], ["platinum", "polished silver"], ["onyx", "garnet", "sapphire"],
     ["pinstripe", "houndstooth", "classic check"], ["anything novelty"], ["commanding", "impeccable"], {"work": "the standard others aspire to", "intimate": "quiet powerful luxury", "daily": "never off-duty"},
     ["embody the standard", "timeless pieces as life investments"], ["anything below your standard"], ["a personal uniform system"],
     {"textures": ["anything cheap"], "colours": ["any frivolous colour"], "silhouettes": ["sloppy casual"], "mood": ["frivolous", "undisciplined", "common"]}),
    ("aquarius", "structured rebellion, disciplined innovation", ["tech fabric", "recycled innovation", "structural mesh"], ["traditional stuffy fabrics"], ["innovation", "structure"],
     [{"name": "cool silver", "hex": "#AAA9AD"}], [{"name": "electric blue", "hex": "#7DF9FF"}], ["traditional conservative tones"], ["titanium", "surgical steel"], ["labradorite", "meteorite"],
     ["circuit-inspired", "architectural pattern"], ["heritage traditional"], ["angular", "innovative"], {"work": "the structured rebel", "intimate": "controlled eccentricity", "daily": "disciplined difference"},
     ["rebellion needs structure to be effective", "innovation within constraints"], ["convention for convention's sake"], ["a structured approach to standing out"],
     {"textures": ["traditional stuffy fabrics"], "colours": ["traditional conservative tones"], "silhouettes": ["conventional safe shapes"], "mood": ["conventional", "traditional", "safe"]}),
    ("pisces", "structured dreaminess, disciplined intuition", ["fluid structured silk", "weighted jersey", "dense chiffon"], ["stiff harsh fabrics"], ["grounding", "flow"],
     [{"name": "deep purple", "hex": "#4B0082"}], [{"name": "seafoam", "hex": "#93E9BE"}], ["harsh jarring tones"], ["silver", "white gold"], ["amethyst", "sapphire"],
     ["subtle watercolour", "structured abstract"], ["harsh geometric"], ["flowing but grounded"], {"work": "grounded creative authority", "intimate": "structured romance", "daily": "disciplined softness"},
     ["ground the dream with structure", "structured layers over flowing base"], ["losing structure entirely"], ["structured underlayers beneath flowing pieces"],
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
        ["one bold hero piece per outfit", "generous proportions that command space", "quality over quantity but in abundant silhouettes"],
        ["scrimping on fabric quality", "pinched or undersized garments", "playing small with safe basics"],
        ["oversized tailoring as a power move", "a single statement coat that announces your arrival"],
        {"textures": ["cheap polyester", "thin clingy jersey", "stiff scratchy blends"], "colours": ["washed-out beige", "pallid grey"], "silhouettes": ["pinched waist", "cramped shoulders", "undersized everything"], "mood": ["confined", "stingy", "apologetic", "timid"]}
    ),
    "jupiter_taurus": make_outer_entry(
        "abundant, tactile, investment luxury",
        ["richness", "weight", "tactile quality"],
        ["rich cashmere", "heavy silk charmeuse", "double-faced wool"],
        ["scratchy acrylic knits", "paper-thin cotton", "shiny cheap satin"],
        [{"name": "rich emerald", "hex": "#046307"}],
        [{"name": "cream", "hex": "#FFFDD0"}],
        ["garish neons", "cold sterile white"],
        ["yellow gold", "bronze"], ["emerald", "jade"],
        ["lush botanical", "oversized florals"], ["busy cluttered prints", "cheap-looking logos"],
        ["luxurious", "generous", "enveloping"],
        {"work": "quietly expensive, investment suiting, touchable fabrics", "intimate": "sumptuous textures, cashmere wraps, silk against skin", "daily": "elevated basics in premium fabrics, the perfect T-shirt"},
        ["invest in one extraordinary fabric per season", "tactile richness you want to run your hands over", "pieces that age beautifully"],
        ["disposable fast-fashion pieces", "scratchy or uncomfortable fabrics regardless of look", "quantity over quality"],
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
        ["diverse mixed prints", "conversational patterns"], ["single-note repetitive prints", "humourless solids"],
        ["varied", "layered", "convertible"],
        {"work": "chameleon professional, different energy for different meetings", "intimate": "playful mixing, unexpected combinations that spark conversation", "daily": "three-outfit-from-one-outfit thinking, reversible pieces"},
        ["pieces that work three ways", "unexpected colour or pattern mixing", "a wardrobe that tells different stories each day"],
        ["a capsule so small it bores you", "uniform dressing that removes all variety", "rigid outfit formulas"],
        ["a jacket that reverses from work to weekend", "accessories that completely change an outfit's personality"],
        {"textures": ["stiff single-use suiting", "heavy unmixable fabrics"], "colours": ["monotone severity", "colourless minimalism"], "silhouettes": ["rigid unalterable shapes", "single-silhouette uniform"], "mood": ["monotonous", "limited", "repetitive", "boring"]}
    ),
    "jupiter_cancer": make_outer_entry(
        "nurturing, generously soft, emotionally abundant",
        ["softness", "comfort", "heritage warmth"],
        ["soft quality knits", "heritage wool", "washed linen"],
        ["stiff starched fabrics", "cold synthetics against skin", "scratchy formal blends"],
        [{"name": "cream", "hex": "#FFFDD0"}],
        [{"name": "pearl white", "hex": "#F0EAD6"}],
        ["harsh black", "cold industrial tones"],
        ["silver", "white gold"], ["pearl", "moonstone"],
        ["soft generous florals", "heirloom prints"], ["aggressive graphics", "harsh geometric"],
        ["nurturing", "enveloping", "softly generous"],
        {"work": "warm professional authority, approachable leadership in soft power fabrics", "intimate": "wrapped in softness, cocooned comfort, blanket-weight knits", "daily": "the softest sweater you own, elevated loungewear"},
        ["pieces that feel like a hug", "heirloom-quality knits worth passing down", "generous wrapping and draping"],
        ["anything that feels cold or punishing against skin", "stiff formal wear that prevents natural movement", "harsh synthetic athleisure"],
        ["a heritage-quality throw that doubles as a wrap", "investing in the softest base layers"],
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
        ["one piece that makes you the main character", "gold accents as signature, not trend", "generosity in fabric and silhouette"],
        ["blending into the background on purpose", "dressing down when the occasion calls for presence", "apologising for taking up visual space"],
        ["a gold-threaded knit that elevates everything", "statement outerwear as daily armour"],
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
        ["invest in tailoring and alterations", "quality visible in the details, buttons, stitching, lining", "a wardrobe where everything fits perfectly"],
        ["visible pilling or wear", "wrinkled or poorly pressed clothing", "sloppy proportions that look accidental"],
        ["finding a tailor who understands your body", "one perfectly fitting shirt to template every future purchase"],
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
        ["beauty as a daily practice, not a special-occasion effort", "tonal dressing with deliberate accent placement", "balanced proportions top to bottom"],
        ["jarring combinations that create visual noise", "neglecting the overall harmony for one flashy piece", "beauty that costs comfort"],
        ["a tonal palette approach across the week", "one perfect accessory that elevates everything"],
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
        ["depth over breadth, fewer pieces, darker, richer", "strategic investment in power pieces", "tone-on-tone layering for built-in gravitas"],
        ["surface-level trend-chasing", "lighthearted dressing when the situation demands gravitas", "revealing too much too soon"],
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
        ["global motifs", "artisan ikat", "tribal-inspired geometry"], ["corporate monotone patterns", "safe repetitive stripes"],
        ["expansive", "worldly", "movement-friendly"],
        {"work": "global professional, cultural confidence, worldly polish, artisan details", "intimate": "travel stories worn on your body, collected pieces with history", "daily": "exploration-ready but polished, adventure meets intention"},
        ["pieces collected from travels or inspired by world cultures", "colour that reflects where you have been or want to go", "fabrics that move as freely as you do"],
        ["precious clothing that restricts movement", "a wardrobe afraid of weather or spontaneity", "domestic-only safe choices"],
        ["one artisan-made piece per season from a different tradition", "travel-weight layers that perform across climates"],
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
        ["build a wardrobe like a portfolio, long-term, appreciating assets", "cost-per-wear thinking over impulse buying", "classic shapes in the best fabric you can afford"],
        ["trendy impulse purchases that date within a season", "flashy logos as a substitute for quality", "disposable fashion of any kind"],
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
        ["invest in materials from the future, recycled, innovative, unexpected", "let your wardrobe reflect the world you want", "generosity toward the planet through conscious choices"],
        ["conventional luxury that ignores its footprint", "backward-looking accumulation of dead stock", "conformist dressing that wastes creative opportunity"],
        ["one truly innovative piece that starts conversations about fashion's future", "sustainable luxury as the ultimate abundance"],
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
        ["fabrics that flow rather than constrict", "colour that feels like an emotion, not a decision", "generosity of spirit visible in softness and openness"],
        ["rigid structured dressing that blocks emotional expression", "harsh fabrics that feel like armour against the world", "material obsession over soulful dressing"],
        ["one silk piece so fluid it feels like wearing water", "colour chosen by feeling rather than matching"],
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
        ["let one strong piece speak instead of many whispering", "decisive colour choices over safe hedge-betting", "clarity over complexity in every combination"],
        ["mixed-message outfits that confuse your own story", "hedging with too many safe neutrals", "fussing over options when the first instinct was right"],
        ["a signature colour that becomes your verbal shorthand", "pre-decided outfit formulas for zero-decision mornings"],
        {"textures": ["fussy delicate chiffon", "indecisive mixed-texture chaos"], "colours": ["wishy-washy neutrals", "indecisive grey-beige"], "silhouettes": ["overly complicated layering", "ambiguous shapeless forms"], "mood": ["hesitant", "unclear", "muddled", "overthinking"]}
    ),
    "mercury_taurus": make_outer_entry(
        "deliberate, substantial, slowly considered",
        ["substance", "deliberation", "patina"],
        ["heavy cotton oxford", "dense linen blend", "substantial ponte"],
        ["paper-thin disposable fabrics", "flimsy trend pieces that fall apart"],
        [{"name": "olive", "hex": "#808000"}],
        [{"name": "warm camel", "hex": "#C19A6B"}],
        ["cheap-looking bright colours", "anything that reads as rushed or careless"],
        ["warm bronze"], ["emerald"],
        ["textured solids", "woven geometric"], ["flashy novelty prints", "gimmicky fast-fashion graphics"],
        ["substantial", "grounded", "deliberately chosen"],
        {"work": "reliably polished, the person whose outfit always looks considered", "intimate": "tactile quality that invites touch, slow luxury", "daily": "perfectly broken-in favourites that improve with wear"},
        ["pieces that look better with age and use", "deliberate slow wardrobe building", "fabrics with visible quality even from across the room"],
        ["impulsive trend-chasing that creates regret", "replacing quality pieces with cheaper versions", "rushing wardrobe decisions under pressure"],
        ["a leather bag that patinas beautifully over years", "heritage denim worn to personal perfection"],
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
        ["mixed prints", "conversational graphics", "dual motifs"], ["humourless solids", "corporate monotony"],
        ["varied", "quick-change", "layered"],
        {"work": "the person with a different brilliant idea every meeting, style to match", "intimate": "playful wit, unexpected details that reward closer looking", "daily": "three different people this week, all authentically you"},
        ["versatile pieces that remix endlessly", "surprise elements that spark dialogue", "colour and pattern as conversation starters"],
        ["a single rigid uniform that kills creativity", "style ruts that last longer than a week", "outfit repetition out of laziness rather than intention"],
        ["one pattern-mixing experiment per week", "accessories as quick personality-changers"],
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
        ["trust your gut when a piece 'feels right'", "soft colours that put others at ease", "clothing as emotional communication"],
        ["ignoring how a piece makes you feel because it looks 'right'", "cold formal dressing in warm personal settings", "dressing to impress rather than connect"],
        ["a signature soft piece that people associate with your warmth", "mood-responsive dressing as an emotional practice"],
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
        ["bold typography", "lion-hearted graphics", "statement prints"], ["tiny timid patterns", "barely-there prints"],
        ["expressive", "bold", "declarative"],
        {"work": "confidence that enters the room before you do", "intimate": "warmth and generosity expressed through golden tones", "daily": "main-character energy even at the grocery store"},
        ["one statement piece that announces your presence", "bold colour as self-expression, not costume", "prints that tell your story loudly and proudly"],
        ["dressing to disappear", "muting yourself for other people's comfort", "beige when your soul says gold"],
        ["a signature bold print that becomes your calling card", "gold accessories as a daily declaration"],
        {"textures": ["mousy thin fabrics", "shy retiring blends"], "colours": ["invisible beige", "disappearing grey"], "silhouettes": ["shrinking minimalist shapes", "self-effacing cuts"], "mood": ["timid", "muted", "invisible", "apologetic"]}
    ),
    "mercury_virgo": make_outer_entry(
        "precise, editorial, immaculately finished",
        ["precision", "finish", "alignment"],
        ["pressed cotton broadcloth", "fine-gauge merino", "precision-knit jersey"],
        ["wrinkle-prone cheap linen", "pilling blend knits", "sloppy oversized sweaters"],
        [{"name": "wheat", "hex": "#F5DEB3"}],
        [{"name": "sage green", "hex": "#9CAF88"}],
        ["sloppy tie-dye", "chaotic multi-colour clash"],
        ["brushed silver"], ["peridot", "sapphire"],
        ["micro-houndstooth", "fine pinstripe", "precise grid"], ["loud oversized prints", "sloppy abstract splatter"],
        ["precise", "clean-lined", "perfectly proportioned"],
        {"work": "the person whose outfit is always immaculate, effortless precision", "intimate": "quality visible in the smallest detail, rewarding close attention", "daily": "crisp even in casual, pressed jeans, clean sneakers, aligned seams"},
        ["perfect fit over perfect fashion", "visible stitch quality and finish", "alignment and proportion as personal standards"],
        ["visible wear, pilling, or fraying in public", "wrinkled clothing that signals carelessness", "proportions that are close-but-not-quite"],
        ["a dedicated pressing routine as style ritual", "strategic fit alterations on every key piece"],
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
        ["tonal coordination as a daily practice", "balanced proportions that flatter universally", "colour relationships that create visual harmony"],
        ["jarring mismatched combinations", "single pieces that overpower the whole outfit", "confrontational style choices in harmonious settings"],
        ["a colour-wheel approach to weekly outfit planning", "one signature balanced combination"],
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
        ["subtle hidden motifs", "tone-on-tone jacquard"], ["loud obvious prints", "billboard-scale graphics"],
        ["controlled", "strategic", "layered meaning"],
        {"work": "the person who reveals nothing accidentally, strategic opacity", "intimate": "depth through concealment, allure through what stays hidden", "daily": "dark tonal layers that communicate control and intent"},
        ["strategic concealment over obvious display", "hidden quality details that reward intimacy", "dark tonal dressing as information control"],
        ["transparent obvious dressing that reveals everything", "loud prints that broadcast instead of suggest", "shallow surface-level styling"],
        ["tone-on-tone dark layering as a communication strategy", "hidden details, quality lining, interior monogram"],
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
        ["pieces with provenance, where they came from matters", "colour and pattern from different traditions", "travel-weight fabrics that perform everywhere"],
        ["a wardrobe that has never left the high street", "dressing as if the world is smaller than it is", "playing it safe with culturally neutral everything"],
        ["one collected piece per trip that joins the rotation", "globally-sourced accessories as conversation pieces"],
        {"textures": ["restrictive formal-only fabrics", "fragile non-travel-worthy pieces"], "colours": ["timid corporate grey", "small-world beige"], "silhouettes": ["stiff office-only silhouettes", "restricted movement-limiting cuts"], "mood": ["narrow", "parochial", "sheltered", "incurious"]}
    ),
    "mercury_capricorn": make_outer_entry(
        "authoritative, precisely tailored, professionally credentialed",
        ["authority", "precision", "maintenance"],
        ["fine worsted suiting", "pressed cotton broadcloth", "quality gabardine"],
        ["wrinkled casual linen", "sloppy oversized knits", "juvenile graphic tees"],
        [{"name": "charcoal", "hex": "#36454F"}],
        [{"name": "navy", "hex": "#000080"}],
        ["juvenile brights", "unprofessional neons"],
        ["silver"], ["garnet"],
        ["classic regimental stripe", "subtle power check"], ["novelty prints", "juvenile graphics"],
        ["structured", "professional", "precisely tailored"],
        {"work": "the person whose outfit says 'I am ready' before they speak", "intimate": "restrained confidence, precision even in casual moments", "daily": "structured casual that never reads as sloppy"},
        ["dress for the position you want, then exceed it", "precision in fit as a form of professional respect", "classic pieces maintained to impeccable standards"],
        ["casual Friday as an excuse for sloppy dressing", "juvenile touches in professional settings", "trendy pieces that undermine credibility"],
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
        ["materials that did not exist five years ago", "style choices that require explaining, that is the point", "progressive aesthetics over backward-looking convention"],
        ["dressing conventionally to fit in", "choosing comfort over innovation", "heritage pieces worn ironically rather than authentically"],
        ["one genuinely innovative material per season", "accessories that signal forward-thinking values"],
        {"textures": ["conventional cotton basics", "backwards-looking traditional fabrics"], "colours": ["establishment navy-and-grey", "convention-conforming safe tones"], "silhouettes": ["dated conventional cuts", "predictable safe shapes"], "mood": ["conventional", "backward", "stale", "conformist"]}
    ),
    "mercury_pisces": make_outer_entry(
        "poetic, flowing, metaphorically soft",
        ["fluidity", "poetry", "emotional softness"],
        ["soft washed jersey", "flowing silk", "watercolour-print chiffon"],
        ["stiff corporate suiting", "rigid structured denim", "harsh synthetic athleisure"],
        [{"name": "sea green", "hex": "#2E8B57"}],
        [{"name": "lavender", "hex": "#E6E6FA"}],
        ["harsh primary colours", "blunt corporate black"],
        ["silver"], ["amethyst", "aquamarine"],
        ["watercolour motifs", "impressionist print", "oceanic flow"], ["stark geometric", "aggressive graphic"],
        ["flowing", "poetic", "softly layered"],
        {"work": "empathetic presence, style that listens and absorbs the room", "intimate": "dreamy layers, flowing fabrics, candlelit softness", "daily": "poetry-in-motion dressing, soft, flowing, quietly beautiful"},
        ["fabrics that move like they are breathing", "colour that dissolves rather than declares", "soft layering as emotional expression"],
        ["blunt literal dressing with no subtext", "aggressive structured shapes that overpower your quiet nature", "harsh colours that shout when you whisper"],
        ["one silk scarf that changes the emotional temperature of any outfit", "watercolour prints as personal poetry"],
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
        ["break one convention per outfit deliberately", "wear something nobody in the room has seen before", "silhouettes from the future, not the archive"],
        ["safe predictable corporate dressing", "following last season's trend", "buying what everyone else is wearing"],
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
        ["materials that challenge what luxury means", "sustainable innovation over conventional status symbols", "quality measured by impact, not just thread count"],
        ["conventional luxury that ignores its environmental cost", "disposable pieces regardless of price point", "greenwashing aesthetics without substance"],
        ["one genuinely innovative sustainable luxury piece per season", "plant-based leather that outperforms the original"],
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
        ["modular pieces that reconfigure", "unexpected tech integration in everyday clothing", "pieces that look different depending on how you wear them"],
        ["fixed-form single-use outfits", "static wardrobe that never recombines", "predictable daily repetition"],
        ["a jacket that becomes a vest becomes a bag", "colour-changing or responsive materials"],
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
        ["choosing comfort technology over nostalgia", "looking for fabrics that regulate temperature before they impress on a hanger", "building softness into the outfit without losing shape"],
        ["uncomfortable clothing worn for tradition's sake", "cold stiff formal pieces that ignore the body", "convention that prioritises appearance over wellbeing"],
        ["temperature-regulating base layers for long days", "comfort tech that looks polished enough to leave the house in"],
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
        ["reflective or metallic pieces as daily drama", "be the brightest, strangest, most original thing in any room", "tech-enhanced visibility as creative statement"],
        ["dimming yourself to fit in", "conventional safe dressing in creative settings", "muting your volume for someone else's comfort"],
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
        ["performance fabrics that improve on natural predecessors", "functional innovation in every detail", "precision engineering visible at seam level"],
        ["sloppy 'creative' dressing that sacrifices function", "decorative-only pieces with no performance value", "imprecise construction marketed as 'relaxed'"],
        ["nano-treated fabrics that repel stains and wrinkles", "precision-fit pieces engineered for your exact measurements"],
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
        ["conventional beauty standards in fashion", "traditional elegance that refuses innovation", "safe pretty for the sake of safe pretty"],
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
        ["dark futuristic motifs", "tech-noir graphics"], ["cheerful conventional prints", "lighthearted florals"],
        ["intense innovation", "darkly experimental"],
        {"work": "the darkly innovative force, tech-noir authority that unsettles and commands", "intimate": "electric intensity through innovative dark materials, tactile surprise", "daily": "tech-noir daily armour, innovative dark materials with hidden depth"},
        ["dark materials with hidden technical innovation", "tech-noir as a personal aesthetic system", "intensity expressed through material innovation, not volume"],
        ["safe cheerful dressing that ignores depth", "conventional comfort that avoids confrontation", "surface-level trends with no substance"],
        ["innovative dark leather alternatives that outperform the originals", "hidden tech details that reward investigation"],
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
        ["global futuristic motifs", "cross-cultural tech-print"], ["parochial local patterns", "conventional travel clichés"],
        ["expansively innovative", "boundary-dissolving"],
        {"work": "the boundary-crosser, global innovation meets professional authority", "intimate": "adventure materials, stories told through tech-enhanced fabrics", "daily": "climate-adaptive dressing that performs across every context"},
        ["clothing that performs across climates and cultures", "tech-enhanced travel pieces that eliminate packing anxiety", "cultural innovation over cultural appropriation"],
        ["restrictive formal wear that limits your world", "conventional travel clichés, safari jackets and cargo shorts", "dressing for only one climate or context"],
        ["climate-adaptive layers that regulate across hemispheres", "one truly innovative travel piece that replaces three conventional ones"],
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
        ["structural innovation over conventional authority symbols", "engineering-first construction that outperforms traditional tailoring", "authority earned through innovation, not inherited through heritage"],
        ["conventional power dressing from the old playbook", "traditional authority symbols worn without question", "hierarchy expressed through conventional status fabrics"],
        ["3D-knit suiting that outperforms traditional tailoring", "structural innovation visible in every seam"],
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
        ["wear something genuinely new, materials or shapes nobody expected", "materials that challenge the definition of clothing", "pure individuality over any group affiliation"],
        ["any outfit chosen to fit in or conform", "dressing to be accepted rather than to be yourself", "convention of any kind, including 'alternative' convention"],
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
        ["colour-shifting or photochromic materials for a soft surprise in daylight", "luminous fabrics that respond to their environment", "transcendent beauty through material innovation"],
        ["rigid materialistic dressing concerned only with status", "unimaginative conventional choices that ignore possibility", "treating clothing as mere function when it could be art"],
        ["one photochromic piece that shifts throughout the day", "luminous finishes that glow under different lights"],
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
        ["boldness filtered through beauty", "soft fabrics in strong colours", "directness tempered by empathy in every outfit choice"],
        ["harsh aggressive dressing that lacks emotional nuance", "blunt literal power-dressing with no soul", "force without grace"],
        ["a washed-silk tee in a powerful colour, strength and softness unified", "soft-edged red tones rather than fire-engine primaries"],
        {"textures": ["harsh stiff gabardine", "rigid power-suiting"], "colours": ["harsh primary red", "blunt aggressive brights"], "silhouettes": ["aggressive padded shoulders", "rigid power shapes"], "mood": ["harsh", "blunt", "aggressive", "soulless"]}
    ),
    "neptune_taurus": make_outer_entry(
        "enchanted, dream-quality, sensorially transcendent",
        ["cloud-weight", "dream finish", "impossible softness"],
        ["cloud-weight cashmere", "dream-finish silk charmeuse", "brushed alpaca"],
        ["scratchy cheap knits", "synthetic imitation luxury", "plasticky faux-silk"],
        [{"name": "misty green", "hex": "#8FBC8F"}],
        [{"name": "cream", "hex": "#FFFDD0"}],
        ["harsh synthetic colours", "cheap-feeling brights", "cold clinical tones"],
        ["rose gold"], ["jade", "opal"],
        ["impressionist botanical", "soft-focus floral"], ["hard-edged graphic", "stark geometric"],
        ["dreamy luxury", "sensory enchantment"],
        {"work": "quiet luxury so tactile it stops conversation", "intimate": "silk against skin, dreamlike softness, close-range sensory pull", "daily": "the softest version of every basic, elevated through touch"},
        ["prioritising fabrics that feel exceptional before they even look expensive", "choosing pieces that read refined from a distance and indulgent up close", "letting texture do the work instead of piling on detail"],
        ["harsh cheap fabrics that break the spell", "synthetic imitations of natural luxury", "prioritising visual over tactile beauty"],
        ["one cashmere piece so soft it feels imaginary", "silk base layers as daily enchantment"],
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
        ["sheer layers that create shifting colour effects", "prints that look different up close versus far away", "colours that change depending on the light"],
        ["literal single-meaning outfits", "blunt one-note colour statements", "humourless functional-only dressing"],
        ["sheer overlay that transforms the colour of everything underneath", "impressionist prints that evoke rather than depict"],
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
        ["trust the feeling a piece gives you over how it looks in a mirror", "pearl and ocean tones as emotional camouflage", "softness as emotional intelligence, not weakness"],
        ["dressing that ignores your emotional state", "cold clinical choices that shut down feeling", "uncomfortable clothing worn for others' expectations"],
        ["pearl-tone base layers as emotional foundation", "one piece kept because of how it makes you feel, not how it looks"],
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
        ["shimmer and light-catching as daily practice, not special-occasion-only", "gold tones as creative fuel", "drama expressed through light and softness, not volume"],
        ["dull pragmatic dressing that drains creative energy", "matte lifeless fabrics that absorb rather than reflect", "treating fashion as merely functional when it could inspire"],
        ["one shimmer piece that catches candlelight beautifully", "champagne-gold tones as a daily creative catalyst"],
        {"textures": ["dull matte basics", "heavy dark formal fabrics"], "colours": ["lifeless grey", "uninspired corporate tones"], "silhouettes": ["dull shapeless forms", "uninspired conventional cuts"], "mood": ["dull", "pragmatic", "uninspired", "lifeless"]}
    ),
    "neptune_virgo": make_outer_entry(
        "mindfully precise, organically refined",
        ["organic fibre", "mindful sourcing", "sustainable detail"],
        ["organic fine cotton", "sustainable silk", "mindfully sourced merino"],
        ["mass-produced synthetics", "chemically treated fabrics", "careless construction"],
        [{"name": "sage mist", "hex": "#9DC183"}],
        [{"name": "ivory", "hex": "#FFFFF0"}],
        ["garish synthetic colours", "carelessly dyed fabrics"],
        ["brushed silver"], ["peridot"],
        ["organic abstract", "nature-inspired minimalism"], ["chaotic loud prints", "careless random patterns"],
        ["mindfully precise", "organically refined"],
        {"work": "mindful excellence, every detail handled with care", "intimate": "close attention to weave, finish, and how the fabric settles on the body", "daily": "clean, intentional dressing with natural fibres and no wasted detail"},
        ["noticing weave, finish, and construction before you buy", "choosing natural fibres and careful sourcing over quick convenience", "keeping the look precise without making it feel severe"],
        ["careless mass-produced consumption", "synthetic fabrics chosen without thought for impact", "chaotic wardrobe entropy"],
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
        ["coldly practical choices that flatten the whole look", "graceless dressing that ignores line and movement", "harsh fabrics that fight the softness you need"],
        ["one flowing piece that makes ordinary life feel cinematic", "dream-pink or lavender as an emotional signature"],
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
        ["dark mystical motifs", "occult-inspired detail", "smoke-effect print"], ["cheerful florals", "bright lighthearted patterns"],
        ["deeply mystical", "veiled and layered"],
        {"work": "psychic power presence, dark authority filtered through otherworldly depth", "intimate": "mystic depth, dark sheer layers, the allure of the unknowable", "daily": "dark layered mystery, even casual carries undertones of the occult"},
        ["dark sheer layers that suggest without revealing", "mystical depth over surface-level darkness", "occult undertones in colour and detail"],
        ["cheerful surface-level dressing that ignores the depths", "shallow shiny status-dressing", "bright happy pieces worn as a mask over complexity"],
        ["dark sheer overlay that creates smoke-like depth", "mystic purple as an emotional frequency"],
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
        ["pieces collected on meaningful journeys, not shopping trips", "handwoven artisan work over machine-produced", "cultural respect expressed through careful curation"],
        ["tourist-shop souvenirs worn as 'global style'", "mass-produced prints that borrow cultural references without any care", "shallow travel aesthetics with no real engagement"],
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
        ["authority built with beautiful materials, not just serious ones", "midnight-blue over harsh black for soulful power", "structure that flows rather than constricts"],
        ["soulless corporate dressing that prioritises image over feeling", "harsh rigid formality with no beauty", "cold uninspired authority that lacks vision"],
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
        ["visionary digital", "collective dream motifs", "utopian pattern"], ["selfish status patterns", "conventional establishment prints"],
        ["visionary innovation", "collectively inspired"],
        {"work": "progressive style with a human point of view, polished but unmistakably modern", "intimate": "luminous finishes, unusual fabrics, softness with a futuristic edge", "daily": "forward-looking dressing built from smart materials and clear intention"},
        ["choosing materials that feel genuinely new, not just trend-led", "using luminous or recycled fabrics to make the outfit feel current", "keeping the look individual without losing wearability"],
        ["status dressing that hides behind expensive labels", "establishment style that feels finished before you arrive", "conformity dressed up as professionalism"],
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
        ["one translucent layer that transforms everything underneath into a dream", "choosing colour by instinct before logic"],
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
        ["timid dressing that clings to an old version of yourself", "surface-level change that avoids real transformation", "safe choices that preserve a self you have outgrown"],
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
        ["ruthless curation, if it does not transform you, it goes", "deep material quality as a form of personal power", "fewer pieces, each one transformatively good"],
        ["accumulating clothing without purpose", "keeping pieces out of guilt or nostalgia", "surface-level shopping that avoids the real work of curation"],
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
        ["style as strategic communication tool", "dual-face garments that reveal different sides to different audiences", "dark versatility over light variety"],
        ["static predictable messaging", "safe surface-level communication through clothing", "one-dimensional self-presentation"],
        ["a reversible piece that shows different faces to different contexts", "dark tonal versatility as communication strategy"],
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
        ["dark protective layers as emotional armour", "deep ocean tones for emotional depth", "clothing as a rebuilt shell after emotional transformation"],
        ["shallow cheerful dressing that masks real feelings", "surface-level emotional presentation", "cold clinical clothing that prevents vulnerability"],
        ["deep-sea tones as emotional signature", "protective layering as a daily ritual of rebuilt safety"],
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
        ["dim safe dressing that hides your transformation", "staying visually the same when everything inside has changed", "dimming your light for others' comfort"],
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
        ["obsessive attention to the details others never see, lining, stitching, inner construction", "dark precision over bright approximation", "quality verified at every level, including the ones no one sees"],
        ["accepting 'good enough' in construction or fit", "surface-level quality that hides poor fundamentals", "careless details in hidden areas"],
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
        ["dark elegant motifs", "deconstructed beauty patterns"], ["shallow decorative prints", "superficial pretty patterns"],
        ["transformed beauty", "darkly elegant"],
        {"work": "radical harmony, beauty as a form of power, not decoration", "intimate": "dark romantic intensity, beauty that has survived and deepened", "daily": "beauty with depth, dark rose over bright pink, earned elegance over inherited"},
        ["beauty as power, not prettiness", "dark elegance over superficial sparkle", "aesthetics that have been through fire and emerged stronger"],
        ["shallow surface-level prettiness without depth", "beauty as decoration rather than expression", "sparkle that distracts from substance"],
        ["dark rose tones as a signature of beauty-through-transformation", "deconstructed elegance that reveals hidden structure"],
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
        ["power totemic symbols", "dark alchemy motifs", "power sigils"], ["cheerful florals", "lighthearted patterns of any kind"],
        ["absolute power", "impenetrably dark"],
        {"work": "the person whose authority needs no introduction, dark, decisive, unquestionable", "intimate": "total intensity, absolute depth, the power of complete vulnerability through strength", "daily": "daily conviction in the deepest black you own, total, impenetrable, grounded"},
        ["power expressed through material quality, not volume", "the deepest blacks as a daily commitment", "concentrated dressing that leaves nothing accidental"],
        ["any softness not earned through strength", "vulnerability without purpose", "cheerful surface-level dressing that avoids the depths"],
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
        ["pieces earned through real experience, not purchased as souvenirs", "cultural depth through genuine engagement", "deep indigo as the colour of hard-won wisdom"],
        ["shallow cultural tourism in clothing", "surface-level philosophical posturing through accessories", "depth-as-aesthetic without real transformation"],
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
        ["treating construction as the source of authority, not labels", "choosing permanence over trends every single time", "keeping the palette dark enough that the cut does the talking"],
        ["surface-level authority through logos or labels", "impermanent trend-chasing in professional settings", "casual undermining of your own power"],
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
        ["status dressing that is only about exclusivity", "mainstream conformity presented as 'professionalism'", "luxury signals that do the thinking for you"],
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

for planet in ["venus", "moon", "sun", "mars"]:
    for house in range(1, 13):
        ctx = house_contexts[house]
        ordinal = {1: "st", 2: "nd", 3: "rd"}.get(house, "th")
        HOUSE_PLACEMENTS[f"{planet}_house_{house}"] = {
            "context": f"{planet.title()} in the {house}{ordinal} house: {ctx}",
            "modifier": HOUSE_MODIFIERS_PER_PLANET[planet][house]
        }

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
# COLOUR LIBRARY (80 named colours)
# ═══════════════════════════════════════════════════════════════

COLOUR_LIBRARY = {
    "bright red": {"hex": "#CC0000", "associations": ["aries", "mars", "fire"]},
    "fire red": {"hex": "#B22222", "associations": ["aries", "mars"]},
    "crimson": {"hex": "#DC143C", "associations": ["mars", "aries", "scorpio"]},
    "hot orange": {"hex": "#FF4500", "associations": ["aries", "leo", "fire"]},
    "coral": {"hex": "#FF6F61", "associations": ["aries", "venus_aries", "venus"]},
    "tangerine": {"hex": "#FF9966", "associations": ["aries", "leo", "fire"]},
    "burnt orange": {"hex": "#CC5500", "associations": ["leo", "fire", "sun"]},
    "warm amber": {"hex": "#FFBF00", "associations": ["leo", "sun", "jupiter"]},
    "gold": {"hex": "#FFD700", "associations": ["leo", "sun", "jupiter"]},
    "warm gold": {"hex": "#DAA520", "associations": ["leo", "sun"]},
    "dark gold": {"hex": "#B8860B", "associations": ["leo", "saturn"]},
    "molten gold": {"hex": "#B8860B", "associations": ["pluto", "leo"]},
    "lemon yellow": {"hex": "#FFF44F", "associations": ["gemini", "mercury", "air"]},
    "pale yellow": {"hex": "#FFFF99", "associations": ["gemini", "mercury"]},
    "golden yellow": {"hex": "#FFD700", "associations": ["leo", "mercury"]},
    "cream": {"hex": "#FFFDD0", "associations": ["taurus", "venus_taurus", "earth"]},
    "ivory": {"hex": "#FFFFF0", "associations": ["virgo", "venus_virgo"]},
    "warm white": {"hex": "#FAF0E6", "associations": ["aries", "venus_aries"]},
    "stark white": {"hex": "#FFFFFF", "associations": ["aries", "sun_aries"]},
    "pearl white": {"hex": "#F0EAD6", "associations": ["cancer", "moon", "pearl"]},
    "soft white": {"hex": "#FAFAFA", "associations": ["cancer", "moon"]},
    "shell white": {"hex": "#FFF5EE", "associations": ["cancer", "mars_cancer"]},
    "champagne": {"hex": "#F7E7CE", "associations": ["libra", "venus_libra"]},
    "blush": {"hex": "#DE5D83", "associations": ["cancer", "venus_cancer"]},
    "blush rose": {"hex": "#FFB7C5", "associations": ["pisces", "venus_pisces"]},
    "dusty rose": {"hex": "#DCAE96", "associations": ["libra", "moon_libra"]},
    "dusky pink": {"hex": "#CC8899", "associations": ["taurus", "moon_taurus"]},
    "rose pink": {"hex": "#FF66B2", "associations": ["libra", "venus_libra"]},
    "seashell pink": {"hex": "#FFF5EE", "associations": ["cancer", "moon_cancer"]},
    "pastel pink": {"hex": "#FFD1DC", "associations": ["libra", "mercury_libra"]},
    "dream pink": {"hex": "#FFB7C5", "associations": ["neptune", "libra"]},
    "holographic pink": {"hex": "#FF69B4", "associations": ["uranus", "libra"]},
    "dark rose": {"hex": "#B5495B", "associations": ["pluto", "libra"]},
    "rose gold tone": {"hex": "#B76E79", "associations": ["jupiter", "libra"]},
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
    "sky blue": {"hex": "#87CEEB", "associations": ["gemini", "air"]},
    "powder blue": {"hex": "#B0E0E6", "associations": ["libra", "venus_libra"]},
    "pale blue": {"hex": "#AEC6CF", "associations": ["cancer", "moon_cancer"]},
    "pale aqua": {"hex": "#ADE8F4", "associations": ["pisces", "venus_pisces"]},
    "cobalt blue": {"hex": "#0047AB", "associations": ["sagittarius", "venus_sagittarius"]},
    "electric blue": {"hex": "#7DF9FF", "associations": ["aquarius", "uranus"]},
    "neon blue": {"hex": "#1B03A3", "associations": ["mars_aquarius", "uranus"]},
    "deep blue": {"hex": "#00008B", "associations": ["sagittarius", "jupiter", "mars_cancer"]},
    "soft navy": {"hex": "#3B5998", "associations": ["virgo", "venus_virgo"]},
    "navy": {"hex": "#000080", "associations": ["capricorn", "saturn"]},
    "dark navy": {"hex": "#000080", "associations": ["capricorn", "moon_capricorn"]},
    "midnight": {"hex": "#191970", "associations": ["scorpio", "capricorn", "saturn"]},
    "midnight blue": {"hex": "#191970", "associations": ["neptune", "capricorn"]},
    "slate blue": {"hex": "#6A5ACD", "associations": ["capricorn", "saturn_cancer"]},
    "deep teal": {"hex": "#008080", "associations": ["sagittarius", "venus_sagittarius"]},
    "dark teal": {"hex": "#004953", "associations": ["scorpio", "moon_scorpio"]},
    "turquoise": {"hex": "#40E0D0", "associations": ["sagittarius", "moon_sagittarius"]},
    "neon teal": {"hex": "#00B5AD", "associations": ["jupiter", "aquarius"]},
    "electric teal": {"hex": "#00FFEF", "associations": ["uranus", "sagittarius"]},
    "seafoam": {"hex": "#93E9BE", "associations": ["pisces", "venus_pisces", "water"]},
    "sea glass": {"hex": "#B2D8D8", "associations": ["cancer", "venus_cancer"]},
    "mint": {"hex": "#98FF98", "associations": ["gemini", "moon_gemini"]},
    "neon lime": {"hex": "#CCFF00", "associations": ["aquarius", "venus_aquarius"]},
    "sage green": {"hex": "#9CAF88", "associations": ["taurus", "venus", "earth", "virgo"]},
    "sage": {"hex": "#9CAF88", "associations": ["virgo", "moon_virgo"]},
    "moss green": {"hex": "#8A9A5B", "associations": ["taurus", "moon_taurus"]},
    "forest green": {"hex": "#228B22", "associations": ["taurus", "venus_taurus"]},
    "deep olive": {"hex": "#556B2F", "associations": ["mars_taurus", "earth"]},
    "olive": {"hex": "#808000", "associations": ["mercury_taurus", "earth"]},
    "warm camel": {"hex": "#C19A6B", "associations": ["taurus", "venus_taurus"]},
    "dark camel": {"hex": "#A0785A", "associations": ["capricorn", "venus_capricorn"]},
    "warm brown": {"hex": "#8B6914", "associations": ["taurus", "earth"]},
    "dark brown": {"hex": "#3B2F2F", "associations": ["capricorn", "mars_capricorn", "saturn"]},
    "chocolate": {"hex": "#3B2F2F", "associations": ["venus_taurus", "earth"]},
    "warm ochre": {"hex": "#CC7722", "associations": ["sagittarius", "venus_sagittarius"]},
    "burnt sienna": {"hex": "#E97451", "associations": ["sagittarius", "venus_sagittarius"]},
    "warm sienna": {"hex": "#A0522D", "associations": ["sagittarius", "moon_sagittarius"]},
    "warm terracotta": {"hex": "#E2725B", "associations": ["moon_aries", "fire"]},
    "rust": {"hex": "#B7410E", "associations": ["mars_taurus", "earth"]},
    "copper": {"hex": "#B87333", "associations": ["mars_leo", "leo"]},
    "copper tone": {"hex": "#B87333", "associations": ["uranus", "taurus"]},
    "light copper": {"hex": "#D4956A", "associations": ["libra", "venus_libra"]},
    "warm taupe": {"hex": "#8B8589", "associations": ["virgo", "earth"]},
    "light grey": {"hex": "#D3D3D3", "associations": ["gemini", "moon_gemini"]},
    "soft grey": {"hex": "#B0B0B0", "associations": ["moon_virgo", "virgo"]},
    "warm grey": {"hex": "#808069", "associations": ["saturn", "cancer"]},
    "silver grey": {"hex": "#C0C0C0", "associations": ["aquarius", "venus_aquarius"]},
    "cool silver": {"hex": "#AAA9AD", "associations": ["aquarius", "moon_aquarius"]},
    "steel grey": {"hex": "#71797E", "associations": ["saturn_gemini", "saturn"]},
    "slate": {"hex": "#708090", "associations": ["moon_capricorn", "saturn"]},
    "stone grey": {"hex": "#928E85", "associations": ["saturn_virgo", "earth"]},
    "mineral grey": {"hex": "#928E85", "associations": ["uranus_virgo", "virgo"]},
    "dark steel": {"hex": "#4A4A4A", "associations": ["uranus_capricorn", "saturn"]},
    "obsidian grey": {"hex": "#3D3D3D", "associations": ["pluto_virgo", "pluto"]},
    "charcoal": {"hex": "#36454F", "associations": ["capricorn", "saturn", "earth"]},
    "dark charcoal": {"hex": "#333333", "associations": ["jupiter_capricorn", "saturn"]},
    "deep black": {"hex": "#0A0A0A", "associations": ["scorpio", "venus_scorpio", "pluto"]},
    "black": {"hex": "#0A0A0A", "associations": ["scorpio", "moon_scorpio"]},
    "jet black": {"hex": "#0A0A0A", "associations": ["saturn_capricorn", "saturn"]},
    "ink black": {"hex": "#1C1C1C", "associations": ["saturn_scorpio", "pluto"]},
    "abyss black": {"hex": "#050505", "associations": ["pluto_scorpio", "pluto"]},
    "power black": {"hex": "#1C1C1C", "associations": ["pluto_capricorn", "pluto"]},
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
    "silver shimmer": {"hex": "#D8D8D8", "associations": ["pisces", "venus_pisces"]},
    "soft silver": {"hex": "#C0C0C0", "associations": ["cancer", "sun_cancer"]},
    "silver": {"hex": "#C0C0C0", "associations": ["moon", "cancer", "water"]},
    "indigo": {"hex": "#4B0082", "associations": ["moon_sagittarius", "sagittarius"]},
    "deep indigo": {"hex": "#130A4F", "associations": ["pluto_sagittarius", "sagittarius"]},
    "ocean indigo": {"hex": "#4B0082", "associations": ["neptune_sagittarius", "sagittarius"]},
    "sea blue": {"hex": "#006994", "associations": ["mars_pisces", "pisces"]},
    "ocean blue": {"hex": "#006994", "associations": ["jupiter_pisces", "pisces"]},
    "ocean pearl": {"hex": "#E8E0D5", "associations": ["neptune_cancer", "cancer"]},
    "aurora green": {"hex": "#01796F", "associations": ["uranus_pisces", "pisces"]},
    "aurora blue": {"hex": "#0077B6", "associations": ["neptune_aquarius", "aquarius"]},
    "deep sea": {"hex": "#003545", "associations": ["pluto_cancer", "cancer"]},
    "deep earth": {"hex": "#3B2F2F", "associations": ["pluto_taurus", "earth"]},
    "sea green": {"hex": "#2E8B57", "associations": ["mercury_pisces", "pisces"]},
    "sage mist": {"hex": "#9DC183", "associations": ["neptune_virgo", "virgo"]},
    "misty green": {"hex": "#8FBC8F", "associations": ["neptune_taurus", "taurus"]},
    "iridescent white": {"hex": "#F0F8FF", "associations": ["uranus_cancer", "cancer"]},
    "sunset orange": {"hex": "#FF6347", "associations": ["moon_leo", "leo"]},
    "champagne gold": {"hex": "#F7E7CE", "associations": ["neptune_leo", "leo"]},
    "wheat": {"hex": "#F5DEB3", "associations": ["virgo", "venus_virgo"]},
    "neon yellow": {"hex": "#CCFF00", "associations": ["uranus_gemini", "gemini"]},
    "electric green": {"hex": "#00FF00", "associations": ["mars_aquarius", "aquarius"]},
    "rich emerald": {"hex": "#046307", "associations": ["jupiter_taurus", "taurus"]},
    "olive green": {"hex": "#808000", "associations": ["jupiter_virgo", "virgo"]},
    "royal red": {"hex": "#B22222", "associations": ["jupiter_aries", "aries"]},
    "bright teal": {"hex": "#008080", "associations": ["jupiter_gemini", "gemini"]},
    "pale violet": {"hex": "#DDA0DD", "associations": ["neptune_pisces", "pisces"]},
    "rose": {"hex": "#FF007F", "associations": ["mars_libra", "libra"]},
    "soft gold": {"hex": "#DAA520", "associations": ["mars_libra", "libra"]},
    "bright yellow": {"hex": "#FFD700", "associations": ["mars_gemini", "gemini"]},
    "clear red": {"hex": "#CC0000", "associations": ["mercury_aries", "aries"]},
    "deep electric": {"hex": "#1B03A3", "associations": ["uranus_scorpio", "scorpio"]},
    "deep navy": {"hex": "#000080", "associations": ["capricorn", "saturn_sagittarius"]},
    "electric gold": {"hex": "#FFD700", "associations": ["uranus_leo", "leo"]},
    "lemon": {"hex": "#FFF44F", "associations": ["mercury_gemini", "gemini"]},
    "misty grey": {"hex": "#B0B7BF", "associations": ["mars_pisces", "pisces"]},
    "peach": {"hex": "#FFDAB9", "associations": ["gemini", "venus_gemini"]},
    "pearl": {"hex": "#F0EAD6", "associations": ["cancer", "moon"]},
    "rich amber": {"hex": "#FFBF00", "associations": ["leo", "venus_leo"]},
    "royal gold": {"hex": "#FFD700", "associations": ["jupiter_aries", "leo"]},
    "teal": {"hex": "#008080", "associations": ["sagittarius", "venus_sagittarius"]},
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
    print(f"colour_library:   {cl_count} entries (expected 60-80)")

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

    output_path = "astrological_style_dataset.json"
    with open(output_path, "w") as f:
        json.dump(dataset, f, indent=2, ensure_ascii=False)
    print(f"\nWritten to {output_path}")
