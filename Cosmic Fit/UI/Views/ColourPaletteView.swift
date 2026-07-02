import UIKit

final class ColourPaletteView: UIView {

    // MARK: - Constants

    private let cellSpacing: CGFloat = 6
    private let sectionSpacing: CGFloat = 24
    private let headerHeight: CGFloat = 30
    private let headerGridSpacing: CGFloat = 14
    private let columnCount: Int = 4
    private let expansionRows: Int = 2
    private let swatchCornerRadius: CGFloat = 4
    private let animDuration: TimeInterval = 0.4

    // MARK: - Focus state

    private struct FocusLocation: Equatable {
        let section: Int
        let cell: Int
    }

    private var swatchFocus: FocusLocation?

    // MARK: - Data

    private var grid: PaletteGrid?
    private var sections: [PaletteGrid.Section] = []

    // MARK: - Per-section UI bookkeeping

    private final class SectionUI {
        let container: UIView
        let heightConstraint: NSLayoutConstraint
        let cells: [PaletteCell]
        var swatches: [UIView] = []
        var focusOverlay: UIView?
        var focusLabel: UILabel?

        init(container: UIView, heightConstraint: NSLayoutConstraint, cells: [PaletteCell]) {
            self.container = container
            self.heightConstraint = heightConstraint
            self.cells = cells
        }
    }

    private var sectionUIs: [SectionUI] = []

