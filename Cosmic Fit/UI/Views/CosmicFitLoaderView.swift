//
//  CosmicFitLoaderView.swift
//  Cosmic Fit
//
//  The single, brand-specific loading indicator used across the app.
//
//  A sharp-silhouette vector "sparkle" (the Cosmic Fit div-star) that
//  pulses on a loop: the exact brand star icon breathes between a larger
//  resting size and a smaller contracted one, never vanishing. No blur,
//  no glow — just a crisp filled silhouette in the Cosmic Fit colours.
//  (Tuned in tools/anim-inspector; the earlier bloom/collapse cycle is
//  recoverable from git history.)
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

    // MARK: - Layers

    private let shapeLayer = CAShapeLayer()

    // MARK: - Geometry

    /// A four-point star outline in normalised coordinates (fractions of the
    /// view's half-extent, centred on the origin, y-down).
    ///
    /// Every frame shares one structure — `move, curve × 4, close` — i.e. four
    /// sharp tips joined by four concave cubic arcs that sweep into the points.
    /// Identical structure is what lets Core Animation morph the parametric
    /// frames straight into the exact embedded brand icon.
    private struct StarShape {
        /// 4 tip anchors, clockwise: top, right, bottom, left.
        let anchors: [CGPoint]
        /// 8 cubic control points: two per side (TR, RB, BL, LT).
        let controls: [CGPoint]
    }

    /// Uniformly scales a shape about the origin (centre). The pulse frames
    /// are scaled copies of the exact icon, so the star's silhouette stays
    /// identical while it breathes.
    private static func scaled(_ s: StarShape, by k: CGFloat) -> StarShape {
        func m(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * k, y: p.y * k) }
        return StarShape(anchors: s.anchors.map(m), controls: s.controls.map(m))
    }

    /// f5 == the Cosmic Fit star icon (`star_icon_placeholder` / div-star),
    /// EXACT geometry recovered by tracing the shipped asset and least-squares
    /// fitting one cubic per side (sub-pixel residual). Vertical points are
    /// ~1.26× the horizontal, with concave arc sides sweeping into sharp points.
    private static let f5 = StarShape(
        anchors: [
            CGPoint(x: 0.0,     y: -1.0),     // top
            CGPoint(x: 0.7939,  y: 0.0),      // right
            CGPoint(x: 0.0,     y: 1.0),      // bottom
            CGPoint(x: -0.7939, y: 0.0)       // left
        ],
        controls: [
            CGPoint(x: 0.1219,  y: -0.4559), CGPoint(x: 0.2729,  y: -0.1176), // top -> right
            CGPoint(x: 0.2729,  y: 0.1176),  CGPoint(x: 0.1219,  y: 0.4559),  // right -> bottom
            CGPoint(x: -0.1219, y: 0.4559),  CGPoint(x: -0.2729, y: 0.1176),  // bottom -> left
            CGPoint(x: -0.2729, y: -0.1176), CGPoint(x: -0.1219, y: -0.4559)  // left -> top
        ]
    )

    // PULSE frames — the icon breathes between a larger resting size (floor)
    // and a smaller contracted one (ceil), fully opaque throughout. Values
    // exported from tools/anim-inspector ("pulse" variant).
    private static let pulseFloor = scaled(f5, by: 0.85)
    private static let pulseCeil  = scaled(f5, by: 0.66)

    // pulse frame order (ends where it starts so the loop is seamless):
    //   pulseFloor, pulseCeil, pulseCeil, pulseFloor, pulseFloor
    private enum Timing {
        static let pulseUp: Double = 1.13
        static let pulseHoldHi: Double = 0.12
        static let pulseDown: Double = 0.45
        static let pulseHoldLo: Double = 0.12
    }

    // MARK: - Init

    init(fill: Fill = .dark) {
        self.fill = fill
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        self.fill = .dark
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

        // Icon-only pulse: contract from the resting floor to the smaller
        // "ceil", hold, expand back, hold. Opacity stays at 1 throughout, so
        // only the path animates.
        let frames: [StarShape] = [
            Self.pulseFloor, Self.pulseCeil,
            Self.pulseCeil,
            Self.pulseFloor,
            Self.pulseFloor
        ]
        let segmentDurations: [Double] = [
            Timing.pulseUp,      // floor -> ceil
            Timing.pulseHoldHi,  // hold at ceil
            Timing.pulseDown,    // ceil -> floor
            Timing.pulseHoldLo   // hold at floor
        ]

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
        pathAnim.duration = total
        pathAnim.repeatCount = .infinity
        pathAnim.isRemovedOnCompletion = false
        pathAnim.fillMode = .both
        shapeLayer.add(pathAnim, forKey: Self.animationKey)
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

    /// Builds the on-screen path for a shape state. The normalised anchors and
    /// controls are scaled by the working radius and centred in `bounds`.
    /// Structure is fixed (`move, curve × 4, close`) for every state so Core
    /// Animation can interpolate between any two frames smoothly.
    private func path(for shape: StarShape) -> UIBezierPath {
        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        // Sides only ever bow inward, so nothing extends past the tips — the
        // modest margin just keeps the sharp points off the edge.
        let radius = min(bounds.width, bounds.height) / 2 * 0.95

        func point(_ n: CGPoint) -> CGPoint {
            CGPoint(x: centre.x + n.x * radius, y: centre.y + n.y * radius)
        }

        let a = shape.anchors
        let c = shape.controls
        let path = UIBezierPath()
        path.move(to: point(a[0]))
        path.addCurve(to: point(a[1]), controlPoint1: point(c[0]), controlPoint2: point(c[1]))
        path.addCurve(to: point(a[2]), controlPoint1: point(c[2]), controlPoint2: point(c[3]))
        path.addCurve(to: point(a[3]), controlPoint1: point(c[4]), controlPoint2: point(c[5]))
        path.addCurve(to: point(a[0]), controlPoint1: point(c[6]), controlPoint2: point(c[7]))
        path.close()
        return path
    }
}
