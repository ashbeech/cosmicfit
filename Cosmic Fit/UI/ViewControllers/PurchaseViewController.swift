import UIKit
import StoreKit

final class PurchaseViewController: UIViewController {

    // MARK: - State

    private enum LoadState { case loading, loaded, failed }
    private var loadState: LoadState = .loading
    private var selectedProduct: Product?
    private var isPurchasing = false

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

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.85
        paragraphStyle.alignment = .center
        label.attributedText = NSAttributedString(
            string: "UNLOCK YOUR\nCOSMIC STYLE",
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
            "Your Daily Fit every day \u{2014} today, tomorrow, and beyond",
            "All 8 sections of your personalised Cosmic Style Guide",
            "Outfit direction grounded in your birth chart",
            "New insights every day as the stars shift"
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

    // Product cards
    private let annualCard = SubscriptionOptionCard()
    private let monthlyCard = SubscriptionOptionCard()
    private let productCardsStack = UIStackView()

    // Loading / error
    private let loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.color = CosmicFitTheme.Colours.cosmicBlue
        return ai
    }()
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .medium)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    private let retryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Retry", for: .normal)
        CosmicFitTheme.styleButton(btn, style: .secondary)
        btn.isHidden = true
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return btn
    }()

    private let ctaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Subscribe Now", for: .normal)
        CosmicFitTheme.styleButton(button, style: .primary)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.isEnabled = false
        button.alpha = 0.6
        return button
    }()

    private let ctaSpinner: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.color = .white
        return ai
    }()

    private let restoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Already subscribed? Restore", for: .normal)
        btn.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 13, weight: .medium)
        btn.setTitleColor(CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.7), for: .normal)
        return btn
    }()

    private let legalStack: UIStackView = {
        let termsBtn = UIButton(type: .system)
        termsBtn.setTitle("Terms of Use", for: .normal)
        termsBtn.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .regular)
        termsBtn.setTitleColor(CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5), for: .normal)
        termsBtn.tag = 1

        let dot = UILabel()
        dot.text = " \u{00B7} "
        dot.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .regular)
        dot.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5)

        let privacyBtn = UIButton(type: .system)
        privacyBtn.setTitle("Privacy Policy", for: .normal)
        privacyBtn.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .regular)
        privacyBtn.setTitleColor(CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5), for: .normal)
        privacyBtn.tag = 2

        let stack = UIStackView(arrangedSubviews: [termsBtn, dot, privacyBtn])
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        stack.distribution = .equalCentering
        return stack
    }()

    private let disclosureLabel: UILabel = {
        let label = UILabel()
        label.text = "Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings."
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 10, weight: .regular)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.45)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        setupLayout()
        setupActions()
        loadProducts()
    }

    // MARK: - Layout

    private func setupLayout() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        productCardsStack.axis = .vertical
        productCardsStack.spacing = 10
        productCardsStack.alignment = .fill
        productCardsStack.addArrangedSubview(annualCard)
        productCardsStack.addArrangedSubview(monthlyCard)

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let mainStack = UIStackView(arrangedSubviews: [
            logoImageView,
            headlineLabel,
            benefitsIntroLabel,
            benefitsStack,
            loadingIndicator,
            errorLabel,
            retryButton,
            productCardsStack,
            ctaButton,
            restoreButton,
            legalStack,
            disclosureLabel
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.setCustomSpacing(16, after: logoImageView)
        mainStack.setCustomSpacing(16, after: headlineLabel)
        mainStack.setCustomSpacing(10, after: benefitsIntroLabel)
        mainStack.setCustomSpacing(28, after: benefitsStack)
        mainStack.setCustomSpacing(16, after: productCardsStack)
        mainStack.setCustomSpacing(16, after: ctaButton)
        mainStack.setCustomSpacing(12, after: restoreButton)
        mainStack.setCustomSpacing(8, after: legalStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.alignment = .fill

        scrollView.addSubview(mainStack)

        ctaButton.addSubview(ctaSpinner)
        ctaSpinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 56),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            mainStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 32),
            mainStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -32),
            mainStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),

            logoImageView.heightAnchor.constraint(equalToConstant: 52),

            ctaSpinner.centerYAnchor.constraint(equalTo: ctaButton.centerYAnchor),
            ctaSpinner.trailingAnchor.constraint(equalTo: ctaButton.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Actions

    private func setupActions() {
        annualCard.onSelected = { [weak self] in self?.selectProduct(isAnnual: true) }
        monthlyCard.onSelected = { [weak self] in self?.selectProduct(isAnnual: false) }
        ctaButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        for case let btn as UIButton in legalStack.arrangedSubviews {
            btn.addTarget(self, action: #selector(legalLinkTapped(_:)), for: .touchUpInside)
        }
    }

    // MARK: - Product Loading

    private func loadProducts() {
        loadState = .loading
        updateUI()

        Task {
            await StoreKitManager.shared.loadProducts()
            if StoreKitManager.shared.monthlyProduct != nil, StoreKitManager.shared.annualProduct != nil {
                loadState = .loaded
                configureProductCards()
                selectProduct(isAnnual: true)
            } else {
                loadState = .failed
            }
            updateUI()
        }
    }

    private func configureProductCards() {
        guard let annual = StoreKitManager.shared.annualProduct,
              let monthly = StoreKitManager.shared.monthlyProduct else { return }

        let savingsText: String? = {
            guard let pct = StoreKitManager.shared.annualSavingsPercent else { return nil }
            return "Save \(pct)%"
        }()

        annualCard.configure(title: "Annual", priceText: "\(annual.displayPrice)/year", badge: savingsText)
        monthlyCard.configure(title: "Monthly", priceText: "\(monthly.displayPrice)/month", badge: nil)
    }

    private func selectProduct(isAnnual: Bool) {
        if isAnnual {
            selectedProduct = StoreKitManager.shared.annualProduct
        } else {
            selectedProduct = StoreKitManager.shared.monthlyProduct
        }
        annualCard.setSelected(isAnnual)
        monthlyCard.setSelected(!isAnnual)
    }

    private func updateUI() {
        switch loadState {
        case .loading:
            loadingIndicator.startAnimating()
            productCardsStack.isHidden = true
            errorLabel.isHidden = true
            retryButton.isHidden = true
            ctaButton.isEnabled = false
            ctaButton.alpha = 0.6
        case .loaded:
            loadingIndicator.stopAnimating()
            productCardsStack.isHidden = false
            errorLabel.isHidden = true
            retryButton.isHidden = true
            ctaButton.isEnabled = true
            ctaButton.alpha = 1.0
        case .failed:
            loadingIndicator.stopAnimating()
            productCardsStack.isHidden = true
            errorLabel.text = "Unable to load subscription options. Please check your connection and try again."
            errorLabel.isHidden = false
            retryButton.isHidden = false
            ctaButton.isEnabled = false
            ctaButton.alpha = 0.6
        }
    }

    // MARK: - Purchase Actions

    @objc private func subscribeTapped() {
        guard let product = selectedProduct, !isPurchasing else { return }
        isPurchasing = true
        ctaButton.setTitle("", for: .normal)
        ctaSpinner.startAnimating()
        ctaButton.isEnabled = false

        Task {
            do {
                try await StoreKitManager.shared.purchase(product)
                if EntitlementManager.shared.hasFullAccess {
                    dismissAfterPurchase()
                }
            } catch StoreKitManager.PurchaseError.pending {
                showInlineMessage("Your purchase is waiting for approval.")
            } catch {
                showInlineMessage(error.localizedDescription)
            }
            isPurchasing = false
            ctaButton.setTitle("Subscribe Now", for: .normal)
            ctaSpinner.stopAnimating()
            ctaButton.isEnabled = true
        }
    }

    @objc private func restoreTapped() {
        restoreButton.isEnabled = false
        restoreButton.setTitle("Restoring...", for: .normal)

        Task {
            do {
                try await StoreKitManager.shared.restorePurchases()
                if EntitlementManager.shared.hasFullAccess {
                    dismissAfterPurchase()
                } else {
                    showInlineMessage("No active subscription found for this Apple ID.")
                }
            } catch {
                showInlineMessage("Restore failed: \(error.localizedDescription)")
            }
            restoreButton.isEnabled = true
            restoreButton.setTitle("Already subscribed? Restore", for: .normal)
        }
    }

    @objc private func retryTapped() {
        loadProducts()
    }

    @objc private func legalLinkTapped(_ sender: UIButton) {
        let urlString: String
        if sender.tag == 1 {
            urlString = "https://cosmicfit.app/terms"
        } else {
            urlString = "https://cosmicfit.app/privacy"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers

    private func showInlineMessage(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.errorLabel.isHidden = true
        }
    }

    private func dismissAfterPurchase() {
        if let genericDetail = parent as? GenericDetailViewController {
            genericDetail.dismissSelf()
        }
    }
}

// MARK: - SubscriptionOptionCard

private final class SubscriptionOptionCard: UIControl {

    var onSelected: (() -> Void)?

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let badgeLabel = UILabel()

    private var isSelectedState = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCard() {
        layer.cornerRadius = 10
        layer.borderWidth = 1.5
        layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.3).cgColor

        titleLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .semibold)
        titleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        priceLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .medium)
        priceLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        priceLabel.textAlignment = .right

        badgeLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = CosmicFitTheme.Colours.cosmicOrange
        badgeLabel.layer.cornerRadius = 4
        badgeLabel.layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.isHidden = true

        [titleLabel, priceLabel, badgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            priceLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            badgeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20),
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    func configure(title: String, priceText: String, badge: String?) {
        titleLabel.text = title
        priceLabel.text = priceText
        if let badge = badge {
            badgeLabel.text = "  \(badge)  "
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }

    func setSelected(_ selected: Bool) {
        isSelectedState = selected
        if selected {
            layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
            layer.borderWidth = 2.0
            backgroundColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.05)
        } else {
            layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.3).cgColor
            layer.borderWidth = 1.5
            backgroundColor = .clear
        }
    }

    @objc private func tapped() {
        onSelected?()
    }
}
