//
//  CompositeTheme.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import Foundation

struct CompositeTheme {
    let name: String             // Human-readable theme name
    let required: [String]       // Token names that MUST be present
    let optional: [String]       // Token names that enhance but aren't required
    let minimumScore: Double     // Threshold score to qualify
}
