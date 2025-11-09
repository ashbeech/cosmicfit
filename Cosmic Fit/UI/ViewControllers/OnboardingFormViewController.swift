//
//  OnboardingFormViewController.swift
//  Cosmic Fit
//
//  Created for multi-page onboarding form
//

import UIKit
import CoreLocation

class OnboardingFormViewController: UIViewController {
    
    // MARK: - Form Data Storage
    private var firstName: String = ""
    private var birthDate: Date = Date()
    private var birthTime: Date = Date()
    private var hasUnknownTime: Bool = false
    private var birthLocation: String = ""
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var timeZone: TimeZone = TimeZone.current
    
    // MARK: - UI Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backButton = UIButton(type: .system)
    private let pageNumberLabel = UILabel()
    private let questionNumberLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let inputContainerView = UIView()
    private let actionButton = UIButton(type: .system)
    private let pageIndicatorLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // Page-specific input views
    private let nameTextField = UITextField()
    private let nameDivider = UIView()
    
    private let dateLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let timeLabel = UILabel()
    private let timePicker = UIDatePicker()
    private let unknownTimeCheckbox = UIButton(type: .system)
    private let unknownTimeLabel = UILabel()
    
    private let locationTextField = UITextField()
    private let locationDivider = UIView()
    
    // MARK: - Properties
    private var currentPage: Int = 1 {
        didSet {
            updatePageContent()
        }
    }
    
    // MARK: - Form Validation Properties
    private var isNameValid = false
    private var isBirthDataValid = true // Date pickers always have valid dates
    private var isLocationValid = false
    
    private let totalPages = 3
    private var geocoder = CLGeocoder()
    
