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
}

enum DailyFitEngineRegistry {

    static let productionId = "production"
    static let legacyBaselineId = "legacy_baseline"
    static let stage1ExperimentalId = "stage1_experimental"

    static let allDescriptors: [DailyFitEngineDescriptor] = [
        productionDescriptor,
        legacyBaselineDescriptor,
        stage1ExperimentalDescriptor,
    ]

    static func descriptor(for id: String) -> DailyFitEngineDescriptor? {
        allDescriptors.first { $0.id == id }
    }

    static func calibration(for id: String) -> DailyFitCalibration {
        if let descriptor = descriptor(for: id) {
            return descriptor.calibration
        }
        logUnknownEngineWarning(id)
        return DailyFitCalibration.default
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

    private static let productionDescriptor = DailyFitEngineDescriptor(
        id: productionId,
        displayName: "Production (Stage 2)",
        summary: "Current shipped Daily Fit calibration (.default)",
        isExperimental: false,
        calibration: .default,
        fingerprint: fingerprint(for: .default),
        mode: .standard,
        dailySeedPolicy: .sharedProfileDate
    )

    private static let legacyBaselineDescriptor = DailyFitEngineDescriptor(
        id: legacyBaselineId,
        displayName: "Legacy Baseline",
        summary: "Pre–Stage 2 source and axis weights for regression comparison",
        isExperimental: true,
        calibration: legacyBaselineCalibration,
        fingerprint: fingerprint(for: legacyBaselineCalibration),
        mode: .standard,
        dailySeedPolicy: .sharedProfileDate
    )

    /// Stage 1 redesign candidate: transit vibe nudges + fractional essence (§5.4). S2 seed policy.
    private static let stage1ExperimentalDescriptor = DailyFitEngineDescriptor(
        id: stage1ExperimentalId,
        displayName: "Stage 1 Experimental",
        summary: "Transit-weighted vibe nudges and axis-heavy essence scoring (DEBUG/inspector)",
        isExperimental: true,
        calibration: .default,
        fingerprint: fingerprint(for: .default),
        mode: .stage1Experimental,
        dailySeedPolicy: .includesEngineId
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
            format: "stage2Sensitivity:paletteJitter=%.6f,vibrancyCoeff=%.6f,contrastCoeff=%.6f,silhouetteAxisScale=%.6f,metalNudgePerHit=%.6f",
            s2.paletteJitter, s2.vibrancyCoeff, s2.contrastCoeff, s2.silhouetteAxisScale, s2.metalNudgePerHit
        ))

        return parts.joined(separator: "|")
    }

    private static func logUnknownEngineWarning(_ id: String) {
        #if DEBUG
        print("[DailyFitEngineRegistry] Unknown dailyFitEngineId '\(id)'; falling back to production")
        #endif
    }
}
