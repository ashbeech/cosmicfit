//
//  CosmicNavigationArrow.swift
//  Cosmic Fit
//
//  Left/right navigation arrows: a vertical half of the Daily Fit
//  silhouette/vibrancy/contrast slider diamond glyph (`♦`), filled and
//  tintable. Right arrows use the diamond's right half, left arrows use
//  the left half. Visually identical to halving the diamond markers on
//  the Daily Fit scale sliders so the navigation arrows feel like part
//  of the same vocabulary as the rest of the screen's iconography.
//

import UIKit

enum CosmicNavigationArrow {

    enum Direction {
        case left
        case right
    }

    /// Glyph used for the full diamond. The renderer clips it down to
    /// the requested half. `♦` (U+2666 BLACK DIAMOND SUIT) is the same
    /// character used by `styleDiamondScaleIndicator` on the Daily Fit
    /// scale markers, which is what keeps the arrow shape locked to
    /// those sliders without us having to re-author a vector path.
    private static let diamondGlyph = "♦"

    /// Applied to all rendered arrow sizes (25% larger than the nominal
    /// `pointSize`). Preserves the established visual weight of the
    /// previous half-star arrow at each callsite so the API behaves the
    /// same despite the shape change.
    private static let sizeMultiplier: CGFloat = 1.25

    /// Renders a filled, template, half-diamond at the given height.
    /// `pointSize` is the nominal target arrow height; the underlying
    /// glyph is drawn slightly larger (see `sizeMultiplier`) so the
    /// arrow keeps a presence beside its button title.
    static func image(direction: Direction, pointSize: CGFloat) -> UIImage {
        let glyphPointSize = pointSize * sizeMultiplier

        // Foreground colour is irrelevant — `.alwaysTemplate` below
        // discards RGB and uses only the alpha channel as a mask that
        // gets tinted to the button's `baseForegroundColor` at draw
        // time. Drawing in black keeps the intermediate bitmap simple.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: glyphPointSize),
            .foregroundColor: UIColor.black
        ]
        let attributed = NSAttributedString(string: diamondGlyph, attributes: attributes)

        let glyphSize = attributed.size()
        let fullWidth = ceil(glyphSize.width)
        let fullHeight = ceil(glyphSize.height)
        let halfWidth = ceil(fullWidth / 2.0)
        let outputSize = CGSize(width: halfWidth, height: fullHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        let image = renderer.image { _ in
            // Draw the full glyph, then let the bitmap's bounds clip
            // away whichever half we don't want.
            let drawOrigin: CGPoint
            switch direction {
            case .left:
                drawOrigin = .zero
            case .right:
                drawOrigin = CGPoint(x: -halfWidth, y: 0)
            }
            attributed.draw(at: drawOrigin)
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
