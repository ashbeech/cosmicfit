//
//  BlueprintViewController.swift
//  Cosmic Fit
//
//  Created for production-ready Blueprint page
//

import UIKit

class BlueprintViewController: UIViewController {
    
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
    private let debugButton = UIButton(type: .system)
    
    private var interpretationText: String = ""
    private var birthDate: Date?
    private var birthCity: String = ""
    private var birthCountry: String = ""
    private var originalChartViewController: NatalChartViewController?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateContent()
    }
    
    // MARK: - Configuration
    func configure(with interpretationText: String,
                   birthDate: Date?,
                   birthCity: String,
                   birthCountry: String,
                   originalChartViewController: NatalChartViewController?) {
        
        self.interpretationText = interpretationText
        self.birthDate = birthDate
        self.birthCity = birthCity
        self.birthCountry = birthCountry
        self.originalChartViewController = originalChartViewController
        
        if isViewLoaded {
            updateContent()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        title = "Blueprint"
        
        // Navigation bar configuration
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
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
        
        // Setup Profile Header
        setupProfileHeader()
        
        // Title label
        titleLabel.text = "Your Cosmic Fit Blueprint"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Create text view for interpretation
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .white
        textView.backgroundColor = .black
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        contentView.addSubview(textView)
        
        // Debug button
        debugButton.setTitle("Debug Chart", for: .normal)
        debugButton.setTitleColor(.systemBlue, for: .normal)
        debugButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(debugButton)
        
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
            
            // TextView fills contentView below title
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Debug button at bottom
            debugButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 24),
            debugButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            debugButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
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
    
    private func updateContent() {
        // Set the interpretation text
        textView.text = interpretationText
        
        // Apply styling
        setupTextViewStyling()
        
        // Update profile header
        updateProfileHeader()
    }
    
    private func updateProfileHeader() {
        // Format birth date if available
        if let date = birthDate {
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
        
        // Set location
        let city = birthCity.isEmpty ? "CITY" : birthCity.uppercased()
        let country = birthCountry.isEmpty ? "COUNTRY" : birthCountry.uppercased()
        locationLabel.text = "\(city), \(country)"
    }
    
    // MARK: - Text Styling
    private func setupTextViewStyling() {
        guard let text = textView.text, !text.isEmpty else {
            print("⚠️ Cannot style empty text")
            return
        }
        
        print("Applying styling to Blueprint text of length: \(text.count)")
        
        let attributedText = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        
        for (i, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if i > 0 {
                attributedText.append(NSAttributedString(string: "\n"))
            }
            
            if trimmedLine.isEmpty {
                continue
            }
            
            // SECTION HEADERS
            if line.hasPrefix("# ") {
                // Main title
                let titleText = String(line.dropFirst(2))
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                attributedText.append(NSAttributedString(string: titleText, attributes: titleAttributes))
                
            } else if line.hasPrefix("## ") {
                // Section header
                let headerText = String(line.dropFirst(3))
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                attributedText.append(NSAttributedString(string: headerText, attributes: headerAttributes))
                
            } else if line.hasSuffix(":") && line.components(separatedBy: " ").count == 1 {
                // Category headers
                let categoryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]
                attributedText.append(NSAttributedString(string: line, attributes: categoryAttributes))
                
            } else if line == "---" {
                // Divider line - add spacing
                let dividerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 6),
                    .foregroundColor: UIColor.gray
                ]
                attributedText.append(NSAttributedString(string: "　", attributes: dividerAttributes))
                
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
        }
        
        textView.attributedText = attributedText
    }
    
    // MARK: - Actions
    @objc private func debugButtonTapped() {
        guard let originalChartVC = originalChartViewController else {
            print("❌ No original chart view controller available")
            return
        }
        
        navigationController?.pushViewController(originalChartVC, animated: true)
    }
    
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
