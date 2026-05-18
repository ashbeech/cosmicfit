import UIKit

final class SignedOutLandingViewController: UIViewController {

    // MARK: - Background Animation Views

    private let backgroundContainer = UIView()
    private let backgroundRunes1 = UIImageView()
    private let backgroundRunes2 = UIImageView()
    private let backgroundRunes3 = UIImageView()
    private let backgroundRunes1Duplicate = UIImageView()
    private let backgroundRunes2Duplicate = UIImageView()
    private let backgroundRunes3Duplicate = UIImageView()

    // MARK: - Logo Views

    private let logoContainer = UIView()
    private let logoPart1 = UIImageView()
    private let logoPart2 = UIImageView()
    private let logoPart3 = UIImageView()
    private let logoPart4 = UIImageView()

    // MARK: - Buttons

    private let startFreshButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        setupBackgroundRunes()
        setupLogoElements()
        setupButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Background Setup

    private func setupBackgroundRunes() {
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.clipsToBounds = true
        view.addSubview(backgroundContainer)

        let runeImage = UIImage(named: "logo-animation-background")

        let columns: [(UIImageView, UIImageView)] = [
            (backgroundRunes1, backgroundRunes1Duplicate),
            (backgroundRunes2, backgroundRunes2Duplicate),
            (backgroundRunes3, backgroundRunes3Duplicate)
        ]

        for (primary, duplicate) in columns {
            primary.image = runeImage
            primary.contentMode = .scaleToFill
            primary.translatesAutoresizingMaskIntoConstraints = false
            primary.alpha = 0
            backgroundContainer.addSubview(primary)

            duplicate.image = runeImage
            duplicate.contentMode = .scaleToFill
            duplicate.translatesAutoresizingMaskIntoConstraints = false
            duplicate.alpha = 0
            backgroundContainer.addSubview(duplicate)
        }

        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundRunes1.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes1.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            backgroundRunes1.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes1.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),

