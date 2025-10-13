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
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Star icon (✦)
        let starLabel = UILabel()
        starLabel.text = "✦"
        starLabel.font = UIFont.systemFont(ofSize: 16)
        starLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        starLabel.textAlignment = .left
        starLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Title (italic)
        let titleLabel = UILabel()
        titleLabel.text = sectionTitle
        titleLabel.font = UIFont(name: "DMSerifText-Italic", size: 18) ?? UIFont.italicSystemFont(ofSize: 18)
        titleLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(starLabel)
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            starLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            starLabel.topAnchor.constraint(equalTo: container.topAnchor),
            starLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            starLabel.widthAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: starLabel.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: starLabel.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return container
    }
    
    private func createBulletPoint(text: String) -> UILabel {
        let label = UILabel()
        
        // Create attributed string with bullet
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20 // Indent for wrapped text
        paragraphStyle.firstLineHeadIndent = 0
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: CosmicFitTheme.Colors.cosmicBlue,
            .paragraphStyle: paragraphStyle
        ]
        
        let bulletText = "• \(text)"
        label.attributedText = NSAttributedString(string: bulletText, attributes: attributes)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        return label
    }
}
