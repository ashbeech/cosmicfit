//
//  EssenceTriangleView.swift
//  Cosmic Fit
//
//  Selective 14-axis radar chart displaying the top 3 style-essence
//  categories for the day. Each vertex sits at the category's fixed
//  angle on the full radar, at a distance proportional to its score.
//

import UIKit

/// Renders the daily style-essence radar: a dotted-line triangle whose
/// vertices are the top-3 scoring categories, with branded star icons
/// at each vertex and adaptively-placed labels.
final class EssenceTriangleView: UIView {

    // MARK: - Properties

    private var profile: StyleEssenceProfile?

    private let triangleLayer = CAShapeLayer()
    private let guideLayer = CAShapeLayer()
    /// Branded div-star asset (same as Style Guide / menu dividers), not a geometric diamond.
    private let vertexStarViews: [UIImageView] = (0..<3).map { _ in UIImageView() }
    private var categoryLabels: [UILabel] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    func configure(with profile: StyleEssenceProfile) {
        self.profile = profile
        rebuildLabels()
        setNeedsLayout()
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
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.strokeColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.12).cgColor
        guideLayer.lineWidth = 0.5
        guideLayer.lineDashPattern = [1, 2]
        layer.addSublayer(guideLayer)

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
        categoryLabels = []

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
    }

    // MARK: - Drawing

    private func drawChart() {
        guard let visible = profile?.visibleCategories, visible.count == 3 else {
            triangleLayer.path = nil
            guideLayer.path = nil
            vertexStarViews.forEach { $0.isHidden = true }
            return
        }

        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        let labelInset: CGFloat = 28
        let maxRadius = min(bounds.width, bounds.height) / 2.0 - labelInset
        let minRadiusFraction = 0.25

        let guidePath = UIBezierPath()
        for entry in visible {
            let angle = CGFloat(entry.category.angle)
            let edgeX = centre.x + cos(angle) * maxRadius
            let edgeY = centre.y + sin(angle) * maxRadius
            guidePath.move(to: centre)
            guidePath.addLine(to: CGPoint(x: edgeX, y: edgeY))
        }
        guideLayer.path = guidePath.cgPath
        guideLayer.frame = bounds

        let maxScore = visible.map(\.score).max() ?? 1.0
        let scaleFactor = maxScore > 0 ? 1.0 / maxScore : 1.0

        var points: [CGPoint] = []
        for (index, entry) in visible.enumerated() {
            let angle = CGFloat(entry.category.angle)
            let normalised = entry.score * scaleFactor
            let clampedNorm = max(CGFloat(normalised), CGFloat(minRadiusFraction))
            let radius = clampedNorm * maxRadius
            let px = centre.x + cos(angle) * radius
            let py = centre.y + sin(angle) * radius
            points.append(CGPoint(x: px, y: py))

            let starSize: CGFloat = 20
            let star = vertexStarViews[index]
            star.bounds = CGRect(x: 0, y: 0, width: starSize, height: starSize)
            star.center = CGPoint(x: px, y: py)
            star.isHidden = false
        }

        let triPath = UIBezierPath()
        triPath.move(to: points[0])
        for i in 1..<points.count {
            triPath.addLine(to: points[i])
        }
        triPath.close()
        triangleLayer.path = triPath.cgPath
        triangleLayer.frame = bounds

        positionLabels(visible: visible, points: points, centre: centre, maxRadius: maxRadius)
    }

    // MARK: - Adaptive Label Placement

    /// Places each label by evaluating candidate positions around its star
    /// vertex and choosing the one that avoids triangle edges, guide spokes,
    /// star icons, other labels, and the view bounds.
    private func positionLabels(
        visible: [StyleEssenceScore],
        points: [CGPoint],
        centre: CGPoint,
        maxRadius: CGFloat
    ) {
        guard points.count == 3 else { return }

        let centroid = CGPoint(
            x: (points[0].x + points[1].x + points[2].x) / 3.0,
            y: (points[0].y + points[1].y + points[2].y) / 3.0
        )

        let starHalf: CGFloat = 10
        let padding: CGFloat = 6
        let lineBuffer: CGFloat = 4

        let segments: [(CGPoint, CGPoint)] = [
            (points[0], points[1]),
            (points[1], points[2]),
            (points[2], points[0]),
            (centre, points[0]),
            (centre, points[1]),
            (centre, points[2])
        ]

        let starSize: CGFloat = 20
        let starRects = points.map { p in
            CGRect(x: p.x - starSize / 2, y: p.y - starSize / 2,
                   width: starSize, height: starSize)
        }

        let candidateCount = 24
        let step = (2 * CGFloat.pi) / CGFloat(candidateCount)
        var placedRects: [CGRect] = []

        for (index, _) in visible.enumerated() where index < categoryLabels.count {
            let label = categoryLabels[index]
            label.sizeToFit()

            let point = points[index]
            let halfW = label.bounds.width / 2
            let halfH = label.bounds.height / 2

            var outDx = point.x - centroid.x
            var outDy = point.y - centroid.y
            let outLen = hypot(outDx, outDy)
            if outLen > 0.001 { outDx /= outLen; outDy /= outLen }
            let preferredAngle = atan2(outDy, outDx)

            var bestCenter = CGPoint(x: point.x + outDx * (starHalf + padding + halfW),
                                     y: point.y + outDy * (starHalf + padding + halfH))
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
                let candidateRect = CGRect(x: cx - halfW, y: cy - halfH,
                                           width: halfW * 2, height: halfH * 2)

                var penalty: CGFloat = 0

                if candidateRect.minX < 2 || candidateRect.maxX > bounds.width - 2 ||
                   candidateRect.minY < 2 || candidateRect.maxY > bounds.height - 2 {
                    penalty += 10000
                }

                for sr in starRects where candidateRect.intersects(sr) {
                    penalty += 500
                }

                let inflated = candidateRect.insetBy(dx: -lineBuffer, dy: -lineBuffer)
                for seg in segments where Self.rectIntersectsSegment(inflated, seg.0, seg.1) {
                    penalty += 200
                }

                let labelBuffer = candidateRect.insetBy(dx: -3, dy: -3)
                for pr in placedRects where labelBuffer.intersects(pr) {
                    penalty += 300
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

            placedRects.append(CGRect(x: lx - halfW, y: ly - halfH,
                                      width: halfW * 2, height: halfH * 2))
        }
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

    private func normaliseAngle(_ a: CGFloat) -> CGFloat {
        var result = a.truncatingRemainder(dividingBy: 2 * .pi)
        if result < 0 { result += 2 * .pi }
        return result
    }

}
