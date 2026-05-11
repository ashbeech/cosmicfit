//
//  DailyColourPaletteView.swift
//  Cosmic Fit
//
//  Displays 3 daily colour swatches in a horizontal row, matching the Style Guide swatch style.
//

import UIKit

final class DailyColourPaletteView: UIView {

    // MARK: - Properties

    private let swatchCornerRadius: CGFloat = 4
    private let swatchSpacing: CGFloat = 6
    private var swatchViews: [UIView] = []
    private var nameLabels: [UILabel] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Configuration

    func configure(dailyHexes: [String], allPaletteHexes: [String]) {
        let dailyUIColors = dailyHexes.compactMap { Self.uiColor(fromHex: $0) }
        for (index, swatch) in swatchViews.enumerated() {
            if index < dailyUIColors.count {
                swatch.backgroundColor = dailyUIColors[index]
            }
        }
    }

    private static func uiColor(fromHex hex: String) -> UIColor? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else { return nil }
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    // MARK: - Private Setup

    private func setupUI() {
        for _ in 0..<3 {
            let swatch = UIView()
            swatch.translatesAutoresizingMaskIntoConstraints = false
            swatch.layer.cornerRadius = swatchCornerRadius
            swatch.clipsToBounds = true
            swatch.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
            addSubview(swatch)
            swatchViews.append(swatch)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard swatchViews.count == 3 else { return }
        let s0 = swatchViews[0]
        let s1 = swatchViews[1]
        let s2 = swatchViews[2]

        NSLayoutConstraint.activate([
            s0.topAnchor.constraint(equalTo: topAnchor),
            s0.leadingAnchor.constraint(equalTo: leadingAnchor),
            s0.heightAnchor.constraint(equalTo: s0.widthAnchor),

            s1.topAnchor.constraint(equalTo: topAnchor),
            s1.leadingAnchor.constraint(equalTo: s0.trailingAnchor, constant: swatchSpacing),
            s1.widthAnchor.constraint(equalTo: s0.widthAnchor),
            s1.heightAnchor.constraint(equalTo: s0.heightAnchor),

            s2.topAnchor.constraint(equalTo: topAnchor),
            s2.leadingAnchor.constraint(equalTo: s1.trailingAnchor, constant: swatchSpacing),
            s2.widthAnchor.constraint(equalTo: s0.widthAnchor),
            s2.heightAnchor.constraint(equalTo: s0.heightAnchor),
            s2.trailingAnchor.constraint(equalTo: trailingAnchor),

            bottomAnchor.constraint(equalTo: s0.bottomAnchor)
        ])
    }
}
