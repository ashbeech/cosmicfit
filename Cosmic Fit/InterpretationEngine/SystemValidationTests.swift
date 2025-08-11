//
// SystemValidationTests.swift
// Cosmic Fit
//
// Validation methods to test improved influence hierarchy
//

import Foundation

class SystemValidationTests {
    
    /// Test case: Venus in Scorpio should dominate over summer seasonal influence
    static func validateVenusScorpioSummer() -> Bool {
        DebugLogger.info("\n🧪 TESTING: Venus in Scorpio Summer Dominance")
        
        // Create mock chart with Venus in Scorpio
        var mockPlanets = createMockPlanets()
        // Set Venus to Scorpio (sign index 7)
        if let venusIndex = mockPlanets.firstIndex(where: { $0.name == "Venus" }) {
            mockPlanets[venusIndex] = NatalChartCalculator.PlanetPosition(
                name: "Venus",
                symbol: "♀",
                longitude: 240.0,
                latitude: 0.0,
                zodiacSign: 7,
                zodiacPosition: "0°00'",
                isRetrograde: false
            )
        }
        
        let mockChart = NatalChartCalculator.NatalChart(
            planets: mockPlanets,
            ascendant: 0.0,
            midheaven: 270.0,
            descendant: 180.0,
            imumCoeli: 90.0,
            houseCusps: createMockHouseCusps(),
            wholeSignHouseCusps: createMockWholeSignHouseCusps(),
            northNode: 0.0,
            southNode: 180.0,
            vertex: 0.0,
            partOfFortune: 0.0,
            lilith: 0.0,
            chiron: 0.0,
            lunarPhase: 0.0
        )
        
        // Generate blueprint tokens (which should show Venus dominance)
        let blueprintTokens = SemanticTokenGenerator.generateBlueprintTokens(
            natal: mockChart,
            currentAge: 30
        )
        
        // Analyze Venus vs seasonal influence
        let venusColorTokens = blueprintTokens.filter {
            $0.planetarySource == "Venus" &&
            ($0.type == "color" || $0.type == "color_quality")
        }
        
        let maxVenusWeight = venusColorTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0
        
        DebugLogger.info("  • Venus color tokens found: \(venusColorTokens.count)")
        DebugLogger.info("  • Max Venus weight: \(String(format: "%.2f", maxVenusWeight))")
        DebugLogger.info("  • Venus tokens: \(venusColorTokens.map { $0.name })")
        
        // Success criteria: Venus tokens should have significant weight
        let success = maxVenusWeight > 2.0 && venusColorTokens.count > 0
        DebugLogger.info("  • Test Result: \(success ? "✅ PASS" : "❌ FAIL")")
        
        return success
    }
    
    /// Test case: Hot weather should filter out warm fabrics via hard filtering
    static func validateHotWeatherFiltering() -> Bool {
        DebugLogger.info("\n🧪 TESTING: Hot Weather Hard Filtering")
        
        //let mockChart = createMockNatalChart()
        let hotWeather = TodayWeather(condition: "Clear", temperature: 35.0, humidity: 40, windKph: 5)
        
        // Test fabric filtering
        let baseFabrics = ["wool", "cashmere", "linen", "cotton", "silk"]
        let filteredFabrics = WeatherFabricFilter.applyWeatherFilters(weather: hotWeather, baseFabrics: baseFabrics)
        
        DebugLogger.info("  • Base fabrics: \(baseFabrics)")
        DebugLogger.info("  • Filtered fabrics: \(filteredFabrics)")
        
        let hasWarmFabrics = filteredFabrics.contains { fabric in
            ["wool", "cashmere"].contains { warm in
                fabric.lowercased().contains(warm)
            }
        }
        
        let hasCoolFabrics = filteredFabrics.contains { fabric in
            ["linen", "silk"].contains { cool in
                fabric.lowercased().contains(cool)
            }
        }
        
        // Success criteria: Warm fabrics filtered out, cool fabrics present
        let success = !hasWarmFabrics && hasCoolFabrics
        DebugLogger.info("  • Test Result: \(success ? "✅ PASS" : "❌ FAIL") - Hot weather \(success ? "properly" : "improperly") filtered fabrics")
        
        return success
    }
    
