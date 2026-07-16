//
//  AstrologicalSoundness_Tests.swift
//  Cosmic FitTests
//
//  Part 6B+6C: Energy map audit and calibration weight review.
//  Verifies planet energy base maps and calibration weights against
//  standard astrological associations.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("Part 6: Astrological Soundness")
struct AstrologicalSoundness_Tests {

    // MARK: - 6B. Energy Map Audit

    @Test("6B.1 — Mars primarily drives Drama and Edge")
    func testMarsEnergyProfile() {
        let chart = makeChartWithPlanetInSign(planet: "Mars", sign: 1) // Mars in Aries (fire)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_mars"
        )
        let v = snapshot.vibeProfile
        let marsContrib = v.drama + v.edge
        let romanticContrib = v.romantic
        #expect(marsContrib >= romanticContrib,
                "Mars-heavy chart: drama(\(v.drama))+edge(\(v.edge))=\(marsContrib) should >= romantic(\(romanticContrib))")
    }

    @Test("6B.2 — Venus primarily drives Romantic and Classic")
    func testVenusEnergyProfile() {
        // Venus-heavy chart: Venus in Taurus (dignified), lots of Venus sign planets
        let signs = [2, 7, 3, 2, 6, 8, 10, 11, 12, 8] // Venus in Taurus
        let chart = makeChart(signs: signs)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_venus"
        )
        let v = snapshot.vibeProfile
        let venusContrib = v.romantic + v.classic
        let utilityContrib = v.utility
        #expect(venusContrib >= utilityContrib,
                "Venus-dominant: romantic(\(v.romantic))+classic(\(v.classic))=\(venusContrib) should >= utility(\(utilityContrib))")
    }

    @Test("6B.3 — Saturn adds Classic and Utility, not Drama")
    func testSaturnEnergyProfile() {
        // Saturn-heavy chart
        let signs = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10] // All Capricorn
        let chart = makeChart(signs: signs)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_saturn"
        )
        let v = snapshot.vibeProfile
        let saturnContrib = v.classic + v.utility
        #expect(saturnContrib >= v.drama,
                "Saturn-heavy: classic(\(v.classic))+utility(\(v.utility))=\(saturnContrib) should >= drama(\(v.drama))")
    }

    @Test("6B.4 — Fire element boosts Drama and Edge")
    func testFireElementEnergy() {
        let signs = [1, 5, 9, 1, 5, 9, 1, 5, 9, 1] // All fire
        let chart = makeChart(signs: signs)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_fire"
        )
        let v = snapshot.vibeProfile
        #expect(v.drama >= 3, "Fire-heavy chart should have drama >= 3, got \(v.drama)")
    }

    @Test("6B.5 — Water element boosts Romantic")
    func testWaterElementEnergy() {
        let signs = [4, 8, 12, 4, 8, 12, 4, 8, 12, 4] // All water
        let chart = makeChart(signs: signs)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_water"
        )
        let v = snapshot.vibeProfile
        #expect(v.romantic >= 3, "Water-heavy chart should have romantic >= 3, got \(v.romantic)")
    }

    @Test("6B.6 — Earth element boosts Classic and Utility")
    func testEarthElementEnergy() {
        let signs = [2, 6, 10, 2, 6, 10, 2, 6, 10, 2] // All earth
        let chart = makeChart(signs: signs)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_earth"
        )
        let v = snapshot.vibeProfile
        let earthContrib = v.classic + v.utility
        #expect(earthContrib >= 6, "Earth-heavy chart: classic(\(v.classic))+utility(\(v.utility))=\(earthContrib) should >= 6")
    }

    @Test("6B.7 — Air element boosts Playful")
    func testAirElementEnergy() {
        let signs = [3, 7, 11, 3, 7, 11, 3, 7, 11, 3] // All air
        let chart = makeChart(signs: signs)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 90.0,
            profileHash: "audit_air"
        )
        let v = snapshot.vibeProfile
        #expect(v.playful >= 3, "Air-heavy chart should have playful >= 3, got \(v.playful)")
    }

    // MARK: - 6C. Calibration Weight Review

    @Test("6C.1 — Default source weights sum to 1.0")
    func testSourceWeightsSum() {
        let cal = DailyFitCalibration.default
        let sum = cal.sourceWeights.natal + cal.sourceWeights.transits +
                  cal.sourceWeights.lunarPhase + cal.sourceWeights.progressed +
                  cal.sourceWeights.currentSun
        #expect(abs(sum - 1.0) < 0.001, "Source weights sum = \(sum), expected 1.0")
        #expect(cal.sourceWeights.isNormalised, "Source weights not normalised")
    }

    @Test("6C.2 — The daily read is lunar-led (F7 repoint: the sky mix drives output, not the .default vector)")
    func testDailyReadIsLunarLed() {
        // F7 / C2: `DailyFitCalibration.default` (natal 0.28 / transits 0.35 / lunar 0.22 / …) is a
        // fingerprint/diagnostics vector — it does NOT drive the daily output. The daily read is the
        // *sky mix*, which Sky Forward v1.0.2 promotes into the fingerprinted calibration (skyVibeWeights)
        // and runs lunar-led. This asserts that design intent; the MEASURED effective shares
        // (lunar ~0.58 vs transits ~0.31 vs v1.0.1's inverted 0.046/0.94) are enforced fail-closed by the
        // inspector fidelity gate (a) — CalibrationAudit_Tests under CALIBRATION_FIDELITY_GATE=1.
        let v102 = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.skyForwardV102Id)
        guard let sky = v102.skyVibeWeights else {
            #expect(Bool(false), "v1.0.2 skyVibeWeights missing — sky mix not fingerprinted")
            return
        }
        #expect(abs((sky.transits + sky.lunar + sky.currentSun) - 1.0) < 0.001, "sky mix must sum to 1.0")
        #expect(sky.lunar > sky.transits, "daily sky vibe should be lunar-led (lunar > transits)")
        #expect(sky.lunar > sky.currentSun, "daily sky vibe should be lunar-led (lunar > currentSun)")
    }

    @Test("6C.3 — All 12 signs have energy multipliers")
    func testAllSignsHaveMultipliers() {
        let cal = DailyFitCalibration.default
        let expectedSigns = [
            "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
            "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
        ]
        for sign in expectedSigns {
            for energy in Energy.allCases {
                let m = cal.signEnergyMap.multiplier(forSign: sign, energy: energy)
                #expect(m > 0.0, "\(sign)/\(energy.rawValue) multiplier should be > 0")
                #expect(m < 3.0, "\(sign)/\(energy.rawValue) multiplier = \(m) seems too high (>3)")
            }
        }
    }

    @Test("6C.4 — Sign energy multipliers are astrologically coherent")
    func testSignEnergyCoherence() {
        let cal = DailyFitCalibration.default

        // Leo and Aries drama both Phase-1 capped at 1.35
        let leoDrama = cal.signEnergyMap.multiplier(forSign: "Leo", energy: .drama)
        let ariesDrama = cal.signEnergyMap.multiplier(forSign: "Aries", energy: .drama)
        #expect(leoDrama == 1.35)
        #expect(ariesDrama == 1.35)
        #expect(leoDrama == ariesDrama)

        // Taurus should have high classic
        let taurusClassic = cal.signEnergyMap.multiplier(forSign: "Taurus", energy: .classic)
        #expect(taurusClassic >= 1.3, "Taurus classic = \(taurusClassic), expected >= 1.3")

        // Aquarius should have high edge
        let aquariusEdge = cal.signEnergyMap.multiplier(forSign: "Aquarius", energy: .edge)
        #expect(aquariusEdge >= 1.3, "Aquarius edge = \(aquariusEdge), expected >= 1.3")

        // Pisces should have high romantic
        let piscesRomantic = cal.signEnergyMap.multiplier(forSign: "Pisces", energy: .romantic)
        #expect(piscesRomantic >= 1.3, "Pisces romantic = \(piscesRomantic), expected >= 1.3")
    }

    @Test("6C.5 — Generate weight audit report")
    func testGenerateWeightAuditReport() {
        var lines: [String] = []
        lines.append("=== Astrological Soundness Audit Report ===")
        lines.append("Generated: \(Date())")
        lines.append("")

        // Source weights (fingerprint/diagnostics vector — does NOT drive the daily output; see F7).
        let cal = DailyFitCalibration.default
        lines.append("--- Source Weights (.default — fingerprint/diagnostics only, NOT the daily read) ---")
        lines.append("  natal=\(cal.sourceWeights.natal)")
        lines.append("  transits=\(cal.sourceWeights.transits)")
        lines.append("  lunarPhase=\(cal.sourceWeights.lunarPhase)")
        lines.append("  progressed=\(cal.sourceWeights.progressed)")
        lines.append("  currentSun=\(cal.sourceWeights.currentSun)")
        lines.append("")

        // Sky vibe mix — the actual driver of the daily read (Sky Forward v1.0.2, fingerprinted).
        let v102 = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.skyForwardV102Id)
        lines.append("--- Sky Vibe Mix (v1.0.2 — the driving daily mix, lunar-led) ---")
        if let sky = v102.skyVibeWeights {
            lines.append("  transits=\(sky.transits)  lunar=\(sky.lunar)  currentSun=\(sky.currentSun)")
            lines.append("  lunarSignificanceCoeff (syzygy swell k)=\(v102.lunarSignificanceCoeff ?? 0)")
        }
        lines.append("  measured effective shares (12×181 real ephemeris): lunar ~0.58 / transits ~0.31 / sun ~0.11")
        lines.append("  (v1.0.1 was inverted: lunar 0.046 / transits 0.94 — see docs/daily_fit_calibration_audit_2026-07-11.md)")
        lines.append("")

        // Sign energy multipliers
        lines.append("--- Sign Energy Multipliers ---")
        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                     "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        let header = "Sign".padding(toLength: 14, withPad: " ", startingAt: 0)
            + Energy.allCases.map { $0.rawValue.padding(toLength: 10, withPad: " ", startingAt: 0) }.joined()
        lines.append("  \(header)")
        for sign in signs {
            var row = sign.padding(toLength: 14, withPad: " ", startingAt: 0)
            for energy in Energy.allCases {
                let m = cal.signEnergyMap.multiplier(forSign: sign, energy: energy)
                row += String(format: "%-10.2f", m)
            }
            lines.append("  \(row)")
        }
        lines.append("")

        // Selection weights
        lines.append("--- Selection Weights ---")
        lines.append("  vibeWeight=\(cal.selectionWeights.vibeWeight)")
        lines.append("  axisWeight=\(cal.selectionWeights.axisWeight)")
        lines.append("  transitBoost=\(cal.selectionWeights.transitBoost)")
        lines.append("")

        // Element profile tests
        lines.append("--- Element Profile Snapshots ---")
        let elementTests: [(String, [Int])] = [
            ("fire-heavy", [1, 5, 9, 1, 5, 9, 1, 5, 9, 1]),
            ("earth-heavy", [2, 6, 10, 2, 6, 10, 2, 6, 10, 2]),
            ("air-heavy", [3, 7, 11, 3, 7, 11, 3, 7, 11, 3]),
            ("water-heavy", [4, 8, 12, 4, 8, 12, 4, 8, 12, 4]),
        ]
        for (label, signs) in elementTests {
            let chart = makeChart(signs: signs)
            let snapshot = DailyEnergyEngine.generateSnapshot(
                natalChart: chart, progressedChart: chart,
                transits: [], moonPhaseDegrees: 90.0,
                profileHash: "audit_\(label)"
            )
            let v = snapshot.vibeProfile
            lines.append("  \(label): C=\(v.classic) P=\(v.playful) R=\(v.romantic) U=\(v.utility) D=\(v.drama) E=\(v.edge)")
        }

        CalibrationReportHelper.writeReport(prefix: "astrological_soundness", content: lines.joined(separator: "\n"))
    }

    // MARK: - Helpers

    private func makeChart(signs: [Int]) -> NatalChartCalculator.NatalChart {
        makeChartFromSigns(signs)
    }

    private func makeChartWithPlanetInSign(planet: String, sign: Int) -> NatalChartCalculator.NatalChart {
        var signs = [1, 4, 3, 7, 1, 9, 10, 11, 12, 8] // Varied baseline
        let planetIndex = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                          "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
            .firstIndex(of: planet) ?? 0
        signs[planetIndex] = sign
        return makeChartFromSigns(signs)
    }
}

private func makeChartFromSigns(_ signs: [Int]) -> NatalChartCalculator.NatalChart {
    let planetDefs: [(String, String)] = [
        ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
        ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
        ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
    ]
    let planets = planetDefs.enumerated().map { (i, pair) in
        NatalChartCalculator.PlanetPosition(
            name: pair.0, symbol: pair.1,
            longitude: Double((signs[i] - 1) * 30 + 15), latitude: 0.0,
            zodiacSign: signs[i], zodiacPosition: "15°00'",
            isRetrograde: false
        )
    }
    return NatalChartCalculator.NatalChart(
        planets: planets,
        ascendant: Double((signs[0] - 1) * 30), midheaven: 90.0,
        descendant: 180.0, imumCoeli: 270.0,
        houseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
        wholeSignHouseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
        northNode: 0.0, southNode: 180.0, vertex: 90.0,
        partOfFortune: 45.0, lilith: 120.0, chiron: 200.0,
        lunarPhase: 90.0
    )
}
