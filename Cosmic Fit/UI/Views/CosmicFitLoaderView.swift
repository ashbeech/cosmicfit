//
//  CosmicFitLoaderView.swift
//  Cosmic Fit
//
//  The single, brand-specific loading indicator used across the app.
//
//  A sharp-silhouette vector "sparkle" (the Cosmic Fit div-star) that
//  pulses on a loop: it blooms in from nothing through needle → cross → star,
//  resolves into the exact brand star icon shape (holding briefly), then collapses
//  through independent outro frames back to nothing before looping. No blur, no glow — just a
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

    /// Builds a parametric four-point star whose concave sides hug a diagonal
    /// "waist". Small waist → deep, thin spikes; larger waist → fuller star.
    private static func parametricShape(
        vTip: CGFloat, hTip: CGFloat, waist: CGFloat, arc: CGFloat
    ) -> StarShape {
        let top = CGPoint(x: 0, y: -vTip)
        let right = CGPoint(x: hTip, y: 0)
        let bottom = CGPoint(x: 0, y: vTip)
        let left = CGPoint(x: -hTip, y: 0)
        let wTR = CGPoint(x: waist, y: -waist)
        let wRB = CGPoint(x: waist, y: waist)
        let wBL = CGPoint(x: -waist, y: waist)
        let wLT = CGPoint(x: -waist, y: -waist)
        func hug(_ p: CGPoint, _ w: CGPoint) -> CGPoint {
            CGPoint(x: p.x + arc * (w.x - p.x), y: p.y + arc * (w.y - p.y))
        }
        return StarShape(
            anchors: [top, right, bottom, left],
            controls: [
                hug(top, wTR),    hug(right, wTR),   // side top -> right
                hug(right, wRB),  hug(bottom, wRB),  // side right -> bottom
                hug(bottom, wBL), hug(left, wBL),    // side bottom -> left
                hug(left, wLT),   hug(top, wLT)      // side left -> top
            ]
        )
    }

    /// Uniformly scales a shape about the origin (centre). Used to build the
    /// collapse frames: scaled-down copies of the exact icon keep the star's
    /// silhouette identical while it shrinks to a glint.
    private static func scaled(_ s: StarShape, by k: CGFloat) -> StarShape {
        func m(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * k, y: p.y * k) }
        return StarShape(anchors: s.anchors.map(m), controls: s.controls.map(m))
    }

    /// Rotates a shape about the origin by the given angle in degrees.
    private static func rotated(_ s: StarShape, byDegrees deg: CGFloat) -> StarShape {
        let a = deg * .pi / 180, c = cos(a), s2 = sin(a)
        func r(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * c - p.y * s2, y: p.x * s2 + p.y * c) }
        return StarShape(anchors: s.anchors.map(r), controls: s.controls.map(r))
    }

    // The loop blooms in through grow frames, holds on the brand icon, then
    // collapses through independent outro frames so the star can retreat
    // differently than it bloomed.
    //
    //   GROW  (blank → g1 → g2 → g3 → icon): needle glint → thin cross → sharp star.
    //   COLLAPSE (icon → o3 → o2 → o1 → blank): independent outro shapes.
    //
    // Every frame keeps the same path structure (move + 4 cubics + close) so Core
    // Animation can morph between any two — needle, bloom, or the brand icon.
    private static let blank = parametricShape(vTip: 0.0010, hTip: 0.0010, waist: 0.0006, arc: 0.78)

    // GROW (intro) frames — needle glint -> thin cross -> sharp star.
    private static let g1 = parametricShape(vTip: 0.0999, hTip: 0.1282, waist: 0.006, arc: 0.965)
    private static let g2 = parametricShape(vTip: 0.9573, hTip: 0.0801, waist: 0.012, arc: 0.95)
    private static let g3 = rotated(parametricShape(vTip: 1.0294, hTip: 0.8974, waist: 0.3905, arc: 0.86), byDegrees: -1.0)

    // OUTRO (collapse) frames — independent of the grow frames.
    private static let o1 = rotated(parametricShape(vTip: 0.0999, hTip: 0.0641, waist: 0.006, arc: 0.965), byDegrees: 125.0)
    private static let o2 = parametricShape(vTip: 1.1217, hTip: 1.0096, waist: 0.0, arc: 0.95)
    private static let o3 = parametricShape(vTip: 1.0294, hTip: 0.8974, waist: 0.3605, arc: 0.86)

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

    // BREATHE frames — for the no-blank (button) variant, a clearly-formed star
    // that pulses between a smaller and the full icon without ever vanishing.
    private static let breatheFloor = scaled(f5, by: 0.50)
    private static let breatheMid   = scaled(f5, by: 0.74)

    // blankGap frame order (intro grows g1->g2->g3->icon, outro collapses o3->o2->o1):
    //   blank, blank, g1, g2, g3, f5, f5, o3, o2, o1, blank
    private enum Timing {
        static let appear: Double = 0.115
        static let riseStep: Double = 0.06
        static let settle: Double = 0.08
        static let iconHold: Double = 0.62
        static let shrink1: Double = 0.045
        static let shrink2: Double = 0.04
        static let blankHold: Double = 0.25
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

        let frames: [StarShape]
        let segmentDurations: [Double]
        let opacityValues: [CGFloat]

        if includesBlankGap {
            frames = [
                Self.blank, Self.blank,
                Self.g1, Self.g2, Self.g3, Self.f5,
                Self.f5,
                Self.o3, Self.o2, Self.o1,
                Self.blank
            ]
            segmentDurations = [
                Timing.blankHold,
                Timing.appear,
                Timing.riseStep,
                Timing.riseStep,
                Timing.settle,
                Timing.iconHold,
                Timing.settle,
                Timing.riseStep,
                Timing.riseStep,
                Timing.appear
            ]
            opacityValues = [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0]
        } else {
            // Breathing variant for small/button placements: a clearly-formed
            // star pulses between a smaller copy and the full icon, never blank.
            frames = [
                Self.breatheFloor, Self.breatheMid, Self.f5,
                Self.f5,
                Self.breatheMid, Self.breatheFloor,
                Self.breatheFloor
            ]
            segmentDurations = [
                Timing.riseStep,     // floor -> mid
                Timing.settle,       // mid -> icon
                Timing.iconHold,     // hold on icon
                Timing.shrink1,      // icon -> mid
                Timing.shrink2,      // mid -> floor
                Timing.iconHold      // brief settle at floor
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
