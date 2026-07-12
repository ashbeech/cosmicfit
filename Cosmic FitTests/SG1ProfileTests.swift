//
//  SG1ProfileTests.swift
//  Cosmic FitTests
//
//  SG-1 (Style Guide Quality Overhaul, Phase 1) golden-matrix tests.
//
//  Inputs:  docs/style_guide/golden/fixtures/{archetype}_chart.json
//           (15 synthetic charts) + Slate's real natal chart (Athens).
//  Vectors: docs/style_guide/golden/profile_expectations.json
//           (same vectors consumed by the SG-3 Python parity check).
//
//  Covers: profile dimensions, coreFormula, key-purity, coarse/fine
//  non-contradiction, conflict policy, overlay gating, and the Phase 1d
//  mechanical bug fixes.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixture / expectation loading

private struct GoldenFixture: Decodable {
    let archetype: String
    let clusterKey: String
    let chartSect: String
    let elementBalance: [String: Int]
    let chartRuler: String
    let sunSign: String
    let moonSign: String
    let venusSign: String
    let marsSign: String
    let ascendantSign: String
    let midheavenSign: String
    let planetSigns: [String: String]
    let planetHouses: [String: Int]

    enum CodingKeys: String, CodingKey {
        case archetype
        case clusterKey = "cluster_key"
        case chartSect = "chart_sect"
        case elementBalance = "element_balance"
        case chartRuler = "chart_ruler"
        case sunSign = "sun_sign"
        case moonSign = "moon_sign"
        case venusSign = "venus_sign"
        case marsSign = "mars_sign"
        case ascendantSign = "ascendant_sign"
        case midheavenSign = "midheaven_sign"
        case planetSigns = "planet_signs"
        case planetHouses = "planet_houses"
    }

    func toChartAnalysis() -> ChartAnalysis {
        let sect: ChartSect = chartSect == "night" ? .night : .day

        var houseScores: [Int: Double] = [:]
        for h in 1...12 { houseScores[h] = 0.0 }
        for (_, house) in planetHouses { houseScores[house, default: 0] += 0.5 }
        let dominantHouses = houseScores
            .sorted { a, b in a.value != b.value ? a.value > b.value : a.key < b.key }
            .prefix(3).map(\.key)

        return ChartAnalysis(
            elementBalance: ElementBalance(
                fire: elementBalance["fire"] ?? 0,
                earth: elementBalance["earth"] ?? 0,
                air: elementBalance["air"] ?? 0,
                water: elementBalance["water"] ?? 0
            ),
            modalityBalance: ModalityBalance(cardinal: 3, fixed: 3, mutable: 2),
            chartRuler: chartRuler,
            sunSign: sunSign,
            moonSign: moonSign,
            ascendantSign: ascendantSign,
            venusSign: venusSign,
            marsSign: marsSign,
            midheavenSign: midheavenSign,
            planetSigns: planetSigns,
            planetDignities: [:],
            planetHouses: planetHouses,
            significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Sun"],
            chartSect: sect,
            planetSectStatus: ChartAnalyser.computePlanetSectStatus(chartSect: sect),
            houseEmphasis: HouseEmphasis(
                houseScores: houseScores,
                dominantHouses: Array(dominantHouses),
                venusHouseDomain: ChartAnalyser.houseDomainLabel(for: planetHouses["Venus"] ?? 1) ?? "identity",
                moonHouseDomain: ChartAnalyser.houseDomainLabel(for: planetHouses["Moon"] ?? 1) ?? "identity"
            )
        )
    }
}

private struct ProfileExpectation: Decodable {
    let clusterKey: String
    let orientation: String
    let register: String
    let metalStrategy: String
    let finishLane: String
    let temperature: String
    let coreFormula: String
    let confidence: String
    let overlayPolicy: String
    let stelliumSigns: [String]
    let excludedKeywords: [String]

