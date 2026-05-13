import Foundation

enum VerdictRunner {

    static func run(
        payload: DailyFitPayload,
        report: DailyFitDiagnosticReport
    ) -> [VerdictRow] {
        var results: [VerdictRow] = []
        results.append(checkSourceContributions(report))
        results.append(checkScaleRanges(payload))
        results.append(checkPaletteUnique(payload))
        results.append(checkTarotRecency(report))
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

    // MARK: - Check 4: Tarot recency (7-day ring)

    private static func checkTarotRecency(_ report: DailyFitDiagnosticReport) -> VerdictRow {
        let selected = report.selectedTarotCard
        let profileId = report.profileIdentifier
        let historyDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cosmicfit-inspector")
        let historyFile = historyDir.appendingPathComponent("tarot-history.json")

        var history: [String: [String]] = [:]
        if let data = try? Data(contentsOf: historyFile),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            history = decoded
        }

        let ring = history[profileId] ?? []
        let recentCount = ring.count
        let last3 = Array(ring.suffix(3))
        let last7 = Array(ring.suffix(7))
        let inLast3 = last3.contains(selected)
        let inLast7 = last7.contains(selected)

        let status: String
        if inLast3 { status = "fail" }
        else if inLast7 { status = "partial" }
        else { status = "pass" }

        // Update ring
        var updatedRing = ring
        updatedRing.append(selected)
        if updatedRing.count > 14 { updatedRing = Array(updatedRing.suffix(14)) }
        history[profileId] = updatedRing

        try? FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)
        if let encoded = try? JSONEncoder().encode(history) {
            try? encoded.write(to: historyFile, options: .atomic)
        }

        return VerdictRow(
            id: "tarot_recency",
            status: status,
            expected: "not in previous 7 days (3d = fail)",
            actual: "\(selected) (history depth: \(recentCount))" + (inLast3 ? " — within 3d" : inLast7 ? " — within 7d" : ""),
            docRef: "docs/test_green_handoff.md#tarot-recency"
        )
    }
}
