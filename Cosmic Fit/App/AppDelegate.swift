//
//  AppDelegate.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Set up the animated launch screen as the initial view controller
        let launchScreenVC = AnimatedLaunchScreenViewController()
        
        // Create the main view controller and navigation controller
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        // Tell the launch screen which view controller to transition to
        launchScreenVC.setMainViewController(navigationController)
        
        // Set the launch screen as the root view controller
        window?.rootViewController = launchScreenVC
        window?.makeKeyAndVisible()
        
        // Initialize debug enhancements
        DebugInitializer.setupDebugEnhancements()
        
        // Configure appearance
        configureAppearance()
        
        return true
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().barTintColor = .white
            UINavigationBar.appearance().tintColor = .black
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black]
            UINavigationBar.appearance().isTranslucent = false
        }
    }
}
