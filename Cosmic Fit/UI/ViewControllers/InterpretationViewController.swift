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
    private let profileHeaderView = UIView()
    private let profileLabel = UILabel()
    private let birthInfoLabel = UILabel()
    private let locationLabel = UILabel()
    private let dividerView = UIView()
    private let titleLabel = UILabel()
    private var textView = UITextView()
    private let themeLabel = UILabel()
    
    private var interpretationText: String = ""
    private var interpretationTitle: String = "Cosmic Fit Interpretation"
    private var themeName: String = ""
    private var isBlueprintView: Bool = false
    
    // Birth information properties
    private var birthDate: Date?
    private var birthCity: String = ""
    private var birthCountry: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Ensure text is displayed
        textView.text = interpretationText
        titleLabel.text = interpretationTitle
        themeLabel.text = ""//themeName.isEmpty ? "" : "Theme: \(themeName)"
        
        // Apply styling after the text is set
        setupTextViewStyling()
        updateProfileHeader()
    }
    
    // MARK: - Configuration
    func configure(with interpretationText: String,
                  title: String = "Cosmic Fit Interpretation",
                  themeName: String = "",
                  isBlueprint: Bool = false,
                  birthDate: Date? = nil,
                  birthCity: String = "",
                  birthCountry: String = "") {
        
        self.interpretationText = interpretationText
        self.interpretationTitle = title
        self.themeName = themeName
        self.isBlueprintView = isBlueprint
        self.birthDate = birthDate
        self.birthCity = birthCity
        self.birthCountry = birthCountry
        
        if isViewLoaded {
            textView.text = interpretationText
            titleLabel.text = interpretationTitle
            themeLabel.text = themeName.isEmpty ? "" : "Theme: \(themeName)"
            setupTextViewStyling()
            updateProfileHeader()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black // Change to black for blueprint style
        title = ""
        
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
        ])
        
        // Setup Profile Header
        setupProfileHeader()
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Theme label
        themeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        themeLabel.textColor = .white
        themeLabel.textAlignment = .left
        themeLabel.numberOfLines = 0
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(themeLabel)
        
        // Create a text view for interpretation
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .white
        textView.backgroundColor = .black
        textView.text = interpretationText
        
        // Important: Set these properties to ensure proper scrolling
        textView.isScrollEnabled = false // We want the scrollView to handle scrolling, not the textView
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            // Profile header view
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Divider view
            dividerView.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 16),
            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Theme label
            themeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            themeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            themeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // TextView fills contentView below labels
            textView.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 24),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        // Add a share button to the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareInterpretation)
        )
    }
    
    private func setupProfileHeader() {
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileHeaderView)
        
        // Profile Label
        profileLabel.text = "PROFILE"
        profileLabel.font = UIFont.systemFont(ofSize: 16, weight: .light)
        profileLabel.textColor = .white
        profileLabel.textAlignment = .left
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(profileLabel)
        
        // Birth Info Label
        birthInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        birthInfoLabel.textColor = .white
        birthInfoLabel.textAlignment = .left
        birthInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(birthInfoLabel)
        
        // Location Label
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        locationLabel.textColor = .white
        locationLabel.textAlignment = .left
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(locationLabel)
        
        // Divider
        dividerView.backgroundColor = .gray
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dividerView)
        
        // Set constraints for profile header components
        NSLayoutConstraint.activate([
            profileLabel.topAnchor.constraint(equalTo: profileHeaderView.topAnchor),
            profileLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor),
            profileLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor),
            
            birthInfoLabel.topAnchor.constraint(equalTo: profileLabel.bottomAnchor, constant: 8),
            birthInfoLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor),
            birthInfoLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor),
            
            locationLabel.topAnchor.constraint(equalTo: birthInfoLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor),
            locationLabel.bottomAnchor.constraint(equalTo: profileHeaderView.bottomAnchor)
        ])
    }
    
    private func updateProfileHeader() {
        // Format birth date if available
        if let date = self.birthDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mma"
            
            let dateString = dateFormatter.string(from: date)
            let timeString = timeFormatter.string(from: date)
            
            birthInfoLabel.text = "Born \(dateString), \(timeString)"
        } else {
            birthInfoLabel.text = "Born --.--.----, --:--"
        }
        
        
        // Set location - ONLY city and country, no time information
        let city = self.birthCity.isEmpty ? "CITY" : self.birthCity.uppercased()
        let country = self.birthCountry.isEmpty ? "COUNTRY" : self.birthCountry.uppercased()
        locationLabel.text = "\(city), \(country)"
        
        print(city)
        print(country)
        
        // Show/hide the profile header based on whether this is a blueprint view
        profileHeaderView.isHidden = !isBlueprintView
        dividerView.isHidden = !isBlueprintView
    }
    
    // MARK: - Text Styling
    func setupTextViewStyling() {
        // Skip if text is empty
        guard let text = textView.text, !text.isEmpty else {
            print("⚠️ Cannot style empty text")
            return
        }
        
        print("Applying styling to text of length: \(text.count)")
        
        // Create a mutable attributed string
        let attributedText = NSMutableAttributedString()
        
        // Split the text into lines for processing
        let lines = text.components(separatedBy: "\n")
        var currentIndex = 0
        
        // Process each line to apply appropriate styling
        for (i, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let lineLength = line.count
            
            // Add newline for all but the first line
            if i > 0 {
                attributedText.append(NSAttributedString(string: "\n"))
            }
            
            // Check if line is empty
            if trimmedLine.isEmpty {
                continue
            }
            
            // SECTION HEADERS (e.g., "Essence", "Core", "Expression")
            if line.hasPrefix("# ") {
                // Main title (e.g., "Your Cosmic Blueprint")
                let titleText = String(line.dropFirst(2))
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                attributedText.append(NSAttributedString(string: titleText, attributes: titleAttributes))
                
            } else if line.hasPrefix("## ") {
                // Section header (e.g., "Essence", "Core")
                let headerText = String(line.dropFirst(3))
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                attributedText.append(NSAttributedString(string: headerText, attributes: headerAttributes))
                
            } else if line.hasSuffix(":") && line.components(separatedBy: " ").count == 1 {
                // Category headers (e.g., "Style Keywords:", "Nourishing Fabrics:")
                let categoryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]
                attributedText.append(NSAttributedString(string: line, attributes: categoryAttributes))
                
            } else if line == "---" {
                // Divider line
                let dividerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 6),
                    .foregroundColor: UIColor.gray
                ]
                attributedText.append(NSAttributedString(string: "　", attributes: dividerAttributes)) // Empty space with divider styling
                
            } else {
                // Regular body text
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                paragraphStyle.paragraphSpacing = 8
                
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraphStyle
                ]
                attributedText.append(NSAttributedString(string: line, attributes: bodyAttributes))
            }
            
            currentIndex += lineLength + 1 // +1 for the newline
        }
        
        // Apply the styled text
        textView.attributedText = attributedText
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
