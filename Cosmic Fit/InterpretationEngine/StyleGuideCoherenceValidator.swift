//
//  StyleGuideCoherenceValidator.swift
//  Cosmic Fit
//
//  SG-4 (Style Guide Quality Overhaul, Phase 4) — the Swift half of the
//  two-layer narrative validator.
//
//  Mirrors tools/sg_validation.py `validate_paragraph_gate` check-for-check.
//  Every rule constant loads from data/style_guide/style_guide_rules.json
//  (bundled via the Resources symlink) and the leak lexicons from
//  ranked_domain_tables.json, so the Python write gate and this validator
//  cannot drift on rule content. Structural constants that the frozen SG-2
//  injection contract fixes (placeholder vocabulary, section groups, required
//  placeholder families, leak-gated sections) are asserted equal to the
//  Python side by SG4ValidatorParityTests against sg4_parity_fixture.json —
//  regenerate that fixture (tools/sg4_parity_fixture.py) whenever the rules
//  or the Python gate change.
//

import Foundation

struct StyleGuideCoherenceValidator {

    // MARK: - Result types

    struct Finding: Equatable {
        let code: String
        let detail: String
    }

    struct GateResult {
        let errors: [Finding]
        let warnings: [Finding]
        var passed: Bool { errors.isEmpty }
        var errorCodes: [String] { errors.map(\.code).sorted() }
        var warningCodes: [String] { warnings.map(\.code).sorted() }
    }

    // MARK: - Section groups (frozen SG-2 contract; parity-asserted)

    static let groupASections: Set<String> = [
        "style_core",
        "occasions_work", "occasions_intimate", "occasions_daily",
        "accessory_1", "accessory_2", "accessory_3",
    ]

    static let groupBSections: Set<String> = NarrativeTemplateRenderer.groupBSections

    /// The frozen placeholder vocabulary — one Swift source of truth, shared
    /// with the renderer.
    static let allowedPlaceholders: Set<String> = NarrativeTemplateRenderer.allPlaceholders

    /// Which resolved-name lexicons must NOT appear literally per Group B
    /// section (mirrors sg_validation._LEAK_LEXICONS_BY_SECTION).
    private static let leakLexiconsBySection: [String: [String]] = [
        "palette_narrative": ["colours"],
        "textures_good": ["colours", "fibres"],
        "textures_bad": ["colours", "fibres"],
        "textures_sweet_spot": ["colours", "fibres"],
        "hardware_metals": ["colours"],
        "hardware_stones": ["colours"],
        "hardware_tip": ["colours"],
        "pattern_narrative": ["colours"],
        "pattern_tip": ["colours"],
    ]

    /// Required placeholder families per Group B section; tip sections are
    /// exempt (mirrors sg_validation._REQUIRED_PLACEHOLDER_FAMILIES).
    private static let requiredPlaceholderFamilies: [String: [(prefixes: [String], minimum: Int)]] = [
        "palette_narrative": [(["core_colour_"], 2), (["accent_colour_"], 1)],
        "textures_good": [(["texture_good_"], 2)],
        "textures_bad": [(["texture_bad_"], 1)],
        "textures_sweet_spot": [(["sweet_spot_keyword_"], 1)],
        "hardware_metals": [(["metal_", "personal_metal_", "structural_metal_"], 2)],
        "hardware_stones": [(["stone_"], 1)],
        "pattern_narrative": [(["recommended_pattern_"], 1)],
    ]

    // MARK: - Loaded rules

    private let rules: [String: Any]
    private let dashRegex: NSRegularExpression
    private let bannedTics: [String]
    private let stampedPhrases: [String]
    private let stampedPatterns: [NSRegularExpression]
    private let contractionReplacements: [(String, String)]
    private let americanWords: [String]
    private let americanAllowedPhrases: [String]
    private let seasonBare: [String]
    private let seasonLabels: [String]
    private let fillerWords: [String]
    private let fillerCap: Int
    private let repetitionBudgets: [String: Int]
    private let concreteWords: [String]
    private let concreteMinimum: Int
    private let formulaSections: Set<String>
    private let lengthBlocks: [String: Int]
    private let lengthBlockDefault: Int
    private let colourLexicon: [String]
    private let fibreLexicon: [String]

    private static let placeholderRegex = try! NSRegularExpression(pattern: "\\{([a-z_0-9]+)\\}")
    private static let stampNormRegex = try! NSRegularExpression(pattern: "[^a-z0-9]+")

    // MARK: - Init

    /// Loads the app-bundled rule + table resources (symlinked from
    /// data/style_guide/). Returns nil if either resource is absent/malformed.
    init?(bundle: Bundle = .main) {
        guard let rulesURL = bundle.url(forResource: "style_guide_rules", withExtension: "json"),
              let tablesURL = bundle.url(forResource: "ranked_domain_tables", withExtension: "json") else {
            return nil
        }
        self.init(rulesURL: rulesURL, rankedTablesURL: tablesURL)
    }

