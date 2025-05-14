//
//  SwissEphemerisBootstrap.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 07/05/2025.
//

import Foundation
import CSwissEphemeris                 // the SPM module

/// Wraps the one‑time initialisation and shutdown.
enum SwissEphemerisBootstrap {
    private static var didInit = false
    
    /// Call early — e.g. in `@main` app’s `init()` or `application(_:didFinishLaunching)`
    static func initialise() {
        guard !didInit else { return }
        
        // 1) Locate seas_18.se1 inside the bundle
        guard let url = Bundle.main.url(forResource: "seas_18", withExtension: "se1")
        else { fatalError("seas_18.se1 missing") }
        
        let dirPath = url.deletingLastPathComponent().path
        
        dirPath.withCString { cStr in
            swe_set_ephe_path(UnsafeMutablePointer(mutating: cStr))
        }
        
        didInit = true
    }
    
    /// Optional — call from `scenePhase == .background` or `applicationWillTerminate`
    static func shutdown() {
        if didInit { swe_close() }
        didInit = false
    }
}
