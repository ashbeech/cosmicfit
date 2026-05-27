//
//  DailyFitSkyAnchor.swift
//  Cosmic Fit
//
//  Resolves the deterministic "sky moment" used for Daily Fit transit, lunar,
//  and snapshot calculations. Anchors to local noon of the target calendar day
//  in `TimeZone.current`, the same timezone used by `DailyFitRevealPersistence`
//  and `DailyFitFrozenPayloadStorage` calendar-day keys.
//
//  The Inspector mirrors this anchor in `DailyFitDateResolver.targetInstant`,
//  so app and inspector outputs align byte-for-byte for any target day.
//

import Foundation

enum DailyFitSkyAnchor {

    /// Local noon of the calendar day containing `date`, computed in
    /// `TimeZone.current`. If noon cannot be resolved (e.g. an exotic
    /// calendar configuration), falls back to start-of-day.
    static func instant(
        forCalendarDay date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startOfDay) ?? startOfDay
    }
}
