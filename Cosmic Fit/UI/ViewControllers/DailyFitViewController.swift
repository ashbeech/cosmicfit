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
    
    private var contentBackgroundView: UIView?
    private var contentBackgroundTopConstraint: NSLayoutConstraint?
    
    // Tarot card header
    private let tarotCardImageView = UIImageView()
    private let cardTitleLabel = UILabel()
    private let scrollIndicatorView = UIView()
    private let scrollArrowLabel = UILabel()
    
    // MARK: - New ContentView Components
    // Header Section
    private let dailyFitLabel = UILabel()
    private let tarotSymbolLabel = UILabel()
    private let tarotTitleLabel = UILabel()
    private let dateLabel = UILabel()
    
    // Style Brief Section
    private let styleBriefLabel = UILabel()
    
    // Style Breakdown Section
    private let colorPaletteContainer = UIView()
    private let colorHeaderLabel = UILabel()
    
    // Pill Sliders Section
    private let pillSlidersContainer = UIView()
    
    // Tone Slider Section
    private let effortLevelLabel = UILabel()
    private let toneHeaderLabel = UILabel()
    private let toneSliderContainer = UIView()
    
    // Vibe Breakdown Section
    private let vibeHeaderLabel = UILabel()
    private let vibeContainer = UIView()
    
    // Silhouette Section
    private let silhouetteHeaderLabel = UILabel()
    private let silhouetteContainer = UIView()
    
    // Bottom Section
    private let takeawayLabel = UILabel()
    
    // Dividers (stored references for constraints)
    private var topDivider: UIView?
    private var styleBreakdownDivider: UIView?
    private var bottomDivider: UIView?
    private var finalStarDivider: UIView?
    
    // Debug button (kept for debugging)
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
        
        // CRITICAL: Set initial alpha BEFORE setupUI checks reveal state
        setInitialContentAlpha()
        
        setupUI()
        updateContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isCardRevealed && currentCardState == .unrevealed {
            scrollingRunesBackground.startAnimating()
        }
        
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
        
        // Calculate visible height (excluding tab bar)
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        let visibleHeight = view.bounds.height - tabBarHeight
        
        scrollingRunesBackground.startAnimating(visibleHeight: visibleHeight)
        
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
        
        // Make it fill from top to just above tab bar
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
        setupContentViewComponents() // New comprehensive content view setup
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
            self.backgroundBlurImageView.alpha = 0.0
            self.scrollIndicatorView.alpha = 0.0
            
            // Hide all new content views
            let allContentViews: [UIView?] = [
                self.dailyFitLabel, self.tarotSymbolLabel, self.tarotTitleLabel, self.dateLabel,
                self.styleBriefLabel, self.colorPaletteContainer, self.colorHeaderLabel,
                self.pillSlidersContainer, self.effortLevelLabel, self.toneHeaderLabel, self.toneSliderContainer,
                self.vibeHeaderLabel, self.vibeContainer, self.silhouetteHeaderLabel, self.silhouetteContainer,
                self.takeawayLabel, self.topDivider, self.styleBreakdownDivider, self.bottomDivider, self.finalStarDivider,
                self.debugButton
            ]
            allContentViews.compactMap { $0 }.forEach { $0.alpha = 0.0 }
            
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
            self.backgroundBlurImageView.alpha = 1.0
            self.scrollIndicatorView.alpha = 1.0
            self.scrollIndicatorView.isHidden = false
            
            // Show all new content views
            let allContentViews: [UIView?] = [
                self.dailyFitLabel, self.tarotSymbolLabel, self.tarotTitleLabel, self.dateLabel,
                self.styleBriefLabel, self.colorPaletteContainer, self.colorHeaderLabel,
                self.pillSlidersContainer, self.effortLevelLabel, self.toneHeaderLabel, self.toneSliderContainer,
                self.vibeHeaderLabel, self.vibeContainer, self.silhouetteHeaderLabel, self.silhouetteContainer,
                self.takeawayLabel, self.topDivider, self.styleBreakdownDivider, self.bottomDivider, self.finalStarDivider,
                self.debugButton
            ]
            allContentViews.compactMap { $0 }.forEach { $0.alpha = 1.0 }
            
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
        
        // Calculate the center point between menu bar and tab bar (in view coordinates)
        let menuBarBottom = calculateMenuBarBottom()
        let tabBarTop = calculateTabBarTop()
        let availableHeight = tabBarTop - menuBarBottom
        let centerYInView = menuBarBottom + (availableHeight / 2)

        // Convert to contentView coordinates
        let contentViewOffset = view.safeAreaInsets.top + 83
        let cardCenterYFromContentTop = centerYInView - contentViewOffset + 10  // Add 25px offset to nudge down

        // Position the card's center
        cardContainerCenterYConstraint = tarotCardContainerView.centerYAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: cardCenterYFromContentTop
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

    // MARK: - Add this to your existing viewDidLayoutSubviews method:
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
    
    // MARK: - ContentView Components Setup
    private func setupContentViewComponents() {
        setupHeaderComponents()
        setupStyleBriefSection()
        setupStyleBreakdownSection()
        setupPillSlidersSection()
        setupToneSlider()
        setupVibeBreakdownSection()
        setupSilhouetteSection()
        setupBottomSection()
        setupDebugButton()
        
        // Initially hide all content (will fade in after card reveal)
        setInitialContentAlpha()
    }
    
    // MARK: - Header Components Setup
    private func setupHeaderComponents() {
        // Daily Fit title
        dailyFitLabel.text = "DAILY FIT"
        CosmicFitTheme.styleTitleLabel(dailyFitLabel, fontSize: 16, weight: .semibold)
        dailyFitLabel.textAlignment = .center
        dailyFitLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyFitLabel.alpha = 0.0
        contentView.addSubview(dailyFitLabel)
        
        // Tarot symbol (placeholder - will be dynamic later)
        tarotSymbolLabel.text = "♦ VII"
        CosmicFitTheme.styleTitleLabel(tarotSymbolLabel, fontSize: 24, weight: .bold)
        tarotSymbolLabel.textAlignment = .center
        tarotSymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        tarotSymbolLabel.alpha = 0.0
        contentView.addSubview(tarotSymbolLabel)
        
        // Tarot card title
        tarotTitleLabel.text = "THE CHARIOT" // Placeholder
        CosmicFitTheme.styleTitleLabel(tarotTitleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        tarotTitleLabel.textAlignment = .center
        tarotTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tarotTitleLabel.alpha = 0.0
        contentView.addSubview(tarotTitleLabel)
        
        // Date label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateLabel.text = dateFormatter.string(from: Date())
        CosmicFitTheme.styleBodyLabel(dateLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        dateLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.alpha = 0.0
        contentView.addSubview(dateLabel)
    }
    
    // MARK: - Divider Helper Methods
    private func createSimpleDivider() -> UIView {
        let divider = UIView()
        CosmicFitTheme.styleDivider(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }
    
    private func createOrnamentalDividerWithText(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let leftDivider = UIView()
        CosmicFitTheme.styleDivider(leftDivider)
        leftDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let rightDivider = UIView()
        CosmicFitTheme.styleDivider(rightDivider)
        rightDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        CosmicFitTheme.styleSubsectionLabel(label, fontSize: CosmicFitTheme.Typography.FontSizes.sectionHeader, italic: true)
        label.textAlignment = .center
        label.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(leftDivider)
        container.addSubview(rightDivider)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 30),
            
            leftDivider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),
            leftDivider.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12),
            
            rightDivider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            rightDivider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Style Brief Section
    private func setupStyleBriefSection() {
        // First divider (simple line)
        topDivider = createSimpleDivider()
        topDivider?.alpha = 0.0
        if let divider = topDivider {
            contentView.addSubview(divider)
        }
        
        // Style brief text block
        styleBriefLabel.text = "You know that tidy-but-slightly-off feeling, like when you expect the bus to be late but it's actually right on time? Keep your look polished but slip in one detail that breaks the rules. A blazer with sneakers, sharp trousers with a mischievous print, or a neat shirt layered over something that shouldn't work but does. The mood is about order with a wink."
        CosmicFitTheme.styleBodyLabel(styleBriefLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        styleBriefLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        styleBriefLabel.numberOfLines = 0
        styleBriefLabel.translatesAutoresizingMaskIntoConstraints = false
        styleBriefLabel.alpha = 0.0
        contentView.addSubview(styleBriefLabel)
    }
    
    // MARK: - Style Breakdown Section
    private func setupStyleBreakdownSection() {
        // Style Breakdown ornamental divider
        styleBreakdownDivider = createOrnamentalDividerWithText("Style Breakdown")
        styleBreakdownDivider?.alpha = 0.0
        if let divider = styleBreakdownDivider {
            contentView.addSubview(divider)
        }
        
        // Color section header
        colorHeaderLabel.text = "Colour"
        CosmicFitTheme.styleSubsectionLabel(colorHeaderLabel, fontSize: CosmicFitTheme.Typography.FontSizes.sectionHeader, italic: true)
        colorHeaderLabel.textAlignment = .center
        colorHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        colorHeaderLabel.alpha = 0.0
        contentView.addSubview(colorHeaderLabel)
        
        // Color palette (placeholder)
        colorPaletteContainer.translatesAutoresizingMaskIntoConstraints = false
        colorPaletteContainer.alpha = 0.0
        contentView.addSubview(colorPaletteContainer)
        
        let colorPalette = createPlaceholderColorPalette()
        colorPalette.translatesAutoresizingMaskIntoConstraints = false
        colorPaletteContainer.addSubview(colorPalette)
        
        NSLayoutConstraint.activate([
            colorPalette.centerXAnchor.constraint(equalTo: colorPaletteContainer.centerXAnchor),
            colorPalette.centerYAnchor.constraint(equalTo: colorPaletteContainer.centerYAnchor),
            colorPaletteContainer.widthAnchor.constraint(equalToConstant: 170),
            colorPaletteContainer.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    
    private func createPlaceholderColorPalette() -> UIView {
        let container = UIView()
        
        // Create 4 color swatches in 2x2 grid
        let colors = [
            UIColor(red: 128/255, green: 47/255, blue: 47/255, alpha: 1.0), // Dark red
            UIColor(red: 75/255, green: 101/255, blue: 132/255, alpha: 1.0), // Blue
            UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0), // Dark blue
            UIColor(red: 88/255, green: 101/255, blue: 114/255, alpha: 1.0) // Gray blue
        ]
        
        for (index, color) in colors.enumerated() {
            let swatch = UIView()
            swatch.backgroundColor = color
            swatch.layer.cornerRadius = 4
            swatch.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(swatch)
            
            let row = index / 2
            let col = index % 2
            
            NSLayoutConstraint.activate([
                swatch.widthAnchor.constraint(equalToConstant: 80),
                swatch.heightAnchor.constraint(equalToConstant: 50),
                swatch.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: CGFloat(col) * 90),
                swatch.topAnchor.constraint(equalTo: container.topAnchor, constant: CGFloat(row) * 60)
            ])
        }
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 170),
            container.heightAnchor.constraint(equalToConstant: 110)
        ])
        
        return container
    }
    
    // MARK: - Pill Sliders Section
    private func setupPillSlidersSection() {
        pillSlidersContainer.translatesAutoresizingMaskIntoConstraints = false
        pillSlidersContainer.alpha = 0.0
        contentView.addSubview(pillSlidersContainer)
        
        let sliderNames = ["Brightness", "Contrast", "Vibrancy"]
        let sliderValues = [3, 4, 1] // Out of 5 pills each
        
        for (index, name) in sliderNames.enumerated() {
            let column = createPillSliderColumn(title: name, filledPills: sliderValues[index])
            column.translatesAutoresizingMaskIntoConstraints = false
            pillSlidersContainer.addSubview(column)
            
            NSLayoutConstraint.activate([
                column.topAnchor.constraint(equalTo: pillSlidersContainer.topAnchor),
                column.bottomAnchor.constraint(equalTo: pillSlidersContainer.bottomAnchor),
                column.leadingAnchor.constraint(equalTo: pillSlidersContainer.leadingAnchor, constant: CGFloat(index) * 100),
                column.widthAnchor.constraint(equalToConstant: 80)
            ])
        }
        
        NSLayoutConstraint.activate([
            pillSlidersContainer.widthAnchor.constraint(equalToConstant: 300),
            pillSlidersContainer.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func createPillSliderColumn(title: String, filledPills: Int) -> UIView {
        let container = UIView()
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = title
        CosmicFitTheme.styleBodyLabel(titleLabel, fontSize: 12, weight: .medium)
        titleLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Pills stack
        let pillsStack = UIStackView()
        pillsStack.axis = .horizontal
        pillsStack.spacing = 4
        pillsStack.distribution = .fillEqually
        pillsStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pillsStack)
        
        // Create 5 pills
        for i in 0..<5 {
            let pill = UIView()
            pill.backgroundColor = i < filledPills ? CosmicFitTheme.Colors.cosmicBlue : UIColor.lightGray
            pill.layer.cornerRadius = 6
            pill.translatesAutoresizingMaskIntoConstraints = false
            pillsStack.addArrangedSubview(pill)
            
            NSLayoutConstraint.activate([
                pill.widthAnchor.constraint(equalToConstant: 12),
                pill.heightAnchor.constraint(equalToConstant: 12)
            ])
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            pillsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            pillsStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            pillsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Tone Slider Section
    private func setupToneSlider() {
        // Effort Level header
        effortLevelLabel.text = "Effort Level"
        CosmicFitTheme.styleBodyLabel(effortLevelLabel, fontSize: 14, weight: .medium)
        effortLevelLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        effortLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        effortLevelLabel.alpha = 0.0
        contentView.addSubview(effortLevelLabel)
        
        // Tone section header
        toneHeaderLabel.text = "Tone"
        CosmicFitTheme.styleBodyLabel(toneHeaderLabel, fontSize: 14, weight: .medium)
        toneHeaderLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        toneHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        toneHeaderLabel.alpha = 0.0
        contentView.addSubview(toneHeaderLabel)
        
        // Tone slider
        toneSliderContainer.translatesAutoresizingMaskIntoConstraints = false
        toneSliderContainer.alpha = 0.0
        contentView.addSubview(toneSliderContainer)
        
        let toneSlider = createToneSlider()
        toneSlider.translatesAutoresizingMaskIntoConstraints = false
        toneSliderContainer.addSubview(toneSlider)
        
        NSLayoutConstraint.activate([
            toneSlider.topAnchor.constraint(equalTo: toneSliderContainer.topAnchor),
            toneSlider.leadingAnchor.constraint(equalTo: toneSliderContainer.leadingAnchor),
            toneSlider.trailingAnchor.constraint(equalTo: toneSliderContainer.trailingAnchor),
            toneSlider.bottomAnchor.constraint(equalTo: toneSliderContainer.bottomAnchor),
            toneSliderContainer.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func createToneSlider() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Cool/Warm labels
        let coolLabel = UILabel()
        coolLabel.text = "Cool"
        CosmicFitTheme.styleBodyLabel(coolLabel, fontSize: 12, weight: .regular)
        coolLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        coolLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(coolLabel)
        
        let warmLabel = UILabel()
        warmLabel.text = "Warm"
        CosmicFitTheme.styleBodyLabel(warmLabel, fontSize: 12, weight: .regular)
        warmLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        warmLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(warmLabel)
        
        // Slider track
        let track = UIView()
        track.backgroundColor = UIColor.lightGray
        track.layer.cornerRadius = 2
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)
        
        // Create spacer views to position indicator at 60%
        let leftSpacer = UIView()
        leftSpacer.isHidden = true
        leftSpacer.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(leftSpacer)
        
        let rightSpacer = UIView()
        rightSpacer.isHidden = true
        rightSpacer.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(rightSpacer)
        
        // Diamond indicator (positioned at 60% from left)
        let indicator = UILabel()
        indicator.text = "♦"
        indicator.font = UIFont.systemFont(ofSize: 16)
        indicator.textColor = CosmicFitTheme.Colors.cosmicBlue
        indicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 40),
            
            coolLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            coolLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            warmLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            warmLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            track.leadingAnchor.constraint(equalTo: coolLabel.trailingAnchor, constant: 16),
            track.trailingAnchor.constraint(equalTo: warmLabel.leadingAnchor, constant: -16),
            track.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            track.heightAnchor.constraint(equalToConstant: 4),
            
            // Spacers to divide track into 60% and 40%
            leftSpacer.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            leftSpacer.topAnchor.constraint(equalTo: track.topAnchor),
            leftSpacer.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            leftSpacer.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: 0.6),
            
            rightSpacer.trailingAnchor.constraint(equalTo: track.trailingAnchor),
            rightSpacer.topAnchor.constraint(equalTo: track.topAnchor),
            rightSpacer.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            rightSpacer.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: 0.4),
            rightSpacer.leadingAnchor.constraint(equalTo: leftSpacer.trailingAnchor),
            
            // Position indicator at the boundary (60% point)
            indicator.centerXAnchor.constraint(equalTo: leftSpacer.trailingAnchor),
            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Vibe Breakdown Section
    private func setupVibeBreakdownSection() {
        // Vibe header
        vibeHeaderLabel.text = "Vibe"
        CosmicFitTheme.styleSubsectionLabel(vibeHeaderLabel, fontSize: CosmicFitTheme.Typography.FontSizes.sectionHeader, italic: true)
        vibeHeaderLabel.textAlignment = .center
        vibeHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        vibeHeaderLabel.alpha = 0.0
        contentView.addSubview(vibeHeaderLabel)
        
        // Vibe progress bars container
        vibeContainer.translatesAutoresizingMaskIntoConstraints = false
        vibeContainer.alpha = 0.0
        contentView.addSubview(vibeContainer)
        
        let vibeData = [
            ("Classic", 0.4),    // About 40% filled
            ("Edgy", 0.7),       // About 70% filled
            ("Romantic", 0.9)    // About 90% filled
        ]
        
        var lastBar: UIView?
        
        for (name, progress) in vibeData {
            let bar = createVibeProgressBar(name: name, progress: progress)
            bar.translatesAutoresizingMaskIntoConstraints = false
            vibeContainer.addSubview(bar)
            
            NSLayoutConstraint.activate([
                bar.leadingAnchor.constraint(equalTo: vibeContainer.leadingAnchor),
                bar.trailingAnchor.constraint(equalTo: vibeContainer.trailingAnchor),
                bar.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            if let last = lastBar {
                bar.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 12).isActive = true
            } else {
                bar.topAnchor.constraint(equalTo: vibeContainer.topAnchor).isActive = true
            }
            
            lastBar = bar
        }
        
        if let lastBar = lastBar {
            vibeContainer.bottomAnchor.constraint(equalTo: lastBar.bottomAnchor).isActive = true
        }
    }
    
    private func createVibeProgressBar(name: String, progress: Double) -> UIView {
        let container = UIView()
        
        // Name label
        let nameLabel = UILabel()
        nameLabel.text = name
        CosmicFitTheme.styleBodyLabel(nameLabel, fontSize: 14, weight: .medium)
        nameLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        // Progress track
        let track = UIView()
        track.backgroundColor = UIColor.lightGray
        track.layer.cornerRadius = 6
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)
        
        // Progress fill
        let fill = UIView()
        fill.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        fill.layer.cornerRadius = 6
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            track.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            track.heightAnchor.constraint(equalToConstant: 12),
            
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: progress)
        ])
        
        return container
    }
    
    // MARK: - Silhouette Sliders Section
    private func setupSilhouetteSection() {
        // Silhouette header
        silhouetteHeaderLabel.text = "Silhouette"
        CosmicFitTheme.styleSubsectionLabel(silhouetteHeaderLabel, fontSize: CosmicFitTheme.Typography.FontSizes.sectionHeader, italic: true)
        silhouetteHeaderLabel.textAlignment = .center
        silhouetteHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        silhouetteHeaderLabel.alpha = 0.0
        contentView.addSubview(silhouetteHeaderLabel)
        
        // Create three slider rows
        let sliderData = [
            ("Masculine", "Feminine", 0.6),
            ("Angular", "Curvy", 0.3),
            ("Structured", "Relaxed", 0.8)
        ]
        
        silhouetteContainer.translatesAutoresizingMaskIntoConstraints = false
        silhouetteContainer.alpha = 0.0
        contentView.addSubview(silhouetteContainer)
        
        var lastSlider: UIView?
        
        for (leftLabel, rightLabel, position) in sliderData {
            let slider = createBipolarSlider(leftLabel: leftLabel, rightLabel: rightLabel, position: position)
            slider.translatesAutoresizingMaskIntoConstraints = false
            silhouetteContainer.addSubview(slider)
            
            NSLayoutConstraint.activate([
                slider.leadingAnchor.constraint(equalTo: silhouetteContainer.leadingAnchor),
                slider.trailingAnchor.constraint(equalTo: silhouetteContainer.trailingAnchor),
                slider.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            if let last = lastSlider {
                slider.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 16).isActive = true
            } else {
                slider.topAnchor.constraint(equalTo: silhouetteContainer.topAnchor).isActive = true
            }
            
            lastSlider = slider
        }
        
        if let lastSlider = lastSlider {
            silhouetteContainer.bottomAnchor.constraint(equalTo: lastSlider.bottomAnchor).isActive = true
        }
    }
    
    private func createBipolarSlider(leftLabel: String, rightLabel: String, position: Double) -> UIView {
        let container = UIView()
        
        // Left label
        let leftLbl = UILabel()
        leftLbl.text = leftLabel
        CosmicFitTheme.styleBodyLabel(leftLbl, fontSize: 12, weight: .regular)
        leftLbl.textColor = CosmicFitTheme.Colors.cosmicBlue
        leftLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(leftLbl)
        
        // Right label
        let rightLbl = UILabel()
        rightLbl.text = rightLabel
        CosmicFitTheme.styleBodyLabel(rightLbl, fontSize: 12, weight: .regular)
        rightLbl.textColor = CosmicFitTheme.Colors.cosmicBlue
        rightLbl.textAlignment = .right
        rightLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rightLbl)
        
        // Slider track
        let track = UIView()
        track.backgroundColor = UIColor.lightGray
        track.layer.cornerRadius = 2
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)
        
        // Create spacer views to position indicator
        let leftSpacer = UIView()
        leftSpacer.isHidden = true
        leftSpacer.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(leftSpacer)
        
        let rightSpacer = UIView()
        rightSpacer.isHidden = true
        rightSpacer.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(rightSpacer)
        
        // Diamond indicator
        let indicator = UILabel()
        indicator.text = "♦"
        indicator.font = UIFont.systemFont(ofSize: 14)
        indicator.textColor = CosmicFitTheme.Colors.cosmicBlue
        indicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            leftLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftLbl.widthAnchor.constraint(equalToConstant: 70),
            
            rightLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightLbl.widthAnchor.constraint(equalToConstant: 70),
            
            track.leadingAnchor.constraint(equalTo: leftLbl.trailingAnchor, constant: 16),
            track.trailingAnchor.constraint(equalTo: rightLbl.leadingAnchor, constant: -16),
            track.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            track.heightAnchor.constraint(equalToConstant: 4),
            
            // Spacers to divide track based on position
            leftSpacer.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            leftSpacer.topAnchor.constraint(equalTo: track.topAnchor),
            leftSpacer.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            leftSpacer.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: position),
            
            rightSpacer.trailingAnchor.constraint(equalTo: track.trailingAnchor),
            rightSpacer.topAnchor.constraint(equalTo: track.topAnchor),
            rightSpacer.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            rightSpacer.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: 1.0 - position),
            rightSpacer.leadingAnchor.constraint(equalTo: leftSpacer.trailingAnchor),
            
            // Position indicator at the boundary
            indicator.centerXAnchor.constraint(equalTo: leftSpacer.trailingAnchor),
            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Bottom Section
    private func setupBottomSection() {
        // Bottom divider
        bottomDivider = createSimpleDivider()
        bottomDivider?.alpha = 0.0
        if let divider = bottomDivider {
            contentView.addSubview(divider)
        }
        
        // Takeaway quote
        takeawayLabel.text = "No one else has to get it. But you do. That's the point."
        CosmicFitTheme.styleTitleLabel(takeawayLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title3, weight: .medium)
        takeawayLabel.textAlignment = .center
        takeawayLabel.numberOfLines = 0
        takeawayLabel.translatesAutoresizingMaskIntoConstraints = false
        takeawayLabel.alpha = 0.0
        contentView.addSubview(takeawayLabel)
        
        // Final star divider
        finalStarDivider = createStarDivider()
        finalStarDivider?.alpha = 0.0
        if let divider = finalStarDivider {
            contentView.addSubview(divider)
        }
    }
    
    private func createStarDivider() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let leftDivider = UIView()
        CosmicFitTheme.styleDivider(leftDivider)
        leftDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let rightDivider = UIView()
        CosmicFitTheme.styleDivider(rightDivider)
        rightDivider.translatesAutoresizingMaskIntoConstraints = false
        
        let star = UILabel()
        star.text = "✦"
        star.font = UIFont.systemFont(ofSize: 20)
        star.textColor = CosmicFitTheme.Colors.cosmicBlue
        star.textAlignment = .center
        star.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        star.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(leftDivider)
        container.addSubview(rightDivider)
        container.addSubview(star)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 30),
            
            leftDivider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),
            leftDivider.trailingAnchor.constraint(equalTo: star.leadingAnchor, constant: -12),
            
            rightDivider.leadingAnchor.constraint(equalTo: star.trailingAnchor, constant: 12),
            rightDivider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),
            
            star.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            star.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            star.widthAnchor.constraint(equalToConstant: 24)
        ])
        
        return container
    }
    
    // MARK: - Debug Button Setup
    private func setupDebugButton() {
        debugButton.setTitle("Debug Chart", for: .normal)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to debug button
        CosmicFitTheme.styleButton(debugButton, style: .secondary)
        
        debugButton.alpha = 0.0
        contentView.addSubview(debugButton)
    }
    
    // MARK: - Initial Content Alpha
    private func setInitialContentAlpha() {
        // All new content starts invisible and fades in after card reveal
        let allContentViews: [UIView?] = [
            dailyFitLabel, tarotSymbolLabel, tarotTitleLabel, dateLabel,
            styleBriefLabel, colorPaletteContainer, colorHeaderLabel,
            pillSlidersContainer, effortLevelLabel, toneHeaderLabel, toneSliderContainer,
            vibeHeaderLabel, vibeContainer, silhouetteHeaderLabel, silhouetteContainer,
            takeawayLabel, topDivider, styleBreakdownDivider, bottomDivider, finalStarDivider,
            debugButton
        ]
        
        for view in allContentViews.compactMap({ $0 }) {
            view.alpha = 0.0
        }
    }
    
    // MARK: - UI Setup Constraints (setupConstraints method)
    private func setupConstraints() {
        let horizontalMargin: CGFloat = 32
        let sectionSpacing: CGFloat = 24
        
        // Use original positioning logic that properly accounts for tab bar
        let screenHeight = view.bounds.height
        let tabBarHeight: CGFloat = 83
        
        // Position content to start well above tab bar (original logic)
        // This positions content 75 points up from the bottom of the screen minus tab bar
        // Which gives approximately 10-15 points above the tab bar as expected
        let contentStartFromBottom = screenHeight - tabBarHeight - 75
        
        // Layout constraints with proper vertical flow
        var constraints: [NSLayoutConstraint] = []
        
        // Header Section - positioned using original bottom-up calculation
        constraints.append(contentsOf: [
            dailyFitLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentStartFromBottom),
            dailyFitLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            dailyFitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
            
            tarotSymbolLabel.topAnchor.constraint(equalTo: dailyFitLabel.bottomAnchor, constant: 8),
            tarotSymbolLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            tarotTitleLabel.topAnchor.constraint(equalTo: tarotSymbolLabel.bottomAnchor, constant: 8),
            tarotTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            tarotTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
            
            dateLabel.topAnchor.constraint(equalTo: tarotTitleLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])
        
        // Top divider (before style brief)
        if let topDivider = topDivider {
            constraints.append(contentsOf: [
                topDivider.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: sectionSpacing),
                topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                topDivider.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
        
        // Style Brief Section
        if let topDivider = topDivider {
            constraints.append(contentsOf: [
                styleBriefLabel.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: sectionSpacing),
                styleBriefLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                styleBriefLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        } else {
            constraints.append(contentsOf: [
                styleBriefLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: sectionSpacing * 2),
                styleBriefLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                styleBriefLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        }
        
        // Style Breakdown Section
        if let styleBreakdownDivider = styleBreakdownDivider {
            constraints.append(contentsOf: [
                styleBreakdownDivider.topAnchor.constraint(equalTo: styleBriefLabel.bottomAnchor, constant: sectionSpacing),
                styleBreakdownDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                styleBreakdownDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                
                colorHeaderLabel.topAnchor.constraint(equalTo: styleBreakdownDivider.bottomAnchor, constant: sectionSpacing),
                colorHeaderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                
                colorPaletteContainer.topAnchor.constraint(equalTo: colorHeaderLabel.bottomAnchor, constant: 12),
                colorPaletteContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
        } else {
            constraints.append(contentsOf: [
                colorHeaderLabel.topAnchor.constraint(equalTo: styleBriefLabel.bottomAnchor, constant: sectionSpacing * 2),
                colorHeaderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                
                colorPaletteContainer.topAnchor.constraint(equalTo: colorHeaderLabel.bottomAnchor, constant: 12),
                colorPaletteContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
        }
        
        // Pill Sliders Section
        constraints.append(contentsOf: [
            pillSlidersContainer.topAnchor.constraint(equalTo: colorPaletteContainer.bottomAnchor, constant: sectionSpacing),
            pillSlidersContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        // Tone Slider Section
        constraints.append(contentsOf: [
            effortLevelLabel.topAnchor.constraint(equalTo: pillSlidersContainer.bottomAnchor, constant: sectionSpacing),
            effortLevelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            effortLevelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
            
            toneHeaderLabel.topAnchor.constraint(equalTo: effortLevelLabel.bottomAnchor, constant: 8),
            toneHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            toneHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
            
            toneSliderContainer.topAnchor.constraint(equalTo: toneHeaderLabel.bottomAnchor, constant: 8),
            toneSliderContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            toneSliderContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])
        
        // Vibe Breakdown Section
        constraints.append(contentsOf: [
            vibeHeaderLabel.topAnchor.constraint(equalTo: toneSliderContainer.bottomAnchor, constant: sectionSpacing),
            vibeHeaderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            vibeContainer.topAnchor.constraint(equalTo: vibeHeaderLabel.bottomAnchor, constant: 12),
            vibeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            vibeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])
        
        // Silhouette Section
        constraints.append(contentsOf: [
            silhouetteHeaderLabel.topAnchor.constraint(equalTo: vibeContainer.bottomAnchor, constant: sectionSpacing),
            silhouetteHeaderLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            silhouetteContainer.topAnchor.constraint(equalTo: silhouetteHeaderLabel.bottomAnchor, constant: 12),
            silhouetteContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            silhouetteContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])
        
        // Bottom Section
        if let bottomDivider = bottomDivider {
            constraints.append(contentsOf: [
                bottomDivider.topAnchor.constraint(equalTo: silhouetteContainer.bottomAnchor, constant: sectionSpacing),
                bottomDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                bottomDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                bottomDivider.heightAnchor.constraint(equalToConstant: 1),
                
                takeawayLabel.topAnchor.constraint(equalTo: bottomDivider.bottomAnchor, constant: sectionSpacing),
                takeawayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                takeawayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        } else {
            constraints.append(contentsOf: [
                takeawayLabel.topAnchor.constraint(equalTo: silhouetteContainer.bottomAnchor, constant: sectionSpacing * 2),
                takeawayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                takeawayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        }
        
        // Final star divider
        if let finalStarDivider = finalStarDivider {
            constraints.append(contentsOf: [
                finalStarDivider.topAnchor.constraint(equalTo: takeawayLabel.bottomAnchor, constant: sectionSpacing),
                finalStarDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                finalStarDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                
                debugButton.topAnchor.constraint(equalTo: finalStarDivider.bottomAnchor, constant: sectionSpacing),
                debugButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                debugButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
            ])
        } else {
            constraints.append(contentsOf: [
                debugButton.topAnchor.constraint(equalTo: takeawayLabel.bottomAnchor, constant: sectionSpacing * 2),
                debugButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                debugButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func updateContent() {
        guard let content = dailyVibeContent else { return }
        
        // Load tarot card image
        loadTarotCardImage(for: content.tarotCard)
        
        // Update header with tarot card information
        if let tarotCard = content.tarotCard {
            tarotTitleLabel.text = tarotCard.displayName.uppercased()
            // TODO: Update tarot symbol based on card data
            // tarotSymbolLabel.text = "♦ \(tarotCard.number ?? "")"
        } else {
            tarotTitleLabel.text = "DAILY ENERGY"
        }
        
        // Update date label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateLabel.text = dateFormatter.string(from: Date())
        
        // TODO: Update style brief with actual content when available
        // styleBriefLabel.text = content.styleBrief
        
        // TODO: Update vibe breakdown progress bars with actual data
        // Update vibe progress bars based on content.vibeBreakdown
        
        print("Content updated with new layout structure")
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
    /*
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
    */
    
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
        
        // Header labels will fade in with other content (no separate animation needed)
        
        // Show scroll indicator
        UIView.animate(withDuration: contentFadeDuration * 0.6, delay: contentFadeDuration * 0.2) {
            self.scrollIndicatorView.alpha = 1.0
            self.scrollIndicatorView.isHidden = false
        }
        
        // Fade in all new content views with stagger
        let allContentViews: [UIView?] = [
            dailyFitLabel, tarotSymbolLabel, tarotTitleLabel, dateLabel,
            topDivider, styleBriefLabel,
            styleBreakdownDivider, colorHeaderLabel, colorPaletteContainer,
            pillSlidersContainer,
            effortLevelLabel, toneHeaderLabel, toneSliderContainer,
            vibeHeaderLabel, vibeContainer,
            silhouetteHeaderLabel, silhouetteContainer,
            bottomDivider, takeawayLabel, finalStarDivider,
            debugButton
        ]
        
        for (index, view) in allContentViews.compactMap({ $0 }).enumerated() {
            let delay = contentFadeDuration * 0.3 + (Double(index) * 0.05)
            UIView.animate(withDuration: contentFadeDuration * 0.7, delay: delay) {
                view.alpha = 1.0
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
        // Remove any existing background
        contentBackgroundView?.removeFromSuperview()
        
        // Remove any existing backgrounds from labels
        let allLabels: [UILabel?] = [
            dailyFitLabel, tarotSymbolLabel, tarotTitleLabel, dateLabel,
            styleBriefLabel, colorHeaderLabel, effortLevelLabel, toneHeaderLabel,
            vibeHeaderLabel, silhouetteHeaderLabel, takeawayLabel
        ]
        
        for label in allLabels.compactMap({ $0 }) {
            label.backgroundColor = .clear
            label.layer.cornerRadius = 0
            label.clipsToBounds = false
            label.layoutMargins = UIEdgeInsets.zero
        }
        
        // Create single content container with theme background
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.alpha = 0  // Start invisible
        
        // Apply theme content background
        CosmicFitTheme.styleContentBackground(backgroundView)
        contentView.insertSubview(backgroundView, aboveSubview: tarotCardImageView)
        
        self.contentBackgroundView = backgroundView
        
        let bottomMargin: CGFloat = 32
        
        // Calculate starting position (behind tab bar)
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 83
        let screenHeight = view.bounds.height
        let startingYPosition = screenHeight - tabBarHeight + 100  // Extra offset to be fully hidden
        
        // Start position constraint (behind tab bar)
        contentBackgroundTopConstraint = backgroundView.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: startingYPosition
        )
        contentBackgroundTopConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: debugButton.bottomAnchor, constant: bottomMargin)
        ])
        
        // Force layout
        view.layoutIfNeeded()
        
        // Animate to final position - use dailyFitLabel as the starting point for content background
        let finalYPosition = dailyFitLabel.frame.origin.y - bottomMargin
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0.2,  // Slight delay after card flip
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: [.curveEaseOut],
            animations: {
                // Fade in
                backgroundView.alpha = 1.0
                
                // Slide up to final position
                self.contentBackgroundTopConstraint?.constant = finalYPosition
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                // Ensure proper z-ordering after animation
                self.contentView.sendSubviewToBack(self.tarotCardImageView)
                
                // Ensure all text stays ABOVE content background
                for label in allLabels.compactMap({ $0 }) {
                    self.contentView.bringSubviewToFront(label)
                }
                // Bring all new content views to front
                let allContentViews: [UIView?] = [
                    self.dailyFitLabel, self.tarotSymbolLabel, self.tarotTitleLabel, self.dateLabel,
                    self.styleBriefLabel, self.colorPaletteContainer, self.colorHeaderLabel,
                    self.pillSlidersContainer, self.effortLevelLabel, self.toneHeaderLabel, self.toneSliderContainer,
                    self.vibeHeaderLabel, self.vibeContainer, self.silhouetteHeaderLabel, self.silhouetteContainer,
                    self.takeawayLabel, self.topDivider, self.styleBreakdownDivider, self.bottomDivider, self.finalStarDivider
                ]
                for view in allContentViews.compactMap({ $0 }) {
                    self.contentView.bringSubviewToFront(view)
                }
                self.contentView.bringSubviewToFront(self.debugButton)
                
                print("✨ Content box slide-up animation completed")
            }
        )
    }
    
    // MARK: - Actions
    @objc private func debugButtonTapped() {
        guard let originalChartVC = originalChartViewController else {
            print("❌ No original chart view controller available")
            return
        }
        
        // Print debug information to console
        print("\n🔮 DEBUG CHART BUTTON TAPPED 🔮")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Print daily vibe content info
        if let dailyVibe = dailyVibeContent {
            print("📊 DAILY VIBE DATA:")
            //print("• Keywords: \(dailyVibe.tarotKeywords)")
            //print("• Style Brief: \(dailyVibe.styleBrief.prefix(100))...")
            
            if let tarotCard = dailyVibe.tarotCard {
                print("• Card: \(tarotCard.displayName)")
                print("• Card Description: \(tarotCard.description)")
            } else {
                print("• Card: None selected")
            }
            
            print("\n🎨 VIBE BREAKDOWN:")
            let vibeBreakdown = dailyVibe.vibeBreakdown
            print("• Classic: \(vibeBreakdown.classic)")
            print("• Playful: \(vibeBreakdown.playful)")
            print("• Romantic: \(vibeBreakdown.romantic)")
            print("• Utility: \(vibeBreakdown.utility)")
            print("• Drama: \(vibeBreakdown.drama)")
            print("• Edge: \(vibeBreakdown.edge)")
            
            /*
            print("\n🌈 COLOR SCORES:")
            let colorScores = dailyVibe.colorScores
            print("• Darkness: \(colorScores.darkness)/10")
            print("• Vibrancy: \(colorScores.vibrancy)/10")
            print("• Contrast: \(colorScores.contrast)/10")
            
            print("\n📐 STRUCTURAL AXES:")
            print("• Angular/Curvy: \(dailyVibe.angularCurvyScore.score)/10")
            print("• Layering: \(dailyVibe.layeringScore)/10")
            
            if let temp = dailyVibe.temperature, let condition = dailyVibe.weatherCondition {
                print("\n🌤 WEATHER CONTEXT:")
                print("• Temperature: \(String(format: "%.1f", temp))°C")
                print("• Condition: \(condition)")
            }
             */
        }
        
        print("\n🌟 Navigating to Full Natal Chart with Debug Menu...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        // Find the tab bar controller in the view hierarchy
        var currentParent: UIViewController? = parent
        while currentParent != nil {
            if let tabBarController = currentParent as? CosmicFitTabBarController {
                // Wrap the chart view controller in a GenericDetailViewController
                let detailVC = GenericDetailViewController(contentViewController: originalChartVC)
                
                // Present using the tab bar's presentation system
                tabBarController.presentDetailViewController(detailVC, animated: true)
                return
            }
            currentParent = currentParent?.parent
        }
        
        // Fallback: if no tab bar controller found, present modally
        print("⚠️ No tab bar controller found - presenting modally")
        let navController = UINavigationController(rootViewController: originalChartVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
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
