//
//  StarView.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import UIKit

class StarView: UIView {
    // MARK: - Properties
    private let starLayer = CAShapeLayer()
    private var starSize: CGFloat = 20
    private var points: Int = 4 // Number of points on the star
    
    // MARK: - Initialization
    init(frame: CGRect, size: CGFloat, points: Int, color: UIColor) {
        self.starSize = size
        self.points = points
        super.init(frame: frame)
        
        setupStar(color: color)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Setup
    private func setupStar(color: UIColor) {
        starLayer.fillColor = color.cgColor
        starLayer.path = createStarPath().cgPath
        layer.addSublayer(starLayer)
        
        // Start invisible
        alpha = 0
    }
    
    private func createStarPath() -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: starSize/2, y: starSize/2)
        let outerRadius = starSize/2
        let innerRadius = outerRadius * 0.4
        
        let angleIncrement = CGFloat.pi * 2 / CGFloat(points)
        
        // Start at the top point
        var currentAngle = -CGFloat.pi / 2
        
        // Move to the first point
        let firstOuterPoint = CGPoint(
            x: center.x + outerRadius * cos(currentAngle),
            y: center.y + outerRadius * sin(currentAngle)
        )
        path.move(to: firstOuterPoint)
        
        // Draw the star
        for _ in 0..<points {
            // Move to inner point
            currentAngle += angleIncrement / 2
            let innerPoint = CGPoint(
                x: center.x + innerRadius * cos(currentAngle),
                y: center.y + innerRadius * sin(currentAngle)
            )
            path.addLine(to: innerPoint)
            
            // Move to next outer point
            currentAngle += angleIncrement / 2
            let outerPoint = CGPoint(
                x: center.x + outerRadius * cos(currentAngle),
                y: center.y + outerRadius * sin(currentAngle)
            )
            path.addLine(to: outerPoint)
        }
        
        path.close()
        return path
    }
    
    // MARK: - Animations
    func fadeIn(delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.8, delay: delay, options: [], animations: {
            self.alpha = 1.0
        }) { _ in
            completion?()
        }
    }
    
    func addTwinkleAnimation() {
        // Scale animation
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.2, 1.0, 0.9, 1.0]
        scaleAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        
        // Opacity animation
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1.0, 0.8, 1.0, 0.7, 1.0]
        opacityAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        
        // Group animations
        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opacityAnimation]
        group.duration = 2.0
        group.repeatCount = 1
        
        layer.add(group, forKey: "twinkle")
    }
    
    func rotate(duration: TimeInterval) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = duration
        rotationAnimation.repeatCount = .greatestFiniteMagnitude
        
        layer.add(rotationAnimation, forKey: "rotation")
    }
}
