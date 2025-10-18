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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        setupBackgroundElements()
        setupLogoElements()
    }
    
    private func setupBackgroundElements() {
        // Background container
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.backgroundColor = .clear
        view.addSubview(backgroundContainer)
        
        // Setup background images
        setupBackgroundImageView(backgroundRunes1, imageName: "ScrollingRunesBackground")
        setupBackgroundImageView(backgroundRunes2, imageName: "ScrollingRunesBackground")
        setupBackgroundImageView(backgroundRunes3, imageName: "ScrollingRunesBackground")
        
        // Setup duplicate images for seamless scrolling
        setupBackgroundImageView(backgroundRunes1Duplicate, imageName: "ScrollingRunesBackground")
        setupBackgroundImageView(backgroundRunes2Duplicate, imageName: "ScrollingRunesBackground")
        setupBackgroundImageView(backgroundRunes3Duplicate, imageName: "ScrollingRunesBackground")
        
        // Layout constraints
        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupBackgroundConstraints()
    }
    
    private func setupBackgroundImageView(_ imageView: UIImageView, imageName: String) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0 // Start invisible
        imageView.image = UIImage(named: imageName)
        backgroundContainer.addSubview(imageView)
    }
    
    private func setupBackgroundConstraints() {
        let screenWidth = view.bounds.width
        let columnWidth = screenWidth / 3
        
        // First column (left)
        NSLayoutConstraint.activate([
            backgroundRunes1.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes1.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            backgroundRunes1.widthAnchor.constraint(equalToConstant: columnWidth),
            backgroundRunes1.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
            
            backgroundRunes1Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes1Duplicate.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            backgroundRunes1Duplicate.widthAnchor.constraint(equalToConstant: columnWidth),
            backgroundRunes1Duplicate.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor)
        ])
        
        // Second column (center)
        NSLayoutConstraint.activate([
            backgroundRunes2.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes2.leadingAnchor.constraint(equalTo: backgroundRunes1.trailingAnchor),
            backgroundRunes2.widthAnchor.constraint(equalToConstant: columnWidth),
            backgroundRunes2.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
            
            backgroundRunes2Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes2Duplicate.leadingAnchor.constraint(equalTo: backgroundRunes1.trailingAnchor),
            backgroundRunes2Duplicate.widthAnchor.constraint(equalToConstant: columnWidth),
            backgroundRunes2Duplicate.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor)
        ])
        
        // Third column (right)
        NSLayoutConstraint.activate([
            backgroundRunes3.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes3.leadingAnchor.constraint(equalTo: backgroundRunes2.trailingAnchor),
            backgroundRunes3.widthAnchor.constraint(equalToConstant: columnWidth),
            backgroundRunes3.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
            
            backgroundRunes3Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes3Duplicate.leadingAnchor.constraint(equalTo: backgroundRunes2.trailingAnchor),
            backgroundRunes3Duplicate.widthAnchor.constraint(equalToConstant: columnWidth),
            backgroundRunes3Duplicate.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor)
        ])
    }
    
    private func setupLogoElements() {
        // Logo container
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = .clear
        view.addSubview(logoContainer)
        
        // Setup logo parts
        setupLogoImageView(logoPart1, imageName: "CosmicFitLogo_Part1")
        setupLogoImageView(logoPart2, imageName: "CosmicFitLogo_Part2")
        setupLogoImageView(logoPart3, imageName: "CosmicFitLogo_Part3")
        setupLogoImageView(logoPart4, imageName: "CosmicFitLogo_Part4")
        
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
    
    private func setupLogoImageView(_ imageView: UIImageView, imageName: String) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0 // Start invisible
        imageView.image = UIImage(named: imageName)
        logoContainer.addSubview(imageView)
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
            // Fallback if mainViewController isn't set - use OnboardingFormViewController instead of MainViewController
            let onboardingFormVC = OnboardingFormViewController()
            let navController = UINavigationController(rootViewController: onboardingFormVC)
            navController.navigationBar.isHidden = true
            navController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            navController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.present(navController, animated: true)
            return
        }
        
        // Transition to the provided main view controller
        mainViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        mainViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(mainViewController, animated: true)
    }
}
