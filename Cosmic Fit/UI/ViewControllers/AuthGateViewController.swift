import UIKit

final class AuthGateViewController: UIViewController {

    // MARK: - UI Components

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.85
        paragraphStyle.alignment = .center
        label.attributedText = NSAttributedString(
            string: "YOUR DAILY STYLE\nFORECAST AWAITS",
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: 36),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign in to unlock personalised daily style guidance written in the stars."
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .regular)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let emailFieldContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = CosmicFitTheme.Colours.transparentBackground
        container.layer.borderColor = CosmicFitTheme.Colours.borderColor.cgColor
        container.layer.borderWidth = 1.0
        container.layer.cornerRadius = 8
        container.clipsToBounds = true
        return container
    }()

    private let emailFieldRow: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 0
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        return stack
    }()

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your email"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textContentType = .emailAddress
        tf.returnKeyType = .done
        tf.clearButtonMode = .never
        CosmicFitTheme.styleTextField(tf)
        return tf
    }()

    private lazy var clearEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .light)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        button.accessibilityLabel = "Clear email"
        button.addTarget(self, action: #selector(clearEmailTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 13, weight: .medium)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let sendCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send code", for: .normal)
        CosmicFitTheme.styleButton(button, style: .onboardingAction)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private let notNowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Not now", for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 15, weight: .medium)
        button.setTitleColor(CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5), for: .normal)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        CosmicFitTheme.styleActivityIndicatorOnOnboardingAction(ai)
        return ai
    }()

    // MARK: - Callbacks

    var onAuthenticationSuccess: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        setupLayout()
        sendCodeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        notNowButton.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)
        emailTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(emailFieldDidChange), for: .editingChanged)

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if CosmicFitAuthService.shared.isAuthenticated {
            clearEmailField()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pending = AuthDeepLinkRouter.shared.consumePendingLink() {
            emailTextField.text = pending.email
            updateClearEmailButtonVisibility()
            let otpVC = OTPVerifyViewController(email: pending.email, prefillCode: pending.code)
            otpVC.onVerified = { [weak self] in
                self?.clearEmailField()
                self?.onAuthenticationSuccess?()
            }
            navigationController?.pushViewController(otpVC, animated: true)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        setupEmailFieldContainer()

        let stack = UIStackView(arrangedSubviews: [
            headlineLabel, subtitleLabel, emailFieldContainer, errorLabel, sendCodeButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.setCustomSpacing(12, after: headlineLabel)
        stack.setCustomSpacing(32, after: subtitleLabel)
        stack.setCustomSpacing(8, after: emailFieldContainer)
        stack.setCustomSpacing(16, after: errorLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        notNowButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(notNowButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            notNowButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notNowButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            activityIndicator.centerYAnchor.constraint(equalTo: sendCodeButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: sendCodeButton.trailingAnchor, constant: -16),
        ])
    }

    private func setupEmailFieldContainer() {
        emailTextField.layer.borderWidth = 0
        emailTextField.backgroundColor = .clear
        emailTextField.rightView = nil
        emailTextField.rightViewMode = .never

        emailFieldContainer.addSubview(emailFieldRow)
        emailFieldRow.addArrangedSubview(emailTextField)
        emailFieldRow.addArrangedSubview(clearEmailButton)

        NSLayoutConstraint.activate([
            emailFieldContainer.heightAnchor.constraint(equalToConstant: 50),

            emailFieldRow.topAnchor.constraint(equalTo: emailFieldContainer.topAnchor),
            emailFieldRow.leadingAnchor.constraint(equalTo: emailFieldContainer.leadingAnchor),
            emailFieldRow.trailingAnchor.constraint(equalTo: emailFieldContainer.trailingAnchor),
            emailFieldRow.bottomAnchor.constraint(equalTo: emailFieldContainer.bottomAnchor),

            emailTextField.heightAnchor.constraint(equalTo: emailFieldContainer.heightAnchor),
            clearEmailButton.widthAnchor.constraint(equalToConstant: 36),
            clearEmailButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Actions

    @objc private func clearEmailTapped() {
        clearEmailField()
    }

    @objc private func emailFieldDidChange() {
        updateClearEmailButtonVisibility()
    }

    private func clearEmailField() {
        emailTextField.text = ""
        errorLabel.isHidden = true
        updateClearEmailButtonVisibility()
    }

    private func updateClearEmailButtonVisibility() {
        let hasText = !(emailTextField.text?.isEmpty ?? true)
        clearEmailButton.isHidden = !hasText
    }

    @objc private func sendCodeTapped() {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showError("Please enter your email address.")
            return
        }
        guard isValidEmail(email) else {
            showError("Please enter a valid email address.")
            return
        }
        performSendOTP(email: email)
    }

    @objc private func notNowTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else if let tabBar = tabBarController {
            tabBar.selectedIndex = 1
        }
    }

    private func performSendOTP(email: String) {
        errorLabel.isHidden = true
        sendCodeButton.isEnabled = false
        activityIndicator.startAnimating()

        Task {
            do {
                try await CosmicFitAuthService.shared.sendOTP(email: email)
                let otpVC = OTPVerifyViewController(email: email)
                otpVC.onVerified = { [weak self] in
                    self?.clearEmailField()
                    self?.onAuthenticationSuccess?()
                }
                navigationController?.pushViewController(otpVC, animated: true)
            } catch {
                print("❌ sendOTP error: \(error)")
                showError("Could not send code: \(error.localizedDescription)")
            }
            sendCodeButton.isEnabled = true
            activityIndicator.stopAnimating()
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - UITextFieldDelegate
extension AuthGateViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendCodeTapped()
        return true
    }
}
