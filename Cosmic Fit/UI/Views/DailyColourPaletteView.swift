//
//  DailyColourPaletteView.swift
//  Cosmic Fit
//
//  Single daily colour swatch spanning the content width. Height matches
//  the former three-up square swatches (width ÷ 3). The colour name is
//  always centred on the swatch.
//

import UIKit

final class DailyColourPaletteView: UIView {

    // MARK: - Constants

    private let swatchCornerRadius: CGFloat = 4
    /// Matches the square swatch height when three equal squares fit in one row.
    private let swatchHeightToWidthRatio: CGFloat = 1.0 / 3.0

    // MARK: - Data

    private var pick: DailyColourPick?

    // MARK: - Subviews

    private let swatchView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        return v
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(
            size: CosmicFitTheme.Typography.FontSizes.sectionHeader
        )
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.75
        return lbl
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Configuration

    func configure(dailyPicks: [DailyColourPick], allPaletteHexes _: [String]) {
        pick = dailyPicks.first
        applyPick()
    }

    // MARK: - Private Setup

    private func setupUI() {
        swatchView.layer.cornerRadius = swatchCornerRadius
        addSubview(swatchView)
        swatchView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            swatchView.topAnchor.constraint(equalTo: topAnchor),
            swatchView.leadingAnchor.constraint(equalTo: leadingAnchor),
            swatchView.trailingAnchor.constraint(equalTo: trailingAnchor),
            swatchView.bottomAnchor.constraint(equalTo: bottomAnchor),
            swatchView.heightAnchor.constraint(
                equalTo: swatchView.widthAnchor,
                multiplier: swatchHeightToWidthRatio
            ),

            nameLabel.centerXAnchor.constraint(equalTo: swatchView.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: swatchView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: swatchView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: swatchView.trailingAnchor, constant: -16),
        ])

        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
        accessibilityContainerType = .semanticGroup
        accessibilityLabel = "Daily style palette"
    }

    private func applyPick() {
        guard let pick, let colour = UIColor(hex: pick.hexValue) else {
            swatchView.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
            nameLabel.text = nil
            nameLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
            swatchView.isAccessibilityElement = false
            swatchView.accessibilityLabel = nil
            return
        }

        swatchView.backgroundColor = colour
        nameLabel.text = pick.name.localizedCapitalized
        nameLabel.textColor = Self.contrastingTextColor(forHex: pick.hexValue)
        swatchView.isAccessibilityElement = true
        swatchView.accessibilityLabel = pick.name
    }

    private static func contrastingTextColor(forHex hex: String) -> UIColor {
        guard let c = UIColor(hex: hex) else { return .white }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.5 ? .black : .white
    }
}
