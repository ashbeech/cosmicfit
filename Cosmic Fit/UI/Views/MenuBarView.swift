//
//  MenuBarView.swift
//  Cosmic Fit
//
//  Sticky top menu bar with logo and menu button
//

import UIKit

final class MenuBarView: UIView {
    
    // MARK: - Properties
    static let height: CGFloat = 40
    var onMenuTapped: (() -> Void)?
    
    // MARK: - UI Components
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "cb_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    private let menuButton = MenuButton()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        
        // Add subtle bottom border
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 0
        
        addSubview(logoImageView)
        addSubview(menuButton)
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        
        menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        
        // Calculate content height: 40px bar - 5px top padding - 5px bottom padding = 30px content
        let contentHeight: CGFloat = 30
        
        NSLayoutConstraint.activate([
            // Logo on left with padding
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: contentHeight),
            logoImageView.widthAnchor.constraint(equalToConstant: contentHeight),
            
            // Menu button on right with padding
            menuButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            menuButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: contentHeight),
            menuButton.heightAnchor.constraint(equalToConstant: contentHeight),
        ])
    }
    
    @objc private func menuButtonTapped() {
        onMenuTapped?()
    }
    
    // MARK: - Public Methods
    func animateMenuButton(toX: Bool) {
        if toX {
            menuButton.animateToX()
        } else {
            menuButton.animateToDots()
        }
    }
}
