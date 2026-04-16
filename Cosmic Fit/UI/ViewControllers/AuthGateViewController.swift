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

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your email"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textContentType = .emailAddress
        tf.returnKeyType = .done
        CosmicFitTheme.styleTextField(tf)
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return tf
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
        CosmicFitTheme.styleButton(button, style: .primary)
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
        ai.hidesWhenStopped = true
        ai.color = CosmicFitTheme.Colours.cosmicBlue
        return ai
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        setupLayout()
        sendCodeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        notNowButton.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)
        emailTextField.delegate = self

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pending = AuthDeepLinkRouter.shared.consumePendingLink() {
            emailTextField.text = pending.email
            let otpVC = OTPVerifyViewController(email: pending.email, prefillCode: pending.code)
            navigationController?.pushViewController(otpVC, animated: true)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            headlineLabel, subtitleLabel, emailTextField, errorLabel, sendCodeButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.setCustomSpacing(12, after: headlineLabel)
        stack.setCustomSpacing(32, after: subtitleLabel)
        stack.setCustomSpacing(8, after: emailTextField)
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

    // MARK: - Actions

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
        if let tabBar = tabBarController {
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
                navigationController?.pushViewController(otpVC, animated: true)
            } catch {
                showError("Could not send code. Please try again.")
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
