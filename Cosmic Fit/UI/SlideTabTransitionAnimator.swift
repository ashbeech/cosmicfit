//
//  SlideTabTransitionAnimator.swift
//  Cosmic Fit
//
//  Created by [Your Name] on [Date]
//

import UIKit

// MARK: - Custom Tab Transition Animator
class SlideTabTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let isPresenting: Bool
    private let direction: SlideDirection
    
    enum SlideDirection {
        case left, right
    }
    
    init(isPresenting: Bool, direction: SlideDirection) {
        self.isPresenting = isPresenting
        self.direction = direction
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let screenBounds = containerView.bounds
        
        // Ensure both views have proper frames
        fromVC.view.frame = screenBounds
        toVC.view.frame = screenBounds
        
        // Ensure content is loaded before transition
        toVC.view.layoutIfNeeded()
        
        // Handle Daily Fit specific setup
        if let navController = toVC as? UINavigationController,
           let dailyFitVC = navController.topViewController as? DailyFitViewController {
            dailyFitVC.prepareForTransition()
        }
        
        // Set initial position for incoming view
        let slideDistance = screenBounds.width
        switch direction {
        case .left:
            toVC.view.transform = CGAffineTransform(translationX: slideDistance, y: 0)
        case .right:
            toVC.view.transform = CGAffineTransform(translationX: -slideDistance, y: 0)
        }
        
        // Add both views to container
        containerView.addSubview(toVC.view)
        
        // Animate the transition
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut],
            animations: {
                // Slide views to final positions
                switch self.direction {
                case .left:
                    fromVC.view.transform = CGAffineTransform(translationX: -slideDistance, y: 0)
                case .right:
                    fromVC.view.transform = CGAffineTransform(translationX: slideDistance, y: 0)
                }
                toVC.view.transform = .identity
            },
            completion: { finished in
                // Reset transforms
                fromVC.view.transform = .identity
                toVC.view.transform = .identity
                
                // Complete transition
                transitionContext.completeTransition(finished)
                
                // Handle Daily Fit post-transition
                if let navController = toVC as? UINavigationController,
                   let dailyFitVC = navController.topViewController as? DailyFitViewController {
                    dailyFitVC.finishTransition()
                }
            }
        )
    }
}
