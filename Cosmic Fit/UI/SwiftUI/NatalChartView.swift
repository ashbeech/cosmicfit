//
//  NatalChartView.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import SwiftUI

struct NatalChartView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NatalChartViewController {
        let controller = NatalChartViewController()
        
        // Retrieve saved values and set them in the controller
        if let date = UserDefaults.standard.object(forKey: "birthDate") as? Date,
           let latitude = UserDefaults.standard.object(forKey: "latitude") as? Double,
           let longitude = UserDefaults.standard.object(forKey: "longitude") as? Double {
            
            //controller.preloadValues(date: date, latitude: latitude, longitude: longitude)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: NatalChartViewController, context: Context) {
        // Updates when SwiftUI state changes
    }
}

// MARK: - SwiftUI Preview

struct NatalChartView_Previews: PreviewProvider {
    static var previews: some View {
        NatalChartView()
    }
}
