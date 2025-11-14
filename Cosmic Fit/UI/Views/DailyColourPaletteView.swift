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
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Configuration
    
    /// Configure the palette with style tokens from the IE
    /// - Parameter tokens: Array of StyleTokens containing colour information
    func configure(with tokens: [StyleToken]) {
        // Filter out any invalid tokens (defensive programming)
        let validTokens = tokens.filter { token in
            // Ensure the token is actually a StyleToken and not NSNull or corrupted
            return type(of: token) == StyleToken.self
        }
        
        guard !validTokens.isEmpty else {
            print("⚠️ DailyColourPaletteView: No valid tokens to display")
            resetToDefaults()
            return
        }
        
        // Get top 3 colours
        let topColours = ColourMapper.getTopColours(from: validTokens, count: 3)
        
        // Apply colours to views
        if topColours.count >= 1 {
            colour1View.backgroundColor = topColours[0].1
        } else {
            colour1View.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        }
        
        if topColours.count >= 2 {
            colour2View.backgroundColor = topColours[1].1
        } else {
            colour2View.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        }
        
        if topColours.count >= 3 {
            colour3View.backgroundColor = topColours[2].1
        } else {
            colour3View.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        }
        
        // Get all colours for gradient
        allColours = ColourMapper.getAllColours(from: validTokens)
        
        // Create gradient bar
        updateGradientBar()
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
        // Remove existing gradient layer
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        
        guard !allColours.isEmpty else {
            // Default gradient if no colours
            gradientBar.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
            return
        }
        
        // Create gradient from all colours
        let gradient = CAGradientLayer()
        gradient.colors = allColours.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.cornerRadius = 6
        
        // Set frame (will be updated in layoutSubviews)
        gradient.frame = gradientBar.bounds
        
        gradientBar.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    private func resetToDefaults() {
        colour1View.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        colour2View.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        colour3View.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        gradientBar.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient layer frame when view bounds change
        if let gradient = gradientLayer {
            gradient.frame = gradientBar.bounds
        }
    }
}
