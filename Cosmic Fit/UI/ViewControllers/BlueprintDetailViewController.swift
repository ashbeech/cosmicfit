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
    
    private var tabBarHeight: CGFloat = 0
    
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
        label.text = "YOUR COSMIC BLUEPRINT"
        label.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.sectionHeader, weight: .bold)
        label.textColor = CosmicFitTheme.Colors.darkerCosmicGrey
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
        
        // Get tab bar height
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
            // Shadow Container - stops below menu bar (under safe area)
            shadowContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height),
            shadowContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(tabBarHeight)),
            
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
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Content Population
    private func populateContent(_ content: BlueprintDetailContent) {
        iconImageView.image = UIImage(named: content.iconImageName)
        titleLabel.text = content.title
        
        topDivider.isHidden = (content.sectionType == .fabricGuide)
        
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for textSection in content.textSections {
            if let subheading = textSection.subheading {
                let subheadingContainer = createSubheadingWithDividers(text: subheading)
                contentStackView.addArrangedSubview(subheadingContainer)
            }
            
            let bodyLabel = createBodyLabel(text: textSection.bodyText)
            contentStackView.addArrangedSubview(bodyLabel)
        }
        
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
            container.heightAnchor.constraint(equalToConstant: 30),
            
            leftDivider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftDivider.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),
            
            rightDivider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            rightDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightDivider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        
        return container
    }
    
    private func createBodyLabel(text: String) -> UIView {
        // Create container for padding
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the label
        let label = UILabel()
        label.text = text
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        // Add 10% screen width padding on each side
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Gesture Handling
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let progress = translation.y / view.bounds.height
        
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: view)
            interactiveDismissalInProgress = true
            
        case .changed:
            // Only allow downward drags
            guard translation.y > 0 else {
                shadowContainerView.transform = .identity
                return
            }
            
            // Apply the drag with damping for a natural feel
            let dampingFactor: CGFloat = 0.5
            let dragDistance = translation.y * dampingFactor
            shadowContainerView.transform = CGAffineTransform(translationX: 0, y: dragDistance)
            
        case .ended, .cancelled:
            interactiveDismissalInProgress = false
            
            // Dismiss if dragged down significantly OR with high downward velocity
            let shouldDismiss = (progress > 0.3 || velocity.y > 800) && translation.y > 0
            
            if shouldDismiss {
                animateDismissal(with: velocity.y)
            } else {
                // Snap back to original position
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: [.curveEaseOut, .allowUserInteraction],
                    animations: {
                        self.shadowContainerView.transform = .identity
                    }
                )
            }
            
        default:
            break
        }
    }
    
    private func animateDismissal(with velocity: CGFloat) {
        let screenHeight = view.bounds.height
        let remainingDistance = screenHeight - shadowContainerView.frame.origin.y
        
        // Calculate duration based on velocity for natural feel
        let minimumDuration: TimeInterval = 0.2
        let velocityBasedDuration = TimeInterval(remainingDistance / max(velocity, 500))
        let duration = max(minimumDuration, min(velocityBasedDuration, 0.4))
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction],
            animations: {
                self.shadowContainerView.transform = CGAffineTransform(translationX: 0, y: screenHeight)
                self.view.backgroundColor = .clear
            },
            completion: { _ in
                self.dismiss(animated: false)
            }
        )
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BlueprintDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan gesture to work with scroll view
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            // Only allow simultaneous recognition when scrolled to top
            return scrollView.contentOffset.y <= 0
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return true }
        
        let velocity = panGestureRecognizer.velocity(in: view)
        
        // Only recognize downward swipes
        guard velocity.y > 0 else { return false }
        
        // Only recognize if scroll view is at top
        if scrollView.contentOffset.y > 0 {
            return false
        }
        
        // Require more vertical than horizontal movement (at least 2:1 ratio)
        return abs(velocity.y) > abs(velocity.x) * 2
    }
}
