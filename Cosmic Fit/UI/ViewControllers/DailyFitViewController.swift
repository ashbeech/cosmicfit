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
        title = "Daily Fit"
        
        // Navigation bar configuration
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
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
        
        // Card title label (positioned at bottom of card, initially hidden)
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        cardTitleLabel.textColor = .white
        cardTitleLabel.textAlignment = .center
        cardTitleLabel.numberOfLines = 0
        cardTitleLabel.alpha = 0.0 // Initially hidden
        cardTitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
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
            contentView.addSubview(label)
        }
        
        // Debug button
        debugButton.setTitle("Debug Chart", for: .normal)
        debugButton.setTitleColor(.systemBlue, for: .normal)
        debugButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(debugButton)
    }
    
    private func setupConstraints() {
        let screenHeight = UIScreen.main.bounds.height
        let cardHeight = screenHeight
        let contentStartY = cardHeight + 50 // Start content below the card with some spacing
        
        NSLayoutConstraint.activate([
            // Tarot card constraints (already set up in setupTarotCardHeader)
            tarotCardImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tarotCardImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Card title label
            cardTitleLabel.leadingAnchor.constraint(equalTo: tarotCardImageView.leadingAnchor, constant: 20),
            cardTitleLabel.trailingAnchor.constraint(equalTo: tarotCardImageView.trailingAnchor, constant: -20),
            cardTitleLabel.bottomAnchor.constraint(equalTo: tarotCardImageView.bottomAnchor, constant: -40),
            
            // Content labels - positioned below the card
            keywordsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentStartY),
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
        
        // Set card title
        cardTitleLabel.text = content.tarotCard?.displayName ?? "Daily Energy"
        
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
            // Set a default gradient or placeholder
            tarotCardImageView.backgroundColor = .systemPurple
            return
        }
        
        // Try to load tarot card image from assets
        let imageName = tarotCard.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "the_", with: "")
        
        if let image = UIImage(named: imageName) {
            tarotCardImageView.image = image
        } else {
            // Fallback to colored background based on card
            let color: UIColor
            switch tarotCard.arcana {
            case .major:
                color = .systemPurple
            case .minor:
                switch tarotCard.suit {
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
            
            // Add card name as overlay text if no image available
            let label = UILabel()
            label.text = tarotCard.displayName
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
        let cardTransitionThreshold = screenHeight * 0.67 // When 2/3 of card reaches top 1/3
        
        // Hide scroll indicator once user starts scrolling
        if scrollOffset > 10 && scrollIndicatorView.alpha > 0 {
            UIView.animate(withDuration: 0.3) {
                self.scrollIndicatorView.alpha = 0
            }
        }
        
        // Calculate blur and movement
        let blurProgress = min(1.0, scrollOffset / cardTransitionThreshold)
        
        // Apply blur effect (simulate with alpha and transform)
        let blurAlpha = 1.0 - (blurProgress * 0.7) // Reduce opacity as we scroll
        let scaleTransform = 1.0 + (blurProgress * 0.1) // Slight scale increase for blur effect
        
        tarotCardImageView.alpha = blurAlpha
        tarotCardImageView.transform = CGAffineTransform(scaleX: scaleTransform, y: scaleTransform)
        
        // Move card up as we scroll
        cardImageTopConstraint?.constant = -scrollOffset
        
        // Show/hide card title based on scroll position
        let titleAlpha = min(1.0, scrollOffset / 100) // Show title as we start scrolling
        cardTitleLabel.alpha = titleAlpha * (1.0 - blurProgress) // Hide as we approach sticky position
        
        // Handle sticky position transition
        if scrollOffset >= cardTransitionThreshold && !isCardSticky {
            // Transition to sticky header
            isCardSticky = true
            createStickyHeader()
        } else if scrollOffset < cardTransitionThreshold && isCardSticky {
            // Transition back to full card
            isCardSticky = false
            restoreFullCard()
        }
    }
    
    private func createStickyHeader() {
        UIView.animate(withDuration: 0.3) {
            // Move card to top 1/3 of screen
            let stickyHeight = self.view.bounds.height * 0.33
            self.cardImageTopConstraint?.constant = 0
            self.cardImageHeightConstraint?.constant = stickyHeight
            
            // Full blur effect
            self.tarotCardImageView.alpha = 0.3
            self.tarotCardImageView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            
            // Hide card title
            self.cardTitleLabel.alpha = 0
            
            self.view.layoutIfNeeded()
        }
    }
    
    private func restoreFullCard() {
        UIView.animate(withDuration: 0.3) {
            // Restore full screen card
            self.cardImageHeightConstraint?.constant = self.view.bounds.height
            
            // Clear blur effect
            self.tarotCardImageView.alpha = 1.0
            self.tarotCardImageView.transform = .identity
            
            // Show card title
            self.cardTitleLabel.alpha = 1.0
            
            self.view.layoutIfNeeded()
        }
    }
}
