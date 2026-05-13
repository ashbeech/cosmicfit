import UIKit

final class PaymentPlaceholderViewController: UIViewController {

    // MARK: - UI Components

    /// Matches `MenuBarView`: inverted mark on cosmic grey reads as the in-app brand lockup.
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "CosmicFitLogo")
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
        if let filter = CIFilter(name: "CIColorInvert") {
            iv.layer.filters = [filter as Any]
        }
        return iv
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

    private let benefitsIntroLabel: UILabel = {
        let label = UILabel()
        label.text = "Full access includes"
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .semibold)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.75)
        label.textAlignment = .center
        return label
    }()

    private lazy var benefitsStack: UIStackView = {
        let items = [
            "Daily Fit for any date — jump to today, last week, or months ahead.",
            "Your personal style calendar in one scrollable timeline.",
            "Guidance grounded in your chart, not one-size-fits-all copy.",
            "Clear outfit direction so you spend less time second-guessing."
        ]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        for text in items {
            stack.addArrangedSubview(Self.makeBenefitRow(text: text))
        }
        return stack
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
    }

    // MARK: - Layout

    private func setupLayout() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [
            logoImageView,
            headlineLabel,
            benefitsIntroLabel,
            benefitsStack,
            ctaButton
        ])
        stack.axis = .vertical
        stack.spacing = 24
        stack.setCustomSpacing(16, after: logoImageView)
        stack.setCustomSpacing(16, after: headlineLabel)
        stack.setCustomSpacing(10, after: benefitsIntroLabel)
        stack.setCustomSpacing(28, after: benefitsStack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 52),

            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    // MARK: - Benefits row

    private static func makeBenefitRow(text: String) -> UIStackView {
        let dot = UIView()
        dot.backgroundColor = CosmicFitTheme.Colours.cosmicOrange
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .regular)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.85)
        label.textAlignment = .left
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),
        ])

        return row
    }
}
