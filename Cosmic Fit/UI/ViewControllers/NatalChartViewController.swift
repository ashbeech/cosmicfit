//
//  NatalChartViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit

class NatalChartViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let birthInfoLabel = UILabel()
    private let chartImageView = UIImageView()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private var chartData: [String: Any] = [:]
    private var planetSections: [[String: Any]] = []
    private var anglesSections: [[String: Any]] = []
    
    private var birthInfo: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Configuration
    func configure(with chartData: [String: Any], birthInfo: String) {
        self.chartData = chartData
        self.birthInfo = birthInfo
        
        // Process chart data for display
        processChartData()
        
        // Update UI with chart data
        if isViewLoaded {
            updateUI()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Natal Chart"
        
        // Add button to show interpretations
        let interpretButton = UIBarButtonItem(title: "Interpret", style: .plain, target: self, action: #selector(showInterpretation))
        navigationItem.rightBarButtonItem = interpretButton
        
        // Setup Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Birth Info Label
        birthInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        birthInfoLabel.font = UIFont.systemFont(ofSize: 14)
        birthInfoLabel.textColor = .secondaryLabel
        birthInfoLabel.textAlignment = .center
        birthInfoLabel.numberOfLines = 0
        
        contentView.addSubview(birthInfoLabel)
        
        // Chart Image View (placeholder for chart wheel)
        chartImageView.translatesAutoresizingMaskIntoConstraints = false
        chartImageView.contentMode = .scaleAspectFit
        chartImageView.backgroundColor = .systemGray6
        chartImageView.layer.cornerRadius = 8
        chartImageView.clipsToBounds = true
        
        contentView.addSubview(chartImageView)
        
        // Add a simple placeholder for the chart wheel
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        let image = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: 300, height: 300)
            ctx.cgContext.setFillColor(UIColor.systemBackground.cgColor)
            ctx.cgContext.fillEllipse(in: rect)
            
            ctx.cgContext.setStrokeColor(UIColor.label.cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.strokeEllipse(in: rect.insetBy(dx: 2, dy: 2))
            
            // Draw center text
            let text = "Natal Chart"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        chartImageView.image = image
        
        // Table View
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChartDataCell.self, forCellReuseIdentifier: "ChartDataCell")
        tableView.isScrollEnabled = false
        
        contentView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            birthInfoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            birthInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            birthInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            chartImageView.topAnchor.constraint(equalTo: birthInfoLabel.bottomAnchor, constant: 16),
            chartImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            chartImageView.widthAnchor.constraint(equalToConstant: 300),
            chartImageView.heightAnchor.constraint(equalToConstant: 300),
            
            tableView.topAnchor.constraint(equalTo: chartImageView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Update UI with any existing data
        updateUI()
    }
    
    private func updateUI() {
        birthInfoLabel.text = birthInfo
        tableView.reloadData()
        
        // Update table view height constraint
        tableView.layoutIfNeeded()
        
        var tableHeight: CGFloat = 0
        
        for section in 0..<tableView.numberOfSections {
            tableHeight += tableView.rectForHeader(inSection: section).height
            
            for row in 0..<tableView.numberOfRows(inSection: section) {
                tableHeight += tableView.rectForRow(at: IndexPath(row: row, section: section)).height
            }
            
            tableHeight += tableView.rectForFooter(inSection: section).height
        }
        
        tableView.heightAnchor.constraint(equalToConstant: tableHeight).isActive = true
    }
    
    private func processChartData() {
        // Process planets
        if let planets = chartData["planets"] as? [[String: Any]] {
            planetSections = planets
        }
        
        // Process angles
        if let angles = chartData["angles"] as? [String: Any] {
            var anglesArray: [[String: Any]] = []
            for (key, value) in angles {
                if let angleData = value as? [String: Any] {
                    var data = angleData
                    data["name"] = key
                    anglesArray.append(data)
                }
            }
            anglesSections = anglesArray
        }
    }
    
    // MARK: - Actions
    @objc private func showInterpretation() {
        // Create and configure interpretation view controller
        let interpretationVC = InterpretationViewController()
        
        // Here you would pass the natal chart for interpretation
        // This is a simplified example - in a full implementation, you'd
        // need to access the original NatalChartCalculator.NatalChart object
        
        // For demonstration, we'll just show a basic interpretation
        let interpretationText = """
        This is a placeholder for the detailed interpretation of your natal chart.
        
        In a complete implementation, this would show interpretations of your Sun, Moon, 
        Ascendant, and significant planets based on your chart data.
        
        The interpretation would be generated by passing your complete natal chart
        to the AstrologicalInterpreter.
        """
        
        interpretationVC.configure(with: interpretationText)
        navigationController?.pushViewController(interpretationVC, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension NatalChartViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Planets, Angles
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return planetSections.count
        case 1: return anglesSections.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChartDataCell", for: indexPath) as! ChartDataCell
        
        switch indexPath.section {
        case 0:
            // Planets
            if indexPath.row < planetSections.count {
                let planet = planetSections[indexPath.row]
                let name = planet["name"] as? String ?? ""
                let symbol = planet["symbol"] as? String ?? ""
                let position = planet["formattedPosition"] as? String ?? ""
                let retrograde = planet["isRetrograde"] as? Bool ?? false
                
                let retrogradeText = retrograde ? " ℞" : ""
                
                cell.configure(
                    title: "\(symbol) \(name)\(retrogradeText)",
                    detail: position,
                    secondary: ""
                )
            }
            
        case 1:
            // Angles
            if indexPath.row < anglesSections.count {
                let angle = anglesSections[indexPath.row]
                let name = angle["name"] as? String ?? ""
                let position = angle["formattedPosition"] as? String ?? ""
                
                cell.configure(
                    title: name,
                    detail: position,
                    secondary: ""
                )
            }
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Planets"
        case 1: return "Angles"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Chart Data Cell
class ChartDataCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let secondaryLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        secondaryLabel.font = UIFont.systemFont(ofSize: 14)
        secondaryLabel.textColor = .tertiaryLabel
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(secondaryLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            secondaryLabel.leadingAnchor.constraint(equalTo: detailLabel.trailingAnchor, constant: 16),
            secondaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            secondaryLabel.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor)
        ])
    }
    
    func configure(title: String, detail: String, secondary: String) {
        titleLabel.text = title
        detailLabel.text = detail
        secondaryLabel.text = secondary
    }
}
