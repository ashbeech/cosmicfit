//
//  StyleUtility.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit

/// Utility struct that provides consistent styling across the app
struct StyleUtility {
    
    // MARK: - Colors
    
    /// Color palette for the app
    struct Colors {
        /// Primary accent color
        static let primary = UIColor.systemBlue
        
        /// Secondary accent color
        static let secondary = UIColor.systemIndigo
        
        /// Main background color
        static let background = UIColor.systemBackground
        
        /// Primary text color
        static let text = UIColor.label
        
        /// Secondary text color
        static let lightText = UIColor.secondaryLabel
        
        /// Border color for UI elements
        static let border = UIColor.systemGray4
        
        /// Success color
        static let success = UIColor.systemGreen
        
        /// Warning color
        static let warning = UIColor.systemOrange
        
        /// Error color
        static let error = UIColor.systemRed
    }
    
    // MARK: - Fonts
    
    /// Font styles for the app
    struct Fonts {
        /// Large title font
        static let largeTitle = UIFont.boldSystemFont(ofSize: 24)
        
        /// Title font
        static let title = UIFont.boldSystemFont(ofSize: 18)
        
        /// Subtitle font
        static let subtitle = UIFont.boldSystemFont(ofSize: 16)
        
        /// Body text font
        static let body = UIFont.systemFont(ofSize: 14)
        
        /// Caption text font
        static let caption = UIFont.systemFont(ofSize: 12)
        
        /// Monospaced font for chart data
        static let monospaced = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    }
    
    // MARK: - Metrics
    
    /// Layout metrics for the app
    struct Metrics {
        /// Standard corner radius
        static let cornerRadius: CGFloat = 8
        
        /// Standard border width
        static let borderWidth: CGFloat = 1
        
        /// Standard content padding
        static let padding: CGFloat = 20
        
        /// Standard spacing between elements
        static let spacing: CGFloat = 10
    }
    
    // MARK: - Styling Methods
    
    /// Apply standard styling to a text field
    /// - Parameter textField: The text field to style
    static func styleTextField(_ textField: UITextField) {
        textField.borderStyle = .roundedRect
        textField.font = Fonts.body
        textField.backgroundColor = Colors.background
        textField.textColor = Colors.text
        textField.layer.borderColor = Colors.border.cgColor
        textField.layer.borderWidth = Metrics.borderWidth
        textField.layer.cornerRadius = Metrics.cornerRadius
    }
    
    /// Apply standard styling to a button
    /// - Parameter button: The button to style
    static func styleButton(_ button: UIButton) {
        button.backgroundColor = Colors.primary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = Metrics.cornerRadius
        button.titleLabel?.font = Fonts.subtitle
    }
    
    /// Apply standard styling to a container view
    /// - Parameter view: The view to style
    static func styleContainerView(_ view: UIView) {
        view.backgroundColor = Colors.background
        view.layer.cornerRadius = Metrics.cornerRadius
        view.layer.borderWidth = Metrics.borderWidth
        view.layer.borderColor = Colors.border.cgColor
    }
    
    /// Apply a shadow effect to a view
    /// - Parameters:
    ///   - view: The view to apply shadow to
    ///   - opacity: Shadow opacity (0.0-1.0)
    ///   - radius: Shadow blur radius
    ///   - offset: Shadow offset
    static func applyShadow(to view: UIView, opacity: Float = 0.2, radius: CGFloat = 3, offset: CGSize = CGSize(width: 0, height: 2)) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = opacity
        view.layer.shadowRadius = radius
        view.layer.shadowOffset = offset
        view.layer.masksToBounds = false
    }
}
