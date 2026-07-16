//
//  DailyFitEngineRegistry.swift
//  Cosmic Fit
//
//  Canonical Daily Fit engine preset registry (single source of truth).
//

import Foundation
import CryptoKit

/// Pipeline algorithm variant for a Daily Fit engine preset (§5.4).
enum DailyFitEngineMode: Equatable {
    case standard
    case stage1Experimental
    /// Sky Forward v1.0.2 — stage-1 sky-forward pipeline with calibrated (fingerprinted)
    /// sky mix, continuous significance-weighted lunar vibe, normalised transits, and
    /// named lunar events. A refinement of `.stage1Experimental`, not a separate pipeline.
    case stage2SkyFidelity
}

extension DailyFitEngineMode {
    /// Sky-forward pipeline family: both `.stage1Experimental` (v1.0.1) and its v1.0.2
    /// refinement `.stage2SkyFidelity` run the chart-anchor + sky-vibe + salience pipeline.
    /// Pipeline-structure gates use this so the new mode inherits every stage-1 behaviour;
    /// the v1.0.2-specific vibe math gates on `== .stage2SkyFidelity` directly.
    var usesSkyForwardPipeline: Bool {
        self == .stage1Experimental || self == .stage2SkyFidelity
    }

    /// True only for the v1.0.2 sky-fidelity vibe path (continuous lunar + normalised transits).
    var usesSkyFidelityVibe: Bool {
        self == .stage2SkyFidelity
    }
}

/// Daily RNG seed policy per preset (§9.2).
enum DailyFitDailySeedPolicy: Equatable {
    /// S1 — `profileHash + date` only (calibration A/B isolation).
    case sharedProfileDate
    /// S2 — includes engine id when algorithm mode diverges.
    case includesEngineId
}

struct DailyFitEngineDescriptor: Equatable {
    let id: String
    let displayName: String
    let summary: String
    let isExperimental: Bool
    let calibration: DailyFitCalibration
    let fingerprint: String
    let mode: DailyFitEngineMode
    let dailySeedPolicy: DailyFitDailySeedPolicy
    /// Shipped marketing version (production only); nil for experimental presets.
    let marketingVersion: String?
}

enum DailyFitEngineRegistry {

    static let productionId = "production"
    static let legacyBaselineId = "legacy_baseline"
    static let stage1ExperimentalId = "stage1_experimental"
    static let stage2LegacyId = "stage2_legacy"
    /// Rollback preset: shipped v1.0.1 calibration + algorithm, runnable after the v1.0.2 cutover.
    static let skyForwardV101Id = "sky_forward_v1_0_1"
    /// Experimental v1.0.2 sky-fidelity preset (validated pre-cutover; becomes production in Phase 7).
    static let skyForwardV102Id = "sky_forward_v1_0_2"

    static let productionMarketingVersion = "1.0.2"
    /// Marketing version retained on the `sky_forward_v1_0_1` rollback preset after cutover.
    static let skyForwardV101MarketingVersion = "1.0.1"

    static var productionDisplayName: String {
        descriptor(for: productionId)?.displayName ?? "Sky Forward"
    }

    /// Read-only Profile / about copy for Release builds.
    static var productionEngineDisplayLine: String {
        "Cosmic Fit Engine: \(productionDisplayName) v\(productionMarketingVersion)"
    }

    /// Compact version stamp shown on Profile in production builds.
    static var productionVersionDisplayText: String {
        "\(productionDisplayName) v\(productionMarketingVersion)"
    }

    static let allDescriptors: [DailyFitEngineDescriptor] = [
        productionDescriptor,
        skyForwardV101Descriptor,
        skyForwardV102Descriptor,
        legacyBaselineDescriptor,
        stage1ExperimentalDescriptor,
        stage2LegacyDescriptor,
    ]

    static func descriptor(for id: String) -> DailyFitEngineDescriptor? {
        allDescriptors.first { $0.id == id }
    }

    static func calibration(for id: String) -> DailyFitCalibration {
        if let descriptor = descriptor(for: id) {
            return descriptor.calibration
        }
        logUnknownEngineWarning(id)
        return descriptor(for: productionId)?.calibration ?? DailyFitCalibration.default
    }

    static func mode(for id: String) -> DailyFitEngineMode {
        descriptor(for: id)?.mode ?? .standard
    }

    /// Resolves mode from an explicit parameter and/or registry engine id (§5.4 central dispatch).
    static func resolvedMode(
        explicit: DailyFitEngineMode = .standard,
        engineId: String? = nil
    ) -> DailyFitEngineMode {
        if explicit != .standard { return explicit }
        if let engineId, let descriptor = descriptor(for: engineId) {
            return descriptor.mode
        }
        return .standard
    }