    init?(rulesURL: URL, rankedTablesURL: URL) {
        guard let rulesData = try? Data(contentsOf: rulesURL),
              let tablesData = try? Data(contentsOf: rankedTablesURL),
              let rules = (try? JSONSerialization.jsonObject(with: rulesData)) as? [String: Any],
              let tables = (try? JSONSerialization.jsonObject(with: tablesData)) as? [String: Any]
        else { return nil }

        self.rules = rules

        guard let dash = rules["dash"] as? [String: Any],
              let dashPattern = dash["regex"] as? String,
              let dashRe = try? NSRegularExpression(pattern: dashPattern)
        else { return nil }
        self.dashRegex = dashRe

        guard let tics = rules["banned_tics"] as? [String: Any],
              let folklore = tics["folklore_floor"] as? [String],
              let harvested = tics["harvested"] as? [String]
        else { return nil }
        self.bannedTics = folklore + harvested

        let stamped = rules["stamped_phrases"] as? [String: Any] ?? [:]
        self.stampedPhrases = stamped["phrases"] as? [String] ?? []
        self.contractionReplacements = (stamped["contraction_replacements"] as? [[String]] ?? [])
            .compactMap { $0.count == 2 ? ($0[0], $0[1]) : nil }
        self.stampedPatterns = (stamped["patterns"] as? [String] ?? [])
            .compactMap { try? NSRegularExpression(pattern: $0) }

        guard let american = rules["american_spellings"] as? [String: Any],
              let americanWords = american["words"] as? [String]
        else { return nil }
        self.americanWords = americanWords
        self.americanAllowedPhrases = american["allowed_phrases"] as? [String] ?? []

        guard let seasons = rules["season_words"] as? [String: Any],
              let bare = seasons["bare"] as? [String],
              let labels = seasons["analysis_labels"] as? [String]
        else { return nil }
        self.seasonBare = bare
        self.seasonLabels = labels

        guard let filler = rules["filler_lexicon"] as? [String: Any],
              let fillerWords = filler["words"] as? [String],
              let fillerCap = filler["cap_per_section"] as? Int
        else { return nil }
        self.fillerWords = fillerWords
        self.fillerCap = fillerCap

        guard let repetition = rules["repetition_budgets"] as? [String: Any],
              let budgets = repetition["phrases"] as? [String: Int]
        else { return nil }
        self.repetitionBudgets = budgets

        guard let concrete = rules["concrete_lexicon"] as? [String: Any],
              let concreteWords = concrete["words"] as? [String],
              let concreteMinimum = concrete["minimum"] as? Int
        else { return nil }
        self.concreteWords = concreteWords
        self.concreteMinimum = concreteMinimum

        guard let writeGate = rules["write_gate"] as? [String: Any],
              let formulaSections = writeGate["core_formula_required_sections"] as? [String],
              let lengthBlock = writeGate["length_block"] as? [String: Int],
              let lengthDefault = lengthBlock["default"]
        else { return nil }
        self.formulaSections = Set(formulaSections)
        self.lengthBlocks = lengthBlock
        self.lengthBlockDefault = lengthDefault

        // Leak lexicons: literal names that MUST be placeholders in the cache.
        var colours = Set<String>()
        if let byRole = tables["colours_by_role"] as? [String: Any] {
            for table in byRole.values {
                guard let table = table as? [String: Any] else { continue }
                for group in ["neutrals", "accents", "relief"] {
                    for entry in table[group] as? [[String: Any]] ?? [] {
                        if let name = entry["name"] as? String {
                            colours.insert(name.lowercased())
                        }
                    }
                }
            }
        }
        var fibres = Set<String>()
        if let textures = tables["textures"] as? [String: Any] {
            for table in textures.values {
                for entry in table as? [[String: Any]] ?? [] {
                    if let name = entry["name"] as? String {
                        fibres.insert(name.lowercased())
                    }
                }
            }
        }
        guard !colours.isEmpty, !fibres.isEmpty else { return nil }
        self.colourLexicon = colours.sorted()
        self.fibreLexicon = fibres.sorted()
    }

    // MARK: - The paragraph gate (mirrors validate_paragraph_gate)