    enum CodingKeys: String, CodingKey {
        case clusterKey = "cluster_key"
        case orientation, register
        case metalStrategy = "metal_strategy"
        case finishLane = "finish_lane"
        case temperature
        case coreFormula = "core_formula"
        case confidence
        case overlayPolicy = "overlay_policy"
        case stelliumSigns = "stellium_signs"
        case excludedKeywords = "excluded_keywords"
    }
}

private enum SG1Golden {
    static var goldenDir: URL {
        FixtureLocator.repoRoot().appendingPathComponent("docs/style_guide/golden")
    }

    static func loadExpectations() throws -> [String: ProfileExpectation] {
        let url = goldenDir.appendingPathComponent("profile_expectations.json")
        let data = try Data(contentsOf: url)
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        var result: [String: ProfileExpectation] = [:]
        let decoder = JSONDecoder()
        for (name, value) in raw where name != "_meta" {
            let entryData = try JSONSerialization.data(withJSONObject: value)
            result[name] = try decoder.decode(ProfileExpectation.self, from: entryData)
        }
        return result
    }

    static func loadFixture(_ archetype: String) throws -> GoldenFixture {
        let url = goldenDir.appendingPathComponent("fixtures/\(archetype)_chart.json")
        return try JSONDecoder().decode(GoldenFixture.self, from: Data(contentsOf: url))
    }

    /// Fine ChartAnalysis for each golden archetype: 15 synthetic fixtures
    /// plus Slate computed from her real natal chart (Athens 04:30 local).
    static func analysis(for archetype: String) throws -> ChartAnalysis {
        if archetype == "slate" {
            let birthDate = ISO8601DateFormatter().date(from: "1989-04-28T01:30:00Z")!
            let chart = NatalChartCalculator.calculateNatalChart(
                birthDate: birthDate,
                latitude: 37.9855765,
                longitude: 23.7283762,
                timeZone: TimeZone(secondsFromGMT: 0)!
            )
            return ChartAnalyser.analyse(chart: chart)
        }
        return try loadFixture(archetype).toChartAnalysis()
    }
}

// MARK: - Phase 1a: golden profile matrix

struct SG1GoldenProfileTests {

