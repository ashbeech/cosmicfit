//
//  TarotCardValidator.swift
//  Cosmic Fit
//
//  Created by AI Assistant on 12/05/2025.
//  Validation and debugging for Tarot card JSON
//

import Foundation

/// Validation utility for debugging Tarot card JSON issues
class TarotCardValidator {
    
    /// Validate the JSON file structure and content
    static func validateJSONFile() {
        print("\n🔍 TAROT JSON VALIDATION 🔍")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Step 1: Check if file exists in bundle
        guard let url = Bundle.main.url(forResource: "TarotCards", withExtension: "json") else {
            print("❌ TarotCards.json not found in app bundle")
            
            // List available resources
            if let bundlePath = Bundle.main.resourcePath {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                    let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                    print("Available JSON files: \(jsonFiles)")
                } catch {
                    print("Could not list bundle contents: \(error)")
                }
            }
            return
        }
        
        print("✅ Found TarotCards.json at: \(url.path)")
        
        // Step 2: Read raw data
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Could not read data from JSON file")
            return
        }
        
        print("✅ Read \(data.count) bytes from JSON file")
        
        // Step 3: Parse as raw JSON first
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let array = json as? [[String: Any]] {
                print("✅ JSON is valid array with \(array.count) objects")
                
                // Check first card structure
                if let firstCard = array.first {
                    print("\n🃏 First card structure:")
                    for (key, value) in firstCard {
                        print("  \(key): \(type(of: value)) = \(value)")
                    }
                    
                    // Specifically check problematic fields
                    if let arcana = firstCard["arcana"] as? String {
                        print("✅ Arcana field: '\(arcana)'")
                    } else {
                        print("❌ Arcana field missing or wrong type")
                    }
                    
                    if let suit = firstCard["suit"] {
                        print("✅ Suit field: \(suit) (\(type(of: suit)))")
                    } else {
                        print("❌ Suit field missing")
                    }
                }
            } else {
                print("❌ JSON is not an array")
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            return
        }
        
        // Step 4: Try decoding with Swift's JSONDecoder
        do {
            let decoder = JSONDecoder()
            let cards = try decoder.decode([TarotCard].self, from: data)
            print("✅ Successfully decoded \(cards.count) Tarot cards")
            
            // Show some example cards
            let majorCount = cards.filter { $0.arcana == .major }.count
            let minorCount = cards.filter { $0.arcana == .minor }.count
            print("  • Major Arcana: \(majorCount)")
            print("  • Minor Arcana: \(minorCount)")
            
            if let firstMajor = cards.first(where: { $0.arcana == .major }) {
                print("  • First Major: \(firstMajor.displayName)")
            }
            
            if let firstMinor = cards.first(where: { $0.arcana == .minor }) {
                print("  • First Minor: \(firstMinor.displayName) of \(firstMinor.suit?.rawValue ?? "Unknown")")
            }
            
        } catch let decodingError as DecodingError {
            print("❌ Swift decoding error: \(decodingError)")
            
            // Detailed error analysis
            switch decodingError {
            case .dataCorrupted(let context):
                print("  Data corrupted at: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                print("  Description: \(context.debugDescription)")
                
            case .keyNotFound(let key, let context):
                print("  Key '\(key.stringValue)' not found at: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                print("  Description: \(context.debugDescription)")
                
            case .typeMismatch(let type, let context):
                print("  Type mismatch for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                print("  Description: \(context.debugDescription)")
                
            case .valueNotFound(let type, let context):
                print("  Value not found for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                print("  Description: \(context.debugDescription)")
                
            @unknown default:
                print("  Unknown decoding error")
            }
        } catch {
            print("❌ Other error: \(error)")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// Test decoding a single card manually
    static func testSingleCardDecoding() {
        let sampleCard = """
        {
          "name": "The Fool",
          "arcana": "Major",
          "suit": null,
          "number": null,
          "keywords": ["spontaneous", "adventurous"],
          "themes": ["Fresh Start"],
          "energyAffinity": {
            "playful": 0.9,
            "classic": 0.2
          },
          "description": "Test card",
          "reversedKeywords": ["reckless"],
          "symbolism": ["cliff"]
        }
        """
        
        print("🧪 Testing single card decoding...")
        
        guard let data = sampleCard.data(using: .utf8) else {
            print("❌ Could not create data from sample")
            return
        }
        
        do {
            let card = try JSONDecoder().decode(TarotCard.self, from: data)
            print("✅ Successfully decoded sample card: \(card.displayName)")
        } catch {
            print("❌ Failed to decode sample card: \(error)")
        }
    }
}
