//
//  SG2DataContractTests.swift
//  Cosmic FitTests
//
//  SG-2 (Style Guide Quality Overhaul, Phases 2a–2e + 2.5).
//  Evidence for the SG-2 gate: metal register/finish schema, resolver register
//  split, renderer placeholders + softenMetalName fix, ranked domain tables,
//  formula_vocabulary 576-key coverage, cache schema v2 decode + composer
//  wiring, output-contract back-compat, and the Phase 2e palette temperature
//  floor (Slate reads warm + deep).
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Shared fixtures

private enum SG2 {
    static func dataset(_ path: String = #filePath) -> AstrologicalStyleDataset {
        BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: path)
        )!
    }

    static func rankedTables(_ path: String = #filePath) -> RankedDomainTables {
        let loader = RankedDomainTablesLoader()
        _ = loader.loadFromURL(StyleGuideDataURL.rankedDomainTables(testFilePath: path))
        return loader.tables!
    }

    /// Slate's real natal chart (Athens 1989-04-28 04:30 local == 01:30Z).
    static func slateChart() -> NatalChartCalculator.NatalChart {
        let birthDate = ISO8601DateFormatter().date(from: "1989-04-28T01:30:00Z")!
        return NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: 37.9855765, longitude: 23.7283762,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
    }

    static func slateAnalysis() -> ChartAnalysis {
        ChartAnalyser.analyse(chart: slateChart())
    }

    static let allSigns = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                           "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
    static let elements = ["fire", "earth", "air", "water"]
}

// MARK: - Phase 2a: Metal register + finish schema

@Suite("SG-2 Phase 2a: metal schema")
struct SG2MetalSchemaTests {

    @Test("Dataset metals decode as objects with register + finish")
    func metalsAreObjects() throws {
        let ds = SG2.dataset()
        let taurus = try #require(ds.planetSign["venus_taurus"])
        #expect(!taurus.metals.isEmpty)
        let gold = try #require(taurus.metals.first { $0.name == "yellow gold" })
        #expect(gold.register == .personal)
        #expect(gold.finish == .matte)
        // Every metal in the dataset now carries a valid register + finish.
        for (_, entry) in ds.planetSign {
            for m in entry.metals {
                #expect(!m.name.isEmpty)
            }
        }
    }

    @Test("Legacy plain-string metal decodes as either/matte (back-compat)")
    func legacyStringDecodes() throws {
        let json = "\"antique bronze\"".data(using: .utf8)!
        let entry = try JSONDecoder().decode(MetalEntry.self, from: json)
        #expect(entry.name == "antique bronze")
        #expect(entry.register == .either)
        #expect(entry.finish == .matte)
    }

    @Test("A mixed legacy/object metals array decodes")
    func mixedArrayDecodes() throws {
        let json = """
        ["silver", {"name":"gunmetal","register":"structural","finish":"brushed"}]
        """.data(using: .utf8)!
        let metals = try JSONDecoder().decode([MetalEntry].self, from: json)
        #expect(metals.count == 2)
        #expect(metals[0].register == .either)     // legacy string
        #expect(metals[1].register == .structural)  // object
        #expect(metals[1].finish == .brushed)
    }
}

// MARK: - Phase 2b: Resolver register split

@Suite("SG-2 Phase 2b: resolver register split")
struct SG2ResolverSplitTests {

    private func resolveSlate(profile: ChartAestheticProfile) -> DeterministicResolverResult {
        let ds = SG2.dataset()
        let analysis = SG2.slateAnalysis()
        let tokens = BlueprintTokenGenerator.generate(analysis: analysis, dataset: ds)
        return DeterministicResolver.resolveNonPalette(
            tokens: tokens.tokens, analysis: analysis, dataset: ds,
            contributingCombos: tokens.contributingCombos, profile: profile
        )
    }

