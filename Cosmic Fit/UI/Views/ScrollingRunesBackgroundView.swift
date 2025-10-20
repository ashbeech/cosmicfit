//
//  ScrollingRunesBackgroundView.swift
//  Cosmic Fit
//
//  Reusable full-screen view with 3 scrolling rune columns
//  Unified implementation for both launch screen and Daily Fit page
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
    private var heightConstraints: [NSLayoutConstraint] = []
    
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
        
        // Setup all columns with identical configuration
        setupColumn(runeColumn1, duplicate: runeColumn1Duplicate, image: runeImage)
        setupColumn(runeColumn2, duplicate: runeColumn2Duplicate, image: runeImage)
        setupColumn(runeColumn3, duplicate: runeColumn3Duplicate, image: runeImage)
        
        // Layout constraints - 3 equal columns, but DON'T set height yet
        let allImageViews = [runeColumn1, runeColumn1Duplicate, runeColumn2,
                             runeColumn2Duplicate, runeColumn3, runeColumn3Duplicate]
        
        NSLayoutConstraint.activate([
            // First column (LEFT)
            runeColumn1.topAnchor.constraint(equalTo: topAnchor),
            runeColumn1.leadingAnchor.constraint(equalTo: leadingAnchor),
            runeColumn1.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            
            runeColumn1Duplicate.topAnchor.constraint(equalTo: topAnchor),
            runeColumn1Duplicate.leadingAnchor.constraint(equalTo: leadingAnchor),
            runeColumn1Duplicate.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            
            // Second column (MIDDLE)
            runeColumn2.topAnchor.constraint(equalTo: topAnchor),
            runeColumn2.leadingAnchor.constraint(equalTo: runeColumn1.trailingAnchor),
            runeColumn2.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            
            runeColumn2Duplicate.topAnchor.constraint(equalTo: topAnchor),
            runeColumn2Duplicate.leadingAnchor.constraint(equalTo: runeColumn1.trailingAnchor),
            runeColumn2Duplicate.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            
            // Third column (RIGHT)
            runeColumn3.topAnchor.constraint(equalTo: topAnchor),
            runeColumn3.leadingAnchor.constraint(equalTo: runeColumn2.trailingAnchor),
            runeColumn3.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0),
            
            runeColumn3Duplicate.topAnchor.constraint(equalTo: topAnchor),
            runeColumn3Duplicate.leadingAnchor.constraint(equalTo: runeColumn2.trailingAnchor),
            runeColumn3Duplicate.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0/3.0)
        ])
        
        // Store height constraints to update later
        for imageView in allImageViews {
            let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.isActive = true
            heightConstraints.append(heightConstraint)
        }
    }
    
    private func setupColumn(_ imageView: UIImageView, duplicate: UIImageView, image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0 // Start invisible
        addSubview(imageView)
        
        duplicate.image = image
        duplicate.contentMode = .scaleToFill
        duplicate.translatesAutoresizingMaskIntoConstraints = false
        duplicate.alpha = 0 // Start invisible
        addSubview(duplicate)
    }
    
    // MARK: - Public Methods
    func startAnimating(visibleHeight: CGFloat? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Ensure layout is complete
        layoutIfNeeded()
        
        // Use provided height if available, otherwise use bounds
        let containerHeight = visibleHeight ?? bounds.height
        
        // UPDATE: Set the image view heights to match the container height
        for constraint in heightConstraints {
            constraint.constant = containerHeight
        }
        layoutIfNeeded()
        
        // Reset all transforms to start fresh
        runeColumn1.transform = .identity
        runeColumn1Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        runeColumn2.transform = .identity
        runeColumn2Duplicate.transform = CGAffineTransform(translationX: 0, y: containerHeight)
        runeColumn3.transform = .identity
        runeColumn3Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        
        // Fade in
        UIView.animate(withDuration: 0.5) {
            self.runeColumn1.alpha = 1.0
            self.runeColumn1Duplicate.alpha = 1.0
            self.runeColumn2.alpha = 1.0
            self.runeColumn2Duplicate.alpha = 1.0
            self.runeColumn3.alpha = 1.0
            self.runeColumn3Duplicate.alpha = 1.0
        }
        
        // Start scrolling animations
        animateScroll(imageView: runeColumn1, duplicate: runeColumn1Duplicate, direction: .down, containerHeight: containerHeight)
        animateScroll(imageView: runeColumn2, duplicate: runeColumn2Duplicate, direction: .up, containerHeight: containerHeight)
        animateScroll(imageView: runeColumn3, duplicate: runeColumn3Duplicate, direction: .down, containerHeight: containerHeight)
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
        
        // Fade out
        UIView.animate(withDuration: 0.33) {
            self.runeColumn1.alpha = 0
            self.runeColumn1Duplicate.alpha = 0
            self.runeColumn2.alpha = 0
            self.runeColumn2Duplicate.alpha = 0
            self.runeColumn3.alpha = 0
            self.runeColumn3Duplicate.alpha = 0
        }
    }
    
    // MARK: - Private Animation
    private enum ScrollDirection {
        case up, down
    }
    
    private func animateScroll(imageView: UIImageView, duplicate: UIImageView, direction: ScrollDirection, containerHeight: CGFloat) {
        // Create seamless looping animations using CABasicAnimation
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.duration = scrollDuration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let duplicateAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        duplicateAnimation.duration = scrollDuration
        duplicateAnimation.repeatCount = .infinity
        duplicateAnimation.isRemovedOnCompletion = false
        duplicateAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        switch direction {
        case .down:
            // Main view: animate from 0 to +height
            animation.fromValue = 0
            animation.toValue = containerHeight
            
            // Duplicate: starts at -height, animates to 0
            duplicateAnimation.fromValue = -containerHeight
            duplicateAnimation.toValue = 0
            
        case .up:
            // Main view: animate from 0 to -height
            animation.fromValue = 0
            animation.toValue = -containerHeight
            
            // Duplicate: starts at +height, animates to 0
            duplicateAnimation.fromValue = containerHeight
            duplicateAnimation.toValue = 0
        }
        
        imageView.layer.add(animation, forKey: "scrollAnimation")
        duplicate.layer.add(duplicateAnimation, forKey: "scrollAnimation")
    }
}
