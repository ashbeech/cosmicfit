//
//  DosAndDontsSectionView.swift
//  Cosmic Fit
//
//  Custom component for Do's & Don'ts sections with star icon and bullet points
//

import UIKit

final class DosAndDontsSectionView: UIView {
    
    private let sectionTitle: String
    private let bulletPoints: [String]
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    init(title: String, bulletPoints: [String]) {
        self.sectionTitle = title
        self.bulletPoints = bulletPoints
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // Add heading with star icon
        let headingContainer = createHeadingContainer()
        stackView.addArrangedSubview(headingContainer)
        
        // Add bullet points
        for bulletText in bulletPoints {
            let bulletLabel = createBulletPoint(text: bulletText)
            stackView.addArrangedSubview(bulletLabel)
        }
    }
    
    private func createHeadingContainer() -> UIView {
        // Outer container for padding
        let outerContainer = UIView()
        outerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Inner container for star + title
        let innerContainer = UIView()
        innerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Star icon (✦)
        let starLabel = UILabel()
        starLabel.text = "✦"
        starLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleSymbolLabel(starLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title3)

        // Title (italic)
        let titleLabel = UILabel()
        titleLabel.text = sectionTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleSubsectionLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title3, italic: true)
        
        innerContainer.addSubview(starLabel)
        innerContainer.addSubview(titleLabel)
        outerContainer.addSubview(innerContainer)
        
        NSLayoutConstraint.activate([
            // Inner container with 10% padding (80% width, centered)
            innerContainer.topAnchor.constraint(equalTo: outerContainer.topAnchor),
            innerContainer.bottomAnchor.constraint(equalTo: outerContainer.bottomAnchor),
            innerContainer.widthAnchor.constraint(equalTo: outerContainer.widthAnchor, multiplier: 0.8),
            innerContainer.centerXAnchor.constraint(equalTo: outerContainer.centerXAnchor),
            
            // Star and title within inner container
            starLabel.leadingAnchor.constraint(equalTo: innerContainer.leadingAnchor),
            starLabel.topAnchor.constraint(equalTo: innerContainer.topAnchor),
            starLabel.bottomAnchor.constraint(equalTo: innerContainer.bottomAnchor),
            starLabel.widthAnchor.constraint(equalToConstant: 18),
            
            titleLabel.leadingAnchor.constraint(equalTo: starLabel.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: innerContainer.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: starLabel.centerYAnchor),
            
            innerContainer.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return outerContainer
    }
    
    private func createBulletPoint(text: String) -> UIView {
        // Create container for padding
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        
        // Create attributed string with bullet
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20 // Indent for wrapped text
        paragraphStyle.firstLineHeadIndent = 0
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular),
            .foregroundColor: CosmicFitTheme.Colors.cosmicBlue,
            .paragraphStyle: paragraphStyle
        ]
        
        let bulletText = "• \(text)"
        label.attributedText = NSAttributedString(string: bulletText, attributes: attributes)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        // Add 10% padding on each side (80% width, centered)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
    }
}
