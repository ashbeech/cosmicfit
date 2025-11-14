//
//  MenuButton.swift
//  Cosmic Fit
//
//  Four-dot menu button that animates to X corners
//

import UIKit

final class MenuButton: UIButton {
    
    // MARK: - Properties
    private var isMenuOpen = false
    
    private let dotSize: CGFloat = 4
    private let xRadius: CGFloat = 5  // Distance from center to X corners
    
    private let topDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        view.layer.cornerRadius = 2
        return view
    }()
    
    private let middleDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        view.layer.cornerRadius = 2
        return view
    }()
    
    private let bottomDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        view.layer.cornerRadius = 2
        return view
    }()
    
    // Hidden 4th dot behind center that appears during animation
    private let hiddenDot: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        view.layer.cornerRadius = 2
        view.alpha = 0  // Start hidden
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
        addSubview(hiddenDot)
        
        topDot.translatesAutoresizingMaskIntoConstraints = false
        middleDot.translatesAutoresizingMaskIntoConstraints = false
        bottomDot.translatesAutoresizingMaskIntoConstraints = false
        hiddenDot.translatesAutoresizingMaskIntoConstraints = false
        
        // Position 3 dots vertically (traditional burger menu)
        let dotSpacing: CGFloat = 4
        
        NSLayoutConstraint.activate([
            // Top dot
            topDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            topDot.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -(dotSpacing + dotSize)),
            topDot.widthAnchor.constraint(equalToConstant: dotSize),
            topDot.heightAnchor.constraint(equalToConstant: dotSize),
            
            // Middle dot
            middleDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            middleDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            middleDot.widthAnchor.constraint(equalToConstant: dotSize),
            middleDot.heightAnchor.constraint(equalToConstant: dotSize),
            
            // Bottom dot
            bottomDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomDot.centerYAnchor.constraint(equalTo: centerYAnchor, constant: (dotSpacing + dotSize)),
            bottomDot.widthAnchor.constraint(equalToConstant: dotSize),
            bottomDot.heightAnchor.constraint(equalToConstant: dotSize),
            
            // Hidden dot (positioned at center, behind middle dot)
            hiddenDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            hiddenDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            hiddenDot.widthAnchor.constraint(equalToConstant: dotSize),
            hiddenDot.heightAnchor.constraint(equalToConstant: dotSize),
        ])
    }
    
    // MARK: - Animation
    func animateToX() {
        isMenuOpen = true
        
        // Calculate 45° diagonal positions for X endpoints
        let diagonal = xRadius * sqrt(2) / 4  // Distance along each axis for 45° angle
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
            // Reveal the hidden 4th dot
            self.hiddenDot.alpha = 1
            
            // Move top dot to top-left corner of X (up and left at 45°)
            self.topDot.transform = CGAffineTransform(translationX: -diagonal, y: -diagonal)
            
            // Move middle dot to top-right corner of X (up and right at 45°)
            self.middleDot.transform = CGAffineTransform(translationX: diagonal, y: -diagonal)
            
            // Move hidden dot to bottom-left corner of X (down and left at 45°)
            self.hiddenDot.transform = CGAffineTransform(translationX: -diagonal, y: diagonal)
            
            // Move bottom dot to bottom-right corner of X (down and right at 45°)
            self.bottomDot.transform = CGAffineTransform(translationX: diagonal, y: diagonal)
        })
    }
    
    func animateToDots() {
        isMenuOpen = false
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            // Hide the 4th dot
            self.hiddenDot.alpha = 0
            
            // Reset all transformations to return to vertical line
            self.topDot.transform = .identity
            self.middleDot.transform = .identity
            self.hiddenDot.transform = .identity
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
