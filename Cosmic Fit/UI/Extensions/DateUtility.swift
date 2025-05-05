//
//  DateUtility.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

/// Utility class for date formatting and manipulation
class DateUtility {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = DateUtility()
    
    // MARK: - Date Formatters
    
    /// Date formatter for date only (e.g., "January 1, 2025")
    private let dateFormatter: DateFormatter
    
    /// Date formatter for time only (e.g., "12:30 PM")
    private let timeFormatter: DateFormatter
    
    /// Date formatter for complete date and time (e.g., "January 1, 2025 at 12:30:45 PM")
    private let fullFormatter: DateFormatter
    
    /// Date formatter for short date (e.g., "01/01/2025")
    private let shortDateFormatter: DateFormatter
    
    /// Date formatter for ISO8601 dates
    private let iso8601Formatter: ISO8601DateFormatter
    
    // MARK: - Initialization
    
    private init() {
        // Initialize date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        // Initialize time formatter
        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        // Initialize full formatter
        fullFormatter = DateFormatter()
        fullFormatter.dateStyle = .long
        fullFormatter.timeStyle = .medium
        
        // Initialize short date formatter
        shortDateFormatter = DateFormatter()
        shortDateFormatter.dateStyle = .short
        shortDateFormatter.timeStyle = .none
        
        // Initialize ISO8601 formatter
        iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    // MARK: - Public Formatting Methods
    
    /// Format a date as a long date string (e.g., "January 1, 2025")
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    /// Format a date as a time string (e.g., "12:30 PM")
    /// - Parameter date: The date to format
    /// - Returns: Formatted time string
    func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    /// Format a date as a full date and time string (e.g., "January 1, 2025 at 12:30:45 PM")
    /// - Parameter date: The date to format
    /// - Returns: Formatted full date and time string
    func formatFullDateTime(_ date: Date) -> String {
        return fullFormatter.string(from: date)
    }
    
    /// Format a date as a short date string (e.g., "01/01/2025")
    /// - Parameter date: The date to format
    /// - Returns: Formatted short date string
    func formatShortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }
    
    /// Format a date as an ISO8601 string
    /// - Parameter date: The date to format
    /// - Returns: ISO8601 formatted string
    func formatISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    /// Format a date for report display with separate date and time lines
    /// - Parameter date: The date to format
    /// - Returns: Multi-line formatted string for reports
    func formatForReport(_ date: Date) -> String {
        return "Date: \(formatDate(date))\nTime: \(formatTime(date))"
    }
    
    // MARK: - Date Creation Methods
    
    /// Create a date from separate components
    /// - Parameters:
    ///   - day: Day (1-31)
    ///   - month: Month (1-12)
    ///   - year: Year
    ///   - hour: Hour (0-23)
    ///   - minute: Minute (0-59)
    ///   - second: Second (0-59)
    /// - Returns: Date object or nil if invalid
    func createDate(day: Int, month: Int, year: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date? {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return Calendar.current.date(from: components)
    }
    
    /// Create a date from date components and AM/PM designator
    /// - Parameters:
    ///   - day: Day (1-31)
    ///   - month: Month (1-12)
    ///   - year: Year
    ///   - hour: Hour (1-12)
    ///   - minute: Minute (0-59)
    ///   - isPM: Whether the time is PM (true) or AM (false)
    /// - Returns: Date object or nil if invalid
    func createDate(day: Int, month: Int, year: Int, hour12: Int, minute: Int, isPM: Bool) -> Date? {
        // Convert 12-hour format to 24-hour format
        let hour24 = isPM ?
            (hour12 == 12 ? 12 : hour12 + 12) :
            (hour12 == 12 ? 0 : hour12)
        
        return createDate(day: day, month: month, year: year, hour: hour24, minute: minute)
    }
    
    // MARK: - Date Calculation Methods
    
    /// Calculate age in years from a birth date
    /// - Parameter birthDate: Birth date
    /// - Returns: Age in years
    func calculateAge(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    /// Get the day of week as a string for a given date
    /// - Parameter date: The date
    /// - Returns: Day of week as string (e.g., "Monday")
    func getDayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
