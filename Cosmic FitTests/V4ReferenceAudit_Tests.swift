import XCTest
import Foundation
@testable import Cosmic_Fit

/// Audit harness for the original 100-user markdown reference dataset.
///
/// This suite is intentionally different from the frozen `v4_dataset.json`
/// regression gate:
/// - `V4CalibrationRegression_Tests` proves the current engine still matches the
///   checked-in V4 expectations.
/// - This file compares the *live* engine output back to the original markdown
///   handoff so we can quantify where the engine is stable, where it widens the
///   palette, and whether the final 20-swatch presentation still carries usable
///   light/deep range for real users.
final class V4ReferenceAudit_Tests: XCTestCase {

    // MARK: - Reference / Fixture Types

    private struct ReferenceRow: Codable {
        let id: String
        let birthData: String
        let location: String
        let family: String
        let secondaryPull: String?
        let depth: String
        let temperature: String
        let saturation: String
        let contrast: String
        let surface: String
        let cluster: String
        let neutrals: [String]
        let coreColours: [String]
        let accentColours: [String]
    }

    private struct PlacementRow: Codable {
        let id: String
        let placements: BirthChartColourInput
    }

    private struct BandMatchFlags: Codable {
        let family: Bool
        let secondaryPull: Bool
        let depth: Bool
        let temperature: Bool
        let saturation: Bool
        let contrast: Bool
        let surface: Bool
        let cluster: Bool
        let neutralsExact: Bool
        let coreExact: Bool
        let accentExact: Bool
    }

    private struct PresentedSwatch: Codable {
        let source: String
        let name: String
        let hex: String
    }

    private struct PresentedRange: Codable {
        let veryLightSwatchCount: Int
        let nearBlackSwatchCount: Int
        let literalBlackSwatchCount: Int
        let namedOffWhiteSwatchCount: Int
        let lightestSwatch: PresentedSwatch?
        let darkestSwatch: PresentedSwatch?
    }

    private struct RowAudit: Codable {
        let id: String
        let birthData: String
        let location: String
        let referenceFamily: String
        let liveFamily: String
        let referenceSecondaryPull: String?
        let liveSecondaryPull: String?
        let variationPull: String?
        let variationStrength: Int
        let substitutions: [VariationSubstitution]
        let matches: BandMatchFlags
        let referenceNeutrals: [String]
        let liveNeutrals: [String]
        let referenceCoreColours: [String]
        let liveCoreColours: [String]
        let referenceAccentColours: [String]
        let liveAccentColours: [String]
        let lightAnchor: String
        let deepAnchor: String
        let luminarySignature: String
        let rulerSignature: String
        let presentedSwatches: [PresentedSwatch]
        let presentedRange: PresentedRange
    }

    private struct FamilySummary: Codable {
        let family: String
        let rowCount: Int
        let secondaryPullMatches: Int
        let coreExactMatches: Int
        let accentExactMatches: Int
        let rowsWithVariation: Int
        let rowsWithLiteralBlack: Int
        let rowsWithNamedOffWhite: Int
        let rowsWithVeryLightSwatch: Int
        let rowsWithNearBlackSwatch: Int
        let averageVariationStrength: Double
    }

    private struct AuditSummary: Codable {
        let totalRows: Int
        let placementsFound: Int
        let familyMatches: Int
        let secondaryPullMatches: Int
        let depthMatches: Int
        let temperatureMatches: Int
        let saturationMatches: Int
        let contrastMatches: Int
        let surfaceMatches: Int
        let clusterMatches: Int
        let neutralsExactMatches: Int
        let coreExactMatches: Int
        let accentExactMatches: Int
        let rowsWithAnyVariation: Int
        let rowsWithVeryLightPresentedSwatch: Int
        let rowsWithNearBlackPresentedSwatch: Int
        let rowsWithLiteralBlackPresentedSwatch: Int
        let rowsWithNamedOffWhitePresentedSwatch: Int
        let averageVariationStrength: Double
        let maxVariationStrength: Int
        let familyBreakdown: [FamilySummary]
    }

    private struct AuditReport: Codable {
        let generatedAt: String
        let markdownReferencePath: String
        let placementsPath: String
        let summary: AuditSummary
        let rows: [RowAudit]
    }

    // MARK: - Public Test