    @Test("Slate (dualRegister + muted): warm personal + cool structural + excludes polished chrome")
    func slateDualRegister() throws {
        let profile = ChartAestheticProfile.derive(from: SG2.slateAnalysis())
        #expect(profile.metalStrategy == .dualRegister)
        #expect(profile.finishLane == .muted)

        let resolved = resolveSlate(profile: profile)
        let personal = try #require(resolved.personalMetals)
        let structural = try #require(resolved.structuralMetals)
        #expect(!personal.isEmpty)
        #expect(!structural.isEmpty)
        // The two registers are disjoint (a metal is warm-personal xor cool-structural).
        #expect(Set(personal).isDisjoint(with: Set(structural)))
        // Personal carries warmth; structural carries cool metal.
        let warmWords = ["gold", "bronze", "brass", "copper", "honey", "sienna", "umber"]
        let coolWords = ["silver", "steel", "titanium", "platinum", "gunmetal", "iron", "white gold"]
        #expect(personal.contains { name in warmWords.contains { name.contains($0) } },
                "personal metals should include a warm metal, got \(personal)")
        #expect(structural.contains { name in coolWords.contains { name.contains($0) } },
                "structural metals should include a cool metal, got \(structural)")
        // No clearly-cool metal leaks into personal; no clearly-warm into structural.
        #expect(!personal.contains { name in coolWords.contains { name.contains($0) } },
                "cool metal leaked into personal: \(personal)")
        #expect(!structural.contains { name in warmWords.contains { name.contains($0) } },
                "warm metal leaked into structural: \(structural)")
        // Muted lane excludes polished chrome.
        let excluded = try #require(resolved.excludedFinishes)
        #expect(excluded.contains("polished chrome"))
    }

    @Test("mixedFree profile produces no artificial split")
    func mixedFreeNoSplit() throws {
        // Zephyr: Gemini Venus / Aquarius Moon / air → mixedFree.
        let zephyr = ChartAestheticProfile.coarseProfile(
            venusSign: "Gemini", moonSign: "Aquarius", dominantElement: "air")
        #expect(zephyr.metalStrategy == .mixedFree)
        let resolved = resolveSlate(profile: zephyr)
        #expect(resolved.personalMetals == nil)
        #expect(resolved.structuralMetals == nil)
        #expect(resolved.excludedFinishes == nil)
    }

    @Test("warmDominant profile does not force a dual split")
    func warmDominantNotSplit() throws {
        // Ember: Aries Venus / Sagittarius Moon / fire → warmDominant.
        let ember = ChartAestheticProfile.coarseProfile(
            venusSign: "Aries", moonSign: "Sagittarius", dominantElement: "fire")
        #expect(ember.metalStrategy == .warmDominant)
        let resolved = resolveSlate(profile: ember)
        #expect(resolved.personalMetals != nil)      // unified warm list
        #expect(resolved.structuralMetals == nil)    // no cool structural split
    }

    @Test("Old HardwareSection JSON without SG-2 fields still decodes")
    func legacyHardwareDecodes() throws {
        let json = """
        {"metalsText":"m","stonesText":"s","tipText":"t",
         "recommendedMetals":["silver","gold"],"recommendedStones":["onyx"]}
        """.data(using: .utf8)!
        let hw = try JSONDecoder().decode(HardwareSection.self, from: json)
        #expect(hw.recommendedMetals == ["silver", "gold"])
        #expect(hw.personalMetals == nil)
        #expect(hw.structuralMetals == nil)
        #expect(hw.excludedFinishes == nil)
        #expect(hw.sectionIntro == nil)
    }
}

// MARK: - Phase 2c: Renderer placeholders + softenMetalName fix + QA mode

@Suite("SG-2 Phase 2c: renderer")
struct SG2RendererTests {

    private func slateResolved() -> DeterministicResolverResult {
        let ds = SG2.dataset()
        let analysis = SG2.slateAnalysis()
        let profile = ChartAestheticProfile.derive(from: analysis)
        let tokens = BlueprintTokenGenerator.generate(analysis: analysis, dataset: ds)
        return DeterministicResolver.resolveNonPalette(
            tokens: tokens.tokens, analysis: analysis, dataset: ds,
            contributingCombos: tokens.contributingCombos, profile: profile
        )
    }

    @Test("Metal names render verbatim, not with ' tones' garble")
    func metalNamesVerbatim() throws {
        let ctx = NarrativeTemplateRenderer.buildContext(resolved: slateResolved())
        let metal1 = try #require(ctx["metal_1"])
        #expect(!metal1.hasSuffix(" tones"))
        // A representative template renders clean.
        let out = NarrativeTemplateRenderer.render(
            template: "Solid {metal_1} details anchor the look.", context: ctx)
        #expect(!out.contains(" tones"))
        #expect(!out.contains("a complementary choice"))
    }

