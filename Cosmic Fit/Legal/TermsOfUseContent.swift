//
//  TermsOfUseContent.swift
//  Cosmic Fit
//
//  Terms of Use copy shared by the in-app page and web/terms/index.html.
//

import Foundation

enum TermsOfUseContent {
    static let lastUpdated = "June 24, 2026"
    static let termsOfUseURL = "https://cosmicfit.app/terms"
    static let privacyPolicyURL = "https://cosmicfit.app/privacy"
    static let supportEmail = "help@cosmicfit.app"
    static let noticeEmail = "help@cosmicfit.app"

    typealias Section = LegalDocumentSection
    typealias Subsection = LegalDocumentSubsection

    static var configuration: LegalDocumentConfiguration {
        LegalDocumentConfiguration(
            pageTitle: "Terms of Use",
            dateLine: "Last Updated: \(lastUpdated)",
            importantNotice: importantNotice,
            sections: sections,
            inlineLinks: [
                LegalDocumentLink(phrase: "Privacy Policy", url: privacyPolicyURL)
            ]
        )
    }

    static let importantNotice = """
    IMPORTANT NOTICE: PLEASE READ THESE TERMS OF USE CAREFULLY—THEY AFFECT YOUR LEGAL RIGHTS AND OBLIGATIONS, AND INCLUDE WAIVERS OF RIGHTS AND LIMITATIONS OF LIABILITY. THEY ALSO REQUIRE DISPUTES BETWEEN YOU AND US TO BE RESOLVED THROUGH BINDING INDIVIDUAL ARBITRATION AND TO WAIVE ANY RIGHT TO A JURY TRIAL, CLASS OR COLLECTIVE ACTIONS OR PROCEEDINGS, AND ANY OTHER COURT PROCEEDING OF ANY KIND, SUBJECT TO LIMITED EXCEPTIONS. UNLESS YOU OPT OUT IN ACCORDANCE WITH THE OPT-OUT PROCEDURES DESCRIBED BELOW, YOU WILL BE BOUND BY THESE TERMS. THE FULL TERMS OF THE ARBITRATION AGREEMENT ARE BELOW.
    """

