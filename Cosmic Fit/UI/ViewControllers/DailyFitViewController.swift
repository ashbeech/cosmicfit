//
//  DailyFitViewController.swift
//  Cosmic Fit
//
//  Created for production-ready Daily Fit page with tarot card scroll animation
//

import UIKit
import CoreImage

class DailyFitViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let topMaskView = UIView()
    
    // Tarot card header
    private let tarotCardImageView = UIImageView()
    private let cardTitleLabel = UILabel()
    private let scrollIndicatorView = UIView()
    private let scrollArrowLabel = UILabel()
    
    // Content views
    private let keywordsLabel = UILabel()
    private let styleBriefLabel = UILabel()
    private let textilesLabel = UILabel()
    private let colorsLabel = UILabel()
    private let patternsLabel = UILabel()
    private let shapeLabel = UILabel()
    private let accessoriesLabel = UILabel()
    private let layeringLabel = UILabel()
    private let vibeBreakdownLabel = UILabel()
    private let debugButton = UIButton(type: .system)
    
    // Animation properties
    private var initialScrollViewTopConstraint: NSLayoutConstraint?
    private var originalCardImage: UIImage? // Store original unblurred image
    private var ciContext: CIContext? // Reuse CI context for better performance
    
    // Data
    private var dailyVibeContent: DailyVibeContent?
    private var originalChartViewController: NatalChartViewController?
    
    // MARK: - Card Reveal Properties
    
    // Card reveal state management
    private var isCardRevealed = false
    private var cardBackImageView = UIImageView()
    private var tapToRevealLabel = UILabel()
    private var backgroundBlurImageView = UIImageView()
    private var cardTapGesture: UITapGestureRecognizer?
    
    private let tarotCardContainerView = UIView()
    private var cardContainerCenterYConstraint: NSLayoutConstraint?
    private var cardContainerWidthConstraint: NSLayoutConstraint?
    private var cardContainerHeightConstraint: NSLayoutConstraint?
    
    private let scrollingRunesBackground = ScrollingRunesBackgroundView()
    
    private var hasPerformedInitialLayout = false
    
    // Card state enum for better state management
    private enum CardState {
        case unrevealed
        case revealing
        case revealed
    }
    private var currentCardState: CardState = .unrevealed
    
    // Card reveal key for UserDefaults (per day)
    private var dailyCardRevealKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "CardRevealed_\(dateFormatter.string(from: Date()))"
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply Cosmic Fit theme
        applyCosmicFitTheme()
        
        setupUI()
        updateContent()
        
        // Set initial content alpha to 0 for scroll-based fade-in
        setInitialContentAlpha()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Restore card state when returning from other tabs
        checkCardRevealState()
        
        if isCardRevealed {
            // Ensure container is properly positioned and visible
            tarotCardContainerView.alpha = 1.0
            tarotCardContainerView.transform = .identity
            tarotCardImageView.alpha = 1.0
            
            view.layoutIfNeeded()
            
            print("Card container and content restored on tab return")
        }
        
        // CRITICAL: Ensure topMaskView stays above scroll content
        view.bringSubviewToFront(topMaskView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scrollingRunesBackground.stopAnimating()
    }
    
    // MARK: - Memory Management
    deinit {
        // Clean up Core Image context
        ciContext = nil
        
        // Remove layer filters to prevent memory leaks
        cardBackImageView.layer.filters = nil
        
        // Remove tap gesture
        if let gesture = cardTapGesture {
            cardBackImageView.removeGestureRecognizer(gesture)
        }
        
        // Stop any ongoing animations
        scrollingRunesBackground.stopAnimating()
        
        print("DailyFitViewController deinitialized - memory cleaned up")
    }
    
    // MARK: - Configuration
    func configure(with dailyVibeContent: DailyVibeContent,
                   originalChartViewController: NatalChartViewController?) {
        
        self.dailyVibeContent = dailyVibeContent
        self.originalChartViewController = originalChartViewController
        
        if isViewLoaded {
            updateContent()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        
        // Always start with black background
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        
        // ADD FULL-SCREEN SCROLLING RUNES BACKGROUND HERE - behind everything
        scrollingRunesBackground.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(scrollingRunesBackground, at: 0) // Insert at bottom of view hierarchy
        
        // Make it fill the ENTIRE screen (same as intro screen)
        NSLayoutConstraint.activate([
            scrollingRunesBackground.topAnchor.constraint(equalTo: view.topAnchor),
            scrollingRunesBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollingRunesBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollingRunesBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Hide navigation bar completely
        //navigationController?.navigationBar.isHidden = true
        
        // Setup background blur image view (behind everything) - will show blurred tarot card as background
        setupBackgroundBlur()
        
        // ADDITIONAL: Ensure no black shows through during any state
        view.backgroundColor = UIColor(red: 31/255, green: 25/255, blue: 61/255, alpha: 1.0) // Dark purple fallback instead of pure black
        
        // Setup scroll view with delegate for animation (PRESERVE existing scroll system)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isScrollEnabled = false // Initially disabled until card is revealed
        
        // Apply theme to scroll view
        CosmicFitTheme.styleScrollView(scrollView)
        
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // ScrollView starts from very top so card can extend all the way up
        initialScrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
        initialScrollViewTopConstraint?.isActive = true

        // Clip scrollView at menu bar level
        scrollView.clipsToBounds = true

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView starts with padding for menu bar + safe area
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: view.safeAreaInsets.top + 83),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Add cosmic grey mask above menu bar
        topMaskView.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        topMaskView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topMaskView)

        NSLayoutConstraint.activate([
            topMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            topMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topMaskView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height - 10)
        ])
        
        setupTarotCardHeader()
        setupCardRevealUI() // New method - adds card back and reveal functionality
        setupContentLabels()
        setupConstraints()
        
        // Check if card was already revealed today
        checkCardRevealState()
        
        view.bringSubviewToFront(topMaskView)
    }
    
    // MARK: - Card Reveal Setup Methods

    // Setup background blur image view (behind everything) - will show blurred tarot card as background
    private func setupBackgroundBlur() {
        backgroundBlurImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundBlurImageView.contentMode = .scaleAspectFill
        backgroundBlurImageView.clipsToBounds = true
        backgroundBlurImageView.alpha = 0.0 // Initially hidden
        
        // CRITICAL: Add to main view (not contentView) to ensure it's behind everything
        view.insertSubview(backgroundBlurImageView, at: 0) // Insert at bottom of view hierarchy
        
        // EXTENDED constraints - background extends beyond screen bounds to cover scroll area
        let extraHeight: CGFloat = 200 // Extra height above and below to cover scroll transforms
        
        NSLayoutConstraint.activate([
            backgroundBlurImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: -extraHeight),
            backgroundBlurImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: extraHeight)
        ])
        
        print("Background blur image view setup with extended bounds to cover scroll area")
    }
    
    // MARK: - Card Reveal UI Setup
    private func setupCardRevealUI() {
        // All unrevealed state elements go into the SAME container
        
        // UNREVEALED STATE: Card back image
        cardBackImageView.translatesAutoresizingMaskIntoConstraints = false
        cardBackImageView.contentMode = .scaleAspectFit
        cardBackImageView.clipsToBounds = false
        cardBackImageView.image = UIImage(named: "CardBacks")
        cardBackImageView.layer.cornerRadius = 24
        cardBackImageView.isUserInteractionEnabled = true
        
        // Glow effect for card back
        cardBackImageView.layer.shadowColor = CosmicFitTheme.Colors.cosmicLilac.cgColor
        cardBackImageView.layer.shadowOffset = CGSize.zero
        cardBackImageView.layer.shadowRadius = 100
        cardBackImageView.layer.shadowOpacity = 0.4
        cardBackImageView.layer.masksToBounds = false
        
        tarotCardContainerView.addSubview(cardBackImageView)
        
        // UNREVEALED STATE: Tap to reveal label
        tapToRevealLabel.translatesAutoresizingMaskIntoConstraints = false
        tapToRevealLabel.text = "Tap to reveal today's fit"
        
        // Apply theme to tap to reveal label
        CosmicFitTheme.styleBodyLabel(tapToRevealLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .medium)
        tapToRevealLabel.textAlignment = .center
        tapToRevealLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        tapToRevealLabel.layer.cornerRadius = 8
        tapToRevealLabel.clipsToBounds = true
        tapToRevealLabel.numberOfLines = 2
        
        tarotCardContainerView.addSubview(tapToRevealLabel)
        
        // Add tap gesture to card back
        cardTapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardBackImageView.addGestureRecognizer(cardTapGesture!)
        
        // CRITICAL: Card back EXACTLY overlays revealed card (1:1 same size and position)
        NSLayoutConstraint.activate([
            // Card back fills entire container, same as revealed card
            cardBackImageView.topAnchor.constraint(equalTo: tarotCardContainerView.topAnchor),
            cardBackImageView.leadingAnchor.constraint(equalTo: tarotCardContainerView.leadingAnchor),
            cardBackImageView.trailingAnchor.constraint(equalTo: tarotCardContainerView.trailingAnchor),
            cardBackImageView.bottomAnchor.constraint(equalTo: tarotCardContainerView.bottomAnchor),
            
            // Tap label centered on card back
            tapToRevealLabel.centerXAnchor.constraint(equalTo: cardBackImageView.centerXAnchor),
            tapToRevealLabel.centerYAnchor.constraint(equalTo: cardBackImageView.centerYAnchor),
            tapToRevealLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardBackImageView.leadingAnchor, constant: 20),
            tapToRevealLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardBackImageView.trailingAnchor, constant: -20),
            tapToRevealLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    // MARK: - Unified state management methods
    private func setCardState(_ state: CardState, animated: Bool = true) {
        guard state != currentCardState else { return }
        currentCardState = state
        
        switch state {
        case .unrevealed:
            showUnrevealedState(animated: animated)
        case .revealing:
            // Handle revealing animation state if needed
            break
        case .revealed:
            showRevealedStateUnified(animated: animated)
        }
    }
    
    private func showUnrevealedState(animated: Bool) {
        let applyChanges = {
            // Show unrevealed elements
            self.cardBackImageView.alpha = 1.0
            self.cardBackImageView.isHidden = false
            self.tapToRevealLabel.alpha = 1.0
            self.tapToRevealLabel.isHidden = false
            self.scrollingRunesBackground.alpha = 1.0
            
            // Hide revealed elements
            self.tarotCardImageView.alpha = 0.0
            self.cardTitleLabel.alpha = 0.0
            self.backgroundBlurImageView.alpha = 0.0
            self.scrollIndicatorView.alpha = 0.0
            
            // Hide content
            let labels = [self.keywordsLabel, self.styleBriefLabel, self.textilesLabel,
                          self.colorsLabel, self.patternsLabel, self.shapeLabel,
                          self.accessoriesLabel, self.layeringLabel, self.vibeBreakdownLabel,
                          self.debugButton]
            labels.forEach { $0.alpha = 0.0 }
            
            // Ensure container visible
            self.tarotCardContainerView.alpha = 1.0
            self.tarotCardContainerView.transform = .identity
            
            // Disable scrolling
            self.scrollView.isScrollEnabled = false
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: applyChanges)
        } else {
            applyChanges()
        }
        
        // Start runes after state change
        scrollingRunesBackground.startAnimating()
        view.backgroundColor = .black
    }
    
    private func showRevealedStateUnified(animated: Bool) {
        // Stop the runes animation
        scrollingRunesBackground.stopAnimating()
        
        let applyChanges = {
            // Hide unrevealed elements
            self.cardBackImageView.alpha = 0.0
            self.cardBackImageView.isHidden = true
            self.tapToRevealLabel.alpha = 0.0
            self.tapToRevealLabel.isHidden = true
            self.scrollingRunesBackground.alpha = 0.0
            
            // Show revealed elements
            self.tarotCardImageView.alpha = 1.0
            self.cardTitleLabel.alpha = 1.0
            self.backgroundBlurImageView.alpha = 1.0
            self.scrollIndicatorView.alpha = 1.0
            self.scrollIndicatorView.isHidden = false
            
            // Show all content
            let labels = [self.keywordsLabel, self.styleBriefLabel, self.textilesLabel,
                          self.colorsLabel, self.patternsLabel, self.shapeLabel,
                          self.accessoriesLabel, self.layeringLabel, self.vibeBreakdownLabel,
                          self.debugButton]
            labels.forEach { $0.alpha = 1.0 }
            
            // Enable scrolling
            self.scrollView.isScrollEnabled = true
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, animations: applyChanges) { _ in
                self.setupContentSectionBackgrounds()
                self.ensureContainerVisibility()
            }
        } else {
            applyChanges()
            setupContentSectionBackgrounds()
            ensureContainerVisibility()
            view.layoutIfNeeded()
        }
    }
    
    // Helper to ensure container is visible
    private func ensureContainerVisibility() {
        tarotCardContainerView.alpha = 1.0
        tarotCardContainerView.isHidden = false
        contentView.sendSubviewToBack(tarotCardContainerView)
    }
    
    private func checkCardRevealState() {
        isCardRevealed = UserDefaults.standard.bool(forKey: dailyCardRevealKey)
        
        if isCardRevealed {
            setCardState(.revealed, animated: false)
        } else {
            setCardState(.unrevealed, animated: false)
        }
    }
    
    // MARK: - Tarot Card Header Setup
    private func setupTarotCardHeader() {
        // Create unified container for card visual elements only (not title)
        tarotCardContainerView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardContainerView.clipsToBounds = false
        tarotCardContainerView.backgroundColor = .clear
        contentView.addSubview(tarotCardContainerView)
        
        // Calculate card dimensions with padding around it
        let cardAspectRatio: CGFloat = 0.62
        let horizontalPadding: CGFloat = 33
        let cardWidth = view.bounds.width - (horizontalPadding * 2) // Reduce width by total padding
        let cardHeight = cardWidth / cardAspectRatio

        // Container is exactly card size (now smaller)
        cardContainerWidthConstraint = tarotCardContainerView.widthAnchor.constraint(equalToConstant: cardWidth)
        cardContainerHeightConstraint = tarotCardContainerView.heightAnchor.constraint(equalToConstant: cardHeight)
        
        // IMPROVED POSITIONING - Calculate actual available space between menu bar and tab bar
        let menuBarBottom = calculateMenuBarBottom()
        let tabBarTop = calculateTabBarTop()
        let availableHeight = tabBarTop - menuBarBottom
        let centerY = menuBarBottom + (availableHeight / 2) - 10
        
        // Position card so its center is at the calculated center point
        let cardCenterYFromContentTop = centerY - view.safeAreaInsets.top
        let cardBottomFromContentTop = cardCenterYFromContentTop + (cardHeight / 2)
        
        // Use original bottomAnchor constraint for proper scroll behavior
        cardContainerCenterYConstraint = tarotCardContainerView.bottomAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: cardBottomFromContentTop
        )
        
        // Activate positioning constraints
        cardContainerCenterYConstraint?.isActive = true
        cardContainerWidthConstraint?.isActive = true
        cardContainerHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            tarotCardContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        // Setup the actual tarot card image view (revealed state)
        tarotCardImageView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardImageView.contentMode = .scaleAspectFit
        tarotCardImageView.clipsToBounds = true
        tarotCardImageView.backgroundColor = CosmicFitTheme.Colors.cosmicLilac // Themed placeholder
        tarotCardImageView.layer.cornerRadius = 24
        tarotCardImageView.alpha = 0.0
        tarotCardContainerView.addSubview(tarotCardImageView)
        
        NSLayoutConstraint.activate([
            tarotCardImageView.topAnchor.constraint(equalTo: tarotCardContainerView.topAnchor),
            tarotCardImageView.leadingAnchor.constraint(equalTo: tarotCardContainerView.leadingAnchor),
            tarotCardImageView.trailingAnchor.constraint(equalTo: tarotCardContainerView.trailingAnchor),
            tarotCardImageView.bottomAnchor.constraint(equalTo: tarotCardContainerView.bottomAnchor),
        ])
        
        // Card back (unrevealed state) - same size as revealed card
        cardBackImageView.translatesAutoresizingMaskIntoConstraints = false
        cardBackImageView.contentMode = .scaleAspectFit
        cardBackImageView.clipsToBounds = false
        cardBackImageView.layer.cornerRadius = 24
        cardBackImageView.alpha = 1.0
        cardBackImageView.isUserInteractionEnabled = true
        tarotCardContainerView.addSubview(cardBackImageView)
        
        // Start the runes animation
        scrollingRunesBackground.startAnimating()
        
        // Tap to reveal label
        tapToRevealLabel.translatesAutoresizingMaskIntoConstraints = false
        tapToRevealLabel.text = "Tap to turn the card" // Updated text to match the UI
        tapToRevealLabel.textAlignment = .center
        
        // Apply theme to tap to reveal label
        CosmicFitTheme.styleBodyLabel(tapToRevealLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .medium)
        tapToRevealLabel.textColor = .white // Override for visibility on dark card back
        
        tapToRevealLabel.numberOfLines = 2
        tapToRevealLabel.alpha = 1.0
        cardBackImageView.addSubview(tapToRevealLabel)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardBackImageView.addGestureRecognizer(tapGesture)
        
        // CRITICAL: Card back EXACTLY overlays revealed card (1:1 same size and position)
        NSLayoutConstraint.activate([
            // Card back fills entire container, same as revealed card
            cardBackImageView.topAnchor.constraint(equalTo: tarotCardContainerView.topAnchor),
            cardBackImageView.leadingAnchor.constraint(equalTo: tarotCardContainerView.leadingAnchor),
            cardBackImageView.trailingAnchor.constraint(equalTo: tarotCardContainerView.trailingAnchor),
            cardBackImageView.bottomAnchor.constraint(equalTo: tarotCardContainerView.bottomAnchor),
            
            // Tap label centered on card back
            tapToRevealLabel.centerXAnchor.constraint(equalTo: cardBackImageView.centerXAnchor),
            tapToRevealLabel.centerYAnchor.constraint(equalTo: cardBackImageView.centerYAnchor),
            tapToRevealLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardBackImageView.leadingAnchor, constant: 20),
            tapToRevealLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardBackImageView.trailingAnchor, constant: -20),
            tapToRevealLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    private func calculateMenuBarBottom() -> CGFloat {
        // Menu bar positioning from CosmicFitTabBarController:
        // menuBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10)
        return view.safeAreaInsets.top + MenuBarView.height - 10
    }

    private func calculateTabBarTop() -> CGFloat {
        // Get actual tab bar height dynamically
        let actualTabBarHeight = getActualTabBarHeight()
        
        // Tab bar top is at: total height - bottom safe area - tab bar height
        return view.bounds.height - view.safeAreaInsets.bottom - actualTabBarHeight
    }

    private func getActualTabBarHeight() -> CGFloat {
        // Try to get the actual tab bar height from the tab bar controller
        if let tabBarController = tabBarController {
            // If the tab bar has been laid out, use its actual frame
            if tabBarController.tabBar.frame.height > 0 {
                return tabBarController.tabBar.frame.height
            }
        }
        
        // Fallback calculation based on safe area
        // Modern iPhones: 49pt tab bar + 34pt home indicator = 83pt total
        // Older iPhones: 49pt tab bar + 0pt = 49pt total
        let hasHomeIndicator = view.safeAreaInsets.bottom > 0
        return hasHomeIndicator ? 83 : 49
    }

    private func updateTarotCardPositioning() {
        // Recalculate positioning after layout changes (rotation, device changes)
        guard let constraint = cardContainerCenterYConstraint,
              let heightConstraint = cardContainerHeightConstraint else { return }
        
        let menuBarBottom = calculateMenuBarBottom()
        let tabBarTop = calculateTabBarTop()
        let availableHeight = tabBarTop - menuBarBottom
        let centerY = menuBarBottom + (availableHeight / 2)
        
        // Update the constraint constant
        let cardHeight = heightConstraint.constant
        let cardCenterYFromContentTop = centerY - view.safeAreaInsets.top
        let cardBottomFromContentTop = cardCenterYFromContentTop + (cardHeight / 2)
        
        constraint.constant = cardBottomFromContentTop
    }

    // MARK: - Add this to your existing viewDidLayoutSubviews method:
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update tarot card positioning after layout changes
        updateTarotCardPositioning()
        
        // CRITICAL: Only start runes animation after the first layout is complete
        if !hasPerformedInitialLayout {
            hasPerformedInitialLayout = true
            
            // Start runes animation if in unrevealed state
            if !isCardRevealed && currentCardState == .unrevealed {
                // Force layout completion, then start animation
                view.layoutIfNeeded()
                scrollingRunesBackground.startAnimating()
                print("🎯 Initial layout completed - starting runes animation")
            }
        }
    }
    
    private func setupScrollIndicator() {
        // Scroll indicator container
        scrollIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        scrollIndicatorView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        scrollIndicatorView.layer.cornerRadius = 20
        contentView.addSubview(scrollIndicatorView)
        
        // Scroll arrow
        scrollArrowLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollArrowLabel.text = "↑"
        
        // Apply theme to scroll arrow
        CosmicFitTheme.styleBodyLabel(scrollArrowLabel, fontSize: 20, weight: .bold)
        scrollArrowLabel.textColor = .white // Override for visibility
        scrollArrowLabel.textAlignment = .center
        
        scrollIndicatorView.addSubview(scrollArrowLabel)
        
        NSLayoutConstraint.activate([
            scrollIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollIndicatorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            scrollIndicatorView.widthAnchor.constraint(equalToConstant: 40),
            scrollIndicatorView.heightAnchor.constraint(equalToConstant: 40),
            
            scrollArrowLabel.centerXAnchor.constraint(equalTo: scrollIndicatorView.centerXAnchor),
            scrollArrowLabel.centerYAnchor.constraint(equalTo: scrollIndicatorView.centerYAnchor)
        ])
        
        // Add pulsing animation to scroll indicator
        addPulsingAnimation()
    }
    
    private func addPulsingAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        scrollIndicatorView.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func setupContentLabels() {
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                      patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                      vibeBreakdownLabel]
        
        for label in labels {
            label.translatesAutoresizingMaskIntoConstraints = false
            
            // Apply theme body label styling
            CosmicFitTheme.styleBodyLabel(label, fontSize: CosmicFitTheme.Typography.FontSizes.body)
            
            label.backgroundColor = .clear // No individual backgrounds
            label.numberOfLines = 0
            label.alpha = 0.0 // Initially invisible, fades in during scroll
            contentView.addSubview(label)
        }
        
        // Debug button
        debugButton.setTitle("Debug Chart", for: .normal)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to debug button
        CosmicFitTheme.styleButton(debugButton, style: .secondary)
        
        debugButton.alpha = 0.0 // Initially invisible, fades in during scroll
        contentView.addSubview(debugButton)
        
        print("Content labels set up with Cosmic Fit theme styling")
    }
    
    // MARK: - UI Setup Constraints (setupConstraints method)
    private func setupConstraints() {
        let screenHeight = view.bounds.height
        let tabBarHeight: CGFloat = 83
        
        // CRITICAL: Position content box at HALF the previous distance above tab bar
        let contentStartFromBottom = screenHeight - tabBarHeight - 75 // Half of previous 30pt = 15pt above tab bar
        
        // Card title label - NOW IN CONTENT AREA, NOT IN CONTAINER
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to card title
        CosmicFitTheme.styleTitleLabel(cardTitleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .semibold)
        
        cardTitleLabel.textAlignment = .center
        cardTitleLabel.numberOfLines = 2
        cardTitleLabel.alpha = 0.0
        contentView.addSubview(cardTitleLabel) // Add to contentView as content header
        
        NSLayoutConstraint.activate([
            
            // CRITICAL FIX: Position title even lower (15pt above tab bar instead of 30pt)
            cardTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentStartFromBottom),
            cardTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            cardTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            cardTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Content labels - positioned INSIDE content box starting right after title
            keywordsLabel.topAnchor.constraint(equalTo: cardTitleLabel.bottomAnchor, constant: 20),
            keywordsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            keywordsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            styleBriefLabel.topAnchor.constraint(equalTo: keywordsLabel.bottomAnchor, constant: 24),
            styleBriefLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            styleBriefLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            textilesLabel.topAnchor.constraint(equalTo: styleBriefLabel.bottomAnchor, constant: 24),
            textilesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            textilesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            colorsLabel.topAnchor.constraint(equalTo: textilesLabel.bottomAnchor, constant: 24),
            colorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            colorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            patternsLabel.topAnchor.constraint(equalTo: colorsLabel.bottomAnchor, constant: 24),
            patternsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            patternsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            shapeLabel.topAnchor.constraint(equalTo: patternsLabel.bottomAnchor, constant: 24),
            shapeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            shapeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            accessoriesLabel.topAnchor.constraint(equalTo: shapeLabel.bottomAnchor, constant: 24),
            accessoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            accessoriesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            layeringLabel.topAnchor.constraint(equalTo: accessoriesLabel.bottomAnchor, constant: 24),
            layeringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            layeringLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            vibeBreakdownLabel.topAnchor.constraint(equalTo: layeringLabel.bottomAnchor, constant: 24),
            vibeBreakdownLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            vibeBreakdownLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // CRITICAL FIX: Proper scroll end - content should end with space above tab bar (not below it)
            debugButton.topAnchor.constraint(equalTo: vibeBreakdownLabel.bottomAnchor, constant: 40),
            debugButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            debugButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50) // Stop well above tab bar
        ])
    }
    
    private func updateContent() {
        guard let content = dailyVibeContent else { return }
        
        // Load tarot card image
        loadTarotCardImage(for: content.tarotCard)
        
        // Set card title (now in content area as header)
        let cardName = content.tarotCard?.displayName ?? "Daily Energy"
        cardTitleLabel.text = cardName
        
        // Update content labels using theme methods
        let keywordsText = content.tarotKeywords.isEmpty ? "Intuitive guidance" : content.tarotKeywords
        keywordsLabel.attributedText = createThemedStyledText(title: "Keywords", content: keywordsText)
        
        styleBriefLabel.attributedText = createThemedStyledText(title: "Style Brief", content: content.styleBrief)
        textilesLabel.attributedText = createThemedStyledText(title: "Textiles", content: content.textiles)
        colorsLabel.attributedText = createThemedStyledText(title: "Colors", content: content.colors)
        patternsLabel.attributedText = createThemedStyledText(title: "Patterns", content: content.patterns)
        shapeLabel.attributedText = createThemedStyledText(title: "Shape", content: content.shape)
        accessoriesLabel.attributedText = createThemedStyledText(title: "Accessories", content: content.accessories)
        layeringLabel.attributedText = createThemedStyledText(title: "Layering", content: content.layering)
        vibeBreakdownLabel.attributedText = createThemedVibeBreakdownText(vibeBreakdown: content.vibeBreakdown)
        
        print("Content updated with theme styling - card title is content header")
    }
    
    private func loadTarotCardImage(for tarotCard: TarotCard?) {
        guard let tarotCard = tarotCard else {
            print("⚠️ No tarot card provided for image loading")
            return
        }
        
        print("🔍 Attempting to load image: \(tarotCard.imagePath)")
        
        let imageName = tarotCard.imagePath.replacingOccurrences(of: "Cards/", with: "")
        
        if let image = UIImage(named: imageName) {
            tarotCardImageView.image = image
            originalCardImage = image
            
            // Create blurred background version for the full-screen background
            createBlurredBackground(from: image)
            
            // Initialize CI context for better blur performance
            if ciContext == nil {
                ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
            }
            
            tarotCardImageView.backgroundColor = .clear
            tarotCardImageView.contentMode = .scaleAspectFit
            tarotCardImageView.clipsToBounds = true
            print("✅ Successfully loaded tarot card image: \(tarotCard.imagePath)")
        } else {
            print("❌ Could not load image: \(tarotCard.imagePath)")
            setupFallbackCardDisplay(for: tarotCard)
        }
    }
    
    private func createBlurredBackground(from image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return
        }
        
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(5.0, forKey: kCIInputRadiusKey) // Strong blur for background
        
        guard let outputImage = blurFilter?.outputImage else {
            print("Failed to create blurred output image")
            return
        }
        
        // Ensure we have a context
        if ciContext == nil {
            ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        }
        
        guard let context = ciContext,
              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            print("Failed to create CGImage from blurred output")
            return
        }
        
        let blurredUIImage = UIImage(cgImage: cgImage)
        
        // Set the blurred image on main thread
        DispatchQueue.main.async {
            self.backgroundBlurImageView.image = blurredUIImage
            print("Blurred background image created successfully")
        }
    }
    
    private func setupFallbackCardDisplay(for card: TarotCard) {
        // Color-coded fallback based on card type using theme colors
        let color: UIColor
        switch card.arcana {
        case .major:
            color = CosmicFitTheme.Colors.cosmicLilac
        case .minor:
            switch card.suit {
            case .cups:
                color = .systemBlue
            case .wands:
                color = CosmicFitTheme.Colors.cosmicLilac
            case .swords:
                color = CosmicFitTheme.Colors.cosmicBlue
            case .pentacles:
                color = .systemGreen
            case .none:
                color = CosmicFitTheme.Colors.cosmicLilac
            }
        }
        
        tarotCardImageView.backgroundColor = color
        tarotCardImageView.image = nil
        
        // Create elegant text overlay
        createCardNameOverlay(for: card)
    }
    
    private func createCardNameOverlay(for card: TarotCard) {
        // Remove any existing overlay labels
        tarotCardImageView.subviews.forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        label.text = card.displayName
        
        // Apply theme to overlay label
        CosmicFitTheme.styleTitleLabel(label, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        label.textColor = .white // Override for visibility on colored background
        
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        tarotCardImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: tarotCardImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: tarotCardImageView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: tarotCardImageView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: tarotCardImageView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Themed Text Styling
    
    private func createThemedStyledText(title: String, content: String) -> NSAttributedString {
        // Use the theme's createAttributedText method for consistent styling
        return CosmicFitTheme.createAttributedText(
            title: title,
            content: content,
            titleSize: CosmicFitTheme.Typography.FontSizes.headline,
            contentSize: CosmicFitTheme.Typography.FontSizes.body
        )
    }
    
    private func createThemedVibeBreakdownText(vibeBreakdown: VibeBreakdown) -> NSAttributedString {
        let breakdown = """
        Classic: \(vibeBreakdown.classic) • Playful: \(vibeBreakdown.playful) • Romantic: \(vibeBreakdown.romantic)
        Utility: \(vibeBreakdown.utility) • Drama: \(vibeBreakdown.drama) • Edge: \(vibeBreakdown.edge)
        """
        
        // Use the theme's createAttributedText method for consistent styling
        return CosmicFitTheme.createAttributedText(
            title: "Vibe Breakdown",
            content: breakdown,
            titleSize: CosmicFitTheme.Typography.FontSizes.headline,
            contentSize: CosmicFitTheme.Typography.FontSizes.body
        )
    }
    
    // MARK: - Content Animation
    
    private func setInitialContentAlpha() {
        // Initial alpha for content labels
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                      patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                      vibeBreakdownLabel, debugButton]
        
        for label in labels {
            label.alpha = 0.0
        }
        
        // Ensure container starts visible
        tarotCardContainerView.alpha = 1.0
    }
    
    // MARK: - Card Reveal Actions
    
    @objc private func cardTapped() {
        guard !isCardRevealed else { return }
        guard currentCardState == .unrevealed else { return }
        
        // Disable further taps
        cardBackImageView.isUserInteractionEnabled = false
        
        // Mark as revealed and save state immediately
        isCardRevealed = true
        UserDefaults.standard.set(true, forKey: dailyCardRevealKey)
        
        // Perform 3D flip animation
        perform3DCardFlip()
    }

    private func perform3DCardFlip() {
        let duration: TimeInterval = 0.33
        
        // CRITICAL: Set up the layers properly BEFORE animation starts
        
        // Add perspective to the container
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 500.0 // Perspective depth
        tarotCardContainerView.layer.sublayerTransform = perspective
        
        // Configure card back (starts visible, facing forward)
        cardBackImageView.layer.isDoubleSided = false // Won't show when rotated away
        cardBackImageView.alpha = 1.0
        cardBackImageView.layer.transform = CATransform3DIdentity // Facing forward (0°)
        
        // Configure card front (starts ALREADY at 180°, so it's facing backward initially)
        tarotCardImageView.layer.isDoubleSided = false // Won't show when facing backward
        tarotCardImageView.alpha = 1.0 // MUST be visible for the flip to work
        tarotCardImageView.layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0) // Pre-rotated 180°
        
        // Hide tap label immediately
        UIView.animate(withDuration: duration * 0.2) {
            self.tapToRevealLabel.alpha = 0.0
        }
        
        // Stop and fade out scrolling runes
        scrollingRunesBackground.stopAnimating()
        UIView.animate(withDuration: duration * 0.3) {
            self.scrollingRunesBackground.alpha = 0.0
        }
        
        // NOW perform the flip: rotate BOTH cards together by 180°
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                // Rotate card back from 0° to 180° (faces away)
                self.cardBackImageView.layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
                
                // Rotate card front from 180° to 360° (0°, faces forward)
                self.tarotCardImageView.layer.transform = CATransform3DMakeRotation(.pi * 2, 0, 1, 0)
            },
            completion: { _ in
                // Reset transforms to clean state
                self.tarotCardContainerView.layer.sublayerTransform = CATransform3DIdentity
                
                // Card front is now facing forward at 0°
                self.tarotCardImageView.layer.transform = CATransform3DIdentity
                self.tarotCardImageView.alpha = 1.0
                
                // Card back is now facing backward and can be hidden
                self.cardBackImageView.layer.transform = CATransform3DIdentity
                self.cardBackImageView.isHidden = true
                self.cardBackImageView.alpha = 0.0
                self.tapToRevealLabel.isHidden = true
                
                // Complete the reveal with content fade-in
                self.completeCardReveal()
            }
        )
    }

    private func completeCardReveal() {
        let contentFadeDuration: TimeInterval = 0.5
        
        // Fade in background blur
        UIView.animate(withDuration: contentFadeDuration) {
            self.backgroundBlurImageView.alpha = 1.0
        }
        
        // Show card title
        UIView.animate(withDuration: contentFadeDuration * 0.8) {
            self.cardTitleLabel.alpha = 1.0
        }
        
        // Show scroll indicator
        UIView.animate(withDuration: contentFadeDuration * 0.6, delay: contentFadeDuration * 0.2) {
            self.scrollIndicatorView.alpha = 1.0
            self.scrollIndicatorView.isHidden = false
        }
        
        // Fade in all content labels with stagger
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                      patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                      vibeBreakdownLabel, debugButton]
        
        for (index, label) in labels.enumerated() {
            let delay = contentFadeDuration * 0.3 + (Double(index) * 0.05)
            UIView.animate(withDuration: contentFadeDuration * 0.7, delay: delay) {
                label.alpha = 1.0
            }
        }
        
        // Enable scrolling
        scrollView.isScrollEnabled = true
        
        // Setup content section backgrounds
        setupContentSectionBackgrounds()
        
        // Update state
        currentCardState = .revealed
        
        // Ensure proper final state
        ensureContainerVisibility()
        
        print("✨ 3D card flip animation completed")
    }

    // MARK: - Content Section Setup
    
    private func setupContentSectionBackgrounds() {
        // Create ONE solid content block that INCLUDES the title and all content
        
        // Remove any existing backgrounds from labels
        let allLabels = [cardTitleLabel, keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                         patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                         vibeBreakdownLabel]
        
        for label in allLabels {
            label.backgroundColor = .clear
            label.layer.cornerRadius = 0
            label.clipsToBounds = false
            label.layoutMargins = UIEdgeInsets.zero
        }
        
        // Create single content container with theme background
        let contentBackgroundView = UIView()
        contentBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme content background
        CosmicFitTheme.styleContentBackground(contentBackgroundView)
        
        // CRITICAL: Insert BELOW text but ABOVE tarot card
        contentView.insertSubview(contentBackgroundView, aboveSubview: tarotCardImageView)
        
        // CRITICAL: Position content background to end with proper spacing above tab bar
        let bottomMargin: CGFloat = 32 // Same as side margins
        
        NSLayoutConstraint.activate([
            contentBackgroundView.topAnchor.constraint(equalTo: cardTitleLabel.topAnchor, constant: -20), // Include title with padding
            contentBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            contentBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -0),
            
            // CRITICAL FIX: Content box ends with proper spacing above tab bar (not below it)
            // Calculate so that when scrolled to max, content box bottom is 32pt above tab bar
            contentBackgroundView.bottomAnchor.constraint(equalTo: debugButton.bottomAnchor, constant: bottomMargin)
        ])
        
        // CRITICAL: Ensure tarot card stays BEHIND content box
        contentView.sendSubviewToBack(tarotCardImageView)
        
        // CRITICAL: Ensure all text stays ABOVE content background
        for label in allLabels {
            contentView.bringSubviewToFront(label)
        }
        contentView.bringSubviewToFront(debugButton)
        
        print("Content box positioned with Cosmic Fit theme background")
    }
    
    // MARK: - Actions
    @objc private func debugButtonTapped() {
        guard let originalChartVC = originalChartViewController else {
            print("❌ No original chart view controller available")
            return
        }
        
        navigationController?.pushViewController(originalChartVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension DailyFitViewController: UIScrollViewDelegate {
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isCardRevealed else { return }
        
        let yOffset = scrollView.contentOffset.y
        
        let cardTranslation = yOffset * 0.5
        
        tarotCardContainerView.transform = CGAffineTransform(translationX: 0, y: cardTranslation)
        
        // Scroll indicator fade
        let arrowOpacity = max(0, 1.0 - (yOffset / 30))
        scrollIndicatorView.alpha = arrowOpacity
        
        if yOffset > 30 && !scrollIndicatorView.isHidden {
            scrollIndicatorView.isHidden = true
        } else if yOffset <= 30 && scrollIndicatorView.isHidden {
            scrollIndicatorView.isHidden = false
        }
        
        // Background blur - reduced parallax movement since we have extended bounds
        backgroundBlurImageView.transform = CGAffineTransform(translationX: 0, y: -cardTranslation * 0.2)
    }
}

// MARK: - Transition Support
extension DailyFitViewController {
    
    /// Prepare the view for incoming transition
    func prepareForTransition() {
        view.layoutIfNeeded()
    }
    
    /// Finalize transition state
    func finishTransition() {
        if isCardRevealed {
            ensureContainerVisibility()
        }
    }
}
