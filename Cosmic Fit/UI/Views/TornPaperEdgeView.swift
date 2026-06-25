//
//  TornPaperEdgeView.swift
//  Cosmic Fit
//
//  Procedurally-drawn torn-paper bottom edge used to cap the Daily Fit
//  content card for restricted (unentitled) users. The top of the band is a
//  solid fill that matches the card colour exactly, so the join is seamless;
//  the lower edge tears away into transparency with a fibrous paper deckle.
//
//  The contour is generated deterministically from the current width, so it
//  spans any screen size with full coverage and never distorts, repeats, or
//  flickers across relayouts.
//

import UIKit

final class TornPaperEdgeView: UIView {

    /// Paper fill colour. Set to the card colour so the top edge is seamless.
    var fillColor: UIColor = .white {
        didSet { setNeedsDisplay() }
    }

    /// Total band height. The solid paper occupies roughly the top half, the
    /// jagged tear sweeps through the middle, and below it is transparent.
    static let preferredHeight: CGFloat = 44

    /// Vertical centre (fraction of height) the torn contour oscillates around.
    private let baselineFraction: CGFloat = 0.44
    /// Peak deviation of the coarse tear contour, in points.
    private let coarseAmplitude: CGFloat = 8.5
    /// Fine fibre jitter amplitude, in points.
    private let fineAmplitude: CGFloat = 1.75
    /// Horizontal sampling step for the contour, in points.
    private let sampleStep: CGFloat = 3
    /// Coarse noise node spacing, in points (controls tear "chunkiness").
    private let nodeSpacing: CGFloat = 36

    private var lastRenderedWidth: CGFloat = -1

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isUserInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if abs(bounds.width - lastRenderedWidth) > 0.5 {
            lastRenderedWidth = bounds.width
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard UIGraphicsGetCurrentContext() != nil,
              bounds.width > 1, bounds.height > 1 else { return }

        let width = bounds.width
        let height = bounds.height
        let baseY = height * baselineFraction

        // Deterministic per-width seed: the tear is stable across relayouts
        // (no flicker) yet differs if the device width changes.
        var rng = SeededGenerator(seed: UInt64(max(1, width.rounded())) &* 2654435761 &+ 1)

        // Coarse value-noise nodes, smoothly interpolated, plus fine jitter.
        let nodeCount = max(3, Int((width / nodeSpacing).rounded(.up)) + 1)
        let nodeValues = (0..<nodeCount).map { _ in CGFloat.random(in: -1...1, using: &rng) }

        func coarseNoise(at x: CGFloat) -> CGFloat {
            let t = (x / width) * CGFloat(nodeCount - 1)
            let i = min(nodeCount - 2, max(0, Int(t)))
            let frac = t - CGFloat(i)
            let s = frac * frac * (3 - 2 * frac) // smoothstep
            return nodeValues[i] + (nodeValues[i + 1] - nodeValues[i]) * s
        }

        // Build the tear contour left -> right.
        var contour: [CGPoint] = []
        var x: CGFloat = 0
        while x < width {
            let jitter = CGFloat.random(in: -1...1, using: &rng) * fineAmplitude
            contour.append(CGPoint(x: x, y: baseY + coarseNoise(at: x) * coarseAmplitude + jitter))
            x += sampleStep
        }
        let endJitter = CGFloat.random(in: -1...1, using: &rng) * fineAmplitude
        contour.append(CGPoint(x: width, y: baseY + coarseNoise(at: width) * coarseAmplitude + endJitter))

        // Solid paper: top rectangle down to the torn contour.
        let paper = UIBezierPath()
        paper.move(to: CGPoint(x: 0, y: 0))
        paper.addLine(to: CGPoint(x: 0, y: contour[0].y))
        for point in contour { paper.addLine(to: point) }
        paper.addLine(to: CGPoint(x: width, y: 0))
        paper.close()

        fillColor.setFill()
        paper.fill()

        drawDeckle(along: contour, rng: &rng)
    }

    /// A lighter lip following the tear plus a scatter of fine fibres hanging
    /// past it, giving the edge a real torn-paper read rather than a clean cut.
    private func drawDeckle(along contour: [CGPoint], rng: inout SeededGenerator) {
        guard contour.count > 1 else { return }

        let lip = UIBezierPath()
        lip.move(to: contour[0])
        for point in contour { lip.addLine(to: point) }
        deckleColor(lighten: true).setStroke()
        lip.lineWidth = 0.8
        lip.lineJoinStyle = .round
        lip.stroke()

        deckleColor(lighten: false).setStroke()
        for point in contour {
            guard Bool.random(using: &rng) else { continue }
            let length = CGFloat.random(in: 0.75...2.5, using: &rng)
            let drift = CGFloat.random(in: -0.5...0.5, using: &rng)
            let fibre = UIBezierPath()
            fibre.move(to: point)
            fibre.addLine(to: CGPoint(x: point.x + drift, y: point.y + length))
            fibre.lineWidth = CGFloat.random(in: 0.4...0.9, using: &rng)
            fibre.lineCapStyle = .round
            fibre.stroke()
        }
    }

    /// A slightly lighter or darker tint of the fill for fibre detail.
    private func deckleColor(lighten: Bool) -> UIColor {
        var white: CGFloat = 1, alpha: CGFloat = 1
        if fillColor.getWhite(&white, alpha: &alpha) {
            let adjusted = lighten ? min(1, white + 0.06) : max(0, white - 0.10)
            return UIColor(white: adjusted, alpha: lighten ? 0.9 : 0.5)
        }
        return fillColor
    }
}

/// Deterministic SplitMix64 PRNG, so the torn contour is stable per width.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// A container that lets touches in its empty areas fall through to views
/// behind it, while still delivering touches to its interactive subviews.
/// Only `UIControl` instances (buttons) capture hits — labels and stack
/// views stay transparent to scrolling.
final class PassthroughContainerView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else { return nil }
        guard bounds.contains(point) else { return nil }
        return deepestControl(at: point, in: self, with: event)
    }

    private func deepestControl(at point: CGPoint, in view: UIView, with event: UIEvent?) -> UIControl? {
        for subview in view.subviews.reversed() {
            let local = view.convert(point, to: subview)
            guard subview.point(inside: local, with: event) else { continue }
            if let nested = deepestControl(at: local, in: subview, with: event) {
                return nested
            }
            if let control = subview as? UIControl, control.isUserInteractionEnabled {
                return control
            }
        }
        return nil
    }
}
