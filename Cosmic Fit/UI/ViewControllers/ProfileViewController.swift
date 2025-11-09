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
    
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let locationLabel = UILabel()
    
    private let nameTextField = UITextField()
    private let birthDatePicker = UIDatePicker()
    private let birthTimePicker = UIDatePicker()
    private let locationTextField = UITextField()
    private let updateButton = UIButton(type: .system)
    private let deleteProfileButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    private var currentUserProfile: UserProfile?
    private var geocoder = CLGeocoder()
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var locationName: String = ""
    private var timeZone: TimeZone = TimeZone.current
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyCosmicFitTheme()
        setupUI()
        setupConstraints()
        setupKeyboardDismissal()
        loadCurrentUserData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure navigation bar is visible
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure the view is always fully interactive when visible
        view.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        // Ensure the close button in the parent GenericDetailViewController is accessible
        // This helps prevent any potential blocking of the close button
        if let parentVC = parent {
            parentVC.view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        // Apply theme to scroll view
        CosmicFitTheme.styleScrollView(scrollView)
        
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "Update Your Profile"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to title
        CosmicFitTheme.styleTitleLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Edit your birth details to update your cosmic profile"
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to subtitle
        CosmicFitTheme.styleBodyLabel(subtitleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body)
        
        subtitleLabel.numberOfLines = 0
        contentView.addSubview(subtitleLabel)
        
        // Name section
        nameLabel.text = "First Name"
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to section labels
        CosmicFitTheme.styleBodyLabel(nameLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(nameLabel)
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to text field
        CosmicFitTheme.styleTextField(nameTextField)
        
        nameTextField.placeholder = "Enter your first name"
        nameTextField.returnKeyType = .next
        nameTextField.delegate = self
        contentView.addSubview(nameTextField)
        
        // Date section
        dateLabel.text = "Birth Date"
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to section labels
        CosmicFitTheme.styleBodyLabel(dateLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(dateLabel)
        
        birthDatePicker.translatesAutoresizingMaskIntoConstraints = false
        birthDatePicker.datePickerMode = .date
        birthDatePicker.preferredDatePickerStyle = .wheels
        birthDatePicker.maximumDate = Date()
        
        // Apply theme to date picker
        CosmicFitTheme.styleDatePicker(birthDatePicker)
        
        if let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) {
            birthDatePicker.minimumDate = hundredYearsAgo
        }
        contentView.addSubview(birthDatePicker)
        
        // Time section
        timeLabel.text = "Birth Time"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to section labels
        CosmicFitTheme.styleBodyLabel(timeLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(timeLabel)
        
        birthTimePicker.translatesAutoresizingMaskIntoConstraints = false
        birthTimePicker.datePickerMode = .time
        birthTimePicker.preferredDatePickerStyle = .wheels
        
        // Apply theme to time picker
        CosmicFitTheme.styleDatePicker(birthTimePicker)
        
        contentView.addSubview(birthTimePicker)
        
        // Location section
        locationLabel.text = "Birth Location"
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to section labels
        CosmicFitTheme.styleBodyLabel(locationLabel, fontSize: CosmicFitTheme.Typography.FontSizes.headline, weight: .semibold)
        
        contentView.addSubview(locationLabel)
        
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to text field
        CosmicFitTheme.styleTextField(locationTextField)
        
        locationTextField.placeholder = "Enter birth city/location"
        locationTextField.returnKeyType = .done
        locationTextField.delegate = self
        contentView.addSubview(locationTextField)
        
        // Update button
        updateButton.setTitle("Update Profile", for: .normal)
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to primary button
        CosmicFitTheme.styleButton(updateButton, style: .primary)
        
        contentView.addSubview(updateButton)
        
        // Delete button
        deleteProfileButton.setTitle("Delete Profile", for: .normal)
        deleteProfileButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteProfileButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply theme to destructive button - use secondary style with red color
        CosmicFitTheme.styleButton(deleteProfileButton, style: .secondary)
        deleteProfileButton.backgroundColor = .systemRed
        deleteProfileButton.setTitleColor(.white, for: .normal)
        
        contentView.addSubview(deleteProfileButton)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .black
        view.addSubview(activityIndicator)
        
        print("ProfileViewController UI set up with Cosmic Fit theme styling")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60), // Space for close button
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Name section
            nameLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Date section
            dateLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 30),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            birthDatePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            birthDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            birthDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Time section
            timeLabel.topAnchor.constraint(equalTo: birthDatePicker.bottomAnchor, constant: 30),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            birthTimePicker.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            birthTimePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            birthTimePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Location section
            locationLabel.topAnchor.constraint(equalTo: birthTimePicker.bottomAnchor, constant: 30),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Buttons
            updateButton.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 40),
            updateButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            updateButton.widthAnchor.constraint(equalToConstant: 250),
            updateButton.heightAnchor.constraint(equalToConstant: 50),
            
            deleteProfileButton.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: 20),
            deleteProfileButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            deleteProfileButton.widthAnchor.constraint(equalToConstant: 250),
            deleteProfileButton.heightAnchor.constraint(equalToConstant: 50),
            deleteProfileButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Activity indicator
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
        
        // Load timezone first
        timeZone = TimeZone(identifier: profile.timeZoneIdentifier) ?? TimeZone.current
        
        // CRITICAL: Set picker timezones BEFORE setting dates
        // This ensures the pickers display times in the birth location timezone
        birthDatePicker.timeZone = timeZone
        birthTimePicker.timeZone = timeZone
        
        // Now set the dates - pickers will display them in birth location timezone
        birthDatePicker.date = profile.birthDate
        birthTimePicker.date = profile.birthDate
        
        // Populate form with existing data
        nameTextField.text = profile.firstName
        locationTextField.text = profile.birthLocation
        latitude = profile.latitude
        longitude = profile.longitude
        locationName = profile.birthLocation
        
        #if DEBUG
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        localFormatter.timeZone = timeZone
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📂 PROFILE LOADED")
        print("📍 Location: \(profile.birthLocation)")
        print("🕐 Timezone: \(timeZone.identifier)")
        print("📅 Birth Date: \(profile.birthDate)")
        print("🌍 Displayed in pickers as: \(localFormatter.string(from: profile.birthDate))")
        print("✅ Pickers configured with birth location timezone")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
    }
    
    // MARK: - Keyboard Handling
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            scrollView.contentInset.bottom = keyboardHeight
            if #available(iOS 13.0, *) {
                scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
            } else {
                scrollView.scrollIndicatorInsets.bottom = keyboardHeight
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
        guard let firstName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !firstName.isEmpty else {
            showAlert(title: "Name Required", message: "Please enter your first name.")
            return
        }
        
        guard let locationString = locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !locationString.isEmpty else {
            showAlert(title: "Location Required", message: "Please enter your birth location.")
            return
        }
        
        locationName = locationString
        
        // Start activity indicator
        activityIndicator.startAnimating()
        updateButton.isEnabled = false
        
        // Geocode the location if it's different from current
        if locationName != currentUserProfile?.birthLocation {
            geocoder.geocodeAddressString(locationName) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.activityIndicator.stopAnimating()
                        self?.updateButton.isEnabled = true
                        self?.showAlert(title: "Location Error", message: "Could not find this location. Please check the spelling and try again.")
                        print("Geocoding error: \(error)")
                        return
                    }
                    
                    guard let placemark = placemarks?.first,
                          let location = placemark.location else {
                        self?.activityIndicator.stopAnimating()
                        self?.updateButton.isEnabled = true
                        self?.showAlert(title: "Location Error", message: "Could not find coordinates for this location. Please try a different location.")
                        return
                    }
                    
                    self?.latitude = location.coordinate.latitude
                    self?.longitude = location.coordinate.longitude
                    
                    // Get timezone for the location
                    let timeZone = TimeZone(identifier: placemark.timeZone?.identifier ?? TimeZone.current.identifier) ?? TimeZone.current
                    self?.timeZone = timeZone
                    
                    // CRITICAL: Update picker timezones when location changes
                    // This ensures the pickers display times in the new location's timezone
                    self?.birthDatePicker.timeZone = timeZone
                    self?.birthTimePicker.timeZone = timeZone
                    
                    #if DEBUG
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("🔄 LOCATION UPDATED")
                    print("📍 New Location: \(self?.locationName ?? "")")
                    print("🕐 New Timezone: \(timeZone.identifier)")
                    print("✅ Pickers reconfigured with new timezone")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    #endif
                    
                    // Now update the profile
                    self?.updateProfile()
                }
            }
        } else {
            // Location hasn't changed, proceed with update
            updateProfile()
        }
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Delete Profile",
            message: "Are you sure you want to delete your profile? This action cannot be undone and you will need to re-enter all your information.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteProfile()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Profile Management
    private func updateProfile() {
        guard let currentProfile = currentUserProfile else {
            activityIndicator.stopAnimating()
            updateButton.isEnabled = true
            showAlert(title: "Error", message: "No current profile found")
            return
        }
        
        // Get dates from pickers
        // Pickers are in birth location timezone, so these dates are correct
        let birthDate = birthDatePicker.date
        let birthTime = birthTimePicker.date
        
        // Create calendar in birth location timezone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        // Extract components (in birth location timezone)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)
        
        // Combine components
        var combinedComponents = DateComponents()
        combinedComponents.calendar = calendar
        combinedComponents.timeZone = timeZone
        combinedComponents.era = 1
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = 0
        
        // Create final date
        guard let birthDateTime = calendar.date(from: combinedComponents) else {
            activityIndicator.stopAnimating()
            updateButton.isEnabled = true
            showAlert(title: "Date Error", message: "Could not process the birth date and time")
            return
        }
        
        // STEP 4: Verification logging (DEBUG only)
        #if DEBUG
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        localFormatter.timeZone = timeZone
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 PROFILE UPDATE VERIFICATION")
        print("📍 Location: \(locationName)")
        print("🕐 Timezone: \(timeZone.identifier)")
        print("📆 Components: \(dateComponents.year!)-\(String(format: "%02d", dateComponents.month!))-\(String(format: "%02d", dateComponents.day!)) \(timeComponents.hour!):\(String(format: "%02d", timeComponents.minute!))")
        print("🌍 Local Time: \(localFormatter.string(from: birthDateTime))")
        print("🔄 UTC: \(birthDateTime)")
        print("☀️  DST: \(timeZone.isDaylightSavingTime(for: birthDateTime) ? "Active" : "Inactive")")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
        
        // Create updated profile (manually create with preserved ID)
        let updatedProfile = UserProfile(
            id: currentProfile.id,
            firstName: nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            birthDate: birthDateTime,
            birthLocation: locationName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            createdAt: currentProfile.createdAt,
            lastModified: Date()
        )
        
        // STEP 5: Save and notify
        if UserProfileStorage.shared.saveUserProfile(updatedProfile) {
            currentUserProfile = updatedProfile
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: updatedProfile
            )
            
            // Stop activity indicator
            activityIndicator.stopAnimating()
            
            // CRITICAL: Ensure the view is fully interactive after update
            view.isUserInteractionEnabled = true
            
            // Show success state on button (will auto-reset after 2 seconds)
            showSuccessStateAndDismiss()
            
            print("✅ Profile updated successfully - button will reset in 2 seconds")
        } else {
            activityIndicator.stopAnimating()
            updateButton.isEnabled = true
            
            // CRITICAL: Ensure the view is fully interactive after error
            view.isUserInteractionEnabled = true
            
            showAlert(title: "Update Failed", message: "Could not update your profile. Please try again.")
        }
    }
    
    private func deleteProfile() {
        UserProfileStorage.shared.deleteUserProfile()
        
        // Post notification
        NotificationCenter.default.post(name: .userProfileDeleted, object: nil)
        
        // First, dismiss the profile edit page
        dismissProfileEditPage()
        
        // Then navigate back to onboarding - skip welcome since they've seen it
        // Use a slight delay to allow the dismiss animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let onboardingFormVC = OnboardingFormViewController()
            let navController = UINavigationController(rootViewController: onboardingFormVC)
            navController.navigationBar.isHidden = true
            
            // Replace the entire app's navigation stack using AppDelegate
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let window = appDelegate.window {
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve) {
                    window.rootViewController = navController
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Success State Animation
    private func showSuccessStateAndDismiss() {
        // Disable the button to prevent multiple taps during animation
        updateButton.isEnabled = false
        
        // Store the original button configuration to restore later
        let originalTitle = updateButton.title(for: .normal)
        let originalBackgroundColor = updateButton.backgroundColor
        
        // Animate the button to green with checkmark (NO SCALE ANIMATION)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // Change to green background
            self.updateButton.backgroundColor = .systemGreen
            
            // Clear the title text
            self.updateButton.setTitle("", for: .normal)
            
            // NO SCALE TRANSFORM - REMOVED
        }) { _ in
            // After the color change, add the checkmark icon
            self.addCheckmarkToButton()
            
            // Wait 2 seconds to let the user see the success state
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Dismiss the profile edit page after successful update
                self.dismissProfileEditPage()
            }
        }
    }
    
    private func addCheckmarkToButton() {
        // Create checkmark image configuration
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let checkmarkImage = UIImage(systemName: "checkmark", withConfiguration: config)
        
        // Set the checkmark as the button image
        updateButton.setImage(checkmarkImage, for: .normal)
        updateButton.tintColor = .white
        
        // Center the image in the button
        updateButton.imageView?.contentMode = .scaleAspectFit
        
        // Ensure image is centered (remove any existing insets)
        updateButton.contentHorizontalAlignment = .center
        updateButton.contentVerticalAlignment = .center
        
        // Animate the checkmark appearance
        updateButton.imageView?.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.updateButton.imageView?.alpha = 1
        }
    }
    
    private func dismissProfileEditPage() {
        // ProfileViewController is a child of GenericDetailViewController
        // GenericDetailViewController is a child of CosmicFitTabBarController
        // So we need to find the GenericDetailViewController (direct parent) and dismiss it
        
        // Method 1: Direct parent should be GenericDetailViewController
        if let genericDetailVC = self.parent as? GenericDetailViewController {
            genericDetailVC.dismissSelf()
            return
        }
        
        // Method 2: Find GenericDetailViewController in parent chain
        var currentParent: UIViewController? = self.parent
        while currentParent != nil {
            if let genericDetailVC = currentParent as? GenericDetailViewController {
                genericDetailVC.dismissSelf()
                return
            }
            currentParent = currentParent?.parent
        }
        
        // Method 3: Find CosmicFitTabBarController (parent of GenericDetailViewController)
        currentParent = self.parent?.parent
        while currentParent != nil {
            if let tabBarController = currentParent as? CosmicFitTabBarController {
                tabBarController.dismissDetailViewController(animated: true)
                return
            }
            currentParent = currentParent?.parent
        }
        
        // Final fallback: Try standard dismiss
        if let presentingVC = self.presentingViewController {
            presentingVC.dismiss(animated: true)
        } else {
            print("⚠️ Could not find appropriate view controller to dismiss profile edit page")
        }
    }
}

// MARK: - UITextFieldDelegate
extension ProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            locationTextField.becomeFirstResponder()
        } else if textField == locationTextField {
            textField.resignFirstResponder()
            updateButtonTapped()
        }
        return true
    }
}
