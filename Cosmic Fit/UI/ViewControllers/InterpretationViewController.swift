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

    // Skip the complex styling for now
    private func setupTextViewStyling() {
        // Don't do anything fancy yet
        print("Skipping complex styling for debugging")
    }
    /*
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
    */
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
