//
//  BlueprintDiagnostics.swift
//  Cosmic Fit
//
//  Structured diagnostic trace for Style Guide (Blueprint) composition.
//  Inspector-only — not used in production UI paths.
//

import Foundation

/// Complete trace of a single Style Guide palette-engine run.
struct BlueprintDiagnosticReport: Codable, Equatable {
    let chartInput: BirthChartColourInput
    let boundaryFlags: [ChartInputAdapter.BoundaryFlag]
    let familyDecisionTrace: FamilyDecisionTrace
    let accentSlots: [AccentSlot]
    let depthOverlay: DepthOverlayResolver.OverlayResult
    let blackEligibility: BlackEligibilityResolver.BlackResult
    let midheavenSign: String
    let midheavenOverlayApplied: Bool

    init(
        chartInput: BirthChartColourInput,
        boundaryFlags: [ChartInputAdapter.BoundaryFlag],
        familyDecisionTrace: FamilyDecisionTrace,
        accentSlots: [AccentSlot],
        depthOverlay: DepthOverlayResolver.OverlayResult,
        blackEligibility: BlackEligibilityResolver.BlackResult = .ineligible,
        midheavenSign: String = "",
        midheavenOverlayApplied: Bool = false
    ) {
        self.chartInput = chartInput
        self.boundaryFlags = boundaryFlags
        self.familyDecisionTrace = familyDecisionTrace
        self.accentSlots = accentSlots
        self.depthOverlay = depthOverlay
        self.blackEligibility = blackEligibility
        self.midheavenSign = midheavenSign
        self.midheavenOverlayApplied = midheavenOverlayApplied
    }

    enum CodingKeys: String, CodingKey {
        case chartInput, boundaryFlags, familyDecisionTrace, accentSlots
        case depthOverlay, blackEligibility
        case midheavenSign, midheavenOverlayApplied
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.chartInput = try c.decode(BirthChartColourInput.self, forKey: .chartInput)
        self.boundaryFlags = try c.decode([ChartInputAdapter.BoundaryFlag].self, forKey: .boundaryFlags)
        self.familyDecisionTrace = try c.decode(FamilyDecisionTrace.self, forKey: .familyDecisionTrace)
        self.accentSlots = try c.decode([AccentSlot].self, forKey: .accentSlots)
        self.depthOverlay = try c.decode(DepthOverlayResolver.OverlayResult.self, forKey: .depthOverlay)
        self.blackEligibility = try c.decodeIfPresent(BlackEligibilityResolver.BlackResult.self, forKey: .blackEligibility) ?? .ineligible
        self.midheavenSign = try c.decodeIfPresent(String.self, forKey: .midheavenSign) ?? ""
        self.midheavenOverlayApplied = try c.decodeIfPresent(Bool.self, forKey: .midheavenOverlayApplied) ?? false
    }
}

struct BlueprintComposeResult: Equatable {
    let blueprint: CosmicBlueprint
    let diagnostics: BlueprintDiagnosticReport
}

enum BlueprintDiagnostics {

    static func report(
        from colourResult: ColourEngineResult,
        adaptedInput: ChartInputAdapter.AdaptedInput,
        midheavenSign: String = "",
        midheavenOverlayApplied: Bool = false
    ) -> BlueprintDiagnosticReport {
        BlueprintDiagnosticReport(
            chartInput: adaptedInput.colourInput,
            boundaryFlags: adaptedInput.boundaryFlags,
            familyDecisionTrace: colourResult.trace,
            accentSlots: colourResult.accentSlots,
            depthOverlay: colourResult.depthOverlay,
            blackEligibility: colourResult.blackEligibility,
            midheavenSign: midheavenSign,
            midheavenOverlayApplied: midheavenOverlayApplied
        )
    }
}
