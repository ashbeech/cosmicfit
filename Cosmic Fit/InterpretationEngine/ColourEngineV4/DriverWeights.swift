import Foundation

enum DriverWeights {

    static let weights: [DriverKey: Int] = [
        .ascendant: 24,
        .venus: 20,
        .sun: 16,
        .moon: 14,
        .mercury: 10,
        .mars: 8,
        .saturn: 5,
        .jupiter: 3,
    ]

    static let totalWeight: Int = 100

    static func weight(for key: DriverKey) -> Int {
        weights[key] ?? 0
    }
}
