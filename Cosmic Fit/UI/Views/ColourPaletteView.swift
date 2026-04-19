//
//  ColourPaletteView.swift
//  Cosmic Fit
//
//  Data-driven 5×12 personal palette grid (V4 layout).
//
//  Rendering rules:
//   • 5 columns × 12 rows (4 neutral + 4 core + 4 accent).
//   • Three bands render as one continuous grid with standard row spacing.
//   • Cells are square, corner radius 4 pt, inter-cell spacing 2 pt.
//   • No cell labels, no tap, scroll disabled (parent scroll view owns
//     vertical scroll).
//   • Empty anchor slots render as `ColourCell.configureEmpty()`
//     (UIColor.label at 8% alpha).
//
//  Layout:
//   • One UICollectionView section per grid row (12 sections total).
//   • The first visible row of each band carries a band title header
//     ("Neutral Colours" / "Core Colours" / "Accent Colours").
//   • When `showsDevelopmentAnchorNames` is true, every visible row
//     also shows its anchor family name and hex.
//

import UIKit

final class ColourPaletteView: UIView {

    // MARK: - Constants

    private let cellSpacing: CGFloat = 2

    /// Index of the first row that belongs to the core band.
    private let coreBandStartRow: Int = PaletteGrid.neutralRowCount
    /// Index of the first row that belongs to the accent band.
    private let accentBandStartRow: Int = PaletteGrid.neutralRowCount + PaletteGrid.coreRowCount

    /// Height reserved for a band title ("Core Colours" / "Accent Colours")
    /// above the first row of each band. Always present in production.
    private let bandTitleHeight: CGFloat = 30

    /// Height reserved for a development anchor-name label above each row
    /// when `showsDevelopmentAnchorNames` is true.
    private let devAnchorLabelHeight: CGFloat = 20

    // MARK: - State

    private var grid: PaletteGrid?

    /// Dev-only: render each row's anchor family name in a small label
    /// above the row of swatches. Default off — production UI per §4.2
    /// has no cell / row labels. Flip this on from a debug call site
    /// (ideally gated with `#if DEBUG`) to inspect which anchors were
    /// picked during development.
    var showsDevelopmentAnchorNames: Bool = false {
        didSet {
            guard oldValue != showsDevelopmentAnchorNames else { return }
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    // MARK: - UI

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.scrollDirection = .vertical

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.allowsSelection = false
        cv.register(ColourCell.self, forCellWithReuseIdentifier: ColourCell.reuseIdentifier)
        cv.register(
            PaletteSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PaletteSectionHeaderView.reuseIdentifier
        )
        return cv
    }()

    // MARK: - Initialisation

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        collectionView.delegate = self
        collectionView.dataSource = self

        isAccessibilityElement = false
        accessibilityLabel = "Personal palette"
        shouldGroupAccessibilityChildren = true
        accessibilityContainerType = .semanticGroup
    }

    // MARK: - Public API

    func configure(with grid: PaletteGrid) {
        self.grid = grid
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        invalidateIntrinsicContentSize()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let width = bounds.width
        guard width > 0, let grid = grid else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }

        let cellSize = calculateCellSize(width: width)

        var neutralVisibleRows = 0
        var coreVisibleRows = 0
        var accentVisibleRows = 0
        for (index, row) in grid.rows.enumerated() {
            guard isRowVisible(row, in: grid) else { continue }
            if index < coreBandStartRow {
                neutralVisibleRows += 1
            } else if index < accentBandStartRow {
                coreVisibleRows += 1
            } else {
                accentVisibleRows += 1
            }
        }

        let totalVisibleRows = neutralVisibleRows + coreVisibleRows + accentVisibleRows
        guard totalVisibleRows > 0 else {
            return CGSize(width: width, height: 0)
        }

        var height = cellSize * CGFloat(totalVisibleRows)

        if neutralVisibleRows > 0 { height += bandTitleHeight }
        if coreVisibleRows > 0 { height += bandTitleHeight }
        if accentVisibleRows > 0 { height += bandTitleHeight }

        // Dev anchor-name headers: one per visible row.
        if showsDevelopmentAnchorNames {
            height += CGFloat(totalVisibleRows) * devAnchorLabelHeight
        }

        // Row spacing between consecutive visible rows. Since the grid now
        // renders as a continuous stack (no special inter-band spacer), the
        // number of vertical row gaps is always (visibleRows - 1).
        height += CGFloat(max(totalVisibleRows - 1, 0)) * cellSpacing