    // MARK: - Placeholder Animation Properties
    private var placeholderTimer: Timer?
    private var currentPlaceholderIndex = 0
    private let placeholders = ["London, UK", "Paris, France", "Athens, Greece"]
    private let placeholderAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: CosmicFitTheme.Colors.darkerCosmicGrey,
        .font: UIFont.systemFont(ofSize: 18)
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
        updatePageContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaceholderAnimation()
    }
    
    deinit {
        stopPlaceholderAnimation()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("< Back", for: .normal)
        backButton.setTitleColor(.black, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.isHidden = true // Hidden on first page
        contentView.addSubview(backButton)
        
        // Question number (large)
        questionNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        questionNumberLabel.font = UIFont.systemFont(ofSize: 120, weight: .light)
        questionNumberLabel.textColor = UIColor(white: 0.8, alpha: 1.0)
        questionNumberLabel.text = "1"
        contentView.addSubview(questionNumberLabel)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        
        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        descriptionLabel.textColor = .black
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        
        // Input container
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(inputContainerView)
        
        // Action button
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.backgroundColor = .black
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        actionButton.layer.cornerRadius = 8
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // Initially disable the button
        updateButtonState()
        
        contentView.addSubview(actionButton)
        
        // Page indicator
        pageIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        pageIndicatorLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        pageIndicatorLabel.textColor = .black
        pageIndicatorLabel.textAlignment = .center
        contentView.addSubview(pageIndicatorLabel)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .black
        view.addSubview(activityIndicator)
        
        setupInputViews()
    }
    
    private func setupInputViews() {
            // Name input
            nameTextField.translatesAutoresizingMaskIntoConstraints = false
            nameTextField.placeholder = "First Name"
            nameTextField.font = UIFont.systemFont(ofSize: 18)
            nameTextField.textColor = .black
            nameTextField.borderStyle = .none
            nameTextField.returnKeyType = .next
            nameTextField.delegate = self
            nameTextField.addTarget(self, action: #selector(nameFieldChanged), for: .editingChanged)
            
            nameDivider.translatesAutoresizingMaskIntoConstraints = false
            nameDivider.backgroundColor = .black
            
            // Date picker
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            dateLabel.text = "Date"
            dateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            dateLabel.textColor = .black
            
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.maximumDate = Date()
            // Set dark text color for the picker
            datePicker.setValue(UIColor.black, forKey: "textColor")
            
            if let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) {
                datePicker.minimumDate = hundredYearsAgo
            }
            
            // Set default date to April 28, 1989
            let calendar = Calendar.current
            var defaultDateComponents = DateComponents()
            defaultDateComponents.year = 1989
            defaultDateComponents.month = 4
            defaultDateComponents.day = 28
            if let defaultDate = calendar.date(from: defaultDateComponents) {
                datePicker.date = defaultDate
            }
            
            // Time picker
            timeLabel.translatesAutoresizingMaskIntoConstraints = false
            timeLabel.text = "Time"
            timeLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            timeLabel.textColor = .black
            
            timePicker.translatesAutoresizingMaskIntoConstraints = false
            timePicker.datePickerMode = .time
            timePicker.preferredDatePickerStyle = .wheels
            // Set dark text color for the picker
            timePicker.setValue(UIColor.black, forKey: "textColor")
            
            // Set default time to 04:30
            var defaultTimeComponents = DateComponents()
            defaultTimeComponents.hour = 04
            defaultTimeComponents.minute = 30
            if let defaultTime = calendar.date(from: defaultTimeComponents) {
                timePicker.date = defaultTime
            }
            
            // Unknown time checkbox
            unknownTimeCheckbox.translatesAutoresizingMaskIntoConstraints = false
            unknownTimeCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
            unknownTimeCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
            unknownTimeCheckbox.tintColor = .black
            unknownTimeCheckbox.addTarget(self, action: #selector(unknownTimeToggled), for: .touchUpInside)
            
            unknownTimeLabel.translatesAutoresizingMaskIntoConstraints = false
            unknownTimeLabel.text = "I don't know my time"
            unknownTimeLabel.font = UIFont.systemFont(ofSize: 16)
            unknownTimeLabel.textColor = .black
            
        // Location input
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.font = UIFont.systemFont(ofSize: 18)
        locationTextField.textColor = .black
        locationTextField.borderStyle = .none
        locationTextField.returnKeyType = .done
        locationTextField.delegate = self
        locationTextField.addTarget(self, action: #selector(locationFieldChanged), for: .editingChanged)
        
        // Set initial placeholder
        locationTextField.attributedPlaceholder = NSAttributedString(
            string: placeholders[0],
            attributes: placeholderAttributes
        )
        
        locationDivider.translatesAutoresizingMaskIntoConstraints = false
        locationDivider.backgroundColor = .black
        }
    
    // MARK: - Placeholder Animation
    private func startPlaceholderAnimation() {
        // Stop any existing timer
        stopPlaceholderAnimation()
        
        // Only animate if text field is empty
        guard locationTextField.text?.isEmpty ?? true else { return }
        
        // Start the cycling timer
        placeholderTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.cyclePlaceholder()
        }
    }
    
    private func stopPlaceholderAnimation() {
        placeholderTimer?.invalidate()
        placeholderTimer = nil
    }
    
    private func cyclePlaceholder() {
        // Only cycle if text field is empty
        guard locationTextField.text?.isEmpty ?? true else {
            stopPlaceholderAnimation()
            return
        }
        
        // Move to next placeholder
        currentPlaceholderIndex = (currentPlaceholderIndex + 1) % placeholders.count
        
        // Fade out current placeholder
        UIView.animate(withDuration: 0.3, animations: {
            self.locationTextField.alpha = 0.0
        }) { _ in
            // Change placeholder text
            self.locationTextField.attributedPlaceholder = NSAttributedString(
                string: self.placeholders[self.currentPlaceholderIndex],
                attributes: self.placeholderAttributes
            )
            
            // Fade back in
            UIView.animate(withDuration: 0.3) {
                self.locationTextField.alpha = 1.0
            }
        }
    }
    
    private func setupConstraints() {
            NSLayoutConstraint.activate([
                // Scroll view
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                // Content view
                contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, constant: -100),
                
                // Back button
                backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                
                // Question number
                questionNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
                questionNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
                
                // Title
                titleLabel.topAnchor.constraint(equalTo: questionNumberLabel.bottomAnchor, constant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
                
                // Description
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
                descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
                
                // Input container
                inputContainerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 0),
                inputContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
                inputContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
                inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
                
                // Action button
                actionButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 20),
                actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                actionButton.widthAnchor.constraint(equalToConstant: 140),
                actionButton.heightAnchor.constraint(equalToConstant: 50),
                
                // Page indicator
                pageIndicatorLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 40),
                pageIndicatorLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                pageIndicatorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
                
                // Activity indicator
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Button State Management
    private func updateButtonState() {
        let isValid: Bool
        
        switch currentPage {
        case 1:
            isValid = isNameValid
        case 2:
            isValid = isBirthDataValid
        case 3:
            isValid = isLocationValid
        default:
            isValid = false
        }
        
        actionButton.isEnabled = isValid
        actionButton.alpha = isValid ? 1.0 : 0.5
    }
    
    // MARK: - Form Validation
    private func validateCurrentPage() {
        switch currentPage {
        case 1:
            checkNameValid()
        case 2:
            checkBirthValid()
        case 3:
            checkLocationValid()
        default:
            break
        }
        updateButtonState()
    }
    
    private func checkNameValid() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isNameValid = !name.isEmpty && name.count >= 2
    }
    
    private func checkBirthValid() {
        // Date pickers always have valid dates
        isBirthDataValid = true
    }
    
    private func checkLocationValid() {
        let location = locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isLocationValid = !location.isEmpty && location.count >= 3
    }
    
    // MARK: - Text Field Change Handlers
    @objc private func nameFieldChanged() {
        checkNameValid()
        updateButtonState()
    }
    
    @objc private func locationFieldChanged() {
        checkLocationValid()
        updateButtonState()
        
        // Stop placeholder animation if user has typed something
        if !(locationTextField.text?.isEmpty ?? true) {
            stopPlaceholderAnimation()
        } else {
            // Restart animation if field becomes empty
            startPlaceholderAnimation()
        }
    }
    
    // MARK: - Page Content Updates
    private func updatePageContent() {
        // Clear input container
        inputContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Update back button visibility
        backButton.isHidden = (currentPage == 1)
        
        // Update question number
        questionNumberLabel.text = "\(currentPage)"
        
        // Update page indicator
        pageIndicatorLabel.text = "Page \(currentPage) of \(totalPages)"
        
        switch currentPage {
        case 1:
            setupNamePage()
        case 2:
            setupBirthPage()
        case 3:
            setupLocationPage()
        default:
            break
        }
    }
    
    private func setupNamePage() {
        titleLabel.text = "What's your name?"
        descriptionLabel.text = "We'll use this to personalise your profile."
        actionButton.setTitle("Next >", for: .normal)
        
        // Add name input to container
        inputContainerView.addSubview(nameTextField)
        inputContainerView.addSubview(nameDivider)
        
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            nameDivider.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: -8),
            nameDivider.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            nameDivider.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            nameDivider.heightAnchor.constraint(equalToConstant: 1),
            nameDivider.bottomAnchor.constraint(lessThanOrEqualTo: inputContainerView.bottomAnchor, constant: -10)
        ])
        
        // Add sparkle decoration
        let sparkle = UILabel()
        sparkle.text = "✦"
        sparkle.font = UIFont.systemFont(ofSize: 20)
        sparkle.textColor = .black
        sparkle.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(sparkle)
        
        NSLayoutConstraint.activate([
            sparkle.centerYAnchor.constraint(equalTo: nameDivider.centerYAnchor),
            sparkle.trailingAnchor.constraint(equalTo: nameDivider.trailingAnchor)
        ])
        
        // Focus on text field with slight delay to ensure proper hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.nameTextField.becomeFirstResponder()
        }
        
        // Initial validation
        validateCurrentPage()
    }
    
    private func setupBirthPage() {
        titleLabel.text = "When were you born?"
        descriptionLabel.text = ""
        actionButton.setTitle("Next >", for: .normal)
        
        // Add birth inputs to container
        inputContainerView.addSubview(dateLabel)
        inputContainerView.addSubview(datePicker)
        inputContainerView.addSubview(timeLabel)
        inputContainerView.addSubview(timePicker)
        inputContainerView.addSubview(unknownTimeCheckbox)
        inputContainerView.addSubview(unknownTimeLabel)
        
        // INLINE LAYOUT: Date label and picker on same horizontal line
        // Time label and picker on same horizontal line
        NSLayoutConstraint.activate([
            // Date row - label and picker inline
            dateLabel.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 0),
            dateLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            dateLabel.widthAnchor.constraint(equalToConstant: 60),
            dateLabel.centerYAnchor.constraint(equalTo: datePicker.centerYAnchor),
            
            datePicker.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
            datePicker.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 10),
            datePicker.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 120),
            
            // Time row - label and picker inline
            timeLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 0),
            timeLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 60),
            timeLabel.centerYAnchor.constraint(equalTo: timePicker.centerYAnchor),
            
            timePicker.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 0),
            timePicker.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 10),
            timePicker.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            timePicker.heightAnchor.constraint(equalToConstant: 120),
            
            // Unknown time checkbox
            unknownTimeCheckbox.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 0),
            unknownTimeCheckbox.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            unknownTimeCheckbox.widthAnchor.constraint(equalToConstant: 24),
            unknownTimeCheckbox.heightAnchor.constraint(equalToConstant: 24),
            
            unknownTimeLabel.centerYAnchor.constraint(equalTo: unknownTimeCheckbox.centerYAnchor),
            unknownTimeLabel.leadingAnchor.constraint(equalTo: unknownTimeCheckbox.trailingAnchor, constant: 10),
            unknownTimeLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            unknownTimeLabel.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor)
        ])
        
        // Update time picker based on checkbox state
        updateTimePickerState()
        
        // Initial validation
        validateCurrentPage()
    }
    
    private func setupLocationPage() {
            titleLabel.text = "And lastly, where were you born?"
            descriptionLabel.text = ""
            actionButton.setTitle("Done", for: .normal)
            
            // Add location input to container
            inputContainerView.addSubview(locationTextField)
            inputContainerView.addSubview(locationDivider)
            
            NSLayoutConstraint.activate([
                locationTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
                locationTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
                locationTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
                locationTextField.heightAnchor.constraint(equalToConstant: 44),
                
                locationDivider.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: -8),
                locationDivider.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
                locationDivider.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
                locationDivider.heightAnchor.constraint(equalToConstant: 1),
                locationDivider.bottomAnchor.constraint(lessThanOrEqualTo: inputContainerView.bottomAnchor, constant: -10)
            ])
            
            // Reset placeholder animation state
            currentPlaceholderIndex = 0
            locationTextField.attributedPlaceholder = NSAttributedString(
                string: placeholders[0],
                attributes: placeholderAttributes
            )
            
            // Start placeholder animation
            startPlaceholderAnimation()
            
            // Focus on text field
            DispatchQueue.main.async {
                self.locationTextField.becomeFirstResponder()
            }
            
            // Initial validation
            validateCurrentPage()
        }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        if currentPage > 1 {
            fadeToPage(currentPage - 1)
        }
    }
    
    @objc private func actionButtonTapped() {
        // Double-check validation before proceeding
        validateCurrentPage()
        
        switch currentPage {
        case 1:
            if isNameValid {
                firstName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                fadeToPage(2)
            } else {
                showAlert(title: "Name Required", message: "Please enter your first name (at least 2 characters).")
            }
        case 2:
            if isBirthDataValid {
                storeBirthData()
                fadeToPage(3)
            } else {
                showAlert(title: "Birth Date Required", message: "Please select your birth date and time.")
            }
        case 3:
            if isLocationValid {
                processLocationAndComplete()
            } else {
                showAlert(title: "Location Required", message: "Please enter your birth location (at least 3 characters).")
            }
        default:
            break
        }
    }
    
    @objc private func unknownTimeToggled() {
        unknownTimeCheckbox.isSelected.toggle()
        hasUnknownTime = unknownTimeCheckbox.isSelected
        updateTimePickerState()
    }
    
    private func updateTimePickerState() {
        timePicker.isEnabled = !hasUnknownTime
        timePicker.alpha = hasUnknownTime ? 0.4 : 1.0
    }
    
    // MARK: - Page Transitions
    private func fadeToPage(_ page: Int) {
        // Stop placeholder animation when leaving page 3
        if currentPage == 3 {
            stopPlaceholderAnimation()
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.currentPage = page
            UIView.animate(withDuration: 0.3) {
                self.view.alpha = 1.0
            }
        }
    }
    
    // MARK: - Data Storage
    private func storeBirthData() {
        birthDate = datePicker.date
        birthTime = timePicker.date
        
        print("Birth Date: \(birthDate)")
        print("Birth Time: \(birthTime)")
        print("Unknown Time: \(hasUnknownTime)")
    }
    
    // MARK: - Location Processing
    private func processLocationAndComplete() {
        birthLocation = locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        activityIndicator.startAnimating()
        actionButton.isEnabled = false
        
        geocodeLocation(birthLocation) { [weak self] success in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            self.actionButton.isEnabled = true
            
            if success {
                self.saveProfileAndComplete()
            } else {
                self.showAlert(title: "Location Error", message: "Could not find this location. Please try a different format (e.g., 'London, UK').")
            }
        }
    }
    
    private func geocodeLocation(_ location: String, completion: @escaping (Bool) -> Void) {
        geocoder.geocodeAddressString(location) { [weak self] placemarks, error in
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
            self.timeZone = placemark.timeZone ?? TimeZone.current
            
            // CRITICAL: Set picker timezones to birth location timezone
            // This ensures all time inputs are interpreted in the birth location context
            self.datePicker.timeZone = self.timeZone
            self.timePicker.timeZone = self.timeZone
            
            print("Geocoded: \(self.latitude), \(self.longitude)")
            print("Timezone: \(self.timeZone.identifier)")
            
            #if DEBUG
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🌍 GEOCODING COMPLETE")
            print("📍 Location: \(location)")
            print("🕐 Timezone: \(self.timeZone.identifier)")
            print("✅ Pickers configured with birth location timezone")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            
            completion(true)
        }
    }
    
    private func saveProfileAndComplete() {
        // Extract component values from stored dates
        // The stored birthDate and birthTime represent what the user selected
        // We extract the numeric values (year, month, day, hour, minute) that the user saw
        let deviceCalendar = Calendar.current
        let dateComponents = deviceCalendar.dateComponents([.year, .month, .day], from: birthDate)
        let timeComponents = deviceCalendar.dateComponents([.hour, .minute], from: birthTime)
        
        // Create DateComponents with birth location timezone
        // This ensures the user's selected time is interpreted in the birth location context
        var combinedComponents = DateComponents()
        combinedComponents.calendar = Calendar(identifier: .gregorian)
        combinedComponents.timeZone = timeZone  // Birth location timezone from geocoding
        combinedComponents.era = 1
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = hasUnknownTime ? 12 : timeComponents.hour
        combinedComponents.minute = hasUnknownTime ? 0 : timeComponents.minute
        combinedComponents.second = 0
        
        // Create final birth date using Calendar with birth location timezone
        // CRITICAL: This Calendar must have the same timezone for proper DST evaluation
        var birthLocationCalendar = Calendar(identifier: .gregorian)
        birthLocationCalendar.timeZone = timeZone
        
        guard let finalBirthDateTime = birthLocationCalendar.date(from: combinedComponents) else {
            showAlert(title: "Error", message: "Could not process birth date and time.")
            return
        }
        
        // STEP 4: Verification logging (DEBUG only)
        #if DEBUG
        verifyBirthDateCreation(
            date: finalBirthDateTime,
            timezone: timeZone,
            location: birthLocation,
            components: combinedComponents
        )
        #endif
        
        // Create user profile
        let profile = UserProfile(
            id: UUID().uuidString,
            firstName: firstName,
            birthDate: finalBirthDateTime,
            birthLocation: birthLocation,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            createdAt: Date(),
            lastModified: Date()
        )
        
        // Save profile
        if UserProfileStorage.shared.saveUserProfile(profile) {
            print("✅ Profile saved successfully")
            navigateToMainApp(with: profile)
        } else {
            showAlert(title: "Error", message: "Could not save your profile. Please try again.")
        }
    }
    
    private func navigateToMainApp(with profile: UserProfile) {
        // Calculate natal chart
        let chartData = NatalChartManager.shared.calculateNatalChart(
            date: profile.birthDate,
            latitude: profile.latitude,
            longitude: profile.longitude,
            timeZone: TimeZone(identifier: profile.timeZoneIdentifier) ?? TimeZone.current
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let birthInfo = "\(dateFormatter.string(from: profile.birthDate)) at \(profile.birthLocation) (Lat: \(String(format: "%.4f", profile.latitude)), Long: \(String(format: "%.4f", profile.longitude)))"
        
        let tabBarController = CosmicFitTabBarController()
        tabBarController.configure(with: chartData,
                                 birthInfo: birthInfo,
                                 birthDate: profile.birthDate,
                                 latitude: profile.latitude,
                                 longitude: profile.longitude,
                                 timeZone: TimeZone(identifier: profile.timeZoneIdentifier) ?? TimeZone.current)
        
        // Replace the entire app's navigation stack using AppDelegate
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let window = appDelegate.window {
                UIView.transition(with: window, duration: 0.1, options: .transitionCrossDissolve) {
                    window.rootViewController = tabBarController
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    #if DEBUG
    /// Comprehensive verification logging for birth date creation
    private func verifyBirthDateCreation(
        date: Date,
        timezone: TimeZone,
        location: String,
        components: DateComponents
    ) {
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        localFormatter.timeZone = timezone
        
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        utcFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let offsetSeconds = timezone.secondsFromGMT(for: date)
        let offsetHours = Double(offsetSeconds) / 3600.0
        let isDST = timezone.isDaylightSavingTime(for: date)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📅 BIRTH DATE CREATION VERIFICATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📆 Components: \(components.year!)-\(String(format: "%02d", components.month!))-\(String(format: "%02d", components.day!)) \(components.hour!):\(String(format: "%02d", components.minute!)):\(components.second!)")
        print("🌍 Local Time: \(localFormatter.string(from: date))")
        print("🔄 UTC Time: \(utcFormatter.string(from: date))")
        print("⏱️  Offset: UTC\(offsetHours >= 0 ? "+" : "")\(String(format: "%.1f", offsetHours)) hours")
        print("☀️  DST: \(isDST ? "Active (summer time)" : "Inactive (standard time)")")
        print("✅ Date pickers were in \(timezone.identifier) timezone")
        
        // Check for potential DST edge cases
        if let transitionInfo = timezone.nextDaylightSavingTimeTransition(after: date) {
            let transitionFormatter = DateFormatter()
            transitionFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            transitionFormatter.timeZone = timezone
            let transitionTime = transitionFormatter.string(from: transitionInfo)
            print("⚠️  Next DST Transition: \(transitionTime)")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    #endif
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
}

// MARK: - UITextFieldDelegate
extension OnboardingFormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            if isNameValid {
                actionButtonTapped()
            }
        } else if textField == locationTextField {
            textField.resignFirstResponder()
            if isLocationValid {
                actionButtonTapped()
            }
        }
        return true
    }
}
