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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
        updatePageContent()
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
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()
        if let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) {
            datePicker.minimumDate = hundredYearsAgo
        }
        
        // Time picker
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.text = "Time"
        timeLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        timeLabel.textColor = .black
        
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .compact
        
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
        locationTextField.placeholder = "Start typing"
        locationTextField.font = UIFont.systemFont(ofSize: 18)
        locationTextField.textColor = .black
        locationTextField.borderStyle = .none
        locationTextField.returnKeyType = .done
        locationTextField.delegate = self
        locationTextField.addTarget(self, action: #selector(locationFieldChanged), for: .editingChanged)
        
        locationDivider.translatesAutoresizingMaskIntoConstraints = false
        locationDivider.backgroundColor = .black
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
            inputContainerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 60),
            inputContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            inputContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Action button
            actionButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 60),
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
            nameTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
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
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            
            datePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: -20),
            datePicker.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            
            timeLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 30),
            timeLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            
            timePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: -30),
            timePicker.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            
            unknownTimeCheckbox.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20),
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
            locationTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 20),
            locationTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            locationTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            locationDivider.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: -16),
            locationDivider.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            locationDivider.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            locationDivider.heightAnchor.constraint(equalToConstant: 1),
            locationDivider.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor)
        ])
        
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
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        scrollView.contentInset.bottom = keyboardHeight
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        } else {
            scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        } else {
            scrollView.scrollIndicatorInsets.bottom = 0
        }
    }
    
    // MARK: - Helper Methods
    private func fadeToPage(_ page: Int) {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.currentPage = page
            UIView.animate(withDuration: 0.3) {
                self.view.alpha = 1.0
            }
        }
    }
    
    private func updateTimePickerState() {
        timePicker.isEnabled = !hasUnknownTime
        timePicker.alpha = hasUnknownTime ? 0.5 : 1.0
        timeLabel.alpha = hasUnknownTime ? 0.5 : 1.0
    }
    
    private func storeBirthData() {
        birthDate = datePicker.date
        if !hasUnknownTime {
            birthTime = timePicker.date
            
            // Combine date and time
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            if let combinedDate = calendar.date(from: combinedComponents) {
                birthDate = combinedDate
            }
        } else {
            // Default to 12:00 PM if time is unknown
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = 12
            combinedComponents.minute = 0
            
            if let combinedDate = calendar.date(from: combinedComponents) {
                birthDate = combinedDate
            }
        }
    }
    
    private func processLocationAndComplete() {
        let locationString = locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        birthLocation = locationString
        
        // Start location geocoding
        activityIndicator.startAnimating()
        actionButton.isEnabled = false
        
        geocoder.geocodeAddressString(locationString) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.actionButton.isEnabled = true
                
                if let error = error {
                    self?.showAlert(title: "Location Error", message: "Could not find this location. Please check the spelling and try again.")
                    print("Geocoding error: \(error)")
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    self?.showAlert(title: "Location Error", message: "Could not find coordinates for this location. Please try a different location.")
                    return
                }
                
                self?.latitude = location.coordinate.latitude
                self?.longitude = location.coordinate.longitude
                
                // Get timezone for the location
                let timeZone = TimeZone(identifier: placemark.timeZone?.identifier ?? TimeZone.current.identifier) ?? TimeZone.current
                self?.timeZone = timeZone
                
                // Create and save user profile
                self?.saveUserProfile()
            }
        }
    }
    
    private func saveUserProfile() {
        let userProfile = UserProfile(
            firstName: firstName,
            birthDate: birthDate,
            birthLocation: birthLocation,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone
        )
        
        if UserProfileStorage.shared.saveUserProfile(userProfile) {
            print("✅ User profile saved successfully")
            
            // Calculate chart and transition to main app
            let chartData = NatalChartManager.shared.calculateNatalChart(
                date: birthDate,
                latitude: latitude,
                longitude: longitude,
                timeZone: timeZone
            )
            
            // Format birth info for display
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let birthInfo = "\(dateFormatter.string(from: birthDate)) at \(birthLocation) (Lat: \(String(format: "%.4f", latitude)), Long: \(String(format: "%.4f", longitude)))"
            
            // Create and present the main app - FIX: Use proper window transition
            let tabBarController = CosmicFitTabBarController()
            tabBarController.configure(
                with: chartData,
                birthInfo: birthInfo,
                birthDate: birthDate,
                latitude: latitude,
                longitude: longitude,
                timeZone: timeZone
            )
            
            // CRITICAL FIX: Use window scene instead of modal presentation
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    
                    // Create navigation controller for tab bar
                    let navigationController = UINavigationController(rootViewController: tabBarController)
                    navigationController.navigationBar.isHidden = true
                    
                    // Smooth transition to main app
                    UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve) {
                        window.rootViewController = navigationController
                    } completion: { _ in
                        print("✅ Successfully transitioned to main app")
                    }
                } else {
                    print("❌ Could not find window for transition")
                    // Fallback to modal presentation
                    tabBarController.modalPresentationStyle = .fullScreen
                    self.present(tabBarController, animated: true)
                }
            }
        } else {
            showAlert(title: "Save Error", message: "Could not save your profile. Please try again.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension OnboardingFormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            actionButtonTapped()
        } else if textField == locationTextField {
            actionButtonTapped()
        }
        return true
    }
}