    @Test("All 16 golden charts produce the expected profile dimensions and formula")
    func goldenProfileMatrix() throws {
        let expectations = try SG1Golden.loadExpectations()
        #expect(expectations.count == 16)

        for (archetype, expected) in expectations.sorted(by: { $0.key < $1.key }) {
            let analysis = try SG1Golden.analysis(for: archetype)
            let profile = ChartAestheticProfile.derive(from: analysis)

            #expect(profile.orientation.rawValue == expected.orientation,
                    "\(archetype): orientation \(profile.orientation.rawValue) != \(expected.orientation)")
            #expect(profile.aestheticRegister.rawValue == expected.register,
                    "\(archetype): register \(profile.aestheticRegister.rawValue) != \(expected.register)")
            #expect(profile.metalStrategy.rawValue == expected.metalStrategy,
                    "\(archetype): metals \(profile.metalStrategy.rawValue) != \(expected.metalStrategy)")
            #expect(profile.finishLane.rawValue == expected.finishLane,
                    "\(archetype): finish \(profile.finishLane.rawValue) != \(expected.finishLane)")
            #expect(profile.temperature.rawValue == expected.temperature,
                    "\(archetype): temperature \(profile.temperature.rawValue) != \(expected.temperature)")
            #expect(profile.coreFormula == expected.coreFormula,
                    "\(archetype): formula '\(profile.coreFormula)' != '\(expected.coreFormula)'")
            #expect(profile.confidence.rawValue == expected.confidence,
                    "\(archetype): confidence \(profile.confidence.rawValue) != \(expected.confidence)")
            #expect(profile.overlayPolicy.rawValue == expected.overlayPolicy,
                    "\(archetype): overlayPolicy \(profile.overlayPolicy.rawValue) != \(expected.overlayPolicy)")
            #expect(profile.stelliumSigns == expected.stelliumSigns,
                    "\(archetype): stelliums \(profile.stelliumSigns) != \(expected.stelliumSigns)")
            #expect(Set(profile.excludedAestheticKeywords) == Set(expected.excludedKeywords),
                    "\(archetype): excluded \(profile.excludedAestheticKeywords) != \(expected.excludedKeywords)")
        }
    }

    @Test("Slate yields quietLuxury + dualRegister + muted + warm + her authored formula")
    func slateProfile() throws {
        let profile = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "slate"))
        #expect(profile.aestheticRegister == .quietLuxury)
        #expect(profile.metalStrategy == .dualRegister)
        #expect(profile.finishLane == .muted)
        #expect(profile.temperature == .warm)
        #expect(profile.orientation == .selfContained)
        #expect(profile.coreFormula == "structure + softness + a touch of quiet depth")
    }

    @Test("Fire/bold charts derive boldExpression with polished/mixedFree, not Slate's lane")
    func boldChartsNotSlateLane() throws {
        for archetype in ["ember", "blaze", "cinder"] {
            let profile = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: archetype))
            #expect(profile.aestheticRegister == .boldExpression, "\(archetype)")
            #expect(profile.finishLane == .polished, "\(archetype)")
            #expect(profile.metalStrategy != .coolDominant, "\(archetype)")
            #expect(profile.finishLane != .muted, "\(archetype)")
        }
    }

    @Test("Borderline charts resolve to neutral lanes, not force-fit")
    func borderlineChartsResolveNeutral() throws {
        // Loom: 3 air / 2 earth / 2 water margin -> low confidence, all-neutral lanes.
        let loom = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "loom"))
        #expect(loom.orientation == .balanced)
        #expect(loom.aestheticRegister == .versatileAdaptive)
        #expect(loom.metalStrategy == .mixedFree)
        #expect(loom.finishLane == .mixed)
        #expect(loom.confidence == .low)
        #expect(loom.overlayPolicy == .neutralPreferred)

        // Wren: three-way register vote split -> versatile tie-break, low confidence.
        let wren = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "wren"))
        #expect(wren.aestheticRegister == .versatileAdaptive)
        #expect(wren.confidence == .low)
    }
}

// MARK: - Phase 1b: coarse/fine seam + key purity

struct SG1CoarseSeamTests {

    @Test("Key-purity: coarseProfile(key).coreFormula == fineProfile(chart).coreFormula for all 16")
    func keyPurity() throws {
        let expectations = try SG1Golden.loadExpectations()
        for (archetype, expected) in expectations {
            let fine = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: archetype))
            let coarse = ChartAestheticProfile.coarseProfile(fromClusterKey: expected.clusterKey)
            #expect(coarse != nil, "\(archetype): coarse factory failed for \(expected.clusterKey)")
            #expect(coarse?.coreFormula == fine.coreFormula,
                    "\(archetype): coarse '\(coarse?.coreFormula ?? "nil")' != fine '\(fine.coreFormula)'")
        }
    }

    @Test("Coarse profile never contradicts the fine profile's primary lanes")
    func coarseNonContradiction() throws {
        let expectations = try SG1Golden.loadExpectations()
        for (archetype, expected) in expectations {
            let fine = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: archetype))
            guard let coarse = ChartAestheticProfile.coarseProfile(fromClusterKey: expected.clusterKey) else {
                Issue.record("\(archetype): coarse factory failed"); continue
            }
            // Key-pure lanes must be identical by construction.
            #expect(coarse.aestheticRegister == fine.aestheticRegister, "\(archetype)")
            #expect(coarse.temperature == fine.temperature, "\(archetype)")
            #expect(coarse.finishLane == fine.finishLane, "\(archetype)")
            #expect(coarse.metalStrategy == fine.metalStrategy, "\(archetype)")
            // Orientation: equal or the coarse is the weaker (balanced) lane.
            #expect(coarse.orientation == fine.orientation || coarse.orientation == .balanced,
                    "\(archetype): coarse orientation \(coarse.orientation) contradicts fine \(fine.orientation)")
        }
    }

    @Test("Coarse factory rejects malformed cluster keys")
    func coarseFactoryRejectsBadKeys() {
        #expect(ChartAestheticProfile.coarseProfile(fromClusterKey: "not_a_key") == nil)
        #expect(ChartAestheticProfile.coarseProfile(fromClusterKey: "venus_taurus__earth_dominant") == nil)
        #expect(ChartAestheticProfile.coarseProfile(fromClusterKey: "moon_taurus__venus_leo__fire_dominant") == nil)
    }
}

