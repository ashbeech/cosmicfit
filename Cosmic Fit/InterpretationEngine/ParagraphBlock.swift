//
//  ParagraphBlock.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import Foundation

enum ParagraphTone: String {
    case warm
    case grounded
    case playful
    case poetic
    case bold
    case minimal
}

enum ParagraphPositionHint {
    case opener
    case middle
    case closer
}

struct ParagraphBlock {
    let text: String
    let tone: ParagraphTone
    let positionHint: ParagraphPositionHint
}
