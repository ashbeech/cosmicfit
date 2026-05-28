//
//  CosmicNavigationArrow.swift
//  Cosmic Fit
//
//  Left/right navigation arrows: a filled, tintable chevron derived from
//  the supplied 85x145 arrow artwork. The right arrow mirrors the same
//  vector path so all solid nav arrows share one source shape.
//

import UIKit

enum CosmicNavigationArrow {

    enum Direction {
        case left
        case right
    }

    /// The original artwork is a left-facing arrow at 85x145 pixels.
    private static let sourceSize = CGSize(width: 85, height: 145)

    /// Applied to all rendered arrow sizes (25% larger than the nominal
    /// `pointSize`). Preserves the established visual weight of the
    /// previous arrow at each callsite so the API behaves the
    /// same despite the shape change.
    private static let sizeMultiplier: CGFloat = 1.25

    /// Renders a filled, template arrow at the given height.
    /// `pointSize` is the nominal target arrow height; the underlying
    /// path is drawn slightly larger (see `sizeMultiplier`) so the
    /// arrow keeps a presence beside its button title.
    static func image(direction: Direction, pointSize: CGFloat) -> UIImage {
        let outputHeight = ceil(pointSize * sizeMultiplier)
        let outputWidth = ceil(outputHeight * sourceSize.width / sourceSize.height)
        let outputSize = CGSize(width: outputWidth, height: outputHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        let image = renderer.image { _ in
            UIColor.black.setFill()
            path(in: CGRect(origin: .zero, size: outputSize), direction: direction).fill()
        }

        return image.withRenderingMode(.alwaysTemplate)
    }

    private static func path(in rect: CGRect, direction: Direction) -> UIBezierPath {
        let sourcePoints = [
            CGPoint(x: 76, y: 0),
            CGPoint(x: 85, y: 8.5),
            CGPoint(x: 17, y: 72.5),
            CGPoint(x: 85, y: 136.5),
            CGPoint(x: 76, y: 145),
            CGPoint(x: 0, y: 72.5)
        ]

        let points = sourcePoints.map { point in
            let sourceX = direction == .left ? point.x : sourceSize.width - point.x
            return CGPoint(
                x: rect.minX + (sourceX / sourceSize.width) * rect.width,
                y: rect.minY + (point.y / sourceSize.height) * rect.height
            )
        }

        let path = UIBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.close()
        return path
    }

    /// Applies title + leading/trailing cosmic arrow on a styled button (single-line title).
    static func apply(
        to button: UIButton,
        title: String,
        arrow: Direction,
        pointSize: CGFloat = 11,
        imagePadding: CGFloat = 6,
        font: UIFont = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote,
            weight: .medium
        )
    ) {
        var config = button.configuration ?? UIButton.Configuration.plain()
        var titleAttributes = AttributeContainer()
        titleAttributes.font = font
        config.attributedTitle = AttributedString(title, attributes: titleAttributes)
        config.image = image(direction: arrow, pointSize: pointSize)
        config.imagePlacement = arrow == .right ? .trailing : .leading
        config.imagePadding = imagePadding
        config.titleLineBreakMode = .byClipping
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.baseForegroundColor = button.titleColor(for: .normal) ?? CosmicFitTheme.Colours.cosmicBlue
        button.configuration = config
        button.titleLabel?.numberOfLines = 1
    }
}
