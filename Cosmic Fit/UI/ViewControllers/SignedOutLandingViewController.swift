import UIKit

final class SignedOutLandingViewController: UIViewController {

    private let scrollingRunesBackground = ScrollingRunesBackgroundView(edgeFadeStyle: .launch)

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
        view.backgroundColor = .black
        setupBackground()
        setupLogoElements()
        setupButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Background Setup

    private func setupBackground() {
        scrollingRunesBackground.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(scrollingRunesBackground, at: 0)

        NSLayoutConstraint.activate([
            scrollingRunesBackground.topAnchor.constraint(equalTo: view.topAnchor),
            scrollingRunesBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollingRunesBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollingRunesBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        scrollingRunesBackground.startAnimating()

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
        let host = view.window ?? view!
        let overlay = CosmicFitLoadingOverlay.show(
            in: host,
            message: "Restoring your chart data\u{2026}",
            fill: .light,
            dimColour: UIColor.black.withAlphaComponent(0.55)
        )

        Task {
            do {
                let profile = try await SupabaseSyncService.shared.pullProfileFromSupabase()
                if let profile {
                    UserProfileStorage.shared.saveUserProfile(profile)
                }
                await MainActor.run {
                    overlay.dismiss {
                        if UserProfileStorage.shared.loadUserProfile() != nil {
                            self.navigateToTabBar()
                        } else {
                            self.navigateToPostAuthOnboarding()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    overlay.dismiss {
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
