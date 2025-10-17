//
//  AnimatedWelcomeIntroViewController.swift
//  Cosmic Fit
//
//  Created for animated welcome intro with cascading text animation
//

import UIKit

class AnimatedWelcomeIntroViewController: UIViewController {
    
    // MARK: - UI Properties
    private let firstPageView = UIView()
    private let secondPageView = UIView()
    
    // First page elements (dark background)
    private let sparkle1 = UILabel()
    private let welcomeLabel = UILabel()
    private let cosmicFitLabel = UILabel()
    private let sparkle2 = UILabel()
    
    // Second page elements (light background)
    private let yourStyleLabel = UILabel()
    private let yourEnergyLabel = UILabel()
    private let yourStoryLabel = UILabel()
    private let spacerView = UIView()
    private let waitingLabel1 = UILabel()
    private let waitingLabel2 = UILabel()
    private let letsBeginLabel = UILabel()
    private let dividerView = UIView()
    private let sparkleIcon = UILabel()
    
    // MARK: - Properties
    private var animationCompleted = false
    private var canAdvance = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTapGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimationSequence()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup first page (dark)
        setupFirstPage()
        
        // Setup second page (light)
        setupSecondPage()
        
        // Initially show only first page
        firstPageView.alpha = 1.0
        secondPageView.alpha = 0.0
    }
    
    private func setupFirstPage() {
        firstPageView.translatesAutoresizingMaskIntoConstraints = false
        firstPageView.backgroundColor = .black
        view.addSubview(firstPageView)
        
        // Welcome text
        welcomeLabel.text = "Welcome to"
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        welcomeLabel.textColor = .white
        welcomeLabel.textAlignment = .center
        welcomeLabel.alpha = 0.0
        firstPageView.addSubview(welcomeLabel)
        
        // Cosmic Fit logo text
        cosmicFitLabel.text = "COSMIC\nFIT"
        cosmicFitLabel.translatesAutoresizingMaskIntoConstraints = false
        cosmicFitLabel.font = UIFont.systemFont(ofSize: 64, weight: .bold)
        cosmicFitLabel.textColor = .white
        cosmicFitLabel.textAlignment = .center
        cosmicFitLabel.numberOfLines = 2
        cosmicFitLabel.alpha = 0.0
        firstPageView.addSubview(cosmicFitLabel)
        
        // Sparkles
        sparkle1.text = "✦"
        sparkle1.translatesAutoresizingMaskIntoConstraints = false
        sparkle1.font = UIFont.systemFont(ofSize: 40)
        sparkle1.textColor = .white
        sparkle1.alpha = 0.0
        firstPageView.addSubview(sparkle1)
        
        sparkle2.text = "✦"
        sparkle2.translatesAutoresizingMaskIntoConstraints = false
        sparkle2.font = UIFont.systemFont(ofSize: 40)
        sparkle2.textColor = .white
        sparkle2.alpha = 0.0
        firstPageView.addSubview(sparkle2)
        
        // Constraints for first page
        NSLayoutConstraint.activate([
            firstPageView.topAnchor.constraint(equalTo: view.topAnchor),
            firstPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            firstPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            firstPageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            sparkle1.topAnchor.constraint(equalTo: firstPageView.safeAreaLayoutGuide.topAnchor, constant: 120),
            sparkle1.trailingAnchor.constraint(equalTo: firstPageView.centerXAnchor, constant: 80),
            
            welcomeLabel.topAnchor.constraint(equalTo: sparkle1.bottomAnchor, constant: 40),
            welcomeLabel.centerXAnchor.constraint(equalTo: firstPageView.centerXAnchor),
            welcomeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: firstPageView.leadingAnchor, constant: 40),
            welcomeLabel.trailingAnchor.constraint(lessThanOrEqualTo: firstPageView.trailingAnchor, constant: -40),
            
            cosmicFitLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            cosmicFitLabel.centerXAnchor.constraint(equalTo: firstPageView.centerXAnchor),
            cosmicFitLabel.leadingAnchor.constraint(greaterThanOrEqualTo: firstPageView.leadingAnchor, constant: 40),
            cosmicFitLabel.trailingAnchor.constraint(lessThanOrEqualTo: firstPageView.trailingAnchor, constant: -40),
            
            sparkle2.topAnchor.constraint(equalTo: cosmicFitLabel.bottomAnchor, constant: 60),
            sparkle2.leadingAnchor.constraint(equalTo: firstPageView.centerXAnchor, constant: -120)
        ])
    }
    
    private func setupSecondPage() {
        secondPageView.translatesAutoresizingMaskIntoConstraints = false
        secondPageView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        view.addSubview(secondPageView)
        
        // Setup labels
        setupSecondPageLabels()
        
        // Constraints for second page
        NSLayoutConstraint.activate([
            secondPageView.topAnchor.constraint(equalTo: view.topAnchor),
            secondPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            secondPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            secondPageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupSecondPageConstraints()
    }
    
    private func setupSecondPageLabels() {
        // Your style
        yourStyleLabel.text = "Your style."
        yourStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        yourStyleLabel.font = UIFont.systemFont(ofSize: 48, weight: .medium)
        yourStyleLabel.textColor = .black
        yourStyleLabel.alpha = 0.0
        secondPageView.addSubview(yourStyleLabel)
        
        // Your energy
        yourEnergyLabel.text = "Your energy."
        yourEnergyLabel.translatesAutoresizingMaskIntoConstraints = false
        yourEnergyLabel.font = UIFont.systemFont(ofSize: 48, weight: .medium)
        yourEnergyLabel.textColor = .black
        yourEnergyLabel.alpha = 0.0
        secondPageView.addSubview(yourEnergyLabel)
        
        // Your story
        yourStoryLabel.text = "Your story."
        yourStoryLabel.translatesAutoresizingMaskIntoConstraints = false
        yourStoryLabel.font = UIFont.systemFont(ofSize: 48, weight: .medium)
        yourStoryLabel.textColor = .black
        yourStoryLabel.alpha = 0.0
        secondPageView.addSubview(yourStoryLabel)
        
        // Spacer
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        secondPageView.addSubview(spacerView)
        
        // Waiting text
        waitingLabel1.text = "It's all waiting"
        waitingLabel1.translatesAutoresizingMaskIntoConstraints = false
        waitingLabel1.font = UIFont.systemFont(ofSize: 36, weight: .medium)
        waitingLabel1.textColor = .black
        waitingLabel1.alpha = 0.0
        secondPageView.addSubview(waitingLabel1)
        
        waitingLabel2.text = "to be revealed."
        waitingLabel2.translatesAutoresizingMaskIntoConstraints = false
        waitingLabel2.font = UIFont.systemFont(ofSize: 36, weight: .medium)
        waitingLabel2.textColor = .black
        waitingLabel2.alpha = 0.0
        secondPageView.addSubview(waitingLabel2)
        
        // Let's begin
        letsBeginLabel.text = "Let's begin."
        letsBeginLabel.translatesAutoresizingMaskIntoConstraints = false
        letsBeginLabel.font = UIFont.systemFont(ofSize: 36, weight: .semibold)
        letsBeginLabel.textColor = .black
        letsBeginLabel.alpha = 0.0
        secondPageView.addSubview(letsBeginLabel)
        
        // Divider
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .black
        dividerView.alpha = 0.0
        secondPageView.addSubview(dividerView)
        
        // Sparkle icon
        sparkleIcon.text = "✦"
        sparkleIcon.translatesAutoresizingMaskIntoConstraints = false
        sparkleIcon.font = UIFont.systemFont(ofSize: 24)
        sparkleIcon.textColor = .black
        sparkleIcon.alpha = 0.0
        secondPageView.addSubview(sparkleIcon)
    }
    
    private func setupSecondPageConstraints() {
        NSLayoutConstraint.activate([
            yourStyleLabel.topAnchor.constraint(equalTo: secondPageView.safeAreaLayoutGuide.topAnchor, constant: 100),
            yourStyleLabel.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            yourStyleLabel.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            
            yourEnergyLabel.topAnchor.constraint(equalTo: yourStyleLabel.bottomAnchor, constant: 20),
            yourEnergyLabel.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            yourEnergyLabel.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            
            yourStoryLabel.topAnchor.constraint(equalTo: yourEnergyLabel.bottomAnchor, constant: 20),
            yourStoryLabel.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            yourStoryLabel.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            
            spacerView.topAnchor.constraint(equalTo: yourStoryLabel.bottomAnchor),
            spacerView.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor),
            spacerView.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor),
            spacerView.heightAnchor.constraint(equalToConstant: 80),
            
            waitingLabel1.topAnchor.constraint(equalTo: spacerView.bottomAnchor),
            waitingLabel1.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            waitingLabel1.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            
            waitingLabel2.topAnchor.constraint(equalTo: waitingLabel1.bottomAnchor, constant: 10),
            waitingLabel2.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            waitingLabel2.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            
            letsBeginLabel.topAnchor.constraint(equalTo: waitingLabel2.bottomAnchor, constant: 60),
            letsBeginLabel.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            letsBeginLabel.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            
            dividerView.centerYAnchor.constraint(equalTo: sparkleIcon.centerYAnchor),
            dividerView.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: 40),
            dividerView.trailingAnchor.constraint(equalTo: sparkleIcon.leadingAnchor, constant: -20),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            sparkleIcon.centerYAnchor.constraint(equalTo: letsBeginLabel.bottomAnchor, constant: 60),
            sparkleIcon.centerXAnchor.constraint(equalTo: secondPageView.centerXAnchor),
            
            dividerView.centerYAnchor.constraint(equalTo: sparkleIcon.centerYAnchor)
        ])
        
        // Add trailing divider
        let trailingDivider = UIView()
        trailingDivider.translatesAutoresizingMaskIntoConstraints = false
        trailingDivider.backgroundColor = .black
        trailingDivider.alpha = 0.0
        secondPageView.addSubview(trailingDivider)
        
        NSLayoutConstraint.activate([
            trailingDivider.centerYAnchor.constraint(equalTo: sparkleIcon.centerYAnchor),
            trailingDivider.leadingAnchor.constraint(equalTo: sparkleIcon.trailingAnchor, constant: 20),
            trailingDivider.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -40),
            trailingDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Animation
    private func startAnimationSequence() {
        // Hold dark page for 1 second, then transition to light page
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.transitionToSecondPage()
        }
    }
    
    private func transitionToSecondPage() {
        UIView.animate(withDuration: 0.5, animations: {
            self.firstPageView.alpha = 0.0
            self.secondPageView.alpha = 1.0
        }) { _ in
            self.startCascadingTextAnimation()
        }
    }
    
    private func startCascadingTextAnimation() {
        let labels = [
            yourStyleLabel,
            yourEnergyLabel,
            yourStoryLabel,
            waitingLabel1,
            waitingLabel2,
            letsBeginLabel,
            dividerView,
            sparkleIcon
        ]
        
        for (index, element) in labels.enumerated() {
            let delay = Double(index) * 0.3
            
            UIView.animate(withDuration: 0.5, delay: delay, options: [.curveEaseOut]) {
                element.alpha = 1.0
            } completion: { _ in
                if index == labels.count - 1 {
                    // Animation completed
                    self.animationCompleted = true
                    self.canAdvance = true
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        if canAdvance {
            advanceToForm()
        }
    }
    
    private func advanceToForm() {
        // Mark welcome as seen so it won't show again
        UserProfileStorage.shared.markWelcomeSeen()
        
        let onboardingFormVC = OnboardingFormViewController()
        
        // Replace current navigation controller content instead of presenting modally
        if let navigationController = self.navigationController {
            navigationController.setViewControllers([onboardingFormVC], animated: true)
        } else {
            // Fallback to modal presentation
            onboardingFormVC.modalPresentationStyle = .fullScreen
            present(onboardingFormVC, animated: true)
        }
    }
}
