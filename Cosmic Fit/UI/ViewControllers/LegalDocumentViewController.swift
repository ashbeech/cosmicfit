//
//  LegalDocumentViewController.swift
//  Cosmic Fit
//
//  Scrollable legal document page used for Terms of Use and Privacy Policy.
//

import UIKit

class LegalDocumentViewController: UIViewController {

    private enum Layout {
        static let horizontalMargin: CGFloat = 32
        static let bodyTextExtraInset: CGFloat = 10
        static let scrollTopInset: CGFloat = 60
        static let contentViewTopInset: CGFloat = 8
        static let eyebrowTop: CGFloat = 20
        static let eyebrowToTitle: CGFloat = 20
        static let titleToUpdated: CGFloat = 16
        static let updatedToNotice: CGFloat = 20
        static let noticeToDivider: CGFloat = 28
        static let dividerToStack: CGFloat = 32
        static let sectionSpacing: CGFloat = 28
        static let subsectionTitleSpacing: CGFloat = 12
        static let paragraphSpacing: CGFloat = 10
        static let bulletSpacing: CGFloat = 8
        static let bottomDividerTop: CGFloat = 40
        static let bottomInset: CGFloat = 40
    }

    private let configuration: LegalDocumentConfiguration

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let updatedLabel = UILabel()
    private let noticeContainer = UIView()
    private let noticeLabel = UILabel()
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

