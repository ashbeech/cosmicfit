//
//  ChartWheelView.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//
/*
import UIKit

class ChartWheelView: UIView {
    var chart: NatalChart?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart else { return }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Calculate center and radius
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 20
        
        // Draw wheel
        drawWheel(context: context, center: center, radius: radius)
        
        // Draw houses
        drawHouses(context: context, center: center, radius: radius, houses: chart.houses)
        
        // Draw planets
        drawPlanets(context: context, center: center, radius: radius, planets: chart.planets)
        
        // Draw aspects
        drawAspects(context: context, center: center, radius: radius * 0.8, aspects: chart.aspects, planets: chart.planets)
    }
    
    private func drawWheel(context: CGContext, center: CGPoint, radius: CGFloat) {
        // Draw outer circle
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
        context.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        context.strokePath()
        
        // Draw inner circle for planets
        context.setLineWidth(1.0)
        context.addArc(center: center, radius: radius * 0.8, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        context.strokePath()
        
        // Draw zodiac segments
        context.setStrokeColor(UIColor.darkGray.cgColor)
        context.setLineWidth(1.0)
        
        for i in 0..<12 {
            let angle = CGFloat(i * 30) * .pi / 180.0
            
            let startPoint = CGPoint(
                x: center.x + radius * 0.8 * cos(angle),
                y: center.y + radius * 0.8 * sin(angle)
            )
            
            let endPoint = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
            
            // Draw zodiac symbol
            let symbolPoint = CGPoint(
                x: center.x + (radius + 15) * cos(angle + .pi / 12),
                y: center.y + (radius + 15) * sin(angle + .pi / 12)
            )
            
            let sign = ZodiacSign.allCases[i]
            let symbol = sign.symbol as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            symbol.draw(at: symbolPoint, withAttributes: attributes)
        }
    }
    
    private func drawHouses(context: CGContext, center: CGPoint, radius: CGFloat, houses: [House]) {
        context.setStrokeColor(UIColor.darkGray.cgColor)
        context.setLineWidth(1.0)
        
        // Draw house lines
        for house in houses {
            let angle = CGFloat(house.cusp * .pi / 180.0)
            let startPoint = center
            let endPoint = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
            
            // Draw house number
            let labelPoint = CGPoint(
                x: center.x + (radius * 0.7) * cos(angle + 0.1),
                y: center.y + (radius * 0.7) * sin(angle + 0.1)
            )
            
            let houseLabel = "\(house.number)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            houseLabel.draw(at: labelPoint, withAttributes: attributes)
        }
    }
    
    private func drawPlanets(context: CGContext, center: CGPoint, radius: CGFloat, planets: [Planet]) {
        // Map to place planets so they don't overlap
        var placedAngles: [CGFloat: [CGFloat]] = [:]
        
        for planet in planets {
            let angle = CGFloat(planet.longitude * .pi / 180.0)
            let baseDistance = radius * 0.9 // Place planets near the outer edge
            
            // Check if there's already a planet at this angle
            let angleKey = floor(angle * 100) / 100 // Round to help with grouping
            
            // Adjust planet distance if needed to avoid overlap
            var distance = baseDistance
            if let existingPlanets = placedAngles[angleKey], !existingPlanets.isEmpty {
                distance = baseDistance - CGFloat(existingPlanets.count) * 10.0
            }
            
            let planetPoint = CGPoint(
                x: center.x + distance * cos(angle),
                y: center.y + distance * sin(angle)
            )
            
            // Store this location
            if placedAngles[angleKey] != nil {
                placedAngles[angleKey]?.append(distance)
            } else {
                placedAngles[angleKey] = [distance]
            }
            
            // Draw planet symbol
            context.setFillColor(UIColor.blue.cgColor)
            context.addArc(center: planetPoint, radius: 5.0, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            context.fillPath()
            
            // Draw planet symbol
            let symbol = planet.type.symbol as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let labelPoint = CGPoint(
                x: planetPoint.x - 5,
                y: planetPoint.y - 15
            )
            
            symbol.draw(at: labelPoint, withAttributes: attributes)
        }
    }
    
    private func drawAspects(context: CGContext, center: CGPoint, radius: CGFloat, aspects: [Aspect], planets: [Planet]) {
        // Create a dictionary to quickly look up planets by type
        var planetDict: [PlanetType: Planet] = [:]
        for planet in planets {
            planetDict[planet.type] = planet
        }
        
        // Only draw major aspects
        let majorAspects = AspectCalculations.getMajorAspects(aspects: aspects)
        
        for aspect in majorAspects {
            guard let planet1 = planetDict[aspect.planet1],
                  let planet2 = planetDict[aspect.planet2] else {
                continue
            }
            
            let angle1 = CGFloat(planet1.longitude * .pi / 180.0)
            let angle2 = CGFloat(planet2.longitude * .pi / 180.0)
            
            let point1 = CGPoint(
                x: center.x + radius * cos(angle1),
                y: center.y + radius * sin(angle1)
            )
            
            let point2 = CGPoint(
                x: center.x + radius * cos(angle2),
                y: center.y + radius * sin(angle2)
            )
            
            // Set line style based on aspect type
            switch aspect.type {
            case .conjunction:
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineWidth(1.0)
            case .opposition:
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineDash(phase: 0, lengths: [4, 2])
                context.setLineWidth(1.0)
            case .trine:
                context.setStrokeColor(UIColor.green.cgColor)
                context.setLineWidth(1.0)
            case .square:
                context.setStrokeColor(UIColor.orange.cgColor)
                context.setLineDash(phase: 0, lengths: [4, 2])
                context.setLineWidth(1.0)
            case .sextile:
                context.setStrokeColor(UIColor.blue.cgColor)
                context.setLineWidth(1.0)
            default:
                context.setStrokeColor(UIColor.lightGray.cgColor)
                context.setLineWidth(0.5)
            }
            
            // Draw line connecting the planets
            context.move(to: point1)
            context.addLine(to: point2)
            context.strokePath()
            
            // Reset dash pattern
            context.setLineDash(phase: 0, lengths: [])
        }
    }
}
*/
