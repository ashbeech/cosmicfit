//
//  CosmicFitLogoMarkView.swift
//  Cosmic Fit
//
//  Renders the "Cosmic Fit" vertical lockup logo as individually
//  animatable vector elements (each star and each letter is its own
//  shape layer) so they can be faded in sequentially.
//

import UIKit

/// A vector rendering of the "Cosmic Fit Logo - Vertical Lockup (White)" artwork.
///
/// The artwork is split into discrete elements — the two decorative stars and
/// every individual letter — so each one can be faded in one after another,
/// mirroring the original star/"CF" reveal.
final class CosmicFitLogoMarkView: UIView {

    /// The natural coordinate space of the source SVG artwork.
    private let viewBox = CGSize(width: 681.09, height: 413.05)

    /// Path data for each element, ordered for a top-to-bottom, reading-order reveal.
    /// Sequence: ✦ · C · o · s · m · i · c · ✦ · F · i · t
    private static let elementPaths: [String] = [
        // ✦ star above "Cosmic"
        "M137.61,76.32c-8.64-2.75-14.95-11.82-17.3-24.66h-2c-2.34,12.82-8.63,21.87-17.25,24.64v1.78c8.64,2.78,14.94,11.88,17.27,24.75h1.96c2.33-12.9,8.65-22.01,17.32-24.77v-1.75Z",
        // C
        "M74.73,151.14c-21.35,0-39.15-7.12-53.38-21.35C7.12,115.55,0,97.2,0,74.73,0,51.97,8.97,31.24,27.06,16.93,42.82,4.47,63.17,0,82.9,0c16.05,0,32.17,2.02,48.36,6.07l-10.89,37.47s-2.09,0-2.09,0c-4.49-6.09-9.28-12.01-14.61-17.39-4.66-4.7-9.67-8.47-15.25-11.98-2.88-1.81-5.84-3.51-8.96-4.87-12.27-5.36-27.83-3.31-38.22,5.28-1.76,1.46-3.37,3.1-4.81,4.88-7.12,8.79-10.68,19.12-10.68,30.98,0,34.61,20.73,86.66,61.54,86.66,17.17,0,32.73-6.63,46.68-19.89l1.88,2.09c-14.1,21.21-34.47,31.82-61.13,31.82Z",
        // o
        "M142.29,97.51c0-14.19,4.8-26.61,14.4-37.25,9.6-10.64,21.77-15.96,36.52-15.96s26.26,5.08,36.62,15.23c10.36,10.16,15.55,22.75,15.55,37.77,0,14.19-4.94,26.64-14.82,37.35-9.88,10.71-22.26,16.07-37.15,16.07s-26.26-5.18-36.21-15.55c-9.95-10.36-14.92-22.92-14.92-37.67ZM200.3,145.51c6.68,0,12.14-2.19,16.38-6.57,4.24-4.38,6.37-9.77,6.37-16.17,0-9.04-3.48-21.7-10.43-37.98-4.87-12.38-9.15-21.35-12.83-26.92-3.69-5.56-8.11-8.35-13.25-8.35-6.68,0-12.04,2.19-16.07,6.57-4.04,4.38-6.05,9.7-6.05,15.96,0,8.49,3.34,21.01,10.02,37.56,4.73,12.8,8.94,21.98,12.63,27.55,3.68,5.57,8.1,8.35,13.25,8.35Z",
        // s
        "M252.1,148.43l8.14-28.8h1.88c.42.7,2.05,2.54,4.9,5.53,2.85,2.99,5.46,5.53,7.83,7.62,10.57,8.35,19.75,12.52,27.55,12.52,4.17,0,7.58-1.04,10.23-3.13,2.64-2.09,3.96-5.08,3.96-8.97,0-2.5-.63-4.76-1.88-6.78-1.25-2.02-3.41-3.93-6.47-5.74-3.06-1.81-5.57-3.16-7.51-4.07-1.95-.9-5.08-2.19-9.39-3.86-1.39-.55-2.44-.97-3.13-1.25-5.84-2.5-10.47-4.66-13.88-6.47-3.41-1.81-6.71-4.1-9.91-6.89-3.2-2.78-5.5-5.95-6.89-9.5-1.39-3.55-2.09-7.75-2.09-12.63,0-20.87,12.8-31.3,38.4-31.3,10.85,0,21.42.97,31.72,2.92l-7.93,28.8h-2.09c-1.25-1.39-2.61-3.03-4.07-4.9-1.46-1.88-2.58-3.27-3.34-4.17-.77-.9-1.71-1.95-2.82-3.13-1.12-1.18-2.37-2.4-3.76-3.65-8.07-7.23-15.44-10.85-22.12-10.85-3.9,0-7.13,1.11-9.7,3.34-2.58,2.23-3.86,5.01-3.86,8.35,0,1.81.49,3.58,1.46,5.32.97,1.74,2.61,3.44,4.9,5.11s4.28,3.1,5.95,4.28c1.67,1.18,4.35,2.58,8.03,4.17,3.68,1.6,6.23,2.71,7.62,3.34,1.39.63,4.03,1.71,7.93,3.23,8.9,3.48,15.82,7.58,20.76,12.31,4.94,4.73,7.41,11.48,7.41,20.24,0,21.15-14.12,31.72-42.36,31.72-5.01,0-11.55-.35-19.62-1.04-8.07-.7-13.36-1.25-15.86-1.67Z",
        // m
        "M336.15,148.64v-2.3l12.94-10.43V62.66l-12.94-8.76v-2.3l38.4-6.47,1.67,23.37c4.45-6.54,9.88-12.14,16.28-16.8,6.4-4.66,13.08-6.99,20.03-6.99,7.65,0,13.77,1.81,18.36,5.43,4.59,3.62,7.86,9.81,9.81,18.57,11.96-16,24.42-24,37.35-24,10.15,0,17.7,3.38,22.64,10.12,4.94,6.75,7.41,18.61,7.41,35.58v45.49l12.94,10.43v2.3h-53.42v-2.3l13.36-10.43v-45.49c0-10.99-1.29-18.75-3.86-23.27-2.58-4.52-7.34-6.78-14.29-6.78-7.65,0-14.75,4.45-21.29,13.36.69,4.04,1.04,9.6,1.04,16.7v45.49l13.15,10.43v2.3h-53.21v-2.3l12.94-10.43v-45.49c0-10.99-1.29-18.75-3.86-23.27-2.58-4.52-7.27-6.78-14.09-6.78-8.49,0-15.58,4.87-21.29,14.61v60.94l13.15,10.43v2.3h-53.21Z",
        // i (Cosmic)
        "M582.21,146.34v2.3h-53.01v-2.3l12.94-10.43V62.66l-12.94-8.97v-2.3l40.07-6.26v90.78l12.94,10.43ZM538.81,18.21c0-4.03,1.46-7.48,4.38-10.33,2.92-2.85,6.33-4.28,10.23-4.28s7.3,1.43,10.23,4.28c2.92,2.85,4.38,6.3,4.38,10.33s-1.46,7.27-4.38,10.12c-2.92,2.85-6.33,4.28-10.23,4.28s-7.3-1.42-10.23-4.28c-2.92-2.85-4.38-6.22-4.38-10.12Z",
        // c
        "M635.8,150.51c-14.47,0-26.47-5.04-36-15.13-9.53-10.09-14.3-22.71-14.3-37.88,0-8.62,1.88-16.45,5.63-23.48,3.76-7.02,8.56-12.59,14.4-16.7,5.84-4.1,12.07-7.27,18.68-9.5,6.61-2.22,13.11-3.34,19.51-3.34,8.07,0,19.06,1.39,32.97,4.17l-7.72,28.17h-2.3c-6.68-8.35-10.92-13.42-12.73-15.23-8.35-7.65-15.72-11.48-22.12-11.48-8.35,0-14.26,2.58-17.74,7.72-3.48,5.15-5.22,11.06-5.22,17.74,0,9.88,3.06,22.05,9.18,36.52,7.37,18.5,17.39,27.76,30.05,27.76,11.96,0,22.05-4.73,30.26-14.19l2.71,2.09c-10.71,15.17-25.81,22.75-45.28,22.75Z",
        // ✦ star above "Fit"
        "M314.57,246.26c-8.56-2.73-14.81-11.7-17.13-24.42h-1.98c-2.32,12.69-8.55,21.66-17.08,24.4v1.77c8.56,2.75,14.8,11.76,17.1,24.52h1.94c2.31-12.78,8.57-21.8,17.15-24.53v-1.73Z",
        // F
        "M334.28,170.04l-113.21-.11-1.58,6.09c2.66,1.56,5.12,3.45,7.34,5.64,7.25,7.16,11.19,17.02,11.24,27.21l.04,8.08v125.45c0,7.79-4.82,12.87-12.13,15.55-.35.13-.71.25-1.06.37v2.7c13.06,4.2,22.59,17.96,26.1,37.43h2.97c3.52-19.5,13.08-33.28,26.18-37.45v-2.65s-.1-.03-.14-.05c-7.64-2.48-12.74-7.74-12.74-15.77v-168.32h29.32c5,3.89,30.29,35.36,35.29,39.25h2.39v-43.42Z",
        // i (Fit)
        "M393.14,312.96v2.3h-53.01v-2.3l12.94-10.43v-73.25l-12.94-8.97v-2.3l40.07-6.26v90.78l12.94,10.43ZM349.74,184.82c0-4.03,1.46-7.48,4.38-10.33,2.92-2.85,6.33-4.28,10.23-4.28s7.3,1.43,10.23,4.28c2.92,2.85,4.38,6.3,4.38,10.33s-1.46,7.27-4.38,10.12c-2.92,2.85-6.33,4.28-10.23,4.28s-7.3-1.42-10.23-4.28c-2.92-2.85-4.38-6.22-4.38-10.12Z",
        // t
        "M395.18,216.75v-3.76l14.82-2.09,21.29-26.5h2.09v28.59h27.13v3.76h-27.13v72.21c0,14.33,5.29,21.5,15.86,21.5,3.2,0,7.65-1.04,13.36-3.13v5.43c-6.54,2.78-14.61,4.17-24.21,4.17-12.38,0-20.84-3.06-25.36-9.18-4.52-6.12-6.78-14.89-6.78-26.29v-64.69h-11.06Z"
    ]

