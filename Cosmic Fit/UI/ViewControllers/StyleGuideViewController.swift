//
//  StyleGuideViewController.swift
//  Cosmic Fit
//
//  Blueprint Style Guide hub — 2×4 grid linking to eight blueprint sections.
//

import UIKit

final class StyleGuideViewController: UIViewController {

    // MARK: - Properties
    private var birthDate: Date?
    private var birthCity: String = ""
    private var birthCountry: String = ""
    private var originalChartViewController: NatalChartViewController?

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
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
                .foregroundColor: CosmicFitTheme.Colours.darkerCosmicGrey,
                .kern: 1.75
            ]
        )
        label.attributedText = attributedText
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "cb_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return iv
    }()

    private let mainHeadingLabel: UILabel = {
        let label = UILabel()
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .center
        label.numberOfLines = 2
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.75
        paragraphStyle.alignment = .center
        let attributedText = NSAttributedString(
            string: "YOUR COSMIC\nSTYLE GUIDE",
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.pageTitle),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attributedText
        return label
    }()

    private let topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        return view
    }()

    // MARK: - Grid Buttons (8 tiles, 2×4)
    private let styleCoreButton = StyleGuideGridButton(
        number: "1.",
        title: "Style Core",
        backgroundImageName: "grid_bg_1_placeholder"
    )
    private let texturesButton = StyleGuideGridButton(
        number: "2.",
        title: "The Textures",
        backgroundImageName: "grid_bg_2_placeholder"
    )
    private let paletteButton = StyleGuideGridButton(
        number: "3.",
        title: "The Palette",
        backgroundImageName: "grid_bg_3_placeholder"
    )
    private let occasionsButton = StyleGuideGridButton(
        number: "4.",
        title: "The Occasions",
        backgroundImageName: "grid_bg_4_placeholder"
    )
    private let hardwareButton = StyleGuideGridButton(
        number: "5.",
        title: "The Hardware",
        backgroundImageName: "grid_bg_1_placeholder"
    )
    private let codeButton = StyleGuideGridButton(
        number: "6.",
        title: "The Code",
        backgroundImageName: "grid_bg_2_placeholder"
    )
    private let accessoryButton = StyleGuideGridButton(
        number: "7.",
        title: "The Accessory",
        backgroundImageName: "grid_bg_3_placeholder"
    )
    private let patternButton = StyleGuideGridButton(
        number: "8.",
        title: "The Pattern",
        backgroundImageName: "grid_bg_4_placeholder"
    )

    private let bottomDividerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let bottomDividerLeft: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        return view
    }()

    private let bottomDividerRight: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        return view
    }()

    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "star_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return iv
    }()

    private var authNudgeBanner: AuthNudgeBannerView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupButtonActions()
        setupAuthNudge()
        navigationController?.delegate = self
        navigationController?.navigationBar.isHidden = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateForNudge),
            name: .cosmicFitAuthStateChanged,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
        updateNudgeVisibility()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Auth Nudge
    
    private func setupAuthNudge() {
        let banner = AuthNudgeBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.isHidden = true
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        
        banner.onTapped = { [weak self] in
            if let tabBar = self?.tabBarController {
                tabBar.selectedIndex = 0
            }
        }
        
        self.authNudgeBanner = banner
    }
    
    private func updateNudgeVisibility() {
        guard let banner = authNudgeBanner else { return }
        let shouldHide = CosmicFitAuthService.shared.isAuthenticated
            || UserDefaults.standard.bool(forKey: "CosmicFitDismissedAuthNudge")
        
        banner.isHidden = shouldHide
        banner.alpha = shouldHide ? 0 : 1
        banner.transform = .identity
        
        if !shouldHide {
            view.bringSubviewToFront(banner)
        }
    }
    
    @objc private func handleAuthStateForNudge() {
        updateNudgeVisibility()
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
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(aboutYouLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(mainHeadingLabel)
        contentView.addSubview(topDivider)

        contentView.addSubview(styleCoreButton)
        contentView.addSubview(texturesButton)
        contentView.addSubview(paletteButton)
        contentView.addSubview(occasionsButton)
        contentView.addSubview(hardwareButton)
        contentView.addSubview(codeButton)
        contentView.addSubview(accessoryButton)
        contentView.addSubview(patternButton)

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

        styleCoreButton.translatesAutoresizingMaskIntoConstraints = false
        texturesButton.translatesAutoresizingMaskIntoConstraints = false
        paletteButton.translatesAutoresizingMaskIntoConstraints = false
        occasionsButton.translatesAutoresizingMaskIntoConstraints = false
        hardwareButton.translatesAutoresizingMaskIntoConstraints = false
        codeButton.translatesAutoresizingMaskIntoConstraints = false
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false
        patternButton.translatesAutoresizingMaskIntoConstraints = false

        bottomDividerContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerLeft.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerRight.translatesAutoresizingMaskIntoConstraints = false
        starImageView.translatesAutoresizingMaskIntoConstraints = false

        let gridButtons = [
            (styleCoreButton, texturesButton),
            (paletteButton, occasionsButton),
            (hardwareButton, codeButton),
            (accessoryButton, patternButton)
        ]

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height - 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            aboutYouLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            aboutYouLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            iconImageView.topAnchor.constraint(equalTo: aboutYouLabel.bottomAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            mainHeadingLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            mainHeadingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainHeadingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            topDivider.topAnchor.constraint(equalTo: mainHeadingLabel.bottomAnchor, constant: 40),
            topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            topDivider.heightAnchor.constraint(equalToConstant: 1),
        ])

        // Row 1
        let firstLeft = gridButtons[0].0
        let firstRight = gridButtons[0].1
        NSLayoutConstraint.activate([
            firstLeft.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: 40),
            firstLeft.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstLeft.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
            firstLeft.heightAnchor.constraint(equalToConstant: 160),

            firstRight.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: 40),
            firstRight.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstRight.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
            firstRight.heightAnchor.constraint(equalToConstant: 160),
        ])

        // Rows 2–4
        for row in 1..<gridButtons.count {
            let left = gridButtons[row].0
            let right = gridButtons[row].1
            let prevLeft = gridButtons[row - 1].0

            NSLayoutConstraint.activate([
                left.topAnchor.constraint(equalTo: prevLeft.bottomAnchor, constant: 10),
                left.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                left.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
                left.heightAnchor.constraint(equalToConstant: 160),

                right.topAnchor.constraint(equalTo: prevLeft.bottomAnchor, constant: 10),
                right.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                right.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -25),
                right.heightAnchor.constraint(equalToConstant: 160),
            ])
        }

        // Bottom divider anchored to last row
        let lastLeft = gridButtons.last!.0
        NSLayoutConstraint.activate([
            bottomDividerContainer.topAnchor.constraint(equalTo: lastLeft.bottomAnchor, constant: 40),
            bottomDividerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bottomDividerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bottomDividerContainer.heightAnchor.constraint(equalToConstant: 30),
            bottomDividerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            bottomDividerLeft.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerLeft.leadingAnchor.constraint(equalTo: bottomDividerContainer.leadingAnchor),
            bottomDividerLeft.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -10),
            bottomDividerLeft.heightAnchor.constraint(equalToConstant: 1),

            bottomDividerRight.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerRight.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 10),
            bottomDividerRight.trailingAnchor.constraint(equalTo: bottomDividerContainer.trailingAnchor),
            bottomDividerRight.heightAnchor.constraint(equalToConstant: 1),

            starImageView.centerXAnchor.constraint(equalTo: bottomDividerContainer.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 24),
            starImageView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func setupButtonActions() {
        styleCoreButton.addTarget(self, action: #selector(styleCoreButtonTapped), for: .touchUpInside)
        texturesButton.addTarget(self, action: #selector(texturesButtonTapped), for: .touchUpInside)
        paletteButton.addTarget(self, action: #selector(paletteButtonTapped), for: .touchUpInside)
        occasionsButton.addTarget(self, action: #selector(occasionsButtonTapped), for: .touchUpInside)
        hardwareButton.addTarget(self, action: #selector(hardwareButtonTapped), for: .touchUpInside)
        codeButton.addTarget(self, action: #selector(codeButtonTapped), for: .touchUpInside)
        accessoryButton.addTarget(self, action: #selector(accessoryButtonTapped), for: .touchUpInside)
        patternButton.addTarget(self, action: #selector(patternButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func styleCoreButtonTapped() {
        navigateToDetail(section: .styleCore)
    }

    @objc private func texturesButtonTapped() {
        navigateToDetail(section: .textures)
    }

    @objc private func paletteButtonTapped() {
        navigateToDetail(section: .palette)
    }

    @objc private func occasionsButtonTapped() {
        navigateToDetail(section: .occasions)
    }

    @objc private func hardwareButtonTapped() {
        navigateToDetail(section: .hardware)
    }

    @objc private func codeButtonTapped() {
        navigateToDetail(section: .code)
    }

    @objc private func accessoryButtonTapped() {
        navigateToDetail(section: .accessory)
    }

    @objc private func patternButtonTapped() {
        navigateToDetail(section: .pattern)
    }

    // MARK: - Navigation
    private func navigateToDetail(section: StyleGuideDetailContent.StyleGuideSection) {
        guard let tabBarController = tabBarController as? CosmicFitTabBarController else {
            return
        }
        let detailVC = StyleGuideDetailViewController()
        let content = createContent(for: section)
        detailVC.configure(with: content)
        tabBarController.presentDetailViewController(detailVC, animated: true)
    }

    // MARK: - Section Content Factory

    private func createContent(for section: StyleGuideDetailContent.StyleGuideSection) -> StyleGuideDetailContent {
        switch section {

        case .styleCore:
            return StyleGuideDetailContent(
                sectionType: .styleCore,
                title: "Style Core",
                iconImageName: "style_core_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Your presence works best when you treat your wardrobe as a public language. While you value the heavy and the settled, you use those qualities to set a standard for the people around you. You move through a room with the composure of someone who is teaching others how to appreciate quality. Your style works best when it feels like a long-term social legacy. This kind of intentional curation looks like a gift you are giving to your community."
                    )
                ],
                customComponent: nil
            )

        case .textures:
            return StyleGuideDetailContent(
                sectionType: .textures,
                title: "The Textures",
                iconImageName: "fabric_guide_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: "The Good",
                        bodyText: "Go for fabrics with actual weight and integrity. Heavy gauge silks that feel cool and substantial provide the right anchor. Organic wools offer a proper architectural frame. Leather that is buttery and gains character with age belongs in your collection. They ground you, make you feel secure, and still look polished."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "The Bad",
                        bodyText: "Flimsy or disposable fabrics just do not suit you. If a material is scratchy or overly synthetic, it is a hard pass. Static-prone polyesters or stiff cottons that fight your natural movement are a distraction. If you have to spend your whole day messing with a garment to make it sit right, it is draining your energy."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "The Sweet Spot",
                        bodyText: "Your absolute peak is a blend of the sturdy and the soft. Choose items that look high quality at a glance but feel like a secret luxury when touched. If it does not feel like a treat for your skin, it does not belong in your wardrobe."
                    )
                ],
                customComponent: nil
            )

        case .palette:
            let colourPalette = ColourPaletteView()
            colourPalette.configure(with: ColourPaletteView.placeholder())
            // Dev-only: surface the anchor family name above each row so we
            // can visually confirm which colour is named what during
            // development. Spec §4.2 locks production to "no labels", so
            // the flag must stay gated on DEBUG and never ship to release.
            #if DEBUG
            colourPalette.showsDevelopmentAnchorNames = true
            #endif

            return StyleGuideDetailContent(
                sectionType: .palette,
                title: "The Palette",
                iconImageName: "colour_guide_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Your core colours are found in the natural world. Look for deep sage greens, sophisticated caramels, slate greys, and creamy neutrals. These tones provide a stable base for your personality to shine through. Accents work best when they feel weathered, muted, or mineral-toned."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Flashes of considered tones like oxidised gold, dusty rose, or a deep burnt saffron add depth. Keep these accents as a highlight rather than the main story. They show that you are adventurous under the surface. It is about creating a look that stays timeless. Aim for colours that feel organic and permanent."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "Personal Palette",
                        bodyText: ""
                    )
                ],
                customComponent: colourPalette
            )

        case .occasions:
            return StyleGuideDetailContent(
                sectionType: .occasions,
                title: "The Occasions",
                iconImageName: "style_core_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: "At Work",
                        bodyText: "Lean into your architectural side. Use clean lines and structured shapes to settle into the room. A properly made coat or a weighted layer that holds its shape is your best tool. You look best when you appear as the person who is definitely in charge."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "Intimate Energy",
                        bodyText: "Soften the edges when the sun goes down. Keep that solid base but introduce pieces with drape and mystery. Aim for quiet magnetism and close-range impact. Heavy silk or soft knits that move with you invite people to get a bit closer."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "Daily Movement",
                        bodyText: "Even casual looks need to look intentional. Ditch the mess for high-quality basics that allow you to move freely. You can do relaxed, but it should never look sloppy. Think of your daily look as the visionary on a day off: elevated and completely unbothered."
                    )
                ],
                customComponent: nil
            )

        case .hardware:
            return StyleGuideDetailContent(
                sectionType: .hardware,
                title: "The Hardware",
                iconImageName: "style_core_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: "The Metals",
                        bodyText: "Your energy requires hardware with actual presence. Look for brushed gold, matte silver, or hammered bronze. Choose pieces that feel like they have some history. Heavy chains and matte surfaces that soak up the light are your best options."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "The Stones",
                        bodyText: "Skip the perfectly clear gems. You suit stones that look like they were pulled directly from the earth. Raw emeralds, smoky quartz, and malachite work best. These natural inclusions make the pieces feel alive and connected to you."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "Tip",
                        bodyText: "One substantial anchor piece is always more powerful than a bunch of delicate items. Pick a signature like a heavy ring or a bold pendant and let it be the focal point."
                    )
                ],
                customComponent: nil
            )

        case .code:
            let codeContainer = UIStackView()
            codeContainer.axis = .vertical
            codeContainer.spacing = 40
            codeContainer.alignment = .fill
            codeContainer.distribution = .fill

            let leanIntoSection = DosAndDontsSectionView(
                title: "Lean Into",
                bulletPoints: [
                    "Trusting your body's first tactile reaction. If the fabric feels right against your skin, it is usually a win.",
                    "Investing in the highest quality version of a piece you can afford.",
                    "Using your style to communicate your values without saying a single word.",
                    "Sticking to the three-year test: only buy things you can see yourself loving in 2029."
                ]
            )
            codeContainer.addArrangedSubview(leanIntoSection)

            let avoidSection = DosAndDontsSectionView(
                title: "Avoid",
                bulletPoints: [
                    "Buying something just because it is a bargain. A deal is only a deal if the item is perfect.",
                    "Chasing trends that clash with your natural composure. If it feels like a costume, it will look like one.",
                    "Keeping your best pieces hidden. Your style works best when it is seen and shared.",
                    "Flimsy or disposable fabrics that lack actual integrity."
                ]
            )
            codeContainer.addArrangedSubview(avoidSection)

            let considerSection = DosAndDontsSectionView(
                title: "Consider",
                bulletPoints: [
                    "How your style acts as a conversation starter in your daily environment.",
                    "The way your physical home space influences your creative output.",
                    "Making sure your outfit is actually comfortable. If you are constantly tugging at your clothes, you lose your edge."
                ]
            )
            codeContainer.addArrangedSubview(considerSection)

            return StyleGuideDetailContent(
                sectionType: .code,
                title: "The Code",
                iconImageName: "dos_donts_glyph",
                textSections: [],
                customComponent: codeContainer
            )

        case .accessory:
            return StyleGuideDetailContent(
                sectionType: .accessory,
                title: "The Accessory",
                iconImageName: "style_core_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "One significant piece carries more weight than five minor ones. Whether it is a heavy watch or a perfectly made bag, let that item be the anchor. This creates a focal point that allows the rest of your look to stay quiet."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Accessories are where you introduce your most rigid lines. While your clothes might flow, your accessories should provide the structure. A stiff bag or a firm leather strap acts as the frame for your more fluid choices."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Think about the sound and scent of your accessories. The weight of a heavy buckle or the specific smell of high-quality leather adds to the vibe. Style is a total sensory environment."
                    )
                ],
                customComponent: nil
            )

        case .pattern:
            return StyleGuideDetailContent(
                sectionType: .pattern,
                title: "The Pattern",
                iconImageName: "style_core_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "You do not really do busy prints. Anything too frantic fights your energy and looks forced. Your patterns need to feel like they have a pulse: organic, slightly blurred, or naturally occurring."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Look for large-scale and soft-focus prints. Marble textures or shadow checks where the lines are not quite sharp work well. You also suit classics like a large windowpane check in your neutral palette. The goal is a pattern that looks painted on rather than factory-made."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: nil,
                        bodyText: "Avoid tiny repetitive prints like polka dots. They look cluttered against your sophisticated aura. Stay away from anything neon or synthetic. If a pattern looks like it belongs on a disposable holiday shirt, it does not belong in your life."
                    ),
                    StyleGuideDetailContent.TextSection(
                        subheading: "Tip",
                        bodyText: "Use pattern as a texture. A tonal jacquard weave or a subtle embossed print is your secret weapon. It adds depth without screaming for attention."
                    )
                ],
                customComponent: nil
            )
        }
    }
}

// MARK: - StyleGuideGridButton
final class StyleGuideGridButton: UIButton {

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.largeTitle, weight: .bold)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .left
        return label
    }()

    private let buttonTitleLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .semibold)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()

    private let backgroundPatternView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.alpha = 0.15
        view.isUserInteractionEnabled = false
        return view
    }()

    init(number: String, title: String, backgroundImageName: String) {
        super.init(frame: .zero)
        numberLabel.text = number
        buttonTitleLabel.text = title
        numberLabel.isUserInteractionEnabled = false
        buttonTitleLabel.isUserInteractionEnabled = false
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
        layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
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
            backgroundPatternView.topAnchor.constraint(equalTo: topAnchor),
            backgroundPatternView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundPatternView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundPatternView.bottomAnchor.constraint(equalTo: buttonTitleLabel.topAnchor, constant: -10),

            numberLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

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
extension StyleGuideViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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
