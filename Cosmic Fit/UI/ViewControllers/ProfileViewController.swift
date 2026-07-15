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
    private let unknownTimeCheckbox = UIButton(type: .custom)
    private let unknownTimeLabel = UILabel()
    private var birthTimeIsUnknown: Bool = false
    
    private let locationAutocompleteView = LocationAutocompleteView()
    private let updateButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
    private let restorePurchasesButton = UIButton(type: .system)
    private let manageSubscriptionButton = UIButton(type: .system)

    // Legal links footer (Terms of Use · Privacy Policy)
    private let legalLinksStack: UIStackView = {
        let termsBtn = UIButton(type: .system)
        termsBtn.setTitle("Terms of Use", for: .normal)
        termsBtn.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .regular)
        termsBtn.setTitleColor(CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5), for: .normal)
        termsBtn.tag = 1

        let dot = UILabel()
        dot.text = " \u{00B7} "
        dot.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .regular)
        dot.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5)

        let privacyBtn = UIButton(type: .system)
        privacyBtn.setTitle("Privacy Policy", for: .normal)
        privacyBtn.titleLabel?.font = CosmicFitTheme.Typography.dmSansFont(size: 11, weight: .regular)
        privacyBtn.setTitleColor(CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.5), for: .normal)
        privacyBtn.tag = 2

        let stack = UIStackView(arrangedSubviews: [termsBtn, dot, privacyBtn])
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        stack.distribution = .equalCentering
        return stack
    }()

    // Promo code UI
    private let subscriptionStatusLabel = UILabel()
    private let promoCodeFieldContainer = UIView()
    private let promoCodeFieldRow = UIStackView()
    private let promoCodeField = UITextField()
    private let redeemButton = UIButton(type: .system)
    private let appliedPromoContainer = UIView()
    private let appliedPromoRow = UIStackView()
    private let appliedPromoCodeLabel = UILabel()
    private let removePromoButton = UIButton(type: .system)
    private let promoErrorLabel = UILabel()
    private var isRedeeming = false
    private var isRemovingPromo = false
    private var promoRedeemFeedbackTask: Task<Void, Never>?
    private var keyboardDismissTapGesture: UITapGestureRecognizer?
    var focusPromoCodeField = false

    private enum PromoRedeemButtonAppearance {
        case coupon
        case failure
    }

    private let engineVersionLabel = UILabel()

    #if DEBUG
    private let engineLabel = UILabel()
    private let engineField = UITextField()
    private let enginePicker = UIPickerView()
    private let engineFootnoteLabel = UILabel()
    private let forceRefreshButton = UIButton(type: .system)
    private var isDevForceRefreshInProgress = false
    #endif
    private let signOutButton = UIButton(type: .system)
    private let deleteProfileButton = UIButton(type: .system)
    private let deleteAccountButton = UIButton(type: .system)
    private let activityIndicator = CosmicFitLoaderView(fill: .dark)
    private let mainStack = UIStackView()
    private let topFormDivider = UIView()
    private let preferencesSectionDivider = UIView()
    private let preferencesSectionTitleLabel = UILabel()
    private let showMasculineFeminineLabel = UILabel()
    private let showMasculineFeminineSwitch = UISwitch()
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
        showMasculineFeminineSwitch.isOn = !UserProfileStorage.shared.showMasculineFeminineSliderInDailyFit()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAuthUI),
            name: .cosmicFitAuthStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateEntitlementUI),
            name: EntitlementManager.entitlementDidChange,
            object: nil
        )

        updateEntitlementUI()
        updateAuthUI()

        #if DEBUG
        if DailyFitEngineConfig.allowsDevEngineTools {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDevForceRefreshStateChanged(_:)),
                name: .devForceRefreshStateChanged,
                object: nil
            )
        }
        #endif
    }

    deinit {
        promoRedeemFeedbackTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure navigation bar is visible
        navigationController?.navigationBar.isHidden = false

        if let grant = CompAccessStorage.load(),
           grant.isValid,
           grant.isFirst50Code,
           grant.redemptionPosition == nil {
            Task {
                await PromoCodeService.shared.restoreCompAccessIfNeeded()
                await MainActor.run { updateEntitlementUI() }
            }
        }

        #if DEBUG
        if DailyFitEngineConfig.allowsDevEngineTools {
            syncDailyFitEnginePickerSelection()
        }
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure the view is always fully interactive when visible
        view.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true

        if focusPromoCodeField {
            focusPromoCodeField = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.promoCodeField.becomeFirstResponder()
            }
        }
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
        
        birthDateField.inputView = CosmicFitTheme.makePickerInputView(
            wrapping: birthDatePicker,
            width: UIScreen.main.bounds.width
        )
        birthTimeField.inputView = CosmicFitTheme.makePickerInputView(
            wrapping: birthTimePicker,
            width: UIScreen.main.bounds.width
        )
        
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
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        var checkboxConfig = UIButton.Configuration.plain()
        checkboxConfig.baseForegroundColor = CosmicFitTheme.Colours.cosmicBlue
        checkboxConfig.preferredSymbolConfigurationForImage = symbolConfig
        checkboxConfig.image = UIImage(systemName: "square")
        unknownTimeCheckbox.configuration = checkboxConfig
        unknownTimeCheckbox.configurationUpdateHandler = { button in
            button.configuration?.image = UIImage(
                systemName: button.isSelected ? "checkmark.square" : "square"
            )
        }
        unknownTimeCheckbox.addTarget(self, action: #selector(unknownTimeToggled), for: .touchUpInside)
        
        unknownTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        unknownTimeLabel.text = "I don't know my time"
        unknownTimeLabel.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.callout, weight: .regular)
        unknownTimeLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
    }
    
    @objc private func unknownTimeToggled() {
        unknownTimeCheckbox.isSelected.toggle()
        birthTimeIsUnknown = unknownTimeCheckbox.isSelected
        updateBirthTimeFieldState()
    }

    @objc private func showMasculineFeminineSwitchChanged() {
        UserProfileStorage.shared.setShowMasculineFeminineSliderInDailyFit(!showMasculineFeminineSwitch.isOn)
    }
    
    private func updateBirthTimeFieldState() {
        birthTimeField.isEnabled = !birthTimeIsUnknown
        birthTimeField.alpha = birthTimeIsUnknown ? 0.4 : 1.0
        timeLabel.alpha = birthTimeIsUnknown ? 0.4 : 1.0

        // NOTE: This is a UX test to stop users from thinking they need to tick this box once they've interacted with the time field. Some users may automatically think they need to tick it like a terms tick box if it is left not-greyed-out.
        // Once a time is entered, visually de-emphasise the unknown-time option so it
        // doesn't look required — but keep it tappable in case the user changes their mind.
        // let unknownTimeSubdued = !birthTimeIsUnknown
        // let unknownTimeAlpha: CGFloat = unknownTimeSubdued ? 0.4 : 1.0
        // unknownTimeCheckbox.alpha = unknownTimeAlpha
        // unknownTimeLabel.alpha = unknownTimeAlpha
        unknownTimeCheckbox.alpha = 1.0
        unknownTimeLabel.alpha = 1.0

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
        
        configureEngineVersionLabel()

        #if DEBUG
        if DailyFitEngineConfig.allowsDevEngineTools {
            configureDailyFitEnginePickerControls()
            forceRefreshButton.setTitle("⟳ Force refresh all data", for: .normal)
            forceRefreshButton.addTarget(self, action: #selector(forceRefreshTapped), for: .touchUpInside)
            forceRefreshButton.translatesAutoresizingMaskIntoConstraints = false
            CosmicFitTheme.styleButton(forceRefreshButton, style: .secondary)
            forceRefreshButton.layer.borderColor = CosmicFitTheme.Colours.cosmicLilac.cgColor
            forceRefreshButton.layer.borderWidth = 1.5
            forceRefreshButton.setTitleColor(CosmicFitTheme.Colours.cosmicLilac, for: .normal)
            forceRefreshButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        #endif
        
        signInButton.setTitle("Sign in to sync your data", for: .normal)
        signInButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(signInButton, style: .secondary)
        signInButton.isHidden = CosmicFitAuthService.shared.isAuthenticated
        signInButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        restorePurchasesButton.setTitle("Restore Purchases", for: .normal)
        restorePurchasesButton.addTarget(self, action: #selector(restorePurchasesTapped), for: .touchUpInside)
        restorePurchasesButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(restorePurchasesButton, style: .secondary)
        restorePurchasesButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        manageSubscriptionButton.setTitle("Manage Subscription", for: .normal)
        manageSubscriptionButton.addTarget(self, action: #selector(manageSubscriptionTapped), for: .touchUpInside)
        manageSubscriptionButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(manageSubscriptionButton, style: .secondary)
        manageSubscriptionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        legalLinksStack.translatesAutoresizingMaskIntoConstraints = false
        for case let btn as UIButton in legalLinksStack.arrangedSubviews {
            btn.addTarget(self, action: #selector(legalLinkTapped(_:)), for: .touchUpInside)
        }

        // Subscription status
        subscriptionStatusLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote, weight: .medium
        )
        subscriptionStatusLabel.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.72)
        subscriptionStatusLabel.textAlignment = .center
        subscriptionStatusLabel.numberOfLines = 0
        subscriptionStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Promo code — inline field + coupon redeem button
        configurePromoCodeInlineRow()
        configureAppliedPromoRow()

        promoErrorLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote, weight: .medium
        )
        promoErrorLabel.textColor = .systemRed
        promoErrorLabel.textAlignment = .center
        promoErrorLabel.numberOfLines = 0
        promoErrorLabel.isHidden = true
        promoErrorLabel.translatesAutoresizingMaskIntoConstraints = false

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

        deleteAccountButton.setTitle("Delete account", for: .normal)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)
        deleteAccountButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(deleteAccountButton, style: .secondary)
        deleteAccountButton.backgroundColor = .systemRed
        deleteAccountButton.setTitleColor(.white, for: .normal)
        deleteAccountButton.layer.borderWidth = 0
        deleteAccountButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        deleteAccountButton.isHidden = true
        
        dangerSectionDivider.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleDivider(dangerSectionDivider)
        dangerSectionDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
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

        if DailyFitEngineConfig.isProductionBuildMode {
            mainStack.addArrangedSubview(engineVersionLabel)
            mainStack.setCustomSpacing(12, after: engineVersionLabel)
        } else {
            mainStack.setCustomSpacing(28, after: mainStack.arrangedSubviews.last!)
        }

        preferencesSectionDivider.translatesAutoresizingMaskIntoConstraints = false
        preferencesSectionDivider.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        preferencesSectionDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        mainStack.addArrangedSubview(preferencesSectionDivider)
        mainStack.setCustomSpacing(20, after: preferencesSectionDivider)
        
        preferencesSectionTitleLabel.text = "Your Preferences"
        preferencesSectionTitleLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.callout,
            weight: .semibold
        )
        preferencesSectionTitleLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        preferencesSectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(preferencesSectionTitleLabel)
        mainStack.setCustomSpacing(16, after: preferencesSectionTitleLabel)
        
        showMasculineFeminineLabel.text = "Hide masculine/feminine"
        showMasculineFeminineLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.callout,
            weight: .regular
        )
        showMasculineFeminineLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        showMasculineFeminineLabel.numberOfLines = 0
        showMasculineFeminineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        CosmicFitTheme.styleSwitch(showMasculineFeminineSwitch)
        showMasculineFeminineSwitch.translatesAutoresizingMaskIntoConstraints = false
        showMasculineFeminineSwitch.addTarget(
            self,
            action: #selector(showMasculineFeminineSwitchChanged),
            for: .valueChanged
        )
        
        let masculineFemininePreferenceRow = UIStackView(arrangedSubviews: [
            showMasculineFeminineLabel,
            showMasculineFeminineSwitch
        ])
        masculineFemininePreferenceRow.axis = .horizontal
        masculineFemininePreferenceRow.spacing = 12
        masculineFemininePreferenceRow.alignment = .center
        showMasculineFeminineSwitch.setContentHuggingPriority(.required, for: .horizontal)
        showMasculineFeminineSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        mainStack.addArrangedSubview(masculineFemininePreferenceRow)
        
        mainStack.setCustomSpacing(28, after: masculineFemininePreferenceRow)
        
        mainStack.addArrangedSubview(updateButton)
        mainStack.setCustomSpacing(34, after: updateButton)
        mainStack.addArrangedSubview(dangerSectionDivider)
        mainStack.setCustomSpacing(22, after: dangerSectionDivider)
        mainStack.addArrangedSubview(signInButton)
        mainStack.addArrangedSubview(promoCodeFieldContainer)
        mainStack.addArrangedSubview(appliedPromoContainer)
        mainStack.setCustomSpacing(8, after: appliedPromoContainer)
        mainStack.addArrangedSubview(subscriptionStatusLabel)
        mainStack.setCustomSpacing(8, after: subscriptionStatusLabel)
        mainStack.addArrangedSubview(promoErrorLabel)
        mainStack.setCustomSpacing(20, after: promoErrorLabel)
        mainStack.addArrangedSubview(restorePurchasesButton)
        mainStack.addArrangedSubview(manageSubscriptionButton)

        #if DEBUG
        if DailyFitEngineConfig.allowsDevEngineTools {
            mainStack.addArrangedSubview(verticalFieldStack(label: engineLabel, field: engineField))
            mainStack.addArrangedSubview(engineFootnoteLabel)
            mainStack.setCustomSpacing(8, after: engineFootnoteLabel)
            mainStack.addArrangedSubview(forceRefreshButton)
        }
        #endif
        mainStack.addArrangedSubview(signOutButton)
        mainStack.addArrangedSubview(deleteAccountButton)
        mainStack.addArrangedSubview(deleteProfileButton)

        mainStack.setCustomSpacing(28, after: deleteProfileButton)
        mainStack.addArrangedSubview(legalLinksStack)
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
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -CosmicFitTheme.Layout.scrollContentBottomInset),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 52),
            activityIndicator.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    private func setupKeyboardDismissal() {
        // Add tap gesture to dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        keyboardDismissTapGesture = tapGesture
        
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
    
    private func configureEngineVersionLabel() {
        engineVersionLabel.translatesAutoresizingMaskIntoConstraints = false
        engineVersionLabel.numberOfLines = 1
        engineVersionLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote,
            weight: .regular
        )
        engineVersionLabel.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.45)
        engineVersionLabel.text = DailyFitEngineRegistry.productionVersionDisplayText
    }

    #if DEBUG
    private func configureDailyFitEnginePickerControls() {
        styleFieldCaption(engineLabel, text: "Daily Fit engine (debug)")

        engineField.translatesAutoresizingMaskIntoConstraints = false
        engineField.placeholder = "Select engine preset"
        CosmicFitTheme.styleTextField(engineField)
        engineField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        engineField.delegate = self
        engineField.autocorrectionType = .no
        engineField.spellCheckingType = .no
        engineField.textContentType = .none

        enginePicker.dataSource = self
        enginePicker.delegate = self
        engineField.inputView = CosmicFitTheme.makePickerInputView(
            wrapping: enginePicker,
            width: UIScreen.main.bounds.width
        )

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(enginePickerDoneTapped))
        toolbar.setItems([flex, done], animated: false)
        engineField.inputAccessoryView = toolbar

        engineFootnoteLabel.translatesAutoresizingMaskIntoConstraints = false
        engineFootnoteLabel.numberOfLines = 0
        engineFootnoteLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.footnote,
            weight: .regular
        )
        engineFootnoteLabel.textColor = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.72)
        engineFootnoteLabel.text = """
        Applies to this install (not per profile). Release builds always use Sky Forward production.
        """

        syncDailyFitEnginePickerSelection()
    }

    private func syncDailyFitEnginePickerSelection() {
        let descriptors = DailyFitEngineRegistry.allDescriptors
        let effectiveId = DailyFitEngineConfig.effectiveEngineId
        let row = descriptors.firstIndex(where: { $0.id == effectiveId }) ?? 0
        enginePicker.selectRow(row, inComponent: 0, animated: false)
        engineField.text = descriptors[row].displayName
    }

    @objc private func enginePickerDoneTapped() {
        applyDailyFitEngineSelectionFromPicker()
        engineField.resignFirstResponder()
    }

    private func applyDailyFitEngineSelectionFromPicker() {
        let descriptors = DailyFitEngineRegistry.allDescriptors
        let row = enginePicker.selectedRow(inComponent: 0)
        guard descriptors.indices.contains(row) else { return }

        let selected = descriptors[row]
        let previousId = DailyFitEngineConfig.effectiveEngineId

        if selected.id == DailyFitEngineConfig.buildTimeEngineId {
            DailyFitEngineConfig.runtimeOverrideEngineId = nil
        } else {
            DailyFitEngineConfig.runtimeOverrideEngineId = selected.id
        }

        syncDailyFitEnginePickerSelection()

        guard DailyFitEngineConfig.effectiveEngineId != previousId else { return }
        NotificationCenter.default.post(name: .dailyFitEngineOverrideChanged, object: nil)
    }

    @objc private func forceRefreshTapped() {
        guard !isDevForceRefreshInProgress else { return }
        isDevForceRefreshInProgress = true
        forceRefreshButton.isEnabled = false
        forceRefreshButton.setTitle("Refreshing…", for: .normal)

        BlueprintStorage.shared.delete()

        NotificationCenter.default.post(name: .devForceRefreshRequested, object: nil)
    }

    @objc private func handleDevForceRefreshStateChanged(_ notification: Notification) {
        guard let isRefreshing = notification.userInfo?["isRefreshing"] as? Bool else { return }
        isDevForceRefreshInProgress = isRefreshing
        if isRefreshing {
            forceRefreshButton.isEnabled = false
            forceRefreshButton.setTitle("Refreshing…", for: .normal)
        } else {
            forceRefreshButton.setTitle("⟳ Force refresh all data", for: .normal)
            forceRefreshButton.isEnabled = true
            view.isUserInteractionEnabled = true
            scrollView.isUserInteractionEnabled = true
        }
    }
    #endif

    @objc private func signInButtonTapped() {
        let authGateVC = AuthGateViewController()
        let nav = UINavigationController(rootViewController: authGateVC)
        nav.navigationBar.isHidden = true
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func restorePurchasesTapped() {
        restorePurchasesButton.isEnabled = false
        restorePurchasesButton.setTitle("Restoring...", for: .normal)

        Task {
            do {
                try await StoreKitManager.shared.restorePurchases()
                if EntitlementManager.shared.hasStoreKitSubscription {
                    showAlert(title: "Restored", message: "Your subscription has been restored.")
                } else if EntitlementManager.shared.hasCompAccess {
                    showAlert(title: "No Subscription Found", message: "No App Store subscription found. Your comp access is active.")
                } else {
                    showAlert(title: "No Subscription Found", message: "No active subscription found for this Apple ID.")
                }
            } catch {
                showAlert(title: "Restore Failed", message: error.localizedDescription)
            }
            restorePurchasesButton.isEnabled = true
            restorePurchasesButton.setTitle("Restore Purchases", for: .normal)
        }
    }

    @objc private func manageSubscriptionTapped() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func legalLinkTapped(_ sender: UIButton) {
        guard let genericDetail = parent as? GenericDetailViewController else { return }
        if sender.tag == 1 {
            genericDetail.pushContentViewController(TermsOfUseViewController())
        } else {
            genericDetail.pushContentViewController(PrivacyPolicyViewController())
        }
    }

    @objc private func updateEntitlementUI() {
        let em = EntitlementManager.shared
        let compGrant = CompAccessStorage.load()

        if em.hasStoreKitSubscription {
            subscriptionStatusLabel.text = "Subscribed"
            subscriptionStatusLabel.isHidden = false
            manageSubscriptionButton.isHidden = false
        } else if em.hasCompAccess, let grant = compGrant, grant.isValid {
            subscriptionStatusLabel.text = compAccessStatusMessage(for: grant)
            subscriptionStatusLabel.isHidden = false
            manageSubscriptionButton.isHidden = true
        } else if !DailyFitEngineConfig.isProductionBuildMode {
            if em.hasFullAccess {
                subscriptionStatusLabel.text = "Access: Debug unlock"
            } else {
                subscriptionStatusLabel.text = "Access: Free"
            }
            subscriptionStatusLabel.isHidden = false
            manageSubscriptionButton.isHidden = true
        } else {
            subscriptionStatusLabel.isHidden = true
            manageSubscriptionButton.isHidden = true
        }

        if em.hasStoreKitSubscription {
            promoCodeFieldContainer.isHidden = true
            appliedPromoContainer.isHidden = true
            promoErrorLabel.isHidden = true
        } else if em.hasCompAccess, let code = em.appliedCompCode {
            appliedPromoCodeLabel.text = code
            appliedPromoContainer.isHidden = false
            promoCodeFieldContainer.isHidden = true
        } else {
            appliedPromoContainer.isHidden = true
            promoCodeFieldContainer.isHidden = false
        }
    }

    private func compAccessStatusMessage(for grant: CompAccessGrant) -> String {
        if grant.isFirst50Code, let position = grant.redemptionPosition {
            return "You're \(position) of the first 50"
        }
        return "Comp access (\(grant.code))"
    }

    private func configureAppliedPromoRow() {
        appliedPromoContainer.translatesAutoresizingMaskIntoConstraints = false
        appliedPromoContainer.backgroundColor = CosmicFitTheme.Colours.transparentBackground
        appliedPromoContainer.layer.borderColor = CosmicFitTheme.Colours.borderColor.cgColor
        appliedPromoContainer.layer.borderWidth = 1.0
        appliedPromoContainer.layer.cornerRadius = 8
        appliedPromoContainer.clipsToBounds = true
        appliedPromoContainer.isHidden = true
        appliedPromoContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        appliedPromoRow.translatesAutoresizingMaskIntoConstraints = false
        appliedPromoRow.axis = .horizontal
        appliedPromoRow.alignment = .center
        appliedPromoRow.spacing = 8
        appliedPromoRow.isLayoutMarginsRelativeArrangement = true
        appliedPromoRow.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)

        appliedPromoCodeLabel.font = CosmicFitTheme.Typography.dmSansFont(
            size: CosmicFitTheme.Typography.FontSizes.body,
            weight: .medium
        )
        appliedPromoCodeLabel.textColor = CosmicFitTheme.Colours.cosmicBlue
        appliedPromoCodeLabel.translatesAutoresizingMaskIntoConstraints = false

        removePromoButton.translatesAutoresizingMaskIntoConstraints = false
        let removeConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        removePromoButton.setImage(
            UIImage(systemName: "xmark", withConfiguration: removeConfig),
            for: .normal
        )
        removePromoButton.tintColor = CosmicFitTheme.Colours.cosmicBlue
        removePromoButton.accessibilityLabel = "Remove promo code"
        removePromoButton.addTarget(self, action: #selector(removePromoTapped), for: .touchUpInside)

        appliedPromoContainer.addSubview(appliedPromoRow)
        appliedPromoRow.addArrangedSubview(appliedPromoCodeLabel)
        appliedPromoRow.addArrangedSubview(removePromoButton)

        NSLayoutConstraint.activate([
            appliedPromoRow.topAnchor.constraint(equalTo: appliedPromoContainer.topAnchor),
            appliedPromoRow.leadingAnchor.constraint(equalTo: appliedPromoContainer.leadingAnchor),
            appliedPromoRow.trailingAnchor.constraint(equalTo: appliedPromoContainer.trailingAnchor),
            appliedPromoRow.bottomAnchor.constraint(equalTo: appliedPromoContainer.bottomAnchor),

            removePromoButton.widthAnchor.constraint(equalToConstant: 36),
            removePromoButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    @objc private func removePromoTapped() {
        guard !isRemovingPromo else { return }

        isRemovingPromo = true
        promoErrorLabel.isHidden = true
        removePromoButton.isEnabled = false
        appliedPromoContainer.alpha = 0.45

        Task {
            do {
                try await PromoCodeService.shared.revokeCompAccess()
                await MainActor.run {
                    updateEntitlementUI()
                }
            } catch {
                await MainActor.run {
                    promoErrorLabel.text = error.localizedDescription
                    promoErrorLabel.isHidden = false
                }
            }
            await MainActor.run {
                isRemovingPromo = false
                removePromoButton.isEnabled = true
                appliedPromoContainer.alpha = 1.0
            }
        }
    }

    private func configurePromoCodeInlineRow() {
        promoCodeFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        promoCodeFieldContainer.backgroundColor = CosmicFitTheme.Colours.transparentBackground
        promoCodeFieldContainer.layer.borderColor = CosmicFitTheme.Colours.borderColor.cgColor
        promoCodeFieldContainer.layer.borderWidth = 1.0
        promoCodeFieldContainer.layer.cornerRadius = 8
        promoCodeFieldContainer.clipsToBounds = true
        promoCodeFieldContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        promoCodeFieldRow.translatesAutoresizingMaskIntoConstraints = false
        promoCodeFieldRow.axis = .horizontal
        promoCodeFieldRow.alignment = .fill
        promoCodeFieldRow.spacing = 0

        promoCodeField.placeholder = "Enter promo code"
        promoCodeField.autocapitalizationType = .allCharacters
        promoCodeField.autocorrectionType = .no
        promoCodeField.spellCheckingType = .no
        promoCodeField.textContentType = .none
        promoCodeField.returnKeyType = .go
        promoCodeField.delegate = self
        promoCodeField.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleTextField(promoCodeField)
        promoCodeField.layer.borderWidth = 0
        promoCodeField.backgroundColor = .clear
        promoCodeField.rightView = nil
        promoCodeField.rightViewMode = .never

        redeemButton.translatesAutoresizingMaskIntoConstraints = false
        // .touchDown ensures redeem fires when the keyboard is up; the first tap can
        // otherwise only resign first responder without delivering .touchUpInside.
        redeemButton.addTarget(self, action: #selector(redeemButtonTapped), for: [.touchUpInside, .touchDown])
        redeemButton.accessibilityLabel = "Redeem promo code"
        CosmicFitTheme.styleButton(redeemButton, style: .onboardingAction)
        redeemButton.setTitle(nil, for: .normal)
        applyPromoRedeemButtonAppearance(.coupon)

        promoCodeFieldContainer.addSubview(promoCodeFieldRow)
        promoCodeFieldRow.addArrangedSubview(promoCodeField)
        promoCodeFieldRow.addArrangedSubview(redeemButton)

        NSLayoutConstraint.activate([
            promoCodeFieldRow.topAnchor.constraint(equalTo: promoCodeFieldContainer.topAnchor),
            promoCodeFieldRow.leadingAnchor.constraint(equalTo: promoCodeFieldContainer.leadingAnchor),
            promoCodeFieldRow.trailingAnchor.constraint(equalTo: promoCodeFieldContainer.trailingAnchor),
            promoCodeFieldRow.bottomAnchor.constraint(equalTo: promoCodeFieldContainer.bottomAnchor),

            redeemButton.widthAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func applyPromoRedeemButtonAppearance(_ appearance: PromoRedeemButtonAppearance) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let symbolName: String
        let background: UIColor

        switch appearance {
        case .coupon:
            symbolName = "ticket.fill"
            background = CosmicFitTheme.Colours.cosmicBlue
        case .failure:
            symbolName = "xmark"
            background = .systemRed
        }

        redeemButton.backgroundColor = background
        redeemButton.setImage(
            UIImage(systemName: symbolName, withConfiguration: symbolConfig),
            for: .normal
        )
        redeemButton.tintColor = .white
    }

    private func setPromoCodeInputEnabled(_ enabled: Bool) {
        promoCodeField.isEnabled = enabled
        promoCodeField.alpha = enabled ? 1.0 : 0.45
        redeemButton.isEnabled = enabled
        redeemButton.alpha = enabled ? 1.0 : 0.85
    }

    private func flashPromoRedeemButtonSuccess() async {
        await withCheckedContinuation { continuation in
            CosmicFitTheme.flashFilledButtonConfirmed(redeemButton, style: .onboardingAction) {
                continuation.resume()
            }
        }
    }

    private func flashPromoRedeemButtonFailure() async {
        await MainActor.run {
            applyPromoRedeemButtonAppearance(.failure)
        }
        try? await Task.sleep(for: .seconds(1))
        await MainActor.run {
            applyPromoRedeemButtonAppearance(.coupon)
        }
    }

    @objc private func redeemButtonTapped() {
        let code = promoCodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty else { return }
        guard !isRedeeming else { return }

        promoRedeemFeedbackTask?.cancel()
        isRedeeming = true
        promoErrorLabel.isHidden = true
        setPromoCodeInputEnabled(false)
        promoCodeField.resignFirstResponder()

        promoRedeemFeedbackTask = Task {
            do {
                _ = try await PromoCodeService.shared.redeem(code: code)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isRedeeming = false
                    setPromoCodeInputEnabled(true)
                }
                await flashPromoRedeemButtonSuccess()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    promoCodeField.text = ""
                    showAlert(title: "Full Access Unlocked", message: "Your code has been applied successfully.")
                    updateEntitlementUI()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isRedeeming = false
                    setPromoCodeInputEnabled(true)
                    promoErrorLabel.text = error.localizedDescription
                    promoErrorLabel.isHidden = false
                }
                await flashPromoRedeemButtonFailure()
            }
        }
    }

    @objc private func signOutButtonTapped() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "You'll return to the home screen. Sign in again to access your account.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            guard let window = self?.view.window else { return }
            Task { try? await CosmicFitAuthService.shared.signOut() }
            let landingVC = SignedOutLandingViewController()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                window.rootViewController = landingVC
            }
        })
        present(alert, animated: true)
    }

    @objc private func updateAuthUI() {
        let isAuth = CosmicFitAuthService.shared.isAuthenticated
        signInButton.isHidden = isAuth
        signOutButton.isHidden = !isAuth
        deleteAccountButton.isHidden = !isAuth
        deleteProfileButton.isHidden = isAuth
    }
    
    @objc private func deleteAccountButtonTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This permanently deletes your cloud account and synced Style Guide data. Your on-device data will also be removed. This does not cancel an App Store subscription. Are you sure?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.deleteAccount()
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
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteProfile()
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
        NotificationCenter.default.post(name: .userProfileDeleted, object: nil)
        navigateToOnboarding()
    }

    private func deleteAccount() {
        activityIndicator.startAnimating()
        deleteAccountButton.isEnabled = false
        deleteProfileButton.isEnabled = false

        Task {
            do {
                try await CosmicFitAuthService.shared.deleteAccount()
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    NotificationCenter.default.post(name: .userProfileDeleted, object: nil)
                    self.navigateToOnboarding()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    deleteAccountButton.isEnabled = true
                    deleteProfileButton.isEnabled = true
                    showAlert(
                        title: "Could Not Delete Account",
                        message: "We couldn't delete your account right now. Please try again or email help@cosmicfit.app."
                    )
                }
            }
        }
    }

    private func navigateToOnboarding() {
        let onboardingFormVC = OnboardingFormViewController()
        let navController = UINavigationController(rootViewController: onboardingFormVC)
        navController.navigationBar.isHidden = true

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
        updateButton.isEnabled = false
        CosmicFitTheme.flashFilledButtonConfirmed(updateButton, style: .primary) { [weak self] in
            self?.requestDismissal()
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

// MARK: - UIGestureRecognizerDelegate
extension ProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === keyboardDismissTapGesture else { return true }

        var candidate: UIView? = touch.view
        while let view = candidate {
            if view is UIControl {
                return false
            }
            candidate = view.superview
        }
        return true
    }
}

// MARK: - UITextFieldDelegate
extension ProfileViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === birthDateField || textField === birthTimeField {
            return false
        }
        #if DEBUG
        if textField === engineField {
            return false
        }
        #endif
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        #if DEBUG
        if textField === engineField {
            enginePickerDoneTapped()
            return true
        }
        #endif
        if textField === promoCodeField {
            redeemButtonTapped()
            return true
        }
        if textField === nameTextField {
            textField.resignFirstResponder()
        } else if textField === birthDateField || textField === birthTimeField {
            birthDateTimePickerDoneTapped()
        }
        return true
    }
}

#if DEBUG
// MARK: - Daily Fit engine picker (P5)
extension ProfileViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        DailyFitEngineRegistry.allDescriptors.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        DailyFitEngineRegistry.allDescriptors[row].displayName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let descriptors = DailyFitEngineRegistry.allDescriptors
        guard descriptors.indices.contains(row) else { return }
        engineField.text = descriptors[row].displayName
    }
}
#endif
