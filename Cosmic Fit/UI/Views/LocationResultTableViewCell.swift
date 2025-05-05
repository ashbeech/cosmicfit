//
//  LocationResultTableViewCell.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit
import MapKit

class LocationResultTableViewCell: UITableViewCell {
    // MARK: - Properties
    
    /// Identifier for reusing the cell
    static let identifier = "LocationResultTableViewCell"
    
    // MARK: - UI Elements
    
    /// Container view for the content
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    /// Icon image view for the location
    private let locationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        return imageView
    }()
    
    /// Label for the main title
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    /// Label for the subtitle
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Configure the cell
        backgroundColor = .clear
        selectionStyle = .none
        
        // Add container view
        contentView.addSubview(containerView)
        
        // Add subviews to container
        containerView.addSubview(locationIcon)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            // Location icon
            locationIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            locationIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            locationIcon.widthAnchor.constraint(equalToConstant: 30),
            locationIcon.heightAnchor.constraint(equalToConstant: 30),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - Public Methods
    
    /// Configure the cell with a search result
    /// - Parameter result: The search completion result to display
    func configure(with result: MKLocalSearchCompletion) {
        titleLabel.text = result.title
        subtitleLabel.text = result.subtitle
        
        // Set icon based on location type
        if result.subtitle.lowercased().contains("airport") {
            locationIcon.image = UIImage(systemName: "airplane")
        } else if result.subtitle.lowercased().contains("station") {
            locationIcon.image = UIImage(systemName: "train.side.front.car")
        } else if result.subtitle.lowercased().contains("university") ||
                  result.subtitle.lowercased().contains("college") {
            locationIcon.image = UIImage(systemName: "building.columns")
        } else if result.subtitle.lowercased().contains("hospital") {
            locationIcon.image = UIImage(systemName: "cross.fill")
        } else {
            locationIcon.image = UIImage(systemName: "mappin.circle.fill")
        }
    }
    
    // MARK: - Cell Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset cell to default state
        titleLabel.text = nil
        subtitleLabel.text = nil
        locationIcon.image = UIImage(systemName: "mappin.circle.fill")
    }
}
