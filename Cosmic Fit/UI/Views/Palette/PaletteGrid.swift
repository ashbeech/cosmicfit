//
//  PaletteGrid.swift
//  Cosmic Fit
//
//  Pure-data 5×12 display matrix for the Personal Palette grid.
//  V4 layout: 4 neutral + 4 core + 4 accent rows.
//
//  Foundation-only, hex-string-based. No UIKit. The business-logic layer
//  (the view-model that builds this from a `PaletteSection`) must never
//  reach for `UIColor`.
//

import Foundation

/// The 5-column × 12-row matrix rendered by `ColourPaletteView`.
///
/// Rows 0–3 are the neutral band (4 neutral anchors × 5 tonal cells).
/// Rows 4–7 are the core band (4 core anchors × 5 tonal cells).
/// Rows 8–11 are the accent band (4 accent anchors × 5 tonal cells).
///
/// Rows without an anchor are represented as empty rows of empty cells,
/// not nil, so the rendered 5×12 silhouette stays stable regardless of
/// content.
struct PaletteGrid: Equatable {

    /// Exactly 12 rows, each exactly 5 cells.
    let rows: [PaletteRow]

    /// If true, rows with no anchor are hidden and the view's intrinsic
    /// height shrinks accordingly.
    var hidesEmptyRows: Bool

    static let columnCount: Int = 5
    static let rowCount: Int = 12
    static let neutralRowCount: Int = 4
    static let coreRowCount: Int = 4
    static let accentRowCount: Int = 4

    init(rows: [PaletteRow], hidesEmptyRows: Bool = false) {
        self.rows = rows
        self.hidesEmptyRows = hidesEmptyRows
    }

    /// Count of rows whose anchor is non-nil.
    var nonEmptyRowCount: Int {
        rows.filter { $0.anchorHex != nil }.count
    }
}

/// A single row of the grid — one anchor family expanded to 5 display cells,
/// or a structurally empty row when no anchor is available for the slot.
struct PaletteRow: Equatable {
    let role: ColourRole            // .neutral, .core, or .accent (engine enum; UI introduces no parallel type)
    let anchorName: String?         // nil for empty / padded rows
    let anchorHex: String?          // nil for empty / padded rows
    let cells: [PaletteCell]        // exactly `PaletteGrid.columnCount` cells
}

/// A single cell — either filled with a hex colour or an empty slot rendered
/// at 8% neutral opacity by the view (§4.3).
struct PaletteCell: Equatable {
    enum Kind: Equatable {
        case filled(hex: String)
        case empty
    }
    let kind: Kind
    /// 0 = lightest, 4 = darkest. Stable across filled and empty cells so
    /// accessibility labels can still describe the slot role if needed later.
    let toneIndex: Int
}
