import UIKit

final class OTPVerifyViewController: UIViewController {

    private let email: String
    private let prefillCode: String?

    // MARK: - UI Components

    private let headingLabel: UILabel = {
        let label = UILabel()
        label.text = "Check your email"
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(size: 32)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 15, weight: .regular)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let codeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "000000"
        tf.keyboardType = .numberPad
        tf.textContentType = .oneTimeCode
        tf.textAlignment = .center
        tf.font = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .bold)
        tf.textColor = CosmicFitTheme.Colours.cosmicBlue
        tf.backgroundColor = .clear
        tf.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
        tf.layer.borderWidth = 1.0
        tf.layer.cornerRadius = 12
        tf.heightAnchor.constraint(equalToConstant: 64).isActive = true
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

    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Verify", for: .normal)
        CosmicFitTheme.styleButton(button, style: .primary)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private let differentEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Use a different email", for: .normal)
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

    // MARK: - Init

    init(email: String, prefillCode: String? = nil) {
        self.email = email
        self.prefillCode = prefillCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        subtitleLabel.text = "We sent a 6-digit code to\n\(email)"
        setupLayout()

        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        differentEmailButton.addTarget(self, action: #selector(differentEmailTapped), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeepLink),
            name: .cosmicFitDeepLinkReceived,
            object: nil
        )

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let code = prefillCode, !code.isEmpty {
            codeTextField.text = code
            verifyTapped()
        } else {
            checkPendingDeepLink()
            codeTextField.becomeFirstResponder()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            headingLabel, subtitleLabel, codeTextField, errorLabel, verifyButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.setCustomSpacing(12, after: headingLabel)
        stack.setCustomSpacing(32, after: subtitleLabel)
        stack.setCustomSpacing(8, after: codeTextField)
        stack.setCustomSpacing(16, after: errorLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        differentEmailButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(differentEmailButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            differentEmailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            differentEmailButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),

            activityIndicator.centerYAnchor.constraint(equalTo: verifyButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: verifyButton.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Actions

    @objc private func verifyTapped() {
        guard let code = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              code.count == 6 else {
            showError("Please enter the 6-digit code.")
            return
        }

        errorLabel.isHidden = true
        verifyButton.isEnabled = false
        activityIndicator.startAnimating()

        Task {
            do {
                try await CosmicFitAuthService.shared.verifyOTP(email: email, code: code)
                Task { await SupabaseSyncService.shared.performFullSync() }
            } catch {
                showError("Incorrect code. Please try again.")
            }
            verifyButton.isEnabled = true
            activityIndicator.stopAnimating()
        }
    }

    @objc private func differentEmailTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleDeepLink() {
        checkPendingDeepLink()
    }

    private func checkPendingDeepLink() {
        guard let pending = AuthDeepLinkRouter.shared.pendingDeepLink,
              pending.email.lowercased() == email.lowercased() else { return }
        let consumed = AuthDeepLinkRouter.shared.consumePendingLink()
        if let code = consumed?.code {
            codeTextField.text = code
            verifyTapped()
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}
