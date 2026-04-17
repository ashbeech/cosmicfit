//
//  ColourPaletteView.swift
//  Cosmic Fit
//
//  Data-driven 5×8 personal palette grid. See
//  `docs/palette_grid_spec_v1.md` §5 / §7.1 / §8.
//
//  Rendering rules (locked, §4 / §8):
//   • 5 columns × 8 rows (4 core + 4 accent), fixed.
//   • 1× row-height band separator between core (rows 1–4) and accent
//     (rows 5–8) bands — implemented as the first accent section's top
//     inset.
//   • Cells are square, corner radius 4 pt, inter-cell spacing 2 pt.
//   • No production labels (§4.2), no tap (§4.4), scroll disabled (parent
//     scroll view owns vertical scroll).
//   • Empty anchor slots render as `ColourCell.configureEmpty()`
//     (UIColor.label at 8% alpha).
//
//  Layout implementation:
//   • One UICollectionView section per grid row (8 sections total). This
//     is deliberately finer-grained than a two-section core/accent split
//     so the optional development anchor-name label can sit natively in
//     `UICollectionView.elementKindSectionHeader` above each row without
//     reinventing layout code. When the dev flag is off, headers report
//     zero reference size and the section collapses to just the row of
//     cells — identical visually to a 2-section layout.
//
//  API surface (§8):
//   • `init()`                                — empty grid.
//   • `configure(with: PaletteGrid)`          — set content.
//   • `static placeholder() -> PaletteGrid`   — deterministic demo grid
//     for previews, onboarding, and the current Style Guide call site
//     (until P5 live wiring lands).
//   • `showsDevelopmentAnchorNames: Bool`     — dev-only aid that draws
//     the anchor family name above each row. NEVER enable in release
//     builds; §4.2 production rule is "no labels".
//

import UIKit

final class ColourPaletteView: UIView {

    // MARK: - Constants

    private let cellSpacing: CGFloat = 2

    /// Index of the first row that belongs to the accent band. Kept aligned
    /// with `PaletteGrid.coreRowCount` so layout and data source agree.
    private let accentBandStartRow: Int = PaletteGrid.coreRowCount

    /// Height reserved for a development anchor-name label above each row
    /// when `showsDevelopmentAnchorNames` is true. Small enough not to
    /// visibly dominate the swatches; generous enough for 10 pt semibold
    /// text with 2 pt top/bottom padding.
    private let devAnchorHeaderHeight: CGFloat = 18

    // MARK: - State

    private var grid: PaletteGrid?

    /// Dev-only: render each row's anchor family name in a small label
    /// above the row of swatches. Default off — production UI per §4.2
    /// has no cell / row labels. Flip this on from a debug call site
    /// (ideally gated with `#if DEBUG`) to inspect which anchors were
    /// picked during development.
    ///
    /// Flipping the flag invalidates layout and intrinsic size so the
    /// enclosing scroll view re-flows correctly.
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
            AnchorNameHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: AnchorNameHeaderView.reuseIdentifier
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

