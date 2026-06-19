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
    
    // MARK: - Colours
    struct Colours {
        /// Cosmic Grey - Main background colour for content areas (#DEDEDE)
        static let cosmicGrey = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 1.0)
        
        /// Darker Cosmic Grey - Sub-page background for subtle depth
        static let darkerCosmicGrey = UIColor(red: 106/255, green: 106/255, blue: 115/255, alpha: 1.0)
        
        /// Dark Cosmic Grey - Navigation bar background for contrast (#B8B8B8)
        static let darkCosmicGrey = UIColor(red: 184/255, green: 184/255, blue: 184/255, alpha: 1.0)
        
        /// Cosmic Blue - Primary text colour (#000210)
        static let cosmicBlue = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        /// Highlight/accent colours (#FF8502/7E69E6)
        static let cosmicOrange = UIColor(red: 255/255, green: 133/255, blue: 2/255, alpha: 1.0)
        
        static let cosmicLilac = UIColor(red: 126/255, green: 105/255, blue: 230/255, alpha: 1.0)

        /// Tab bar background colour - Black
        static let tabBarBackground = cosmicBlue
        
        /// Tab bar text/icon colour - White
        static let tabBarInactive = UIColor.white
        
        /// Tab bar active/selected colour - Cosmic Orange
        static let tabBarActive = cosmicLilac
        
        /// Border colour for form elements
        static let borderColor = cosmicBlue
        
        /// Transparent background for input fields
        static let transparentBackground = UIColor.clear
        
        /// Divider colour
        static let dividerColor = cosmicBlue.withAlphaComponent(0.3)
    }

    // MARK: - Header glyph layout
    /// Shared spacing and frame for section glyphs (Daily Fit numerals, Style Guide sub-pages).
    struct HeaderGlyphLayout {
        static let spacingAbove: CGFloat = 26
        static let spacingBelow: CGFloat = 22
        static let width: CGFloat = 60
        static let height: CGFloat = 44
    }

    /// Style Guide hub header (`style_guide_glyph` is 86×44 — wider than section glyphs).
    /// Frame width is derived from height so the rendered mark matches sub-page glyph height.
    struct StyleGuideHubGlyphLayout {
        private static let assetAspect: CGFloat = 86 / 44
        static let height = HeaderGlyphLayout.height
        static let width = height * assetAspect
        static let spacingAbove = HeaderGlyphLayout.spacingAbove
        /// Sub-pages place `title1` (28pt) below the glyph; the hub uses `pageTitle` (48pt)
        /// with tight line height, so extra gap keeps the visual rhythm consistent.
        static let spacingBelow = HeaderGlyphLayout.spacingBelow
            + (Typography.FontSizes.pageTitle - Typography.FontSizes.title1) / 2
            + 6
    }

    /// Eyebrow label above section glyphs ("ABOUT YOU", "DAILY FIT", etc.).
    struct PageEyebrowTypography {
        static let fontSize: CGFloat = 15
        /// Letter-spacing as a fraction of font size (4% → 0.04).
        static let letterSpacingFraction: CGFloat = 0.04
        static var letterSpacing: CGFloat { fontSize * letterSpacingFraction }

        static func attributedString(_ text: String, color: UIColor) -> NSAttributedString {
            NSAttributedString(
                string: text,
                attributes: [
                    .font: Typography.dmSansFont(size: fontSize, weight: .bold),
                    .foregroundColor: color,
                    .kern: letterSpacing
                ]
            )
        }
    }

    /// Style Guide hub title — two-line serif caps ("YOUR COSMIC STYLE GUIDE").
    struct PageMainTitleTypography {
        static let styleGuideLetterSpacingFraction: CGFloat = 0.024
        static let multiLineHeightMultiple: CGFloat = 0.78

        static func attributedString(
            _ text: String,
            fontSize: CGFloat = Typography.FontSizes.pageTitle,
            color: UIColor = Colours.cosmicBlue,
            weight: UIFont.Weight = .regular
        ) -> NSAttributedString {
            let font = Typography.DMSerifTextFont(size: fontSize, weight: weight)
            let kern = fontSize * styleGuideLetterSpacingFraction

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = multiLineHeightMultiple
            paragraphStyle.alignment = .center

            return NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .kern: kern,
                    .paragraphStyle: paragraphStyle
                ]
            )
        }
    }

    /// Style Guide sub-page titles — serif section headers ("The Textures", "The Blueprint", etc.).
    struct StyleGuideSubPageTitleTypography {
        static let letterSpacingFraction: CGFloat = 0.052

        static func attributedString(
            _ text: String,
            fontSize: CGFloat = Typography.FontSizes.title1,
            color: UIColor = Colours.cosmicBlue,
            weight: UIFont.Weight = .bold
        ) -> NSAttributedString {
            let font = Typography.DMSerifTextFont(size: fontSize, weight: weight)
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .kern: fontSize * letterSpacingFraction
                ]
            )
        }
    }

    /// Daily Fit tarot card title — single-line serif caps ("THE CHARIOT"); default line height.
    struct DailyFitCardTitleTypography {
        static let letterSpacingFraction: CGFloat = 0.078

        static func attributedString(
            _ text: String,
            fontSize: CGFloat = Typography.FontSizes.title1,
            color: UIColor = .black,
            weight: UIFont.Weight = .semibold
        ) -> NSAttributedString {
            let font = Typography.DMSerifTextFont(size: fontSize, weight: weight)
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .kern: fontSize * letterSpacingFraction
                ]
            )
        }
    }

    /// Daily Fit date line — sans caps ("FRIDAY, MAY 2").
    struct DailyFitDateTypography {
        static let fontSize = Typography.FontSizes.callout
        static let letterSpacingFraction: CGFloat = 0.14

        static func attributedString(_ text: String, color: UIColor = .black) -> NSAttributedString {
            NSAttributedString(
                string: text,
                attributes: [
                    .font: Typography.dmSansFont(size: fontSize, weight: .regular),
                    .foregroundColor: color,
                    .kern: fontSize * letterSpacingFraction
                ]
            )
        }
    }
    
    // MARK: - Typography
    struct Typography {
        
        /// Font sizes following iOS Human Interface Guidelines
        struct FontSizes {
            static let largeTitle: CGFloat = 35
            static let title1: CGFloat = 28
            static let title2: CGFloat = 22
            static let title3: CGFloat = 20
            static let headline: CGFloat = 17
            static let body: CGFloat = 18
            static let callout: CGFloat = 16
            static let subheadline: CGFloat = 22
            static let sectionHeader: CGFloat = 16
            static let pageTitle: CGFloat = 48
            static let footnote: CGFloat = 13
            static let caption1: CGFloat = 12
            static let caption2: CGFloat = 11
        }
        
        /// DM Serif Text font for titles and headers (replaces Noctis)
        /// Supports weight parameter: regular uses PTSerif-Regular, bold weights use system serif font with weight
        static func DMSerifTextFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            // For regular weight, use PTSerif-Regular
            if weight == .regular {
                if let customFont = UIFont(name: "PTSerif-Regular", size: size) {
                    return customFont
                }
            }
            
            // For bold weights (semibold, bold, heavy, black), use system serif font with weight
            // This provides bold appearance when PT Serif Bold is not available
            // Create a serif font descriptor and apply the weight
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            if let serifDescriptor = descriptor.withDesign(.serif) {
                // Create font with serif design and apply weight trait
                var traits = (serifDescriptor.fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
                traits[.weight] = weight
                let boldSerifDescriptor = serifDescriptor.addingAttributes([.traits: traits])
                return UIFont(descriptor: boldSerifDescriptor, size: size)
            }
            
            // Fallback to system font with requested weight (will use system serif if available)
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        /// PT Serif Text Italic font for subsection headers
        static func DMSerifTextItalicFont(size: CGFloat) -> UIFont {
            if let customFont = UIFont(name: "PTSerif-Italic", size: size) {
                return customFont
            }
            // Fallback to system italic
            return UIFont.italicSystemFont(ofSize: size)
        }

        /// PT Serif bold italic — requires bundled `PTSerif-BoldItalic.ttf`.
        static func DMSerifTextBoldItalicFont(size: CGFloat) -> UIFont {
            if let customFont = UIFont(name: "PTSerif-BoldItalic", size: size) {
                return customFont
            }
            return DMSerifTextItalicFont(size: size)
        }
        
        /// DM Sans font for body text (replaces SF Pro Display)
        static func dmSansFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            let fontName = getDMSansFontName(for: weight)
            
            if let customFont = UIFont(name: fontName, size: size) {
                return customFont
            }
            
            // Fallback to system font with appropriate weight
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        // Helper to get correct DM Sans font name based on weight
        private static func getDMSansFontName(for weight: UIFont.Weight) -> String {
            switch weight {
            case .ultraLight, .thin, .light:
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
            // Noctis removed; map all requests to PT Serif Regular
            return "PTSerif-Regular"
        }
    }
    
    // MARK: - Styling Methods
    
    /// Apply theme to navigation bar
    static func styleNavigationBar(_ navigationBar: UINavigationBar) {
        navigationBar.backgroundColor = Colours.darkCosmicGrey
        navigationBar.titleTextAttributes = [
            .foregroundColor: Colours.cosmicBlue,
            .font: Typography.DMSerifTextFont(size: Typography.FontSizes.headline, weight: .semibold)
        ]
        navigationBar.tintColor = Colours.cosmicOrange
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Colours.darkCosmicGrey
            appearance.titleTextAttributes = [
                .foregroundColor: Colours.cosmicBlue,
                .font: Typography.DMSerifTextFont(size: Typography.FontSizes.headline, weight: .semibold)
            ]
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    /// Apply theme to tab bar with black background and white text
    static func styleTabBar(_ tabBar: UITabBar) {
        tabBar.backgroundColor = Colours.tabBarBackground
        tabBar.barTintColor = Colours.tabBarBackground
        tabBar.tintColor = Colours.tabBarActive
        tabBar.unselectedItemTintColor = Colours.tabBarInactive
        tabBar.isTranslucent = false
        
        if #available(iOS 13.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = Colours.tabBarBackground
            
            // Selected tab item - Orange text with DM Serif Text font
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: Colours.tabBarActive,
                .font: Typography.DMSerifTextFont(size: Typography.FontSizes.body, weight: .regular)
            ]
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .clear // Hide icon
            
            // Normal tab item - White text with DM Serif Text font
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: Colours.tabBarInactive,
                .font: Typography.DMSerifTextFont(size: Typography.FontSizes.body, weight: .regular)
            ]
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .clear // Hide icon
            
            // Increase title position to center text vertically (since no icon)
            tabBarAppearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -10)
            tabBarAppearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -10)
            
            tabBar.standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBarAppearance
            }
        } else {
            // Fallback for older iOS versions
            tabBar.items?.forEach { item in
                item.setTitleTextAttributes([
                    .foregroundColor: Colours.tabBarInactive,
                    .font: Typography.DMSerifTextFont(size: Typography.FontSizes.body, weight: .regular)
                ], for: .normal)
                item.setTitleTextAttributes([
                    .foregroundColor: Colours.tabBarActive,
                    .font: Typography.DMSerifTextFont(size: Typography.FontSizes.body, weight: .regular)
                ], for: .selected)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -10)
            }
        }
    }
    
    /// Apply custom selection indicator for active tab - REMOVED
    /// No longer using background selection indicators per new design
    static func applyTabSelectionIndicator(_ tabBar: UITabBar, selectedIndex: Int) {
        // Remove any existing selection indicators from old design
        tabBar.subviews.forEach { subview in
            if subview.tag == 999 {
                subview.removeFromSuperview()
            }
        }
        // New design uses colour change only, no background indicator
    }
    
    /// Add vertical dividers between tabs
    static func addTabDividers(_ tabBar: UITabBar) {
        // Remove existing dividers
        tabBar.subviews.filter { $0.tag == 888 }.forEach { $0.removeFromSuperview() }
        
        guard let itemCount = tabBar.items?.count, itemCount > 1 else { return }
        
        let tabWidth = tabBar.frame.width / CGFloat(itemCount)
        
        // Add dividers between tabs
        for i in 1..<itemCount {
            let divider = UIView()
            divider.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            divider.tag = 888
            
            let x = tabWidth * CGFloat(i)
            let height = tabBar.frame.height // Full height
            let y: CGFloat = 0 // Start at top
            
            divider.frame = CGRect(x: x - 0.5, y: y, width: 1, height: height)
            tabBar.addSubview(divider)
        }
    }
    
    /// Apply theme to a content background view
    static func styleContentBackground(_ view: UIView) {
        view.backgroundColor = Colours.cosmicGrey
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }
    
    /// Apply theme to a title label (headers)
    static func styleTitleLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.title2, weight: UIFont.Weight = .semibold) {
        label.font = Typography.DMSerifTextFont(size: fontSize, weight: weight)
        label.textColor = Colours.cosmicBlue
    }

    /// Eyebrow caps label above a section glyph (15pt DM Sans bold, 4% tracking).
    static func stylePageEyebrowLabel(_ label: UILabel, text: String, color: UIColor) {
        label.textAlignment = .center
        label.attributedText = PageEyebrowTypography.attributedString(text, color: color)
    }
    
    /// text over tarot card
    static func styleBodyLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.body, weight: UIFont.Weight = .regular) {
        label.font = Typography.dmSansFont(size: fontSize, weight: weight)
        label.textColor = Colours.cosmicGrey
    }
    
    /// Apply theme to a subsection header label (for Do's & Don'ts sections)
    static func styleSubsectionLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.title3, italic: Bool = true) {
        label.font = italic ? Typography.DMSerifTextItalicFont(size: fontSize) : Typography.DMSerifTextFont(size: fontSize)
        label.textColor = Colours.cosmicBlue
        label.textAlignment = .left
    }

    /// Apply theme to a decorative symbol label (like stars, bullets)
    static func styleSymbolLabel(_ label: UILabel, fontSize: CGFloat = Typography.FontSizes.title3) {
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textColor = Colours.cosmicBlue
        label.textAlignment = .left
    }
    
    /// Apply theme to a text field
    static func styleTextField(_ textField: UITextField) {
        textField.backgroundColor = Colours.transparentBackground
        textField.font = Typography.dmSansFont(size: Typography.FontSizes.body)
        textField.textColor = Colours.cosmicBlue
        textField.layer.borderColor = Colours.borderColor.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 8
        
        // Placeholder text
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: Colours.cosmicBlue.withAlphaComponent(0.6),
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
        textView.backgroundColor = Colours.transparentBackground
        textView.font = Typography.dmSansFont(size: Typography.FontSizes.body)
        textView.textColor = Colours.cosmicBlue
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.layer.borderColor = Colours.borderColor.cgColor
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
            button.backgroundColor = Colours.cosmicOrange
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: Typography.FontSizes.headline, weight: .semibold)
            button.layer.cornerRadius = 8
        case .onboardingAction:
            button.backgroundColor = Colours.cosmicBlue
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: 18, weight: .medium)
            button.layer.cornerRadius = 6
        case .secondary:
            button.backgroundColor = Colours.cosmicGrey
            button.setTitleColor(Colours.cosmicBlue, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: Typography.FontSizes.headline, weight: .medium)
            button.layer.borderColor = Colours.cosmicBlue.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 8
        case .text:
            button.backgroundColor = UIColor.clear
            button.setTitleColor(Colours.cosmicOrange, for: .normal)
            button.titleLabel?.font = Typography.dmSansFont(size: Typography.FontSizes.body, weight: .medium)
            button.layer.cornerRadius = 8
        }

        button.layer.masksToBounds = true
    }

    /// Light spinner for `.onboardingAction` buttons (cosmicBlue background).
    static func styleActivityIndicatorOnOnboardingAction(_ indicator: UIActivityIndicatorView) {
        indicator.style = .medium
        indicator.color = .white
        indicator.hidesWhenStopped = true
    }
    
    /// Apply theme to date picker
    static func styleDatePicker(_ datePicker: UIDatePicker) {
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.backgroundColor = Colours.cosmicGrey
        datePicker.setValue(Colours.cosmicBlue, forKey: "textColor")
    }
    
    /// Apply theme to divider/separator views
    static func styleDivider(_ divider: UIView) {
        divider.backgroundColor = Colours.dividerColor
    }
    
    /// Create themed attributed string for mixed title/content text
    static func createAttributedText(title: String, content: String, titleSize: CGFloat = Typography.FontSizes.title3, contentSize: CGFloat = Typography.FontSizes.body) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Title attributes (DM Serif Text font)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.DMSerifTextFont(size: titleSize, weight: .semibold),
            .foregroundColor: Colours.cosmicBlue
        ]
        attributedString.append(NSAttributedString(string: "\(title)\n", attributes: titleAttributes))
        
        // Content attributes (DM Sans font)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.dmSansFont(size: contentSize, weight: .regular),
            .foregroundColor: Colours.cosmicBlue
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
    case primary           // Cosmic Orange background
    case onboardingAction  // cosmicBlue + white text on light backgrounds (onboarding Next, auth actions)
    case secondary         // Cosmic Grey background with border
    case text              // Text only, no background
}

// MARK: - Theme Application Extension
extension UIViewController {
    
    /// Apply the global Cosmic Fit theme to this view controller
    func applyCosmicFitTheme() {
        view.backgroundColor = UIColor.systemBackground
        /*
        // Apply to navigation bar if present
        if let navigationBar = navigationController?.navigationBar {
            CosmicFitTheme.styleNavigationBar(navigationBar)
        }
         */
    }
}
