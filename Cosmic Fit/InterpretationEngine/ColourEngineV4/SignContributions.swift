import Foundation

struct SignContribution {
    let depthDelta: Int
    let warmthDelta: Int
    let saturationDelta: Int
    let contrastDelta: Int
    let structureDelta: Int
}

enum SignContributions {

    static let table: [V4ZodiacSign: SignContribution] = [
        .aries:       SignContribution(depthDelta:  0, warmthDelta:  2, saturationDelta:  2, contrastDelta:  1, structureDelta:  1),
        .taurus:      SignContribution(depthDelta:  2, warmthDelta:  2, saturationDelta:  1, contrastDelta:  0, structureDelta:  1),
        .gemini:      SignContribution(depthDelta: -1, warmthDelta:  0, saturationDelta:  2, contrastDelta:  1, structureDelta:  0),
        .cancer:      SignContribution(depthDelta:  0, warmthDelta: -1, saturationDelta: -1, contrastDelta: -1, structureDelta: -1),
        .leo:         SignContribution(depthDelta:  1, warmthDelta:  2, saturationDelta:  2, contrastDelta:  1, structureDelta:  1),
        .virgo:       SignContribution(depthDelta:  1, warmthDelta:  0, saturationDelta: -1, contrastDelta:  0, structureDelta:  1),
        .libra:       SignContribution(depthDelta: -1, warmthDelta:  0, saturationDelta:  1, contrastDelta:  0, structureDelta: -1),
        .scorpio:     SignContribution(depthDelta:  2, warmthDelta: -1, saturationDelta:  1, contrastDelta:  2, structureDelta:  2),
        .sagittarius: SignContribution(depthDelta:  0, warmthDelta:  2, saturationDelta:  2, contrastDelta:  1, structureDelta:  0),
        .capricorn:   SignContribution(depthDelta:  2, warmthDelta: -1, saturationDelta: -1, contrastDelta:  1, structureDelta:  2),
        .aquarius:    SignContribution(depthDelta:  1, warmthDelta: -1, saturationDelta:  2, contrastDelta:  2, structureDelta:  1),
        .pisces:      SignContribution(depthDelta: -1, warmthDelta: -1, saturationDelta: -1, contrastDelta: -1, structureDelta: -1),
    ]

    static func contribution(for sign: V4ZodiacSign) -> SignContribution {
        table[sign]!
    }
}
