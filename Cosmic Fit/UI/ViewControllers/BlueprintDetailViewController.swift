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
    
    // Interactive dismissal properties
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var initialTouchPoint: CGPoint = .zero
    private var interactiveDismissalInProgress = false
    
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
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
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
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = CosmicFitTheme.Colors.cosmicBlue
        button.contentHorizontalAlignment = .right
        return button
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        
        let attributedText = NSAttributedString(
            string: "YOUR COSMIC BLUEPRINT",
            attributes: [
                .font: CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.sectionHeader, weight: .bold),
                .foregroundColor: CosmicFitTheme.Colors.darkerCosmicGrey,
                .kern: 1.75
            ]
        )
        label.attributedText = attributedText
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
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
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
        
        setupUI()
        setupConstraints()
        setupActions()
        setupGestures()
        
        if let content = content {
            populateContent(content)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        view.backgroundColor = .clear
        
        view.addSubview(shadowContainerView)
        shadowContainerView.addSubview(cardContainerView)
        
        cardContainerView.addSubview(closeButton)
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
        closeButton.translatesAutoresizingMaskIntoConstraints = false
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
            // FIXED: Shadow Container now uses full view bounds since CardPresentationController handles tab bar spacing
            shadowContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height + 10),
            shadowContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor), // FIXED: No manual tab bar height subtraction
            
            // Card Container
            cardContainerView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            cardContainerView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor),
            
            // Close Button (right side)
            closeButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
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
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Top Divider
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
            
            // Bottom divider elements
            bottomDividerLeft.leadingAnchor.constraint(equalTo: bottomDividerContainer.leadingAnchor),
            bottomDividerLeft.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerLeft.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -10),
            bottomDividerLeft.heightAnchor.constraint(equalToConstant: 1),
            
            starImageView.centerXAnchor.constraint(equalTo: bottomDividerContainer.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 20),
            starImageView.heightAnchor.constraint(equalToConstant: 20),
            
            bottomDividerRight.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 10),
            bottomDividerRight.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerRight.trailingAnchor.constraint(equalTo: bottomDividerContainer.trailingAnchor),
            bottomDividerRight.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let touchPoint = gesture.location(in: view.window)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = touchPoint
            interactiveDismissalInProgress = true
            
        case .changed:
            if interactiveDismissalInProgress {
                let deltaY = touchPoint.y - initialTouchPoint.y
                if deltaY > 0 { // Only allow downward pan
                    let progress = min(deltaY / 200, 1.0)
                    view.transform = CGAffineTransform(translationX: 0, y: deltaY)
                    view.alpha = 1.0 - (progress * 0.3)
                }
            }
            
        case .ended, .cancelled:
            interactiveDismissalInProgress = false
            let deltaY = touchPoint.y - initialTouchPoint.y
            let shouldDismiss = deltaY > 100 || velocity.y > 500
            
            if shouldDismiss {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                    self.view.alpha = 0
                }) { _ in
                    self.dismiss(animated: false)
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.view.transform = .identity
                    self.view.alpha = 1.0
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Content Population
    private func populateContent(_ content: BlueprintDetailContent) {
        titleLabel.text = content.title
        iconImageView.image = UIImage(named: content.iconImageName)
        
        // Clear existing content
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add text sections
        for textSection in content.textSections {
            let sectionView = createTextSectionView(textSection)
            contentStackView.addArrangedSubview(sectionView)
        }
        
        // Add custom component if provided
        if let customComponent = content.customComponent {
            contentStackView.addArrangedSubview(customComponent)
        }
    }
    
    private func createTextSectionView(_ textSection: BlueprintDetailContent.TextSection) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        if let subheading = textSection.subheading {
            // Create subheading with dividers
            let subheadingContainer = createSubheadingWithDividers(subheading)
            containerView.addSubview(subheadingContainer)
            
            // Create body text
            let bodyLabel = UILabel()
            bodyLabel.text = textSection.bodyText
            bodyLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
            bodyLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
            bodyLabel.numberOfLines = 0
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(bodyLabel)
            
            NSLayoutConstraint.activate([
                subheadingContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
                subheadingContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                subheadingContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                
                bodyLabel.topAnchor.constraint(equalTo: subheadingContainer.bottomAnchor, constant: 20),
                bodyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                bodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bodyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        } else {
            // Just body text without subheading
            let bodyLabel = UILabel()
            bodyLabel.text = textSection.bodyText
            bodyLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
            bodyLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
            bodyLabel.numberOfLines = 0
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(bodyLabel)
            
            NSLayoutConstraint.activate([
                bodyLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                bodyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                bodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bodyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        return containerView
    }
    
    private func createSubheadingWithDividers(_ text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let leftDivider = UIView()
        leftDivider.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        leftDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .medium)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let rightDivider = UIView()
        rightDivider.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        rightDivider.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(leftDivider)
        containerView.addSubview(label)
        containerView.addSubview(rightDivider)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 30),
            
            leftDivider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),
            leftDivider.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -10),
            
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            rightDivider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
            rightDivider.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),
            rightDivider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        return containerView
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BlueprintDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
