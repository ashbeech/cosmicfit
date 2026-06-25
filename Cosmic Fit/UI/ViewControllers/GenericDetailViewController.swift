//
//  GenericDetailViewController.swift
//  Cosmic Fit
//
//  Generic detail view controller with swipe-to-dismiss for FAQ, Profile, etc.
//

import UIKit

class GenericDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    private(set) var contentViewController: UIViewController
    private var contentStack: [UIViewController] = []
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var initialTouchPoint: CGPoint = .zero
    private var interactiveDismissalInProgress = false
    private var closeButton: UIButton!
    private var contentViewConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization
    init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
        contentStack = [contentViewController]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGesture()
        
        // Set up the dismiss callback if content is ProfileViewController
        if let profileVC = contentViewController as? ProfileViewController {
            profileVC.onDismissRequested = { [weak self] in
                print("🔍 GenericDetailViewController received dismiss request")
                self?.closeButtonTapped()
            }
        }
    }
    
    // MARK: - UI Components
    private let shadowContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 6
        return view
    }()

    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.cgColor
        return view
    }()

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Shadow container
        shadowContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shadowContainerView)
        
        // Card container (inside shadow container)
        cardContainerView.translatesAutoresizingMaskIntoConstraints = false
        shadowContainerView.addSubview(cardContainerView)
        
        NSLayoutConstraint.activate([
            shadowContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            shadowContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            cardContainerView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            cardContainerView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor)
        ])
        
        // Add content view controller
        installContentViewController(contentViewController)
        
        // Add close button
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = CosmicFitTheme.Colours.cosmicBlue
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        cardContainerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        updateNavigationChrome()
    }

    /// Pushes another content screen inside this detail sheet, keeping the tab bar visible.
    func pushContentViewController(_ viewController: UIViewController, animated: Bool = true) {
        let outgoing = contentViewController
        contentStack.append(viewController)
        contentViewController = viewController

        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        cardContainerView.insertSubview(viewController.view, belowSubview: closeButton)
        viewController.didMove(toParent: self)

        NSLayoutConstraint.deactivate(contentViewConstraints)
        contentViewConstraints = contentConstraints(for: viewController.view)
        NSLayoutConstraint.activate(contentViewConstraints)

        outgoing.view.isHidden = true

        if animated {
            let offset = view.bounds.width * 0.12
            viewController.view.alpha = 0
            viewController.view.transform = CGAffineTransform(translationX: offset, y: 0)
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                viewController.view.alpha = 1
                viewController.view.transform = .identity
            }
        }

        updateNavigationChrome()
    }

    func popContentViewController(animated: Bool = true) {
        guard contentStack.count > 1 else { return }

        let departing = contentStack.removeLast()
        removeChildViewController(departing)
        NSLayoutConstraint.deactivate(contentViewConstraints)
        contentViewConstraints = []

        guard let previous = contentStack.last else { return }
        contentViewController = previous
        previous.view.isHidden = false

        contentViewConstraints = contentConstraints(for: previous.view)
        NSLayoutConstraint.activate(contentViewConstraints)

        if animated {
            previous.view.alpha = 0.85
            previous.view.transform = CGAffineTransform(translationX: -view.bounds.width * 0.08, y: 0)
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                previous.view.alpha = 1
                previous.view.transform = .identity
            }
        }

        updateNavigationChrome()
    }

    private func installContentViewController(_ viewController: UIViewController) {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        cardContainerView.addSubview(viewController.view)
        viewController.didMove(toParent: self)

        contentViewConstraints = contentConstraints(for: viewController.view)
        NSLayoutConstraint.activate(contentViewConstraints)
    }

    private func contentConstraints(for contentView: UIView) -> [NSLayoutConstraint] {
        [
            contentView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor)
        ]
    }

    private func removeChildViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    private func updateNavigationChrome() {
        let showsBack = contentStack.count > 1
        let symbolName = showsBack ? "chevron.left" : "xmark"
        closeButton.setImage(UIImage(systemName: symbolName), for: .normal)
        closeButton.accessibilityLabel = showsBack ? "Back" : "Close"
    }
    
    private func setupGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Actions
    @objc func closeButtonTapped() {
        if contentStack.count > 1 {
            popContentViewController()
            return
        }
        dismissSelf()
    }
    
    func dismissSelf(completion: (() -> Void)? = nil) {
        if presentingViewController != nil {
            dismiss(animated: true, completion: completion)
            return
        }

        var currentParent: UIViewController? = parent
        while currentParent != nil {
            if let tabBarController = currentParent as? CosmicFitTabBarController {
                tabBarController.dismissDetailViewController(animated: true, completion: completion)
                return
            }
            currentParent = currentParent?.parent
        }
        
        print("⚠️ Could not find CosmicFitTabBarController to dismiss")
        completion?()
    }
    
    // MARK: - Gesture Handling
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let progress = translation.y / view.bounds.height
        
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: view)
            interactiveDismissalInProgress = true
            
        case .changed:
            // Only allow downward drags
            guard translation.y > 0 else {
                shadowContainerView.transform = .identity
                return
            }
            
            // Apply the drag with damping for a natural feel
            let dampingFactor: CGFloat = 0.5
            let dragDistance = translation.y * dampingFactor
            shadowContainerView.transform = CGAffineTransform(translationX: 0, y: dragDistance)
            
        case .ended, .cancelled:
            interactiveDismissalInProgress = false
            
            // Dismiss if dragged down significantly OR with high downward velocity
            let shouldDismiss = (progress > 0.3 || velocity.y > 800) && translation.y > 0
            
            if shouldDismiss {
                animateDismissal(with: velocity.y)
            } else {
                // Snap back to original position
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: [.curveEaseOut, .allowUserInteraction],
                    animations: {
                        self.shadowContainerView.transform = .identity
                    }
                )
            }
            
        default:
            break
        }
    }
    
    private func animateDismissal(with velocity: CGFloat) {
        var currentParent: UIViewController? = parent
        var tabBarController: CosmicFitTabBarController?
        while currentParent != nil {
            if let tbc = currentParent as? CosmicFitTabBarController {
                tabBarController = tbc
                break
            }
            currentParent = currentParent?.parent
        }
        
        guard let tbc = tabBarController else {
            print("⚠️ Could not find CosmicFitTabBarController for dismissal")
            return
        }
        
        let containerHeight = view.bounds.height
        let remainingDistance = containerHeight - shadowContainerView.frame.origin.y
        
        let minimumDuration: TimeInterval = 0.2
        let velocityBasedDuration = TimeInterval(remainingDistance / max(velocity, 500))
        let duration = max(minimumDuration, min(velocityBasedDuration, 0.4))
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction],
            animations: {
                self.shadowContainerView.transform = CGAffineTransform(translationX: 0, y: containerHeight)
                if let dimmingView = tbc.view.subviews.first(where: { $0.backgroundColor == UIColor.black.withAlphaComponent(0.4) }) {
                    dimmingView.alpha = 0
                }
            },
            completion: { _ in
                tbc.dismissDetailViewController(animated: false)
            }
        )
    }
    
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            return scrollView.contentOffset.y <= 0
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return true }
        
        let velocity = panGestureRecognizer.velocity(in: view)
        
        guard velocity.y > 0 else { return false }
        
        // Check if any scroll view is at top
        if let scrollView = findScrollView(in: contentViewController.view), scrollView.contentOffset.y > 0 {
            return false
        }
        
        return abs(velocity.y) > abs(velocity.x) * 2
    }
    
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        return nil
    }
}
