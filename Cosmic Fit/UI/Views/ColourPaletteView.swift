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
//     (rows 5–8) bands — implemented as section 1's top inset.
//   • Cells are square, corner radius 4 pt, inter-cell spacing 2 pt.
//   • No labels (§4.2), no tap (§4.4), scroll disabled (parent scroll view
//     owns vertical scroll).
//   • Empty anchor slots render as `ColourCell.configureEmpty()`
//     (UIColor.label at 8% alpha).
//
//  API surface (§8):
//   • `init()`                                — empty grid.
//   • `configure(with: PaletteGrid)`          — set content.
//   • `static placeholder() -> PaletteGrid`   — deterministic demo grid
//     for previews, onboarding, and the current Style Guide call site
//     (until P5 live wiring lands).
//

import UIKit

final class ColourPaletteView: UIView {

    // MARK: - Constants

    private let cellSpacing: CGFloat = 2

    /// Index of the first row that belongs to the accent band. Kept aligned
    /// with `PaletteGrid.coreRowCount` so layout and data source agree.
    private let accentBandStartRow: Int = PaletteGrid.coreRowCount

    // MARK: - State

    private var grid: PaletteGrid?

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

        accessibilityLabel = "Personal palette"
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
        guard width > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }

        let coreRows = visibleRowCount(in: coreRowRange)
        let accentRows = visibleRowCount(in: accentRowRange)

        // Both bands always render — an empty band contributes zero height
        // and no gap (see §4.3 / §8). If hidesEmptyRows is true AND the
        // accent band is empty, we drop the band gap too.
        let cellSize = calculateCellSize(width: width)
        let rowsPerSection = max(coreRows, 0) + max(accentRows, 0)
        guard rowsPerSection > 0 else {
            return CGSize(width: width, height: 0)
        }

        let coreSectionHeight: CGFloat = coreRows > 0
            ? cellSize * CGFloat(coreRows) + cellSpacing * CGFloat(max(coreRows - 1, 0))
            : 0
        let accentSectionHeight: CGFloat = accentRows > 0
            ? cellSize * CGFloat(accentRows) + cellSpacing * CGFloat(max(accentRows - 1, 0))
            : 0

        // Band gap: 1× row height between the bands. Only contributes if
        // both bands have any visible rows.
        let bandGap: CGFloat = (coreRows > 0 && accentRows > 0) ? cellSize : 0

        let height = coreSectionHeight + bandGap + accentSectionHeight
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

    private var coreRowRange: Range<Int> { 0..<accentBandStartRow }
    private var accentRowRange: Range<Int> { accentBandStartRow..<PaletteGrid.rowCount }

    /// Count of rows in the given range that should be laid out given the
    /// grid's content and its `hidesEmptyRows` flag.
    private func visibleRowCount(in range: Range<Int>) -> Int {
        guard let grid = grid else { return 0 }
        let slice = grid.rows[range]
        if grid.hidesEmptyRows {
            return slice.filter { $0.anchorHex != nil }.count
        }
        return slice.count
    }

    private func calculateCellSize(width: CGFloat) -> CGFloat {
        let columns = PaletteGrid.columnCount
        let totalSpacing = cellSpacing * CGFloat(columns - 1)
        return (width - totalSpacing) / CGFloat(columns)
    }

    /// Returns the grid row index for (section, item), accounting for
    /// `hidesEmptyRows`. Section 0 = core band, section 1 = accent band.
    private func gridRowIndex(for indexPath: IndexPath) -> Int? {
        guard let grid = grid else { return nil }
        let range = indexPath.section == 0 ? coreRowRange : accentRowRange
        let slice = grid.rows[range]
        let visibleRows: [(offset: Int, row: PaletteRow)] = slice.enumerated().compactMap { offset, row in
            if grid.hidesEmptyRows && row.anchorHex == nil { return nil }
            return (offset, row)
        }
        guard indexPath.item / PaletteGrid.columnCount < visibleRows.count else { return nil }
        let visibleIndex = indexPath.item / PaletteGrid.columnCount
        return range.lowerBound + visibleRows[visibleIndex].offset
    }
}

// MARK: - UICollectionViewDataSource

extension ColourPaletteView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return grid == nil ? 0 : 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let range = section == 0 ? coreRowRange : accentRowRange
        return visibleRowCount(in: range) * PaletteGrid.columnCount
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColourCell.reuseIdentifier,
                for: indexPath
            ) as? ColourCell,
            let grid = grid,
            let rowIndex = gridRowIndex(for: indexPath)
        else {
            return UICollectionViewCell()
        }

        let row = grid.rows[rowIndex]
        let columnIndex = indexPath.item % PaletteGrid.columnCount
        let paletteCell = row.cells[columnIndex]

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
        // Inject the 1× row-height band separator ahead of the accent band,
        // but only if the core band actually rendered any rows. This keeps
        // the intrinsicContentSize math honest when hidesEmptyRows is true
        // and one band ends up empty.
        guard section == 1 else { return .zero }
        guard visibleRowCount(in: coreRowRange) > 0,
              visibleRowCount(in: accentRowRange) > 0 else { return .zero }
        let cellSize = calculateCellSize(width: collectionView.bounds.width)
        return UIEdgeInsets(top: cellSize, left: 0, bottom: 0, right: 0)
    }
}
