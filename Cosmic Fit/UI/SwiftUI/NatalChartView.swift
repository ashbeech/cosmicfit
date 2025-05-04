//
//  NatalChartView.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import SwiftUI

struct NatalChartView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NatalChartViewController {
        return NatalChartViewController()
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
