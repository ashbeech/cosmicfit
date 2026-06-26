//
//  FAQViewController.swift
//  Cosmic Fit
//
//  Comprehensive FAQ page for Cosmic Fit users
//

import UIKit

class FAQViewController: UIViewController {

    // MARK: - Layout (aligned with StyleGuideDetailViewController + Profile / Daily Fit margins)

    private enum Layout {
        /// Profile, Daily Fit text column, GenericDetail close clearance
        static let horizontalMargin: CGFloat = 32
        /// Style Guide detail: body label inset inside the margin
        static let bodyTextExtraInset: CGFloat = 10
        static let scrollTopInset: CGFloat = 60
        static let contentViewTopInset: CGFloat = 8
        static let eyebrowTop: CGFloat = 20
        static let eyebrowToTitle: CGFloat = 20
        static let titleToTopDivider: CGFloat = 40
        static let topDividerToStack: CGFloat = 40
        /// Space between the previous answer and the next section's hairline (stack spacing)
        static let stackSpacingBetweenFAQs: CGFloat = 32
        /// Space from hairline down to the next question
        static let dividerToQuestion: CGFloat = 28
        /// Space from question label bottom to answer label top.
        static let questionToAnswer: CGFloat = 22
        static let bottomDividerTop: CGFloat = 40
        static let bottomInset: CGFloat = CosmicFitTheme.Layout.scrollContentBottomInset
    }

