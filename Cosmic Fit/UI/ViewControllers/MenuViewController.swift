//
//  MenuViewController.swift
//  Cosmic Fit
//
//  Menu overlay with blur effect and navigation options
//

import UIKit
import MessageUI

final class MenuViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    private static let socialIconPointSize: CGFloat = 28 * 4 / 3
    
    private static func socialIconImage(named assetName: String) -> UIImage? {
        guard let image = UIImage(named: assetName)?.withRenderingMode(.alwaysTemplate) else { return nil }
        let size = CGSize(width: socialIconPointSize, height: socialIconPointSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - Properties
    var onDismiss: (() -> Void)?
    var onNavigateToProfile: (() -> Void)?
    var onNavigateToFAQ: (() -> Void)?
    
    // MARK: - UI Components
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        view.alpha = 0
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey.withAlphaComponent(0.95)
        view.alpha = 0
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return button
    }()
    
    private let cfLogoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "CosmicFitLogo")
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
        
        let filter = CIFilter(name: "CIColorInvert")
        iv.layer.filters = [filter as Any]
        
        return iv
    }()
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "menu_glyph")
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
        button.setTitleColor(CosmicFitTheme.Colours.cosmicBlue, for: .normal)
        return button
    }()
    
    private let faqsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("FAQs", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .regular)
        button.setTitleColor(CosmicFitTheme.Colours.cosmicBlue, for: .normal)
        return button
    }()
    
    private let helpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Help", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .regular)
        button.setTitleColor(CosmicFitTheme.Colours.cosmicBlue, for: .normal)
        return button
    }()
    
    private let socialIconsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 32
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    private let tiktokButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(socialIconImage(named: "tiktok_glyph"), for: .normal)
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return button
    }()
    
    private let instagramButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(socialIconImage(named: "instagram_glyph"), for: .normal)
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return button
    }()
    
    private let bottomDividerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let bottomDividerLeft: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        return view
    }()
    
    private let bottomDividerRight: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        return view
    }()
    
    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "star_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
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
        contentView.addSubview(cfLogoImageView)
        cfLogoImageView.isUserInteractionEnabled = true
        contentView.addSubview(logoImageView)
        contentView.addSubview(menuStackView)
        contentView.addSubview(socialIconsStackView)
        contentView.addSubview(bottomDividerContainer)
        
        bottomDividerContainer.addSubview(bottomDividerLeft)
        bottomDividerContainer.addSubview(bottomDividerRight)
        bottomDividerContainer.addSubview(starImageView)
        
        menuStackView.addArrangedSubview(accountButton)
        menuStackView.addArrangedSubview(faqsButton)
        menuStackView.addArrangedSubview(helpButton)
        
        // Add social icons to stack
        socialIconsStackView.addArrangedSubview(tiktokButton)
        socialIconsStackView.addArrangedSubview(instagramButton)
    }
    
    private func setupConstraints() {
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        cfLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        socialIconsStackView.translatesAutoresizingMaskIntoConstraints = false
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
            
            // CF logo — matches top nav position and size
            cfLogoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MenuBarView.logoLeadingInset),
            cfLogoImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MenuBarView.logoCenterYOffsetFromSafeAreaTop),
            cfLogoImageView.widthAnchor.constraint(equalToConstant: MenuBarView.logoSize),
            cfLogoImageView.heightAnchor.constraint(equalToConstant: MenuBarView.logoSize),
            
            // Logo sits above the menu stack with design-matched spacing
            logoImageView.bottomAnchor.constraint(equalTo: menuStackView.topAnchor, constant: -36),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            logoImageView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            // Menu stack (centered vertically)
            menuStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            menuStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            menuStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 40),
            menuStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40),
            
            // Social icons
            socialIconsStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            socialIconsStackView.bottomAnchor.constraint(equalTo: bottomDividerContainer.topAnchor, constant: -40),
            tiktokButton.widthAnchor.constraint(equalToConstant: Self.socialIconPointSize),
            tiktokButton.heightAnchor.constraint(equalToConstant: Self.socialIconPointSize),
            instagramButton.widthAnchor.constraint(equalToConstant: Self.socialIconPointSize),
            instagramButton.heightAnchor.constraint(equalToConstant: Self.socialIconPointSize),
            
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
        cfLogoImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped))
        )
        accountButton.addTarget(self, action: #selector(accountButtonTapped), for: .touchUpInside)
        faqsButton.addTarget(self, action: #selector(faqsButtonTapped), for: .touchUpInside)
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)
        tiktokButton.addTarget(self, action: #selector(tiktokButtonTapped), for: .touchUpInside)
        instagramButton.addTarget(self, action: #selector(instagramButtonTapped), for: .touchUpInside)
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
        print("✅ Account tapped - navigating to Profile")
        
        // Dismiss menu first
        hide(animated: true) { [weak self] in
            self?.dismiss(animated: false) {
                // Trigger navigation to profile after menu is dismissed
                self?.onNavigateToProfile?()
            }
        }
    }
    
    @objc private func faqsButtonTapped() {
        print("✅ FAQs tapped - navigating to FAQ page")
        
        guard self.presentingViewController != nil else {
            print("❌ No presenting view controller")
            return
        }
        
        // Dismiss menu first
        hide(animated: true) { [weak self] in
            self?.dismiss(animated: false) {
                // Trigger FAQ navigation
                self?.onNavigateToFAQ?()
            }
        }
    }
    
    @objc private func helpButtonTapped() {
        print("✅ Help tapped - opening email client")
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["help@cosmicfit.app"])
            mailComposer.setSubject("Cosmic Fit Help Request")
            
            present(mailComposer, animated: true)
        } else {
            // Fallback to mailto URL if mail composer isn't available
            if let mailURL = URL(string: "mailto:help@cosmicfit.app") {
                UIApplication.shared.open(mailURL)
            } else {
                // Show alert if neither method works
                let alert = UIAlertController(
                    title: "Email Not Available",
                    message: "Please email us at help@cosmicfit.app",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
    
    @objc private func tiktokButtonTapped() {
        print("✅ TikTok tapped - opening @cosmicfitapp")
        
        let username = "cosmicfitapp"
        
        // Try to open TikTok app first
        if let tiktokAppURL = URL(string: "tiktok://user?username=\(username)"),
           UIApplication.shared.canOpenURL(tiktokAppURL) {
            UIApplication.shared.open(tiktokAppURL)
        } else {
            // Fallback to web URL
            if let webURL = URL(string: "https://www.tiktok.com/@\(username)") {
                UIApplication.shared.open(webURL)
            }
        }
    }
    
    @objc private func instagramButtonTapped() {
        print("✅ Instagram tapped - opening @cosmicfitapp")
        
        let username = "cosmicfitapp"
        
        // Try to open Instagram app first
        if let instagramAppURL = URL(string: "instagram://user?username=\(username)"),
           UIApplication.shared.canOpenURL(instagramAppURL) {
            UIApplication.shared.open(instagramAppURL)
        } else {
            // Fallback to web URL
            if let webURL = URL(string: "https://www.instagram.com/\(username)") {
                UIApplication.shared.open(webURL)
            }
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
