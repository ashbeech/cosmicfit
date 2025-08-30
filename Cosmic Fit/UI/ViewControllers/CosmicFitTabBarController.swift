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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        startWeatherFetch()
        setupTabMemoryPersistence()
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
    
    // MARK: - Private Methods
    private func setupTabBar() {
        // Configure tab bar appearance
        tabBar.backgroundColor = .systemBackground
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        
        // Set title
        title = "Cosmic Fit"
        navigationItem.hidesBackButton = true
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
        print("  • Blueprint cached: \(blueprintContent != nil)")
        print("  • Daily Fit cached: \(dailyVibeContent != nil)")
        
        // Generate Blueprint content (only if not already cached)
        // Note: Blueprint should NEVER regenerate after first creation
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
        
        // Generate Daily Fit content (check cache first)
        if dailyVibeContent == nil {
            if let existingContent = DailyVibeStorage.shared.loadDailyVibe(
                for: Date(),
                chartIdentifier: chartId
            ) {
                print("✅ Loaded existing daily vibe for today")
                dailyVibeContent = existingContent
            } else {
                print("🎯 Generating new Daily Fit content for today...")
                
                // Get transits for daily fit
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
                
                // Save the generated content
                if let content = dailyVibeContent {
                    DailyVibeStorage.shared.saveDailyVibe(
                        content,
                        for: Date(),
                        chartIdentifier: chartId
                    )
                    print("✅ Daily Fit generated and saved")
                }
            }
        } else {
            print("✅ Daily Fit already cached, skipping regeneration")
        }
        
        print("🎯 Content Generation Complete")
    }
    
    private func setupViewControllers() {
        var viewControllers: [UIViewController] = []
        
        // Blueprint Tab
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
        
        // Daily Fit Tab
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
        
        // Set the view controllers
        self.viewControllers = viewControllers
        
        // Select Blueprint tab by default
        selectedIndex = 0
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
        // Allow all tab switches - view controllers remain in memory
        print("🔄 Switching to tab: \(viewController.title ?? "Unknown")")
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Log tab selection for debugging
        print("✅ Selected tab: \(viewController.title ?? "Unknown")")
        
        // Ensure content is loaded in the selected tab
        if let navController = viewController as? UINavigationController {
            if navController.topViewController is BlueprintViewController {
                // Blueprint tab selected - content should already be loaded
                print("📑 Blueprint tab active")
            } else if navController.topViewController is DailyFitViewController {
                // Daily Fit tab selected - content should already be loaded
                print("🔮 Daily Fit tab active")
            }
        }
    }
}
