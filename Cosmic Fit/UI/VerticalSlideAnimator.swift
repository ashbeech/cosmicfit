//
//  VerticalSlideAnimator.swift
//  Cosmic Fit
//
//  Custom vertical slide transition for sub-pages
//  Works with .overCurrentContext to keep tab bar visible
//

import UIKit

final class VerticalSlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum Operation {
        case push  // Slide up from bottom (present)
        case pop   // Slide down to bottom (dismiss)
    }
    
    private let operation: Operation
    private let duration: TimeInterval = 0.35
    
    init(operation: Operation) {
        self.operation = operation
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let screenHeight = containerView.bounds.height
        
        switch operation {
        case .push:
            // Present: slide toVC up from bottom
            toVC.view.frame = containerView.bounds
            toVC.view.transform = CGAffineTransform(translationX: 0, y: screenHeight)
            containerView.addSubview(toVC.view)
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    toVC.view.transform = .identity
                },
                completion: { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
            
        case .pop:
            // Dismiss: slide fromVC down
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    fromVC.view.transform = CGAffineTransform(translationX: 0, y: screenHeight)
                },
                completion: { finished in
                    fromVC.view.transform = .identity
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        }
    }
}
