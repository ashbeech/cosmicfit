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
        
        // Check if user profile exists to determine app flow
        if UserProfileStorage.shared.hasUserProfile() {
            // Existing user - go directly to main app with stored data
            if let userProfile = UserProfileStorage.shared.loadUserProfile() {
                let tabBarController = CosmicFitTabBarController()
                let navigationController = UINavigationController(rootViewController: tabBarController)
                
                // Configure with stored user data
                let chartData = NatalChartManager.shared.calculateNatalChart(
                    date: userProfile.birthDate,
                    latitude: userProfile.latitude,
                    longitude: userProfile.longitude,
                    timeZone: TimeZone(identifier: userProfile.timeZoneIdentifier) ?? TimeZone.current
                )
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                let birthInfo = "\(dateFormatter.string(from: userProfile.birthDate)) at \(userProfile.birthLocation) (Lat: \(String(format: "%.4f", userProfile.latitude)), Long: \(String(format: "%.4f", userProfile.longitude)))"
                
                tabBarController.configure(with: chartData,
                                         birthInfo: birthInfo,
                                         birthDate: userProfile.birthDate,
                                         latitude: userProfile.latitude,
                                         longitude: userProfile.longitude,
                                         timeZone: TimeZone(identifier: userProfile.timeZoneIdentifier) ?? TimeZone.current)
                
                // Set Daily Fit as default tab (index 1) for returning users
                tabBarController.selectedIndex = 1
                
                launchScreenVC.setMainViewController(navigationController)
                
                print("✅ Returning user detected - launching to Daily Fit tab")
            } else {
                // Profile exists but corrupted - fallback to onboarding
                setupFirstTimeUser(launchScreenVC: launchScreenVC)
            }
        } else {
            // First time user - show onboarding form
            setupFirstTimeUser(launchScreenVC: launchScreenVC)
            print("📱 First time user detected - showing onboarding")
        }
        
        setupGlobalAppearance()
        
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
    
    private func setupFirstTimeUser(launchScreenVC: AnimatedLaunchScreenViewController) {
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        launchScreenVC.setMainViewController(navigationController)
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
        // Hide navigation bars globally
        UINavigationBar.appearance().isHidden = true
        
        // Configure tab bar appearance only
        UITabBar.appearance().backgroundColor = .systemBackground
        UITabBar.appearance().tintColor = .systemBlue
        UITabBar.appearance().unselectedItemTintColor = .systemGray
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
    
    private func setupGlobalAppearance() {
        // Configure global appearance proxy settings
        if #available(iOS 13.0, *) {
            // Set window background
            if let window = window {
                window.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
            }
        }
        
        // Configure global UI appearance
        UINavigationBar.appearance().backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        UINavigationBar.appearance().tintColor = CosmicFitTheme.Colors.cosmicOrange
        UITabBar.appearance().backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        UITabBar.appearance().tintColor = CosmicFitTheme.Colors.cosmicOrange
        UITabBar.appearance().unselectedItemTintColor = CosmicFitTheme.Colors.cosmicBlue
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Posted when the daily vibe needs to be refreshed due to date change
    static let dailyVibeNeedsRefresh = Notification.Name("dailyVibeNeedsRefresh")
}