    @Test("Register-split placeholders populate for Slate")
    func splitPlaceholders() throws {
        let ctx = NarrativeTemplateRenderer.buildContext(resolved: slateResolved())
        #expect(ctx["personal_metal_1"] != nil)
        #expect(ctx["structural_metal_1"] != nil)
        #expect(ctx["excluded_finish"] == "polished chrome")
    }

    @Test("Missing split context falls back gracefully in production mode")
    func gracefulFallback() throws {
        // A resolved result with no split (mixedFree path → nil lists).
        let ember = ChartAestheticProfile.coarseProfile(
            venusSign: "Gemini", moonSign: "Aquarius", dominantElement: "air")
        let ds = SG2.dataset()
        let analysis = SG2.slateAnalysis()
        let tokens = BlueprintTokenGenerator.generate(analysis: analysis, dataset: ds)
        let resolved = DeterministicResolver.resolveNonPalette(
            tokens: tokens.tokens, analysis: analysis, dataset: ds,
            contributingCombos: tokens.contributingCombos, profile: ember)
        let ctx = NarrativeTemplateRenderer.buildContext(resolved: resolved)
        let wasQA = NarrativeTemplateRenderer.qaModeEnabled
        NarrativeTemplateRenderer.qaModeEnabled = false
        defer { NarrativeTemplateRenderer.qaModeEnabled = wasQA }
        let out = NarrativeTemplateRenderer.render(
            template: "Pair {personal_metal_1} with something.", context: ctx)
        // No split → graceful fallback string, never empty.
        #expect(out.contains("a complementary choice"))
        #expect(!out.isEmpty)
    }

    @Test("QA mode surfaces missing and unknown placeholders as sentinels")
    func qaModeSentinels() throws {
        let wasQA = NarrativeTemplateRenderer.qaModeEnabled
        NarrativeTemplateRenderer.qaModeEnabled = true
        defer { NarrativeTemplateRenderer.qaModeEnabled = wasQA }
        // Recognised-but-unfilled placeholder.
        let out1 = NarrativeTemplateRenderer.render(
            template: "A {personal_metal_1} piece.", context: [:])
        #expect(NarrativeTemplateRenderer.containsUnresolvedSentinels(out1))
        // Unknown placeholder.
        let out2 = NarrativeTemplateRenderer.render(
            template: "A {not_a_real_token} piece.", context: [:])
        #expect(out2.contains("⟦UNKNOWN:not_a_real_token⟧"))
    }
}

// MARK: - Phase 2d: Ranked domain tables

@Suite("SG-2 Phase 2d: ranked domain tables")
struct SG2RankedTablesTests {

    @Test("Ranked tables parse with full matrix coverage")
    func tablesParse() throws {
        let t = SG2.rankedTables()
        // 12 colour tables (3 temperatures × 4 lanes incl. water_dominant).
        #expect(t.coloursByRole.count == 12)
        // Textures: 3 registers + a distinct water_dominant lane.
        #expect(t.textures.count == 4)
        #expect(t.textures["water_dominant"] != nil)
        // Accessories: 3 registers × 3 orientations × 3 finish lanes = 27.
        #expect(t.accessorySpecs.count == 27)
    }

    @Test("Slate resolves to warm quietLuxury colour/texture/accessory tables")
    func slateResolves() throws {
        let loader = RankedDomainTablesLoader()
        _ = loader.loadFromURL(StyleGuideDataURL.rankedDomainTables())
        let slate = ChartAestheticProfile.derive(from: SG2.slateAnalysis())

        let colours = try #require(loader.colourTable(for: slate))
        // Slate's warm quietLuxury base includes the camel/toffee/olive family.
        let names = colours.neutrals.map { $0.name.lowercased() }.joined(separator: " ")
        #expect(names.contains("camel"))

        let textures = try #require(loader.textureTable(for: slate))
        #expect(textures.count >= 7)

        let accessories = try #require(loader.accessoryTable(for: slate))
        #expect(accessories.categories.count >= 3)
    }

