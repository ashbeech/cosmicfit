//
//  DailyColourPaletteView.swift
//  Cosmic Fit
//
//  A reusable component that displays daily colour palette with top 3 colours and gradient bar
//

import UIKit

/// Displays the daily colour palette with top 3 colours in a specific layout plus a gradient bar
final class DailyColourPaletteView: UIView {
    
    // MARK: - Properties
    
    private let colour1View = UIView()
    private let colour2View = UIView()
    private let colour3View = UIView()
    private let gradientBar = UIView()
    
    private var allColours: [UIColor] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Configuration
    
    /// Configure the palette with style tokens from the IE (legacy path).
    func configure(with tokens: [StyleToken]) {
        let topColours = ColourMapper.getTopColours(from: tokens, count: 3)

        if topColours.count >= 1 { colour1View.backgroundColor = topColours[0].1 }
        if topColours.count >= 2 { colour2View.backgroundColor = topColours[1].1 }
        if topColours.count >= 3 { colour3View.backgroundColor = topColours[2].1 }

        allColours = ColourMapper.getAllColours(from: tokens)
        updateGradientBar()
    }

    /// Configure the palette directly from V4 hex strings (3 daily colours +
    /// full gradient from all 12 palette anchors).
    func configure(dailyHexes: [String], allPaletteHexes: [String]) {
        let dailyUIColors = dailyHexes.compactMap { Self.uiColor(fromHex: $0) }
        if dailyUIColors.count >= 1 { colour1View.backgroundColor = dailyUIColors[0] }
        if dailyUIColors.count >= 2 { colour2View.backgroundColor = dailyUIColors[1] }
        if dailyUIColors.count >= 3 { colour3View.backgroundColor = dailyUIColors[2] }

        allColours = allPaletteHexes.compactMap { Self.uiColor(fromHex: $0) }
        updateGradientBar()
    }

    private static func uiColor(fromHex hex: String) -> UIColor? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else { return nil }
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
    
    // MARK: - Private Setup
    
    private func setupUI() {
        // Configure colour views with rounded corners
        [colour1View, colour2View, colour3View].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 12
            view.clipsToBounds = true
            view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey // Default
            addSubview(view)
        }
        
        // Configure gradient bar
        gradientBar.translatesAutoresizingMaskIntoConstraints = false
        gradientBar.layer.cornerRadius = 6
        gradientBar.clipsToBounds = true
        addSubview(gradientBar)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Colour 1: Left column, spans 2 rows (most prominent)
            colour1View.leadingAnchor.constraint(equalTo: leadingAnchor),
            colour1View.topAnchor.constraint(equalTo: topAnchor),
            colour1View.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.48), // Slightly less than half
            colour1View.heightAnchor.constraint(equalToConstant: 140),
            
            // Colour 2: Right column, top row
            colour2View.trailingAnchor.constraint(equalTo: trailingAnchor),
            colour2View.topAnchor.constraint(equalTo: topAnchor),
            colour2View.leadingAnchor.constraint(equalTo: colour1View.trailingAnchor, constant: 8),
            colour2View.heightAnchor.constraint(equalToConstant: 66),
            
            // Colour 3: Right column, bottom row
            colour3View.trailingAnchor.constraint(equalTo: trailingAnchor),
            colour3View.topAnchor.constraint(equalTo: colour2View.bottomAnchor, constant: 8),
            colour3View.leadingAnchor.constraint(equalTo: colour1View.trailingAnchor, constant: 8),
            colour3View.heightAnchor.constraint(equalToConstant: 66),
            
            // Gradient bar: Below the colour grid, spanning full width
            gradientBar.topAnchor.constraint(equalTo: colour1View.bottomAnchor, constant: 12),
            gradientBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientBar.heightAnchor.constraint(equalToConstant: 12),
            
            // Container height
            bottomAnchor.constraint(equalTo: gradientBar.bottomAnchor)
        ])
    }
    
    private func updateGradientBar() {
        // Remove existing gradient layers
        gradientBar.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        guard !allColours.isEmpty else { return }
        
        // Create gradient from all colours
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = allColours.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.cornerRadius = 6
        
        // Set frame (will be updated in layoutSubviews)
        gradientLayer.frame = gradientBar.bounds
        
        gradientBar.layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient layer frame when view bounds change
        if let gradientLayer = gradientBar.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = gradientBar.bounds
        }
    }
}