// MARK: - Phase 1e: conflict policy

struct SG1ConflictPolicyTests {

    @Test("Wren's bold Aries stellium against the versatile coarse lane resolves to suppressConflicting")
    func wrenStelliumConflict() throws {
        let wren = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "wren"))
        #expect(wren.overlayPolicy == .suppressConflicting)
        #expect(wren.stelliumSigns == ["Aries"])
        // The coarse lane is never flipped by the stellium.
        #expect(wren.aestheticRegister == .versatileAdaptive)
        // Bold vocabulary is mechanically excluded for this chart.
        #expect(wren.excludedAestheticKeywords.contains("bold"))
        #expect(wren.excludedAestheticKeywords.contains("statement"))
        #expect(wren.excludedAestheticKeywords.contains("fierce"))
    }

    @Test("Reinforcing stelliums do not trigger suppression")
    func reinforcingStelliums() throws {
        // Mist: Pisces stellium reinforces the quiet lane.
        let mist = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "mist"))
        #expect(mist.stelliumSigns == ["Pisces"])
        #expect(mist.overlayPolicy == .full)
        // Blaze: Sagittarius stellium reinforces the bold lane.
        let blaze = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "blaze"))
        #expect(blaze.stelliumSigns == ["Sagittarius"])
        #expect(blaze.overlayPolicy == .full)
        // Slate: Capricorn + Taurus stelliums reinforce the quiet lane.
        let slate = ChartAestheticProfile.derive(from: try SG1Golden.analysis(for: "slate"))
        #expect(slate.stelliumSigns == ["Capricorn", "Taurus"])
        #expect(slate.overlayPolicy == .full)
    }

    @Test("Flat element balance resolves borderline dimensions to neutral with low confidence")
    func flatBalanceNeutral() throws {
        // Loom is the authored flat-balance chart (margin 1).
        let analysis = try SG1Golden.loadFixture("loom").toChartAnalysis()
        let profile = ChartAestheticProfile.derive(from: analysis)
        #expect(profile.confidence == .low)
        #expect(profile.overlayPolicy == .neutralPreferred)
        #expect(profile.orientation == .balanced)
    }
}

// MARK: - Phase 1c/1d: overlay gating + mechanical bugs

struct SG1OverlayGatingTests {

