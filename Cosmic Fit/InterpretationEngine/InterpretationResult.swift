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
    
    // Additional optional properties for blueprint vs daily vibe
    let isBlueprintReport: Bool
    let reportDate: Date
    
    init(themeName: String, stitchedParagraph: String, tokensUsed: [StyleToken],
         isBlueprintReport: Bool = false, reportDate: Date = Date()) {
        self.themeName = themeName
        self.stitchedParagraph = stitchedParagraph
        self.tokensUsed = tokensUsed
        self.isBlueprintReport = isBlueprintReport
        self.reportDate = reportDate
    }
}
