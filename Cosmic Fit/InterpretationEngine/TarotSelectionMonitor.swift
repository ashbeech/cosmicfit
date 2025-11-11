//
//  TarotSelectionMonitor.swift
//  Cosmic Fit
//
//  Monitor and log Tarot card selection patterns for variety analysis
//

import Foundation

/// Monitor and log Tarot card selection patterns for variety analysis
class TarotSelectionMonitor {
    
    /// Log detailed selection process for analysis
    static func logSelectionProcess(
        selectedCard: TarotCard,
        topCandidates: [(TarotCard, Double, Double, Double, Double)],
        axes: DerivedAxes,
        vibeBreakdown: VibeBreakdown?,
        date: Date
    ) {
        print("🃏 TAROT SELECTION ANALYSIS for \(date):")
        print("📊 Input Profile:")
        print("  Axes: A:\(String(format: "%.1f", axes.action)) T:\(String(format: "%.1f", axes.tempo)) S:\(String(format: "%.1f", axes.strategy)) V:\(String(format: "%.1f", axes.visibility))")
        
        if let vibes = vibeBreakdown {
            print("  Vibes: R:\(vibes.romantic) C:\(vibes.classic) P:\(vibes.playful) U:\(vibes.utility) D:\(vibes.drama) E:\(vibes.edge)")
        }
        
        print("🏆 Selected: \(selectedCard.displayName)")
        print("📈 Score Breakdown:")
        for (index, candidate) in topCandidates.prefix(5).enumerated() {
            let (card, total, axis, vibe, boost) = candidate
            let symbol = index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "🔸"
            print("  \(symbol) \(card.displayName): \(String(format: "%.1f", total)) (A:\(String(format: "%.1f", axis)) V:\(String(format: "%.1f", vibe)) B:\(String(format: "%.1f", boost)))")
        }
        
        // Calculate selection diversity metrics
        let selectedCardTypes = topCandidates.prefix(10).map { $0.0.arcana.rawValue }
        let typeVariety = Set(selectedCardTypes).count
        print("🎯 Selection Diversity: \(typeVariety)/10 different card types in top 10")
        
        if topCandidates.count > 1 {
            let scoreSpread = topCandidates[0].1 - topCandidates[min(4, topCandidates.count-1)].1
            print("📏 Score Spread: \(String(format: "%.1f", scoreSpread)) points (higher = more variety)")
        }
    }
    
    /// Track card selection over time for pattern detection
    static func trackSelectionPattern(card: TarotCard, profileId: String) {
        let key = "selection.history.\(profileId)"
        var history = UserDefaults.standard.stringArray(forKey: key) ?? []
        
        // Add current selection
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        history.append("\(dateString):\(card.displayName)")
        
        // Keep last 30 selections
        if history.count > 30 {
            history.removeFirst(history.count - 30)
        }
        
        UserDefaults.standard.set(history, forKey: key)
        
        // Log recent patterns
        let recentCards = history.suffix(7).map { entry in
            entry.components(separatedBy: ":").last ?? "Unknown"
        }
        let uniqueRecent = Set(recentCards).count
        print("📅 Recent Selection Pattern (last 7 days): \(uniqueRecent)/7 unique cards")
        if uniqueRecent < 5 {
            print("⚠️ LOW VARIETY WARNING: Only \(uniqueRecent) unique cards in last week")
        }
    }
}

