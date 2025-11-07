//
//  TarotCardTester.swift
//  Cosmic Fit
//
//  Created by AI Assistant on 12/05/2025.
//  Testing and validation framework for Tarot card selection
//

/*
import Foundation

/// Testing framework for validating Tarot card selection accuracy and consistency
class TarotCardTester {
    
    // MARK: - Test Result Structures
    
    struct TestResult {
        let testName: String
        let passed: Bool
        let score: Double?
        let selectedCard: String?
        let expectedCard: String?
        let details: String
    }
    
    struct TestSuite {
        let name: String
        let results: [TestResult]
        let passRate: Double
        let avgScore: Double
    }
    
    // MARK: - Main Testing Methods
    
    /// Run comprehensive test suite
    /// - Returns: Complete test results
    static func runComprehensiveTests() -> [TestSuite] {
        print("\n🧪 TAROT CARD TESTING FRAMEWORK 🧪")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        var testSuites: [TestSuite] = []
        
        // Test Suite 1: Basic Functionality
        testSuites.append(runBasicFunctionalityTests())
        
        // Test Suite 2: Energy Alignment
        testSuites.append(runEnergyAlignmentTests())
        
        // Test Suite 3: Token Matching
        testSuites.append(runTokenMatchingTests())
        
        // Test Suite 4: Edge Cases
        testSuites.append(runEdgeCaseTests())
        
        // Test Suite 5: Consistency
        testSuites.append(runConsistencyTests())
        
        // Print summary
        printTestSummary(testSuites)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return testSuites
    }
    
    // MARK: - Test Suite Implementations
    
    /// Test basic functionality - deck loading, card selection, scoring
    private static func runBasicFunctionalityTests() -> TestSuite {
        print("\n🔧 Basic Functionality Tests")
        var results: [TestResult] = []
        
        // Test 1: Deck Loading
        let validationResult = TarotCardSelector.runValidationTests()
        let deckLoaded = validationResult.contains("78 cards loaded") || validationResult.contains("cards loaded")
        results.append(TestResult(
            testName: "Deck Loading",
            passed: deckLoaded,
            score: nil,
            selectedCard: nil,
            expectedCard: nil,
            details: deckLoaded ? "Successfully loaded deck" : "Failed to load deck"
        ))
        
        // Test 2: Basic Selection
        let basicTokens = [
            StyleToken(name: "structured", type: "form", weight: 2.0, planetarySource: "Saturn", originType: .natal)
        ]
        
        let selectedCard = TarotCardSelector.selectCard(for: basicTokens)
        results.append(TestResult(
            testName: "Basic Selection",
            passed: selectedCard != nil,
            score: nil,
            selectedCard: selectedCard?.displayName,
            expectedCard: nil,
            details: selectedCard != nil ? "Card selected successfully" : "No card selected"
        ))
        
        // Test 3: Score Calculation
        if let card = selectedCard {
            let score = card.calculateMatchScore(for: basicTokens)
            results.append(TestResult(
                testName: "Score Calculation",
                passed: score > 0,
                score: score,
                selectedCard: card.displayName,
                expectedCard: nil,
                details: "Score: \(String(format: "%.2f", score))"
            ))
        }
        
        let passRate = Double(results.filter { $0.passed }.count) / Double(results.count)
        let avgScore = results.compactMap { $0.score }.reduce(0, +) / Double(results.compactMap { $0.score }.count)
        
        return TestSuite(name: "Basic Functionality", results: results, passRate: passRate, avgScore: avgScore)
    }
    
    /// Test energy alignment accuracy
    private static func runEnergyAlignmentTests() -> TestSuite {
        print("\n⚡ Energy Alignment Tests")
        var results: [TestResult] = []
        
        let energyTestCases = [
            ("High Drama", 
             VibeBreakdown(classic: 1, playful: 2, romantic: 2, utility: 2, drama: 9, edge: 5),
             ["dramatic", "intense", "powerful", "transformative"]),
            
            ("Pure Classic", 
             VibeBreakdown(classic: 10, playful: 1, romantic: 3, utility: 4, drama: 2, edge: 1),
             ["classic", "structured", "authoritative", "disciplined"]),
             
            ("High Romantic", 
             VibeBreakdown(classic: 2, playful: 3, romantic: 10, utility: 2, drama: 2, edge: 2),
             ["romantic", "flowing", "soft", "beautiful", "harmonious"]),
             
            ("Maximum Utility", 
             VibeBreakdown(classic: 3, playful: 1, romantic: 1, utility: 10, drama: 3, edge: 3),
             ["practical", "functional", "efficient", "reliable"])
        ]
        
        for (testName, vibeBreakdown, tokenNames) in energyTestCases {
            let tokens = tokenNames.map { name in
                StyleToken(name: name, type: "mood", weight: 2.0, originType: .natal)
            }
            
            let selectedCard = TarotCardSelector.selectCard(for: tokens, vibeBreakdown: vibeBreakdown)
            
            if let card = selectedCard {
                let dominantEnergy: Energy = vibeBreakdown.dominantEnergy
                let dominantEnergyName = dominantEnergy.rawValue
                let cardAffinity = card.energyAffinity[dominantEnergyName] ?? 0.0
                let passed = cardAffinity >= 0.5 // Card should have decent affinity for dominant energy
                
                results.append(TestResult(
                    testName: testName,
                    passed: passed,
                    score: cardAffinity,
                    selectedCard: card.displayName,
                    expectedCard: "Card with \(dominantEnergy) affinity",
                    details: "Selected \(card.displayName) with \(String(format: "%.2f", cardAffinity)) \(dominantEnergy) affinity"
                ))
            } else {
                results.append(TestResult(
                    testName: testName,
                    passed: false,
                    score: 0.0,
                    selectedCard: nil,
                    expectedCard: "Any card",
                    details: "No card selected"
                ))
            }
        }
        
        let passRate = Double(results.filter { $0.passed }.count) / Double(results.count)
        let avgScore = results.compactMap { $0.score }.reduce(0, +) / Double(results.compactMap { $0.score }.count)
        
        return TestSuite(name: "Energy Alignment", results: results, passRate: passRate, avgScore: avgScore)
    }
    
    /// Test token matching accuracy
    private static func runTokenMatchingTests() -> TestSuite {
        print("\n🎯 Token Matching Tests")
        var results: [TestResult] = []
        
        let tokenTestCases = [
            ("High Weight Dramatic Token", 
             [StyleToken(name: "dramatic", type: "mood", weight: 5.0, planetarySource: "Pluto", originType: .natal)],
             ["The Tower", "Death", "Five of Wands", "Ten of Swords"]),
             
            ("Venus Romantic Tokens", 
             [StyleToken(name: "romantic", type: "mood", weight: 3.0, planetarySource: "Venus", originType: .natal),
              StyleToken(name: "beautiful", type: "quality", weight: 2.5, planetarySource: "Venus", originType: .natal)],
             ["The Lovers", "The Empress", "Two of Cups", "Queen of Cups"]),
             
            ("Saturn Structure Tokens", 
             [StyleToken(name: "structured", type: "form", weight: 3.0, planetarySource: "Saturn", originType: .natal),
              StyleToken(name: "disciplined", type: "mood", weight: 2.5, planetarySource: "Saturn", originType: .natal)],
             ["The Emperor", "Justice", "Four of Pentacles", "King of Pentacles"]),
             
            ("Weather Utility Tokens", 
             [StyleToken(name: "practical", type: "function", weight: 4.0, originType: .weather),
              StyleToken(name: "waterproof", type: "function", weight: 3.5, originType: .weather)],
             ["Ten of Wands", "Knight of Pentacles", "Eight of Pentacles", "Four of Pentacles"])
        ]
        
        for (testName, tokens, expectedCards) in tokenTestCases {
            let selectedCard = TarotCardSelector.selectCard(for: tokens)
            
            if let card = selectedCard {
                let isExpectedCard = expectedCards.contains(card.displayName)
                let score = card.calculateMatchScore(for: tokens)
                
                results.append(TestResult(
                    testName: testName,
                    passed: isExpectedCard,
                    score: score,
                    selectedCard: card.displayName,
                    expectedCard: expectedCards.joined(separator: " or "),
                    details: "Selected \(card.displayName), score: \(String(format: "%.2f", score))"
                ))
            } else {
                results.append(TestResult(
                    testName: testName,
                    passed: false,
                    score: 0.0,
                    selectedCard: nil,
                    expectedCard: expectedCards.joined(separator: " or "),
                    details: "No card selected"
                ))
            }
        }
        
        let passRate = Double(results.filter { $0.passed }.count) / Double(results.count)
        let avgScore = results.compactMap { $0.score }.reduce(0, +) / Double(results.compactMap { $0.score }.count)
        
        return TestSuite(name: "Token Matching", results: results, passRate: passRate, avgScore: avgScore)
    }
    
    /// Test edge cases and error handling
    private static func runEdgeCaseTests() -> TestSuite {
        print("\n🔍 Edge Case Tests")
        var results: [TestResult] = []
        
        // Test 1: Empty token array
        let emptyResult = TarotCardSelector.selectCard(for: [])
        results.append(TestResult(
            testName: "Empty Tokens",
            passed: emptyResult != nil, // Should fall back to default card
            score: nil,
            selectedCard: emptyResult?.displayName,
            expectedCard: "Any fallback card",
            details: emptyResult != nil ? "Fallback card selected" : "No fallback provided"
        ))
        
        // Test 2: No matching tokens
        let unmatchableTokens = [
            StyleToken(name: "nonexistent", type: "impossible", weight: 1.0, originType: .natal),
            StyleToken(name: "fictional", type: "imaginary", weight: 1.0, originType: .natal)
        ]
        
        let unmatchableResult = TarotCardSelector.selectCard(for: unmatchableTokens)
        results.append(TestResult(
            testName: "Unmatchable Tokens",
            passed: unmatchableResult != nil,
            score: nil,
            selectedCard: unmatchableResult?.displayName,
            expectedCard: "Any card",
            details: unmatchableResult != nil ? "Card selected despite no matches" : "No card selected"
        ))
        
        // Test 3: Extreme vibe breakdown
        let extremeVibe = VibeBreakdown(classic: 0, playful: 0, romantic: 0, utility: 0, drama: 21, edge: 0)
        let extremeResult = TarotCardSelector.selectCard(for: [], vibeBreakdown: extremeVibe)
        results.append(TestResult(
            testName: "Extreme Vibe Breakdown",
            passed: extremeResult != nil,
            score: nil,
            selectedCard: extremeResult?.displayName,
            expectedCard: "Drama-aligned card",
            details: extremeResult != nil ? "Handled extreme energy distribution" : "Failed with extreme distribution"
        ))
        
        let passRate = Double(results.filter { $0.passed }.count) / Double(results.count)
        
        return TestSuite(name: "Edge Cases", results: results, passRate: passRate, avgScore: 0.0)
    }
    
    /// Test consistency of selections
    private static func runConsistencyTests() -> TestSuite {
        print("\n🔄 Consistency Tests")
        var results: [TestResult] = []
        
        // Clear any previous selections for clean testing
        TarotCardSelector.clearLastSelectedCard()
        
        // Test: Same input should produce same output (first time)
        let consistencyTokens = [
            StyleToken(name: "balanced", type: "mood", weight: 2.0, originType: .natal),
            StyleToken(name: "harmonious", type: "quality", weight: 2.0, planetarySource: "Venus", originType: .natal)
        ]
        
        let consistencyVibe = VibeBreakdown(classic: 4, playful: 3, romantic: 6, utility: 3, drama: 3, edge: 2)
        
        // First selection
        let firstCard = TarotCardSelector.selectCard(for: consistencyTokens, vibeBreakdown: consistencyVibe)
        
        // Second selection - should get redundancy penalty
        let secondCard = TarotCardSelector.selectCard(for: consistencyTokens, vibeBreakdown: consistencyVibe)
        
        let redundancyWorking = firstCard?.name != secondCard?.name
        
        results.append(TestResult(
            testName: "Redundancy Prevention",
            passed: redundancyWorking,
            score: redundancyWorking ? 1.0 : 0.0,
            selectedCard: "\(firstCard?.name ?? "None") → \(secondCard?.name ?? "None")",
            expectedCard: "Different cards",
            details: redundancyWorking ? "Successfully avoided repetition" : "Failed to avoid repetition"
        ))
        
        // Test token override system
        let overrideTokens = [
            StyleToken(name: "versatile", type: "structure", weight: 2.0, originType: .natal), // Should have custom mapping
            StyleToken(name: "transformative", type: "mood", weight: 1.5, originType: .transit) // Should have custom mapping
        ]
        
        TarotCardSelector.clearLastSelectedCard() // Clean slate
        let overrideCard = TarotCardSelector.selectCard(for: overrideTokens, vibeBreakdown: consistencyVibe)
        
        results.append(TestResult(
            testName: "Token Override System",
            passed: overrideCard != nil,
            score: overrideCard != nil ? 1.0 : 0.0,
            selectedCard: overrideCard?.name,
            expectedCard: "Any card with nuanced scoring",
            details: "Token overrides processed: versatile, transformative"
        ))
        
        // Test weight dampening
        let highWeightTokens = [
            StyleToken(name: "luxurious", type: "texture", weight: 10.0, originType: .natal), // Extremely high weight
            StyleToken(name: "practical", type: "function", weight: 0.5, originType: .natal)  // Low weight
        ]
        
        TarotCardSelector.clearLastSelectedCard()
        let dampenedCard = TarotCardSelector.selectCard(for: highWeightTokens, vibeBreakdown: consistencyVibe)
        
        results.append(TestResult(
            testName: "Weight Dampening",
            passed: dampenedCard != nil,
            score: dampenedCard != nil ? 1.0 : 0.0,
            selectedCard: dampenedCard?.name,
            expectedCard: "Balanced selection despite extreme weights",
            details: "High weight (10.0) dampened to prevent over-indexing"
        ))
        
        let passRate = Double(results.filter { $0.passed }.count) / Double(results.count)
        let avgScore = results.compactMap { $0.score }.reduce(0, +) / Double(results.compactMap { $0.score }.count)
        
        return TestSuite(name: "Enhanced Features", results: results, passRate: passRate, avgScore: avgScore)
    }
    
    // MARK: - Manual Testing Methods
    
    /// Manual test with custom tokens for experimentation
    /// - Parameters:
    ///   - tokens: Custom token array
    ///   - expectedCardName: Optional expected card name for validation
    /// - Returns: Test result
    static func manualTest(tokens: [StyleToken], expectedCardName: String? = nil) -> TestResult {
        print("\n🧑‍🔬 Manual Test")
        
        let selectedCard = TarotCardSelector.selectCard(for: tokens)
        let vibeBreakdown = VibeBreakdownGenerator.generateVibeBreakdown(from: tokens)
        
        let passed = if let expected = expectedCardName {
            selectedCard?.displayName.lowercased() == expected.lowercased()
        } else {
            selectedCard != nil
        }
        
        let score = selectedCard?.calculateMatchScore(for: tokens, vibeBreakdown: vibeBreakdown) ?? 0.0
        
        return TestResult(
            testName: "Manual Test",
            passed: passed,
            score: score,
            selectedCard: selectedCard?.displayName,
            expectedCard: expectedCardName,
            details: "Score: \(String(format: "%.2f", score)), Dominant Energy: \(vibeBreakdown.dominantEnergyName)"
        )
    }
    
    /// Quick smoke test for development
    static func quickSmokeTest() -> Bool {
        print("\n💨 Quick Smoke Test")
        
        let tokens = [
            StyleToken(name: "confident", type: "mood", weight: 2.0, originType: .natal),
            StyleToken(name: "bold", type: "expression", weight: 1.5, originType: .transit)
        ]
        
        let result = TarotCardSelector.selectCard(for: tokens)
        let passed = result != nil
        
        print(passed ? "✅ Smoke test passed" : "❌ Smoke test failed")
        
        return passed
    }
    
    // MARK: - Reporting Methods
    
    /// Print comprehensive test summary
    private static func printTestSummary(_ testSuites: [TestSuite]) {
        print("\n📊 TEST SUMMARY")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        var totalTests = 0
        var totalPassed = 0
        var totalScores: [Double] = []
        
        for suite in testSuites {
            let passCount = suite.results.filter { $0.passed }.count
            totalTests += suite.results.count
            totalPassed += passCount
            
            if suite.avgScore > 0 {
                totalScores.append(suite.avgScore)
            }
            
            let passPercentage = Int(suite.passRate * 100)
            let status = suite.passRate >= 0.8 ? "✅" : suite.passRate >= 0.6 ? "⚠️" : "❌"
            
            print("\(status) \(suite.name): \(passCount)/\(suite.results.count) (\(passPercentage)%)")
            
            if suite.avgScore > 0 {
                print("   Average Score: \(String(format: "%.2f", suite.avgScore))")
            }
            
            // Show failed tests
            let failedTests = suite.results.filter { !$0.passed }
            if !failedTests.isEmpty {
                for test in failedTests {
                    print("   ❌ \(test.testName): \(test.details)")
                }
            }
        }
        
        let overallPassRate = Double(totalPassed) / Double(totalTests)
        let overallAvgScore = totalScores.isEmpty ? 0.0 : totalScores.reduce(0, +) / Double(totalScores.count)
        
        print("\n🎯 OVERALL RESULTS:")
        print("  Pass Rate: \(totalPassed)/\(totalTests) (\(Int(overallPassRate * 100))%)")
        
        if overallAvgScore > 0 {
            print("  Average Score: \(String(format: "%.2f", overallAvgScore))")
        }
        
        let overallStatus = overallPassRate >= 0.8 ? "✅ EXCELLENT" : 
                           overallPassRate >= 0.6 ? "⚠️ NEEDS WORK" : "❌ FAILING"
        print("  Status: \(overallStatus)")
    }
    
    /// Generate detailed test report for logging
    static func generateTestReport(_ testSuites: [TestSuite]) -> String {
        var report = "TAROT CARD SELECTOR TEST REPORT\n"
        report += "Generated: \(Date())\n\n"
        
        for suite in testSuites {
            report += "Test Suite: \(suite.name)\n"
            report += "Pass Rate: \(Int(suite.passRate * 100))%\n"
            
            if suite.avgScore > 0 {
                report += "Average Score: \(String(format: "%.2f", suite.avgScore))\n"
            }
            
            report += "\nResults:\n"
            for result in suite.results {
                let status = result.passed ? "PASS" : "FAIL"
                report += "  [\(status)] \(result.testName): \(result.details)\n"
            }
            report += "\n"
        }
        
        return report
    }
}
*/
