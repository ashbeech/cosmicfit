//
//  NatalChartViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit
import CoreLocation

class NatalChartViewController: UIViewController {
    // UI Components
    private let dateLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let locationLabel = UILabel()
    private let latitudeTextField = UITextField()
    private let longitudeTextField = UITextField()
    private let generateButton = UIButton(type: .system)
    private let chartTextView = UITextView()
    private let chartWheelView = ChartWheelView()
    private let segmentedControl = UISegmentedControl(items: ["Text Report", "Chart Wheel"])
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Current chart
    private var currentChart: NatalChart?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View did load called")
        setupUI()
        setupLocationManager()
    }
    
    private func setupUI() {
        title = "Natal Chart Generator"
        view.backgroundColor = .systemBackground
        
        // Configure date picker
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure text fields
        latitudeTextField.placeholder = "Latitude"
        latitudeTextField.borderStyle = .roundedRect
        latitudeTextField.keyboardType = .decimalPad
        latitudeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        longitudeTextField.placeholder = "Longitude"
        longitudeTextField.borderStyle = .roundedRect
        longitudeTextField.keyboardType = .decimalPad
        longitudeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure labels
        dateLabel.text = "Birth Date and Time"
        dateLabel.font = UIFont.boldSystemFont(ofSize: 16)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        locationLabel.text = "Birth Location"
        locationLabel.font = UIFont.boldSystemFont(ofSize: 16)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure generate button
        generateButton.setTitle("Generate Natal Chart", for: .normal)
        generateButton.backgroundColor = .systemBlue
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.layer.cornerRadius = 8
        generateButton.addTarget(self, action: #selector(generateChartTapped), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure use current location button
        let useLocationButton = UIButton(type: .system)
        useLocationButton.setTitle("Use Current Location", for: .normal)
        useLocationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        useLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure chart text view
        chartTextView.isEditable = false
        chartTextView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        chartTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure chart wheel view
        chartWheelView.backgroundColor = .white
        chartWheelView.isHidden = true
        chartWheelView.layer.borderColor = UIColor.lightGray.cgColor
        chartWheelView.layer.borderWidth = 1
        chartWheelView.layer.cornerRadius = 8
        chartWheelView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(dateLabel)
        view.addSubview(datePicker)
        view.addSubview(locationLabel)
        view.addSubview(latitudeTextField)
        view.addSubview(longitudeTextField)
        view.addSubview(useLocationButton)
        view.addSubview(generateButton)
        view.addSubview(segmentedControl)
        view.addSubview(chartTextView)
        view.addSubview(chartWheelView)
                
                // Setup constraints
                NSLayoutConstraint.activate([
                    dateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    
                    datePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
                    datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    datePicker.heightAnchor.constraint(equalToConstant: 200),
                    
                    locationLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 20),
                    locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    
                    latitudeTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
                    latitudeTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    latitudeTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
                    
                    longitudeTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
                    longitudeTextField.leadingAnchor.constraint(equalTo: latitudeTextField.trailingAnchor, constant: 20),
                    longitudeTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
                    
                    useLocationButton.topAnchor.constraint(equalTo: latitudeTextField.bottomAnchor, constant: 10),
                    useLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    
                    generateButton.topAnchor.constraint(equalTo: useLocationButton.bottomAnchor, constant: 20),
                    generateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    generateButton.widthAnchor.constraint(equalToConstant: 200),
                    generateButton.heightAnchor.constraint(equalToConstant: 44),
                    
                    segmentedControl.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 20),
                    segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    
                    chartTextView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
                    chartTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    chartTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    chartTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                    
                    chartWheelView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
                    chartWheelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    chartWheelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    chartWheelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
                ])
                
                // Add toolbar to keyboard for decimal fields
                setupKeyboardToolbar()
                
                // Set up tap gesture to dismiss keyboard
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                view.addGestureRecognizer(tapGesture)
            }
            
            private func setupKeyboardToolbar() {
                let toolbar = UIToolbar()
                toolbar.sizeToFit()
                
                let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
                
                toolbar.items = [flexSpace, doneButton]
                
                latitudeTextField.inputAccessoryView = toolbar
                longitudeTextField.inputAccessoryView = toolbar
            }
            
            @objc private func dismissKeyboard() {
                view.endEditing(true)
            }
            
            private func setupLocationManager() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
            }
            
            @objc private func useCurrentLocationTapped() {
                locationManager.requestWhenInUseAuthorization()
                locationManager.requestLocation()
            }
            
            @objc private func segmentChanged(_ sender: UISegmentedControl) {
                if sender.selectedSegmentIndex == 0 {
                    chartTextView.isHidden = false
                    chartWheelView.isHidden = true
                } else {
                    chartTextView.isHidden = true
                    chartWheelView.isHidden = false
                }
            }
            
            @objc private func generateChartTapped() {
                // Validate inputs
                guard let latText = latitudeTextField.text, !latText.isEmpty,
                      let latitude = Double(latText),
                      let longText = longitudeTextField.text, !longText.isEmpty,
                      let longitude = Double(longText) else {
                    showAlert(message: "Please enter valid latitude and longitude")
                    return
                }
                
                // Generate chart
                let birthDate = datePicker.date
                currentChart = NatalChart(birthDate: birthDate, latitude: latitude, longitude: longitude)
                
                // Display the report
                if let chart = currentChart {
                    chartTextView.text = chart.generateReport()
                    chartWheelView.chart = chart
                    chartWheelView.setNeedsDisplay()
                }
            }
            
            private func showAlert(message: String) {
                let alert = UIAlertController(title: "Input Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
            
            // Share chart functionality
            @objc private func shareChart() {
                guard let chart = currentChart else {
                    showAlert(message: "No chart has been generated yet")
                    return
                }
                
                // Generate text to share
                let chartText = chart.generateReport()
                
                // Create activity view controller
                let activityViewController = UIActivityViewController(
                    activityItems: [chartText],
                    applicationActivities: nil
                )
                
                // Present the view controller
                present(activityViewController, animated: true)
            }
            
            // Save chart functionality
            @objc private func saveChart() {
                guard let chart = currentChart else {
                    showAlert(message: "No chart has been generated yet")
                    return
                }
                
                // Get JSON representation
                let chartDict = chart.toDictionary()
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: chartDict, options: .prettyPrinted)
                    
                    // Create file URL in Documents directory
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                    let fileName = "NatalChart_\(dateFormatter.string(from: Date())).json"
                    let fileURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    // Write to file
                    try jsonData.write(to: fileURL)
                    
                    showAlert(message: "Chart saved successfully")
                } catch {
                    showAlert(message: "Error saving chart: \(error.localizedDescription)")
                }
            }
        }

        // MARK: - CLLocationManagerDelegate

        extension NatalChartViewController: CLLocationManagerDelegate {
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                if let location = locations.first {
                    latitudeTextField.text = String(format: "%.6f", location.coordinate.latitude)
                    longitudeTextField.text = String(format: "%.6f", location.coordinate.longitude)
                }
            }
            
            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                print("Location manager error: \(error.localizedDescription)")
                showAlert(message: "Unable to get your location. Please enter coordinates manually.")
            }
        }