    func testAuditCurrentEngineAgainstOriginalMarkdownReference() throws {
        print("[V4ReferenceAudit] Resolving local reference fixture")
        let referenceURL = try resolveReferenceFixtureURL()
        print("[V4ReferenceAudit] Loading reference rows from \(referenceURL.path)")
        let referenceRows = try loadReferenceRows(from: referenceURL)
        print("[V4ReferenceAudit] Loaded \(referenceRows.count) reference rows")
        let placements = try loadPlacements()
        print("[V4ReferenceAudit] Loaded \(placements.count) frozen placements")
        let placementLookup = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.placements) })

        var audits: [RowAudit] = []
        var missingPlacementIDs: [String] = []

        var familyMatches = 0
        var secondaryPullMatches = 0
        var depthMatches = 0
        var temperatureMatches = 0
        var saturationMatches = 0
        var contrastMatches = 0
        var surfaceMatches = 0
        var clusterMatches = 0
        var neutralsExactMatches = 0
        var coreExactMatches = 0
        var accentExactMatches = 0
        var rowsWithAnyVariation = 0
        var rowsWithVeryLightPresentedSwatch = 0
        var rowsWithNearBlackPresentedSwatch = 0
        var rowsWithLiteralBlackPresentedSwatch = 0
        var rowsWithNamedOffWhitePresentedSwatch = 0
        var totalVariationStrength = 0
        var maxVariationStrength = 0

        struct MutableFamilySummary {
            var rowCount = 0
            var secondaryPullMatches = 0
            var coreExactMatches = 0
            var accentExactMatches = 0
            var rowsWithVariation = 0
            var rowsWithLiteralBlack = 0
            var rowsWithNamedOffWhite = 0
            var rowsWithVeryLightSwatch = 0
            var rowsWithNearBlackSwatch = 0
            var totalVariationStrength = 0
        }

        var familySummaries: [String: MutableFamilySummary] = [:]

        for reference in referenceRows {
            guard let input = placementLookup[reference.id] else {
                missingPlacementIDs.append(reference.id)
                continue
            }

            let result = ColourEngine.evaluateStrict(input: input)
            let swatches = makePresentedSwatches(from: result)
            let presentedRange = makePresentedRange(from: swatches)

            let matches = BandMatchFlags(
                family: result.family.rawValue == reference.family,
                secondaryPull: result.secondaryPull?.rawValue == reference.secondaryPull,
                depth: result.variables.depth.rawValue == reference.depth,
                temperature: result.variables.temperature.rawValue == reference.temperature,
                saturation: result.variables.saturation.rawValue == reference.saturation,
                contrast: result.variables.contrast.rawValue == reference.contrast,
                surface: result.variables.surface.rawValue == reference.surface,
                cluster: result.cluster.rawValue == reference.cluster,
                neutralsExact: result.palette.neutrals == reference.neutrals,
                coreExact: result.palette.coreColours == reference.coreColours,
                accentExact: result.palette.accentColours == reference.accentColours
            )

            if matches.family { familyMatches += 1 }
            if matches.secondaryPull { secondaryPullMatches += 1 }
            if matches.depth { depthMatches += 1 }
            if matches.temperature { temperatureMatches += 1 }
            if matches.saturation { saturationMatches += 1 }
            if matches.contrast { contrastMatches += 1 }
            if matches.surface { surfaceMatches += 1 }
            if matches.cluster { clusterMatches += 1 }
            if matches.neutralsExact { neutralsExactMatches += 1 }
            if matches.coreExact { coreExactMatches += 1 }
            if matches.accentExact { accentExactMatches += 1 }

            let variationStrength = result.trace.variation.pullStrength
            totalVariationStrength += variationStrength
            maxVariationStrength = max(maxVariationStrength, variationStrength)
            if variationStrength > 0 { rowsWithAnyVariation += 1 }

            if presentedRange.veryLightSwatchCount > 0 { rowsWithVeryLightPresentedSwatch += 1 }
            if presentedRange.nearBlackSwatchCount > 0 { rowsWithNearBlackPresentedSwatch += 1 }
            if presentedRange.literalBlackSwatchCount > 0 { rowsWithLiteralBlackPresentedSwatch += 1 }
            if presentedRange.namedOffWhiteSwatchCount > 0 { rowsWithNamedOffWhitePresentedSwatch += 1 }

            var familySummary = familySummaries[reference.family] ?? MutableFamilySummary()
            familySummary.rowCount += 1
            if matches.secondaryPull { familySummary.secondaryPullMatches += 1 }
            if matches.coreExact { familySummary.coreExactMatches += 1 }
            if matches.accentExact { familySummary.accentExactMatches += 1 }
            if variationStrength > 0 { familySummary.rowsWithVariation += 1 }
            if presentedRange.literalBlackSwatchCount > 0 { familySummary.rowsWithLiteralBlack += 1 }
            if presentedRange.namedOffWhiteSwatchCount > 0 { familySummary.rowsWithNamedOffWhite += 1 }
            if presentedRange.veryLightSwatchCount > 0 { familySummary.rowsWithVeryLightSwatch += 1 }
            if presentedRange.nearBlackSwatchCount > 0 { familySummary.rowsWithNearBlackSwatch += 1 }
            familySummary.totalVariationStrength += variationStrength
            familySummaries[reference.family] = familySummary

            audits.append(
                RowAudit(
                    id: reference.id,
                    birthData: reference.birthData,
                    location: reference.location,
                    referenceFamily: reference.family,
                    liveFamily: result.family.rawValue,
                    referenceSecondaryPull: reference.secondaryPull,
                    liveSecondaryPull: result.secondaryPull?.rawValue,
                    variationPull: result.trace.variation.pullFamily,
                    variationStrength: variationStrength,
                    substitutions: result.trace.variation.substitutions,
                    matches: matches,
                    referenceNeutrals: reference.neutrals,
                    liveNeutrals: result.palette.neutrals,
                    referenceCoreColours: reference.coreColours,
                    liveCoreColours: result.palette.coreColours,
                    referenceAccentColours: reference.accentColours,
                    liveAccentColours: result.palette.accentColours,
                    lightAnchor: result.palette.lightAnchor,
                    deepAnchor: result.palette.deepAnchor,
                    luminarySignature: result.luminarySignature,
                    rulerSignature: result.rulerSignature,
                    presentedSwatches: swatches,
                    presentedRange: presentedRange
                )
            )
        }

        print("[V4ReferenceAudit] Completed live evaluation for \(audits.count) rows")

        let familyBreakdown = familySummaries
            .keys
            .sorted()
            .compactMap { family -> FamilySummary? in
                guard let summary = familySummaries[family] else { return nil }
                let averageVariationStrength = summary.rowCount == 0
                    ? 0
                    : Double(summary.totalVariationStrength) / Double(summary.rowCount)
                return FamilySummary(
                    family: family,
                    rowCount: summary.rowCount,
                    secondaryPullMatches: summary.secondaryPullMatches,
                    coreExactMatches: summary.coreExactMatches,
                    accentExactMatches: summary.accentExactMatches,
                    rowsWithVariation: summary.rowsWithVariation,
                    rowsWithLiteralBlack: summary.rowsWithLiteralBlack,
                    rowsWithNamedOffWhite: summary.rowsWithNamedOffWhite,
                    rowsWithVeryLightSwatch: summary.rowsWithVeryLightSwatch,
                    rowsWithNearBlackSwatch: summary.rowsWithNearBlackSwatch,
                    averageVariationStrength: roundTo3(averageVariationStrength)
                )
            }

        let summary = AuditSummary(
            totalRows: referenceRows.count,
            placementsFound: audits.count,
            familyMatches: familyMatches,
            secondaryPullMatches: secondaryPullMatches,
            depthMatches: depthMatches,
            temperatureMatches: temperatureMatches,
            saturationMatches: saturationMatches,
            contrastMatches: contrastMatches,
            surfaceMatches: surfaceMatches,
            clusterMatches: clusterMatches,
            neutralsExactMatches: neutralsExactMatches,
            coreExactMatches: coreExactMatches,
            accentExactMatches: accentExactMatches,
            rowsWithAnyVariation: rowsWithAnyVariation,
            rowsWithVeryLightPresentedSwatch: rowsWithVeryLightPresentedSwatch,
            rowsWithNearBlackPresentedSwatch: rowsWithNearBlackPresentedSwatch,
            rowsWithLiteralBlackPresentedSwatch: rowsWithLiteralBlackPresentedSwatch,
            rowsWithNamedOffWhitePresentedSwatch: rowsWithNamedOffWhitePresentedSwatch,
            averageVariationStrength: audits.isEmpty ? 0 : roundTo3(Double(totalVariationStrength) / Double(audits.count)),
            maxVariationStrength: maxVariationStrength,
            familyBreakdown: familyBreakdown
        )

        let report = AuditReport(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            markdownReferencePath: referenceURL.path,
            placementsPath: placementsFixtureURL()?.path ?? "missing:v4_placements.json",
            summary: summary,
            rows: audits
        )

        print("[V4ReferenceAudit] Writing audit report")
        try write(report: report)
        print("[V4ReferenceAudit] Audit report written")

        XCTAssertTrue(missingPlacementIDs.isEmpty, "Missing placements for: \(missingPlacementIDs.joined(separator: ", "))")
        XCTAssertEqual(audits.count, referenceRows.count, "Every reference row should have a frozen placement")

        // Hard behavioural contract: the live engine must preserve the original
        // family / variable / cluster assignments even if the palette surface
        // is widened by variation and anchors.
        XCTAssertEqual(familyMatches, referenceRows.count, "Family drift detected against the original markdown reference")
        XCTAssertEqual(depthMatches, referenceRows.count, "Depth drift detected against the original markdown reference")
        XCTAssertEqual(temperatureMatches, referenceRows.count, "Temperature drift detected against the original markdown reference")
        XCTAssertEqual(saturationMatches, referenceRows.count, "Saturation drift detected against the original markdown reference")
        XCTAssertEqual(contrastMatches, referenceRows.count, "Contrast drift detected against the original markdown reference")
        XCTAssertEqual(surfaceMatches, referenceRows.count, "Surface drift detected against the original markdown reference")
        XCTAssertEqual(clusterMatches, referenceRows.count, "Cluster drift detected against the original markdown reference")

        // Presentation range is intentionally *reported* rather than hard-gated.
        // This audit's purpose is to surface where the palette is tighter than
        // expected for real-world wearability, not to silently codify a guess.
    }

    // MARK: - Reference Loading

    private func resolveReferenceFixtureURL() throws -> URL {
        let env = ProcessInfo.processInfo.environment["V4_REFERENCE_FIXTURE_PATH"]
        var candidates: [String] = []
        if let env {
            candidates.append(env)
        }
        if let resolved = FixtureLocator.fixtureURL(named: "v4_markdown_reference.json") {
            candidates.append(resolved.path)
        }

        for candidate in candidates {
            let url = URL(fileURLWithPath: candidate)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        throw XCTSkip("""
            Reference fixture not found.
            Generate docs/fixtures/v4_markdown_reference.json or set V4_REFERENCE_FIXTURE_PATH.
            """)
    }

    private func loadReferenceRows(from url: URL) throws -> [ReferenceRow] {
        let data = try Data(contentsOf: url)
        let rows = try JSONDecoder().decode([ReferenceRow].self, from: data)
        XCTAssertEqual(rows.count, 100, "Expected exactly 100 reference rows in markdown dataset")
        return rows
    }

    // MARK: - Fixture Loading

    private func loadPlacements() throws -> [PlacementRow] {
        guard let placementsURL = placementsFixtureURL() else {
            throw XCTSkip("v4_placements.json not found in docs/fixtures or docs/archive/fixtures")
        }
        let data = try Data(contentsOf: placementsURL)
        return try JSONDecoder().decode([PlacementRow].self, from: data)
    }

    private func placementsFixtureURL() -> URL? {
        FixtureLocator.fixtureURL(named: "v4_placements.json")
    }

    private func fixturesDirectoryURL() -> URL {
        FixtureLocator.primaryFixturesDirectory()
    }

    // MARK: - Report Construction

    private func makePresentedSwatches(from result: ColourEngineResult) -> [PresentedSwatch] {
        var swatches: [PresentedSwatch] = []

        var nonAccentNames = Set<String>()
        for name in result.palette.neutrals { nonAccentNames.insert(name.lowercased()) }
        for name in result.palette.coreColours { nonAccentNames.insert(name.lowercased()) }
        if let support = result.palette.supportColours {
            for name in support { nonAccentNames.insert(name.lowercased()) }
        }
        nonAccentNames.insert(result.palette.lightAnchor.lowercased())
        nonAccentNames.insert(result.palette.deepAnchor.lowercased())

        let accentLabels: [String]
        if result.accentSlots.isEmpty {
            accentLabels = PaletteLibrary.deduplicatedAccentLabelsFromTemplate(
                names: result.palette.accentColours,
                claimedTemplateNames: nonAccentNames
            )
        } else {
            accentLabels = PaletteLibrary.deduplicatedAccentLabels(
                slots: result.accentSlots,
                templateNames: Array(nonAccentNames),
                claimedTemplateNames: nonAccentNames
            )
        }

        for (index, name) in result.palette.neutrals.enumerated() {
            swatches.append(makeSwatch(source: "neutral[\(index)]", name: name, hex: PaletteLibrary.hex(for: name)))
        }
        for (index, name) in result.palette.coreColours.enumerated() {
            swatches.append(makeSwatch(source: "core[\(index)]", name: name, hex: PaletteLibrary.hex(for: name)))
        }
        if result.accentSlots.isEmpty {
            for (index, label) in accentLabels.enumerated() {
                let originalName = result.palette.accentColours[index]
                swatches.append(makeSwatch(source: "accent[\(index)]", name: label, hex: PaletteLibrary.hex(for: originalName)))
            }
        } else {
            for (index, slot) in result.accentSlots.enumerated() {
                let label = index < accentLabels.count ? accentLabels[index] : slot.displayName
                swatches.append(makeSwatch(source: "accent[\(index)]", name: label, hex: slot.hex))
            }
        }
        for (index, name) in (result.palette.supportColours ?? []).enumerated() {
            swatches.append(makeSwatch(source: "support[\(index)]", name: name, hex: PaletteLibrary.hex(for: name)))
        }

        swatches.append(makeSwatch(
            source: "lightAnchor", name: result.palette.lightAnchor, hex: PaletteLibrary.hex(for: result.palette.lightAnchor)
        ))
        swatches.append(makeSwatch(
            source: "deepAnchor", name: result.palette.deepAnchor, hex: PaletteLibrary.hex(for: result.palette.deepAnchor)
        ))

        var claimed = Set<String>()
        for s in swatches { claimed.insert(s.name.lowercased()) }
        let sig = PaletteLibrary.signaturePairLabels(
            luminaryHex: result.luminarySignature,
            rulerHex: result.rulerSignature,
            claimedTemplateNames: claimed
        )
        swatches.append(makeSwatch(source: "luminarySignature", name: sig.luminary, hex: result.luminarySignature))
        swatches.append(makeSwatch(source: "rulerSignature", name: sig.ruler, hex: result.rulerSignature))

        return swatches
    }

    private func makeSwatch(source: String, name: String, hex: String) -> PresentedSwatch {
        PresentedSwatch(source: source, name: name, hex: hex)
    }

    private func makePresentedRange(from swatches: [PresentedSwatch]) -> PresentedRange {
        let analysed = swatches.compactMap { swatch -> (PresentedSwatch, lab: (L: Double, a: Double, b: Double))? in
            guard let lab = ColourMath.hexToLab(swatch.hex) else { return nil }
            return (swatch, lab)
        }

        let veryLight = analysed.filter { $0.lab.L >= 88.0 }
        let nearBlack = analysed.filter { $0.lab.L <= 18.0 }
        let literalBlack = swatches.filter { $0.name.lowercased() == "black" }
        let namedOffWhite = swatches.filter { Self.offWhiteNames.contains($0.name.lowercased()) }

        let lightest = analysed.max { lhs, rhs in lhs.lab.L < rhs.lab.L }?.0
        let darkest = analysed.min { lhs, rhs in lhs.lab.L < rhs.lab.L }?.0

        return PresentedRange(
            veryLightSwatchCount: veryLight.count,
            nearBlackSwatchCount: nearBlack.count,
            literalBlackSwatchCount: literalBlack.count,
            namedOffWhiteSwatchCount: namedOffWhite.count,
            lightestSwatch: lightest,
            darkestSwatch: darkest
        )
    }

    private func write(report: AuditReport) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(report)

        let jsonURL = fixturesDirectoryURL().appendingPathComponent("v4_markdown_reference_audit.json")
        try jsonData.write(to: jsonURL, options: [.atomic])

        let markdownURL = fixturesDirectoryURL().appendingPathComponent("v4_markdown_reference_audit.md")
        let markdown = renderMarkdown(report: report)
        try markdown.write(to: markdownURL, atomically: true, encoding: .utf8)

        print("Wrote V4 markdown reference audit to:")
        print("  \(jsonURL.path)")
        print("  \(markdownURL.path)")
    }

    private func renderMarkdown(report: AuditReport) -> String {
        let summary = report.summary
        let topRows = report.rows
            .sorted {
                if $0.variationStrength != $1.variationStrength {
                    return $0.variationStrength > $1.variationStrength
                }
                return $0.id < $1.id
            }
            .prefix(12)

        var lines: [String] = []
        lines.append("# V4 Markdown Reference Audit")
        lines.append("")
        lines.append("- Generated: \(report.generatedAt)")
        lines.append("- Markdown reference: `\(report.markdownReferencePath)`")
        lines.append("- Frozen placements: `\(report.placementsPath)`")
        lines.append("")
        lines.append("## Summary")
        lines.append("")
        lines.append("- Rows audited: \(summary.totalRows)")
        lines.append("- Family matches: \(summary.familyMatches)/\(summary.totalRows)")
        lines.append("- Secondary pull matches: \(summary.secondaryPullMatches)/\(summary.totalRows)")
        lines.append("- Variable matches: depth \(summary.depthMatches), temperature \(summary.temperatureMatches), saturation \(summary.saturationMatches), contrast \(summary.contrastMatches), surface \(summary.surfaceMatches)")
        lines.append("- Cluster matches: \(summary.clusterMatches)/\(summary.totalRows)")
        lines.append("- Exact triad matches vs markdown: neutrals \(summary.neutralsExactMatches), core \(summary.coreExactMatches), accent \(summary.accentExactMatches)")
        lines.append("- Rows with any variation: \(summary.rowsWithAnyVariation)/\(summary.totalRows)")
        lines.append("- Presented palettes with very-light swatch: \(summary.rowsWithVeryLightPresentedSwatch)/\(summary.totalRows)")
        lines.append("- Presented palettes with near-black swatch: \(summary.rowsWithNearBlackPresentedSwatch)/\(summary.totalRows)")
        lines.append("- Presented palettes with literal black swatch: \(summary.rowsWithLiteralBlackPresentedSwatch)/\(summary.totalRows)")
        lines.append("- Presented palettes with named off-white swatch: \(summary.rowsWithNamedOffWhitePresentedSwatch)/\(summary.totalRows)")
        lines.append("- Average variation strength: \(summary.averageVariationStrength)")
        lines.append("- Max variation strength: \(summary.maxVariationStrength)")
        lines.append("")
        lines.append("## Family Breakdown")
        lines.append("")
        lines.append("| Family | Rows | Pull match | Core exact | Accent exact | Any variation | Literal black | Named off-white | Very light | Near black | Avg variation |")
        lines.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")

        for family in summary.familyBreakdown {
            lines.append("| \(family.family) | \(family.rowCount) | \(family.secondaryPullMatches) | \(family.coreExactMatches) | \(family.accentExactMatches) | \(family.rowsWithVariation) | \(family.rowsWithLiteralBlack) | \(family.rowsWithNamedOffWhite) | \(family.rowsWithVeryLightSwatch) | \(family.rowsWithNearBlackSwatch) | \(family.averageVariationStrength) |")
        }

        lines.append("")
        lines.append("## Highest-Variation Rows")
        lines.append("")

        for row in topRows {
            let substitutions = row.substitutions.map {
                "\($0.band)[\($0.slotIndex)] \($0.originalColour) -> \($0.replacedWith) (\($0.fromFamily))"
            }
            let substitutionSummary = substitutions.isEmpty ? "none" : substitutions.joined(separator: "; ")
            lines.append("- `\(row.id)` — ref \(row.referenceFamily) / live \(row.liveFamily), reference pull `\(row.referenceSecondaryPull ?? "nil")`, live pull `\(row.liveSecondaryPull ?? "nil")`, variation strength \(row.variationStrength), substitutions: \(substitutionSummary)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static let offWhiteNames: Set<String> = [
        "warm white",
        "warm ivory",
        "clear ivory",
        "soft white",
        "optic white",
        "bright white",
        "smoke white",
        "bone",
        "warm cream",
        "cool ivory",
        "hard white",
        "buttercream",
        "oatmeal",
    ]

    private func roundTo3(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }
}
