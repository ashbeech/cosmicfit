//
//  CosmicFitLoaderView.swift
//  Cosmic Fit
//
//  The single, brand-specific loading indicator used across the app.
//
//  A sharp-silhouette vector "sparkle" (the Cosmic Fit div-star) that
//  pulses on a boomerang loop: it blooms in from nothing, resolves into
//  the exact brand star icon shape (holding briefly), then retraces its
//  path back out to nothing before looping. No blur, no glow — just a
//  crisp filled silhouette in the Cosmic Fit colours.
//
//  This view is a drop-in replacement for `UIActivityIndicatorView`:
//  it exposes `startAnimating()`, `stopAnimating()`, `isAnimating`, and
//  `hidesWhenStopped` with the same semantics.
//

import UIKit

final class CosmicFitLoaderView: UIView {

    // MARK: - Fill

    /// Which brand colour fills the silhouette. Pick the one that contrasts
    /// with the surface the loader sits on.
    enum Fill {
        /// Off-white fill for dark backgrounds.
        case light
        /// Cosmic-blue (#000210) fill for light backgrounds.
        case dark

        var colour: UIColor {
            switch self {
            case .light: return .white
            case .dark:  return CosmicFitTheme.Colours.cosmicBlue
            }
        }
    }

    // MARK: - Public API (mirrors UIActivityIndicatorView)

    /// When `true`, the loader hides itself while stopped.
    var hidesWhenStopped: Bool = true {
        didSet { if !isAnimating { isHidden = hidesWhenStopped } }
    }

    private(set) var isAnimating: Bool = false

    var fill: Fill {
        didSet { shapeLayer.fillColor = fill.colour.cgColor }
    }

    // MARK: - Configuration

    /// When `true` (the full brand spec) the loop passes through a fully
    /// invisible state held for `Timing.blankHold`. When `false`, the star
    /// never disappears — used for small/button placements where a blank
    /// frame would read as a flicker of "nothing happening".
    private let includesBlankGap: Bool

    // MARK: - Layers

    private let shapeLayer = CAShapeLayer()

    // MARK: - Geometry

    /// A single shape state in the morph, expressed as fractions of the
    /// view's half-extent so it scales with `bounds`.
    private struct StarParams {
        /// Tip reach along the vertical axis (top/bottom points).
        let vTip: CGFloat
        /// Tip reach along the horizontal axis (left/right points).
        let hTip: CGFloat
        /// Reach of the diagonal "waist" between two tips. Small values
        /// pull the silhouette into sharp spikes; large values fill it out.
        let waist: CGFloat
        /// 0 = sharp tips & sharp inner corners (sparkle),
        /// 1 = fully smoothed corners (convex squircle bloom).
        let round: CGFloat
    }

    // Frame guide, numbered to match the reference frames. The "in"
    // direction runs blank -> f1 -> ... -> f5 (the brand icon), then the
    // loop boomerangs back out. Tuned to read as: a thin glint that grows,
    // blooms full, then resolves into the crisp brand star.
    private static let blank = StarParams(vTip: 0.0008, hTip: 0.0008, waist: 0.0008, round: 0)
    private static let f1    = StarParams(vTip: 0.42,   hTip: 0.56,   waist: 0.045,  round: 0.0)
    private static let f2    = StarParams(vTip: 1.00,   hTip: 0.74,   waist: 0.20,   round: 0.06)
    private static let f3    = StarParams(vTip: 0.95,   hTip: 0.95,   waist: 0.92,   round: 1.0)
    private static let f4    = StarParams(vTip: 0.92,   hTip: 0.86,   waist: 0.50,   round: 0.45)
    /// f5 == the Cosmic Fit star icon: vertically a touch longer, sharp
    /// points, lightly concave sides.
    private static let f5    = StarParams(vTip: 1.00,   hTip: 0.84,   waist: 0.30,   round: 0.08)

    private enum Timing {
        /// Seconds the loop rests on the fully invisible state.
        static let blankHold: Double = 0.2
        /// Seconds the loop holds on the resolved brand-star icon.
        static let iconHold: Double = 0.5
        /// Seconds per shape-to-shape transition.
        static let step: Double = 0.14
    }

