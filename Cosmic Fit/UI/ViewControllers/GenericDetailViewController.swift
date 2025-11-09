//
//  GenericDetailViewController.swift
//  Cosmic Fit
//
//  Generic detail view controller with swipe-to-dismiss for FAQ, Profile, etc.
//

import UIKit

class GenericDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    private let contentViewController: UIViewController
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var initialTouchPoint: CGPoint = .zero
    private var interactiveDismissalInProgress = false
    
    // Expose content view controller type for checking
    var isProfileViewController: Bool {
        return contentViewController is ProfileViewController
    }
    
    // MARK: - Initialization
    init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGesture()
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
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = CosmicFitTheme.Colors.cosmicBlue.cgColor
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
        addChild(contentViewController)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        cardContainerView.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            contentViewController.view.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            contentViewController.view.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor)
        ])
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = CosmicFitTheme.Colors.cosmicBlue
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        cardContainerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Actions
    @objc func closeButtonTapped() {
        dismissSelf()
    }
    
    func dismissSelf() {
        var currentParent: UIViewController? = parent
        while currentParent != nil {
            if let tabBarController = currentParent as? CosmicFitTabBarController {
                tabBarController.dismissDetailViewController(animated: true)
                return
            }
            currentParent = currentParent?.parent
        }
        
        print("⚠️ Could not find CosmicFitTabBarController to dismiss")
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
