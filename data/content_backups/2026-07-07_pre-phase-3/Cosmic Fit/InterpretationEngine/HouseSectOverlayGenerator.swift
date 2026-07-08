//
//  HouseSectOverlayGenerator.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Generates short, deterministic overlay strings from house placements and sect
//  data. Appended to specific narrative sections by BlueprintComposer.
//  All templates are jargon-free: no house numbers, planet names, or chart terms.
//
//  SG-1 (Phase 1c): all overlay text is gated through ChartAestheticProfile.
//  Register-variant MC text, orientation-variant Moon 11th-house text, and
//  register-variant domainPairImplication ensure appended sentences never
//  contradict the coarse cache prose. A final keyword screen suppresses any
//  overlay containing the profile's excluded keywords (overlay strings are
//  single positive-assertion sentences, so plain matching is sound here).
//

import Foundation

struct HouseSectOverlayGenerator {

    struct Overlays {
        let styleCoreAppend: String?
        let texturesSweetSpotAppend: String?
        let occasionsWorkAppend: String?
        let occasionsIntimateAppend: String?
        let occasionsDailyAppend: String?
    }

    static func generate(
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset,
        profile: ChartAestheticProfile
    ) -> Overlays {
        let venusOverlay = generateVenusOverlay(analysis: analysis, dataset: dataset)
        let moonOverlay = generateMoonOverlay(
            analysis: analysis, dataset: dataset, profile: profile
        )
        let sectOverlay = generateSectOverlay(sect: analysis.chartSect)
        let dominantOverlay = generateDominantHouseOverlay(
            analysis: analysis, profile: profile
        )

        var styleCoreAppend: String?
        var texturesSweetSpotAppend: String?
        var occasionsWorkAppend: String?
        var occasionsDailyAppend: String?

        // Venus overlay -> style_core
        if let venusText = venusOverlay {
            let combined = [venusText, sectOverlay].compactMap { $0 }.joined(separator: " ")
            styleCoreAppend = combined.isEmpty ? nil : combined
        } else {
            styleCoreAppend = sectOverlay
        }

        // Moon overlay -> routed by occasion_bias or fixed house fallback
        if let moonText = moonOverlay.text {
            if moonOverlay.routeToTextures {
                texturesSweetSpotAppend = moonText
            } else {
                occasionsDailyAppend = moonText
            }
        }

        // Dominant house summary -> occasions_work if top houses include public/routine,
        // otherwise occasions_daily
        if let domText = dominantOverlay {
            let workDomains: Set<String> = ["public", "routine", "resources"]
            let topDomains = analysis.houseEmphasis.dominantHouses.prefix(2).compactMap {
                ChartAnalyser.houseDomainLabel(for: $0)
            }
            if topDomains.contains(where: { workDomains.contains($0) }) {
                if let existing = occasionsWorkAppend {
                    occasionsWorkAppend = existing + " " + domText
                } else {
                    occasionsWorkAppend = domText
                }
            } else {
                if let existing = occasionsDailyAppend {
                    occasionsDailyAppend = existing + " " + domText
                } else {
                    occasionsDailyAppend = domText
                }
            }
        }

        // Midheaven overlay -> style_core (always) + occasions_work (when H10 not dominant)
        if let mcStyleCore = midheavenStyleCoreText(
            for: analysis.midheavenSign, profile: profile
        ) {
            if let existing = styleCoreAppend {
                styleCoreAppend = existing + " " + mcStyleCore
            } else {
                styleCoreAppend = mcStyleCore
            }
        }

        let house10Dominant = analysis.houseEmphasis.dominantHouses.prefix(2).contains(10)
        if !house10Dominant, let mcWork = midheavenWorkText(
            for: analysis.midheavenSign, profile: profile
        ) {
            if let existing = occasionsWorkAppend {
                occasionsWorkAppend = existing + " " + mcWork
            } else {
                occasionsWorkAppend = mcWork
            }
        }

        // Final lane screen (Phase 1e priority 1: suppress). Any overlay
        // sentence positively asserting one of the profile's excluded
        // keywords is dropped rather than appended against the cache prose.
        return Overlays(
            styleCoreAppend: screened(styleCoreAppend, profile: profile),
            texturesSweetSpotAppend: screened(texturesSweetSpotAppend, profile: profile),
            occasionsWorkAppend: screened(occasionsWorkAppend, profile: profile),
            occasionsIntimateAppend: nil,
            occasionsDailyAppend: screened(occasionsDailyAppend, profile: profile)
        )
    }

