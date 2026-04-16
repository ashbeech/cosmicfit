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
        
        requestLocationPermissionEarly()
        
        // Auth bootstrap: init service, listen, check session async
        _ = CosmicFitAuthService.shared
        CosmicFitAuthService.shared.listenForAuthChanges()
        Task { await CosmicFitAuthService.shared.checkSession() }
        
        // Migrate profile from UserDefaults to Documents-dir JSON
        UserProfileStorage.shared.migrateFromUserDefaultsIfNeeded()
                
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let launchScreenVC = AnimatedLaunchScreenViewController()
        
        if UserProfileStorage.shared.hasCompleteUserProfile() {
            setupExistingUserFlow(launchScreenVC: launchScreenVC)
        } else {
            if UserProfileStorage.shared.hasSeenWelcome() {
                setupOnboardingFormFlow(launchScreenVC: launchScreenVC)
            } else {
                setupWelcomeIntroFlow(launchScreenVC: launchScreenVC)
            }
        }
        
        setupGlobalAppearance()
        
        window?.rootViewController = launchScreenVC
        window?.makeKeyAndVisible()
        
        setupDailyVibeManagement()
        
        lastActiveDate = Date()
        
        return true
    }
    
    // MARK: - Deep Link Handling
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return AuthDeepLinkRouter.shared.handle(url: url)
    }
    
    private func setupExistingUserFlow(launchScreenVC: AnimatedLaunchScreenViewController) {
        guard let userProfile = UserProfileStorage.shared.loadUserProfile() else {
            print("❌ Profile exists but corrupted - fallback to onboarding")
            setupOnboardingFormFlow(launchScreenVC: launchScreenVC)
            return
        }
        
        let tabBarController = CosmicFitTabBarController()
        
        // CRITICAL: Set background to match launch screen
        tabBarController.view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        
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
        
        // Always land on Blueprint (Style Guide, index 1) first.
        // Auth resolves async; tab controller handles deferred swap to Daily Fit.
        tabBarController.selectedIndex = 1
        
        _ = tabBarController.view
        
        launchScreenVC.setMainViewController(tabBarController)
        
        print("✅ Returning user detected — landing on Blueprint tab (auth resolving async)")
    }
    
    private func setupWelcomeIntroFlow(launchScreenVC: AnimatedLaunchScreenViewController) {
        let animatedWelcomeVC = AnimatedWelcomeIntroViewController()
        let navigationController = UINavigationController(rootViewController: animatedWelcomeVC)
        navigationController.navigationBar.isHidden = true
        
        // CRITICAL: Set navigation controller background to match launch screen
        navigationController.view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        
        // CRITICAL: Force view to load immediately to prevent delay
        _ = animatedWelcomeVC.view
        
        launchScreenVC.setMainViewController(navigationController)
        
        print("📱 First time user - showing animated welcome intro")
    }
    
    private func setupOnboardingFormFlow(launchScreenVC: AnimatedLaunchScreenViewController) {
        let onboardingFormVC = OnboardingFormViewController()
        let navigationController = UINavigationController(rootViewController: onboardingFormVC)
        navigationController.navigationBar.isHidden = true
        
        // CRITICAL: Set navigation controller background to match launch screen
        navigationController.view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        
        // CRITICAL: Force view to load immediately to prevent delay
        _ = onboardingFormVC.view
        
        launchScreenVC.setMainViewController(navigationController)
        
        print("📱 User needs profile completion - showing onboarding form")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Check if the date has changed since the app was last active
        checkForDateChange()
        
        // Refresh location when app becomes active to ensure accuracy
        // This ensures location is current for Daily Fit calculations
        refreshLocationIfNeeded()
        
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
            // CRITICAL: Set window background to black to match launch screen
            if let window = window {
                window.backgroundColor = CosmicFitTheme.Colours.cosmicBlue  // BLACK instead of cosmicGrey
            }
        }
        
        // Not sure what these do
        // Configure global UI appearance
        //UINavigationBar.appearance().backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        //UINavigationBar.appearance().tintColor = CosmicFitTheme.Colours.cosmicLilac
        UITabBar.appearance().backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        UITabBar.appearance().tintColor = CosmicFitTheme.Colours.cosmicLilac
        UITabBar.appearance().unselectedItemTintColor = CosmicFitTheme.Colours.cosmicBlue
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
    
    // MARK: - Early Location Request
    /// Request location permission and start location updates as early as possible
    /// This ensures location is available immediately when Daily Fit needs it
    private func requestLocationPermissionEarly() {
        print("📍 Requesting location permission early in app launch...")
        
        // Request location permission immediately
        // This will show the permission prompt as soon as possible
        LocationManager.shared.requestLocation(
            onSuccess: { coordinate in
                print("✅ Early location obtained: \(coordinate.latitude), \(coordinate.longitude)")
                // Location is now available for Daily Fit calculations
            },
            onError: { error in
                print("⚠️ Early location request failed: \(error.localizedDescription)")
                // Location will be requested again when needed, but we tried early
            }
        )
    }
    
    /// Refresh location when app becomes active if we don't have a recent location
    private func refreshLocationIfNeeded() {
        // Only refresh if we don't have a recent location (within 30 minutes)
        guard !LocationManager.shared.hasRecentLocation else {
            print("📍 Location is recent, no refresh needed")
            return
        }
        
        print("📍 Refreshing location on app activation...")
        LocationManager.shared.requestLocation(
            onSuccess: { coordinate in
                print("✅ Location refreshed on app activation: \(coordinate.latitude), \(coordinate.longitude)")
            },
            onError: { error in
                print("⚠️ Location refresh failed: \(error.localizedDescription)")
            }
        )
    }
}
