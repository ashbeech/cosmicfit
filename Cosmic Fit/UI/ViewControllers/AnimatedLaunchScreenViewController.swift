//
//  AnimatedLaunchScreenViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import UIKit

class AnimatedLaunchScreenViewController: UIViewController {
    
    // MARK: - UI Elements
    private let backgroundContainer = UIView()
    
    // Number of scrolling rune columns across the screen
    private let columnCount = 5
    
    // The rune strip image and its natural aspect ratio (height / width)
    private let runeImage = UIImage(named: "logo-animation-background")
    private var runeAspectRatio: CGFloat {
        guard let size = runeImage?.size, size.width > 0 else { return 1.0 }
        return size.height / size.width
    }
    
    // One clip view per column; each holds a "track" that is tiled vertically and scrolls
    private var columnClips: [UIView] = []
    private var columnTracks: [UIView] = []

    // Edge fade overlays. Each band is split into thin vertical strips whose
    // opacity oscillation is phase-shifted by x, so the pulse flows sideways
    // as a continuous waveform instead of the whole band breathing in unison.
    private let topFadeView = UIView()
    private let bottomFadeView = UIView()
    private var topStripLayers: [CAGradientLayer] = []
    private var bottomStripLayers: [CAGradientLayer] = []
    private var fadeBreathingActive = false
    private static let breathHalfPeriod: CFTimeInterval = 1.05 * (4.0 / 3.0)
    /// Launch fades sit lighter than Daily Fit — half the base overlay opacity.
    private static let breathOpacityMid: Float = 0.5
    private static let breathOpacityDelta: Float = 0.22
    private static let breathKey = "edgeFadeBreath"
    private static let waveStripWidth: CGFloat = 24.0
    private static let waveCrests: Double = 0.5
    
    private let logoContainer = UIView()
    private let logoMark = CosmicFitLogoMarkView()
    private var logoCenterYConstraint: NSLayoutConstraint?

    // Aspect ratio (width / height) of the "Cosmic Fit" vertical lockup artwork.
    private let logoAspectRatio: CGFloat = 681.09 / 413.05
    
    // MARK: - Properties
    private var mainViewController: UIViewController?
    private var minimumAnimationElapsed = false
    private var hasTransitioned = false

    /// UserDefaults key recording that the full anticipation intro has played once.
    private static let hasShownIntroKey = "hasShownAnimatedLaunchIntro"

    /// True only the very first time the launch screen is shown after install.
    /// Subsequent launches get a quick fade so daily users aren't slowed down.
    private let isFirstLaunch: Bool =
        !UserDefaults.standard.bool(forKey: AnimatedLaunchScreenViewController.hasShownIntroKey)

    /// How long the launch screen stays up before transitioning to the app.
    /// First launch holds a little after the slow reveal for anticipation; later
    /// launches transition the instant the fast reveal finishes — no extra wait.
    private var minimumAnimationDuration: TimeInterval {
        isFirstLaunch ? 3.9 : 1.21
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Nudge the lockup down by a quarter of its own height so it sits
        // visually centred rather than slightly high on screen.
        let logoHeight = view.bounds.width * 0.88 / logoAspectRatio
        logoCenterYConstraint?.constant = logoHeight / 5

        updateGradientFrames()
    }

    private func updateGradientFrames() {
        let rebuiltTop = layoutFadeStrips(in: topFadeView, strips: &topStripLayers, blackAtTop: true)
        let rebuiltBottom = layoutFadeStrips(in: bottomFadeView, strips: &bottomStripLayers, blackAtTop: false)
        if (rebuiltTop || rebuiltBottom) && fadeBreathingActive {
            startEdgeFadeBreathing()
        }
    }

    /// Builds (if needed) and positions the strip stack for one fade band.
    /// Returns true when the strips were rebuilt (count changed).
    @discardableResult
    private func layoutFadeStrips(in fadeView: UIView, strips: inout [CAGradientLayer], blackAtTop: Bool) -> Bool {
        let bounds = fadeView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return false }

        let count = max(2, Int(ceil(bounds.width / Self.waveStripWidth)))
        var rebuilt = false

        if strips.count != count {
            strips.forEach { $0.removeFromSuperlayer() }
            strips.removeAll()
            for _ in 0..<count {
                let gradient = CAGradientLayer()
                gradient.colors = blackAtTop
                    ? [UIColor.black.cgColor, UIColor.clear.cgColor]
                    : [UIColor.clear.cgColor, UIColor.black.cgColor]
                gradient.locations = [0.0, 1.0]
                gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradient.opacity = Self.breathOpacityMid
                fadeView.layer.addSublayer(gradient)
                strips.append(gradient)
            }
            rebuilt = true
        }

