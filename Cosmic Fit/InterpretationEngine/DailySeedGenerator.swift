//
//  DailySeedGenerator.swift
//  Cosmic Fit
//

import Foundation
import CryptoKit

/// Generates stable, deterministic seeds for daily content variation.
final class DailySeedGenerator {

    // MARK: - Public

    /// Generate a stable daily seed based on a profile hash and date.
    /// - Parameters:
    ///   - profileHash: Stable identifier for the user/profile (e.g. your chart/profile id).
    ///   - date: Date to generate the seed for (defaults to today).
    static func generateDailySeed(profileHash: String, for date: Date = Date()) -> Int {
        let dateString = dateFormatter.string(from: date)
        let combined = "\(profileHash)_\(dateString)"
        return intSeed(from: combined)
    }

    /// Generate a stable daily seed based on birth details (in case profileHash is unavailable).
    static func generateDailySeed(
        birthDate: Date,
        latitude: Double,
        longitude: Double,
        for date: Date = Date()
    ) -> Int {
        let birthFormatter = DateFormatter()
        birthFormatter.dateFormat = "yyyy-MM-dd_HH:mm"
        birthFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        birthFormatter.locale = Locale(identifier: "en_GB")

        let birthString = birthFormatter.string(from: birthDate)
        let locationString = String(format: "%.4f_%.4f", latitude, longitude)
        let combinedProfile = "\(birthString)_\(locationString)"

        let dateString = dateFormatter.string(from: date)
        let combined = "\(combinedProfile)_\(dateString)"
        return intSeed(from: combined)
    }

    /// Convert any string to a deterministic Int seed.
    static func intSeed(from string: String) -> Int {
        let hash = SHA256.hash(data: Data(string.utf8))
        // take first 8 hex chars for a 32-bit range
        let prefix = hash.compactMap { String(format: "%02x", $0) }.joined().prefix(8)
        return Int(prefix, radix: 16) ?? abs(string.hashValue)
    }

    // MARK: - Private

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // stable across devices/timezones
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
}

/// A simple deterministic RNG based on a seed.
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed))
        self.state &*= 6364136223846793005
        self.state &+= 1442695040888963407
    }

    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        return state
    }
}

extension Array {
    /// Deterministically shuffle, returning a new array.
    func shuffled(seed: Int) -> [Element] {
        var g = SeededRandomGenerator(seed: seed)
        return shuffled(using: &g)
    }

    /// Deterministically shuffle in place.
    mutating func shuffle(seed: Int) {
        var g = SeededRandomGenerator(seed: seed)
        shuffle(using: &g)
    }
}
