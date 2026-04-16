import UIKit

final class PaymentPlaceholderViewController: UIViewController {

    // MARK: - UI Components

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return button
    }()

    private let iconCluster: UILabel = {
        let label = UILabel()
        label.text = "✦ ☾ ✦"
        label.font = UIFont.systemFont(ofSize: 40)
        label.textColor = CosmicFitTheme.Colours.cosmicLilac
        label.textAlignment = .center
        return label
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.85
        paragraphStyle.alignment = .center
        label.attributedText = NSAttributedString(
            string: "UNLOCK YOUR\nSTYLE CALENDAR",
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: 32),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Access every day's Daily Fit forecast. Scroll through your personal style calendar and never wonder what to wear again. Historical guidance, future forecasts, all written in the stars."
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .regular)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let ctaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Coming Soon", for: .normal)
        CosmicFitTheme.styleButton(button, style: .primary)
        button.isEnabled = false
        button.alpha = 0.6
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        setupLayout()
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    // MARK: - Layout

    private func setupLayout() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        let stack = UIStackView(arrangedSubviews: [
            iconCluster, headlineLabel, descriptionLabel, ctaButton
        ])
        stack.axis = .vertical
        stack.spacing = 24
        stack.setCustomSpacing(16, after: iconCluster)
        stack.setCustomSpacing(16, after: headlineLabel)
        stack.setCustomSpacing(32, after: descriptionLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
