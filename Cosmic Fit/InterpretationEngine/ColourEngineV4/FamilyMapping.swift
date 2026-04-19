import Foundation

enum FamilyMapping {

    // MARK: - Public API

    static func mapToFamily(
        input: BirthChartColourInput,
        rawScores: RawVariableScores,
        overrideFlags: inout OverrideFlags
    ) -> PaletteFamily {
        let fa = countFireAir(input: input)
        let ew = countEarthWater(input: input)
        let d = rawScores.depth
        let w = rawScores.warmth
        let s = rawScores.saturation
        let c = rawScores.contrast
        let st = rawScores.structure

        let earthDepthCheck = Overrides.evaluateEarthDepthOverride(input: input)
        if earthDepthCheck.qualifyingForDeep || earthDepthCheck.qualifyingForMediumDeep {
            overrideFlags.earthDepthOverrideApplied = true
        }

        let family = classify(
            fa: fa, ew: ew, d: d, w: w, s: s, c: c, st: st, input: input
        )

        if family == .deepAutumn {
            if Overrides.shouldApplyWinterCompression(
                input: input,
                variables: FamilyProfiles.variables(for: .deepAutumn),
                rawScores: rawScores
            ) {
                overrideFlags.winterCompressionApplied = true
            }
        }

        return family
    }

    // MARK: - Top-Level Classification

    private static func classify(
        fa: Int, ew: Int,
        d: Int, w: Int, s: Int, c: Int, st: Int,
        input: BirthChartColourInput
    ) -> PaletteFamily {

        // True Winter: fa=3, ew=3 with very high contrast, cool, specific structure range
        if fa == 3 && ew == 3 && c >= 100 && w <= 5 && st >= 55 && st <= 97 && d <= 105 {
            return .trueWinter
        }

        // Soft Summer (conservative): very low saturation, high ew, moderate structure
        if s <= 0 && ew >= 3 && st <= 50 && d <= 70 {
            return .softSummer
        }

        if fa >= 4 {
            return classifyHighFireAir(d: d, w: w, s: s, c: c, st: st, input: input)
        }

        if fa <= 2 {
            return classifyHighEarthWater(d: d, w: w, s: s, c: c, st: st, input: input)
        }

        return classifyBalanced(d: d, w: w, s: s, c: c, st: st, input: input)
    }

    // MARK: - High Fire-Air (fa ≥ 4)

    private static func classifyHighFireAir(
        d: Int, w: Int, s: Int, c: Int, st: Int,
        input: BirthChartColourInput
    ) -> PaletteFamily {

        // DW stray: very deep, very cool, very high contrast
        if d >= 100 && c >= 100 && w <= -40 {
            return .deepWinter
        }

        // DA stray: deep, high contrast+structure, lower saturation
        if d >= 70 && c >= 100 && st >= 70 && s < 100 {
            return .deepAutumn
        }

        // TA stray: deep-ish, very high structure, warm, lower contrast
        if d >= 55 && st >= 80 && w >= 20 && c < 100 {
            return .trueAutumn
        }

        // DA sign-based stray: moderate-to-deep depth + high structure with
        // strong grounding sign signature (Scorpio asc or 2+ earth/water core signs)
        if d >= 46 && st >= 50 && hasDeepAutumnSignSignature(input: input) {
            return .deepAutumn
        }

        // Bright Winter: high contrast + high saturation with guards
        if c >= 84 && s >= 99 && w <= 80 && c <= 140 && d <= 93
            && (w >= 0 || d >= 40)
            && (w < 20 || c >= 100 || s >= 120) {
            return .brightWinter
        }

        // Light Spring at very low depth
        if d <= -15 && s >= 100 && w >= 10 && c >= 50 {
            return .lightSpring
        }

        // Light Summer: low depth, low structure, moderate contrast
        if d <= 8 && st <= 10 && c <= 75 && s >= 75 && (s >= 110 || d >= -15) {
            return .lightSummer
        }

        // True Spring at shallow depth
        if d >= -15 && d <= 10 {
            if w >= 150 && s >= 190 {
                return .trueSpring
            }
            if c + st >= 100 && w >= 44 && w <= 80 && s >= 100 {
                return .trueSpring
            }
            if s >= 102 && w >= 13 {
                return .lightSpring
            }
        }

        // True Spring at moderate-to-deep depth
        if d > 10 && w >= 44 && s >= 100 && c <= 94 && c + st <= 140 {
            return .trueSpring
        }

        // --- Stray family overrides (before BS catch-all) ---

        if c < 0 { return .trueSummer }
        if w < -35 { return .trueSummer }
        if s < 70 && w < 0 && st < 0 && d >= -10 && d <= 10 { return .trueSummer }
        if w >= 80 && s < 100 && c < 50 { return .softAutumn }
        if w < 0 && d < -20 && s >= 80 { return .softAutumn }
        if w >= 20 && w <= 30 && c >= 80 && c <= 95 && s >= 100 && st <= 40 { return .softAutumn }

        return .brightSpring
    }

