//
//  EssenceTriangleView.swift
//  Cosmic Fit
//
//  Selective 14-axis radar chart displaying the top 3 style-essence
//  categories for the day. Each vertex sits at the category's fixed
//  angle on the full radar, at a distance proportional to its score.
//

import UIKit

/// Renders the daily style-essence radar: weather triangle (solid) with optional
/// chart-anchor ghost layer (dashed) on stage-1 experimental days.
final class EssenceTriangleView: UIView {

    // MARK: - Properties

    private var profile: StyleEssenceProfile?
    private var presentation: EssencePresentationDirective?

    private let triangleLayer = CAShapeLayer()
    private let anchorTriangleLayer = CAShapeLayer()
    /// Branded div-star asset (same as Style Guide / menu dividers), not a geometric diamond.
    private let vertexStarViews: [UIImageView] = (0..<3).map { _ in UIImageView() }
    private var categoryLabels: [UILabel] = []
    private var anchorGhostLabels: [(label: UILabel, entry: StyleEssenceScore)] = []

    /// Side length (points) of each vertex's star asset. Single source
    /// of truth — `drawChart` sizes the imageView with this, and
    /// `positionLabels` feeds the same value into the label avoidance
    /// geometry so labels never crash into the star artwork. Edit
    /// here to shrink/grow stars without touching layout code.
    private static let vertexStarSize: CGFloat = 14

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    func configure(with profile: StyleEssenceProfile, presentation: EssencePresentationDirective? = nil) {
        self.profile = profile
        self.presentation = presentation
        rebuildLabels()
        setNeedsLayout()
    }

    @available(*, deprecated, message: "Use configure(with:presentation:)")
    func configure(with profile: StyleEssenceProfile) {
        configure(with: profile, presentation: nil)
    }

    @available(*, deprecated, message: "Use configure(with: StyleEssenceProfile)")
    func configure(with _: EssenceTriangle) {}

    // MARK: - Layout

    override var intrinsicContentSize: CGSize {
        CGSize(width: 220, height: 220)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        drawChart()
    }

    // MARK: - Setup

    private func setupLayers() {
        anchorTriangleLayer.fillColor = UIColor.clear.cgColor
        anchorTriangleLayer.strokeColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.15).cgColor
        anchorTriangleLayer.lineWidth = 1.0
        anchorTriangleLayer.lineDashPattern = [3, 4]
        layer.addSublayer(anchorTriangleLayer)

