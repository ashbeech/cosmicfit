//
//  NatalChartViewController.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//  Updated 09/05/2025 – adds full Houses section and cleans up naming.
//

import UIKit

class NatalChartViewController: UIViewController {

    // MARK: - Properties --------------------------------------------------

    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let birthInfoLabel = UILabel()
    private let chartImageView = UIImageView()
    private let tableView      = UITableView(frame: .zero, style: .grouped)

    private var chartData: [String: Any] = [:]
    private var progressedChartData: [String: Any] = [:]

    private var planetSections: [[String: Any]] = []
    private var angleSections:  [[String: Any]] = []
    private var houseSections:  [[String: Any]] = []
    private var progressedPlanetSections: [[String: Any]] = []
    private var progressedAngleSections: [[String: Any]] = []
    private var currentAge: Int = 0

    private var birthInfo: String = ""
    private var birthDate: Date?
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var timeZone: TimeZone?

    // MARK: - Lifecycle ---------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Configuration ----------------------------------------------

    func configure(with chartData: [String: Any], birthInfo: String, birthDate: Date, latitude: Double, longitude: Double, timeZone: TimeZone) {
        self.chartData = chartData
        self.birthInfo = birthInfo
        self.birthDate = birthDate
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
        
        // Calculate current age
        self.currentAge = NatalChartCalculator.calculateCurrentAge(from: birthDate)
        
        // Calculate progressed chart
        if let tz = self.timeZone {
            self.progressedChartData = NatalChartManager.shared.calculateProgressedChart(
                date: birthDate,
                latitude: latitude,
                longitude: longitude,
                timeZone: tz
            )
        }
        
        processChartData()
        if isViewLoaded { updateUI() }
    }

    // MARK: - UI Setup ----------------------------------------------------

    private func setupUI() {

        view.backgroundColor = .systemBackground
        title = "Natal Chart"

        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Interpret",
                            style: .plain,
                            target: self,
                            action: #selector(showInterpretation))

        // ---------- Scroll / Content hierarchy ---------------------------
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

        // ---------- Birth‑info label -------------------------------------
        birthInfoLabel.font          = .systemFont(ofSize: 14)
        birthInfoLabel.textColor     = .secondaryLabel
        birthInfoLabel.textAlignment = .center
        birthInfoLabel.numberOfLines = 0
        birthInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(birthInfoLabel)

        // ---------- Chart wheel placeholder ------------------------------
        chartImageView.translatesAutoresizingMaskIntoConstraints = false
        chartImageView.contentMode   = .scaleAspectFit
        chartImageView.backgroundColor = .systemGray6
        chartImageView.layer.cornerRadius = 8
        chartImageView.clipsToBounds = true
        contentView.addSubview(chartImageView)
        chartImageView.image = makePlaceholderWheel()

        // ---------- Table view -------------------------------------------
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.register(ChartDataCell.self,
                           forCellReuseIdentifier: "ChartDataCell")
        tableView.isScrollEnabled = false
        contentView.addSubview(tableView)

        // ---------- Layout constraints -----------------------------------
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

        // ---------- Initial UI refresh -----------------------------------
        updateUI()
    }

    // Renders a simple wheel placeholder
    private func makePlaceholderWheel() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            ctx.cgContext.setFillColor(UIColor.systemBackground.cgColor)
            ctx.cgContext.fillEllipse(in: rect)

