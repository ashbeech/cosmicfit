//
//  ColorPaletteView.swift
//  Cosmic Fit
//
//  Custom component for displaying color palette grid
//

import UIKit

final class ColorPaletteView: UIView {
    
    // MARK: - Properties
    private var colors: [[UIColor]] = []
    private let columns: Int = 5
    private let cellSpacing: CGFloat = 2
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
        return cv
    }()
    
    // MARK: - Initialization
    init(colors: [[UIColor]]) {
        self.colors = colors
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // Calculate and set height based on content
        let rows = colors.count
        let cellSize = calculateCellSize()
        let totalHeight = (cellSize * CGFloat(rows)) + (cellSpacing * CGFloat(rows - 1))
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: totalHeight)
        ])
    }
    
    private func calculateCellSize() -> CGFloat {
        // Get screen width minus padding (20px on each side)
        let screenWidth = UIScreen.main.bounds.width - 40
        let totalSpacing = cellSpacing * CGFloat(columns - 1)
        let cellWidth = (screenWidth - totalSpacing) / CGFloat(columns)
        return cellWidth
    }
}

// MARK: - UICollectionViewDataSource
extension ColorPaletteView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.reuseIdentifier, for: indexPath) as? ColorCell else {
            return UICollectionViewCell()
        }
        
        let color = colors[indexPath.section][indexPath.item]
        cell.configure(with: color)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ColorPaletteView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = calculateCellSize()
        return CGSize(width: size, height: size)
    }
}

// MARK: - ColorCell
final class ColorCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ColorCell"
    
    private let colorView: UIView = {
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
        contentView.addSubview(colorView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    func configure(with color: UIColor) {
        colorView.backgroundColor = color
    }
}

// MARK: - Placeholder Color Palette Generator
extension ColorPaletteView {
    
    /// Creates a placeholder color palette matching the design in the image
    static func createPlaceholderPalette() -> ColorPaletteView {
        // This is a placeholder palette matching the colors in the design
        // Later this will be generated dynamically from user's chart data
        let palette: [[UIColor]] = [
            // Row 1 - Warm peachy tones
            [
                UIColor(red: 233/255, green: 213/255, blue: 203/255, alpha: 1.0),
                UIColor(red: 220/255, green: 180/255, blue: 180/255, alpha: 1.0),
                UIColor(red: 205/255, green: 175/255, blue: 165/255, alpha: 1.0),
                UIColor(red: 235/255, green: 215/255, blue: 195/255, alpha: 1.0),
                UIColor(red: 225/255, green: 210/255, blue: 190/255, alpha: 1.0),
            ],
            // Row 2 - Deeper warm tones
            [
                UIColor(red: 210/255, green: 185/255, blue: 175/255, alpha: 1.0),
                UIColor(red: 195/255, green: 170/255, blue: 165/255, alpha: 1.0),
                UIColor(red: 160/255, green: 110/255, blue: 90/255, alpha: 1.0),
                UIColor(red: 180/255, green: 150/255, blue: 130/255, alpha: 1.0),
                UIColor(red: 220/255, green: 190/255, blue: 150/255, alpha: 1.0),
            ],
            // Row 3 - Browns and tans
            [
                UIColor(red: 200/255, green: 180/255, blue: 170/255, alpha: 1.0),
                UIColor(red: 185/255, green: 165/255, blue: 160/255, alpha: 1.0),
                UIColor(red: 140/255, green: 100/255, blue: 80/255, alpha: 1.0),
                UIColor(red: 175/255, green: 145/255, blue: 125/255, alpha: 1.0),
                UIColor(red: 195/255, green: 175/255, blue: 135/255, alpha: 1.0),
            ],
            // Row 4 - Pale neutrals
            [
                UIColor(red: 240/255, green: 235/255, blue: 220/255, alpha: 1.0),
                UIColor(red: 230/255, green: 225/255, blue: 210/255, alpha: 1.0),
                UIColor(red: 220/255, green: 215/255, blue: 200/255, alpha: 1.0),
                UIColor(red: 235/255, green: 230/255, blue: 215/255, alpha: 1.0),
                UIColor(red: 245/255, green: 240/255, blue: 225/255, alpha: 1.0),
            ],
            // Row 5 - Cool pastels
            [
                UIColor(red: 210/255, green: 220/255, blue: 215/255, alpha: 1.0),
                UIColor(red: 200/255, green: 210/255, blue: 205/255, alpha: 1.0),
                UIColor(red: 190/255, green: 210/255, blue: 220/255, alpha: 1.0),
                UIColor(red: 200/255, green: 220/255, blue: 235/255, alpha: 1.0),
                UIColor(red: 215/255, green: 210/255, blue: 200/255, alpha: 1.0),
            ],
            // Row 6 - Muted greens and blues
            [
                UIColor(red: 180/255, green: 200/255, blue: 190/255, alpha: 1.0),
                UIColor(red: 165/255, green: 185/255, blue: 180/255, alpha: 1.0),
                UIColor(red: 160/255, green: 180/255, blue: 200/255, alpha: 1.0),
                UIColor(red: 175/255, green: 195/255, blue: 210/255, alpha: 1.0),
                UIColor(red: 185/255, green: 180/255, blue: 170/255, alpha: 1.0),
            ],
            // Row 7 - Deeper muted tones
            [
                UIColor(red: 150/255, green: 170/255, blue: 160/255, alpha: 1.0),
                UIColor(red: 140/255, green: 160/255, blue: 155/255, alpha: 1.0),
                UIColor(red: 130/255, green: 150/255, blue: 170/255, alpha: 1.0),
                UIColor(red: 145/255, green: 165/255, blue: 180/255, alpha: 1.0),
                UIColor(red: 160/255, green: 155/255, blue: 145/255, alpha: 1.0),
            ],
        ]
        
        return ColorPaletteView(colors: palette)
    }
}