            backgroundRunes1Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes1Duplicate.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            backgroundRunes1Duplicate.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes1Duplicate.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),

            backgroundRunes2.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes2.leadingAnchor.constraint(equalTo: backgroundRunes1.trailingAnchor),
            backgroundRunes2.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes2.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),

            backgroundRunes2Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes2Duplicate.leadingAnchor.constraint(equalTo: backgroundRunes1.trailingAnchor),
            backgroundRunes2Duplicate.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes2Duplicate.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),

            backgroundRunes3.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes3.leadingAnchor.constraint(equalTo: backgroundRunes2.trailingAnchor),
            backgroundRunes3.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes3.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor),

            backgroundRunes3Duplicate.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            backgroundRunes3Duplicate.leadingAnchor.constraint(equalTo: backgroundRunes2.trailingAnchor),
            backgroundRunes3Duplicate.widthAnchor.constraint(equalTo: backgroundContainer.widthAnchor, multiplier: 1.0/3.0),
            backgroundRunes3Duplicate.heightAnchor.constraint(equalTo: backgroundContainer.heightAnchor)
        ])
    }

    // MARK: - Logo Setup

    private func setupLogoElements() {
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoContainer)

        let parts = [logoPart1, logoPart2, logoPart3, logoPart4]
        for (index, part) in parts.enumerated() {
            part.image = UIImage(named: "logo-animation-part-\(index + 1)")
            part.contentMode = .scaleAspectFit
            part.translatesAutoresizingMaskIntoConstraints = false
            part.alpha = 0
            logoContainer.addSubview(part)
        }

        NSLayoutConstraint.activate([
            logoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            logoContainer.widthAnchor.constraint(equalToConstant: 200),
            logoContainer.heightAnchor.constraint(equalToConstant: 200)
        ])

        for part in parts {
            NSLayoutConstraint.activate([
                part.topAnchor.constraint(equalTo: logoContainer.topAnchor),
                part.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
                part.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
                part.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor)
            ])
        }
    }

    // MARK: - Buttons Setup

    private func setupButtons() {
        let buttonStack = UIStackView(arrangedSubviews: [startFreshButton, signInButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 14
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        styleLandingButton(startFreshButton, title: "Start Fresh")
        styleLandingButton(signInButton, title: "Sign In")

        startFreshButton.addTarget(self, action: #selector(startFreshTapped), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),

            startFreshButton.heightAnchor.constraint(equalToConstant: 52),
            signInButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private func styleLandingButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1.0)
        button.layer.cornerRadius = 12
    }

    // MARK: - Animations

    private func startAnimations() {
        startBackgroundScrolling()

        UIView.animate(withDuration: 0.5) {
            self.backgroundRunes1.alpha = 1
            self.backgroundRunes1Duplicate.alpha = 1
            self.backgroundRunes2.alpha = 1
            self.backgroundRunes2Duplicate.alpha = 1
            self.backgroundRunes3.alpha = 1
            self.backgroundRunes3Duplicate.alpha = 1
        }

        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseInOut) {
            self.logoPart1.alpha = 1.0
        }
        UIView.animate(withDuration: 1.0, delay: 0.25, options: .curveEaseInOut) {
            self.logoPart2.alpha = 1.0
        }
        UIView.animate(withDuration: 1.0, delay: 0.33, options: .curveEaseInOut) {
            self.logoPart3.alpha = 1.0
        }
        UIView.animate(withDuration: 1.0, delay: 0.44, options: .curveEaseInOut) {
            self.logoPart4.alpha = 1.0
        }
    }

    private func startBackgroundScrolling() {
        view.layoutIfNeeded()

        let containerHeight = view.bounds.height
        let scrollDuration: TimeInterval = 20.0

        backgroundRunes1Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        backgroundRunes3Duplicate.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        backgroundRunes2Duplicate.transform = CGAffineTransform(translationX: 0, y: containerHeight)

        animateColumn(backgroundRunes1, duplicate: backgroundRunes1Duplicate, direction: .down, duration: scrollDuration, height: containerHeight)
        animateColumn(backgroundRunes2, duplicate: backgroundRunes2Duplicate, direction: .up, duration: scrollDuration, height: containerHeight)
        animateColumn(backgroundRunes3, duplicate: backgroundRunes3Duplicate, direction: .down, duration: scrollDuration, height: containerHeight)
    }

    private enum ScrollDirection { case up, down }

    private func animateColumn(_ primary: UIImageView, duplicate: UIImageView, direction: ScrollDirection, duration: TimeInterval, height: CGFloat) {
        let primaryAnim = CABasicAnimation(keyPath: "transform.translation.y")
        primaryAnim.duration = duration
        primaryAnim.repeatCount = .infinity
        primaryAnim.isRemovedOnCompletion = false

        let dupAnim = CABasicAnimation(keyPath: "transform.translation.y")
        dupAnim.duration = duration
        dupAnim.repeatCount = .infinity
        dupAnim.isRemovedOnCompletion = false

        switch direction {
        case .down:
            primaryAnim.fromValue = 0
            primaryAnim.toValue = height
            dupAnim.fromValue = -height
            dupAnim.toValue = 0
        case .up:
            primaryAnim.fromValue = 0
            primaryAnim.toValue = -height
            dupAnim.fromValue = height
            dupAnim.toValue = 0
        }

        primary.layer.add(primaryAnim, forKey: "scrollAnimation")
        duplicate.layer.add(dupAnim, forKey: "scrollAnimation")
    }

    // MARK: - Actions

    @objc private func signInTapped() {
        let authGate = AuthGateViewController()
        authGate.onAuthenticationSuccess = { [weak self] in
            self?.handleAuthSuccess()
        }
        let nav = UINavigationController(rootViewController: authGate)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func startFreshTapped() {
        let alert = UIAlertController(
            title: "Start Fresh?",
            message: "This will erase your birth chart and start over with a new account. Your subscription follows your Apple ID, not your Cosmic Fit account.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Start Fresh", style: .destructive) { [weak self] _ in
            self?.performStartFresh()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func performStartFresh() {
        Task {
            try? await CosmicFitAuthService.shared.signOut()
            await MainActor.run {
                UserProfileStorage.shared.deleteUserProfile()
                BlueprintStorage.shared.delete()
                UserProfileStorage.shared.clearOnboardingPendingAuth()
                CosmicFitAuthService.shared.clearAccountEmail()
                CosmicFitAuthService.shared.clearLastUserId()

                let onboardingVC = OnboardingFormViewController()
                let nav = UINavigationController(rootViewController: onboardingVC)
                nav.navigationBar.isHidden = true

                guard let window = self.view.window else { return }
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                    window.rootViewController = nav
                }
            }
        }
    }

    private func handleAuthSuccess() {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }

            if UserProfileStorage.shared.loadUserProfile() == nil {
                self.pullProfileThenNavigate()
            } else {
                Task {
                    await SupabaseSyncService.shared.performFullSync()
                }
                self.navigateToTabBar()
            }
        }
    }

    private func pullProfileThenNavigate() {
        let loadingAlert = UIAlertController(title: nil, message: "Restoring your chart data...", preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        loadingAlert.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: loadingAlert.view.centerYAnchor),
            indicator.leadingAnchor.constraint(equalTo: loadingAlert.view.leadingAnchor, constant: 20)
        ])
        present(loadingAlert, animated: true)

        Task {
            do {
                let profile = try await SupabaseSyncService.shared.pullProfileFromSupabase()
                if let profile {
                    UserProfileStorage.shared.saveUserProfile(profile)
                }
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        if UserProfileStorage.shared.loadUserProfile() != nil {
                            self.navigateToTabBar()
                        } else {
                            self.navigateToPostAuthOnboarding()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        if UserProfileStorage.shared.loadUserProfile() != nil {
                            self.navigateToTabBar()
                        } else {
                            self.handlePullError(error)
                        }
                    }
                }
            }
        }
    }

    private func handlePullError(_ error: Error) {
        let isNotFoundError = "\(error)".contains("PGRST116") || "\(error)".contains("406")

        if isNotFoundError {
            navigateToPostAuthOnboarding()
        } else {
            showPullFailedAlert()
        }
    }

    private func navigateToPostAuthOnboarding() {
        let onboardingVC = OnboardingFormViewController(postAuthMode: true)
        let nav = UINavigationController(rootViewController: onboardingVC)
        nav.navigationBar.isHidden = true

        guard let window = view.window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = nav
        }
    }

    private func showPullFailedAlert() {
        let alert = UIAlertController(
            title: "Couldn't Restore Data",
            message: "We couldn't restore your chart data. Please check your connection and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.pullProfileThenNavigate()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func navigateToTabBar() {
        guard let tabBar = AppDelegate.makeConfiguredTabBarController(),
              let window = view.window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = tabBar
        }
    }
}
