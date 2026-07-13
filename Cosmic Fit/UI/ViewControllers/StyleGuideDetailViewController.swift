//
//  StyleGuideDetailViewController.swift
//  Cosmic Fit
//
//  Reusable template for all Style Guide detail pages. When the user lacks
//  full access, shows partial content with a torn-paper edge, animated glyph
//  background, and a scroll-reveal unlock CTA — mirroring the Daily Fit
//  gated experience.
//

import UIKit

// MARK: - Tear Placement

/// Describes where the torn-paper edge should sit relative to
/// `contentStackView`'s arranged subviews. Resolved to a concrete Y offset
/// after layout completes.
enum StyleGuideGatedTearPlacement {
    /// Tear immediately after a stack subview (e.g. Blueprint body label).
    case afterStackSubview(index: Int)
    /// Tear partway through a stack subview (fraction 0…1 of its height).
    case offsetIntoStackSubview(index: Int, fraction: CGFloat)
    /// Tear through the vertical centre of the second core-palette swatch row
    /// inside a `ColourPaletteView` that is the `customComponent`.
    case paletteAfterFirstRow
    /// Tear partway through a specific Lean Into bullet inside the
    /// code `customComponent` stack.
    case codeOffsetIntoLeanIntoBullet(bulletIndex: Int, fraction: CGFloat)
    /// Tear at a fraction of the total `contentStackView` height.
    case pageContentFraction(CGFloat)
}

// MARK: - Content Configuration

struct StyleGuideDetailContent {
    let sectionType: StyleGuideSection
    let title: String
    let iconImageName: String
    let textSections: [TextSection]
    let customComponent: UIView?
    let tearPlacement: StyleGuideGatedTearPlacement?
    // SG-2 Phase 2.5 output-contract slots. All optional; when absent the
    // detail page renders exactly as before (no visible change for pre-SG-2
    // blueprints). Populated by SG-3 generation; the rendering path exists now
    // so SG-4's "filled-but-unsurfaced slot fails" check has a target.
    let sectionIntro: String?
    let rankedItems: [RankedItem]?
    let tests: [String]?
    let traps: [Trap]?
    let closing: String?

    struct TextSection {
        let subheading: String?
        let bodyText: String
    }

    init(sectionType: StyleGuideSection, title: String, iconImageName: String,
         textSections: [TextSection], customComponent: UIView?,
         tearPlacement: StyleGuideGatedTearPlacement?,
         sectionIntro: String? = nil, rankedItems: [RankedItem]? = nil,
         tests: [String]? = nil, traps: [Trap]? = nil, closing: String? = nil) {
        self.sectionType = sectionType
        self.title = title
        self.iconImageName = iconImageName
        self.textSections = textSections
        self.customComponent = customComponent
        self.tearPlacement = tearPlacement
        self.sectionIntro = sectionIntro
        self.rankedItems = rankedItems
        self.tests = tests
        self.traps = traps
        self.closing = closing
    }

    /// SG-2 Phase 2.5: formats the structured output-contract slots into extra
    /// text sections. Empty when no slot is populated (graceful fallback).
    func outputContractTrailingSections() -> [TextSection] {
        var out: [TextSection] = []
        if let items = rankedItems, !items.isEmpty {
            let body = items.map { item -> String in
                let use = item.useCase.map { " — \($0)" } ?? ""
                return "• \(item.name) (\(item.role))\(use)"
            }.joined(separator: "\n")
            out.append(TextSection(subheading: "Ranked", bodyText: body))
        }
        if let tests {
            // SG-4 stopgap: the shipped narrative cache emits ~40% of `tests`
            // entries as bare named labels ("the host test") with no
            // explanatory clause, which read as meaningless to the user. Hide
            // those until they are backfilled to the "name: meaning" form.
            // See docs/style_guide/TODO_tests_backfill.md.
            let shown = tests.filter { !Self.isBareNamedTest($0) }
            if !shown.isEmpty {
                out.append(TextSection(subheading: "Tests",
                                       bodyText: shown.map { "• \($0)" }.joined(separator: "\n")))
            }
        }
        if let traps, !traps.isEmpty {
            let body = traps.map { "• \($0.failure) → \($0.fix)" }.joined(separator: "\n")
            out.append(TextSection(subheading: "Traps", bodyText: body))
        }
        if let closing, !closing.isEmpty {
            out.append(TextSection(subheading: "Closing", bodyText: closing))
        }
        return out
    }

    /// SG-4 stopgap guard (see `outputContractTrailingSections`): a `tests`
    /// entry is "bare" — a named heuristic with no explanation the reader can
    /// act on — when it is of the shape `the … test` and carries no `:` or
    /// `(…)` clause. The explained forms in the cache always contain one of
    /// those markers (e.g. `pick it up: looks lie, weight doesn't (the
    /// pick-it-up weight test)`), so this hides only the label-only entries.
    /// Remove once the cache is backfilled — TODO_tests_backfill.md.
    static func isBareNamedTest(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.contains(":"), !s.contains("(") else { return false }
        let lower = s.lowercased()
        return lower.hasPrefix("the ") && lower.hasSuffix(" test")
    }

    enum StyleGuideSection {
        case styleCore
        case textures
        case palette
        case occasions
        case hardware
        case code
        case accessory
        case pattern
    }
}

// MARK: - StyleGuideDetailViewController

