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
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        
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
        
        // Title
        titleLabel.text = "Frequently Asked Questions"
        titleLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        titleLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
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
                answer: "Cosmic Fit translates your astrological birth chart into personalized style guidance. We analyze the planetary positions at your birth to understand your authentic style essence, then give you daily fashion recommendations based on current cosmic energy."
            ),
            (
                question: "How does the Daily Fit work?",
                answer: "Each day, we calculate where the planets are right now (transits) and how they interact with your birth chart. These cosmic conversations create specific energetic themes that translate into style guidance—colors, textures, silhouettes, and mood."
            ),
            (
                question: "Why does the Daily Fit consider weather?",
                answer: "Real style exists in the physical world. Cosmic energy is beautiful, but it needs to meet you where you are—literally. We factor in your local weather so the guidance is actually wearable, not just conceptual."
            ),
            (
                question: "Can my Cosmic Blueprint change?",
                answer: "Your natal chart (birth blueprint) stays constant—it's your foundation. However, progressed planets show how you evolve over time, which is why we show both your core essence and your current phase in the Blueprint."
            ),
            (
                question: "What are transits and why do they matter?",
                answer: "Transits are where planets are right now, creating temporary energy shifts that influence your mood, energy, and yes—your style needs. Today's Mars-Venus aspect might make you crave bolder colors than usual, even if your blueprint skews minimalist."
            ),
            (
                question: "How do the tarot cards connect to fashion?",
                answer: "Each tarot card carries archetypal energy that translates beautifully into aesthetic language. The Tower's transformation becomes dramatic silhouettes. The Hermit's introspection becomes cocooning layers. We've mapped the entire deck to style guidance."
            ),
            (
                question: "What are the vibe percentages (Classic, Playful, Edge, etc.)?",
                answer: "These show the energetic breakdown of today's recommendations. High Drama + High Edge might mean leather and structure. High Romantic + High Playful suggests soft colors and flowing shapes. It's cosmic mood boarding."
            ),
            (
                question: "Why does my Daily Fit sometimes contradict my Blueprint?",
                answer: "That's the magic! Your Blueprint is who you are at your core. Your Daily Fit is responding to today's energy. Sometimes growth means dressing outside your comfort zone. Sometimes cosmic weather calls for a different vibe. Trust both."
            ),
            (
                question: "Can I use Cosmic Fit if I don't believe in astrology?",
                answer: "Absolutely. Think of it as a creative framework for exploring your style. Even if you're skeptical about planets, you might find the daily prompts help you break out of fashion ruts and try new combinations."
            ),
            (
                question: "How is this different from just reading my horoscope?",
                answer: "Generic horoscopes give the same advice to millions of people. Cosmic Fit analyzes YOUR specific birth chart, considers YOUR current transits, and gives YOU personalized fashion guidance. It's the difference between a form letter and a personal stylist."
            ),
            (
                question: "Is my birth data private?",
                answer: "Yes. Your birth data is stored locally on your device and used solely to calculate your chart. We don't share, sell, or use your personal information for anything beyond giving you cosmic style guidance."
            ),
            (
                question: "Can I use Cosmic Fit for special occasions?",
                answer: "Definitely! The Blueprint section includes special occasion guidance. You can also check your Daily Fit on the morning of an event—cosmic timing matters, and dressing in flow with that day's energy adds another layer of intentionality."
            ),
            (
                question: "What if multiple style elements seem contradictory?",
                answer: "Contradiction is where interesting style lives! 'Protective but fluid' might mean a soft trench coat. 'Bold yet refined' could be a statement minimalist piece. The tension between elements creates your unique look."
            ),
            (
                question: "How much should I invest in following these recommendations?",
                answer: "You don't need to buy anything new. Cosmic Fit works with your existing wardrobe—we're helping you see what you already own through a new lens and combine pieces in ways aligned with your energy."
            ),
            (
                question: "Does Cosmic Fit replace working with a personal stylist?",
                answer: "We're complementary, not competitive. A human stylist brings expertise, shopping knowledge, and hands-on help. Cosmic Fit adds the energetic and intuitive layer. Use both if you can—they enhance each other."
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
        
        let questionLabel = UILabel()
        questionLabel.text = question
        questionLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.headline, weight: .bold)
        questionLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(questionLabel)
        
        let answerLabel = UILabel()
        answerLabel.text = answer
        answerLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        answerLabel.textColor = CosmicFitTheme.Colors.cosmicBlue
        answerLabel.numberOfLines = 0
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
