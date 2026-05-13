//
//  DailyColourPaletteView.swift
//  Cosmic Fit
//
//  Three daily colour swatches in a horizontal row (Style Guide swatch style).
//  Tapping a swatch expands a panel above the row (same interaction language as
//  `ColourPaletteView` in the Style Guide palette) showing the colour name, with
//  room to add more detail later.
//

import UIKit

final class DailyColourPaletteView: UIView {

    // MARK: - Constants

    private let swatchCornerRadius: CGFloat = 4
    private let swatchSpacing: CGFloat = 6
    private let expansionToSwatchGap: CGFloat = 6
    private let expansionRowCount: CGFloat = 2
    private let animDuration: TimeInterval = 0.4

    // MARK: - Data

    private var picks: [DailyColourPick] = []

    private var focusedIndex: Int?

    // MARK: - Subviews

    private let expansionContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        v.backgroundColor = .clear
        return v
    }()

    private let expansionPanel: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        return v
    }()

    private let expansionLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(
            size: CosmicFitTheme.Typography.FontSizes.sectionHeader
        )
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private var swatchViews: [UIView] = []
    private var expansionCollapsedConstraint: NSLayoutConstraint!
    private var expansionExpandedConstraint: NSLayoutConstraint!

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
        picks = Array(dailyPicks.prefix(3))
        focusedIndex = nil
        applyPickColors()
        setExpansionVisible(animated: false)
    }

    // MARK: - Private Setup

    private func setupUI() {
        addSubview(expansionContainer)
        expansionContainer.addSubview(expansionPanel)
        expansionPanel.addSubview(expansionLabel)
        expansionPanel.layer.cornerRadius = swatchCornerRadius

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(onExpansionPanelTap))
        expansionPanel.addGestureRecognizer(dismissTap)

        NSLayoutConstraint.activate([
            expansionPanel.topAnchor.constraint(equalTo: expansionContainer.topAnchor),
            expansionPanel.leadingAnchor.constraint(equalTo: expansionContainer.leadingAnchor),
            expansionPanel.trailingAnchor.constraint(equalTo: expansionContainer.trailingAnchor),
            expansionPanel.bottomAnchor.constraint(equalTo: expansionContainer.bottomAnchor),

            expansionLabel.centerXAnchor.constraint(equalTo: expansionPanel.centerXAnchor),
            expansionLabel.centerYAnchor.constraint(equalTo: expansionPanel.centerYAnchor),
            expansionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: expansionPanel.leadingAnchor, constant: 16),
            expansionLabel.trailingAnchor.constraint(lessThanOrEqualTo: expansionPanel.trailingAnchor, constant: -16),
        ])

        for _ in 0..<3 {
            let swatch = UIView()
            swatch.translatesAutoresizingMaskIntoConstraints = false
            swatch.layer.cornerRadius = swatchCornerRadius
            swatch.clipsToBounds = true
            swatch.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
            swatch.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(onSwatchTap(_:)))
            swatch.addGestureRecognizer(tap)
            addSubview(swatch)
            swatchViews.append(swatch)
        }

        let s0 = swatchViews[0]
        let s1 = swatchViews[1]
        let s2 = swatchViews[2]

        expansionCollapsedConstraint = expansionContainer.heightAnchor.constraint(equalToConstant: 0)
        expansionExpandedConstraint = expansionContainer.heightAnchor.constraint(
            equalTo: s0.heightAnchor,
            multiplier: expansionRowCount,
            constant: CGFloat(max(Int(expansionRowCount) - 1, 0)) * swatchSpacing
        )
        expansionCollapsedConstraint.isActive = true

        NSLayoutConstraint.activate([
            expansionContainer.topAnchor.constraint(equalTo: topAnchor),
            expansionContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            expansionContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            s0.topAnchor.constraint(equalTo: expansionContainer.bottomAnchor, constant: expansionToSwatchGap),
            s0.leadingAnchor.constraint(equalTo: leadingAnchor),
            s0.heightAnchor.constraint(equalTo: s0.widthAnchor),

            s1.topAnchor.constraint(equalTo: expansionContainer.bottomAnchor, constant: expansionToSwatchGap),
            s1.leadingAnchor.constraint(equalTo: s0.trailingAnchor, constant: swatchSpacing),
            s1.widthAnchor.constraint(equalTo: s0.widthAnchor),
            s1.heightAnchor.constraint(equalTo: s0.heightAnchor),

            s2.topAnchor.constraint(equalTo: expansionContainer.bottomAnchor, constant: expansionToSwatchGap),
            s2.leadingAnchor.constraint(equalTo: s1.trailingAnchor, constant: swatchSpacing),
            s2.widthAnchor.constraint(equalTo: s0.widthAnchor),
            s2.heightAnchor.constraint(equalTo: s0.heightAnchor),
            s2.trailingAnchor.constraint(equalTo: trailingAnchor),

            bottomAnchor.constraint(equalTo: s0.bottomAnchor),
        ])

        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
        accessibilityContainerType = .semanticGroup
        accessibilityLabel = "Daily style palette"
    }

    private func applyPickColors() {
        for (index, swatch) in swatchViews.enumerated() {
            if index < picks.count, let c = UIColor(hex: picks[index].hexValue) {
                swatch.backgroundColor = c
                swatch.isUserInteractionEnabled = true
                swatch.accessibilityLabel = picks[index].name
                swatch.isAccessibilityElement = true
            } else {
                swatch.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
                swatch.isUserInteractionEnabled = false
                swatch.accessibilityLabel = nil
                swatch.isAccessibilityElement = false
            }
        }
    }

    @objc private func onSwatchTap(_ g: UITapGestureRecognizer) {
        guard let v = g.view, let idx = swatchViews.firstIndex(of: v) else { return }
        guard idx < picks.count else { return }

        if focusedIndex == idx {
            focusedIndex = nil
        } else {
            focusedIndex = idx
        }
        setExpansionVisible(animated: true)
    }

    @objc private func onExpansionPanelTap() {
        focusedIndex = nil
        setExpansionVisible(animated: true)
    }

    private func setExpansionVisible(animated: Bool) {
        let expanded = focusedIndex.map { $0 < picks.count } ?? false

        guard bounds.width > 0 else {
            expansionCollapsedConstraint.isActive = true
            expansionExpandedConstraint.isActive = false
            expansionPanel.alpha = 0
            expansionPanel.accessibilityElementsHidden = true
            return
        }

        let wasExpanded = expansionExpandedConstraint.isActive

        if expanded, let fi = focusedIndex, fi < picks.count {
            let pick = picks[fi]
            expansionPanel.backgroundColor = UIColor(hex: pick.hexValue) ?? .gray
            expansionLabel.text = pick.name.localizedCapitalized
            expansionLabel.textColor = Self.contrastingTextColor(forHex: pick.hexValue)
            expansionCollapsedConstraint.isActive = false
            expansionExpandedConstraint.isActive = true
            expansionPanel.accessibilityElementsHidden = false
        } else {
            expansionExpandedConstraint.isActive = false
            expansionCollapsedConstraint.isActive = true
            expansionPanel.accessibilityElementsHidden = true
        }

        let openingAnimated = animated && expanded && !wasExpanded
        if openingAnimated {
            expansionPanel.alpha = 0
        }

        let updates = {
            self.expansionPanel.alpha = expanded ? 1 : 0
            self.superview?.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: animDuration,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
    }

    private static func contrastingTextColor(forHex hex: String) -> UIColor {
        guard let c = UIColor(hex: hex) else { return .white }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.5 ? .black : .white
    }
}
