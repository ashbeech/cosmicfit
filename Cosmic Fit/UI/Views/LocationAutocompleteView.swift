//
//  LocationAutocompleteView.swift
//  Cosmic Fit
//
//  Inline location autocomplete with dropdown suggestions
//

import UIKit
import MapKit
import CoreLocation

/// Delegate protocol for location selection
protocol LocationAutocompleteDelegate: AnyObject {
    func locationAutocompleteDidSelectLocation(name: String, latitude: Double, longitude: Double, timeZone: TimeZone)
    func locationAutocompleteDidUpdateText(_ text: String)
}

class LocationAutocompleteView: UIView {
    
    // MARK: - Properties
    weak var delegate: LocationAutocompleteDelegate?
    weak var parentView: UIView? // Need reference to parent for dropdown overlay
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private let geocoder = CLGeocoder()
    private var isUpdatingProgrammatically = false // Prevent search trigger on programmatic updates
    
    /// Single bordered container so the field matches `CosmicFitTheme` inputs (no extra underline inside the box).
    private let fieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = CosmicFitTheme.Colours.borderColor.cgColor
        return view
    }()

    /// Optional underline shown beneath the field when the onboarding underline styling is applied.
    private let underlineView = UIView()
    
    // MARK: - UI Elements
    let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.returnKeyType = .done
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.clearButtonMode = .never
        return field
    }()
    
    private lazy var clearTextButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .light)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = CosmicFitTheme.Colours.cosmicBlue
        button.accessibilityLabel = "Clear location"
        button.addTarget(self, action: #selector(clearTextTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private let accessoryStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        return stack
    }()
    
    private let suggestionsTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .white
        table.layer.cornerRadius = 8
        table.layer.shadowColor = UIColor.black.cgColor
        table.layer.shadowOffset = CGSize(width: 0, height: 2)
        table.layer.shadowRadius = 4
        table.layer.shadowOpacity = 0.1
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.isHidden = true
        table.isUserInteractionEnabled = true // Ensure it can receive touches
        return table
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.45)
        return indicator
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint!
    private var overlayTopConstraint: NSLayoutConstraint?
    private var overlayLeadingConstraint: NSLayoutConstraint?
    private var overlayWidthConstraint: NSLayoutConstraint?
    private let maxVisibleResults = 3
    private let rowHeight: CGFloat = 60
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupSearchCompleter()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(fieldContainer)
        fieldContainer.addSubview(textField)
        fieldContainer.addSubview(accessoryStack)
        accessoryStack.addArrangedSubview(activityIndicator)
        accessoryStack.addArrangedSubview(clearTextButton)
        // Note: suggestionsTableView will be added to parent view as overlay
        
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(LocationSuggestionCell.self, 
                                     forCellReuseIdentifier: LocationSuggestionCell.identifier)
        suggestionsTableView.rowHeight = rowHeight
    }
    
    private func setupConstraints() {
        tableViewHeightConstraint = suggestionsTableView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            fieldContainer.topAnchor.constraint(equalTo: topAnchor),
            fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            fieldContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            fieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            textField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            textField.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            textField.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),
            textField.trailingAnchor.constraint(equalTo: accessoryStack.leadingAnchor),
            
            accessoryStack.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            accessoryStack.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            
            clearTextButton.widthAnchor.constraint(equalToConstant: 36),
            clearTextButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Suggestions table constraints will be set up when attached to parent
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        // Use resultTypes to filter for addresses and points of interest
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    // MARK: - Public Methods
    
    /// Must be called to set up the suggestions overlay in the parent view
    func setupSuggestionsOverlay(in parentView: UIView) {
        self.parentView = parentView
        if suggestionsTableView.superview !== parentView {
            suggestionsTableView.removeFromSuperview()
            parentView.addSubview(suggestionsTableView)
        }
        
        if let overlayTopConstraint,
           let overlayLeadingConstraint,
           let overlayWidthConstraint {
            NSLayoutConstraint.deactivate([overlayTopConstraint, overlayLeadingConstraint, overlayWidthConstraint])
        }
        
        let topConstraint = suggestionsTableView.topAnchor.constraint(equalTo: parentView.topAnchor)
        let leadingConstraint = suggestionsTableView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor)
        let widthConstraint = suggestionsTableView.widthAnchor.constraint(equalToConstant: 0)
        
        overlayTopConstraint = topConstraint
        overlayLeadingConstraint = leadingConstraint
        overlayWidthConstraint = widthConstraint
        
        var constraintsToActivate = [topConstraint, leadingConstraint, widthConstraint]
        if !tableViewHeightConstraint.isActive {
            constraintsToActivate.append(tableViewHeightConstraint)
        }
        NSLayoutConstraint.activate(constraintsToActivate)
        updateSuggestionsOverlayFrameConstraints()
    }
    
    func setPlaceholder(_ placeholder: String, animated: Bool = false) {
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: CosmicFitTheme.Colours.cosmicBlue.withAlphaComponent(0.6),
            .font: CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attrs)
        _ = animated // retained for call-site compatibility (onboarding placeholder animation)
    }
    
    /// Call from screens that use Cosmic Fit form styling (replaces applying `styleTextField` to `textField`, which double-borders this view).
    func applyCosmicFieldStyling() {
        textField.font = CosmicFitTheme.Typography.dmSansFont(size: CosmicFitTheme.Typography.FontSizes.body)
        textField.textColor = CosmicFitTheme.Colours.cosmicBlue
        textField.layer.borderWidth = 0
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        textField.leftView = padding
        textField.leftViewMode = .always
        textField.rightView = nil
        textField.rightViewMode = .never
        fieldContainer.layer.borderColor = CosmicFitTheme.Colours.borderColor.cgColor
        fieldContainer.layer.borderWidth = 1
    }

    /// Style the field for the multi-step onboarding flow: no bordered box, just an underline beneath
    /// the input. Keeps the autocomplete dropdown and the trailing 'x' clear button shared with the
    /// profile edit screen.
    func applyOnboardingUnderlineStyling() {
        textField.font = CosmicFitTheme.Typography.dmSansFont(size: 18, weight: .regular)
        textField.textColor = CosmicFitTheme.Colours.cosmicBlue
        textField.layer.borderWidth = 0
        textField.leftView = nil
        textField.leftViewMode = .never
        textField.rightView = nil
        textField.rightViewMode = .never
        fieldContainer.layer.borderWidth = 0
        fieldContainer.layer.cornerRadius = 0
        fieldContainer.backgroundColor = .clear
        showUnderlineDecoration()
    }

    private func showUnderlineDecoration() {
        underlineView.removeFromSuperview()
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        underlineView.backgroundColor = CosmicFitTheme.Colours.cosmicBlue
        addSubview(underlineView)
        NSLayoutConstraint.activate([
            underlineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            underlineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setText(_ text: String) {
        isUpdatingProgrammatically = true
        textField.text = text
        isUpdatingProgrammatically = false
        updateClearButtonVisibility()
    }
    
    func getText() -> String {
        return textField.text ?? ""
    }
    
    // MARK: - Private Methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSuggestionsOverlayFrameConstraints()
    }
    
    private func updateSuggestionsOverlayFrameConstraints() {
        guard let parentView else { return }
        guard suggestionsTableView.superview === parentView else { return }
        
        let frameInParent = convert(bounds, to: parentView)
        overlayTopConstraint?.constant = frameInParent.maxY + 8
        overlayLeadingConstraint?.constant = frameInParent.minX
        overlayWidthConstraint?.constant = frameInParent.width
    }
    
    @objc private func clearTextTapped() {
        textField.text = ""
        updateClearButtonVisibility()
        searchResults.removeAll()
        suggestionsTableView.reloadData()
        hideSuggestions()
        searchCompleter.queryFragment = ""
        textFieldDidChange()
    }
    
    private func updateClearButtonVisibility() {
        let hasText = !(textField.text?.isEmpty ?? true)
        clearTextButton.isHidden = !hasText
    }
    
    @objc private func textFieldDidChange() {
        updateClearButtonVisibility()
        // Skip if we're updating programmatically after selection
        guard !isUpdatingProgrammatically else { return }
        
        let searchText = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        delegate?.locationAutocompleteDidUpdateText(searchText)
        
        if searchText.isEmpty {
            hideSuggestions()
            searchResults.removeAll()
            suggestionsTableView.reloadData()
        } else {
            searchCompleter.queryFragment = searchText
        }
    }
    
    private func showSuggestions() {
        guard !searchResults.isEmpty else {
            hideSuggestions()
            return
        }
        
        let visibleCount = min(searchResults.count, maxVisibleResults)
        let height = CGFloat(visibleCount) * rowHeight
        
        tableViewHeightConstraint.constant = height
        updateSuggestionsOverlayFrameConstraints()
        suggestionsTableView.isHidden = false
        
        // Bring to front to ensure it's above other views
        parentView?.bringSubviewToFront(suggestionsTableView)
        
        UIView.animate(withDuration: 0.2) {
            self.parentView?.layoutIfNeeded()
        }
    }
    
    private func hideSuggestions() {
        tableViewHeightConstraint.constant = 0
        
        UIView.animate(withDuration: 0.2, animations: {
            self.parentView?.layoutIfNeeded()
        }) { _ in
            self.suggestionsTableView.isHidden = true
        }
    }
    
    private func selectLocation(at index: Int) {
        print("🟢 selectLocation called for index \(index)")
        guard index < searchResults.count else {
            print("❌ Index out of bounds: \(index) >= \(searchResults.count)")
            return
        }
        
        let selectedResult = searchResults[index]
        print("🟡 Geocoding: \(selectedResult.title)")
        activityIndicator.startAnimating()
        textField.isEnabled = false
        
        // Geocode to get precise coordinates
        let searchRequest = MKLocalSearch.Request(completion: selectedResult)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.textField.isEnabled = true
                
                if let error = error {
                    print("❌ Location search error: \(error.localizedDescription)")
                    return
                }
                
                guard let mapItem = response?.mapItems.first else {
                    print("❌ No map item found")
                    return
                }
                
                let coordinate = mapItem.placemark.coordinate
                let locationName = self.formatLocationName(from: mapItem.placemark)
                
                // Update text field (prevent triggering new search)
                self.isUpdatingProgrammatically = true
                self.textField.text = locationName
                self.isUpdatingProgrammatically = false
                self.updateClearButtonVisibility()
                
                self.hideSuggestions()
                
                // Get timezone
                self.getTimeZone(for: coordinate) { timeZone in
                    print("✅ Location selected: \(locationName)")
                    print("📍 Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
                    print("🕐 Timezone: \(timeZone.identifier)")
                    
                    self.delegate?.locationAutocompleteDidSelectLocation(
                        name: locationName,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        timeZone: timeZone
                    )
                }
            }
        }
    }
    
    private func formatLocationName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let adminArea = placemark.administrativeArea, adminArea != placemark.locality {
            components.append(adminArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func getTimeZone(for coordinate: CLLocationCoordinate2D, completion: @escaping (TimeZone) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("⚠️ Reverse geocoding error: \(error.localizedDescription)")
                completion(TimeZone.current)
                return
            }
            
            let timeZone = placemarks?.first?.timeZone ?? TimeZone.current
            completion(timeZone)
        }
    }
}