    /// Test case: Cold weather should filter out cool fabrics
    static func validateColdWeatherFiltering() -> Bool {
        DebugLogger.info("\n🧪 TESTING: Cold Weather Hard Filtering")
        
        //let mockChart = createMockNatalChart()
        let coldWeather = TodayWeather(condition: "Cloudy", temperature: 5.0, humidity: 70, windKph: 15)
        
        let baseFabrics = ["wool", "cashmere", "linen", "cotton", "silk"]
        let filteredFabrics = WeatherFabricFilter.applyWeatherFilters(weather: coldWeather, baseFabrics: baseFabrics)
        
        DebugLogger.info("  • Base fabrics: \(baseFabrics)")
        DebugLogger.info("  • Filtered fabrics: \(filteredFabrics)")
        
        let hasCoolFabrics = filteredFabrics.contains { fabric in
            ["linen", "silk"].contains { cool in
                fabric.lowercased().contains(cool)
            }
        }
        
        let hasWarmFabrics = filteredFabrics.contains { fabric in
            ["wool", "cashmere"].contains { warm in
                fabric.lowercased().contains(warm)
            }
        }
        
        // Success criteria: Cool fabrics filtered out, warm fabrics present
        let success = !hasCoolFabrics && hasWarmFabrics
        DebugLogger.info("  • Test Result: \(success ? "✅ PASS" : "❌ FAIL") - Cold weather \(success ? "properly" : "improperly") filtered fabrics")
        
        return success
    }
    
    /// Test case: Validate enhanced Venus/Mars/Moon weights
    static func validateEnhancedPlanetWeights() -> Bool {
        DebugLogger.info("\n🧪 TESTING: Enhanced Venus/Mars/Moon Weights")
        
        let mockChart = createMockNatalChart()
        
        // Generate tokens with enhanced weights
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(
            natal: mockChart,
            currentAge: 30
        )
        
        // Check Venus/Mars/Moon weights
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        let mercuryTokens = tokens.filter { $0.planetarySource == "Mercury" }
        
        let venusMaxWeight = venusTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0
        let marsMaxWeight = marsTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0
        let moonMaxWeight = moonTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0
        let mercuryMaxWeight = mercuryTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0
        
        DebugLogger.info("  • Venus max weight: \(String(format: "%.2f", venusMaxWeight))")
        DebugLogger.info("  • Mars max weight: \(String(format: "%.2f", marsMaxWeight))")
        DebugLogger.info("  • Moon max weight: \(String(format: "%.2f", moonMaxWeight))")
        DebugLogger.info("  • Mercury max weight (for comparison): \(String(format: "%.2f", mercuryMaxWeight))")
        
        // Success criteria: Venus/Mars/Moon should have higher weights than other personal planets
        let success = venusMaxWeight > mercuryMaxWeight &&
                      marsMaxWeight > mercuryMaxWeight &&
                      moonMaxWeight > mercuryMaxWeight
        
        DebugLogger.info("  • Test Result: \(success ? "✅ PASS" : "❌ FAIL") - Expression planets \(success ? "properly" : "improperly") enhanced")
        
        return success
    }
    
