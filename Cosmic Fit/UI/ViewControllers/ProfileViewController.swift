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
    /// Shown in the form; wheels live in `inputView` only so scrolling cannot change values.
    private let birthDateField = UITextField()
    private let birthTimeField = UITextField()
    private let birthDatePicker = UIDatePicker()
    private let birthTimePicker = UIDatePicker()
    private let unknownTimeCheckbox = UIButton(type: .system)
    private let unknownTimeLabel = UILabel()
    private var birthTimeIsUnknown: Bool = false
    
    private let locationAutocompleteView = LocationAutocompleteView()
    private let updateButton = UIButton(type: .system)
    #if DEBUG
    private let forceRefreshButton = UIButton(type: .system)
    #endif
    private let signOutButton = UIButton(type: .system)
    private let deleteProfileButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let mainStack = UIStackView()
    private let topFormDivider = UIView()
    private let dangerSectionDivider = UIView()
    
    // Callback for dismissal request
    var onDismissRequested: (() -> Void)?
    
    // MARK: - Properties
    private var currentUserProfile: UserProfile?
    private var geocoder = CLGeocoder()
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var locationName: String = ""
    private var timeZone: TimeZone = TimeZone.current
    
    private let birthDateDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()
    
    private let birthTimeDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
    
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
        /*
        if let parentVC = parent {
            parentVC.view.isUserInteractionEnabled = true
        }*/
    }
    
    // MARK: - UI Setup
    
    private func styleFieldCaption(_ label: UILabel, text: String) {
        label.text = text
        label.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.callout, weight: .semibold)
        label.textColor = CosmicFitTheme.Colours.cosmicBlue
        label.numberOfLines = 0
    }
    
    private func verticalFieldStack(label: UILabel, field: UIView, spacing: CGFloat = 8) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = .fill
        return stack
    }
    
    private func configureBirthDateTimePickersAndFields() {
        birthDatePicker.datePickerMode = .date
        birthDatePicker.preferredDatePickerStyle = .wheels
        birthDatePicker.maximumDate = Date()
        if let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) {
            birthDatePicker.minimumDate = hundredYearsAgo
        }
        CosmicFitTheme.styleDatePicker(birthDatePicker)
        birthDatePicker.addTarget(self, action: #selector(birthDatePickerValueChanged), for: .valueChanged)
        
        birthTimePicker.datePickerMode = .time
        birthTimePicker.preferredDatePickerStyle = .wheels
        CosmicFitTheme.styleDatePicker(birthTimePicker)
        birthTimePicker.addTarget(self, action: #selector(birthTimePickerValueChanged), for: .valueChanged)
        
        birthDateField.translatesAutoresizingMaskIntoConstraints = false
        birthTimeField.translatesAutoresizingMaskIntoConstraints = false
        birthDateField.placeholder = "Tap to select date"
        birthTimeField.placeholder = "Tap to select time"
        CosmicFitTheme.styleTextField(birthDateField)
        CosmicFitTheme.styleTextField(birthTimeField)
        birthDateField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        birthTimeField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        birthDateField.delegate = self
        birthTimeField.delegate = self
        birthDateField.autocorrectionType = .no
        birthTimeField.autocorrectionType = .no
        birthDateField.spellCheckingType = .no
        birthTimeField.spellCheckingType = .no
        birthDateField.textContentType = .none
        birthTimeField.textContentType = .none
        birthDateField.returnKeyType = .done
        birthTimeField.returnKeyType = .done
        
        birthDateField.inputView = birthDatePicker
        birthTimeField.inputView = birthTimePicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(birthDateTimePickerDoneTapped))
        toolbar.setItems([flex, done], animated: false)
        birthDateField.inputAccessoryView = toolbar
        birthTimeField.inputAccessoryView = toolbar
        
        configureUnknownTimeControls()
    }
    
    private func configureUnknownTimeControls() {
        unknownTimeCheckbox.translatesAutoresizingMaskIntoConstraints = false
        let uncheckedImage = makeCheckboxImage(filled: false)
        let checkedImage = makeCheckboxImage(filled: true)
        unknownTimeCheckbox.setImage(uncheckedImage, for: .normal)
        unknownTimeCheckbox.setImage(uncheckedImage, for: .highlighted)
        unknownTimeCheckbox.setImage(checkedImage, for: .selected)
        unknownTimeCheckbox.setImage(checkedImage, for: [.selected, .highlighted])
        unknownTimeCheckbox.tintColor = CosmicFitTheme.Colours.cosmicBlue
        unknownTimeCheckbox.addTarget(self, action: #selector(unknownTimeToggled), for: .touchUpInside)
        
        unknownTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        unknownTimeLabel.text = "I don't know my time"
        unknownTimeLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.callout, weight: .regular)
        unknownTimeLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
    }
    
    private func makeCheckboxImage(filled: Bool) -> UIImage? {
        let size = CGSize(width: 22, height: 22)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 2)
            cgContext.setStrokeColor(CosmicFitTheme.Colours.cosmicBlue.cgColor)
            cgContext.setLineWidth(1.5)
            path.stroke()
            
            if filled {
                cgContext.setStrokeColor(CosmicFitTheme.Colours.cosmicBlue.cgColor)
                cgContext.setLineWidth(2.0)
                cgContext.setLineCap(.round)
                cgContext.move(to: CGPoint(x: rect.minX + 4, y: rect.midY))
                cgContext.addLine(to: CGPoint(x: rect.midX - 1, y: rect.maxY - 4))
                cgContext.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.minY + 4))
                cgContext.strokePath()
            }
        }.withRenderingMode(.alwaysOriginal)
    }
    
    @objc private func unknownTimeToggled() {
        unknownTimeCheckbox.isSelected.toggle()
        birthTimeIsUnknown = unknownTimeCheckbox.isSelected
        updateBirthTimeFieldState()
    }
    
    private func updateBirthTimeFieldState() {
        birthTimeField.isEnabled = !birthTimeIsUnknown
        birthTimeField.alpha = birthTimeIsUnknown ? 0.4 : 1.0
        timeLabel.alpha = birthTimeIsUnknown ? 0.4 : 1.0
        if birthTimeIsUnknown, birthTimeField.isFirstResponder {
            birthTimeField.resignFirstResponder()
        }
    }
    
    private func refreshBirthDateFieldDisplay() {
        birthDateDisplayFormatter.timeZone = timeZone
        birthDateField.text = birthDateDisplayFormatter.string(from: birthDatePicker.date)
    }
    
    private func refreshBirthTimeFieldDisplay() {
        birthTimeDisplayFormatter.timeZone = timeZone
        birthTimeField.text = birthTimeDisplayFormatter.string(from: birthTimePicker.date)
    }
    
    @objc private func birthDatePickerValueChanged() {
        refreshBirthDateFieldDisplay()
    }
    
    @objc private func birthTimePickerValueChanged() {
        refreshBirthTimeFieldDisplay()
    }
    
    @objc private func birthDateTimePickerDoneTapped() {
        if birthDateField.isFirstResponder {
            refreshBirthDateFieldDisplay()
        } else if birthTimeField.isFirstResponder {
            refreshBirthTimeFieldDisplay()
        }
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleScrollView(scrollView)
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .fill
        contentView.addSubview(mainStack)
        
        titleLabel.text = "Update Your Profile"
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleTitleLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        
        subtitleLabel.text = "Edit your birth details to refresh your cosmic chart and daily guidance."
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.callout, weight: .regular)
        subtitleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.72)
        
        topFormDivider.translatesAutoresizingMaskIntoConstraints = false
        topFormDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        topFormDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        styleFieldCaption(nameLabel, text: "First name")
        styleFieldCaption(dateLabel, text: "Birth date")
        styleFieldCaption(timeLabel, text: "Birth time")
        styleFieldCaption(locationLabel, text: "Birth location")
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleTextField(nameTextField)
        nameTextField.placeholder = "Enter your first name"
        nameTextField.returnKeyType = .next
        nameTextField.delegate = self
        nameTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        configureBirthDateTimePickersAndFields()
        
        locationAutocompleteView.translatesAutoresizingMaskIntoConstraints = false
        locationAutocompleteView.delegate = self
        locationAutocompleteView.applyCosmicFieldStyling()
        locationAutocompleteView.setPlaceholder("Start typing city, town, or address")
        locationAutocompleteView.setupSuggestionsOverlay(in: contentView)
        
        updateButton.setTitle("Update profile", for: .normal)
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(updateButton, style: .primary)
        updateButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        #if DEBUG
        forceRefreshButton.setTitle("⟳ Force refresh all data", for: .normal)
        forceRefreshButton.addTarget(self, action: #selector(forceRefreshTapped), for: .touchUpInside)
        forceRefreshButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(forceRefreshButton, style: .secondary)
        forceRefreshButton.layer.borderColor = UIColor.systemOrange.cgColor
        forceRefreshButton.layer.borderWidth = 1.5
        forceRefreshButton.setTitleColor(.systemOrange, for: .normal)
        forceRefreshButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        #endif
        
        signOutButton.setTitle("Sign out", for: .normal)
        signOutButton.addTarget(self, action: #selector(signOutButtonTapped), for: .touchUpInside)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(signOutButton, style: .secondary)
        signOutButton.isHidden = !CosmicFitAuthService.shared.isAuthenticated
        signOutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        deleteProfileButton.setTitle("Delete profile", for: .normal)
        deleteProfileButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteProfileButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(deleteProfileButton, style: .secondary)
        deleteProfileButton.backgroundColor = .systemRed
        deleteProfileButton.setTitleColor(.white, for: .normal)
        deleteProfileButton.layer.borderWidth = 0
        deleteProfileButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        dangerSectionDivider.translatesAutoresizingMaskIntoConstraints = false
        dangerSectionDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.28)
        dangerSectionDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = CosmicFitTheme.Colours.cosmicBlue
        view.addSubview(activityIndicator)
        
        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(subtitleLabel)
        mainStack.setCustomSpacing(20, after: titleLabel)
        mainStack.setCustomSpacing(28, after: subtitleLabel)
        mainStack.addArrangedSubview(topFormDivider)
        mainStack.setCustomSpacing(28, after: topFormDivider)
        
        mainStack.addArrangedSubview(verticalFieldStack(label: nameLabel, field: nameTextField))
        mainStack.addArrangedSubview(verticalFieldStack(label: dateLabel, field: birthDateField))
        mainStack.addArrangedSubview(verticalFieldStack(label: timeLabel, field: birthTimeField))
        
        let unknownTimeRow = UIStackView(arrangedSubviews: [unknownTimeCheckbox, unknownTimeLabel])
        unknownTimeRow.axis = .horizontal
        unknownTimeRow.spacing = 10
        unknownTimeRow.alignment = .center
        unknownTimeCheckbox.widthAnchor.constraint(equalToConstant: 26).isActive = true
        unknownTimeCheckbox.heightAnchor.constraint(equalToConstant: 26).isActive = true
        mainStack.addArrangedSubview(unknownTimeRow)
        mainStack.setCustomSpacing(8, after: mainStack.arrangedSubviews[mainStack.arrangedSubviews.count - 2])
        
        mainStack.addArrangedSubview(verticalFieldStack(label: locationLabel, field: locationAutocompleteView))
        
        mainStack.setCustomSpacing(28, after: mainStack.arrangedSubviews.last!)
        
        mainStack.addArrangedSubview(updateButton)
        mainStack.setCustomSpacing(34, after: updateButton)
        mainStack.addArrangedSubview(dangerSectionDivider)
        mainStack.setCustomSpacing(22, after: dangerSectionDivider)
        #if DEBUG
        mainStack.addArrangedSubview(forceRefreshButton)
        #endif
        mainStack.addArrangedSubview(signOutButton)
        mainStack.addArrangedSubview(deleteProfileButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 56),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28),
            
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
        
        refreshBirthDateFieldDisplay()
        refreshBirthTimeFieldDisplay()
        
        // Populate form with existing data
        nameTextField.text = profile.firstName
        locationAutocompleteView.setText(profile.birthLocation)
        latitude = profile.latitude
        longitude = profile.longitude
        locationName = profile.birthLocation
        
        birthTimeIsUnknown = profile.birthTimeIsUnknown
        unknownTimeCheckbox.isSelected = birthTimeIsUnknown
        updateBirthTimeFieldState()
        
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
        
        let locationString = locationAutocompleteView.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !locationString.isEmpty, latitude != 0.0, longitude != 0.0 else {
            showAlert(title: "Location Required", message: "Please select a valid birth location from the suggestions.")
            return
        }
        
        // Location is already validated from the autocomplete, proceed with update
        locationName = locationString
        updateProfile()
    }
    
    #if DEBUG
    @objc private func forceRefreshTapped() {
        forceRefreshButton.isEnabled = false
        forceRefreshButton.setTitle("Refreshing…", for: .normal)

        BlueprintStorage.shared.delete()

        NotificationCenter.default.post(name: .devForceRefreshRequested, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.forceRefreshButton.setTitle("⟳ Force refresh all data", for: .normal)
            self.forceRefreshButton.isEnabled = true
        }
    }
    #endif

    @objc private func signOutButtonTapped() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "You will need to sign in again to access your Daily Fit.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            Task {
                try? await CosmicFitAuthService.shared.signOut()
            }
        })
        present(alert, animated: true)
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
    
    private func updateProfile() {
        guard let currentProfile = currentUserProfile else {
            activityIndicator.stopAnimating()
            updateButton.isEnabled = true
            showAlert(title: "Error", message: "No current profile found")
            return
        }
        
        // Get dates from pickers
        let birthDate = birthDatePicker.date
        let birthTime = birthTimePicker.date
        
        // CRITICAL FIX: Extract components using the picker's CURRENT timezone
        // This gets the actual numeric values the user sees (e.g., 04:30)
        var pickerCalendar = Calendar(identifier: .gregorian)
        pickerCalendar.timeZone = birthDatePicker.timeZone ?? timeZone
        let dateComponents = pickerCalendar.dateComponents([.year, .month, .day], from: birthDate)
        
        pickerCalendar.timeZone = birthTimePicker.timeZone ?? timeZone
        let timeComponents = pickerCalendar.dateComponents([.hour, .minute], from: birthTime)
        
        // Create calendar in birth location timezone for final date creation
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        // Combine components
        var combinedComponents = DateComponents()
        combinedComponents.calendar = calendar
        combinedComponents.timeZone = timeZone
        combinedComponents.era = 1
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = birthTimeIsUnknown ? 12 : timeComponents.hour
        combinedComponents.minute = birthTimeIsUnknown ? 0 : timeComponents.minute
        combinedComponents.second = 0
        
        // Create final date
        guard let birthDateTime = calendar.date(from: combinedComponents) else {
            activityIndicator.stopAnimating()
            updateButton.isEnabled = true
            showAlert(title: "Date Error", message: "Could not process the birth date and time")
            return
        }
        
        // Create updated profile
        let updatedProfile = UserProfile(
            id: currentProfile.id,
            firstName: nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            birthDate: birthDateTime,
            birthLocation: locationName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            birthTimeIsUnknown: birthTimeIsUnknown,
            createdAt: currentProfile.createdAt,
            lastModified: Date()
        )
        
        // Stop loading and show success animation with immediate dismissal
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
        showSuccessStateAndDismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if UserProfileStorage.shared.saveUserProfile(updatedProfile) {
                self.currentUserProfile = updatedProfile
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: .userProfileUpdated,
                        object: updatedProfile
                    )
                }
                
                // Sync to Supabase if authenticated
                if CosmicFitAuthService.shared.isAuthenticated {
                    Task {
                        try? await SupabaseSyncService.shared.syncProfileToSupabase(updatedProfile)
                    }
                }
            }
        }
    }
    
    private func deleteProfile() {
        UserProfileStorage.shared.deleteUserProfile()
        
        // Post notification
        NotificationCenter.default.post(name: .userProfileDeleted, object: nil)
        
        // Navigate back to onboarding - skip welcome since they've seen it
        let onboardingFormVC = OnboardingFormViewController()
        let navController = UINavigationController(rootViewController: onboardingFormVC)
        navController.navigationBar.isHidden = true
        
        // Replace the entire app's navigation stack using AppDelegate
        DispatchQueue.main.async {
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
    
    // Request dismissal via notification (for debugging)
    private func requestDismissal() {
        print("🔍 ProfileViewController posting dismiss notification...")
        print("🔍 Notification name: dismissProfileRequested")
        print("🔍 Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        NotificationCenter.default.post(name: .dismissProfileRequested, object: nil)
        
        print("🔍 Notification posted successfully")
    }
    
    // MARK: - Success State Animation
    private func showSuccessStateAndDismiss() {
        // Disable the button to prevent multiple taps during animation
        updateButton.isEnabled = false
        
        // Store the original button configuration to restore later
        //let originalTitle = updateButton.title(for: .normal)
        //let originalbackgroundColor = updateButton.backgroundColor
        
        // Show success animation
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.updateButton.backgroundColor = .systemGreen
            self.updateButton.setTitle("", for: .normal)
        }) { _ in
            self.addCheckmarkToButton()
            
            // DISMISS WITHOUT SAVING (temporary test)
            print("DISMISSING WITHOUT SAVING (TEST)!!!")
            self.requestDismissal()
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
    
    private func resetButtonToOriginalState(title: String, backgroundColor: UIColor) {
        // Animate back to original state (NO SCALE ANIMATION)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // Restore original background colour
            self.updateButton.backgroundColor = backgroundColor
            
            // Remove the checkmark image
            self.updateButton.setImage(nil, for: .normal)
            
            // Restore the original title
            self.updateButton.setTitle(title, for: .normal)
            
            // NO SCALE TRANSFORM - REMOVED
        }) { _ in
            // Re-enable the button so it can be used again
            self.updateButton.isEnabled = true
            
            print("✅ Update button reset to original state and re-enabled")
        }
    }
}

// MARK: - LocationAutocompleteDelegate
extension ProfileViewController: LocationAutocompleteDelegate {
    func locationAutocompleteDidSelectLocation(name: String, latitude: Double, longitude: Double, timeZone: TimeZone) {
        // Update with validated location
        self.locationName = name
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
        
        birthDatePicker.timeZone = timeZone
        birthTimePicker.timeZone = timeZone
        refreshBirthDateFieldDisplay()
        refreshBirthTimeFieldDisplay()
        
        print("✅ Location selected: \(name)")
        print("📍 Coordinates: \(latitude), \(longitude)")
        print("🕐 Timezone: \(timeZone.identifier)")
    }
    
    func locationAutocompleteDidUpdateText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            latitude = 0
            longitude = 0
            locationName = ""
        }
    }
}

// MARK: - UITextFieldDelegate
extension ProfileViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === birthDateField || textField === birthTimeField {
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameTextField {
            textField.resignFirstResponder()
        } else if textField === birthDateField || textField === birthTimeField {
            birthDateTimePickerDoneTapped()
        }
        return true
    }
}