    // MARK: - High Earth-Water (fa ≤ 2, ew ≥ 4)

    private static func classifyHighEarthWater(
        d: Int, w: Int, s: Int, c: Int, st: Int,
        input: BirthChartColourInput
    ) -> PaletteFamily {

        // Additional Soft Summer: low sat+contrast, moderate depth, some structure
        if s <= 50 && c <= 50 && d >= 20 && d <= 70 && st >= 5 {
            return .softSummer
        }

        // --- Deep group (d ≥ 85) ---
        if d >= 85 {
            // True Autumn stray at extreme depth+structure with negative sat
            if st >= 100 && s <= 0 {
                return .trueAutumn
            }
            // Deep Winter: specific patterns
            if s >= 80 || w <= -60 || d >= 145 {
                return .deepWinter
            }
            return .deepAutumn
        }

        // Deep Autumn at moderate-high depth + high structure
        if d >= 46 && st >= 50 {
            return .deepAutumn
        }

        // True Autumn: moderate depth, high structure, warm
        if d >= 30 && d <= 50 && st >= 50 && w >= 10 {
            return .trueAutumn
        }

        // Soft Autumn: warm-leaning with some saturation
        if w >= -15 && s >= 10 && d <= 80 {
            return .softAutumn
        }

        return .trueSummer
    }

    // MARK: - Balanced (fa = 3, ew = 3) — True Winter already handled

    private static func classifyBalanced(
        d: Int, w: Int, s: Int, c: Int, st: Int,
        input: BirthChartColourInput
    ) -> PaletteFamily {

        // Soft Summer stray: low sat + contrast, cool-leaning
        if s <= 50 && c <= 50 && w <= -2 {
            return .softSummer
        }

        // --- Deep group (d ≥ 85) ---
        if d >= 85 {
            if (d >= 105 && w <= 2) || (w <= -10 && c <= 100) {
                return .deepWinter
            }
            return .deepAutumn
        }

        // --- Medium-deep group (d ∈ [46, 84]) ---
        if d >= 46 {
            if w <= -70 { return .trueSummer }

            if w >= 95 { return .softAutumn }
            if c > 105 && w >= 20 { return .softAutumn }
            if s >= 85 && c < 85 && w >= 5 && w <= 30 && st <= 45 { return .softAutumn }

            if d >= 70 && st <= 45 && w >= 40 && c <= 55 { return .trueAutumn }

            if st >= 39 { return .deepAutumn }

            return .trueSummer
        }

        // Light Summer: low depth, low structure
        if d < 0 && st <= 10 {
            return .lightSummer
        }

        // Remaining: True Summer catch-all
        return .trueSummer
    }

    // MARK: - Element Counting

    private static let fireAirSigns: Set<V4ZodiacSign> = [
        .aries, .leo, .sagittarius, .gemini, .libra, .aquarius
    ]

    private static let earthWaterSigns: Set<V4ZodiacSign> = [
        .taurus, .virgo, .capricorn, .cancer, .scorpio, .pisces
    ]

    static func countFireAir(input: BirthChartColourInput) -> Int {
        let relevantKeys: [DriverKey] = [.ascendant, .venus, .sun, .moon, .mercury, .mars]
        return relevantKeys
            .compactMap { input.sign(for: $0) }
            .filter { fireAirSigns.contains($0) }
            .count
    }

    static func countEarthWater(input: BirthChartColourInput) -> Int {
        let relevantKeys: [DriverKey] = [.ascendant, .venus, .sun, .moon, .mercury, .mars]
        return relevantKeys
            .compactMap { input.sign(for: $0) }
            .filter { earthWaterSigns.contains($0) }
            .count
    }

    // MARK: - Sign-Level Helpers

    private static let groundingSigns: Set<V4ZodiacSign> = [
        .scorpio, .virgo, .capricorn, .taurus
    ]

    private static func hasDeepAutumnSignSignature(input: BirthChartColourInput) -> Bool {
        if input.ascendant.sign == .scorpio { return true }
        let groundingCount = [input.venus.sign, input.moon.sign]
            .filter { groundingSigns.contains($0) }
            .count
        return groundingCount >= 2
    }
}
