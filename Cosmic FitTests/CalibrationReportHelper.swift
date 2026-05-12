//
//  CalibrationReportHelper.swift
//  Cosmic FitTests
//
//  Part 5: Shared infrastructure for calibration report output.
//  Handles parallel-safe filenames, tiered gating, and report directory resolution.
//

import Foundation
import Testing
@testable import Cosmic_Fit

// MARK: - Report Tier

enum CalibrationTier {
    /// Tier 1: Diagnostic only — no assertions, always runs
    case diagnostic
    /// Tier 2: CI-gated — hard pass/fail thresholds (enabled via CALIBRATION_CI_GATE=1)
    case ciGated

    static var current: CalibrationTier {
        ProcessInfo.processInfo.environment["CALIBRATION_CI_GATE"] == "1" ? .ciGated : .diagnostic
    }

    var isCIGated: Bool { self == .ciGated }
}

// MARK: - CalibrationReportHelper

enum CalibrationReportHelper {

    // MARK: - Report Directory

    /// Resolve the output directory for calibration reports.
    /// Checks `CALIBRATION_REPORT_DIR` env var first; falls back to `docs/fixtures/`.
    static func reportDirectory() -> URL {
        if let envDir = ProcessInfo.processInfo.environment["CALIBRATION_REPORT_DIR"], !envDir.isEmpty {
            let url = envDir.hasPrefix("/")
                ? URL(fileURLWithPath: envDir)
                : repoRoot().appendingPathComponent(envDir)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        let docsFixtures = repoRoot().appendingPathComponent("docs/fixtures")
        try? FileManager.default.createDirectory(at: docsFixtures, withIntermediateDirectories: true)
        return docsFixtures
    }

    // MARK: - Unique Report Filename

    /// Build a unique report filename with engine version, date, and run disambiguator.
    /// Example: `daily_fit_histogram_v4.7_2026-05-12_pid12345_7f3a2c1d.txt`
    static func uniqueFilename(prefix: String, extension ext: String = "txt") -> String {
        let version = "v4.7"
        let dateStr = isoDateString()
        let pid = ProcessInfo.processInfo.processIdentifier
        let uuid = UUID().uuidString.prefix(8).lowercased()
        return "\(prefix)_\(version)_\(dateStr)_pid\(pid)_\(uuid).\(ext)"
    }

    /// Write a report string to the resolved report directory.
    @discardableResult
    static func writeReport(prefix: String, content: String) -> URL? {
        let dir = reportDirectory()
        let filename = uniqueFilename(prefix: prefix)
        let url = dir.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }

    }

    // MARK: - Histogram Rendering

    /// Render an ASCII histogram from label→count pairs.
    static func renderHistogram(
        title: String,
        data: [(label: String, count: Int)],
        barWidth: Int = 40
    ) -> String {
        var lines: [String] = []
        lines.append("╔══════════════════════════════════════════════════════════════")
        lines.append("║  \(title)")
        lines.append("╚══════════════════════════════════════════════════════════════")
        lines.append("")

        let total = data.reduce(0) { $0 + $1.count }
        let maxCount = data.map(\.count).max() ?? 1

        for (label, count) in data {
            let pct = total > 0 ? Double(count) / Double(total) * 100.0 : 0
            let barLen = maxCount > 0 ? Int(Double(count) / Double(maxCount) * Double(barWidth)) : 0
            let bar = String(repeating: "█", count: barLen) + String(repeating: "░", count: barWidth - barLen)
            let paddedLabel = label.padding(toLength: 20, withPad: " ", startingAt: 0)
            lines.append("  \(paddedLabel)  \(bar)  \(String(format: "%3d", count)) (\(String(format: "%5.1f", pct))%)")
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    /// Render a numeric distribution histogram from bucketed values.
    static func renderNumericHistogram(
        title: String,
        values: [Double],
        bucketCount: Int = 10,
        rangeMin: Double = 0.0,
        rangeMax: Double = 1.0,
        barWidth: Int = 40
    ) -> String {
        let step = (rangeMax - rangeMin) / Double(bucketCount)
        var buckets = [Int](repeating: 0, count: bucketCount)
        for v in values {
            let idx = min(Int((v - rangeMin) / step), bucketCount - 1)
            if idx >= 0 && idx < bucketCount { buckets[idx] += 1 }
        }
        let data = (0..<bucketCount).map { i -> (label: String, count: Int) in
            let lo = rangeMin + Double(i) * step
            let hi = lo + step
            return (label: String(format: "%.2f-%.2f", lo, hi), count: buckets[i])
        }
        return renderHistogram(title: title, data: data, barWidth: barWidth)
    }

    /// Render summary statistics for an array of doubles.
    static func summaryStats(label: String, values: [Double]) -> String {
        guard !values.isEmpty else { return "  \(label): no data" }
        let sorted = values.sorted()
        let mean = values.reduce(0.0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0.0, +) / Double(values.count)
        let stddev = sqrt(variance)
        return "  \(label): n=\(values.count)  min=\(f3(sorted.first!))  max=\(f3(sorted.last!))  mean=\(f3(mean))  stddev=\(f3(stddev))"
    }

    // MARK: - Private Helpers

    private static func repoRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        // Walk up from Cosmic FitTests/ to the repo root
        url.deleteLastPathComponent() // remove filename
        url.deleteLastPathComponent() // remove Cosmic FitTests
        return url
    }

    private static func isoDateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: Date())
    }

    private static func f3(_ v: Double) -> String { String(format: "%.3f", v) }
}
