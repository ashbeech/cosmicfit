import Foundation

enum FamilyProfiles {

    static let canonical: [PaletteFamily: DerivedVariables] = [
        .lightSpring: DerivedVariables(depth: .light, temperature: .warm, saturation: .rich, contrast: .medium, surface: .soft),
        .trueSpring: DerivedVariables(depth: .medium, temperature: .warm, saturation: .rich, contrast: .medium, surface: .balanced),
        .brightSpring: DerivedVariables(depth: .medium, temperature: .neutral, saturation: .rich, contrast: .high, surface: .structured),
        .lightSummer: DerivedVariables(depth: .light, temperature: .cool, saturation: .soft, contrast: .low, surface: .soft),
        .trueSummer: DerivedVariables(depth: .medium, temperature: .cool, saturation: .soft, contrast: .low, surface: .soft),
        .softSummer: DerivedVariables(depth: .medium, temperature: .cool, saturation: .muted, contrast: .low, surface: .soft),
        .softAutumn: DerivedVariables(depth: .medium, temperature: .warm, saturation: .muted, contrast: .low, surface: .balanced),
        .trueAutumn: DerivedVariables(depth: .medium, temperature: .warm, saturation: .rich, contrast: .medium, surface: .balanced),
        .deepAutumn: DerivedVariables(depth: .deep, temperature: .warm, saturation: .rich, contrast: .medium, surface: .structured),
        .deepWinter: DerivedVariables(depth: .deep, temperature: .cool, saturation: .rich, contrast: .medium, surface: .structured),
        .trueWinter: DerivedVariables(depth: .deep, temperature: .cool, saturation: .rich, contrast: .high, surface: .structured),
        .brightWinter: DerivedVariables(depth: .deep, temperature: .cool, saturation: .rich, contrast: .high, surface: .structured),
    ]

    static func variables(for family: PaletteFamily) -> DerivedVariables {
        canonical[family]!
    }
}
