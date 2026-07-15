//
//  CalibrationAudit_Tests.swift
//  InspectorEngineTests
//
//  Daily Fit calibration audit experiments (diagnostic, report-writing).
//  Measures how the shipped Sky Forward v1.0.1 mix behaves on real ephemeris data:
//    A1 — effective (not nominal) source shares of the daily sky vibe
//    A2 — lunar phase step granularity in the vibe path
//    A3 — full/new-moon bucket hit rates under once-a-day sampling
//    A4 — jitter share of day-over-day axis variation
//    A5 — full-moon salience in the output (vibe/axes deltas)
//
//  These tests assert only structural sanity; findings go to report files
//  (CALIBRATION_AUDIT_DIR or the temporary directory) and stdout.
//

import XCTest
import CoreLocation
@testable import CosmicFitInspectorLib

// MARK: - Support

enum CalibrationAuditSupport {

    static let deviceCoord = CLLocationCoordinate2D(
        latitude: InspectorDefaults.defaultDeviceLatitude,
        longitude: InspectorDefaults.defaultDeviceLongitude
    )

    static let productionCalibration = DailyFitEngineRegistry.calibration(
        for: DailyFitEngineRegistry.productionId
    )

    static var zeroJitterCalibration: DailyFitCalibration {
        let p = productionCalibration
        return DailyFitCalibration(
            sourceWeights: p.sourceWeights,
            signEnergyMap: p.signEnergyMap,
            signMultiplierPolicy: p.signMultiplierPolicy,
            planetAxisMap: p.planetAxisMap,
            selectionWeights: p.selectionWeights,
            axisTuning: DailyFitCalibration.AxisTuning(
                sigmoidSpread: p.axisTuning.sigmoidSpread, jitterRange: 0.0
            ),
            stage2Sensitivity: p.stage2Sensitivity,
            elementBoostDedupeThreshold: p.elementBoostDedupeThreshold,
            narrativeSelection: p.narrativeSelection
        )
    }

    private static var bootstrapped = false
    static func bootstrapEphemeris() {
        guard !bootstrapped else { return }
        SwissEphemerisBootstrap.initialise(
            ephemerisDirectoryPath: ResourcePaths.swissEphemerisDirectory.path
        )
        VSOP87Parser.setDataDirectory(ResourcePaths.vsop87DataDirectory)
        VSOP87Parser.loadData()
        bootstrapped = true
    }

    struct BirthSpec {
        let id: String
        let iso: String
        let latitude: Double
        let longitude: Double
        let timeZoneId: String
    }

    /// 12 diverse real births: sun signs across the zodiac, both hemispheres,
    /// birth years 1958–2003.
    static let birthSpecs: [BirthSpec] = [
        BirthSpec(id: "ash_london_1984", iso: "1984-12-11T12:00:00Z", latitude: 51.5074, longitude: -0.1278, timeZoneId: "Europe/London"),
        BirthSpec(id: "nyc_1990_gemini", iso: "1990-06-21T08:30:00Z", latitude: 40.7128, longitude: -74.0060, timeZoneId: "America/New_York"),
        BirthSpec(id: "tokyo_1975_pisces", iso: "1975-03-05T22:15:00Z", latitude: 35.6762, longitude: 139.6503, timeZoneId: "Asia/Tokyo"),
        BirthSpec(id: "sydney_2000_scorpio", iso: "2000-11-02T04:45:00Z", latitude: -33.8688, longitude: 151.2093, timeZoneId: "Australia/Sydney"),
        BirthSpec(id: "la_1988_leo", iso: "1988-08-08T16:20:00Z", latitude: 34.0522, longitude: -118.2437, timeZoneId: "America/Los_Angeles"),
        BirthSpec(id: "berlin_1965_aquarius", iso: "1965-01-30T06:00:00Z", latitude: 52.5200, longitude: 13.4050, timeZoneId: "Europe/Berlin"),
        BirthSpec(id: "saopaulo_1995_aries", iso: "1995-04-17T14:10:00Z", latitude: -23.5505, longitude: -46.6333, timeZoneId: "America/Sao_Paulo"),
        BirthSpec(id: "mumbai_1979_libra", iso: "1979-09-23T02:35:00Z", latitude: 19.0760, longitude: 72.8777, timeZoneId: "Asia/Kolkata"),
        BirthSpec(id: "capetown_1992_aquarius", iso: "1992-02-14T18:50:00Z", latitude: -33.9249, longitude: 18.4241, timeZoneId: "Africa/Johannesburg"),
        BirthSpec(id: "chicago_2003_cancer", iso: "2003-07-04T11:25:00Z", latitude: 41.8781, longitude: -87.6298, timeZoneId: "America/Chicago"),
        BirthSpec(id: "paris_1958_taurus", iso: "1958-05-19T09:40:00Z", latitude: 48.8566, longitude: 2.3522, timeZoneId: "Europe/Paris"),
        BirthSpec(id: "moscow_1998_scorpio", iso: "1998-10-31T20:05:00Z", latitude: 55.7558, longitude: 37.6173, timeZoneId: "Europe/Moscow"),
    ]