    @Test("A bold profile resolves to different tables than Slate")
    func boldDiffersFromSlate() throws {
        let loader = RankedDomainTablesLoader()
        _ = loader.loadFromURL(StyleGuideDataURL.rankedDomainTables())
        let slate = ChartAestheticProfile.derive(from: SG2.slateAnalysis())
        let cinder = ChartAestheticProfile.coarseProfile(
            venusSign: "Leo", moonSign: "Aries", dominantElement: "fire")

        let slateColours = try #require(loader.colourTable(for: slate))
        let cinderColours = try #require(loader.colourTable(for: cinder))
        #expect(slateColours != cinderColours)
    }

    @Test("No profile combination hits an empty table lookup")
    func noEmptyLookups() throws {
        let loader = RankedDomainTablesLoader()
        _ = loader.loadFromURL(StyleGuideDataURL.rankedDomainTables())
        let temps: [ChartAestheticProfile.Temperature] = [.warm, .cool, .neutral]
        let registers: [ChartAestheticProfile.AestheticRegister] = [.quietLuxury, .boldExpression, .versatileAdaptive]
        let orientations: [ChartAestheticProfile.Orientation] = [.selfContained, .communityOriented, .balanced]
        let finishes: [ChartAestheticProfile.FinishLane] = [.muted, .polished, .mixed]

        for t in temps {
            for r in registers {
                for waterFlag in [false, true] {
                    let key = RankedDomainTablesLoader.colourKey(
                        temperature: t, register: r, isWaterDominant: waterFlag)
                    #expect(loader.tables?.coloursByRole[key] != nil, "missing colour \(key)")
                }
                #expect(loader.tables?.textures[r.rawValue] != nil, "missing texture \(r.rawValue)")
                for o in orientations {
                    for f in finishes {
                        let key = RankedDomainTablesLoader.accessoryKey(
                            register: r, orientation: o, finishLane: f)
                        #expect(loader.tables?.accessorySpecs[key] != nil, "missing accessory \(key)")
                    }
                }
            }
        }
    }
}

// MARK: - Phase 2d: formula_vocabulary 576-key coverage + parity

@Suite("SG-2 Phase 2d: formula vocabulary")
struct SG2FormulaVocabularyTests {

    /// The 12 core golden coarse keys → their authored formulas (README table).
    private static let goldenFormulas: [(venus: String, moon: String, element: String, formula: String)] = [
        ("Taurus", "Capricorn", "earth", "structure + softness + a touch of quiet depth"),        // Slate
        ("Aries", "Sagittarius", "fire", "clean impact + fast movement + one hot accent"),        // Ember
        ("Gemini", "Aquarius", "air", "crisp separation + mobile layers + one clever contrast"),   // Zephyr
        ("Cancer", "Scorpio", "water", "soft shelter + quiet undercurrent + one sentimental keepsake"), // Cove
        ("Sagittarius", "Leo", "fire", "expansive colour + athletic space + one theatrical finish"),   // Blaze
        ("Virgo", "Virgo", "earth", "precise fit + honest fabric + one meticulous detail"),        // Flint
        ("Aquarius", "Libra", "air", "clean geometry + cool composure + one polished signal"),      // Frost
        ("Pisces", "Pisces", "water", "weightless layers + blurred edges + one pearl of light"),    // Mist
        ("Capricorn", "Taurus", "earth", "enduring structure + sensory comfort + one living texture"), // Moss
        ("Leo", "Aries", "fire", "dark drama + sharp edges + one molten flash"),                    // Cinder
        ("Libra", "Gemini", "air", "balanced proportions + light movement + one refined touch"),    // Breeze
        ("Scorpio", "Cancer", "water", "close drape + hidden depth + one warm point of light"),     // Tide
    ]

    /// Mechanism anchors (guides 13-16) that exercise recombination.
    private static let recombinationFormulas: [(venus: String, moon: String, element: String, formula: String)] = [
        ("Taurus", "Pisces", "water", "soft structure + blurred edges + a touch of quiet depth"),   // Ripple
        ("Leo", "Capricorn", "earth", "quiet grandeur + softness + one molten flash"),              // Hearth
        ("Pisces", "Virgo", "air", "weightless layers + honest fabric + one pearl of light"),        // Loom
        ("Cancer", "Gemini", "fire", "soft shelter + light movement + one sentimental keepsake"),    // Wren
    ]