    /// Paths in the artwork's native coordinate space; transformed to fit `bounds` on layout.
    private var nativePaths: [CGPath] = []

    /// One shape layer per element, in reveal order.
    private(set) var elementLayers: [CAShapeLayer] = []

    /// Element indices grouped into the logical pieces of the lockup.
    /// Matches the order of `elementPaths`.
    enum ElementGroup {
        /// The ✦ star tucked inside the "C" of "Cosmic".
        static let cosmicStar = [0]
        /// The letters C · o · s · m · i · c.
        static let cosmicLetters = [1, 2, 3, 4, 5, 6]
        /// The ✦ star plus the letters F · i · t.
        static let fit = [7, 8, 9, 10]
        /// Every element of the lockup (both stars and all letters).
        static var all: [Int] { Array(0..<elementPaths.count) }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        for pathString in Self.elementPaths {
            let path = SVGPathParser.cgPath(from: pathString)
            nativePaths.append(path)

            let shape = CAShapeLayer()
            shape.fillColor = UIColor.white.cgColor
            shape.fillRule = .nonZero
            shape.opacity = 0 // Start invisible
            layer.addSublayer(shape)
            elementLayers.append(shape)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0, bounds.height > 0 else { return }

        // Aspect-fit the artwork's viewBox inside our bounds and centre it.
        let scale = min(bounds.width / viewBox.width, bounds.height / viewBox.height)
        let drawnWidth = viewBox.width * scale
        let drawnHeight = viewBox.height * scale
        let offsetX = (bounds.width - drawnWidth) / 2
        let offsetY = (bounds.height - drawnHeight) / 2

        var transform = CGAffineTransform(translationX: offsetX, y: offsetY)
            .scaledBy(x: scale, y: scale)

        for (index, shape) in elementLayers.enumerated() {
            shape.frame = bounds
            shape.path = nativePaths[index].copy(using: &transform)
        }
    }

