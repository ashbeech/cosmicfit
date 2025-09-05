//
//  ProfileViewController.swift
//  Cosmic Fit
//
//  Created for user profile management
//

import UIKit
import CoreLocation

class ProfileViewController: UIViewController {
    
    // MARK: - UI Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let locationLabel = UILabel()
    
    private let birthDatePicker = UIDatePicker()
    private let birthTimePicker = UIDatePicker()
    private let locationTextField = UITextField()
    private let updateButton = UIButton(type: .system)
    private let deleteProfileButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    private var currentUserProfile: UserProfile?
    private var geocoder = CLGeocoder()
    private var latitude: Double = 0
    private var longitude: Double = 0
    private var locationName: String = ""
    private var timeZone: TimeZone = TimeZone.current
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply Cosmic Fit theme
        applyCosmicFitTheme()
        
        setupUI()
        loadCurrentUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Hide navigation bar
        navigationController?.navigationBar.isHidden = true
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never  // KEY FIX: Prevent automatic adjustments
        
        // Apply theme to scroll view
        CosmicFitTheme.styleScrollView(scrollView)
        
        view.addSubview(scrollView)
        
        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme content background
        CosmicFitTheme.styleContentBackground(contentView)
        
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            // FIX: Use view.topAnchor + contentInsetAdjustmentBehavior = .never (like Daily Fit)
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupFormElements()
        setupKeyboardDismissal()
    }

    private func setupFormElements() {
        // Title - with proper status bar compensation
        titleLabel.text = "Profile"
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to title
        CosmicFitTheme.styleTitleLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.largeTitle, weight: .bold)
        
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Edit your birth information"
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to subtitle
        CosmicFitTheme.styleBodyLabel(subtitleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body, weight: .regular)
        subtitleLabel.textColor = CosmicFitTheme.Colors.cosmicBlue.withAlphaComponent(0.7) // Slightly muted
        
        contentView.addSubview(subtitleLabel)
        
        // Birth Date Picker
        dateLabel.text = "Birth Date:"
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to form label
        CosmicFitTheme.styleBodyLabel(dateLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(dateLabel)
        
        birthDatePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            birthDatePicker.preferredDatePickerStyle = .wheels
        }
        birthDatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to date picker
        CosmicFitTheme.styleDatePicker(birthDatePicker)
        
        contentView.addSubview(birthDatePicker)
        
        // Birth Time Picker
        timeLabel.text = "Birth Time:"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to form label
        CosmicFitTheme.styleBodyLabel(timeLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(timeLabel)
        
        birthTimePicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            birthTimePicker.preferredDatePickerStyle = .wheels
        }
        birthTimePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to date picker
        CosmicFitTheme.styleDatePicker(birthTimePicker)
        
        contentView.addSubview(birthTimePicker)
        
        // Location Text Field
        locationLabel.text = "Birth Location:"
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to form label
        CosmicFitTheme.styleBodyLabel(locationLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(locationLabel)
        
        locationTextField.placeholder = "City, Country"
        locationTextField.returnKeyType = .search
        locationTextField.delegate = self
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to text field
        CosmicFitTheme.styleTextField(locationTextField)
        
        contentView.addSubview(locationTextField)
        
        // Update Button
        updateButton.setTitle("Update Profile", for: .normal)
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to update button (primary style)
        CosmicFitTheme.styleButton(updateButton, style: .primary)
        
        contentView.addSubview(updateButton)
        
        // Delete Profile Button
        deleteProfileButton.setTitle("Delete Profile", for: .normal)
        deleteProfileButton.addTarget(self, action: #selector(deleteProfileButtonTapped), for: .touchUpInside)
        deleteProfileButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to delete button (secondary style with red color override)
        CosmicFitTheme.styleButton(deleteProfileButton, style: .secondary)
        deleteProfileButton.backgroundColor = .systemRed
        deleteProfileButton.setTitleColor(.white, for: .normal)
        deleteProfileButton.layer.borderColor = UIColor.systemRed.cgColor
        
        contentView.addSubview(deleteProfileButton)
        
        // Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = CosmicFitTheme.Colors.cosmicOrange
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // FIX: Add proper status bar compensation (64pt) to first element
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 64),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            birthDatePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            birthDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            birthDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            timeLabel.topAnchor.constraint(equalTo: birthDatePicker.bottomAnchor, constant: 30),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            birthTimePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            birthTimePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            birthTimePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            locationLabel.topAnchor.constraint(equalTo: birthTimePicker.bottomAnchor, constant: 30),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            locationTextField.heightAnchor.constraint(equalToConstant: 50),
            
            updateButton.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 40),
            updateButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            updateButton.widthAnchor.constraint(equalToConstant: 250),
            updateButton.heightAnchor.constraint(equalToConstant: 50),
            
            deleteProfileButton.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: 20),
            deleteProfileButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            deleteProfileButton.widthAnchor.constraint(equalToConstant: 250),
            deleteProfileButton.heightAnchor.constraint(equalToConstant: 50),
            deleteProfileButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
    
    // MARK: - Configuration
    private func loadCurrentUserData() {
        currentUserProfile = UserProfileStorage.shared.loadUserProfile()
        
        guard let profile = currentUserProfile else {
            print("No user profile to load")
            return
        }
        
        // Populate form with existing data
        birthDatePicker.date = profile.birthDate
        birthTimePicker.date = profile.birthDate
        locationTextField.text = profile.birthLocation
        latitude = profile.latitude
        longitude = profile.longitude
        locationName = profile.birthLocation
        timeZone = TimeZone(identifier: profile.timeZoneIdentifier) ?? TimeZone.current
        
        print("✅ Profile form populated with existing data")
    }
    
    // MARK: - Keyboard Handling
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollView.contentInset.bottom = keyboardSize.height
            
            if #available(iOS 13.0, *) {
                scrollView.verticalScrollIndicatorInsets.bottom = keyboardSize.height
            } else {
                scrollView.scrollIndicatorInsets.bottom = keyboardSize.height
            }
            
            if locationTextField.isFirstResponder {
                let rect = locationTextField.convert(locationTextField.bounds, to: scrollView)
                scrollView.scrollRectToVisible(rect, animated: true)
            }
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
    
    // MARK: - Actions
    @objc private func updateButtonTapped() {
        guard let locationText = locationTextField.text, !locationText.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a birth location")
            return
        }
        
        activityIndicator.startAnimating()
        
        // First geocode the location
        geocoder.geocodeAddressString(locationText) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Location Error", message: "Could not find coordinates for the specified location. Please enter a valid city and country.")
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Location Error", message: "Could not find coordinates for the specified location. Please enter a valid city and country.")
                    return
                }
                
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
                self.locationName = locationText
                
                // Determine the time zone for the location
                if let timeZone = placemark.timeZone {
                    self.timeZone = timeZone
                } else {
                    self.timeZone = TimeZone(identifier: "Europe/London") ?? TimeZone.current
                }
                
                // Now update the profile
                self.updateProfile()
            }
        }
    }
    
    @objc private func deleteProfileButtonTapped() {
        let alert = UIAlertController(title: "Delete Profile",
                                    message: "This will delete all your data and require setting up your profile again.",
                                    preferredStyle: .alert)
        
        // Apply theme to alert
        if let titleString = alert.title {
            alert.setValue(CosmicFitTheme.createAttributedText(title: titleString, content: "", titleSize: CosmicFitTheme.Typography.FontSizes.headline), forKey: "attributedTitle")
        }
        
        if let messageString = alert.message {
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body),
                .foregroundColor: CosmicFitTheme.Colors.cosmicBlue
            ]
            alert.setValue(NSAttributedString(string: messageString, attributes: messageAttributes), forKey: "attributedMessage")
        }
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteProfile()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Profile Management
    private func updateProfile() {
        guard let currentProfile = currentUserProfile else {
            activityIndicator.stopAnimating()
            showAlert(title: "Error", message: "No current profile found")
            return
        }
        
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
            activityIndicator.stopAnimating()
            showAlert(title: "Date Error", message: "Could not process the birth date and time")
            return
        }
        
        // Create updated profile (manually create with preserved ID)
        let updatedProfile = UserProfile(
            id: currentProfile.id,
            birthDate: birthDateTime,
            birthLocation: locationName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            createdAt: currentProfile.createdAt,
            lastModified: Date()
        )
        
        // Save updated profile
        if UserProfileStorage.shared.saveUserProfile(updatedProfile) {
            currentUserProfile = updatedProfile
            
            // Notify other parts of app that profile was updated
            NotificationCenter.default.post(name: .userProfileUpdated, object: updatedProfile)
            
            activityIndicator.stopAnimating()
            showAlert(title: "Profile Updated", message: "Your birth information has been updated successfully. The app will refresh with your new data.")
        } else {
            activityIndicator.stopAnimating()
            showAlert(title: "Update Failed", message: "Could not update your profile. Please try again.")
        }
    }
    
    private func deleteProfile() {
        UserProfileStorage.shared.deleteUserProfile()
        
        // Post notification
        NotificationCenter.default.post(name: .userProfileDeleted, object: nil)
        
        // Navigate back to onboarding
        let mainVC = MainViewController()
        let navController = UINavigationController(rootViewController: mainVC)
        
        // Replace the entire app's navigation stack using AppDelegate
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.window?.rootViewController = navController
                print("🔄 Navigated back to onboarding after profile deletion")
            } else {
                // Fallback: present modally if we can't access app delegate
                self.present(navController, animated: true) {
                    print("⚠️ Used modal presentation as fallback for profile deletion navigation")
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Apply theme to alert
        if let titleString = alert.title {
            alert.setValue(CosmicFitTheme.createAttributedText(title: titleString, content: "", titleSize: CosmicFitTheme.Typography.FontSizes.headline), forKey: "attributedTitle")
        }
        
        if let messageString = alert.message {
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body),
                .foregroundColor: CosmicFitTheme.Colors.cosmicBlue
            ]
            alert.setValue(NSAttributedString(string: messageString, attributes: messageAttributes), forKey: "attributedMessage")
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == locationTextField {
            // Trigger update when user hits return on location field
            updateButtonTapped()
        }
        
        return true
    }
}
