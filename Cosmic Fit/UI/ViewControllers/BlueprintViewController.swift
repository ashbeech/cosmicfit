//
//  BlueprintViewController.swift
//  Cosmic Fit
//
//  Redesigned with placeholder layout for new visual structure
//

import UIKit

final class BlueprintViewController: UIViewController {
    
    // MARK: - Properties
    private var birthDate: Date?
    private var birthCity: String = ""
    private var birthCountry: String = ""
    private var originalChartViewController: NatalChartViewController?
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let aboutYouLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        
        let attributedText = NSAttributedString(
            string: "ABOUT YOU",
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
        iv.image = UIImage(named: "cb_icon_placeholder") // Placeholder image
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    private let mainHeadingLabel: UILabel = {
        let label = UILabel()
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .center
        label.numberOfLines = 2
        
        // Use attributed string for custom line height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.75
        paragraphStyle.alignment = .center
        
        let attributedText = NSAttributedString(
            string: "YOUR COSMIC\nBLUEPRINT",
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.pageTitle),
                .foregroundColor: CosmicFitTheme.Colors.cosmicBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attributedText
        
        return label
    }()
    
    private let topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    private let styleEssenceLabel: UILabel = {
        let label = UILabel()
        label.text = "Style Essence"
        label.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.subheadline, weight: .regular)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .center
        return label
    }()
    
    private let bodyTextLabel: UILabel = {
        let label = UILabel()
        label.text = "You've got that intuitive elegance that feels both grounded and gently dreamy. Quality lands through texture and quiet proportion, so your presence reads luxurious without effort. There is a soft confidence in the way you move, a tactile-first approach that makes people feel both soothed and curious. Fewer, better pieces that age well are your language."
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let middleDivider: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    // Grid buttons
    private let styleCoreButton = BlueprintGridButton(
        number: "1.",
        title: "Style Core",
        backgroundImageName: "grid_bg_1_placeholder"
    )
    
    private let fabricGuideButton = BlueprintGridButton(
        number: "2.",
        title: "Fabric Guide",
        backgroundImageName: "grid_bg_2_placeholder"
    )
    
    private let colourGuideButton = BlueprintGridButton(
        number: "3.",
        title: "Colour Guide",
        backgroundImageName: "grid_bg_3_placeholder"
    )
    
    private let dosAndDontsButton = BlueprintGridButton(
        number: "4.",
        title: "Do's & Don'ts",
        backgroundImageName: "grid_bg_4_placeholder"
    )
    
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
        iv.image = UIImage(named: "star_icon_placeholder") // Placeholder image
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupButtonActions()
        
        // Set navigation controller delegate for custom transitions
        navigationController?.delegate = self
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Re-set delegate when returning to this view
        navigationController?.delegate = self
    }
    
