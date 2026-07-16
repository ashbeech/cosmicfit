//
//  PersonalScaleEnvelope.swift
//  Cosmic Fit
//
//  Personal scale envelope types and calculator. Computes user-relative
//  display positions for Vibrancy, Contrast, and Metal Tone from blueprint
//  variables and engine preset constants. Display-only — absolute engine
//  values on DailyFitPayload remain unchanged.
//

import Foundation

// MARK: - Types

enum PersonalScaleKind: String, Codable, Equatable {
    case vibrancy
    case contrast
    case metalTone
    case masculineFeminine
    case angularRounded
    case structuredDraped
}

struct PersonalScaleEnvelope: Codable, Equatable {
    let kind: PersonalScaleKind
    let floor: Double
    let ceiling: Double
    let baseline: Double
    let value: Double
    let displayPosition: Double
    let baselinePosition: Double
}

struct PersonalScalePresentation: Codable, Equatable {
    let vibrancy: PersonalScaleEnvelope
    let contrast: PersonalScaleEnvelope
    let metalTone: PersonalScaleEnvelope
    let masculineFeminine: PersonalScaleEnvelope?
    let angularRounded: PersonalScaleEnvelope?
    let structuredDraped: PersonalScaleEnvelope?
}

// MARK: - Calculator

enum PersonalScaleEnvelopeCalculator {

    // E1: degenerate range guard threshold
    private static let epsilon = 0.001

    static func makePresentation(
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode,
        vibrancy: Double,
        contrast: Double,
        metalTone: Double,
        silhouette: SilhouetteProfile? = nil
    ) -> PersonalScalePresentation {
        let silhouetteEnvelopes: (PersonalScaleEnvelope, PersonalScaleEnvelope, PersonalScaleEnvelope)?
        if let sil = silhouette {
            silhouetteEnvelopes = (
                silhouetteEnvelope(kind: .masculineFeminine, value: sil.masculineFeminine, baseline: sil.chartAnchorMF ?? 0.5),
                silhouetteEnvelope(kind: .angularRounded, value: sil.angularRounded, baseline: sil.chartAnchorAR ?? 0.5),
                silhouetteEnvelope(kind: .structuredDraped, value: sil.structuredDraped, baseline: sil.chartAnchorSD ?? 0.5)
            )
        } else {
            silhouetteEnvelopes = nil
        }

        return PersonalScalePresentation(
            vibrancy: vibrancyEnvelope(blueprint: blueprint, calibration: calibration, mode: mode, value: vibrancy),
            contrast: contrastEnvelope(blueprint: blueprint, calibration: calibration, mode: mode, value: contrast),
            metalTone: metalToneEnvelope(blueprint: blueprint, calibration: calibration, mode: mode, value: metalTone),
            masculineFeminine: silhouetteEnvelopes?.0,
            angularRounded: silhouetteEnvelopes?.1,
            structuredDraped: silhouetteEnvelopes?.2
        )
    }

    // MARK: - Display Position

    static func computeDisplayPosition(value: Double, floor: Double, ceiling: Double) -> Double {
        let range = ceiling - floor
        // E1: degenerate range → centre
        guard range >= epsilon else { return 0.5 }
        // E2: clamp overshoot from future engine tweaks
        return max(0.0, min(1.0, (value - floor) / range))
    }

    // MARK: - Contrast Envelope (§6.2)

    private static func contrastEnvelope(
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode,
        value: Double
    ) -> PersonalScaleEnvelope {
        let baseline: Double
        switch blueprint.palette.variables?.contrast {
        case .low:    baseline = 0.25
        case .medium: baseline = 0.50
        case .high:   baseline = 0.75
        case nil:     baseline = 0.50
        }

        let coeff = calibration.stage2Sensitivity.contrastCoeff
        let floor: Double
        let ceiling: Double

        switch mode {
        case .standard:
            let minModulation = -0.4 * coeff
            let maxModulation = 0.5 * coeff
            floor = clamp01(baseline + minModulation)
            ceiling = clamp01(baseline + maxModulation)
        case .stage1Experimental, .stage2SkyFidelity:
            let halfSpan = Stage1ScaleSensitivity.contrastPracticalHalfSpan
            floor = clamp01(baseline - halfSpan)
            ceiling = clamp01(baseline + halfSpan)
        }

        let dp = computeDisplayPosition(value: value, floor: floor, ceiling: ceiling)
        let bp = computeDisplayPosition(value: baseline, floor: floor, ceiling: ceiling)

        return PersonalScaleEnvelope(
            kind: .contrast, floor: floor, ceiling: ceiling,
            baseline: baseline, value: value,
            displayPosition: dp, baselinePosition: bp
        )
    }

    // MARK: - Vibrancy Envelope (§6.3)

