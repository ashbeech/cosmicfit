//
//  InterpretationResult.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import Foundation

struct InterpretationResult {
    let themeName: String
    let stitchedParagraph: String
    let tokensUsed: [StyleToken]
    
    // Additional optional properties for style guide vs daily vibe
    let isStyleGuideReport: Bool
    let reportDate: Date
    
    init(themeName: String, stitchedParagraph: String, tokensUsed: [StyleToken],
         isStyleGuideReport: Bool = false, reportDate: Date = Date()) {
        self.themeName = themeName
        self.stitchedParagraph = stitchedParagraph
        self.tokensUsed = tokensUsed
        self.isStyleGuideReport = isStyleGuideReport
        self.reportDate = reportDate
    }
}