// MARK: - UITextFieldDelegate
extension LocationAutocompleteView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Don't resign first responder - keep keyboard up so user can continue typing
        // If there's exactly one result, select it
        if searchResults.count == 1 {
            selectLocation(at: 0)
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Show suggestions if we have results
        if !searchResults.isEmpty {
            showSuggestions()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Keep suggestions visible so user can tap them
        // They will be hidden after selection
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationAutocompleteView: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTableView.reloadData()
        showSuggestions()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Search completer error: \(error.localizedDescription)")
        searchResults.removeAll()
        suggestionsTableView.reloadData()
        hideSuggestions()
    }
}

// MARK: - UITableViewDataSource
extension LocationAutocompleteView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(searchResults.count, maxVisibleResults)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LocationSuggestionCell.identifier,
            for: indexPath
        ) as? LocationSuggestionCell else {
            return UITableViewCell()
        }
        
        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LocationAutocompleteView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("🔵 Table view cell tapped at row \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
        selectLocation(at: indexPath.row)
    }
}

// MARK: - LocationSuggestionCell
class LocationSuggestionCell: UITableViewCell {
    static let identifier = "LocationSuggestionCell"
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .default
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with result: MKLocalSearchCompletion) {
        titleLabel.text = result.title
        subtitleLabel.text = result.subtitle
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        iconImageView.image = UIImage(systemName: "mappin.circle.fill")
    }
}