    static func engineId(
        for calibration: DailyFitCalibration,
        mode: DailyFitEngineMode = .standard
    ) -> String {
        if let match = allDescriptors.first(where: {
            $0.calibration == calibration && $0.mode == mode
        }) {
            return match.id
        }
        if let match = allDescriptors.first(where: { $0.calibration == calibration }) {
            return match.id
        }
        return productionId
    }

    static func fingerprint(for calibration: DailyFitCalibration) -> String {
        let canonical = canonicalCalibrationString(for: calibration)
        let digest = SHA256.hash(data: Data(canonical.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Presets

    /// Pre–Stage 2 weights preserved verbatim from exploration tests (§5.2).
    private static let legacyBaselineCalibration: DailyFitCalibration = {
        let source = DailyFitCalibration.SourceWeights(
            natal: 0.40, transits: 0.25, lunarPhase: 0.15,
            progressed: 0.15, currentSun: 0.05
        )
        let selection = DailyFitCalibration.SelectionWeights(
            vibeWeight: 0.50, axisWeight: 0.35, transitBoost: 0.15
        )
        return DailyFitCalibration(
            sourceWeights: source,
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            signMultiplierPolicy: .productionDefault,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: selection,
            axisTuning: DailyFitCalibration.AxisTuning(sigmoidSpread: 2.0, jitterRange: 0.1),
            stage2Sensitivity: DailyFitCalibration.Stage2Sensitivity(
                paletteJitter: 0.001, vibrancyCoeff: 0.15,
                contrastCoeff: 0.20, silhouetteAxisScale: 1.0,
                metalNudgePerHit: 0.05
            )
        )
    }()

    /// Pre–Sky Forward Stage 2 calibration preserved for DEBUG regression comparison.
    private static let stage2LegacyCalibration: DailyFitCalibration = .default

    private static let productionDescriptor = DailyFitEngineDescriptor(
        id: productionId,
        displayName: "Sky Forward",
        summary: "Shipped Daily Fit engine — lunar-led sky-fidelity daily read (v1.0.2)",
        isExperimental: false,
        calibration: skyFidelityCalibration,
        fingerprint: fingerprint(for: skyFidelityCalibration),
        mode: .stage2SkyFidelity,
        dailySeedPolicy: .includesEngineId,
        marketingVersion: productionMarketingVersion
    )

    private static let legacyBaselineDescriptor = DailyFitEngineDescriptor(
        id: legacyBaselineId,
        displayName: "Legacy Baseline",
        summary: "Pre–Stage 2 source and axis weights for regression comparison",
        isExperimental: true,
        calibration: legacyBaselineCalibration,
        fingerprint: fingerprint(for: legacyBaselineCalibration),
        mode: .standard,
        dailySeedPolicy: .sharedProfileDate,
        marketingVersion: nil
    )

    /// Stage 1 sky-forward sandbox: chart anchor + amplified outside-energy delta (§5.4).
    private static let stage1ExperimentalCalibration: DailyFitCalibration = {
        let source = DailyFitCalibration.SourceWeights(
            natal: 0.16, transits: 0.44, lunarPhase: 0.30,
            progressed: 0.07, currentSun: 0.03
        )
        let selection = DailyFitCalibration.SelectionWeights(
            vibeWeight: 0.40, axisWeight: 0.30, transitBoost: 0.30
        )
        return DailyFitCalibration(
            sourceWeights: source,
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            signMultiplierPolicy: .stage1OptionA,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: selection,
            axisTuning: DailyFitCalibration.AxisTuning(sigmoidSpread: 0.8, jitterRange: 0.40),
            stage2Sensitivity: DailyFitCalibration.Stage2Sensitivity(
                paletteJitter: 0.20, vibrancyCoeff: 0.55,
                contrastCoeff: 0.55, silhouetteAxisScale: 1.25,
                metalNudgePerHit: 0.12,
                paletteSelectionStrategy: .pureSkyScoring
            ),
            narrativeSelection: .stage1Default
        )
    }()

    /// DEBUG alias — same calibration as shipped Sky Forward production; kept for frozen-payload compatibility.
    private static let stage1ExperimentalDescriptor = DailyFitEngineDescriptor(
        id: stage1ExperimentalId,
        displayName: "Stage 1 Experimental (Sky Forward alias)",
        summary: "DEBUG alias of shipped Sky Forward production — same calibration and fingerprint",
        isExperimental: true,
        calibration: stage1ExperimentalCalibration,
        fingerprint: fingerprint(for: stage1ExperimentalCalibration),
        mode: .stage1Experimental,
        dailySeedPolicy: .includesEngineId,
        marketingVersion: nil
    )

    /// Pre–Sky Forward Stage 2 production calibration (dramaSlots) for DEBUG regression.
    private static let stage2LegacyDescriptor = DailyFitEngineDescriptor(
        id: stage2LegacyId,
        displayName: "Stage 2 Legacy (pre-Sky Forward)",
        summary: "Previous production calibration (.default / dramaSlots) for regression comparison",
        isExperimental: true,
        calibration: stage2LegacyCalibration,
        fingerprint: fingerprint(for: stage2LegacyCalibration),
        mode: .standard,
        dailySeedPolicy: .sharedProfileDate,
        marketingVersion: nil
    )

    /// Rollback preset — the shipped v1.0.1 calibration + algorithm, retained runnable
    /// after the v1.0.2 cutover. Same calibration and mode as `productionDescriptor`
    /// (pre-cutover), so `engineId(for:mode:)` collapses it to `production` for seeding →
    /// byte-identical v1.0.1 output. Kept as its own selectable id + retained `"1.0.1"` stamp.
    private static let skyForwardV101Descriptor = DailyFitEngineDescriptor(
        id: skyForwardV101Id,
        displayName: "Sky Forward",
        summary: "Rollback preset — shipped Sky Forward v1.0.1 calibration + algorithm (v1.0.1)",
        isExperimental: true,
        calibration: stage1ExperimentalCalibration,
        fingerprint: fingerprint(for: stage1ExperimentalCalibration),
        mode: .stage1Experimental,
        dailySeedPolicy: .includesEngineId,
        marketingVersion: skyForwardV101MarketingVersion
    )

    /// Sky Forward v1.0.2 sky-fidelity calibration (§5.4, audit F1/F2/F3/F5/F6).
    /// Stage-1 sky-forward pipeline with: fingerprinted sky mix (`skyVibeWeights`, Phase 2),
    /// continuous significance-weighted lunar vibe (`lunarSignificanceCoeff`, Phase 3),
    /// normalised transits (Phase 4), jitter cut 0.40 → 0.18 (F5), and named lunar events (Phase 5).
    private static let skyFidelityCalibration: DailyFitCalibration = {
        let source = DailyFitCalibration.SourceWeights(
            natal: 0.16, transits: 0.44, lunarPhase: 0.30,
            progressed: 0.07, currentSun: 0.03
        )
        let selection = DailyFitCalibration.SelectionWeights(
            vibeWeight: 0.40, axisWeight: 0.30, transitBoost: 0.30
        )
        return DailyFitCalibration(
            sourceWeights: source,
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            signMultiplierPolicy: .stage1OptionA,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: selection,
            // F5: jitter 0.40 → 0.18 (legacy floor, below the ±0.3 full-moon axis nudge).
            axisTuning: DailyFitCalibration.AxisTuning(sigmoidSpread: 0.8, jitterRange: 0.18),
            stage2Sensitivity: DailyFitCalibration.Stage2Sensitivity(
                paletteJitter: 0.20, vibrancyCoeff: 0.55,
                contrastCoeff: 0.55, silhouetteAxisScale: 1.25,
                metalNudgePerHit: 0.12,
                paletteSelectionStrategy: .pureSkyScoring
            ),
            narrativeSelection: .stage1Default,
            // Ratified lunar-dominant seed (owner 2026-07-13): the fingerprinted sky mix.
            skyVibeWeights: DailyFitCalibration.SkyVibeWeights(
                transits: 0.25, lunar: 0.60, currentSun: 0.15
            ),
            // Significance amplification seed k = 0.8 (Phase 3).
            lunarSignificanceCoeff: 0.8
        )
    }()

    /// Experimental v1.0.2 preset — validated through the full ladder before the Phase-7 cutover.
    private static let skyForwardV102Descriptor = DailyFitEngineDescriptor(
        id: skyForwardV102Id,
        displayName: "Sky Forward",
        summary: "Sky Forward v1.0.2 sky-fidelity engine (experimental; lunar-led calibration)",
        isExperimental: true,
        calibration: skyFidelityCalibration,
        fingerprint: fingerprint(for: skyFidelityCalibration),
        mode: .stage2SkyFidelity,
        dailySeedPolicy: .includesEngineId,
        marketingVersion: nil
    )

    // MARK: - Fingerprint serialization (§5.3)

    private static func canonicalCalibrationString(for calibration: DailyFitCalibration) -> String {
        var parts: [String] = []

        let sw = calibration.sourceWeights
        parts.append(String(
            format: "sourceWeights:natal=%.6f,transits=%.6f,lunarPhase=%.6f,progressed=%.6f,currentSun=%.6f",
            sw.natal, sw.transits, sw.lunarPhase, sw.progressed, sw.currentSun
        ))

        var signParts: [String] = []
        for sign in calibration.signEnergyMap.multipliers.keys.sorted() {
            guard let energies = calibration.signEnergyMap.multipliers[sign] else { continue }
            let energyParts = energies.keys
                .sorted { $0.rawValue < $1.rawValue }
                .map { energy in
                    String(format: "%@=%.6f", energy.rawValue, energies[energy] ?? 0)
                }
                .joined(separator: ",")
            signParts.append("\(sign)={\(energyParts)}")
        }
        parts.append("signEnergyMap:{\(signParts.joined(separator: ";"))}")

        let policy = calibration.signMultiplierPolicy
        parts.append(String(
            format: "signMultiplierPolicy:applyToDailyVibe=%d,applyToChartAnchor=%d",
            policy.applyToDailyVibe ? 1 : 0,
            policy.applyToChartAnchor ? 1 : 0
        ))

        if let threshold = calibration.elementBoostDedupeThreshold {
            parts.append(String(format: "elementBoostDedupeThreshold=%.6f", threshold))
        } else {
            parts.append("elementBoostDedupeThreshold=off")
        }

        var planetParts: [String] = []
        for planet in calibration.planetAxisMap.weights.keys.sorted() {
            guard let axes = calibration.planetAxisMap.weights[planet] else { continue }
            let axisParts = axes.keys.sorted().map { axis in
                String(format: "%@=%.6f", axis, axes[axis] ?? 0)
            }.joined(separator: ",")
            planetParts.append("\(planet)={\(axisParts)}")
        }
        parts.append("planetAxisMap:{\(planetParts.joined(separator: ";"))}")

        let sel = calibration.selectionWeights
        parts.append(String(
            format: "selectionWeights:vibeWeight=%.6f,axisWeight=%.6f,transitBoost=%.6f",
            sel.vibeWeight, sel.axisWeight, sel.transitBoost
        ))

        let at = calibration.axisTuning
        parts.append(String(
            format: "axisTuning:sigmoidSpread=%.6f,jitterRange=%.6f",
            at.sigmoidSpread, at.jitterRange
        ))

        let s2 = calibration.stage2Sensitivity
        parts.append(String(
            format: "stage2Sensitivity:paletteJitter=%.6f,vibrancyCoeff=%.6f,contrastCoeff=%.6f,silhouetteAxisScale=%.6f,metalNudgePerHit=%.6f,paletteStrategy=%@",
            s2.paletteJitter, s2.vibrancyCoeff, s2.contrastCoeff, s2.silhouetteAxisScale, s2.metalNudgePerHit,
            s2.paletteSelectionStrategy.rawValue
        ))

        if let ns = calibration.narrativeSelection {
            parts.append(String(
                format: "narrativeSelection:categoryBoostWeight=%.6f,rolePreferenceBonus=%.6f,categoryEnergyWeight=%.6f,narrativePaletteJitter=%.6f,softenVibrancyCap=%.6f,softenContrastCap=%.6f,softenBaselineBlend=%.6f,intenseAnchorRestrainedWeatherBlend=%.6f,variantBridgeWeight=%.6f,bridgeCandidatePoolSize=%d,minVariantBridgeSimilarity=%.6f,minBridgeMargin=%.6f,pairScoreTieEpsilon=%.6f,variantFormBridgeWeight=%.6f,structureSkyWeight=%.6f,structureSilhouetteWeight=%.6f,minFormBridgeSimilarity=%.6f,structureVariantStrategyFloor=%d,structureSliderThreshold=%.6f",
                ns.categoryBoostWeight, ns.rolePreferenceBonus, ns.categoryEnergyWeight, ns.narrativePaletteJitter,
                ns.softenVibrancyCap, ns.softenContrastCap, ns.softenBaselineBlend, ns.intenseAnchorRestrainedWeatherBlend,
                ns.variantBridgeWeight, ns.bridgeCandidatePoolSize, ns.minVariantBridgeSimilarity, ns.minBridgeMargin, ns.pairScoreTieEpsilon,
                ns.variantFormBridgeWeight, ns.structureSkyWeight, ns.structureSilhouetteWeight, ns.minFormBridgeSimilarity,
                ns.structureVariantStrategyFloor, ns.structureSliderThreshold
            ))
        } else {
            parts.append("narrativeSelection=off")
        }

        // v1.0.2 sky-fidelity fields. Serialised ONLY when present so every pre-v1.0.2
        // preset's canonical string (and therefore fingerprint) stays byte-identical.
        if let svw = calibration.skyVibeWeights {
            parts.append(String(
                format: "skyVibeWeights:transits=%.6f,lunar=%.6f,currentSun=%.6f",
                svw.transits, svw.lunar, svw.currentSun
            ))
        }
        if let k = calibration.lunarSignificanceCoeff {
            parts.append(String(format: "lunarSignificanceCoeff=%.6f", k))
        }

        return parts.joined(separator: "|")
    }

    private static func logUnknownEngineWarning(_ id: String) {
        #if DEBUG
        print("[DailyFitEngineRegistry] Unknown dailyFitEngineId '\(id)'; falling back to production")
        #endif
    }
}
