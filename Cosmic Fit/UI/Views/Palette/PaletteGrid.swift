import Foundation

/// Two-section palette display: a main grid (neutrals + core + support +
/// anchors + signatures, Lab-chain sorted, 4 columns) and a separate
/// accent row (4 columns, template order). Each section carries a title
/// rendered as a centred-divider subheader by `ColourPaletteView`.
struct PaletteGrid: Equatable {

    struct Section: Equatable {
        let title: String
        let cells: [PaletteCell]
        let columnCount: Int
    }

    let sections: [Section]

    static let columnCount: Int = 4
}

struct PaletteCell: Equatable {
    enum Kind: Equatable {
        case filled(hex: String, anchorName: String)
        case empty
    }
    let kind: Kind
}
