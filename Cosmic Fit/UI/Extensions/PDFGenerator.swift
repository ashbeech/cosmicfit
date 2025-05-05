//
//  PDFGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit
import PDFKit

/// Utility class for generating PDF documents from natal charts
class PDFGenerator {
    
    // MARK: - Constants
    
    /// Standard page margins
    private static let pageMargin: CGFloat = 50.0
    
    /// Standard line height
    private static let lineHeight: CGFloat = 18.0
    
    // MARK: - PDF Generation
    
    /// Generate a PDF document from a natal chart
    /// - Parameters:
    ///   - chart: The natal chart to export
    ///   - withHeading: Whether to include app branding and heading
    /// - Returns: PDF data or nil if generation failed
    static func generatePDF(from chart: NatalChart, withHeading: Bool = true) -> Data? {
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "Cosmic Fit",
            kCGPDFContextAuthor: "Cosmic Fit",
            kCGPDFContextTitle: "Natal Chart Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Use US Letter size (8.5 x 11 inches)
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { (context) in
            context.beginPage()
            
            // Add logo and header if requested
            let headerHeight: CGFloat = withHeading ? 120.0 : 0.0
            var contentY: CGFloat = 10.0
            
            if withHeading {
                // Add app logo
                let logoSize: CGFloat = 60.0
                let logoX = (pageWidth - logoSize) / 2.0
                let logoRect = CGRect(x: logoX, y: contentY, width: logoSize, height: logoSize)
                
                if let logoImage = UIImage(named: "AppIcon") {
                    logoImage.draw(in: logoRect)
                }
                
                contentY += logoSize + 10
                
                // Add title
                let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ]
                
                let titleText = "Natal Chart Report"
                let titleTextWidth = titleText.size(withAttributes: titleAttributes).width
                let titleX = (pageWidth - titleTextWidth) / 2.0
                
                titleText.draw(at: CGPoint(x: titleX, y: contentY), withAttributes: titleAttributes)
                contentY += 30.0
                
                // Add generation date
                let dateFont = UIFont.systemFont(ofSize: 10.0)
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: dateFont,
                    .foregroundColor: UIColor.darkGray
                ]
                
                let dateText = "Generated: \(DateUtility.shared.formatFullDateTime(Date()))"
                let dateTextWidth = dateText.size(withAttributes: dateAttributes).width
                let dateX = (pageWidth - dateTextWidth) / 2.0
                
                dateText.draw(at: CGPoint(x: dateX, y: contentY), withAttributes: dateAttributes)
                contentY += 20.0
            }
            
            // Add chart data
            let textFont = UIFont.systemFont(ofSize: 12.0)
            let boldFont = UIFont.boldSystemFont(ofSize: 14.0)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let headingAttributes: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            // Get the chart text report
            let reportText = chart.generateReport()
            let reportLines = reportText.components(separatedBy: "\n")
            
            let margin: CGFloat = pageMargin
            let textRect = CGRect(x: margin, y: contentY, width: pageWidth - (margin * 2), height: pageHeight - contentY - margin)
            
            // Draw each line with appropriate styling
            var y = contentY
            var isHeading = false
            
            for line in reportLines {
                // Determine if this is a heading
                if line.contains("=====") || line.isEmpty {
                    // Skip separator lines
                    continue
                } else if line == line.uppercased() && !line.isEmpty {
                    // It's a heading (all caps)
                    isHeading = true
                    
                    // Add some space before headings except the first one
                    if y > contentY {
                        y += 10
                    }
                } else {
                    isHeading = false
                }
                
                // Draw the line
                let attributes = isHeading ? headingAttributes : textAttributes
                line.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
                
                // Move to next line
                let lineHeight = isHeading ? 20.0 : lineHeight
                y += lineHeight
                
                // Check if we need a new page
                if y > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
            }
            
            // Add chart wheel on second page
            context.beginPage()
            
            // Add title for chart wheel
            let wheelTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let wheelTitle = "Natal Chart Wheel"
            let wheelTitleWidth = wheelTitle.size(withAttributes: wheelTitleAttributes).width
            let wheelTitleX = (pageWidth - wheelTitleWidth) / 2.0
            
            wheelTitle.draw(at: CGPoint(x: wheelTitleX, y: margin / 2), withAttributes: wheelTitleAttributes)
            
            // Draw chart wheel in the center of the page
            let wheelSize = min(pageWidth, pageHeight) - (margin * 2)
            let wheelRect = CGRect(x: (pageWidth - wheelSize) / 2, y: (pageHeight - wheelSize) / 2, width: wheelSize, height: wheelSize)
            
            // Render chart wheel
            let wheelView = ChartWheelView(frame: wheelRect)
            wheelView.chart = chart
            
            // Render the chart wheel view to the PDF context
            let renderer = UIGraphicsImageRenderer(bounds: wheelRect)
            let wheelImage = renderer.image { ctx in
                wheelView.drawHierarchy(in: wheelRect.offsetBy(dx: -wheelRect.minX, dy: -wheelRect.minY), afterScreenUpdates: true)
            }
            wheelImage.draw(in: wheelRect)
            
            // Add birth information at the bottom
            let birthInfoAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
            
            let birthInfo = "Birth Date: \(DateUtility.shared.formatDate(chart.birthDate)) - Birth Time: \(DateUtility.shared.formatTime(chart.birthDate))"
            let birthInfoWidth = birthInfo.size(withAttributes: birthInfoAttributes).width
            let birthInfoX = (pageWidth - birthInfoWidth) / 2.0
            let birthInfoY = pageHeight - margin / 2
            
            birthInfo.draw(at: CGPoint(x: birthInfoX, y: birthInfoY), withAttributes: birthInfoAttributes)
        }
    }
    
    // MARK: - File Management
    
    /// Save PDF data to a file in the Documents directory
    /// - Parameters:
    ///   - data: PDF data to save
    ///   - fileName: Base file name (date/time will be appended)
    /// - Returns: URL to the saved file or nil if saving failed
    static func savePDF(data: Data, fileName: String = "NatalChart") -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileNameWithDate = "\(fileName)_\(dateFormatter.string(from: Date())).pdf"
        let fileURL = documentsDirectory.appendingPathComponent(fileNameWithDate)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get all saved PDF files in the Documents directory
    /// - Returns: Array of URLs to PDF files
    static func getAllPDFs() -> [URL] {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension.lowercased() == "pdf" }
        } catch {
            print("Error getting PDFs: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Delete a PDF file
    /// - Parameter url: URL of file to delete
    /// - Returns: Whether deletion was successful
    static func deletePDF(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("Error deleting PDF: \(error.localizedDescription)")
            return false
        }
    }
}
