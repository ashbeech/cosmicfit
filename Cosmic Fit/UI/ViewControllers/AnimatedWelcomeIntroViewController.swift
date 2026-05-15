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
    private let waitingLabel = UILabel()
    private let letsBeginLabel = UILabel()
    private let leadingDividerView = UIView()
    private let trailingDividerView = UIView()
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
        secondPageView.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        view.addSubview(secondPageView)

        setupSecondPageLabels()

        NSLayoutConstraint.activate([
            secondPageView.topAnchor.constraint(equalTo: view.topAnchor),
            secondPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            secondPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            secondPageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupSecondPageConstraints()
    }

    private func setupSecondPageLabels() {
        let serifSize: CGFloat = 36

        yourStyleLabel.attributedText = makeYourLineAttributedText("style.", size: serifSize)
        yourStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        yourStyleLabel.numberOfLines = 1
        yourStyleLabel.alpha = 0.0
        secondPageView.addSubview(yourStyleLabel)

        yourEnergyLabel.attributedText = makeYourLineAttributedText("energy.", size: serifSize)
        yourEnergyLabel.translatesAutoresizingMaskIntoConstraints = false
        yourEnergyLabel.numberOfLines = 1
        yourEnergyLabel.alpha = 0.0
        secondPageView.addSubview(yourEnergyLabel)

        yourStoryLabel.attributedText = makeYourLineAttributedText("story.", size: serifSize)
        yourStoryLabel.translatesAutoresizingMaskIntoConstraints = false
        yourStoryLabel.numberOfLines = 1
        yourStoryLabel.alpha = 0.0
        secondPageView.addSubview(yourStoryLabel)

        waitingLabel.text = "It’s all waiting\nto be revealed."
        waitingLabel.translatesAutoresizingMaskIntoConstraints = false
        waitingLabel.font = serifFont(size: serifSize, italic: false)
        waitingLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        waitingLabel.numberOfLines = 0
        waitingLabel.alpha = 0.0
        secondPageView.addSubview(waitingLabel)

        letsBeginLabel.text = "Let’s begin."
        letsBeginLabel.translatesAutoresizingMaskIntoConstraints = false
        letsBeginLabel.font = serifFont(size: serifSize, italic: false)
        letsBeginLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        letsBeginLabel.alpha = 0.0
        secondPageView.addSubview(letsBeginLabel)

        leadingDividerView.translatesAutoresizingMaskIntoConstraints = false
        leadingDividerView.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        leadingDividerView.alpha = 0.0
        secondPageView.addSubview(leadingDividerView)

        trailingDividerView.translatesAutoresizingMaskIntoConstraints = false
        trailingDividerView.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        trailingDividerView.alpha = 0.0
        secondPageView.addSubview(trailingDividerView)

        sparkleIcon.text = "✦"
        sparkleIcon.translatesAutoresizingMaskIntoConstraints = false
        sparkleIcon.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        sparkleIcon.textColor = CosmicFitTheme.Colours.cosmicBlue
        sparkleIcon.alpha = 0.0
        secondPageView.addSubview(sparkleIcon)
    }

    private func setupSecondPageConstraints() {
        let horizontalInset: CGFloat = 36

        NSLayoutConstraint.activate([
            yourStyleLabel.centerYAnchor.constraint(equalTo: secondPageView.centerYAnchor, constant: -120),
            yourStyleLabel.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: horizontalInset),
            yourStyleLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondPageView.trailingAnchor, constant: -horizontalInset),

            yourEnergyLabel.topAnchor.constraint(equalTo: yourStyleLabel.bottomAnchor, constant: 8),
            yourEnergyLabel.leadingAnchor.constraint(equalTo: yourStyleLabel.leadingAnchor),
            yourEnergyLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondPageView.trailingAnchor, constant: -horizontalInset),

            yourStoryLabel.topAnchor.constraint(equalTo: yourEnergyLabel.bottomAnchor, constant: 8),
            yourStoryLabel.leadingAnchor.constraint(equalTo: yourStyleLabel.leadingAnchor),
            yourStoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondPageView.trailingAnchor, constant: -horizontalInset),

            waitingLabel.topAnchor.constraint(equalTo: yourStoryLabel.bottomAnchor, constant: 36),
            waitingLabel.leadingAnchor.constraint(equalTo: yourStyleLabel.leadingAnchor),
            waitingLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondPageView.trailingAnchor, constant: -horizontalInset),

            letsBeginLabel.topAnchor.constraint(equalTo: waitingLabel.bottomAnchor, constant: 28),
            letsBeginLabel.leadingAnchor.constraint(equalTo: yourStyleLabel.leadingAnchor),
            letsBeginLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondPageView.trailingAnchor, constant: -horizontalInset),

            sparkleIcon.topAnchor.constraint(equalTo: letsBeginLabel.bottomAnchor, constant: 56),
            sparkleIcon.centerXAnchor.constraint(equalTo: secondPageView.centerXAnchor),

            leadingDividerView.centerYAnchor.constraint(equalTo: sparkleIcon.centerYAnchor),
            leadingDividerView.leadingAnchor.constraint(equalTo: secondPageView.leadingAnchor, constant: horizontalInset),
            leadingDividerView.trailingAnchor.constraint(equalTo: sparkleIcon.leadingAnchor, constant: -16),
            leadingDividerView.heightAnchor.constraint(equalToConstant: 1),

            trailingDividerView.centerYAnchor.constraint(equalTo: sparkleIcon.centerYAnchor),
            trailingDividerView.leadingAnchor.constraint(equalTo: sparkleIcon.trailingAnchor, constant: 16),
            trailingDividerView.trailingAnchor.constraint(equalTo: secondPageView.trailingAnchor, constant: -horizontalInset),
            trailingDividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: - Typography helpers
    private func serifFont(size: CGFloat, italic: Bool) -> UIFont {
        let fontName = italic ? "DMSerifText-Italic" : "DMSerifText-Regular"
        if let font = UIFont(name: fontName, size: size) {
            return font
        }
        if italic {
            if let pt = UIFont(name: "PTSerif-Italic", size: size) { return pt }
            return UIFont.italicSystemFont(ofSize: size)
        }
        if let pt = UIFont(name: "PTSerif-Regular", size: size) { return pt }
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    private func makeYourLineAttributedText(_ trailing: String, size: CGFloat) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: "Your",
            attributes: [
                .font: serifFont(size: size, italic: true),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue
            ]
        )
        attributed.append(NSAttributedString(
            string: " \(trailing)",
            attributes: [
                .font: serifFont(size: size, italic: false),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue
            ]
        ))
        return attributed
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
        let elements: [UIView] = [
            yourStyleLabel,
            yourEnergyLabel,
            yourStoryLabel,
            waitingLabel,
            letsBeginLabel,
            sparkleIcon,
            leadingDividerView,
            trailingDividerView
        ]

        for (index, element) in elements.enumerated() {
            let delay = Double(index) * 0.3

            UIView.animate(withDuration: 0.5, delay: delay, options: [.curveEaseOut]) {
                element.alpha = 1.0
            } completion: { _ in
                if index == elements.count - 1 {
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
