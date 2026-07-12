//
//  StyleGuideViewController.swift
//  Cosmic Fit
//
//  Style Guide hub — 2×4 grid linking to eight sections of the user's CosmicBlueprint.
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
        CosmicFitTheme.stylePageEyebrowLabel(label, text: "ABOUT YOU", color: CosmicFitTheme.Colours.cosmicBlue)
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "style_guide_glyph")
        return iv
    }()

    private let mainHeadingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.attributedText = CosmicFitTheme.PageMainTitleTypography.attributedString(
            "YOUR COSMIC\nSTYLE GUIDE"
        )
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
        title: "The Blueprint",
        backgroundImageName: "style_core_glyph"
    )
    private let texturesButton = StyleGuideGridButton(
        number: "3.",
        title: "The Textures",
        backgroundImageName: "textures_glyph"
    )
    private let paletteButton = StyleGuideGridButton(
        number: "2.",
        title: "The Palette",
        backgroundImageName: "palette_glyph"
    )
    private let occasionsButton = StyleGuideGridButton(
        number: "4.",
        title: "The Occasions",
        backgroundImageName: "occasion_glyph"
    )
    private let hardwareButton = StyleGuideGridButton(
        number: "5.",
        title: "The Hardware",
        backgroundImageName: "hardware_glyph"
    )
    private let codeButton = StyleGuideGridButton(
        number: "6.",
        title: "The Code",
        backgroundImageName: "code_glyph"
    )
    private let accessoryButton = StyleGuideGridButton(
        number: "7.",
        title: "The Accessory",
        backgroundImageName: "accessory_glyph"
    )
    private let patternButton = StyleGuideGridButton(
        number: "8.",
        title: "The Pattern",
        backgroundImageName: "pattern_glyph"
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
            let authGateVC = AuthGateViewController()
            let nav = UINavigationController(rootViewController: authGateVC)
            nav.navigationBar.isHidden = true
            nav.modalPresentationStyle = .pageSheet
            self?.present(nav, animated: true)
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
            (styleCoreButton, paletteButton),
            (texturesButton, occasionsButton),
            (hardwareButton, codeButton),
            (accessoryButton, patternButton)
        ]

        var scrollHorizontalConstraints: [NSLayoutConstraint]
        if CosmicFitTheme.Layout.isPad {
            let scrollFillWidth = scrollView.widthAnchor.constraint(equalTo: view.widthAnchor)
            scrollFillWidth.priority = .defaultHigh
            scrollHorizontalConstraints = [
                scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                scrollFillWidth,
                scrollView.widthAnchor.constraint(lessThanOrEqualToConstant: CosmicFitTheme.Layout.maxContentWidth),
            ]
        } else {
            scrollHorizontalConstraints = [
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ]
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height - 10),
        ] + scrollHorizontalConstraints + [
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            aboutYouLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            aboutYouLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            iconImageView.topAnchor.constraint(
                equalTo: aboutYouLabel.bottomAnchor,
                constant: CosmicFitTheme.StyleGuideHubGlyphLayout.spacingAbove
            ),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: CosmicFitTheme.StyleGuideHubGlyphLayout.width),
            iconImageView.heightAnchor.constraint(equalToConstant: CosmicFitTheme.StyleGuideHubGlyphLayout.height),

            mainHeadingLabel.topAnchor.constraint(
                equalTo: iconImageView.bottomAnchor,
                constant: CosmicFitTheme.StyleGuideHubGlyphLayout.spacingBelow
            ),
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

        // Bottom divider anchored to last row — extra scroll tail so the star isn’t clipped
        // by the tab bar (scrollView extends to `view.bottomAnchor`).
        let lastLeft = gridButtons.last!.0
        NSLayoutConstraint.activate([
            bottomDividerContainer.topAnchor.constraint(equalTo: lastLeft.bottomAnchor, constant: 40),
            bottomDividerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bottomDividerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bottomDividerContainer.heightAnchor.constraint(equalToConstant: 30),
            bottomDividerContainer.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -CosmicFitTheme.Layout.scrollContentBottomInset
            ),

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

    // MARK: - Live Palette Data

    /// Attempts to build a live `PaletteGrid` from the current user's
    /// persisted `CosmicBlueprint`. Returns nil when no valid Style Guide data is
    /// available (not yet generated, decode failure, empty palette, etc.),
    /// signalling the caller to fall back to `ColourPaletteView.placeholder()`.
    ///
    /// Validation: only `coreColours.isEmpty` is checked because a zero-core
    /// grid is visually broken (entire top band empty), warranting fallback.
    /// A short accent band (0–3 accents) is handled gracefully by
    /// `PaletteGridViewModel.build` which pads with empty rows — acceptable
    /// UI so no fallback is needed.
    ///
    /// Called from `createContent(for:)` on the main thread (button-tap
    /// handler). The synchronous `BlueprintStorage.load()` is fast (<1ms
    /// for a single-user JSON file) and avoids async complexity.
    private func buildLivePaletteGrid() -> PaletteGrid? {
        guard let blueprint = BlueprintStorage.shared.load() else {
            print("[Palette] No persisted Style Guide — using placeholder grid")
            return nil
        }
        let section = blueprint.palette
        guard !section.coreColours.isEmpty else {
            print("[Palette] Style Guide loaded but palette has no core colours — using placeholder grid")
            return nil
        }
        print("[Palette] Live Style Guide palette loaded — \(section.coreColours.count) core, \(section.accentColours.count) accent")
        return PaletteGridViewModel.build(from: section)
    }

    // MARK: - Section Content Factory

    /// Loads the persisted Style Guide (`CosmicBlueprint`) once per detail-view tap and routes each
    /// section to the corresponding field. Falls back to
    /// placeholder copy when no data is available (not yet generated,
    /// narrative cache empty, etc.).
    private func createContent(for section: StyleGuideDetailContent.StyleGuideSection) -> StyleGuideDetailContent {
        let bp = BlueprintStorage.shared.load()

        switch section {

        case .styleCore:
            let body = bp?.styleCore.narrativeText.nonEmpty
                ?? "Your presence works best when you treat your wardrobe as a public language. While you value the heavy and the settled, you use those qualities to set a standard for the people around you. You move through a room with the composure of someone who is teaching others how to appreciate quality. Your style works best when it feels like a long-term social legacy. This kind of intentional curation looks like a gift you are giving to your community."

            return StyleGuideDetailContent(
                sectionType: .styleCore,
                title: "The Blueprint",
                iconImageName: "style_core_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(subheading: nil, bodyText: body)
                ],
                customComponent: nil,
                tearPlacement: .afterStackSubview(index: 0),
                // SG-2 Phase 2.5 output-contract slots (nil until SG-3 fills them).
                sectionIntro: bp?.styleCore.sectionIntro,
                rankedItems: bp?.styleCore.rankedItems,
                tests: bp?.styleCore.tests,
                traps: bp?.styleCore.traps,
                closing: bp?.closing
            )

        case .textures:
            let good = bp?.textures.goodText.nonEmpty
                ?? "You demand fabrics with actual weight, gravity, and structural integrity. A heavy gauge silk that feels cool and substantial against the skin provides the perfect anchor for your wardrobe. An organic wool offers a proper architectural frame, holding its shape without clinging to the body. A buttery leather jacket that gains character with age absolutely belongs in your daily rotation. These substantial textiles ground your look, make you feel entirely secure, and ensure you always look ruthlessly polished."
            let bad = bp?.textures.badText.nonEmpty
                ?? "Flimsy, disposable fabrics simply have no place in your wardrobe. If a material is scratchy, overly synthetic, or lacks structural integrity, you must give it a hard pass. A static-prone polyester or a stiff cotton that fights your natural movement acts as a constant, irritating distraction. Clothing should never feel like a battle against your own body. If you have to spend your entire day adjusting a garment just to make it sit right, it is draining the life out of your look."
            let sweet = bp?.textures.sweetSpotText.nonEmpty
                ?? "Your absolute peak is a blend of the sturdy and the soft. Choose items that look high quality at a glance but feel like a secret luxury when touched. If it does not feel like a treat for your skin, it does not belong in your wardrobe."

            return StyleGuideDetailContent(
                sectionType: .textures,
                title: "The Textures",
                iconImageName: "textures_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(subheading: "The Good", bodyText: good),
                    StyleGuideDetailContent.TextSection(subheading: "The Bad", bodyText: bad),
                    StyleGuideDetailContent.TextSection(subheading: "The Sweet Spot", bodyText: sweet)
                ],
                customComponent: nil,
                tearPlacement: .offsetIntoStackSubview(index: 3, fraction: 0.12)
            )

        case .palette:
            let colourPalette = ColourPaletteView()
            let grid = buildLivePaletteGrid() ?? ColourPaletteView.placeholder()
            colourPalette.configure(with: grid)


            let paletteContainer = UIView()
            paletteContainer.translatesAutoresizingMaskIntoConstraints = false
            paletteContainer.addSubview(colourPalette)
            colourPalette.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                colourPalette.topAnchor.constraint(equalTo: paletteContainer.topAnchor),
                colourPalette.leadingAnchor.constraint(equalTo: paletteContainer.leadingAnchor),
                colourPalette.trailingAnchor.constraint(equalTo: paletteContainer.trailingAnchor),
                colourPalette.bottomAnchor.constraint(equalTo: paletteContainer.bottomAnchor),
            ])

            let narrativeText = bp?.palette.narrativeText.nonEmpty
            let para1 = narrativeText
                ?? "The colours that flatter you most are pulled straight from the natural world. You look incredible in a deep sage green, a sophisticated caramel, a slate grey, or a creamy neutral. These grounding tones provide a brilliantly stable base for your wardrobe, allowing the texture of the fabric to take centre stage. Your accent colours work best when they feel distinctly weathered, beautifully muted, or richly mineral-toned. Build your rotation around these earthy shades to guarantee a consistently expensive finish."

            var textSections = [
                StyleGuideDetailContent.TextSection(subheading: nil, bodyText: para1)
            ]
            if narrativeText == nil {
                textSections.append(StyleGuideDetailContent.TextSection(
                    subheading: nil,
                    bodyText: "Flashes of considered tones like oxidised gold, dusty rose, or a deep burnt saffron add depth. Keep these accents as a highlight rather than the main story. They show that you are adventurous under the surface. It is about creating a look that stays timeless. Aim for colours that feel organic and permanent."
                ))
            }
            return StyleGuideDetailContent(
                sectionType: .palette,
                title: "The Palette",
                iconImageName: "palette_glyph",
                textSections: textSections,
                customComponent: paletteContainer,
                tearPlacement: .paletteAfterFirstRow
            )

        case .occasions:
            let work = bp?.occasions.workText.nonEmpty
                ?? "Lean into your architectural side. Use clean lines and structured shapes to settle into the room. A properly made coat or a weighted layer that holds its shape is your best tool. You look best when you appear as the person who is definitely in charge."
            let intimate = bp?.occasions.intimateText.nonEmpty
                ?? "Soften the edges when the sun goes down. Keep that solid base but introduce pieces with drape and mystery. Aim for quiet magnetism and close-range impact. Heavy silk or soft knits that move with you invite people to get a bit closer."
            let daily = bp?.occasions.dailyText.nonEmpty
                ?? "Even your most casual weekend looks require a distinct sense of intention. Ditch the messy loungewear for high-quality, beautifully cut basics that allow you to move freely without losing your shape. You do relaxed dressing brilliantly, but the execution must never look sloppy or unfinished. Think of your daily uniform as the wardrobe of a fashion insider on a day off. You always step out looking completely unbothered, incredibly comfortable, and ruthlessly put together."

            return StyleGuideDetailContent(
                sectionType: .occasions,
                title: "The Occasions",
                iconImageName: "occasion_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(subheading: "At Work", bodyText: work),
                    StyleGuideDetailContent.TextSection(subheading: "Intimate Energy", bodyText: intimate),
                    StyleGuideDetailContent.TextSection(subheading: "Daily Movement", bodyText: daily)
                ],
                customComponent: nil,
                tearPlacement: .offsetIntoStackSubview(index: 3, fraction: 0.12)
            )

        case .hardware:
            let metals = bp?.hardware.metalsText.nonEmpty
                ?? "Your wardrobe demands hardware with a genuine, undeniable physical presence. You look spectacular in a brushed gold, a matte silver, or a heavily hammered bronze. Choose heavy zippers, thick buckles, and chunky rings that feel as though they carry some real history. A heavy chain or a matte surface that absorbs the light rather than reflecting it cheaply will always be your best option. Invest in substantial metals to give your clothing an instantly expensive, perfectly weighted finish."
            let stones = bp?.hardware.stonesText.nonEmpty
                ?? "Skip the perfectly clear gems. You suit stones that look like they were pulled directly from the earth. Raw emeralds, smoky quartz, and malachite work best. These natural inclusions make the pieces feel alive and connected to you."
            let tip = bp?.hardware.tipText.nonEmpty
                ?? "Your hardware dictates the entire attitude of your outfit. Stacking a dozen flimsy chains simply looks chaotic. You need one substantial, uncompromising anchor piece to centre the look. Slide on a heavy brushed steel signet ring or clasp a thick, sculptural silver collar around your neck. Let that single, heavy metal focal point speak for itself. Your accessories should command attention, not whisper for it."

            return StyleGuideDetailContent(
                sectionType: .hardware,
                title: "The Hardware",
                iconImageName: "hardware_glyph",
                textSections: [
                    StyleGuideDetailContent.TextSection(subheading: "The Metals", bodyText: metals),
                    StyleGuideDetailContent.TextSection(subheading: "The Stones", bodyText: stones),
                    StyleGuideDetailContent.TextSection(subheading: "Tip", bodyText: tip)
                ],
                customComponent: nil,
                tearPlacement: .offsetIntoStackSubview(index: 3, fraction: 0.15),
                // SG-2 Phase 2.5 output-contract slots (nil until SG-3 fills them).
                sectionIntro: bp?.hardware.sectionIntro,
                rankedItems: bp?.hardware.rankedItems,
                tests: bp?.hardware.tests,
                traps: bp?.hardware.traps
            )

        case .code:
            let codeContainer = UIStackView()
            codeContainer.axis = .vertical
            codeContainer.spacing = 40
            codeContainer.alignment = .fill
            codeContainer.distribution = .fill

            let leanIntoItems = bp?.code.leanInto.nilIfEmpty ?? [
                "Trusting your body's first tactile reaction. If the fabric feels right against your skin, it is usually a win.",
                "Investing in the highest quality version of a piece you can afford.",
                "Using your style to communicate your values without saying a single word.",
                "Sticking to the three-year test: only buy things you can see yourself loving in 2029."
            ]
            codeContainer.addArrangedSubview(DosAndDontsSectionView(title: "Lean Into", bulletPoints: leanIntoItems))

            let avoidItems = bp?.code.avoid.nilIfEmpty ?? [
                "Buying something just because it is a bargain. A deal is only a deal if the item is perfect.",
                "Chasing trends that clash with your natural composure. If it feels like a costume, it will look like one.",
                "Keeping your best pieces hidden. Your style works best when it is seen and shared.",
                "Flimsy, disposable synthetic fabrics that completely lack structural integrity or a decent tactile finish."
            ]
            codeContainer.addArrangedSubview(DosAndDontsSectionView(title: "Avoid", bulletPoints: avoidItems))

            let considerItems = bp?.code.consider.nilIfEmpty ?? [
                "Introducing heavy statement hardware and exaggerated silhouettes to act as immediate conversation starters in your daily routine.",
                "Dressing your physical living space in the exact same rich, tactile fabrics you wear to fuel your creative output.",
                "Making sure your outfit is actually comfortable. If you are constantly tugging at your clothes, you lose your edge."
            ]
            codeContainer.addArrangedSubview(DosAndDontsSectionView(title: "Consider", bulletPoints: considerItems))

            return StyleGuideDetailContent(
                sectionType: .code,
                title: "The Code",
                iconImageName: "code_glyph",
                textSections: [],
                customComponent: codeContainer,
                tearPlacement: .codeOffsetIntoLeanIntoBullet(bulletIndex: 2, fraction: 0.5)
            )

        case .accessory:
            let fallback = [
                "The right accessory completely rewrites the geometry of your outfit. Throwing on five minor, forgettable additions dilutes your visual impact. Instead, you must ground your silhouette with one incredibly significant, meticulously constructed piece. Fasten a heavy, oversized chronograph to your wrist or grip the structural leather handle of a perfectly made architectural bag. This creates a decisive focal point that allows the rest of your garments to drape quietly. Make your one addition impossible to ignore.",
                "Accessories are where you introduce your most rigid lines. While your clothes might flow, your accessories should provide the structure. A stiff bag or a firm leather strap acts as the frame for your more fluid choices.",
                "Think about the sound and scent of your accessories. The weight of a heavy buckle or the specific smell of high-quality leather adds to the vibe. Style is a total sensory environment."
            ]
            let paragraphs = bp?.accessory.paragraphs.nilIfEmpty ?? fallback

            return StyleGuideDetailContent(
                sectionType: .accessory,
                title: "The Accessory",
                iconImageName: "accessory_glyph",
                textSections: paragraphs.map {
                    StyleGuideDetailContent.TextSection(subheading: nil, bodyText: $0)
                },
                customComponent: nil,
                tearPlacement: .pageContentFraction(0.5)
            )

        case .pattern:
            let narrative = bp?.pattern.narrativeText.nonEmpty
                ?? "Frantic prints kill a good outfit. Busy, high-contrast motifs fight your presence and look manufactured. Shift your focus toward textiles with a living pulse. Seek out watercolour bleeds, moiré silks, or marble effects over rigid geometrics. A successful pattern must look grown rather than drafted. Leave the dizzying polka dots on the rail and choose prints that breathe with the cloth."
            let tipText = bp?.pattern.tipText.nonEmpty
                ?? "Use pattern as a texture. A tonal jacquard weave or a subtle embossed print is your secret weapon. It adds depth without screaming for attention."

            var textSections = [
                StyleGuideDetailContent.TextSection(subheading: nil, bodyText: narrative)
            ]
            if bp == nil {
                textSections.append(StyleGuideDetailContent.TextSection(
                    subheading: nil,
                    bodyText: "Look for large-scale and soft-focus prints. Marble textures or shadow checks where the lines are not quite sharp work well. You also suit classics like a large windowpane check in your neutral palette. The goal is a pattern that looks painted on rather than factory-made."
                ))
                textSections.append(StyleGuideDetailContent.TextSection(
                    subheading: nil,
                    bodyText: "Avoid tiny repetitive prints like polka dots. They look cluttered against your sophisticated aura. Stay away from anything neon or synthetic. If a pattern looks like it belongs on a disposable holiday shirt, it does not belong in your life."
                ))
            }
            textSections.append(StyleGuideDetailContent.TextSection(subheading: "Tip", bodyText: tipText))

            let tipBodyIndex = textSections.count
            return StyleGuideDetailContent(
                sectionType: .pattern,
                title: "The Pattern",
                iconImageName: "pattern_glyph",
                textSections: textSections,
                customComponent: nil,
                tearPlacement: .offsetIntoStackSubview(index: tipBodyIndex, fraction: 0.15)
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
        label.font = CosmicFitTheme.Typography.dmSerifTextDisplayFont(size: 23)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()

    private let backgroundPatternView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.alpha = 0.1
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    init(number: String, title: String, backgroundImageName: String) {
        super.init(frame: .zero)
        numberLabel.text = number
        buttonTitleLabel.text = title
        numberLabel.isUserInteractionEnabled = false
        buttonTitleLabel.isUserInteractionEnabled = false
        backgroundPatternView.image = UIImage(named: backgroundImageName)
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

        var glyphConstraints: [NSLayoutConstraint] = [
            backgroundPatternView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backgroundPatternView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            backgroundPatternView.bottomAnchor.constraint(equalTo: buttonTitleLabel.topAnchor, constant: -10),
            backgroundPatternView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
        ]

        if let image = backgroundPatternView.image, image.size.height > 0 {
            let aspectRatio = image.size.width / image.size.height
            glyphConstraints.append(
                backgroundPatternView.widthAnchor.constraint(
                    equalTo: backgroundPatternView.heightAnchor,
                    multiplier: aspectRatio
                )
            )
        }

        NSLayoutConstraint.activate(glyphConstraints + [
            numberLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),

            buttonTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            buttonTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            buttonTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
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