    @Test("All 576 coarse keys compose a register-consistent formula; Swift == dataset")
    func coverage576() throws {
        let ds = SG2.dataset()
        let fv = try #require(ds.formulaVocabulary, "dataset must ship formula_vocabulary")

        var total = 0
        // Per register: which distinct (venus,moon) source pairs map to each
        // formula string. A register-pure vocabulary maps each formula to
        // exactly one source pair (the water variant only re-flavours the
        // structure slot for the same venus, so it never collides across
        // different pairs).
        var formulaToPairs: [ChartAestheticProfile.AestheticRegister: [String: Set<String>]] = [:]

        for venus in SG2.allSigns {
            for moon in SG2.allSigns {
                for element in SG2.elements {
                    total += 1
                    let profile = ChartAestheticProfile.coarseProfile(
                        venusSign: venus, moonSign: moon, dominantElement: element)
                    let swift = FormulaVocabulary.compose(
                        venusSign: venus, moonSign: moon,
                        dominantElement: element, register: profile.aestheticRegister)
                    // Non-empty, three-part, register-consistent.
                    let parts = swift.components(separatedBy: " + ")
                    #expect(parts.count == 3, "malformed formula for \(venus)/\(moon)/\(element): \(swift)")
                    #expect(parts.allSatisfy { !$0.isEmpty })
                    #expect(swift == profile.coreFormula)
                    // Dataset parity: the JSON mirror composes identically.
                    let fromData = fv.compose(
                        venusSign: venus, moonSign: moon,
                        dominantElement: element, register: profile.aestheticRegister)
                    #expect(fromData == swift, "Swift/dataset drift at \(venus)/\(moon)/\(element)")

                    formulaToPairs[profile.aestheticRegister, default: [:]][swift, default: []]
                        .insert("\(venus)|\(moon)")
                }
            }
        }
        #expect(total == 576)

        // Purity + variety: within each register no formula string is produced
        // by two DIFFERENT (venus,moon) pairs (no vocabulary collision), and
        // each register yields many distinct formulas ("one formula per
        // register" is dead).
        for (register, map) in formulaToPairs {
            for (formula, pairs) in map {
                #expect(pairs.count == 1, "register \(register): formula '\(formula)' shared by \(pairs)")
            }
            #expect(map.count >= 30, "register \(register) has only \(map.count) distinct formulas")
        }
    }

    @Test("Every golden cluster reproduces its authored formula exactly")
    func goldenReproduction() throws {
        for g in Self.goldenFormulas + Self.recombinationFormulas {
            let profile = ChartAestheticProfile.coarseProfile(
                venusSign: g.venus, moonSign: g.moon, dominantElement: g.element)
            #expect(profile.coreFormula == g.formula,
                    "\(g.venus)/\(g.moon)/\(g.element): got '\(profile.coreFormula)', want '\(g.formula)'")
        }
    }
}

// MARK: - Phase 2.5: Cache schema v2 + composer wiring

@Suite("SG-2 Phase 2.5: cache schema v2")
struct SG2CacheSchemaTests {

    @Test("v1 cache (plain strings) still loads")
    func v1StillLoads() throws {
        let loader = NarrativeCacheLoader()
        #expect(loader.loadFromURL(StyleGuideDataURL.blueprintNarrativeCache()))
        #expect(loader.clusterCount > 0)
        #expect(loader.schemaVersion == 1)
    }

