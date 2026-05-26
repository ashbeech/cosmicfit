import Foundation

enum VerdictRunner {

    static func run(
        payload: DailyFitPayload,
        report: DailyFitDiagnosticReport,
        profileHash: String,
        targetDate: Date,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) -> [VerdictRow] {
        var results: [VerdictRow] = []
        results.append(checkSourceContributions(report))
        results.append(checkScaleRanges(payload))
        results.append(checkPaletteUnique(payload))
        results.append(checkTarotRecency(
            report: report,
            profileHash: profileHash,
            targetDate: targetDate,
            dailyFitEngineId: dailyFitEngineId
        ))
        results.append(checkDisplayPositionRange(report))
        return results
    }

    // MARK: - Check 1: Source contributions sum ≈ 1.0

    private static func checkSourceContributions(_ report: DailyFitDiagnosticReport) -> VerdictRow {
        let sc = report.sourceContributions
        let sum = sc.natalShare + sc.transitShare + sc.lunarShare + sc.progressedShare + sc.currentSunShare
        let pass = abs(sum - 1.0) < 0.005
        return VerdictRow(
            id: "source_contributions_normalised",
            status: pass ? "pass" : "fail",
            expected: "sum ≈ 1.0 (tol 0.005)",
            actual: String(format: "%.6f", sum),
            docRef: "docs/test_green_handoff.md#source-contributions"
        )
    }

    // MARK: - Check 2: Scale ranges

    private static func checkScaleRanges(_ payload: DailyFitPayload) -> VerdictRow {
        let inRange = (0...1).contains(payload.vibrancy) &&
                      (0...1).contains(payload.contrast) &&
                      (0...1).contains(payload.metalTone)
        let actual = "vibrancy=\(String(format: "%.3f", payload.vibrancy)) " +
                     "contrast=\(String(format: "%.3f", payload.contrast)) " +
                     "metalTone=\(String(format: "%.3f", payload.metalTone))"
        return VerdictRow(
            id: "vibrancy_contrast_metal_in_range",
            status: inRange ? "pass" : "fail",
            expected: "all in [0, 1]",
            actual: actual,
            docRef: "docs/test_green_handoff.md#scale-ranges"
        )
    }

    // MARK: - Check 3: Three unique palette colours

    private static func checkPaletteUnique(_ payload: DailyFitPayload) -> VerdictRow {
        let colours = payload.dailyPalette.colours
        let count = colours.count
        let names = Set(colours.map(\.name))
        let unique = names.count == count && count == 3
        return VerdictRow(
            id: "palette_three_unique",
            status: unique ? "pass" : "fail",
            expected: "3 distinct colours",
            actual: "\(count) colours, \(names.count) unique: \(colours.map(\.name).joined(separator: ", "))",
            docRef: "docs/test_green_handoff.md#palette-uniqueness"
        )
    }

    // MARK: - Check 4: Tarot recency (engine tracker)

    private static func checkTarotRecency(
        report: DailyFitDiagnosticReport,
        profileHash: String,
        targetDate: Date,
        dailyFitEngineId: String
    ) -> VerdictRow {
        let selected = report.selectedTarotCard
        let prior = TarotRecencyTracker.shared.getRecentSelections(
            profileHash: profileHash,
            referenceDate: targetDate,
            dailyFitEngineId: dailyFitEngineId
        ).filter { $0.daysAgo > 0 }

        let inLast3 = prior.contains { $0.cardName == selected && $0.daysAgo <= 3 }
        let inLast7 = prior.contains { $0.cardName == selected && $0.daysAgo <= 7 }
        let historyDepth = prior.count

        let status: String
        if inLast3 { status = "fail" }
        else if inLast7 { status = "partial" }
        else { status = "pass" }

        var detail = "\(selected) (history depth: \(historyDepth))"
        if inLast3 { detail += " — within 3d" }
        else if inLast7 { detail += " — within 7d" }

        return VerdictRow(
            id: "tarot_recency",
            status: status,
            expected: "not in previous 7 days (3d = fail)",
            actual: detail,
            docRef: "docs/test_green_handoff.md#tarot-recency"
        )
    }

    // MARK: - Check 5: Display positions in [0, 1] (non-blocking)

    private static func checkDisplayPositionRange(_ report: DailyFitDiagnosticReport) -> VerdictRow {
        guard let sp = report.personalScalePresentation else {
            return VerdictRow(
                id: "display_position_in_range",
                status: "info",
                expected: "all displayPosition ∈ [0, 1]",
                actual: "no scalePresentation (legacy payload)",
                docRef: nil
            )
        }
        let allOk = (0...1).contains(sp.vibrancy.displayPosition) &&
                    (0...1).contains(sp.contrast.displayPosition) &&
                    (0...1).contains(sp.metalTone.displayPosition)
        let actual = "vib=\(String(format: "%.3f", sp.vibrancy.displayPosition)) " +
                     "con=\(String(format: "%.3f", sp.contrast.displayPosition)) " +
                     "met=\(String(format: "%.3f", sp.metalTone.displayPosition))"
        return VerdictRow(
            id: "display_position_in_range",
            status: allOk ? "pass" : "warn",
            expected: "all displayPosition ∈ [0, 1]",
            actual: actual,
            docRef: nil
        )
    }
}
