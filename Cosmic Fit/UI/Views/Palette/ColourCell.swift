//
//  ColourCell.swift
//  Cosmic Fit
//
//  Extracted from the former inner class in `ColourPaletteView.swift`
//  (pre-refactor lines 108–144). See `docs/palette_grid_spec_v1.md` §7.4.
//
//  Adds two configuration entry points:
//   • `configure(withHex:)` for cells driven by an engine-derived hex.
//   • `configureEmpty()`   for faint padded slots at 8% neutral opacity
//     (see §4.3).
//
//  Decorative-only — no tap gestures in v1 (§4.4).
//

import UIKit

final class ColourCell: UICollectionViewCell {

    static let reuseIdentifier = "ColourCell"

    private let colourView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(colourView)
        colourView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colourView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colourView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colourView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colourView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    func configure(withHex hex: String) {
        colourView.backgroundColor = UIColor(hex: hex) ?? .gray
        colourView.alpha = 1.0
    }

    func configureEmpty() {
        colourView.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        colourView.alpha = 1.0
    }
}

// MARK: - UIColor hex helper (local, no 3rd-party dependency)

extension UIColor {

    /// Minimal hex initialiser used by the palette grid cells. Accepts
    /// `#RRGGBB` or `RRGGBB`; returns `nil` for anything else so call sites
    /// can fall back to a neutral tone deterministically.
    convenience init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else {
            return nil
        }
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
