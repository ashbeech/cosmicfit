//
//  InterpretationViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import UIKit

class InterpretationViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let themeLabel = UILabel()
    
    private var interpretationText: String = ""
    private var interpretationTitle: String = "Cosmic Fit Interpretation"
    private var themeName: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Configuration
    func configure(with interpretationText: String, title: String = "Cosmic Fit Interpretation", themeName: String = "") {
        self.interpretationText = interpretationText
        self.interpretationTitle = title
        self.themeName = themeName
        
        if isViewLoaded {
            textView.text = interpretationText
            titleLabel.text = interpretationTitle
            themeLabel.text = themeName.isEmpty ? "" : "Theme: \(themeName)"
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Style Interpretation"
        
        // Add share button
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareInterpretation))
        navigationItem.rightBarButtonItem = shareButton
        
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
        
        // Setup Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = interpretationTitle
        
        // Setup Theme Label
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        themeLabel.font = UIFont.italicSystemFont(ofSize: 16)
        themeLabel.textAlignment = .center
        themeLabel.textColor = .secondaryLabel
        themeLabel.text = themeName.isEmpty ? "" : "Theme: \(themeName)"
        
        // Setup Text View
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.text = interpretationText
        
        // Apply styling to make paragraphs more readable
        setupTextViewStyling()
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(themeLabel)
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            themeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            themeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            themeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func setupTextViewStyling() {
        // Apply styling to the text view for better readability
        
        // Check if we have attributed text with styling already
        guard textView.attributedText == nil else { return }
        
        // Check if we're using a dark or light interface
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Create paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 12
        
        // Create attributed string
        let attributedText = NSMutableAttributedString(string: interpretationText)
        
        // Apply paragraph style to the entire text
        attributedText.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedText.length)
        )
        
        // Look for section headers (all caps followed by newlines)
        let headerRegex = try? NSRegularExpression(pattern: "([A-Z][A-Z\\s]+):?\n", options: [])
        if let matches = headerRegex?.matches(in: interpretationText, options: [], range: NSRange(location: 0, length: interpretationText.count)) {
            for match in matches.reversed() {
                let range = match.range
                
                // Apply bold and slightly larger font to section headers
                attributedText.addAttributes([
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: isDarkMode ? UIColor.white : UIColor.black
                ], range: range)
            }
        }
        
        textView.attributedText = attributedText
    }
    
    // MARK: - UITraitCollection
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Re-apply styling when appearance changes (e.g., dark/light mode)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            setupTextViewStyling()
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