    static let sections: [LegalDocumentSection] = [
        LegalDocumentSection(
            title: "i. Introduction",
            paragraphs: [
                "Welcome to Cosmic Fit.",
                "These Terms of Use (\"Terms\") govern your access to and use of the Cosmic Fit mobile application, related websites, and any other services we make available (collectively, the \"Services\"). Cosmic Fit translates astrological birth-chart data into personalised style guidance, including your Style Guide and Daily Fit.",
                "By downloading, accessing, or using the Services, you agree to these Terms. If you do not agree, do not use the Services.",
                "For information on how we collect, use, and protect personal data, please see our Privacy Policy.",
                "By using the Services, you also acknowledge our Privacy Policy."
            ]
        ),
        LegalDocumentSection(
            title: "ii. Definitions",
            bullets: [
                "\"App Store\" means the third-party store from which you obtained the mobile app, such as the Apple App Store or Google Play Store.",
                "\"App Store Sourced Application\" means a mobile app accessed through or downloaded from the Apple App Store.",
                "\"Company,\" \"we,\" \"our,\" and \"us\" means the operator of Cosmic Fit (cosmicfit.app).",
                "\"Company Parties\" means Company and its predecessors, successors, assigns, parents, subsidiaries, and affiliates.",
                "\"Content\" means text, graphics, images, audio, video, software, data, interpretations, recommendations, and other materials made available through the Services.",
                "\"Dispute\" means any dispute, claim, or controversy between you and Company Parties relating to the Services or these Terms, including the Arbitration Agreement.",
                "\"Licensed Parties\" means Company Parties and their partners, representatives, agents, and licensees.",
                "\"Mobile Application\" means the Cosmic Fit software application for mobile devices.",
                "\"Our Content\" means the Services and Content owned or provided by or on behalf of Company Parties, including style guidance, tarot imagery, datasets, algorithms, and software.",
                "\"Services\" means the Mobile Application, websites, tools, features, and related offerings provided by Company Parties.",
                "\"Subscription\" means a recurring paid plan that grants access to premium features for a defined period and automatically renews until cancelled.",
                "\"Terms\" means these Terms of Use, as updated from time to time.",
                "\"You\" or \"you\" means the individual using the Services, or the entity on whose behalf that individual acts.",
                "\"Your Information\" means information you provide to use the Services, such as your name, email address, birth date, birth time, and birth location."
            ]
        ),
        LegalDocumentSection(
            title: "iii. Your Relationship With Us",
            subsections: [
                LegalDocumentSubsection(
                    title: "A. What You Can Expect From Us",
                    paragraphs: [
                        "Services. We provide astrological style guidance through your Style Guide and Daily Fit. Some features are available without a paid Subscription; others require full access.",
                        "Changes to the Services. We may add, modify, suspend, or remove features at any time. If we make a material change that significantly affects your use of the Services, we will try to notify you when we have your contact information.",
                        "Changes to these Terms. We may update these Terms from time to time. If a change materially affects your rights, we will provide notice when practicable. Your continued use of the Services after changes become effective means you accept the updated Terms."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "B. What We Expect From You",
                    paragraphs: [
                        "Follow applicable rules. Your permission to use the Services lasts only while you comply with these Terms, applicable laws, and any platform terms that apply to your device or app store.",
                        "Provide accurate information. Birth date, birth time, and birth location affect your chart and recommendations. You agree to provide information that is accurate to the best of your knowledge.",
                        "Pay fees you owe. Paid Subscriptions and other purchases are billed through the applicable app store or payment provider. You agree to pay all applicable charges and taxes.",
                        "Feedback. If you submit comments, suggestions, or other feedback, you grant Licensed Parties the right to use that feedback without restriction, payment, or attribution to you.",
                        "By using the Services, you represent and warrant that:"
                    ],
                    bullets: [
                        "You have the legal capacity to enter into these Terms;",
                        "Your use of the Services will not violate any applicable law or third-party rights;",
                        "Your use of the Services is for personal, non-commercial purposes unless we agree otherwise in writing;",
                        "Any information you provide is accurate and does not infringe anyone else's rights."
                    ]
                )
            ]
        ),
        LegalDocumentSection(
            title: "iv. Using the Services",
            subsections: [
                LegalDocumentSubsection(
                    title: "A. Age Requirements",
                    paragraphs: [
                        "You must be at least 13 years old to use the Services. If you are under 18 (or the age of majority where you live), you may use the Services only with the involvement and consent of a parent or legal guardian, who agrees to these Terms on your behalf and is responsible for your activity and any purchases you make."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "B. Accounts and Sign-In",
                    paragraphs: [
                        "You may use much of the Services without creating an account. Optional sign-in via email and one-time passcode lets you sync your profile and Style Guide across devices.",
                        "You are responsible for maintaining the security of your account credentials and for all activity under your account. If you believe your account has been compromised, contact us at \(supportEmail).",
                        "Signing in or out does not by itself grant or revoke a paid Subscription. Subscription status is determined by the app store account used for purchase, promotional access, or other entitlement rules described below."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "C. Free and Premium Access",
                    paragraphs: [
                        "Without a Subscription, you may access a limited preview of the Services, which may include today's Daily Fit and selected Style Guide sections. Premium access unlocks additional Daily Fit previews, the full Style Guide, and related features described in the app.",
                        "We may change which features are free or premium at any time."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "D. Subscriptions and Purchases",
                    paragraphs: [
                        "Cosmic Fit offers auto-renewing Subscriptions, currently including monthly and annual plans, processed through the Apple App Store or Google Play Store (as applicable). Prices are shown in the app before purchase and may vary by region.",
                        "Your Subscription automatically renews unless you cancel at least 24 hours before the end of the current billing period through your app store account settings. Cancellation takes effect at the end of the current period.",
                        "YOU MAY CANCEL YOUR SUBSCRIPTION AT ANY TIME, BUT WE DO NOT PROVIDE REFUNDS FOR FEES ALREADY PAID except where required by applicable law or the applicable app store policy.",
                        "If you purchased through an app store, billing, renewal, cancellation, and refund requests must be handled through that store. Apple and Google are not responsible for the Services themselves.",
                        "We may change Subscription prices from time to time. Any price increase will apply no earlier than the next renewal period after notice as required by applicable law and store rules.",
                        "From time to time we may offer promotional or complimentary access codes. Such access is subject to the terms of the offer, may expire, and does not replace app-store billing rules for separately purchased Subscriptions.",
                        "Deleting your Cosmic Fit profile or account does not cancel an app store Subscription. Billing continues until you cancel with Apple or Google. Reinstalling the app and using the same app store account may restore premium access while a Subscription remains active."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "E. Restore Purchases",
                    paragraphs: [
                        "If you previously subscribed on the same app store account, you may use the \"Restore purchases\" option in the app to refresh your entitlement. This does not create a new charge."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "F. Mobile Services",
                    paragraphs: [
                        "Data usage and charges. If you use the Services on a mobile device, your carrier's data rates and other fees may apply.",
                        "Compatibility. We do not guarantee that the Services will function on every device or operating-system version.",
                        "Security. You are responsible for keeping your device and account credentials secure."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "G. Mobile Application and App Stores",
                    paragraphs: [
                        "Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to install and use one copy of the Mobile Application on a device you own or control for your personal, non-commercial use.",
                        "These Terms are between you and Company, not the app store. Company, not the app store, is responsible for the Mobile Application and Services, including maintenance, support, and legal compliance, subject to applicable store rules.",
                        "The following applies to any App Store Sourced Application:"
                    ],
                    bullets: [
                        "These Terms are between you and Company only, not Apple;",
                        "Apple has no obligation to furnish maintenance or support for the App Store Sourced Application;",
                        "If the App Store Sourced Application fails to conform to any applicable warranty, you may notify Apple and Apple may refund the purchase price to you; to the maximum extent permitted by law, Apple has no other warranty obligation;",
                        "Company, not Apple, is responsible for addressing claims relating to the App Store Sourced Application, including product liability, legal compliance, and intellectual property infringement;",
                        "Apple and Apple's subsidiaries are third-party beneficiaries of these Terms as they relate to your license of the App Store Sourced Application and may enforce these Terms against you."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "H. Acceptable Use",
                    paragraphs: [
                        "You agree to use the Services responsibly and not to:"
                    ],
                    bullets: [
                        "Copy, scrape, reverse engineer, decompile, or attempt to extract source code or underlying algorithms from the Services;",
                        "Circumvent access controls, subscription checks, or security measures;",
                        "Use bots or automated means to access the Services without our written permission;",
                        "Upload malware or interfere with the operation of the Services;",
                        "Use the Services for unlawful, fraudulent, harassing, or abusive purposes;",
                        "Impersonate any person or misrepresent your affiliation with any entity;",
                        "Use the Services for commercial purposes without our written permission;",
                        "Encourage anyone else to do any of the foregoing."
                    ]
                )
            ]
        ),
        LegalDocumentSection(
            title: "v. Content and Intellectual Property",
            subsections: [
                LegalDocumentSubsection(
                    title: "A. Our Content",
                    paragraphs: [
                        "Our Content is owned by Company Parties or their licensors and is protected by intellectual property laws. We grant you a limited license to access and use Our Content solely as needed to use the Services for personal purposes. You may not copy, distribute, sell, or create derivative works from Our Content except as expressly permitted.",
                        "Cosmic Fit style guidance, tarot selections, colour names, narratives, and related outputs are generated for you through our systems. They remain Our Content and are licensed to you for personal use only."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "B. Your Information",
                    paragraphs: [
                        "You retain ownership of Your Information. You grant Licensed Parties a worldwide, non-exclusive, royalty-free license to use, store, process, reproduce, and display Your Information as necessary to operate, improve, and secure the Services, and as described in our Privacy Policy.",
                        "You may update or delete profile information in the app. Deleting your profile removes locally stored data and, if you are signed in, associated cloud data as described in our Privacy Policy."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "C. Copyright Complaints",
                    paragraphs: [
                        "If you believe Content on the Services infringes your copyright, please email \(noticeEmail) with: (1) identification of the copyrighted work; (2) identification of the material you claim is infringing; (3) your contact information; (4) a statement of good-faith belief; and (5) a statement, under penalty of perjury, that your notice is accurate and you are authorized to act on behalf of the copyright owner."
                    ]
                )
            ]
        ),
        LegalDocumentSection(
            title: "vi. Issues, Claims, Risks, and Disputes",
            subsections: [
                LegalDocumentSubsection(
                    title: "A. Warranty Disclaimer",
                    paragraphs: [
                        "WE PROVIDE THE SERVICES AND ALL CONTENT \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE SERVICES WILL BE UNINTERRUPTED, ERROR-FREE, OR MEET YOUR EXPECTATIONS."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "B. Assumptions of Risk",
                    paragraphs: [
                        "Entertainment and informational purposes only. Astrological interpretations, style recommendations, tarot references, colour suggestions, and other Content are provided for entertainment and general informational purposes only. They are not professional advice of any kind—including medical, psychological, financial, legal, or fashion-industry advice—and should not be relied on for important personal, professional, or financial decisions.",
                        "You use the Services at your own risk. Licensed Parties are not liable for decisions you make based on Content in the Services.",
                        "Third parties. Some Services rely on third-party platforms, app stores, payment processors, or infrastructure. We are not responsible for third-party acts or omissions."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "C. Limitation of Liability",
                    paragraphs: [
                        "TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, LICENSED PARTIES WILL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, OR FOR LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, ARISING FROM OR RELATED TO YOUR USE OF OR INABILITY TO USE THE SERVICES, WHETHER BASED ON WARRANTY, CONTRACT, TORT, OR ANY OTHER LEGAL THEORY.",
                        "IF APPLICABLE LAW DOES NOT ALLOW ALL OR PART OF THE ABOVE LIMITATION, IT APPLIES ONLY TO THE EXTENT PERMITTED."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "D. Enforcement and Termination",
                    paragraphs: [
                        "We may suspend or terminate your access to the Services if you violate these Terms, applicable law, or third-party rights, or for any other reason in our discretion. Upon termination, licenses granted to you end immediately. Termination does not entitle you to a refund except where required by law.",
                        "We may remove or restrict access to Content that we reasonably believe violates these Terms or applicable law."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "E. Indemnification",
                    paragraphs: [
                        "You agree to defend, indemnify, and hold harmless Licensed Parties from claims, damages, losses, and expenses (including reasonable legal fees) arising out of or related to your use of the Services, Your Information, or your violation of these Terms."
                    ]
                ),
                LegalDocumentSubsection(
                    title: "F. Resolving Disputes; Agreement to Arbitrate; Class Action and Jury Waiver",
                    paragraphs: [
                        "PLEASE READ THIS SECTION CAREFULLY. IT REQUIRES MOST DISPUTES TO BE RESOLVED BY INDIVIDUAL BINDING ARBITRATION RATHER THAN IN COURT, AND INCLUDES A JURY TRIAL AND CLASS ACTION WAIVER.",
                        "1. Mandatory Individual Arbitration. Except as stated below, any Dispute will be resolved exclusively by binding individual arbitration under the Federal Arbitration Act. The arbitrator will have authority to resolve disputes about the interpretation, applicability, and enforceability of this Arbitration Agreement.",
                        "Either party may bring an individual claim in small claims court if it qualifies and remains individual. Either party may seek injunctive relief in court for intellectual property misuse.",
                        "To the extent permitted by law, any claim must be filed within one year after it arose or it is permanently barred.",
                        "2. Class Action / Jury Trial Waiver. You and Company Parties waive any right to a jury trial and to participate in a class, collective, consolidated, private attorney general, or representative proceeding.",
                        "If a court or arbitrator determines that the class waiver cannot be enforced for a particular claim, that claim must be litigated in court on an individual basis and individual arbitration of other claims may proceed.",
                        "3. Opt-Out. You may opt out of this Arbitration Agreement by emailing \(noticeEmail) within 30 days of first accepting these Terms (or first purchase or first use after updated Terms are posted). Your email must include your full name, mailing address, email address, phone number, and a clear statement that you wish to opt out of arbitration. If you validly opt out, Disputes will be resolved in court as described below.",
                        "4. Informal Resolution First. Before starting arbitration, you and we agree to send a written notice of the Dispute to \(noticeEmail) describing the claim and your contact information. We will try to resolve the Dispute informally for at least 30 days.",
                        "5. Rules and Governing Law. Unless you opt out, arbitration will be administered by the American Arbitration Association (AAA) under its Consumer Arbitration Rules. The Federal Arbitration Act governs this section. If arbitration does not apply, the exclusive jurisdiction and venue for Disputes will be the state or federal courts located in California, United States, and the laws of the State of California will govern, without regard to conflict-of-law rules.",
                        "6. Survival. This Arbitration Agreement survives termination of these Terms."
                    ]
                )
            ]
        ),
        LegalDocumentSection(
            title: "vii. Notice for California Users",
            paragraphs: [
                "Under California Civil Code Section 1789.3, California users may contact the Complaint Assistance Unit of the Division of Consumer Services of the California Department of Consumer Affairs in writing at 400 R Street, Suite 1080, Sacramento, California 95814, or by telephone at (916) 445-1254 or (800) 952-5210."
            ]
        ),
        LegalDocumentSection(
            title: "viii. Miscellaneous",
            paragraphs: [
                "Entire agreement. These Terms, together with our Privacy Policy and any additional terms presented for specific features, are the entire agreement between you and us regarding the Services.",
                "Severability. If any provision is found invalid, the remaining provisions remain in effect.",
                "No waiver. Our failure to enforce a provision is not a waiver of our right to do so later.",
                "Assignment. You may not assign these Terms without our consent. We may assign these Terms without restriction.",
                "Survival. Provisions that by their nature should survive termination—including intellectual property, disclaimers, limitation of liability, indemnification, and dispute resolution—will survive.",
                "Export. You agree to comply with applicable export and sanctions laws.",
                "Contact. Questions about these Terms may be sent to \(supportEmail)."
            ]
        )
    ]
}
