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

    /// Whether the parent Daily Fit page is currently showing tomorrow.
    private let isViewingTomorrow: Bool

    /// Calendar reference date (today).
    private let todayDate: Date

    /// Fired when the user taps a navigable day block. `true` = tomorrow, `false` = today.
    var onDaySelected: ((Bool) -> Void)?

    init(mode: PresentationMode, isViewingTomorrow: Bool = false, todayDate: Date = Date()) {
        self.mode = mode
        self.isViewingTomorrow = isViewingTomorrow
        self.todayDate = todayDate
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
        label.numberOfLines = 1
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        let headline = mode == .unlockPreview
            ? "UNLOCK YOUR STYLE CALENDAR"
            : "YOUR STYLE CALENDAR"
        label.attributedText = NSAttributedString(
            string: headline,
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: 24),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
            ]
        )
        return label
    }()

    private static let blockCornerRadius: CGFloat = 6
    private static let headerStripHeight: CGFloat = 14
    private static let blockHeight: CGFloat = 58

    private lazy var calendarRow: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.heightAnchor.constraint(equalToConstant: Self.blockHeight),
        ])

        let calendar = Calendar.current
        let activeIndex = isViewingTomorrow ? 1 : 0
        let tappableIndex = isViewingTomorrow ? 0 : 1

        for dayOffset in 0..<5 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: todayDate) ?? todayDate
            let dayNumber = calendar.component(.day, from: date)

            let block = UIView()
            block.translatesAutoresizingMaskIntoConstraints = false
            block.layer.cornerRadius = Self.blockCornerRadius
            block.clipsToBounds = true

            let headerStrip = UIView()
            headerStrip.translatesAutoresizingMaskIntoConstraints = false
            block.addSubview(headerStrip)

            let numberLabel = UILabel()
            numberLabel.text = "\(dayNumber)"
            numberLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 15, weight: .semibold)
            numberLabel.textAlignment = .center
            numberLabel.translatesAutoresizingMaskIntoConstraints = false
            block.addSubview(numberLabel)

            NSLayoutConstraint.activate([
                headerStrip.topAnchor.constraint(equalTo: block.topAnchor),
                headerStrip.leadingAnchor.constraint(equalTo: block.leadingAnchor),
                headerStrip.trailingAnchor.constraint(equalTo: block.trailingAnchor),
                headerStrip.heightAnchor.constraint(equalToConstant: Self.headerStripHeight),

                numberLabel.centerXAnchor.constraint(equalTo: block.centerXAnchor),
                numberLabel.centerYAnchor.constraint(equalTo: block.centerYAnchor, constant: Self.headerStripHeight / 2),
            ])

            if dayOffset == activeIndex {
                block.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
                block.layer.borderWidth = 2
                block.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
                headerStrip.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
                numberLabel.textColor = CosmicFitTheme.Colours.cosmicGrey
            } else if dayOffset == tappableIndex {
                block.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
                block.layer.borderWidth = 2
                block.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
                headerStrip.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
                numberLabel.textColor = CosmicFitTheme.Colours.cosmicBlue

                let tap = UITapGestureRecognizer(target: self, action: #selector(tappableDayBlockTapped))
                block.addGestureRecognizer(tap)
                block.isUserInteractionEnabled = true
            } else {
                let fadeStep: CGFloat = {
                    switch dayOffset {
                    case 2: return 0.35
                    case 3: return 0.20
                    default: return 0.10
                    }
                }()
                block.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
                block.layer.borderWidth = 2
                block.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(fadeStep).cgColor
                headerStrip.backgroundColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(fadeStep)
                numberLabel.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(fadeStep)
            }

            stack.addArrangedSubview(block)
        }

        return container
    }()

    private lazy var benefitsStack: UIStackView = {
        let items = [
            "Daily Fit for any date, jump to today, last week, or months ahead.",
            "Guidance grounded in your chart, not one-size-fits-all copy.",
            "Clear outfit direction so you spend less time and money and look your best."
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
        button.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold
        )
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.alpha = 0.45
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        setupLayout()
    }

    // MARK: - Actions

    @objc private func tappableDayBlockTapped() {
        let navigateToTomorrow = !isViewingTomorrow
        onDaySelected?(navigateToTomorrow)
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
            calendarRow,
            benefitsStack,
            ctaButton
        ])
        stack.axis = .vertical
        stack.spacing = 24
        stack.setCustomSpacing(16, after: logoImageView)
        stack.setCustomSpacing(16, after: headlineLabel)
        stack.setCustomSpacing(28, after: calendarRow)
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
