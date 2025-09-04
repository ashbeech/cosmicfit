//
//  CosmicFitTheme.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/09/2025.
//

import UIKit

/// Cosmic Fit Theme Engine
/// Provides centralized theming for all UI elements across the app
struct CosmicFitTheme {
    
    // MARK: - Colors
    struct Colors {
        /// Cosmic Grey - Main background color for content areas (#DEDEDE)
        static let cosmicGrey = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 1.0)
        
        /// Cosmic Blue - Primary text color (#000210)
        static let cosmicBlue = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        /// Cosmic Orange - Highlight/accent color (#FF8502)
        static let cosmicOrange = UIColor(red: 255/255, green: 133/255, blue: 2/255, alpha: 1.0)
        
        /// Tab bar active background (darker version of cosmicGrey for selection indicator)
        static let tabBarActive = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1.0)
        
        /// Border color for form elements
        static let borderColor = cosmicBlue
        
        /// Transparent background for input fields
        static let transparentBackground = UIColor.clear
    }
    
    // MARK: - Typography
    struct Typography {
        
        /// Noctis font family for titles and headers
        static func noctisFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            // Try to load Noctis font, fallback to system font with appropriate weight
            if let noctisFont = UIFont(name: getNoctisFontName(for: weight), size: size) {
                return noctisFont
            }
            
            // Fallback to system font
            print("⚠️ Noctis font not found, using system font fallback")
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        /// DM Sans font family for body text and forms
        static func dmSansFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            // Try to load DM Sans font, fallback to system font
            if let dmSansFont = UIFont(name: getDMSansFontName(for: weight), size: size) {
                return dmSansFont
            }
            
            // Fallback to system font
            print("⚠️ DM Sans font not found, using system font fallback")
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        // MARK: - Font Sizes
        struct FontSizes {
            static let largeTitle: CGFloat = 28
            static let title1: CGFloat = 24
            static let title2: CGFloat = 20
            static let title3: CGFloat = 18
            static let headline: CGFloat = 17
            static let body: CGFloat = 16
            static let callout: CGFloat = 15
            static let subheadline: CGFloat = 14
            static let footnote: CGFloat = 13
            static let caption1: CGFloat = 12
            static let caption2: CGFloat = 11
        }
        
        // MARK: - Private Helper Methods
        private static func getNoctisFontName(for weight: UIFont.Weight) -> String {
            switch weight {
            case .ultraLight:
                return "Noctis-UltraLight"
            case .thin:
                return "Noctis-Thin"
            case .light:
                return "Noctis-Light"
            case .regular:
                return "Noctis-Regular"
            case .medium:
                return "Noctis-Medium"
            case .semibold:
                return "Noctis-SemiBold"
            case .bold:
                return "Noctis-Bold"
            case .heavy:
                return "Noctis-Heavy"
            case .black:
                return "Noctis-Black"
            default:
                return "Noctis-Regular"
            }
        }
        
        private static func getDMSansFontName(for weight: UIFont.Weight) -> String {
            switch weight {
            case .ultraLight, .thin:
                return "DMSans-Thin"
            case .light:
                return "DMSans-Light"
            case .regular:
                return "DMSans-Regular"
            case .medium:
                return "DMSans-Medium"
            case .semibold:
                return "DMSans-SemiBold"
            case .bold:
                return "DMSans-Bold"
            case .heavy, .black:
                return "DMSans-ExtraBold"
            default:
                return "DMSans-Regular"
            }
        }
    }
    
    // MARK: - Styling Methods
    
    /// Apply theme to navigation bar
    static func styleNavigationBar(_ navigationBar: UINavigationBar) {
        navigationBar.backgroundColor = Colors.cosmicGrey
        navigationBar.titleTextAttributes = [
            .foregroundColor: Colors.cosmicBlue,
            .font: Typography.noctisFont(size: Typography.FontSizes.headline, weight: .semibold)
        ]
        navigationBar.tintColor = Colors.cosmicOrange
    }
    
    /// Apply theme to tab bar
    static func styleTabBar(_ tabBar: UITabBar) {
        tabBar.backgroundColor = Colors.cosmicGrey
        tabBar.tintColor = Colors.cosmicOrange
        tabBar.unselectedItemTintColor = Colors.cosmicBlue
        
        // Custom appearance for selected tab
        if #available(iOS 13.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = Colors.cosmicGrey
            
            // Selected tab item
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = Colors.cosmicOrange
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: Colors.cosmicOrange,
                .font: Typography.dmSansFont(size: Typography.FontSizes.caption1, weight: .medium)
            ]
            
            // Normal tab item
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = Colors.cosmicBlue
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: Colors.cosmicBlue,
                .font: Typography.dmSansFont(size: Typography.FontSizes.caption1, weight: .regular)
            ]
            
            tabBar.standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
    /// Apply theme to a content background view
    static func styleContentBackground(_ view: UIView) {
        view.backgroundColor = Colors.cosmicGrey
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }
    
    /// Apply theme to a title label
    static func styleTitleLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.title2, weight: UIFont.Weight = .semibold) {
        label.font = Typography.noctisFont(size: fontSize, weight: weight)
        label.textColor = Colors.cosmicBlue
    }
    
    /// Apply theme to a body text label
    static func styleBodyLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.body, weight: UIFont.Weight = .regular) {
        label.font = Typography.dmSansFont(size: fontSize, weight: weight)
        label.textColor = Colors.cosmicBlue
    }
    
    /// Apply theme to a text field
    static func styleTextField(_ textField: UITextField) {
        textField.backgroundColor = Colors.transparentBackground
        textField.font = Typography.dmSansFont(size: Typography.FontSizes.body)
        textField.textColor = Colors.cosmicBlue
        textField.layer.borderColor = Colors.borderColor.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 8
        
        // Placeholder text
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: Colors.cosmicBlue.withAlphaComponent(0.6),
                    .font: Typography.dmSansFont(size: Typography.FontSizes.body)
                ]
            )
        }
        
        // Add padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
        textField.rightViewMode = .always
    }
    
    /// Apply theme to a button
    static func styleButton(_ button: UIButton, style: ButtonStyle = .primary) {
        switch style {
        case .primary:
            button.backgroundColor = Colors.cosmicOrange
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: Typography.FontSizes.headline, weight: .semibold)
        case .secondary:
            button.backgroundColor = Colors.cosmicGrey
            button.setTitleColor(Colors.cosmicBlue, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: Typography.FontSizes.headline, weight: .medium)
            button.layer.borderColor = Colors.cosmicBlue.cgColor
            button.layer.borderWidth = 1.0
        case .text:
            button.backgroundColor = UIColor.clear
            button.setTitleColor(Colors.cosmicOrange, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: Typography.FontSizes.body, weight: .medium)
        }
        
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
    }
    
    /// Create themed attributed string for mixed title/content text
    static func createAttributedText(title: String, content: String, titleSize: CGFloat = Typography.FontSizes.title3, contentSize: CGFloat = Typography.FontSizes.body) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Title attributes
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.noctisFont(size: titleSize, weight: .semibold),
            .foregroundColor: Colors.cosmicBlue
        ]
        attributedString.append(NSAttributedString(string: "\(title)\n", attributes: titleAttributes))
        
        // Content attributes
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.dmSansFont(size: contentSize, weight: .regular),
            .foregroundColor: Colors.cosmicBlue
        ]
        attributedString.append(NSAttributedString(string: content, attributes: contentAttributes))
        
        return attributedString
    }
    
    /// Apply theme to scroll view
    static func styleScrollView(_ scrollView: UIScrollView) {
        scrollView.backgroundColor = UIColor.clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    /// Apply theme to date picker
    static func styleDatePicker(_ datePicker: UIDatePicker) {
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.backgroundColor = Colors.cosmicGrey
        datePicker.setValue(Colors.cosmicBlue, forKey: "textColor")
    }
}

// MARK: - Button Styles
enum ButtonStyle {
    case primary    // Cosmic Orange background
    case secondary  // Cosmic Grey background with border
    case text       // Text only, no background
}

// MARK: - Theme Application Extension
extension UIViewController {
    
    /// Apply the global Cosmic Fit theme to this view controller
    func applyCosmicFitTheme() {
        view.backgroundColor = UIColor.systemBackground
        
        // Apply to navigation bar if present
        if let navigationBar = navigationController?.navigationBar {
            CosmicFitTheme.styleNavigationBar(navigationBar)
        }
    }
}
