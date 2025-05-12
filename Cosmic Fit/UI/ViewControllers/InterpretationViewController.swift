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
    private var textView = UITextView()
    private let themeLabel = UILabel()
    
    private var interpretationText: String = ""
    private var interpretationTitle: String = "Cosmic Fit Interpretation"
    private var themeName: String = ""
    
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

    // Also add this method to check lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("InterpretationViewController viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("InterpretationViewController viewDidAppear - text length: \(textView.text.count)")
    }
    
    // MARK: - Configuration
    func configure(with interpretationText: String, title: String = "Cosmic Fit Interpretation", themeName: String = "") {
        print("Configuring InterpretationVC with \(interpretationText.count) characters of text")
        self.interpretationText = interpretationText
        self.interpretationTitle = title
        self.themeName = themeName
        
        if isViewLoaded {
            textView.text = interpretationText
            titleLabel.text = interpretationTitle
            themeLabel.text = themeName.isEmpty ? "" : "Theme: \(themeName)"
            print("View was loaded, text applied directly to textView")
        } else {
            print("View not yet loaded, text will be applied when view loads")
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Style Interpretation"
        
        // Add debug background colors to identify layout issues
        scrollView.backgroundColor = UIColor.red.withAlphaComponent(0.1)
        contentView.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
        
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
        
        // *** SIMPLIFIED TEXT VIEW APPROACH ***
        // Create a simpler text view directly
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .label // Uses system text color
        textView.backgroundColor = UIColor.green.withAlphaComponent(0.1) // Debug color
        textView.text = interpretationText
        
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 500) // Force a minimum height
        ])
        
        // Add a debug button to verify the view controller is responsive
        let debugButton = UIButton(type: .system)
        debugButton.setTitle("Debug: Tap Me", for: .normal)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugButton)
        
        NSLayoutConstraint.activate([
            debugButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            debugButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        print("UI setup completed with text length: \(textView.text?.count ?? 0)")
    }
    
    @objc private func debugButtonTapped() {
        print("Debug button tapped - text length: \(textView.text?.count ?? 0)")
        let alert = UIAlertController(title: "Debug Info",
                                     message: "Text length: \(textView.text?.count ?? 0)",
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        let headerColor = isDarkMode ? UIColor.white : UIColor.darkText
        
        // Create paragraph style with safe values
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 12
        
        // Create attributed string safely
        let attributedText = NSMutableAttributedString(string: text)
        
        // Apply base text color and paragraph style to the entire text
        attributedText.addAttributes([
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 16)
        ], range: NSRange(location: 0, length: attributedText.length))
        
        // Apply header styling
        do {
            // Find section headers (all caps followed by newlines or colons)
            let headerRegex = try NSRegularExpression(pattern: "([A-Z][A-Z\\s]+[A-Z]):?(?:\n|$)", options: [])
            let matches = headerRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            print("Found \(matches.count) headers to style")
            
            for match in matches {
                let range = match.range
                // Apply bold and slightly larger font to section headers
                attributedText.addAttributes([
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: headerColor
                ], range: range)
            }
        } catch {
            print("⚠️ Regex error: \(error.localizedDescription)")
            // Continue without header styling
        }
        
        // Apply the styled text
        textView.attributedText = attributedText
        print("✅ Successfully applied styling")
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
