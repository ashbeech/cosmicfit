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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Store original card frame for animation calculations
        if originalCardFrame == .zero {
            originalCardFrame = tarotCardImageView.frame
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
        view.backgroundColor = .black
        
        // Hide navigation bar completely
        navigationController?.navigationBar.isHidden = true
        
        // Setup scroll view with delegate for animation
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Initial scroll view constraints (full screen)
        initialScrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
        initialScrollViewTopConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupTarotCardHeader()
        setupContentLabels()
        setupConstraints()
    }
    
    private func setupTarotCardHeader() {
        // Tarot card image view - initially full screen
        tarotCardImageView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardImageView.contentMode = .scaleAspectFill
        tarotCardImageView.clipsToBounds = true
        tarotCardImageView.backgroundColor = .systemPurple // Placeholder color
        contentView.addSubview(tarotCardImageView)
        
        // Card title label (independent element, always visible)
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        cardTitleLabel.textColor = .white
        cardTitleLabel.textAlignment = .center
        cardTitleLabel.numberOfLines = 0
        cardTitleLabel.alpha = 0.0 // Initially invisible, fades in during scroll
        cardTitleLabel.backgroundColor = UIColor.clear // Remove black background
        // Remove corner radius since there's no background
        cardTitleLabel.clipsToBounds = false
        
        // Add padding for better visual appearance - text will be updated in updateContent()
        contentView.addSubview(cardTitleLabel)
        
        // Scroll indicator
        setupScrollIndicator()
        
        // Store constraint references for animation
        cardImageTopConstraint = tarotCardImageView.topAnchor.constraint(equalTo: contentView.topAnchor)
        cardImageHeightConstraint = tarotCardImageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        
        cardImageTopConstraint?.isActive = true
        cardImageHeightConstraint?.isActive = true
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
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel, 
                     patternsLabel, shapeLabel, accessoriesLabel, layeringLabel, 
                     vibeBreakdownLabel]
        
        for label in labels {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = .white
            label.numberOfLines = 0
            label.alpha = 0.0 // Initially invisible, fades in during scroll
            contentView.addSubview(label)
        }
        
        // Debug button
        debugButton.setTitle("Debug Chart", for: .normal)
        debugButton.setTitleColor(.systemBlue, for: .normal)
        debugButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.alpha = 0.0 // Initially invisible, fades in during scroll
        contentView.addSubview(debugButton)
    }
    
    private func setupConstraints() {
        let screenHeight = UIScreen.main.bounds.height
        
        NSLayoutConstraint.activate([
            // Tarot card constraints (already set up in setupTarotCardHeader)
            tarotCardImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tarotCardImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Card title label - positioned at middle of screen (1/3 up from bottom)
            cardTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: screenHeight * 0.67), // 1/3 up from bottom
            cardTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cardTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cardTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44), // Minimum height for touch
            
            // Content labels - positioned close below the title
            keywordsLabel.topAnchor.constraint(equalTo: cardTitleLabel.bottomAnchor, constant: 20), // Much closer to title
            keywordsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            keywordsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            styleBriefLabel.topAnchor.constraint(equalTo: keywordsLabel.bottomAnchor, constant: 20),
            styleBriefLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            styleBriefLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            textilesLabel.topAnchor.constraint(equalTo: styleBriefLabel.bottomAnchor, constant: 20),
            textilesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textilesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            colorsLabel.topAnchor.constraint(equalTo: textilesLabel.bottomAnchor, constant: 20),
            colorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            colorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            patternsLabel.topAnchor.constraint(equalTo: colorsLabel.bottomAnchor, constant: 20),
            patternsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            patternsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            shapeLabel.topAnchor.constraint(equalTo: patternsLabel.bottomAnchor, constant: 20),
            shapeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            shapeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            accessoriesLabel.topAnchor.constraint(equalTo: shapeLabel.bottomAnchor, constant: 20),
            accessoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            accessoriesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            layeringLabel.topAnchor.constraint(equalTo: accessoriesLabel.bottomAnchor, constant: 20),
            layeringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            layeringLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            vibeBreakdownLabel.topAnchor.constraint(equalTo: layeringLabel.bottomAnchor, constant: 20),
            vibeBreakdownLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            vibeBreakdownLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Debug button at bottom
            debugButton.topAnchor.constraint(equalTo: vibeBreakdownLabel.bottomAnchor, constant: 30),
            debugButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            debugButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func updateContent() {
        guard let content = dailyVibeContent else { return }
        
        // Load tarot card image
        loadTarotCardImage(for: content.tarotCard)
        
        // Set card title with padding for better appearance
        let cardName = content.tarotCard?.displayName ?? "Daily Energy"
        cardTitleLabel.text = "  \(cardName)  " // Add padding spaces
        
        // Update content labels
        keywordsLabel.text = content.tarotKeywords.isEmpty ? "" : "Keywords: \(content.tarotKeywords)"
        
        styleBriefLabel.attributedText = createStyledText(
            title: "Style Brief",
            content: content.styleBrief
        )
        
        textilesLabel.attributedText = createStyledText(
            title: "Textiles",
            content: content.textiles
        )
        
        colorsLabel.attributedText = createStyledText(
            title: "Colors",
            content: content.colors
        )
        
        patternsLabel.attributedText = createStyledText(
            title: "Patterns",
            content: content.patterns
        )
        
        shapeLabel.attributedText = createStyledText(
            title: "Shape",
            content: content.shape
        )
        
        accessoriesLabel.attributedText = createStyledText(
            title: "Accessories",
            content: content.accessories
        )
        
        layeringLabel.attributedText = createStyledText(
            title: "Layering",
            content: "\(content.layering)\n\nScore: \(content.layeringScore)/10"
        )
        
        vibeBreakdownLabel.attributedText = createVibeBreakdownText(content.vibeBreakdown)
    }
    
    private func loadTarotCardImage(for tarotCard: TarotCard?) {
        guard let tarotCard = tarotCard else {
            print("⚠️ No tarot card provided for image loading")
            tarotCardImageView.backgroundColor = .systemPurple
            return
        }
        
        print("🔍 Attempting to load image: \(tarotCard.imagePath)")
        
        // Extract just the filename from the path (removing "Cards/" prefix)
        let imageName = tarotCard.imagePath.replacingOccurrences(of: "Cards/", with: "")
        
        // Use the imagePath from the TarotCard data model  
        if let image = UIImage(named: imageName) {
            tarotCardImageView.image = image
            originalCardImage = image // Store original for Gaussian blur effects
            
            // Initialize CI context for better blur performance
            if ciContext == nil {
                ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
            }
            
            tarotCardImageView.backgroundColor = .clear
            tarotCardImageView.contentMode = .scaleAspectFit  // Changed from scaleAspectFill to scaleAspectFit
            tarotCardImageView.clipsToBounds = true
            print("✅ Successfully loaded tarot card image: \(tarotCard.imagePath) - Size: \(image.size)")
        } else {
            print("❌ Could not load image: \(tarotCard.imagePath)")
            print("🔍 Check Assets.xcassets for Cards/[imagename].imageset")
            
            // Apply fallback styling with better visual feedback
            setupFallbackCardDisplay(for: tarotCard)
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
    
    private func createStyledText(title: String, content: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        attributedString.append(NSAttributedString(string: "\(title)\n", attributes: titleAttributes))
        
        // Content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white
        ]
        attributedString.append(NSAttributedString(string: content, attributes: contentAttributes))
        
        return attributedString
    }
    
    private func createVibeBreakdownText(_ vibeBreakdown: VibeBreakdown) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        attributedString.append(NSAttributedString(string: "Vibe Breakdown\n", attributes: titleAttributes))
        
        // Breakdown
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = view.bounds.height
        
        // Card locks almost immediately after user starts scrolling (just enough to show it scrolls)
        let lockThreshold = screenHeight * 0.015 // Card locks at 1.5% scroll (very early)
        
        // Hide scroll indicator once user starts scrolling
        if scrollOffset > 10 && scrollIndicatorView.alpha > 0 {
            UIView.animate(withDuration: 0.3) {
                self.scrollIndicatorView.alpha = 0
            }
        }
        
        if scrollOffset <= lockThreshold {
            // Phase 1: Card moves up with scrolling (Y position changes)
            cardImageTopConstraint?.constant = -scrollOffset
            //print("🎬 Phase 1: Card moving to position: \(-scrollOffset)") // Debug
            
            // No fade/scale effects during movement phase, BUT apply gentle blur from start
            tarotCardImageView.alpha = 1.0
            tarotCardImageView.transform = .identity
            
            // Apply very gentle blur from the very beginning of scroll
            let initialBlurProgress = min(1.0, scrollOffset / (screenHeight * 0.6)) // Blur progress over 60% of screen
            if scrollOffset > 0 {
                applyGaussianBlur(intensity: initialBlurProgress * 0.3) // Very gentle initial blur (max 30% intensity)
            } else {
                removeGaussianBlur()
            }
            
            // Fade in content from 0% until it reaches 25% of screen (content travels from 67% to 25% = 42% movement)
            // Content starts at 67% down, reaches 25% down = 42% of screen height movement needed
            let contentMovementDistance = screenHeight * 0.42 // Distance content needs to travel to reach 25% of screen
            let fadeProgress = min(1.0, scrollOffset / contentMovementDistance) // 0 to 1 as content reaches 25% of screen
            cardTitleLabel.alpha = fadeProgress
            
            // Fade in all content labels
            let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel, 
                         patternsLabel, shapeLabel, accessoriesLabel, layeringLabel, 
                         vibeBreakdownLabel, debugButton]
            for label in labels {
                label.alpha = fadeProgress
            }
            
            // If we were in sticky mode, exit it
            if isCardSticky {
                isCardSticky = false
                // Restore original card height if it was changed
                cardImageHeightConstraint?.constant = screenHeight
            }
            
        } else {
            // Phase 2: Card Y position is LOCKED - only blur and fade (NO MORE MOVEMENT)
            cardImageTopConstraint?.constant = -lockThreshold // LOCK Y position here - NO FURTHER CHANGES
            //print("🔒 Phase 2: Card LOCKED at position: \(-lockThreshold), scaling/blurring only") // Debug
            
            // Calculate blur/fade progress from 5% to 60% scroll (55% range)
            // Card fades out gradually until content reaches nearly the top of screen
            let blurDistance = screenHeight * 0.55 // Much longer fade: 60% - 5% = 55% for complete blur/scale
            let beyondLockScroll = scrollOffset - lockThreshold
            let blurProgress = min(1.0, beyondLockScroll / blurDistance)
            
            // Apply stronger blur effect (simulate with alpha and transform)
            let blurAlpha = 1.0 - (blurProgress * 0.9) // Very strong fade as user continues scrolling
            let scaleTransform = 1.0 + (blurProgress * 0.25) // More pronounced scale increase for better blur simulation
            
            tarotCardImageView.alpha = max(0.1, blurAlpha) // Don't completely disappear
            tarotCardImageView.transform = CGAffineTransform(scaleX: scaleTransform, y: scaleTransform)
            
            // Apply real Gaussian blur to the image itself
            if blurProgress > 0.1 {
                applyGaussianBlur(intensity: blurProgress)
            } else {
                removeGaussianBlur()
            }
            
            // Keep content fully visible during blur phase (it should be fully faded in by now)
            cardTitleLabel.alpha = 1.0
            
            // Keep all content labels fully visible
            let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel, 
                         patternsLabel, shapeLabel, accessoriesLabel, layeringLabel, 
                         vibeBreakdownLabel, debugButton]
            for label in labels {
                label.alpha = 1.0
            }
            
            // Mark as sticky if we reach significant blur
            if blurProgress > 0.5 && !isCardSticky {
                isCardSticky = true
            } else if blurProgress <= 0.5 && isCardSticky {
                isCardSticky = false
            }
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
    
    func animateContentFadeIn() {
        // Set initial alpha to 0 for smooth fade-in
        cardTitleLabel.alpha = 0.0
        let labels = [keywordsLabel, styleBriefLabel, textilesLabel, colorsLabel, 
                     patternsLabel, shapeLabel, accessoriesLabel, layeringLabel, 
                     vibeBreakdownLabel, debugButton]
        for label in labels {
            label.alpha = 0.0
        }
        
        // Animate content fade-in with staggered timing for elegant effect
        UIView.animate(withDuration: 0.4, delay: 0.1, options: [.curveEaseOut], animations: {
            self.cardTitleLabel.alpha = 1.0
        })
        
        // Stagger the content labels for a cascading effect
        for (index, label) in labels.enumerated() {
            let delay = 0.15 + (Double(index) * 0.05) // Stagger each label by 50ms
            UIView.animate(withDuration: 0.3, delay: delay, options: [.curveEaseOut], animations: {
                label.alpha = 1.0
            })
        }
    }
}