        let stripWidth = bounds.width / CGFloat(count)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, gradient) in strips.enumerated() {
            gradient.frame = CGRect(x: CGFloat(index) * stripWidth,
                                    y: 0,
                                    width: stripWidth + 0.5,
                                    height: bounds.height)
        }
        CATransaction.commit()

        return rebuilt
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        setupBackgroundRunes()
        setupLogoElements()
    }
    
    private func setupBackgroundRunes() {
        // Background container
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.clipsToBounds = true
        view.addSubview(backgroundContainer)
        
        var constraints: [NSLayoutConstraint] = [
            // Background container fills entire view
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        let widthMultiplier = 1.0 / CGFloat(columnCount)
        var previousClip: UIView?
        
        // Build each column as a full-height clip view. The tiled, scrolling content
        // is added later (in startBackgroundScrolling) once the layout size is known.
        for _ in 0..<columnCount {
            let clip = UIView()
            clip.translatesAutoresizingMaskIntoConstraints = false
            clip.clipsToBounds = true
            clip.alpha = 0 // Start invisible
            backgroundContainer.addSubview(clip)
            
            // Leading: first column pins to container, others pin to the previous column
            let leadingAnchor = previousClip?.trailingAnchor ?? backgroundContainer.leadingAnchor
            constraints.append(contentsOf: [
                clip.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
                clip.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
                clip.leadingAnchor.constraint(equalTo: leadingAnchor),
                clip.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: widthMultiplier)
            ])
            
            columnClips.append(clip)
            previousClip = clip
        }
        
        NSLayoutConstraint.activate(constraints)

        setupEdgeFades()
    }

    private func setupEdgeFades() {
        for fadeView in [topFadeView, bottomFadeView] {
            fadeView.translatesAutoresizingMaskIntoConstraints = false
            fadeView.isUserInteractionEnabled = false
            fadeView.alpha = 0
            view.addSubview(fadeView)
        }

        NSLayoutConstraint.activate([
            topFadeView.topAnchor.constraint(equalTo: view.topAnchor),
            topFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
        ])
    }
    
    /// Fills each column clip with vertically-tiled copies of the rune image at its
    /// natural aspect ratio, so narrow columns repeat more often instead of squishing.
    private func buildColumnTracks() {
        guard columnTracks.isEmpty else { return }
        
        for clip in columnClips {
            let columnWidth = clip.bounds.width
            let columnHeight = clip.bounds.height
            guard columnWidth > 0, columnHeight > 0 else { continue }
            
            // A single tile keeps the image's aspect ratio at the column width
            let tileHeight = columnWidth * runeAspectRatio
            guard tileHeight > 0 else { continue }
            
            // Enough tiles to cover the column plus one extra above and below for the loop
            let tileCount = Int(ceil(columnHeight / tileHeight)) + 2
            
            let track = UIView(frame: clip.bounds)
            for i in 0..<tileCount {
                let tile = UIImageView(image: runeImage)
                tile.contentMode = .scaleToFill
                // Start one tile above the top so downward scrolling has no gap
                tile.frame = CGRect(x: 0,
                                    y: CGFloat(i - 1) * tileHeight,
                                    width: columnWidth,
                                    height: tileHeight)
                track.addSubview(tile)
            }
            
            clip.addSubview(track)
            columnTracks.append(track)
        }
    }
    
    private func setupLogoElements() {
        // Logo container for centering
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoContainer)

        // Vector "Cosmic Fit" lockup whose stars and letters each fade in separately
        logoMark.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(logoMark)

        logoCenterYConstraint = logoContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        NSLayoutConstraint.activate([
            // Logo container centred horizontally; vertical offset applied in layout.
            logoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoCenterYConstraint!,
            logoContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.88),
            logoContainer.heightAnchor.constraint(equalTo: logoContainer.widthAnchor,
                                                  multiplier: 1.0 / logoAspectRatio),

            // Logo mark fills the container
            logoMark.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoMark.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
            logoMark.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
            logoMark.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Animations
    private func startAnimations() {
        startLogoAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumAnimationDuration) {
            self.minimumAnimationElapsed = true
            self.attemptTransitionToMainApp()
        }
    }
    
    private func startLogoAnimation() {
        
        // START BACKGROUND FADE-IN immediately
        self.startBackgroundGradualFadeIn()
        
        // Same three-phase sequential reveal in both cases — the star inside
        // "Cosmic" first, then "Cosmic", then "Fit", sweeping left-to-right within
        // each phase. Subsequent launches just play it much faster.
        let groups = [
            CosmicFitLogoMarkView.ElementGroup.cosmicStar,
            CosmicFitLogoMarkView.ElementGroup.cosmicLetters,
            CosmicFitLogoMarkView.ElementGroup.fit
        ]

        if isFirstLaunch {
            // First ever launch: slow, anticipatory pacing.
            logoMark.animateGroupedReveal(
                groups: groups,
                groupDuration: 1.0,
                groupStagger: 0.85,
                elementStagger: 0.12,
                startDelay: 0.35)

            // Remember we've played the full intro so later launches stay quick.
            UserDefaults.standard.set(true, forKey: Self.hasShownIntroKey)
        } else {
            // Every subsequent launch: identical sequencing, compressed to ~1s.
            logoMark.animateGroupedReveal(
                groups: groups,
                groupDuration: 0.4,
                groupStagger: 0.28,
                elementStagger: 0.05,
                startDelay: 0.1)
        }
    }
    
    private func startBackgroundGradualFadeIn() {
        // Start scrolling immediately but invisibly
        startBackgroundScrolling()
        
        // Fade in all background columns and edge fades
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut], animations: {
            for clip in self.columnClips {
                clip.alpha = 1.0
            }
            self.topFadeView.alpha = 1.0
            self.bottomFadeView.alpha = 1.0
        }, completion: nil)

        startEdgeFadeBreathing()
    }
    
    private func startBackgroundScrolling() {
        // Need to let constraints lay out the column clips before measuring them
        view.layoutIfNeeded()
        
        // Build the tiled, aspect-correct content now that column sizes are known
        buildColumnTracks()
        
        // Constant scroll speed (points per second) so every column moves at the same pace
        let scrollSpeed: CGFloat = 42.0
        
        // Alternate scroll direction per column (even = down, odd = up)
        for index in 0..<columnTracks.count {
            let track = columnTracks[index]
            let columnWidth = columnClips[index].bounds.width
            let tileHeight = columnWidth * runeAspectRatio
            guard tileHeight > 0 else { continue }
            
            let direction: ScrollDirection = (index % 2 == 0) ? .down : .up
            let duration = TimeInterval(tileHeight / scrollSpeed)
            animateBackgroundScroll(track: track, direction: direction, tileHeight: tileHeight, duration: duration)
        }
    }
    
    private enum ScrollDirection {
        case up, down
    }
    
    private func animateBackgroundScroll(track: UIView, direction: ScrollDirection, tileHeight: CGFloat, duration: TimeInterval) {
        // The tiles repeat every `tileHeight`, so shifting by exactly one tile loops seamlessly
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        switch direction {
        case .down:
            animation.fromValue = 0
            animation.toValue = tileHeight
        case .up:
            animation.fromValue = 0
            animation.toValue = -tileHeight
        }
        
        track.layer.add(animation, forKey: "scrollAnimation")
    }

    // MARK: - Edge fade breathing
    private func startEdgeFadeBreathing() {
        fadeBreathingActive = true
        let now = CACurrentMediaTime()
        animateWave(across: topStripLayers, startTime: now)
        animateWave(across: bottomStripLayers, startTime: now)
    }

    /// Drives one fade band's strips with a shared opacity oscillation whose
    /// phase advances with x position, so the identical waveform appears to
    /// flow sideways across the band as a continuous wave.
    private func animateWave(across strips: [CAGradientLayer], startTime: CFTimeInterval) {
        guard !strips.isEmpty else { return }
        let fullCycle = Self.breathHalfPeriod * 2.0

        for (index, gradient) in strips.enumerated() {
            gradient.removeAnimation(forKey: Self.breathKey)

            let fraction = Double(index) / Double(strips.count)
            let phaseOffset = fraction * Self.waveCrests * fullCycle

            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = Self.breathOpacityMid - Self.breathOpacityDelta
            anim.toValue = Self.breathOpacityMid + Self.breathOpacityDelta
            anim.duration = Self.breathHalfPeriod
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.isRemovedOnCompletion = false
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.beginTime = startTime - phaseOffset
            gradient.add(anim, forKey: Self.breathKey)
        }
    }
    
    // MARK: - Transition
    func setMainViewController(_ viewController: UIViewController) {
        self.mainViewController = viewController
        attemptTransitionToMainApp()
    }
    
    private func attemptTransitionToMainApp() {
        guard !hasTransitioned else { return }
        guard minimumAnimationElapsed else { return }
        guard let mainViewController = mainViewController else { return }
        
        hasTransitioned = true
        
        mainViewController.modalTransitionStyle = .crossDissolve
        mainViewController.modalPresentationStyle = .fullScreen
        self.present(mainViewController, animated: true)
    }
}
