//
//  CosmicFitLoadingOverlay.swift
//  Cosmic Fit
//
//  A branded, full-surface loading overlay built around `CosmicFitLoaderView`.
//  Used wherever we previously dimmed the screen and showed a spinner — and
//  as the replacement for the old `UIAlertController`-hosted "Restoring your
//  chart data…" spinners, which couldn't host a custom vector animation.
//

import UIKit

final class CosmicFitLoadingOverlay: UIView {

    private let dimView = UIView()
    private let loader: CosmicFitLoaderView
    private let messageLabel = UILabel()
    private let stack = UIStackView()

    /// Side length of the loader inside the overlay.
    private static let loaderSize: CGFloat = 56

    // MARK: - Init

    init(message: String?, fill: CosmicFitLoaderView.Fill, dimColour: UIColor) {
        self.loader = CosmicFitLoaderView(fill: fill)
        super.init(frame: .zero)
        setup(message: message, dimColour: dimColour)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(message: String?, dimColour: UIColor) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        accessibilityViewIsModal = true
        accessibilityLabel = message ?? "Loading"

        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = dimColour
        addSubview(dimView)

        loader.translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(loader)

        if let message, !message.isEmpty {
            messageLabel.text = message
            messageLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .medium)
            messageLabel.textColor = loader.fill == .light ? .white : CosmicFitTheme.Colours.cosmicBlue
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stack.addArrangedSubview(messageLabel)
        }

        addSubview(stack)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            loader.widthAnchor.constraint(equalToConstant: Self.loaderSize),
            loader.heightAnchor.constraint(equalToConstant: Self.loaderSize),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }

    // MARK: - Presentation

    /// Presents a branded loading overlay pinned to `host`'s bounds.
    /// - Parameters:
    ///   - host: the view to cover (typically a view controller's `view`).
    ///   - message: optional caption shown beneath the loader.
    ///   - fill: silhouette colour; pick the variant that contrasts the surface.
    ///   - dimColour: scrim colour drawn behind the loader.
    @discardableResult
    static func show(
        in host: UIView,
        message: String? = nil,
        fill: CosmicFitLoaderView.Fill = .dark,
        dimColour: UIColor = UIColor.black.withAlphaComponent(0.12)
    ) -> CosmicFitLoadingOverlay {
        let overlay = CosmicFitLoadingOverlay(message: message, fill: fill, dimColour: dimColour)
        host.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: host.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        overlay.alpha = 0
        overlay.loader.startAnimating()
        UIView.animate(withDuration: 0.2) { overlay.alpha = 1 }
        return overlay
    }

    /// Fades the overlay out, stops the loader, and removes it.
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        let tearDown = {
            self.loader.stopAnimating()
            self.removeFromSuperview()
            completion?()
        }
        guard animated else { tearDown(); return }
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in tearDown() }
    }
}