    private static func vibrancyEnvelope(
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode,
        value: Double
    ) -> PersonalScaleEnvelope {
        let baseline: Double
        switch blueprint.palette.variables?.saturation {
        case .soft:  baseline = 0.25
        case .muted: baseline = 0.50
        case .rich:  baseline = 0.75
        case nil:    baseline = 0.50
        }

        let floor: Double
        let ceiling: Double

        switch mode {
        case .standard:
            let coeff = calibration.stage2Sensitivity.vibrancyCoeff
            let minModulation = -1.0 * coeff
            let maxModulation = (20.0 / 21.0) * coeff
            floor = clamp01(baseline + minModulation)
            ceiling = clamp01(baseline + maxModulation)
        case .stage1Experimental, .stage2SkyFidelity:
            let halfSpan = Stage1ScaleSensitivity.vibrancyPracticalHalfSpan
            floor = clamp01(baseline - halfSpan)
            ceiling = clamp01(baseline + halfSpan)
        }

        let dp = computeDisplayPosition(value: value, floor: floor, ceiling: ceiling)
        let bp = computeDisplayPosition(value: baseline, floor: floor, ceiling: ceiling)

        return PersonalScaleEnvelope(
            kind: .vibrancy, floor: floor, ceiling: ceiling,
            baseline: baseline, value: value,
            displayPosition: dp, baselinePosition: bp
        )
    }

    // MARK: - Metal Tone Envelope (§6.4)

    private static let warmMetalKeywords: Set<String> =
        ["gold", "brass", "copper", "bronze"]
    private static let coolMetalKeywords: Set<String> =
        ["silver", "platinum", "pewter", "white gold", "steel"]

    private static func metalToneEnvelope(
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode,
        value: Double
    ) -> PersonalScaleEnvelope {
        let tempVal: Double
        switch blueprint.palette.variables?.temperature {
        case .cool:    tempVal = 0.2
        case .neutral: tempVal = 0.5
        case .warm:    tempVal = 0.8
        case nil:      tempVal = 0.5
        }

        var warmCount = 0, coolCount = 0
        for metal in blueprint.hardware.recommendedMetals {
            let lower = metal.lowercased()
            if coolMetalKeywords.contains(where: { lower.contains($0) }) {
                coolCount += 1
            } else if warmMetalKeywords.contains(where: { lower.contains($0) }) {
                warmCount += 1
            }
        }
        let metalLean = Double(warmCount) / Double(max(1, warmCount + coolCount))
        let baseline = tempVal * 0.6 + metalLean * 0.4

        let nudgeCap = mode.usesSkyForwardPipeline
            ? Stage1ScaleSensitivity.metalNudgeCap
            : Stage1ScaleSensitivity.metalNudgeCapStandard
        let lunarMetalMaxAbs = mode.usesSkyForwardPipeline
            ? Stage1ScaleSensitivity.lunarDegreeMaxAbs
            : 0.0

        let floor: Double
        let ceiling: Double

        switch mode {
        case .stage1Experimental, .stage2SkyFidelity:
            let halfSpan = Stage1ScaleSensitivity.metalPracticalHalfSpan
            floor = clamp01(baseline - halfSpan)
            ceiling = clamp01(baseline + halfSpan)
        case .standard:
            let maxNudge = nudgeCap + Stage1ScaleSensitivity.lunarNamedPhaseNudge + lunarMetalMaxAbs
            floor = clamp01(baseline - maxNudge)
            ceiling = clamp01(baseline + maxNudge)
        }

        let dp = computeDisplayPosition(value: value, floor: floor, ceiling: ceiling)
        let bp = computeDisplayPosition(value: baseline, floor: floor, ceiling: ceiling)

        return PersonalScaleEnvelope(
            kind: .metalTone, floor: floor, ceiling: ceiling,
            baseline: baseline, value: value,
            displayPosition: dp, baselinePosition: bp
        )
    }

    // MARK: - Silhouette Envelopes (Plan 3 §3.2, Plan 4 per-user calibration)

    private static func silhouetteEnvelope(
        kind: PersonalScaleKind,
        value: Double,
        baseline: Double
    ) -> PersonalScaleEnvelope {
        let halfSpan: Double
        switch kind {
        case .structuredDraped:
            halfSpan = Stage1ScaleSensitivity.silhouetteSDPracticalHalfSpan
        default:
            halfSpan = Stage1ScaleSensitivity.silhouetteMFARPracticalHalfSpan
        }

        let floor = clamp01(baseline - halfSpan)
        let ceiling = clamp01(baseline + halfSpan)

        let dp = computeDisplayPosition(value: value, floor: floor, ceiling: ceiling)
        let bp = computeDisplayPosition(value: baseline, floor: floor, ceiling: ceiling)

        return PersonalScaleEnvelope(
            kind: kind, floor: floor, ceiling: ceiling,
            baseline: baseline, value: value,
            displayPosition: dp, baselinePosition: bp
        )
    }

    // MARK: - Helpers

    private static func clamp01(_ v: Double) -> Double {
        max(0.0, min(1.0, v))
    }
}