    // MARK: - Excluded-keyword screen (sentence-level suppress)

    /// Drops individual sentences that contain an excluded keyword; keeps
    /// the rest of the overlay. Overlay strings are short positive-assertion
    /// sentences (never Avoid/pass-over prose), so plain containment is the
    /// correct assertion-aware behaviour at this call site.
    static func screened(
        _ text: String?, profile: ChartAestheticProfile
    ) -> String? {
        guard let text else { return nil }
        guard !profile.excludedAestheticKeywords.isEmpty else { return text }
        let sentences = text.components(separatedBy: ". ")
        let kept = sentences.filter { sentence in
            let lowered = sentence.lowercased()
            return !profile.excludedAestheticKeywords.contains { keyword in
                lowered.contains(keyword.lowercased())
            }
        }
        guard !kept.isEmpty else { return nil }
        var result = kept.joined(separator: ". ")
        if !result.hasSuffix(".") { result += "." }
        return result
    }

    // MARK: - Venus Overlay (-> style_core)

    private static func generateVenusOverlay(
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset
    ) -> String? {
        guard let house = analysis.planetHouses["Venus"],
              let placement = dataset.housePlacements["venus_house_\(house)"] else { return nil }

        let domain = ChartAnalyser.houseDomainLabel(for: house) ?? "identity"
        let modifier = placement.modifier

        return "Your natural sense of beauty shows up most powerfully in your \(domainPhrase(domain)), \(modifier)."
    }

    // MARK: - Moon Overlay (-> textures_sweet_spot or occasions_daily)

    private static func generateMoonOverlay(
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset,
        profile: ChartAestheticProfile
    ) -> (text: String?, routeToTextures: Bool) {
        guard let house = analysis.planetHouses["Moon"],
              let placement = dataset.housePlacements["moon_house_\(house)"] else {
            return (nil, false)
        }

        // Moon in the 11th carries community language in the dataset
        // modifier; gate it by orientation so a self-contained chart never
        // reads "community softness / collective belonging" (Phase 1c).
        let modifier: String
        if house == 11 {
            switch profile.orientation {
            case .communityOriented:
                modifier = placement.modifier
            case .selfContained:
                modifier = "comfort that keeps a personal sanctuary intact even in shared settings"
            case .balanced:
                modifier = "comfort that works equally well alone or in good company"
            }
        } else {
            modifier = placement.modifier
        }

        let text = "Your comfort instinct gravitates toward \(modifier)."

        // Route by occasion_bias first, then fixed fallback
        let routeToTextures: Bool
        if let occasionBias = placement.occasionBias, occasionBias.contains("daily") {
            routeToTextures = false
        } else {
            let textureHouses: Set<Int> = [2, 4, 6, 12]
            routeToTextures = textureHouses.contains(house)
        }

        return (text, routeToTextures)
    }

    // MARK: - Sect Overlay (-> style_core)

    private static func generateSectOverlay(sect: ChartSect) -> String? {
        switch sect {
        case .day:
            return "Your style instincts lean toward clarity, structure, and visible polish."
        case .night:
            return "Your style instincts lean toward sensory richness, intuitive beauty, and tactile comfort."
        }
    }

    // MARK: - Dominant House Summary (-> occasions_work or occasions_daily)

    private static func generateDominantHouseOverlay(
        analysis: ChartAnalysis,
        profile: ChartAestheticProfile
    ) -> String? {
        let top2 = analysis.houseEmphasis.dominantHouses.prefix(2)
        guard top2.count == 2 else { return nil }

        let domain1 = ChartAnalyser.houseDomainLabel(for: top2[0]) ?? "identity"
        let domain2 = ChartAnalyser.houseDomainLabel(for: top2[1]) ?? "expression"

        let implication = domainPairImplication(
            domain1, domain2, register: profile.aestheticRegister
        )

        return "Your style energy concentrates in \(domain1) and \(domain2), so \(implication)."
    }

    // MARK: - Midheaven Overlay (-> style_core always, occasions_work conditionally)

