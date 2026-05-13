//
//  DosAndDontsSectionView.swift
//  Cosmic Fit
//
//  Custom component for Do's & Don'ts sections with star icon and bullet points
//

import UIKit

final class DosAndDontsSectionView: UIView {

    /// Same asset as `EssenceTriangleView` vertex markers (brand div-star, not system/Unicode ornaments).
    private static let headingStarImageName = "star_icon_placeholder"
    
    /// Extra vertical gap between one bullet row and the next (heading → first bullet still uses `stackView.spacing`).
    private static let bulletToBulletSpacing: CGFloat = 22
    
    private let sectionTitle: String
    private let bulletPoints: [String]
    /// When true, the heading uses the branded star image (Daily Fit essence diagram); otherwise the ✦ glyph.
    private let useBrandHeadingStar: Bool
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    init(title: String, bulletPoints: [String], useBrandHeadingStar: Bool = false) {
        self.sectionTitle = title
        self.bulletPoints = bulletPoints
        self.useBrandHeadingStar = useBrandHeadingStar
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
        
        // Add bullet points (tighter under heading, more air between bullets)
        for (index, bulletText) in bulletPoints.enumerated() {
            let bulletLabel = createBulletPoint(text: bulletText)
            stackView.addArrangedSubview(bulletLabel)
            if index < bulletPoints.count - 1 {
                stackView.setCustomSpacing(Self.bulletToBulletSpacing, after: bulletLabel)
            }
        }
    }
    
    private func createHeadingContainer() -> UIView {
        // Outer container for padding
        let outerContainer = UIView()
        outerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Inner container for star + title
        let innerContainer = UIView()
        innerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let starColumn: UIView
        let starWidth: CGFloat
        if useBrandHeadingStar {
            let starImageView = UIImageView()
            starImageView.image = UIImage(named: Self.headingStarImageName)?.withRenderingMode(.alwaysTemplate)
            starImageView.tintColor = CosmicFitTheme.Colours.cosmicBlue
            starImageView.contentMode = .scaleAspectFit
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starColumn = starImageView
            starWidth = 20
        } else {
            let starLabel = UILabel()
            starLabel.text = "✦"
            starLabel.translatesAutoresizingMaskIntoConstraints = false
            CosmicFitTheme.styleSymbolLabel(starLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title3)
            starColumn = starLabel
            starWidth = 18
        }

        // Title (italic)
        let titleLabel = UILabel()
        titleLabel.text = sectionTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleSubsectionLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title3, italic: true)
        
        innerContainer.addSubview(starColumn)
        innerContainer.addSubview(titleLabel)
        outerContainer.addSubview(innerContainer)

        var starConstraints: [NSLayoutConstraint] = [
            starColumn.leadingAnchor.constraint(equalTo: innerContainer.leadingAnchor),
            starColumn.centerYAnchor.constraint(equalTo: innerContainer.centerYAnchor),
            starColumn.widthAnchor.constraint(equalToConstant: starWidth)
        ]
        if useBrandHeadingStar {
            starConstraints.append(starColumn.heightAnchor.constraint(equalToConstant: 20))
        }
        
        NSLayoutConstraint.activate([
            // Inner container: reduced padding - 10px less on each side
            innerContainer.topAnchor.constraint(equalTo: outerContainer.topAnchor),
            innerContainer.bottomAnchor.constraint(equalTo: outerContainer.bottomAnchor),
            innerContainer.leadingAnchor.constraint(equalTo: outerContainer.leadingAnchor, constant: 10),
            innerContainer.trailingAnchor.constraint(equalTo: outerContainer.trailingAnchor, constant: -10),
        ] + starConstraints + [
            titleLabel.leadingAnchor.constraint(equalTo: starColumn.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: innerContainer.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: starColumn.centerYAnchor),
            
            innerContainer.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return outerContainer
    }
    
    private func createBulletPoint(text: String) -> UIView {
        // Outer container for horizontal centering (10% padding)
        let outerContainer = UIView()
        outerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Inner container for bullet alignment
        let innerContainer = UIView()
        innerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        
        let font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.body,
            weight: .regular
        )
        let bulletPrefix = "• "
        let prefixWidth = ceil((bulletPrefix as NSString).size(withAttributes: [.font: font]).width)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = prefixWidth
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
            .paragraphStyle: paragraphStyle
        ]
        
        let bulletText = bulletPrefix + text
        label.attributedText = NSAttributedString(string: bulletText, attributes: attributes)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        innerContainer.addSubview(label)
        outerContainer.addSubview(innerContainer)
        
        NSLayoutConstraint.activate([
            // Inner container: reduced padding - 10px less on each side
            innerContainer.topAnchor.constraint(equalTo: outerContainer.topAnchor),
            innerContainer.bottomAnchor.constraint(equalTo: outerContainer.bottomAnchor),
            innerContainer.leadingAnchor.constraint(equalTo: outerContainer.leadingAnchor, constant: 10),
            innerContainer.trailingAnchor.constraint(equalTo: outerContainer.trailingAnchor, constant: -10),
            
            // Label: pushed in by 24pt to align with star (20pt star width + 4pt gap)
            label.topAnchor.constraint(equalTo: innerContainer.topAnchor),
            label.bottomAnchor.constraint(equalTo: innerContainer.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: innerContainer.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: innerContainer.trailingAnchor)
        ])
        
        return outerContainer
    }
}
