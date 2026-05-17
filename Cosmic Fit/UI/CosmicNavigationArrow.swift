//
//  CosmicNavigationArrow.swift
//  Cosmic Fit
//
//  Left/right navigation arrows: a vertical half of the brand div-star (`star_icon_placeholder`),
//  filled and tintable. Right arrows use the star’s right half (mirror of the left).
//

import UIKit

enum CosmicNavigationArrow {

    enum Direction {
        case left
        case right
    }

    private static let starImageName = "star_icon_placeholder"

    /// Applied to all rendered arrow sizes (25% larger than the nominal `pointSize`).
    private static let sizeMultiplier: CGFloat = 1.25

    /// Squash on Y so the half-star tips are less tall (25% shorter).
    private static let verticalCompression: CGFloat = 0.75

    /// Renders a filled template half-star at the given height.
    static func image(direction: Direction, pointSize: CGFloat) -> UIImage {
        guard let star = UIImage(named: starImageName) else {
            assertionFailure("Missing asset: \(starImageName)")
            return UIImage()
        }

        let naturalHeight = pointSize * sizeMultiplier
        let outputHeight = naturalHeight * verticalCompression
        let fullWidth = naturalHeight * (star.size.width / star.size.height)
        let halfWidth = fullWidth / 2
        let outputSize = CGSize(width: halfWidth, height: outputHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        let image = renderer.image { context in
            let cg = context.cgContext
            cg.translateBy(x: 0, y: outputHeight)
            cg.scaleBy(x: 1, y: -verticalCompression)

            let drawRect: CGRect
            switch direction {
            case .left:
                drawRect = CGRect(x: 0, y: 0, width: fullWidth, height: naturalHeight)
            case .right:
                drawRect = CGRect(x: -halfWidth, y: 0, width: fullWidth, height: naturalHeight)
            }
            star.withRenderingMode(.alwaysTemplate).draw(in: drawRect)
        }

        return image.withRenderingMode(.alwaysTemplate)
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
