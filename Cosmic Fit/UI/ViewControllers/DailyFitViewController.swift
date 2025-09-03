//
//  DailyFitViewController.swift
//  Cosmic Fit
//
//  Created for production-ready Daily Fit page with tarot card scroll animation
//

import UIKit

class DailyFitViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
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

        // Card reveal key for UserDefaults (per day)
        private var dailyCardRevealKey: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return "CardRevealed_\(dateFormatter.string(from: Date()))"
        }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        // CRITICAL FIX: Restore card state when returning from other tabs
        checkCardRevealState()
        
        if isCardRevealed {
            // CRITICAL: Immediately restore card visibility and position
            tarotCardImageView.alpha = 1.0
            tarotCardImageView.isHidden = false
            cardImageTopConstraint?.constant = -50 // Reset to centered position
            
            // Ensure background is visible
            backgroundBlurImageView.alpha = 0.8
            
            // Force immediate layout to prevent disappearing
            view.layoutIfNeeded()
            
            print("Card restored on tab return - alpha: \(tarotCardImageView.alpha), position: \(cardImageTopConstraint?.constant ?? 0)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isCardRevealed {
            // CRITICAL: Double-check card visibility after tab transition completes
            tarotCardImageView.alpha = 1.0
            tarotCardImageView.isHidden = false
            
            // Ensure card is at correct initial position
            cardImageTopConstraint?.constant = -50
            
            // Ensure proper layering - card BEHIND content but VISIBLE
            contentView.sendSubviewToBack(tarotCardImageView)
            view.bringSubviewToFront(scrollView)
            
            // Force layout update
            view.layoutIfNeeded()
            
            print("Card final visibility check - should be visible at center position")
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
            
            // Setup scroll view with delegate for animation (PRESERVE existing scroll system)
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.delegate = self
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.isScrollEnabled = false // Initially disabled until card is revealed
            view.addSubview(scrollView)
            
            // Content view
            contentView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(contentView)
            
            // Initial scroll view constraints (full screen) - PRESERVE existing constraint system
            initialScrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
            initialScrollViewTopConstraint?.isActive = true
            
            // CRITICAL FIX: Adjust scroll view bottom to account for tab bar for proper scroll end
            let tabBarHeight: CGFloat = 83
            
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBarHeight), // Account for tab bar
                
                contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
            
            setupTarotCardHeader()
            setupCardRevealUI() // New method - adds card back and reveal functionality
            setupContentLabels()
            setupConstraints()
            
            // Check if card was already revealed today
            checkCardRevealState()
        }
    
    // MARK: - Card Reveal Setup Methods (ADD these new methods)
        
    private func setupBackgroundBlur() {
        backgroundBlurImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundBlurImageView.contentMode = .scaleAspectFill
        backgroundBlurImageView.clipsToBounds = true
        backgroundBlurImageView.alpha = 0.0 // Initially hidden
        
        // CRITICAL: Add to main view (not contentView) to ensure it's behind everything
        view.insertSubview(backgroundBlurImageView, at: 0) // Insert at bottom of view hierarchy
        
        NSLayoutConstraint.activate([
            backgroundBlurImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Final Card Reveal UI Setup (REPLACE existing setupCardRevealUI method)
    private func setupCardRevealUI() {
        // Card back image view - EXACT SAME WIDTH as content box
        cardBackImageView.translatesAutoresizingMaskIntoConstraints = false
        cardBackImageView.contentMode = .scaleAspectFit
        cardBackImageView.clipsToBounds = false // Allow shadow to show outside bounds
        cardBackImageView.image = UIImage(named: "CardBacks")
        cardBackImageView.layer.cornerRadius = 12
        
        // FIXED: Proper glow around entire card
        cardBackImageView.layer.shadowColor = UIColor.blue.cgColor
        cardBackImageView.layer.shadowOffset = CGSize.zero // No offset for even glow
        cardBackImageView.layer.shadowRadius = 100 // Larger radius for better glow
        cardBackImageView.layer.shadowOpacity = 0.4 // Higher opacity for visible glow
        cardBackImageView.layer.masksToBounds = false // CRITICAL: Allow shadow to render
        
        contentView.addSubview(cardBackImageView)
        
        // "Tap to reveal" label
        tapToRevealLabel.translatesAutoresizingMaskIntoConstraints = false
        tapToRevealLabel.text = "Tap to reveal today's fit"
        tapToRevealLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        tapToRevealLabel.textColor = .white
        tapToRevealLabel.textAlignment = .center
        tapToRevealLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        tapToRevealLabel.layer.cornerRadius = 8
        tapToRevealLabel.clipsToBounds = true
        tapToRevealLabel.numberOfLines = 2
        contentView.addSubview(tapToRevealLabel)
        
        // Add tap gesture
        cardTapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardBackImageView.addGestureRecognizer(cardTapGesture!)
        cardBackImageView.isUserInteractionEnabled = true
        
        // CRITICAL: Card width EXACTLY matches content box width (16pt margins)
        let contentBoxMargin: CGFloat = 16 // SAME margins as content box
        let cardAspectRatio: CGFloat = 0.625  // Standard tarot card ratio
        let cardWidth = view.bounds.width - (contentBoxMargin * 2) // EXACT same width as content box
        let cardHeight = cardWidth / cardAspectRatio
        
        NSLayoutConstraint.activate([
            cardBackImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            cardBackImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cardBackImageView.widthAnchor.constraint(equalToConstant: cardWidth),
            cardBackImageView.heightAnchor.constraint(equalToConstant: cardHeight),
            
            // FIXED: Center text perfectly in middle of card
            tapToRevealLabel.centerXAnchor.constraint(equalTo: cardBackImageView.centerXAnchor),
            tapToRevealLabel.centerYAnchor.constraint(equalTo: cardBackImageView.centerYAnchor), // Perfectly centered
            tapToRevealLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardBackImageView.leadingAnchor, constant: 20),
            tapToRevealLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardBackImageView.trailingAnchor, constant: -20),
            tapToRevealLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func checkCardRevealState() {
        isCardRevealed = UserDefaults.standard.bool(forKey: dailyCardRevealKey)
        
        if isCardRevealed {
            // Already revealed today - show revealed state immediately
            showRevealedState(animated: false)
            
            // CRITICAL: Ensure card is visible and properly positioned after state check
            DispatchQueue.main.async {
                self.tarotCardImageView.alpha = 1.0
                self.tarotCardImageView.isHidden = false
                self.cardImageTopConstraint?.constant = -50 // Centered position
                self.view.layoutIfNeeded()
                
                print("Card reveal state restored - card should be visible")
            }
        } else {
            // Not revealed yet - show card back state
            showCardBackState()
        }
    }
    
    // MARK: - Final Tarot Card Header Setup (REPLACE existing setupTarotCardHeader method)
    private func setupTarotCardHeader() {
        // Tarot card image view - EXACT SAME WIDTH as content box (16pt margins)
        tarotCardImageView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardImageView.contentMode = .scaleAspectFit
        tarotCardImageView.clipsToBounds = true
        tarotCardImageView.backgroundColor = .systemPurple // Placeholder color
        tarotCardImageView.layer.cornerRadius = 12
        contentView.addSubview(tarotCardImageView)
        
        // Card title label
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        cardTitleLabel.textColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0) // Dark text
        cardTitleLabel.textAlignment = .center
        cardTitleLabel.numberOfLines = 2
        cardTitleLabel.backgroundColor = .clear
        cardTitleLabel.clipsToBounds = false
        contentView.addSubview(cardTitleLabel)
        
        // Setup scroll indicator
        setupScrollIndicator()
        
        // CRITICAL: Card width EXACTLY matches content box width (16pt margins)
        let contentBoxMargin: CGFloat = 16 // SAME margins as content box
        let cardAspectRatio: CGFloat = 0.625  // Standard tarot card ratio
        let cardWidth = view.bounds.width - (contentBoxMargin * 2) // EXACT same width as content box
        let cardHeight = cardWidth / cardAspectRatio
        
        // Store constraint references for animation - card starts centered
        cardImageTopConstraint = tarotCardImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50)
        cardImageHeightConstraint = tarotCardImageView.heightAnchor.constraint(equalToConstant: cardHeight)
        
        NSLayoutConstraint.activate([
            cardImageTopConstraint!,
            tarotCardImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            tarotCardImageView.widthAnchor.constraint(equalToConstant: cardWidth),
            cardImageHeightConstraint!
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
        scrollArrowLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        scrollArrowLabel.textColor = .white
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
        // Dark text color for light content background
        let textColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                     patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                     vibeBreakdownLabel]
        
        for label in labels {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = textColor // CRITICAL: Dark text on light background
            label.backgroundColor = .clear // No individual backgrounds
            label.numberOfLines = 0
            label.alpha = 0.0 // Initially invisible, fades in during scroll
            contentView.addSubview(label)
        }
        
        // CRITICAL: Update card title for dark text on light background (it's now inside content box)
        cardTitleLabel.textColor = textColor // Dark text instead of white
        cardTitleLabel.backgroundColor = .clear // No background needed
        
        // Debug button
        debugButton.setTitle("Debug Chart", for: .normal)
        debugButton.setTitleColor(textColor, for: .normal) // Dark text
        debugButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.alpha = 0.0 // Initially invisible, fades in during scroll
        contentView.addSubview(debugButton)
        
        print("Content labels set up with dark text color for light background")
    }
    
    // MARK: - UI Setup Constraints (setupConstraints method)
    private func setupConstraints() {
    let screenHeight = view.bounds.height
    let tabBarHeight: CGFloat = 83
    
    // CRITICAL: Position content box at HALF the previous distance above tab bar
    let contentStartFromBottom = screenHeight - tabBarHeight - 15 // Half of previous 30pt = 15pt above tab bar
    
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
        
        // CRITICAL: Set card title with dark text (it's now inside light content box)
        let cardName = content.tarotCard?.displayName ?? "Daily Energy"
        cardTitleLabel.text = cardName
        cardTitleLabel.textColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0) // Dark text
        
        // CRITICAL: Update content labels with dark text and ensure visibility
        let darkTextColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        // FIXED: Handle tarotKeywords as String, not Array (compilation fix for line 452)
        let keywordsText = content.tarotKeywords.isEmpty ? "Intuitive guidance" : content.tarotKeywords
        keywordsLabel.attributedText = createStyledText(title: "Keywords", content: keywordsText)
        
        styleBriefLabel.attributedText = createStyledText(title: "Style Brief", content: content.styleBrief)
        textilesLabel.attributedText = createStyledText(title: "Textiles", content: content.textiles)
        colorsLabel.attributedText = createStyledText(title: "Colors", content: content.colors)
        patternsLabel.attributedText = createStyledText(title: "Patterns", content: content.patterns)
        shapeLabel.attributedText = createStyledText(title: "Shape", content: content.shape)
        accessoriesLabel.attributedText = createStyledText(title: "Accessories", content: content.accessories)
        layeringLabel.attributedText = createStyledText(title: "Layering", content: content.layering)
        
        // FIXED: Access vibeBreakdown directly, not as optional (compilation fix for line 463)
        vibeBreakdownLabel.attributedText = createVibeBreakdownText(vibeBreakdown: content.vibeBreakdown)
        
        // CRITICAL: Ensure all text is dark color and visible
        let allLabels = [cardTitleLabel, keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                        patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                        vibeBreakdownLabel]
        
        for label in allLabels {
            label.textColor = darkTextColor
            label.backgroundColor = .clear // Ensure no background conflicts
        }
        
        debugButton.setTitleColor(darkTextColor, for: .normal)
        
        print("Content updated with dark text for light background - text should be visible")
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
        blurFilter?.setValue(25.0, forKey: kCIInputRadiusKey) // Strong blur for background
        
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
        // Color-coded fallback based on card type
        let color: UIColor
        switch card.arcana {
        case .major:
            color = .systemPurple
        case .minor:
            switch card.suit {
            case .cups:
                color = .systemBlue
            case .wands:
                color = .systemRed
            case .swords:
                color = .systemGray
            case .pentacles:
                color = .systemGreen
            case .none:
                color = .systemPurple
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
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
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
    
    // MARK: - Text Styling
    
    private func createStyledText(title: String, content: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // CRITICAL: Dark text color for light content background - EXACT specification
        let textColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        // Title - dark and bold
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: textColor // Dark text on light background
        ]
        attributedString.append(NSAttributedString(string: "\(title)\n", attributes: titleAttributes))
        
        // Content - dark and readable
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: textColor // Dark text on light background
        ]
        attributedString.append(NSAttributedString(string: content, attributes: contentAttributes))
        
        return attributedString
    }
    
    private func createVibeBreakdownText(vibeBreakdown: VibeBreakdown) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // CRITICAL: Dark text color for light content background
        let textColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: textColor
        ]
        attributedString.append(NSAttributedString(string: "Vibe Breakdown\n", attributes: titleAttributes))
        
        // Content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: textColor
        ]
        
        let breakdown = """
        Classic: \(vibeBreakdown.classic) • Playful: \(vibeBreakdown.playful) • Romantic: \(vibeBreakdown.romantic)
        Utility: \(vibeBreakdown.utility) • Drama: \(vibeBreakdown.drama) • Edge: \(vibeBreakdown.edge)
        """
        
        attributedString.append(NSAttributedString(string: breakdown, attributes: contentAttributes))
        
        return attributedString
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
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = view.bounds.height
        let tabBarHeight: CGFloat = 83
        
        // Hide scroll indicator once user starts scrolling
        if scrollOffset > 10 && scrollIndicatorView.alpha > 0 {
            UIView.animate(withDuration: 0.3) {
                self.scrollIndicatorView.alpha = 0
                self.scrollIndicatorView.isHidden = true
            }
        }
        
        // Calculate total scroll distance needed for content box to reach top of screen
        let contentStartPosition = screenHeight - tabBarHeight - 30 // Content starts above tab bar
        let totalScrollDistanceToTop = contentStartPosition // Distance to scroll for content to reach top
        
        // Content slide-up animation (opacity AND position)
        let slideProgress = min(1.0, max(0.0, scrollOffset / (screenHeight * 0.15)))
        
        // Apply content slide-up animation
        cardTitleLabel.alpha = slideProgress
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                     patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                     vibeBreakdownLabel, debugButton]
        for label in labels {
            label.alpha = slideProgress
        }
        
        // TAROT CARD PARALLAX: Very slow movement
        if scrollOffset > 0 {
            let maxCardMovement = screenHeight / 3.0 // Card moves max 1/3 screen height
            let parallaxProgress = min(1.0, scrollOffset / totalScrollDistanceToTop) // 0 to 1 over full scroll
            
            // Card movement even slower
            let cardMovement = parallaxProgress * maxCardMovement * 0.8 // 20% slower than previous
            
            // Card moves UP very slowly as content scrolls
            let initialCenterY: CGFloat = -50 // Starting center Y offset
            let newCenterY = initialCenterY - cardMovement // Move up very slowly
            cardImageTopConstraint?.constant = newCenterY
            
            // NO BLUR OR FADE EFFECTS - card stays sharp and visible
            removeGaussianBlur()
            tarotCardImageView.alpha = 1.0 // Keep card fully visible always
            
        } else {
            // At top - reset to original state
            cardImageTopConstraint?.constant = -50 // Reset to center
            removeGaussianBlur()
            tarotCardImageView.alpha = 1.0
        }
        
        // FIXED: BLURRED BACKGROUND PARALLAX MOVEMENT - CORRECT DIRECTION
        // Background moves UP (same direction) but only 5% of screen height over full scroll distance
        if scrollOffset > 0 {
            let maxBackgroundMovement = screenHeight * 0.075 // 5% of screen height maximum
            let backgroundParallaxProgress = min(1.0, scrollOffset / totalScrollDistanceToTop) // 0 to 1 over full scroll
            let backgroundMovement = backgroundParallaxProgress * maxBackgroundMovement
            
            // FIXED: Move background UP (negative Y) as user scrolls up - same direction but slowest
            backgroundBlurImageView.transform = CGAffineTransform(translationX: 0, y: -backgroundMovement)
            
        } else {
            // Reset background to original position
            backgroundBlurImageView.transform = .identity
        }
        
        // Ensure content stays ABOVE card at all times
        contentView.sendSubviewToBack(tarotCardImageView) // Card always behind content
        let allLabels = [cardTitleLabel, keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                        patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                        vibeBreakdownLabel, debugButton]
        for label in allLabels {
            contentView.bringSubviewToFront(label)
        }
    }
    
    // MARK: - Gaussian Blur Methods
    
    private func applyGaussianBlur(intensity: Double) {
        guard let originalImage = originalCardImage,
              let context = ciContext else { return }
        
        // Avoid redundant blur operations
        let roundedIntensity = (intensity * 100).rounded() / 100 // Round to 2 decimal places
        guard roundedIntensity != lastBlurIntensity else { return }
        lastBlurIntensity = roundedIntensity
        
        // Create Gaussian blur with variable intensity
        let blurRadius = intensity * 10.0 // Gentler max blur radius for smoother transition
        
        guard let ciImage = CIImage(image: originalImage) else { return }
        
        // Use background queue for blur processing to avoid main thread freezing
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            let blurFilter = CIFilter(name: "CIGaussianBlur")
            blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
            blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
            
            guard let outputImage = blurFilter?.outputImage else { return }
            
            // Use reusable context for better performance
            guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
            
            let blurredImage = UIImage(cgImage: cgImage)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.tarotCardImageView.image = blurredImage
            }
        }
    }
    
    private func removeGaussianBlur() {
        guard let originalImage = originalCardImage else { return }
        lastBlurIntensity = -1 // Reset cache
        tarotCardImageView.image = originalImage
    }
    
    // MARK: - Content Animation
    
    private func setInitialContentAlpha() {
        // CRITICAL: Content starts hidden and appears during scroll
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                     patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                     vibeBreakdownLabel, debugButton]
        
        for label in labels {
            label.alpha = 0.0
        }
        
        // CRITICAL: Card title also starts hidden (it's now part of content box)
        cardTitleLabel.alpha = 0.0
        
        // Tarot card itself starts hidden (shown after reveal)
        tarotCardImageView.alpha = 0.0
    }
    
    func animateContentFadeIn() {
        // This method is now used for tab transitions only
        // The actual content fade-in happens during scroll in scrollViewDidScroll
        
        // Set initial alpha to 0 for smooth fade-in
        setInitialContentAlpha()
        
        // Quick fade-in for tab transitions
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

    // MARK: - Fixed Show Revealed State
    private func showRevealedState(animated: Bool = true) {
        let cardDuration: TimeInterval = 0.6 // Card transition duration
        let backgroundDelay: TimeInterval = 0 // Delay before background fades in
        let backgroundDuration: TimeInterval = 0.5 // Background fade duration
        
        if animated {
            // PHASE 1: Card reveal animation (card back out, tarot card in)
            UIView.animate(withDuration: cardDuration, animations: {
                // Hide card back elements
                self.cardBackImageView.alpha = 0.0
                self.tapToRevealLabel.alpha = 0.0
                
                // Show tarot card
                self.tarotCardImageView.alpha = 1.0
                
                // Do NOT show background yet - it comes after delay
                
            }) { _ in
                // Hide card back elements completely
                self.cardBackImageView.isHidden = true
                self.tapToRevealLabel.isHidden = true
                
                // Enable scrolling
                self.scrollView.isScrollEnabled = true
                
                // Set up content sections
                self.setupContentSectionBackgrounds()
                
                // Show scroll arrow after card reveal
                self.scrollIndicatorView.alpha = 1.0
                self.scrollIndicatorView.isHidden = false
                
                // PHASE 2: Background fade-in with 1 second delay
                UIView.animate(withDuration: backgroundDuration, delay: backgroundDelay, animations: {
                    // Fade in blurred background after delay
                    self.backgroundBlurImageView.alpha = 0.8
                    
                }) { _ in
                    // Ensure proper layering after both animations complete
                    self.ensureCardVisibilityAfterTabSwitch()
                }
            }
        } else {
            // Immediate state change (no animation)
            cardBackImageView.isHidden = true
            cardBackImageView.alpha = 0.0
            tapToRevealLabel.isHidden = true
            tapToRevealLabel.alpha = 0.0
            
            tarotCardImageView.alpha = 1.0
            backgroundBlurImageView.alpha = 0.8
            
            // Show scroll arrow
            scrollIndicatorView.alpha = 1.0
            scrollIndicatorView.isHidden = false
            
            scrollView.isScrollEnabled = true
            setupContentSectionBackgrounds()
            ensureCardVisibilityAfterTabSwitch()
        }
    }
    
    private func ensureCardVisibilityAfterTabSwitch() {
        // CRITICAL: Ensure card is visible when returning to tab
        tarotCardImageView.alpha = 1.0
        tarotCardImageView.isHidden = false
        
        // Reset position to initial centered state
        cardImageTopConstraint?.constant = -50
        
        // Ensure proper layering - card behind content but visible
        contentView.sendSubviewToBack(tarotCardImageView) // Card goes behind content
        view.bringSubviewToFront(scrollView) // Scroll view (with content) on top
        
        // Force immediate layout
        view.layoutIfNeeded()
        
        print("Card visibility ensured for tab switching - position: \(cardImageTopConstraint?.constant ?? 0)")
    }
    
    @objc private func cardTapped() {
        guard !isCardRevealed else { return }
        
        // Disable further taps during animation
        cardBackImageView.isUserInteractionEnabled = false
        
        // Calculate screen dimensions for glow scaling
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        let maxScreenDimension = max(screenWidth, screenHeight)
        
        // TACTILE FEEDBACK ANIMATION: Press down → Pop up → Reveal
        UIView.animateKeyframes(withDuration: 0.6, delay: 0, options: [.calculationModeCubic], animations: {
            
            // Phase 1: Press down quickly (0.0 to 0.3 of animation)
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.05) {
                self.cardBackImageView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98) // Shrink 5%
                self.cardBackImageView.layer.shadowOpacity = 0.2 // Glow starts fading
                self.cardBackImageView.layer.shadowRadius = maxScreenDimension * 0.3 // Glow starts expanding
            }
            
            // Phase 2: Pop up larger (0.3 to 0.7 of animation)
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.3) {
                self.cardBackImageView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01) // Grow 5% larger
            }
            
            // Phase 3: Return to normal (0.7 to 1.0 of animation)
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.1) {
                self.cardBackImageView.transform = .identity // Back to normal
                self.cardBackImageView.layer.shadowOpacity = 0.0 // Glow almost gone
                self.cardBackImageView.layer.shadowRadius = maxScreenDimension * 1.2 // Glow fills entire screen before disappearing
            }
            
            /*
            // Phase 1: Press down quickly (0.0 to 0.3 of animation)
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.05) {
                self.cardBackImageView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98) // Shrink 5%
                self.cardBackImageView.layer.shadowOpacity = 0.4 // Glow starts fading
                self.cardBackImageView.layer.shadowRadius = maxScreenDimension * 0.3 // Glow starts expanding
            }
            
            // Phase 2: Pop up larger (0.3 to 0.7 of animation)
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.6) {
                self.cardBackImageView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01) // Grow 5% larger
                //self.cardBackImageView.layer.shadowOpacity = 0.0 // Glow starts fading
                self.cardBackImageView.layer.shadowRadius = maxScreenDimension * 1.5 // Glow fills entire screen before disappearing
            }
            
            // Phase 3: Return to normal (0.7 to 1.0 of animation)
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.1) {
                self.cardBackImageView.transform = .identity // Back to normal
            }*/
            
        }) { _ in
            // Reset shadow properties to normal (though card back will be hidden)
            self.cardBackImageView.layer.shadowRadius = 20 // Reset to original
            
            // Mark as revealed
            self.isCardRevealed = true
            UserDefaults.standard.set(true, forKey: self.dailyCardRevealKey)
            
            // Trigger reveal animation after tactile feedback completes
            self.showRevealedState(animated: true)
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
        
        // Create single content container
        let contentBackgroundView = UIView()
        contentBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentBackgroundView.backgroundColor = UIColor(red: 204/255, green: 207/255, blue: 213/255, alpha: 1.0)
        contentBackgroundView.layer.cornerRadius = 16
        contentBackgroundView.clipsToBounds = true
        
        // CRITICAL: Insert BELOW text but ABOVE tarot card
        contentView.insertSubview(contentBackgroundView, aboveSubview: tarotCardImageView)
        
        // CRITICAL: Position content background to end with proper spacing above tab bar
        //let tabBarHeight: CGFloat = 83
        let bottomMargin: CGFloat = 32 // Same as side margins
        
        NSLayoutConstraint.activate([
            contentBackgroundView.topAnchor.constraint(equalTo: cardTitleLabel.topAnchor, constant: -20), // Include title with padding
            contentBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
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
        
        // Update text colors to dark for light background
        updateContentColors()
        
        print("Content box positioned 15pt above tab bar, ends with proper spacing")
    }
        
    private func updateContentColors() {
        // Dark text color for light content background - EXACTLY as specified
        let textColor = UIColor(red: 0/255, green: 2/255, blue: 16/255, alpha: 1.0)
        
        // CRITICAL: Update card title to dark color (it's now inside the light content box)
        cardTitleLabel.textColor = textColor
        cardTitleLabel.backgroundColor = .clear // Ensure no background conflicts
        
        // Update ALL content label colors to dark text
        let contentLabels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel,
                            patternsLabel, shapeLabel, accessoriesLabel, layeringLabel,
                            vibeBreakdownLabel]
        
        for label in contentLabels {
            // CRITICAL: Set direct text color for immediate visibility
            label.textColor = textColor
            label.backgroundColor = .clear // Ensure labels don't have competing backgrounds
            
            // Also update attributed text if it exists
            if let attributedText = label.attributedText?.mutableCopy() as? NSMutableAttributedString {
                attributedText.addAttribute(.foregroundColor, value: textColor,
                                          range: NSRange(location: 0, length: attributedText.length))
                label.attributedText = attributedText
            }
        }
        
        // Debug button color
        debugButton.setTitleColor(textColor, for: .normal)
        
        print("Updated all text colors to dark (#000210) for light content background")
    }
}
