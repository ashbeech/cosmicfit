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
}

struct BlueprintComposeResult: Equatable {
    let blueprint: CosmicBlueprint
    let diagnostics: BlueprintDiagnosticReport
}

enum BlueprintDiagnostics {

    static func report(
        from colourResult: ColourEngineResult,
        adaptedInput: ChartInputAdapter.AdaptedInput
    ) -> BlueprintDiagnosticReport {
        BlueprintDiagnosticReport(
            chartInput: adaptedInput.colourInput,
            boundaryFlags: adaptedInput.boundaryFlags,
            familyDecisionTrace: colourResult.trace,
            accentSlots: colourResult.accentSlots
        )
    }
}
