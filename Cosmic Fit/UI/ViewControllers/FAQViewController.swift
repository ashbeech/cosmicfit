//
//  FAQViewController.swift
//  Cosmic Fit
//
//  Comprehensive FAQ page for Cosmic Fit users
//

import UIKit

class FAQViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        CosmicFitTheme.styleScrollView(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60), // Space for close button
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Title - matching Blueprint page style
        titleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Use attributed string for custom line height like Blueprint
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.85
        paragraphStyle.alignment = .center
        
        let attributedText = NSAttributedString(
            string: "FREQUENTLY ASKED\nQUESTIONS",
            attributes: [
                .font: CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.pageTitle),
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        titleLabel.attributedText = attributedText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
        ])
        
        // Add FAQ items
        setupFAQItems()
    }
    
    private func setupFAQItems() {
        let faqs: [(question: String, answer: String)] = [
            (
                question: "What is Cosmic Fit?",
                answer: "Cosmic Fit translates your astrological birth chart into personalized style guidance. By analyzing the unique planetary positions at the moment of your birth, we uncover your energetic signature and help you express it through clothing choices that feel authentic and empowering."
            ),
            (
                question: "How does the birth chart connect to style?",
                answer: "Your natal chart reveals your core energy patterns—how you show up in the world, what makes you feel confident, and where you naturally shine. We translate those cosmic themes into tangible style elements: fabrics, colours, silhouettes, and styling approaches that align with your innate energy."
            ),
            (
                question: "What's the \"Daily Fit\"?",
                answer: "Each day, the planets move into new positions, creating fresh energetic weather. Your Daily Fit is a personalized outfit interpretation based on how today's cosmic climate interacts with your birth chart. Think of it as styling advice that honors both who you are and what the day calls for."
            ),
            (
                question: "Do I need to know astrology to use this?",
                answer: "Not at all. We handle the astrology—you focus on getting dressed. If you're curious, the app offers deeper explanations, but you can also simply enjoy the style guidance without needing to understand planetary transits or house placements."
            ),
            (
                question: "How accurate is the birth time requirement?",
                answer: "Birth time affects your Rising sign and house placements, which influence how you present yourself to the world. The more accurate your birth time, the more precise your interpretation. Even an approximate time (within an hour or two) can still yield meaningful insights, though exact timing is ideal."
            ),
            (
                question: "Can I change my birth information later?",
                answer: "Yes. Go to your Profile page to update your birth details. Keep in mind that changing your birth time or location will affect your chart and may shift your style recommendations."
            ),
            (
                question: "Is this just for women?",
                answer: "Not at all. Cosmic Fit is for anyone interested in aligning their personal style with their energetic blueprint, regardless of gender. The guidance adapts to your unique chart and can be interpreted across any style spectrum."
            ),
            (
                question: "What if I don't like the outfit suggestion?",
                answer: "Your Daily Fit is meant to inspire, not dictate. Think of it as a creative prompt. You might take just one element—a colour, a texture, an accessory choice—and build from there. The goal is alignment with your energy, not rigid adherence to a specific look."
            ),
            (
                question: "How often does my Daily Fit change?",
                answer: "Your Daily Fit updates every day based on the current planetary transits and how they interact with your natal chart. Each morning brings fresh cosmic energy and fresh styling guidance."
            ),
            (
                question: "Can I see past Daily Fits?",
                answer: "Currently, the app focuses on today's guidance. We're exploring ways to offer a history view in future updates, so you can revisit past interpretations and track patterns in your cosmic style evolution."
            ),
            (
                question: "What's the difference between the Daily Fit and my Cosmic Blueprint?",
                answer: "Your Cosmic Blueprint is your foundational style DNA—timeless guidance based on your birth chart. It doesn't change. Your Daily Fit is how that foundation responds to the current cosmic weather. One is your core; the other is your daily expression of it."
            ),
            (
                question: "How do I interpret the \"vibe breakdown\" percentages?",
                answer: "The vibe breakdown shows how different style energies (like Classic, Playful, Romantic) blend in today's outfit suggestion. Higher percentages mean that energy is more prominent. It's a quick snapshot of the outfit's overall feel."
            ),
            (
                question: "Can I share my readings with friends?",
                answer: "Not directly within the app yet, but you can always screenshot your Daily Fit or Blueprint and share it however you like. Just remember: their chart is different, so their cosmic style will be too."
            ),
            (
                question: "Does Cosmic Fit replace a personal stylist?",
                answer: "Not exactly—it's a different tool. A human stylist brings expertise, shopping knowledge, and hands-on help. Cosmic Fit adds the energetic and intuitive layer. Use both if you can—they enhance each other."
            ),
            (
                question: "Can I share my Daily Fit with friends?",
                answer: "While everyone's cosmic guidance is deeply personal, sharing your interpretation and how you styled it can be fun! Just remember—their chart is different, so the same day's energy might call for completely different outfit guidance for them."
            )
        ]
        
        var previousView: UIView = titleLabel
        
        for (index, faq) in faqs.enumerated() {
            let faqView = createFAQView(question: faq.question, answer: faq.answer)
            contentView.addSubview(faqView)
            
            NSLayoutConstraint.activate([
                faqView.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 32),
                faqView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
                faqView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
            ])
            
            previousView = faqView
            
            if index == faqs.count - 1 {
                NSLayoutConstraint.activate([
                    faqView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
                ])
            }
        }
    }
    
    private func createFAQView(question: String, answer: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Question - using DMSerifText like Blueprint headings
        let questionLabel = UILabel()
        questionLabel.text = question
        questionLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.title3, weight: .bold)
        questionLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(questionLabel)
        
        // Answer - using DMSerifText like Blueprint body text
        let answerLabel = UILabel()
        answerLabel.text = answer
        answerLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        answerLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        answerLabel.numberOfLines = 0
        answerLabel.lineBreakMode = .byWordWrapping
        answerLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(answerLabel)
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: container.topAnchor),
            questionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            questionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            answerLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            answerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            answerLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            answerLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
}
