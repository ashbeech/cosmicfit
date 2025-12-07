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
    
    // MARK: - UI Elements
    let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = UIFont.systemFont(ofSize: 18)
        field.textColor = .black
        field.borderStyle = .none
        field.returnKeyType = .done
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        return field
    }()
    
    private let divider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
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
        indicator.color = .systemGray
        return indicator
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint!
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
        addSubview(textField)
        addSubview(divider)
        addSubview(activityIndicator)
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
            // Text field
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44),
            
            // Divider
            divider.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: -8),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            // Bottom anchor of the view is the divider when no suggestions
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Activity indicator
            activityIndicator.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -8)
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
        parentView.addSubview(suggestionsTableView)
        
        // Position suggestions below this view
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
            suggestionsTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableViewHeightConstraint
        ])
    }
    
    func setPlaceholder(_ placeholder: String, animated: Bool = false) {
        if animated {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                    .font: UIFont.systemFont(ofSize: 18)
                ]
            )
        } else {
            textField.placeholder = placeholder
        }
    }
    
    func setText(_ text: String) {
        isUpdatingProgrammatically = true
        textField.text = text
        isUpdatingProgrammatically = false
    }
    
    func getText() -> String {
        return textField.text ?? ""
    }
    
    // MARK: - Private Methods
    @objc private func textFieldDidChange() {
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