            ctx.cgContext.setStrokeColor(UIColor.label.cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.strokeEllipse(in: rect.insetBy(dx: 2, dy: 2))

            let text = "Natal Chart"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height)
            text.draw(in: textRect, withAttributes: attrs)
        }
    }

    // MARK: - Data preprocessing -----------------------------------------

    private func processChartData() {

        // ---------- Planets ----------------------------------------------
        if let planets = chartData["planets"] as? [[String: Any]] {
            planetSections = planets
        }

        // ---------- Angles -----------------------------------------------
        if let angles = chartData["angles"] as? [String: Any] {
            var arr: [[String: Any]] = []
            for (k, v) in angles {
                if var dict = v as? [String: Any] {
                    dict["name"] = k
                    arr.append(dict)
                }
            }
            angleSections = arr
        }

        // ---------- Houses -----------------------------------------------
        if let houses = chartData["houses"] as? [[String: Any]] {
            houseSections = houses.sorted {
                let a = $0["number"] as? Int ?? 0
                let b = $1["number"] as? Int ?? 0
                return a < b
            }
        }
        
        // ---------- Progressed Planets -----------------------------------
        if let progPlanets = progressedChartData["planets"] as? [[String: Any]] {
            progressedPlanetSections = progPlanets
        }
        
        // ---------- Progressed Angles -----------------------------------
        if let progAngles = progressedChartData["angles"] as? [String: Any] {
            var arr: [[String: Any]] = []
            for (k, v) in progAngles {
                if var dict = v as? [String: Any] {
                    dict["name"] = k
                    arr.append(dict)
                }
            }
            progressedAngleSections = arr
        }
    }

    // MARK: - UI refresh --------------------------------------------------

    private func updateUI() {
        birthInfoLabel.text = birthInfo
        tableView.reloadData()

        tableView.layoutIfNeeded()
        var height: CGFloat = 0
        for section in 0..<tableView.numberOfSections {
            height += tableView.rectForHeader(inSection: section).height
            for row in 0..<tableView.numberOfRows(inSection: section) {
                height += tableView.rectForRow(at: IndexPath(row: row, section: section)).height
            }
            height += tableView.rectForFooter(inSection: section).height
        }
        tableView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    // MARK: - Actions -----------------------------------------------------

    @objc private func showInterpretation() {
        let interpretationVC = InterpretationViewController()
        interpretationVC.configure(with:
            """
            This is a placeholder for the detailed interpretation of your natal chart.
            """)
        navigationController?.pushViewController(interpretationVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate --------------------

extension NatalChartViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5   // Planets · House Cusps · Angles · Progressed Planets · Progressed Angles
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return planetSections.count
        case 1: return houseSections.count
        case 2: return angleSections.count
        case 3: return progressedPlanetSections.count
        case 4: return progressedAngleSections.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ChartDataCell",
                                                 for: indexPath) as! ChartDataCell

        switch indexPath.section {

        // -------- Planets -------------------------------------------------
        case 0:
            let p = planetSections[indexPath.row]
            let name   = p["name"] as? String ?? ""
            let symbol = p["symbol"] as? String ?? ""
            let pos    = p["formattedPosition"] as? String ?? ""
            let retro  = (p["isRetrograde"] as? Bool ?? false) ? " ℞" : ""
            let house  = p["house"] as? Int ?? 0
            let houseStr = house > 0 ? "House \(house)" : ""
            
            cell.configure(title: "\(symbol) \(name)\(retro)",
                           detail: pos,
                           secondary: houseStr)

        // -------- House Cusps ---------------------------------------------
        case 1:
            let h   = houseSections[indexPath.row]
            let num = h["number"] as? Int ?? 0
            let pos = h["formattedPosition"] as? String ?? ""
            cell.configure(title: "House Cusp \(num)",
                           detail: pos,
                           secondary: "")

        // -------- Angles --------------------------------------------------
        case 2:
            let a   = angleSections[indexPath.row]
            let name = a["name"] as? String ?? ""
            let pos  = a["formattedPosition"] as? String ?? ""
            cell.configure(title: name,
                           detail: pos,
                           secondary: "")
            
        // -------- Progressed Planets -------------------------------------
        case 3:
            let p = progressedPlanetSections[indexPath.row]
            let name   = p["name"] as? String ?? ""
            let symbol = p["symbol"] as? String ?? ""
            let pos    = p["formattedPosition"] as? String ?? ""
            let retro  = (p["isRetrograde"] as? Bool ?? false) ? " ℞" : ""
            let house  = p["house"] as? Int ?? 0
            let houseStr = house > 0 ? "House \(house)" : ""
            
            cell.configure(title: "\(symbol) \(name)\(retro)",
                           detail: pos,
                           secondary: houseStr)
            
        // -------- Progressed Angles -------------------------------------
        case 4:
            let a = progressedAngleSections[indexPath.row]
            let name = a["name"] as? String ?? ""
            let pos  = a["formattedPosition"] as? String ?? ""
            cell.configure(title: name,
                           detail: pos,
                           secondary: "")

        default: break
        }
        return cell
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Planets"
        case 1: return "House Cusps"
        case 2: return "Angles"
        case 3: return "Progressed Planets (Age \(currentAge))"
        case 4: return "Progressed Angles (Age \(currentAge))"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - ChartDataCell ---------------------------------------------------

class ChartDataCell: UITableViewCell {

    private let titleLabel     = UILabel()
    private let detailLabel    = UILabel()
    private let secondaryLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {

        titleLabel.font = .boldSystemFont(ofSize: 16)
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel
        secondaryLabel.font = .systemFont(ofSize: 14)
        secondaryLabel.textColor = .tertiaryLabel

        [titleLabel, detailLabel, secondaryLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            secondaryLabel.leadingAnchor.constraint(equalTo: detailLabel.trailingAnchor, constant: 16),
            secondaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            secondaryLabel.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor)
        ])
    }

    func configure(title: String, detail: String, secondary: String) {
        titleLabel.text     = title
        detailLabel.text    = detail
        secondaryLabel.text = secondary
    }
}