    // MARK: - Animation

    /// Fades each element in sequentially, mirroring the original star/"CF" reveal.
    /// - Parameters:
    ///   - elementDuration: how long each individual element takes to fade in.
    ///   - stagger: delay between the start of consecutive elements.
    ///   - startDelay: delay before the first element begins.
    func animateReveal(elementDuration: TimeInterval = 0.8,
                       stagger: TimeInterval = 0.09,
                       startDelay: TimeInterval = 0.0) {
        // Ensure paths are laid out before animating.
        layoutIfNeeded()

        let start = CACurrentMediaTime() + startDelay
        for (index, shape) in elementLayers.enumerated() {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0
            fade.toValue = 1
            fade.duration = elementDuration
            fade.beginTime = start + Double(index) * stagger
            fade.fillMode = .both
            fade.isRemovedOnCompletion = false
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            shape.add(fade, forKey: "fadeIn")

            // Final model value so the element stays visible after the animation.
            shape.opacity = 1
        }
    }

    /// Total time for the full reveal to complete, useful for sequencing transitions.
    func revealDuration(elementDuration: TimeInterval = 0.8,
                        stagger: TimeInterval = 0.09,
                        startDelay: TimeInterval = 0.0) -> TimeInterval {
        startDelay + Double(max(elementLayers.count - 1, 0)) * stagger + elementDuration
    }

