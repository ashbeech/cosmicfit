//
//  NatalChartViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit
import CoreLocation
import MapKit
import PDFKit

class NatalChartViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Date components
    private let dateLabel = UILabel()
    private let dateContainer = UIView()
    private let dayPicker = UIPickerView()
    private let monthPicker = UIPickerView()
    private let yearPicker = UIPickerView()
    
    // Time components
    private let timeLabel = UILabel()
    private let timeContainer = UIView()
    private let hourPicker = UIPickerView()
    private let minutePicker = UIPickerView()
    private let amPmPicker = UIPickerView()
    
    // Location components
    private let locationLabel = UILabel()
    private let locationTextField = UITextField()
    private let locationSearchTable = UITableView()
    
    // Generate button
    private let generateButton = UIButton(type: .system)
    
    // Chart display components
    private let chartTextView = UITextView()
    private let chartWheelView = ChartWheelView()
    private let segmentedControl = UISegmentedControl(items: ["Text Report", "Chart Wheel"])
    
    // Data
    private let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    private let days = Array(1...31)
    private let years = Array(1900...2025)
    private let hours = Array(1...12)
    private let minutes = Array(0...59)
    private let amPm = ["AM", "PM"]
    
    // Location search
    private var searchResults = [MKLocalSearchCompletion]()
    private let locationService = LocationService()
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Selected values
    private var selectedDay = 1
    private var selectedMonth = 0
    private var selectedYear = 2000
    private var selectedHour = 12
    private var selectedMinute = 0
    private var selectedAmPm = 0 // 0 = AM, 1 = PM
    private var selectedLocation: CLLocation?
    private var selectedLocationName: String?
    
    // Current chart
    private var currentChart: NatalChart?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupSearchCompleter()
        loadSavedData()
        
        // Add keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadSavedData() {
        // Try to load birth date
        if let birthDate = UserDefaultsManager.loadBirthDate() {
            selectedDay = birthDate.day
            selectedMonth = birthDate.month
            selectedYear = birthDate.year
            
            // Update pickers to reflect the loaded values
            dayPicker.selectRow(selectedDay - 1, inComponent: 0, animated: false)
            monthPicker.selectRow(selectedMonth, inComponent: 0, animated: false)
            if let yearIndex = years.firstIndex(of: selectedYear) {
                yearPicker.selectRow(yearIndex, inComponent: 0, animated: false)
            }
        }
        
        // Try to load birth time
        if let birthTime = UserDefaultsManager.loadBirthTime() {
            selectedHour = birthTime.hour
            selectedMinute = birthTime.minute
            selectedAmPm = birthTime.amPm
            
            // Update pickers to reflect the loaded values
            hourPicker.selectRow(selectedHour - 1, inComponent: 0, animated: false)
            minutePicker.selectRow(selectedMinute, inComponent: 0, animated: false)
            amPmPicker.selectRow(selectedAmPm, inComponent: 0, animated: false)
        }
        
        // Try to load location
        if let locationData = UserDefaultsManager.loadLocation() {
            selectedLocationName = locationData.name
            selectedLocation = locationData.location
            locationTextField.text = locationData.name
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Natal Chart Generator"
        view.backgroundColor = .systemBackground
        
        // Setup scroll view for better form handling
        setupScrollView()
        
        // Setup date pickers
        setupDateSection()
        
        // Setup time pickers
        setupTimeSection()
        
        // Setup location search
        setupLocationSection()
        
        // Setup generate button
        setupGenerateButton()
        
        // Setup chart display
        setupChartDisplay()
        
        // Set up tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Initial selection of current date
        let currentDate = Date()
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate) - 1 // 0-based index
        let currentYear = calendar.component(.year, from: currentDate)
        let currentHour = calendar.component(.hour, from: currentDate)
        let currentMinute = calendar.component(.minute, from: currentDate)
        
        // Set initial picker selections
        dayPicker.selectRow(currentDay - 1, inComponent: 0, animated: false)
        monthPicker.selectRow(currentMonth, inComponent: 0, animated: false)
        yearPicker.selectRow(years.firstIndex(of: currentYear) ?? 100, inComponent: 0, animated: false)
        
        let hour12 = currentHour % 12 == 0 ? 12 : currentHour % 12
        let isPM = currentHour >= 12
        
        hourPicker.selectRow(hour12 - 1, inComponent: 0, animated: false)
        minutePicker.selectRow(currentMinute, inComponent: 0, animated: false)
        amPmPicker.selectRow(isPM ? 1 : 0, inComponent: 0, animated: false)
        
        // Update selected values
        selectedDay = currentDay
        selectedMonth = currentMonth
        selectedYear = currentYear
        selectedHour = hour12
        selectedMinute = currentMinute
        selectedAmPm = isPM ? 1 : 0
    }
    
    private func setupScrollView() {
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
        ])
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        // Check if location text field is first responder
        if locationTextField.isFirstResponder {
            scrollToLocationField()
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset scroll position if needed
    }

    private func scrollToLocationField() {
        // Calculate the position of the location field in the scroll view coordinates
        let locationFieldRect = locationTextField.convert(locationTextField.bounds, to: scrollView)
        
        // Create a rect that ensures the location field is visible with enough space for the dropdown
        var visibleRect = locationFieldRect
        visibleRect.size.height += 300 // Add extra space for dropdown
        
        // Scroll to make this rect visible
        scrollView.scrollRectToVisible(visibleRect, animated: true)
    }

    private func setupDateSection() {
        // Configure date label
        dateLabel.text = "Birth Date"
        dateLabel.font = StyleUtility.Fonts.subtitle
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure date container
        dateContainer.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleContainerView(dateContainer)
        
        // Create selector labels for day/month/year
        let dayLabel = UILabel()
        dayLabel.text = "Day"
        dayLabel.font = StyleUtility.Fonts.caption
        dayLabel.textAlignment = .center
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let monthLabel = UILabel()
        monthLabel.text = "Month"
        monthLabel.font = StyleUtility.Fonts.caption
        monthLabel.textAlignment = .center
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let yearLabel = UILabel()
        yearLabel.text = "Year"
        yearLabel.font = StyleUtility.Fonts.caption
        yearLabel.textAlignment = .center
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add labels to container
        dateContainer.addSubview(dayLabel)
        dateContainer.addSubview(monthLabel)
        dateContainer.addSubview(yearLabel)
        
        // Configure pickers
        dayPicker.tag = 0
        monthPicker.tag = 1
        yearPicker.tag = 2
        
        // Updated to avoid the delegate/datasource assignment errors
        dayPicker.dataSource = self
        dayPicker.delegate = self
        monthPicker.dataSource = self
        monthPicker.delegate = self
        yearPicker.dataSource = self
        yearPicker.delegate = self
        
        dayPicker.translatesAutoresizingMaskIntoConstraints = false
        monthPicker.translatesAutoresizingMaskIntoConstraints = false
        yearPicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(dateLabel)
        contentView.addSubview(dateContainer)
        dateContainer.addSubview(dayPicker)
        dateContainer.addSubview(monthPicker)
        dateContainer.addSubview(yearPicker)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            dateContainer.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            dateContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            dateContainer.heightAnchor.constraint(equalToConstant: 150), // Increased height for labels
            
            // Day picker (leftmost)
            dayPicker.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 25), // Add space for label
            dayPicker.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor),
            dayPicker.heightAnchor.constraint(equalToConstant: 120),
            dayPicker.widthAnchor.constraint(equalTo: dateContainer.widthAnchor, multiplier: 0.25),
            
            // Month picker (middle)
            monthPicker.topAnchor.constraint(equalTo: dayPicker.topAnchor),
            monthPicker.leadingAnchor.constraint(equalTo: dayPicker.trailingAnchor),
            monthPicker.heightAnchor.constraint(equalTo: dayPicker.heightAnchor),
            monthPicker.widthAnchor.constraint(equalTo: dateContainer.widthAnchor, multiplier: 0.45),
            
            // Year picker (rightmost)
            yearPicker.topAnchor.constraint(equalTo: dayPicker.topAnchor),
            yearPicker.leadingAnchor.constraint(equalTo: monthPicker.trailingAnchor),
            yearPicker.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor),
            yearPicker.heightAnchor.constraint(equalTo: dayPicker.heightAnchor),
            
            // Day label
            dayLabel.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 5),
            dayLabel.centerXAnchor.constraint(equalTo: dayPicker.centerXAnchor),
            dayLabel.widthAnchor.constraint(equalTo: dayPicker.widthAnchor),
            
            // Month label
            monthLabel.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 5),
            monthLabel.centerXAnchor.constraint(equalTo: monthPicker.centerXAnchor),
            monthLabel.widthAnchor.constraint(equalTo: monthPicker.widthAnchor),
            
            // Year label
            yearLabel.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 5),
            yearLabel.centerXAnchor.constraint(equalTo: yearPicker.centerXAnchor),
            yearLabel.widthAnchor.constraint(equalTo: yearPicker.widthAnchor)
        ])
    }
    
    private func setupTimeSection() {
        // Configure time label
        timeLabel.text = "Birth Time"
        timeLabel.font = StyleUtility.Fonts.subtitle
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure time container
        timeContainer.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleContainerView(timeContainer)
        
        // Create selector labels for hour/minute/AM-PM
        let hourLabel = UILabel()
        hourLabel.text = "Hour"
        hourLabel.font = StyleUtility.Fonts.caption
        hourLabel.textAlignment = .center
        hourLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let minuteLabel = UILabel()
        minuteLabel.text = "Minute"
        minuteLabel.font = StyleUtility.Fonts.caption
        minuteLabel.textAlignment = .center
        minuteLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let amPmLabel = UILabel()
        amPmLabel.text = "AM/PM"
        amPmLabel.font = StyleUtility.Fonts.caption
        amPmLabel.textAlignment = .center
        amPmLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add labels to container
        timeContainer.addSubview(hourLabel)
        timeContainer.addSubview(minuteLabel)
        timeContainer.addSubview(amPmLabel)
        
        // Configure pickers
        hourPicker.tag = 3
        minutePicker.tag = 4
        amPmPicker.tag = 5
        
        // Updated to avoid the delegate/datasource assignment errors
        hourPicker.dataSource = self
        hourPicker.delegate = self
        minutePicker.dataSource = self
        minutePicker.delegate = self
        amPmPicker.dataSource = self
        amPmPicker.delegate = self
        
        hourPicker.translatesAutoresizingMaskIntoConstraints = false
        minutePicker.translatesAutoresizingMaskIntoConstraints = false
        amPmPicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(timeLabel)
        contentView.addSubview(timeContainer)
        timeContainer.addSubview(hourPicker)
        timeContainer.addSubview(minutePicker)
        timeContainer.addSubview(amPmPicker)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            timeContainer.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            timeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            timeContainer.heightAnchor.constraint(equalToConstant: 150), // Increased height for labels
            
            // Hour picker
            hourPicker.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 25), // Add space for label
            hourPicker.leadingAnchor.constraint(equalTo: timeContainer.leadingAnchor),
            hourPicker.heightAnchor.constraint(equalToConstant: 120),
            hourPicker.widthAnchor.constraint(equalTo: timeContainer.widthAnchor, multiplier: 0.33),
            
            // Minute picker
            minutePicker.topAnchor.constraint(equalTo: hourPicker.topAnchor),
            minutePicker.leadingAnchor.constraint(equalTo: hourPicker.trailingAnchor),
            minutePicker.heightAnchor.constraint(equalTo: hourPicker.heightAnchor),
            minutePicker.widthAnchor.constraint(equalTo: timeContainer.widthAnchor, multiplier: 0.33),
            
            // AM/PM picker
            amPmPicker.topAnchor.constraint(equalTo: hourPicker.topAnchor),
            amPmPicker.leadingAnchor.constraint(equalTo: minutePicker.trailingAnchor),
            amPmPicker.trailingAnchor.constraint(equalTo: timeContainer.trailingAnchor),
            amPmPicker.heightAnchor.constraint(equalTo: hourPicker.heightAnchor),
            
            // Hour label
            hourLabel.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 5),
            hourLabel.centerXAnchor.constraint(equalTo: hourPicker.centerXAnchor),
            hourLabel.widthAnchor.constraint(equalTo: hourPicker.widthAnchor),
            
            // Minute label
            minuteLabel.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 5),
            minuteLabel.centerXAnchor.constraint(equalTo: minutePicker.centerXAnchor),
            minuteLabel.widthAnchor.constraint(equalTo: minutePicker.widthAnchor),
            
            // AM/PM label
            amPmLabel.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 5),
            amPmLabel.centerXAnchor.constraint(equalTo: amPmPicker.centerXAnchor),
            amPmLabel.widthAnchor.constraint(equalTo: amPmPicker.widthAnchor)
        ])
    }
    
    private func setupLocationSection() {
        // Configure location label
        locationLabel.text = "Birth Location"
        locationLabel.font = StyleUtility.Fonts.subtitle
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure location text field
        locationTextField.placeholder = "Enter city, country"
        locationTextField.returnKeyType = .search
        locationTextField.clearButtonMode = .whileEditing
        locationTextField.delegate = self
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleTextField(locationTextField)
        
        // Add helper text
        let helperLabel = UILabel()
        helperLabel.text = "Enter your birth location for accurate chart calculations"
        helperLabel.font = UIFont.systemFont(ofSize: 12)
        helperLabel.textColor = .secondaryLabel
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure location search results table
        locationSearchTable.isHidden = true
        locationSearchTable.dataSource = self
        locationSearchTable.delegate = self
        locationSearchTable.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleContainerView(locationSearchTable)
        locationSearchTable.register(LocationResultTableViewCell.self, forCellReuseIdentifier: LocationResultTableViewCell.identifier)
        locationSearchTable.separatorStyle = .none
        locationSearchTable.backgroundColor = .systemBackground
        
        // Configure use current location button
        let useLocationButton = UIButton(type: .system)
        useLocationButton.setTitle("Use Current Location", for: .normal)
        useLocationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        useLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "location.fill")
            config.imagePlacement = .leading
            config.imagePadding = 8
            useLocationButton.configuration = config
        } else {
            useLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
            useLocationButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        }
        
        useLocationButton.tintColor = StyleUtility.Colors.primary
        
        // Add subviews
        contentView.addSubview(locationLabel)
        contentView.addSubview(locationTextField)
        contentView.addSubview(helperLabel)
        contentView.addSubview(locationSearchTable)
        contentView.addSubview(useLocationButton)
        
        // Setup constraints with correct z-ordering
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: 20),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            helperLabel.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 5),
            helperLabel.leadingAnchor.constraint(equalTo: locationTextField.leadingAnchor, constant: 5),
            helperLabel.trailingAnchor.constraint(equalTo: locationTextField.trailingAnchor),
            
            locationSearchTable.topAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: 5),
            locationSearchTable.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationSearchTable.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            locationSearchTable.heightAnchor.constraint(equalToConstant: 250),
            
            useLocationButton.topAnchor.constraint(equalTo: locationSearchTable.bottomAnchor, constant: 10),
            useLocationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
        
        // Ensure the search table appears above other views
        contentView.bringSubviewToFront(locationSearchTable)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setupSearchCompleter() {
        // Already set up in LocationService class
    }
    
    private func setupGenerateButton() {
        // Configure generate button
        generateButton.setTitle("Generate Natal Chart", for: .normal)
        generateButton.addTarget(self, action: #selector(generateChartTapped), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleButton(generateButton)
        
        // Create share button
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share Chart", for: .normal)
        shareButton.addTarget(self, action: #selector(shareChartTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.alpha = 0.0 // Initially hidden until chart is generated
        shareButton.tag = 1001  // Tag for later reference
        StyleUtility.styleButton(shareButton)
        shareButton.backgroundColor = StyleUtility.Colors.secondary
        
        // Create PDF export button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export PDF", for: .normal)
        exportButton.addTarget(self, action: #selector(exportPDFTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.alpha = 0.0 // Initially hidden until chart is generated
        exportButton.tag = 1002  // Tag for later reference
        StyleUtility.styleButton(exportButton)
        exportButton.backgroundColor = UIColor.systemGreen
        
        // Add subviews
        contentView.addSubview(generateButton)
        contentView.addSubview(shareButton)
        contentView.addSubview(exportButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            generateButton.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 100),
            generateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            generateButton.widthAnchor.constraint(equalToConstant: 180),
            generateButton.heightAnchor.constraint(equalToConstant: 44),
            
            shareButton.topAnchor.constraint(equalTo: generateButton.topAnchor),
            shareButton.leadingAnchor.constraint(equalTo: generateButton.trailingAnchor, constant: 10),
            shareButton.widthAnchor.constraint(equalToConstant: 100),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            
            exportButton.topAnchor.constraint(equalTo: generateButton.topAnchor),
            exportButton.leadingAnchor.constraint(equalTo: shareButton.trailingAnchor, constant: 10),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            exportButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupChartDisplay() {
        // Configure segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.alpha = 0.0 // Initially hidden
        
        // Configure chart text view
        chartTextView.isEditable = false
        chartTextView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        chartTextView.translatesAutoresizingMaskIntoConstraints = false
        chartTextView.alpha = 0.0 // Initially hidden
        
        // Configure chart wheel view
        chartWheelView.backgroundColor = .white
        chartWheelView.isHidden = true
        chartWheelView.layer.borderColor = UIColor.lightGray.cgColor
        chartWheelView.layer.borderWidth = 1
        chartWheelView.layer.cornerRadius = 8
        chartWheelView.translatesAutoresizingMaskIntoConstraints = false
        chartWheelView.alpha = 0.0 // Initially hidden
        
        // Add subviews
        contentView.addSubview(segmentedControl)
        contentView.addSubview(chartTextView)
        contentView.addSubview(chartWheelView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            chartTextView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            chartTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chartTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chartTextView.heightAnchor.constraint(equalToConstant: 300),
            chartTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            chartWheelView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            chartWheelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chartWheelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chartWheelView.heightAnchor.constraint(equalToConstant: 300),
            chartWheelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func useCurrentLocationTapped() {
        // Show a loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = locationTextField.center
        loadingIndicator.tag = 9999 // Tag for easy finding later
        view.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        
        // Clear previous text
        locationTextField.text = "Detecting location..."
        locationTextField.isEnabled = false
        
        // Request location
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
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        locationSearchTable.isHidden = true
    }
    
    // Calculate age from birth date
    private func calculateAge(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    private func validateInputs() -> (birthDate: Date, location: CLLocation)? {
        // Validate location with better debugging
        guard let location = selectedLocation else {
            print("Location validation failed: selectedLocation is nil")
            if let locationName = selectedLocationName {
                print("selectedLocationName exists but coordinates are missing: \(locationName)")
            }
            showAlert(message: "Please enter a valid birth location")
            return nil
        }
        
        print("Location validation passed: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
            
            // Create date components
            var dateComponents = DateComponents()
            dateComponents.year = selectedYear
            dateComponents.month = selectedMonth + 1 // Month is 0-based in our picker
            dateComponents.day = selectedDay
            
            // Calculate hour in 24-hour format
            let hour24 = selectedAmPm == 1
                ? (selectedHour == 12 ? 12 : selectedHour + 12)
                : (selectedHour == 12 ? 0 : selectedHour)
            
            dateComponents.hour = hour24
            dateComponents.minute = selectedMinute
            
            // Create date
            let calendar = Calendar.current
            guard let birthDate = calendar.date(from: dateComponents) else {
                showAlert(message: "Invalid date combination. Please check your date selection.")
                return nil
            }
            
            // Validate future dates - birth date shouldn't be in the future
            if birthDate > Date() {
                showAlert(message: "Birth date cannot be in the future")
                return nil
            }
            
            // Validate extremely old birth dates (over 120 years)
            let age = calculateAge(from: birthDate)
            if age > 120 {
                // Allow it but show a confirmation
                let confirmMessage = "The birth date you entered is over \(age) years ago. Is this correct?"
                
                // We'll let it pass but show this message
                let alert = UIAlertController(title: "Confirm Birth Date", message: confirmMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes, Continue", style: .default))
                alert.addAction(UIAlertAction(title: "No, Edit Date", style: .cancel) { _ in
                    return
                })
                present(alert, animated: true)
            }
            
            return (birthDate, location)
        }
        
        @objc private func generateChartTapped() {
            // Show loading indicator
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.center = view.center
            activityIndicator.startAnimating()
            view.addSubview(activityIndicator)
            
            // Validate inputs
            guard let validInputs = validateInputs() else {
                activityIndicator.removeFromSuperview()
                return
            }
            
            // Save input data for future use
            if let locationName = selectedLocationName {
                UserDefaultsManager.saveBirthData(
                    day: selectedDay,
                    month: selectedMonth,
                    year: selectedYear,
                    hour: selectedHour,
                    minute: selectedMinute,
                    amPm: selectedAmPm,
                    locationName: locationName,
                    location: validInputs.location
                )
            }
            
            // Generate chart in background to avoid UI freeze
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // Generate chart
                self.currentChart = NatalChart(
                    birthDate: validInputs.birthDate,
                    latitude: validInputs.location.coordinate.latitude,
                    longitude: validInputs.location.coordinate.longitude
                )
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    activityIndicator.removeFromSuperview()
                    
                    // Add animation for the appearance of results
                    UIView.animate(withDuration: 0.3) {
                        self.segmentedControl.alpha = 1.0
                        self.chartTextView.alpha = 1.0
                        self.chartWheelView.alpha = 1.0
                        
                        // Show share and export buttons
                        if let shareButton = self.contentView.viewWithTag(1001) as? UIButton {
                            shareButton.alpha = 1.0
                        }
                        
                        if let exportButton = self.contentView.viewWithTag(1002) as? UIButton {
                            exportButton.alpha = 1.0
                        }
                    }
                    
                    // Display the report
                    if let chart = self.currentChart {
                        self.chartTextView.text = chart.generateReport()
                        self.chartWheelView.chart = chart
                        self.chartWheelView.setNeedsDisplay()
                    }
                }
            }
        }
        
        @objc private func shareChartTapped() {
            guard let chart = currentChart else {
                showAlert(message: "No chart has been generated yet")
                return
            }
            
            // Create text to share
            let chartText = chart.generateReport()
            
            // Create activity view controller
            let activityViewController = UIActivityViewController(
                activityItems: [chartText],
                applicationActivities: nil
            )
            
            // Present the view controller
            present(activityViewController, animated: true)
        }
        
        @objc private func exportPDFTapped() {
            guard let chart = currentChart else {
                showAlert(message: "Please generate a chart first")
                return
            }
            
            // Show loading indicator
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.center = view.center
            activityIndicator.startAnimating()
            view.addSubview(activityIndicator)
            
            // Generate PDF in background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                if let pdfData = PDFGenerator.generatePDF(from: chart) {
                    if let fileURL = PDFGenerator.savePDF(data: pdfData) {
                        DispatchQueue.main.async {
                            activityIndicator.removeFromSuperview()
                            
                            // Show PDF preview and share options
                            let pdfViewController = UIActivityViewController(
                                activityItems: [fileURL],
                                applicationActivities: nil
                            )
                            
                            self.present(pdfViewController, animated: true)
                        }
                    } else {
                        DispatchQueue.main.async {
                            activityIndicator.removeFromSuperview()
                            self.showAlert(message: "Failed to save PDF file")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        activityIndicator.removeFromSuperview()
                        self.showAlert(message: "Failed to generate PDF")
                    }
                }
            }
        }
        
        private func showAlert(message: String, title: String = "Input Error") {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        // MARK: - Location Search Methods
        
        private func lookUpLocationDetails(for placemark: MKPlacemark) {
            selectedLocation = CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
            selectedLocationName = placemark.name ?? "\(placemark.locality ?? ""), \(placemark.country ?? "")"
            locationTextField.text = selectedLocationName
            locationSearchTable.isHidden = true
        }
        
        private func search(for query: String) {
            // Don't search for very short queries
            guard query.count >= 2 else {
                self.searchResults = []
                self.locationSearchTable.reloadData()
                return
            }
            
            locationService.searchLocation(query: query) { [weak self] results in
                guard let self = self else { return }
                self.searchResults = results
                DispatchQueue.main.async {
                    self.locationSearchTable.reloadData()
                    self.locationSearchTable.isHidden = self.searchResults.isEmpty
                }
            }
        }
        
        // MARK: - UIPickerViewDataSource & UIPickerViewDelegate
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch pickerView.tag {
            case 0: // Day
                return days.count
            case 1: // Month
                return months.count
            case 2: // Year
                return years.count
            case 3: // Hour
                return hours.count
            case 4: // Minute
                return minutes.count
            case 5: // AM/PM
                return amPm.count
            default:
                return 0
            }
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch pickerView.tag {
            case 0: // Day
                return "\(days[row])"
            case 1: // Month
                return months[row]
            case 2: // Year
                return "\(years[row])"
            case 3: // Hour
                return "\(hours[row])"
            case 4: // Minute
                // Format minutes with leading zero
                return String(format: "%02d", minutes[row])
            case 5: // AM/PM
                return amPm[row]
            default:
                return ""
            }
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch pickerView.tag {
            case 0: // Day
                selectedDay = days[row]
            case 1: // Month
                selectedMonth = row
                updateDaysInMonth()
            case 2: // Year
                selectedYear = years[row]
                updateDaysInMonth()
            case 3: // Hour
                selectedHour = hours[row]
            case 4: // Minute
                selectedMinute = minutes[row]
            case 5: // AM/PM
                selectedAmPm = row
            default:
                break
            }
        }
        
        private func updateDaysInMonth() {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            dateComponents.year = selectedYear
            dateComponents.month = selectedMonth + 1
            
            guard let date = calendar.date(from: dateComponents),
                  let range = calendar.range(of: .day, in: .month, for: date) else {
                return
            }
            
            // If the selected day is greater than the number of days in the month,
            // set it to the last day of the month
            if selectedDay > range.count {
                selectedDay = range.count
                dayPicker.selectRow(selectedDay - 1, inComponent: 0, animated: true)
            }
        }
        
        // MARK: - UITextFieldDelegate
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            if textField == locationTextField, let searchText = textField.text {
                search(for: searchText)
                // The location table visibility is handled in the search completion handler
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            locationSearchTable.isHidden = true
            return true
        }
        
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == locationTextField {
            // Scroll to make location field visible
            scrollToLocationField()
            
            // Show search results if there's text
            if let searchText = textField.text, !searchText.isEmpty {
                search(for: searchText)
            }
        }
    }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            // If the text field is cleared, hide the search results
            if textField == locationTextField {
                searchResults = []
                locationSearchTable.reloadData()
                locationSearchTable.isHidden = true
            }
            return true
        }
        
        // MARK: - UITableViewDataSource & UITableViewDelegate
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80 // Height for our custom location cell
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return searchResults.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LocationResultTableViewCell.identifier, for: indexPath) as? LocationResultTableViewCell else {
                return UITableViewCell()
            }
            
            let searchResult = searchResults[indexPath.row]
            cell.configure(with: searchResult)
            return cell
        }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedResult = searchResults[indexPath.row]
        
        // Use LocationService to get coordinates first
        locationService.getCoordinates(for: selectedResult) { [weak self] location in
            guard let self = self, let location = location else {
                return
            }
            
            self.selectedLocation = location
            self.selectedLocationName = "\(selectedResult.title), \(selectedResult.subtitle)"
            
            // Make sure UI updates are on the main thread
            DispatchQueue.main.async {
                // Update text field text
                self.locationTextField.text = self.selectedLocationName
                
                // Hide the location search table
                self.locationSearchTable.isHidden = true
                
                // Debug log to confirm location was set properly
                print("Location set successfully: \(self.selectedLocationName ?? "nil"), coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
        
        // MARK: - CLLocationManagerDelegate
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.first {
                selectedLocation = location
                
                // Reverse geocode to get the place name
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
                    guard let self = self else { return }
                    
                    // Remove loading indicator
                    if let loadingIndicator = self.view.viewWithTag(9999) as? UIActivityIndicatorView {
                        loadingIndicator.stopAnimating()
                        loadingIndicator.removeFromSuperview()
                    }
                    
                    // Re-enable text field
                    self.locationTextField.isEnabled = true
                    
                    if let error = error {
                        print("Reverse geocoding error: \(error.localizedDescription)")
                        self.locationTextField.text = ""
                        self.showAlert(message: "Unable to get location details. Please try again or enter manually.")
                        return
                    }
                    
                    if let placemark = placemarks?.first {
                        let locationName = [
                            placemark.locality,
                            placemark.administrativeArea,
                            placemark.country
                        ].compactMap { $0 }.joined(separator: ", ")
                        
                        self.selectedLocationName = locationName
                        self.locationTextField.text = locationName
                    }
                }
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Location manager error: \(error.localizedDescription)")
            
            // Remove loading indicator
            if let loadingIndicator = view.viewWithTag(9999) as? UIActivityIndicatorView {
                loadingIndicator.stopAnimating()
                loadingIndicator.removeFromSuperview()
            }
            
            // Re-enable text field
            locationTextField.isEnabled = true
            locationTextField.text = ""
            
            showAlert(message: "Unable to get your location. Please enter location manually.")
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            // Check if the authorization status changed
            let status = manager.authorizationStatus
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                // User granted permission, try to get location
                manager.requestLocation()
            case .denied, .restricted:
                // Remove loading indicator
                if let loadingIndicator = view.viewWithTag(9999) as? UIActivityIndicatorView {
                    loadingIndicator.stopAnimating()
                    loadingIndicator.removeFromSuperview()
                }
                
                // Re-enable text field
                locationTextField.isEnabled = true
                locationTextField.text = ""
                
                // Show alert about denied permissions
                showAlert(
                    message: "Location access is denied. Please go to Settings > Privacy > Location Services to enable location access for this app, or enter your location manually.",
                    title: "Location Access Denied"
                )
            default:
                break
            }
        }
    }
