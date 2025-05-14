//
//  NatalChartViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//  Updated with Blueprint specification implementation
//

import UIKit
import CoreLocation

// -----------------------------------------------------------------------
// MARK: - View Controller
// -----------------------------------------------------------------------

@MainActor
final class NatalChartViewController: UIViewController {
    
    // MARK: UI elements --------------------------------------------------
    
    private let scrollView      = UIScrollView()
    private let contentView     = UIView()
    private let birthInfoLabel  = UILabel()
    private let chartWheelView  = ChartWheelView()
    private let tableView       = UITableView(frame: .zero, style: .grouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    /// Single table‑height constraint (updated, never recreated)
    private var tableHeightConstraint: NSLayoutConstraint?
    
    // MARK: Chart & section data -----------------------------------------
    
    private var chartData:               [String: Any] = [:]
    private var progressedChartData:     [String: Any] = [:]
    private var natalChart: NatalChartCalculator.NatalChart?
    private var progressedChart: NatalChartCalculator.NatalChart?
    
    private var planetSections:           [[String: Any]] = []
    private var houseSections:            [[String: Any]] = []
    private var angleSections:            [[String: Any]] = []
    private var progressedPlanetSections:[[String: Any]] = []
    private var progressedAngleSections: [[String: Any]] = []
    
    private var shortTermTransits:        [[String: Any]] = []
    private var regularTransits:          [[String: Any]] = []
    private var longTermTransits:         [[String: Any]] = []
    
    private var todayWeather: TodayWeather?
    
    // MARK: Meta ----------------------------------------------------------
    
    private var transitDate  = ""
    private var currentAge   = 0
    
    private var birthInfo:  String = ""
    private var birthDate:  Date?
    private var latitude:   Double = 0
    private var longitude:  Double = 0
    private var timeZone:   TimeZone?
    
    // Helpers
    private let locManager = LocationManager()
    
    // MARK: Lifecycle -----------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        startWeatherFetch()
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }   // Swift 6 support
    init() { super.init(nibName: nil, bundle: nil) }
    
    // MARK: Public configure() -------------------------------------------
    
    func configure(with chartData: [String: Any],
                   birthInfo: String,
                   birthDate: Date,
                   latitude: Double,
                   longitude: Double,
                   timeZone: TimeZone) {
        
        self.chartData   = chartData
        self.birthInfo   = birthInfo
        self.birthDate   = birthDate
        self.latitude    = latitude
        self.longitude   = longitude
        self.timeZone    = timeZone
        
        currentAge = NatalChartCalculator.calculateCurrentAge(from: birthDate)
        
        // Calculate natal chart
        natalChart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone)
        if let nat = natalChart { chartWheelView.setChart(nat) }
        
        // Calculate progressed chart
        progressedChart = NatalChartCalculator.calculateProgressedChart(
            birthDate: birthDate,
            targetAge: currentAge,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            progressAnglesMethod: .solarArc)
        
        progressedChartData = NatalChartManager.shared.calculateProgressedChart(
            date: birthDate,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone)
        
        if let nat = natalChart {
            let t = NatalChartManager.shared.calculateTransitChart(natalChart: nat)
            shortTermTransits = (t["groupedAspects"] as? [String: [[String: Any]]])?["Short-term Influences"] ?? []
            regularTransits   = (t["groupedAspects"] as? [String: [[String: Any]]])?["Regular Influences"] ?? []
            longTermTransits  = (t["groupedAspects"] as? [String: [[String: Any]]])?["Long-term Influences"] ?? []
            transitDate       = t["date"] as? String ?? ""
        }
        
