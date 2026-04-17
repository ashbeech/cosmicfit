//
//  PaletteGrid.swift
//  Cosmic Fit
//
//  Pure-data 5×8 display matrix for the Personal Palette grid.
//  See `docs/palette_grid_spec_v1.md` §4 and §7.1.
//
//  Foundation-only, hex-string-based. No UIKit. The business-logic layer
//  (the view-model that builds this from a `PaletteSection`) must never
//  reach for `UIColor`.
//

import Foundation

/// The 5-column × 8-row matrix rendered by `ColourPaletteView`.
///
/// Rows 0–3 are the core band (up to 4 core anchors × 5 tonal cells).
/// Rows 4–7 are the accent band (up to 4 accent anchors × 5 tonal cells).
///
/// Rows without an anchor are represented as empty rows of empty cells,
/// not nil, so the rendered 5×8 silhouette stays stable regardless of
/// content (see §4.3 of the spec).
struct PaletteGrid: Equatable {

    /// Exactly 8 rows, each exactly 5 cells.
    let rows: [PaletteRow]

    /// If true, rows with no anchor are hidden and the view's intrinsic
    /// height shrinks accordingly. Default: false (the locked §8 decision).
    /// Implemented as a stored property so the call site can flip it later
    /// without a model change.
    var hidesEmptyRows: Bool

    static let columnCount: Int = 5
    static let rowCount: Int = 8
    static let coreRowCount: Int = 4

    init(rows: [PaletteRow], hidesEmptyRows: Bool = false) {
        self.rows = rows
        self.hidesEmptyRows = hidesEmptyRows
    }

    /// Count of rows whose anchor is non-nil. Used for intrinsic height
    /// calculation when `hidesEmptyRows` is true.
    var nonEmptyRowCount: Int {
        rows.filter { $0.anchorHex != nil }.count
    }
}

/// A single row of the grid — one anchor family expanded to 5 display cells,
/// or a structurally empty row when no anchor is available for the slot.
struct PaletteRow: Equatable {
    let role: ColourRole            // .core or .accent (engine's enum — UI does not introduce a parallel type)
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
