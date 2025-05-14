
//
//  AnimatedLaunchScreenViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import UIKit

class AnimatedLaunchScreenViewController: UIViewController {
    
    // MARK: - UI Elements
    private let logoImageView = UIImageView()
    private let star1 = UIImageView()
    private let star2 = UIImageView()
    private let star3 = UIImageView()
    //private let appNameLabel = UILabel()
    
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
        // Match the background color to the launch screen's background
        view.backgroundColor = .systemBackground
        
        // Logo
        logoImageView.image = UIImage(named: "CosmicFitLogo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.alpha = 0 // Start invisible
        view.addSubview(logoImageView)
        
        /*
         // App Name Label
         appNameLabel.text = "Cosmic Fit"
         appNameLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
         appNameLabel.textAlignment = .center
         appNameLabel.textColor = .tintColor
         appNameLabel.alpha = 0 // Start invisible
         appNameLabel.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(appNameLabel)
         */
        // Get a star image to use for all stars
        let starImage = UIImage(systemName: "sparkle")?.withRenderingMode(.alwaysTemplate)
        
        // Setup star1
        star1.image = starImage
        star1.tintColor = .white // Set to white color
        star1.contentMode = .scaleAspectFit
        star1.alpha = 0 // Start invisible
        star1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(star1)
        
        // Setup star2
        star2.image = starImage
        star2.tintColor = .white // Set to white color
        star2.contentMode = .scaleAspectFit
        star2.alpha = 0 // Start invisible
        star2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(star2)
        
        // Setup star3
        star3.image = starImage
        star3.tintColor = .white // Set to white color
        star3.contentMode = .scaleAspectFit
        star3.alpha = 0 // Start invisible
        star3.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(star3)
        
        // Constraints for logo
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            logoImageView.widthAnchor.constraint(equalToConstant: 180),
            logoImageView.heightAnchor.constraint(equalToConstant: 180),
            
            /*
             // App name label
             appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
             appNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             appNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
             appNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
             */
            // Star1 position and size - individually adjustable
            star1.trailingAnchor.constraint(equalTo: logoImageView.leadingAnchor, constant: 33),
            star1.topAnchor.constraint(equalTo: logoImageView.topAnchor, constant: 130),
            star1.widthAnchor.constraint(equalToConstant: 28),  // Individual size control
            star1.heightAnchor.constraint(equalToConstant: 28), // Individual size control
            
            // Star2 position and size - individually adjustable
            star2.trailingAnchor.constraint(equalTo: logoImageView.leadingAnchor, constant: 70),
            star2.topAnchor.constraint(equalTo: logoImageView.topAnchor, constant: 155),
            star2.widthAnchor.constraint(equalToConstant: 33),  // Individual size control
            star2.heightAnchor.constraint(equalToConstant: 33), // Individual size control
            
            // Star3 position and size - individually adjustable
            star3.topAnchor.constraint(equalTo: logoImageView.topAnchor, constant: -15),
            star3.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor, constant: 55),
            star3.widthAnchor.constraint(equalToConstant: 36),  // Individual size control
            star3.heightAnchor.constraint(equalToConstant: 46)  // Individual size control
        ])
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Logo fade in and scale animation
        UIView.animate(withDuration: 1.2, delay: 0.1, options: [.curveEaseOut], animations: {
            self.logoImageView.alpha = 1.0
            self.logoImageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.5) {
                self.logoImageView.transform = .identity
            }
        }
        
        // App name fade in
        /*
         UIView.animate(withDuration: 1.0, delay: 0.8, options: [], animations: {
         self.appNameLabel.alpha = 1.0
         }, completion: nil)
         */
        
        // Animate stars with different delays
        animateStar(star1, delay: 0.5)
        animateStar(star2, delay: 0.7)
        animateStar(star3, delay: 0.9)
        
        // Transition to main app after animations complete (faster timing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            self.transitionToMainApp()
        }
    }
    
    private func animateStar(_ starView: UIImageView, delay: TimeInterval) {
        // Fade in
        UIView.animate(withDuration: 0.8, delay: delay, options: [], animations: {
            starView.alpha = 1.0
        }) { _ in
            // Add twinkling effect
            self.addTwinkleAnimation(to: starView)
        }
    }
    
    private func addTwinkleAnimation(to starView: UIImageView) {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [1.0, 0.7, 1.0, 0.6, 1.0]
        animation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        animation.duration = 1.5 // Made shorter
        animation.repeatCount = 1
        starView.layer.add(animation, forKey: "twinkle")
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
