//
//  Form.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import SwiftUI

struct BirthDetailsFormView: View {
    @Binding var showingForm: Bool
    @State private var birthDate = Date()
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var locationName: String = ""
    @State private var useCurrentLocation = false
    
    var body: some View {
        Form {
            Section(header: Text("Birth Date and Time")) {
                DatePicker("Select", selection: $birthDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(GraphicalDatePickerStyle())
            }
            
            Section(header: Text("Birth Location")) {
                TextField("Location Name (optional)", text: $locationName)
                TextField("Latitude", text: $latitude)
                    .keyboardType(.decimalPad)
                TextField("Longitude", text: $longitude)
                    .keyboardType(.decimalPad)
                
                Button(action: {
                    // Request location here
                    useCurrentLocation = true
                }) {
                    Label("Use Current Location", systemImage: "location")
                }
            }
            
            Button("Generate Natal Chart") {
                // Validate inputs
                if let lat = Double(latitude), let long = Double(longitude) {
                    // Store the values for use in the chart
                    UserDefaults.standard.set(birthDate, forKey: "birthDate")
                    UserDefaults.standard.set(lat, forKey: "latitude")
                    UserDefaults.standard.set(long, forKey: "longitude")
                    
                    // Hide the form and show the chart
                    showingForm = false
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(latitude.isEmpty || longitude.isEmpty)
        }
        .navigationTitle("Birth Details")
    }
}
