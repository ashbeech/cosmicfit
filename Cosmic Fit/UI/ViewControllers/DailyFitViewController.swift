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
    
    // Style Edit Section
    private var styleEditHeaderLabel: UIView?
    private let styleEditLabel = UILabel()

    // Style Breakdown Section
    private let colourPaletteContainer = DailyColourPaletteView()
    private var colourHeaderDivider: UIView?
    
    // Tone Slider Section
    private let toneHeaderLabel = UILabel()
    private var toneSliderContainer = UIView()
    
    // Essence Section
    private var vibeHeaderDivider: UIView?
    
    // Silhouette Section
    private var silhouetteHeaderDivider: UIView?
    private let silhouetteContainer = UIView()
    
    // Bottom Section
    
    // Dividers (stored references for constraints)
    private var topDivider: UIView?
    private var styleBreakdownDivider: UIView?
    private var finalStarDivider: UIView?
    
    // Calendar button (same row as "DAILY FIT"; added in setupHeaderComponents)
    private lazy var calendarButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        button.setImage(UIImage(systemName: "calendar", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Animation properties
    private var initialScrollViewTopConstraint: NSLayoutConstraint?
    private var originalCardImage: UIImage? // Store original unblurred image
    private var ciContext: CIContext? // Reuse CI context for better performance
    
    // Data
    private var originalChartViewController: NatalChartViewController?

    // MARK: - DailyFitPayload Pipeline
    private var dailyFitPayload: DailyFitPayload?

    private var dailyRitualHeaderDivider: UIView?
    private let dailyRitualLabel = UILabel()
    private var postTarotParagraphDivider: UIView?
    private var postDailyRitualDivider: UIView?
    private var styleBreakdownAfterDailyRitualConstraint: NSLayoutConstraint?
    private var styleBreakdownAfterStyleParagraphConstraint: NSLayoutConstraint?
    private var postTarotParagraphDividerConstraints: [NSLayoutConstraint] = []
    private var dailyRitualBlockConstraints: [NSLayoutConstraint] = []
    private var postDailyRitualDividerConstraints: [NSLayoutConstraint] = []
    private var styleEditAfterTopDividerConstraint: NSLayoutConstraint?
    private var vibeHeaderAfterToneConstraint: NSLayoutConstraint?
    private var silhouetteHeaderAfterTriangleConstraint: NSLayoutConstraint?
    private var essenceTriangleView: EssenceTriangleView?
    private let wardrobeReflectionLabel = UILabel()
    private let tomorrowTeaseLabel = UILabel()
    private let tomorrowButton = UIButton(type: .system)

    /// Captured so `updateLayoutDependentConstants` can keep the
    /// "Tap to reveal…" caption pinned the right distance above the
    /// tab bar even when `view.safeAreaLayoutGuide.bottomAnchor`
    /// temporarily collapses during slide-tab transitions (the same
    /// reparenting that broke the card's vertical centre — see
    /// `calculateTabBarTop()` for the full story).
    private var tapToRevealBottomConstraint: NSLayoutConstraint?
    /// Fixed distance between the caption's bottom and the tab bar's
    /// top edge, mirroring the prior `-32` constant on the safe-area
    /// anchor.
    private static let tapToRevealBottomGapAboveTabBar: CGFloat = 32

    /// Scroll `contentView` extends this far below the day-navigation CTA (cosmic grey + small blur tail).
    private static let contentBottomPaddingBelowTomorrow: CGFloat = 100
    /// Cosmic grey panel extends this far below the CTA; remainder of bottom padding shows blurred card.
    private static let contentBackgroundTailBelowTomorrowButton: CGFloat = 88
    /// Slightly taller tarot slot so `scaleAspectFit` art (especially `CardBacks`) is not nipped at the foot.
    private static let tarotCardSlotExtraHeight: CGFloat = 5
    /// Fine-tune for the card centre between menu bar and tab bar (contentView coords).
    /// Was +10; raised 15 pt so the card sits higher on iPhone 14 Pro-class layouts.
    private static let tarotCardCenterYNudge: CGFloat = -5

    private var vibrancyScaleContainer = UIView()
    private var contrastScaleContainer = UIView()

    private var vibrancyIndicator: UILabel?
    private var vibrancyTrack: UIView?
    private var vibrancyIndicatorConstraint: NSLayoutConstraint?

    private var contrastIndicator: UILabel?
    private var contrastTrack: UIView?
    private var contrastIndicatorConstraint: NSLayoutConstraint?

    private var metalToneIndicator: UILabel?
    private var metalToneTrack: UIView?
    private var metalToneIndicatorConstraint: NSLayoutConstraint?

    private var silhouetteSliderData: [(indicator: UILabel, track: UIView, constraint: NSLayoutConstraint?)] = []

    // MARK: - Day Navigation
    
    /// Which calendar date is currently displayed (today or tomorrow).
    private var displayDate = Date()
    /// Wall-clock "today" — updated on midnight rollover.
    private var todayDate = Date()
    /// True when showing tomorrow's fit.
    private var isViewingTomorrow = false
    /// Cached payload for today.
    private var todayPayload: DailyFitPayload?
    /// Cached payload for tomorrow (generated on demand).
    private var tomorrowPayload: DailyFitPayload?
    /// Generates a DailyFitPayload for an arbitrary date. Provided by the tab bar controller.
    var payloadGenerator: ((Date) -> DailyFitPayload?)?
    /// Chart/profile scope for freezing revealed payloads (matches tab bar `chartIdentifier`).
    var persistenceProfileKey: String?

    private lazy var dayNavigationBackButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = CosmicNavigationArrow.image(direction: .left, pointSize: 19.3)
        config.contentInsets = .zero
        config.baseForegroundColor = .white
        btn.configuration = config
        btn.contentHorizontalAlignment = .leading
        btn.contentVerticalAlignment = .center
        btn.translatesAutoresizingMaskIntoConstraints = false
        // White with difference blending inverts against the scrolled content:
        // light backgrounds render the arrow dark, dark backgrounds keep it bright.
        btn.layer.compositingFilter = "differenceBlendMode"
        btn.alpha = 0
        btn.isHidden = true
        btn.addTarget(self, action: #selector(dayNavigationBackTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Card Reveal Properties
    
    private var isCardRevealed = false
    private var cardBackImageView = UIImageView()
    /// Iridescent motion-driven sheen on the card back. Set up at view
    /// init time and given its mask image immediately so the holographic
    /// effect is present from the very first frame the card back is
    /// visible (no asymmetric "image first, sheen later" appearance).
    private let cardBackSheenView = MotionSheenView()
    /// Iridescent motion-driven sheen on the revealed card front. Mask
    /// image is set in `loadTarotCardImage(for:)` in lockstep with the
    /// imageView's `image` property so card art and sheen always paint
    /// in unison.
    private let cardFrontSheenView = MotionSheenView()
    /// Subtle inverted-tilt 3D parallax on the card container. Created
    /// lazily in `viewWillAppear` and torn down in `viewWillDisappear`
    /// so the gyro is only running while the card is on-screen. Writes
    /// to `tarotCardContainerView.layer.transform`; the flip animation
    /// uses `sublayerTransform` on the same layer plus inner-image-view
    /// transforms, so the two effects compose cleanly.
    private var cardParallax: MotionParallaxBinding?
    private var tapToRevealLabel = UILabel()
    private var backgroundBlurImageView = UIImageView()
    /// Stored so `viewDidLayoutSubviews` can grow it as the scroll
    /// `contentSize` does, guaranteeing the blur's bottom edge always
    /// extends past the tab bar by at least the worst-case parallax
    /// shift. Without this, a long daily-fit reading translates the
    /// blur far enough up that its bottom rises above the tab bar at
    /// max scroll and exposes the solid `cosmicBlue` fill underneath.
    private var backgroundBlurBottomConstraint: NSLayoutConstraint?
    /// Resting bottom inset of `backgroundBlurImageView` below
    /// `view.bottom`. Used as the floor for the dynamically grown
    /// bottom constraint — we never shrink past this even when content
    /// happens to be short.
    private static let backgroundBlurBottomBaseExtension: CGFloat = 200
    /// Same shift factor used in `scrollViewDidScroll` for the blur
    /// parallax (`-cardTranslation * 0.2`, with `cardTranslation = yOffset * 0.5`),
    /// i.e. `0.5 * 0.2 = 0.1`. Hoisted to a constant so the layout-side
    /// over-extension calculation cannot drift out of sync with the
    /// scroll-side translation.
    private static let backgroundBlurParallaxFactor: CGFloat = 0.1
    /// Extra padding past the worst-case parallax shift; absorbs
    /// rounding and any one-frame race between contentSize settling
    /// and the layout pass updating the constraint.
    private static let backgroundBlurSafetyMargin: CGFloat = 32
    /// Semi-transparent layer on top of the blurred card wallpaper so the sharp tarot reads clearly.
    private let revealedBackgroundDimmingView = UIView()
    private var cardTapGesture: UITapGestureRecognizer?
    
    private let tarotCardContainerView = UIView()
    /// Sibling view that hosts ONLY the card's halo (the soft outer
    /// glow + breath animation). Lives on its own layer, so it never
    /// inherits the parallax 3D transform written to the card
    /// container — the shadow rendering doesn't follow `m34`
    /// perspective faithfully, which made the halo "slide down away
    /// from the card" during over-scroll. Keeping the halo on a 2D
    /// sibling also lets us drive an independent scale + fade off
    /// the rubber-band without touching the card's own transform.
    private let tarotCardGlowView = UIView()
    private var cardContainerCenterYConstraint: NSLayoutConstraint?
    private var cardContainerWidthConstraint: NSLayoutConstraint?
    private var cardContainerHeightConstraint: NSLayoutConstraint?
    /// Top inset of `contentView` inside `scrollView`. The constant
    /// depends on `view.safeAreaInsets.top`, which is `0` at
    /// `viewDidLoad` (view not yet in the window hierarchy) and only
    /// becomes valid once the first layout pass runs. We keep a
    /// reference so the constant can be refreshed in
    /// `viewDidLayoutSubviews`, otherwise the contentView (and the
    /// card it hosts) stays anchored to a stale, zero-safe-area
    /// origin — which in turn drives "Tap to reveal…" too low,
    /// behind the tab bar.
    private var contentViewTopConstraint: NSLayoutConstraint?
    
    private let scrollingRunesBackground = ScrollingRunesBackgroundView()
    
    // Card state enum for better state management
    private enum CardState {
        case unrevealed
        case revealing
        case revealed
    }
    private var currentCardState: CardState = .unrevealed
    
    private var dailyCardRevealKey: String {
        DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: displayDate, engineId: DailyFitEngineConfig.effectiveEngineId)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyCosmicFitTheme()
        
        // CRITICAL: Set initial alpha BEFORE setupUI checks reveal state
        setInitialContentAlpha()
        
        setupUI()
        setupDayRolloverObservers()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEntitlementChange),
            name: EntitlementManager.entitlementDidChange,
            object: nil
        )

        if dailyFitPayload != nil {
            updateContentFromPayload()
        }
    }

    @objc private func handleEntitlementChange() {
        updateDayNavigationUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Refresh constraint constants whose initial values were
        // computed against `view.safeAreaInsets`/tab-bar metrics that
        // weren't valid at `viewDidLoad`. Otherwise the card (and the
        // "Tap to reveal…" caption that centres against its bottom)
        // can paint anchored to a stale, zero-safe-area origin and
        // sit too low — visibly behind the tab bar — until the next
        // cold launch happens to set up under correct insets.
        updateLayoutDependentConstants()
        updateContentPanelTopIfNeeded()
        updateBackgroundBlurBottomExtensionIfNeeded()
        updateTarotCardOuterGlow()
        updateDayNavigationBackButtonScrollPosition()
        guard dailyFitPayload != nil else { return }
        refreshDiamondScalePositions()
    }

    /// Sizes `backgroundBlurImageView`'s bottom over-extension to the
    /// worst-case parallax shift implied by the current scroll
    /// `contentSize`. The blur is translated upward by
    /// `yOffset * backgroundBlurParallaxFactor` (see
    /// `scrollViewDidScroll`); at max scroll that shift equals
    /// `maxValidOffset * backgroundBlurParallaxFactor`. If the
    /// constraint's constant is smaller than that shift plus a safety
    /// margin, the blur's bottom edge rises above the tab bar at the
    /// natural scroll limit and exposes the solid `cosmicBlue` fill.
    ///
    /// We never shrink past `backgroundBlurBottomBaseExtension` (the
    /// rest-state buffer) and we only write the constraint when it
    /// would change by more than a half point, mirroring the guard in
    /// `updateLayoutDependentConstants` so successive layout passes
    /// don't churn out no-op writes.
    private func updateBackgroundBlurBottomExtensionIfNeeded() {
        guard let bottomConstraint = backgroundBlurBottomConstraint else { return }
        let maxValidOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
        let maxParallaxShift = maxValidOffset * Self.backgroundBlurParallaxFactor
        let required = maxParallaxShift + Self.backgroundBlurSafetyMargin
        let newConstant = max(Self.backgroundBlurBottomBaseExtension, required)
        guard abs(bottomConstraint.constant - newConstant) > 0.5 else { return }
        UIView.performWithoutAnimation {
            bottomConstraint.constant = newConstant
        }
    }

    /// Re-derives the safe-area-dependent constants for the
    /// `contentView` top inset and the tarot card's vertical centre,
    /// applying them only when they meaningfully differ from the
    /// current values. The guard avoids layout feedback loops and a
    /// stream of no-op writes on every layout pass.
    ///
    /// The constant writes are wrapped in `performWithoutAnimation` so
    /// that if `viewDidLayoutSubviews` happens to fire while we are
    /// inside someone else's `UIView.animate { … layoutIfNeeded() }`
    /// — e.g. the content-panel slide-up in
    /// `setupContentSectionBackgrounds` — our background safe-area
    /// settling is never captured by that animation. Without this,
    /// shifting `contentViewTopConstraint` by ~47pt mid-reveal
    /// dragged the whole content tree (including the panel itself)
    /// through the slide-up, swallowing the visible "pop up" entirely.
    private func updateLayoutDependentConstants() {
        let newContentViewOffset = view.safeAreaInsets.top + 83

        let menuBarBottom = calculateMenuBarBottom()
        let tabBarTop = calculateTabBarTop()
        let availableHeight = tabBarTop - menuBarBottom
        let centerYInView = menuBarBottom + (availableHeight / 2)
        let newCardCenter = centerYInView - newContentViewOffset + Self.tarotCardCenterYNudge
        let newTapToRevealBottom = tabBarTop - Self.tapToRevealBottomGapAboveTabBar

        UIView.performWithoutAnimation {
            if let topConstraint = contentViewTopConstraint,
               abs(topConstraint.constant - newContentViewOffset) > 0.5 {
                topConstraint.constant = newContentViewOffset
            }
            if let centerYConstraint = cardContainerCenterYConstraint,
               abs(centerYConstraint.constant - newCardCenter) > 0.5 {
                centerYConstraint.constant = newCardCenter
            }
            if let tapBottom = tapToRevealBottomConstraint,
               abs(tapBottom.constant - newTapToRevealBottom) > 0.5 {
                tapBottom.constant = newTapToRevealBottom
            }
        }
    }

    /// Keeps the white content panel's top edge at the correct resting
    /// position once safe-area insets are known. `setupContentSectionBackgrounds`
    /// computes `finalYPosition` using `view.safeAreaInsets.top`, but on
    /// first launch that value is 0 (view not yet in the window). This
    /// method re-derives the correct constant on every layout pass so the
    /// panel lands with its rounded top visible above the tab bar regardless
    /// of when the initial setup ran.
    private func updateContentPanelTopIfNeeded() {
        guard isCardRevealed,
              let constraint = contentBackgroundTopConstraint,
              dailyFitLabel.frame.origin.y > 0 else { return }

        let contentPanelTopInset: CGFloat = 44
        let correct = dailyFitLabel.frame.origin.y - contentPanelTopInset - view.safeAreaInsets.top
        if abs(constraint.constant - correct) > 0.5 {
            constraint.constant = correct
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkForDayRollover()
        
        if !isCardRevealed && currentCardState == .unrevealed {
            scrollingRunesBackground.startAnimating()
        }
        
        checkCardRevealState()
        
        if !isCardRevealed, currentCardState == .unrevealed {
            contentView.bringSubviewToFront(tarotCardContainerView)
            contentView.bringSubviewToFront(tapToRevealLabel)
        }
        
        if isCardRevealed {
            // Ensure container is properly positioned and visible
            tarotCardContainerView.alpha = 1.0
            tarotCardContainerView.transform = .identity
            // Reset halo over-scroll state when we re-enter the
            // revealed view, otherwise a previous pull's scale + fade
            // (last written by `scrollViewDidScroll`) could persist
            // on the next appearance until the user scrolls again.
            tarotCardGlowView.transform = .identity
            tarotCardGlowView.alpha = 1.0
            tarotCardImageView.alpha = 1.0
            
            view.layoutIfNeeded()
            
            print("Card container and content restored on tab return")
        }
        
        // CRITICAL: Keep the top mask above scroll content and the day-back button just beneath it,
        // so the button can slide behind the nav strip when it starts tracking the header row.
        view.bringSubviewToFront(topMaskView)
        if isViewingTomorrow {
            positionDayNavigationBackButtonInChromeStack()
            updateDayNavigationBackButtonScrollPosition()
        }

        // Activate the inverted-tilt 3D parallax on the card container
        // while this tab is visible. Created here (rather than in
        // `viewDidLoad`) so the gyro/accelerometer are only running
        // while the card is actually on-screen.
        if cardParallax == nil {
            cardParallax = MotionParallaxBinding(host: tarotCardContainerView)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Calculate visible height (excluding tab bar)
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        let visibleHeight = view.bounds.height - tabBarHeight
        
        scrollingRunesBackground.startAnimating(visibleHeight: visibleHeight)

        // Restart tarot halo breath if layout did not run (e.g. quick tab switch).
        updateTarotCardOuterGlow()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scrollingRunesBackground.stopAnimating()
        stopTarotCardGlowBreathingAnimation()
        // Tear down parallax so the gyro/accelerometer stop while the
        // tab is hidden; deinit on `MotionParallaxBinding` also resets
        // the host's `layer.transform` to identity, preventing a
        // stale tilt from being baked in when we re-appear.
        cardParallax = nil
    }
    
    // MARK: - Memory Management
    deinit {
        NotificationCenter.default.removeObserver(self)
        ciContext = nil
        cardBackImageView.layer.filters = nil
        if let gesture = cardTapGesture {
            cardBackImageView.removeGestureRecognizer(gesture)
        }
        scrollingRunesBackground.stopAnimating()
    }
    
    // MARK: - Configuration

    func configure(with payload: DailyFitPayload,
                   originalChartViewController: NatalChartViewController?) {
        self.dailyFitPayload = payload
        self.todayPayload = payload
        self.originalChartViewController = originalChartViewController
        self.displayDate = Date()
        self.todayDate = Date()
        self.isViewingTomorrow = false

        if isViewLoaded {
            updateContentFromPayload()
            updateDayNavigationUI()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        
        // Always start with black background
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        
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

        // Captured so the constant can be refreshed once the real
        // `view.safeAreaInsets.top` is known (see
        // `updateLayoutDependentConstants`). At `viewDidLoad` time the
        // view isn't in the window yet, so the insets read as zero and
        // a one-shot inline `constant:` would freeze that wrong value.
        contentViewTopConstraint = contentView.topAnchor.constraint(
            equalTo: scrollView.topAnchor,
            constant: view.safeAreaInsets.top + 83
        )

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // ContentView starts with padding for menu bar + safe area
            contentViewTopConstraint!,
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Add cosmic grey mask above menu bar
        topMaskView.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        topMaskView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topMaskView)

        NSLayoutConstraint.activate([
            topMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            topMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topMaskView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.height - 10)
        ])
        
        setupTarotCardHeader()
        setupCardRevealUI()
        setupContentViewComponents()
        setupConstraints()
        setupDayNavigationBackButton()
        
        checkCardRevealState()
        updateDayNavigationUI()
        
        view.bringSubviewToFront(topMaskView)
        if isViewingTomorrow {
            positionDayNavigationBackButtonInChromeStack()
            updateDayNavigationBackButtonScrollPosition()
        }
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
        
        // EXTENDED constraints - background extends beyond screen
        // bounds to cover the parallax shift. The bottom constraint is
        // stored and updated in `viewDidLayoutSubviews` once the scroll
        // `contentSize` is known, because the maximum parallax shift
        // (and therefore the required over-extension below the tab bar)
        // scales with content length. Long daily-fit readings would
        // otherwise translate the blur up so far that its bottom edge
        // rose above the tab bar, leaving the solid `cosmicBlue` fill
        // visible underneath. The top stays fixed because top
        // rubber-band moves the blur DOWN — never opening a gap there.
        let extraHeight = Self.backgroundBlurBottomBaseExtension
        let bottomConstraint = backgroundBlurImageView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: extraHeight
        )
        backgroundBlurBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            backgroundBlurImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: -extraHeight),
            backgroundBlurImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint
        ])

        revealedBackgroundDimmingView.translatesAutoresizingMaskIntoConstraints = false
        revealedBackgroundDimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.52)
        revealedBackgroundDimmingView.isUserInteractionEnabled = false
        revealedBackgroundDimmingView.alpha = 0
        view.insertSubview(revealedBackgroundDimmingView, aboveSubview: backgroundBlurImageView)
        NSLayoutConstraint.activate([
            revealedBackgroundDimmingView.topAnchor.constraint(equalTo: backgroundBlurImageView.topAnchor),
            revealedBackgroundDimmingView.leadingAnchor.constraint(equalTo: backgroundBlurImageView.leadingAnchor),
            revealedBackgroundDimmingView.trailingAnchor.constraint(equalTo: backgroundBlurImageView.trailingAnchor),
            revealedBackgroundDimmingView.bottomAnchor.constraint(equalTo: backgroundBlurImageView.bottomAnchor)
        ])
        
        print("Background blur image view setup with extended bounds to cover scroll area")
    }
    
    // MARK: - Card Reveal UI Setup
    private func setupCardRevealUI() {
        // UNREVEALED STATE: Card back lives in `tarotCardContainerView`; tap caption is a `contentView` sibling so the card glow bounds stay tight.
        cardBackImageView.translatesAutoresizingMaskIntoConstraints = false
        cardBackImageView.contentMode = .scaleAspectFit
        cardBackImageView.clipsToBounds = false
        let cardBackImage = UIImage(named: "CardBacks")
        cardBackImageView.image = cardBackImage
        cardBackImageView.layer.cornerRadius = 24
        cardBackImageView.isUserInteractionEnabled = true
        
        tarotCardContainerView.addSubview(cardBackImageView)

        // Iridescent sheen for the card back. Subview of the imageView so
        // it inherits the 3D flip transform applied during reveal, and is
        // given its mask image immediately so it paints in unison with
        // the back artwork on first appearance.
        attachSheen(cardBackSheenView, to: cardBackImageView, image: cardBackImage)
        
        // UNREVEALED STATE: Tap to reveal label
        tapToRevealLabel.translatesAutoresizingMaskIntoConstraints = false
        tapToRevealLabel.text = "Tap to reveal today's fit"
        
        tapToRevealLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.headline,
            weight: .medium
        )
        tapToRevealLabel.textAlignment = .center
        tapToRevealLabel.textColor = .white
        tapToRevealLabel.backgroundColor = .clear
        tapToRevealLabel.numberOfLines = 2
        tapToRevealLabel.isUserInteractionEnabled = true
        
        // Sibling of the card container (not inside it) so halo/shadow bounds stay card-sized.
        contentView.addSubview(tapToRevealLabel)

        // Add tap gesture to card back
        cardTapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardBackImageView.addGestureRecognizer(cardTapGesture!)
        let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        tapToRevealLabel.addGestureRecognizer(captionTapGesture)

        let minCaptionHeight = tapToRevealLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        minCaptionHeight.priority = .defaultHigh

        // Pin the caption's bottom to `view.topAnchor` with a manually
        // managed constant equal to the tab bar's top edge in this
        // view's coords, minus a small visual gap. We *can't* anchor
        // to `view.safeAreaLayoutGuide.bottomAnchor` here even though
        // that would be the obvious choice — UIKit derives that guide
        // from `view.bounds.height - safeAreaInsets.bottom`, and
        // during a `SlideTabTransitionAnimator` transition the view
        // is reparented out from under the tab bar, which collapses
        // `safeAreaInsets.bottom` to 0 (or just the home-indicator
        // 34pt) while `bounds.height` stretches to the full screen
        // height. The safe-area guide then sits ~50–83pt below the
        // real tab bar top, dragging the caption partway under the
        // tab bar where the user sees it as "having drifted down".
        // `view.topAnchor` is stable across all that reparenting, so
        // anchoring there and writing the resolved offset by hand
        // (via `updateLayoutDependentConstants`) keeps the caption at
        // the correct 32pt above the tab bar in every layout pass —
        // same fix shape as `calculateTabBarTop()`.
        let initialTapBottom = calculateTabBarTop() - Self.tapToRevealBottomGapAboveTabBar
        tapToRevealBottomConstraint = tapToRevealLabel.bottomAnchor.constraint(
            equalTo: view.topAnchor,
            constant: initialTapBottom
        )
        tapToRevealBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardBackImageView.topAnchor.constraint(equalTo: tarotCardContainerView.topAnchor),
            cardBackImageView.leadingAnchor.constraint(equalTo: tarotCardContainerView.leadingAnchor),
            cardBackImageView.trailingAnchor.constraint(equalTo: tarotCardContainerView.trailingAnchor),
            cardBackImageView.bottomAnchor.constraint(equalTo: tarotCardContainerView.bottomAnchor),

            tapToRevealLabel.centerXAnchor.constraint(equalTo: tarotCardContainerView.centerXAnchor),
            tapToRevealLabel.leadingAnchor.constraint(equalTo: tarotCardContainerView.leadingAnchor),
            tapToRevealLabel.trailingAnchor.constraint(equalTo: tarotCardContainerView.trailingAnchor),
            minCaptionHeight
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
            self.cardBackImageView.alpha = 1.0
            self.cardBackImageView.isHidden = false
            self.cardBackImageView.isUserInteractionEnabled = true
            self.tapToRevealLabel.alpha = 1.0
            self.tapToRevealLabel.isHidden = false
            self.tapToRevealLabel.isUserInteractionEnabled = true
            self.scrollingRunesBackground.alpha = 1.0
            
            self.tarotCardImageView.alpha = 0.0
            self.backgroundBlurImageView.alpha = 0.0
            self.revealedBackgroundDimmingView.alpha = 0.0
            self.scrollIndicatorView.alpha = 0.0
            self.contentBackgroundView?.alpha = 0.0
            self.calendarButton.alpha = 0.0
            
            let allContentViews: [UIView?] = [
                self.dailyFitLabel, self.calendarButton, self.tarotSymbolLabel, self.tarotTitleLabel, self.dateLabel,
                self.topDivider,
                self.styleEditHeaderLabel, self.styleEditLabel,
                self.postTarotParagraphDivider,
                self.postDailyRitualDivider,
                self.styleBreakdownDivider, self.colourHeaderDivider, self.colourPaletteContainer,
                self.toneSliderContainer,
                self.vibeHeaderDivider, self.essenceTriangleView,
                self.silhouetteHeaderDivider, self.silhouetteContainer,
                self.finalStarDivider,
                self.dailyRitualHeaderDivider, self.dailyRitualLabel,
                self.vibrancyScaleContainer, self.contrastScaleContainer,
                self.wardrobeReflectionHeaderDivider, self.wardrobeReflectionLabel,
                self.tomorrowTeaseLabel, self.tomorrowButton
            ]
            allContentViews.compactMap { $0 }.forEach { $0.alpha = 0.0 }
            
            self.tarotCardContainerView.alpha = 1.0
            self.tarotCardContainerView.transform = .identity
            // Mirror the card container reset on the halo sibling —
            // see `viewWillAppear` for the rationale; without this,
            // returning to the unrevealed state with leftover
            // over-scroll scale/fade from a prior revealed session
            // would briefly show a faded, oversized halo.
            self.tarotCardGlowView.transform = .identity
            self.tarotCardGlowView.alpha = 1.0

            self.scrollView.isScrollEnabled = false
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: applyChanges) { _ in
                self.contentView.bringSubviewToFront(self.tarotCardContainerView)
                self.contentView.bringSubviewToFront(self.tapToRevealLabel)
                self.view.layoutIfNeeded()
                self.updateTarotCardOuterGlow()
            }
        } else {
            applyChanges()
            contentView.bringSubviewToFront(tarotCardContainerView)
            contentView.bringSubviewToFront(tapToRevealLabel)
            view.layoutIfNeeded()
            updateTarotCardOuterGlow()
        }
        
        scrollingRunesBackground.startAnimating()
        view.backgroundColor = .black
    }
    
    private func showRevealedStateUnified(animated: Bool) {
        scrollingRunesBackground.stopAnimating()

        // Reset halo over-scroll state on every transition into the
        // revealed view; `scrollViewDidScroll` is the only writer and
        // it bails for unrevealed cards, so a previous pull's scale +
        // fade would otherwise persist into the next reveal.
        tarotCardGlowView.transform = .identity
        tarotCardGlowView.alpha = 1.0

        let applyChanges = {
            self.cardBackImageView.alpha = 0.0
            self.cardBackImageView.isHidden = true
            self.tapToRevealLabel.alpha = 0.0
            self.tapToRevealLabel.isHidden = true
            self.scrollingRunesBackground.alpha = 0.0
            
            self.tarotCardImageView.alpha = 1.0
            self.backgroundBlurImageView.alpha = 1.0
            self.revealedBackgroundDimmingView.alpha = 1.0
            self.scrollIndicatorView.alpha = 1.0
            self.scrollIndicatorView.isHidden = false
            self.calendarButton.alpha = 1.0
            
            let allContentViews: [UIView?] = [
                self.dailyFitLabel, self.calendarButton, self.tarotSymbolLabel, self.tarotTitleLabel, self.dateLabel,
                self.topDivider,
                self.styleEditHeaderLabel, self.styleEditLabel,
                self.postTarotParagraphDivider,
                self.postDailyRitualDivider,
                self.styleBreakdownDivider, self.colourHeaderDivider, self.colourPaletteContainer,
                self.toneSliderContainer,
                self.vibeHeaderDivider, self.essenceTriangleView,
                self.silhouetteHeaderDivider, self.silhouetteContainer,
                self.finalStarDivider,
                self.dailyRitualHeaderDivider, self.dailyRitualLabel,
                self.vibrancyScaleContainer, self.contrastScaleContainer,
                self.wardrobeReflectionHeaderDivider, self.wardrobeReflectionLabel,
                self.tomorrowTeaseLabel, self.tomorrowButton
            ]
            allContentViews.compactMap { $0 }.forEach { $0.alpha = 1.0 }
            
            self.scrollView.isScrollEnabled = true
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, animations: applyChanges) { _ in
                self.setupContentSectionBackgrounds(animated: true)
                self.ensureContainerVisibility()
                self.view.layoutIfNeeded()
                self.updateTarotCardOuterGlow()
                self.updateDayNavigationUI()
            }
        } else {
            applyChanges()
            setupContentSectionBackgrounds(animated: false)
            ensureContainerVisibility()
            view.layoutIfNeeded()
            updateTarotCardOuterGlow()
            updateDayNavigationUI()
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
        // Push the container back along z so the parallax `m34`
        // perspective can tilt corners "forward" in 3D without ever
        // letting them pop in front of sibling layers (the content
        // panel, headers, etc.). With ~5° max rotation on a ~600 pt
        // card, the forward extent is ~26 pt; -50 is a comfortable
        // safety margin so the rotated layer always stays behind
        // siblings whose `zPosition` defaults to 0. Subview-array
        // ordering still controls sibling z when zPositions match,
        // so the unrevealed state's `bringSubviewToFront` calls
        // continue to work for siblings that are also at -50; in
        // practice the only competing views in the unrevealed state
        // are the runes background and `tapToRevealLabel`, both of
        // which read fine in front of the card cover.
        tarotCardContainerView.layer.zPosition = -50
        contentView.addSubview(tarotCardContainerView)
        
        // Calculate card dimensions with padding around it
        let cardAspectRatio: CGFloat = 0.62
        let horizontalPadding: CGFloat = 33
        let cardWidth = view.bounds.width - (horizontalPadding * 2) // Reduce width by total padding
        let cardFaceHeight = cardWidth / cardAspectRatio + Self.tarotCardSlotExtraHeight
        // Container is only the card face so outer glow (`updateTarotCardOuterGlow`) matches the tarot bounds.
        cardContainerWidthConstraint = tarotCardContainerView.widthAnchor.constraint(equalToConstant: cardWidth)
        cardContainerHeightConstraint = tarotCardContainerView.heightAnchor.constraint(equalToConstant: cardFaceHeight)
        
        // Calculate the center point between menu bar and tab bar (in view coordinates)
        let menuBarBottom = calculateMenuBarBottom()
        let tabBarTop = calculateTabBarTop()
        let availableHeight = tabBarTop - menuBarBottom
        let centerYInView = menuBarBottom + (availableHeight / 2)

        // Convert to contentView coordinates
        let contentViewOffset = view.safeAreaInsets.top + 83
        let cardCenterYFromContentTop = centerYInView - contentViewOffset + Self.tarotCardCenterYNudge

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

        // Halo sibling: pinned to the card container's geometry and
        // inserted *below* it in the subview list so the shadow halo
        // composites behind the card art. We also push it further
        // back in `zPosition` than the card (which sits at -50) so
        // the parallax-rotated card layer always renders in front,
        // even when the rotation pulls a corner forward in 3D.
        tarotCardGlowView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardGlowView.backgroundColor = .clear
        tarotCardGlowView.isUserInteractionEnabled = false
        tarotCardGlowView.layer.zPosition = -100
        contentView.insertSubview(tarotCardGlowView, belowSubview: tarotCardContainerView)
        NSLayoutConstraint.activate([
            tarotCardGlowView.centerXAnchor.constraint(equalTo: tarotCardContainerView.centerXAnchor),
            tarotCardGlowView.centerYAnchor.constraint(equalTo: tarotCardContainerView.centerYAnchor),
            tarotCardGlowView.widthAnchor.constraint(equalTo: tarotCardContainerView.widthAnchor),
            tarotCardGlowView.heightAnchor.constraint(equalTo: tarotCardContainerView.heightAnchor)
        ])

        // Setup the actual tarot card image view (revealed state)
        tarotCardImageView.translatesAutoresizingMaskIntoConstraints = false
        tarotCardImageView.contentMode = .scaleAspectFit
        tarotCardImageView.clipsToBounds = true
        tarotCardImageView.backgroundColor = CosmicFitTheme.Colours.cosmicLilac // Themed placeholder
        tarotCardImageView.layer.cornerRadius = 24
        tarotCardImageView.alpha = 0.0
        tarotCardContainerView.addSubview(tarotCardImageView)
        
        NSLayoutConstraint.activate([
            tarotCardImageView.topAnchor.constraint(equalTo: tarotCardContainerView.topAnchor),
            tarotCardImageView.leadingAnchor.constraint(equalTo: tarotCardContainerView.leadingAnchor),
            tarotCardImageView.trailingAnchor.constraint(equalTo: tarotCardContainerView.trailingAnchor),
            tarotCardImageView.bottomAnchor.constraint(equalTo: tarotCardContainerView.bottomAnchor),
        ])

        // Iridescent sheen overlay for the revealed card front. Added now
        // so the layer hierarchy and motion subscription are ready before
        // any image arrives — the mask image is supplied later in
        // `loadTarotCardImage(for:)` at the same instant the imageView's
        // `image` is set, guaranteeing card art and sheen paint together.
        attachSheen(cardFrontSheenView, to: tarotCardImageView, image: nil)

        // Start the runes animation
        scrollingRunesBackground.startAnimating()
    }

    // MARK: - Motion sheen helpers

    /// Adds a `MotionSheenView` as a subview of `host`, pinned to its
    /// bounds so it inherits both layout and any 3D transforms applied
    /// during the card flip. Sets the mask image right away so the
    /// iridescent effect paints in unison with the card art rather than
    /// arriving a frame late (which would visually unmoor the sheen
    /// from the physical card).
    private func attachSheen(_ sheen: MotionSheenView, to host: UIImageView, image: UIImage?) {
        guard sheen.superview !== host else {
            sheen.cardImage = image
            return
        }
        sheen.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(sheen)
        NSLayoutConstraint.activate([
            sheen.topAnchor.constraint(equalTo: host.topAnchor),
            sheen.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            sheen.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            sheen.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        sheen.cardImage = image
    }

    /// Glow tint: lightest of the day's Style Palette picks (Lab *L*), softened for a halo on dark UI.
    private func tarotCardGlowShadowColor() -> UIColor {
        guard let picks = dailyFitPayload?.dailyPalette.colours, !picks.isEmpty else {
            return UIColor(white: 0.74, alpha: 1)
        }
        var bestColour: UIColor?
        var bestL = -Double.greatestFiniteMagnitude
        for pick in picks {
            guard let lab = ColourMath.hexToLab(pick.hexValue),
                  let c = UIColor(hex: pick.hexValue) else { continue }
            if lab.L > bestL {
                bestL = lab.L
                bestColour = c
            }
        }
        guard let base = bestColour else {
            return UIColor(white: 0.74, alpha: 1)
        }
        return Self.softenedGlowTint(from: base)
    }

    /// Blend base palette colour toward white so the shadow reads as a glow, not a solid rim.
    private static func softenedGlowTint(from base: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard base.getRed(&r, green: &g, blue: &b, alpha: &a) else { return base }
        let lift: CGFloat = 0.46
        return UIColor(
            red: r * (1 - lift) + lift,
            green: g * (1 - lift) + lift,
            blue: b * (1 - lift) + lift,
            alpha: 1
        )
    }

    private static let tarotCardContainerGlowBreathKey = "tarotCardContainerGlowBreath"
    private static let tarotCardContainerGlowRadiusBreathKey = "tarotCardContainerGlowRadiusBreath"
    /// Legacy key — stripped so older installs do not leave a static halo on the card back.
    private static let tarotCardBackGlowBreathKey = "tarotCardBackGlowBreath"
    /// Model-layer opacity when the breath animation is not running (also the visual midpoint of the pulse).
    private static let tarotCardGlowOpacityMid: Float = 0.47
    /// How far opacity swings above/below the midpoint (wider = stronger pulse contrast).
    private static let tarotCardGlowOpacityBreathDelta: Float = 0.07
    /// One leg of the breath (fade up or down); full cycle is ~2× this — lower = faster pulse.
    /// Base period scaled so pulse frequency is 3/4 of prior (slowed by 1/4).
    private static let tarotCardGlowBreathHalfPeriod: CFTimeInterval = 1.05 * (4.0 / 3.0)
    private static let tarotCardGlowShadowRadius: CGFloat = 17
    /// Extra ± swing on `shadowRadius` for a second, faster layer of “noise” on the halo.
    private static let tarotCardGlowShadowRadiusBreathDelta: CGFloat = 4
    /// Desynced from opacity half-period so the two beats don’t lock step (reads livelier / less mechanical).
    /// Same ×(4/3) as opacity leg so radius breath slows with the glow.
    private static let tarotCardGlowRadiusBreathHalfPeriod: CFTimeInterval = 0.72 * (4.0 / 3.0)

    /// Points of top-rubber-band pull at which the halo's "dissipate"
    /// effect saturates. Below this, scale + fade ease in linearly;
    /// at and above, the halo holds at its terminal scale/alpha so a
    /// long pull doesn't grow the effect without bound.
    private static let tarotCardGlowOverscrollSaturation: CGFloat = 120
    /// Additional scale at saturation (1.0 + this = peak scale). Tuned
    /// so the halo visibly spreads around the card without crowding
    /// the screen edges or pulling the shadow into hard banding.
    private static let tarotCardGlowOverscrollMaxScale: CGFloat = 0.55
    /// Fraction of alpha removed at saturation. Anchored well clear of
    /// 1.0 so the halo never fully disappears — even at peak pull a
    /// soft remnant still reads as the card's own light.
    private static let tarotCardGlowOverscrollFadeDepth: CGFloat = 0.8

    /// Soft outer glow around the rounded tarot card; colour follows the day's light palette tone.
    /// Hosted on `tarotCardGlowView` (a sibling pinned to the card's
    /// geometry, never given a 3D transform) so the halo no longer
    /// rides the card container's `m34` parallax — which previously
    /// caused the shadow to slide down away from the card during
    /// rubber-band over-scroll because CALayer's shadow rendering
    /// does not honour perspective transforms.
    private func updateTarotCardOuterGlow() {
        let cornerRadius: CGFloat = 24
        let containerBounds = tarotCardContainerView.bounds
        guard containerBounds.width > 1, containerBounds.height > 1 else { return }

        stripTarotOuterGlow(from: cardBackImageView, breathKey: Self.tarotCardBackGlowBreathKey)
        // Defensive: clear any legacy shadow that may still be on the
        // card container itself (older code paths applied the glow
        // here). Without this, the old halo would double-render
        // behind the new sibling halo and continue exhibiting the
        // 3D-drift bug.
        stripTarotOuterGlow(from: tarotCardContainerView, breathKey: Self.tarotCardContainerGlowBreathKey)
        applyTarotOuterGlow(
            to: tarotCardGlowView,
            bounds: containerBounds,
            cornerRadius: cornerRadius,
            breathKey: Self.tarotCardContainerGlowBreathKey
        )
    }

    private func stripTarotOuterGlow(from host: UIView, breathKey: String) {
        host.layer.removeAnimation(forKey: breathKey)
        host.layer.shadowOpacity = 0
        host.layer.shadowRadius = 0
        host.layer.shadowOffset = .zero
        host.layer.shadowPath = nil
        host.layer.shadowColor = nil
    }

    private func applyTarotOuterGlow(to host: UIView, bounds: CGRect, cornerRadius: CGFloat, breathKey: String) {
        guard bounds.width > 1, bounds.height > 1 else { return }
        host.layer.masksToBounds = false
        host.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        host.layer.shadowColor = tarotCardGlowShadowColor().cgColor
        host.layer.shadowRadius = Self.tarotCardGlowShadowRadius
        host.layer.shadowOffset = .zero
        if host.layer.animation(forKey: breathKey) == nil {
            host.layer.shadowOpacity = Self.tarotCardGlowOpacityMid
            addTarotGlowBreathing(to: host.layer, key: breathKey)
        }
    }

    private func addTarotGlowBreathing(to layer: CALayer, key: String) {
        guard layer.animation(forKey: key) == nil else { return }
        let mid = Self.tarotCardGlowOpacityMid
        let delta = Self.tarotCardGlowOpacityBreathDelta
        let opacityAnim = CABasicAnimation(keyPath: "shadowOpacity")
        opacityAnim.fromValue = mid - delta
        opacityAnim.toValue = mid + delta
        opacityAnim.duration = Self.tarotCardGlowBreathHalfPeriod
        opacityAnim.autoreverses = true
        opacityAnim.repeatCount = .infinity
        opacityAnim.isRemovedOnCompletion = false
        opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(opacityAnim, forKey: key)

        guard layer.animation(forKey: Self.tarotCardContainerGlowRadiusBreathKey) == nil else { return }
        let baseRadius = Self.tarotCardGlowShadowRadius
        let rDelta = Self.tarotCardGlowShadowRadiusBreathDelta
        let radiusAnim = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnim.fromValue = baseRadius - rDelta
        radiusAnim.toValue = baseRadius + rDelta
        radiusAnim.duration = Self.tarotCardGlowRadiusBreathHalfPeriod
        radiusAnim.autoreverses = true
        radiusAnim.repeatCount = .infinity
        radiusAnim.isRemovedOnCompletion = false
        radiusAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(radiusAnim, forKey: Self.tarotCardContainerGlowRadiusBreathKey)
    }

    private func stopTarotCardGlowBreathingAnimation() {
        // Halo now lives on its own sibling view; the card container
        // never hosts a breath animation any more (see
        // `updateTarotCardOuterGlow`).
        stopTarotGlowBreath(on: tarotCardGlowView.layer)
        stripTarotOuterGlow(from: cardBackImageView, breathKey: Self.tarotCardBackGlowBreathKey)
    }

    private func stopTarotGlowBreath(on layer: CALayer) {
        let hadOpacity = layer.animation(forKey: Self.tarotCardContainerGlowBreathKey) != nil
        let hadRadius = layer.animation(forKey: Self.tarotCardContainerGlowRadiusBreathKey) != nil
        guard hadOpacity || hadRadius else { return }
        layer.removeAnimation(forKey: Self.tarotCardContainerGlowBreathKey)
        layer.removeAnimation(forKey: Self.tarotCardContainerGlowRadiusBreathKey)
        layer.shadowOpacity = Self.tarotCardGlowOpacityMid
        layer.shadowRadius = Self.tarotCardGlowShadowRadius
    }

    private func calculateMenuBarBottom() -> CGFloat {
        // Menu bar positioning from CosmicFitTabBarController:
        // menuBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10)
        return view.safeAreaInsets.top + MenuBarView.height - 10
    }

    private func calculateTabBarTop() -> CGFloat {
        // Query the tab bar's actual on-screen position via window
        // coordinates rather than deriving it from
        // `view.bounds.height - safeAreaInsets.bottom`.
        //
        // Why the safe-area-based derivation isn't safe here:
        // `SlideTabTransitionAnimator` does `containerView.addSubview(toVC.view)`
        // mid-transition, which reparents this VC's view out from under
        // the tab bar. While reparented, `view.bounds.height` stretches
        // to the transition container's full screen height (~852pt on
        // iPhone 14 Pro) while `safeAreaInsets.bottom` collapses to 0
        // (or just the 34pt home-indicator inset) because the tab bar
        // is no longer an ancestor. `bounds.height - safeAreaInsets.bottom`
        // then reports 852 or 818 instead of the real 769, and any
        // `viewDidLayoutSubviews` pass that fires during the transition
        // writes the wrong `cardContainerCenterYConstraint.constant`
        // (`333.5` or `316.5` instead of `292` on iPhone 14 Pro). The
        // bad constant persists after the transition completes — the
        // settled post-transition mode (bounds=852, bottom=34) also
        // resolves to a wrong value — until something else (presenting
        // the menu / account sub-page) bounces the view back to the
        // "natural" mode (bounds=769, bottom=0) and the layout pass
        // re-converges to 292.
        //
        // The tab bar's own position in the window is stable across
        // all of this: it doesn't move during a tab transition. So
        // computing `tabBarTop_in_window - viewTop_in_window` gives
        // the correct relative position in this view's coordinate
        // space regardless of which container the view currently
        // sits inside.
        if let tabBar = tabBarController?.tabBar,
           let window = view.window ?? tabBar.window {
            let tabBarTopInWindow = tabBar.convert(CGPoint.zero, to: window).y
            let viewOriginInWindow = view.convert(CGPoint.zero, to: window).y
            return tabBarTopInWindow - viewOriginInWindow
        }
        // Fallback for the brief window where the view (or the tab
        // bar) isn't attached to a UIWindow yet — e.g. very first
        // `viewDidLayoutSubviews` after `viewDidLoad`, before the
        // tab bar controller has finished moving the VC into its
        // hierarchy. The derived value is wrong here too, but it
        // will be corrected on the next layout pass once the view
        // is in a window.
        return view.bounds.height - view.safeAreaInsets.bottom
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
        setupNewPipelineContentSections()

        // Initially hide all content (will fade in after card reveal)
        setInitialContentAlpha()
    }

    // MARK: - New Pipeline Content Sections

    private func setupNewPipelineContentSections() {
        setupStyleParagraphSection()
        setupDailyRitualSection()
        setupStyleBreakdownSection()
        setupNewColourPaletteSection()
        setupVibrancyContrastSection()
        setupNewToneSliderSection()
        setupEssenceSection()
        setupNewSilhouetteSection()
        setupWardrobeReflectionSection()
        setupNewBottomSection()
    }

    private func setupStyleParagraphSection() {
        topDivider = createSimpleDivider()
        topDivider?.alpha = 0.0
        if let divider = topDivider {
            contentView.addSubview(divider)
            divider.backgroundColor = .black
        }

        styleEditLabel.text = ""
        styleEditLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.body,
            weight: .regular
        )
        styleEditLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        styleEditLabel.textAlignment = .left
        styleEditLabel.numberOfLines = 0
        styleEditLabel.translatesAutoresizingMaskIntoConstraints = false
        styleEditLabel.alpha = 0.0
        contentView.addSubview(styleEditLabel)
    }

    private func setupDailyRitualSection() {
        postTarotParagraphDivider = createSimpleDivider()
        postTarotParagraphDivider?.alpha = 0.0
        if let divider = postTarotParagraphDivider {
            contentView.addSubview(divider)
        }

        dailyRitualHeaderDivider = createLargeHeaderLabel("Daily Ritual")
        dailyRitualHeaderDivider?.alpha = 0.0
        if let header = dailyRitualHeaderDivider {
            contentView.addSubview(header)
        }

        dailyRitualLabel.numberOfLines = 0
        dailyRitualLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyRitualLabel.alpha = 0.0
        dailyRitualLabel.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(size: CosmicFitTheme.Typography.FontSizes.body)
        dailyRitualLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        dailyRitualLabel.textAlignment = .center
        contentView.addSubview(dailyRitualLabel)

        postDailyRitualDivider = createSimpleDivider()
        postDailyRitualDivider?.alpha = 0.0
        if let divider = postDailyRitualDivider {
            contentView.addSubview(divider)
        }
    }

    private func setupNewColourPaletteSection() {
        colourHeaderDivider = createOrnamentalDividerWithText("Style Palette")
        colourHeaderDivider?.alpha = 0.0
        if let divider = colourHeaderDivider {
            contentView.addSubview(divider)
        }

        colourPaletteContainer.translatesAutoresizingMaskIntoConstraints = false
        colourPaletteContainer.alpha = 0.0
        contentView.addSubview(colourPaletteContainer)
    }

    private func setupVibrancyContrastSection() {
        let (vibContainer, vibIndicator, vibTrack) = buildVibrancyScale()
        vibrancyScaleContainer = vibContainer
        vibrancyIndicator = vibIndicator
        vibrancyTrack = vibTrack
        vibrancyScaleContainer.translatesAutoresizingMaskIntoConstraints = false
        vibrancyScaleContainer.alpha = 0.0
        contentView.addSubview(vibrancyScaleContainer)

        let (conContainer, conIndicator, conTrack) = buildContrastScale()
        contrastScaleContainer = conContainer
        contrastIndicator = conIndicator
        contrastTrack = conTrack
        contrastScaleContainer.translatesAutoresizingMaskIntoConstraints = false
        contrastScaleContainer.alpha = 0.0
        contentView.addSubview(contrastScaleContainer)
    }

    private func setupNewToneSliderSection() {
        toneHeaderLabel.isHidden = true
        toneHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        toneHeaderLabel.alpha = 0.0

        let (toneContainer, toneInd, toneTrackView) = buildMetalToneScale()
        toneSliderContainer = toneContainer
        metalToneIndicator = toneInd
        metalToneTrack = toneTrackView
        toneSliderContainer.translatesAutoresizingMaskIntoConstraints = false
        toneSliderContainer.alpha = 0.0
        contentView.addSubview(toneSliderContainer)
    }

    private func setupEssenceSection() {
        vibeHeaderDivider = createOrnamentalDividerWithText("Essence")
        vibeHeaderDivider?.alpha = 0.0
        if let divider = vibeHeaderDivider {
            contentView.addSubview(divider)
        }

        let triangle = EssenceTriangleView()
        triangle.translatesAutoresizingMaskIntoConstraints = false
        triangle.alpha = 0.0
        contentView.addSubview(triangle)
        essenceTriangleView = triangle
    }

    private func setupNewSilhouetteSection() {
        silhouetteHeaderDivider = createOrnamentalDividerWithText("Silhouette")
        silhouetteHeaderDivider?.alpha = 0.0
        if let divider = silhouetteHeaderDivider {
            contentView.addSubview(divider)
        }

        silhouetteContainer.translatesAutoresizingMaskIntoConstraints = false
        silhouetteContainer.alpha = 0.0
        contentView.addSubview(silhouetteContainer)

        let sliderLabels = [
            ("Masculine", "Feminine"),
            ("Angular", "Rounded"),
            ("Structured", "Draped")
        ]

        silhouetteSliderData = []
        var lastSlider: UIView?

        for (leftLabel, rightLabel) in sliderLabels {
            let (slider, indicator, track) = createSilhouetteSlider(leftLabel: leftLabel, rightLabel: rightLabel)
            slider.translatesAutoresizingMaskIntoConstraints = false
            silhouetteContainer.addSubview(slider)
            silhouetteSliderData.append((indicator: indicator, track: track, constraint: nil))

            NSLayoutConstraint.activate([
                slider.leadingAnchor.constraint(equalTo: silhouetteContainer.leadingAnchor),
                slider.trailingAnchor.constraint(equalTo: silhouetteContainer.trailingAnchor),
            ])

            if let last = lastSlider {
                slider.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 24).isActive = true
            } else {
                slider.topAnchor.constraint(equalTo: silhouetteContainer.topAnchor).isActive = true
            }
            lastSlider = slider
        }

        if let lastSlider = lastSlider {
            silhouetteContainer.bottomAnchor.constraint(equalTo: lastSlider.bottomAnchor).isActive = true
        }
    }

    /// PT Serif bold italic — synthesised from `PTSerif-Italic` when no dedicated bold-italic face is bundled.
    private func preferredBoldItalicSerifFont(size: CGFloat) -> UIFont {
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

    private var wardrobeReflectionHeaderDivider: UIView?

    private func setupWardrobeReflectionSection() {
        wardrobeReflectionHeaderDivider = createSimpleDivider()
        wardrobeReflectionHeaderDivider?.alpha = 0.0
        if let header = wardrobeReflectionHeaderDivider {
            contentView.addSubview(header)
        }

        wardrobeReflectionLabel.numberOfLines = 0
        wardrobeReflectionLabel.translatesAutoresizingMaskIntoConstraints = false
        wardrobeReflectionLabel.alpha = 0.0
        let wardrobeBody = CosmicFitTheme.Typography.FontSizes.body
        // Slightly larger than tease copy (body / regular) so the reflection reads as the hero line.
        wardrobeReflectionLabel.font = preferredBoldItalicSerifFont(size: wardrobeBody + 2)
        wardrobeReflectionLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        wardrobeReflectionLabel.textAlignment = .center
        contentView.addSubview(wardrobeReflectionLabel)
    }

    private func setupNewBottomSection() {
        finalStarDivider = createStarDivider()
        finalStarDivider?.alpha = 0.0
        if let divider = finalStarDivider {
            contentView.addSubview(divider)
        }

        tomorrowTeaseLabel.font = preferredBoldItalicSerifFont(size: CosmicFitTheme.Typography.FontSizes.body)
        tomorrowTeaseLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        tomorrowTeaseLabel.textAlignment = .center
        tomorrowTeaseLabel.numberOfLines = 0
        tomorrowTeaseLabel.translatesAutoresizingMaskIntoConstraints = false
        tomorrowTeaseLabel.alpha = 0.0
        contentView.addSubview(tomorrowTeaseLabel)

        CosmicFitTheme.styleButton(tomorrowButton, style: .secondary)
        tomorrowButton.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote, weight: .medium
        )
        tomorrowButton.translatesAutoresizingMaskIntoConstraints = false
        tomorrowButton.titleLabel?.numberOfLines = 1
        tomorrowButton.titleLabel?.lineBreakMode = .byClipping
        tomorrowButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        tomorrowButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        tomorrowButton.alpha = 0.0
        tomorrowButton.addTarget(self, action: #selector(dayNavigationButtonTapped), for: .touchUpInside)
        contentView.addSubview(tomorrowButton)
    }

    // MARK: - Day Navigation

    @objc private func dayNavigationButtonTapped() {
        if isViewingTomorrow {
            switchToToday()
        } else {
            guard EntitlementManager.shared.hasFullAccess else {
                presentPurchaseScreen()
                return
            }
            switchToTomorrow()
        }
    }

    private func presentDetailScreen(_ contentViewController: UIViewController) {
        if let tbc = tabBarController as? CosmicFitTabBarController {
            let detailVC = GenericDetailViewController(contentViewController: contentViewController)
            tbc.presentDetailViewController(detailVC, animated: true)
        } else {
            contentViewController.modalPresentationStyle = .pageSheet
            present(contentViewController, animated: true)
        }
    }

    private func presentPurchaseScreen() {
        presentDetailScreen(PurchaseViewController())
    }

    private func presentStyleCalendarUnlockScreen() {
        let mode: StyleCalendarUnlockViewController.PresentationMode =
            EntitlementManager.shared.hasFullAccess ? .subscribedComingSoon : .unlockPreview
        let calendarVC = StyleCalendarUnlockViewController(
            mode: mode,
            isViewingTomorrow: isViewingTomorrow,
            todayDate: todayDate
        )
        calendarVC.onDaySelected = { [weak self] goToTomorrow in
            guard let self = self else { return }
            if let tbc = self.tabBarController as? CosmicFitTabBarController {
                tbc.dismissDetailViewController(animated: true) {
                    if goToTomorrow {
                        self.switchToTomorrow()
                    } else {
                        self.switchToToday()
                    }
                }
            }
        }
        presentDetailScreen(calendarVC)
    }

    private func switchToTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayDate) ?? todayDate

        if tomorrowPayload == nil {
            tomorrowPayload = payloadGenerator?(tomorrow)
        }
        guard let payload = tomorrowPayload else { return }

        performDayBlurTransition {
            self.applyDaySwitch(date: tomorrow, payload: payload, isTomorrow: true)
        }
    }

    private func switchToToday() {
        guard let payload = todayPayload else { return }
        performDayBlurTransition {
            self.applyDaySwitch(date: self.todayDate, payload: payload, isTomorrow: false)
        }
    }

    /// Common work for switching the displayed day.
    private func applyDaySwitch(date: Date, payload: DailyFitPayload, isTomorrow: Bool) {
        displayDate = date
        isViewingTomorrow = isTomorrow
        dailyFitPayload = payload

        updateContentFromPayload()
        scrollView.setContentOffset(.zero, animated: false)
        checkCardRevealState()
        updateDayNavigationUI()
    }

    /// Cross-blur transition used when moving between days.
    /// The current page progressively blurs in place, the underlying content is swapped
    /// while the heavy blur visually masks the change, then the new page blurs back to clear.
    /// Neither page is ever faded to a solid colour, so there is no "background reveal".
    private func performDayBlurTransition(reconfigure: @escaping () -> Void) {
        let halfDuration: TimeInterval = 0.25 * 0.75
        let fadeOutBackButton = isViewingTomorrow && !dayNavigationBackButton.isHidden && dayNavigationBackButton.alpha > 0

        // Snapshot the current state so the reconfigure happens invisibly behind the veil.
        let snapshotBefore = view.snapshotView(afterScreenUpdates: false)
        snapshotBefore?.frame = view.bounds
        snapshotBefore?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        snapshotBefore?.isUserInteractionEnabled = false

        let blurView = UIVisualEffectView(effect: nil)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false

        // Keep `topMaskView` above the blur so the strip under the tab menu stays cosmic grey.
        if let snapshotBefore = snapshotBefore {
            view.insertSubview(snapshotBefore, belowSubview: topMaskView)
        }
        view.insertSubview(blurView, belowSubview: topMaskView)
        view.bringSubviewToFront(topMaskView)
        positionDayNavigationBackButtonInChromeStack()

        if fadeOutBackButton {
            dayNavigationBackButton.isUserInteractionEnabled = false
            UIView.animate(withDuration: halfDuration, delay: 0, options: .curveEaseIn) {
                self.dayNavigationBackButton.alpha = 0
            }
        }

        let blurInAnimator = UIViewPropertyAnimator(duration: halfDuration, curve: .easeIn) {
            blurView.effect = UIBlurEffect(style: .regular)
        }
        blurInAnimator.addCompletion { [weak self] _ in
            guard let self = self else {
                snapshotBefore?.removeFromSuperview()
                blurView.removeFromSuperview()
                return
            }

            // Reconfigure the live view while it is hidden behind the snapshot + blur layers.
            reconfigure()
            self.view.layoutIfNeeded()

            // Drop the "before" snapshot so the same blur view now renders the new content.
            snapshotBefore?.removeFromSuperview()
            self.view.bringSubviewToFront(self.topMaskView)

            let blurOutAnimator = UIViewPropertyAnimator(duration: halfDuration, curve: .easeOut) {
                blurView.effect = nil
            }
            blurOutAnimator.addCompletion { _ in
                blurView.removeFromSuperview()
            }
            blurOutAnimator.startAnimation()
        }
        blurInAnimator.startAnimation()
    }

    @objc private func dayNavigationBackTapped() {
        guard isViewingTomorrow else { return }
        switchToToday()
    }

    /// Retapping the Daily Fit tab while viewing tomorrow returns to today (same blur transition as other day switches).
    func handleTabBarDailyFitReselect() {
        guard isViewingTomorrow else { return }
        switchToToday()
    }

    private func updateDayNavigationUI() {
        if isViewingTomorrow {
            if isCardRevealed {
                CosmicNavigationArrow.apply(
                    to: tomorrowButton,
                    title: "SEE TODAY\u{2019}S FIT",
                    arrow: .left,
                    pointSize: 6
                )
                tomorrowTeaseLabel.text = "Today\u{2019}s fit awaits you..."
            } else {
                tapToRevealLabel.text = "Tap to reveal tomorrow\u{2019}s fit"
            }
            dayNavigationBackButton.isHidden = false
            dayNavigationBackButton.alpha = 1
            dayNavigationBackButton.isUserInteractionEnabled = true
        } else {
            if EntitlementManager.shared.hasFullAccess {
                CosmicNavigationArrow.apply(
                    to: tomorrowButton,
                    title: "SEE TOMORROW\u{2019}S FIT",
                    arrow: .right,
                    pointSize: 6
                )
            } else {
                var config = tomorrowButton.configuration ?? UIButton.Configuration.plain()
                var titleAttributes = AttributeContainer()
                titleAttributes.font = CosmicFitTheme.Typography.dmSansFont(
                    size: CosmicFitTheme.Typography.FontSizes.footnote,
                    weight: .medium
                )
                config.attributedTitle = AttributedString("UNLOCK FULL ACCESS", attributes: titleAttributes)
                config.image = nil
                config.titleLineBreakMode = .byClipping
                config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
                config.baseForegroundColor = CosmicFitTheme.Colours.cosmicBlue
                tomorrowButton.configuration = config
            }
            tomorrowTeaseLabel.text = "Tomorrow\u{2019}s energy is already shifting..."
            dayNavigationBackButton.isHidden = true
            dayNavigationBackButton.alpha = 0
            dayNavigationBackButton.isUserInteractionEnabled = true
            tapToRevealLabel.text = "Tap to reveal today\u{2019}s fit"
        }
        if isViewingTomorrow {
            positionDayNavigationBackButtonInChromeStack()
            updateDayNavigationBackButtonScrollPosition()
        } else {
            dayNavigationBackButton.transform = .identity
        }
    }

    private func setupDayNavigationBackButton() {
        view.insertSubview(dayNavigationBackButton, belowSubview: topMaskView)
        NSLayoutConstraint.activate([
            dayNavigationBackButton.topAnchor.constraint(equalTo: topMaskView.bottomAnchor, constant: 8),
            dayNavigationBackButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: MenuBarView.logoLeadingInset
            ),
            dayNavigationBackButton.widthAnchor.constraint(equalToConstant: 44),
            dayNavigationBackButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func positionDayNavigationBackButtonInChromeStack() {
        view.insertSubview(dayNavigationBackButton, belowSubview: topMaskView)
    }

    private func updateDayNavigationBackButtonScrollPosition() {
        guard isViewingTomorrow,
              !dayNavigationBackButton.isHidden,
              dayNavigationBackButton.superview != nil,
              calendarButton.superview != nil else {
            dayNavigationBackButton.transform = .identity
            return
        }

        let stickyCenterY = dayNavigationBackButton.center.y
        let calendarCenterY = calendarButton.convert(
            CGPoint(x: calendarButton.bounds.midX, y: calendarButton.bounds.midY),
            to: view
        ).y
        // Stick in the top-left until the scrolling calendar icon reaches the same
        // vertical center, then track that header row upward at the same pace.
        let translationY = min(0, calendarCenterY - stickyCenterY)
        dayNavigationBackButton.transform = CGAffineTransform(translationX: 0, y: translationY)
    }

    private func cardRevealKey(for date: Date) -> String {
        DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date, engineId: DailyFitEngineConfig.effectiveEngineId)
    }

    // MARK: - Midnight / Day Rollover

    private func setupDayRolloverObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppEnteredForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignificantTimeChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
    }

    @objc private func handleAppEnteredForeground() {
        checkForDayRollover()
    }

    @objc private func handleSignificantTimeChange() {
        checkForDayRollover()
    }

    private func checkForDayRollover() {
        let calendar = Calendar.current
        guard !calendar.isDate(Date(), inSameDayAs: todayDate) else { return }

        let newToday = Date()
        let previousTomorrow = calendar.date(byAdding: .day, value: 1, to: todayDate)

        if isViewingTomorrow,
           let prevTomorrow = previousTomorrow,
           calendar.isDate(newToday, inSameDayAs: prevTomorrow) {
            todayPayload = tomorrowPayload
        } else {
            todayPayload = payloadGenerator?(newToday)
        }

        todayDate = newToday
        tomorrowPayload = nil
        displayDate = newToday
        isViewingTomorrow = false
        dailyFitPayload = todayPayload

        if dailyFitPayload != nil {
            updateContentFromPayload()
        }
        checkCardRevealState()
        updateDayNavigationUI()
    }
    
    // MARK: - Header Components Setup
    private func setupHeaderComponents() {
        // Daily Fit title — bold sans caps (design); calendar sits on same row, trailing.
        dailyFitLabel.text = "DAILY FIT"
        dailyFitLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 15, weight: .bold)
        dailyFitLabel.textColor = .black
        dailyFitLabel.textAlignment = .center
        dailyFitLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyFitLabel.alpha = 0.0
        contentView.addSubview(dailyFitLabel)

        contentView.addSubview(calendarButton)
        calendarButton.alpha = 0.0

        // Tarot glyph row omitted in current design — keep view for future use, collapsed.
        tarotSymbolLabel.text = "♦ VII"
        tarotSymbolLabel.isHidden = true
        tarotSymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        tarotSymbolLabel.alpha = 0.0
        contentView.addSubview(tarotSymbolLabel)

        // Tarot card title — large serif caps
        tarotTitleLabel.text = "THE CHARIOT"
        tarotTitleLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.title1,
            weight: .semibold
        )
        tarotTitleLabel.textColor = .black
        tarotTitleLabel.textAlignment = .center
        tarotTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tarotTitleLabel.alpha = 0.0
        contentView.addSubview(tarotTitleLabel)

        applyDailyFitDateLabel(for: Date())
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.alpha = 0.0
        contentView.addSubview(dateLabel)
    }

    /// Short uppercase date (e.g. "FRIDAY, MAY 2") with wide tracking — sans, black.
    private func applyDailyFitDateLabel(for date: Date) {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"
        df.locale = Locale(identifier: "en_GB")
        let raw = df.string(from: date).uppercased()
        let font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.callout, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .kern: 2.25
        ]
        dateLabel.attributedText = NSAttributedString(string: raw, attributes: attrs)
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
        label.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
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
    
    private func createLargeHeaderLabel(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        CosmicFitTheme.styleTitleLabel(label, fontSize: 20, weight: .bold)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 36),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    // MARK: - Outfit Breakdown Section
    private func setupStyleBreakdownSection() {
        styleBreakdownDivider = createLargeHeaderLabel("Outfit Breakdown")
        styleBreakdownDivider?.alpha = 0.0
        if let divider = styleBreakdownDivider {
            contentView.addSubview(divider)
        }
    }
    
    // MARK: - New Pipeline Helpers

    /// Point size for the black / white-stroke diamond on Vibrancy,
    /// Contrast, Metal Tone, and Silhouette tracks. Drives the marker's
    /// rendered width *and* height — the ♦ glyph scales uniformly with
    /// font size, and `styleDiamondScaleIndicator` derives the white
    /// stroke width from this value (-0.14 × size) so the outline grows
    /// in proportion. Single source of truth for every slider's marker.
    private static let sharedScaleDiamondMarkerFontSize: CGFloat = 24

    /// Black diamond with white stroke (matches Daily Fit scale marker designs).
    private func styleDiamondScaleIndicator(_ label: UILabel, fontSize: CGFloat) {
        let font = UIFont.systemFont(ofSize: fontSize)
        let strokeWidth = -(fontSize * 0.14)
        label.attributedText = NSAttributedString(
            string: "♦",
            attributes: [
                .font: font,
                .foregroundColor: UIColor.black,
                .strokeColor: UIColor.white,
                .strokeWidth: strokeWidth
            ]
        )
    }

    private func makeSharedScaleDiamondIndicatorLabel() -> UILabel {
        let label = UILabel()
        styleDiamondScaleIndicator(label, fontSize: Self.sharedScaleDiamondMarkerFontSize)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func buildVibrancyScale() -> (container: UIView, indicator: UILabel, track: UIView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "Vibrancy"
        titleLbl.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(size: 14)
        titleLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        let track = GradientTrackView(colors: [
            UIColor.gray,
            UIColor(red: 0/255, green: 165/255, blue: 195/255, alpha: 1.0)
        ])
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)

        let indicator = makeSharedScaleDiamondIndicatorLabel()
        container.addSubview(indicator)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: container.topAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            track.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 10),
            track.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.heightAnchor.constraint(equalToConstant: 6),

            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor),

            container.bottomAnchor.constraint(equalTo: track.bottomAnchor, constant: 8)
        ])

        return (container, indicator, track)
    }

    private func buildContrastScale() -> (container: UIView, indicator: UILabel, track: UIView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "Contrast"
        titleLbl.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(size: 14)
        titleLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        let track = HalftoneTrackView(frame: .zero)
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)

        let indicator = makeSharedScaleDiamondIndicatorLabel()
        container.addSubview(indicator)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: container.topAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            track.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 10),
            track.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.heightAnchor.constraint(equalToConstant: 6),

            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor),

            container.bottomAnchor.constraint(equalTo: track.bottomAnchor, constant: 8)
        ])

        return (container, indicator, track)
    }

    private func buildMetalToneScale() -> (container: UIView, indicator: UILabel, track: UIView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "Metal Tone"
        titleLbl.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(size: 14)
        titleLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        let track = MetallicGradientTrackView(colors: [
            UIColor(red: 150/255, green: 160/255, blue: 180/255, alpha: 1.0),
            UIColor(red: 210/255, green: 210/255, blue: 210/255, alpha: 1.0),
            UIColor(red: 200/255, green: 175/255, blue: 95/255, alpha: 1.0)
        ])
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)

        let indicator = makeSharedScaleDiamondIndicatorLabel()
        container.addSubview(indicator)

        let coolLbl = UILabel()
        coolLbl.text = "Cool"
        coolLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 12, weight: .regular)
        coolLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        coolLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(coolLbl)

        let mixedLbl = UILabel()
        mixedLbl.text = "Mixed"
        mixedLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 12, weight: .regular)
        mixedLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        mixedLbl.textAlignment = .center
        mixedLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mixedLbl)

        let warmLbl = UILabel()
        warmLbl.text = "Warm"
        warmLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 12, weight: .regular)
        warmLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        warmLbl.textAlignment = .right
        warmLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(warmLbl)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: container.topAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            track.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 10),
            track.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.heightAnchor.constraint(equalToConstant: 6),

            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor),

            coolLbl.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 4),
            coolLbl.leadingAnchor.constraint(equalTo: track.leadingAnchor),

            mixedLbl.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 4),
            mixedLbl.centerXAnchor.constraint(equalTo: track.centerXAnchor),

            warmLbl.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 4),
            warmLbl.trailingAnchor.constraint(equalTo: track.trailingAnchor),

            container.bottomAnchor.constraint(equalTo: coolLbl.bottomAnchor, constant: 4)
        ])

        return (container, indicator, track)
    }

    private func createDiamondScale(leftLabel: String, rightLabel: String, centreLabel: String? = nil) -> (container: UIView, indicator: UILabel, track: UIView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let leftLbl = UILabel()
        leftLbl.text = leftLabel
        leftLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 14, weight: .semibold)
        leftLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        leftLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(leftLbl)

        let rightLbl = UILabel()
        rightLbl.text = rightLabel
        rightLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 14, weight: .semibold)
        rightLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        rightLbl.textAlignment = .right
        rightLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rightLbl)

        let track = UIView()
        track.backgroundColor = UIColor.lightGray
        track.layer.cornerRadius = 2
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)

        let indicator = UILabel()
        styleDiamondScaleIndicator(indicator, fontSize: 14)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(indicator)

        if let centre = centreLabel {
            let centreLbl = UILabel()
            centreLbl.text = centre
            centreLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 12, weight: .regular)
            centreLbl.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.6)
            centreLbl.textAlignment = .center
            centreLbl.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(centreLbl)
            NSLayoutConstraint.activate([
                centreLbl.centerXAnchor.constraint(equalTo: track.centerXAnchor),
                centreLbl.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 4)
            ])
        }

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 40),

            leftLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftLbl.widthAnchor.constraint(equalToConstant: 60),

            rightLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightLbl.widthAnchor.constraint(equalToConstant: 60),

            track.leadingAnchor.constraint(equalTo: leftLbl.trailingAnchor, constant: 12),
            track.trailingAnchor.constraint(equalTo: rightLbl.leadingAnchor, constant: -12),
            track.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            track.heightAnchor.constraint(equalToConstant: 4),

            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor)
        ])

        return (container, indicator, track)
    }

    private func createTitledDiamondScale(
        title: String, leftLabel: String, rightLabel: String,
        storeRefs: @escaping (UILabel, UIView) -> Void
    ) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 14, weight: .semibold)
        titleLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(titleLbl)

        let (scaleContainer, indicator, track) = createDiamondScale(leftLabel: leftLabel, rightLabel: rightLabel)
        scaleContainer.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(scaleContainer)

        storeRefs(indicator, track)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            scaleContainer.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 6),
            scaleContainer.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            scaleContainer.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            scaleContainer.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])

        return wrapper
    }

    private func createSilhouetteSlider(leftLabel: String, rightLabel: String) -> (container: UIView, indicator: UILabel, track: UIView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let track = UIView()
        track.backgroundColor = UIColor.lightGray
        track.layer.cornerRadius = 3
        track.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(track)

        let indicator = makeSharedScaleDiamondIndicatorLabel()
        container.addSubview(indicator)

        let leftLbl = UILabel()
        leftLbl.text = leftLabel
        leftLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 15, weight: .regular)
        leftLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        leftLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(leftLbl)

        let rightLbl = UILabel()
        rightLbl.text = rightLabel
        rightLbl.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 15, weight: .regular)
        rightLbl.textColor = CosmicFitTheme.Colours.cosmicBlue
        rightLbl.textAlignment = .right
        rightLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rightLbl)

        NSLayoutConstraint.activate([
            track.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            track.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            track.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            track.heightAnchor.constraint(equalToConstant: 6),

            indicator.centerYAnchor.constraint(equalTo: track.centerYAnchor),

            leftLbl.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 6),
            leftLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            rightLbl.topAnchor.constraint(equalTo: track.bottomAnchor, constant: 6),
            rightLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            container.bottomAnchor.constraint(equalTo: leftLbl.bottomAnchor, constant: 2),
        ])

        return (container, indicator, track)
    }

    private func updateDiamondScale(constraint: inout NSLayoutConstraint?, indicator: UILabel?, track: UIView?, value: Double) {
        guard let indicator = indicator, let track = track else { return }
        constraint?.isActive = false
        let trackWidth = track.bounds.width
        guard trackWidth > 0 else { return }
        let offset = CGFloat(value) * trackWidth
        let newConstraint = indicator.centerXAnchor.constraint(equalTo: track.leadingAnchor, constant: offset)
        newConstraint.isActive = true
        constraint = newConstraint
    }

    /// Pick the most accent / vibrant colour from the daily palette and apply it
    /// to the right end of the vibrancy gradient track.
    private func updateVibrancyTrackAccentColor(from palette: DailyPaletteSelection) {
        let accentColor: UIColor = {
            if let accent = palette.colours.first(where: { $0.role == "accent" }) {
                return UIColor(hex: accent.hexValue) ?? UIColor(red: 0, green: 165/255, blue: 195/255, alpha: 1)
            }
            return palette.colours
                .compactMap { pick -> (UIColor, CGFloat)? in
                    guard let color = UIColor(hex: pick.hexValue) else { return nil }
                    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                    return (color, s * b)
                }
                .max(by: { $0.1 < $1.1 })?.0
                ?? UIColor(red: 0, green: 165/255, blue: 195/255, alpha: 1)
        }()
        (vibrancyTrack as? GradientTrackView)?.updateColors([UIColor.gray, accentColor])
    }

    /// Snap a 0–1 value to Cool (0.0) / Mixed (0.5) / Warm (1.0) using equal tertiles.
    /// Boundaries: [0, 1/3) = Cool, [1/3, 2/3] = Mixed, (2/3, 1] = Warm.
    /// Used for both personal displayPosition and legacy absolute metal tone.
    static func snapMetalToThreePositions(_ value: Double) -> Double {
        if value < 1.0 / 3.0 { return 0.0 }
        if value > 2.0 / 3.0 { return 1.0 }
        return 0.5
    }

    private func refreshDiamondScalePositions() {
        guard let payload = dailyFitPayload else { return }

        if let sp = payload.scalePresentation {
            updateDiamondScale(constraint: &vibrancyIndicatorConstraint, indicator: vibrancyIndicator, track: vibrancyTrack, value: sp.vibrancy.displayPosition)
            updateDiamondScale(constraint: &contrastIndicatorConstraint, indicator: contrastIndicator, track: contrastTrack, value: sp.contrast.displayPosition)
            let snappedMetal = Self.snapMetalToThreePositions(sp.metalTone.displayPosition)
            updateDiamondScale(constraint: &metalToneIndicatorConstraint, indicator: metalToneIndicator, track: metalToneTrack, value: snappedMetal)
        } else {
            // Legacy fallback: absolute positioning, same tertile snap
            updateDiamondScale(constraint: &vibrancyIndicatorConstraint, indicator: vibrancyIndicator, track: vibrancyTrack, value: payload.vibrancy)
            updateDiamondScale(constraint: &contrastIndicatorConstraint, indicator: contrastIndicator, track: contrastTrack, value: payload.contrast)
            let snappedMetal = Self.snapMetalToThreePositions(payload.metalTone)
            updateDiamondScale(constraint: &metalToneIndicatorConstraint, indicator: metalToneIndicator, track: metalToneTrack, value: snappedMetal)
        }

        updateSilhouetteSliders(with: payload.silhouetteProfile)
    }

    private func updateSilhouetteSliders(with profile: SilhouetteProfile) {
        let values = [profile.masculineFeminine, profile.angularRounded, profile.structuredDraped]
        for (index, value) in values.enumerated() where index < silhouetteSliderData.count {
            let entry = silhouetteSliderData[index]
            let track = entry.track
            let indicator = entry.indicator
            guard track.bounds.width > 0 else { continue }
            entry.constraint?.isActive = false
            let offset = CGFloat(value) * track.bounds.width
            let newConstraint = indicator.centerXAnchor.constraint(equalTo: track.leadingAnchor, constant: offset)
            newConstraint.isActive = true
            silhouetteSliderData[index] = (indicator: indicator, track: track, constraint: newConstraint)
        }
    }

    // MARK: - New Pipeline Update

    private func updateContentFromPayload() {
        guard let payload = dailyFitPayload else { return }

        loadTarotCardImage(for: payload.tarotCard)
        tarotTitleLabel.text = payload.tarotCard.displayName.uppercased()

        applyDailyFitDateLabel(for: payload.generatedAt)

        styleEditLabel.text = payload.styleEditVariant.description

        if let ritual = payload.styleEditVariant.dailyRitual {
            dailyRitualLabel.text = ritual
            dailyRitualHeaderDivider?.isHidden = false
            dailyRitualLabel.isHidden = false
            updateDailyRitualLayoutConstraints(hasRitual: true)
        } else {
            dailyRitualHeaderDivider?.isHidden = true
            dailyRitualLabel.isHidden = true
            updateDailyRitualLayoutConstraints(hasRitual: false)
        }

        let allHexes = payload.dailyPalette.allPaletteHexes
        colourPaletteContainer.configure(dailyPicks: payload.dailyPalette.colours, allPaletteHexes: allHexes)

        essenceTriangleView?.configure(with: payload.essenceProfile, presentation: nil)

        if let reflection = payload.styleEditVariant.wardrobeReflection {
            wardrobeReflectionLabel.text = reflection
            wardrobeReflectionHeaderDivider?.isHidden = false
            wardrobeReflectionLabel.isHidden = false
        } else {
            wardrobeReflectionHeaderDivider?.isHidden = true
            wardrobeReflectionLabel.isHidden = true
        }

        updateVibrancyTrackAccentColor(from: payload.dailyPalette)
        refreshDiamondScalePositions()
        updateTarotCardOuterGlow()
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
        
        // Brand div-star asset — same image used by the Essence triangle
        // vertex markers and every other divider/header sparkle across
        // the app (Menu, Style Guide, FAQ, Dos & Don'ts). Keeps the
        // divider iconography consistent rather than mixing a Unicode
        // ornament here with the branded asset elsewhere.
        let starImageView = UIImageView()
        starImageView.image = UIImage(named: "star_icon_placeholder")?.withRenderingMode(.alwaysTemplate)
        starImageView.tintColor = CosmicFitTheme.Colours.cosmicBlue
        starImageView.contentMode = .scaleAspectFit
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(leftDivider)
        container.addSubview(rightDivider)
        container.addSubview(starImageView)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 30),
            
            leftDivider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),
            leftDivider.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -12),
            
            rightDivider.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 12),
            rightDivider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),
            
            starImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            starImageView.heightAnchor.constraint(equalToConstant: 20),
            starImageView.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }
    
    // MARK: - Initial Content Alpha
    private func setInitialContentAlpha() {
        let allViews: [UIView?] = [
            dailyFitLabel, calendarButton, tarotSymbolLabel, tarotTitleLabel, dateLabel,
            topDivider,
            styleEditHeaderLabel, styleEditLabel,
            postTarotParagraphDivider,
            styleBreakdownDivider, colourHeaderDivider, colourPaletteContainer,
            toneSliderContainer,
            vibeHeaderDivider, silhouetteHeaderDivider, silhouetteContainer,
            finalStarDivider,
            dailyRitualHeaderDivider, dailyRitualLabel,
            postDailyRitualDivider,
            vibrancyScaleContainer, contrastScaleContainer,
            essenceTriangleView,
            wardrobeReflectionHeaderDivider, wardrobeReflectionLabel,
            tomorrowTeaseLabel, tomorrowButton
        ]

        for view in allViews.compactMap({ $0 }) {
            view.alpha = 0.0
        }
    }
    
    // MARK: - UI Setup Constraints (setupConstraints method)
    private func setupConstraints() {
        setupNewPipelineConstraints()
    }

    private func setupNewPipelineConstraints() {
        let horizontalMargin: CGFloat = 32
        let styleParagraphHorizontalInset = horizontalMargin + 10
        // Style Guide detail pages use ~40pt around major dividers; loosen Daily Fit from the prior 24pt stack.
        let sectionSpacing: CGFloat = 32
        let paragraphToDividerGap: CGFloat = 40
        let dividerToDailyRitualTitleGap: CGFloat = 32
        let sectionTitleToBodyGap: CGFloat = 18
        let subsectionGap: CGFloat = 18
        let scaleRowSpacing: CGFloat = 24
        let outfitGapWhenNoDailyRitual: CGFloat = 36
        let ritualTextToBottomDividerGap: CGFloat = 44
        let dividerToOutfitBreakdownGap: CGFloat = 32
        /// Tighter stack: Style Palette ornamental divider sits just under the Outfit Breakdown title.
        let outfitBreakdownToStylePaletteGap: CGFloat = 14
        /// Equal space above and below wardrobe reflection so it sits between the two dividers.
        /// Space from the rule above wardrobe copy down to the label (slightly more than below for breathing room).
        let wardrobeReflectionGapAbove: CGFloat = 46
        /// Space from wardrobe copy down to the star divider.
        let wardrobeReflectionGapBelow: CGFloat = 37.5
        /// Extra air above Essence after Vibrancy / Contrast / Metal Tone; base matches `sectionSpacing`, +10pt scaled with Dynamic Type.
        let metalToneToEssenceGap = sectionSpacing + UIFontMetrics(forTextStyle: .body).scaledValue(for: 10)

        let screenHeight = view.bounds.height
        let tabBarHeight: CGFloat = 83
        let contentStartFromBottom = screenHeight - tabBarHeight - 75

        var constraints: [NSLayoutConstraint] = []

        // Header — "DAILY FIT" uses full width for true centering; calendar sits on the trailing edge (overlaps label bounds).
        let headerRowToTarotTitle: CGFloat = 28
        let tarotTitleToDate: CGFloat = 16
        constraints.append(contentsOf: [
            dailyFitLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentStartFromBottom),
            dailyFitLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            dailyFitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

            calendarButton.centerYAnchor.constraint(equalTo: dailyFitLabel.centerYAnchor),
            calendarButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
            calendarButton.widthAnchor.constraint(equalToConstant: 32),
            calendarButton.heightAnchor.constraint(equalToConstant: 32),

            tarotTitleLabel.topAnchor.constraint(equalTo: dailyFitLabel.bottomAnchor, constant: headerRowToTarotTitle),
            tarotTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            tarotTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

            tarotSymbolLabel.bottomAnchor.constraint(equalTo: tarotTitleLabel.topAnchor),
            tarotSymbolLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            tarotSymbolLabel.widthAnchor.constraint(equalToConstant: 1),
            tarotSymbolLabel.heightAnchor.constraint(equalToConstant: 0),

            dateLabel.topAnchor.constraint(equalTo: tarotTitleLabel.bottomAnchor, constant: tarotTitleToDate),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])

        // Top divider + style paragraph (tarot / daily copy block)
        if let topDivider = topDivider {
            constraints.append(contentsOf: [
                topDivider.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: sectionSpacing),
                topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                topDivider.heightAnchor.constraint(equalToConstant: 1)
            ])

            styleEditAfterTopDividerConstraint = styleEditLabel.topAnchor.constraint(
                equalTo: topDivider.bottomAnchor, constant: sectionSpacing
            )
            constraints.append(contentsOf: [
                styleEditAfterTopDividerConstraint!,
                styleEditLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: styleParagraphHorizontalInset),
                styleEditLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -styleParagraphHorizontalInset)
            ])
        }

        // Full-span divider after main paragraph + Daily Ritual block (vertical constraints toggled when payload has no ritual)
        if let postDiv = postTarotParagraphDivider,
           let ritualHeader = dailyRitualHeaderDivider {
            postTarotParagraphDividerConstraints = [
                postDiv.topAnchor.constraint(equalTo: styleEditLabel.bottomAnchor, constant: paragraphToDividerGap),
                postDiv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                postDiv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                postDiv.heightAnchor.constraint(equalToConstant: 1)
            ]
            dailyRitualBlockConstraints = [
                ritualHeader.topAnchor.constraint(equalTo: postDiv.bottomAnchor, constant: dividerToDailyRitualTitleGap),
                ritualHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                ritualHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                dailyRitualLabel.topAnchor.constraint(equalTo: ritualHeader.bottomAnchor, constant: sectionTitleToBodyGap),
                dailyRitualLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                dailyRitualLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ]
        }

        if let bottomRitualDiv = postDailyRitualDivider {
            postDailyRitualDividerConstraints = [
                bottomRitualDiv.topAnchor.constraint(equalTo: dailyRitualLabel.bottomAnchor, constant: ritualTextToBottomDividerGap),
                bottomRitualDiv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                bottomRitualDiv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                bottomRitualDiv.heightAnchor.constraint(equalToConstant: 1)
            ]
        }

        // Outfit Breakdown header — top pin depends on optional Daily Ritual (see `updateDailyRitualLayoutConstraints`)
        var lastAnchor: NSLayoutYAxisAnchor = styleEditLabel.bottomAnchor
        if let styleBreakdownDivider = styleBreakdownDivider {
            if let bottomRitualDiv = postDailyRitualDivider {
                styleBreakdownAfterDailyRitualConstraint = styleBreakdownDivider.topAnchor.constraint(
                    equalTo: bottomRitualDiv.bottomAnchor,
                    constant: dividerToOutfitBreakdownGap
                )
            }
            styleBreakdownAfterStyleParagraphConstraint = styleBreakdownDivider.topAnchor.constraint(
                equalTo: styleEditLabel.bottomAnchor,
                constant: outfitGapWhenNoDailyRitual
            )
            constraints.append(contentsOf: [
                styleBreakdownDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                styleBreakdownDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
            lastAnchor = styleBreakdownDivider.bottomAnchor
        }

        // Colour / Style Palette
        if let colourHeaderDivider = colourHeaderDivider {
            constraints.append(contentsOf: [
                colourHeaderDivider.topAnchor.constraint(equalTo: lastAnchor, constant: outfitBreakdownToStylePaletteGap),
                colourHeaderDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                colourHeaderDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

                colourPaletteContainer.topAnchor.constraint(equalTo: colourHeaderDivider.bottomAnchor, constant: subsectionGap),
                colourPaletteContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                colourPaletteContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
            lastAnchor = colourPaletteContainer.bottomAnchor
        }

        // Vibrancy + Contrast scales
        constraints.append(contentsOf: [
            vibrancyScaleContainer.topAnchor.constraint(equalTo: lastAnchor, constant: sectionSpacing),
            vibrancyScaleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            vibrancyScaleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

            contrastScaleContainer.topAnchor.constraint(equalTo: vibrancyScaleContainer.bottomAnchor, constant: scaleRowSpacing),
            contrastScaleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            contrastScaleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])

        // Tone
        constraints.append(contentsOf: [
            toneSliderContainer.topAnchor.constraint(equalTo: contrastScaleContainer.bottomAnchor, constant: scaleRowSpacing),
            toneSliderContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
            toneSliderContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
        ])

        // Essence triangle
        if let vibeHeaderDivider = vibeHeaderDivider, let triangle = essenceTriangleView {
            vibeHeaderAfterToneConstraint = vibeHeaderDivider.topAnchor.constraint(
                equalTo: toneSliderContainer.bottomAnchor, constant: metalToneToEssenceGap
            )
            constraints.append(contentsOf: [
                vibeHeaderAfterToneConstraint!,
                vibeHeaderDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                vibeHeaderDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

                triangle.topAnchor.constraint(equalTo: vibeHeaderDivider.bottomAnchor, constant: subsectionGap),
                triangle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                triangle.widthAnchor.constraint(equalToConstant: 200),
                triangle.heightAnchor.constraint(equalToConstant: 200)
            ])
        }

        // Silhouette
        if let silhouetteHeaderDivider = silhouetteHeaderDivider, let triangle = essenceTriangleView {
            silhouetteHeaderAfterTriangleConstraint = silhouetteHeaderDivider.topAnchor.constraint(
                equalTo: triangle.bottomAnchor, constant: sectionSpacing
            )
            constraints.append(contentsOf: [
                silhouetteHeaderAfterTriangleConstraint!,
                silhouetteHeaderDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                silhouetteHeaderDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

                silhouetteContainer.topAnchor.constraint(equalTo: silhouetteHeaderDivider.bottomAnchor, constant: subsectionGap),
                silhouetteContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                silhouetteContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        }

        // Wardrobe Reflection
        if let reflectionHeader = wardrobeReflectionHeaderDivider {
            constraints.append(contentsOf: [
                reflectionHeader.topAnchor.constraint(equalTo: silhouetteContainer.bottomAnchor, constant: sectionSpacing),
                reflectionHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                reflectionHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),
                reflectionHeader.heightAnchor.constraint(equalToConstant: 1),

                wardrobeReflectionLabel.topAnchor.constraint(equalTo: reflectionHeader.bottomAnchor, constant: wardrobeReflectionGapAbove),
                wardrobeReflectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                wardrobeReflectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        } else {
            constraints.append(contentsOf: [
                wardrobeReflectionLabel.topAnchor.constraint(equalTo: silhouetteContainer.bottomAnchor, constant: sectionSpacing),
                wardrobeReflectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                wardrobeReflectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin)
            ])
        }

        // Star divider + Tomorrow section
        if let finalStarDivider = finalStarDivider {
            constraints.append(contentsOf: [
                finalStarDivider.topAnchor.constraint(equalTo: wardrobeReflectionLabel.bottomAnchor, constant: wardrobeReflectionGapBelow),
                finalStarDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalMargin),
                finalStarDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalMargin),

                tomorrowTeaseLabel.topAnchor.constraint(equalTo: finalStarDivider.bottomAnchor, constant: sectionSpacing),
                tomorrowTeaseLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                tomorrowTeaseLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.52),

                tomorrowButton.topAnchor.constraint(equalTo: tomorrowTeaseLabel.bottomAnchor, constant: 20),
                tomorrowButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                tomorrowButton.leadingAnchor.constraint(
                    greaterThanOrEqualTo: contentView.leadingAnchor,
                    constant: horizontalMargin
                ),
                tomorrowButton.trailingAnchor.constraint(
                    lessThanOrEqualTo: contentView.trailingAnchor,
                    constant: -horizontalMargin
                ),
                tomorrowButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),
                tomorrowButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.contentBottomPaddingBelowTomorrow)
            ])
        }

        NSLayoutConstraint.activate(constraints)

        let hasRitual = dailyFitPayload?.styleEditVariant.dailyRitual != nil
        updateDailyRitualLayoutConstraints(hasRitual: hasRitual)
    }

    private func updateDailyRitualLayoutConstraints(hasRitual: Bool) {
        postTarotParagraphDivider?.isHidden = !hasRitual
        postTarotParagraphDividerConstraints.forEach { $0.isActive = hasRitual }
        dailyRitualBlockConstraints.forEach { $0.isActive = hasRitual }
        postDailyRitualDivider?.isHidden = !hasRitual
        postDailyRitualDividerConstraints.forEach { $0.isActive = hasRitual }
        styleBreakdownAfterDailyRitualConstraint?.isActive = hasRitual
        styleBreakdownAfterStyleParagraphConstraint?.isActive = !hasRitual
    }

    private func loadTarotCardImage(for tarotCard: TarotCard?) {
        guard let tarotCard = tarotCard else {
            print("⚠️ No tarot card provided for image loading")
            cardFrontSheenView.cardImage = nil
            return
        }
        
        print("🔍 Attempting to load image: \(tarotCard.imagePath)")
        
        let imageName = tarotCard.imagePath.replacingOccurrences(of: "Cards/", with: "")
        
        if let image = UIImage(named: imageName) {
            // CRITICAL: assign the sheen mask in the same synchronous beat
            // as the imageView's image, so the card art and the iridescent
            // sheen become visible together on the very next paint. Any
            // gap here would let the image flash bare for a frame and
            // destroy the illusion that the sheen is part of the card.
            tarotCardImageView.image = image
            cardFrontSheenView.cardImage = image
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
        blurFilter?.setValue(28.0, forKey: kCIInputRadiusKey) // Heavy blur so the sharp foreground card reads clearly
        
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
        // Colour-coded fallback based on card type using theme colours
        let colour: UIColor
        switch card.arcana {
        case .major:
            colour = CosmicFitTheme.Colours.cosmicLilac
        case .minor:
            switch card.suit {
            case .cups:
                colour = .systemBlue
            case .wands:
                colour = CosmicFitTheme.Colours.cosmicLilac
            case .swords:
                colour = CosmicFitTheme.Colours.cosmicBlue
            case .pentacles:
                colour = .systemGreen
            case .none:
                colour = CosmicFitTheme.Colours.cosmicLilac
            }
        }
        
        tarotCardImageView.backgroundColor = colour
        tarotCardImageView.image = nil
        // No real card art = no sheen. The motion driver auto-pauses
        // when no `MotionSheenView` has a non-nil `cardImage` and is in
        // a window.
        cardFrontSheenView.cardImage = nil
        
        // Create elegant text overlay
        createCardNameOverlay(for: card)
    }
    
    private func createCardNameOverlay(for card: TarotCard) {
        // Remove any existing overlay labels — but preserve the sheen
        // overlay so the holographic effect survives the fallback path
        // (re-entering this code on subsequent loads must not orphan the
        // sheen view).
        tarotCardImageView.subviews
            .filter { !($0 is MotionSheenView) }
            .forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        label.text = card.displayName
        
        // Apply theme to overlay label
        CosmicFitTheme.styleTitleLabel(label, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        label.textColor = .white // Override for visibility on coloured background
        
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
        let labels = [keywordsLabel, styleEditLabel, textilesLabel, coloursLabel,
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
        tapToRevealLabel.isUserInteractionEnabled = false
        
        // Freeze the payload to disk FIRST — the reveal flag is only set after
        // a confirmed write so a cold-launch can never see "revealed" without
        // the matching frozen JSON on disk.
        if let payload = dailyFitPayload, let pk = persistenceProfileKey {
            let saved = DailyFitFrozenPayloadStorage.shared.save(
                payload: payload, date: displayDate, profileKey: pk
            )
            if saved {
                UserDefaults.standard.set(true, forKey: dailyCardRevealKey)
            } else {
                print("⚠️ Frozen payload write failed — reveal flag NOT set (will re-freeze on next reveal)")
            }
        }

        isCardRevealed = true

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
        
        updateDayNavigationUI()
        
        UIView.animate(withDuration: contentFadeDuration) {
            self.backgroundBlurImageView.alpha = 1.0
            self.revealedBackgroundDimmingView.alpha = 1.0
        }
        
        UIView.animate(withDuration: contentFadeDuration * 0.6, delay: contentFadeDuration * 0.2) {
            self.scrollIndicatorView.alpha = 1.0
            self.scrollIndicatorView.isHidden = false
        }
        
        let allContentViews: [UIView?] = [
            dailyFitLabel, calendarButton, tarotSymbolLabel, tarotTitleLabel, dateLabel,
            topDivider, styleEditLabel,
            postTarotParagraphDivider,
            dailyRitualHeaderDivider, dailyRitualLabel,
            postDailyRitualDivider,
            styleBreakdownDivider, colourHeaderDivider, colourPaletteContainer,
            vibrancyScaleContainer, contrastScaleContainer,
            toneSliderContainer,
            vibeHeaderDivider, essenceTriangleView,
            silhouetteHeaderDivider, silhouetteContainer,
            wardrobeReflectionHeaderDivider, wardrobeReflectionLabel,
            finalStarDivider,
            tomorrowTeaseLabel, tomorrowButton
        ]

        for (index, view) in allContentViews.compactMap({ $0 }).enumerated() {
            let delay = contentFadeDuration * 0.3 + (Double(index) * 0.05)
            UIView.animate(withDuration: contentFadeDuration * 0.7, delay: delay) {
                view.alpha = 1.0
            }
        }
        
        scrollView.isScrollEnabled = true
        setupContentSectionBackgrounds(animated: true)
        currentCardState = .revealed
        ensureContainerVisibility()
        view.layoutIfNeeded()
        updateTarotCardOuterGlow()
    }

    // MARK: - Content Section Setup
    
    private func setupContentSectionBackgrounds(animated: Bool = true) {
        contentBackgroundView?.removeFromSuperview()
        
        // Remove any existing backgrounds from labels
        let allLabels: [UILabel?] = [
            dailyFitLabel, tarotSymbolLabel, tarotTitleLabel, dateLabel,
            styleEditLabel
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
        
        // Apply theme content background, then large rounded top corners only (design sheet).
        CosmicFitTheme.styleContentBackground(backgroundView)
        backgroundView.layer.cornerRadius = 22
        backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        backgroundView.clipsToBounds = true
        // `tarotCardImageView` is a descendant of `tarotCardContainerView`,
        // not a direct sibling of `contentView` — passing it as the
        // sibling reference is "undefined behaviour" per UIKit docs.
        // Use the real sibling (`tarotCardContainerView`) so the panel
        // is reliably inserted above the card layer in the subview
        // array on every call, which the reveal slide-up depends on.
        contentView.insertSubview(backgroundView, aboveSubview: tarotCardContainerView)
        
        self.contentBackgroundView = backgroundView
        
        /// Inset from top of `dailyFitLabel` when pinning the panel top (shows blurred card strip above sheet).
        let contentPanelTopInset: CGFloat = 44
        
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
            backgroundView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: view.bounds.height
            )
        ])
        
        view.layoutIfNeeded()

        // `dailyFitLabel.frame.origin.y` is in `contentView`'s local coord
        // space, derived from `contentStartFromBottom = screenHeight -
        // tabBarHeight - 75` — a constant that was hand-tuned back when
        // `contentViewTopConstraint` was frozen at its `viewDidLoad` value
        // (i.e. `view.safeAreaInsets.top == 0`, so `contentView.top` sat at
        // view-coord 83 instead of the correct ~130). Now that
        // `updateLayoutDependentConstants()` refreshes `contentViewTopConstraint`
        // with the real safe-area inset, the same `finalYPosition` lands the
        // panel ~47 pt lower in view coords — exactly far enough to push its
        // rounded top behind the tab bar, which is the regression visible in
        // the user's "incorrect" screenshot.
        //
        // Subtracting `view.safeAreaInsets.top` here cancels that shift and
        // restores the original visual: the panel slides up to peek ~36 pt
        // above the tab bar as a "there's more below — scroll" affordance,
        // without re-introducing the stale-constraint bug fixed earlier.
        let finalYPosition = dailyFitLabel.frame.origin.y
            - contentPanelTopInset
            - view.safeAreaInsets.top

        let applyFinalLayout = {
            // Push the card container — not the inner image view —
            // to the back of `contentView`'s subview array so the
            // content panel composites in front when scrolled. The
            // previous version targeted `tarotCardImageView`, which
            // is a descendant rather than a direct sibling and so
            // reduced to a no-op. Z-ordering against the parallax's
            // 3D-rotated layer is enforced by the container's
            // negative `zPosition`; this call keeps the subview
            // array in the same order as the rendering, which makes
            // `bringSubviewToFront` semantics for the unrevealed
            // state predictable.
            self.contentView.sendSubviewToBack(self.tarotCardContainerView)
            for label in allLabels.compactMap({ $0 }) {
                self.contentView.bringSubviewToFront(label)
            }
            let allContentViews: [UIView?] = [
                self.dailyFitLabel, self.calendarButton, self.tarotSymbolLabel, self.tarotTitleLabel, self.dateLabel,
                self.topDivider, self.styleEditLabel,
                self.postTarotParagraphDivider,
                self.dailyRitualHeaderDivider, self.dailyRitualLabel,
                self.postDailyRitualDivider,
                self.styleBreakdownDivider, self.colourHeaderDivider, self.colourPaletteContainer,
                self.vibrancyScaleContainer, self.contrastScaleContainer,
                self.toneSliderContainer,
                self.vibeHeaderDivider, self.essenceTriangleView,
                self.silhouetteHeaderDivider, self.silhouetteContainer,
                self.wardrobeReflectionHeaderDivider, self.wardrobeReflectionLabel,
                self.finalStarDivider,
                self.tomorrowTeaseLabel, self.tomorrowButton
            ]
            for v in allContentViews.compactMap({ $0 }) {
                self.contentView.bringSubviewToFront(v)
            }
            self.calendarButton.alpha = 1.0
            self.contentView.bringSubviewToFront(self.calendarButton)
        }
        
        if animated {
            UIView.animate(
                withDuration: 0.5,
                delay: 0.2,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0,
                options: [.curveEaseOut],
                animations: {
                    backgroundView.alpha = 1.0
                    self.contentBackgroundTopConstraint?.constant = finalYPosition
                    self.view.layoutIfNeeded()
                },
                completion: { _ in applyFinalLayout() }
            )
        } else {
            backgroundView.alpha = 1.0
            contentBackgroundTopConstraint?.constant = finalYPosition
            view.layoutIfNeeded()
            applyFinalLayout()
        }
    }
    
    @objc private func calendarButtonTapped() {
        presentStyleCalendarUnlockScreen()
    }
}

