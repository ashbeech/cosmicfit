//
//  TrialCopyTests.swift
//  Cosmic FitTests
//
//  Trial duration copy formatters backing the annual free-trial paywall
//  ("7 days free, then …/year" / "a 7-day free trial").
//

import Testing
import StoreKit
@testable import Cosmic_Fit

@MainActor
struct TrialCopyTests {

    @Test func oneWeekRendersAsSevenDays() {
        #expect(StoreKitManager.trialDurationText(value: 1, unit: .week) == "7 days")
        #expect(StoreKitManager.trialDurationAdjective(value: 1, unit: .week) == "7-day")
    }

    @Test func dayValuesPluraliseCorrectly() {
        #expect(StoreKitManager.trialDurationText(value: 1, unit: .day) == "1 day")
        #expect(StoreKitManager.trialDurationText(value: 3, unit: .day) == "3 days")
        #expect(StoreKitManager.trialDurationText(value: 7, unit: .day) == "7 days")
        #expect(StoreKitManager.trialDurationAdjective(value: 3, unit: .day) == "3-day")
        #expect(StoreKitManager.trialDurationAdjective(value: 7, unit: .day) == "7-day")
    }

    @Test func multiWeekRendersAsDays() {
        #expect(StoreKitManager.trialDurationText(value: 2, unit: .week) == "14 days")
        #expect(StoreKitManager.trialDurationAdjective(value: 2, unit: .week) == "14-day")
    }

    @Test func monthAndYearUnits() {
        #expect(StoreKitManager.trialDurationText(value: 1, unit: .month) == "1 month")
        #expect(StoreKitManager.trialDurationText(value: 3, unit: .month) == "3 months")
        #expect(StoreKitManager.trialDurationText(value: 1, unit: .year) == "1 year")
        #expect(StoreKitManager.trialDurationAdjective(value: 1, unit: .month) == "1-month")
        #expect(StoreKitManager.trialDurationAdjective(value: 1, unit: .year) == "1-year")
    }
}
