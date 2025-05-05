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

class NatalChartViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    // Scroll view
    private let scrollView = UIScrollView()
    
    // Main container for all content
    private let contentStackView = UIStackView()
    
    // Chart result view
    private let chartResultView = UIView()
    
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
    
    // Keyboard height for adjusting scroll position
    private var keyboardHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear any previous location data
        selectedLocation = nil
        selectedLocationName = nil
        
        setupUI()
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
        
        // Setup scroll view and main stack view
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
        
        // Hide chart result view initially
        chartResultView.isHidden = true
        
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
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Pin scroll view to edges of the safe area
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Configure main stack view for all content
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 10
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Pin stack view to scroll view with proper width
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Configure chart result view
        chartResultView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chartResultView)
        
        // Pin chart result view to fill the entire safe area
        NSLayoutConstraint.activate([
            chartResultView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chartResultView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chartResultView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chartResultView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            
            // If the location field is the first responder, scroll to it
            if locationTextField.isFirstResponder {
                scrollToLocationField()
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        keyboardHeight = 0
    }
    
    private func scrollToLocationField() {
        // Convert the location text field's frame to the scroll view's coordinate space
        let locationFieldFrame = locationTextField.convert(locationTextField.bounds, to: scrollView)
        
        // Calculate the bottom of the location field in scroll view coordinates
        let fieldBottom = locationFieldFrame.maxY
        
        // Calculate the visible area of the scroll view (accounting for keyboard)
        let visibleHeight = scrollView.bounds.height - keyboardHeight
        
        // Calculate how much additional scrolling is needed
        let scrollPoint = CGPoint(x: 0, y: max(0, fieldBottom - visibleHeight + 20))
        
        // Animate scrolling to the location field
        scrollView.setContentOffset(scrollPoint, animated: true)
    }

    private func setupDateSection() {
        // Create date section container
        let dateSectionView = UIView()
        dateSectionView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        // Configure pickers
        dayPicker.tag = 0
        monthPicker.tag = 1
        yearPicker.tag = 2
        
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
        dateSectionView.addSubview(dateLabel)
        dateSectionView.addSubview(dateContainer)
        dateContainer.addSubview(dayPicker)
        dateContainer.addSubview(monthPicker)
        dateContainer.addSubview(yearPicker)
        dateContainer.addSubview(dayLabel)
        dateContainer.addSubview(monthLabel)
        dateContainer.addSubview(yearLabel)
        
        // Add to stack view
        contentStackView.addArrangedSubview(dateSectionView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: dateSectionView.topAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: dateSectionView.leadingAnchor),
            
            dateContainer.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            dateContainer.leadingAnchor.constraint(equalTo: dateSectionView.leadingAnchor),
            dateContainer.trailingAnchor.constraint(equalTo: dateSectionView.trailingAnchor),
            dateContainer.heightAnchor.constraint(equalToConstant: 150),
            dateContainer.bottomAnchor.constraint(equalTo: dateSectionView.bottomAnchor),
            
            // Day picker (leftmost)
            dayPicker.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 25),
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
        // Create time section container
        let timeSectionView = UIView()
        timeSectionView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        // Configure pickers
        hourPicker.tag = 3
        minutePicker.tag = 4
        amPmPicker.tag = 5
        
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
        timeSectionView.addSubview(timeLabel)
        timeSectionView.addSubview(timeContainer)
        timeContainer.addSubview(hourPicker)
        timeContainer.addSubview(minutePicker)
        timeContainer.addSubview(amPmPicker)
        timeContainer.addSubview(hourLabel)
        timeContainer.addSubview(minuteLabel)
        timeContainer.addSubview(amPmLabel)
        
        // Add to stack view
        contentStackView.addArrangedSubview(timeSectionView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: timeSectionView.topAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: timeSectionView.leadingAnchor),
            
            timeContainer.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            timeContainer.leadingAnchor.constraint(equalTo: timeSectionView.leadingAnchor),
            timeContainer.trailingAnchor.constraint(equalTo: timeSectionView.trailingAnchor),
            timeContainer.heightAnchor.constraint(equalToConstant: 150),
            timeContainer.bottomAnchor.constraint(equalTo: timeSectionView.bottomAnchor),
            
            // Hour picker
            hourPicker.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 25),
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
        // Create location section container
        let locationSectionView = UIView()
        locationSectionView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        // Add subviews
        locationSectionView.addSubview(locationLabel)
        locationSectionView.addSubview(locationTextField)
        locationSectionView.addSubview(helperLabel)
        locationSectionView.addSubview(locationSearchTable)
        
        // Add to stack view
        contentStackView.addArrangedSubview(locationSectionView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: locationSectionView.topAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationSectionView.leadingAnchor),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            locationTextField.leadingAnchor.constraint(equalTo: locationSectionView.leadingAnchor),
            locationTextField.trailingAnchor.constraint(equalTo: locationSectionView.trailingAnchor),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            helperLabel.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 5),
            helperLabel.leadingAnchor.constraint(equalTo: locationTextField.leadingAnchor, constant: 5),
            helperLabel.trailingAnchor.constraint(equalTo: locationTextField.trailingAnchor),
            
            locationSearchTable.topAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: 5),
            locationSearchTable.leadingAnchor.constraint(equalTo: locationSectionView.leadingAnchor),
            locationSearchTable.trailingAnchor.constraint(equalTo: locationSectionView.trailingAnchor),
            locationSearchTable.heightAnchor.constraint(equalToConstant: 200),
            
            // Make sure the section view's bottom is at the bottom of the helper label when the search table is hidden
            locationSectionView.bottomAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: 10)
        ])
    }
    
    private func setupGenerateButton() {
        // Configure generate button
        generateButton.setTitle("Generate Natal Chart", for: .normal)
        generateButton.addTarget(self, action: #selector(generateChartTapped), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleButton(generateButton)
        
        // Add to stack view
        contentStackView.addArrangedSubview(generateButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            generateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupChartDisplay() {
        // Create chart view scroll view for scrolling chart content
        let chartScrollView = UIScrollView()
        chartScrollView.translatesAutoresizingMaskIntoConstraints = false
        chartResultView.addSubview(chartScrollView)
        
        // Create a container view for chart content
        let chartContentView = UIView()
        chartContentView.translatesAutoresizingMaskIntoConstraints = false
        chartScrollView.addSubview(chartContentView)
        
        // Add a back button to return to the form
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back to Form", for: .normal)
        backButton.addTarget(self, action: #selector(backToFormTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleButton(backButton)
        backButton.backgroundColor = StyleUtility.Colors.secondary
        
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
        
        // Create action buttons container
        let actionButtonsContainer = UIView()
        actionButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create share button
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share Chart", for: .normal)
        shareButton.addTarget(self, action: #selector(shareChartTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleButton(shareButton)
        shareButton.backgroundColor = StyleUtility.Colors.primary
        
        // Create PDF export button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export PDF", for: .normal)
        exportButton.addTarget(self, action: #selector(exportPDFTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        StyleUtility.styleButton(exportButton)
        exportButton.backgroundColor = UIColor.systemGreen
        
        // Add subviews
        chartContentView.addSubview(backButton)
        chartContentView.addSubview(segmentedControl)
        chartContentView.addSubview(chartTextView)
        chartContentView.addSubview(chartWheelView)
        chartContentView.addSubview(actionButtonsContainer)
        actionButtonsContainer.addSubview(shareButton)
        actionButtonsContainer.addSubview(exportButton)
        
        // Set up scroll view and content view constraints
        NSLayoutConstraint.activate([
            chartScrollView.topAnchor.constraint(equalTo: chartResultView.safeAreaLayoutGuide.topAnchor),
            chartScrollView.leadingAnchor.constraint(equalTo: chartResultView.leadingAnchor),
            chartScrollView.trailingAnchor.constraint(equalTo: chartResultView.trailingAnchor),
            chartScrollView.bottomAnchor.constraint(equalTo: chartResultView.safeAreaLayoutGuide.bottomAnchor),
            
            chartContentView.topAnchor.constraint(equalTo: chartScrollView.topAnchor),
            chartContentView.leadingAnchor.constraint(equalTo: chartScrollView.leadingAnchor, constant: 20),
            chartContentView.trailingAnchor.constraint(equalTo: chartScrollView.trailingAnchor, constant: -20),
            chartContentView.bottomAnchor.constraint(equalTo: chartScrollView.bottomAnchor, constant: -20),
            chartContentView.widthAnchor.constraint(equalTo: chartScrollView.widthAnchor, constant: -40),
            
            backButton.topAnchor.constraint(equalTo: chartContentView.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: chartContentView.leadingAnchor),
            backButton.trailingAnchor.constraint(equalTo: chartContentView.trailingAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            segmentedControl.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: chartContentView.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: chartContentView.trailingAnchor),
            
            chartTextView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            chartTextView.leadingAnchor.constraint(equalTo: chartContentView.leadingAnchor),
            chartTextView.trailingAnchor.constraint(equalTo: chartContentView.trailingAnchor),
            chartTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            chartWheelView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            chartWheelView.leadingAnchor.constraint(equalTo: chartContentView.leadingAnchor),
            chartWheelView.trailingAnchor.constraint(equalTo: chartContentView.trailingAnchor),
            chartWheelView.heightAnchor.constraint(equalToConstant: 300),
            
            actionButtonsContainer.topAnchor.constraint(equalTo: chartTextView.bottomAnchor, constant: 20),
            actionButtonsContainer.leadingAnchor.constraint(equalTo: chartContentView.leadingAnchor),
            actionButtonsContainer.trailingAnchor.constraint(equalTo: chartContentView.trailingAnchor),
            actionButtonsContainer.heightAnchor.constraint(equalToConstant: 44),
            actionButtonsContainer.bottomAnchor.constraint(equalTo: chartContentView.bottomAnchor),
            
            shareButton.leadingAnchor.constraint(equalTo: actionButtonsContainer.leadingAnchor),
            shareButton.topAnchor.constraint(equalTo: actionButtonsContainer.topAnchor),
            shareButton.bottomAnchor.constraint(equalTo: actionButtonsContainer.bottomAnchor),
            shareButton.widthAnchor.constraint(equalTo: actionButtonsContainer.widthAnchor, multiplier: 0.48),
            
            exportButton.trailingAnchor.constraint(equalTo: actionButtonsContainer.trailingAnchor),
            exportButton.topAnchor.constraint(equalTo: actionButtonsContainer.topAnchor),
            exportButton.bottomAnchor.constraint(equalTo: actionButtonsContainer.bottomAnchor),
            exportButton.widthAnchor.constraint(equalTo: actionButtonsContainer.widthAnchor, multiplier: 0.48)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backToFormTapped() {
        // Hide chart view and show form
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.chartResultView.isHidden = true
            self.scrollView.isHidden = false
        }, completion: nil)
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
        // Verify that we have a location selected
        guard let location = selectedLocation else {
            print("ERROR in validateInputs: selectedLocation is nil")
            print("locationTextField.text = \(locationTextField.text ?? "nil")")
            print("selectedLocationName = \(selectedLocationName ?? "nil")")
            showAlert(message: "Please enter and select a valid birth location")
            return nil
        }
        
        print("Validated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
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
                
                // Show chart and hide form
                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.scrollView.isHidden = true
                    self.chartResultView.isHidden = false
                }, completion: nil)
                
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
        // Get the selected location result
        let result = searchResults[indexPath.row]
        
        print("User selected location: \(result.title), \(result.subtitle)")
        
        // Show a loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        
        // Create a search request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(result.title), \(result.subtitle)"
        
        // Perform the search directly here instead of using the service
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] (response, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Remove loading indicator
                loadingIndicator.removeFromSuperview()
                
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    self.showAlert(message: "Error finding location. Please try again.")
                    return
                }
                
                guard let response = response,
                      let item = response.mapItems.first,
                      let location = item.placemark.location else {
                    print("No location found in search results")
                    self.showAlert(message: "Could not get coordinates for this location. Please try another.")
                    return
                }
                
                // Explicitly set all location-related properties
                self.selectedLocation = location
                self.locationTextField.text = "\(result.title), \(result.subtitle)"
                self.selectedLocationName = "\(result.title), \(result.subtitle)"
                
                // Debug log the successful location setting
                print("LOCATION SET: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                print("Location name: \(self.selectedLocationName ?? "unknown")")
                
                // Save location immediately to UserDefaults for persistence
                UserDefaultsManager.saveLocation(
                    name: self.selectedLocationName ?? "\(result.title), \(result.subtitle)",
                    location: location
                )
                
                // Hide search results table
                self.locationSearchTable.isHidden = true
            }
        }
    }
}
