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
    private var cardImageTopConstraint: NSLayoutConstraint?
    private var cardImageHeightConstraint: NSLayoutConstraint?
    private var originalCardFrame: CGRect = .zero
    private var isCardSticky = false
    private var originalCardImage: UIImage? // Store original unblurred image
    private var ciContext: CIContext? // Reuse CI context for better performance
    private var lastBlurIntensity: Double = -1 // Cache to avoid redundant blur operations
    
    // Data
    private var dailyVibeContent: DailyVibeContent?
    private var originalChartViewController: NatalChartViewController?
    
    // MARK: - Card Reveal Properties (Add after existing properties)
    
    // Card reveal state management
    private var isCardRevealed = false
    private var cardBackImageView = UIImageView()
    private var tapToRevealLabel = UILabel()
    private var backgroundBlurImageView = UIImageView()
    private var cardTapGesture: UITapGestureRecognizer?
    
    private let tarotCardContainerView = UIView()
    private var cardContainerBottomConstraint: NSLayoutConstraint?
    private var cardContainerCenterYConstraint: NSLayoutConstraint?
    private var cardContainerWidthConstraint: NSLayoutConstraint?
    private var cardContainerHeightConstraint: NSLayoutConstraint?
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Store original card frame for animation calculations
        if originalCardFrame == .zero {
            originalCardFrame = tarotCardImageView.frame
        }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isCardRevealed {
            // Final visibility check for container and ALL its children
            tarotCardContainerView.alpha = 1.0
            tarotCardContainerView.transform = .identity
            tarotCardImageView.alpha = 1.0
            
            // Ensure proper layering - card behind content, but topMask ABOVE scrollView
            contentView.sendSubviewToBack(tarotCardContainerView)
            // DO NOT bring scrollView to front - it would cover the topMaskView
            
            // Ensure topMask stays on top
            view.bringSubviewToFront(topMaskView)
            
            view.layoutIfNeeded()
            
            print("Card container final check - container and all children visible with correct alpha values")
        }
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
        view.backgroundColor = .black
        
        // Hide navigation bar completely
        navigationController?.navigationBar.isHidden = true
        
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
        
        let menuConstant = MenuBarView.height * 0.5
        
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
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: view.safeAreaInsets.top + MenuBarView.height),
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
    
    // MARK: - Card Reveal Setup Methods (ADD these new methods)
    
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
    
    // MARK: - Final Card Reveal UI Setup
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
    
    // MARK: - Step 4: New unified state management methods
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
        // NO POSITION CHANGES - card stays static in same location
        
        let changes = {
            // Show unrevealed elements IN container
            self.cardBackImageView.alpha = 1.0
            self.cardBackImageView.isHidden = false
            self.tapToRevealLabel.alpha = 1.0
            self.tapToRevealLabel.isHidden = false
            
            // Hide revealed elements
            self.tarotCardImageView.alpha = 0.0
            self.cardTitleLabel.alpha = 0.0
            
            // Hide background and UI elements
            self.backgroundBlurImageView.alpha = 0.0
            self.scrollIndicatorView.alpha = 0.0
            
            // Hide content labels
            let labels = [self.keywordsLabel, self.styleBriefLabel, self.textilesLabel, self.colorsLabel,
                          self.patternsLabel, self.shapeLabel, self.accessoriesLabel, self.layeringLabel,
                          self.vibeBreakdownLabel, self.debugButton]
            for label in labels {
                label.alpha = 0.0
            }
            
            // Ensure container is visible and not transformed
            self.tarotCardContainerView.alpha = 1.0
            self.tarotCardContainerView.transform = .identity
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: changes)
        } else {
            changes()
        }
        
        // Disable scrolling
        scrollView.isScrollEnabled = false
        view.backgroundColor = .black
    }
    
    private func showRevealedStateUnified(animated: Bool) {
        
        let cardDuration: TimeInterval = 0.4
        let backgroundDuration: TimeInterval = 0.8
        
        if animated {
            // Fade between card back and card front simultaneously + show content immediately
            UIView.animate(withDuration: cardDuration, animations: {
                // Fade out unrevealed elements
                self.cardBackImageView.alpha = 0.0
                self.tapToRevealLabel.alpha = 0.0
                
                // Fade in revealed elements
                self.tarotCardImageView.alpha = 1.0
                self.cardTitleLabel.alpha = 1.0
                
                // IMMEDIATE: Show content text right with card flip
                let labels = [self.keywordsLabel, self.styleBriefLabel, self.textilesLabel, self.colorsLabel,
                              self.patternsLabel, self.shapeLabel, self.accessoriesLabel, self.layeringLabel,
                              self.vibeBreakdownLabel, self.debugButton]
                for label in labels {
                    label.alpha = 1.0
                }
            }) { _ in
                // Clean up unrevealed elements after fade completes
                self.cardBackImageView.isHidden = true
                self.tapToRevealLabel.isHidden = true
                
                // Enable scrolling
                self.scrollView.isScrollEnabled = true
                
                // Setup content sections
                self.setupContentSectionBackgrounds()
                
                // Show scroll indicator
                self.scrollIndicatorView.alpha = 1.0
                self.scrollIndicatorView.isHidden = false
                
                // Background fade
                UIView.animate(withDuration: backgroundDuration, animations: {
                    self.backgroundBlurImageView.alpha = 1.0
                }) { _ in
                    // Ensure proper final state
                    self.ensureContainerVisibility()
                }
            }
        } else {
            // Immediate changes for non-animated transition
            cardBackImageView.alpha = 0.0
            cardBackImageView.isHidden = true
            tapToRevealLabel.alpha = 0.0
            tapToRevealLabel.isHidden = true
            
            tarotCardImageView.alpha = 1.0
            cardTitleLabel.alpha = 1.0
            backgroundBlurImageView.alpha = 0.8
            scrollIndicatorView.alpha = 1.0
            scrollIndicatorView.isHidden = false
            
            // IMMEDIATE: Show all content text
            let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                          patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                          vibeBreakdownLabel, debugButton]
            for label in labels {
                label.alpha = 1.0
            }
            
            scrollView.isScrollEnabled = true
            setupContentSectionBackgrounds()
            
            view.layoutIfNeeded()
            ensureContainerVisibility()
        }
    }
    
    // Helper to ensure container is visible
    private func ensureContainerVisibility() {
        tarotCardContainerView.alpha = 1.0
        tarotCardContainerView.isHidden = false
        
        // Ensure proper layering
        contentView.sendSubviewToBack(tarotCardContainerView)
        //view.bringSubviewToFront(scrollView)
        
    }
    
    private func checkCardRevealState() {
        isCardRevealed = UserDefaults.standard.bool(forKey: dailyCardRevealKey)
        
        if isCardRevealed {
            setCardState(.revealed, animated: false)
            
            // Ensure container and contents are visible
            DispatchQueue.main.async {
                self.tarotCardContainerView.alpha = 1.0
                self.tarotCardContainerView.transform = .identity
                self.tarotCardImageView.alpha = 1.0
                self.cardTitleLabel.alpha = 1.0
                
                // CRITICAL: Ensure content text is visible when restored
                let labels = [self.keywordsLabel, self.styleBriefLabel, self.textilesLabel, self.colorsLabel,
                              self.patternsLabel, self.shapeLabel, self.accessoriesLabel, self.layeringLabel,
                              self.vibeBreakdownLabel, self.debugButton]
                for label in labels {
                    label.alpha = 1.0
                }
                
                self.view.layoutIfNeeded()
                print("Card reveal state restored - container and content visible")
            }
        } else {
            setCardState(.unrevealed, animated: false)
        }
    }
    
    // MARK: - Final Tarot Card Header Setup
    private func setupTarotCardHeader() {
        // Create unified container for card visual elements only (not title)
        tarotCardContainerView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardContainerView.clipsToBounds = false
        tarotCardContainerView.backgroundColor = .clear
        contentView.addSubview(tarotCardContainerView)
        
        // Calculate card dimensions with padding around it
        let cardAspectRatio: CGFloat = 0.62
        let horizontalPadding: CGFloat = 24 // 10px more space on each side
        let cardWidth = view.bounds.width - (horizontalPadding * 2) // Reduce width by total padding
        let cardHeight = cardWidth / cardAspectRatio

        // Container is exactly card size (now smaller)
        cardContainerWidthConstraint = tarotCardContainerView.widthAnchor.constraint(equalToConstant: cardWidth)
        cardContainerHeightConstraint = tarotCardContainerView.heightAnchor.constraint(equalToConstant: cardHeight)
        
        // RESTORE ORIGINAL positioning logic with smaller card size
        // STATIC position above content box (matching original scroll behavior)
        let screenHeight = view.bounds.height
        let tabBarHeight: CGFloat = 83
        let contentStartFromBottom = screenHeight - tabBarHeight - 83
        let contentBoxTop = contentStartFromBottom - 20 // Account for title label padding
        let marginAboveContent: CGFloat = 24 // Space between card and content box
        
        // Use original bottomAnchor constraint to contentView.topAnchor for proper scroll behavior
        cardContainerCenterYConstraint = tarotCardContainerView.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: contentBoxTop - marginAboveContent)
        
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
            tarotCardImageView.bottomAnchor.constraint(equalTo: tarotCardContainerView.bottomAnchor)
        ])
        
        // Card back (unrevealed state) - same size as revealed card
        cardBackImageView.translatesAutoresizingMaskIntoConstraints = false
        cardBackImageView.contentMode = .scaleAspectFit
        cardBackImageView.clipsToBounds = true
        cardBackImageView.backgroundColor = UIColor(red: 31/255, green: 25/255, blue: 61/255, alpha: 1.0)
        cardBackImageView.layer.cornerRadius = 24
        cardBackImageView.alpha = 1.0
        cardBackImageView.isUserInteractionEnabled = true
        tarotCardContainerView.addSubview(cardBackImageView)
        
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
            
            // CRITICAL FIX: Update constraints properly without breaking existing animation system
            updateTarotCardConstraintsForReveal()
            
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
    
    private func updateTarotCardConstraintsForReveal() {
        // With the corrected sizing in setupTarotCardHeader, no constraint changes needed
        // Both card back and revealed card now use the same proper dimensions
        // This maintains size consistency and prevents layering issues
        
        print("Tarot card constraints maintained - no changes needed for size consistency")
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
    
    private func applyBlur(to image: UIImage, intensity: Double) -> UIImage? {
        // Initialize CI context if needed
        if ciContext == nil {
            ciContext = CIContext(options: nil)
        }
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext?.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
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
    
    func animateContentFadeIn() {
        // Only perform fade-in animation if card hasn't been revealed yet
        guard !isCardRevealed else {
            print("Card already revealed - skipping fade animation for tab transition")
            //restoreContentVisibilityState()
            return
        }
        
        // This method is now only used for initial card reveal
        // Set initial alpha to 0 for smooth fade-in
        setInitialContentAlpha()
        
        // Quick fade-in for initial card reveal only
        UIView.animate(withDuration: 0.3, delay: 0.05, options: [.curveEaseOut], animations: {
            self.cardTitleLabel.alpha = 1.0
            let labels = [self.keywordsLabel, self.styleBriefLabel, self.textilesLabel, self.colorsLabel,
                          self.patternsLabel, self.shapeLabel, self.accessoriesLabel, self.layeringLabel,
                          self.vibeBreakdownLabel, self.debugButton]
            for label in labels {
                label.alpha = 1.0
            }
        })
    }
    
    // MARK: - Card Reveal State Management (ADD these new methods)
    
    private func showCardBackState() {
        // Show card back elements
        cardBackImageView.alpha = 1.0
        cardBackImageView.isHidden = false
        tapToRevealLabel.alpha = 1.0
        tapToRevealLabel.isHidden = false
        
        // Hide revealed elements
        tarotCardImageView.alpha = 0.0
        cardTitleLabel.alpha = 0.0
        backgroundBlurImageView.alpha = 0.0
        
        // CRITICAL: Hide scroll arrow before reveal (no scrolling available yet)
        scrollIndicatorView.alpha = 0.0
        scrollIndicatorView.isHidden = true
        
        // Keep all content labels hidden
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                      patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                      vibeBreakdownLabel, debugButton]
        for label in labels {
            label.alpha = 0.0
        }
        
        // Disable scrolling
        scrollView.isScrollEnabled = false
        
        // Keep black background
        view.backgroundColor = .black
    }
    
    private func ensureCardVisibilityAfterTabSwitch() {
        // CRITICAL: Ensure card is visible when returning to tab
        tarotCardImageView.alpha = 1.0
        tarotCardImageView.isHidden = false
        
        // Reset position to initial centered state
        cardImageTopConstraint?.constant = -50
        
        // Ensure proper layering - card behind content but visible
        contentView.sendSubviewToBack(tarotCardImageView) // Card goes behind content
        //view.bringSubviewToFront(scrollView) // Scroll view (with content) on top
        
        // Force immediate layout
        view.layoutIfNeeded()
        
        print("Card visibility ensured for tab switching - position: \(cardImageTopConstraint?.constant ?? 0)")
    }
    
    @objc private func cardTapped() {
        guard !isCardRevealed else { return }
        guard currentCardState == .unrevealed else { return }
        
        // Disable further taps
        cardBackImageView.isUserInteractionEnabled = false
        
        // Calculate screen dimensions for glow effect
        let maxScreenDimension = max(view.bounds.width, view.bounds.height)
        
        // Tactile feedback animation with themed glow color
        UIView.animateKeyframes(withDuration: 0.33, delay: 0, options: [.calculationModeCubic], animations: {
            // Press down slightly
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.1) {
                self.tarotCardContainerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.cardBackImageView.layer.shadowOpacity = 0.2
                self.cardBackImageView.layer.shadowRadius = maxScreenDimension * 0.3
            }
            
            // Return to exact normal
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.03) {
                self.tarotCardContainerView.transform = .identity // Back to exact normal
                self.cardBackImageView.layer.shadowOpacity = 0.0
                self.cardBackImageView.layer.shadowRadius = maxScreenDimension * 1.2
            }
        }) { _ in
            // Reset shadow
            self.cardBackImageView.layer.shadowRadius = 20
            
            // Mark as revealed and save state
            self.isCardRevealed = true
            UserDefaults.standard.set(true, forKey: self.dailyCardRevealKey)
            
            // Transition to revealed state (will handle position change)
            self.setCardState(.revealed, animated: true)
        }
    }
    
    // MARK: - Fixed Content Section Setup (REPLACE existing setupContentSectionBackgrounds method)
    
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
}

// MARK: - Transition Support
extension DailyFitViewController {
    
    /// Prepare the view for incoming transition
    func prepareForTransition() {
        // Ensure view is loaded and laid out
        view.layoutIfNeeded()
        
        // If card is revealed, ensure content is properly visible
        if isCardRevealed {
            ensureContentVisibility()
        }
        
        // Make sure background is set correctly
        view.backgroundColor = .black
    }
    
    /// Finalize transition state
    func finishTransition() {
        // Perform any post-transition setup
        if isCardRevealed {
            // Ensure all content is properly visible
            tarotCardContainerView.alpha = 1.0
            tarotCardImageView.alpha = 1.0
            
            // Ensure proper layering
            contentView.sendSubviewToBack(tarotCardContainerView)
            //view.bringSubviewToFront(scrollView)
        }
    }
    
    private func ensureContentVisibility() {
        // Ensure all revealed content is visible with correct alpha values
        tarotCardContainerView.alpha = 1.0
        tarotCardImageView.alpha = 1.0
        cardTitleLabel.alpha = 1.0
        backgroundBlurImageView.alpha = 1.0
        
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                      patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                      vibeBreakdownLabel, debugButton]
        
        for label in labels {
            label.alpha = 1.0
        }
    }
}
