//
//  CosmicFitTabBarController.swift
//  Cosmic Fit
//
//  Created for production-ready interface restructuring
//

import UIKit

final class CosmicFitTabBarController: UITabBarController, UIGestureRecognizerDelegate {

    // MARK: - Properties
    private var chartData: [String: Any] = [:]
    private var birthInfo: String = ""
    private var birthDate: Date?
    private var latitude: Double = 0
    private var longitude: Double = 0
    private var timeZone: TimeZone?
    
    // Menu bar properties
    private var menuBarView: MenuBarView!
    private var menuViewController: MenuViewController?
    private var detailContentContainer: UIView!
    private var dimmingView: UIView?
    
    private var natalChart: NatalChartCalculator.NatalChart?
    private var progressedChart: NatalChartCalculator.NatalChart?
    private var dailyVibeContent: DailyVibeContent?
    private var blueprintContent: String?
    
    private var todayWeather: TodayWeather?
    private var chartIdentifier: String?
    
    // Transition properties
    private var transitionAnimator: SlideTabTransitionAnimator?
    private var isCustomTransitioning = false
    
    // User profile property
    private var userProfile: UserProfile?
    
    private lazy var swipeLeft: UISwipeGestureRecognizer = {
        let g = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        g.direction = .left
        g.delegate = self
        g.cancelsTouchesInView = false      // ← do not steal touches
        g.delaysTouchesBegan = false
        return g
    }()

    private lazy var swipeRight: UISwipeGestureRecognizer = {
        let g = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        g.direction = .right
        g.delegate = self
        g.cancelsTouchesInView = false      // ← do not steal touches
        g.delaysTouchesBegan = false
        return g
    }()

    private func installSwipeGesturesIfNeeded() {
        // Attach to the TAB BAR CONTROLLER’S VIEW (not the tab bar, not child VCs)
        if !(view.gestureRecognizers?.contains(swipeLeft) ?? false) { view.addGestureRecognizer(swipeLeft) }
        if !(view.gestureRecognizers?.contains(swipeRight) ?? false) { view.addGestureRecognizer(swipeRight) }
    }
    
