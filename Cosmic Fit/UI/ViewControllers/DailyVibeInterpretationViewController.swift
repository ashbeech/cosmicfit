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

    // Header views
    private let headerLabel = UILabel()
    private let dateLabel = UILabel()
    private let weatherInfoLabel = UILabel()
    private let topDividerView = UIView()

    // Style Brief
    private let styleBriefHeaderLabel = UILabel()
    private let styleBriefLabel = UILabel()
    private let middleDividerView = UIView()
    
    // Content section views
    private let textilesHeaderLabel = UILabel()
    private let textilesContentLabel = UILabel()
    
    private let colorsHeaderLabel = UILabel()
    private let colorsContentLabel = UILabel()
    
    private let brightnessHeaderLabel = UILabel()
    private let brightnessSliderView = UIView()
    private let brightnessValueLabel = UILabel()
    
    private let vibrancyHeaderLabel = UILabel()
    private let vibrancySliderView = UIView()
    private let vibrancyValueLabel = UILabel()
    
    private let patternsHeaderLabel = UILabel()
    private let patternsContentLabel = UILabel()
    
    private let shapeHeaderLabel = UILabel()
    private let shapeContentLabel = UILabel()
    
    private let accessoriesHeaderLabel = UILabel()
    private let accessoriesContentLabel = UILabel()
    
    // Bottom section
    private let bottomDividerView = UIView()
    private let takeawayLabel = UILabel()
    private let finalDividerView = UIView()
    
    // Data
    private var vibeContent: DailyVibeContent?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Update UI with content if available
        if let content = vibeContent {
            updateUI(with: content)
        }
    }
    
    // MARK: - Configuration
    func configure(with content: DailyVibeContent) {
        self.vibeContent = content
        
        if isViewLoaded {
            updateUI(with: content)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Daily Cosmic Vibe"
        
        // Setup Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        
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
        
        // Setup Header
        setupHeader()
        
        // Setup Title and Main Paragraph
        setupStyleBrief()
        
        // Setup Content Sections
        //setupContentSections()
        
        // Setup Bottom Section
        //setupBottomSection()
        
        // Add a share button to the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareInterpretation)
        )
    }
    
    private func setupHeader() {
        // Header Label (TODAY'S COSMIC VIBE)
        headerLabel.text = "TODAY'S COSMIC VIBE"
        headerLabel.font = UIFont.systemFont(ofSize: 14, weight: .light)
        headerLabel.textColor = .label
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerLabel)
        
        // Date Label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMMM yyyy"
        dateLabel.text = dateFormatter.string(from: Date())
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        dateLabel.textColor = .label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        // Weather Info Label
        weatherInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        weatherInfoLabel.textColor = .label
        weatherInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(weatherInfoLabel)
        
        // Top Divider
        topDividerView.backgroundColor = .separator
        topDividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topDividerView)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            dateLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            weatherInfoLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            weatherInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            weatherInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            topDividerView.topAnchor.constraint(equalTo: weatherInfoLabel.bottomAnchor, constant: 16),
            topDividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            topDividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            topDividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupStyleBrief() {
        // Style Brief Header
        styleBriefHeaderLabel.text = "Style Brief"
        styleBriefHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        styleBriefHeaderLabel.textColor = .label
        styleBriefHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(styleBriefHeaderLabel)
        
        // Style Brief Label
        styleBriefLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        styleBriefLabel.textColor = .label
        styleBriefLabel.numberOfLines = 0
        styleBriefLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(styleBriefLabel)
        
        // Middle Divider
        middleDividerView.backgroundColor = .separator
        middleDividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(middleDividerView)
        
        NSLayoutConstraint.activate([
            styleBriefHeaderLabel.topAnchor.constraint(equalTo: topDividerView.bottomAnchor, constant: 24),
            styleBriefHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            styleBriefHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            styleBriefLabel.topAnchor.constraint(equalTo: styleBriefHeaderLabel.bottomAnchor, constant: 8),
            styleBriefLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            styleBriefLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            middleDividerView.topAnchor.constraint(equalTo: styleBriefLabel.bottomAnchor, constant: 24),
            middleDividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            middleDividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            middleDividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupContentSections() {
        // Textiles Section
        setupSectionHeader(textilesHeaderLabel, title: "Textiles", topAnchor: middleDividerView.bottomAnchor)
        setupSectionContent(textilesContentLabel, topAnchor: textilesHeaderLabel.bottomAnchor)
        
        // Colors Section
        setupSectionHeader(colorsHeaderLabel, title: "Colors", topAnchor: textilesContentLabel.bottomAnchor)
        setupSectionContent(colorsContentLabel, topAnchor: colorsHeaderLabel.bottomAnchor)
        
        // Brightness Section
        setupSectionHeader(brightnessHeaderLabel, title: "Brightness", topAnchor: colorsContentLabel.bottomAnchor)
        setupBrightnessSlider(topAnchor: brightnessHeaderLabel.bottomAnchor)
        
        // Vibrancy Section
        setupSectionHeader(vibrancyHeaderLabel, title: "Vibrancy", topAnchor: brightnessSliderView.bottomAnchor)
        setupVibrancySlider(topAnchor: vibrancyHeaderLabel.bottomAnchor)
        
        // Patterns Section
        setupSectionHeader(patternsHeaderLabel, title: "Patterns", topAnchor: vibrancySliderView.bottomAnchor)
        setupSectionContent(patternsContentLabel, topAnchor: patternsHeaderLabel.bottomAnchor)
        
        // Shape Section
        setupSectionHeader(shapeHeaderLabel, title: "Shape", topAnchor: patternsContentLabel.bottomAnchor)
        setupSectionContent(shapeContentLabel, topAnchor: shapeHeaderLabel.bottomAnchor)
        
        // Accessories Section
        setupSectionHeader(accessoriesHeaderLabel, title: "Accessories", topAnchor: shapeContentLabel.bottomAnchor)
        setupSectionContent(accessoriesContentLabel, topAnchor: accessoriesHeaderLabel.bottomAnchor)
    }
    
    private func setupSectionHeader(_ label: UILabel, title: String, topAnchor: NSLayoutYAxisAnchor) {
        label.text = title
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }
    
    private func setupSectionContent(_ label: UILabel, topAnchor: NSLayoutYAxisAnchor) {
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }
    
    private func setupBrightnessSlider(topAnchor: NSLayoutYAxisAnchor) {
        // Create slider container view
        brightnessSliderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(brightnessSliderView)
        
        // Add value label
        brightnessValueLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        brightnessValueLabel.textColor = .label
        brightnessValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(brightnessValueLabel)
        
        NSLayoutConstraint.activate([
            brightnessSliderView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            brightnessSliderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            brightnessSliderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            brightnessSliderView.heightAnchor.constraint(equalToConstant: 30),
            
            brightnessValueLabel.topAnchor.constraint(equalTo: brightnessSliderView.bottomAnchor, constant: 4),
            brightnessValueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            brightnessValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }
    
    private func setupVibrancySlider(topAnchor: NSLayoutYAxisAnchor) {
        // Create slider container view
        vibrancySliderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(vibrancySliderView)
        
        // Add value label
        vibrancyValueLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        vibrancyValueLabel.textColor = .label
        vibrancyValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(vibrancyValueLabel)
        
        NSLayoutConstraint.activate([
            vibrancySliderView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            vibrancySliderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            vibrancySliderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            vibrancySliderView.heightAnchor.constraint(equalToConstant: 30),
            
            vibrancyValueLabel.topAnchor.constraint(equalTo: vibrancySliderView.bottomAnchor, constant: 4),
            vibrancyValueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            vibrancyValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }
    
    private func setupBottomSection() {
        // Bottom Divider
        bottomDividerView.backgroundColor = .separator
        bottomDividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomDividerView)
        
        // Takeaway Label
        takeawayLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        takeawayLabel.textColor = .label
        takeawayLabel.numberOfLines = 0
        takeawayLabel.textAlignment = .center
        takeawayLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(takeawayLabel)
        
        // Final Divider
        finalDividerView.backgroundColor = .separator
        finalDividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(finalDividerView)
        
        NSLayoutConstraint.activate([
            bottomDividerView.topAnchor.constraint(equalTo: accessoriesContentLabel.bottomAnchor, constant: 24),
            bottomDividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            bottomDividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            bottomDividerView.heightAnchor.constraint(equalToConstant: 1),
            
            takeawayLabel.topAnchor.constraint(equalTo: bottomDividerView.bottomAnchor, constant: 24),
            takeawayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            takeawayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            finalDividerView.topAnchor.constraint(equalTo: takeawayLabel.bottomAnchor, constant: 24),
            finalDividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            finalDividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            finalDividerView.heightAnchor.constraint(equalToConstant: 1),
            finalDividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func drawBrightnessSlider(value: Int) {
        // Clear previous drawings
        brightnessSliderView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create gradient view
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        brightnessSliderView.addSubview(gradientView)
        
        // Position gradient view
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: brightnessSliderView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: brightnessSliderView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: brightnessSliderView.trailingAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Create gradient layer after layout to ensure correct sizing
        brightnessSliderView.layoutIfNeeded()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.cornerRadius = 4
        gradientLayer.frame = gradientView.bounds
        
        gradientView.layer.cornerRadius = 4
        gradientView.layer.masksToBounds = true
        gradientView.layer.addSublayer(gradientLayer)
        
        // Create indicator triangle
        let triangleView = TriangleView()
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        brightnessSliderView.addSubview(triangleView)
        
        // Calculate position based on gradient view width
        let fullWidth = gradientView.bounds.width
        let position = fullWidth * CGFloat(value) / 100.0
        
        // Position triangle under the gradient at the appropriate position
        NSLayoutConstraint.activate([
            triangleView.topAnchor.constraint(equalTo: gradientView.bottomAnchor),
            triangleView.widthAnchor.constraint(equalToConstant: 10),
            triangleView.heightAnchor.constraint(equalToConstant: 8),
            triangleView.centerXAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: position)
        ])
        
        // Update value label
        brightnessValueLabel.text = "\(value)%"
    }
    
    private func drawVibrancySlider(value: Int) {
        // Clear previous drawings
        vibrancySliderView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create gradient view
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        vibrancySliderView.addSubview(gradientView)
        
        // Position gradient view
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: vibrancySliderView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: vibrancySliderView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: vibrancySliderView.trailingAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Create gradient layer after layout to ensure correct sizing
        vibrancySliderView.layoutIfNeeded()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.gray.cgColor, UIColor.purple.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.cornerRadius = 4
        gradientLayer.frame = gradientView.bounds
        
        gradientView.layer.cornerRadius = 4
        gradientView.layer.masksToBounds = true
        gradientView.layer.addSublayer(gradientLayer)
        
        // Create indicator triangle
        let triangleView = TriangleView()
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        vibrancySliderView.addSubview(triangleView)
        
        // Calculate position based on gradient view width
        let fullWidth = gradientView.bounds.width
        let position = fullWidth * CGFloat(value) / 100.0
        
        // Position triangle under the gradient at the appropriate position
        NSLayoutConstraint.activate([
            triangleView.topAnchor.constraint(equalTo: gradientView.bottomAnchor),
            triangleView.widthAnchor.constraint(equalToConstant: 10),
            triangleView.heightAnchor.constraint(equalToConstant: 8),
            triangleView.centerXAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: position)
        ])
        
        // Update value label
        vibrancyValueLabel.text = "\(value)%"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Redraw sliders after layout to ensure correct positioning
        if let content = vibeContent {
            // Force layout before drawing to ensure views have correct sizes
            view.layoutIfNeeded()
            //drawBrightnessSlider(value: 10 - content.colorScores.darkness) // Brightness is inverse of darkness
            //drawVibrancySlider(value: content.colorScores.vibrancy)
        }
    }
    
    // MARK: - Update UI with Content
    private func updateUI(with content: DailyVibeContent) {
        // Update Style Brief
        //styleBriefLabel.text = content.styleBrief
        
        // Update date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMMM yyyy"
        dateLabel.text = dateFormatter.string(from: Date())
        
        /*
        // Weather
        if let temp = content.temperature,
           let condition = content.weatherCondition {       // <-- ‘condition’ now used!
            
            let symbol: String
            switch condition.lowercased() {
            case "sunny", "clear":                 symbol = "☀️"
            case "partly cloudy", "cloudy":        symbol = "☁️"
            case "rain", "rainy", "showers":       symbol = "🌧"
            case "storm", "thunderstorm":          symbol = "⛈"
            case "snow", "snowy":                  symbol = "❄️"
            case "fog", "mist":                    symbol = "🌫"
            default:                               symbol = "🌤"
            }
            
            weatherInfoLabel.text = "\(symbol) \(Int(temp))°C — \(condition.capitalized)"
        } else {
            weatherInfoLabel.text = ""
        }
         */
        
        /*
        // Populate content sections
        textilesContentLabel.text   = content.textiles
        colorsContentLabel.text     = content.colors
        patternsContentLabel.text   = content.patterns
        shapeContentLabel.text      = content.shape
        accessoriesContentLabel.text = content.accessories
        
        // Take‑away
        takeawayLabel.text = content.styleBrief
         */
        
        // Redraw sliders
        //drawBrightnessSlider(value: 10 - content.colorScores.darkness) // Brightness is inverse of darkness
        //drawVibrancySlider(value: content.colorScores.vibrancy)
    }
    
    // MARK: - Actions
    @objc private func shareInterpretation() {
        // Create an image of the interpretation for sharing
        UIGraphicsBeginImageContextWithOptions(contentView.bounds.size, false, 0.0)
        contentView.drawHierarchy(in: contentView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Items to share
        var itemsToShare: [Any] = []
        /*
        if let content = vibeContent {
            // Create formatted text for sharing
            var shareText = "TODAY'S COSMIC VIBE\n\n"
            shareText += "\(content.styleBrief)\n\n"
            shareText += "---\n\n"
            shareText += "TEXTILES\n\(content.textiles)\n\n"
            shareText += "COLORS\n\(content.colors)\n\n"
            shareText += "PATTERNS\n\(content.patterns)\n\n"
            shareText += "SHAPE\n\(content.shape)\n\n"
            shareText += "ACCESSORIES\n\(content.accessories)\n\n"
            shareText += "---\n\n"
            shareText += "\(content.styleBrief)"
            
            itemsToShare.append(shareText)
        }
         */
        
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

// MARK: - Triangle View for Slider Indicator
class TriangleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.beginPath()
        context.move(to: CGPoint(x: rect.midX, y: 0))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.addLine(to: CGPoint(x: 0, y: rect.maxY))
        context.closePath()
        
        context.setFillColor(UIColor.label.cgColor)
        context.fillPath()
    }
}
