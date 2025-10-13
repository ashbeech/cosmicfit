//
//  BlueprintDetailViewController.swift
//  Cosmic Fit
//
//  Reusable template for all Blueprint detail pages (Style Core, Fabric Guide, Colour Guide, Do's & Don'ts)
//

import UIKit

// MARK: - Content Configuration
struct BlueprintDetailContent {
    let sectionType: BlueprintSection
    let title: String
    let iconImageName: String
    let textSections: [TextSection]
    let customComponent: UIView?
    
    struct TextSection {
        let subheading: String?  // Italic subheading with dividers (optional)
        let bodyText: String
    }
    
    enum BlueprintSection {
        case styleCore
        case fabricGuide
        case colourGuide
        case dosAndDonts
    }
}

// MARK: - BlueprintDetailViewController
final class BlueprintDetailViewController: UIViewController {
    
    // MARK: - Properties
    private var content: BlueprintDetailContent?
    private var birthDate: Date?
    private var birthCity: String = ""
    private var birthCountry: String = ""
    private var originalChartViewController: NatalChartViewController?
    
    // Store tab bar height for layout
    private var tabBarHeight: CGFloat = 0
    
    // MARK: - UI Components
    private let shadowContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.darkerCosmicGrey
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // Only round top corners
        view.clipsToBounds = true
        
        // Add 1px border around card
        view.layer.borderWidth = 1
        view.layer.borderColor = CosmicFitTheme.Colors.cosmicBlue.cgColor
        
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = CosmicFitTheme.Colors.cosmicBlue
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "YOUR COSMIC BLUEPRINT"
        label.font = UIFont(name: "DMSans-Bold", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .center
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "DMSerifText-Regular", size: 28) ?? UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 40
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let bottomDividerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let bottomDividerLeft: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    private let bottomDividerRight: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "star_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get tab bar height from presenting view controller
        if let presentingVC = presentingViewController,
           let tabBarController = presentingVC as? UITabBarController {
            tabBarHeight = tabBarController.tabBar.frame.height
        } else if let presentingVC = presentingViewController as? UINavigationController,
                  let tabBarController = presentingVC.tabBarController {
            tabBarHeight = tabBarController.tabBar.frame.height
        }
        
        setupUI()
        setupConstraints()
        setupActions()
        
        if let content = content {
            populateContent(content)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Add shadow path to shadow container (matches card shape)
        shadowContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: shadowContainerView.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 16, height: 16)
        ).cgPath
    }
    
    // MARK: - Configuration
    func configure(with content: BlueprintDetailContent) {
        self.content = content
        
        if isViewLoaded {
            populateContent(content)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear // Transparent to show Blueprint page behind
        
        // Add shadow container with gap at top
        view.addSubview(shadowContainerView)
        
        // Add card inside shadow container
        shadowContainerView.addSubview(cardContainerView)
        
        // Add all content inside the card
        cardContainerView.addSubview(backButton)
        cardContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(topDivider)
        contentView.addSubview(contentStackView)
        contentView.addSubview(bottomDividerContainer)
        
        bottomDividerContainer.addSubview(bottomDividerLeft)
        bottomDividerContainer.addSubview(bottomDividerRight)
        bottomDividerContainer.addSubview(starImageView)
    }
    
    private func setupConstraints() {
        shadowContainerView.translatesAutoresizingMaskIntoConstraints = false
        cardContainerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerLeft.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerRight.translatesAutoresizingMaskIntoConstraints = false
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Shadow Container - leaves 40px gap at top to show Blueprint page behind
            // and leaves space at bottom for tab bar
            shadowContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            shadowContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(tabBarHeight)),
            
            // Card Container - fills shadow container
            cardContainerView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            cardContainerView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor),
            
            // Back Button (inside card)
            backButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // ScrollView (inside card)
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header Label
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Icon - constrain height only, let width adjust to aspect ratio
            iconImageView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Top Divider (will be hidden for Fabric Guide)
            topDivider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            topDivider.heightAnchor.constraint(equalToConstant: 1),
            
            // Content Stack View - use topDivider as anchor (works even when hidden)
            contentStackView.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: 40),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Bottom Divider Container
            bottomDividerContainer.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 40),
            bottomDividerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bottomDividerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bottomDividerContainer.heightAnchor.constraint(equalToConstant: 30),
            bottomDividerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Bottom Divider Lines
            bottomDividerLeft.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerLeft.leadingAnchor.constraint(equalTo: bottomDividerContainer.leadingAnchor),
            bottomDividerLeft.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -10),
            bottomDividerLeft.heightAnchor.constraint(equalToConstant: 1),
            
            bottomDividerRight.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerRight.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 10),
            bottomDividerRight.trailingAnchor.constraint(equalTo: bottomDividerContainer.trailingAnchor),
            bottomDividerRight.heightAnchor.constraint(equalToConstant: 1),
            
            // Star Icon
            starImageView.centerXAnchor.constraint(equalTo: bottomDividerContainer.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 24),
            starImageView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Content Population
    private func populateContent(_ content: BlueprintDetailContent) {
        // Set icon and title
        iconImageView.image = UIImage(named: content.iconImageName)
        titleLabel.text = content.title
        
        // Hide top divider for Fabric Guide (uses first section divider instead)
        topDivider.isHidden = (content.sectionType == .fabricGuide)
        
        // Clear existing content
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add text sections
        for textSection in content.textSections {
            // Add subheading with dividers if present
            if let subheading = textSection.subheading {
                let subheadingContainer = createSubheadingWithDividers(text: subheading)
                contentStackView.addArrangedSubview(subheadingContainer)
            }
            
            // Add body text
            let bodyLabel = createBodyLabel(text: textSection.bodyText)
            contentStackView.addArrangedSubview(bodyLabel)
        }
        
        // Add custom component if present
        if let customComponent = content.customComponent {
            contentStackView.addArrangedSubview(customComponent)
        }
    }
    
    // MARK: - UI Factory Methods
    private func createSubheadingWithDividers(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let leftDivider = UIView()
        leftDivider.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        leftDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let rightDivider = UIView()
        rightDivider.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        rightDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "DMSerifText-Italic", size: 16) ?? UIFont.italicSystemFont(ofSize: 16)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(leftDivider)
        container.addSubview(rightDivider)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            // Container height
            container.heightAnchor.constraint(equalToConstant: 30),
            
            // Left divider
            leftDivider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftDivider.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),
            
            // Right divider
            rightDivider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            rightDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightDivider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),
            
            // Label
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        
        return container
    }
    
    private func createBodyLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "DMSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}
