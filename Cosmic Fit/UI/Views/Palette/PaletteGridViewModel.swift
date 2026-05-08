import Foundation

enum PaletteGridViewModel {

    /// Build a two-section `PaletteGrid` from a `PaletteSection`.
    ///
    /// Section 1 — "Personal Palette": neutrals + core + support +
    ///   light/deep anchors + luminary/ruler signatures, ordered by a
    ///   perceptual nearest-neighbour chain in CIE Lab space (lightest
    ///   seed, greedy fill, 2-opt refinement). Up to 16 cells laid out
    ///   in a 4-column grid.
    ///
    /// Section 2 — "Accent Colours": the four accent colours in
    ///   template order (no Lab sort — template order is intentional).
    ///   Single row, 4 columns.
    /// Perceptual distance below which two hexes are considered duplicates.
    /// Delta-E ~4 (squared = 16) is barely distinguishable on a phone screen.
    private static let dedupThresholdSquared: Double = 16.0

    static func build(from section: PaletteSection) -> PaletteGrid {
        let signatureExtras: [BlueprintColour] = [
            section.luminarySignature, section.rulerSignature
        ].compactMap { $0 }

        let middleAnchors: [BlueprintColour] =
            (section.neutrals ?? []) +
            section.coreColours +
            (section.supportColours ?? []) +
            signatureExtras

        let lightAnchorCell: PaletteCell? = section.lightAnchor.map {
            PaletteCell(kind: .filled(hex: $0.hexValue, anchorName: $0.name))
        }
        let deepAnchorCell: PaletteCell? = section.deepAnchor.map {
            PaletteCell(kind: .filled(hex: $0.hexValue, anchorName: $0.name))
        }

        let middleCells = buildLabChainCells(from: middleAnchors, padTo: 0)

        var mainCells: [PaletteCell] = []
        if let light = lightAnchorCell { mainCells.append(light) }
        mainCells.append(contentsOf: middleCells)
        if let deep = deepAnchorCell { mainCells.append(deep) }

        var seenHexes: [String] = []
        mainCells = dedup(mainCells, seen: &seenHexes)
        mainCells = padCells(Array(mainCells.prefix(16)), to: 16)

        let accentCells = section.accentColours.map { colour in
            PaletteCell(kind: .filled(hex: colour.hexValue, anchorName: colour.name))
        }
        let dedupedAccentCells = dedup(accentCells, seen: &seenHexes)
        let paddedAccentCells = padCells(dedupedAccentCells, to: 4)

        return PaletteGrid(sections: [
            PaletteGrid.Section(title: "Core Palette", cells: mainCells, columnCount: PaletteGrid.columnCount),
            PaletteGrid.Section(title: "Accent Colours", cells: paddedAccentCells, columnCount: PaletteGrid.columnCount),
        ])
    }

    /// Remove filled cells whose hex is perceptually identical to one already seen.
    private static func dedup(_ cells: [PaletteCell], seen: inout [String]) -> [PaletteCell] {
        cells.filter { cell in
            guard case .filled(let hex, _) = cell.kind else { return true }
            let isDuplicate = seen.contains { ColourMath.labDistanceSquared(hex, $0) < dedupThresholdSquared }
            if !isDuplicate { seen.append(hex) }
            return !isDuplicate
        }
    }

    static let malformedHexFallback: String = "#808080"

    // MARK: - Lab-chain cell builder

    private static func buildLabChainCells(from anchors: [BlueprintColour], padTo count: Int) -> [PaletteCell] {
        var parseable: [ParsedAnchor] = []
        var malformed: [(colour: BlueprintColour, originalIndex: Int)] = []

        for (index, colour) in anchors.enumerated() {
            if let lab = ColourMath.hexToLab(colour.hexValue) {
                parseable.append(
                    ParsedAnchor(colour: colour, originalIndex: index, lab: lab)
                )
            } else {
                print("[PaletteGridViewModel] Warning: invalid hex '\(colour.hexValue)', falling back to \(malformedHexFallback)")
                malformed.append((colour, index))
            }
        }

        let greedy = greedyLabChain(from: parseable)
        let chain  = twoOptRefine(chain: greedy)

        var ordered: [PaletteCell] = chain.map { anchor in
            PaletteCell(kind: .filled(hex: anchor.colour.hexValue, anchorName: anchor.colour.name))
        }
        for entry in malformed {
            ordered.append(
                PaletteCell(kind: .filled(hex: malformedHexFallback, anchorName: entry.colour.name))
            )
        }

        if count > 0 {
            return padCells(Array(ordered.prefix(count)), to: count)
        }
        return ordered
    }

    private static func padCells(_ cells: [PaletteCell], to count: Int) -> [PaletteCell] {
        var result = cells
        while result.count < count {
            result.append(PaletteCell(kind: .empty))
        }
        return result
    }

    // MARK: - Greedy Lab chain

    private struct ParsedAnchor {
        let colour: BlueprintColour
        let originalIndex: Int
        let lab: (L: Double, a: Double, b: Double)
    }

    private static func greedyLabChain(from anchors: [ParsedAnchor]) -> [ParsedAnchor] {
        guard !anchors.isEmpty else { return [] }

        var remaining = anchors
        let seedIndex = remaining.indices.min(by: { i, j in
            let a = remaining[i]
            let b = remaining[j]
            if a.lab.L != b.lab.L { return a.lab.L > b.lab.L }
            return a.originalIndex < b.originalIndex
        })!
        var chain: [ParsedAnchor] = [remaining.remove(at: seedIndex)]

        while !remaining.isEmpty {
            let tail = chain.last!.lab
            let nextIndex = remaining.indices.min { i, j in
                let a = remaining[i]
                let b = remaining[j]
                let da = squaredLabDistance(tail, a.lab)
                let db = squaredLabDistance(tail, b.lab)
                if da != db { return da < db }
                return a.originalIndex < b.originalIndex
            }!
            chain.append(remaining.remove(at: nextIndex))
        }

        return chain
    }

    private static func twoOptRefine(chain: [ParsedAnchor]) -> [ParsedAnchor] {
        guard chain.count >= 4 else { return chain }
        var current = chain
        var improved = true
        let eps = 1e-12

        while improved {
            improved = false
            for i in 1..<(current.count - 1) {
                for j in (i + 1)..<current.count {
                    let before: Double
                    let after: Double
                    if j == current.count - 1 {
                        before = squaredLabDistance(current[i - 1].lab, current[i].lab)
                        after  = squaredLabDistance(current[i - 1].lab, current[j].lab)
                    } else {
                        before = squaredLabDistance(current[i - 1].lab, current[i].lab)
                               + squaredLabDistance(current[j].lab, current[j + 1].lab)
                        after  = squaredLabDistance(current[i - 1].lab, current[j].lab)
                               + squaredLabDistance(current[i].lab, current[j + 1].lab)
                    }
                    if after + eps < before {
                        current[i...j].reverse()
                        improved = true
                    }
                }
            }
        }

        return current
    }

    private static func squaredLabDistance(
        _ a: (L: Double, a: Double, b: Double),
        _ b: (L: Double, a: Double, b: Double)
    ) -> Double {
        let dL = a.L - b.L
        let da = a.a - b.a
        let db = a.b - b.b
        return dL * dL + da * da + db * db
    }
}
