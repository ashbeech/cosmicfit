import UIKit

final class AuthNudgeBannerView: UIView {

    var onTapped: (() -> Void)?
    var onDismissed: (() -> Void)?

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Sign in to sync your data"
        label.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .medium)
        label.textColor = .white
        return label
    }()

    private let navigationArrow: UIImageView = {
        let iv = UIImageView(image: CosmicNavigationArrow.image(direction: .right, pointSize: 14))
        iv.tintColor = .white.withAlphaComponent(0.7)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white.withAlphaComponent(0.6)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.9)
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        label.translatesAutoresizingMaskIntoConstraints = false
        navigationArrow.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        addSubview(navigationArrow)
        addSubview(dismissButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),

            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            navigationArrow.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 6),
            navigationArrow.centerYAnchor.constraint(equalTo: centerYAnchor),

            dismissButton.leadingAnchor.constraint(greaterThanOrEqualTo: navigationArrow.trailingAnchor, constant: 8),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            dismissButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
        addGestureRecognizer(tap)

        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }

    @objc private func bannerTapped() {
        onTapped?()
    }

    @objc private func dismissTapped() {
        UserDefaults.standard.set(true, forKey: "CosmicFitDismissedAuthNudge")
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 20)
        }) { _ in
            self.isHidden = true
            self.onDismissed?()
        }
    }
}
