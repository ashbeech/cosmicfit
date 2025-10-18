//
//  MainViewController.swift
//  Cosmic Fit
//
//  Original onboarding controller - now fallback only
//

/*

import UIKit
import CoreLocation

class MainViewController: UIViewController {
    
    // MARK: - Properties
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var locationName: String = ""
    private var timeZone: TimeZone = TimeZone.current
    private var geocoder = CLGeocoder()
    
    // MARK: - UI Properties
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let birthDatePicker = UIDatePicker()
    private let birthTimePicker = UIDatePicker()
    private let locationTextField = UITextField()
    private let calculateButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This is now a fallback controller - redirect to new intro
        redirectToNewIntro()
    }
    
    // MARK: - Redirect Method
    private func redirectToNewIntro() {
        // Navigate to the new animated intro
        let animatedWelcomeVC = AnimatedWelcomeIntroViewController()
        let navController = UINavigationController(rootViewController: animatedWelcomeVC)
        navController.navigationBar.isHidden = true
        navController.modalPresentationStyle = .fullScreen
        
        present(navController, animated: false)
    }
    
    // MARK: - Legacy Setup (for compatibility)
    private func setupUI() {
        applyCosmicFitTheme()
        view.backgroundColor = CosmicFitTheme.Colors.cosmicGrey
        
        // Title
        titleLabel.text = "Enter Your Birth Details"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleTitleLabel(titleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.title1, weight: .bold)
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "We'll use this information to create your personalized cosmic profile"
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleBodyLabel(subtitleLabel, fontSize: CosmicFitTheme.Typography.FontSizes.body)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)
        
        // Birth date picker
        birthDatePicker.translatesAutoresizingMaskIntoConstraints = false
        birthDatePicker.datePickerMode = .date
        birthDatePicker.preferredDatePickerStyle = .wheels
        birthDatePicker.maximumDate = Date()
        CosmicFitTheme.styleDatePicker(birthDatePicker)
        
        if let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: Date()) {
            birthDatePicker.minimumDate = hundredYearsAgo
        }
        view.addSubview(birthDatePicker)
        
        // Birth time picker
        birthTimePicker.translatesAutoresizingMaskIntoConstraints = false
        birthTimePicker.datePickerMode = .time
        birthTimePicker.preferredDatePickerStyle = .wheels
        CosmicFitTheme.styleDatePicker(birthTimePicker)
        view.addSubview(birthTimePicker)
        
        // Location text field
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.placeholder = "Enter birth location (city, country)"
        CosmicFitTheme.styleTextField(locationTextField)
        locationTextField.delegate = self
        view.addSubview(locationTextField)
        
        // Calculate button
        calculateButton.setTitle("Calculate Chart", for: .normal)
        calculateButton.translatesAutoresizingMaskIntoConstraints = false
        CosmicFitTheme.styleButton(calculateButton, style: .primary)
        calculateButton.addTarget(self, action: #selector(calculateButtonTapped), for: .touchUpInside)
        view.addSubview(calculateButton)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .black
        view.addSubview(activityIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            birthDatePicker.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            birthDatePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            birthDatePicker.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            birthDatePicker.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            birthTimePicker.topAnchor.constraint(equalTo: birthDatePicker.bottomAnchor, constant: 20),
            birthTimePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            birthTimePicker.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            birthTimePicker.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            locationTextField.topAnchor.constraint(equalTo: birthTimePicker.bottomAnchor, constant: 40),
            locationTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            locationTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            calculateButton.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 40),
            calculateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            calculateButton.widthAnchor.constraint(equalToConstant: 200),
            calculateButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func calculateButtonTapped() {
        // Legacy method - should not be reached in normal flow
        print("Legacy calculate button tapped - redirecting to new intro")
        redirectToNewIntro()
    }
}

// MARK: - UITextFieldDelegate
extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
*/
