#!/usr/bin/env python3
"""
Cosmic Fit — Extract Runtime Style Guide Strings

Extracts hardcoded user-visible strings from Swift source files into
data/style_guide/extracted_runtime_strings.json for the content audit engine.

Sources:
  - HouseSectOverlayGenerator.swift  (overlay templates appended to narratives)
  - StyleGuideViewController.swift   (fallback copy shown when blueprint is nil)

Usage:
    python3 tools/extract_runtime_style_guide_strings.py
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = REPO_ROOT / "data" / "style_guide" / "extracted_runtime_strings.json"

OVERLAY_SWIFT = "Cosmic Fit/InterpretationEngine/HouseSectOverlayGenerator.swift"
FALLBACK_SWIFT = "Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift"


def build():
    data = {"overlays": build_overlays(), "fallbacks": build_fallbacks()}
    OUTPUT.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    total = len(data["overlays"]) + len(data["fallbacks"])
    print(f"Extracted {total} strings → {OUTPUT}")


def build_overlays():
    entries = []

    # Sect overlays
    entries.append({
        "id": "overlay:sect.day",
        "text": "Your style instincts lean toward clarity, structure, and visible polish.",
        "swift_file": OVERLAY_SWIFT,
        "ui_section": "The Blueprint (appended)",
        "template_type": "fixed",
    })
    entries.append({
        "id": "overlay:sect.night",
        "text": "Your style instincts lean toward sensory richness, intuitive beauty, and tactile comfort.",
        "swift_file": OVERLAY_SWIFT,
        "ui_section": "The Blueprint (appended)",
        "template_type": "fixed",
    })

    # Venus overlay template (uses runtime domain + modifier)
    entries.append({
        "id": "overlay:venus_house",
        "text": "Your natural sense of beauty shows up most powerfully in your {domain}, {modifier}.",
        "swift_file": OVERLAY_SWIFT,
        "ui_section": "The Blueprint (appended)",
        "template_type": "template",
    })

    # Moon overlay template
    entries.append({
        "id": "overlay:moon_house",
        "text": "Your comfort instinct gravitates toward {modifier}.",
        "swift_file": OVERLAY_SWIFT,
        "ui_section": "The Textures — Sweet Spot / The Occasions — Daily (appended)",
        "template_type": "template",
    })

    # Dominant house overlay template
    entries.append({
        "id": "overlay:dominant_house",
        "text": "Your style energy concentrates in {domain1} and {domain2}, so {implication}.",
        "swift_file": OVERLAY_SWIFT,
        "ui_section": "The Occasions — Work / Daily (appended)",
        "template_type": "template",
    })

    # Midheaven style_core strings (12 signs)
    mc_style_core = {
        "Aries": "Your public style reads as bold and decisive; you make strong first impressions without trying too hard.",
        "Taurus": "Your public style reads as quietly luxurious; tactile quality and understated expense signal before you speak.",
        "Gemini": "Your public style reads as versatile and expressive; you communicate range and adaptability through what you wear.",
        "Cancer": "Your public style reads as warm and approachable; polished comfort signals care and emotional intelligence.",
        "Leo": "Your public style reads as radiant and confident; generous presence and visible polish are your natural mode.",
        "Virgo": "Your public style reads as refined and precise; quiet excellence and immaculate detail speak louder than flash.",
        "Libra": "Your public style reads as harmonious and elegant; social grace and balanced aesthetics are immediately legible.",
        "Scorpio": "Your public style reads as magnetic and controlled; depth, intensity, and polished restraint draw people in.",
        "Sagittarius": "Your public style reads as bold and expansive; globally informed choices and adventurous scope signal confidence.",
        "Capricorn": "Your public style reads as structured and authoritative; timeless polish and investment-grade quality define your image.",
        "Aquarius": "Your public style reads as distinctive and forward-thinking; modern edge and independent taste set you apart.",
        "Pisces": "Your public style reads as fluid and intuitive; soft elegance and imaginative beauty feel effortlessly composed.",
    }
    for sign, text in mc_style_core.items():
        entries.append({
            "id": f"overlay:midheaven_style_core.{sign.lower()}",
            "text": text,
            "swift_file": OVERLAY_SWIFT,
            "ui_section": "The Blueprint (appended)",
            "template_type": "fixed",
        })

    # Midheaven work strings (12 signs)
    mc_work = {
        "Aries": "At work, lean into direct confidence; structured pieces and clean lines reinforce your natural authority.",
        "Taurus": "At work, lean into quality and permanence; investment pieces and rich textures signal reliability and taste.",
        "Gemini": "At work, lean into adaptability; polished separates and communication-friendly styling keep you agile.",
        "Cancer": "At work, lean into approachable authority; soft structure and nurturing polish build trust without sacrificing presence.",
        "Leo": "At work, lean into commanding warmth; statement pieces with generous polish project leadership naturally.",
        "Virgo": "At work, lean into meticulous polish; impeccable tailoring and refined detail communicate competence instantly.",
        "Libra": "At work, lean into diplomatic elegance; balanced proportions and harmonious palettes support collaborative authority.",
        "Scorpio": "At work, lean into powerful restraint; deep tones, controlled intensity, and impeccable finish command respect quietly.",
        "Sagittarius": "At work, lean into expansive confidence; globally inspired pieces and bold scope signal vision and ambition.",
        "Capricorn": "At work, lean into structured authority; timeless tailoring and investment-grade workwear build lasting credibility.",
        "Aquarius": "At work, lean into distinctive innovation; unconventional polish and forward-thinking choices signal original leadership.",
        "Pisces": "At work, lean into empathetic fluidity; soft structure and creatively composed pieces communicate intuitive intelligence.",
    }
    for sign, text in mc_work.items():
        entries.append({
            "id": f"overlay:midheaven_work.{sign.lower()}",
            "text": text,
            "swift_file": OVERLAY_SWIFT,
            "ui_section": "The Occasions — Work (appended)",
            "template_type": "fixed",
        })

    # Domain pair implications
    implications = [
        ("public+creativity", "your wardrobe is at its best when it feels both expressive and camera-ready"),
        ("public+routine", "your wardrobe works hardest when polished pieces double as daily workhorses"),
        ("identity+creativity", "dressing is a core creative practice; lean into that"),
        ("partnership+creativity", "your style thrives when it balances personal expression with social harmony"),
        ("foundations+retreat", "your wardrobe needs a strong private-comfort foundation before anything public-facing"),
        ("resources+routine", "quality daily-wear investments give you the most style return"),
        ("intensity+retreat", "your strongest style moments happen in intimate, high-stakes settings"),
        ("community+expression", "your style communicates most when it signals belonging and individuality at once"),
        ("public+identity", "your personal brand and public image are deeply linked; dress accordingly"),
        ("philosophy+any", "your wardrobe benefits from globally inspired, intentional choices"),
    ]
    for pair_id, text in implications:
        entries.append({
            "id": f"overlay:domain_implication.{pair_id}",
            "text": text,
            "swift_file": OVERLAY_SWIFT,
            "ui_section": "Overlay (appended to occasions)",
            "template_type": "fixed",
        })

    return entries


def build_fallbacks():
    entries = []

    entries.append({
        "id": "fallback:style_core",
        "text": "Your presence works best when you treat your wardrobe as a public language. While you value the heavy and the settled, you use those qualities to set a standard for the people around you. You move through a room with the composure of someone who is teaching others how to appreciate quality. Your style works best when it feels like a long-term social legacy. This kind of intentional curation looks like a gift you are giving to your community.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Blueprint (fallback)",
        "format": "paragraph",
    })

    entries.append({
        "id": "fallback:textures_good",
        "text": "Go for fabrics with actual weight and integrity. Heavy gauge silks that feel cool and substantial provide the right anchor. Organic wools offer a proper architectural frame. Leather that is buttery and gains character with age belongs in your collection. They ground you, make you feel secure, and still look polished.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Textures — Good (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:textures_bad",
        "text": "Flimsy or disposable fabrics just do not suit you. If a material is scratchy or overly synthetic, it is a hard pass. Static-prone polyesters or stiff cottons that fight your natural movement are a distraction. If you have to spend your whole day messing with a garment to make it sit right, it is draining your energy.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Textures — Bad (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:textures_sweet_spot",
        "text": "Your absolute peak is a blend of the sturdy and the soft. Choose items that look high quality at a glance but feel like a secret luxury when touched. If it does not feel like a treat for your skin, it does not belong in your wardrobe.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Textures — Sweet Spot (fallback)",
        "format": "paragraph",
    })

    entries.append({
        "id": "fallback:palette_1",
        "text": "Your core colours are found in the natural world. Look for deep sage greens, sophisticated caramels, slate greys, and creamy neutrals. These tones provide a stable base for your personality to shine through. Accents work best when they feel weathered, muted, or mineral-toned.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Palette (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:palette_2",
        "text": "Flashes of considered tones like oxidised gold, dusty rose, or a deep burnt saffron add depth. Keep these accents as a highlight rather than the main story. They show that you are adventurous under the surface. It is about creating a look that stays timeless. Aim for colours that feel organic and permanent.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Palette (fallback para 2)",
        "format": "paragraph",
    })

    entries.append({
        "id": "fallback:occasions_work",
        "text": "Lean into your architectural side. Use clean lines and structured shapes to settle into the room. A properly made coat or a weighted layer that holds its shape is your best tool. You look best when you appear as the person who is definitely in charge.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Occasions — Work (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:occasions_intimate",
        "text": "Soften the edges when the sun goes down. Keep that solid base but introduce pieces with drape and mystery. Aim for quiet magnetism and close-range impact. Heavy silk or soft knits that move with you invite people to get a bit closer.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Occasions — Intimate (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:occasions_daily",
        "text": "Even casual looks need to look intentional. Ditch the mess for high-quality basics that allow you to move freely. You can do relaxed, but it should never look sloppy. Think of your daily look as the visionary on a day off: elevated and completely unbothered.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Occasions — Daily (fallback)",
        "format": "paragraph",
    })

    entries.append({
        "id": "fallback:hardware_metals",
        "text": "Your energy requires hardware with actual presence. Look for brushed gold, matte silver, or hammered bronze. Choose pieces that feel like they have some history. Heavy chains and matte surfaces that soak up the light are your best options.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Hardware — Metals (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:hardware_stones",
        "text": "Skip the perfectly clear gems. You suit stones that look like they were pulled directly from the earth. Raw emeralds, smoky quartz, and malachite work best. These natural inclusions make the pieces feel alive and connected to you.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Hardware — Stones (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:hardware_tip",
        "text": "One substantial anchor piece is always more powerful than a bunch of delicate items. Pick a signature like a heavy ring or a bold pendant and let it be the focal point.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Hardware — Tip (fallback)",
        "format": "paragraph",
    })

    # Code fallbacks
    for text in [
        "Trusting your body's first tactile reaction. If the fabric feels right against your skin, it is usually a win.",
        "Investing in the highest quality version of a piece you can afford.",
        "Using your style to communicate your values without saying a single word.",
        "Sticking to the three-year test: only buy things you can see yourself loving in 2029.",
    ]:
        entries.append({
            "id": f"fallback:code_leaninto.{len([e for e in entries if e['id'].startswith('fallback:code_leaninto')])}",
            "text": text,
            "swift_file": FALLBACK_SWIFT,
            "ui_section": "The Code — Lean Into (fallback)",
            "format": "bullet",
        })

    for text in [
        "Buying something just because it is a bargain. A deal is only a deal if the item is perfect.",
        "Chasing trends that clash with your natural composure. If it feels like a costume, it will look like one.",
        "Keeping your best pieces hidden. Your style works best when it is seen and shared.",
        "Flimsy or disposable fabrics that lack actual integrity.",
    ]:
        entries.append({
            "id": f"fallback:code_avoid.{len([e for e in entries if e['id'].startswith('fallback:code_avoid')])}",
            "text": text,
            "swift_file": FALLBACK_SWIFT,
            "ui_section": "The Code — Avoid (fallback)",
            "format": "bullet",
        })

    for text in [
        "How your style acts as a conversation starter in your daily environment.",
        "The way your physical home space influences your creative output.",
        "Making sure your outfit is actually comfortable. If you are constantly tugging at your clothes, you lose your edge.",
    ]:
        entries.append({
            "id": f"fallback:code_consider.{len([e for e in entries if e['id'].startswith('fallback:code_consider')])}",
            "text": text,
            "swift_file": FALLBACK_SWIFT,
            "ui_section": "The Code — Consider (fallback)",
            "format": "bullet",
        })

    # Accessory fallbacks
    for i, text in enumerate([
        "One significant piece carries more weight than five minor ones. Whether it is a heavy watch or a perfectly made bag, let that item be the anchor. This creates a focal point that allows the rest of your look to stay quiet.",
        "Accessories are where you introduce your most rigid lines. While your clothes might flow, your accessories should provide the structure. A stiff bag or a firm leather strap acts as the frame for your more fluid choices.",
        "Think about the sound and scent of your accessories. The weight of a heavy buckle or the specific smell of high-quality leather adds to the vibe. Style is a total sensory environment.",
    ]):
        entries.append({
            "id": f"fallback:accessory.{i}",
            "text": text,
            "swift_file": FALLBACK_SWIFT,
            "ui_section": f"The Accessory — Paragraph {i+1} (fallback)",
            "format": "paragraph",
        })

    # Pattern fallbacks
    entries.append({
        "id": "fallback:pattern_narrative",
        "text": "You do not really do busy prints. Anything too frantic fights your energy and looks forced. Your patterns need to feel like they have a pulse: organic, slightly blurred, or naturally occurring.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Pattern (fallback)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:pattern_extra_1",
        "text": "Look for large-scale and soft-focus prints. Marble textures or shadow checks where the lines are not quite sharp work well. You also suit classics like a large windowpane check in your neutral palette. The goal is a pattern that looks painted on rather than factory-made.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Pattern (fallback para 2)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:pattern_extra_2",
        "text": "Avoid tiny repetitive prints like polka dots. They look cluttered against your sophisticated aura. Stay away from anything neon or synthetic. If a pattern looks like it belongs on a disposable holiday shirt, it does not belong in your life.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Pattern (fallback para 3)",
        "format": "paragraph",
    })
    entries.append({
        "id": "fallback:pattern_tip",
        "text": "Use pattern as a texture. A tonal jacquard weave or a subtle embossed print is your secret weapon. It adds depth without screaming for attention.",
        "swift_file": FALLBACK_SWIFT,
        "ui_section": "The Pattern — Tip (fallback)",
        "format": "paragraph",
    })

    return entries


if __name__ == "__main__":
    build()
