//
//  VibeBreakdownBarsView.swift
//  Cosmic Fit
//
//  Created by AI Assistant
//  A reusable component that displays the top 3 vibe breakdown categories as horizontal bars
//

import UIKit

/// A reusable component that displays the top 3 vibe breakdown categories as horizontal bars
final class VibeBreakdownBarsView: UIView {
    
    // MARK: - Properties
    
    private let stackView = UIStackView()
    private var barViews: [VibeBarRow] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Configuration
    
    /// Configure the view with vibe breakdown data
    /// - Parameter vibeBreakdown: The vibe breakdown containing all 6 categories
    func configure(with vibeBreakdown: VibeBreakdown) {
        // Get top 3 categories by score
        let topThree = getTopThreeCategories(from: vibeBreakdown)
        
        // Clear existing bars
        barViews.forEach { $0.removeFromSuperview() }
        barViews.removeAll()
        
        // Create bars for top 3
        for (name, score) in topThree {
            let barRow = VibeBarRow()
            barRow.configure(name: name, score: score, maxScore: 10)
            stackView.addArrangedSubview(barRow)
            barViews.append(barRow)
        }
    }
    
    // MARK: - Private Setup
    
    private func setupUI() {
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Helper Methods
    
    /// Get the top 3 scoring categories from the vibe breakdown
    /// - Parameter vibeBreakdown: The full vibe breakdown with 6 categories
    /// - Returns: Array of (name, score) tuples for the top 3 categories
    private func getTopThreeCategories(from vibeBreakdown: VibeBreakdown) -> [(String, Int)] {
        let allCategories: [(String, Int)] = [
            ("Classic", vibeBreakdown.classic),
            ("Playful", vibeBreakdown.playful),
            ("Romantic", vibeBreakdown.romantic),
            ("Utility", vibeBreakdown.utility),
            ("Drama", vibeBreakdown.drama),
            ("Edge", vibeBreakdown.edge)
        ]
        
        // Sort by score descending and take top 3
        let topThree = allCategories
            .sorted { $0.1 > $1.1 }
            .prefix(3)
        
        return Array(topThree)
    }
}

// MARK: - Vibe Bar Row Component

/// Individual bar row component showing category name and progress bar
private final class VibeBarRow: UIView {
    
    // MARK: - Properties
    
    private let nameLabel = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    
    private var fillWidthConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    /// Configure the bar row with name and score
    /// - Parameters:
    ///   - name: Category name (e.g., "Classic", "Edgy")
    ///   - score: Score value (0-10)
    ///   - maxScore: Maximum possible score (always 10 for vibe breakdown)
    func configure(name: String, score: Int, maxScore: Int) {
        // Set name label text
        nameLabel.text = name
        
        // Calculate fill percentage (score out of maxScore)
        let percentage = CGFloat(score) / CGFloat(maxScore)
        
        // Update fill width constraint
        fillWidthConstraint?.isActive = false
        fillWidthConstraint = fillView.widthAnchor.constraint(
            equalTo: trackView.widthAnchor,
            multiplier: max(0, min(1, percentage)) // Clamp between 0 and 1
        )
        fillWidthConstraint?.isActive = true
        
        // Force layout update
        layoutIfNeeded()
    }
    
    // MARK: - Private Setup
    
    private func setupUI() {
        // Configure name label with serif font
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleBodyLabel(nameLabel, fontSize: 14, weight: .semibold)
        nameLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 14, weight: .semibold)
        nameLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        addSubview(nameLabel)
        
        // Configure track (background bar)
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        trackView.layer.cornerRadius = 6
        trackView.clipsToBounds = true
        addSubview(trackView)
        
        // Configure fill (progress bar)
        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        fillView.layer.cornerRadius = 6
        fillView.clipsToBounds = true
        trackView.addSubview(fillView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Name label on the left
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // Track spans from name label to trailing edge
            trackView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.heightAnchor.constraint(equalToConstant: 12),
            
            // Fill starts at leading edge of track
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            // Width constraint is set dynamically in configure()
            
            // Container height
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}

