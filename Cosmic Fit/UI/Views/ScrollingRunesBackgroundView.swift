//
//  ScrollingRunesBackgroundView.swift
//  Cosmic Fit
//
//  Reusable full-screen view with 3 scrolling rune columns
//  Exactly matches AnimatedLaunchScreenViewController implementation
//

import UIKit

class ScrollingRunesBackgroundView: UIView {
    
    // MARK: - UI Elements
    private let runeColumn1 = UIImageView()
    private let runeColumn2 = UIImageView()
    private let runeColumn3 = UIImageView()
    
    private let runeColumn1Duplicate = UIImageView()
    private let runeColumn2Duplicate = UIImageView()
    private let runeColumn3Duplicate = UIImageView()
    
    // MARK: - Properties
    private var isAnimating = false
    private let scrollDuration: TimeInterval = 20.0
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        clipsToBounds = true
        backgroundColor = .clear
        
        guard let runeImage = UIImage(named: "logo-animation-background") else {
            print("⚠️ Could not load logo-animation-background image")
            return
        }
        
        // Setup first column (scrolls down) - LEFT
        runeColumn1.image = runeImage
        runeColumn1.contentMode = .scaleToFill
        runeColumn1.translatesAutoresizingMaskIntoConstraints = false
        runeColumn1.alpha = 0 // Start invisible
        addSubview(runeColumn1)
        
        runeColumn1Duplicate.image = runeImage
        runeColumn1Duplicate.contentMode = .scaleToFill
        runeColumn1Duplicate.translatesAutoresizingMaskIntoConstraints = false
        runeColumn1Duplicate.alpha = 0 // Start invisible
        addSubview(runeColumn1Duplicate)
        
        // Setup second column (scrolls up) - MIDDLE
        runeColumn2.image = runeImage
        runeColumn2.contentMode = .scaleToFill
        runeColumn2.translatesAutoresizingMaskIntoConstraints = false
        runeColumn2.alpha = 0 // Start invisible
        addSubview(runeColumn2)
        
        runeColumn2Duplicate.image = runeImage
        runeColumn2Duplicate.contentMode = .scaleToFill
        runeColumn2Duplicate.translatesAutoresizingMaskIntoConstraints = false
        runeColumn2Duplicate.alpha = 0 // Start invisible
        addSubview(runeColumn2Duplicate)
        
        // Setup third column (scrolls down) - RIGHT
        runeColumn3.image = runeImage
        runeColumn3.contentMode = .scaleToFill
        runeColumn3.translatesAutoresizingMaskIntoConstraints = false
        runeColumn3.alpha = 0 // Start invisible
        addSubview(runeColumn3)
        
        runeColumn3Duplicate.image = runeImage
        runeColumn3Duplicate.contentMode = .scaleToFill
        runeColumn3Duplicate.translatesAutoresizingMaskIntoConstraints = false
        runeColumn3Duplicate.alpha = 0 // Start invisible
        addSubview(runeColumn3Duplicate)
        
