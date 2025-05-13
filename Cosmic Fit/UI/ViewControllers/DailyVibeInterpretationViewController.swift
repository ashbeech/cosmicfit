//
//  DailyVibeInterpretationViewController.swift
//  Cosmic Fit
//
//  Created for Daily Vibe implementation
//

import UIKit

class DailyVibeInterpretationViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let textView = UITextView()
    private let weatherInfoLabel = UILabel()
    private let moonPhaseLabel = UILabel()
    private let dateLabel = UILabel()
    
    private var interpretationText: String = ""
    private var weather: TodayWeather?
    private var moonPhase: Double = 0.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Set text content
        textView.text = interpretationText
        updateWeatherAndMoonInfo()
    }
    
    // MARK: - Configuration
    func configure(with interpretationText: String,
                  weather: TodayWeather?,
                  moonPhase: Double) {
        self.interpretationText = interpretationText
        self.weather = weather
        self.moonPhase = moonPhase
        
        if isViewLoaded {
            textView.text = interpretationText
            updateWeatherAndMoonInfo()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black // Dark theme for cosmic vibe
        title = "Daily Cosmic Fit"
        
        // Setup Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            // ScrollView fills the entire safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView matches width of scrollView but can expand in height
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Date Label
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = .white
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        // Format today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateLabel.text = dateFormatter.string(from: Date())
        
        // Weather Info Label
        weatherInfoLabel.font = UIFont.systemFont(ofSize: 14)
        weatherInfoLabel.textColor = .lightGray
        weatherInfoLabel.textAlignment = .left
        weatherInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(weatherInfoLabel)
        
        // Moon Phase Label
        moonPhaseLabel.font = UIFont.systemFont(ofSize: 14)
        moonPhaseLabel.textColor = .lightGray
        moonPhaseLabel.textAlignment = .right
        moonPhaseLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(moonPhaseLabel)
        
        // Create a text view for interpretation
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .white
        textView.backgroundColor = .black
        
        // Important: Set these properties to ensure proper scrolling
        textView.isScrollEnabled = false // We want the scrollView to handle scrolling, not the textView
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            // Date label
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Weather info label
            weatherInfoLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            weatherInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            weatherInfoLabel.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -8),
            
            // Moon phase label
            moonPhaseLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            moonPhaseLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),
            moonPhaseLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // TextView fills contentView below labels
            textView.topAnchor.constraint(equalTo: weatherInfoLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        // Add a share button to the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareInterpretation)
        )
    }
    
    private func updateWeatherAndMoonInfo() {
        // Update weather info label
        if let weather = weather {
            weatherInfoLabel.text = "\(weather.conditions), \(Int(weather.temp))°C"
        } else {
            weatherInfoLabel.text = "Weather data unavailable"
        }
        
        // Update moon phase label
        moonPhaseLabel.text = getMoonPhaseDescription(moonPhase)
    }
    
    private func getMoonPhaseDescription(_ phase: Double) -> String {
        if phase < 45.0 {
            return "New Moon"
        } else if phase < 90.0 {
            return "Waxing Crescent"
        } else if phase < 135.0 {
            return "First Quarter"
        } else if phase < 180.0 {
            return "Waxing Gibbous"
        } else if phase < 225.0 {
            return "Full Moon"
        } else if phase < 270.0 {
            return "Waning Gibbous"
        } else if phase < 315.0 {
            return "Last Quarter"
        } else {
            return "Waning Crescent"
        }
    }
    
    // MARK: - Actions
    @objc private func shareInterpretation() {
        // Create an image of the interpretation for sharing
        UIGraphicsBeginImageContextWithOptions(contentView.bounds.size, false, 0.0)
        contentView.drawHierarchy(in: contentView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Items to share
        var itemsToShare: [Any] = [interpretationText]
        if let image = image {
            itemsToShare.append(image)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Present the share sheet
        present(activityViewController, animated: true)
    }
}