    init(configuration: LegalDocumentConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

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
        CosmicFitTheme.stylePageEyebrowLabel(eyebrowLabel, text: "COSMIC FIT", color: CosmicFitTheme.Colours.cosmicBlue)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.title1,
            weight: .bold
        )
        titleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = configuration.pageTitle

        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .semibold)
        updatedLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        updatedLabel.textAlignment = .center
        updatedLabel.numberOfLines = 0
        updatedLabel.text = configuration.dateLine

        noticeContainer.translatesAutoresizingMaskIntoConstraints = false
        noticeContainer.backgroundColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.06)
        noticeContainer.layer.cornerRadius = 10
        noticeContainer.layer.borderWidth = 1
        noticeContainer.layer.borderColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.15).cgColor
        noticeContainer.isHidden = configuration.importantNotice == nil

        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        noticeLabel.numberOfLines = 0
        if let notice = configuration.importantNotice {
            noticeLabel.attributedText = bodyAttributedText(notice, fontSize: 13, weight: .medium)
        }

        topDivider.translatesAutoresizingMaskIntoConstraints = false
        topDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = Layout.sectionSpacing
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
        contentView.addSubview(updatedLabel)
        contentView.addSubview(noticeContainer)
        noticeContainer.addSubview(noticeLabel)
        contentView.addSubview(topDivider)
        contentView.addSubview(contentStackView)
        contentView.addSubview(bottomDividerContainer)
        bottomDividerContainer.addSubview(bottomDividerLeft)
        bottomDividerContainer.addSubview(bottomDividerRight)
        bottomDividerContainer.addSubview(starImageView)

        for section in configuration.sections {
            contentStackView.addArrangedSubview(makeSectionView(section))
        }

        let dividerTopAnchor: NSLayoutYAxisAnchor
        let dividerTopConstant: CGFloat
        if configuration.importantNotice != nil {
            dividerTopAnchor = noticeContainer.bottomAnchor
            dividerTopConstant = Layout.noticeToDivider
        } else {
            dividerTopAnchor = updatedLabel.bottomAnchor
            dividerTopConstant = Layout.updatedToNotice
        }

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

            updatedLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToUpdated),
            updatedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            updatedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),

            noticeContainer.topAnchor.constraint(equalTo: updatedLabel.bottomAnchor, constant: Layout.updatedToNotice),
            noticeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            noticeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),

            noticeLabel.topAnchor.constraint(equalTo: noticeContainer.topAnchor, constant: 14),
            noticeLabel.leadingAnchor.constraint(equalTo: noticeContainer.leadingAnchor, constant: 14),
            noticeLabel.trailingAnchor.constraint(equalTo: noticeContainer.trailingAnchor, constant: -14),
            noticeLabel.bottomAnchor.constraint(equalTo: noticeContainer.bottomAnchor, constant: -14),

            topDivider.topAnchor.constraint(equalTo: dividerTopAnchor, constant: dividerTopConstant),
            topDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalMargin),
            topDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalMargin),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            contentStackView.topAnchor.constraint(equalTo: topDivider.bottomAnchor, constant: Layout.dividerToStack),
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

    private func makeSectionView(_ section: LegalDocumentSection) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = Layout.subsectionTitleSpacing
        container.alignment = .fill

        container.addArrangedSubview(makeSectionTitleLabel(section.title))

        for paragraph in section.paragraphs {
            container.addArrangedSubview(makeBodyLabel(paragraph))
        }

        if !section.bullets.isEmpty {
            container.addArrangedSubview(makeBulletBlock(section.bullets))
        }

        for subsection in section.subsections {
            container.addArrangedSubview(makeSubsectionView(subsection))
        }

        return container
    }

    private func makeSubsectionView(_ subsection: LegalDocumentSubsection) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = Layout.paragraphSpacing
        container.alignment = .fill
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)

        container.addArrangedSubview(makeSubsectionTitleLabel(subsection.title))

        for paragraph in subsection.paragraphs {
            container.addArrangedSubview(makeBodyLabel(paragraph))
        }

        if !subsection.bullets.isEmpty {
            container.addArrangedSubview(makeBulletBlock(subsection.bullets))
        }

        return container
    }

    private func makeSectionTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = CosmicFitTheme.Typography.DMSerifTextFont(
            size: CosmicFitTheme.Typography.FontSizes.title3,
            weight: .semibold
        )
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.text = text
        return label
    }

    private func makeSubsectionTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.headline,
            weight: .semibold
        )
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.text = text
        return label
    }

    private func makeBodyLabel(_ text: String) -> UIView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.attributedText = bodyAttributedText(text)
        textView.linkTextAttributes = [
            .foregroundColor: CosmicFitTheme.Colours.cosmicLilac,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.delegate = self
        return textView
    }

    private func makeBulletBlock(_ bullets: [String]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Layout.bulletSpacing
        stack.alignment = .fill

        for bullet in bullets {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 8

            let dash = UILabel()
            dash.text = "—"
            dash.font = CosmicFitTheme.Typography.dmSansFont(size: 14, weight: .medium)
            dash.textColor = CosmicFitTheme.Colours.cosmicLilac
            dash.setContentHuggingPriority(.required, for: .horizontal)

            let textLabel = UILabel()
            textLabel.numberOfLines = 0
            textLabel.attributedText = bodyAttributedText(
                bullet,
                fontSize: CosmicFitTheme.Typography.FontSizes.callout
            )

            row.addArrangedSubview(dash)
            row.addArrangedSubview(textLabel)
            stack.addArrangedSubview(row)
        }

        let wrapper = UIStackView(arrangedSubviews: [stack])
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Layout.bodyTextExtraInset,
            bottom: 0,
            right: Layout.bodyTextExtraInset
        )
        return wrapper
    }

    private func bodyAttributedText(
        _ text: String,
        fontSize: CGFloat = CosmicFitTheme.Typography.FontSizes.body,
        weight: UIFont.Weight = .regular
    ) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 8
        style.lineSpacing = 3

        let font = weight == .regular
            ? CosmicFitTheme.Typography.DMSerifTextFont(size: fontSize, weight: .regular)
            : CosmicFitTheme.Typography.dmSansFont(size: fontSize, weight: weight)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CosmicFitTheme.Colours.cosmicBlue,
            .paragraphStyle: style
        ]

        let attributed = NSMutableAttributedString(string: text, attributes: attrs)

        for link in configuration.inlineLinks {
            guard text.contains(link.phrase), let url = URL(string: link.url) else { continue }
            let ns = text as NSString
            var searchRange = NSRange(location: 0, length: ns.length)
            while true {
                let found = ns.range(of: link.phrase, options: [], range: searchRange)
                if found.location == NSNotFound { break }
                attributed.addAttribute(.link, value: url, range: found)
                attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: found)
                let nextLocation = found.location + found.length
                if nextLocation >= ns.length { break }
                searchRange = NSRange(location: nextLocation, length: ns.length - nextLocation)
            }
        }

        return attributed
    }
}

extension LegalDocumentViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        primaryActionFor textItem: UITextItem,
        defaultAction: UIAction
    ) -> UIAction? {
        switch textItem.content {
        case .link(let url):
            return UIAction { _ in UIApplication.shared.open(url) }
        default:
            return defaultAction
        }
    }

    func textView(
        _ textView: UITextView,
        menuConfigurationFor textItem: UITextItem,
        defaultMenu: UIMenu
    ) -> UITextItem.MenuConfiguration? {
        nil
    }
}
