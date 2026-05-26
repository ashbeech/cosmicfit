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
        metalTone: Double
    ) -> PersonalScalePresentation {
        PersonalScalePresentation(
            vibrancy: vibrancyEnvelope(blueprint: blueprint, calibration: calibration, mode: mode, value: vibrancy),
            contrast: contrastEnvelope(blueprint: blueprint, calibration: calibration, mode: mode, value: contrast),
            metalTone: metalToneEnvelope(blueprint: blueprint, calibration: calibration, mode: mode, value: metalTone)
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
        let minModulation: Double
        let maxModulation: Double

        switch mode {
        case .standard:
            minModulation = -0.4 * coeff
            maxModulation = 0.5 * coeff
        case .stage1Experimental:
            minModulation = -Stage1ScaleSensitivity.contrastMaxBlendNorm * coeff
            maxModulation = Stage1ScaleSensitivity.contrastMaxBlendNorm * coeff
        }

        let floor = clamp01(baseline + minModulation)
        let ceiling = clamp01(baseline + maxModulation)

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

        let minModulation: Double
        let maxModulation: Double

        switch mode {
        case .standard:
            let coeff = calibration.stage2Sensitivity.vibrancyCoeff
            minModulation = -1.0 * coeff
            maxModulation = (20.0 / 21.0) * coeff
        case .stage1Experimental:
            let maxVibeModulation = (20.0 / 21.0) * Stage1ScaleSensitivity.vibeScale
            let minVibeModulation = -1.0 * Stage1ScaleSensitivity.vibeScale
            let maxTempoMod = (Stage1ScaleSensitivity.tempoNormMax - 0.5) * Stage1ScaleSensitivity.tempoScale
            let minTempoMod = (Stage1ScaleSensitivity.tempoNormMin - 0.5) * Stage1ScaleSensitivity.tempoScale
            maxModulation = maxVibeModulation + maxTempoMod
            minModulation = minVibeModulation + minTempoMod
        }

        let floor = clamp01(baseline + minModulation)
        let ceiling = clamp01(baseline + maxModulation)

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

        let nudgeCap = mode == .stage1Experimental
            ? Stage1ScaleSensitivity.metalNudgeCap
            : Stage1ScaleSensitivity.metalNudgeCapStandard
        let lunarMetalMaxAbs = mode == .stage1Experimental
            ? Stage1ScaleSensitivity.lunarDegreeMaxAbs
            : 0.0
        let maxNudge = nudgeCap + Stage1ScaleSensitivity.lunarNamedPhaseNudge + lunarMetalMaxAbs

        let floor = clamp01(baseline - maxNudge)
        let ceiling = clamp01(baseline + maxNudge)

        let dp = computeDisplayPosition(value: value, floor: floor, ceiling: ceiling)
        let bp = computeDisplayPosition(value: baseline, floor: floor, ceiling: ceiling)

        return PersonalScaleEnvelope(
            kind: .metalTone, floor: floor, ceiling: ceiling,
            baseline: baseline, value: value,
            displayPosition: dp, baselinePosition: bp
        )
    }

    // MARK: - Helpers

    private static func clamp01(_ v: Double) -> Double {
        max(0.0, min(1.0, v))
    }
}
