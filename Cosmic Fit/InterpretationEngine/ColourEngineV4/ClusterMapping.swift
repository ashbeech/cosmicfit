import Foundation

enum ClusterMapping {

    static func mapToCluster(
        variables: DerivedVariables,
        family: PaletteFamily
    ) -> PaletteCluster {
        let d = variables.depth
        let t = variables.temperature
        let s = variables.saturation
        let c = variables.contrast
        let sf = variables.surface

        if d == .light && t == .warm && s == .rich && c == .medium && sf == .soft {
            return .lightAiryWarm
        }
        if d == .light && t == .cool && s == .soft && c == .low && sf == .soft {
            return .lightAiryCool
        }
        if d == .medium && t == .warm && s == .rich && c == .medium
            && (sf == .balanced || sf == .soft)
            && (family == .trueSpring || family == .trueAutumn) {
            return .mediumWarmGrounded
        }
        if d == .medium && t == .warm && s == .muted && c == .low && sf == .balanced {
            return .mediumWarmMuted
        }
        if d == .medium && t == .neutral && s == .rich && c == .high && sf == .structured {
            return .mediumNeutralElectric
        }
        if d == .medium && t == .cool && s == .soft && c == .low && sf == .soft {
            return .mediumCoolSoft
        }
        if d == .medium && t == .cool && s == .muted && c == .low && sf == .soft {
            return .mediumCoolMuted
        }
        if d == .deep && (t == .warm || t == .neutral) && s == .rich && c == .medium
            && (sf == .structured || sf == .balanced) {
            return .deepWarmStructured
        }
        if d == .deep && t == .cool && s == .rich && c == .medium && sf == .structured {
            return .deepCoolControlled
        }
        if d == .deep && t == .cool && s == .rich && c == .high && sf == .structured {
            return .deepCoolHighContrast
        }

        return inferClusterFromFamily(family)
    }

    private static func inferClusterFromFamily(_ family: PaletteFamily) -> PaletteCluster {
        switch family {
        case .lightSpring: return .lightAiryWarm
        case .lightSummer: return .lightAiryCool
        case .trueSpring, .trueAutumn: return .mediumWarmGrounded
        case .brightSpring: return .mediumNeutralElectric
        case .trueSummer: return .mediumCoolSoft
        case .softSummer: return .mediumCoolMuted
        case .softAutumn: return .mediumWarmMuted
        case .deepAutumn: return .deepWarmStructured
        case .deepWinter: return .deepCoolControlled
        case .trueWinter, .brightWinter: return .deepCoolHighContrast
        }
    }
}
