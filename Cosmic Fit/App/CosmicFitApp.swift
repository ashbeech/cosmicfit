//
//  CosmicFitApp.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import SwiftUI

@main
struct CosmicFitApp: App {
    
    init() {
        // Initialize VSOP87Parser to load data files
        print("Initializing VSOP87 parser...")
        VSOP87Parser.initialize()
        print("VSOP87 initialization complete - Cosmic Fit is ready for accurate planetary calculations!")
    }
    
    var body: some Scene {
        WindowGroup {
            NatalChartView()
        }
    }
}
