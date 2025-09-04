//
//  CosmicFitTabBarController.swift
//  Cosmic Fit
//
//  Created for production-ready interface restructuring
//

import UIKit

class CosmicFitTabBarController: UITabBarController {
    
    // MARK: - Properties
    private var chartData: [String: Any] = [:]
    private var birthInfo: String = ""
    private var birthDate: Date?
    private var latitude: Double = 0
    private var longitude: Double = 0
    private var timeZone: TimeZone?
    
    private var natalChart: NatalChartCalculator.NatalChart?
    private var progressedChart: NatalChartCalculator.NatalChart?
    private var dailyVibeContent: DailyVibeContent?
    private var blueprintContent: String?
    
    private var todayWeather: TodayWeather?
    private var chartIdentifier: String?
    
    // Transition properties
    private var isTransitioning = false
    private var transitionContainer: UIView?
    private var transitionAnimator: UIViewPropertyAnimator?
    
    // Swipe gesture properties
    private var leftSwipeGesture: UISwipeGestureRecognizer!
    private var rightSwipeGesture: UISwipeGestureRecognizer!
    
    // User profile property
    private var userProfile: UserProfile?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        startWeatherFetch()
        setupTabMemoryPersistence()
        setupSwipeGestures() // ADD THIS LINE
        setupProfileUpdateNotifications() // ADD THIS LINE
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🧹 CosmicFitTabBarController deallocated")
    }
    
    private func setupTabMemoryPersistence() {
        // Ensure view controllers remain in memory when switching tabs
        delegate = self
    }
    
    // MARK: - Configuration
    func configure(with chartData: [String: Any],
                   birthInfo: String,
                   birthDate: Date,
                   latitude: Double,
                   longitude: Double,
                   timeZone: TimeZone) {
        
        // Load user profile if available
        self.userProfile = UserProfileStorage.shared.loadUserProfile()
        
        self.chartData = chartData
        self.birthInfo = birthInfo
        self.birthDate = birthDate
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
        
        // Generate chart identifier for daily vibe persistence
        self.chartIdentifier = DailyVibeStorage.generateChartIdentifier(
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude
        )
        
        // Calculate natal and progressed charts
        calculateCharts()
        
        // Generate content
        generateContent()
        
        // Setup view controllers with generated content
        setupViewControllers()
    }
    
    private func setupSwipeGestures() {
        // Left swipe (go to next tab)
        leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
        leftSwipeGesture.direction = .left
        view.addGestureRecognizer(leftSwipeGesture)
        
        // Right swipe (go to previous tab)
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
        rightSwipeGesture.direction = .right
        view.addGestureRecognizer(rightSwipeGesture)
        
        print("✅ Swipe gestures configured")
    }
    
    private func setupProfileUpdateNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileUpdate(_:)),
            name: .userProfileUpdated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileDeleted),
            name: .userProfileDeleted,
            object: nil
        )
    }
    
    @objc private func handleLeftSwipe() {
        guard !isTransitioning else { return }
        
        let currentIndex = selectedIndex
        let nextIndex = (currentIndex + 1) % (viewControllers?.count ?? 1)
        
        if nextIndex != currentIndex, let targetVC = viewControllers?[nextIndex] {
            performSmoothSlideTransition(from: currentIndex, to: nextIndex, targetViewController: targetVC)
        }
    }

    @objc private func handleRightSwipe() {
        guard !isTransitioning else { return }
        
        let currentIndex = selectedIndex
        let totalTabs = viewControllers?.count ?? 1
        let prevIndex = (currentIndex - 1 + totalTabs) % totalTabs
        
        if prevIndex != currentIndex, let targetVC = viewControllers?[prevIndex] {
            performSmoothSlideTransition(from: currentIndex, to: prevIndex, targetViewController: targetVC)
        }
    }
    
    @objc private func handleProfileUpdate(_ notification: Notification) {
        guard let updatedProfile = notification.object as? UserProfile else { return }
        
        print("🔄 Profile updated - refreshing app data")
        
        // Update stored profile
        userProfile = updatedProfile
        
        // Update class properties with new profile data
        self.birthDate = updatedProfile.birthDate
        self.latitude = updatedProfile.latitude
        self.longitude = updatedProfile.longitude
        self.timeZone = TimeZone(identifier: updatedProfile.timeZoneIdentifier) ?? TimeZone.current
        
        // Update birthInfo string
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        self.birthInfo = "\(dateFormatter.string(from: updatedProfile.birthDate)) at \(updatedProfile.birthLocation) (Lat: \(String(format: "%.4f", updatedProfile.latitude)), Long: \(String(format: "%.4f", updatedProfile.longitude)))"
        
        // Recalculate charts with new data
        calculateCharts()
        
        // Clear cached content to force regeneration
        blueprintContent = nil
        dailyVibeContent = nil
        
        // Regenerate content
        generateContent()
        
        // Regenerate view controllers with new data
        setupViewControllers()
        
        print("✅ App data refreshed with updated profile")
    }
    
    @objc private func handleProfileDeleted() {
        print("🗑️ Profile deleted - should return to onboarding")
        // The ProfileViewController handles navigation back to onboarding
    }
    
    // MARK: - Private Methods
    private func setupTabBar() {
        // Configure tab bar appearance
        tabBar.backgroundColor = .systemBackground
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
    }
    
    private func calculateCharts() {
        guard let birthDate = birthDate else { return }
        
        // Calculate natal chart
        natalChart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone ?? TimeZone.current
        )
        
        // Calculate progressed chart
        let currentAge = NatalChartCalculator.calculateCurrentAge(from: birthDate)
        progressedChart = NatalChartCalculator.calculateProgressedChart(
            birthDate: birthDate,
            targetAge: currentAge,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone ?? TimeZone.current,
            progressAnglesMethod: .solarArc
        )
    }
    
    private func generateContent() {
        guard let natalChart = natalChart,
              let progChart = progressedChart,
              let chartId = chartIdentifier else {
            print("❌ Missing required data for content generation")
            return
        }
        
        print("🎯 Content Generation Started")
        print("  • Chart ID: \(chartId)")
        print("  • User ID: \(userProfile?.id ?? "None")")
        print("  • Blueprint cached: \(blueprintContent != nil)")
        print("  • Daily Fit cached: \(dailyVibeContent != nil)")
        
        // Generate Blueprint content (only if not already cached)
        if blueprintContent == nil {
            print("🎯 Generating Blueprint content (one-time generation)...")
            let interpretation = CosmicFitInterpretationEngine.generateBlueprintInterpretation(
                from: natalChart
            )
            blueprintContent = interpretation.stitchedParagraph
            print("✅ Blueprint generated (\(interpretation.stitchedParagraph.count) characters)")
        } else {
            print("✅ Blueprint already cached, skipping regeneration")
        }
        
        // Generate Daily Fit content (check user-specific cache first)
        if dailyVibeContent == nil {
            // Check if daily fit already exists for today under user ID
            if let userId = userProfile?.id,
               let existingContent = DailyVibeStorage.shared.loadDailyVibeForUser(userId: userId, for: Date()) {
                self.dailyVibeContent = existingContent
                print("📱 Loaded existing daily fit for user \(userId) today")
            } else {
                // Check legacy storage (for backwards compatibility)
                if let existingContent = DailyVibeStorage.shared.loadDailyVibe(for: Date(), chartIdentifier: chartId) {
                    self.dailyVibeContent = existingContent
                    print("✅ Loaded existing daily vibe for today (legacy storage)")
                } else {
                    print("🎯 Generating new Daily Fit content for today...")
                    
                    // Get transits for daily fit (using existing logic)
                    let transitData = NatalChartManager.shared.calculateTransitChart(natalChart: natalChart)
                    let shortTermTransits = (transitData["groupedAspects"] as? [String: [[String: Any]]])?["Short-term Influences"] ?? []
                    let regularTransits = (transitData["groupedAspects"] as? [String: [[String: Any]]])?["Regular Influences"] ?? []
                    let longTermTransits = (transitData["groupedAspects"] as? [String: [[String: Any]]])?["Long-term Influences"] ?? []
                    let allTransits = [shortTermTransits, regularTransits, longTermTransits].flatMap { $0 }
                    
                    dailyVibeContent = CosmicFitInterpretationEngine.generateDailyVibeInterpretation(
                        from: natalChart,
                        progressedChart: progChart,
                        transits: allTransits,
                        weather: todayWeather
                    )
                    
                    // Save the generated content with user ID if available
                    if let content = dailyVibeContent {
                        if let userId = userProfile?.id {
                            DailyVibeStorage.shared.saveDailyVibeForUser(
                                content,
                                userId: userId,
                                for: Date()
                            )
                            print("✅ Daily Fit generated and saved for user \(userId)")
                        } else {
                            // Fallback to legacy storage
                            DailyVibeStorage.shared.saveDailyVibe(
                                content,
                                for: Date(),
                                chartIdentifier: chartId
                            )
                            print("✅ Daily Fit generated and saved (legacy storage)")
                        }
                    }
                }
            }
        } else {
            print("✅ Daily Fit already cached, skipping regeneration")
        }
        
        print("🎯 Content Generation Complete")
    }
    
    private func extractLocationFromBirthInfo() -> (city: String, country: String) {
        var city = ""
        var country = ""
        
        // Parse the location from birthInfo string
        if let locationRange = birthInfo.range(of: "at ") {
            let locationStartIndex = locationRange.upperBound
            let locationSubstring = birthInfo[locationStartIndex...]
            
            if let coordinatesRange = locationSubstring.range(of: "(") {
                let locationName = String(locationSubstring[..<coordinatesRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Try to split into city and country if there's a comma
                let components = locationName.components(separatedBy: ", ")
                if components.count >= 2 {
                    city = components[0]
                    country = components.dropFirst().joined(separator: ", ")
                } else {
                    city = locationName
                }
                
                // Clean up city name (remove time patterns and "AT" prefix)
                if let timeRange = city.range(of: "\\d{1,2}:\\d{2}", options: .regularExpression) {
                    if let spaceAfterTime = city.range(of: " ", range: timeRange.upperBound..<city.endIndex) {
                        city = String(city[spaceAfterTime.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                if city.uppercased().hasPrefix("AT ") {
                    city = String(city.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return (city: city, country: country)
    }
    
    private func createDebugChartViewController() -> NatalChartViewController? {
        guard let birthDate = birthDate else { return nil }
        
        let debugChartVC = NatalChartViewController()
        debugChartVC.configure(
            with: chartData,
            birthInfo: birthInfo,
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone ?? TimeZone.current
        )
        
        return debugChartVC
    }
    
    private func startWeatherFetch() {
        LocationManager.shared.requestLocation(
            onSuccess: { [weak self] coordinate in
                guard let self = self else { return }
                
                Task {
                    do {
                        let wx = try await WeatherService.shared.fetch(
                            lat: coordinate.latitude,
                            lon: coordinate.longitude
                        )
                        self.todayWeather = wx
                        
                        // Regenerate daily content with weather data if needed
                        if self.dailyVibeContent == nil {
                            self.generateContent()
                            self.setupViewControllers()
                        }
                        
                        print("✅ Weather fetched successfully for tab bar controller")
                    } catch {
                        print("Weather fetch failed: \(error.localizedDescription)")
                        self.useDefaultWeatherLocation()
                    }
                }
            },
            onError: { [weak self] error in
                print("Location error for weather: \(error.localizedDescription)")
                self?.useDefaultWeatherLocation()
            }
        )
    }
    
    private func setupViewControllers() {
        var viewControllers: [UIViewController] = []
        
        // Blueprint Tab (Index 0)
        let blueprintVC = BlueprintViewController()
        if let blueprintContent = blueprintContent,
           let birthDate = birthDate {
            
            // Extract city and country from birthInfo
            let (city, country) = extractLocationFromBirthInfo()
            
            blueprintVC.configure(
                with: blueprintContent,
                birthDate: birthDate,
                birthCity: city,
                birthCountry: country,
                originalChartViewController: createDebugChartViewController()
            )
        }
        
        let blueprintNavController = UINavigationController(rootViewController: blueprintVC)
        blueprintNavController.tabBarItem = UITabBarItem(
            title: "Blueprint",
            image: UIImage(systemName: "star.circle"),
            selectedImage: UIImage(systemName: "star.circle.fill")
        )
        viewControllers.append(blueprintNavController)
        
        // Daily Fit Tab (Index 1)
        let dailyFitVC = DailyFitViewController()
        if let dailyVibeContent = dailyVibeContent {
            dailyFitVC.configure(
                with: dailyVibeContent,
                originalChartViewController: createDebugChartViewController()
            )
        }
        
        let dailyFitNavController = UINavigationController(rootViewController: dailyFitVC)
        dailyFitNavController.tabBarItem = UITabBarItem(
            title: "Daily Fit",
            image: UIImage(systemName: "calendar.circle"),
            selectedImage: UIImage(systemName: "calendar.circle.fill")
        )
        viewControllers.append(dailyFitNavController)
        
        // Profile Tab (Index 2) - NEW
        let profileVC = ProfileViewController()
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
        viewControllers.append(profileNavController)
        
        // Set the view controllers
        self.viewControllers = viewControllers
        
        // Only set default tab if not already set (preserves current selection during updates)
        if selectedIndex == 0 && viewControllers.count > 1 {
            selectedIndex = 1 // Daily Fit as default
        }
    }
    
    private func useDefaultWeatherLocation() {
        Task {
            do {
                // Hornsea, England fallback
                let wx = try await WeatherService.shared.fetch(
                    lat: 53.9108,
                    lon: -0.1667
                )
                todayWeather = wx
                
                // Regenerate daily content with weather data if needed
                if dailyVibeContent == nil {
                    generateContent()
                    setupViewControllers()
                }
            } catch {
                print("Default weather fetch failed:", error.localizedDescription)
            }
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension CosmicFitTabBarController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Prevent tab switching during transition
        guard !isTransitioning else { return false }
        
        // Get the target tab index
        guard let targetIndex = viewControllers?.firstIndex(of: viewController) else { return true }
        let currentIndex = selectedIndex
        
        // Skip animation if selecting the same tab
        guard targetIndex != currentIndex else { return true }
        
        // Perform smooth slide transition using proper container transitions
        performSmoothSlideTransition(from: currentIndex, to: targetIndex, targetViewController: viewController)
        
        // Return false to prevent default tab switching (we'll handle it manually)
        return false
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Log tab selection for debugging
        var tabName = "Unknown"
        if let navController = viewController as? UINavigationController {
            if navController.topViewController is BlueprintViewController {
                tabName = "Blueprint"
            } else if navController.topViewController is DailyFitViewController {
                tabName = "Daily Fit"
            } else if navController.topViewController is ProfileViewController {
                tabName = "Profile"
            }
        }
        
        print("✅ Selected tab: \(tabName)")
        
        // Ensure content is loaded in the selected tab
        if let navController = viewController as? UINavigationController {
            if navController.topViewController is BlueprintViewController {
                // Blueprint tab selected - content should already be loaded
                print("📑 Blueprint tab active")
            } else if navController.topViewController is DailyFitViewController {
                // Daily Fit tab selected - content should already be loaded
                print("🔮 Daily Fit tab active")
            } else if navController.topViewController is ProfileViewController {
                // Profile tab selected - content should already be loaded
                print("👤 Profile tab active")
            }
        }
    }
    
    // MARK: - Smooth Slide Transitions
    
    // In CosmicFitTabBarController.swift, update performSmoothSlideTransition:

    private func performSmoothSlideTransition(from fromIndex: Int, to toIndex: Int, targetViewController: UIViewController) {
        guard let viewControllers = viewControllers,
              fromIndex < viewControllers.count,
              toIndex < viewControllers.count else { return }
        
        isTransitioning = true
        
        let fromVC = viewControllers[fromIndex]
        let toVC = viewControllers[toIndex]
        
        // SIMPLIFIED: Since wraparound is disabled, direction is simply based on index comparison
        let isSlideLeft = toIndex > fromIndex // Moving to higher index = slide left
        
        // Rest of the transition logic remains the same...
        let containerBounds = view.bounds
        let contentFrame = CGRect(x: 0, y: 0, width: containerBounds.width, height: containerBounds.height - tabBar.frame.height)
        
        let transitionContainer = UIView(frame: contentFrame)
        transitionContainer.clipsToBounds = true
        view.insertSubview(transitionContainer, belowSubview: tabBar)
        self.transitionContainer = transitionContainer
        
        let fromSnapshot = fromVC.view.snapshotView(afterScreenUpdates: false) ?? UIView()
        let toSnapshot = toVC.view.snapshotView(afterScreenUpdates: true) ?? UIView()
        
        let originalViewBounds = fromVC.view.bounds
        fromSnapshot.frame = originalViewBounds
        toSnapshot.frame = originalViewBounds
        
        transitionContainer.addSubview(fromSnapshot)
        transitionContainer.addSubview(toSnapshot)
        
        if isSlideLeft {
            toSnapshot.transform = CGAffineTransform(translationX: originalViewBounds.width, y: 0)
        } else {
            toSnapshot.transform = CGAffineTransform(translationX: -originalViewBounds.width, y: 0)
        }
        
        fromVC.view.alpha = 0
        toVC.view.alpha = 0
        
        transitionAnimator = UIViewPropertyAnimator(duration: 0.35, dampingRatio: 0.9) {
            if isSlideLeft {
                fromSnapshot.transform = CGAffineTransform(translationX: -originalViewBounds.width, y: 0)
                toSnapshot.transform = .identity
            } else {
                fromSnapshot.transform = CGAffineTransform(translationX: originalViewBounds.width, y: 0)
                toSnapshot.transform = .identity
            }
        }
        
        transitionAnimator?.addCompletion { [weak self] _ in
            self?.cleanupTransition(targetViewController: targetViewController, toViewController: toVC)
        }
        
        transitionAnimator?.startAnimation()
    }
    
    private func cleanupTransition(targetViewController: UIViewController, toViewController: UIViewController) {
        // Remove transition container
        transitionContainer?.removeFromSuperview()
        transitionContainer = nil
        transitionAnimator = nil
        
        // Restore view alpha
        if let viewControllers = viewControllers {
            for vc in viewControllers {
                vc.view.alpha = 1.0
            }
        }
        
        // Update selected index properly
        selectedIndex = viewControllers?.firstIndex(of: targetViewController) ?? selectedIndex
        
        // REMOVED: No longer calling animateContentFadeIn() for tab transitions
        // The content should maintain its current state when switching tabs
        
        isTransitioning = false
        
        print("✅ Smooth slide transition completed")
    }
}
