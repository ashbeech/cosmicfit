//
//  ChartWheelView.swift
//  Cosmic Fit
//
//  Vector‑drawn natal‑chart wheel – dark, minimal, ruler‑style.
//  Outer ring: 12 grey/black wedges (zodiac signs)
//  Inner ruler : three ticks (0°, 10°, 20°) per sign
//  House spokes : dashed
//  Planet glyphs : inside ruler
//  Aspect net   : inside glyph ring
//
//  Created by ChatGPT‑o3 on 09 May 2025.
//

import UIKit

final class ChartWheelView: UIView {
    
    // MARK: – Public ------------------------------------------------------
    
    func setChart(_ chart: NatalChartCalculator.NatalChart) {
        self.chart = chart
        setNeedsDisplay()
    }
    
    // MARK: – Private -----------------------------------------------------
    
    private var chart: NatalChartCalculator.NatalChart?
    private let zodiacNames = [
        "ARIES","TAURUS","GEMINI","CANCER","LEO","VIRGO",
        "LIBRA","SCORPIO","SAGITTARIUS","CAPRICORN","AQUARIUS","PISCES"
    ]
    
    // MARK: – UIView ------------------------------------------------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let chart = chart else { return }
        
        // ---------- Radii & geometry ------------------------------------
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR      = min(rect.width, rect.height) * 0.5 - 4        // whole wheel
        let bandW       = outerR * 0.13                                 // width of zodiac band
        let rulerR      = outerR - bandW                                // base of tick ruler
        let planetR     = rulerR - 18                                   // glyph radius
        let aspectR     = planetR - 30                                  // net radius
        
        let darkSeg  = UIColor(white: 0.05, alpha: 1).cgColor
        let lightSeg = UIColor(white: 0.18, alpha: 1).cgColor
        
        // ---------- Zodiac wedges (alternate black / grey) --------------
        for i in 0..<12 {
            let start = deg2rad(CGFloat(i*30) - 90)
            let end   = start + deg2rad(30)
            
            ctx.beginPath()
            ctx.addArc(center: c, radius: outerR, startAngle: start, endAngle: end, clockwise: false)
            ctx.addArc(center: c, radius: rulerR, startAngle: end,   endAngle: start, clockwise: true)
            ctx.closePath()
            ctx.setFillColor(i % 2 == 0 ? darkSeg : lightSeg)
            ctx.fillPath()
        }
        