    private func resetTransitionState() {
        isCustomTransitioning = false
        print("🔄 Transition state reset")
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        print("🏃‍♂️ Swipe gesture fired - direction: \(gesture.direction.rawValue)")
        print("🏃‍♂️ Current state - selectedIndex: \(selectedIndex), isCustomTransitioning: \(isCustomTransitioning)")
        
        guard !isCustomTransitioning, presentedViewController == nil else {
            print("❌ Swipe blocked - isCustomTransitioning: \(isCustomTransitioning), presentedViewController: \(presentedViewController != nil)")
            return
        }
        guard let vcs = viewControllers, !vcs.isEmpty else {
            print("❌ Swipe blocked - no view controllers")
            return
        }

        let next: Int = {
            switch gesture.direction {
            case .left:  return min(selectedIndex + 1, vcs.count - 1)
            case .right: return max(selectedIndex - 1, 0)
            default:     return selectedIndex
            }
        }()
        
        print("🏃‍♂️ Calculated next index: \(next) from current: \(selectedIndex)")
        guard next != selectedIndex else {
            print("❌ Swipe blocked - already at target index")
            return
        }

        print("✅ Swipe proceeding - setting isCustomTransitioning = true")
        isCustomTransitioning = true
        
        // Create the animator with the correct direction based on index change
        let direction: SlideTabTransitionAnimator.SlideDirection = next > selectedIndex ? .left : .right
        transitionAnimator = SlideTabTransitionAnimator(isPresenting: true, direction: direction)
        print("🎬 Starting transition via swipe with direction \(direction)")
        
        selectedIndex = next
        
        // Safety timeout - reset flag after 1 second if transition doesn't complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.isCustomTransitioning == true {
                print("⚠️ Transition timeout - forcing reset")
                self?.resetTransitionState()
            }
        }
    }

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // If the touch begins on the tab bar (or any control), let the tab bar handle it.
        if touch.view is UIControl { return false }
        let p = touch.location(in: view)
        if tabBar.frame.contains(p) { return false }   // ← critical line
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don’t block scroll views inside child controllers.
        return true
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply Cosmic Fit theme to the main view controller
        applyCosmicFitTheme()
        setupMenuButton()  // MUST come first - creates menuBarView
        setupDetailContentContainer()  // NOW can reference menuBarView
        startWeatherFetch()
        setupTabMemoryPersistence()
        setupProfileUpdateNotifications()
        installSwipeGesturesIfNeeded()
        setupTabBar()
        hideProfileTabBarItem()  // Add this line
        delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Apply tab selection indicator after layout is complete
        updateTabSelectionIndicator()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Add dividers after layout is complete
        CosmicFitTheme.addTabDividers(tabBar)
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
    
    private func setupDetailContentContainer() {
        detailContentContainer = UIView()
        detailContentContainer.translatesAutoresizingMaskIntoConstraints = false
        detailContentContainer.backgroundColor = .clear
        detailContentContainer.isHidden = true
        detailContentContainer.isUserInteractionEnabled = true
        
        view.addSubview(detailContentContainer)
        
        NSLayoutConstraint.activate([
            // Start 10px below the menu bar
            detailContentContainer.topAnchor.constraint(equalTo: menuBarView.bottomAnchor, constant: 10),
            detailContentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailContentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailContentContainer.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
    }
    
    func presentDetailViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        // Check if a detail view is already open
        if let existingDetailVC = children.first(where: { 
            $0 is BlueprintDetailViewController || $0 is GenericDetailViewController 
        }) {
            print("⚠️ Detail view already open - dismissing existing before presenting new one")
            
            // Dismiss existing, then present new one
            dismissDetailViewController(animated: false) { [weak self] in
                self?.presentDetailViewController(viewController, animated: animated, completion: completion)
            }
            return
        }
        
        // Create and add dimming view - positioned to not cover menu bar area
        let dimming = UIView()
        dimming.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimming.alpha = 0
        dimming.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to the main view, not the selected VC view
        view.insertSubview(dimming, belowSubview: detailContentContainer)
        NSLayoutConstraint.activate([
            // Extend right up to the bottom of menu bar (no gap)
            dimming.topAnchor.constraint(equalTo: menuBarView.bottomAnchor),
            dimming.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimming.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimming.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
        self.dimmingView = dimming
        
        // Add detail VC as child
        addChild(viewController)
        viewController.view.frame = detailContentContainer.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        detailContentContainer.addSubview(viewController.view)
        detailContentContainer.isHidden = false
        viewController.didMove(toParent: self)
        
        // Ensure proper z-ordering
        view.bringSubviewToFront(dimmingView!)
        view.bringSubviewToFront(detailContentContainer)
        view.bringSubviewToFront(tabBar)
        view.bringSubviewToFront(menuBarView)
        
        if animated {
            // Start position: below the visible area
            let containerHeight = detailContentContainer.bounds.height
            viewController.view.transform = CGAffineTransform(translationX: 0, y: containerHeight)
            
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    viewController.view.transform = .identity
                    dimming.alpha = 1.0
                },
                completion: { _ in
                    completion?()
                }
            )
        } else {
            dimming.alpha = 1.0
            completion?()
        }
    }

    func dismissDetailViewController(animated: Bool, completion: (() -> Void)? = nil) {
        let detailVC = children.first(where: {
            $0 is BlueprintDetailViewController || $0 is GenericDetailViewController
        })
        
        guard let detailVC = detailVC else {
            completion?()
            return
        }
        
        if animated {
            let containerHeight = detailContentContainer.bounds.height
            
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    detailVC.view.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                    self.dimmingView?.alpha = 0
                },
                completion: { _ in
                    detailVC.view.transform = .identity
                    detailVC.willMove(toParent: nil)
                    detailVC.view.removeFromSuperview()
                    detailVC.removeFromParent()
                    self.detailContentContainer.isHidden = true
                    
                    self.dimmingView?.removeFromSuperview()
                    self.dimmingView = nil
                    
                    completion?()
                }
            )
        } else {
            detailVC.willMove(toParent: nil)
            detailVC.view.removeFromSuperview()
            detailVC.removeFromParent()
            detailContentContainer.isHidden = true
            
            dimmingView?.removeFromSuperview()
            dimmingView = nil
            
            completion?()
        }
    }
    
    // MARK: - Menu Bar Setup
    private func setupMenuButton() {
        menuBarView = MenuBarView()
        menuBarView.translatesAutoresizingMaskIntoConstraints = false
        
        menuBarView.onMenuTapped = { [weak self] in
            self?.menuButtonTapped()
        }
        
        view.addSubview(menuBarView)
        
        NSLayoutConstraint.activate([
            menuBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10),
            menuBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuBarView.heightAnchor.constraint(equalToConstant: MenuBarView.height),
        ])
        
        // Ensure menu bar stays on top
        view.bringSubviewToFront(menuBarView)
    }

    private func updateMenuBarVisibility() {
        // Menu bar always visible on main pages
        menuBarView.alpha = 1
        menuBarView.isUserInteractionEnabled = true
    }

    @objc private func menuButtonTapped() {
        if menuViewController != nil {
            dismissMenu()
        } else {
            showMenu()
        }
    }

    // MARK: - Menu
    private func showMenu() {
        let menu = MenuViewController()
        menu.modalPresentationStyle = .overFullScreen
        menu.modalTransitionStyle = .crossDissolve
        
        menu.onDismiss = { [weak self] in
            self?.menuBarView.animateMenuButton(toX: false)
            self?.menuViewController = nil
        }
        
        // Handle navigation to profile
        menu.onNavigateToProfile = { [weak self] in
            self?.navigateToProfile()
        }
        
        // Handle navigation to FAQ
        menu.onNavigateToFAQ = { [weak self] in
            self?.showFAQPage()
        }
        
        menuViewController = menu
        
        present(menu, animated: false) {
            menu.show(animated: true)
            self.menuBarView.animateMenuButton(toX: true)
        }
    }
    
    // MARK: - Profile Navigation
    private func navigateToProfile() {
        // Check if profile is already open
        if let existingDetail = children.first(where: { $0 is GenericDetailViewController }),
           let genericDetail = existingDetail as? GenericDetailViewController,
           genericDetail.contentViewController is ProfileViewController {
            return
        }
        
        let profileVC = ProfileViewController()
        let detailVC = GenericDetailViewController(contentViewController: profileVC)
        presentDetailViewController(detailVC, animated: true)
    }

    func showFAQPage() {
        let faqVC = FAQViewController()
        let detailVC = GenericDetailViewController(contentViewController: faqVC)
        presentDetailViewController(detailVC, animated: true)
    }
    
    private func dismissMenu() {
        guard let menu = menuViewController else { return }
        
        menuBarView.animateMenuButton(toX: false)
        menu.hide(animated: true) { [weak self] in
            menu.dismiss(animated: false)
            self?.menuViewController = nil
        }
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileDismissRequest),
            name: .dismissProfileRequested,
            object: nil
        )
    }
    
    @objc private func handleProfileUpdate(_ notification: Notification) {
        guard let updatedProfile = notification.object as? UserProfile else { return }
        
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
    }
    
    @objc private func handleProfileDeleted() {
        // The ProfileViewController handles navigation back to onboarding
    }
    
    @objc private func handleProfileDismissRequest() {
        dismissDetailViewController(animated: true)
    }
    
    // MARK: - Private Methods
    private func setupTabBar() {
        // Apply Cosmic Fit theme to tab bar (uses black background)
        CosmicFitTheme.styleTabBar(tabBar)
        
        // Additional tab bar configuration
        tabBar.isTranslucent = false
        
        print("✅ Tab bar styled with Cosmic Fit theme")
    }
    
    private func hideProfileTabBarItem() {
        // Hide the profile tab from the visual tab bar
        guard let items = tabBar.items, items.count > 2 else { return }
        
        // Make profile tab invisible in tab bar
        items[2].isEnabled = false
        items[2].title = ""
        
        /*
        // Adjust tab bar to only show first 2 tabs visually
        if let view = tabBar.subviews.first(where: { $0 is UIControl }) {
            // This ensures the tab bar only displays 2 tabs visually
        }
         */
    }
    
    private func updateTabSelectionIndicator() {
        // Apply custom selection indicator from theme
        CosmicFitTheme.applyTabSelectionIndicator(tabBar, selectedIndex: selectedIndex)
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
               let existingContent = DailyVibeStorage.shared.loadDailyVibeForUser(
                userId: userId,
                for: Date()
               ) {
                self.dailyVibeContent = existingContent
                
                // PART 5: Update recency tracking for today's cached card
                if let cachedCard = existingContent.tarotCard {
                    TarotRecencyTracker.shared.storeCardSelection(
                        cachedCard.name,
                        profileHash: userId,
                        date: Date()
                    )
                    print("📱 Loaded existing daily fit for user \(userId) today and updated recency tracking")
                } else {
                    print("📱 Loaded existing daily fit for user \(userId) today")
                }
            } else {
                // Check legacy storage (for backwards compatibility)
                if let existingContent = DailyVibeStorage.shared.loadDailyVibe(
                    for: Date(),
                    chartIdentifier: chartId
                ) {
                    self.dailyVibeContent = existingContent
                    
                    // Update recency tracking if we have a profile
                    if let userId = userProfile?.id, let cachedCard = existingContent.tarotCard {
                        TarotRecencyTracker.shared.storeCardSelection(
                            cachedCard.name,
                            profileHash: userId,
                            date: Date()
                        )
                    }
                    
                    print("✅ Loaded existing daily vibe for today (legacy storage)")
                } else {
                    print("🎯 Generating new Daily Fit content for today...")
                    
                    // P0 FIX: Get typed transits directly (no dictionary conversion!)
                    let allTransits = NatalChartManager.shared.calculateTypedTransits(natalChart: natalChart)
                    
                    // Generate profile hash for daily seed
                    let profileHashForSeed = userProfile?.id ?? chartId
                    
                    dailyVibeContent = CosmicFitInterpretationEngine.generateDailyVibeInterpretation(
                        from: natalChart,
                        progressedChart: progChart,
                        transits: allTransits,
                        weather: todayWeather,
                        profileHash: profileHashForSeed,
                        date: Date()
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
        
        // CRITICAL: Add debug menu options to enable debug functionality
        debugChartVC.addDebugMenuOptions()
        
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
        
        // Daily Fit Tab (Index 0)
        let dailyFitVC = DailyFitViewController()
        if let dailyVibeContent = dailyVibeContent {
            dailyFitVC.configure(
                with: dailyVibeContent,
                originalChartViewController: createDebugChartViewController()
            )
        }

        // Text-only tab item with no image - NO navigation controller wrapper
        dailyFitVC.tabBarItem = UITabBarItem(
            title: "Daily Fit",
            image: nil,
            selectedImage: nil
        )
        viewControllers.append(dailyFitVC)

        // Cosmic Blueprint Tab (Index 1)
        let blueprintVC = BlueprintViewController()
        if let blueprintContent = blueprintContent {
            // Only configure if we have content (prevents empty state)
           
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

        // Text-only tab item with no image - NO navigation controller wrapper
        blueprintVC.tabBarItem = UITabBarItem(
            title: "Cosmic Blueprint",
            image: nil,
            selectedImage: nil
        )
        viewControllers.append(blueprintVC)
        
        // Set the view controllers
        self.viewControllers = viewControllers
        
        // Set Daily Fit as default tab (index 0)
        selectedIndex = 0
        
        // Update tab selection indicator after setting view controllers
        DispatchQueue.main.async { [weak self] in
            self?.updateTabSelectionIndicator()
        }
        
        print("✅ View controllers setup with 2 tabs (Daily Fit and Cosmic Blueprint)")
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
        // CRITICAL: Dismiss any open detail pages before tab switch
        if !detailContentContainer.isHidden {
            dismissDetailViewController(animated: false)
        }
        
        // Don't block selection if already transitioning via gesture
        guard !isCustomTransitioning else {
            print("⚠️ Custom transition in progress - allowing selection")
            return true
        }
        
        // Get indices for tab taps (not swipe gestures)
        guard let fromIndex = viewControllers?.firstIndex(of: selectedViewController!),
              let toIndex = viewControllers?.firstIndex(of: viewController),
              fromIndex != toIndex else {
            print("✅ Same tab selected - allowing")
            return true
        }
        
        print("🖱️ Tab tap detected - from \(fromIndex) to \(toIndex)")
        
        // Determine direction for tab taps
        let direction: SlideTabTransitionAnimator.SlideDirection = toIndex > fromIndex ? .left : .right
        
        // Start custom transition for tab taps
        isCustomTransitioning = true
        transitionAnimator = SlideTabTransitionAnimator(isPresenting: true, direction: direction)
        
        print("🎬 Starting transition via tab tap with direction \(direction)")
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("✅ Tab selection completed - resetting transition flag")
        // ALWAYS reset the flag, regardless of how we got here
        isCustomTransitioning = false
        
        // Update tab selection indicator
        updateTabSelectionIndicator()
        
        // Ensure menu bar stays on top after tab switch
        view.bringSubviewToFront(menuBarView)
        
        // Log the selected tab for debugging
        var tabName = "Unknown"
        if viewController is BlueprintViewController {
            tabName = "Blueprint"
        } else if viewController is DailyFitViewController {
            tabName = "Daily Fit"
        } else if viewController is ProfileViewController {
            tabName = "Profile"
        }
        print("✅ Selected tab: \(tabName)")
    }
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Return the custom animator when we have one
        if let animator = transitionAnimator {
            print("🎨 Using custom transition animator")
            return animator
        }
        
        print("🎨 No custom animator - using default transition")
        return nil
    }
}