    func validateParagraph(
        text: String,
        sectionKey: String,
        coreKeywords: [String],
        existingClusterTexts: [String] = [],
        allowedLeakPhrases: [String] = []
    ) -> GateResult {
        var errors: [Finding] = []
        var warnings: [Finding] = []

        let dashes = findDashes(text)
        if !dashes.isEmpty {
            errors.append(Finding(code: "dash",
                                  detail: "found \(dashes.count) dash character(s) (\(dashes[0]))"))
        }

        let tics = findBannedTics(text)
        if !tics.isEmpty {
            errors.append(Finding(code: "banned_tic", detail: tics.joined(separator: ", ")))
        }

        let american = findAmericanSpellings(text)
        if !american.isEmpty {
            errors.append(Finding(code: "american_spelling", detail: american.joined(separator: ", ")))
        }

        let stamps = findStampedPhrases(text)
        if !stamps.isEmpty {
            errors.append(Finding(code: "stamped_phrase", detail: stamps.joined(separator: ", ")))
        }

        if formulaSections.contains(sectionKey), !formulaKeywordsPresent(text, coreKeywords: coreKeywords) {
            errors.append(Finding(code: "core_formula_absent",
                                  detail: "none of the formula slot phrases \(coreKeywords.prefix(3)) appear"))
        }

        errors.append(contentsOf: placeholderErrors(text, sectionKey: sectionKey))

        let leaks = findLiteralLeaks(text, sectionKey: sectionKey, allowedPhrases: allowedLeakPhrases)
        if !leaks.isEmpty {
            errors.append(Finding(code: "literal_name_leak",
                                  detail: "must be placeholders: " + leaks.prefix(6).joined(separator: ", ")))
        }

        let missing = missingRequiredPlaceholders(text, sectionKey: sectionKey)
        if !missing.isEmpty {
            errors.append(Finding(code: "missing_required_placeholder",
                                  detail: missing.joined(separator: "; ")))
        }

        if sectionKey == "palette_narrative" {
            let seasons = findSeasonWords(text)
            if !seasons.isEmpty {
                errors.append(Finding(code: "season_word_in_palette",
                                      detail: seasons.joined(separator: ", ")))
            }
        }

        // Warnings
        let fillerHits = fillerWordsFound(text)
        if fillerHits.count > fillerCap {
            warnings.append(Finding(code: "filler_over_cap",
                                    detail: "\(fillerHits.count) filler words \(fillerHits) (cap \(fillerCap))"))
        }

        if !meetsConcreteNounFloor(text) {
            warnings.append(Finding(code: "concrete_noun_floor",
                                    detail: "fewer than \(concreteMinimum) named concrete nouns"))
        }

        if !existingClusterTexts.isEmpty {
            let combined = (existingClusterTexts + [text]).joined(separator: " ")
            for violation in repetitionBudgetViolations(combined) {
                warnings.append(Finding(code: "phrase_repetition", detail: violation))
            }
        }

        return GateResult(errors: errors, warnings: warnings)
    }

    /// Hard length block (write_gate.length_block): a separate verdict from
    /// the paragraph gate, matching sg_generate.gate_section's application.
    func isTooLong(text: String, sectionKey: String) -> Bool {
        let limit = lengthBlocks[sectionKey] ?? lengthBlockDefault
        return wordCount(text) > limit
    }

    // MARK: - Individual checks

    func findDashes(_ text: String) -> [String] {
        matches(of: dashRegex, in: text)
    }

    func findBannedTics(_ text: String) -> [String] {
        let lower = text.lowercased()
        return bannedTics.filter { lower.contains($0) }
    }

    func findAmericanSpellings(_ text: String) -> [String] {
        var lower = text.lowercased()
        for phrase in americanAllowedPhrases {
            lower = lower.replacingOccurrences(of: phrase.lowercased(), with: " ")
        }
        return americanWords.filter { containsWord($0, in: lower) }
    }

    func findStampedPhrases(_ text: String) -> [String] {
        let normText = normalizeStamp(text)
        var hits = stampedPhrases.filter { normText.contains(normalizeStamp($0)) }
        for pattern in stampedPatterns {
            let range = NSRange(normText.startIndex..., in: normText)
            if let match = pattern.firstMatch(in: normText, range: range),
               let matchRange = Range(match.range, in: normText) {
                let matched = normalizeStamp(String(normText[matchRange]))
                if !hits.contains(where: { matched.contains(normalizeStamp($0)) }) {
                    hits.append("pattern: \(pattern.pattern)")
                }
            }
        }
        return hits
    }

    func findSeasonWords(_ text: String) -> [String] {
        let lower = text.lowercased()
        var hits = seasonLabels.filter { lower.contains($0) }
        for word in seasonBare where containsWord(word, in: lower) {
            if !hits.contains(where: { $0.contains(word) }) {
                hits.append(word)
            }
        }
        return hits
    }

    func formulaKeywordsPresent(_ text: String, coreKeywords: [String]) -> Bool {
        let lower = text.lowercased()
        return coreKeywords.prefix(3).contains { lower.contains($0.lowercased()) }
    }