final class StyleGuideDetailViewController: UIViewController {

    // MARK: - Properties

    private var content: StyleGuideDetailContent?

    private var contentStackTopToTitle: NSLayoutConstraint!
    private var contentStackTopToDivider: NSLayoutConstraint!
    /// Normal bottom constraint (non-gated layout).
    private var bottomDividerToContentBottom: NSLayoutConstraint?

    // MARK: - Gated paywall state

    private var isGated: Bool {
        !EntitlementManager.shared.hasFullAccess
    }
    private var isGatedLayoutActive = false
    private var gatedSpacerHeightConstraint: NSLayoutConstraint?
    /// Positions the torn paper edge at the resolved tear Y.
    private var tornPaperTopConstraint: NSLayoutConstraint?
    /// Bottom constraint for gated layout (spacer → contentView bottom).
    private var gatedContentBottomConstraint: NSLayoutConstraint?
    private var contentMaskLayer: CALayer?
    private var paletteClipMaskLayer: CALayer?
    private var resolvedTearY: CGFloat = 0

    /// Matches `ColourPaletteView` grid layout constants.
    private static let paletteCellSpacing: CGFloat = 6
    private static let paletteColumnCount: CGFloat = 4

    /// Style Guide sub-pages park the tear lower than Daily Fit (~48% vs 33%)
    /// so a band of glyph backdrop shows above the unlock CTA at max scroll.
    private static let tornEdgeRestFraction: CGFloat = 0.48
    private static let tornEdgeViewHeight: CGFloat = TornPaperEdgeView.preferredHeight
    private static let gatedCTARevealStartScale: CGFloat = 0.88

    // MARK: - Torn paper + glyph field + CTA views

    private let tornPaperEdgeView = TornPaperEdgeView()

    private let gatedPaywallBackgroundContainer = UIView()
    private let gatedPaywallBackdrop = UIView()
    private let gatedGlyphBackground = ScrollingRunesBackgroundView(
        edgeFadeStyle: .launch,
        glyphColumnTargetAlpha: CosmicFitTheme.gatedPaywallGlyphOpacity
    )
    private let gatedPaywallMaskLayer = CALayer()

    private let gatedCTAContainer = PassthroughContainerView()
    private let gatedCTAMaskLayer = CALayer()
    private let gatedCTAStack = UIStackView()
    private let gatedUnlockBlock = UIStackView()
    private let gatedUnlockHeadingLabel = UILabel()
    private let gatedUnlockBulletsStack = UIStackView()
    private let unlockButton = UIButton(type: .system)
    private var gatedCTARevealItems: [UIView] = []
    private var gatedCTATopConstraint: NSLayoutConstraint?

    /// Spacer added at the end of scroll content so max scroll parks the tear
    /// at `tornEdgeRestFraction` of the card height.
    private let gatedScrollSpacer = UIView()

    // MARK: - UI Components