    // MARK: - Properties

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let topDivider = UIView()
    private let contentStackView = UIStackView()
    private let bottomDividerContainer = UIView()
    private let bottomDividerLeft = UIView()
    private let bottomDividerRight = UIView()
    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "star_icon_placeholder")
        iv.tintColor = CosmicFitTheme.Colours.cosmicBlue
        return iv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        CosmicFitTheme.styleScrollView(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false

        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false
        eyebrowLabel.textAlignment = .center
        eyebrowLabel.numberOfLines = 0
        let eyebrowAttrs: [NSAttributedString.Key: Any] = [
            .font: CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.sectionHeader, weight: .bold),
            .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
            .kern: 1.75
        ]
        eyebrowLabel.attributedText = NSAttributedString(string: "COSMIC FIT", attributes: eyebrowAttrs)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(size: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        titleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = "Frequently Asked Questions"

        topDivider.translatesAutoresizingMaskIntoConstraints = false
        topDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = Layout.stackSpacingBetweenFAQs
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill

        bottomDividerContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerContainer.backgroundColor = .clear
        bottomDividerLeft.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerRight.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerLeft.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        bottomDividerRight.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        starImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(eyebrowLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(topDivider)
        contentView.addSubview(contentStackView)
        contentView.addSubview(bottomDividerContainer)
        bottomDividerContainer.addSubview(bottomDividerLeft)
        bottomDividerContainer.addSubview(bottomDividerRight)
        bottomDividerContainer.addSubview(starImageView)

        populateFAQStack()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Layout.scrollTopInset),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Layout.contentViewTopInset),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            eyebrowLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.eyebrowTop),
            eyebrowLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: eyebrowLabel.bottomAnchor, constant: Layout.eyebrowToTitle),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),

            topDivider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToTopDivider),
            topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            contentStackView.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: Layout.topDividerToStack),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),

            bottomDividerContainer.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: Layout.bottomDividerTop),
            bottomDividerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            bottomDividerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),
            bottomDividerContainer.heightAnchor.constraint(equalToConstant: 30),
            bottomDividerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.bottomInset),

            bottomDividerLeft.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerLeft.leadingAnchor.constraint(equalTo: bottomDividerContainer.leadingAnchor),
            bottomDividerLeft.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -10),
            bottomDividerLeft.heightAnchor.constraint(equalToConstant: 1),

            bottomDividerRight.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            bottomDividerRight.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 10),
            bottomDividerRight.trailingAnchor.constraint(equalTo: bottomDividerContainer.trailingAnchor),
            bottomDividerRight.heightAnchor.constraint(equalToConstant: 1),

            starImageView.centerXAnchor.constraint(equalTo: bottomDividerContainer.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: bottomDividerContainer.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 24),
            starImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func populateFAQStack() {
        let faqs: [(question: String, answer: String)] = [
            (
                question: "What is Cosmic Fit?",
                answer: "Cosmic Fit translates your astrological birth chart into personalized style guidance. By analyzing the unique planetary positions at the moment of your birth, we uncover your energetic signature and help you express it through clothing choices that feel authentic and empowering."
            ),
            (
                question: "How does the birth chart connect to style?",
                answer: "Your natal chart reveals your core energy patterns; how you show up in the world, what makes you feel confident, and where you naturally shine. We translate those cosmic themes into tangible style elements: fabrics, colours, silhouettes, and styling approaches that align with your innate energy."
            ),
            (
                question: "What's the \"Daily Fit\"?",
                answer: "Each day, the planets move into new positions, creating fresh energetic weather. Your Daily Fit is a personalized outfit interpretation based on how that day's sky interacts with your birth chart; styling advice that honors both who you are and what the moment calls for. You can focus on today and, when you want to plan ahead, preview tomorrow from the same screen."
            ),
            (
                question: "Do I need to know astrology to use this?",
                answer: "Not at all. The app turns chart data into style language, so you never have to parse transits or house systems to get dressed. If you enjoy the technical side, your natal chart and Style Guide sections offer more to explore; if not, you can stay in the outfit guidance and still get the full experience."
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
                question: "What if I don't like the outfit suggestion?",
                answer: "Your Daily Fit is meant to inspire, not dictate. Think of it as a creative prompt. You might take just one element, such as a colour, a texture, or an accessory choice, and build from there. The goal is alignment with your energy, not rigid adherence to a specific look."
            ),
            (
                question: "How often does my Daily Fit change?",
                answer: "Each calendar day gets a new Daily Fit as the transits shift against your chart. Open today's reading anytime, and use tomorrow's preview on the Daily Fit screen when you want to plan ahead; both update with the date, not continuously through the day."
            ),
            (
                question: "Can I see past Daily Fits?",
                answer: "There isn't a history or calendar view yet; Daily Fit is built around today, with an optional look at tomorrow. We're exploring ways to revisit past days in a future update so you can track patterns in your cosmic style over time."
            ),
            (
                question: "What's the difference between the Daily Fit and my Style Guide?",
                answer: "Your Style Guide is your foundational style DNA, timeless guidance drawn from your birth chart and stable from day to day. If you change birth details in Profile, the chart (and Style Guide) can refresh to match. Your Daily Fit is how that foundation meets the current sky: a tarot-led prompt, palette, and notes for the specific day. One is your core reference; the other is today's expression of it."
            ),
            (
                question: "What does the Essence section show?",
                answer: "Essence maps fourteen style energies (for example Classic, Playful, Magnetic, Minimal). For each day we highlight the top three; the radar triangle's shape shows their relative strength compared to each other, not a percentage readout. Think of it as a quick mood board for the outfit's attitude."
            ),
            (
                question: "Can I share my Daily Fit or Style Guide?",
                answer: "There's no in-app share button yet, but screenshots work well. Everyone's chart is different, so what the app suggests for you on a given day may not match what it would suggest for a friend; sharing is still a fun way to compare notes on how you each styled the day."
            )
        ]

        for (index, faq) in faqs.enumerated() {
            contentStackView.addArrangedSubview(
                createFAQBlock(question: faq.question, answer: faq.answer, isFirst: index == 0)
            )
        }
    }

    private func createFAQBlock(question: String, answer: String, isFirst: Bool) -> UIView {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        var questionTopAnchor: NSLayoutYAxisAnchor = block.topAnchor
        var questionTopConstant: CGFloat = 0

        if !isFirst {
            let divider = UIView()
            divider.translatesAutoresizingMaskIntoConstraints = false
            CosmicFitTheme.styleDivider(divider)
            block.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: block.topAnchor),
                divider.leadingAnchor.constraint(equalTo: block.leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: block.trailingAnchor),
                divider.heightAnchor.constraint(equalToConstant: 1)
            ])
            questionTopAnchor = divider.bottomAnchor
            questionTopConstant = Layout.dividerToQuestion
        }

        let questionLabel = UILabel()
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .left
        questionLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.headline,
            weight: .semibold
        )
        questionLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        questionLabel.text = question

        let answerLabel = UILabel()
        answerLabel.translatesAutoresizingMaskIntoConstraints = false
        answerLabel.attributedText = Self.bodyAttributedText(answer)
        answerLabel.textAlignment = .left
        answerLabel.numberOfLines = 0
        answerLabel.lineBreakMode = .byWordWrapping

        block.addSubview(questionLabel)
        block.addSubview(answerLabel)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: questionTopAnchor, constant: questionTopConstant),
            questionLabel.leadingAnchor.constraint(equalTo: block.leadingAnchor),
            questionLabel.trailingAnchor.constraint(equalTo: block.trailingAnchor),

            answerLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: Layout.questionToAnswer),
            answerLabel.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: Layout.bodyTextExtraInset),
            answerLabel.trailingAnchor.constraint(equalTo: block.trailingAnchor, constant: -Layout.bodyTextExtraInset),
            answerLabel.bottomAnchor.constraint(equalTo: block.bottomAnchor)
        ])

        return block
    }

    // MARK: - Body typography (matches StyleGuideDetailViewController)

    private static let sentencesPerParagraph = 2

    private static func bodyAttributedText(_ text: String) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 8
        style.lineSpacing = 3

        let font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.body,
            weight: .regular
        )

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
            .paragraphStyle: style
        ]

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains("\n\n") {
            return NSAttributedString(string: trimmed, attributes: attrs)
        }

        let sentences = splitIntoSentences(trimmed)
        guard sentences.count > sentencesPerParagraph else {
            return NSAttributedString(string: trimmed, attributes: attrs)
        }

        var paragraphs: [String] = []
        for start in stride(from: 0, to: sentences.count, by: sentencesPerParagraph) {
            let end = min(start + sentencesPerParagraph, sentences.count)
            paragraphs.append(sentences[start..<end].joined(separator: " "))
        }

        return NSAttributedString(string: paragraphs.joined(separator: "\n"), attributes: attrs)
    }

    private static func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(
            in: text.startIndex...,
            options: .bySentences
        ) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespaces), !s.isEmpty {
                sentences.append(s)
            }
        }
        return sentences
    }
}
