import Foundation

enum Thresholds {

    // MARK: - Canonical Thresholds (TS spec §9)

    static let depthLightMax     = -25
    static let depthMediumMax    =  34

    static let warmthCoolMax     = -18
    static let warmthWarmMin     =  18

    static let saturationSoftMax = -18
    static let saturationMutedMax =  5

    static let contrastLowMax    = -10
    static let contrastMediumMax =  19

    static let structureSoftMax  = -8
    static let structureBalancedMax = 15

    // MARK: - Derive Buckets (strict — for calibration regression)

    static func deriveDepth(_ score: Int) -> DepthLevel {
        if score <= depthLightMax { return .light }
        if score <= depthMediumMax { return .medium }
        return .deep
    }

    static func deriveTemperature(_ score: Int) -> Temperature {
        if score <= warmthCoolMax { return .cool }
        if score >= warmthWarmMin { return .warm }
        return .neutral
    }

    static func deriveSaturation(_ score: Int) -> Saturation {
        if score <= saturationSoftMax { return .soft }
        if score <= saturationMutedMax { return .muted }
        return .rich
    }

    static func deriveContrast(_ score: Int) -> ContrastLevel {
        if score <= contrastLowMax { return .low }
        if score <= contrastMediumMax { return .medium }
        return .high
    }

    static func deriveSurface(_ score: Int) -> SurfaceQuality {
        if score <= structureSoftMax { return .soft }
        if score <= structureBalancedMax { return .balanced }
        return .structured
    }

    static func deriveAll(from scores: RawVariableScores) -> DerivedVariables {
        DerivedVariables(
            depth: deriveDepth(scores.depth),
            temperature: deriveTemperature(scores.warmth),
            saturation: deriveSaturation(scores.saturation),
            contrast: deriveContrast(scores.contrast),
            surface: deriveSurface(scores.structure)
        )
    }
}
