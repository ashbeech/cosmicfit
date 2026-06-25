//
//  ScrollingRunesBackgroundView.swift
//  Cosmic Fit
//
//  Reusable full-screen view with 5 scrolling rune columns
//  Unified implementation for both launch screen and Daily Fit page
//

import UIKit

class ScrollingRunesBackgroundView: UIView {

    /// Visual treatment for the top/bottom dark gradient bands.
    enum EdgeFadeStyle {
        /// Daily Fit pre-reveal: slightly lighter, shorter bands.
        case dailyFit
        /// Launch screen: deeper fades over half the height.
        case launch
    }

    var edgeFadeStyle: EdgeFadeStyle = .dailyFit

    // MARK: - Properties
    private let columnCount = 5
    private let runeImage = UIImage(named: "logo-animation-background")
    private var runeAspectRatio: CGFloat {
        guard let size = runeImage?.size, size.width > 0 else { return 1.0 }
        return size.height / size.width
    }

    private var columnClips: [UIView] = []
    private var columnTracks: [UIView] = []
    private var isAnimating = false
    private static let scrollSpeed: CGFloat = 42.0

    // MARK: - Edge fade overlays
     private let topFadeView = UIView()
    private let bottomFadeView = UIView()
    private var topStripLayers: [CAGradientLayer] = []
    private var bottomStripLayers: [CAGradientLayer] = []
    private var fadeBreathingActive = false
    private static let breathHalfPeriod: CFTimeInterval = 1.05 * (4.0 / 3.0)
    private static let breathKey = "edgeFadeBreath"
    private static let waveStripWidth: CGFloat = 24.0

    private var breathOpacityMid: Float {
        switch edgeFadeStyle {
        case .dailyFit: return 0.66
        case .launch: return 0.5
        }
    }

    private var breathOpacityDelta: Float {
        switch edgeFadeStyle {
        case .dailyFit: return 0.20
        case .launch: return 0.22
        }
    }

    private var waveCrests: Double {
        switch edgeFadeStyle {
        case .dailyFit: return 1.0
        case .launch: return 0.5
        }
    }

    private var topFadeHeightMultiplier: CGFloat {
        switch edgeFadeStyle {
        case .dailyFit: return 0.4
        case .launch: return 0.5
        }
    }

    private var bottomFadeHeightMultiplier: CGFloat {
        switch edgeFadeStyle {
        case .dailyFit: return 0.33
        case .launch: return 0.5
        }
    }

    private var edgeFadeTargetAlpha: CGFloat {
        switch edgeFadeStyle {
        case .dailyFit: return 0.75
        case .launch: return 1.0
        }
    }

    // MARK: - Initialization
    init(edgeFadeStyle: EdgeFadeStyle = .dailyFit) {
        self.edgeFadeStyle = edgeFadeStyle
        super.init(frame: .zero)
        setupUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        clipsToBounds = true
        backgroundColor = .clear

        guard runeImage != nil else {
            print("⚠️ Could not load logo-animation-background image")
            return
        }

        let widthMultiplier = 1.0 / CGFloat(columnCount)
        var constraints: [NSLayoutConstraint] = []
        var previousClip: UIView?

        for _ in 0..<columnCount {
            let clip = UIView()
            clip.translatesAutoresizingMaskIntoConstraints = false
            clip.clipsToBounds = true
            clip.alpha = 0
            addSubview(clip)

            let leadingAnchor = previousClip?.trailingAnchor ?? self.leadingAnchor
            constraints.append(contentsOf: [
                clip.topAnchor.constraint(equalTo: topAnchor),
                clip.bottomAnchor.constraint(equalTo: bottomAnchor),
                clip.leadingAnchor.constraint(equalTo: leadingAnchor),
                clip.widthAnchor.constraint(equalTo: widthAnchor, multiplier: widthMultiplier)
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
            addSubview(fadeView)
        }

        NSLayoutConstraint.activate([
            topFadeView.topAnchor.constraint(equalTo: topAnchor),
            topFadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topFadeView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: topFadeHeightMultiplier),

            bottomFadeView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomFadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomFadeView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: bottomFadeHeightMultiplier),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rebuiltTop = layoutFadeStrips(in: topFadeView, strips: &topStripLayers, blackAtTop: true)
        let rebuiltBottom = layoutFadeStrips(in: bottomFadeView, strips: &bottomStripLayers, blackAtTop: false)
        // A size change (e.g. rotation) drops the per-strip animations, so
        // re-arm the travelling wave if it should currently be running.
        if (rebuiltTop || rebuiltBottom) && isAnimating {
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
                gradient.opacity = breathOpacityMid
                fadeView.layer.addSublayer(gradient)
                strips.append(gradient)
            }
            rebuilt = true
        }

        let stripWidth = bounds.width / CGFloat(count)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, gradient) in strips.enumerated() {
            // +0.5 overlap avoids hairline seams between adjacent strips.
            gradient.frame = CGRect(x: CGFloat(index) * stripWidth,
                                    y: 0,
                                    width: stripWidth + 0.5,
                                    height: bounds.height)
        }
        CATransaction.commit()

        return rebuilt
    }