    private func loadDataset() -> AstrologicalStyleDataset? {
        BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath)
        )
    }

    @Test("Quiet-luxury chart with MC Sagittarius gets the quiet variant, not bold/expansive text")
    func mcSagittariusQuietVariant() throws {
        let profile = ChartAestheticProfile.coarseProfile(
            venusSign: "Taurus", moonSign: "Capricorn", dominantElement: "earth"
        )
        let styleCore = HouseSectOverlayGenerator.midheavenStyleCoreText(
            for: "Sagittarius", profile: profile
        )
        #expect(styleCore != nil)
        for keyword in ["bold", "global", "adventurous", "expansive"] {
            #expect(!(styleCore!.localizedCaseInsensitiveContains(keyword)),
                    "quiet MC Sag text asserts '\(keyword)': \(styleCore!)")
        }
        let work = HouseSectOverlayGenerator.midheavenWorkText(
            for: "Sagittarius", profile: profile
        )
        #expect(work != nil)
        for keyword in ["bold", "global", "expansive"] {
            #expect(!(work!.localizedCaseInsensitiveContains(keyword)),
                    "quiet MC Sag work text asserts '\(keyword)': \(work!)")
        }
    }

    @Test("Bold chart with MC Sagittarius keeps the adventurous language")
    func mcSagittariusBoldRetained() throws {
        let profile = ChartAestheticProfile.coarseProfile(
            venusSign: "Aries", moonSign: "Sagittarius", dominantElement: "fire"
        )
        let styleCore = HouseSectOverlayGenerator.midheavenStyleCoreText(
            for: "Sagittarius", profile: profile
        )
        #expect(styleCore?.contains("bold and expansive") == true)
        #expect(styleCore?.contains("adventurous") == true)
    }

    @Test("Moon 11th overlay variants by orientation")
    func moonEleventhVariants() throws {
        guard let dataset = loadDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        func analysisWithMoon11(venus: String, moon: String, element: String) -> ChartAnalysis {
            let sect: ChartSect = .day
            var houseScores: [Int: Double] = [:]
            for h in 1...12 { houseScores[h] = 0.0 }
            houseScores[11] = 1.0; houseScores[5] = 0.5
            let counts: (Int, Int, Int, Int)
            switch element {
            case "earth": counts = (1, 5, 1, 1)
            case "air":   counts = (1, 1, 5, 1)
            default:      counts = (5, 1, 1, 1)
            }
            return ChartAnalysis(
                elementBalance: ElementBalance(fire: counts.0, earth: counts.1, air: counts.2, water: counts.3),
                modalityBalance: ModalityBalance(cardinal: 3, fixed: 3, mutable: 2),
                chartRuler: "Venus",
                sunSign: venus, moonSign: moon, ascendantSign: "Libra",
                venusSign: venus, marsSign: "Aries", midheavenSign: "Capricorn",
                planetSigns: ["Sun": venus, "Moon": moon, "Venus": venus, "Mars": "Aries"],
                planetDignities: [:],
                planetHouses: ["Venus": 5, "Moon": 11],
                significantAspects: [],
                dominantPlanets: ["Venus", "Moon", "Sun"],
                chartSect: sect,
                planetSectStatus: ChartAnalyser.computePlanetSectStatus(chartSect: sect),
                houseEmphasis: HouseEmphasis(
                    houseScores: houseScores,
                    dominantHouses: [11, 5, 1],
                    venusHouseDomain: "creativity",
                    moonHouseDomain: "community"
                )
            )
        }

        // Self-contained quiet chart: community wording must be gone.
        let quietAnalysis = analysisWithMoon11(venus: "Taurus", moon: "Capricorn", element: "earth")
        let quietProfile = ChartAestheticProfile.derive(from: quietAnalysis)
        #expect(quietProfile.orientation == .selfContained)
        let quietOverlays = HouseSectOverlayGenerator.generate(
            analysis: quietAnalysis, dataset: dataset, profile: quietProfile
        )
        let quietDaily = quietOverlays.occasionsDailyAppend ?? ""
        for keyword in ["community", "belonging", "collective"] {
            #expect(!quietDaily.localizedCaseInsensitiveContains(keyword),
                    "selfContained daily overlay asserts '\(keyword)': \(quietDaily)")
        }
        #expect(quietDaily.contains("personal sanctuary"),
                "selfContained Moon-11th variant missing: \(quietDaily)")

        // Community-oriented chart: dataset community wording is retained.
        let communityAnalysis = analysisWithMoon11(venus: "Gemini", moon: "Aquarius", element: "air")
        let communityProfile = ChartAestheticProfile.derive(from: communityAnalysis)
        #expect(communityProfile.orientation == .communityOriented)
        let communityOverlays = HouseSectOverlayGenerator.generate(
            analysis: communityAnalysis, dataset: dataset, profile: communityProfile
        )
        let communityDaily = communityOverlays.occasionsDailyAppend ?? ""
        #expect(communityDaily.localizedCaseInsensitiveContains("community"),
                "communityOriented Moon-11th overlay lost its community language: \(communityDaily)")
    }

    @Test("domainPairImplication starts lowercase and carries no trailing period, all registers")
    func domainPairImplicationContract() {
        let domains = ["identity", "resources", "expression", "foundations",
                       "creativity", "routine", "partnership", "intensity",
                       "philosophy", "public", "community", "retreat"]
        let registers: [ChartAestheticProfile.AestheticRegister] =
            [.quietLuxury, .boldExpression, .versatileAdaptive]

        for register in registers {
            for d1 in domains {
                for d2 in domains where d1 != d2 {
                    let implication = HouseSectOverlayGenerator.domainPairImplication(
                        d1, d2, register: register
                    )
                    #expect(!implication.hasSuffix("."),
                            "[\(register)] \(d1)+\(d2) has trailing period: '\(implication)'")
                    let first = implication.first.map(String.init) ?? ""
                    #expect(first == first.lowercased(),
                            "[\(register)] \(d1)+\(d2) starts uppercase: '\(implication)'")
                    #expect(!implication.contains(".."),
                            "[\(register)] \(d1)+\(d2) contains '..': '\(implication)'")
                }
            }
        }
    }

    @Test("Excluded-keyword screen suppresses off-lane sentences and keeps clean ones")
    func excludedKeywordScreen() {
        let profile = ChartAestheticProfile.coarseProfile(
            venusSign: "Taurus", moonSign: "Capricorn", dominantElement: "earth"
        )
        // Whole overlay off-lane -> suppressed entirely.
        #expect(HouseSectOverlayGenerator.screened(
            "Your public style reads as bold and expansive.", profile: profile
        ) == nil)
        // Mixed overlay -> off-lane sentence dropped, clean sentence kept.
        let mixed = HouseSectOverlayGenerator.screened(
            "Your instincts lean toward tactile comfort. Your public style reads as bold and expansive.",
            profile: profile
        )
        #expect(mixed == "Your instincts lean toward tactile comfort.")
        // Clean overlay -> untouched.
        let clean = "Your instincts lean toward tactile comfort."
        #expect(HouseSectOverlayGenerator.screened(clean, profile: profile) == clean)
    }
}

