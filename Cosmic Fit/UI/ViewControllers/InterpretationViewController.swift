//
//  InterpretationViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//  Updated to better display the Blueprint format

import UIKit

class InterpretationViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private var textView = UITextView()
    private let themeLabel = UILabel()
    
    private var interpretationText: String = ""
    private var interpretationTitle: String = "Cosmic Fit Interpretation"
    private var themeName: String = ""
    private var isBlueprintView: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("InterpretationViewController viewDidLoad called")
        setupUI()
        
        // Ensure text is displayed
        print("Setting text: \(interpretationText.prefix(50))...")
        textView.text = interpretationText
        titleLabel.text = interpretationTitle
        themeLabel.text = themeName.isEmpty ? "" : "Theme: \(themeName)"
        
        // Apply styling after the text is set
        setupTextViewStyling()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("InterpretationViewController viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("InterpretationViewController viewDidAppear - text length: \(textView.text.count)")
    }
    
    // MARK: - Configuration
    func configure(with interpretationText: String, title: String = "Cosmic Fit Interpretation", themeName: String = "", isBlueprint: Bool = false) {
        print("Configuring InterpretationVC with \(interpretationText.count) characters of text")
        self.interpretationText = interpretationText
        self.interpretationTitle = title
        self.themeName = themeName
        self.isBlueprintView = isBlueprint
        
        if isViewLoaded {
            textView.text = interpretationText
            titleLabel.text = interpretationTitle
            themeLabel.text = themeName.isEmpty ? "" : "Theme: \(themeName)"
            setupTextViewStyling()
            print("View was loaded, text applied directly to textView")
        } else {
            print("View not yet loaded, text will be applied when view loads")
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Style Interpretation"
        
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
            // Note: We deliberately don't constrain contentView's height to scrollView
        ])
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Theme label
        themeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        themeLabel.textColor = .secondaryLabel
        themeLabel.textAlignment = .center
        themeLabel.numberOfLines = 0
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(themeLabel)
        
        // Create a text view for interpretation
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.text = interpretationText
        
        // Important: Set these properties to ensure proper scrolling
        textView.isScrollEnabled = false // We want the scrollView to handle scrolling, not the textView
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Theme label
            themeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            themeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            themeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // TextView fills contentView below labels
            textView.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Add a share button to the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareInterpretation)
        )
        
        print("UI setup completed with text length: \(textView.text?.count ?? 0)")
    }

    private func setupTextViewStyling() {
        // Skip if text is empty
        guard let text = textView.text, !text.isEmpty else {
            print("⚠️ Cannot style empty text")
            return
        }
        
        print("Applying styling to text of length: \(text.count)")
        
        // Check if we're using a dark or light interface
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let textColor = isDarkMode ? UIColor.white : UIColor.black
        let headerColor = isDarkMode ? UIColor.systemBlue : UIColor.systemBlue
        let subHeaderColor = isDarkMode ? UIColor.systemTeal : UIColor.systemTeal
        
        // Create an attributed string from the markdown-like text
        let attributedText = NSMutableAttributedString(string: text)
        
        // Apply base styling to the entire text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 12
        
        attributedText.addAttributes([
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 16)
        ], range: NSRange(location: 0, length: attributedText.length))
        
        // Apply header styling for different levels
        styleTitleHeaders(in: attributedText, text: text, color: headerColor)
        styleSubtitleHeaders(in: attributedText, text: text, color: subHeaderColor)
        
        // Apply divider styling
        styleDividers(in: attributedText, text: text)
        
        // Apply blueprint-specific styling if needed
        if isBlueprintView {
            styleBlueprintSections(in: attributedText, text: text)
        }
        
        // Apply the styled text
        textView.attributedText = attributedText
    }
    
    // Helper method to style main headers (# Title)
    private func styleTitleHeaders(in attributedText: NSMutableAttributedString, text: String, color: UIColor) {
        do {
            // Find section title headers (# Title)
            let headerRegex = try NSRegularExpression(pattern: "# ([^\n]+)", options: [])
            let matches = headerRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                let fullRange = match.range
                
                // Apply styling to the header text (excluding the # symbol)
                let headerTextRange = NSRange(location: match.range(at: 1).location, length: match.range(at: 1).length)
                
                attributedText.addAttributes([
                    .font: UIFont.boldSystemFont(ofSize: 22),
                    .foregroundColor: color
                ], range: headerTextRange)
                
                // Replace the # with empty space to maintain alignment but hide the markdown symbol
                attributedText.replaceCharacters(in: NSRange(location: fullRange.location, length: 2), with: "")
            }
        } catch {
            print("⚠️ Regex error for headers: \(error.localizedDescription)")
        }
    }
    
    // Helper method to style subheaders (## Subtitle)
    private func styleSubtitleHeaders(in attributedText: NSMutableAttributedString, text: String, color: UIColor) {
        do {
            // Find section subtitle headers (## Subtitle)
            let subheaderRegex = try NSRegularExpression(pattern: "## ([^\n]+)", options: [])
            let matches = subheaderRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                let fullRange = match.range
                
                // Apply styling to the header text (excluding the ## symbols)
                let headerTextRange = NSRange(location: match.range(at: 1).location, length: match.range(at: 1).length)
                
                attributedText.addAttributes([
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: color
                ], range: headerTextRange)
                
                // Replace the ## with empty space to maintain alignment but hide the markdown symbol
                attributedText.replaceCharacters(in: NSRange(location: fullRange.location, length: 3), with: "")
            }
        } catch {
            print("⚠️ Regex error for subheaders: \(error.localizedDescription)")
        }
    }
    
    // Helper method to style dividers (---)
    private func styleDividers(in attributedText: NSMutableAttributedString, text: String) {
        do {
            // Find divider lines (---)
            let dividerRegex = try NSRegularExpression(pattern: "---+", options: [])
            let matches = dividerRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                let range = match.range
                
                // Create a divider line with spacing
                let divider = "\n\n\n"
                
                // Replace the --- with divider
                attributedText.replaceCharacters(in: range, with: divider)
            }
        } catch {
            print("⚠️ Regex error for dividers: \(error.localizedDescription)")
        }
    }
    
    // Helper method for blueprint-specific styling
    private func styleBlueprintSections(in attributedText: NSMutableAttributedString, text: String) {
        // Custom styling for special blueprint sections (if needed)
        // This could highlight keywords, color-code specific sections, etc.
    }
    
    // MARK: - UITraitCollection
    @available(iOS, introduced: 13.0, deprecated: 17.0, message: "Use the trait change registration APIs instead")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 17.0, *) {
            // Use the new registration API in iOS 17+
        } else {
            // Re-apply styling when appearance changes (e.g., dark/light mode)
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                setupTextViewStyling()
            }
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