        return CGSize(width: width, height: height)
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
        let section = PaletteSection(
            neutrals: neutral,
            coreColours: core,
            accentColours: accent,
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

    // MARK: - Private helpers

    private func isRowVisible(_ row: PaletteRow, in grid: PaletteGrid) -> Bool {
        if grid.hidesEmptyRows && row.anchorHex == nil { return false }
        return true
    }

    private func calculateCellSize(width: CGFloat) -> CGFloat {
        let columns = PaletteGrid.columnCount
        let totalSpacing = cellSpacing * CGFloat(columns - 1)
        return (width - totalSpacing) / CGFloat(columns)
    }

    private func firstVisibleRow(inRange range: Range<Int>) -> Int? {
        guard let grid = grid else { return nil }
        for index in range {
            if isRowVisible(grid.rows[index], in: grid) {
                return index
            }
        }
        return nil
    }

    /// Whether this section is the first visible row of its band.
    private func isBandLeader(_ section: Int) -> Bool {
        if section < coreBandStartRow {
            return firstVisibleRow(inRange: 0..<coreBandStartRow) == section
        } else if section < accentBandStartRow {
            return firstVisibleRow(inRange: coreBandStartRow..<accentBandStartRow) == section
        } else {
            return firstVisibleRow(inRange: accentBandStartRow..<PaletteGrid.rowCount) == section
        }
    }

    private func bandTitle(for section: Int) -> String? {
        guard isBandLeader(section) else { return nil }
        if section < coreBandStartRow { return "Neutral Colours" }
        if section < accentBandStartRow { return "Core Colours" }
        return "Accent Colours"
    }

    /// Total header height for a given section. Combines band title height
    /// (if this section leads its band) + dev anchor label height (if the
    /// dev flag is on).
    private func headerHeight(for section: Int) -> CGFloat {
        guard let grid = grid else { return 0 }
        let row = grid.rows[section]
        guard isRowVisible(row, in: grid) else { return 0 }

        var h: CGFloat = 0
        if isBandLeader(section) { h += bandTitleHeight }
        if showsDevelopmentAnchorNames { h += devAnchorLabelHeight }
        return h
    }
}

// MARK: - UICollectionViewDataSource

extension ColourPaletteView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return grid == nil ? 0 : PaletteGrid.rowCount
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let grid = grid else { return 0 }
        let row = grid.rows[section]
        return isRowVisible(row, in: grid) ? PaletteGrid.columnCount : 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColourCell.reuseIdentifier,
                for: indexPath
            ) as? ColourCell,
            let grid = grid
        else {
            return UICollectionViewCell()
        }

        let row = grid.rows[indexPath.section]
        let paletteCell = row.cells[indexPath.item]

        switch paletteCell.kind {
        case .filled(let hex):
            cell.configure(withHex: hex)
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = accessibilityLabel(for: row, toneIndex: paletteCell.toneIndex)
        case .empty:
            cell.configureEmpty()
            cell.isAccessibilityElement = false
            cell.accessibilityLabel = nil
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PaletteSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as? PaletteSectionHeaderView ?? PaletteSectionHeaderView()

        let title = bandTitle(for: indexPath.section)

        var anchorName: String? = nil
        var anchorHex: String? = nil
        if showsDevelopmentAnchorNames, let grid = grid {
            let row = grid.rows[indexPath.section]
            anchorName = row.anchorName
            anchorHex = row.anchorHex
        }

        header.configure(bandTitle: title, anchorName: anchorName, anchorHex: anchorHex)
        return header
    }

    private func accessibilityLabel(for row: PaletteRow, toneIndex: Int) -> String? {
        guard let name = row.anchorName else { return nil }
        return "\(name) \(Self.toneRoleName(for: toneIndex))"
    }

    private static func toneRoleName(for index: Int) -> String {
        switch index {
        case 0: return "lightest"
        case 1: return "light"
        case 2: return "true"
        case 3: return "dark"
        case 4: return "darkest"
        default: return "tone \(index)"
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ColourPaletteView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = calculateCellSize(width: collectionView.bounds.width)
        return CGSize(width: size, height: size)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let grid = grid else { return .zero }
        let row = grid.rows[section]
        guard isRowVisible(row, in: grid) else { return .zero }

        if section == 0 {
            return .zero
        }
        return UIEdgeInsets(top: cellSpacing, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        let h = headerHeight(for: section)
        guard h > 0 else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: h)
    }
}

// MARK: - Section header view
//
// Combined header that can show a band title ("Core Colours" /
// "Accent Colours") and/or a development anchor-name label. Band
// titles are production-visible; anchor names are dev-only.

private final class PaletteSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "PaletteSectionHeaderView"

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .leading
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let bandTitleLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.DMSerifTextItalicFont(
            size: CosmicFitTheme.Typography.FontSizes.sectionHeader
        )
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private let anchorNameLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote,
            weight: .regular
        )
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(stackView)
        stackView.addArrangedSubview(bandTitleLabel)
        stackView.addArrangedSubview(anchorNameLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])

        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(bandTitle: String?, anchorName: String?, anchorHex: String?) {
        if let title = bandTitle {
            bandTitleLabel.text = title
            bandTitleLabel.isHidden = false
        } else {
            bandTitleLabel.text = nil
            bandTitleLabel.isHidden = true
        }

        if let name = anchorName, !name.isEmpty {
            if let hex = anchorHex {
                anchorNameLabel.text = "\(name.uppercased())  \(hex)"
            } else {
                anchorNameLabel.text = name.uppercased()
            }
            anchorNameLabel.isHidden = false
        } else {
            anchorNameLabel.text = nil
            anchorNameLabel.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bandTitleLabel.text = nil
        bandTitleLabel.isHidden = true
        anchorNameLabel.text = nil
        anchorNameLabel.isHidden = true
    }
}