    private let shadowContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 6
        return view
    }()

    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
        return view
    }()

    private let scrollView: GatedPaywallScrollView = {
        let sv = GatedPaywallScrollView()
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
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        button.contentHorizontalAlignment = .right
        return button
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        CosmicFitTheme.stylePageEyebrowLabel(
            label,
            text: "YOUR COSMIC STYLE GUIDE",
            color: CosmicFitTheme.Colours.cosmicBlue
        )
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        return view
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
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

    // MARK: - Interactive dismissal

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var initialTouchPoint: CGPoint = .zero

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupGestures()
        setupGatedPaywall()

        scrollView.delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEntitlementChange),
            name: EntitlementManager.entitlementDidChange,
            object: nil
        )

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

        if isGatedLayoutActive {
            resolveTearPosition()
            updateGatedPaywallMetrics()
            updateGatedCTAFade()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Configuration

    func configure(with content: StyleGuideDetailContent) {
        self.content = content
        if isViewLoaded {
            populateContent(content)
        }
    }

    // MARK: - Entitlement

    @objc private func handleEntitlementChange() {
        applyGatedLayout(isGated)
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

        let bottomConstraint = bottomDividerContainer.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -CosmicFitTheme.Layout.scrollContentBottomInset
        )
        bottomDividerToContentBottom = bottomConstraint

        NSLayoutConstraint.activate([
            shadowContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            shadowContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardContainerView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            cardContainerView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            iconImageView.topAnchor.constraint(
                equalTo: headerLabel.bottomAnchor,
                constant: CosmicFitTheme.HeaderGlyphLayout.spacingAbove
            ),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: CosmicFitTheme.HeaderGlyphLayout.width),
            iconImageView.heightAnchor.constraint(equalToConstant: CosmicFitTheme.HeaderGlyphLayout.height),

            titleLabel.topAnchor.constraint(
                equalTo: iconImageView.bottomAnchor,
                constant: CosmicFitTheme.HeaderGlyphLayout.spacingBelow
            ),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            topDivider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            bottomDividerContainer.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 40),
            bottomDividerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bottomDividerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bottomDividerContainer.heightAnchor.constraint(equalToConstant: 30),
            bottomConstraint,

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

        contentStackTopToDivider = contentStackView.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: 40)
        contentStackTopToTitle = contentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40)
        contentStackTopToDivider.isActive = true
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }

    // MARK: - Gated Paywall Setup

    private func setupGatedPaywall() {
        // Torn paper edge sits in the scroll view (not the masked content view) so
        // text clipped at the tear line cannot bleed through the deckle transparency.
        tornPaperEdgeView.translatesAutoresizingMaskIntoConstraints = false
        tornPaperEdgeView.fillColor = CosmicFitTheme.Colours.cosmicGrey
        tornPaperEdgeView.isHidden = true
        scrollView.addSubview(tornPaperEdgeView)

        let tearTop = tornPaperEdgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
        tornPaperTopConstraint = tearTop

        NSLayoutConstraint.activate([
            tornPaperEdgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tornPaperEdgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tornPaperEdgeView.heightAnchor.constraint(equalToConstant: Self.tornEdgeViewHeight),
        ])

        // Gated scroll spacer — extends scroll content so the tear can
        // scroll up to `tornEdgeRestFraction` from the top of the card.
        gatedScrollSpacer.translatesAutoresizingMaskIntoConstraints = false
        gatedScrollSpacer.isHidden = true
        contentView.addSubview(gatedScrollSpacer)
        let spacerHeight = gatedScrollSpacer.heightAnchor.constraint(equalToConstant: 0)
        spacerHeight.isActive = true
        gatedSpacerHeightConstraint = spacerHeight

        let gatedBottom = gatedScrollSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        gatedContentBottomConstraint = gatedBottom

        NSLayoutConstraint.activate([
            gatedScrollSpacer.topAnchor.constraint(equalTo: tornPaperEdgeView.bottomAnchor),
            gatedScrollSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gatedScrollSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        // Glyph background inside cardContainerView, behind scrollView
        gatedPaywallBackgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        gatedPaywallBackgroundContainer.isHidden = true
        gatedPaywallBackgroundContainer.isUserInteractionEnabled = false
        gatedPaywallMaskLayer.backgroundColor = UIColor.black.cgColor
        gatedPaywallMaskLayer.anchorPoint = .zero
        gatedPaywallBackgroundContainer.layer.mask = gatedPaywallMaskLayer

        gatedPaywallBackdrop.translatesAutoresizingMaskIntoConstraints = false
        gatedPaywallBackdrop.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        gatedPaywallBackdrop.isUserInteractionEnabled = false

        gatedGlyphBackground.translatesAutoresizingMaskIntoConstraints = false
        gatedGlyphBackground.isUserInteractionEnabled = false

        gatedPaywallBackgroundContainer.addSubview(gatedPaywallBackdrop)
        gatedPaywallBackgroundContainer.addSubview(gatedGlyphBackground)
        cardContainerView.insertSubview(gatedPaywallBackgroundContainer, belowSubview: scrollView)

        NSLayoutConstraint.activate([
            gatedPaywallBackgroundContainer.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            gatedPaywallBackgroundContainer.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            gatedPaywallBackgroundContainer.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            gatedPaywallBackgroundContainer.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),

            gatedPaywallBackdrop.topAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.topAnchor),
            gatedPaywallBackdrop.leadingAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.leadingAnchor),
            gatedPaywallBackdrop.trailingAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.trailingAnchor),
            gatedPaywallBackdrop.bottomAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.bottomAnchor),

            gatedGlyphBackground.topAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.topAnchor),
            gatedGlyphBackground.leadingAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.leadingAnchor),
            gatedGlyphBackground.trailingAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.trailingAnchor),
            gatedGlyphBackground.bottomAnchor.constraint(equalTo: gatedPaywallBackgroundContainer.bottomAnchor),
        ])

        // CTA container
        setupGatedCTA()
    }

    private func setupGatedCTA() {
        CosmicFitTheme.styleGatedPaywallButton(unlockButton, title: "Unlock Your Style Guide")
        unlockButton.translatesAutoresizingMaskIntoConstraints = false
        unlockButton.accessibilityLabel = "Unlock Your Style Guide"

        // Trial-forward copy when the user is eligible for the annual free
        // trial; fails closed to the default "Unlock" copy.
        Task { [weak self] in
            if StoreKitManager.shared.annualProduct == nil {
                await StoreKitManager.shared.loadProducts()
            }
            guard await StoreKitManager.shared.isEligibleForAnnualIntroOffer(),
                  StoreKitManager.shared.annualTrialIsOneWeek,
                  let self else { return }
            CosmicFitTheme.styleGatedPaywallButton(self.unlockButton, title: "Try 7 Days Free")
            self.unlockButton.accessibilityLabel = "Try 7 Days Free"
        }
        unlockButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        unlockButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        unlockButton.addTarget(self, action: #selector(unlockButtonTapped), for: .touchUpInside)

        gatedUnlockHeadingLabel.text = "Unlock your Style Guide"
        gatedUnlockHeadingLabel.font = Self.preferredBoldItalicSerifFont(size: CosmicFitTheme.Typography.FontSizes.title3)
        gatedUnlockHeadingLabel.textColor = .white
        gatedUnlockHeadingLabel.textAlignment = .center
        gatedUnlockHeadingLabel.numberOfLines = 0

        gatedUnlockBulletsStack.axis = .vertical
        gatedUnlockBulletsStack.alignment = .leading
        gatedUnlockBulletsStack.spacing = 7
        for text in [
            "Your full colour palette & texture guide",
            "Occasion, hardware & accessory direction",
            "Personal style code & pattern guidance"
        ] {
            gatedUnlockBulletsStack.addArrangedSubview(makeGatedBulletLabel(text))
        }

        gatedUnlockBlock.axis = .vertical
        gatedUnlockBlock.alignment = .center
        gatedUnlockBlock.spacing = 16
        gatedUnlockBlock.isUserInteractionEnabled = false
        gatedUnlockBulletsStack.isUserInteractionEnabled = false
        gatedUnlockBlock.addArrangedSubview(gatedUnlockHeadingLabel)
        gatedUnlockBlock.addArrangedSubview(gatedUnlockBulletsStack)
        gatedUnlockBlock.addArrangedSubview(unlockButton)

        gatedCTAStack.axis = .vertical
        gatedCTAStack.alignment = .center
        gatedCTAStack.spacing = 34
        gatedCTAStack.isUserInteractionEnabled = false
        gatedCTAStack.translatesAutoresizingMaskIntoConstraints = false
        gatedCTAStack.addArrangedSubview(gatedUnlockBlock)

        gatedCTAContainer.translatesAutoresizingMaskIntoConstraints = false
        gatedCTAContainer.isHidden = true
        gatedCTAMaskLayer.backgroundColor = UIColor.black.cgColor
        gatedCTAMaskLayer.anchorPoint = .zero
        gatedCTAContainer.layer.mask = gatedCTAMaskLayer
        gatedCTAContainer.addSubview(gatedCTAStack)
        cardContainerView.insertSubview(gatedCTAContainer, aboveSubview: gatedPaywallBackgroundContainer)

        gatedCTARevealItems = [
            gatedUnlockHeadingLabel,
            gatedUnlockBulletsStack.arrangedSubviews[0],
            gatedUnlockBulletsStack.arrangedSubviews[1],
            gatedUnlockBulletsStack.arrangedSubviews[2],
            unlockButton,
        ]
        resetGatedCTAReveal()

        scrollView.ctaTouchTarget = gatedCTAContainer
        scrollView.isGatedPaywallActive = { [weak self] in
            self?.isGatedLayoutActive == true
        }

        let horizontalMargin: CGFloat = 32
        gatedCTATopConstraint = gatedCTAContainer.topAnchor.constraint(equalTo: cardContainerView.topAnchor)

        var ctaStackConstraints: [NSLayoutConstraint] = [
            gatedCTAStack.centerYAnchor.constraint(equalTo: gatedCTAContainer.centerYAnchor),
        ]
        if CosmicFitTheme.Layout.isPad {
            let ctaStackMaxWidth = CosmicFitTheme.Layout.maxContentWidth - horizontalMargin * 2
            ctaStackConstraints.append(contentsOf: [
                gatedCTAStack.centerXAnchor.constraint(equalTo: gatedCTAContainer.centerXAnchor),
                gatedCTAStack.leadingAnchor.constraint(greaterThanOrEqualTo: gatedCTAContainer.leadingAnchor, constant: horizontalMargin),
                gatedCTAStack.trailingAnchor.constraint(lessThanOrEqualTo: gatedCTAContainer.trailingAnchor, constant: -horizontalMargin),
                gatedCTAStack.widthAnchor.constraint(lessThanOrEqualToConstant: ctaStackMaxWidth),
            ])
        } else {
            ctaStackConstraints.append(contentsOf: [
                gatedCTAStack.leadingAnchor.constraint(equalTo: gatedCTAContainer.leadingAnchor, constant: horizontalMargin),
                gatedCTAStack.trailingAnchor.constraint(equalTo: gatedCTAContainer.trailingAnchor, constant: -horizontalMargin),
            ])
        }

        NSLayoutConstraint.activate([
            gatedCTATopConstraint!,
            gatedCTAContainer.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            gatedCTAContainer.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            gatedCTAContainer.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -16),
        ] + ctaStackConstraints + [
            unlockButton.widthAnchor.constraint(equalTo: gatedCTAStack.widthAnchor),
            unlockButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),
        ])
    }

    private func makeGatedBulletLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.white.withAlphaComponent(0.88)
        label.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.callout, weight: .regular
        )
        label.text = "\u{2022}  \(text)"
        return label
    }

    private static func preferredBoldItalicSerifFont(size: CGFloat) -> UIFont {
        if let italic = UIFont(name: "PTSerif-Italic", size: size) {
            if let boldItalicDescriptor = italic.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
                return UIFont(descriptor: boldItalicDescriptor, size: size)
            }
            var traits = (italic.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
            traits[.weight] = UIFont.Weight.bold
            return UIFont(descriptor: italic.fontDescriptor.addingAttributes([.traits: traits]), size: size)
        }
        if let serifDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif),
           let boldItalicDescriptor = serifDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
            return UIFont(descriptor: boldItalicDescriptor, size: size)
        }
        return UIFont.italicSystemFont(ofSize: size)
    }

    // MARK: - Gated Layout Application

    private func applyGatedLayout(_ gated: Bool) {
        if gated {
            tornPaperEdgeView.isHidden = false
            gatedScrollSpacer.isHidden = false
            bottomDividerContainer.isHidden = true

            bottomDividerToContentBottom?.isActive = false
            tornPaperTopConstraint?.isActive = true
            gatedContentBottomConstraint?.isActive = true

            scrollView.bringSubviewToFront(tornPaperEdgeView)

            gatedPaywallBackgroundContainer.isHidden = false
            gatedGlyphBackground.startAnimating()
            cardContainerView.insertSubview(gatedPaywallBackgroundContainer, belowSubview: scrollView)
            gatedCTAContainer.isHidden = false
            cardContainerView.insertSubview(gatedCTAContainer, belowSubview: scrollView)

            scrollView.backgroundColor = .clear

            resolveTearPosition()
        } else {
            tornPaperEdgeView.isHidden = true
            gatedScrollSpacer.isHidden = true
            bottomDividerContainer.isHidden = false

            tornPaperTopConstraint?.isActive = false
            gatedContentBottomConstraint?.isActive = false
            bottomDividerToContentBottom?.isActive = true

            gatedGlyphBackground.stopAnimating()
            gatedPaywallBackgroundContainer.isHidden = true
            gatedCTAContainer.isHidden = true
            resetGatedCTAReveal()

            contentMaskLayer?.removeFromSuperlayer()
            contentMaskLayer = nil
            contentView.layer.mask = nil
            if let customComponent = content?.customComponent {
                clearPaletteClipMask(from: customComponent)
            }
        }

        updatePaletteInteraction(forGated: gated)

        isGatedLayoutActive = gated
        view.setNeedsLayout()
        view.layoutIfNeeded()

        if gated {
            updateGatedPaywallMetrics()
            updateGatedCTAFade()
        }
    }

    // MARK: - Tear Position Resolution

    private func resolveTearPosition() {
        guard let placement = content?.tearPlacement else { return }
        let stackFrame = contentStackView.frame
        let arrangedSubviews = contentStackView.arrangedSubviews

        var tearY: CGFloat

        switch placement {
        case .afterStackSubview(let index):
            let idx = min(index, arrangedSubviews.count - 1)
            guard idx >= 0 else { tearY = stackFrame.maxY; break }
            let subview = arrangedSubviews[idx]
            tearY = stackFrame.minY + subview.frame.maxY

        case .offsetIntoStackSubview(let index, let fraction):
            let idx = min(index, arrangedSubviews.count - 1)
            guard idx >= 0 else { tearY = stackFrame.maxY; break }
            let subview = arrangedSubviews[idx]
            tearY = stackFrame.minY + subview.frame.minY + subview.frame.height * fraction

        case .paletteAfterFirstRow:
            if let customComponent = content?.customComponent {
                let componentInStack = stackFrame.minY + customComponent.frame.minY
                let paletteView = customComponent.subviews.first(where: { $0 is ColourPaletteView }) ?? customComponent
                if let container = findFirstGridContainer(in: paletteView) {
                    let containerOriginInStack = container.convert(.zero, to: contentStackView).y
                    let cellSize = Self.paletteCellSize(forGridWidth: container.bounds.width)
                    let secondRowCenterY = Self.paletteSecondRowCenterY(cellSize: cellSize)
                    tearY = stackFrame.minY + containerOriginInStack + secondRowCenterY
                    updatePaletteClipMask(
                        on: customComponent,
                        gridContainer: container,
                        clipHeightInGrid: secondRowCenterY
                    )
                } else {
                    tearY = componentInStack + 100
                    clearPaletteClipMask(from: customComponent)
                }
            } else {
                tearY = stackFrame.midY
            }

        case .codeOffsetIntoLeanIntoBullet(let bulletIndex, let fraction):
            if let customComponent = content?.customComponent,
               let codeStack = customComponent as? UIStackView,
               let leanIntoSection = codeStack.arrangedSubviews.first as? DosAndDontsSectionView,
               let innerStack = leanIntoSection.subviews.first as? UIStackView {
                let leanIntoInStack = leanIntoSection.convert(CGPoint.zero, to: contentStackView)
                let bulletArranged = innerStack.arrangedSubviews
                let adjustedIndex = min(bulletIndex + 1, bulletArranged.count - 1)
                if adjustedIndex >= 0, adjustedIndex < bulletArranged.count {
                    let bullet = bulletArranged[adjustedIndex]
                    tearY = stackFrame.minY + leanIntoInStack.y + bullet.frame.minY + bullet.frame.height * fraction
                } else {
                    tearY = stackFrame.minY + leanIntoInStack.y + leanIntoSection.frame.height * 0.5
                }
            } else {
                tearY = stackFrame.midY
            }

        case .pageContentFraction(let fraction):
            tearY = stackFrame.minY + stackFrame.height * fraction
        }

        if case .paletteAfterFirstRow = placement {
            // Grid placement is already exact; line snapping does not apply.
        } else {
            tearY = snapTearYToLineBoundary(proposedY: tearY)
        }

        resolvedTearY = tearY

        // Position the torn paper via its top constraint (2pt overlap with content above).
        tornPaperTopConstraint?.constant = tearY - 2

        // Clip scroll content exactly at the tear — the torn-paper band lives outside
        // this mask so deckle transparency never reveals hidden lines beneath.
        let maskRect = CGRect(
            x: 0, y: 0,
            width: max(1, contentView.bounds.width),
            height: tearY
        )
        if contentMaskLayer == nil {
            contentMaskLayer = CALayer()
            contentMaskLayer?.backgroundColor = UIColor.black.cgColor
            contentView.layer.mask = contentMaskLayer
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentMaskLayer?.frame = maskRect
        CATransaction.commit()
    }

    private func findFirstGridContainer(in view: UIView) -> UIView? {
        if view is ColourPaletteView {
            let stack = view.subviews.first(where: { $0 is UIStackView })
            if let outerStack = stack as? UIStackView {
                // Swatch grid holds four or more cells; section headers only have three subviews.
                for sub in outerStack.arrangedSubviews where sub.subviews.count >= 4 {
                    return sub
                }
            }
            return nil
        }
        for sub in view.subviews {
            if let found = findFirstGridContainer(in: sub) { return found }
        }
        return nil
    }

    private static func paletteCellSize(forGridWidth width: CGFloat) -> CGFloat {
        (width - paletteCellSpacing * (paletteColumnCount - 1)) / paletteColumnCount
    }

    /// Vertical centre of the second swatch row (1-based) in a palette grid container.
    private static func paletteSecondRowCenterY(cellSize: CGFloat) -> CGFloat {
        cellSize + paletteCellSpacing + cellSize * 0.5
    }

    /// Clips gated palette content at the tear line so lower rows cannot bleed
    /// through the torn-paper edge's transparent deckle.
    private func updatePaletteClipMask(on component: UIView, gridContainer: UIView, clipHeightInGrid: CGFloat) {
        let clipY = gridContainer.convert(
            CGPoint(x: 0, y: clipHeightInGrid),
            to: component
        ).y
        let clipHeight = max(0, clipY)

        if paletteClipMaskLayer == nil {
            let layer = CALayer()
            layer.backgroundColor = UIColor.black.cgColor
            paletteClipMaskLayer = layer
        }
        component.layer.mask = paletteClipMaskLayer

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        paletteClipMaskLayer?.frame = CGRect(
            x: 0,
            y: 0,
            width: max(1, component.bounds.width),
            height: clipHeight
        )
        CATransaction.commit()
    }

    private func clearPaletteClipMask(from component: UIView) {
        if component.layer.mask === paletteClipMaskLayer {
            component.layer.mask = nil
        }
        paletteClipMaskLayer = nil
    }

    private func paletteView(in customComponent: UIView?) -> ColourPaletteView? {
        customComponent?.subviews.first { $0 is ColourPaletteView } as? ColourPaletteView
    }

    private func updatePaletteInteraction(forGated gated: Bool) {
        guard content?.sectionType == .palette else { return }
        paletteView(in: content?.customComponent)?.setSwatchInteractionEnabled(!gated)
    }

    // MARK: - Tear line snapping

    /// Snaps a proposed tear Y to the nearest line boundary above it so no line is
    /// bisected and descenders on the last visible line stay intact.
    private func snapTearYToLineBoundary(proposedY: CGFloat) -> CGFloat {
        let labels = collectGatedTextLabels()
        guard !labels.isEmpty else { return proposedY }

        var lines: [(minY: CGFloat, maxY: CGFloat)] = []
        for label in labels {
            guard label.bounds.width > 0, label.attributedText != nil else { continue }
            for rect in lineRects(for: label, in: contentView) {
                lines.append((minY: rect.minY, maxY: rect.maxY))
            }
        }
        guard !lines.isEmpty else { return proposedY }
        lines.sort { $0.minY < $1.minY }

        for line in lines {
            if proposedY <= line.minY + 0.5 {
                break
            }
            if proposedY < line.maxY - 0.5 {
                return line.minY
            }
        }
        return proposedY
    }

    private func collectGatedTextLabels() -> [UILabel] {
        var labels = collectMultilineLabels(in: contentStackView)
        if let customComponent = content?.customComponent {
            labels.append(contentsOf: collectMultilineLabels(in: customComponent))
        }
        return labels
    }

    private func collectMultilineLabels(in view: UIView) -> [UILabel] {
        var labels: [UILabel] = []
        if let label = view as? UILabel,
           label.numberOfLines == 0,
           label.attributedText != nil {
            labels.append(label)
        }
        for subview in view.subviews {
            labels.append(contentsOf: collectMultilineLabels(in: subview))
        }
        return labels
    }

    private func lineRects(for label: UILabel, in coordinateSpace: UICoordinateSpace) -> [CGRect] {
        guard let attributedText = label.attributedText, label.bounds.width > 0 else { return [] }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        var rects: [CGRect] = []
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, _, _ in
            rects.append(label.convert(usedRect, to: coordinateSpace))
        }
        return rects
    }

    // MARK: - Gated Metrics & Mask Updates

    private func updateGatedPaywallMetrics() {
        guard isGatedLayoutActive else { return }
        let containerHeight = cardContainerView.bounds.height
        let visibleHeight = scrollView.bounds.height
        guard containerHeight > 1, visibleHeight > 1 else { return }

        let spacer = max(0, visibleHeight - containerHeight * Self.tornEdgeRestFraction - Self.tornEdgeViewHeight)
        if let constraint = gatedSpacerHeightConstraint, abs(constraint.constant - spacer) > 0.5 {
            constraint.constant = spacer
        }

        updateGatedMaskFrames()
    }

    /// Vertically centres the unlock CTA block in the live gap between the
    /// bottom of the torn-paper edge and the top of the tab nav bar (the card
    /// bottom). Tracking the tear's actual on-screen position keeps the CTA
    /// centred at whatever scroll rest position the page settles at, rather
    /// than anchoring to a fixed fraction that drifts low once the scroll-view
    /// top inset and tear band are accounted for.
    private func updateGatedCTACentering() {
        guard isGatedLayoutActive, let topConstraint = gatedCTATopConstraint else { return }
        let containerHeight = cardContainerView.bounds.height
        guard containerHeight > 1 else { return }

        let tearBottomInCard = tornPaperEdgeView.convert(.zero, to: cardContainerView).y + Self.tornEdgeViewHeight
        let blockHeight = gatedCTAStack.bounds.height
        let maxTop = max(0, containerHeight - 16 - blockHeight)
        let desiredTop = min(max(0, tearBottomInCard), maxTop)

        if abs(topConstraint.constant - desiredTop) > 0.5 {
            topConstraint.constant = desiredTop
            cardContainerView.layoutIfNeeded()
        }
    }

    private func updateGatedMaskFrames() {
        guard isGatedLayoutActive else { return }
        updateGatedCTACentering()
        let tearTopInCard = tornPaperEdgeView.convert(CGPoint.zero, to: cardContainerView).y

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let paywallTop = max(0, tearTopInCard)
        gatedPaywallMaskLayer.frame = CGRect(
            x: 0, y: paywallTop,
            width: gatedPaywallBackgroundContainer.bounds.width,
            height: max(0, gatedPaywallBackgroundContainer.bounds.height - paywallTop)
        )

        let ctaMaskTop = max(0, tearTopInCard - gatedCTAContainer.frame.minY)
        gatedCTAMaskLayer.frame = CGRect(
            x: 0, y: ctaMaskTop,
            width: gatedCTAContainer.bounds.width,
            height: max(0, gatedCTAContainer.bounds.height - ctaMaskTop)
        )

        CATransaction.commit()
    }

    private func updateGatedCTAFade() {
        guard isGatedLayoutActive else { return }
        let maxOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
        let progress = min(1, max(0, scrollView.contentOffset.y / maxOffset))
        let itemCount = CGFloat(gatedCTARevealItems.count)
        guard itemCount > 0 else { return }

        var unlockButtonReveal: CGFloat = 0
        for (index, item) in gatedCTARevealItems.enumerated() {
            let start = CGFloat(index) / itemCount
            let end = CGFloat(index + 1) / itemCount
            let t = rampedAlpha(progress, start: start, end: end)
            item.alpha = t
            let scale = Self.gatedCTARevealStartScale + (1 - Self.gatedCTARevealStartScale) * t
            item.transform = CGAffineTransform(scaleX: scale, y: scale)
            if item === unlockButton {
                unlockButtonReveal = t
            }
        }

        let buttonsActive = unlockButtonReveal > 0.5
        gatedCTAContainer.isUserInteractionEnabled = buttonsActive
        unlockButton.isUserInteractionEnabled = buttonsActive
        updateGatedMaskFrames()
    }

    private func resetGatedCTAReveal() {
        let startScale = Self.gatedCTARevealStartScale
        let startTransform = CGAffineTransform(scaleX: startScale, y: startScale)
        gatedCTARevealItems.forEach {
            $0.alpha = 0
            $0.transform = startTransform
        }
        gatedCTAContainer.isUserInteractionEnabled = false
        unlockButton.isUserInteractionEnabled = false
    }

    private func rampedAlpha(_ progress: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard end > start else { return progress >= end ? 1 : 0 }
        return min(1, max(0, (progress - start) / (end - start)))
    }

    // MARK: - Purchase

    @objc private func unlockButtonTapped() {
        presentPurchaseScreen()
    }

    private func presentPurchaseScreen() {
        var currentParent: UIViewController? = parent
        while currentParent != nil {
            if let tbc = currentParent as? CosmicFitTabBarController {
                let purchaseVC = PurchaseViewController()
                let detailVC = GenericDetailViewController(contentViewController: purchaseVC)
                tbc.dismissDetailViewController(animated: true) {
                    tbc.presentDetailViewController(detailVC, animated: true)
                }
                return
            }
            currentParent = currentParent?.parent
        }
    }

    // MARK: - Content Population

    private func populateContent(_ content: StyleGuideDetailContent) {
        iconImageView.image = UIImage(named: content.iconImageName)
        titleLabel.attributedText = CosmicFitTheme.StyleGuideSubPageTitleTypography.attributedString(content.title)

        let firstSectionHasSubheading = content.textSections.first?.subheading != nil
        topDivider.isHidden = firstSectionHasSubheading
        contentStackTopToDivider.isActive = !firstSectionHasSubheading
        contentStackTopToTitle.isActive = firstSectionHasSubheading

        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // SG-2 Phase 2.5: section intro renders above the section body when
        // present (nil → no change).
        if let intro = content.sectionIntro?.trimmingCharacters(in: .whitespacesAndNewlines),
           !intro.isEmpty {
            addBody(intro)
        }

        let allSections = content.textSections + content.outputContractTrailingSections()
        for (index, textSection) in allSections.enumerated() {
            if let subheading = textSection.subheading {
                let subheadingContainer = createSubheadingWithDividers(text: subheading)
                contentStackView.addArrangedSubview(subheadingContainer)

                let isLastTextSection = index == (allSections.count - 1)
                let bodyIsEmpty = textSection.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if isLastTextSection && bodyIsEmpty && content.customComponent != nil {
                    contentStackView.setCustomSpacing(14, after: subheadingContainer)
                }
            }

            addBody(textSection.bodyText)
        }

        if let customComponent = content.customComponent {
            contentStackView.addArrangedSubview(customComponent)
        }

        applyGatedLayout(isGated)
    }

    // MARK: - UI Factory Methods

    private func createSubheadingWithDividers(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let leftDivider = UIView()
        leftDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        leftDivider.translatesAutoresizingMaskIntoConstraints = false

        let rightDivider = UIView()
        rightDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        rightDivider.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = CosmicFitTheme.Typography.dmSerifTextDisplayItalicFont(size: 19)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
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

    private static let sentencesPerParagraph = 2

    /// Adds a section body to the content stack, one label per paragraph.
    ///
    /// Authored paragraph breaks (`\n\n`) become separate arranged subviews so
    /// the gap between paragraphs is `contentStackView.spacing` — the same gap
    /// used between the section intro and body, and between every other block.
    /// Rendering `\n\n` inside a single label instead produced a blank line
    /// plus paragraph spacing on both sides (~2x too tall). Bodies without an
    /// authored break (bullet lists, single narratives) keep the existing
    /// single-label path, including its sentence-splitting fallback.
    private func addBody(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.contains("\n\n") {
            let blocks = trimmed.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            for block in blocks {
                contentStackView.addArrangedSubview(createBodyLabel(text: block, splitParagraphs: false))
            }
        } else {
            contentStackView.addArrangedSubview(createBodyLabel(text: text))
        }
    }

    private func createBodyLabel(text: String, splitParagraphs: Bool = true) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.attributedText = Self.paragraphFormatted(text, splitParagraphs: splitParagraphs)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10)
        ])

        return container
    }

    private static func paragraphFormatted(_ text: String, splitParagraphs: Bool = true) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 8
        style.lineSpacing = 3

        let font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.body,
            weight: .regular
        )

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style
        ]

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // A single authored paragraph rendered on its own — no in-label
        // splitting. Paragraph-to-paragraph spacing is handled by the stack.
        if !splitParagraphs {
            return NSAttributedString(string: trimmed, attributes: attrs)
        }

        if trimmed.contains("\n\n") {
            return NSAttributedString(string: trimmed, attributes: attrs)
        }

        let sentences = splitIntoSentences(trimmed)
        guard sentences.count > sentencesPerParagraph else {
            return NSAttributedString(string: trimmed, attributes: attrs)
        }

        var paragraphs: [String] = []
        for start in stride(from: 0, to: sentences.count, by: sentencesPerParagraph) {
            let end = min(start + sentencesPerParagraph, sentences.count)
            paragraphs.append(sentences[start..<end].joined(separator: " "))
        }

        return NSAttributedString(string: paragraphs.joined(separator: "\n"), attributes: attrs)
    }

    private static func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(
            in: text.startIndex...,
            options: .bySentences
        ) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespaces), !s.isEmpty {
                sentences.append(s)
            }
        }
        return sentences
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        var currentParent: UIViewController? = parent
        while currentParent != nil {
            if let tabBarController = currentParent as? CosmicFitTabBarController {
                tabBarController.dismissDetailViewController(animated: true)
                return
            }
            currentParent = currentParent?.parent
        }
    }

    // MARK: - Gesture Handling

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let progress = translation.y / view.bounds.height

        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: view)

        case .changed:
            guard translation.y > 0 else {
                shadowContainerView.transform = .identity
                return
            }
            let dampingFactor: CGFloat = 0.5
            let dragDistance = translation.y * dampingFactor
            shadowContainerView.transform = CGAffineTransform(translationX: 0, y: dragDistance)

        case .ended, .cancelled:
            let shouldDismiss = (progress > 0.3 || velocity.y > 800) && translation.y > 0

            if shouldDismiss {
                animateDismissal(with: velocity.y)
            } else {
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
        var currentParent: UIViewController? = parent
        var tabBarController: CosmicFitTabBarController?
        while currentParent != nil {
            if let tbc = currentParent as? CosmicFitTabBarController {
                tabBarController = tbc
                break
            }
            currentParent = currentParent?.parent
        }

        guard let tbc = tabBarController else { return }

        let containerHeight = view.bounds.height
        let remainingDistance = containerHeight - shadowContainerView.frame.origin.y
        let minimumDuration: TimeInterval = 0.2
        let velocityBasedDuration = TimeInterval(remainingDistance / max(velocity, 500))
        let duration = max(minimumDuration, min(velocityBasedDuration, 0.4))

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction],
            animations: {
                self.shadowContainerView.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                if let dimmingView = tbc.view.subviews.first(where: { $0.backgroundColor == UIColor.black.withAlphaComponent(0.4) }) {
                    dimmingView.alpha = 0
                }
            },
            completion: { _ in
                tbc.dismissDetailViewController(animated: false)
            }
        )
    }
}

// MARK: - UIScrollViewDelegate

extension StyleGuideDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isGatedLayoutActive else { return }
        updateGatedCTAFade()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension StyleGuideDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            return scrollView.contentOffset.y <= 0
        }
        return false
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return true }

        let velocity = panGestureRecognizer.velocity(in: view)
        guard velocity.y > 0 else { return false }

        if scrollView.contentOffset.y > 0 {
            return false
        }

        return abs(velocity.y) > abs(velocity.x) * 2
    }
}