        // Stroke outer & inner edge of band
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: CGRect(x: c.x-outerR, y: c.y-outerR, width: outerR*2, height: outerR*2))
        ctx.strokeEllipse(in: CGRect(x: c.x-rulerR, y: c.y-rulerR, width: rulerR*2, height: rulerR*2))
        
        // ---------- Zodiac labels (wrapped) ------------------------------------
        let labelFont = UIFont.systemFont(ofSize: nine(rect), weight: .bold)
        for i in 0..<12 {
            let midLon = CGFloat(i) * 30 + 15           // middle of the sign
            let ang    = deg2rad(midLon - 90)           // 0 ° Aries straight up
            let text   = zodiacNames[i] as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font           : labelFont,
                .foregroundColor: UIColor.white
            ]
            let size = text.size(withAttributes: attrs)
            
            // --- place the baseline of the text on a circle just inside band ---
            let radius = outerR - bandW * 0.55          // fine‑tune inward offset
            let anchor = point(on: radius, angle: ang, center: c)
            
            ctx.saveGState()
            ctx.translateBy(x: anchor.x, y: anchor.y)
            ctx.rotate(by: ang + .pi/2)                 // tangent to circle
            text.draw(at: CGPoint(x: -size.width/2,
                                  y: -size.height/2),
                      withAttributes: attrs)
            ctx.restoreGState()
        }
        
        // ---------- Ruler ticks (0°, 5°, 10° …) -------------------------------
        ctx.saveGState()
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1)

        let longLen:   CGFloat = 12   // sign cusps ••• longest
        let mediumLen: CGFloat = 8    // 10 ° marks •• medium
        let shortLen:  CGFloat = 4    // 5 ° marks  • shortest

        for deg in stride(from: 0, through: 355, by: 5) {      // every 5 °
            let ang  = deg2rad(CGFloat(deg) - 90)
            let len: CGFloat
            switch deg % 30 {          // position inside current sign
            case 0:      len = longLen             // 0°  (sign cusp)
            case 10,20:  len = mediumLen           // 10° and 20°
            default:     len = shortLen            // 5°, 15°, 25°
            }
            let pOuter = point(on: rulerR,        angle: ang, center: c)
            let pInner = point(on: rulerR - len,  angle: ang, center: c)
            ctx.beginPath(); ctx.move(to: pOuter); ctx.addLine(to: pInner); ctx.strokePath()
        }
        ctx.restoreGState()
        
        // ---------- House spokes (dashed, sign‑aligned) -----------------------
        ctx.saveGState()
        ctx.setStrokeColor(UIColor(white: 1, alpha: 0.5).cgColor)
        ctx.setLineWidth(0.8)
        ctx.setLineDash(phase: 0, lengths: [4,3])

        for i in 0..<12 {                               // 12 spokes
            let ang     = deg2rad(CGFloat(i*30) - 90)   // Aries 0°, Taurus 30° …
            let outerPt = point(on: rulerR, angle: ang, center: c)          // same
            let innerPt = point(on: planetR, angle: ang, center: c)         // NEW – stop at glyph ring
            ctx.beginPath()
            ctx.move(to: innerPt)       // ⬅️ start here, so nothing is drawn inside planetR
            ctx.addLine(to: outerPt)
            ctx.strokePath()
        }
        ctx.restoreGState()
        
        // ---------- House numerals (I‑XII) ------------------------------------
        let houseNumerals = ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII"]
        let numeralFont   = UIFont.systemFont(ofSize: nine(rect), weight: .regular)

        for i in 0..<12 {
            let midLon = CGFloat(i)*30 + 15
            let ang    = deg2rad(midLon - 90)
            let txt    = houseNumerals[i] as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: numeralFont,
                .foregroundColor: UIColor.white
            ]
            let size   = txt.size(withAttributes: attrs)
            
            // place on the inside edge of planet ring
            let radius = planetR - 6
            let anchor = point(on: radius, angle: ang, center: c)
            
            ctx.saveGState()
            ctx.translateBy(x: anchor.x, y: anchor.y)
            ctx.rotate(by: ang + .pi/2)      // tangent orientation
            txt.draw(at: CGPoint(x: -size.width/2,
                                 y: -size.height/2),
                     withAttributes: attrs)
            ctx.restoreGState()
        }
        
        // ---------- Planet glyphs ---------------------------------------
        let glyphFont = UIFont.systemFont(ofSize:  fourteen(rect), weight: .regular)
        var glyphPts: [CGPoint] = []
        for p in chart.planets {
            let ang = deg2rad(CGFloat(p.longitude) - 90)
            let pt  = point(on: planetR, angle: ang, center: c)
            glyphPts.append(pt)
            let sym = p.symbol as NSString
            let sz  = sym.size(withAttributes: [.font : glyphFont])
            sym.draw(at: CGPoint(x: pt.x - sz.width/2,
                                 y: pt.y - sz.height/2),
                      withAttributes: [.font: glyphFont,
                                       .foregroundColor: UIColor.white])
        }
        
        // ---------- Aspect net ------------------------------------------
        ctx.saveGState()
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1)
        let majors: Set<String> = ["Conjunction","Opposition","Trine","Square","Sextile"]
        for i in 0..<chart.planets.count {
            for j in (i+1)..<chart.planets.count {
                if let (aspect,_) = AstronomicalCalculator.calculateAspect(
                        point1: chart.planets[i].longitude,
                        point2: chart.planets[j].longitude,
                        orb: 4.0),
                   majors.contains(aspect) {
                    let a = glyphPts[i]
                    let b = glyphPts[j]
                    ctx.beginPath()
                    ctx.move(to: moveIn(a, centroid: c, by: planetR-aspectR))
                    ctx.addLine(to: moveIn(b, centroid: c, by: planetR-aspectR))
                    ctx.strokePath()
                }
            }
        }
        ctx.restoreGState()
        
        // ----- dashed circle to frame aspect net ------------------------
        ctx.setStrokeColor(UIColor(white: 1, alpha: 0.4).cgColor)
        ctx.setLineDash(phase: 0, lengths: [2,4])
        ctx.setLineWidth(0.6)
        ctx.strokeEllipse(in: CGRect(x: c.x-aspectR, y: c.y-aspectR,
                                     width: aspectR*2, height: aspectR*2))
    }
    
    // MARK: – Helpers -----------------------------------------------------
    
    private func deg2rad(_ d: CGFloat) -> CGFloat { d * .pi / 180 }
    
    private func point(on r: CGFloat, angle: CGFloat, center: CGPoint) -> CGPoint {
        CGPoint(x: center.x + cos(angle)*r,
                y: center.y + sin(angle)*r)
    }
    
    private func moveIn(_ p: CGPoint, centroid: CGPoint, by dist: CGFloat) -> CGPoint {
        let v = CGVector(dx: p.x-centroid.x, dy: p.y-centroid.y)
        let len = sqrt(v.dx*v.dx + v.dy*v.dy)
        let f = max(len-dist,0) / len
        return CGPoint(x: centroid.x + v.dx*f, y: centroid.y + v.dy*f)
    }
    
    // dynamic type helpers
    private func nine(_ r:CGRect)->CGFloat{ max(8, min(r.width,r.height)*0.03) }
    private func fourteen(_ r:CGRect)->CGFloat{ max(12, min(r.width,r.height)*0.045) }
}