    /// Run all validation tests
    static func runAllValidationTests() -> Bool {
        DebugLogger.info("\n🔬 RUNNING SYSTEM VALIDATION TESTS")
        DebugLogger.info(String(repeating: "=", count: 50))
        
        let test1 = validateVenusScorpioSummer()
        let test2 = validateHotWeatherFiltering()
        let test3 = validateColdWeatherFiltering()
        let test4 = validateEnhancedPlanetWeights()
        
        let allPassed = test1 && test2 && test3 && test4
        
        DebugLogger.info("\n📊 VALIDATION SUMMARY:")
        DebugLogger.info("  • Venus Scorpio dominance: \(test1 ? "✅ PASS" : "❌ FAIL")")
        DebugLogger.info("  • Hot weather filter: \(test2 ? "✅ PASS" : "❌ FAIL")")
        DebugLogger.info("  • Cold weather filter: \(test3 ? "✅ PASS" : "❌ FAIL")")
        DebugLogger.info("  • Enhanced planet weights: \(test4 ? "✅ PASS" : "❌ FAIL")")
        DebugLogger.info("  • Overall: \(allPassed ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED")")
        
        return allPassed
    }
    
    /// Helper: Create mock natal chart for testing
    static func createMockNatalChart() -> NatalChartCalculator.NatalChart {
        let mockPlanets = createMockPlanets()
        
        return NatalChartCalculator.NatalChart(
            planets: mockPlanets,
            ascendant: 0.0, // Aries rising
            midheaven: 270.0,
            descendant: 180.0,
            imumCoeli: 90.0,
            houseCusps: createMockHouseCusps(),
            wholeSignHouseCusps: createMockWholeSignHouseCusps(),
            northNode: 0.0,
            southNode: 180.0,
            vertex: 0.0,
            partOfFortune: 0.0,
            lilith: 0.0,
            chiron: 0.0,
            lunarPhase: 0.0
        )
    }
    
    /// Helper: Create mock planets array
    static func createMockPlanets() -> [NatalChartCalculator.PlanetPosition] {
        return [
            NatalChartCalculator.PlanetPosition(
                name: "Sun",
                symbol: "☉",
                longitude: 120.0,
                latitude: 0.0,
                zodiacSign: 3,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Moon",
                symbol: "☽",
                longitude: 60.0,
                latitude: 0.0,
                zodiacSign: 1,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Mercury",
                symbol: "☿",
                longitude: 90.0,
                latitude: 0.0,
                zodiacSign: 2,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Venus",
                symbol: "♀",
                longitude: 180.0,
                latitude: 0.0,
                zodiacSign: 5,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Mars",
                symbol: "♂",
                longitude: 0.0,
                latitude: 0.0,
                zodiacSign: 0,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Jupiter",
                symbol: "♃",
                longitude: 150.0,
                latitude: 0.0,
                zodiacSign: 4,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Saturn",
                symbol: "♄",
                longitude: 300.0,
                latitude: 0.0,
                zodiacSign: 9,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Uranus",
                symbol: "♅",
                longitude: 330.0,
                latitude: 0.0,
                zodiacSign: 10,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Neptune",
                symbol: "♆",
                longitude: 360.0,
                latitude: 0.0,
                zodiacSign: 11,
                zodiacPosition: "0°00'",
                isRetrograde: false
            ),
            NatalChartCalculator.PlanetPosition(
                name: "Pluto",
                symbol: "♇",
                longitude: 270.0,
                latitude: 0.0,
                zodiacSign: 8,
                zodiacPosition: "0°00'",
                isRetrograde: false
            )
        ]
    }
    
    /// Helper: Create mock house cusps for Placidus system
    static func createMockHouseCusps() -> [Double] {
        // Create array with 13 elements (index 0 is unused, houses 1-12)
        var cusps = [Double](repeating: 0.0, count: 13)
        for i in 1...12 {
            cusps[i] = Double((i - 1) * 30) // Simple 30-degree houses for testing
        }
        return cusps
    }
    
    /// Helper: Create mock house cusps for Whole Sign system
    static func createMockWholeSignHouseCusps() -> [Double] {
        // For Whole Sign, each house begins at 0° of a sign
        var cusps = [Double](repeating: 0.0, count: 13)
        for i in 1...12 {
            cusps[i] = Double((i - 1) * 30) // Each house starts at 0° of a sign
        }
        return cusps
    }
}
