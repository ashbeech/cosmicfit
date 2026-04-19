import Foundation

enum Scoring {

    static func accumulateRawScores(normalized: NormalizedDriverSet) -> RawVariableScores {
        var scores = RawVariableScores.zero

        for driver in normalized.drivers {
            let c = SignContributions.contribution(for: driver.sign)
            scores.depth      += c.depthDelta * driver.weight
            scores.warmth     += c.warmthDelta * driver.weight
            scores.saturation += c.saturationDelta * driver.weight
            scores.contrast   += c.contrastDelta * driver.weight
            scores.structure  += c.structureDelta * driver.weight
        }

        return scores
    }
}