    private func buildColumnTracks() {
        guard columnTracks.isEmpty else { return }

        for clip in columnClips {
            let columnWidth = clip.bounds.width
            let columnHeight = clip.bounds.height
            guard columnWidth > 0, columnHeight > 0 else { continue }

            let tileHeight = columnWidth * runeAspectRatio
            guard tileHeight > 0 else { continue }

            let tileCount = Int(ceil(columnHeight / tileHeight)) + 2

            let track = UIView(frame: clip.bounds)
            for i in 0..<tileCount {
                let tile = UIImageView(image: runeImage)
                tile.contentMode = .scaleToFill
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

    // MARK: - Public Methods
    func startAnimating(visibleHeight: CGFloat? = nil) {
        guard !isAnimating else { return }
        isAnimating = true

        layoutIfNeeded()
        buildColumnTracks()

        UIView.animate(withDuration: 0.5) {
            for clip in self.columnClips {
                clip.alpha = 1.0
            }
            self.topFadeView.alpha = self.edgeFadeTargetAlpha
            self.bottomFadeView.alpha = self.edgeFadeTargetAlpha
        }

        for index in 0..<columnTracks.count {
            let track = columnTracks[index]
            let columnWidth = columnClips[index].bounds.width
            let tileHeight = columnWidth * runeAspectRatio
            guard tileHeight > 0 else { continue }

            let direction: ScrollDirection = (index % 2 == 0) ? .down : .up
            let duration = TimeInterval(tileHeight / Self.scrollSpeed)
            animateScroll(track: track, direction: direction, tileHeight: tileHeight, duration: duration)
        }

        startEdgeFadeBreathing()
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false

        for track in columnTracks {
            track.layer.removeAllAnimations()
        }
        stopEdgeFadeBreathing()

        UIView.animate(withDuration: 0.33) {
            for clip in self.columnClips {
                clip.alpha = 0
            }
            self.topFadeView.alpha = 0
            self.bottomFadeView.alpha = 0
        }
    }

    // MARK: - Edge fade breathing
    private func startEdgeFadeBreathing() {
        let now = CACurrentMediaTime()
        animateWave(across: topStripLayers, startTime: now)
        animateWave(across: bottomStripLayers, startTime: now)
    }

    /// Drives one fade band's strips with a shared opacity oscillation whose
    /// phase advances with x position. The per-strip `beginTime` offset makes
    /// the identical waveform appear to flow sideways as a continuous wave.
    private func animateWave(across strips: [CAGradientLayer], startTime: CFTimeInterval) {
        guard !strips.isEmpty else { return }
        let fullCycle = Self.breathHalfPeriod * 2.0

        for (index, gradient) in strips.enumerated() {
            gradient.removeAnimation(forKey: Self.breathKey)

            let fraction = Double(index) / Double(strips.count)
            let phaseOffset = fraction * waveCrests * fullCycle

            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = breathOpacityMid - breathOpacityDelta
            anim.toValue = breathOpacityMid + breathOpacityDelta
            anim.duration = Self.breathHalfPeriod
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.isRemovedOnCompletion = false
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            // Shift each strip back in time so it lags its neighbour, turning
            // the in-place pulse into a wave that travels across the band.
            anim.beginTime = startTime - phaseOffset
            gradient.add(anim, forKey: Self.breathKey)
        }
    }

    private func stopEdgeFadeBreathing() {
        for gradient in topStripLayers + bottomStripLayers {
            gradient.removeAnimation(forKey: Self.breathKey)
            gradient.opacity = breathOpacityMid
        }
    }

    // MARK: - Private Animation
    private enum ScrollDirection {
        case up, down
    }

    private func animateScroll(track: UIView, direction: ScrollDirection, tileHeight: CGFloat, duration: TimeInterval) {
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
}