    /// MC Sagittarius carries the loudest lane-specific language, so it is
    /// register-variant (Phase 1c). Other signs keep their single string;
    /// the excluded-keyword screen suppresses them for off-lane profiles
    /// (Phase 1e priority 1) until SG-3 regenerates their content.
    static func midheavenStyleCoreText(
        for sign: String, profile: ChartAestheticProfile
    ) -> String? {
        if sign == "Sagittarius" {
            switch profile.aestheticRegister {
            case .quietLuxury:
                return "Your public style carries a quietly authoritative scope; well-travelled taste shows in the quality of what you choose, not its volume."
            case .boldExpression:
                return "Your public style reads as bold and expansive; globally informed choices and adventurous scope signal confidence."
            case .versatileAdaptive:
                return "Your public style carries an open, well-travelled ease; range and curiosity read clearly in what you wear."
            }
        }
        switch sign {
        case "Aries":
            return "Your public style reads as bold and decisive; you make strong first impressions without trying too hard."
        case "Taurus":
            return "Your public style reads as quietly luxurious; tactile quality and understated expense signal before you speak."
        case "Gemini":
            return "Your public style reads as versatile and expressive; you communicate range and adaptability through what you wear."
        case "Cancer":
            return "Your public aesthetic relies on heavy silk crepe and soft draping to communicate a welcoming yet deeply polished presence."
        case "Leo":
            return "Your public style reads as radiant and confident; generous presence and visible polish are your natural mode."
        case "Virgo":
            return "You command a room through the razor-sharp precision of your tailoring and the impeccable finish of your minimalist wardrobe."
        case "Libra":
            return "Your public style reads as harmonious and elegant; social grace and balanced aesthetics are immediately legible."
        case "Scorpio":
            return "Your commanding public presence demands heavy leather outerwear and fiercely structured silhouettes that project absolute control."
        case "Capricorn":
            return "You project absolute authority through the structured lines of double-breasted blazers and the faultless drape of heavy wool trousers."
        case "Aquarius":
            return "Your distinctive public image relies on avant-garde silhouettes and unexpected hardware to establish a fiercely independent aesthetic."
        case "Pisces":
            return "Your public style reads as fluid and intuitive; soft elegance and imaginative beauty feel effortlessly composed."
        default:
            return nil
        }
    }

    static func midheavenWorkText(
        for sign: String, profile: ChartAestheticProfile
    ) -> String? {
        if sign == "Sagittarius" {
            switch profile.aestheticRegister {
            case .quietLuxury:
                return "At work, you signal your ambition through quietly considered pieces whose scope shows in craftsmanship rather than scale."
            case .boldExpression:
                return "At work, you signal your ambition and vision by wearing globally inspired pieces and bold silhouettes that project expansive confidence."
            case .versatileAdaptive:
                return "At work, you signal your ambition and vision through well-travelled, adaptable pieces that read as quietly confident range."
            }
        }
        switch sign {
        case "Aries":
            return "At work, lean into direct confidence; structured pieces and clean lines reinforce your natural authority."
        case "Taurus":
            return "You dominate your office environment by wearing investment-grade worsted wool and rich cashmere knits that communicate permanent luxury."
        case "Gemini":
            return "You maintain your professional agility by styling sharply cut separates with lightweight silk shirts for a flawlessly dynamic aesthetic."
        case "Cancer":
            return "You command your workplace by softening the rigorous structure of traditional suiting with fluid silks and tactile brushed cotton."
        case "Leo":
            return "At work, you project natural leadership by choosing commanding statement pieces finished with a generous polish."
        case "Virgo":
            return "At work, you instantly communicate competence by anchoring your wardrobe in impeccable tailoring and a meticulous, highly refined polish."
        case "Libra":
            return "At work, you command collaborative authority by dressing in balanced proportions and maintaining a harmonious colour palette for diplomatic elegance."
        case "Scorpio":
            return "At work, you command quiet respect through a powerful restraint, relying on deep colour tones and an impeccable finish."
        case "Capricorn":
            return "At work, you build lasting credibility by grounding your wardrobe in timeless tailoring and investment-grade workwear for a structured authority."
        case "Aquarius":
            return "At work, you signal your original leadership by embracing a distinctive innovation, combining an unconventional polish with forward-thinking sartorial choices."
        case "Pisces":
            return "At work, you communicate your intuitive intelligence by wearing creatively composed pieces and adopting a soft structure for empathetic fluidity."
        default:
            return nil
        }
    }

    // MARK: - Template Helpers