    @Test("A hand-built v2 entry loads with structured fields populated")
    func v2FixtureLoads() throws {
        let key = "venus_taurus__moon_capricorn__earth_dominant"
        let json = """
        {
          "schema_version": 2,
          "\(key)": {
            "coreFormula": "structure + softness + a touch of quiet depth",
            "closing": "your map of instincts.",
            "hardware_metals": {
              "text": "Warm gold sits against cool silver.",
              "sectionIntro": "Two registers, one wardrobe.",
              "rankedItems": [{"name":"yellow gold","role":"personal","useCase":"warm jewellery"}],
              "tests": ["pick it up: it should feel heavier than it looks"],
              "traps": [{"failure":"all one metal","fix":"split warm and cool"}]
            },
            "style_core": "You dress to feel aligned."
          }
        }
        """.data(using: .utf8)!
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sg2_v2_fixture_\(UUID().uuidString).json")
        try json.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let loader = NarrativeCacheLoader()
        #expect(loader.loadFromURL(url))
        #expect(loader.schemaVersion == 2)

        let keyResult = ArchetypeKeyGenerator.KeyGenerationResult(
            archetypeCluster: key, venusComponent: "venus_taurus",
            moonComponent: "moon_capricorn", elementComponent: "earth_dominant",
            usedFallback: false, fallbackLog: nil)
        let (structured, _, _) = loader.lookupStructured(keyResult: keyResult)
        let entry = try #require(structured)
        #expect(entry.coreFormula == "structure + softness + a touch of quiet depth")
        #expect(entry.closing == "your map of instincts.")
        let hw = try #require(entry.sections["hardware_metals"])
        #expect(hw.sectionIntro == "Two registers, one wardrobe.")
        #expect(hw.rankedItems?.first?.name == "yellow gold")
        #expect(hw.tests?.count == 1)
        #expect(hw.traps?.first?.fix == "split warm and cool")
        // v1 flat lookup still returns the section text.
        #expect(loader.lookupSection(section: .hardwareMetals, keyResult: keyResult)
                == "Warm gold sits against cool silver.")
    }

    @Test("Composer carries a v2 entry's fields into the CosmicBlueprint")
    func composerWiring() throws {
        let key = "venus_taurus__moon_capricorn__earth_dominant"
        let v2 = NarrativeStructuredEntry(
            sections: [
                "style_core": NarrativeStructuredSection(text: "Aligned."),
                "hardware_metals": NarrativeStructuredSection(
                    text: "Gold and silver.",
                    sectionIntro: "Two registers.",
                    rankedItems: [RankedItem(name: "yellow gold", role: "personal")],
                    tests: ["pick it up"],
                    traps: [Trap(failure: "monotone", fix: "split")])
            ],
            coreFormula: "structure + softness + a touch of quiet depth",
            closing: "your map of instincts.",
            schemaVersion: 2)

        let cache = NarrativeCacheLoader()
        cache.injectStructured([key: v2])

        let ds = SG2.dataset()
        let blueprint = BlueprintComposer.compose(
            chart: SG2.slateChart(), birthDate: Date(), birthLocation: "Athens",
            dataset: ds, narrativeCache: cache)

        #expect(blueprint.coreFormula == "structure + softness + a touch of quiet depth")
        #expect(blueprint.closing == "your map of instincts.")
        #expect(blueprint.hardware.sectionIntro == "Two registers.")
        #expect(blueprint.hardware.rankedItems?.first?.name == "yellow gold")
        #expect(blueprint.hardware.tests == ["pick it up"])
        #expect(blueprint.hardware.traps?.first?.failure == "monotone")
    }
}

// MARK: - Phase 2.5: Output-contract back-compat

@Suite("SG-2 Phase 2.5: output-contract back-compat")
struct SG2OutputContractTests {

    @Test("Pre-change blueprint JSON (no new fields) still decodes")
    func legacyBlueprintDecodes() throws {
        // Round-trip a blueprint whose new fields are nil, then strip the new
        // keys entirely from the JSON and decode again (simulating stored
        // pre-SG-2 data).
        let ds = SG2.dataset()
        let cache = NarrativeCacheLoader()
        _ = cache.loadFromURL(StyleGuideDataURL.blueprintNarrativeCache())
        let bp = BlueprintComposer.compose(
            chart: SG2.slateChart(), birthDate: Date(), birthLocation: "Athens",
            dataset: ds, narrativeCache: cache)

        let encoded = try JSONEncoder().encode(bp)
        var obj = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        obj.removeValue(forKey: "coreFormula")
        obj.removeValue(forKey: "closing")
        if var hw = obj["hardware"] as? [String: Any] {
            for k in ["personalMetals", "structuralMetals", "excludedFinishes",
                      "sectionIntro", "rankedItems", "tests", "traps"] {
                hw.removeValue(forKey: k)
            }
            obj["hardware"] = hw
        }
        let stripped = try JSONSerialization.data(withJSONObject: obj)
        let decoded = try JSONDecoder().decode(CosmicBlueprint.self, from: stripped)
        #expect(decoded.coreFormula == nil)
        #expect(decoded.hardware.personalMetals == nil)
        #expect(decoded.hardware.sectionIntro == nil)
    }