        assembleSections()
        if isViewLoaded { refreshUI() }
    }
    
    // --------------------------------------------------------------------
    // MARK: Weather
    // --------------------------------------------------------------------
    
    private func useDefaultWeatherLocation() {
        Task {
            do {
                // Hornsea, England fallback
                let wx = try await WeatherService.shared.fetch(
                    lat: 53.9108,
                    lon: -0.1667)
                todayWeather = wx
                refreshUI()
            } catch {
                print("Weather fetch failed:", error.localizedDescription)
            }
        }
    }
    
    private func startWeatherFetch() {
        // fallback timer
        let timeout = DispatchWorkItem { [weak self] in
            print("Location timeout, using default location")
            // NOTE: Should cache long an lat at some point during the app
            self?.useDefaultWeatherLocation()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeout)
        
        locManager.onLocation = { [weak self] coord in
            guard let self else { return }
            timeout.cancel()
            Task {
                do {
                    let wx = try await WeatherService.shared.fetch(
                        lat: coord.latitude,
                        lon: coord.longitude)
                    self.todayWeather = wx
                    self.refreshUI()
                } catch {
                    print("Weather fetch failed:", error.localizedDescription)
                    self.useDefaultWeatherLocation()
                }
            }
        }
        locManager.onError = { [weak self] error in
            print("Location error: \(error.localizedDescription)")
            self?.useDefaultWeatherLocation()
        }
        locManager.requestOnce()
    }
    
    // --------------------------------------------------------------------
    // MARK: UI construction
    // --------------------------------------------------------------------
    
    private func buildUI() {
        view.backgroundColor = .systemBackground
        title = "Natal Chart"
        
        // Set up navigation bar buttons - one for daily vibe, one for blueprint
        // IMPORTANT NOTE: Currently set to DEBUG version. Should remove `WithDebug` for production.
        let dailyVibeButton = UIBarButtonItem(
            title: "Daily Vibe",
            style: .plain,
            target: self,
            action: #selector(showDailyVibeInterpretationWithDebug))
        
        let blueprintButton = UIBarButtonItem(
            title: "Blueprint",
            style: .plain,
            target: self,
            action: #selector(showBlueprintInterpretationWithDebug))
        
        navigationItem.rightBarButtonItems = [dailyVibeButton, blueprintButton]
        
        [scrollView, contentView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(scrollView); scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Birth info
        birthInfoLabel.font = .systemFont(ofSize: 14)
        birthInfoLabel.textColor = .secondaryLabel
        birthInfoLabel.textAlignment = .center
        birthInfoLabel.numberOfLines = 0
        birthInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(birthInfoLabel)
        
        // Wheel
        chartWheelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartWheelView)
        
        // Table
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(ChartDataCell.self, forCellReuseIdentifier: "ChartDataCell")
        contentView.addSubview(tableView)
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemBlue
        view.addSubview(activityIndicator)
        
        // single, reusable height constraint
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            birthInfoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            birthInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            birthInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            chartWheelView.topAnchor.constraint(equalTo: birthInfoLabel.bottomAnchor, constant: 16),
            chartWheelView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            chartWheelView.widthAnchor.constraint(equalToConstant: 300),
            chartWheelView.heightAnchor.constraint(equalToConstant: 300),
            
            tableView.topAnchor.constraint(equalTo: chartWheelView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Activity indicator centered in view
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        refreshUI()   // first pass
    }
    
    // --------------------------------------------------------------------
    // MARK: Data → Section arrays
    // --------------------------------------------------------------------
    
    private func assembleSections() {
        planetSections = chartData["planets"] as? [[String: Any]] ?? []
        
        if let angles = chartData["angles"] as? [String: Any] {
            angleSections = angles.compactMap { k, v in
                var d = v as? [String: Any] ?? [:]; d["name"] = k; return d
            }
        }
        if let houses = chartData["houses"] as? [[String: Any]] {
            houseSections = houses.sorted {
                ($0["number"] as? Int ?? 0) < ($1["number"] as? Int ?? 0)
            }
        }
        
        progressedPlanetSections = progressedChartData["planets"] as? [[String: Any]] ?? []
        if let pAngles = progressedChartData["angles"] as? [String: Any] {
            progressedAngleSections = pAngles.compactMap { k, v in
                var d = v as? [String: Any] ?? [:]; d["name"] = k; return d
            }
        }
    }
    
    // --------------------------------------------------------------------
    // MARK: UI Refresh
    // --------------------------------------------------------------------
    
    private func refreshUI() {
        birthInfoLabel.text = birthInfo
        tableView.reloadData()
        
        tableView.layoutIfNeeded()
        var height: CGFloat = 0
        for s in 0..<tableView.numberOfSections {
            height += tableView.rectForHeader(inSection: s).height
            for r in 0..<tableView.numberOfRows(inSection: s) {
                height += tableView.rectForRow(at: IndexPath(row: r, section: s)).height
            }
            height += tableView.rectForFooter(inSection: s).height
        }
        tableHeightConstraint?.constant = height
    }
    
    // --------------------------------------------------------------------
    // MARK: Actions
    // --------------------------------------------------------------------
    
    @objc private func showDailyVibeInterpretation() {
        guard let natalChart = natalChart, let progChart = progressedChart else {
            showAlert(message: "Chart data is not available. Please try again.")
            return
        }
        
        // Show loading indicator
        activityIndicator.startAnimating()
        
        print("Generating Daily Vibe interpretation")
        
        // Collect transits
        let allTransits = [shortTermTransits, regularTransits, longTermTransits].flatMap { $0 }
        
        // Generate daily vibe content using the NatalChartManager
        let dailyVibeContent = NatalChartManager.shared.generateDailyVibeInterpretation(
            for: natalChart,
            progressedChart: progChart,
            transits: allTransits,
            weather: todayWeather
        )
        
        // Create and push the DailyVibeInterpretationViewController
        let dailyVibeVC = DailyVibeInterpretationViewController()
        dailyVibeVC.configure(with: dailyVibeContent)
        
        // Stop the activity indicator
        self.activityIndicator.stopAnimating()
        
        // Navigate to daily vibe view
        if let navController = self.navigationController {
            print("Pushing Daily Vibe interpretation view controller")
            navController.pushViewController(dailyVibeVC, animated: true)
        } else {
            print("ERROR: No navigation controller available")
            // Fallback: Present modally if navigation controller isn't available
            self.present(dailyVibeVC, animated: true)
        }
    }
    
    /// Override the Blueprint interpretation generation to use the debug version
    @objc func showBlueprintInterpretationWithDebug() {
        guard let natalChart = natalChart else {
            showAlert(message: "Chart data is not available. Please try again.")
            return
        }
        
        // Show loading indicator
        activityIndicator.startAnimating()
        
        print("\n🔍 STARTING DETAILED DEBUG BLUEPRINT GENERATION 🔍")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate the blueprint interpretation with detailed debugging
        let interpretation = CosmicFitInterpretationEngine.generateBlueprintInterpretationWithDebug(
            from: natalChart
        )
        
        print("Generated Blueprint interpretation with \(interpretation.stitchedParagraph.count) characters")
        
        // Extract location information from birthInfo if possible
        var city = ""
        var country = ""
        
        // Parse the location from birthInfo string by extracting only city, country
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
                    // If can't split, just use the whole location name
                    city = locationName
                }
                
                // Check if city contains a time pattern like "04:30" followed by a space
                if let timeRange = city.range(of: "\\d{1,2}:\\d{2}", options: .regularExpression) {
                    // Find the first space after the time
                    if let spaceAfterTime = city.range(of: " ", range: timeRange.upperBound..<city.endIndex) {
                        // Extract everything after the space
                        city = String(city[spaceAfterTime.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                // Remove "AT " prefix if present (case insensitive)
                if city.uppercased().hasPrefix("AT ") {
                    city = String(city.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Create and push the view controller with proper formatting for Blueprint
        let vc = InterpretationViewController()
        vc.configure(
            with: interpretation.stitchedParagraph,
            title: "Your Cosmic Fit Blueprint",
            themeName: interpretation.themeName,
            isBlueprint: true,
            birthDate: birthDate,  // Pass the actual birth date
            birthCity: city,       // Pass the extracted city (without time or "AT" prefix)
            birthCountry: country  // Pass the extracted country
        )
        
        // Stop the activity indicator
        self.activityIndicator.stopAnimating()
        
        // Navigate to interpretation view
        if let navController = self.navigationController {
            print("Pushing Blueprint interpretation view controller")
            navController.pushViewController(vc, animated: true)
        } else {
            print("ERROR: No navigation controller available")
            // Fallback: Present modally if navigation controller isn't available
            self.present(vc, animated: true)
        }
        
        print("✅ DEBUG BLUEPRINT GENERATION COMPLETE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Override the Daily Vibe interpretation generation to use the debug version
    @objc func showDailyVibeInterpretationWithDebug() {
        guard let natalChart = natalChart, let progChart = progressedChart else {
            showAlert(message: "Chart data is not available. Please try again.")
            return
        }
        
        // Show loading indicator
        activityIndicator.startAnimating()
        
        print("\n🔍 STARTING DETAILED DEBUG DAILY VIBE GENERATION 🔍")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Collect transits
        let allTransits = [shortTermTransits, regularTransits, longTermTransits].flatMap { $0 }
        
        // Generate daily vibe content using the debug-enhanced version
        let dailyVibeContent = CosmicFitInterpretationEngine.generateDailyVibeInterpretationWithDebug(
            from: natalChart,
            progressedChart: progChart,
            transits: allTransits,
            weather: todayWeather
        )
        
        // Create and push the DailyVibeInterpretationViewController
        let dailyVibeVC = DailyVibeInterpretationViewController()
        dailyVibeVC.configure(with: dailyVibeContent)
        
        // Stop the activity indicator
        self.activityIndicator.stopAnimating()
        
        // Navigate to daily vibe view
        if let navController = self.navigationController {
            print("Pushing Daily Vibe interpretation view controller")
            navController.pushViewController(dailyVibeVC, animated: true)
        } else {
            print("ERROR: No navigation controller available")
            // Fallback: Present modally if navigation controller isn't available
            self.present(dailyVibeVC, animated: true)
        }
        
        print("✅ DEBUG DAILY VIBE GENERATION COMPLETE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Add debug menu options to the view controller
    func addDebugMenuOptions() {
        // Create a debug options button
        let debugButton = UIBarButtonItem(
            title: "Debug",
            style: .plain,
            target: self,
            action: #selector(showDebugOptions))
        
        // Add to left side of navigation bar
        navigationItem.leftBarButtonItem = debugButton
    }
    
    /// Show debug options menu
    @objc func showDebugOptions() {
        let alert = UIAlertController(
            title: "Debug Options",
            message: "Select a debug option",
            preferredStyle: .actionSheet
        )
        
        // Debug Blueprint option
        alert.addAction(UIAlertAction(
            title: "Debug Blueprint Generation",
            style: .default,
            handler: { [weak self] _ in
                self?.showBlueprintInterpretationWithDebug()
            }
        ))
        
        // Debug Daily Vibe option
        alert.addAction(UIAlertAction(
            title: "Debug Daily Vibe Generation",
            style: .default,
            handler: { [weak self] _ in
                self?.showDailyVibeInterpretationWithDebug()
            }
        ))
        
        // Debug log level options
        alert.addAction(UIAlertAction(
            title: "Set Debug Level",
            style: .default,
            handler: { [weak self] _ in
                self?.showDebugLevelOptions()
            }
        ))
        
        // Cancel option
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))
        
        // Present the alert
        present(alert, animated: true)
    }
    
    /// Show debug level options
    @objc func showDebugLevelOptions() {
        let alert = UIAlertController(
            title: "Debug Log Level",
            message: "Select a debug log level",
            preferredStyle: .actionSheet
        )
        
        // Add options for each debug level
        for level in [
            DebugLogger.LogLevel.verbose,
            DebugLogger.LogLevel.debug,
            DebugLogger.LogLevel.info,
            DebugLogger.LogLevel.warning,
            DebugLogger.LogLevel.error,
            DebugLogger.LogLevel.none
        ] {
            let isCurrentLevel = level == DebugLogger.currentLogLevel
            let checkmark = isCurrentLevel ? " ✓" : ""
            
            alert.addAction(UIAlertAction(
                title: "\(level)" + checkmark,
                style: .default,
                handler: { _ in
                    DebugLogger.currentLogLevel = level
                    print("Debug log level set to: \(level)")
                }
            ))
        }
        
        // Additional options for paragraph assembly logging
        alert.addAction(UIAlertAction(
            title: "Toggle Paragraph Assembly Logging " +
                  (DebugLogger.enableParagraphAssemblyLogging ? "✓" : ""),
            style: .default,
            handler: { _ in
                DebugLogger.enableParagraphAssemblyLogging.toggle()
                print("Paragraph assembly logging: \(DebugLogger.enableParagraphAssemblyLogging ? "Enabled" : "Disabled")")
            }
        ))
        
        // Cancel option
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))
        
        // Present the alert
        present(alert, animated: true)
    }
    
    @objc private func showBlueprintInterpretation() {
        guard let natalChart = natalChart else {
            showAlert(message: "Chart data is not available. Please try again.")
            return
        }
        
        // Show loading indicator
        activityIndicator.startAnimating()
        
        print("Generating Blueprint interpretation")
        
        // Generate the blueprint interpretation (based only on natal chart)
        let interpretation = CosmicFitInterpretationEngine.generateBlueprintInterpretation(
            from: natalChart
        )
        
        print("Generated Blueprint interpretation with \(interpretation.stitchedParagraph.count) characters")
        
        // Extract location information from birthInfo if possible
        var city = ""
        var country = ""
        
        // Parse the location from birthInfo string by extracting only city, country
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
                    // If can't split, just use the whole location name
                    city = locationName
                }
                
                // Check if city contains a time pattern like "04:30" followed by a space
                if let timeRange = city.range(of: "\\d{1,2}:\\d{2}", options: .regularExpression) {
                    // Find the first space after the time
                    if let spaceAfterTime = city.range(of: " ", range: timeRange.upperBound..<city.endIndex) {
                        // Extract everything after the space
                        city = String(city[spaceAfterTime.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                // Remove "AT " prefix if present (case insensitive)
                if city.uppercased().hasPrefix("AT ") {
                    city = String(city.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Create and push the view controller with proper formatting for Blueprint
        let vc = InterpretationViewController()
        vc.configure(
            with: interpretation.stitchedParagraph,
            title: "Your Cosmic Fit Blueprint",
            themeName: interpretation.themeName,
            isBlueprint: true,
            birthDate: birthDate,  // Pass the actual birth date
            birthCity: city,       // Pass the extracted city (without time or "AT" prefix)
            birthCountry: country  // Pass the extracted country
        )
        
        // Stop the activity indicator
        self.activityIndicator.stopAnimating()
        
        // Navigate to interpretation view
        if let navController = self.navigationController {
            print("Pushing Blueprint interpretation view controller")
            navController.pushViewController(vc, animated: true)
        } else {
            print("ERROR: No navigation controller available")
            // Fallback: Present modally if navigation controller isn't available
            self.present(vc, animated: true)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Chart Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}

// ------------------------------------------------------------------------
// MARK: - UITableViewDataSource & UITableViewDelegate
// ------------------------------------------------------------------------

extension NatalChartViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in _: UITableView) -> Int { 9 }   // + Weather
    
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: planetSections.count
        case 1: houseSections.count
        case 2: angleSections.count
        case 3: progressedPlanetSections.count
        case 4: progressedAngleSections.count
        case 5: shortTermTransits.count
        case 6: regularTransits.count
        case 7: longTermTransits.count
        case 8: todayWeather == nil ? 0 : 1
        default: 0
        }
    }
    
    func tableView(_ tv: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "ChartDataCell", for: indexPath) as! ChartDataCell
        
        // Helper
        func configurePlanet(from dict: [String: Any]) {
            let retro   = (dict["isRetrograde"] as? Bool ?? false) ? " ℞" : ""
            let title   = "\(dict["symbol"] ?? "") \(dict["name"] ?? "")\(retro)"
            let house   = (dict["house"] as? Int).map { "House \($0)" } ?? ""
            cell.configure(title: title,
                           detail: dict["formattedPosition"] as? String ?? "",
                           secondary: house)
        }
        
        switch indexPath.section {
        case 0: configurePlanet(from: planetSections[indexPath.row])
        case 1:
            let h = houseSections[indexPath.row]
            cell.configure(title: "House Cusp \(h["number"] ?? "")",
                           detail: h["formattedPosition"] as? String ?? "",
                           secondary: "")
        case 2:
            let a = angleSections[indexPath.row]
            cell.configure(title: a["name"] as? String ?? "",
                           detail: a["formattedPosition"] as? String ?? "",
                           secondary: "")
        case 3: configurePlanet(from: progressedPlanetSections[indexPath.row])
        case 4:
            let a = progressedAngleSections[indexPath.row]
            cell.configure(title: a["name"] as? String ?? "",
                           detail: a["formattedPosition"] as? String ?? "",
                           secondary: "")
        case 5: configureTransitCell(cell, with: shortTermTransits[indexPath.row])
        case 6: configureTransitCell(cell, with: regularTransits[indexPath.row])
        case 7: configureTransitCell(cell, with: longTermTransits[indexPath.row])
        case 8:
            if let wx = todayWeather {
                let title  = "\(wx.conditions) • \(Int(wx.temp)) ℃"
                let detail = "Humidity \(wx.humidity)% • Wind \(Int(wx.windKph)) km/h"
                cell.configure(title: title, detail: detail, secondary: "Today")
            }
        default: break
        }
        return cell
    }
    
    private func configureTransitCell(_ cell: ChartDataCell, with entry: [String: Any]) {
        cell.configure(title: entry["description"] as? String ?? "", detail: "", secondary: "")
        cell.heightAdjustment = 80
    }
    
    func tableView(_ tv: UITableView, titleForHeaderInSection s: Int) -> String? {
        switch s {
        case 0: "Planets"
        case 1: "House Cusps"
        case 2: "Angles"
        case 3: "Progressed Planets (Age \(currentAge))"
        case 4: "Progressed Angles (Age \(currentAge))"
        case 5: "Short‑term Transits (\(transitDate))"
        case 6: "Regular Transits (\(transitDate))"
        case 7: "Long‑term Transits (\(transitDate))"
        case 8: todayWeather == nil ? nil : "Today's Weather"
        default: nil
        }
    }
    
    func tableView(_ tv: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section >= 5 && indexPath.section <= 7 ? 120 : 60
    }
}

// ------------------------------------------------------------------------
// MARK: - ChartDataCell
// ------------------------------------------------------------------------

final class ChartDataCell: UITableViewCell {
    
    private let titleLabel     = UILabel()
    private let detailLabel    = UILabel()
    private let secondaryLabel = UILabel()
    
    var heightAdjustment: CGFloat = 0   // reserved
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func build() {
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        secondaryLabel.font = .systemFont(ofSize: 14)
        secondaryLabel.textColor = .tertiaryLabel
        
        [titleLabel, detailLabel, secondaryLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondaryLabel.leadingAnchor, constant: -8),
            
            secondaryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            secondaryLabel.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
            secondaryLabel.leadingAnchor.constraint(greaterThanOrEqualTo: detailLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(title: String, detail: String, secondary: String) {
        titleLabel.text     = title
        detailLabel.text    = detail
        secondaryLabel.text = secondary
    }
}

/// Swizzle the original viewDidLoad method to add our debug menu
extension UIViewController {
    static let swizzleViewDidLoad: Void = {
        let originalSelector = #selector(UIViewController.viewDidLoad)
        let swizzledSelector = #selector(UIViewController.swizzled_viewDidLoad)
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc func swizzled_viewDidLoad() {
        swizzled_viewDidLoad()
        
        // Add debug menu if this is NatalChartViewController
        if let natalChartVC = self as? NatalChartViewController {
            natalChartVC.addDebugMenuOptions()
        }
    }
}

/// Debug initialization to be called at app launch
class DebugInitializer {
    static func setupDebugEnhancements() {
        // Enable method swizzling to add debug menu
        UIViewController.swizzleViewDidLoad
        
        // Set initial debug log level
        DebugLogger.currentLogLevel = .verbose
        DebugLogger.enableParagraphAssemblyLogging = true
        DebugLogger.enableTokenDebugLogging = true
        
        print("🧩 DEBUG ENHANCEMENTS INITIALIZED 🧩")
        print("Debug log level: \(DebugLogger.currentLogLevel)")
        print("Paragraph assembly logging: \(DebugLogger.enableParagraphAssemblyLogging ? "Enabled" : "Disabled")")
        print("Token debug logging: \(DebugLogger.enableTokenDebugLogging ? "Enabled" : "Disabled")")
    }
}
