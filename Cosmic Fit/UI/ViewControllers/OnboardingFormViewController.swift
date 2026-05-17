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
    private let stepImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let inputContainerView = UIView()
    private let actionButton = UIButton(type: .system)
    private let pageIndicatorLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // Page-specific input views
    private let nameTextField = UITextField()
    private let nameDivider = UIView()
    private let nameSparkleLabel = UILabel()

    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let dateField = UITextField()
    private let timeField = UITextField()
    private let dateDivider = UIView()
    private let timeDivider = UIView()
    private let datePicker = UIDatePicker()
    private let timePicker = UIDatePicker()
    private let unknownTimeCheckbox = UIButton(type: .system)
    private let unknownTimeLabel = UILabel()
    private var hasSelectedDate = false
    private var hasSelectedTime = false

    private let locationAutocompleteView = LocationAutocompleteView()

    // MARK: - Properties
    private var currentPage: Int = 1 {
        didSet {
            updatePageContent()
        }
    }

    // MARK: - Form Validation Properties
    private var isNameValid = false
    private var isBirthDataValid = false
    private var isLocationValid = false

    private let totalPages = 3
    private var geocoder = CLGeocoder()
    private var stepImageWidthConstraint: NSLayoutConstraint?

    // MARK: - Placeholder Animation Properties
    private var placeholderTimer: Timer?
    private var currentPlaceholderIndex = 0
    private let locationPlaceholders = ["Start typing", "London, UK", "Paris, France", "Athens, Greece"]

    // MARK: - Formatters
    private let dateDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private let timeDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }()

    private var hasAppearedOnce = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
        updatePageContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAppearedOnce {
            hasAppearedOnce = true
            if currentPage == 1 {
                nameTextField.becomeFirstResponder()
            }
        }
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
        view.backgroundColor = CosmicFitTheme.Colours.cosmicGrey

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(CosmicFitTheme.Colours.cosmicBlue, for: .normal)
        backButton.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .bold)
        backButton.setImage(CosmicNavigationArrow.image(direction: .left, pointSize: 18), for: .normal)
        backButton.tintColor = CosmicFitTheme.Colours.cosmicBlue
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 6)
        backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.contentHorizontalAlignment = .leading
        backButton.isHidden = true
        contentView.addSubview(backButton)

        stepImageView.translatesAutoresizingMaskIntoConstraints = false
        stepImageView.contentMode = .scaleAspectFit
        contentView.addSubview(stepImageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 24, weight: .semibold)
        titleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 22, weight: .regular)
        descriptionLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)

        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.backgroundColor = .clear
        contentView.addSubview(inputContainerView)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .medium)
        actionButton.layer.cornerRadius = 6
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        contentView.addSubview(actionButton)

        pageIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        pageIndicatorLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 15, weight: .regular)
        pageIndicatorLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        pageIndicatorLabel.textAlignment = .center
        view.addSubview(pageIndicatorLabel)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = CosmicFitTheme.Colours.cosmicBlue
        view.addSubview(activityIndicator)

        setupInputViews()
        updateButtonState()
    }

    private func setupInputViews() {
        // Name field
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.attributedPlaceholder = makePlaceholder("First Name")
        nameTextField.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .regular)
        nameTextField.textColor = CosmicFitTheme.Colours.cosmicBlue
        nameTextField.borderStyle = .none
        nameTextField.returnKeyType = .next
        nameTextField.autocorrectionType = .no
        nameTextField.spellCheckingType = .no
        nameTextField.autocapitalizationType = .words
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(nameFieldChanged), for: .editingChanged)

        nameDivider.translatesAutoresizingMaskIntoConstraints = false
        nameDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue

        nameSparkleLabel.translatesAutoresizingMaskIntoConstraints = false
        nameSparkleLabel.text = "✦"
        nameSparkleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        nameSparkleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        nameSparkleLabel.textAlignment = .center

        // Date / time labels
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.text = "Date"
        dateLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .regular)
        dateLabel.textColor = CosmicFitTheme.Colours.cosmicBlue

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.text = "Time"
        timeLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .regular)
        timeLabel.textColor = CosmicFitTheme.Colours.cosmicBlue

        // Date / time fields styled like the design (placeholder text + underline)
        configureDateTimeFields()

        dateDivider.translatesAutoresizingMaskIntoConstraints = false
        dateDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        timeDivider.translatesAutoresizingMaskIntoConstraints = false
        timeDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue

        // Unknown time controls
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
        unknownTimeLabel.text = "I don’t know my time"
        unknownTimeLabel.font = CosmicFitTheme.Typography.dmSansFont(size: 16, weight: .regular)
        unknownTimeLabel.textColor = CosmicFitTheme.Colours.cosmicBlue

        // Location autocomplete (shares construction with profile edit but uses underline styling)
        locationAutocompleteView.translatesAutoresizingMaskIntoConstraints = false
        locationAutocompleteView.delegate = self
        locationAutocompleteView.applyOnboardingUnderlineStyling()
        locationAutocompleteView.setPlaceholder(locationPlaceholders[0])
    }

    private func configureDateTimeFields() {
        // Give the picker an explicit, sensible frame *before* it ever gets installed as an
        // inputView. Otherwise UIKit installs a 0x0 inputView, then resizes it on the next
        // run loop tick, which produces "UIInputViewSetPlacementInvisible" chatter in the
        // simulator console on iOS 18.
        datePicker.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 216)
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.setValue(CosmicFitTheme.Colours.cosmicBlue, forKey: "textColor")
        if let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) {
            datePicker.minimumDate = hundredYearsAgo
        }
        let calendar = Calendar.current
        var defaultDateComponents = DateComponents()
        defaultDateComponents.year = 1989
        defaultDateComponents.month = 4
        defaultDateComponents.day = 28
        if let defaultDate = calendar.date(from: defaultDateComponents) {
            datePicker.date = defaultDate
        }
        datePicker.addTarget(self, action: #selector(dateValueChanged), for: .valueChanged)

        timePicker.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 216)
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.setValue(CosmicFitTheme.Colours.cosmicBlue, forKey: "textColor")
        var defaultTimeComponents = DateComponents()
        defaultTimeComponents.hour = 12
        defaultTimeComponents.minute = 0
        if let defaultTime = calendar.date(from: defaultTimeComponents) {
            timePicker.date = defaultTime
        }
        timePicker.addTarget(self, action: #selector(timeValueChanged), for: .valueChanged)

        configurePickerField(dateField, placeholder: "dd/mm/yyyy", inputView: datePicker)
        configurePickerField(timeField, placeholder: "12:00am", inputView: timePicker)
    }

    /// Picker-driven fields don't use the system keyboard, so disable the text-input
    /// trait machinery (autocorrect, smart inserts, inline predictions, the input
    /// assistant bar). This silences a class of simulator console chatter such as
    /// `UIEmojiSearchOperations requires a valid sessionID` that fires when the
    /// system tries to install text-input services on a field that will only ever
    /// display a picker.
    private func configurePickerField(_ field: UITextField, placeholder: String, inputView: UIView) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.attributedPlaceholder = makePlaceholder(placeholder)
        field.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .regular)
        field.textColor = CosmicFitTheme.Colours.cosmicBlue
        field.borderStyle = .none
        field.tintColor = CosmicFitTheme.Colours.cosmicBlue
        field.delegate = self
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.smartInsertDeleteType = .no
        if #available(iOS 17.0, *) {
            field.inlinePredictionType = .no
        }
        field.inputAssistantItem.leadingBarButtonGroups = []
        field.inputAssistantItem.trailingBarButtonGroups = []
        field.inputView = inputView
        field.inputAccessoryView = makeKeyboardToolbar()
    }

    private func makePlaceholder(_ text: String) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.4),
                .font: CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .regular)
            ]
        )
    }

    private func makeKeyboardToolbar() -> UIToolbar {
        // Provide a non-zero initial width before adding items to avoid the system
        // attempting to lay out items inside a 0-width content view (which raises
        // an "Unable to simultaneously satisfy constraints" warning involving
        // _UIToolbarContentView.width == 0 vs the button's intrinsic 16pt margins).
        let initialWidth = UIScreen.main.bounds.width
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: initialWidth, height: 44))
        toolbar.autoresizingMask = .flexibleWidth
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(pickerDoneTapped))
        done.tintColor = CosmicFitTheme.Colours.cosmicBlue
        toolbar.setItems([flex, done], animated: false)
        return toolbar
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

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),

            stepImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 100),
            stepImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            stepImageView.heightAnchor.constraint(equalToConstant: 110),

            titleLabel.topAnchor.constraint(equalTo: stepImageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),

            inputContainerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            inputContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            inputContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            actionButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 40),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40),

            pageIndicatorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageIndicatorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

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
        case 1: isValid = isNameValid
        case 2: isValid = isBirthDataValid
        case 3: isValid = isLocationValid
        default: isValid = false
        }

        actionButton.isEnabled = isValid
        actionButton.alpha = isValid ? 1.0 : 0.55
    }

    // MARK: - Validation
    private func validateCurrentPage() {
        switch currentPage {
        case 1: checkNameValid()
        case 2: checkBirthValid()
        case 3: checkLocationValid()
        default: break
        }
        updateButtonState()
    }

    private func checkNameValid() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isNameValid = !name.isEmpty && name.count >= 2
    }

    private func checkBirthValid() {
        let dateOK = hasSelectedDate
        let timeOK = hasUnknownTime || hasSelectedTime
        isBirthDataValid = dateOK && timeOK
    }

    private func checkLocationValid() {
        let location = locationAutocompleteView.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        isLocationValid = !location.isEmpty && location.count >= 3 && latitude != 0.0 && longitude != 0.0
    }

    // MARK: - Field Change Handlers
    @objc private func nameFieldChanged() {
        checkNameValid()
        updateButtonState()
    }

    @objc private func dateValueChanged() {
        hasSelectedDate = true
        dateField.text = dateDisplayFormatter.string(from: datePicker.date)
        checkBirthValid()
        updateButtonState()
    }

    @objc private func timeValueChanged() {
        hasSelectedTime = true
        timeField.text = timeDisplayFormatter.string(from: timePicker.date)
        checkBirthValid()
        updateButtonState()
    }

    @objc private func pickerDoneTapped() {
        if dateField.isFirstResponder {
            if !hasSelectedDate {
                hasSelectedDate = true
                dateField.text = dateDisplayFormatter.string(from: datePicker.date)
            }
        } else if timeField.isFirstResponder {
            if !hasSelectedTime {
                hasSelectedTime = true
                timeField.text = timeDisplayFormatter.string(from: timePicker.date)
            }
        }
        view.endEditing(true)
        checkBirthValid()
        updateButtonState()
    }

    // MARK: - Page Content Updates
    private func updatePageContent() {
        inputContainerView.subviews.forEach { $0.removeFromSuperview() }
        backButton.isHidden = (currentPage == 1)
        pageIndicatorLabel.text = "Page \(currentPage) of \(totalPages)"

        let stepImage = UIImage(named: "onboarding-step-\(currentPage)")
        stepImageView.image = stepImage
        stepImageWidthConstraint?.isActive = false
        if let img = stepImage, img.size.height > 0 {
            let aspect = img.size.width / img.size.height
            stepImageWidthConstraint = stepImageView.widthAnchor.constraint(equalTo: stepImageView.heightAnchor, multiplier: aspect)
            stepImageWidthConstraint?.isActive = true
        }

        switch currentPage {
        case 1: setupNamePage()
        case 2: setupBirthPage()
        case 3: setupLocationPage()
        default: break
        }
    }

    private func setupNamePage() {
        titleLabel.text = "What’s your name?"
        descriptionLabel.text = "We’ll use this to personalise your profile."
        actionButton.setTitle("Next >", for: .normal)

        inputContainerView.addSubview(nameTextField)
        inputContainerView.addSubview(nameDivider)
        inputContainerView.addSubview(nameSparkleLabel)

        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            nameTextField.heightAnchor.constraint(equalToConstant: 36),

            nameDivider.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 6),
            nameDivider.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            nameDivider.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            nameDivider.heightAnchor.constraint(equalToConstant: 1),
            nameDivider.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),

            nameSparkleLabel.centerYAnchor.constraint(equalTo: nameDivider.centerYAnchor),
            nameSparkleLabel.trailingAnchor.constraint(equalTo: nameDivider.trailingAnchor)
        ])

        if hasAppearedOnce {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.nameTextField.becomeFirstResponder()
            }
        }

        validateCurrentPage()
    }

    private func setupBirthPage() {
        titleLabel.text = "When were you born?"
        descriptionLabel.text = ""
        actionButton.setTitle("Next >", for: .normal)

        inputContainerView.addSubview(dateLabel)
        inputContainerView.addSubview(dateField)
        inputContainerView.addSubview(dateDivider)
        inputContainerView.addSubview(timeLabel)
        inputContainerView.addSubview(timeField)
        inputContainerView.addSubview(timeDivider)
        inputContainerView.addSubview(unknownTimeCheckbox)
        inputContainerView.addSubview(unknownTimeLabel)

        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),

            dateField.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            dateField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            dateField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            dateField.heightAnchor.constraint(equalToConstant: 36),

            dateDivider.topAnchor.constraint(equalTo: dateField.bottomAnchor, constant: 4),
            dateDivider.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            dateDivider.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            dateDivider.heightAnchor.constraint(equalToConstant: 1),

            timeLabel.topAnchor.constraint(equalTo: dateDivider.bottomAnchor, constant: 28),
            timeLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),

            timeField.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            timeField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            timeField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            timeField.heightAnchor.constraint(equalToConstant: 36),

            timeDivider.topAnchor.constraint(equalTo: timeField.bottomAnchor, constant: 4),
            timeDivider.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            timeDivider.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            timeDivider.heightAnchor.constraint(equalToConstant: 1),

            unknownTimeCheckbox.topAnchor.constraint(equalTo: timeDivider.bottomAnchor, constant: 28),
            unknownTimeCheckbox.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            unknownTimeCheckbox.widthAnchor.constraint(equalToConstant: 26),
            unknownTimeCheckbox.heightAnchor.constraint(equalToConstant: 26),
            unknownTimeCheckbox.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),

            unknownTimeLabel.centerYAnchor.constraint(equalTo: unknownTimeCheckbox.centerYAnchor),
            unknownTimeLabel.leadingAnchor.constraint(equalTo: unknownTimeCheckbox.trailingAnchor, constant: 12),
            unknownTimeLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor)
        ])

        // Reflect any data the user has already entered
        if hasSelectedDate {
            dateField.text = dateDisplayFormatter.string(from: datePicker.date)
        }
        if hasSelectedTime {
            timeField.text = timeDisplayFormatter.string(from: timePicker.date)
        }
        unknownTimeCheckbox.isSelected = hasUnknownTime
        updateTimeFieldState()

        validateCurrentPage()
    }

    private func setupLocationPage() {
        titleLabel.text = "And lastly, where were you born?"
        descriptionLabel.text = ""
        actionButton.setTitle("Done", for: .normal)

        inputContainerView.addSubview(locationAutocompleteView)

        NSLayoutConstraint.activate([
            locationAutocompleteView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 24),
            locationAutocompleteView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            locationAutocompleteView.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            locationAutocompleteView.heightAnchor.constraint(equalToConstant: 50),
            locationAutocompleteView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor)
        ])

        locationAutocompleteView.setupSuggestionsOverlay(in: contentView)

        currentPlaceholderIndex = 0
        locationAutocompleteView.setPlaceholder(locationPlaceholders[0])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startPlaceholderAnimation()
        }

        validateCurrentPage()
    }

    // MARK: - Placeholder Animation
    private func startPlaceholderAnimation() {
        stopPlaceholderAnimation()
        guard locationAutocompleteView.getText().isEmpty else { return }

        placeholderTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.cyclePlaceholder()
        }
    }

    private func stopPlaceholderAnimation() {
        placeholderTimer?.invalidate()
        placeholderTimer = nil
    }

    private func cyclePlaceholder() {
        guard locationAutocompleteView.getText().isEmpty else {
            stopPlaceholderAnimation()
            return
        }

        currentPlaceholderIndex = (currentPlaceholderIndex + 1) % locationPlaceholders.count

        UIView.transition(with: locationAutocompleteView.textField, duration: 0.4, options: .transitionCrossDissolve) {
            self.locationAutocompleteView.setPlaceholder(self.locationPlaceholders[self.currentPlaceholderIndex])
        }
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        if currentPage > 1 {
            fadeToPage(currentPage - 1)
        }
    }

    @objc private func actionButtonTapped() {
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
                showAlert(title: "Location Required", message: "Please select your birth location from the suggestions.")
            }
        default:
            break
        }
    }

    @objc private func unknownTimeToggled() {
        unknownTimeCheckbox.isSelected.toggle()
        hasUnknownTime = unknownTimeCheckbox.isSelected
        updateTimeFieldState()
        checkBirthValid()
        updateButtonState()
    }

    private func updateTimeFieldState() {
        timeField.isEnabled = !hasUnknownTime
        timeField.alpha = hasUnknownTime ? 0.4 : 1.0
        timeLabel.alpha = hasUnknownTime ? 0.4 : 1.0
        if hasUnknownTime, timeField.isFirstResponder {
            timeField.resignFirstResponder()
        }
    }

    // MARK: - Page Transitions
    private func fadeToPage(_ page: Int) {
        if currentPage == 3 {
            stopPlaceholderAnimation()
        }
        view.endEditing(true)

        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 0.0
        }) { _ in
            self.currentPage = page
            UIView.animate(withDuration: 0.2) {
                self.contentView.alpha = 1.0
            }
        }
    }

    // MARK: - Data Storage
    private func storeBirthData() {
        birthDate = datePicker.date
        birthTime = timePicker.date
    }

    // MARK: - Location Processing
    private func processLocationAndComplete() {
        saveProfileAndComplete()
    }

    private func saveProfileAndComplete() {
        let deviceCalendar = Calendar.current
        let dateComponents = deviceCalendar.dateComponents([.year, .month, .day], from: birthDate)
        let timeComponents = deviceCalendar.dateComponents([.hour, .minute], from: birthTime)

        var birthLocationCalendar = Calendar(identifier: .gregorian)
        birthLocationCalendar.timeZone = timeZone

        var combinedComponents = DateComponents()
        combinedComponents.calendar = birthLocationCalendar
        combinedComponents.timeZone = timeZone
        combinedComponents.era = 1
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = hasUnknownTime ? 12 : timeComponents.hour
        combinedComponents.minute = hasUnknownTime ? 0 : timeComponents.minute
        combinedComponents.second = 0

        guard let finalBirthDateTime = birthLocationCalendar.date(from: combinedComponents) else {
            showAlert(title: "Error", message: "Could not process birth date and time.")
            return
        }

        #if DEBUG
        verifyBirthDateCreation(
            date: finalBirthDateTime,
            timezone: timeZone,
            location: birthLocation,
            components: combinedComponents
        )
        #endif

        let profile = UserProfile(
            id: UUID().uuidString,
            firstName: firstName,
            birthDate: finalBirthDateTime,
            birthLocation: birthLocation,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            birthTimeIsUnknown: hasUnknownTime,
            createdAt: Date(),
            lastModified: Date()
        )

        if UserProfileStorage.shared.saveUserProfile(profile) {
            print("✅ Profile saved successfully")
            navigateToMainApp(with: profile)
        } else {
            showAlert(title: "Error", message: "Could not save your profile. Please try again.")
        }
    }

    private func navigateToMainApp(with profile: UserProfile) {
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

        tabBarController.selectedIndex = 0

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

// MARK: - LocationAutocompleteDelegate
extension OnboardingFormViewController: LocationAutocompleteDelegate {
    func locationAutocompleteDidSelectLocation(name: String, latitude: Double, longitude: Double, timeZone: TimeZone) {
        self.birthLocation = name
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone

        stopPlaceholderAnimation()

        isLocationValid = true
        updateButtonState()

        print("✅ Location selected: \(name)")
        print("📍 Coordinates: \(latitude), \(longitude)")
        print("🕐 Timezone: \(timeZone.identifier)")
    }

    func locationAutocompleteDidUpdateText(_ text: String) {
        if text.isEmpty {
            latitude = 0
            longitude = 0
            birthLocation = ""
        }
        checkLocationValid()
        updateButtonState()

        if !text.isEmpty {
            stopPlaceholderAnimation()
        } else if currentPage == 3 {
            startPlaceholderAnimation()
        }
    }
}

// MARK: - UITextFieldDelegate
extension OnboardingFormViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === dateField || textField === timeField {
            return false
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            if isNameValid {
                actionButtonTapped()
            }
        } else if textField === dateField || textField === timeField {
            pickerDoneTapped()
        }
        return true
    }
}
