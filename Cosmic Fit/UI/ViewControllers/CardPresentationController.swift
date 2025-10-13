//
//  CardPresentationController.swift
//  Cosmic Fit
//
//  Custom presentation controller that keeps the presenting view controller visible
//  and ensures tab bar remains visible
//

import UIKit

final class CardPresentationController: UIPresentationController {
    
    private var tabBarHeight: CGFloat {
        // Get tab bar height from the tab bar controller
        if let tabBarController = presentingViewController as? UITabBarController {
            return tabBarController.tabBar.frame.height
        }
        return 0
    }
    
    override var shouldRemovePresentersView: Bool {
        // CRITICAL: Return false to keep the presenting view controller visible
        return false
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return .zero
        }
        
        // Create a frame that leaves space for the tab bar at the bottom
        let tabBarHeight = self.tabBarHeight
        
        return CGRect(
            x: 0,
            y: 0,
            width: containerView.bounds.width,
            height: containerView.bounds.height - tabBarHeight
        )
    }
}