    @Test("New output-contract fields round-trip")
    func newFieldsRoundTrip() throws {
        let hw = HardwareSection(
            metalsText: "m", stonesText: "s", tipText: "t",
            recommendedMetals: ["gold"], personalMetals: ["gold"],
            structuralMetals: ["silver"], excludedFinishes: ["polished chrome"],
            recommendedStones: ["onyx"],
            sectionIntro: "intro", rankedItems: [RankedItem(name: "gold", role: "personal", useCase: "u")],
            tests: ["t1"], traps: [Trap(failure: "f", fix: "x")])
        let data = try JSONEncoder().encode(hw)
        let back = try JSONDecoder().decode(HardwareSection.self, from: data)
        #expect(back == hw)
    }
}

// MARK: - Phase 2e: Palette temperature floor (Layer A)

@Suite("SG-2 Phase 2e: palette temperature")
struct SG2PaletteTemperatureTests {

    private func input(
        asc: V4ZodiacSign, venus: V4ZodiacSign, sun: V4ZodiacSign, moon: V4ZodiacSign,
        mercury: V4ZodiacSign = .taurus, mars: V4ZodiacSign = .taurus,
        saturn: V4ZodiacSign = .capricorn, jupiter: V4ZodiacSign = .taurus,
        pluto: V4ZodiacSign? = .scorpio
    ) -> BirthChartColourInput {
        BirthChartColourInput(
            ascendant: PlacementInput(sign: asc), venus: PlacementInput(sign: venus),
            sun: PlacementInput(sign: sun), moon: PlacementInput(sign: moon),
            mercury: PlacementInput(sign: mercury), mars: PlacementInput(sign: mars),
            saturn: PlacementInput(sign: saturn), jupiter: PlacementInput(sign: jupiter),
            pluto: pluto.map { PlacementInput(sign: $0) }, midheaven: nil)
    }

    @Test("Venus element sets the temperature floor per the SG-1 table")
    func floorMapping() {
        #expect(Overrides.venusTemperatureFloor(input: input(asc: .pisces, venus: .taurus, sun: .taurus, moon: .capricorn)) == .warm)
        #expect(Overrides.venusTemperatureFloor(input: input(asc: .pisces, venus: .scorpio, sun: .taurus, moon: .capricorn)) == .warm) // warm-deep
        #expect(Overrides.venusTemperatureFloor(input: input(asc: .pisces, venus: .virgo, sun: .taurus, moon: .capricorn)) == .neutral)
        #expect(Overrides.venusTemperatureFloor(input: input(asc: .pisces, venus: .pisces, sun: .taurus, moon: .capricorn)) == .cool)
    }

    @Test("A warm Venus floor remaps a cool-deep family to Deep Autumn; a cool Venus is untouched")
    func warmFloorRemap() {
        var flags = OverrideFlags()
        let slateLike = input(asc: .pisces, venus: .taurus, sun: .taurus, moon: .capricorn)
        #expect(Overrides.applyVenusWarmFloor(family: .deepWinter, input: slateLike, flags: &flags) == .deepAutumn)
        #expect(flags.venusWarmFloorApplied)
        // A warm chart already in a warm family is unchanged.
        var flags2 = OverrideFlags()
        #expect(Overrides.applyVenusWarmFloor(family: .deepAutumn, input: slateLike, flags: &flags2) == .deepAutumn)
        #expect(!flags2.venusWarmFloorApplied)
        // A cool Venus (Pisces) is never flipped warm.
        var flags3 = OverrideFlags()
        let coolLike = input(asc: .pisces, venus: .pisces, sun: .pisces, moon: .cancer)
        #expect(Overrides.applyVenusWarmFloor(family: .deepWinter, input: coolLike, flags: &flags3) == .deepWinter)
        #expect(!flags3.venusWarmFloorApplied)
    }

    @Test("Slate's V4 palette reads warm and deep (flip fixed, depth kept)")
    func slateWarmDeep() throws {
        let ds = SG2.dataset()
        let cache = NarrativeCacheLoader()
        _ = cache.loadFromURL(StyleGuideDataURL.blueprintNarrativeCache())
        let bp = BlueprintComposer.compose(
            chart: SG2.slateChart(), birthDate: Date(), birthLocation: "Athens",
            dataset: ds, narrativeCache: cache)
        let vars = try #require(bp.palette.variables)
        #expect(vars.temperature == .warm, "Slate temperature should be warm, got \(vars.temperature)")
        #expect(vars.depth == .deep, "Slate depth should stay deep, got \(vars.depth)")
    }
}