        // Layout constraints - exactly matching intro screen
        NSLayoutConstraint.activate([
            // First column (LEFT - exactly 1/3 width)
            runeColumn1.topAnchor.constraint(equalTo: topAnchor),
            runeColumn1.leadingAnchor.constraint(equalTo: leadingAnchor),
            runeColumn1.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            runeColumn1.heightAnchor.constraint(equalTo: heightAnchor),
            
            // First column duplicate
            runeColumn1Duplicate.topAnchor.constraint(equalTo: topAnchor),
            runeColumn1Duplicate.leadingAnchor.constraint(equalTo: leadingAnchor),
            runeColumn1Duplicate.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            runeColumn1Duplicate.heightAnchor.constraint(equalTo: heightAnchor),
            
            // Second column (MIDDLE - exactly 1/3 width)
            runeColumn2.topAnchor.constraint(equalTo: topAnchor),
            runeColumn2.leadingAnchor.constraint(equalTo: runeColumn1.trailingAnchor),
            runeColumn2.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            runeColumn2.heightAnchor.constraint(equalTo: heightAnchor),
            
            // Second column duplicate
            runeColumn2Duplicate.topAnchor.constraint(equalTo: topAnchor),
            runeColumn2Duplicate.leadingAnchor.constraint(equalTo: runeColumn1.trailingAnchor),
            runeColumn2Duplicate.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            runeColumn2Duplicate.heightAnchor.constraint(equalTo: heightAnchor),
            
            // Third column (RIGHT - exactly 1/3 width)
            runeColumn3.topAnchor.constraint(equalTo: topAnchor),
            runeColumn3.leadingAnchor.constraint(equalTo: runeColumn2.trailingAnchor),
            runeColumn3.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            runeColumn3.heightAnchor.constraint(equalTo: heightAnchor),
            
            // Third column duplicate
            runeColumn3Duplicate.topAnchor.constraint(equalTo: topAnchor),
            runeColumn3Duplicate.leadingAnchor.constraint(equalTo: runeColumn2.trailingAnchor),
            runeColumn3Duplicate.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            runeColumn3Duplicate.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Need to let constraints layout first
        layoutIfNeeded()
        
        let containerHeight = bounds.height
        
        // Position duplicates using transforms before starting animations
        // For down-scrolling columns, duplicate starts above
        runeColumn1Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        runeColumn3Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        
        // For up-scrolling column, duplicate starts below
        runeColumn2Duplicate.transform = CGAffineTransform(translationX: 0, y: containerHeight)
        
        // Fade in all runes
        UIView.animate(withDuration: 0.33) {
            self.runeColumn1.alpha = 1.0
            self.runeColumn1Duplicate.alpha = 1.0
            self.runeColumn2.alpha = 1.0
            self.runeColumn2Duplicate.alpha = 1.0
            self.runeColumn3.alpha = 1.0
            self.runeColumn3Duplicate.alpha = 1.0
        }
        
        // Start infinite scrolling animations - matching intro implementation
        animateBackgroundScroll(
            imageView: runeColumn1,
            duplicate: runeColumn1Duplicate,
            direction: .down,
            duration: scrollDuration
        )
        
        animateBackgroundScroll(
            imageView: runeColumn2,
            duplicate: runeColumn2Duplicate,
            direction: .up,
            duration: scrollDuration
        )
        
        animateBackgroundScroll(
            imageView: runeColumn3,
            duplicate: runeColumn3Duplicate,
            direction: .down,
            duration: scrollDuration
        )
    }
    
    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        
        // Remove all animations
        runeColumn1.layer.removeAllAnimations()
        runeColumn1Duplicate.layer.removeAllAnimations()
        runeColumn2.layer.removeAllAnimations()
        runeColumn2Duplicate.layer.removeAllAnimations()
        runeColumn3.layer.removeAllAnimations()
        runeColumn3Duplicate.layer.removeAllAnimations()
        
        // Fade out all runes
        UIView.animate(withDuration: 0.33) {
            self.runeColumn1.alpha = 0
            self.runeColumn1Duplicate.alpha = 0
            self.runeColumn2.alpha = 0
            self.runeColumn2Duplicate.alpha = 0
            self.runeColumn3.alpha = 0
            self.runeColumn3Duplicate.alpha = 0
        }
    }
    
    // MARK: - Private Animation Methods (Exactly matching AnimatedLaunchScreenViewController)
    private enum ScrollDirection {
        case up, down
    }
    
    private func animateBackgroundScroll(imageView: UIImageView, duplicate: UIImageView, direction: ScrollDirection, duration: TimeInterval) {
        
        let tabBarHeight: CGFloat = 83
        let containerHeight = bounds.height - tabBarHeight
        
        // CRITICAL: Reset any existing transforms to ensure clean starting state
        imageView.layer.removeAllAnimations()
        duplicate.layer.removeAllAnimations()
        
        // Use Core Animation for smoother infinite scroll - EXACTLY as in intro
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.duration = duration
        animation.repeatCount = .infinity  // TRUE INFINITE LOOP
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear) // CRITICAL: Linear timing for seamless loop
        
        let duplicateAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        duplicateAnimation.duration = duration
        duplicateAnimation.repeatCount = .infinity  // TRUE INFINITE LOOP
        duplicateAnimation.isRemovedOnCompletion = false
        duplicateAnimation.timingFunction = CAMediaTimingFunction(name: .linear) // CRITICAL: Linear timing for seamless loop
        
        switch direction {
        case .down:
            // Main view: animate from 0 to +height
            animation.fromValue = 0
            animation.toValue = containerHeight
            
            // Duplicate: animate from -height to 0
            duplicateAnimation.fromValue = -containerHeight
            duplicateAnimation.toValue = 0
            
            imageView.layer.add(animation, forKey: "scrollAnimation")
            duplicate.layer.add(duplicateAnimation, forKey: "scrollAnimation")
            
        case .up:
            // Main view: animate from 0 to -height
            animation.fromValue = 0
            animation.toValue = -containerHeight
            
            // Duplicate: animate from +height to 0
            duplicateAnimation.fromValue = containerHeight
            duplicateAnimation.toValue = 0
            
            imageView.layer.add(animation, forKey: "scrollAnimation")
            duplicate.layer.add(duplicateAnimation, forKey: "scrollAnimation")
        }
    }
}