    private static func domainPhrase(_ domain: String) -> String {
        switch domain {
        case "identity":     return "personal identity"
        case "resources":    return "personal investments"
        case "expression":   return "everyday expression"
        case "foundations":  return "private world"
        case "creativity":   return "creative self-expression"
        case "routine":      return "daily rituals"
        case "partnership":  return "shared spaces"
        case "intensity":    return "transformative moments"
        case "philosophy":   return "broader vision"
        case "public":       return "public-facing identity"
        case "community":    return "community presence"
        case "retreat":      return "inner world"
        default:             return domain
        }
    }

    /// Register-variant implications (Phase 1c). Contract (Phase 1d, fixed
    /// at source): every returned string starts lowercase (it is
    /// interpolated after "so ") and carries NO trailing period — the
    /// `"...so \(implication)."` wrapper in generateDominantHouseOverlay
    /// supplies it. A trailing period here produced the ".." bug.
    static func domainPairImplication(
        _ d1: String,
        _ d2: String,
        register: ChartAestheticProfile.AestheticRegister
    ) -> String {
        let pair = Set([d1, d2])

        if pair.contains("public") && pair.contains("creativity") {
            switch register {
            case .quietLuxury:
                return "your wardrobe is at its best when refined pieces carry a quiet creative signature into visible settings"
            case .boldExpression:
                return "your wardrobe is at its best when it feels both expressive and camera-ready"
            case .versatileAdaptive:
                return "your wardrobe is at its best when creative pieces adapt cleanly to visible settings"
            }
        }
        if pair.contains("public") && pair.contains("routine") {
            switch register {
            case .quietLuxury:
                return "your most quietly refined tailoring doubles effortlessly as daily workwear"
            case .boldExpression:
                return "your sharpest tailored pieces and polished finishes double effortlessly as daily workhorses"
            case .versatileAdaptive:
                return "your most adaptable tailored pieces double effortlessly as daily workhorses"
            }
        }
        if pair.contains("identity") && pair.contains("creativity") {
            switch register {
            case .quietLuxury:
                return "you express your personal creativity best through subtle silhouettes and considered fabric pairings"
            case .boldExpression:
                return "you express your personal creativity best through daring silhouettes and unexpected fabric combinations"
            case .versatileAdaptive:
                return "you express your personal creativity best through flexible silhouettes and fresh fabric pairings"
            }
        }
        if pair.contains("partnership") && pair.contains("creativity") {
            switch register {
            case .quietLuxury:
                return "your most considered looks balance personal expression with a socially aware refinement"
            case .boldExpression:
                return "your most striking looks balance bold personal expression with a highly considered, socially aware aesthetic"
            case .versatileAdaptive:
                return "your most effective looks balance personal expression with a considered, socially aware aesthetic"
            }
        }
        if pair.contains("foundations") && pair.contains("retreat") {
            return "your wardrobe needs a strong private-comfort foundation before anything public-facing"
        }
        if pair.contains("resources") && pair.contains("routine") {
            return "quality daily-wear investments give you the most style return"
        }
        if pair.contains("intensity") && pair.contains("retreat") {
            switch register {
            case .quietLuxury:
                return "your most composed looks are reserved for intimate, private settings"
            case .boldExpression:
                return "you deliver your most devastatingly chic looks behind closed doors in intimate, high-stakes environments"
            case .versatileAdaptive:
                return "your most considered looks come together in intimate, private settings"
            }
        }
        if pair.contains("community") && pair.contains("expression") {
            switch register {
            case .quietLuxury:
                return "your clothes read most confident when they stay true to your own taste in shared settings"
            case .boldExpression:
                return "your clothes communicate absolute confidence when they signal both collective belonging and stark individuality"
            case .versatileAdaptive:
                return "your clothes work hardest when they move easily between group settings and personal expression"
            }
        }
        if pair.contains("public") && pair.contains("identity") {
            return "your personal brand and public image are deeply linked; dress accordingly"
        }
        if pair.contains("philosophy") {
            switch register {
            case .quietLuxury:
                return "you build an intelligent wardrobe by investing in quietly considered silhouettes and deeply intentional craftsmanship"
            case .boldExpression:
                return "you build an intelligent wardrobe by investing in globally inspired silhouettes and deeply intentional craftsmanship"
            case .versatileAdaptive:
                return "you build an intelligent wardrobe by investing in adaptable silhouettes and deeply intentional craftsmanship"
            }
        }

        return "your wardrobe is at its best when it reflects both \(d1) and \(d2)"
    }
}