// MARK: - UIScrollViewDelegate
extension DailyFitViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isCardRevealed else { return }
        
        let yOffset = scrollView.contentOffset.y
        updateDayNavigationBackButtonScrollPosition()
        
        let cardTranslation = yOffset * 0.5

        // Route the scroll-driven translation through the parallax
        // binding so it can be composed with the motion-driven
        // rotation into a single `layer.transform` write per frame.
        // Writing to `tarotCardContainerView.transform` directly here
        // would clobber the parallax rotation on alternating frames
        // (scroll fires every display sync, motion fires every 60 Hz
        // motion update) and read as a visible jitter during scroll.
        let translation3D = CATransform3DMakeTranslation(0, cardTranslation, 0)
        if let parallax = cardParallax {
            parallax.hostBaseTransform = translation3D
        } else {
            tarotCardContainerView.layer.transform = translation3D
        }

        // Halo: track the card's translation so the glow stays
        // anchored behind the card (no independent Y drift), then —
        // only on top-rubber-band — scale outward and fade. The
        // expansion reads as the halo "dissipating" while the card
        // is pulled toward the camera; opposite-direction scaling
        // because the card visually compresses forward through
        // parallax while the halo spreads radially outward. Cap on
        // `normalizedPull` so the effect saturates rather than
        // running away on a long pull, and uniform `scaleX = scaleY`
        // so the halo never squashes anisotropically.
        let overscrollPull = max(0, -yOffset)
        let normalizedPull = min(1.0, overscrollPull / Self.tarotCardGlowOverscrollSaturation)
        let glowScale = 1 + normalizedPull * Self.tarotCardGlowOverscrollMaxScale
        let glowAlpha = 1 - normalizedPull * Self.tarotCardGlowOverscrollFadeDepth
        // Matrix order is `scale · translate`: scale is applied to
        // the local point first (anchor 0.5,0.5 ⇒ centre maps to
        // itself), then translate offsets the whole result by
        // `cardTranslation`. The chain `translation.scaledBy(...)`
        // produces exactly this product, so the halo's centre lands
        // at `cardTranslation` regardless of `glowScale` — i.e. the
        // halo never drifts past the card just because it grew.
        let glowTransform = CGAffineTransform(translationX: 0, y: cardTranslation)
            .scaledBy(x: glowScale, y: glowScale)
        tarotCardGlowView.transform = glowTransform
        tarotCardGlowView.alpha = glowAlpha

        // Scroll indicator fade
        let arrowOpacity = max(0, 1.0 - (yOffset / 30))
        scrollIndicatorView.alpha = arrowOpacity
        
        if yOffset > 30 && !scrollIndicatorView.isHidden {
            scrollIndicatorView.isHidden = true
        } else if yOffset <= 30 && scrollIndicatorView.isHidden {
            scrollIndicatorView.isHidden = false
        }
        
        // Background blur. The y-offset driving the parallax is
        // clamped to the max valid scroll position so bottom
        // rubber-band over-scroll cannot keep pulling the blurred
        // card up — that previously exposed the solid cosmic-blue
        // fill under its bottom edge as an ugly seam between the blur
        // and the tab bar. The light content panel above still
        // travels with the raw scroll offset and retains its
        // bounce/snap behaviour.
        //
        // The blur's bottom over-extension is sized in
        // `updateBackgroundBlurBottomExtensionIfNeeded` to absorb
        // exactly this maximum shift, so at the natural scroll limit
        // the blur is still flush with (and slightly past) the tab
        // bar's top. The translation factor matches
        // `backgroundBlurParallaxFactor` (0.5 * 0.2 = 0.1); they are
        // multiplied apart here for readability but must agree.
        let maxValidOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
        let clampedOffsetForBlur = min(yOffset, maxValidOffset)
        let blurCardTranslation = clampedOffsetForBlur * 0.5
        let blurParallax = CGAffineTransform(translationX: 0, y: -blurCardTranslation * 0.2)
        backgroundBlurImageView.transform = blurParallax
        revealedBackgroundDimmingView.transform = blurParallax
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

