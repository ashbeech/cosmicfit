//
//  ColourPaletteView.swift
//  Cosmic Fit
//
//  Custom component for displaying colour palette grid (used by Blueprint)
//

import UIKit

final class ColourPaletteView: UIView {
    
    // MARK: - Properties
    private var colours: [[UIColor]] = []
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
        cv.register(ColourCell.self, forCellWithReuseIdentifier: ColourCell.reuseIdentifier)
        return cv
    }()
    
    // MARK: - Initialization
    init(colours: [[UIColor]]) {
        self.colours = colours
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
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // MARK: - Layout
    private func calculateCellSize() -> CGFloat {
        let totalSpacing = cellSpacing * CGFloat(columns - 1)
        let availableWidth = bounds.width - totalSpacing
        return availableWidth / CGFloat(columns)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UICollectionViewDataSource
extension ColourPaletteView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return colours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colours[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ColourCell.reuseIdentifier,
            for: indexPath
        ) as? ColourCell else {
            return UICollectionViewCell()
        }
        
        let colour = colours[indexPath.section][indexPath.item]
        cell.configure(with: colour)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ColourPaletteView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = calculateCellSize()
        return CGSize(width: size, height: size)
    }
}

// MARK: - ColourCell
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
    
    func configure(with colour: UIColor) {
        colourView.backgroundColor = colour
    }
}

// MARK: - Placeholder Colour Palette Generator
extension ColourPaletteView {
    
    /// Creates a placeholder colour palette matching the design
    /// Used by Blueprint page for Colour Guide section
    static func createPlaceholderPalette() -> ColourPaletteView {
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
        
        return ColourPaletteView(colours: palette)
    }
}
