//
//  VSOP87Types.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

/// Structure to hold the VSOP87 term coefficients
struct VSOP87Term {
    let a: Double  // Amplitude
    let b: Double  // Phase (in radians)
    let c: Double  // Frequency
}