// MARK: - Custom Track Views

private class GradientTrackView: UIView {
    fileprivate let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = 3
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func updateColors(_ colors: [UIColor]) {
        gradientLayer.colors = colors.map { $0.cgColor }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

/// Metal-tone track with a thin diagonal specular gleam (not a horizontal band) for a metallic read.
private class MetallicGradientTrackView: GradientTrackView {
    private let gleamLayer = CAGradientLayer()

    override init(colors: [UIColor]) {
        super.init(colors: colors)
        // Narrow highlight along the diagonal from bottom-left → top-right.
        gleamLayer.colors = [
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.52).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        gleamLayer.locations = [0.0, 0.40, 0.5, 0.60, 1.0] as [NSNumber]
        gleamLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gleamLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        layer.addSublayer(gleamLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gleamLayer.frame = bounds
    }
}

private class HalftoneTrackView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentMode = .redraw
        isOpaque = false
        clipsToBounds = true
        layer.cornerRadius = 3
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), rect.width > 0, rect.height > 0 else { return }

        UIColor(white: 0.87, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 3).fill()

        let dotColor = CosmicFitTheme.Colours.cosmicBlue
        let spacing: CGFloat = 1.75
        let maxRadius = spacing * 0.42
        let cols = max(1, Int(rect.width / spacing))
        let rows = max(1, Int(rect.height / spacing))

        for col in 0...cols {
            let linearProgress = CGFloat(col) / CGFloat(max(1, cols))
            let progress = pow(linearProgress, 0.4)
            let radius = maxRadius * (0.08 + 0.92 * progress)
            let alpha: CGFloat = min(1.0, 0.12 + 1.3 * progress)
            ctx.setFillColor(dotColor.withAlphaComponent(alpha).cgColor)

            for row in 0...rows {
                let x = CGFloat(col) * spacing + spacing * 0.5
                let y = CGFloat(row) * spacing + spacing * 0.5
                guard x <= rect.width + maxRadius, y <= rect.height + maxRadius else { continue }
                ctx.fillEllipse(in: CGRect(
                    x: x - radius, y: y - radius,
                    width: radius * 2, height: radius * 2
                ))
            }
        }
    }
}
