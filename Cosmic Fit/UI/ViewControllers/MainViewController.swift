//
//  MainViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import UIKit
import CoreLocation

class MainViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let birthDatePicker = UIDatePicker()
    private let birthTimePicker = UIDatePicker()
    private let locationTextField = UITextField()
    private let calculateButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var locationName: String = ""
    private var timeZone: TimeZone = TimeZone.current
    
    private let geocoder = CLGeocoder()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request early device location
        //LocationManager.shared.startLocationUpdates()
        
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Cosmic Fit"
        
        // Set up scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            // Note: We do NOT constrain contentView height to scrollView height to allow scrolling
        ])
        
        // Birth Date Picker
        let dateLabel = UILabel()
        dateLabel.text = "Birth Date:"
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        birthDatePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            birthDatePicker.preferredDatePickerStyle = .wheels
        }
        birthDatePicker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(birthDatePicker)
        
        // Birth Time Picker
        let timeLabel = UILabel()
        timeLabel.text = "Birth Time:"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        birthTimePicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            birthTimePicker.preferredDatePickerStyle = .wheels
        }
        birthTimePicker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(birthTimePicker)
        
        // Location Text Field
        let locationLabel = UILabel()
        locationLabel.text = "Birth Location:"
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationLabel)
        
        locationTextField.placeholder = "City, Country"
        locationTextField.borderStyle = .roundedRect
        locationTextField.returnKeyType = .search
        locationTextField.delegate = self
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationTextField)
        
        // Calculate Button
        calculateButton.setTitle("Calculate Chart", for: .normal)
        calculateButton.backgroundColor = .systemBlue
        calculateButton.setTitleColor(.white, for: .normal)
        calculateButton.layer.cornerRadius = 8
        calculateButton.addTarget(self, action: #selector(calculateButtonTapped), for: .touchUpInside)
        calculateButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(calculateButton)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicator)
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            birthDatePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            birthDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            birthDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: birthDatePicker.bottomAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            birthTimePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            birthTimePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            birthTimePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            locationLabel.topAnchor.constraint(equalTo: birthTimePicker.bottomAnchor, constant: 20),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            calculateButton.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 40),
            calculateButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            calculateButton.widthAnchor.constraint(equalToConstant: 250),
            calculateButton.heightAnchor.constraint(equalToConstant: 50),
            // This bottom constraint is critical to ensure content expands beyond screen size
            calculateButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Set default date (e.g., for Maria's chart: April 28, 1989, 4 AM)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let defaultDate = dateFormatter.date(from: "1989-04-28 04:30") {
            birthDatePicker.date = defaultDate
            birthTimePicker.date = defaultDate
        }
        
        // Set default location (e.g., for Maria's chart: Athens, Greece)
        locationTextField.text = "Athens, Greece"
        
        // Set up keyboard dismissal
        setupKeyboardDismissal()
    }
    
    private func setupKeyboardDismissal() {
        // Add tap gesture to dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Keyboard Handling
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollView.contentInset.bottom = keyboardSize.height
            
            // Use the appropriate API based on iOS version
            if #available(iOS 13.0, *) {
                scrollView.verticalScrollIndicatorInsets.bottom = keyboardSize.height
            } else {
                // Use deprecated API for iOS versions < 13.0
                scrollView.scrollIndicatorInsets.bottom = keyboardSize.height
            }
            
            // Scroll to active text field if any
            if locationTextField.isFirstResponder {
                let rect = locationTextField.convert(locationTextField.bounds, to: scrollView)
                scrollView.scrollRectToVisible(rect, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        
        // Use the appropriate API based on iOS version
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        } else {
            // Use deprecated API for iOS versions < 13.0
            scrollView.scrollIndicatorInsets.bottom = 0
        }
    }
    
    // MARK: - Actions
    @objc private func calculateButtonTapped() {
        guard !locationTextField.text!.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a birth location")
            return
        }
        
        activityIndicator.startAnimating()
        
        // First geocode the location
        geocodeLocation { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.calculateChart()
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Location Error", message: "Could not find coordinates for the specified location. Please enter a valid city and country.")
                }
            }
        }
    }
    
    private func geocodeLocation(completion: @escaping (Bool) -> Void) {
        guard let locationText = locationTextField.text, !locationText.isEmpty else {
            completion(false)
            return
        }
        
        geocoder.geocodeAddressString(locationText) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(false)
                return
            }
            
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.locationName = locationText
            
            // Determine the time zone for the location
            if let timeZone = placemark.timeZone {
                self.timeZone = timeZone
            } else {
                // Fallback to a default time zone based on the location
                self.timeZone = TimeZone(identifier: "Europe/London") ?? TimeZone.current
            }
            
            print("✅ GEOCODING SUCCESS")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📍 Location: \(self.locationName)")
            print("🌐 Resolved to: Lat \(String(format: "%.6f", self.latitude)), Long \(String(format: "%.6f", self.longitude))")
            print("⏰ Time Zone: \(self.timeZone.identifier)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            completion(true)
        }
    }
    
    private func logBirthDetails(date: Date, locationName: String, latitude: Double, longitude: Double, timeZone: TimeZone) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        
        let formattedDate = dateFormatter.string(from: date)
        let tzName = timeZone.identifier
        let tzOffset = timeZone.secondsFromGMT() / 3600
        let offsetSign = tzOffset >= 0 ? "+" : ""
        
        print("🔍 BIRTH DETAILS LOG 🔍")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📅 Date & Time: \(formattedDate)")
        print("📍 Location: \(locationName)")
        print("🌐 Coordinates: Lat \(String(format: "%.6f", latitude)), Long \(String(format: "%.6f", longitude))")
        print("⏰ Time Zone: \(tzName) (GMT\(offsetSign)\(tzOffset))")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func calculateChart() {
        // Combine date and time from the pickers
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDatePicker.date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTimePicker.date)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        guard let birthDateTime = calendar.date(from: combinedComponents) else {
            showAlert(title: "Date Error", message: "Could not process the birth date and time")
            activityIndicator.stopAnimating()
            return
        }
        
        logBirthDetails(date: birthDateTime,
                        locationName: self.locationName,
                        latitude: self.latitude,
                        longitude: self.longitude,
                        timeZone: self.timeZone)
        
        // Calculate the natal chart
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let chartData = NatalChartManager.shared.calculateNatalChart(
                date: birthDateTime,
                latitude: self.latitude,
                longitude: self.longitude,
                timeZone: self.timeZone
            )
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                // Format birth info for display
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                let birthInfo = "\(dateFormatter.string(from: birthDateTime)) at \(self.locationName) (Lat: \(String(format: "%.4f", self.latitude)), Long: \(String(format: "%.4f", self.longitude)))"
                
                // Create and present the chart view controller
                let chartVC = NatalChartViewController()
                chartVC.configure(with: chartData,
                                  birthInfo: birthInfo,
                                  birthDate: birthDateTime,
                                  latitude: self.latitude,
                                  longitude: self.longitude,
                                  timeZone: self.timeZone)
                self.navigationController?.pushViewController(chartVC, animated: true)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == locationTextField {
            geocodeLocation { [weak self] success in
                guard let self = self else { return }
                
                if !success {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Location Error", message: "Could not find coordinates for the specified location. Please enter a valid city and country.")
                    }
                }
            }
        }
        
        return true
    }
}