    /// Fades in groups of elements one phase after another. Each subsequent group
    /// begins `groupStagger` after the previous one started, and within a group the
    /// elements fade in one after another (left-to-right, in the order listed) using
    /// `elementStagger` so each phase keeps the original sweeping fade-in feel.
    /// - Parameters:
    ///   - groups: ordered groups of element indices to reveal in turn.
    ///   - groupDuration: how long each individual element takes to fade in.
    ///   - groupStagger: delay between the start of consecutive groups.
    ///   - elementStagger: delay between consecutive elements within a group.
    ///   - startDelay: delay before the first group begins.
    func animateGroupedReveal(groups: [[Int]],
                              groupDuration: TimeInterval = 1.0,
                              groupStagger: TimeInterval = 0.8,
                              elementStagger: TimeInterval = 0.12,
                              startDelay: TimeInterval = 0.0) {
        // Ensure paths are laid out before animating.
        layoutIfNeeded()

        // Disable implicit layer actions so setting the model opacity doesn't kick
        // off its own fade — otherwise the elements flash fully visible for a frame
        // before our explicit staggered animation takes over.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let start = CACurrentMediaTime() + startDelay
        for (groupIndex, group) in groups.enumerated() {
            let groupBegin = start + Double(groupIndex) * groupStagger
            for (positionInGroup, elementIndex) in group.enumerated() {
                guard elementLayers.indices.contains(elementIndex) else { continue }
                let shape = elementLayers[elementIndex]

                // Hold invisible until the explicit animation begins.
                shape.opacity = 0

                let fade = CABasicAnimation(keyPath: "opacity")
                fade.fromValue = 0
                fade.toValue = 1
                fade.duration = groupDuration
                fade.beginTime = groupBegin + Double(positionInGroup) * elementStagger
                fade.fillMode = .both
                fade.isRemovedOnCompletion = false
                fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                shape.add(fade, forKey: "fadeIn")

                // Final model value so the element stays visible afterwards.
                shape.opacity = 1
            }
        }

        CATransaction.commit()
    }

    /// Total time for a grouped reveal to complete.
    func groupedRevealDuration(groupCount: Int,
                               groupDuration: TimeInterval = 1.0,
                               groupStagger: TimeInterval = 0.8,
                               startDelay: TimeInterval = 0.0) -> TimeInterval {
        startDelay + Double(max(groupCount - 1, 0)) * groupStagger + groupDuration
    }
}

// MARK: - SVG Path Parsing

/// Minimal SVG path-data (`d` attribute) parser that produces a `CGPath`.
/// Supports the command set used by the Cosmic Fit logo artwork:
/// M/m, L/l, H/h, V/v, C/c, S/s, Q/q, T/t and Z/z (absolute and relative).
enum SVGPathParser {