    struct AuditProfile {
        let id: String
        let natal: NatalChartCalculator.NatalChart
        let progressed: NatalChartCalculator.NatalChart
    }

    static func loadProfiles() -> [AuditProfile] {
        bootstrapEphemeris()
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        var profiles: [AuditProfile] = []
        for spec in birthSpecs {
            guard let birthDate = fmt.date(from: spec.iso),
                  let tz = TimeZone(identifier: spec.timeZoneId) else { continue }
            let natal = NatalChartCalculator.calculateNatalChart(
                birthDate: birthDate, latitude: spec.latitude,
                longitude: spec.longitude, timeZone: tz
            )
            let age = NatalChartCalculator.calculateCurrentAge(from: birthDate)
            let progressed = NatalChartCalculator.calculateProgressedChart(
                birthDate: birthDate, targetAge: age,
                latitude: spec.latitude, longitude: spec.longitude,
                timeZone: tz, progressAnglesMethod: .solarArc
            )
            profiles.append(AuditProfile(id: spec.id, natal: natal, progressed: progressed))
        }
        return profiles
    }

    static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    static func utcInstant(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    static func moonPhaseDegrees(at date: Date) -> Double {
        let jd = JulianDateCalculator.calculateJulianDate(from: date)
        return AstronomicalCalculator.calculateLunarPhase(julianDay: jd)
    }

    static func runDay(
        profile: AuditProfile,
        date: Date,
        calibration: DailyFitCalibration = productionCalibration,
        transitsOverride: [NatalChartCalculator.TransitAspect]? = nil,
        moonOverride: Double? = nil
    ) -> (snapshot: DailyEnergySnapshot, trace: DailyEnergyEngine.SnapshotTrace,
          transits: [NatalChartCalculator.TransitAspect], moon: Double) {
        let transits = transitsOverride ?? NatalChartCalculator.calculateTransits(
            natalChart: profile.natal, date: date, overrideDeviceLocation: deviceCoord
        )
        let moon = moonOverride ?? moonPhaseDegrees(at: date)
        let (snapshot, trace) = DailyEnergyEngine.generateSnapshotWithTrace(
            natalChart: profile.natal,
            progressedChart: profile.progressed,
            transits: transits,
            moonPhaseDegrees: moon,
            profileHash: profile.id,
            date: date,
            calibration: calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        return (snapshot, trace, transits, moon)
    }

    static func vibeVector(_ v: VibeBreakdown) -> [Int] {
        [v.classic, v.playful, v.romantic, v.utility, v.drama, v.edge]
    }

    static func vibeL1(_ a: VibeBreakdown, _ b: VibeBreakdown) -> Int {
        zip(vibeVector(a), vibeVector(b)).map { abs($0 - $1) }.reduce(0, +)
    }

    static func axesVector(_ a: DerivedAxes) -> [Double] {
        [a.action, a.tempo, a.strategy, a.visibility]
    }

    static func axesL1(_ a: DerivedAxes, _ b: DerivedAxes) -> Double {
        zip(axesVector(a), axesVector(b)).map { abs($0 - $1) }.reduce(0, +)
    }

    struct Stats {
        let mean: Double
        let std: Double
        let minV: Double
        let maxV: Double
        init(_ values: [Double]) {
            guard !values.isEmpty else { mean = 0; std = 0; minV = 0; maxV = 0; return }
            let m = values.reduce(0, +) / Double(values.count)
            mean = m
            std = (values.map { ($0 - m) * ($0 - m) }.reduce(0, +) / Double(values.count)).squareRoot()
            minV = values.min()!
            maxV = values.max()!
        }
        var line: String {
            String(format: "mean %.4f  std %.4f  min %.4f  max %.4f", mean, std, minV, maxV)
        }
    }

    static func pearson(_ xs: [Double], _ ys: [Double]) -> Double {
        guard xs.count == ys.count, xs.count > 1 else { return 0 }
        let n = Double(xs.count)
        let mx = xs.reduce(0, +) / n
        let my = ys.reduce(0, +) / n
        var num = 0.0, dx2 = 0.0, dy2 = 0.0
        for i in 0..<xs.count {
            let dx = xs[i] - mx, dy = ys[i] - my
            num += dx * dy; dx2 += dx * dx; dy2 += dy * dy
        }
        let denom = (dx2 * dy2).squareRoot()
        return denom > 0 ? num / denom : 0
    }

    static func reportDirectory() -> URL {
        if let dir = ProcessInfo.processInfo.environment["CALIBRATION_AUDIT_DIR"] {
            let url = URL(fileURLWithPath: dir)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        return FileManager.default.temporaryDirectory
    }

    @discardableResult
    static func writeReport(name: String, content: String) -> URL {
        let url = reportDirectory().appendingPathComponent("\(name).txt")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        print("=== CALIBRATION AUDIT REPORT: \(name) → \(url.path) ===")
        print(content)
        print("=== END REPORT: \(name) ===")
        return url
    }
}

// MARK: - Tests

final class CalibrationAudit_Tests: XCTestCase {

    typealias S = CalibrationAuditSupport

    // A1 + A6 — effective source shares of the daily sky vibe, on real skies.
    // Nominal sky mix: transits 0.25 / lunar 0.60 / currentSun 0.15.
    // Measures what the accumulation actually produces once transit count scales in.
    func testA1_EffectiveSourceShares() {
        let profiles = S.loadProfiles()
        XCTAssertFalse(profiles.isEmpty, "ephemeris unavailable — cannot run audit")

        let start = S.utcInstant(year: 2026, month: 1, day: 1)
        let days = 181 // 2026-01-01 .. 2026-06-30

        var lunarShares: [Double] = []
        var transitShares: [Double] = []
        var sunShares: [Double] = []
        var transitCounts: [Double] = []
        var transitShareByCount: [Int: [Double]] = [:]
        var daysTransitAboveLunar = 0
        var total = 0

        for profile in profiles {
            for d in 0..<days {
                let date = start.addingTimeInterval(Double(d) * 86400)
                let r = S.runDay(profile: profile, date: date)
                let c = r.trace.sourceContributions
                let lunar = c["lunar"] ?? 0
                let transit = c["transits"] ?? 0
                let sun = c["currentSun"] ?? 0
                lunarShares.append(lunar)
                transitShares.append(transit)
                sunShares.append(sun)
                transitCounts.append(Double(r.transits.count))
                transitShareByCount[r.transits.count, default: []].append(transit)
                if transit > lunar { daysTransitAboveLunar += 1 }
                total += 1
            }
        }

        let corr = S.pearson(transitCounts, transitShares)
        var lines: [String] = []
        lines.append("A1 — EFFECTIVE SOURCE SHARES OF THE DAILY SKY VIBE")
        lines.append("Cohort: \(profiles.count) real-ephemeris profiles × \(days) days (2026-01-01..2026-06-30), production engine")
        lines.append("Nominal sky mix: transits 0.25 / lunarPhase 0.60 / currentSun 0.15")
        lines.append("")
        lines.append("Effective share of pre-normalisation vibe energy:")
        lines.append("  lunar:      \(S.Stats(lunarShares).line)")
        lines.append("  transits:   \(S.Stats(transitShares).line)")
        lines.append("  currentSun: \(S.Stats(sunShares).line)")
        lines.append("")
        lines.append("Daily in-orb transit count: \(S.Stats(transitCounts).line)")
        lines.append("Pearson r (transit count vs effective transit share): \(String(format: "%.3f", corr))")
        lines.append("Days where transits out-weigh lunar: \(daysTransitAboveLunar)/\(total) (\(String(format: "%.1f", 100.0 * Double(daysTransitAboveLunar) / Double(max(total, 1))))%)")
        lines.append("")
        lines.append("Effective transit share by daily transit count:")
        for count in transitShareByCount.keys.sorted() {
            let stats = S.Stats(transitShareByCount[count]!)
            lines.append(String(format: "  %2d transits (n=%4d): mean %.3f  min %.3f  max %.3f",
                                count, transitShareByCount[count]!.count, stats.mean, stats.minV, stats.maxV))
        }
        S.writeReport(name: "a1_effective_source_shares", content: lines.joined(separator: "\n"))

        // Structural sanity only.
        XCTAssertEqual(total, profiles.count * days)
    }

    // A2 — lunar phase step granularity: with the sky held fixed, how many
    // distinct vibe outputs can the moon produce across a full cycle?
    func testA2_LunarPhaseStepGranularity() {
        let profiles = S.loadProfiles()
        guard let profile = profiles.first else {
            XCTFail("ephemeris unavailable"); return
        }
        let date = S.utcInstant(year: 2026, month: 3, day: 15)
        let transits = NatalChartCalculator.calculateTransits(
            natalChart: profile.natal, date: date, overrideDeviceLocation: S.deviceCoord
        )

        var distinctVibes: [[Int]] = []
        var previousVibe: VibeBreakdown?
        var boundaries: [(degree: Double, l1: Int)] = []
        var degree = 0.0
        while degree < 360.0 {
            let r = S.runDay(profile: profile, date: date,
                             transitsOverride: transits, moonOverride: degree)
            let vibe = r.snapshot.vibeProfile
            if let prev = previousVibe {
                let l1 = S.vibeL1(prev, vibe)
                if l1 > 0 { boundaries.append((degree, l1)) }
            }
            let vec = S.vibeVector(vibe)
            if !distinctVibes.contains(vec) { distinctVibes.append(vec) }
            previousVibe = vibe
            degree += 0.25
        }

        var lines: [String] = []
        lines.append("A2 — LUNAR PHASE STEP GRANULARITY (fixed sky, phase swept 0..360° in 0.25° steps)")
        lines.append("Profile: \(profile.id), transits frozen at 2026-03-15 (\(transits.count) aspects)")
        lines.append("")
        lines.append("Distinct vibe outputs across the whole lunar cycle: \(distinctVibes.count)")
        lines.append("Vibe changes occur only at these phase degrees (bucket boundaries):")
        for b in boundaries {
            lines.append(String(format: "  %.2f° — vibe L1 step %d (of 42 max)", b.degree, b.l1))
        }
        lines.append("")
        lines.append("Interpretation: the moon-phase contribution to the vibe is a step function")
        lines.append("over 8 buckets; between boundaries the moon cannot move the vibe at all.")
        lines.append("(The axes DO move continuously via fullMoonProximity nudges.)")
        S.writeReport(name: "a2_lunar_phase_step_granularity", content: lines.joined(separator: "\n"))

        XCTAssertLessThanOrEqual(distinctVibes.count, 8)
    }

    // A3 — full/new-moon bucket hit rates under once-daily sampling.
    // fullMoon bucket = 177..183° (6°), newMoon = 358..2° (4°); elongation moves
    // ~12.2°/day, so a daily sample can skip the bucket entirely.
    func testA3_PhaseBucketHitRates() {
        S.bootstrapEphemeris()
        let year = 2026
        let sampleHours = [0, 6, 12, 18]
        var lines: [String] = []
        lines.append("A3 — NAMED-PHASE BUCKET HIT RATES (\(year), one sample per day)")
        lines.append("Buckets: newMoon 358–2° (4° wide), firstQuarter 87–93°, fullMoon 177–183°, lastQuarter 267–273° (6° wide)")
        lines.append("Moon elongation advances ~12.2°/day → bucket dwell ≈ 0.5 day (full) / 0.33 day (new)")
        lines.append("")

        for hour in sampleHours {
            var fullClusters = 0, newClusters = 0
            var lunations = 0
            var prevPhase = -1.0
            var inFull = false, inNew = false
            var day = S.utcInstant(year: year, month: 1, day: 1, hour: hour)
            let end = S.utcInstant(year: year + 1, month: 1, day: 1, hour: hour)
            while day < end {
                let phase = S.moonPhaseDegrees(at: day)
                if prevPhase >= 0 {
                    // count lunations by 180° upward crossing (full moon instants)
                    if prevPhase < 180.0 && phase >= 180.0 { lunations += 1 }
                }
                let bucket = MoonPhaseInterpreter.Phase.fromDegrees(phase)
                if bucket == .fullMoon { if !inFull { fullClusters += 1; inFull = true } } else { inFull = false }
                if bucket == .newMoon { if !inNew { newClusters += 1; inNew = true } } else { inNew = false }
                prevPhase = phase
                day = day.addingTimeInterval(86400)
            }
            lines.append("Sampled daily at \(String(format: "%02d", hour)):00 UTC — actual full-moon lunations: \(lunations); days labelled Full Moon cover \(fullClusters) of them; New Moon events labelled: \(newClusters)")
        }
        lines.append("")
        lines.append("A 'missed' full moon is labelled Waxing/Waning Gibbous instead; the waning-gibbous")
        lines.append("energy vector leads with classic (0.35) vs full moon's drama (0.35) + playful (0.30),")
        lines.append("so a missed full moon flips the day's lunar message.")
        S.writeReport(name: "a3_phase_bucket_hit_rates", content: lines.joined(separator: "\n"))
    }

    // A4 — how much of day-over-day axis motion is seeded jitter vs sky signal?
    // Production jitterRange = 0.40 (per-axis, pre-sigmoid); full-moon axis nudge peaks at ±0.3.
    func testA4_JitterShareOfAxisVariation() {
        let profiles = S.loadProfiles()
        XCTAssertFalse(profiles.isEmpty, "ephemeris unavailable")
        let subset = Array(profiles.prefix(6))
        let start = S.utcInstant(year: 2026, month: 3, day: 1)
        let days = 91 // 2026-03-01 .. 2026-05-30

        var dayDeltaProd: [Double] = []
        var dayDeltaNoJitter: [Double] = []
        var withinDayDisplacement: [Double] = []

        for profile in subset {
            var prevProd: DerivedAxes?
            var prevNJ: DerivedAxes?
            for d in 0..<days {
                let date = start.addingTimeInterval(Double(d) * 86400)
                let transits = NatalChartCalculator.calculateTransits(
                    natalChart: profile.natal, date: date, overrideDeviceLocation: S.deviceCoord
                )
                let moon = S.moonPhaseDegrees(at: date)
                let prod = S.runDay(profile: profile, date: date,
                                    transitsOverride: transits, moonOverride: moon)
                let nj = S.runDay(profile: profile, date: date,
                                  calibration: S.zeroJitterCalibration,
                                  transitsOverride: transits, moonOverride: moon)
                withinDayDisplacement.append(
                    S.axesL1(prod.snapshot.axes, nj.snapshot.axes) / 4.0
                )
                if let p = prevProd {
                    dayDeltaProd.append(S.axesL1(p, prod.snapshot.axes) / 4.0)
                }
                if let p = prevNJ {
                    dayDeltaNoJitter.append(S.axesL1(p, nj.snapshot.axes) / 4.0)
                }
                prevProd = prod.snapshot.axes
                prevNJ = nj.snapshot.axes
            }
        }

        let prodStats = S.Stats(dayDeltaProd)
        let njStats = S.Stats(dayDeltaNoJitter)
        let dispStats = S.Stats(withinDayDisplacement)
        let jitterShare = prodStats.mean > 0
            ? (prodStats.mean - njStats.mean) / prodStats.mean : 0

        var lines: [String] = []
        lines.append("A4 — JITTER SHARE OF DAY-OVER-DAY AXIS VARIATION")
        lines.append("Cohort: \(subset.count) profiles × \(days) days (2026-03-01..2026-05-30)")
        lines.append("Production axisTuning: sigmoidSpread \(S.productionCalibration.axisTuning.sigmoidSpread), jitterRange \(S.productionCalibration.axisTuning.jitterRange)")
        lines.append("Full-moon axis nudge range: ±0.3 (action/visibility), ±0.2 (tempo/strategy) — pre-sigmoid")
        lines.append("")
        lines.append("Mean per-axis day-over-day |Δ| (1–10 scale):")
        lines.append("  with production jitter (0.40): \(prodStats.line)")
        lines.append("  with jitter disabled (0.00):   \(njStats.line)")
        lines.append(String(format: "  → share of daily axis motion attributable to seeded noise: %.1f%%", jitterShare * 100))
        lines.append("")
        lines.append("Mean per-axis displacement caused by jitter within a single day: \(dispStats.line)")
        S.writeReport(name: "a4_jitter_share_of_axis_variation", content: lines.joined(separator: "\n"))

        XCTAssertFalse(dayDeltaProd.isEmpty)
    }

    // A5 — is a full moon visible in the output? Day-over-day vibe deltas grouped
    // by lunar bucket transitions, plus axis behaviour around the full-moon peak.
    func testA5_FullMoonSalienceInOutput() {
        let profiles = S.loadProfiles()
        XCTAssertFalse(profiles.isEmpty, "ephemeris unavailable")
        let subset = Array(profiles.prefix(6))
        let start = S.utcInstant(year: 2026, month: 1, day: 1)
        let days = 181

        var sameBucketDeltas: [Double] = []
        var bucketChangeDeltas: [Double] = []
        var intoFullMoonDeltas: [Double] = []
        var fullMoonPeakAxes: [Double] = []       // action+visibility mean near peak
        var newMoonAxes: [Double] = []
        var quarterAxes: [Double] = []

        for profile in subset {
            var prev: (vibe: VibeBreakdown, bucket: MoonPhaseInterpreter.Phase)?
            for d in 0..<days {
                let date = start.addingTimeInterval(Double(d) * 86400)
                let r = S.runDay(profile: profile, date: date)
                let bucket = MoonPhaseInterpreter.Phase.fromDegrees(r.moon)
                let vibe = r.snapshot.vibeProfile

                let fraction = r.moon / 360.0
                let proximity = 1.0 - abs(fraction - 0.5) * 2.0
                let actVis = (r.snapshot.axes.action + r.snapshot.axes.visibility) / 2.0
                if proximity > 0.9 { fullMoonPeakAxes.append(actVis) }
                else if proximity < 0.1 { newMoonAxes.append(actVis) }
                else if proximity > 0.4 && proximity < 0.6 { quarterAxes.append(actVis) }

                if let p = prev {
                    let delta = Double(S.vibeL1(p.vibe, vibe))
                    if p.bucket == bucket {
                        sameBucketDeltas.append(delta)
                    } else {
                        bucketChangeDeltas.append(delta)
                        if bucket == .fullMoon { intoFullMoonDeltas.append(delta) }
                    }
                }
                prev = (vibe, bucket)
            }
        }

        var lines: [String] = []
        lines.append("A5 — FULL-MOON SALIENCE IN THE OUTPUT")
        lines.append("Cohort: \(subset.count) profiles × \(days) days (2026-01-01..2026-06-30), production engine")
        lines.append("")
        lines.append("Day-over-day vibe L1 delta (21-point budget, 42 max):")
        lines.append("  same lunar bucket (n=\(sameBucketDeltas.count)):    \(S.Stats(sameBucketDeltas).line)")
        lines.append("  bucket-change days (n=\(bucketChangeDeltas.count)): \(S.Stats(bucketChangeDeltas).line)")
        lines.append("  entering fullMoon bucket (n=\(intoFullMoonDeltas.count)): \(S.Stats(intoFullMoonDeltas).line)")
        lines.append("")
        lines.append("Mean of (action+visibility)/2 axis value (1–10):")
        lines.append("  near full moon (proximity>0.9, n=\(fullMoonPeakAxes.count)): \(S.Stats(fullMoonPeakAxes).line)")
        lines.append("  near quarters  (0.4<prox<0.6, n=\(quarterAxes.count)): \(S.Stats(quarterAxes).line)")
        lines.append("  near new moon  (proximity<0.1, n=\(newMoonAxes.count)): \(S.Stats(newMoonAxes).line)")
        S.writeReport(name: "a5_full_moon_salience", content: lines.joined(separator: "\n"))

        XCTAssertFalse(sameBucketDeltas.isEmpty)
    }
}
