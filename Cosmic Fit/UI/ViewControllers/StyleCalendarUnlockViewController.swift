import UIKit

/// Unlock teaser for the Style Calendar — shown from the Daily Fit calendar control.
/// Subscribers and non-subscribers both see coming-soon content until the feature ships;
/// copy differs slightly when full access is already active.
final class StyleCalendarUnlockViewController: UIViewController {

    enum PresentationMode {
        /// User does not have monthly/annual access — unlock framing.
        case unlockPreview
        /// User has full access — feature still in development.
        case subscribedComingSoon
    }

    private let mode: PresentationMode

    init(mode: PresentationMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components

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

    private lazy var headlineLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.85
        paragraphStyle.alignment = .center
        let headline = mode == .unlockPreview
            ? "UNLOCK YOUR\nSTYLE CALENDAR"
            : "YOUR STYLE\nCALENDAR"
        label.attributedText = NSAttributedString(
            string: headline,
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: 32),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        return label
    }()

    private lazy var benefitsIntroLabel: UILabel = {
        let label = UILabel()
        label.text = mode == .unlockPreview
            ? "Planned with full access — details to be confirmed"
            : "Coming soon — details to be confirmed"
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .semibold)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.75)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var benefitsStack: UIStackView = {
        let items = [
            "Daily Fit for any date — jump to today, last week, or months ahead (TBC).",
            "Your personal style calendar in one scrollable timeline (TBC).",
            "Guidance grounded in your chart, not one-size-fits-all copy (TBC).",
            "Clear outfit direction so you spend less time second-guessing (TBC)."
        ]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DosAndDontsSectionView.bulletToBulletSpacing
        stack.alignment = .fill
        for text in items {
            stack.addArrangedSubview(DosAndDontsSectionView.bulletPointRow(text: text))
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

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

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
        stack.alignment = .fill

        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 56),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -32),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),

            logoImageView.heightAnchor.constraint(equalToConstant: 52),
        ])
    }
}
