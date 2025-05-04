//
//  NatalChartViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit
import CoreLocation
import MapKit

class NatalChartViewController: UIViewController {
    // UI Components
    private let dateLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let locationLabel = UILabel()
    private let locationSearchBar = UISearchBar()
    private let locationTableView = UITableView()
    private let latitudeTextField = UITextField()
    private let longitudeTextField = UITextField()
    private let generateButton = UIButton(type: .system)
    private let chartTextView = UITextView()
    private let chartWheelView = ChartWheelView()
    private let segmentedControl = UISegmentedControl(items: ["Text Report", "Chart Wheel"])
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Location search
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    
    // Current chart
    private var currentChart: NatalChart?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View did load called")
        setupUI()
        setupLocationManager()
        setupSearchCompleter()
    }
    
    private func setupUI() {
        title = "Natal Chart Generator"
        view.backgroundColor = .systemBackground
        
        // Configure date picker
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        // Add calendar component to show year
        datePicker.calendar = Calendar.current
        // Set daterange to allow birth dates in the past
        datePicker.maximumDate = Date()
        // Make datepicker more appropriate height
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure location search
        locationSearchBar.placeholder = "Enter birth place (city, country)"
        locationSearchBar.delegate = self
        locationSearchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure location search results table
        locationTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        locationTableView.delegate = self
        locationTableView.dataSource = self
        locationTableView.isHidden = true // Initially hidden
        locationTableView.layer.borderColor = UIColor.lightGray.cgColor
        locationTableView.layer.borderWidth = 1
        locationTableView.layer.cornerRadius = 8
        locationTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure hidden coordinate text fields (not shown to user)
        latitudeTextField.isHidden = true
        longitudeTextField.isHidden = true
        latitudeTextField.translatesAutoresizingMaskIntoConstraints = false
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
        view.addSubview(locationSearchBar)
        view.addSubview(locationTableView)
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
            
            locationSearchBar.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            locationSearchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            locationSearchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            locationTableView.topAnchor.constraint(equalTo: locationSearchBar.bottomAnchor, constant: 0),
            locationTableView.leadingAnchor.constraint(equalTo: locationSearchBar.leadingAnchor),
            locationTableView.trailingAnchor.constraint(equalTo: locationSearchBar.trailingAnchor),
            locationTableView.heightAnchor.constraint(equalToConstant: 150),
            
            latitudeTextField.topAnchor.constraint(equalTo: locationTableView.bottomAnchor),
            longitudeTextField.topAnchor.constraint(equalTo: latitudeTextField.topAnchor),
            
            useLocationButton.topAnchor.constraint(equalTo: locationTableView.bottomAnchor, constant: 10),
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
        
        // Add toolbar to keyboard for search bar
        setupKeyboardToolbar()
        
        // Set up tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    func preloadValues(date: Date, latitude: Double, longitude: Double) {
        // Set the date picker to the saved date
        datePicker.date = date
        
        // Set the latitude and longitude text fields
        latitudeTextField.text = String(format: "%.6f", latitude)
        longitudeTextField.text = String(format: "%.6f", longitude)
        
        // Reverse geocode to get location name for the search bar
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, error == nil, let placemark = placemarks?.first else { return }
            
            var locationText = ""
            if let locality = placemark.locality {
                locationText += locality
            }
            if let country = placemark.country {
                if !locationText.isEmpty {
                    locationText += ", "
                }
                locationText += country
            }
            
            if !locationText.isEmpty {
                self.locationSearchBar.text = locationText
            }
        }
    }
    
    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.items = [flexSpace, doneButton]
        
        locationSearchBar.inputAccessoryView = toolbar
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        locationTableView.isHidden = true
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
            showAlert(message: "Please select a valid birth location")
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
    
    // Search for a location and get its coordinates
    private func searchLocation(for placeName: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = placeName
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] (response, error) in
            guard let self = self, let response = response else {
                print("Location search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let firstItem = response.mapItems.first {
                let coordinate = firstItem.placemark.coordinate
                self.latitudeTextField.text = String(format: "%.6f", coordinate.latitude)
                self.longitudeTextField.text = String(format: "%.6f", coordinate.longitude)
                self.locationSearchBar.text = firstItem.name
                self.locationTableView.isHidden = true
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension NatalChartViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            latitudeTextField.text = String(format: "%.6f", location.coordinate.latitude)
            longitudeTextField.text = String(format: "%.6f", location.coordinate.longitude)
            
            // Reverse geocode to get location name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
                guard let self = self, error == nil, let placemark = placemarks?.first else { return }
                
                var locationText = ""
                if let locality = placemark.locality {
                    locationText += locality
                }
                if let country = placemark.country {
                    if !locationText.isEmpty {
                        locationText += ", "
                    }
                    locationText += country
                }
                
                if !locationText.isEmpty {
                    self.locationSearchBar.text = locationText
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        showAlert(message: "Unable to get your location. Please enter location manually.")
    }
}

// MARK: - UISearchBarDelegate

extension NatalChartViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            locationTableView.isHidden = true
        } else {
            searchCompleter.queryFragment = searchText
            locationTableView.isHidden = false
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchLocation(for: searchText)
        }
        searchBar.resignFirstResponder()
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension NatalChartViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        locationTableView.reloadData()
        locationTableView.isHidden = searchResults.isEmpty
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension NatalChartViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let result = searchResults[indexPath.row]
        
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        let fullAddress = "\(result.title), \(result.subtitle)"
        locationSearchBar.text = result.title
        searchLocation(for: fullAddress)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