    static func cgPath(from d: String) -> CGPath {
        let path = CGMutablePath()
        let chars = Array(d)
        var i = 0

        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?
        var command: Character?

        func skipSeparators() {
            while i < chars.count {
                let c = chars[i]
                if c == " " || c == "," || c == "\n" || c == "\t" || c == "\r" {
                    i += 1
                } else {
                    break
                }
            }
        }

        func readNumber() -> CGFloat? {
            skipSeparators()
            guard i < chars.count else { return nil }

            var s = ""
            if chars[i] == "+" || chars[i] == "-" {
                s.append(chars[i]); i += 1
            }

            var hasDot = false
            var hasDigits = false
            while i < chars.count {
                let c = chars[i]
                if c >= "0" && c <= "9" {
                    s.append(c); i += 1; hasDigits = true
                } else if c == "." {
                    if hasDot { break } // a second dot starts a new number
                    hasDot = true; s.append(c); i += 1
                } else if c == "e" || c == "E" {
                    s.append(c); i += 1
                    if i < chars.count, chars[i] == "+" || chars[i] == "-" {
                        s.append(chars[i]); i += 1
                    }
                    while i < chars.count, chars[i] >= "0" && chars[i] <= "9" {
                        s.append(chars[i]); i += 1
                    }
                    break
                } else {
                    break
                }
            }

            guard hasDigits else { return nil }
            return CGFloat(Double(s) ?? 0)
        }

        func isCommandLetter(_ c: Character) -> Bool {
            "MmLlHhVvCcSsQqTtAaZz".contains(c)
        }

        while i < chars.count {
            skipSeparators()
            guard i < chars.count else { break }

            if isCommandLetter(chars[i]) {
                command = chars[i]
                i += 1
            } else if command == nil || command == "Z" || command == "z" {
                // Nothing to repeat (close commands consume no parameters):
                // bail out rather than loop forever.
                break
            }
            // Otherwise reuse the previous command (implicit repeat).

            guard let cmd = command else { break }

            let isRelative = cmd.isLowercase

            switch cmd {
            case "M", "m":
                guard let x = readNumber(), let y = readNumber() else { i = chars.count; break }
                var p = CGPoint(x: x, y: y)
                if isRelative { p.x += current.x; p.y += current.y }
                path.move(to: p)
                current = p
                subpathStart = p
                lastCubicControl = nil
                lastQuadControl = nil
                // Subsequent implicit pairs become line-to commands.
                command = isRelative ? "l" : "L"

            case "L", "l":
                guard let x = readNumber(), let y = readNumber() else { i = chars.count; break }
                var p = CGPoint(x: x, y: y)
                if isRelative { p.x += current.x; p.y += current.y }
                path.addLine(to: p)
                current = p
                lastCubicControl = nil
                lastQuadControl = nil

            case "H", "h":
                guard let x = readNumber() else { i = chars.count; break }
                var nx = x
                if isRelative { nx += current.x }
                let p = CGPoint(x: nx, y: current.y)
                path.addLine(to: p)
                current = p
                lastCubicControl = nil
                lastQuadControl = nil

            case "V", "v":
                guard let y = readNumber() else { i = chars.count; break }
                var ny = y
                if isRelative { ny += current.y }
                let p = CGPoint(x: current.x, y: ny)
                path.addLine(to: p)
                current = p
                lastCubicControl = nil
                lastQuadControl = nil

            case "C", "c":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { i = chars.count; break }
                var c1 = CGPoint(x: x1, y: y1)
                var c2 = CGPoint(x: x2, y: y2)
                var p = CGPoint(x: x, y: y)
                if isRelative {
                    c1.x += current.x; c1.y += current.y
                    c2.x += current.x; c2.y += current.y
                    p.x += current.x; p.y += current.y
                }
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p
                lastCubicControl = c2
                lastQuadControl = nil

            case "S", "s":
                guard let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { i = chars.count; break }
                var c2 = CGPoint(x: x2, y: y2)
                var p = CGPoint(x: x, y: y)
                if isRelative {
                    c2.x += current.x; c2.y += current.y
                    p.x += current.x; p.y += current.y
                }
                // First control point is the reflection of the previous cubic control.
                let c1: CGPoint
                if let last = lastCubicControl {
                    c1 = CGPoint(x: 2 * current.x - last.x, y: 2 * current.y - last.y)
                } else {
                    c1 = current
                }
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p
                lastCubicControl = c2
                lastQuadControl = nil

            case "Q", "q":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { i = chars.count; break }
                var c1 = CGPoint(x: x1, y: y1)
                var p = CGPoint(x: x, y: y)
                if isRelative {
                    c1.x += current.x; c1.y += current.y
                    p.x += current.x; p.y += current.y
                }
                path.addQuadCurve(to: p, control: c1)
                current = p
                lastQuadControl = c1
                lastCubicControl = nil

            case "T", "t":
                guard let x = readNumber(), let y = readNumber() else { i = chars.count; break }
                var p = CGPoint(x: x, y: y)
                if isRelative { p.x += current.x; p.y += current.y }
                let c1: CGPoint
                if let last = lastQuadControl {
                    c1 = CGPoint(x: 2 * current.x - last.x, y: 2 * current.y - last.y)
                } else {
                    c1 = current
                }
                path.addQuadCurve(to: p, control: c1)
                current = p
                lastQuadControl = c1
                lastCubicControl = nil

            case "Z", "z":
                path.closeSubpath()
                current = subpathStart
                lastCubicControl = nil
                lastQuadControl = nil

            default:
                // Unsupported command (e.g. arcs); stop to avoid an infinite loop.
                i = chars.count
            }
        }

        return path
    }
}
