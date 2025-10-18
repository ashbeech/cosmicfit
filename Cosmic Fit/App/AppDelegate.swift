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
        
        // Determine app flow based on user profile and welcome state
        if UserProfileStorage.shared.hasCompleteUserProfile() {
            // User has complete profile - go directly to main app
            setupExistingUserFlow(launchScreenVC: launchScreenVC)
        } else {
            // User needs onboarding - check if they've seen welcome
            if UserProfileStorage.shared.hasSeenWelcome() {
                // Skip welcome, go straight to form
                setupOnboardingFormFlow(launchScreenVC: launchScreenVC)
            } else {
                // Show welcome intro first
                setupWelcomeIntroFlow(launchScreenVC: launchScreenVC)
            }
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
    
    private func setupExistingUserFlow(launchScreenVC: AnimatedLaunchScreenViewController) {
        guard let userProfile = UserProfileStorage.shared.loadUserProfile() else {
            print("❌ Profile exists but corrupted - fallback to onboarding")
            setupOnboardingFormFlow(launchScreenVC: launchScreenVC)
            return
        }
        
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
    }
    
    private func setupWelcomeIntroFlow(launchScreenVC: AnimatedLaunchScreenViewController) {
        let animatedWelcomeVC = AnimatedWelcomeIntroViewController()
        let navigationController = UINavigationController(rootViewController: animatedWelcomeVC)
        navigationController.navigationBar.isHidden = true
        launchScreenVC.setMainViewController(navigationController)
        
        print("📱 First time user - showing animated welcome intro")
    }
    
    private func setupOnboardingFormFlow(launchScreenVC: AnimatedLaunchScreenViewController) {
        let onboardingFormVC = OnboardingFormViewController()
        let navigationController = UINavigationController(rootViewController: onboardingFormVC)
        navigationController.navigationBar.isHidden = true
        launchScreenVC.setMainViewController(navigationController)
        
        print("📱 User needs profile completion - showing onboarding form")
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
    
    // MARK: - Global Appearance Setup
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
        UINavigationBar.appearance().tintColor = CosmicFitTheme.Colors.cosmicLilac
        UITabBar.appearance().backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        UITabBar.appearance().tintColor = CosmicFitTheme.Colors.cosmicLilac
        UITabBar.appearance().unselectedItemTintColor = CosmicFitTheme.Colors.cosmicBlue
    }
    
    // MARK: - App Configuration
    private func configureAppearance() {
        // Configure global appearance settings if needed
        let appearance = UINavigationBar.appearance()
        appearance.isTranslucent = false
        appearance.backgroundColor = .black
        appearance.barTintColor = .black
        appearance.tintColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    // MARK: - Daily Vibe Management
    private func setupDailyVibeManagement() {
        // Clean up old daily vibe entries on app launch
        DailyVibeStorage.shared.cleanupOldEntries(daysToKeep: 30)
        
        // Set up background task for midnight refresh if needed
        setupMidnightRefreshObserver()
        
        // Set up notification observers for daily vibe updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDailyVibeUpdate),
            name: Notification.Name("DailyVibeGenerated"),
            object: nil
        )
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
    
    @objc private func handleDailyVibeUpdate() {
        print("📅 Daily vibe content updated")
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
