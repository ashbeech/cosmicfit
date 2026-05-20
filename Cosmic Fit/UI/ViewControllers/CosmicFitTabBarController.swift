//
//  CosmicFitTabBarController.swift
//  Cosmic Fit
//
//  Created for production-ready interface restructuring
//

import UIKit

final class CosmicFitTabBarController: UITabBarController {

    // MARK: - Properties
    private var chartData: [String: Any] = [:]
    private var birthInfo: String = ""
    private var birthDate: Date?
    private var latitude: Double = 0
    private var longitude: Double = 0
    private var timeZone: TimeZone?
    
    // Menu bar properties
    private var menuBarView: MenuBarView!
    /// Fills the status-bar / notch strip so tab content never shows through above `MenuBarView`.
    private let statusBarBackdropView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        v.isUserInteractionEnabled = false
        return v
    }()
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
        elevateSystemChromeAboveTabContent()
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
        elevateSystemChromeAboveTabContent()
        
        if animated {
            // Start position: below the visible area
            let containerHeight = detailContentContainer.bounds.height
            viewController.view.transform = CGAffineTransform(translationX: 0, y: containerHeight)
            
            UIView.animate(
                withDuration: 0.35 * 0.75,
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
                withDuration: 0.35 * 0.75,
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
        view.insertSubview(statusBarBackdropView, belowSubview: menuBarView)

        NSLayoutConstraint.activate([
            statusBarBackdropView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBackdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBackdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBackdropView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            menuBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10),
            menuBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuBarView.heightAnchor.constraint(equalToConstant: MenuBarView.height),
        ])

        elevateSystemChromeAboveTabContent()
    }

    /// Keeps status strip + menu above transitioning tab content (same grey as `MenuBarView`).
    private func elevateSystemChromeAboveTabContent() {
        guard statusBarBackdropView.superview != nil, menuBarView != nil else { return }
        view.bringSubviewToFront(statusBarBackdropView)
        view.bringSubviewToFront(tabBar)
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDailyFitEngineOverrideChanged),
            name: .dailyFitEngineOverrideChanged,
            object: nil
        )
        #endif
    }

    #if DEBUG
    @objc private func handleDevForceRefresh() {
        print("🔄 [DEV] Force refresh requested — wiping caches and regenerating")

        BlueprintStorage.bumpRemoteBlueprintPullEpoch()
        BlueprintStorage.shared.delete()
        DailyFitFrozenPayloadStorage.shared.removeAll()
        dailyFitPayload = nil

        calculateCharts()
        generateContent()
        BlueprintStorage.bumpRemoteBlueprintPullEpoch()

        setupViewControllers()

        print("✅ [DEV] Force refresh complete")
    }

    @objc private func handleDailyFitEngineOverrideChanged() {
        guard let chartId = chartIdentifier else { return }
        let profileKey = userProfile?.id ?? chartId
        let today = Date()
        let engineId = DailyFitEngineConfig.effectiveEngineId

        print("🔄 [DEV] Daily Fit engine override changed — invalidating today (\(engineId))")

        DailyFitFrozenPayloadStorage.shared.invalidatePurgeCache()
        _ = DailyFitFrozenPayloadStorage.shared.load(date: today, profileKey: profileKey)

        dailyFitPayload = nil
        generateAndCacheDailyVibe(chartId: chartId, forDate: today)
        refreshDailyFitViewControllerIfNeeded()
        updateDailyFitEngineDebugBanner()

        print("✅ [DEV] Daily Fit regenerated under engine \(engineId)")
    }

    private func refreshDailyFitViewControllerIfNeeded() {
        guard let payload = dailyFitPayload,
              let dailyFitVC = viewControllers?.first as? DailyFitViewController else {
            return
        }
        dailyFitVC.configure(
            with: payload,
            originalChartViewController: createDebugChartViewController()
        )
    }

    private func updateDailyFitEngineDebugBanner() {
        guard let items = tabBar.items, !items.isEmpty else { return }
        let item = items[0]
        let engineId = DailyFitEngineConfig.effectiveEngineId

        if engineId != DailyFitEngineRegistry.productionId,
           let descriptor = DailyFitEngineRegistry.descriptor(for: engineId) {
            item.title = "Daily Fit\nEngine: \(descriptor.displayName) (debug)"
            item.badgeValue = nil
        } else {
            item.title = "Daily Fit"
            item.badgeValue = nil
        }
    }
    #endif

    @objc private func handleProfileUpdate(_ notification: Notification) {
        guard let updatedProfile = notification.object as? UserProfile else { return }
        
        print("🔄 Profile updated - refreshing app data")
        
        let priorProfile = self.userProfile
        userProfile = updatedProfile
        
        self.birthDate = updatedProfile.birthDate
        self.latitude = updatedProfile.latitude
        self.longitude = updatedProfile.longitude
        self.timeZone = TimeZone(identifier: updatedProfile.timeZoneIdentifier) ?? TimeZone.current
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        self.birthInfo = "\(dateFormatter.string(from: updatedProfile.birthDate)) at \(updatedProfile.birthLocation) (Lat: \(String(format: "%.4f", updatedProfile.latitude)), Long: \(String(format: "%.4f", updatedProfile.longitude)))"
        
        calculateCharts()

        let birthInputsChanged: Bool = {
            guard let prior = priorProfile else { return true }
            return prior.birthDate != updatedProfile.birthDate
                || prior.latitude != updatedProfile.latitude
                || prior.longitude != updatedProfile.longitude
                || prior.timeZoneIdentifier != updatedProfile.timeZoneIdentifier
                || prior.birthTimeIsUnknown != updatedProfile.birthTimeIsUnknown
        }()

        if birthInputsChanged {
            chartIdentifier = "\(updatedProfile.birthDate.timeIntervalSince1970)_\(updatedProfile.latitude)_\(updatedProfile.longitude)"

            if let tz = self.timeZone {
                chartData = NatalChartManager.shared.calculateNatalChart(
                    date: updatedProfile.birthDate,
                    latitude: updatedProfile.latitude,
                    longitude: updatedProfile.longitude,
                    timeZone: tz
                )
            }

            BlueprintStorage.bumpRemoteBlueprintPullEpoch()
            BlueprintStorage.shared.delete()
            DailyFitFrozenPayloadStorage.shared.removeAll()
            let cal = Calendar.current
            let revealStart = cal.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            let revealEnd = cal.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            DailyFitRevealPersistence.clearRevealFlags(from: revealStart, through: revealEnd)
            dailyFitPayload = nil

            generateAndPersistBlueprint()
            BlueprintStorage.bumpRemoteBlueprintPullEpoch()

            if let chartId = chartIdentifier {
                generateAndCacheDailyVibe(chartId: chartId)
            }
        }

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
            print("🔓 Auth state: authenticated — hydrating blueprint if needed")
            
            if BlueprintStorage.shared.load() == nil {
                Task {
                    await hydrateBlueprint()
                    DispatchQueue.main.async { [weak self] in
                        self?.setupViewControllers()
                    }
                }
            }
            
            setupViewControllers()
        } else {
            print("🔒 Auth state: signed out — refreshing UI (entitlement unchanged)")
            setupViewControllers()
        }

        Task { await EntitlementManager.shared.checkEntitlement() }
    }
    
    /// Attempts to pull Style Guide data (`CosmicBlueprint`) from Supabase and save it locally.
    /// If no remote copy exists, falls back to local generation.
    private func hydrateBlueprint() async {
        let epochAtStart = await MainActor.run { BlueprintStorage.remoteBlueprintPullEpoch }
        do {
            if let remote = try await SupabaseSyncService.shared.pullBlueprintFromSupabase() {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    guard epochAtStart == BlueprintStorage.remoteBlueprintPullEpoch else {
                        print("ℹ️ Style Guide hydration skipped — local blueprint changed during remote fetch")
                        if BlueprintStorage.shared.load() == nil {
                            print("ℹ️ Composing Style Guide locally after superseded remote fetch")
                            self.generateAndPersistBlueprint()
                        }
                        return
                    }
                    BlueprintStorage.shared.save(remote)
                    print("✅ Style Guide hydrated from Supabase")
                }
            } else {
                await MainActor.run { [weak self] in
                    print("ℹ️ No remote Style Guide — generating locally")
                    self?.generateAndPersistBlueprint()
                }
            }
        } catch {
            await MainActor.run { [weak self] in
                print("⚠️ Style Guide pull failed: \(error.localizedDescription) — generating locally")
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
        let revealKey = DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date, engineId: DailyFitEngineConfig.effectiveEngineId)
        let wasRevealed = UserDefaults.standard.bool(forKey: revealKey)

        if wasRevealed,
           let frozen = DailyFitFrozenPayloadStorage.shared.load(date: date, profileKey: profileKey) {
            dailyFitPayload = frozen
            return
        }

        // Stale flag: UserDefaults says "revealed" but the frozen file is missing
        // or failed to decode. Clear the flag so the regenerated payload is treated
        // as a fresh (unrevealed) card, then freeze immediately after generation so
        // the next launch is stable.
        if wasRevealed {
            print("⚠️ Stale reveal flag for \(revealKey) — frozen payload missing. Clearing flag and regenerating.")
            UserDefaults.standard.removeObject(forKey: revealKey)
        }

        guard let natal = natalChart, let progressed = progressedChart else {
            return
        }

        let transits = NatalChartCalculator.calculateTransits(natalChart: natal, date: date)
        let julianDay = JulianDateCalculator.calculateJulianDate(from: date)
        let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)
        let profileHash = userProfile?.id ?? chartId
        let cal = DailyFitEngineConfig.effectiveCalibration
        let engineId = DailyFitEngineConfig.effectiveEngineId

        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: moonPhase,
            profileHash: profileHash,
            date: date,
            calibration: cal,
            dailyFitEngineId: engineId
        )

        if let blueprint = BlueprintStorage.shared.load() {
            let payload = BlueprintLensEngine.generatePayload(
                blueprint: blueprint,
                snapshot: snapshot,
                calibration: cal,
                dailyFitEngineId: engineId
            )
            dailyFitPayload = payload

            #if DEBUG
            BlueprintLensEngine.logDailyFitDiagnostics(
                snapshot: snapshot, payload: payload, blueprint: blueprint,
                calibration: cal
            )
            #endif
        } else {
            print("⚠️ No Style Guide available — Daily Fit cannot be generated")
        }
    }

    /// Generates a payload for a given date without caching it on the tab bar controller.
    private func generateDailyPayload(forDate date: Date) -> DailyFitPayload? {
        let profileKey = userProfile?.id ?? chartIdentifier ?? ""
        let revealKey = DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date, engineId: DailyFitEngineConfig.effectiveEngineId)
        let wasRevealed = UserDefaults.standard.bool(forKey: revealKey)

        if wasRevealed,
           let frozen = DailyFitFrozenPayloadStorage.shared.load(date: date, profileKey: profileKey) {
            return frozen
        }

        if wasRevealed {
            print("⚠️ Stale reveal flag for \(revealKey) — frozen payload missing. Clearing flag and regenerating.")
            UserDefaults.standard.removeObject(forKey: revealKey)
        }

        guard let natal = natalChart, let progressed = progressedChart else { return nil }
        let transits = NatalChartCalculator.calculateTransits(natalChart: natal, date: date)
        let julianDay = JulianDateCalculator.calculateJulianDate(from: date)
        let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)
        let profileHash = userProfile?.id ?? chartIdentifier ?? ""
        let cal = DailyFitEngineConfig.effectiveCalibration
        let engineId = DailyFitEngineConfig.effectiveEngineId

        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: moonPhase,
            profileHash: profileHash,
            date: date,
            calibration: cal,
            dailyFitEngineId: engineId
        )

        guard let blueprint = BlueprintStorage.shared.load() else { return nil }
        return BlueprintLensEngine.generatePayload(
            blueprint: blueprint,
            snapshot: snapshot,
            calibration: cal,
            dailyFitEngineId: engineId
        )
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
        
        // Index 0: Daily Fit — always shown (no auth gate)
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
            #if DEBUG
            self?.updateDailyFitEngineDebugBanner()
            #endif
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
        
        // Get indices for tab taps
        guard let fromIndex = viewControllers?.firstIndex(of: selectedViewController!),
              let toIndex = viewControllers?.firstIndex(of: viewController) else {
            return true
        }

        if fromIndex == toIndex {
            if let dailyFit = dailyFitViewController(from: viewController) {
                dailyFit.handleTabBarDailyFitReselect()
            }
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
        elevateSystemChromeAboveTabContent()
        
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

    private func dailyFitViewController(from root: UIViewController) -> DailyFitViewController? {
        if let vc = root as? DailyFitViewController { return vc }
        if let nav = root as? UINavigationController,
           let vc = nav.topViewController as? DailyFitViewController {
            return vc
        }
        return nil
    }
}

#if DEBUG
extension Notification.Name {
    /// DEBUG: Posted when Profile engine picker changes `DailyFitEngineConfig.runtimeOverrideEngineId`.
    static let dailyFitEngineOverrideChanged = Notification.Name("dailyFitEngineOverrideChanged")
}
#endif