        // §9 — group the grid under a single labelled accessibility
        // container. `shouldGroupAccessibilityChildren` tells VoiceOver to
        // focus children before moving to siblings; `semanticGroup` plus
        // the label surfaces "Personal palette" as a rotor summary while
        // still allowing individual cells to be navigated (each filled
        // cell carries its own "{anchorName} {toneRole}" label — set in
        // the data source). The view itself must not be its own a11y
        // element, otherwise children would be hidden from VoiceOver.
        isAccessibilityElement = false
        accessibilityLabel = "Personal palette"
        shouldGroupAccessibilityChildren = true
        accessibilityContainerType = .semanticGroup
    }

    // MARK: - Public API

    /// Set the grid content. Triggers a data reload, layout invalidation,
    /// and `intrinsicContentSize` recalculation so the enclosing scroll
    /// view re-flows.
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

        var coreVisibleRows = 0
        var accentVisibleRows = 0
        for (index, row) in grid.rows.enumerated() {
            guard isRowVisible(row, in: grid) else { continue }
            if index < accentBandStartRow {
                coreVisibleRows += 1
            } else {
                accentVisibleRows += 1
            }
        }

        let totalVisibleRows = coreVisibleRows + accentVisibleRows
        guard totalVisibleRows > 0 else {
            return CGSize(width: width, height: 0)
        }

        // Cell rows.
        var height = cellSize * CGFloat(totalVisibleRows)

        // Dev headers: one per visible row when the flag is on.
        if showsDevelopmentAnchorNames {
            height += CGFloat(totalVisibleRows) * devAnchorHeaderHeight
        }

        // Intra-band spacing: between adjacent visible rows of the same band.
        height += CGFloat(max(coreVisibleRows - 1, 0)) * cellSpacing
        height += CGFloat(max(accentVisibleRows - 1, 0)) * cellSpacing

        // Band gap: 1× row height between bands, only if both bands have
        // visible content (matches §4.3 / §8 — no floating gap).
        if coreVisibleRows > 0 && accentVisibleRows > 0 {
            height += cellSize
        }

        return CGSize(width: width, height: height)
    }

    // MARK: - Placeholder factory

    /// Deterministic demo grid. Built from 4 made-up core + 4 accent anchors
    /// so the Style Guide screen renders a stable preview today — and
    /// previews / tests have a non-empty fixture — until live `PaletteSection`
    /// wiring lands (spec §8 / §10 P5).
    static func placeholder() -> PaletteGrid {
        let provenance: ColourProvenance = .libraryFallback(reason: "UI placeholder")
        let core: [BlueprintColour] = [
            BlueprintColour(name: "sage",    hexValue: "#7AA18C", role: .core, provenance: provenance),
            BlueprintColour(name: "caramel", hexValue: "#B08254", role: .core, provenance: provenance),
            BlueprintColour(name: "slate",   hexValue: "#4B5A6E", role: .core, provenance: provenance),
            BlueprintColour(name: "cream",   hexValue: "#E8DCC4", role: .core, provenance: provenance),
        ]
        let accent: [BlueprintColour] = [
            BlueprintColour(name: "saffron",      hexValue: "#D4A23C", role: .accent, provenance: provenance),
            BlueprintColour(name: "dusty rose",   hexValue: "#C97D7D", role: .accent, provenance: provenance),
            BlueprintColour(name: "teal",         hexValue: "#3C7A85", role: .accent, provenance: provenance),
            BlueprintColour(name: "midnight blue", hexValue: "#1F2A44", role: .accent, provenance: provenance),
        ]
        let section = PaletteSection(
            coreColours: core,
            accentColours: accent,
            swatchFamilies: [],
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

    /// First accent section index that will actually render cells — used to
    /// place the band-gap top inset on the correct section when
    /// `hidesEmptyRows` is true and the leading accent row(s) happen to be
    /// empty. Falls back to `accentBandStartRow` when nothing in the accent
    /// band is visible (inset won't be used in that case anyway).
    private var firstVisibleAccentSection: Int {
        guard let grid = grid else { return accentBandStartRow }
        for index in accentBandStartRow..<PaletteGrid.rowCount {
            if isRowVisible(grid.rows[index], in: grid) {
                return index
            }
        }
        return accentBandStartRow
    }

    private var hasAnyVisibleCoreRow: Bool {
        guard let grid = grid else { return false }
        return (0..<accentBandStartRow).contains { isRowVisible(grid.rows[$0], in: grid) }
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
            withReuseIdentifier: AnchorNameHeaderView.reuseIdentifier,
            for: indexPath
        ) as? AnchorNameHeaderView ?? AnchorNameHeaderView()

        if showsDevelopmentAnchorNames, let grid = grid {
            let row = grid.rows[indexPath.section]
            header.configure(name: row.anchorName, hex: row.anchorHex)
        } else {
            header.configure(name: nil, hex: nil)
        }
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

        let cellSize = calculateCellSize(width: collectionView.bounds.width)

        // First visible accent section: apply the 1× row-height band
        // separator, but only if there was any visible core row above.
        if section == firstVisibleAccentSection && hasAnyVisibleCoreRow {
            return UIEdgeInsets(top: cellSize, left: 0, bottom: 0, right: 0)
        }

        // Intra-band spacing between adjacent visible rows. First visible
        // row of the core band (section 0 when nothing is hidden) gets 0
        // — there is no preceding content to space away from.
        if section == 0 {
            return .zero
        }
        // For any row other than the first core row / first accent row,
        // insert cellSpacing of top inset so adjacent rows within the same
        // band sit `cellSpacing` apart. (Flow layout applies `insetForSection`
        // independently per section; the spacing between two adjacent
        // sections is the sum of the previous section's bottom inset plus
        // this section's top inset — previous bottom is 0 so this gives us
        // exactly cellSpacing between visible rows of the same band.)
        return UIEdgeInsets(top: cellSpacing, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard showsDevelopmentAnchorNames, let grid = grid else { return .zero }
        let row = grid.rows[section]
        guard isRowVisible(row, in: grid) else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: devAnchorHeaderHeight)
    }
}

// MARK: - Development anchor-name header
//
// Supplementary view that renders the anchor family name (and its hex)
// above a row. Used only when `ColourPaletteView.showsDevelopmentAnchorNames`
// is true; production builds never see it because the flag is `false` by
// default and should only be flipped inside `#if DEBUG`. Kept fileprivate
// so it can't be referenced from outside the view it belongs to.

private final class AnchorNameHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "AnchorNameHeaderView"

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String?, hex: String?) {
        guard let name = name, !name.isEmpty else {
            label.text = nil
            return
        }
        if let hex = hex {
            label.text = "\(name.uppercased())  \(hex)"
        } else {
            label.text = name.uppercased()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
}
