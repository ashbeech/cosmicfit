//
//  CosmicFitTheme.swift
//  Cosmic Fit
//
//  Enhanced theme engine for comprehensive styling across the app
//

import UIKit

/// Cosmic Fit Theme Engine
/// Provides centralized theming for all UI elements across the app
struct CosmicFitTheme {
    
    // MARK: - Colors
    struct Colors {
        /// Cosmic Grey - Main background color for content areas (#DEDEDE)
        static let cosmicGrey = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 1.0)
        
        /// Dark Cosmic Grey - Navigation bar background for contrast (#B8B8B8)
        static let darkCosmicGrey = UIColor(red: 184/255, green: 184/255, blue: 184/255, alpha: 1.0)
        
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
        
        /// Divider color
        static let dividerColor = cosmicBlue.withAlphaComponent(0.3)
    }
    
    // MARK: - Typography
    struct Typography {
        
        /// Noctis font family for titles and headers
        static func DMSerifTextFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            // Try to load Noctis font, fallback to system font with appropriate weight
            if let DMSerifTextFont = UIFont(name: getDMSerifTextFontName(for: weight), size: size) {
                return DMSerifTextFont
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
            static let subhead: CGFloat = 14
            static let footnote: CGFloat = 13
            static let caption1: CGFloat = 12
            static let caption2: CGFloat = 11
        }
        
        // Keep DM Sans weight mapping as-is
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
        
        // Legacy helper kept for compatibility (not used anymore but safe if referenced)
        private static func getDMSerifTextFontName(for weight: UIFont.Weight) -> String {
            // Noctis removed; map all requests to DM Serif Text Regular
            return "DMSerifText-Regular"
        }
    }
    
    // MARK: - Styling Methods
    
    /// Apply theme to navigation bar
    static func styleNavigationBar(_ navigationBar: UINavigationBar) {
        navigationBar.backgroundColor = Colors.darkCosmicGrey
        navigationBar.titleTextAttributes = [
            .foregroundColor: Colors.cosmicBlue,
            .font: Typography.DMSerifTextFont(size: Typography.FontSizes.headline, weight: .semibold)
        ]
        navigationBar.tintColor = Colors.cosmicOrange
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Colors.darkCosmicGrey
            appearance.titleTextAttributes = [
                .foregroundColor: Colors.cosmicBlue,
                .font: Typography.DMSerifTextFont(size: Typography.FontSizes.headline, weight: .semibold)
            ]
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    /// Apply theme to tab bar with proper selection indicator
    static func styleTabBar(_ tabBar: UITabBar) {
        tabBar.backgroundColor = Colors.darkCosmicGrey
        tabBar.tintColor = Colors.cosmicOrange
        tabBar.unselectedItemTintColor = Colors.cosmicBlue
        
        if #available(iOS 13.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = Colors.darkCosmicGrey
            
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
    
    /// Apply custom selection indicator for active tab
    static func applyTabSelectionIndicator(_ tabBar: UITabBar, selectedIndex: Int) {
        // Remove existing selection indicators
        tabBar.subviews.forEach { subview in
            if subview.tag == 999 {
                subview.removeFromSuperview()
            }
        }
        
        // Calculate tab width and position
        let tabWidth = tabBar.frame.width / CGFloat(tabBar.items?.count ?? 1)
        let indicatorWidth = tabWidth * 0.8
        let indicatorHeight: CGFloat = tabBar.frame.height - 10
        let xPosition = tabWidth * CGFloat(selectedIndex) + (tabWidth - indicatorWidth) / 2
        
        // Create selection indicator
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = Colors.tabBarActive
        selectionIndicator.layer.cornerRadius = 8
        selectionIndicator.tag = 999
        selectionIndicator.frame = CGRect(
            x: xPosition,
            y: 5,
            width: indicatorWidth,
            height: indicatorHeight
        )
        
        tabBar.insertSubview(selectionIndicator, at: 0)
    }
    
    /// Apply theme to a content background view
    static func styleContentBackground(_ view: UIView) {
        view.backgroundColor = Colors.cosmicGrey
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }
    
    /// Apply theme to a title label (headers)
    static func styleTitleLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.title2, weight: UIFont.Weight = .semibold) {
        label.font = Typography.DMSerifTextFont(size: fontSize, weight: weight)
        label.textColor = Colors.cosmicBlue
    }
    
    /// Apply theme to a body text label
    static func styleBodyLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.body, weight: UIFont.Weight = .regular) {
        label.font = Typography.dmSansFont(size: fontSize, weight: weight)
        label.textColor = Colors.cosmicGrey
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
    
    /// Apply theme to a text view
    static func styleTextView(_ textView: UITextView) {
        textView.backgroundColor = Colors.transparentBackground
        textView.font = Typography.dmSansFont(size: Typography.FontSizes.body)
        textView.textColor = Colors.cosmicBlue
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.layer.borderColor = Colors.borderColor.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
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
    
    /// Apply theme to date picker
    static func styleDatePicker(_ datePicker: UIDatePicker) {
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.backgroundColor = Colors.cosmicGrey
        datePicker.setValue(Colors.cosmicBlue, forKey: "textColor")
    }
    
    /// Apply theme to divider/separator views
    static func styleDivider(_ divider: UIView) {
        divider.backgroundColor = Colors.dividerColor
    }
    
    /// Create themed attributed string for mixed title/content text
    static func createAttributedText(title: String, content: String, titleSize: CGFloat = Typography.FontSizes.title3, contentSize: CGFloat = Typography.FontSizes.body) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Title attributes (Noctis font)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.DMSerifTextFont(size: titleSize, weight: .semibold),
            .foregroundColor: Colors.cosmicBlue
        ]
        attributedString.append(NSAttributedString(string: "\(title)\n", attributes: titleAttributes))
        
        // Content attributes (DM Sans font)
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
        scrollView.contentInsetAdjustmentBehavior = .never
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