    func placeholderErrors(_ text: String, sectionKey: String) -> [Finding] {
        let tokens = placeholderTokens(text)
        var errors: [Finding] = []
        if Self.groupASections.contains(sectionKey), !tokens.isEmpty {
            errors.append(Finding(
                code: "group_a_placeholder",
                detail: "Group A section must be plain prose but contains placeholders: "
                    + tokens.prefix(5).map { "{\($0)}" }.joined(separator: ", ")))
        }
        let unknown = tokens.filter { !Self.allowedPlaceholders.contains($0) }
        if !unknown.isEmpty {
            errors.append(Finding(
                code: "unknown_placeholder",
                detail: unknown.prefix(5).map { "{\($0)}" }.joined(separator: ", ")))
        }
        return errors
    }

    func findLiteralLeaks(_ text: String, sectionKey: String,
                          allowedPhrases: [String] = []) -> [String] {
        guard let lexKeys = Self.leakLexiconsBySection[sectionKey] else { return [] }
        var low = stripPlaceholders(text).lowercased()
        for phrase in allowedPhrases {
            low = low.replacingOccurrences(of: phrase.lowercased(), with: " ")
        }
        var hits = Set<String>()
        for key in lexKeys {
            let lexicon = key == "colours" ? colourLexicon : fibreLexicon
            for name in lexicon where containsWord(name, in: low) {
                hits.insert(name)
            }
        }
        return hits.sorted()
    }

    func missingRequiredPlaceholders(_ text: String, sectionKey: String) -> [String] {
        guard let requirements = Self.requiredPlaceholderFamilies[sectionKey] else { return [] }
        let tokens = Set(placeholderTokens(text))
        var missing: [String] = []
        for (prefixes, minimum) in requirements {
            let count = tokens.filter { token in prefixes.contains { token.hasPrefix($0) } }.count
            if count < minimum {
                missing.append("need >= \(minimum) of \(prefixes.joined(separator: "/")) (found \(count))")
            }
        }
        return missing
    }

    func fillerWordsFound(_ text: String) -> [String] {
        let lower = text.lowercased()
        return fillerWords.filter { containsWord($0, in: lower) }
    }

    func meetsConcreteNounFloor(_ text: String) -> Bool {
        let lower = text.lowercased()
        var found = concreteWords.reduce(0) { $0 + (containsWord($1, in: lower) ? 1 : 0) }
        // Placeholders count as concrete (they resolve to named nouns at render).
        found += placeholderTokens(text).count
        return found >= concreteMinimum
    }

    func repetitionBudgetViolations(_ combinedText: String) -> [String] {
        let lower = combinedText.lowercased()
        var violations: [String] = []
        for (phrase, budget) in repetitionBudgets.sorted(by: { $0.key < $1.key }) {
            let count = occurrenceCount(of: phrase, in: lower)
            if count > budget {
                violations.append("'\(phrase)' x\(count) (budget \(budget))")
            }
        }
        return violations
    }

    // MARK: - Helpers

    private func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private func placeholderTokens(_ text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return Self.placeholderRegex.matches(in: text, range: range).compactMap { match in
            Range(match.range(at: 1), in: text).map { String(text[$0]) }
        }
    }

    private func stripPlaceholders(_ text: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return Self.placeholderRegex.stringByReplacingMatches(
            in: text, range: range, withTemplate: " ")
    }

    private func normalizeStamp(_ s: String) -> String {
        var low = s.lowercased()
        for (old, new) in contractionReplacements {
            low = low.replacingOccurrences(of: old, with: new)
        }
        let range = NSRange(low.startIndex..., in: low)
        return Self.stampNormRegex
            .stringByReplacingMatches(in: low, range: range, withTemplate: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private func matches(of regex: NSRegularExpression, in text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    /// Word-boundary containment (\b<word>\b) on pre-lowercased text, with a
    /// per-validator regex cache (the lexicons are hundreds of words).
    private static var wordRegexCache: [String: NSRegularExpression] = [:]
    private static let cacheLock = NSLock()

    private func containsWord(_ word: String, in lowerText: String) -> Bool {
        Self.cacheLock.lock()
        var regex = Self.wordRegexCache[word]
        if regex == nil {
            regex = try? NSRegularExpression(
                pattern: "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b")
            Self.wordRegexCache[word] = regex
        }
        Self.cacheLock.unlock()
        guard let regex else { return false }
        let range = NSRange(lowerText.startIndex..., in: lowerText)
        return regex.firstMatch(in: lowerText, range: range) != nil
    }

    /// Non-overlapping occurrence count (mirrors Python str.count).
    private func occurrenceCount(of needle: String, in haystack: String) -> Int {
        guard !needle.isEmpty else { return 0 }
        var count = 0
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let found = haystack.range(of: needle, range: searchRange) {
            count += 1
            searchRange = found.upperBound..<haystack.endIndex
        }
        return count
    }
}
