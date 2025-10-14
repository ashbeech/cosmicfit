//
//  MenuButton.swift
//  Cosmic Fit
//
//  Three-dot menu button that animates to X
//

import UIKit

final class MenuButton: UIButton {
    
    // MARK: - Properties
    private var isMenuOpen = false
    
    private let dotSize: CGFloat = 4  // ← SMALLER (was 6)
    private let dotSpacing: CGFloat = 4  // ← SMALLER (was 6)
    
    private let topDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        view.layer.cornerRadius = 2  // ← SMALLER (was 3)
        return view
    }()
    
    private let middleDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        view.layer.cornerRadius = 2  // ← SMALLER (was 3)
        return view
    }()
    
    private let bottomDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        view.layer.cornerRadius = 2  // ← SMALLER (was 3)
        return view
    }()
    
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
        addSubview(topDot)
        addSubview(middleDot)
        addSubview(bottomDot)
        
        topDot.translatesAutoresizingMaskIntoConstraints = false
        middleDot.translatesAutoresizingMaskIntoConstraints = false
        bottomDot.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Top dot
            topDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            topDot.topAnchor.constraint(equalTo: topAnchor, constant: 7),  // ← ADJUSTED (was 8)
            topDot.widthAnchor.constraint(equalToConstant: dotSize),
            topDot.heightAnchor.constraint(equalToConstant: dotSize),
            
            // Middle dot
            middleDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            middleDot.topAnchor.constraint(equalTo: topDot.bottomAnchor, constant: dotSpacing),
            middleDot.widthAnchor.constraint(equalToConstant: dotSize),
            middleDot.heightAnchor.constraint(equalToConstant: dotSize),
            
            // Bottom dot
            bottomDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomDot.topAnchor.constraint(equalTo: middleDot.bottomAnchor, constant: dotSpacing),
            bottomDot.widthAnchor.constraint(equalToConstant: dotSize),
            bottomDot.heightAnchor.constraint(equalToConstant: dotSize),
        ])
    }
    
    // MARK: - Animation
    func animateToX() {
        isMenuOpen = true
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // Rotate top dot to form top part of X
            self.topDot.transform = CGAffineTransform(rotationAngle: .pi / 4).translatedBy(x: 0, y: self.dotSpacing + self.dotSize/2)
            
            // Hide middle dot
            self.middleDot.alpha = 0
            self.middleDot.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
            // Rotate bottom dot to form bottom part of X
            self.bottomDot.transform = CGAffineTransform(rotationAngle: -.pi / 4).translatedBy(x: 0, y: -(self.dotSpacing + self.dotSize/2))
        })
    }
    
    func animateToDots() {
        isMenuOpen = false
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // Reset all transformations
            self.topDot.transform = .identity
            self.middleDot.transform = .identity
            self.middleDot.alpha = 1
            self.bottomDot.transform = .identity
        })
    }
    
    func toggle() {
        if isMenuOpen {
            animateToDots()
        } else {
            animateToX()
        }
    }
}