    // MARK: - Init

    init(fill: Fill = .dark, includesBlankGap: Bool = true) {
        self.fill = fill
        self.includesBlankGap = includesBlankGap
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        self.fill = .dark
        self.includesBlankGap = true
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        shapeLayer.fillColor = fill.colour.cgColor
        shapeLayer.strokeColor = UIColor.clear.cgColor
        shapeLayer.fillRule = .nonZero
        layer.addSublayer(shapeLayer)
        isHidden = hidesWhenStopped
    }

    // MARK: - Layout

    override var intrinsicContentSize: CGSize { CGSize(width: 44, height: 44) }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        // Keep the static (stopped) path in sync with the resolved icon so
        // the view looks correct even before/without animation.
        shapeLayer.path = path(for: Self.f5).cgPath
        if isAnimating { applyAnimation() }
    }

    // MARK: - Animation control

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        isHidden = false
        applyAnimation()
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        shapeLayer.removeAnimation(forKey: Self.animationKey)
        if hidesWhenStopped { isHidden = true }
    }

    // MARK: - Re-arm after backgrounding / re-attach

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, isAnimating {
            applyAnimation()
        }
    }

    // MARK: - Animation construction

    private static let animationKey = "cosmicFitLoader.morph"

    private func applyAnimation() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        shapeLayer.removeAnimation(forKey: Self.animationKey)

        let frames: [StarParams]
        let segmentDurations: [Double]
        let opacityValues: [CGFloat]

        if includesBlankGap {
            // blank(hold) -> f1 f2 f3 f4 f5 -> f5(hold) -> f4 f3 f2 f1 -> blank
            frames = [
                Self.blank, Self.blank,
                Self.f1, Self.f2, Self.f3, Self.f4, Self.f5,
                Self.f5,
                Self.f4, Self.f3, Self.f2, Self.f1,
                Self.blank
            ]
            segmentDurations = [
                Timing.blankHold,                                    // blank hold
                Timing.step, Timing.step, Timing.step, Timing.step, Timing.step, // in
                Timing.iconHold,                                     // icon hold
                Timing.step, Timing.step, Timing.step, Timing.step,  // out
                Timing.step                                          // -> blank
            ]
            opacityValues = [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
        } else {
            // f1(small) -> f5(icon) -> hold -> back to f1, never invisible.
            frames = [
                Self.f1, Self.f2, Self.f3, Self.f4, Self.f5,
                Self.f5,
                Self.f4, Self.f3, Self.f2, Self.f1,
                Self.f1
            ]
            segmentDurations = [
                Timing.step, Timing.step, Timing.step, Timing.step, // in
                Timing.iconHold,                                    // icon hold
                Timing.step, Timing.step, Timing.step, Timing.step, // out
                Timing.blankHold                                    // brief settle at f1
            ]
            opacityValues = Array(repeating: 1, count: frames.count)
        }

        let total = segmentDurations.reduce(0, +)
        let keyTimes = Self.keyTimes(from: segmentDurations, total: total)

        let pathAnim = CAKeyframeAnimation(keyPath: "path")
        pathAnim.values = frames.map { path(for: $0).cgPath }
        pathAnim.keyTimes = keyTimes.map { NSNumber(value: Double($0)) }
        pathAnim.calculationMode = .linear
        pathAnim.timingFunctions = Array(
            repeating: CAMediaTimingFunction(name: .easeInEaseOut),
            count: max(0, frames.count - 1)
        )

        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.values = opacityValues.map { NSNumber(value: Double($0)) }
        opacityAnim.keyTimes = keyTimes.map { NSNumber(value: Double($0)) }
        opacityAnim.calculationMode = .linear

        let group = CAAnimationGroup()
        group.animations = [pathAnim, opacityAnim]
        group.duration = total
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        group.fillMode = .both
        shapeLayer.add(group, forKey: Self.animationKey)
    }

    private static func keyTimes(from durations: [Double], total: Double) -> [CGFloat] {
        guard total > 0 else { return durations.map { _ in 0 } }
        var times: [CGFloat] = [0]
        var running: Double = 0
        for d in durations {
            running += d
            times.append(CGFloat(running / total))
        }
        // `times` has count == durations.count + 1, matching the value array.
        return times
    }

    // MARK: - Path generation

    /// Builds the four-point sparkle for a given shape state. Every state
    /// produces an identically-structured path (1 move + 8 cubic curves +
    /// close) so Core Animation can interpolate between them smoothly.
    private func path(for p: StarParams) -> UIBezierPath {
        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        // Leave a hair of breathing room so tips never clip the bounds.
        let radius = min(bounds.width, bounds.height) / 2 * 0.96

        let vTip = p.vTip * radius
        let hTip = p.hTip * radius
        let waist = p.waist * radius * 0.7071 // projected onto each diagonal axis

        // Anchors, clockwise from the top tip.
        let anchors: [CGPoint] = [
            CGPoint(x: centre.x,         y: centre.y - vTip),  // 0 top tip
            CGPoint(x: centre.x + waist, y: centre.y - waist), // 1 TR waist
            CGPoint(x: centre.x + hTip,  y: centre.y),         // 2 right tip
            CGPoint(x: centre.x + waist, y: centre.y + waist), // 3 BR waist
            CGPoint(x: centre.x,         y: centre.y + vTip),  // 4 bottom tip
            CGPoint(x: centre.x - waist, y: centre.y + waist), // 5 BL waist
            CGPoint(x: centre.x - hTip,  y: centre.y),         // 6 left tip
            CGPoint(x: centre.x - waist, y: centre.y - waist)  // 7 TL waist
        ]

        let count = anchors.count
        // Handle length grows with roundness so smoothed states bulge into a
        // convex bloom while sharp states keep near-straight edges.
        let handleScale: CGFloat = 0.30 + 0.28 * p.round

        // Precompute, per anchor, the outgoing and incoming handle directions
        // blended between "sharp" (toward neighbours) and "round" (along the
        // prev->next chord, i.e. a smooth tangent).
        var outDir = [CGVector](repeating: .zero, count: count)
        var inDir = [CGVector](repeating: .zero, count: count)
        for i in 0..<count {
            let prev = anchors[(i + count - 1) % count]
            let cur = anchors[i]
            let next = anchors[(i + 1) % count]

            let sharpOut = Self.unit(from: cur, to: next)
            let sharpIn = Self.unit(from: cur, to: prev)
            let roundOut = Self.unitVector(dx: next.x - prev.x, dy: next.y - prev.y)
            let roundIn = CGVector(dx: -roundOut.dx, dy: -roundOut.dy)

            outDir[i] = Self.unitVector(
                dx: Self.lerp(sharpOut.dx, roundOut.dx, p.round),
                dy: Self.lerp(sharpOut.dy, roundOut.dy, p.round)
            )
            inDir[i] = Self.unitVector(
                dx: Self.lerp(sharpIn.dx, roundIn.dx, p.round),
                dy: Self.lerp(sharpIn.dy, roundIn.dy, p.round)
            )
        }

        let path = UIBezierPath()
        path.move(to: anchors[0])
        for i in 0..<count {
            let a = anchors[i]
            let b = anchors[(i + 1) % count]
            let segLen = hypot(b.x - a.x, b.y - a.y)
            let len = segLen * handleScale
            let c1 = CGPoint(x: a.x + outDir[i].dx * len, y: a.y + outDir[i].dy * len)
            let c2 = CGPoint(
                x: b.x + inDir[(i + 1) % count].dx * len,
                y: b.y + inDir[(i + 1) % count].dy * len
            )
            path.addCurve(to: b, controlPoint1: c1, controlPoint2: c2)
        }
        path.close()
        return path
    }

    // MARK: - Vector helpers

    private static func unit(from a: CGPoint, to b: CGPoint) -> CGVector {
        unitVector(dx: b.x - a.x, dy: b.y - a.y)
    }

    private static func unitVector(dx: CGFloat, dy: CGFloat) -> CGVector {
        let len = hypot(dx, dy)
        guard len > 0.0001 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}
