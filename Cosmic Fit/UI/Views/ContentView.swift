//
//  ContentView.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

// ContentView.swift - Create this file
import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var birthDate = Date()
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var showChart = false
    @State private var natalChart: NatalChart?
    @State private var showingTextReport = true
    
    // Location manager for current location
    @StateObject private var locationViewModel = LocationViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Natal Chart Generator")
                    .font(.largeTitle)
                    .padding(.top)
                
                // Birth date picker
                VStack(alignment: .leading) {
                    Text("Birth Date and Time")
                        .font(.headline)
                    DatePicker("", selection: $birthDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .frame(maxHeight: 400)
                }
                .padding(.horizontal)
                
                // Location fields
                VStack(alignment: .leading) {
                    Text("Birth Location")
                        .font(.headline)
                    
                    HStack {
                        VStack {
                            TextField("Latitude", text: $latitude)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        VStack {
                            TextField("Longitude", text: $longitude)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Button(action: {
                        locationViewModel.requestLocation()
                    }) {
                        Text("Use Current Location")
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                // Generate button
                Button(action: {
                    generateChart()
                }) {
                    Text("Generate Natal Chart")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .disabled(latitude.isEmpty || longitude.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Cosmic Fit")
            .onChange(of: locationViewModel.currentLocation) { _, newLocation in
                if let location = newLocation {
                    latitude = String(format: "%.6f", location.coordinate.latitude)
                    longitude = String(format: "%.6f", location.coordinate.longitude)
                }
            }
            .sheet(isPresented: $showChart) {
                ChartResultView(chart: natalChart!, showText: $showingTextReport)
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    // Generate the natal chart
    private func generateChart() {
        guard let latValue = Double(latitude),
              let longValue = Double(longitude) else {
            return
        }
        
        natalChart = NatalChart(birthDate: birthDate, latitude: latValue, longitude: longValue)
        showChart = true
    }
    
    // Hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// LocationViewModel to handle CoreLocation
class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}

// Chart Result View
struct ChartResultView: View {
    let chart: NatalChart
    @Binding var showText: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Toggle between text and chart wheel
            Picker("View", selection: $showText) {
                Text("Text Report").tag(true)
                Text("Chart Wheel").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if showText {
                // Text report
                ScrollView {
                    Text(chart.generateReport())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            } else {
                // Chart wheel view using UIViewRepresentable
                ChartWheelUIView(chart: chart)
                    .padding()
            }
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
    }
}

// UIViewRepresentable wrapper for ChartWheelView
struct ChartWheelUIView: UIViewRepresentable {
    let chart: NatalChart
    
    func makeUIView(context: Context) -> ChartWheelView {
        let view = ChartWheelView()
        view.chart = chart
        return view
    }
    
    func updateUIView(_ uiView: ChartWheelView, context: Context) {
        uiView.chart = chart
        uiView.setNeedsDisplay()
    }
}
