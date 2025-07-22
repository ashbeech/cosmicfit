//
//  AppDelegate.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var lastActiveDate: Date?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Set up the animated launch screen as the initial view controller
        let launchScreenVC = AnimatedLaunchScreenViewController()
        
        // Create the main view controller and navigation controller
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        // Tell the launch screen which view controller to transition to
        launchScreenVC.setMainViewController(navigationController)
        
        // Set the launch screen as the root view controller
        window?.rootViewController = launchScreenVC
        window?.makeKeyAndVisible()
        
        // Initialize debug enhancements
        //DebugInitializer.setupDebugEnhancements()
        
        // Configure appearance
        configureAppearance()
        
        // Set up daily vibe management
        setupDailyVibeManagement()
        
        // Store current date for comparison when app becomes active
        lastActiveDate = Date()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Check if the date has changed since the app was last active
        checkForDateChange()
        
        // Update last active date
        lastActiveDate = Date()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Store the current date when app goes to background
        lastActiveDate = Date()
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().barTintColor = .white
            UINavigationBar.appearance().tintColor = .black
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black]
            UINavigationBar.appearance().isTranslucent = false
        }
    }
    
    private func setupDailyVibeManagement() {
        // Clean up old daily vibe entries on app launch
        DailyVibeStorage.shared.cleanupOldEntries(daysToKeep: 30)
        
        // Set up background task for midnight refresh if needed
        setupMidnightRefreshObserver()
    }
    
    private func setupMidnightRefreshObserver() {
        // Listen for day change notifications (when crossing midnight)
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDateChange()
        }
        
        // Also listen for timezone change notifications
        NotificationCenter.default.addObserver(
            forName: UIApplication.significantTimeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDateChange()
        }
    }
    
    private func checkForDateChange() {
        guard let lastDate = lastActiveDate else { return }
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Check if we're on a different day
        if !calendar.isDate(lastDate, inSameDayAs: currentDate) {
            print("📅 Date changed detected: \(lastDate) -> \(currentDate)")
            handleDateChange()
        }
    }
    
    private func handleDateChange() {
        print("🔄 Handling date change - preparing for new daily vibe")
        
        // Post notification that date has changed
        // This allows any daily vibe view controllers to refresh their content
        NotificationCenter.default.post(name: .dailyVibeNeedsRefresh, object: nil)
        
        // Clear any cached daily vibe data for the new day
        // (The storage handles date-specific keys, so this is just for any in-memory caches)
        
        // Optionally clean up old entries
        DailyVibeStorage.shared.cleanupOldEntries(daysToKeep: 30)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Posted when the daily vibe needs to be refreshed due to date change
    static let dailyVibeNeedsRefresh = Notification.Name("dailyVibeNeedsRefresh")
}
