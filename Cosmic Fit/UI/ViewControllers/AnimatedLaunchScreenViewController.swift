//
//  AnimatedLaunchScreenViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import UIKit

class AnimatedLaunchScreenViewController: UIViewController {
    
    // MARK: - UI Elements
    private let backgroundContainer = UIView()
    private let backgroundRunes1 = UIImageView()
    private let backgroundRunes2 = UIImageView()
    private let backgroundRunes3 = UIImageView()
    
    // Duplicate background views for seamless looping
    private let backgroundRunes1Duplicate = UIImageView()
    private let backgroundRunes2Duplicate = UIImageView()
    private let backgroundRunes3Duplicate = UIImageView()
    
    private let logoContainer = UIView()
    private let logoPart1 = UIImageView()
    private let logoPart2 = UIImageView()
    private let logoPart3 = UIImageView()
    private let logoPart4 = UIImageView()
    
    // MARK: - Properties
    private var mainViewController: UIViewController?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Start with complete black background
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        
        setupBackgroundRunes()
        setupLogoElements()
    }
    
    private func setupBackgroundRunes() {
        // Background container
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.clipsToBounds = true
        view.addSubview(backgroundContainer)
        
        // Get the background rune image
        let runeImage = UIImage(named: "logo-animation-background")
        
        // Setup first rune column (scrolls down) - LEFT COLUMN
        backgroundRunes1.image = runeImage
        backgroundRunes1.contentMode = .scaleToFill
        backgroundRunes1.translatesAutoresizingMaskIntoConstraints = false
        backgroundRunes1.alpha = 0 // Start invisible
        backgroundContainer.addSubview(backgroundRunes1)
        
        backgroundRunes1Duplicate.image = runeImage
        backgroundRunes1Duplicate.contentMode = .scaleToFill
        backgroundRunes1Duplicate.translatesAutoresizingMaskIntoConstraints = false
        backgroundRunes1Duplicate.alpha = 0 // Start invisible
        backgroundContainer.addSubview(backgroundRunes1Duplicate)
        
        // Setup second rune column (scrolls up) - MIDDLE COLUMN
        backgroundRunes2.image = runeImage
        backgroundRunes2.contentMode = .scaleToFill
        backgroundRunes2.translatesAutoresizingMaskIntoConstraints = false
        backgroundRunes2.alpha = 0 // Start invisible
        backgroundContainer.addSubview(backgroundRunes2)
        
        backgroundRunes2Duplicate.image = runeImage
        backgroundRunes2Duplicate.contentMode = .scaleToFill
        backgroundRunes2Duplicate.translatesAutoresizingMaskIntoConstraints = false
        backgroundRunes2Duplicate.alpha = 0 // Start invisible
        backgroundContainer.addSubview(backgroundRunes2Duplicate)
        
        // Setup third rune column (scrolls down) - RIGHT COLUMN
        backgroundRunes3.image = runeImage
        backgroundRunes3.contentMode = .scaleToFill
        backgroundRunes3.translatesAutoresizingMaskIntoConstraints = false
        backgroundRunes3.alpha = 0 // Start invisible
        backgroundContainer.addSubview(backgroundRunes3)
        
        backgroundRunes3Duplicate.image = runeImage
        backgroundRunes3Duplicate.contentMode = .scaleToFill
        backgroundRunes3Duplicate.translatesAutoresizingMaskIntoConstraints = false
        backgroundRunes3Duplicate.alpha = 0 // Start invisible
        backgroundContainer.addSubview(backgroundRunes3Duplicate)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Background container fills entire view
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // First column (LEFT - exactly 1/3 width)
            backgroundRunes1.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes1.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            backgroundRunes1.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes1.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),
            
            // First column duplicate - starts at same position (we'll use transforms to position)
            backgroundRunes1Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes1Duplicate.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            backgroundRunes1Duplicate.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes1Duplicate.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),
            
            // Second column (MIDDLE - exactly 1/3 width)
            backgroundRunes2.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes2.leadingAnchor.constraint(equalTo: backgroundRunes1.trailingAnchor),
            backgroundRunes2.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes2.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),
            
            // Second column duplicate - starts at same position (we'll use transforms to position)
            backgroundRunes2Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes2Duplicate.leadingAnchor.constraint(equalTo: backgroundRunes1.trailingAnchor),
            backgroundRunes2Duplicate.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes2Duplicate.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),
            
            // Third column (RIGHT - exactly 1/3 width)
            backgroundRunes3.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes3.leadingAnchor.constraint(equalTo: backgroundRunes2.trailingAnchor),
            backgroundRunes3.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes3.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),
            
            // Third column duplicate - starts at same position (we'll use transforms to position)
            backgroundRunes3Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes3Duplicate.leadingAnchor.constraint(equalTo: backgroundRunes2.trailingAnchor),
            backgroundRunes3Duplicate.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes3Duplicate.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor)
        ])
    }
    
    private func setupLogoElements() {
        // Logo container for centering
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoContainer)
        
        // Setup logo parts
        logoPart1.image = UIImage(named: "logo-animation-part-1")
        logoPart1.contentMode = .scaleAspectFit
        logoPart1.translatesAutoresizingMaskIntoConstraints = false
        logoPart1.alpha = 0 // Start invisible
        logoContainer.addSubview(logoPart1)
        
        logoPart2.image = UIImage(named: "logo-animation-part-2")
        logoPart2.contentMode = .scaleAspectFit
        logoPart2.translatesAutoresizingMaskIntoConstraints = false
        logoPart2.alpha = 0 // Start invisible
        logoContainer.addSubview(logoPart2)
        
        logoPart3.image = UIImage(named: "logo-animation-part-3")
        logoPart3.contentMode = .scaleAspectFit
        logoPart3.translatesAutoresizingMaskIntoConstraints = false
        logoPart3.alpha = 0 // Start invisible
        logoContainer.addSubview(logoPart3)
        
        logoPart4.image = UIImage(named: "logo-animation-part-4")
        logoPart4.contentMode = .scaleAspectFit
        logoPart4.translatesAutoresizingMaskIntoConstraints = false
        logoPart4.alpha = 0 // Start invisible
        logoContainer.addSubview(logoPart4)
        
        // Layout constraints - all logo parts centered and same size
        NSLayoutConstraint.activate([
            // Logo container centered in view
            logoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 200),
            logoContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // All logo parts fill the container
            logoPart1.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoPart1.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
            logoPart1.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
            logoPart1.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
            
            logoPart2.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoPart2.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
            logoPart2.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
            logoPart2.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
            
            logoPart3.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoPart3.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
            logoPart3.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
            logoPart3.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
            
            logoPart4.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoPart4.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
            logoPart4.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
            logoPart4.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Animations
    private func startAnimations() {
        startLogoAnimation()
        
        // Transition to main app after 2 seconds total
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.transitionToMainApp()
        }
    }
    
    private func startLogoAnimation() {
        // Part 1: Fade in over 0.5 seconds (halved time)
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.logoPart1.alpha = 1.0
        }) { _ in
            // START BACKGROUND FADE-IN immediately after part 1 completes (very slowly over 4 seconds)
            self.startBackgroundGradualFadeIn()
        }
        
        // Part 2: Starts after part 1, fades in over 0.5 seconds (overlapping with part 3)
        UIView.animate(withDuration: 1.0, delay: 0.25, options: [.curveEaseInOut], animations: {
            self.logoPart2.alpha = 1.0
        }, completion: nil)
        
        // Part 3: Starts while part 2 is still fading in, overlaps with part 4
        UIView.animate(withDuration: 1.0, delay: 0.33, options: [.curveEaseInOut], animations: {
            self.logoPart3.alpha = 1.0
        }, completion: nil)
        
        // Part 4: Starts while part 3 is still fading in
        UIView.animate(withDuration: 1.0, delay: 0.44, options: [.curveEaseInOut], animations: {
            self.logoPart4.alpha = 1.0
        }, completion: nil)
    }
    
    private func startBackgroundGradualFadeIn() {
        // Start scrolling immediately but invisibly
        startBackgroundScrolling()
        
        // Fade in all background elements very slowly over 4 seconds
        UIView.animate(withDuration: 0.44, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.backgroundRunes1.alpha = 1.0
            self.backgroundRunes1Duplicate.alpha = 1.0
            self.backgroundRunes2.alpha = 1.0
            self.backgroundRunes2Duplicate.alpha = 1.0
            self.backgroundRunes3.alpha = 1.0
            self.backgroundRunes3Duplicate.alpha = 1.0
        }, completion: nil)
    }
    
    private func startBackgroundScrolling() {
        // Need to let constraints layout first
        view.layoutIfNeeded()
        
        let scrollDuration: TimeInterval = 20.0 // Slow infinite scroll
        
        // Position duplicates using transforms before starting animations
        let containerHeight = view.bounds.height
        
        // For down-scrolling columns, duplicate starts above
        backgroundRunes1Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        backgroundRunes3Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        
        // For up-scrolling column, duplicate starts below
        backgroundRunes2Duplicate.transform = CGAffineTransform(translationX: 0, y: containerHeight)
        
        // First column scrolls down
        animateBackgroundScroll(
            imageView: backgroundRunes1,
            duplicate: backgroundRunes1Duplicate,
            direction: .down,
            duration: scrollDuration
        )
        
        // Second column scrolls up
        animateBackgroundScroll(
            imageView: backgroundRunes2,
            duplicate: backgroundRunes2Duplicate,
            direction: .up,
            duration: scrollDuration
        )
        
        // Third column scrolls down
        animateBackgroundScroll(
            imageView: backgroundRunes3,
            duplicate: backgroundRunes3Duplicate,
            direction: .down,
            duration: scrollDuration
        )
    }
    
    private enum ScrollDirection {
        case up, down
    }
    
    private func animateBackgroundScroll(imageView: UIImageView, duplicate: UIImageView, direction: ScrollDirection, duration: TimeInterval) {
        let containerHeight = view.bounds.height
        
        // Create infinite scrolling animation
        func animateLoop() {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .repeat], animations: {
                switch direction {
                case .down:
                    // Move both images down by 2x container height
                    // This ensures the duplicate (starting above) reaches the original's starting position
                    imageView.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                    duplicate.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                    
                case .up:
                    // Move both images up by 2x container height
                    // This ensures the duplicate (starting below) reaches the original's starting position
                    imageView.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
                    duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
                }
            }, completion: nil)
        }
        
        // Alternative approach using CABasicAnimation for smoother infinite scroll
        func animateWithCoreAnimation() {
            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            animation.duration = duration
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = false
            
            switch direction {
            case .down:
                // Animate from current position to one screen height down
                animation.fromValue = 0
                animation.toValue = containerHeight
                
                // For the duplicate (which starts above), animate from -height to 0
                let duplicateAnimation = CABasicAnimation(keyPath: "transform.translation.y")
                duplicateAnimation.duration = duration
                duplicateAnimation.repeatCount = .infinity
                duplicateAnimation.isRemovedOnCompletion = false
                duplicateAnimation.fromValue = -containerHeight
                duplicateAnimation.toValue = 0
                
                imageView.layer.add(animation, forKey: "scrollAnimation")
                duplicate.layer.add(duplicateAnimation, forKey: "scrollAnimation")
                
            case .up:
                // Animate from current position to one screen height up
                animation.fromValue = 0
                animation.toValue = -containerHeight
                
                // For the duplicate (which starts below), animate from +height to 0
                let duplicateAnimation = CABasicAnimation(keyPath: "transform.translation.y")
                duplicateAnimation.duration = duration
                duplicateAnimation.repeatCount = .infinity
                duplicateAnimation.isRemovedOnCompletion = false
                duplicateAnimation.fromValue = containerHeight
                duplicateAnimation.toValue = 0
                
                imageView.layer.add(animation, forKey: "scrollAnimation")
                duplicate.layer.add(duplicateAnimation, forKey: "scrollAnimation")
            }
        }
        
        // Use Core Animation for smoother infinite scroll
        animateWithCoreAnimation()
    }
    
    // MARK: - Transition
    func setMainViewController(_ viewController: UIViewController) {
        self.mainViewController = viewController
    }
    
    private func transitionToMainApp() {
        guard let mainViewController = mainViewController else {
            // Fallback if mainViewController isn't set
            let mainVC = MainViewController()
            let navController = UINavigationController(rootViewController: mainVC)
            navController.modalTransitionStyle = .crossDissolve
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true)
            return
        }
        
        // Transition to the provided main view controller
        mainViewController.modalTransitionStyle = .crossDissolve
        mainViewController.modalPresentationStyle = .fullScreen
        self.present(mainViewController, animated: true)
    }
}