    // MARK: - Configuration
    func configure(with content: String,
                   birthDate: Date?,
                   birthCity: String,
                   birthCountry: String,
                   originalChartViewController: NatalChartViewController?) {
        self.birthDate = birthDate
        self.birthCity = birthCity
        self.birthCountry = birthCountry
        self.originalChartViewController = originalChartViewController
        
        // For now, we're using placeholder text
        // Later, this will be replaced with dynamic content generation
        print("✅ Blueprint configured with placeholder content")
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all subviews to contentView
        contentView.addSubview(aboutYouLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(mainHeadingLabel)
        contentView.addSubview(topDivider)
        contentView.addSubview(styleEssenceLabel)
        //contentView.addSubview(bodyTextLabel)
        contentView.addSubview(middleDivider)
        contentView.addSubview(styleCoreButton)
        contentView.addSubview(fabricGuideButton)
        contentView.addSubview(colourGuideButton)
        contentView.addSubview(dosAndDontsButton)
        contentView.addSubview(bottomDividerContainer)
        bottomDividerContainer.addSubview(bottomDividerLeft)
        bottomDividerContainer.addSubview(bottomDividerRight)
        bottomDividerContainer.addSubview(starImageView)
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        aboutYouLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        mainHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        styleEssenceLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyTextLabel.translatesAutoresizingMaskIntoConstraints = false
        middleDivider.translatesAutoresizingMaskIntoConstraints = false
        styleCoreButton.translatesAutoresizingMaskIntoConstraints = false
        fabricGuideButton.translatesAutoresizingMaskIntoConstraints = false
        colourGuideButton.translatesAutoresizingMaskIntoConstraints = false
        dosAndDontsButton.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerLeft.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerRight.translatesAutoresizingMaskIntoConstraints = false
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create container for body text padding
        let bodyTextContainer = UIView()
        bodyTextContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyTextContainer)
        bodyTextContainer.addSubview(bodyTextLabel)
        
        NSLayoutConstraint.activate([
            // ScrollView - starts below menu bar (menu bar is -10 from safe area, so 40-10=30)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height - 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // About You Label (~60px from top)
            aboutYouLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            aboutYouLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // CB Icon
            iconImageView.topAnchor.constraint(equalTo: aboutYouLabel.bottomAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Main Heading
            mainHeadingLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            mainHeadingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainHeadingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Top Divider (~40px spacing)
            topDivider.topAnchor.constraint(equalTo: mainHeadingLabel.bottomAnchor, constant: 40),
            topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            topDivider.heightAnchor.constraint(equalToConstant: 1),
            
            // Style Essence Label (~40px spacing)
            styleEssenceLabel.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: 40),
            styleEssenceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Body Text Container (~40px spacing)
            bodyTextContainer.topAnchor.constraint(equalTo: styleEssenceLabel.bottomAnchor, constant: 40),
            bodyTextContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bodyTextContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                        
            // Body Text with reduced padding (10px less on each side)
            bodyTextLabel.topAnchor.constraint(equalTo: bodyTextContainer.topAnchor),
            bodyTextLabel.bottomAnchor.constraint(equalTo: bodyTextContainer.bottomAnchor),
            bodyTextLabel.leadingAnchor.constraint(equalTo: bodyTextContainer.leadingAnchor, constant: 10),
            bodyTextLabel.trailingAnchor.constraint(equalTo: bodyTextContainer.trailingAnchor, constant: -10),
            
            // Middle Divider (~40px spacing)
            middleDivider.topAnchor.constraint(equalTo: bodyTextContainer.bottomAnchor, constant: 40),
            middleDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            middleDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            middleDivider.heightAnchor.constraint(equalToConstant: 1),
            
            // Grid Buttons (2x2 layout, ~40px from divider)
            // Row 1
            styleCoreButton.topAnchor.constraint(equalTo: middleDivider.bottomAnchor, constant: 40),
            styleCoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            styleCoreButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
            styleCoreButton.heightAnchor.constraint(equalToConstant: 160),
            
            fabricGuideButton.topAnchor.constraint(equalTo: middleDivider.bottomAnchor, constant: 40),
            fabricGuideButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fabricGuideButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
            fabricGuideButton.heightAnchor.constraint(equalToConstant: 160),
            
            // Row 2
            colourGuideButton.topAnchor.constraint(equalTo: styleCoreButton.bottomAnchor, constant: 10),
            colourGuideButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            colourGuideButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
            colourGuideButton.heightAnchor.constraint(equalToConstant: 160),
            
            dosAndDontsButton.topAnchor.constraint(equalTo: fabricGuideButton.bottomAnchor, constant: 10),
            dosAndDontsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            dosAndDontsButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
            dosAndDontsButton.heightAnchor.constraint(equalToConstant: 160),
            
            // Bottom Divider Container (~40px spacing)
            bottomDividerContainer.topAnchor.constraint(equalTo: colourGuideButton.bottomAnchor, constant: 40),
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
    
    private func setupButtonActions() {
        styleCoreButton.addTarget(self, action: #selector(styleCoreButtonTapped), for: .touchUpInside)
        fabricGuideButton.addTarget(self, action: #selector(fabricGuideButtonTapped), for: .touchUpInside)
        colourGuideButton.addTarget(self, action: #selector(colourGuideButtonTapped), for: .touchUpInside)
        dosAndDontsButton.addTarget(self, action: #selector(dosAndDontsButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Button Actions
    @objc private func styleCoreButtonTapped() {
        print("🎯 Style Core button tapped")
        navigateToDetail(section: .styleCore)
    }
    
    @objc private func fabricGuideButtonTapped() {
        print("🎯 Fabric Guide button tapped")
        navigateToDetail(section: .fabricGuide)
    }
    
    @objc private func colourGuideButtonTapped() {
        print("🎯 Colour Guide button tapped")
        navigateToDetail(section: .colourGuide)
    }
    
    @objc private func dosAndDontsButtonTapped() {
        print("🎯 Do's & Don'ts button tapped")
        navigateToDetail(section: .dosAndDonts)
    }
    
    // MARK: - Navigation
    private func navigateToDetail(section: BlueprintDetailContent.BlueprintSection) {
        guard let tabBarController = tabBarController as? CosmicFitTabBarController else {
            print("❌ Cannot find CosmicFitTabBarController")
            return
        }
        
        let detailVC = BlueprintDetailViewController()
        let content = createContent(for: section)
        detailVC.configure(with: content)
        
        // Use the tab bar controller's child VC presentation
        tabBarController.presentDetailViewController(detailVC, animated: true)
    }
    
    private func createContent(for section: BlueprintDetailContent.BlueprintSection) -> BlueprintDetailContent {
        switch section {
        case .styleCore:
            return BlueprintDetailContent(
                sectionType: .styleCore,
                title: "Style Core",
                iconImageName: "style_core_glyph",
                textSections: [
                    BlueprintDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Placeholder content for Style Core. This will be dynamically generated based on the user's natal chart interpretation."
                    )
                ],
                customComponent: nil
            )
            
        case .fabricGuide:
            return BlueprintDetailContent(
                sectionType: .fabricGuide,
                title: "Fabric Guide",
                iconImageName: "fabric_guide_glyph",
                textSections: [
                    BlueprintDetailContent.TextSection(
                        subheading: "Activating Textures",
                        bodyText: "Rich natural fibers with substance, smooth surfaces with weight, fabrics with gentle movement that follow your body's natural lines. Beautiful drape, organic variation, luxurious hand feel, just enough richness to make you feel genuinely pampered."
                    ),
                    BlueprintDetailContent.TextSection(
                        subheading: "Regulating Textures",
                        bodyText: "Natural fibers with substance, soft textures with good drape, anything that feels substantial while remaining light."
                    ),
                    BlueprintDetailContent.TextSection(
                        subheading: "Draining Textures",
                        bodyText: "Anything too stiff, synthetic, or overly clingy against your skin, plus fabrics that need constant fussing. If it's fighting you or feels like it's trying too hard, it's not for you."
                    ),
                    BlueprintDetailContent.TextSection(
                        subheading: "Your sweet spot",
                        bodyText: "Materials that feel like a cozy hug, sturdy enough to support you but soft enough to live in, fancy but not precious."
                    )
                ],
                customComponent: nil
            )
            
        case .colourGuide:
            let colorPalette = ColorPaletteView.createPlaceholderPalette()
            
            return BlueprintDetailContent(
                sectionType: .colourGuide,
                title: "Colour Guide",
                iconImageName: "colour_guide_glyph",
                textSections: [
                    BlueprintDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Rich natural fibers with substance, smooth surfaces with weight, fabrics with gentle movement that follow your body's natural lines. Beautiful drape, organic variation, luxurious hand feel, just enough richness to make you feel genuinely pampered."
                    ),
                    BlueprintDetailContent.TextSection(
                        subheading: "Current Colour Phase",
                        bodyText: "You're settling deeper into your natural palette of rich, luxurious earth tones, but with this soft, dreamy edge. Think creamy caramels, deep sage greens, sophisticated warm browns, and those pearl greys that feel both solid and ethereal. You're getting braver with warmer, more expansive touches like golden undertones and dusty roses, plus little hits of adaptable colors that can roll with whatever your day brings."
                    ),
                    BlueprintDetailContent.TextSection(
                        subheading: "Personal Palette",
                        bodyText: ""
                    )
                ],
                customComponent: colorPalette
            )
            
        case .dosAndDonts:
            // Create custom component with three sections
            let dosAndDontsContainer = UIStackView()
            dosAndDontsContainer.axis = .vertical
            dosAndDontsContainer.spacing = 40
            dosAndDontsContainer.alignment = .fill
            dosAndDontsContainer.distribution = .fill
            
            // Lean into section
            let leanIntoSection = DosAndDontsSectionView(
                title: "Lean into",
                bulletPoints: [
                    "Your first gut reaction about how stuff feels, your body knows what works",
                    "Investing in pieces that feel solid and well-made",
                    "Layering for both comfort and visual interest",
                    "Picking colors that make you feel grounded and confident",
                    "Honouring your need for both beauty and practicality"
                ]
            )
            dosAndDontsContainer.addArrangedSubview(leanIntoSection)
            
            // Release section
            let releaseSection = DosAndDontsSectionView(
                title: "Release",
                bulletPoints: [
                    "Trends that clash with your natural elegance",
                    "Settling on fit for the sake of a \"good deal\"",
                    "Overcomplicating outfits, your power is in simplicity with depth",
                    "Ignoring your comfort needs for looks",
                    "Rushing big style decisions"
                ]
            )
            dosAndDontsContainer.addArrangedSubview(releaseSection)
            
            // Watch for section
            let watchForSection = DosAndDontsSectionView(
                title: "Watch for",
                bulletPoints: [
                    "Perfectionist tendencies that limit your experimenting",
                    "Going for \"safe\" choices when your gut suggests something bolder",
                    "Underestimating your natural magnetism and playing smaller than you are"
                ]
            )
            dosAndDontsContainer.addArrangedSubview(watchForSection)
            
            return BlueprintDetailContent(
                sectionType: .dosAndDonts,
                title: "Do's & Donts",
                iconImageName: "dos_donts_glyph",
                textSections: [],
                customComponent: dosAndDontsContainer
            )
        }
    }
}

// MARK: - BlueprintGridButton
final class BlueprintGridButton: UIButton {
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.largeTitle, weight: .bold)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .left
        return label
    }()
    
    private let buttonTitleLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .semibold)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()
    
    private let backgroundPatternView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.alpha = 0.15 // Faded effect
        view.isUserInteractionEnabled = false // Allow touches to pass through
        return view
    }()
    
    init(number: String, title: String, backgroundImageName: String) {
        super.init(frame: .zero)
        
        numberLabel.text = number
        buttonTitleLabel.text = title
        
        // Disable user interaction on labels so button receives all touches
        numberLabel.isUserInteractionEnabled = false
        buttonTitleLabel.isUserInteractionEnabled = false
        
        // Apply tiling pattern background
        if let glyphImage = UIImage(named: backgroundImageName) {
            backgroundPatternView.backgroundColor = UIColor(patternImage: glyphImage)
        }
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        layer.borderColor = CosmicFitTheme.Colors.cosmicBlue.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 12
        clipsToBounds = true
        
        addSubview(backgroundPatternView)
        addSubview(numberLabel)
        addSubview(buttonTitleLabel)
        
        backgroundPatternView.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Background pattern - fills from top-left, stops before title
            backgroundPatternView.topAnchor.constraint(equalTo: topAnchor),
            backgroundPatternView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundPatternView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundPatternView.bottomAnchor.constraint(equalTo: buttonTitleLabel.topAnchor, constant: -10),
            
            // Number label (top-left with padding)
            numberLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            // Title label (bottom-left with padding)
            buttonTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            buttonTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            buttonTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.6 : 1.0
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension BlueprintViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // This handles tab transitions (Daily Fit <-> Cosmic Blueprint)
        // For sub-pages, we use UIViewControllerTransitioningDelegate instead
        switch operation {
        case .push:
            return VerticalSlideAnimator(operation: .push)
        case .pop:
            return VerticalSlideAnimator(operation: .pop)
        case .none:
            return nil
        @unknown default:
            return nil
        }
    }
}
