//
//  LegalDocumentTypes.swift
//  Cosmic Fit
//
//  Shared models for in-app Terms of Use and Privacy Policy pages.
//

import Foundation

struct LegalDocumentSection {
    let title: String
    let paragraphs: [String]
    let bullets: [String]
    let subsections: [LegalDocumentSubsection]

    init(
        title: String,
        paragraphs: [String] = [],
        bullets: [String] = [],
        subsections: [LegalDocumentSubsection] = []
    ) {
        self.title = title
        self.paragraphs = paragraphs
        self.bullets = bullets
        self.subsections = subsections
    }
}

struct LegalDocumentSubsection {
    let title: String
    let paragraphs: [String]
    let bullets: [String]

    init(title: String, paragraphs: [String] = [], bullets: [String] = []) {
        self.title = title
        self.paragraphs = paragraphs
        self.bullets = bullets
    }
}

struct LegalDocumentLink {
    let phrase: String
    let url: String
}

struct LegalDocumentConfiguration {
    let pageTitle: String
    let dateLine: String
    let importantNotice: String?
    let sections: [LegalDocumentSection]
    let inlineLinks: [LegalDocumentLink]
}
