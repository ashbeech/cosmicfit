//
//  ChartSignatureResolver_Tests.swift
//  Cosmic FitTests
//
//  V4.4 — chart-signature resolver unit tests.
//
//  Contract coverage:
//   • Every (family × zodiac sign) combination resolves to a valid hex
//     that decodes back to a Lab triplet.
//   • Every resolved signature lands inside its family envelope
//     (L\* range, C\* range, hue arc) to within gamut-clip tolerance.
//   • Determinism — repeated calls yield byte-identical hex.
//   • Luminary uses the Sun's sign always; ruler uses the domicile
//     lord of the Ascendant's sign.
//

import Testing
import Foundation
@testable import Cosmic_Fit

struct ChartSignatureResolverTests {

    // MARK: - Full coverage

    @Test("Every family × sign combo resolves to a parseable hex")
    func everyFamilySignResolves() {
        for family in PaletteFamily.allCases {
            for sign in V4ZodiacSign.allCases {
                let input = Self.input(sun: sign, ascendant: .aries)
                let hex = ChartSignatureResolver.luminarySignature(
                    family: family, input: input
                )
                #expect(ColourMath.hexToLab(hex) != nil,
                        "Luminary hex '\(hex)' unparseable for \(family) / \(sign)")
            }
        }
    }

    @Test("Signatures are deterministic across repeated calls")
    func determinism() {
        let input = Self.input(sun: .leo, ascendant: .scorpio)
        let first = ChartSignatureResolver.luminarySignature(family: .deepAutumn, input: input)
        let second = ChartSignatureResolver.luminarySignature(family: .deepAutumn, input: input)
        #expect(first == second)
        let thirdRuler = ChartSignatureResolver.rulerSignature(family: .deepAutumn, input: input)
        let fourthRuler = ChartSignatureResolver.rulerSignature(family: .deepAutumn, input: input)
        #expect(thirdRuler == fourthRuler)
    }

    // MARK: - Envelope clipping

    @Test("Signatures fall within family lightness + chroma envelope")
    func signaturesInsideLightnessAndChromaEnvelope() {
        for family in PaletteFamily.allCases {
            let envelope = ChartSignatureResolver.envelope(for: family)
            for sign in V4ZodiacSign.allCases {
                let input = Self.input(sun: sign, ascendant: .aries)
                let hex = ChartSignatureResolver.luminarySignature(family: family, input: input)
                guard let lab = ColourMath.hexToLab(hex) else {
                    Issue.record("Unparseable signature '\(hex)' for \(family)/\(sign)")
                    continue
                }
                // Allow a modest tolerance to absorb gamut-clip rounding.
                // The envelope clamp targets LCH directly; sRGB round-trip
                // can drift by a few units, especially near the gamut hull.
                let LTol = 6.0
                let CTol = 12.0
                #expect(lab.L >= envelope.lightness.min - LTol,
                        "\(family)/\(sign) L*=\(lab.L) < min \(envelope.lightness.min)")
                #expect(lab.L <= envelope.lightness.max + LTol,
                        "\(family)/\(sign) L*=\(lab.L) > max \(envelope.lightness.max)")
                let chroma = sqrt(lab.a * lab.a + lab.b * lab.b)
                #expect(chroma <= envelope.chroma.max + CTol,
                        "\(family)/\(sign) C*=\(chroma) > max \(envelope.chroma.max)")
            }
        }
    }

    // MARK: - Luminary uses Sun's sign

    @Test("Luminary signature changes with the Sun's sign")
    func luminaryTracksSunSign() {
        let deepAutumn = PaletteFamily.deepAutumn
        let leoSun    = Self.input(sun: .leo, ascendant: .aries)
        let scorpioSun = Self.input(sun: .scorpio, ascendant: .aries)
        let leoHex    = ChartSignatureResolver.luminarySignature(family: deepAutumn, input: leoSun)
        let scorpioHex = ChartSignatureResolver.luminarySignature(family: deepAutumn, input: scorpioSun)
        #expect(leoHex != scorpioHex,
                "Different Sun signs should produce different luminary signatures within the same family")
    }

    // MARK: - Ruler uses Ascendant's domicile ruler

    @Test("Ruler signature tracks the domicile ruler's sign, not the Ascendant sign itself")
    func rulerTracksDomicileRuler() {
        // Libra ASC → domicile ruler Venus. If Venus is in Taurus vs Pisces
        // the ruler signature should differ even though the ASC stays the same.
        let venusInTaurus = Self.input(
            sun: .leo, ascendant: .libra, venus: .taurus, mercury: .leo
        )
        let venusInPisces = Self.input(
            sun: .leo, ascendant: .libra, venus: .pisces, mercury: .leo
        )
        let deepAutumn = PaletteFamily.deepAutumn
        let hexA = ChartSignatureResolver.rulerSignature(family: deepAutumn, input: venusInTaurus)
        let hexB = ChartSignatureResolver.rulerSignature(family: deepAutumn, input: venusInPisces)
        #expect(hexA != hexB,
                "Moving Venus (Libra's ruler) from Taurus to Pisces should shift the ruler signature")
    }

    @Test("Aries ASC uses Mars sign; Cancer ASC uses Moon sign")
    func domicileRulerMapping() {
        // Aries ruler = Mars. Compare rulerSignature(aries ASC, Mars in Leo)
        // with luminarySignature(Sun in Leo) — same sign, same envelope,
        // same hex, proving Aries is using its Mars-ruled path.
        let input = Self.input(
            sun: .leo, ascendant: .aries, mars: .leo
        )
        let ruler = ChartSignatureResolver.rulerSignature(family: .deepAutumn, input: input)
        let leoAsSun = ChartSignatureResolver.luminarySignature(
            family: .deepAutumn,
            input: Self.input(sun: .leo, ascendant: .aries)
        )
        #expect(ruler == leoAsSun,
                "Aries ASC with Mars in Leo should produce the Leo signature hex")

        // Cancer ruler = Moon. Moon in Sagittarius ≠ Sun in Cancer.
        let cancerInput = Self.input(
            sun: .cancer, ascendant: .cancer, moon: .sagittarius
        )
        let cancerRuler = ChartSignatureResolver.rulerSignature(family: .deepAutumn, input: cancerInput)
        let sagAsSun = ChartSignatureResolver.luminarySignature(
            family: .deepAutumn,
            input: Self.input(sun: .sagittarius, ascendant: .cancer)
        )
        #expect(cancerRuler == sagAsSun,
                "Cancer ASC with Moon in Sagittarius should produce the Sagittarius signature hex")
    }

    // MARK: - Hue arc wrap handling

    @Test("Cool-family signature for a warm sign (Aries) snaps into the cool arc")
    func warmSignClampedIntoCoolEnvelope() {
        // Deep Winter is cool (hue arc [170°, 310°]). Aries sits at 28°,
        // outside the arc. The clamp should snap to whichever arc endpoint
        // is nearer on the circle — here, 310° (distance 82°) wins over
        // 170° (distance 142°).
        let input = Self.input(sun: .aries, ascendant: .aries)
        let hex = ChartSignatureResolver.luminarySignature(
            family: .deepWinter, input: input
        )
        guard let lab = ColourMath.hexToLab(hex) else {
            Issue.record("Unparseable hex \(hex)")
            return
        }
        let hue = atan2(lab.b, lab.a) * 180 / .pi
        let normalized = hue < 0 ? hue + 360 : hue
        // Expect the hue to be near 310° (red-magenta), not 28° (red).
        // Allow a generous tolerance because the gamut clip can pull the
        // hue meaningfully when chroma is high.
        let distanceTo310 = Swift.min(
            abs(normalized - 310),
            abs(normalized - 310 + 360),
            abs(normalized - 310 - 360)
        )
        #expect(distanceTo310 < 30,
                "Clamped hue=\(normalized)° should be within 30° of 310° (the near cool-arc endpoint)")
    }

    // MARK: - Helpers

    private static func input(
        sun: V4ZodiacSign,
        ascendant: V4ZodiacSign,
        moon: V4ZodiacSign = .virgo,
        venus: V4ZodiacSign = .libra,
        mercury: V4ZodiacSign = .gemini,
        mars: V4ZodiacSign = .aries,
        jupiter: V4ZodiacSign = .sagittarius,
        saturn: V4ZodiacSign = .capricorn
    ) -> BirthChartColourInput {
        BirthChartColourInput(
            ascendant: PlacementInput(sign: ascendant),
            venus: PlacementInput(sign: venus),
            sun: PlacementInput(sign: sun),
            moon: PlacementInput(sign: moon),
            mercury: PlacementInput(sign: mercury),
            mars: PlacementInput(sign: mars),
            saturn: PlacementInput(sign: saturn),
            jupiter: PlacementInput(sign: jupiter),
            pluto: nil,
            midheaven: nil
        )
    }
}