    // MARK: - Outer stack

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.alignment = .fill
        s.distribution = .fill
        return s
    }()

    // MARK: - Initialisation

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear

        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        isAccessibilityElement = false
        accessibilityLabel = "Personal palette"
        shouldGroupAccessibilityChildren = true
        accessibilityContainerType = .semanticGroup
    }

    private var swatchInteractionEnabled = true

    // MARK: - Public API

    func configure(with grid: PaletteGrid) {
        self.grid = grid
        swatchFocus = nil
        rebuildAllSections()
    }

    /// When `false`, swatch taps and focus expansion are disabled (e.g. gated paywall).
    func setSwatchInteractionEnabled(_ enabled: Bool) {
        guard swatchInteractionEnabled != enabled else { return }
        swatchInteractionEnabled = enabled
        if !enabled {
            dismissFocus()
        }
        isUserInteractionEnabled = enabled
        applySwatchInteractionState()
    }

    private func applySwatchInteractionState() {
        for sui in sectionUIs {
            for (index, swatch) in sui.swatches.enumerated() {
                if case .filled = sui.cells[index].kind {
                    swatch.isUserInteractionEnabled = swatchInteractionEnabled
                }
            }
            sui.focusOverlay?.isUserInteractionEnabled = swatchInteractionEnabled
        }
    }


    func dismissFocus() {
        guard swatchFocus != nil else { return }
        swatchFocus = nil
        relayout(animated: true)
    }

    // MARK: - Layout

    private var lastWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        guard w > 0, w != lastWidth else { return }
        lastWidth = w
        relayout(animated: false)
    }

    override var intrinsicContentSize: CGSize {
        let w = bounds.width
        guard w > 0, !sections.isEmpty else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        var total: CGFloat = 0
        for (i, section) in sections.enumerated() {
            if i > 0 { total += sectionSpacing }
            total += headerHeight + headerGridSpacing
            total += gridHeight(section, sectionIndex: i, width: w)
        }
        return CGSize(width: w, height: total)
    }

    // MARK: - Rebuild all sections

    private func rebuildAllSections() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sectionUIs.removeAll()

        sections = grid?.sections ?? []

        for (idx, section) in sections.enumerated() {
            if idx > 0 {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.heightAnchor.constraint(equalToConstant: sectionSpacing).isActive = true
                stack.addArrangedSubview(spacer)
            }

            let header = createSubheadingWithDividers(text: section.title)
            stack.addArrangedSubview(header)

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.clipsToBounds = false
            let hc = container.heightAnchor.constraint(equalToConstant: 0)
            hc.isActive = true
            stack.addArrangedSubview(container)
            stack.setCustomSpacing(headerGridSpacing, after: header)

            let sui = SectionUI(container: container, heightConstraint: hc, cells: section.cells)
            createSwatchViews(sui: sui, sectionIndex: idx)
            sectionUIs.append(sui)
        }

        applySwatchInteractionState()
        lastWidth = 0
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    // MARK: - Swatch view creation

    private func createSwatchViews(sui: SectionUI, sectionIndex: Int) {
        for (cellIdx, cell) in sui.cells.enumerated() {
            let v = UIView()
            v.layer.cornerRadius = swatchCornerRadius
            v.clipsToBounds = true
            switch cell.kind {
            case .filled(let hex, let name):
                v.backgroundColor = UIColor(hex: hex) ?? .gray
                v.isUserInteractionEnabled = true
                v.accessibilityLabel = name
                v.isAccessibilityElement = true
                let tap = SwatchTap(target: self, action: #selector(onSwatchTap(_:)))
                tap.sec = sectionIndex
                tap.idx = cellIdx
                v.addGestureRecognizer(tap)
            case .empty:
                v.backgroundColor = UIColor.label.withAlphaComponent(0.08)
                v.isUserInteractionEnabled = false
                v.isAccessibilityElement = false
            }
            sui.container.addSubview(v)
            sui.swatches.append(v)
        }
    }

    // MARK: - Tap handling

    @objc private func onSwatchTap(_ g: SwatchTap) {
        guard swatchInteractionEnabled else { return }
        let loc = FocusLocation(section: g.sec, cell: g.idx)
        swatchFocus = (swatchFocus == loc) ? nil : loc
        relayout(animated: true)
    }

    @objc private func onInfoPanelTap() {
        swatchFocus = nil
        relayout(animated: true)
    }

    // MARK: - Relayout

    private func relayout(animated: Bool) {
        let w = bounds.width
        guard w > 0 else { return }
        let cs = cellSize(for: w)

        for (si, sui) in sectionUIs.enumerated() {
            let fci = (swatchFocus?.section == si) ? swatchFocus?.cell : nil
            let h = gridHeight(sections[si], sectionIndex: si, width: w)

            if let fc = fci {
                ensureFocusOverlay(sui: sui, cellIndex: fc)
            }

            if animated {
                if sui.focusOverlay != nil, fci != nil {
                    sui.focusOverlay?.alpha = 0
                }

                UIView.animate(
                    withDuration: animDuration, delay: 0,
                    usingSpringWithDamping: 0.85, initialSpringVelocity: 0,
                    options: [.curveEaseInOut, .beginFromCurrentState],
                    animations: {
                        self.positionSwatches(sui: sui, swatchFocusCell: fci, cs: cs, w: w)
                        sui.heightConstraint.constant = h
                        sui.focusOverlay?.alpha = fci != nil ? 1 : 0
                        self.superview?.layoutIfNeeded()
                    },
                    completion: { _ in
                        if fci == nil {
                            sui.focusOverlay?.removeFromSuperview()
                            sui.focusOverlay = nil
                            sui.focusLabel = nil
                        }
                    }
                )
            } else {
                positionSwatches(sui: sui, swatchFocusCell: fci, cs: cs, w: w)
                sui.heightConstraint.constant = h
                if fci == nil {
                    sui.focusOverlay?.removeFromSuperview()
                    sui.focusOverlay = nil
                    sui.focusLabel = nil
                } else {
                    sui.focusOverlay?.alpha = 1
                }
            }
        }

        invalidateIntrinsicContentSize()
    }

    // MARK: - Swatch positioning

    private func positionSwatches(sui: SectionUI, swatchFocusCell: Int?, cs: CGFloat, w: CGFloat) {
        guard let fc = swatchFocusCell else {
            positionSwatchesNormal(sui: sui, cs: cs)
            return
        }
        positionSwatchesFocused(sui: sui, swatchFocusIndex: fc, cs: cs, w: w)
    }

    private func positionSwatchesNormal(sui: SectionUI, cs: CGFloat) {
        sui.focusOverlay?.isHidden = true
        for (i, v) in sui.swatches.enumerated() {
            v.isHidden = false
            let col = i % columnCount
            let row = i / columnCount
            v.frame = CGRect(
                x: CGFloat(col) * (cs + cellSpacing),
                y: CGFloat(row) * (cs + cellSpacing),
                width: cs, height: cs
            )
        }
    }

    private func positionSwatchesFocused(sui: SectionUI, swatchFocusIndex: Int, cs: CGFloat, w: CGFloat) {
        var before: [UIView] = []
        var after: [UIView] = []

        for (i, v) in sui.swatches.enumerated() {
            guard case .filled = sui.cells[i].kind else {
                v.isHidden = true
                continue
            }
            if i == swatchFocusIndex {
                v.isHidden = true
                continue
            }
            v.isHidden = false
            if i < swatchFocusIndex { before.append(v) }
            else { after.append(v) }
        }

        let aboveCount = (before.count / columnCount) * columnCount
        let overflow = Array(before[aboveCount...])
        let above = Array(before[..<aboveCount])
        let below = overflow + after

        let aboveRows = aboveCount / columnCount
        let expH = CGFloat(expansionRows) * cs + CGFloat(expansionRows - 1) * cellSpacing
        let expY = CGFloat(aboveRows) * (cs + cellSpacing)

        for (i, v) in above.enumerated() {
            let col = i % columnCount
            let row = i / columnCount
            v.frame = CGRect(
                x: CGFloat(col) * (cs + cellSpacing),
                y: CGFloat(row) * (cs + cellSpacing),
                width: cs, height: cs
            )
        }

        if let overlay = sui.focusOverlay {
            overlay.isHidden = false
            overlay.frame = CGRect(x: 0, y: expY, width: w, height: expH)
        }

        let belowStartRow = aboveRows + expansionRows
        for (j, v) in below.enumerated() {
            let col = j % columnCount
            let row = belowStartRow + j / columnCount
            v.frame = CGRect(
                x: CGFloat(col) * (cs + cellSpacing),
                y: CGFloat(row) * (cs + cellSpacing),
                width: cs, height: cs
            )
        }
    }

    // MARK: - Focus overlay

    private func ensureFocusOverlay(sui: SectionUI, cellIndex: Int) {
        guard case .filled(let hex, let name) = sui.cells[cellIndex].kind else { return }

        if sui.focusOverlay == nil {
            let overlay = UIView()
            overlay.layer.cornerRadius = swatchCornerRadius
            overlay.clipsToBounds = true
            overlay.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(onInfoPanelTap))
            overlay.addGestureRecognizer(tap)

            let lbl = UILabel()
            lbl.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(
                size: CosmicFitTheme.Typography.FontSizes.sectionHeader
            )
            lbl.textAlignment = .center
            lbl.numberOfLines = 0
            lbl.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview(lbl)

            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
                lbl.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 16),
                lbl.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -16),
            ])

            sui.container.addSubview(overlay)
            sui.focusOverlay = overlay
            sui.focusLabel = lbl
        }

        sui.focusOverlay?.backgroundColor = UIColor(hex: hex) ?? .gray
        sui.focusLabel?.text = name.localizedCapitalized
        sui.focusLabel?.textColor = Self.contrastingTextColor(forHex: hex)
    }

    // MARK: - Grid height calculation

    private func gridHeight(_ section: PaletteGrid.Section, sectionIndex: Int, width: CGFloat) -> CGFloat {
        let cs = cellSize(for: width)

        if let f = swatchFocus, f.section == sectionIndex {
            let filledBefore = section.cells[..<f.cell]
                .filter { if case .filled = $0.kind { return true }; return false }.count
            let filledAfter: Int
            if f.cell + 1 < section.cells.count {
                filledAfter = section.cells[(f.cell + 1)...]
                    .filter { if case .filled = $0.kind { return true }; return false }.count
            } else {
                filledAfter = 0
            }
            let aboveCount = (filledBefore / columnCount) * columnCount
            let overflowCount = filledBefore - aboveCount
            let aboveRows = aboveCount / columnCount
            let belowTotal = overflowCount + filledAfter
            let belowRows = belowTotal > 0 ? Int(ceil(Double(belowTotal) / Double(columnCount))) : 0
            let totalRows = aboveRows + expansionRows + belowRows
            return CGFloat(totalRows) * cs + CGFloat(max(totalRows - 1, 0)) * cellSpacing
        }

        let rows = ceil(CGFloat(section.cells.count) / CGFloat(columnCount))
        return rows * cs + max(rows - 1, 0) * cellSpacing
    }

    private func cellSize(for width: CGFloat) -> CGFloat {
        (width - cellSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    // MARK: - Contrast helper

    private static func contrastingTextColor(forHex hex: String) -> UIColor {
        guard let c = UIColor(hex: hex) else { return .white }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.5 ? .black : .white
    }

    // MARK: - Section header (centred text with divider lines)

    private func createSubheadingWithDividers(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let leftDivider = UIView()
        leftDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        leftDivider.translatesAutoresizingMaskIntoConstraints = false

        let rightDivider = UIView()
        rightDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        rightDivider.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = CosmicFitTheme.Typography.dmSerifTextDisplayItalicFont(size: 19)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(leftDivider)
        container.addSubview(rightDivider)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: headerHeight),

            leftDivider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            leftDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftDivider.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12),
            leftDivider.heightAnchor.constraint(equalToConstant: 1),

            rightDivider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            rightDivider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightDivider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightDivider.heightAnchor.constraint(equalToConstant: 1),

            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }

    // MARK: - Placeholder factory

    static func placeholder() -> PaletteGrid {
        let provenance: ColourProvenance = .v4Template(family: "Deep Autumn", band: "placeholder", index: 0)
        let neutral: [BlueprintColour] = [
            BlueprintColour(name: "warm ivory",  hexValue: "#F5EDE0", role: .neutral, provenance: provenance),
            BlueprintColour(name: "camel sand",  hexValue: "#C4A775", role: .neutral, provenance: provenance),
            BlueprintColour(name: "warm stone",  hexValue: "#8C7A6B", role: .neutral, provenance: provenance),
            BlueprintColour(name: "espresso",    hexValue: "#3C2415", role: .neutral, provenance: provenance),
        ]
        let core: [BlueprintColour] = [
            BlueprintColour(name: "sage",    hexValue: "#7AA18C", role: .core, provenance: provenance),
            BlueprintColour(name: "caramel", hexValue: "#B08254", role: .core, provenance: provenance),
            BlueprintColour(name: "slate",   hexValue: "#4B5A6E", role: .core, provenance: provenance),
            BlueprintColour(name: "cream",   hexValue: "#E8DCC4", role: .core, provenance: provenance),
        ]
        let accent: [BlueprintColour] = [
            BlueprintColour(name: "saffron",       hexValue: "#D4A23C", role: .accent, provenance: provenance),
            BlueprintColour(name: "dusty rose",    hexValue: "#C97D7D", role: .accent, provenance: provenance),
            BlueprintColour(name: "teal",          hexValue: "#3C7A85", role: .accent, provenance: provenance),
            BlueprintColour(name: "midnight blue", hexValue: "#1F2A44", role: .accent, provenance: provenance),
        ]
        let support: [BlueprintColour] = [
            BlueprintColour(name: "ink navy",       hexValue: "#1B2A4A", role: .support, provenance: provenance),
            BlueprintColour(name: "cool charcoal",  hexValue: "#3B3F42", role: .support, provenance: provenance),
            BlueprintColour(name: "slate",          hexValue: "#5B6770", role: .support, provenance: provenance),
            BlueprintColour(name: "midnight olive", hexValue: "#2F3A2B", role: .support, provenance: provenance),
        ]
        let lightAnchor = BlueprintColour(
            name: "warm cream", hexValue: "#F2E8D4", role: .anchor, provenance: provenance
        )
        let deepAnchor = BlueprintColour(
            name: "ink brown", hexValue: "#2B1E15", role: .anchor, provenance: provenance
        )
        let lumHex = "#8A3A16"
        let rulHex = "#6B4C1E"
        var claimedForSignatures = Set<String>()
        for row in [neutral, core, accent, support].flatMap({ $0 }) {
            claimedForSignatures.insert(row.name.lowercased())
        }
        claimedForSignatures.insert(lightAnchor.name.lowercased())
        claimedForSignatures.insert(deepAnchor.name.lowercased())
        let sigLabels = PaletteLibrary.signaturePairLabels(
            luminaryHex: lumHex,
            rulerHex: rulHex,
            claimedTemplateNames: claimedForSignatures
        )
        let luminarySignature = BlueprintColour(
            name: sigLabels.luminary,
            hexValue: lumHex,
            role: .signature,
            provenance: provenance,
            semanticLabel: "luminary signature"
        )
        let rulerSignature = BlueprintColour(
            name: sigLabels.ruler,
            hexValue: rulHex,
            role: .signature,
            provenance: provenance,
            semanticLabel: "ruler signature"
        )
        let section = PaletteSection(
            neutrals: neutral,
            coreColours: core,
            accentColours: accent,
            supportColours: support,
            lightAnchor: lightAnchor,
            deepAnchor: deepAnchor,
            luminarySignature: luminarySignature,
            rulerSignature: rulerSignature,
            family: .deepAutumn,
            cluster: .deepWarmStructured,
            variables: DerivedVariables(
                depth: .deep, temperature: .warm, saturation: .rich,
                contrast: .medium, surface: .structured
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: ""
        )
        return PaletteGridViewModel.build(from: section)
    }
}

// MARK: - Custom tap gesture carrying section + cell indices

private final class SwatchTap: UITapGestureRecognizer {
    var sec: Int = 0
    var idx: Int = 0
}