        triangleLayer.fillColor = UIColor.clear.cgColor
        triangleLayer.strokeColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5).cgColor
        triangleLayer.lineWidth = 1.0
        triangleLayer.lineDashPattern = [2, 3]
        layer.addSublayer(triangleLayer)

        let starImage = UIImage(named: "star_icon_placeholder")?.withRenderingMode(.alwaysTemplate)
        for star in vertexStarViews {
            star.image = starImage
            star.tintColor = CosmicFitTheme.Colours.cosmicBlue
            star.contentMode = .scaleAspectFit
            star.isHidden = true
            star.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(star, at: 0)
        }
    }

    private func rebuildLabels() {
        categoryLabels.forEach { $0.removeFromSuperview() }
        anchorGhostLabels.map(\.label).forEach { $0.removeFromSuperview() }
        categoryLabels = []
        anchorGhostLabels = []

        guard let visible = profile?.visibleCategories else { return }
        for entry in visible {
            let label = UILabel()
            label.font = CosmicFitTheme.Typography.dmSansFont(
                size: CosmicFitTheme.Typography.FontSizes.caption1,
                weight: .medium
            )
            label.textColor = CosmicFitTheme.Colours.cosmicBlue
            label.textAlignment = .center
            label.attributedText = NSAttributedString(
                string: entry.category.label,
                attributes: [
                    .kern: 1.2 as CGFloat,
                    .font: label.font!,
                    .foregroundColor: label.textColor!
                ]
            )
            addSubview(label)
            categoryLabels.append(label)
        }

        for entry in anchorGhostEntries(excludingWeather: visible) {
            let ghostSize = CosmicFitTheme.Typography.FontSizes.caption1 - 2
            let label = UILabel()
            label.font = CosmicFitTheme.Typography.dmSansFont(size: ghostSize, weight: .medium)
            label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.35)
            label.textAlignment = .center
            label.attributedText = NSAttributedString(
                string: entry.category.label,
                attributes: [
                    .kern: 1.0 as CGFloat,
                    .font: label.font!,
                    .foregroundColor: label.textColor!
                ]
            )
            addSubview(label)
            anchorGhostLabels.append((label: label, entry: entry))
        }
    }

    private func anchorTop3Entries() -> [StyleEssenceScore] {
        guard let anchorScores = profile?.chartAnchorScores else { return [] }
        return Array(anchorScores.sorted { $0.score > $1.score }.prefix(3))
    }

    private func anchorGhostEntries(excludingWeather weather: [StyleEssenceScore]) -> [StyleEssenceScore] {
        guard presentation?.showAnchorGhost == true else { return [] }
        let weatherCategories = Set(weather.map(\.category))
        return anchorTop3Entries().filter { !weatherCategories.contains($0.category) }
    }

    /// Lowest normalised radius a vertex may have, so a weak-scoring category
    /// never collapses onto the centre and flattens the triangle.
    private static let minRadiusFraction: CGFloat = 0.25

    /// Reserved margin (points) around the chart so vertex stars and the
    /// outward-placed labels stay inside `bounds` after the fit.
    private static let chartMargin: CGFloat = 28

    /// A vertex in normalised radar space: origin-centred, radius `0...1`.
    /// Only the *shape* (relative angles + radii, which encode the data) lives
    /// here. Absolute position and on-screen size are resolved separately by
    /// `ChartFit`, so layout never depends on which categories happened to win.
    private func rawRadarPoint(for entry: StyleEssenceScore, scale: Double) -> CGPoint {
        let angle = CGFloat(entry.category.angle)
        let clampedNorm = max(CGFloat(entry.score * scale), Self.minRadiusFraction)
        return CGPoint(x: cos(angle) * clampedNorm, y: sin(angle) * clampedNorm)
    }

    /// Uniform similarity transform that maps a set of normalised-space points
    /// so their combined bounding box is centred in `targetRect` and scaled —
    /// preserving aspect ratio — to fill it.
    ///
    /// This is what guarantees the requested behaviour: the diagram is always
    /// centred regardless of triangle shape, and is enlarged to a consistent
    /// footprint whenever the day's categories cluster into a small or
    /// off-centre arrangement. Aspect ratio is preserved (single scale factor)
    /// so the triangle is never stretched/skewed; a genuinely thin spread of
    /// categories stays thin, but is still centred and as large as it can be.
    private struct ChartFit {
        let scale: CGFloat
        let sourceCentre: CGPoint
        let targetCentre: CGPoint

        func apply(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: (point.x - sourceCentre.x) * scale + targetCentre.x,
                y: (point.y - sourceCentre.y) * scale + targetCentre.y
            )
        }

        init(points: [CGPoint], targetRect: CGRect) {
            guard let first = points.first else {
                scale = 1
                sourceCentre = .zero
                targetCentre = CGPoint(x: targetRect.midX, y: targetRect.midY)
                return
            }
            var minX = first.x, maxX = first.x
            var minY = first.y, maxY = first.y
            for point in points {
                minX = min(minX, point.x); maxX = max(maxX, point.x)
                minY = min(minY, point.y); maxY = max(maxY, point.y)
            }
            // Guard against a degenerate (collinear) spread in either axis.
            let spanX = max(maxX - minX, 0.0001)
            let spanY = max(maxY - minY, 0.0001)
            scale = min(targetRect.width / spanX, targetRect.height / spanY)
            sourceCentre = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
            targetCentre = CGPoint(x: targetRect.midX, y: targetRect.midY)
        }
    }

    // MARK: - Drawing

    private func layoutShapeLayer(_ shapeLayer: CAShapeLayer, path: CGPath?) {
        shapeLayer.path = path
        guard bounds.width > 0, bounds.height > 0 else { return }
        shapeLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private func drawChart() {
        guard let visible = profile?.visibleCategories, visible.count == 3 else {
            layoutShapeLayer(triangleLayer, path: nil)
            layoutShapeLayer(anchorTriangleLayer, path: nil)
            vertexStarViews.forEach { $0.isHidden = true }
            return
        }

        let viewCentre = CGPoint(x: bounds.midX, y: bounds.midY)
        let targetRect = bounds.insetBy(dx: Self.chartMargin, dy: Self.chartMargin)

        // --- Shape in normalised space (independent of placement/size) ---
        let weatherMax = visible.map(\.score).max() ?? 1.0
        let weatherScale = weatherMax > 0 ? 1.0 / weatherMax : 1.0
        let weatherRaw = visible.map { rawRadarPoint(for: $0, scale: weatherScale) }

        let showGhost = presentation?.showAnchorGhost == true
        let anchorTop3 = showGhost ? anchorTop3Entries() : []
        let anchorMax = anchorTop3.map(\.score).max() ?? 1.0
        let anchorScale = anchorMax > 0 ? 1.0 / anchorMax : 1.0
        let anchorRaw = anchorTop3.map { rawRadarPoint(for: $0, scale: anchorScale) }

        let ghostEntries = showGhost ? anchorGhostEntries(excludingWeather: visible) : []
        let ghostRaw = ghostEntries.map { rawRadarPoint(for: $0, scale: anchorScale) }

        // --- Resolve placement + size once, for everything that will be drawn ---
        // All layers share a single fit so their relationship is preserved while
        // the whole composition is centred and scaled to fill the square.
        let fit = ChartFit(points: weatherRaw + anchorRaw + ghostRaw, targetRect: targetRect)
        let weatherPoints = weatherRaw.map(fit.apply)
        let anchorPoints = anchorRaw.map(fit.apply)
        let ghostPoints = ghostRaw.map(fit.apply)

        for (index, point) in weatherPoints.enumerated() {
            let star = vertexStarViews[index]
            star.bounds = CGRect(x: 0, y: 0, width: Self.vertexStarSize, height: Self.vertexStarSize)
            star.center = point
            star.isHidden = false
        }

        let triPath = UIBezierPath()
        triPath.move(to: weatherPoints[0])
        for i in 1..<weatherPoints.count {
            triPath.addLine(to: weatherPoints[i])
        }
        triPath.close()
        layoutShapeLayer(triangleLayer, path: triPath.cgPath)

        if anchorPoints.count == 3 {
            let anchorPath = UIBezierPath()
            anchorPath.move(to: anchorPoints[0])
            anchorPath.addLine(to: anchorPoints[1])
            anchorPath.addLine(to: anchorPoints[2])
            anchorPath.close()
            layoutShapeLayer(anchorTriangleLayer, path: anchorPath.cgPath)
        } else {
            layoutShapeLayer(anchorTriangleLayer, path: nil)
        }

        positionLabels(
            visible: visible,
            weatherPoints: weatherPoints,
            ghostEntries: ghostEntries,
            ghostPoints: ghostPoints,
            anchorPoints: anchorPoints.count == 3 ? anchorPoints : [],
            centre: viewCentre
        )
    }

    // MARK: - Adaptive Label Placement

    private func positionLabels(
        visible: [StyleEssenceScore],
        weatherPoints: [CGPoint],
        ghostEntries: [StyleEssenceScore],
        ghostPoints: [CGPoint],
        anchorPoints: [CGPoint],
        centre: CGPoint
    ) {
        guard weatherPoints.count == 3 else { return }

        let weatherCentroid = CGPoint(
            x: (weatherPoints[0].x + weatherPoints[1].x + weatherPoints[2].x) / 3.0,
            y: (weatherPoints[0].y + weatherPoints[1].y + weatherPoints[2].y) / 3.0
        )

        let starSize = Self.vertexStarSize
        let starHalf = starSize / 2
        let padding: CGFloat = 6
        let lineBuffer: CGFloat = 4

        var avoidanceSegments: [(CGPoint, CGPoint)] = [
            (weatherPoints[0], weatherPoints[1]),
            (weatherPoints[1], weatherPoints[2]),
            (weatherPoints[2], weatherPoints[0])
        ]
        if anchorPoints.count == 3 {
            avoidanceSegments.append(contentsOf: [
                (anchorPoints[0], anchorPoints[1]),
                (anchorPoints[1], anchorPoints[2]),
                (anchorPoints[2], anchorPoints[0])
            ])
        }

        let starRects = weatherPoints.map { point in
            CGRect(
                x: point.x - starSize / 2,
                y: point.y - starSize / 2,
                width: starSize,
                height: starSize
            )
        }

        var placedRects: [CGRect] = []

        for index in visible.indices where index < categoryLabels.count {
            let label = categoryLabels[index]
            let point = weatherPoints[index]
            let placedRect = placeLabel(
                label,
                atVertex: point,
                outwardFrom: weatherCentroid,
                starHalf: starHalf,
                padding: padding,
                lineBuffer: lineBuffer,
                segments: avoidanceSegments,
                starRects: starRects,
                placedRects: placedRects
            )
            placedRects.append(placedRect)
        }

        guard ghostEntries.count == ghostPoints.count,
              ghostEntries.count == anchorGhostLabels.count else { return }

        for (index, ghost) in anchorGhostLabels.enumerated() {
            guard ghost.entry.category == ghostEntries[index].category else { continue }
            let point = ghostPoints[index]
            let placedRect = placeLabel(
                ghost.label,
                atVertex: point,
                outwardFrom: centre,
                starHalf: 0,
                padding: padding,
                lineBuffer: lineBuffer,
                segments: avoidanceSegments,
                starRects: starRects,
                placedRects: placedRects
            )
            placedRects.append(placedRect)
        }
    }

    @discardableResult
    private func placeLabel(
        _ label: UILabel,
        atVertex point: CGPoint,
        outwardFrom reference: CGPoint,
        starHalf: CGFloat,
        padding: CGFloat,
        lineBuffer: CGFloat,
        segments: [(CGPoint, CGPoint)],
        starRects: [CGRect],
        placedRects: [CGRect]
    ) -> CGRect {
        label.sizeToFit()

        let halfW = label.bounds.width / 2
        let halfH = label.bounds.height / 2

        var outDx = point.x - reference.x
        var outDy = point.y - reference.y
        let outLen = hypot(outDx, outDy)
        if outLen > 0.001 { outDx /= outLen; outDy /= outLen }
        let preferredAngle = atan2(outDy, outDx)

        let candidateCount = 24
        let step = (2 * CGFloat.pi) / CGFloat(candidateCount)

        var bestCenter = CGPoint(
            x: point.x + outDx * (starHalf + padding + halfW),
            y: point.y + outDy * (starHalf + padding + halfH)
        )
        var bestPenalty: CGFloat = .greatestFiniteMagnitude

        for i in 0..<candidateCount {
            let angle = preferredAngle + CGFloat(i) * step
            let cosA = cos(angle)
            let sinA = sin(angle)
            let absCos = abs(cosA)
            let absSin = abs(sinA)

            let dFromX = absCos > 0.01
                ? (starHalf + halfW + padding) / absCos
                : CGFloat.greatestFiniteMagnitude
            let dFromY = absSin > 0.01
                ? (starHalf + halfH + padding) / absSin
                : CGFloat.greatestFiniteMagnitude
            let clearance = min(dFromX, dFromY)

            let cx = point.x + cosA * clearance
            let cy = point.y + sinA * clearance
            let candidateRect = CGRect(
                x: cx - halfW,
                y: cy - halfH,
                width: halfW * 2,
                height: halfH * 2
            )

            var penalty: CGFloat = 0

            if candidateRect.minX < 2 || candidateRect.maxX > bounds.width - 2 ||
               candidateRect.minY < 2 || candidateRect.maxY > bounds.height - 2 {
                penalty += 10000
            }

            for starRect in starRects where candidateRect.intersects(starRect) {
                penalty += 500
            }

            let inflated = candidateRect.insetBy(dx: -lineBuffer, dy: -lineBuffer)
            for segment in segments where Self.rectIntersectsSegment(inflated, segment.0, segment.1) {
                penalty += 200
            }

            let labelBuffer = candidateRect.insetBy(dx: -3, dy: -3)
            for placedRect in placedRects where labelBuffer.intersects(placedRect) {
                penalty += 800
            }

            let wrappedDiff = min(CGFloat(i) * step, 2 * .pi - CGFloat(i) * step)
            penalty += wrappedDiff * 10

            if penalty < bestPenalty {
                bestPenalty = penalty
                bestCenter = CGPoint(x: cx, y: cy)
            }
        }

        let lx = max(halfW + 2, min(bounds.width - halfW - 2, bestCenter.x))
        let ly = max(halfH + 2, min(bounds.height - halfH - 2, bestCenter.y))
        label.center = CGPoint(x: lx, y: ly)

        return CGRect(x: lx - halfW, y: ly - halfH, width: halfW * 2, height: halfH * 2)
    }

    // MARK: - Geometry Helpers

    private static func rectIntersectsSegment(_ rect: CGRect, _ a: CGPoint, _ b: CGPoint) -> Bool {
        if rect.contains(a) || rect.contains(b) { return true }
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]
        for i in 0..<4 {
            if segmentsIntersect(a, b, corners[i], corners[(i + 1) % 4]) { return true }
        }
        return false
    }

    private static func segmentsIntersect(
        _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint
    ) -> Bool {
        let d1 = cross(p3, p4, p1)
        let d2 = cross(p3, p4, p2)
        let d3 = cross(p1, p2, p3)
        let d4 = cross(p1, p2, p4)
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        if d1 == 0 && onSegment(p3, p4, p1) { return true }
        if d2 == 0 && onSegment(p3, p4, p2) { return true }
        if d3 == 0 && onSegment(p1, p2, p3) { return true }
        if d4 == 0 && onSegment(p1, p2, p4) { return true }
        return false
    }

    private static func cross(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }

    private static func onSegment(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Bool {
        min(a.x, b.x) <= c.x && c.x <= max(a.x, b.x) &&
        min(a.y, b.y) <= c.y && c.y <= max(a.y, b.y)
    }
}
