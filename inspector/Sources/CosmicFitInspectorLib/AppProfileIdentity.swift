import Foundation

/// Profile identity aligned with the iOS app (`CosmicFitTabBarController`).
enum AppProfileIdentity {

    /// Same formula as `chartIdentifier` in the app tab bar / natal chart VC.
    static func chartId(birthDate: Date, latitude: Double, longitude: Double) -> String {
        "\(birthDate.timeIntervalSince1970)_\(latitude)_\(longitude)"
    }

    /// Matches `userProfile?.id ?? chartId` in the app Daily Fit pipeline.
    static func profileHash(
        birthDate: Date,
        latitude: Double,
        longitude: Double,
        profileId: String?
    ) -> String {
        if let profileId, !profileId.isEmpty { return profileId }
        return chartId(birthDate: birthDate, latitude: latitude, longitude: longitude)
    }
}

enum BirthInstantResolver {

    /// Builds the birth instant the same way as onboarding (`OnboardingFormViewController`).
    static func resolve(
        birthDate: String,
        birthTime: String?,
        unknownTime: Bool,
        timeZoneId: String,
        legacyDateISO: String? = nil
    ) -> Date {
        let tz = TimeZone(identifier: timeZoneId) ?? TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz

        let ymd: String
        if !birthDate.isEmpty {
            ymd = birthDate
        } else if let legacy = legacyDateISO, let parsed = parseLegacyISO(legacy, timeZone: tz) {
            return parsed
        } else {
            return Date()
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = tz
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let day = df.date(from: String(ymd.prefix(10))) else {
            return Date()
        }

        var components = calendar.dateComponents([.year, .month, .day], from: day)
        if unknownTime {
            components.hour = 12
            components.minute = 0
        } else {
            let parts = (birthTime ?? "00:00").split(separator: ":")
            components.hour = Int(parts.first ?? "0") ?? 0
            components.minute = Int(parts.dropFirst().first ?? "0") ?? 0
        }
        components.second = 0
        components.timeZone = tz
        return calendar.date(from: components) ?? day
    }

    private static func parseLegacyISO(_ iso: String, timeZone: TimeZone) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: iso) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: iso) { return d }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
        df.timeZone = timeZone
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: iso)
    }
}

enum DailyFitDateResolver {

    /// Anchor each yyyy-MM-dd target on local noon — stable “calendar day” instant (matches in-app date picker / Ash harness).
    static func targetInstant(from dateString: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = Calendar.current.timeZone
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let day = df.date(from: dateString) else { return Date() }
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }
}
