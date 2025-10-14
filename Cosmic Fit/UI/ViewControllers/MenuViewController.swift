//
//  MenuViewController.swift
//  Cosmic Fit
//
//  Menu overlay with blur effect and navigation options
//

import UIKit

final class MenuViewController: UIViewController {
    
    // MARK: - Properties
    var onDismiss: (() -> Void)?
    
    // MARK: - UI Components
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        view.alpha = 0
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey.withAlphaComponent(0.95)
        view.alpha = 0
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return button
    }()
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "menu_glyph")
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    private let menuStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 32
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    private let accountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Account", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .regular)
        button.setTitleColor(CosmicFitTheme.Colors.cosmicBlue, for: .normal)
        return button
    }()
    
    private let redeemButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Redeem Offer Code", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .regular)
        button.setTitleColor(CosmicFitTheme.Colors.cosmicBlue, for: .normal)
        return button
    }()
    
    private let faqsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("FAQs", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .regular)
        button.setTitleColor(CosmicFitTheme.Colors.cosmicBlue, for: .normal)
        return button
    }()
    
    private let helpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Help", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .regular)
        button.setTitleColor(CosmicFitTheme.Colors.cosmicBlue, for: .normal)
        return button
    }()
    
    private let socialIconsLabel: UILabel = {
        let label = UILabel()
        label.text = "SOCIAL ICONS GO HERE"
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .medium)
        label.textColor = CosmicFitTheme.Colors.cosmicBlue
        label.textAlignment = .center
        return label
    }()
    
    private let bottomDividerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let bottomDividerLeft: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    private let bottomDividerRight: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicBlue
        return view
    }()
    
    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "star_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colors.cosmicBlue
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(blurEffectView)
        view.addSubview(contentView)
        
        contentView.addSubview(closeButton)
        contentView.addSubview(logoImageView)
        contentView.addSubview(menuStackView)
        contentView.addSubview(socialIconsLabel)
        contentView.addSubview(bottomDividerContainer)
        
        bottomDividerContainer.addSubview(bottomDividerLeft)
        bottomDividerContainer.addSubview(bottomDividerRight)
        bottomDividerContainer.addSubview(starImageView)
        
        // Add menu buttons to stack
        menuStackView.addArrangedSubview(accountButton)
        menuStackView.addArrangedSubview(redeemButton)
        menuStackView.addArrangedSubview(faqsButton)
        menuStackView.addArrangedSubview(helpButton)
    }
    
    private func setupConstraints() {
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        socialIconsLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerLeft.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerRight.translatesAutoresizingMaskIntoConstraints = false
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Blur effect covers entire screen
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view covers entire screen
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Close button - aligned with menu button position
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -9),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Logo (centered near top)
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Menu stack (centered vertically)
            menuStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            menuStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            menuStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 40),
            menuStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40),
            
            // Social icons placeholder
            socialIconsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            socialIconsLabel.bottomAnchor.constraint(equalTo: bottomDividerContainer.topAnchor, constant: -40),
            
            // Bottom divider (above safe area)
            bottomDividerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bottomDividerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bottomDividerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            bottomDividerContainer.heightAnchor.constraint(equalToConstant: 30),
            
            // Divider lines
            bottomDividerLeft.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerLeft.leadingAnchor.constraint(equalTo: bottomDividerContainer.leadingAnchor),
            bottomDividerLeft.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -10),
            bottomDividerLeft.heightAnchor.constraint(equalToConstant: 1),
            
            bottomDividerRight.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerRight.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 10),
            bottomDividerRight.trailingAnchor.constraint(equalTo: bottomDividerContainer.trailingAnchor),
            bottomDividerRight.heightAnchor.constraint(equalToConstant: 1),
            
            // Star icon
            starImageView.centerXAnchor.constraint(equalTo: bottomDividerContainer.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 24),
            starImageView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        accountButton.addTarget(self, action: #selector(accountButtonTapped), for: .touchUpInside)
        redeemButton.addTarget(self, action: #selector(redeemButtonTapped), for: .touchUpInside)
        faqsButton.addTarget(self, action: #selector(faqsButtonTapped), for: .touchUpInside)
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Animation
    func show(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                self.blurEffectView.alpha = 1
                self.contentView.alpha = 1
            })
        } else {
            blurEffectView.alpha = 1
            contentView.alpha = 1
        }
    }
    
    func hide(animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
                self.blurEffectView.alpha = 0
                self.contentView.alpha = 0
            }, completion: { _ in
                completion?()
                self.onDismiss?()
            })
        } else {
            blurEffectView.alpha = 0
            contentView.alpha = 0
            completion?()
            onDismiss?()
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        hide(animated: true) { [weak self] in
            self?.dismiss(animated: false)
        }
    }
    
    @objc private func accountButtonTapped() {
        print("Account tapped")
    }
    
    @objc private func redeemButtonTapped() {
        print("Redeem tapped")
    }
    
    @objc private func faqsButtonTapped() {
        print("FAQs tapped")
    }
    
    @objc private func helpButtonTapped() {
        print("Help tapped")
    }
}
