//
//  DailyColorPaletteView.swift
//  Cosmic Fit
//
//  A reusable component that displays daily color palette with top 3 colors and gradient bar
//

import UIKit

/// Displays the daily color palette with top 3 colors in a specific layout plus a gradient bar
final class DailyColorPaletteView: UIView {
    
    // MARK: - Properties
    
    private let color1View = UIView()
    private let color2View = UIView()
    private let color3View = UIView()
    private let gradientBar = UIView()
    
    private var allColors: [UIColor] = []
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
    /// - Parameter tokens: Array of StyleTokens containing color information
    func configure(with tokens: [StyleToken]) {
        // Get top 3 colors
        let topColors = ColorMapper.getTopColors(from: tokens, count: 3)
        
        // Apply colors to views
        if topColors.count >= 1 {
            color1View.backgroundColor = topColors[0].1
        } else {
            color1View.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        }
        
        if topColors.count >= 2 {
            color2View.backgroundColor = topColors[1].1
        } else {
            color2View.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        }
        
        if topColors.count >= 3 {
            color3View.backgroundColor = topColors[2].1
        } else {
            color3View.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        }
        
        // Get all colors for gradient
        allColors = ColorMapper.getAllColors(from: tokens)
        
        // Create gradient bar
        updateGradientBar()
    }
    
    // MARK: - Private Setup
    
    private func setupUI() {
        // Configure color views with rounded corners
        [color1View, color2View, color3View].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 12
            view.clipsToBounds = true
            view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey // Default
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
            // Color 1: Left column, spans 2 rows (most prominent)
            color1View.leadingAnchor.constraint(equalTo: leadingAnchor),
            color1View.topAnchor.constraint(equalTo: topAnchor),
            color1View.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.48), // Slightly less than half
            color1View.heightAnchor.constraint(equalToConstant: 140),
            
            // Color 2: Right column, top row
            color2View.trailingAnchor.constraint(equalTo: trailingAnchor),
            color2View.topAnchor.constraint(equalTo: topAnchor),
            color2View.leadingAnchor.constraint(equalTo: color1View.trailingAnchor, constant: 8),
            color2View.heightAnchor.constraint(equalToConstant: 66),
            
            // Color 3: Right column, bottom row
            color3View.trailingAnchor.constraint(equalTo: trailingAnchor),
            color3View.topAnchor.constraint(equalTo: color2View.bottomAnchor, constant: 8),
            color3View.leadingAnchor.constraint(equalTo: color1View.trailingAnchor, constant: 8),
            color3View.heightAnchor.constraint(equalToConstant: 66),
            
            // Gradient bar: Below the color grid, spanning full width
            gradientBar.topAnchor.constraint(equalTo: color1View.bottomAnchor, constant: 12),
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
        
        guard !allColors.isEmpty else {
            // Default gradient if no colors
            gradientBar.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
            return
        }
        
        // Create gradient from all colors
        let gradient = CAGradientLayer()
        gradient.colors = allColors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.cornerRadius = 6
        
        // Set frame (will be updated in layoutSubviews)
        gradient.frame = gradientBar.bounds
        
        gradientBar.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient layer frame when view bounds change
        if let gradient = gradientLayer {
            gradient.frame = gradientBar.bounds
        }
    }
}

