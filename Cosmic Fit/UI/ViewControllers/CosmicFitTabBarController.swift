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
    private var dailyFitPayload: DailyFitPayload?
    
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
    
    // Track whether user manually navigated away from the Style Guide tab
    private var userHasManuallyNavigated = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyCosmicFitTheme()
        setupMenuButton()
        setupDetailContentContainer()
        startWeatherFetch()
        setupTabMemoryPersistence()
        setupProfileUpdateNotifications()
        setupAuthStateNotifications()
        installSwipeGesturesIfNeeded()
        setupTabBar()
        hideProfileTabBarItem()
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
        self.chartIdentifier = "\(birthDate.timeIntervalSince1970)_\(latitude)_\(longitude)"
        
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
        // Check if a detail view is already open (child VC or orphaned subview)
        let hasChildDetail = children.contains(where: {
            $0 is StyleGuideDetailViewController || $0 is GenericDetailViewController
        })
        if hasChildDetail || !detailContentContainer.subviews.isEmpty {
            print("⚠️ Detail view already open - dismissing existing before presenting new one")

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
        print("🔍 dismissDetailViewController called with animated: \(animated)")
        
        // Find any detail view controller (not just StyleGuideDetailViewController)
        let detailVC = children.first(where: {
            $0 is StyleGuideDetailViewController || $0 is GenericDetailViewController
        })
        
        print("🔍 Found detail VC: \(detailVC != nil ? String(describing: type(of: detailVC!)) : "nil")")
        print("🔍 Current children count: \(children.count)")
        print("🔍 Current children types: \(children.map { String(describing: type(of: $0)) })")
        
        guard let detailVC = detailVC else {
            // Defensive: clean up orphaned subviews in the container even when
            // no child VC is found (can happen if the VC hierarchy was rebuilt
            // while a detail page was still on screen).
            if !detailContentContainer.subviews.isEmpty {
                print("⚠️ No child detail VC but container has orphaned subviews — cleaning up")
                detailContentContainer.subviews.forEach { $0.removeFromSuperview() }
                detailContentContainer.isHidden = true
                dimmingView?.removeFromSuperview()
                dimmingView = nil
            }
            completion?()
            return
        }
        
        print("🔍 Starting dismissal animation for: \(String(describing: type(of: detailVC)))")
        
        if animated {
            let containerHeight = detailContentContainer.bounds.height
            print("🔍 Container height: \(containerHeight)")
            print("🔍 Detail VC view frame: \(detailVC.view.frame)")
            print("🔍 Detail content container isHidden: \(detailContentContainer.isHidden)")
            print("🔍 Dimming view exists: \(dimmingView != nil)")
            
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    print("🔍 Animation block - applying transform")
                    detailVC.view.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                    self.dimmingView?.alpha = 0
                    print("🔍 Transform applied: \(detailVC.view.transform)")
                },
                completion: { finished in
                    print("🔍 Animation completed with finished: \(finished)")
                    detailVC.view.transform = .identity
                    detailVC.willMove(toParent: nil)
                    detailVC.view.removeFromSuperview()
                    detailVC.removeFromParent()
                    self.detailContentContainer.isHidden = true
                    
                    self.dimmingView?.removeFromSuperview()
                    self.dimmingView = nil
                    
                    print("🔍 Detail VC removed from parent")
                    print("🔍 Detail content container isHidden after removal: \(self.detailContentContainer.isHidden)")
                    completion?()
                }
            )
        } else {
            print("🔍 Non-animated dismissal")
            detailVC.willMove(toParent: nil)
            detailVC.view.removeFromSuperview()
            detailVC.removeFromParent()
            detailContentContainer.isHidden = true
            
            dimmingView?.removeFromSuperview()
            dimmingView = nil
            
            print("🔍 Detail VC removed from parent (non-animated)")
            print("🔍 Detail content container isHidden after removal: \(detailContentContainer.isHidden)")
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
            print("⚠️ Profile already open - ignoring")
            return
        }
        
        print("🔄 Presenting Profile as detail view")
        
        let profileVC = ProfileViewController()
        let detailVC = GenericDetailViewController(contentViewController: profileVC)
        presentDetailViewController(detailVC, animated: true)
    }

    func showFAQPage() {
        print("🔄 Presenting FAQ as detail view")
        
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
        print("🔍 Setting up profile update notifications...")
        
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
        
        // Add this observer with debugging
        print("🔍 Adding dismiss observer...")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileDismissRequest),
            name: .dismissProfileRequested,
            object: nil
        )
        print("🔍 Dismiss observer added successfully")

        #if DEBUG
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDevForceRefresh),
            name: .devForceRefreshRequested,
            object: nil
        )
        #endif
    }

    #if DEBUG
    @objc private func handleDevForceRefresh() {
        print("🔄 [DEV] Force refresh requested — wiping caches and regenerating")

        BlueprintStorage.shared.delete()
        DailyFitFrozenPayloadStorage.shared.removeAll()
        dailyFitPayload = nil

        calculateCharts()
        generateContent()

        setupViewControllers()

        print("✅ [DEV] Force refresh complete")
    }
    #endif

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
        
        // Delete existing Style Guide data so the engine regenerates from the updated chart
        BlueprintStorage.shared.delete()
        DailyFitFrozenPayloadStorage.shared.removeAll()
        dailyFitPayload = nil
        
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
    
    @objc private func handleProfileDismissRequest() {
        dismissDetailViewController(animated: true)
    }
    
    // MARK: - Auth State
    
    private func setupAuthStateNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateChanged(_:)),
            name: .cosmicFitAuthStateChanged,
            object: nil
        )
    }
    
    @objc private func handleAuthStateChanged(_ notification: Notification) {
        let isAuthenticated = notification.userInfo?["isAuthenticated"] as? Bool ?? false
        
        if isAuthenticated {
            print("🔓 Auth state: authenticated — swapping auth gate for Daily Fit")
            
            // Hydrate: if no local Style Guide, try pulling from Supabase (new device / reinstall)
            if BlueprintStorage.shared.load() == nil {
                Task {
                    await hydrateBlueprint()
                    DispatchQueue.main.async { [weak self] in
                        self?.setupViewControllers()
                    }
                }
            }
            
            setupViewControllers()
            
            // Deferred tab swap: if user hasn't manually navigated away from Style Guide, switch to Daily Fit
            if !userHasManuallyNavigated && selectedIndex == 1 {
                selectedIndex = 0
                updateTabSelectionIndicator()
            }
        } else {
            print("🔒 Auth state: signed out — swapping Daily Fit for auth gate")
            setupViewControllers()
            selectedIndex = 1
            updateTabSelectionIndicator()
        }
    }
    
    /// Attempts to pull Style Guide data (`CosmicBlueprint`) from Supabase and save it locally.
    /// If no remote copy exists, falls back to local generation.
    private func hydrateBlueprint() async {
        do {
            if let remote = try await SupabaseSyncService.shared.pullBlueprintFromSupabase() {
                BlueprintStorage.shared.save(remote)
                print("✅ Style Guide hydrated from Supabase")
            } else {
                print("ℹ️ No remote Style Guide — generating locally")
                DispatchQueue.main.async { [weak self] in
                    self?.generateAndPersistBlueprint()
                }
            }
        } catch {
            print("⚠️ Style Guide pull failed: \(error.localizedDescription) — generating locally")
            DispatchQueue.main.async { [weak self] in
                self?.generateAndPersistBlueprint()
            }
        }
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
        guard natalChart != nil,
              progressedChart != nil,
              let chartId = chartIdentifier else {
            print("❌ Missing required data for content generation")
            return
        }
        
        print("🎯 Content Generation Started")
        print("  • Chart ID: \(chartId)")
        print("  • User ID: \(userProfile?.id ?? "None")")
        print("  • Style Guide persisted: \(BlueprintStorage.shared.load() != nil)")
        
        // Style Guide generation (one-per-life: only compose when no local CosmicBlueprint exists)
        if BlueprintStorage.shared.load() == nil {
            generateAndPersistBlueprint()
        } else {
            print("✅ Style Guide already persisted, skipping generation")
        }
        
        // Daily Fit content via new 2-stage pipeline
        if dailyFitPayload == nil {
            generateAndCacheDailyVibe(chartId: chartId)
        } else {
            print("✅ Daily Fit payload already cached, skipping regeneration")
        }
        
        print("🎯 Content Generation Complete")
    }
    
    /// Runs the full Style Guide pipeline: chart → tokens → resolve → narratives → CosmicBlueprint.
    /// Persists locally and pushes to Supabase if authenticated.
    private func generateAndPersistBlueprint() {
        guard let chart = natalChart, let birthDate = birthDate else {
            print("❌ Cannot generate Style Guide — missing natal chart or birth date")
            return
        }
        
        guard let dataset = BlueprintTokenGenerator.loadDataset() else {
            print("❌ Cannot generate Style Guide — bundle resource astrological_style_dataset.json missing (symlink data/style_guide/?)")
            return
        }
        
        let narrativeCache = NarrativeCacheLoader.shared
        if !narrativeCache.isLoaded {
            if !narrativeCache.loadFromBundle() {
                print("⚠️ Narrative cache not loaded — Style Guide will have empty narrative sections")
            }
        }
        
        let birthLocation = userProfile?.birthLocation ?? birthInfo
        
        let blueprint = BlueprintComposer.compose(
            chart: chart,
            birthDate: birthDate,
            birthLocation: birthLocation,
            dataset: dataset,
            narrativeCache: narrativeCache
        )
        
        BlueprintStorage.shared.save(blueprint)
        print("✅ Style Guide generated and saved (engine v\(blueprint.engineVersion))")
        
        if CosmicFitAuthService.shared.isAuthenticated {
            Task {
                do {
                    try await SupabaseSyncService.shared.syncBlueprintToSupabase(blueprint)
                } catch {
                    print("⚠️ Style Guide Supabase sync failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateAndCacheDailyVibe(chartId: String, forDate date: Date = Date()) {
        let profileKey = userProfile?.id ?? chartId
        if UserDefaults.standard.bool(forKey: DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date)),
           let frozen = DailyFitFrozenPayloadStorage.shared.load(date: date, profileKey: profileKey) {
            dailyFitPayload = frozen
            return
        }

        guard let natal = natalChart, let progressed = progressedChart else {
            return
        }

        let transits = NatalChartCalculator.calculateTransits(natalChart: natal)
        let julianDay = JulianDateCalculator.calculateJulianDate(from: date)
        let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)
        let profileHash = userProfile?.id ?? chartId

        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: moonPhase,
            profileHash: profileHash,
            date: date
        )

        if let blueprint = BlueprintStorage.shared.load() {
            let payload = BlueprintLensEngine.generatePayload(
                blueprint: blueprint,
                snapshot: snapshot
            )
            dailyFitPayload = payload

            #if DEBUG
            BlueprintLensEngine.logDailyFitDiagnostics(
                snapshot: snapshot, payload: payload, blueprint: blueprint
            )
            #endif
        } else {
            print("⚠️ No Style Guide available — Daily Fit cannot be generated")
        }
    }

    /// Generates a payload for a given date without caching it on the tab bar controller.
    private func generateDailyPayload(forDate date: Date) -> DailyFitPayload? {
        let profileKey = userProfile?.id ?? chartIdentifier ?? ""
        if UserDefaults.standard.bool(forKey: DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date)),
           let frozen = DailyFitFrozenPayloadStorage.shared.load(date: date, profileKey: profileKey) {
            return frozen
        }

        guard let natal = natalChart, let progressed = progressedChart else { return nil }
        let transits = NatalChartCalculator.calculateTransits(natalChart: natal)
        let julianDay = JulianDateCalculator.calculateJulianDate(from: date)
        let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)
        let profileHash = userProfile?.id ?? chartIdentifier ?? ""

        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: moonPhase,
            profileHash: profileHash,
            date: date
        )

        guard let blueprint = BlueprintStorage.shared.load() else { return nil }
        return BlueprintLensEngine.generatePayload(blueprint: blueprint, snapshot: snapshot)
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
                        if self.dailyFitPayload == nil {
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
        let currentSelectedIndex = selectedIndex
        
        var viewControllers: [UIViewController] = []
        
        // Index 0: Daily Fit (authenticated) or Auth Gate (unauthenticated)
        if CosmicFitAuthService.shared.isAuthenticated {
            let dailyFitVC = DailyFitViewController()
            if let payload = dailyFitPayload {
                dailyFitVC.configure(
                    with: payload,
                    originalChartViewController: createDebugChartViewController()
                )
            }

            dailyFitVC.persistenceProfileKey = userProfile?.id ?? chartIdentifier
            dailyFitVC.payloadGenerator = { [weak self] date -> DailyFitPayload? in
                return self?.generateDailyPayload(forDate: date)
            }
            dailyFitVC.tabBarItem = UITabBarItem(
                title: "Daily Fit",
                image: nil,
                selectedImage: nil
            )
            viewControllers.append(dailyFitVC)
        } else {
            let authGateVC = AuthGateViewController()
            let authNav = UINavigationController(rootViewController: authGateVC)
            authNav.navigationBar.isHidden = true
            authNav.tabBarItem = UITabBarItem(
                title: "Daily Fit",
                image: nil,
                selectedImage: nil
            )
            viewControllers.append(authNav)
        }

        // Index 1: Style Guide
        let styleGuideVC = StyleGuideViewController()
        let (city, country) = extractLocationFromBirthInfo()
        styleGuideVC.configure(
            with: "",
            birthDate: birthDate,
            birthCity: city,
            birthCountry: country,
            originalChartViewController: createDebugChartViewController()
        )

        styleGuideVC.tabBarItem = UITabBarItem(
            title: "Style Guide",
            image: nil,
            selectedImage: nil
        )
        viewControllers.append(styleGuideVC)
        
        self.viewControllers = viewControllers
        
        if currentSelectedIndex < viewControllers.count {
            selectedIndex = currentSelectedIndex
        } else {
            selectedIndex = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateTabSelectionIndicator()
        }
        
        print("✅ View controllers setup — auth: \(CosmicFitAuthService.shared.isAuthenticated), selection: \(selectedIndex)")
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
                if dailyFitPayload == nil {
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
        isCustomTransitioning = false
        userHasManuallyNavigated = true
        
        updateTabSelectionIndicator()
        view.bringSubviewToFront(menuBarView)
        
        var tabName = "Unknown"
        if viewController is StyleGuideViewController {
            tabName = "Style Guide"
        } else if viewController is DailyFitViewController {
            tabName = "Daily Fit"
        } else if viewController is ProfileViewController {
            tabName = "Profile"
        } else if let nav = viewController as? UINavigationController,
                  nav.viewControllers.first is AuthGateViewController {
            tabName = "Auth Gate"
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
