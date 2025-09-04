//
//  BlueprintViewController.swift
//  Cosmic Fit
//
//  Created for production-ready Blueprint page
//

import UIKit

class BlueprintViewController: UIViewController {
    
    // MARK: - Properties
    var blueprintContent: String = ""
    var birthInfo: String = ""
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileHeaderView = UIView()
    private let profileLabel = UILabel()
    private let birthInfoLabel = UILabel()
    private let locationLabel = UILabel()
    private let dividerView = UIView()
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let debugButton = UIButton(type: .system)
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyCosmicFitTheme()
        populateContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar for this view
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupScrollView()
        setupProfileHeader()
        setupContent()
        setupConstraints()
    }
    
    private func setupScrollView() {
        CosmicFitTheme.styleScrollView(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupContent() {
        // Apply themed content background
        let contentBackgroundView = UIView()
        CosmicFitTheme.styleContentBackground(contentBackgroundView)
        contentBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentBackgroundView)
        
        // Title Label
        titleLabel.text = "Your Cosmic Blueprint"
        CosmicFitTheme.styleTitleLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Text View
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body)
        textView.textColor = CosmicFitTheme.Colors.cosmicBlue
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)
        
        // Debug Button
        debugButton.setTitle("Debug Chart", for: .normal)
        CosmicFitTheme.styleButton(debugButton, style: .text)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(debugButton)
        
        // Content background constraints
        NSLayoutConstraint.activate([
            contentBackgroundView.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 24),
            contentBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentBackgroundView.bottomAnchor.constraint(equalTo: debugButton.bottomAnchor, constant: 24)
        ])
        
        // Main content constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentBackgroundView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentBackgroundView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentBackgroundView.trailingAnchor, constant: -24),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            textView.leadingAnchor.constraint(equalTo: contentBackgroundView.leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: contentBackgroundView.trailingAnchor, constant: -24),
            
            debugButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 24),
            debugButton.centerXAnchor.constraint(equalTo: contentBackgroundView.centerXAnchor)
        ])
    }
    
    private func setupProfileHeader() {
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileHeaderView)
        
        // Profile Label
        profileLabel.text = "PROFILE"
        CosmicFitTheme.styleTitleLabel(profileLabel, fontSize: CosmicFitTheme.Typography.FontSizes.subheadline, weight: .medium)
        profileLabel.textAlignment = .left
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(profileLabel)
        
        // Birth Info Label
        CosmicFitTheme.styleBodyLabel(birthInfoLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        birthInfoLabel.textAlignment = .left
        birthInfoLabel.numberOfLines = 0
        birthInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(birthInfoLabel)
        
        // Location Label
        CosmicFitTheme.styleBodyLabel(locationLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        locationLabel.textAlignment = .left
        locationLabel.numberOfLines = 0
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(locationLabel)
        
        // Divider
        dividerView.backgroundColor = CosmicFitTheme.Colors.cosmicBlue.withAlphaComponent(0.3)
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.addSubview(dividerView)
        
        NSLayoutConstraint.activate([
            profileLabel.topAnchor.constraint(equalTo: profileHeaderView.topAnchor),
            profileLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: 24),
            profileLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -24),
            
            birthInfoLabel.topAnchor.constraint(equalTo: profileLabel.bottomAnchor, constant: 8),
            birthInfoLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: 24),
            birthInfoLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -24),
            
            locationLabel.topAnchor.constraint(equalTo: birthInfoLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: 24),
            locationLabel.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -24),
            
            dividerView.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 16),
            dividerView.leadingAnchor.constraint(equalTo: profileHeaderView.leadingAnchor, constant: 24),
            dividerView.trailingAnchor.constraint(equalTo: profileHeaderView.trailingAnchor, constant: -24),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            dividerView.bottomAnchor.constraint(equalTo: profileHeaderView.bottomAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile Header
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        
        // Set content view height constraint to be at least scroll view height for proper scrolling
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        contentHeightConstraint.priority = UILayoutPriority(250)
        contentHeightConstraint.isActive = true
    }
    
    // MARK: - Content Population
    private func populateContent() {
        // Set birth info
        birthInfoLabel.text = birthInfo.isEmpty ? "Birth information not available" : birthInfo
        
        // Set location (extracted from birth info if available)
        let locationText = extractLocationFromBirthInfo(birthInfo)
        locationLabel.text = locationText.isEmpty ? "Location not specified" : locationText
        
        // Set blueprint content
        textView.text = blueprintContent.isEmpty ? "Loading your cosmic blueprint..." : blueprintContent
    }
    
    private func extractLocationFromBirthInfo(_ info: String) -> String {
        // Extract location from birth info string
        // Format is typically: "Date Time at Location (Lat: xx, Long: yy)"
        let components = info.components(separatedBy: " at ")
        if components.count > 1 {
            let locationPart = components[1]
            let locationComponents = locationPart.components(separatedBy: " (")
            return locationComponents.first ?? ""
        }
        return ""
    }
    
    // MARK: - Actions
    @objc private func debugButtonTapped() {
        // This should be connected to show debug chart view
        print("Debug button tapped in Blueprint")
        
        // You can implement navigation to debug chart here
        // For example: navigationController?.pushViewController(debugViewController, animated: true)
    }
    
    // MARK: - Public Methods
    func updateContent(blueprint: String, birthInfo: String) {
        self.blueprintContent = blueprint
        self.birthInfo = birthInfo
        
        if isViewLoaded {
            populateContent()
        }
    }
}