// MARK: - Composed output (Slate end-to-end)

struct SG1ComposedOutputTests {

    @Test("Slate composed output has no MC/community contradictions and no double periods")
    func slateComposedClean() throws {
        guard let dataset = BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath)
        ) else {
            Issue.record("Failed to load dataset"); return
        }
        let narrativeCache = NarrativeCacheLoader()
        guard narrativeCache.loadFromURL(
            StyleGuideDataURL.blueprintNarrativeCache(testFilePath: #filePath)
        ), narrativeCache.clusterCount > 0 else {
            Issue.record("Failed to load narrative cache"); return
        }

        let birthDate = ISO8601DateFormatter().date(from: "1989-04-28T01:30:00Z")!
        let chart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: 37.9855765, longitude: 23.7283762,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        let blueprint = BlueprintComposer.compose(
            chart: chart, birthDate: birthDate, birthLocation: "Athens, Greece",
            dataset: dataset, narrativeCache: narrativeCache
        )

        let sections: [(String, String)] = [
            ("style_core", blueprint.styleCore.narrativeText),
            ("textures_good", blueprint.textures.goodText),
            ("textures_bad", blueprint.textures.badText),
            ("textures_sweet_spot", blueprint.textures.sweetSpotText),
            ("occasions_work", blueprint.occasions.workText),
            ("occasions_intimate", blueprint.occasions.intimateText),
            ("occasions_daily", blueprint.occasions.dailyText)
        ]

        // Plan Phase 1c test: zero instances of the contradiction keywords.
        let forbidden = ["bold", "global", "adventurous", "expansive", "community", "belonging"]
        for (name, text) in sections {
            for keyword in forbidden {
                #expect(!text.localizedCaseInsensitiveContains(keyword),
                        "Slate \(name) contains '\(keyword)'")
            }
            // Plan Phase 1d test: no double periods anywhere.
            #expect(!text.contains(".."), "Slate \(name) contains '..'")
        }
    }
}
