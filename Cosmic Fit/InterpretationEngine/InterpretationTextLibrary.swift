//
//  InterpretationTextLibrary.swift
//  Cosmic Fit
//
//  Created for separating text content from logic
//

import Foundation

/// Centralized library for all interpretation text content
struct InterpretationTextLibrary {
    
    // MARK: - Blueprint Text Content
    
    struct Blueprint {
        
        // MARK: - Essence Section Text
        struct Essence {
            static let earthyIntuitive = "You walk the line between earth and ether, rooted yet always sensing something deeper. "
            static let earthyOnly = "You embody a grounded presence, drawing strength from what feels stable and real. "
            static let fluidOnly = "There's a flowing energy to your presence that's adaptable, intuitive, and subtly responsive. "
            static let boldOnly = "You project a confident energy that leaves an impression—unmistakable, defined, and purposeful. "
            static let defaultEssence = "Your style essence balances personal expression with authentic presence. "
            
            static let compellingForce = "compelling force in your presence, a clear kind of intention. "
            static let quietForce = "quiet force in your presence, a soft kind of defiance. "
            
            static let energyNotSubtle = "subtle, but it resonates deeply. "
            static let energyNotLoud = "loud, but it lingers meaningfully. "
            
            static let dreamsDressing = "You dress like someone who remembers dreams and honors them through "
            static let versionsDressing = "You dress like someone who remembers every version of yourself and honors them through "
            
            static let dressingMedium = "texture, color, and the way fabric falls. This blueprint reflects a wardrobe built on "
            static let defaultClosing = "intuition, integrity, and evolution."
        }
        
        // MARK: - Core Section Text
        struct Core {
            static let elementDescriptors = [
                "earth": ["grounded", "instinctual", "tactile"],
                "water": ["intuitive", "flowing", "receptive"],
                "fire": ["passionate", "energetic", "expressive"],
                "air": ["communicative", "versatile", "intellectual"],
                "balanced": ["balanced", "harmonious", "multifaceted"]
            ]
            
            static let foundationTexts = [
                "earth": "your foundation is built on clothing that feels like home.",
                "water": "your foundation is built on clothing that flows with your emotions.",
                "fire": "your foundation is built on clothing that expresses your energy.",
                "air": "your foundation is built on clothing that adapts to your social contexts.",
                "balanced": "your foundation is built on clothing that balances multiple aspects of your identity."
            ]
        }
        
        // MARK: - Expression Section Text
        struct Expression {
            static let cardinalVenus = "Directed and intentional"
            static let fixedVenus = "Consistent and defined"
            static let mutableVenus = "Adaptable and fluid"
            static let defaultExpression = "Personal and authentic"
            
            static let intentionStyles = [
                "subtlePractical": "subtle edge with practical intention",
                "subtleCreative": "subtle creativity with artistic intention",
                "boldPractical": "bold presence with practical intention",
                "boldCreative": "bold creativity with expressive intention",
                "subtle": "subtle nuance with personal intention",
                "bold": "bold statement with personal intention",
                "practical": "practical approach with functional intention",
                "creative": "creative flair with artistic intention",
                "default": "personal style with authentic intention"
            ]
            
            static let choosingClothes = "You choose clothes that do more than look good—they "
            
            static let purposeEndings = [
                "practical": "serve a purpose, adapt to your needs, and support your daily journey.",
                "creative": "tell a story, evoke emotion, and reflect your creative spirit.",
                "subtle": "hold weight, memory, and meaning beyond what others might notice.",
                "default": "express your authentic self and communicate your presence."
            ]
        }
        
        // MARK: - Magnetism Section Text
        struct Magnetism {
            static let magnetismQualities = [
                "quietDeep": "Quiet strength and depth",
                "subtlePlayful": "Subtle playfulness and charm",
                "powerfulDeep": "Powerful presence and depth",
                "radiantPlayful": "Radiant charisma and playfulness",
                "quietDefault": "Subtle presence and authenticity",
                "boldDefault": "Bold energy and confidence",
                "deepDefault": "Deep resonance and substance",
                "playfulDefault": "Playful spirit and versatility",
                "default": "Authentic presence and natural appeal"
            ]
            
            static let lureNuances = [
                "venus": " (Visually harmonious and naturally relational).",
                "moon": " (Emotionally resonant and naturally inviting).",
                "visual": " (Poised for connection—one‑to‑one interactions feel immediate).",
                "balanced": "."
            ]
            
            static let impactTexts = [
                "quiet": "People may not always notice your outfit first, but they remember how it felt.",
                "bold": "Your style creates an immediate impression that lingers in others' memories."
            ]
            
            static let retrogradeUndertone = " A retrograde undertone makes the allure contemplative—others sense unspoken stories."
        }
        
        // MARK: - Emotional Dressing Text
        struct EmotionalDressing {
            static let emotionalStyles = [
                "honestEmotional": "You dress as a form of honest self‑reflection—truthful, tactile, and emotionally expressive.",
                "emotionalProtective": "You dress as emotional protection—creating a safe boundary between your sensitive core and the outside world.",
                "emotionalIntuitive": "You dress intuitively, in harmony with emotional currents—flowing, responsive, and personal.",
                "protective": "Your clothing creates a protective boundary, regulating how much of yourself you share.",
                "intuitive": "You follow intuition, aligning inner landscape with outer expression.",
                "emotional": "Your choices reflect your emotional state, expressing your inner world.",
                "honest": "Your style reflects a commitment to authenticity, choosing pieces that resonate with your true self.",
                "default": "You balance emotional expression with practical considerations."
            ]
            
            static let lunarNeptunianEndings = [
                "moonDominant": " Emotional comfort and security are consistently your first checkpoints when dressing.",
                "neptuneDominant": " A dreamlike, imaginative quality consistently influences how you clothe yourself.",
                "balanced": " You balance emotional comfort with artistic imagination—clothes feel like living, breathing memories."
            ]
        }
        
        // MARK: - Planetary Frequency Text
        struct PlanetaryFrequency {
            static let elementalDescriptions = [
                "earth": "You are drawn to what feels lived-in, weathered, and raw—with details that speak softly but stay.",
                "water": "You are drawn to what flows, adapts, and carries emotional resonance—with details that evoke feeling and memory.",
                "fire": "You are drawn to what energizes, transforms, and expresses vitality—with details that catch the light and command attention.",
                "air": "You are drawn to what communicates, connects, and conceptualizes—with details that stimulate the mind and facilitate exchange.",
                "metal": "You are drawn to what endures, structures, and refines—with details that demonstrate craftsmanship and longevity.",
                "balanced": "You are drawn to a balance of elements—incorporating details that address multiple sensory and emotional needs."
            ]
        }
        
        // MARK: - Style Tensions Text
        struct StyleTensions {
            static let tensionPairs: [(String, String, String)] = [
                ("fluid", "structured", "A tension between flow and form—your outfits might oscillate between surrender and definition."),
                ("intuitive", "practical", "You sense your way through style, but also crave function. Dressing may feel like balancing instinct and purpose."),
                ("minimal", "expressive", "You prefer restraint, yet there's a desire to be seen. Your look may shift between quiet and pronounced."),
                ("airy", "grounded", "Your chart straddles weightlessness and rootedness—a dialogue between freedom and stability."),
                ("bold", "reserved", "Sometimes loud, sometimes soft. You dress to declare—and sometimes to disappear."),
                ("emotive", "cool", "You feel deeply, but show selectively. Style becomes a method of managing what's seen."),
                ("playful", "serious", "You oscillate between lighthearted expression and grounded purpose in how you present yourself."),
                ("luxurious", "minimal", "A pull between lavish richness and clean simplicity—your style negotiates abundance and restraint."),
                ("vibrant", "muted", "Your wardrobe might swing between saturated statements and quiet neutrals as you balance visibility and subtlety."),
                ("classic", "experimental", "You honor tradition while craving novelty—your style weaves between timeless pieces and unexpected choices."),
                ("soft", "structured", "Your chart balances yielding textures with architectural forms—a conversation between comfort and definition.")
            ]
            
            static let noTensions = "Your style shows a harmonious integration of elements without significant opposing tensions. Your chart suggests a natural coherence between different aspects of your style expression."
            
            static let tensionsIntro = "Your chart reveals meaningful tensions that add depth to your style profile:\n\n"
            
            static let tensionsClosing = "\n\nThese contrasts aren't flaws—they're dimensions. The most compelling personal style emerges from resolving these creative tensions in ways that feel authentic to you."
        }
        
        // MARK: - Fabric Guide Text
        struct FabricGuide {
            static let fabricCollections = [
                "earthy": ["raw denim", "washed cotton", "linen"],
                "watery": ["silk", "rayon", "modal"],
                "fiery": ["wool", "leather", "textured knits"],
                "airy": ["cotton voile", "lightweight linen", "gauze"],
                "soft": ["cashmere", "brushed cotton", "jersey"],
                "luxurious": ["silk", "cashmere", "fine wool"],
                "practical": ["cotton", "wool", "linen"],
                "sensual": ["velvet", "silk", "soft leather"]
            ]
            
            static let textureCollections = [
                "earthy": ["nubby", "coarse", "textured"],
                "watery": ["flowing", "draping", "liquid"],
                "fiery": ["ribbed", "raised", "structured"],
                "airy": ["light", "breathable", "translucent"],
                "soft": ["plush", "brushed", "velvety"],
                "structured": ["crisp", "substantial", "supportive"],
                "fluid": ["flowing", "draping", "liquid"],
                "textured": ["varied", "tactile", "dimensional"]
            ]
            
            static let depletingFabrics = [
                "structured": ["unstructured synthetics"],
                "fluid": ["stiff brocades", "crisp organiza"],
                "textured": ["flat synthetics"],
                "default": ["high-shine synthetics", "overly processed materials", "fabrics that restrict movement"]
            ]
            
            static let defaultNourishing = ["natural fibers", "breathable cotton", "textured weaves"]
            static let defaultGrounding = ["tactile", "natural", "dimensional"]
            static let defaultActivating = ["structured", "crisp", "defined"]
        }
        
        // MARK: - Style Pulse Text
        struct StylePulse {
            static let sensoryPriorities = [
                "texture": "Texture and feel first; how clothing rests on the body is more important than how it photographs.",
                "visual": "Visual impact first; how clothing appears and communicates is your primary consideration.",
                "comfort": "Comfort and function first; how clothing performs and feels during daily activities guides your choices.",
                "balanced": "Balance of sensory experiences; you consider both how clothing feels and how it presents visually."
            ]
            
            static let journeyStarts = [
                "moonVenusHard": "From rebellious self-protection to embodied self-expression, ",
                "northNodeStyle": "From seeking external validation to authentic self-discovery, ",
                "plutoSaturn": "From controlled presentation to empowered self-mastery, ",
                "default": "From exploration to refinement, "
            ]
            
            static let journeyEndings = [
                "grounded": "Your evolution has been steady, soulful, and deeply felt.",
                "passionate": "Your evolution has been energetic, transformative, and boldly expressed.",
                "adaptable": "Your evolution has been thoughtful, communicative, and always evolving.",
                "sensitive": "Your evolution has been intuitive, responsive, and emotionally attuned.",
                "default": "Your evolution has been personal, meaningful, and authentically yours."
            ]
            
            static let progressedEvolution = "you've been evolving toward a more "
            
            static let progressedDirections = [
                "fire": "energized and expressive style. ",
                "earth": "grounded and practical style. ",
                "air": "intellectual and communicative style. ",
                "water": "intuitive and emotionally responsive style. ",
                "default": "authentic personal style. "
            ]
        }
        
        // MARK: - Fashion Guidance Text
        struct FashionGuidance {
            static let leanIntoItems = [
                "layered": "layering with intention",
                "comfortable": "structured comfort",
                "bold": "expressive details",
                "earthy": "warm neutrals",
                "slow": "slow fashion",
                "textured": "textured surfaces",
                "vintage": "reworking pieces",
                "balanced": "balanced proportions"
            ]
            
            static let releaseItems = [
                "structuredNotFluid": "overly fluid silhouettes that lack definition",
                "fluidNotStructured": "stiff silhouettes that ignore your rhythm",
                "minimalNotMaximal": "overly decorative or busy patterns",
                "maximalNotMinimal": "excessively minimal pieces that lack character",
                "matteNotShiny": "anything high-shine or overly polished",
                "shinyNotMatte": "flat, textureless fabrics that lack depth",
                "modestNotRevealing": "overly revealing pieces that create discomfort",
                "revealingNotModest": "unnecessarily concealing layers that hide your natural form"
            ]
            
            static let generalReleases = [
                "authentic": ["trend-driven looks that don't resonate personally"],
                "intentional": ["impulse purchases without consideration for longevity"],
                "default": ["overly trend-driven looks", "pieces that don't feel authentic to you", "fast fashion without personal meaning"]
            ]
            
            static let watchOutFor = [
                "subtle": "Mistaking simplicity for invisibility. You can be subtle and still be seen.",
                "bold": "Confusing loudness with impact. True power can be focused and intentional.",
                "practical": "Sacrificing beauty for function. The two can and should coexist.",
                "unique": "Pursuing originality at the expense of wearability. Your best pieces will be both unique and practical.",
                "default": "Letting external expectations override your authentic preferences. Your style is most powerful when it's truly yours."
            ]
        }
        
        // MARK: - Color Recommendations Text
        struct ColorRecommendations {
            static let elementalColors = [
                "earthy": ["olive", "terracotta", "moss", "ochre", "walnut", "sand", "umber"],
                "watery": ["navy ink", "teal", "indigo", "slate blue", "stormy gray", "deep aqua"],
                "airy": ["pale blue", "silver gray", "cloud white", "light lavender", "sky"],
                "fiery": ["oxblood", "rust", "amber", "burnt orange", "burgundy", "ruby"]
            ]
            
            static let defaultColors = ["stone", "navy", "charcoal", "cream"]
            static let defaultPowerColors = ["deep indigo", "matte silver", "burgundy"]
            static let defaultCurrentPhase = ["muted sage", "faded black", "soft cream"]
        }
        
        // MARK: - Wardrobe Storyline Text
        struct WardrobeStoryline {
            static let pastArcs = [
                "moonVenusOr8th12th": "Style as armour—layers that protected and defined your identity. ",
                "fixed": "Style as definition—consistent elements that established your visual identity. ",
                "default": "Style as exploration—trying different approaches to discover what resonates. "
            ]
            
            static let pastArcEndings = [
                "moonVenusFixed": "Edgy, expressive, unafraid to resist the mainstream.",
                "moonVenusDefault": "Distinctive, personal, with elements that kept others at a distance when needed.",
                "fixed": "Reliable, recognizable, with signature pieces that became your calling card.",
                "default": "Varied, experimental, with phases that reflected your evolving sense of self."
            ]
            
            static let presentPhases = [
                "progressedMoonVenus": "Emotionally attuned and aesthetically refined. Your current phase integrates emotional awareness with visual harmony. You're drawn to pieces that reflect your inner state while maintaining a cohesive visual language.",
                "progressedMoon": "Emotionally responsive and intuitive. Your current phase prioritizes how clothing feels on multiple levels. You're drawn to pieces that support your emotional well-being and inner sense of security.",
                "progressedVenus": "Aesthetically evolved and relationally aware. Your current phase emphasizes visual harmony and social connection. You're drawn to pieces that communicate your values while creating meaningful impression.",
                "earth": "Streamlined and intentional. You know what suits your energy, and you choose with care. Fewer pieces, stronger presence.",
                "balanced": "Harmonious and integrated. You've found balance between different aspects of your style. Versatile, adaptable, with pieces that work together in multiple ways.",
                "intentional": "Refined and purposeful. Your choices reflect deeper considerations about quality and impact. Thoughtful curation, meaningful selection.",
                "default": "Authentic and present. Your style reflects who you are now, not who you were or should be. Honest, current, responsive to your actual life."
            ]
            
            static let emergingChapters = [
                "progressedAscMC": "Evolution of self-expression and public identity. As your ascendant ",
                "both": "and midheaven progress, you're entering a phase where both personal and public expression are shifting. ",
                "ascendant": "progresses, you're entering a phase of renewed self-definition and personal presence. ",
                "mc": "evolves, you're entering a phase of reconnection with your public role and visible impact. ",
                "integration": "This chapter invites conscious integration of evolving identity with enduring essence.",
                "transformative": "Reclamation and refinement. You're honoring the past versions of yourself through custom, quality, and a slow, soulful approach to style.",
                "innovative": "Innovation and personalization. You're moving toward more custom, unique expressions that integrate technical advances with personal meaning.",
                "authentic": "Authenticity and integrity. You're evolving toward choices that align deeply with your values, prioritizing ethical production and personal resonance.",
                "default": "Integration and evolution. You're bringing together the most resonant elements of past phases while staying open to new approaches that honor your current self."
            ]
        }
    }
    
    // MARK: - Token Generation Text Content
    
    struct TokenGeneration {
        
        // MARK: - Planet in Sign Descriptions
        struct PlanetInSign {
            
            // MARK: - Sun in Signs
            struct Sun {
                static let descriptions = [
                    "Aries": [
                        ("bold", "mood"), ("dynamic", "structure"), ("bright red", "color"), ("vibrant", "color_quality")
                    ],
                    "Taurus": [
                        ("luxurious", "texture"), ("sage green", "color"), ("rose", "color"), ("tactile", "color_quality")
                    ],
                    "Gemini": [
                        ("playful", "mood"), ("versatile", "structure"), ("yellow", "color"), ("bright", "color_quality")
                    ],
                    "Cancer": [
                        ("protective", "structure"), ("flowing", "texture"), ("pearl", "color"), ("nautical", "color_quality")
                    ],
                    "Leo": [
                        ("radiant", "mood"), ("expressive", "structure"), ("gold", "color"), ("warm", "color_quality")
                    ],
                    "Virgo": [
                        ("refined", "mood"), ("practical", "structure"), ("wheat", "color"), ("precise", "color_quality")
                    ],
                    "Libra": [
                        ("balanced", "structure"), ("harmonious", "color"), ("rose pink", "color"), ("elegant", "color_quality")
                    ],
                    "Scorpio": [
                        ("magnetic", "mood"), ("leather", "texture"), ("black", "color"), ("powerful", "color_quality")
                    ],
                    "Sagittarius": [
                        ("expansive", "structure"), ("adventurous", "mood"), ("royal blue", "color"), ("vibrant", "color_quality")
                    ],
                    "Capricorn": [
                        ("structured", "structure"), ("enduring", "texture"), ("charcoal", "color"), ("classic", "color_quality")
                    ],
                    "Aquarius": [
                        ("innovative", "structure"), ("distinctive", "mood"), ("electric blue", "color"), ("unique", "color_quality")
                    ],
                    "Pisces": [
                        ("fluid", "structure"), ("dreamy", "mood"), ("seafoam", "color"), ("flowing", "color_quality")
                    ]
                ]
            }
            
            // MARK: - Moon in Signs
            struct Moon {
                static let descriptions = [
                    "Aries": [
                        ("energetic", "mood"), ("impulsive", "texture"), ("coral red", "color"), ("warm", "color_quality")
                    ],
                    "Taurus": [
                        ("quality", "texture"), ("grounded", "mood"), ("warm brown", "color"), ("enduring", "color_quality")
                    ],
                    "Gemini": [
                        ("adaptable", "structure"), ("communicative", "mood"), ("pale yellow", "color"), ("bright", "color_quality")
                    ],
                    "Cancer": [
                        ("nurturing", "texture"), ("emotional", "mood"), ("pearl", "color"), ("luminous", "color_quality")
                    ],
                    "Leo": [
                        ("warm", "color"), ("dramatic", "structure"), ("amber", "color"), ("radiant", "color_quality")
                    ],
                    "Virgo": [
                        ("detailed", "structure"), ("thoughtful", "mood"), ("taupe", "color"), ("precise", "color_quality")
                    ],
                    "Libra": [
                        ("elegant", "structure"), ("social", "mood"), ("lavender", "color"), ("harmonious", "color_quality")
                    ],
                    "Scorpio": [
                        ("structured", "color"), ("leather", "texture"), ("burgundy", "color"), ("intense", "color_quality")
                    ],
                    "Sagittarius": [
                        ("optimistic", "mood"), ("free-spirited", "structure"), ("indigo", "color"), ("deep", "color_quality")
                    ],
                    "Capricorn": [
                        ("grounded", "mood"), ("reserved", "structure"), ("slate gray", "color"), ("solid", "color_quality")
                    ],
                    "Aquarius": [
                        ("unique", "structure"), ("independent", "mood"), ("turquoise", "color"), ("innovative", "color_quality")
                    ],
                    "Pisces": [
                        ("soft", "texture"), ("intuitive", "mood"), ("seafoam", "color"), ("dreamy", "color_quality")
                    ]
                ]
            }
            
            // MARK: - Venus in Signs
            struct Venus {
                static let descriptions = [
                    "Aries": [
                        ("spontaneous", "structure"), ("bold", "color"), ("coral", "color"), ("dynamic", "color_quality")
                    ],
                    "Taurus": [
                        ("indulgent", "texture"), ("sensual", "mood"), ("cream", "color"), ("luxurious", "color_quality")
                    ],
                    "Gemini": [
                        ("eclectic", "structure"), ("playful", "color"), ("peach", "color"), ("varied", "color_quality")
                    ],
                    "Cancer": [
                        ("nostalgic", "mood"), ("nurturing", "texture"), ("cream", "color"), ("soft", "color_quality")
                    ],
                    "Leo": [
                        ("glamorous", "structure"), ("vibrant", "color"), ("warm gold", "color"), ("radiant", "color_quality")
                    ],
                    "Virgo": [
                        ("subtle", "color"), ("refined", "structure"), ("sage", "color"), ("precise", "color_quality")
                    ],
                    "Libra": [
                        ("harmonious", "structure"), ("balanced", "color"), ("rose quartz", "color"), ("elegant", "color_quality")
                    ],
                    "Scorpio": [
                        ("magnetic", "mood"), ("power", "structure"), ("black", "color"), ("controlled", "color_quality")
                    ],
                    "Sagittarius": [
                        ("exuberant", "mood"), ("expansive", "color"), ("teal", "color"), ("vivid", "color_quality")
                    ],
                    "Capricorn": [
                        ("elegant", "structure"), ("classic", "texture"), ("merlot", "color"), ("timeless", "color_quality")
                    ],
                    "Aquarius": [
                        ("unconventional", "structure"), ("futuristic", "texture"), ("periwinkle", "color"), ("innovative", "color_quality")
                    ],
                    "Pisces": [
                        ("romantic", "mood"), ("dreamy", "texture"), ("lilac", "color"), ("ethereal", "color_quality")
                    ]
                ]
            }
            
            // MARK: - Mars in Signs
            struct Mars {
                static let descriptions = [
                    "Aries": [
                        ("assertive", "structure"), ("energetic", "texture"), ("crimson", "color"), ("bold", "color_quality")
                    ],
                    "Taurus": [
                        ("enduring", "texture"), ("substantial", "structure"), ("rust", "color"), ("earthy", "color_quality")
                    ],
                    "Gemini": [
                        ("versatile", "structure"), ("quick", "texture"), ("bright yellow", "color"), ("dynamic", "color_quality")
                    ],
                    "Cancer": [
                        ("protective", "structure"), ("soft", "texture"), ("white", "color"), ("gentle", "color_quality")
                    ],
                    "Leo": [
                        ("confident", "structure"), ("bold", "color"), ("copper", "color"), ("radiant", "color_quality")
                    ],
                    "Virgo": [
                        ("precise", "structure"), ("detailed", "texture"), ("brick red", "color"), ("structured", "color_quality")
                    ],
                    "Libra": [
                        ("balanced", "structure"), ("harmonious", "mood"), ("rose", "color"), ("balanced", "color_quality")
                    ],
                    "Scorpio": [
                        ("deep", "color"), ("power", "structure"), ("black", "color"), ("magnetic", "color_quality")
                    ],
                    "Sagittarius": [
                        ("adventurous", "structure"), ("expansive", "texture"), ("purple", "color"), ("dynamic", "color_quality")
                    ],
                    "Capricorn": [
                        ("disciplined", "structure"), ("enduring", "texture"), ("dark brown", "color"), ("structured", "color_quality")
                    ],
                    "Aquarius": [
                        ("innovative", "structure"), ("progressive", "mood"), ("electric blue", "color"), ("unique", "color_quality")
                    ],
                    "Pisces": [
                        ("fluid", "texture"), ("adaptive", "structure"), ("sea blue", "color"), ("flowing", "color_quality")
                    ]
                ]
            }
            
            // MARK: - Mercury in Signs
            struct Mercury {
                static let descriptions = [
                    "Aries": [
                        ("direct", "communication"), ("quick", "pace"), ("clear red", "color"), ("crisp", "color_quality")
                    ],
                    "Taurus": [
                        ("deliberate", "communication"), ("practical", "approach"), ("olive", "color"), ("textured", "color_quality")
                    ],
                    "Gemini": [
                        ("versatile", "communication"), ("curious", "approach"), ("yellow", "color"), ("varied", "color_quality")
                    ],
                    "Cancer": [
                        ("intuitive", "communication"), ("receptive", "approach"), ("silver gray", "color"), ("nuanced", "color_quality")
                    ],
                    "Leo": [
                        ("expressive", "communication"), ("confident", "approach"), ("golden yellow", "color"), ("distinct", "color_quality")
                    ],
                    "Virgo": [
                        ("precise", "communication"), ("analytical", "approach"), ("wheat", "color"), ("precise", "color_quality")
                    ],
                    "Libra": [
                        ("balanced", "communication"), ("diplomatic", "approach"), ("pastel pink", "color"), ("balanced", "color_quality")
                    ],
                    "Scorpio": [
                        ("penetrating", "communication"), ("strategic", "approach"), ("deep burgundy", "color"), ("intense", "color_quality")
                    ],
                    "Sagittarius": [
                        ("expansive", "communication"), ("optimistic", "approach"), ("blue", "color"), ("clear", "color_quality")
                    ],
                    "Capricorn": [
                        ("structured", "communication"), ("disciplined", "approach"), ("charcoal", "color"), ("defined", "color_quality")
                    ],
                    "Aquarius": [
                        ("innovative", "communication"), ("objective", "approach"), ("electric blue", "color"), ("unique", "color_quality")
                    ],
                    "Pisces": [
                        ("intuitive", "communication"), ("imaginative", "approach"), ("sea green", "color"), ("blended", "color_quality")
                    ]
                ]
            }
            
            // MARK: - Outer Planets
            struct OuterPlanets {
                static let neptune = [
                    ("opalescent blue", "color"), ("mermaid teal", "color"), ("misty lavender", "color"),
                    ("ethereal", "color_quality"), ("dreamlike", "color_quality")
                ]
                
                static let pluto = [
                    ("abyssal black", "color"), ("plutonium purple", "color"),
                    ("transformative", "color_quality"), ("intense", "color_quality")
                ]
                
                static let jupiter = [
                    ("royal purple", "color"), ("abundant indigo", "color"),
                    ("expansive", "color_quality"), ("abundant", "color_quality")
                ]
                
                static let saturn = [
                    ("structured charcoal", "color"), ("leaden grey", "color"),
                    ("disciplined", "color_quality"), ("enduring", "color_quality")
                ]
                
                static let uranus = [
                    ("electric blue", "color"), ("neon turquoise", "color"),
                    ("unexpected", "color_quality"), ("innovative", "color_quality")
                ]
            }
            
            // MARK: - Elemental Fallbacks
            struct ElementalFallbacks {
                static let fire = [
                    ("fiery", "mood"), ("warm bronze", "color"), ("vibrant", "color_quality")
                ]
                
                static let earth = [
                    ("earthy", "mood"), ("rich brown", "color"), ("grounded", "color_quality")
                ]
                
                static let air = [
                    ("airy", "mood"), ("clear azure", "color"), ("light", "color_quality")
                ]
                
                static let water = [
                    ("watery", "mood"), ("oceanic teal", "color"), ("fluid", "color_quality")
                ]
            }
            
            // MARK: - Retrograde Modifications
            struct Retrograde {
                static let general = [
                    ("muted", "color_quality"), ("contemplative", "color_quality"), ("vintage", "color_quality")
                ]
                
                static let venus = [("faded rose", "color")]
                static let mars = [("smoldering brick", "color")]
                static let mercury = [("misty grey", "color")]
            }
        }
        
        // MARK: - Ascendant Descriptions
        struct Ascendant {
            static let descriptions = [
                "Aries": [
                    ("bold", "expression"), ("direct", "structure"), ("vibrant crimson", "color"), ("dynamic", "color_quality")
                ],
                "Taurus": [
                    ("stable", "structure"), ("sensual", "texture"), ("rich moss green", "color"), ("substantial", "color_quality")
                ],
                "Gemini": [
                    ("versatile", "structure"), ("communicative", "expression"), ("bright lemon yellow", "color"), ("versatile", "color_quality")
                ],
                "Cancer": [
                    ("protective", "structure"), ("nurturing", "expression"), ("luminous silver", "color"), ("reflective", "color_quality")
                ],
                "Leo": [
                    ("expressive", "structure"), ("radiant", "expression"), ("regal gold", "color"), ("commanding", "color_quality")
                ],
                "Virgo": [
                    ("precise", "structure"), ("refined", "texture"), ("warm taupe", "color"), ("refined", "color_quality")
                ],
                "Libra": [
                    ("balanced", "structure"), ("harmonious", "expression"), ("delicate blush pink", "color"), ("elegant", "color_quality")
                ],
                "Scorpio": [
                    ("intense", "expression"), ("transformative", "structure"), ("deep oxblood", "color"), ("magnetic", "color_quality")
                ],
                "Sagittarius": [
                    ("expansive", "structure"), ("adventurous", "expression"), ("rich indigo", "color"), ("expansive", "color_quality")
                ],
                "Capricorn": [
                    ("structured", "structure"), ("disciplined", "expression"), ("polished graphite", "color"), ("authoritative", "color_quality")
                ],
                "Aquarius": [
                    ("innovative", "structure"), ("unique", "expression"), ("electric cerulean", "color"), ("futuristic", "color_quality")
                ],
                "Pisces": [
                    ("fluid", "structure"), ("intuitive", "expression"), ("iridescent aqua", "color"), ("dreamy", "color_quality")
                ]
            ]
        }
        
        // MARK: - House Placements
        struct Houses {
            static let descriptions = [
                1: [
                    ("visible", "expression"), ("defining", "structure"), ("vibrant", "color_quality")
                ],
                2: [
                    ("tactile", "texture"), ("substantial", "structure"), ("rich", "color_quality")
                ],
                3: [
                    ("communicative", "expression"), ("adaptable", "structure"), ("varied", "color_quality")
                ],
                4: [
                    ("comforting", "texture"), ("grounded", "structure"), ("soft", "color_quality")
                ],
                5: [
                    ("playful", "expression"), ("expressive", "structure"), ("vibrant", "color_quality")
                ],
                6: [
                    ("practical", "structure"), ("functional", "texture"), ("precise", "color_quality")
                ],
                7: [
                    ("balanced", "structure"), ("harmonious", "expression"), ("harmonious", "color_quality")
                ],
                8: [
                    ("intense", "expression"), ("transformative", "structure"), ("deep", "color_quality")
                ],
                9: [
                    ("expansive", "structure"), ("cultural", "expression"), ("rich", "color_quality")
                ],
                10: [
                    ("authoritative", "structure"), ("polished", "texture"), ("structured", "color_quality")
                ],
                11: [
                    ("unconventional", "structure"), ("innovative", "expression"), ("unique", "color_quality")
                ],
                12: [
                    ("mystical", "expression"), ("fluid", "structure"), ("dreamy", "color_quality")
                ]
            ]
        }
        
        // MARK: - Elemental Balance
        struct ElementalBalance {
            static let descriptions = [
                "fire": [
                    ("blazing vermilion", "color"), ("warm amber", "color"), ("burnished copper", "color"),
                    ("vibrant", "color_quality"), ("energetic", "color_quality")
                ],
                "earth": [
                    ("rich olive", "color"), ("warm terracotta", "color"), ("deep moss", "color"),
                    ("grounded", "color_quality"), ("tactile", "color_quality")
                ],
                "air": [
                    ("clear azure", "color"), ("luminous silver", "color"), ("pale citrine", "color"),
                    ("light", "color_quality"), ("bright", "color_quality")
                ],
                "water": [
                    ("deep sapphire", "color"), ("oceanic teal", "color"), ("misty aquamarine", "color"),
                    ("fluid", "color_quality"), ("reflective", "color_quality")
                ]
            ]
            
            static let lack = [
                "fire": [("reserved", "mood"), ("muted", "color_quality")],
                "earth": [("ethereal", "texture"), ("light", "color_quality")],
                "air": [("instinctive", "approach"), ("rich", "color_quality")],
                "water": [("structured", "approach"), ("defined", "color_quality")]
            ]
            
            static let balanced = [
                ("balanced", "element"), ("harmonious", "color_quality")
            ]
        }
        
        // MARK: - Aspect Color Descriptions
        struct AspectColors {
            static let conjunction = [
                "VenusMoon": [("iridescent pearl", "color"), ("luminous", "color_quality")],
                "VenusSun": [("radiant gold", "color"), ("warm champagne", "color")],
                "MoonNeptune": [("moonlit aqua", "color"), ("dream blue", "color")],
                "VenusNeptune": [("opalescent lavender", "color"), ("ethereal", "color_quality")],
                "MarsVenus": [("passionate crimson", "color"), ("dynamic", "color_quality")]
            ]
            
            static let trine = [
                "VenusNeptune": [("oceanic teal", "color"), ("flowing", "color_quality")],
                "MoonVenus": [("luminous mother of pearl", "color"), ("harmonious", "color_quality")],
                "SunVenus": [("warm amber", "color"), ("honeyed", "color_quality")]
            ]
            
            static let square = [
                "VenusMars": [("dynamic burgundy", "color"), ("contrasting", "color_quality")],
                "MoonVenus": [("complex slate blue", "color"), ("dualistic", "color_quality")]
            ]
            
            static let opposition = [
                "VenusNeptune": [("mysterious indigo", "color"), ("counterbalanced", "color_quality")],
                "SunMoon": [("balanced silver-gold", "color"), ("complementary", "color_quality")]
            ]
            
            static let minor = [
                ("subtle", "color_quality")
            ]
        }
        
        // MARK: - Color Nuance
        struct ColorNuance {
            static let conjunction = [
                "Sun": [
                    ("luminous gold", "color"),
                    ("warm", "color_quality"),
                    ("harmonious", "color_quality")
                ],
                "Moon": [
                    ("pearl luminescence", "color"),
                    ("luminous", "color_quality")
                ],
                "Mars": [
                    ("passionate rose-red", "color"),
                    ("vibrant", "color_quality")
                ],
                "Neptune": [
                    ("ethereal aquamarine", "color"),
                    ("dreamy", "color_quality")
                ]
            ]
            
            static let trine = [
                "Neptune": [
                    ("oceanic teal", "color"),
                    ("flowing", "color_quality")
                ],
                "Moon": [
                    ("moonlit rose", "color"),
                    ("nurturing", "color_quality")
                ],
                "Sun": [
                    ("warm amber", "color"),
                    ("honeyed", "color_quality")
                ]
            ]
            
            static let square = [
                "Mars": [
                    ("dynamic burgundy", "color"),
                    ("contrasting", "color_quality")
                ],
                "Moon": [
                    ("complex slate blue", "color"),
                    ("dualistic", "color_quality")
                ]
            ]
            
            static let opposition = [
                "Neptune": [
                    ("mysterious indigo", "color"),
                    ("counterbalanced", "color_quality")
                ],
                "Sun": [
                    ("balanced silver-gold", "color"),
                    ("complementary", "color_quality")
                ]
            ]
            
            static let sextile = [
                "Moon": [
                    ("supportive", "mood"),
                    ("gentle", "color_quality")
                ],
                "Mars": [
                    ("active", "mood"),
                    ("dynamic", "color_quality")
                ]
            ]
            
            static let minor = [
                ("subtle", "color_quality"),
                ("nuanced", "color_quality")
            ]
        }
        
        // MARK: - Dignity Colors
        struct DignityColors {
            static let domicile = [
                "Sun": [
                    ("pure gold", "color"),
                    ("radiant", "color_quality")
                ],
                "Moon": [
                    ("pure silver", "color"),
                    ("luminous", "color_quality")
                ],
                "Mercury": [
                    ("quicksilver", "color"),
                    ("brilliant", "color_quality")
                ],
                "Venus": [
                    ("purest rose", "color"),
                    ("exquisite", "color_quality")
                ],
                "Mars": [
                    ("perfect crimson", "color"),
                    ("intense", "color_quality")
                ],
                "Jupiter": [
                    ("regal purple", "color"),
                    ("expansive", "color_quality")
                ],
                "Saturn": [
                    ("perfect obsidian", "color"),
                    ("enduring", "color_quality")
                ]
            ]
            
            static let exaltation = [
                "Sun": [
                    ("exalted amber", "color"),
                    ("noble", "color_quality")
                ],
                "Moon": [
                    ("exalted pearl", "color"),
                    ("sublime", "color_quality")
                ],
                "Mercury": [
                    ("elevated citrine", "color"),
                    ("refined", "color_quality")
                ],
                "Venus": [
                    ("exalted jade", "color"),
                    ("harmonious", "color_quality")
                ],
                "Mars": [
                    ("elevated garnet", "color"),
                    ("powerful", "color_quality")
                ],
                "Jupiter": [
                    ("exalted sapphire", "color"),
                    ("abundant", "color_quality")
                ],
                "Saturn": [
                    ("elevated graphite", "color"),
                    ("disciplined", "color_quality")
                ]
            ]
            
            static let fall = [
                "Sun": [
                    ("muted amber", "color"),
                    ("subdued", "color_quality")
                ],
                "Moon": [
                    ("clouded silver", "color"),
                    ("diffused", "color_quality")
                ],
                "Mercury": [
                    ("misty grey", "color"),
                    ("complex", "color_quality")
                ],
                "Venus": [
                    ("muted rose", "color"),
                    ("subtle", "color_quality")
                ],
                "Mars": [
                    ("subdued terracotta", "color"),
                    ("tempered", "color_quality")
                ],
                "Jupiter": [
                    ("muted indigo", "color"),
                    ("restrained", "color_quality")
                ],
                "Saturn": [
                    ("subtle charcoal", "color"),
                    ("introspective", "color_quality")
                ]
            ]
            
            static let detriment = [
                "Sun": [
                    ("complex ochre", "color"),
                    ("nuanced", "color_quality")
                ],
                "Moon": [
                    ("shadowed pearl", "color"),
                    ("reflective", "color_quality")
                ],
                "Mercury": [
                    ("complex pewter", "color"),
                    ("contemplative", "color_quality")
                ],
                "Venus": [
                    ("complex mauve", "color"),
                    ("interesting", "color_quality")
                ],
                "Mars": [
                    ("complex rust", "color"),
                    ("challenging", "color_quality")
                ],
                "Jupiter": [
                    ("complex slate", "color"),
                    ("transformative", "color_quality")
                ],
                "Saturn": [
                    ("complex rust", "color"),
                    ("evolving", "color_quality")
                ]
            ]
        }
        
        // MARK: - Transit Descriptions
        struct Transits {
            static let conjunction = [
                "Moon": [
                    ("intensified", "mood"),
                    ("emotional", "texture"),
                    ("luminous", "color_quality")
                ],
                "Venus": [
                    ("intensified", "mood"),
                    ("harmonious", "color"),
                    ("balanced", "color_quality")
                ],
                "Mars": [
                    ("intensified", "mood"),
                    ("energetic", "structure"),
                    ("vibrant", "color_quality")
                ]
            ]
            
            static let opposition = [
                "Moon": [
                    ("contrasting", "structure"),
                    ("reflective", "mood"),
                    ("contrasting", "color_quality")
                ],
                "Venus": [
                    ("contrasting", "structure"),
                    ("balanced", "color"),
                    ("harmonizing", "color_quality")
                ],
                "Mars": [
                    ("contrasting", "structure"),
                    ("dynamic", "texture"),
                    ("bold", "color_quality")
                ]
            ]
            
            static let trine = [
                "Moon": [
                    ("flowing", "structure"),
                    ("intuitive", "mood"),
                    ("flowing", "color_quality")
                ],
                "Venus": [
                    ("flowing", "structure"),
                    ("attractive", "texture"),
                    ("harmonious", "color_quality")
                ],
                "Mars": [
                    ("flowing", "structure"),
                    ("confident", "mood"),
                    ("energetic", "color_quality")
                ]
            ]
            
            static let square = [
                "Moon": [
                    ("structured", "structure"),
                    ("challenging", "texture"),
                    ("dynamic", "color_quality")
                ],
                "Venus": [
                    ("structured", "structure"),
                    ("creative", "color"),
                    ("expressive", "color_quality")
                ],
                "Mars": [
                    ("structured", "structure"),
                    ("bold", "structure"),
                    ("intense", "color_quality")
                ]
            ]
            
            static let sextile = [
                "Moon": [
                    ("harmonious", "structure"),
                    ("supportive", "mood"),
                    ("gentle", "color_quality")
                ],
                "Venus": [
                    ("harmonious", "structure"),
                    ("pleasant", "texture"),
                    ("balanced", "color_quality")
                ],
                "Mars": [
                    ("harmonious", "structure"),
                    ("active", "mood"),
                    ("dynamic", "color_quality")
                ]
            ]
            
            static let minor = [
                ("subtle", "texture"),
                ("nuanced", "color_quality")
            ]
            
            static let general = [
                ("shifting", "mood"),
                ("evolving", "color_quality")
            ]
        }
        
        // MARK: - Aspects
        struct Aspects {
            static let conjunction = [
                ("intensified", "mood")
            ]
            
            static let opposition = [
                ("balanced", "structure")
            ]
            
            static let trine = [
                ("flowing", "structure")
            ]
            
            static let square = [
                ("dynamic", "structure")
            ]
            
            static let sextile = [
                ("harmonious", "structure")
            ]
            
            static let minor = [
                ("nuanced", "mood")
            ]
        }
    }
    
    // MARK: - Daily Vibe Text Content
    
    struct DailyVibe {
        
        // MARK: - Title Generation
        struct Titles {
            static let firstWords = [
                "earthy": ["Cinders", "Earth", "Roots", "Soil", "Ember"],
                "ethereal": ["Mist", "Whispers", "Echoes", "Shadow", "Ghost"],
                "fluid": ["Flow", "Current", "Rivers", "Waves", "Drift"],
                "structured": ["Structure", "Framework", "Scaffold", "Bones", "Pillars"],
                "subtle": ["Subtle", "Quiet", "Gentle", "Soft", "Tender"],
                "bold": ["Bold", "Statement", "Command", "Presence", "Power"],
                "minimal": ["Minimal", "Essential", "Core", "Basic", "Pure"],
                "layered": ["Layers", "Depths", "Textured", "Woven", "Veiled"],
                "instinctive": ["Instinct", "Intuition", "Primal", "Wild", "Raw"],
                "default": ["Resonance", "Threshold", "Echo", "Whisper", "Rhythm", "Pulse", "Thread", "Cinders", "Veil", "Shift"]
            ]
            
            static let connectionWords = ["Beneath", "Within", "Beyond", "Between", "Through", "Against", "Beside", "Behind", "Under", "Above"]
            
            static let finalWords = ["the Surface", "the Veil", "the Noise", "the Current", "the Light", "the Shadow", "the Day", "the Self", "the Moment", "the Form"]
            
            static let patterns = [
                "%s %s %s",            // e.g. "Resonance Beneath Surface"
                "The %s of %s",        // e.g. "The Flow of Light"
                "%s and %s",           // e.g. "Structure and Shadow"
                "%s in %s",            // e.g. "Depth in Motion"
                "%s meets %s",         // e.g. "Form meets Function"
                "%s through %s"        // e.g. "Light through Shadow"
            ]
        }
        
        // MARK: - Main Paragraph Text
        struct MainParagraph {
            static let openingPatterns = [
                "A %@ glows today, asking for %@ without %@. ",
                "Today carries a %@ current, inviting %@ with %@. ",
                "There's a %@ quality to today's energy, suggesting %@ and %@. ",
                "%@ weaves through today, encouraging a balance of %@ and %@. ",
                "The day unfolds with a %@ rhythm, connecting %@ to %@. "
            ]
            
            static let openingWords = [
                "subtle": ["quiet smoulder", "warmth", "noise"],
                "bold": ["electric", "clarity", "presence"],
                "fluid": ["flowing", "adaptability", "intuitive ease"],
                "structured": ["grounded", "intention", "purpose"],
                "dreamy": ["misty", "trust", "the unseen"],
                "default": ["balanced", "harmony", "expression"]
            ]
            
            static let middlePatterns = [
                "You're %@. There's an %@ pulling you %@ to dress for your %@, not the %@. ",
                "You're meant to %@ through %@. Your %@ should tell a story only you fully %@. ",
                "Today asks you to embrace %@ and release %@. Your style can reflect this through %@ and %@. ",
                "Find the courage to %@ rather than %@. Your appearance today is more about %@ than %@. "
            ]
            
            static let middleWords = [
                "earthyIntuitive": ["not meant to burn bright—just burn real", "undercurrent", "inward", "inner world", "outer gaze"],
                "layeredMinimal": ["meant to reveal through concealing", "careful restraint", "layers", "understand"],
                "boldLayered": ["depth", "flash", "presence", "layer by layer"],
                "fluidIntuitive": ["flow with your instincts", "allowing", "outer expression", "inner currents"],
                "default": ["find balance between what you show and what you keep hidden", "authentic extension", "style", "interior landscape"]
            ]
            
            static let closingPatterns = [
                "It's a day to %@ with %@, to carry %@ like %@, and to resist the urge to %@. ",
                "Today invites you to %@ through %@, to embody %@ with %@, and to trust your %@. ",
                "Consider how to %@ your %@ today, allowing %@ to guide your %@ rather than %@. ",
                "The day's energy supports %@ that %@, creating a sense of %@ without sacrificing %@. "
            ]
            
            static let closingWords = [
                "newMoon": ["layer comfort", "mystery", "softness", "armour", "explain yourself"],
                "firstQuarter": ["build presence", "intention", "texture and form", "clarity", "evolving intuition"],
                "fullMoon": ["embody", "full expression", "what you reveal", "what you protect", "authentic presence"],
                "lastQuarter": ["release", "what no longer serves", "simplify", "its essence", "new cycles of creativity"]
            ]
            
            static let finalStatements = [
                "What matters is how it feels, not how it looks from the outside. Trust the flicker in your gut.",
                "The strongest style statements come from within. Let your inner knowing guide your choices today.",
                "Your body already knows what it needs. Listen to that wisdom rather than external expectations.",
                "The most powerful appearance is one that aligns with your authentic energy. Trust that alignment.",
                "Style is a conversation between your inner and outer worlds. Make sure both voices are heard."
            ]
        }
        
        // MARK: - Textiles Text
        struct Textiles {
            static let fabricCollections = [
                "soft": ["brushed cotton", "cashmere", "velvet", "mohair", "silk", "flannel"],
                "structured": ["denim", "wool gabardine", "canvas", "heavyweight cotton", "leather", "suede"],
                "fluid": ["silk", "lyocell", "matte satin", "modal", "fluid jersey", "lightweight wool"],
                "textured": ["tweed", "bouclé", "corduroy", "raw silk", "nubby linen", "textured knits"],
                "layered": ["layered jersey", "tissue-weight cotton", "fine wool", "lightweight layers"],
                "earthy": ["washed leather", "stonewashed cotton", "linen", "hemp", "raw denim"],
                "luxurious": ["fine wool", "silk velvet", "cashmere", "merino", "high-quality leather"],
                "default": ["cotton blends", "jersey", "wool", "linen", "denim"]
            ]
            
            static let dailyFabrics = [
                "washed linen", "raw silk", "brushed wool", "supple leather",
                "lightly waxed cotton", "textured knit", "airy gauze",
                "structured denim", "fluid rayon", "crisp poplin",
                "heavyweight jersey", "distressed suede", "lightweight tweed",
                "crisp oxford", "vintage velvet", "laundered chambray",
                "bouclé wool", "burnished leather", "crinkled cotton",
                "technical mesh", "textured lace", "organic hemp",
                "woven jacquard", "structured canvas", "draped georgette"
            ]
            
            static let descriptivePatterns = [
                "—anything that feels like %@ with a touch of %@. Choose %@ that %@.",
                "—anything with %@ and %@. Choose materials that %@ while letting you %@.",
                "—anything that %@ and %@ to your movement. Choose fabrics that %@ through %@.",
                "—anything that %@ through %@ rather than %@. Choose materials that %@ against your skin."
            ]
            
            static let descriptiveWords = [
                "softTextured": ["second skin", "shadow", "tactile layers", "soften the wind but hold your power close"],
                "structuredEarthy": ["substance", "character", "ground you", "move with intention"],
                "fluidLayered": ["flows", "adapts", "create dimension", "layering rather than weight"],
                "luxurious": ["elevates", "quality rather than flash", "feel transformative", "transformative"],
                "default": ["resonates", "your body's needs today", "support", "rather than distract from your presence"]
            ]
        }
        
        // MARK: - Colors Text
        struct Colors {
            static let colorCollections = [
                "earthy": ["olive", "terracotta", "moss", "ochre", "walnut", "sand", "umber"],
                "watery": ["navy ink", "teal", "indigo", "slate blue", "stormy gray", "deep aqua"],
                "airy": ["pale blue", "silver gray", "cloud white", "light lavender", "sky"],
                "fiery": ["oxblood", "rust", "amber", "burnt orange", "burgundy", "ruby"],
                "dark": ["coal", "espresso", "midnight blue", "deep forest", "smoky plum", "charcoal"],
                "light": ["ivory", "bone", "pearl", "light gray", "soft white", "pale gold"],
                "muted": ["faded indigo", "dove gray", "dusty rose", "sage", "muted mauve", "ash grey"],
                "vibrant": ["electric blue", "emerald", "crimson", "royal purple", "bright mustard"],
                "default": ["navy", "charcoal", "ivory", "taupe", "black", "gray"]
            ]
            
            static let dailyColors = [
                "washed indigo", "burnt sienna", "faded moss", "rich mahogany",
                "pale chamomile", "misty lavender", "storm grey", "warm terracotta",
                "dusty sage", "deep bordeaux", "weathered denim", "soft ochre",
                "antique ivory", "vintage cognac", "muted juniper", "hazy charcoal",
                "blushed clay", "stained walnut", "aged brass", "smoky quartz",
                "faded damson", "burnished copper", "sea glass", "deep olive",
                "washed saffron", "shadow mauve", "midnight navy", "sunlit amber",
                "cool teal", "sandstone", "dusty plum", "smoked pearl"
            ]
            
            static let closingPhrases = [
                ". Let them %@ the light, not %@ it",
                ". Let them %@ with %@ presence",
                ". Let them %@ your energy with %@",
                ". Let them %@ and %@ your presence today",
                ". Let them %@ your %@ with subtle %@"
            ]
            
            static let closingWords = [
                "darkMuted": ["absorb", "reflect"],
                "lightAiry": ["diffuse", "subtle"],
                "vibrantFiery": ["express", "intention"],
                "default": ["ground", "center"]
            ]
        }
        
        // MARK: - Patterns Text
        struct Patterns {
            static let patternDescriptions = [
                "minimalTextured": [
                    "Uneven dye effects (stonewash, acid, mineral)%@. Minimal prints that feel faded or lived-in—nothing polished or loud.",
                    "Today favors uneven dye effects (stonewash, acid, mineral)%@. Minimal prints that feel faded or lived-in.",
                    "Consider uneven dye effects (stonewash, acid, mineral)%@. These create texture without overwhelming.",
                    "Uneven dye effects (stonewash, acid, mineral)%@. Let these patterns connect with subtlety."
                ],
                "expressiveEclectic": [
                    "Bold geometrics, unexpected color combinations%@. Statement prints that tell a story or reference art—each with a clear point of view.",
                    "Today favors bold geometrics, unexpected color combinations%@. Statement prints that tell a story or reference art.",
                    "Consider bold geometrics, unexpected color combinations%@. These create impact without overwhelming.",
                    "Bold geometrics, unexpected color combinations%@. Let these patterns speak with intention."
                ],
                "structuredMinimal": [
                    "Architectural lines, subtle grids%@. Patterns with mathematical order—rather than organic flow.",
                    "Today favors architectural lines, subtle grids%@. Patterns with mathematical order.",
                    "Consider architectural lines, subtle grids%@. These create structure without complexity.",
                    "Architectural lines, subtle grids%@. Let these patterns bring order with elegance."
                ],
                "fluidExpressive": [
                    "Watercolor effects, organic forms%@. Patterns that move and flow—with a sense of natural rhythm.",
                    "Today favors watercolor effects, organic forms%@. Patterns that move and flow.",
                    "Consider watercolor effects, organic forms%@. These create movement without constraint.",
                    "Watercolor effects, organic forms%@. Let these patterns flow with your movements."
                ],
                "subtle": [
                    "Barely-there textures, monochromatic tone-on-tone%@. Patterns that reveal themselves—only upon closer inspection.",
                    "Today favors barely-there textures, monochromatic tone-on-tone%@. Patterns that reveal themselves.",
                    "Consider barely-there textures, monochromatic tone-on-tone%@. These create depth without distraction.",
                    "Barely-there textures, monochromatic tone-on-tone%@. Let these patterns whisper rather than shout."
                ],
                "eclectic": [
                    "Unexpected combinations, vintage-inspired motifs%@. Mix patterns of different scales—for a curated eclectic approach.",
                    "Today favors unexpected combinations, vintage-inspired motifs%@. Mix patterns of different scales.",
                    "Consider unexpected combinations, vintage-inspired motifs%@. These create interest without chaos.",
                    "Unexpected combinations, vintage-inspired motifs%@. Let these patterns tell your unique story."
                ],
                "default": [
                    "Balanced, intentional patterns%@. Choose prints that feel authentic—to your energy today.",
                    "Today favors balanced, intentional patterns%@. Choose prints that feel authentic.",
                    "Consider balanced, intentional patterns%@. These create harmony without overwhelming.",
                    "Balanced, intentional patterns%@. Let these patterns enhance your natural presence."
                ]
            ]
            
            static let dailyPatternEmphases = [
                ", today especially fine pinstripes",
                ", with today's emphasis on tonal texture",
                ", focusing today on shadowed stripes",
                ", with attention to today's speckled details",
                ", incorporating today's subtle check pattern",
                ", with today's focus on irregular dots",
                ", emphasizing today organic textures",
                ", highlighting today's geometric simplicity",
                ", with today's emphasis on fluid stripes",
                ", focusing today on balanced asymmetry",
                ", leaning today toward textural contrast",
                ", with today's gentle gradients"
            ]
        }
        
        // MARK: - Shape Text
        struct Shape {
            static let shapeDescriptions = [
                "structuredProtective": [
                    "Cocooned, but defined%@. A wrap coat with structure. Layer your look like secrets stacked: fitted base, fluid overlay, something sculptural to finish.",
                    "Cocooned, but defined%@. Consider a wrap coat with structure that moves with your body as you move.",
                    "Today's energy favors cocooned, but defined%@. A wrap coat with structure that protects rather than restricts.",
                    "Focus on cocooned, but defined%@. Create a wrap coat with structure through layered elements."
                ],
                "fluidLayered": [
                    "Flowing layers with intentional drape%@. Pieces that breathe. Movement is key, restriction is counterproductive.",
                    "Flowing layers with intentional drape%@. Consider pieces that move with your body as you move.",
                    "Today's energy favors flowing layers with intentional drape%@. Pieces that move with your body rather than constrain.",
                    "Focus on flowing layers with intentional drape%@. Create movement through thoughtful layering."
                ],
                "minimalBalanced": [
                    "Clean lines with precise proportion%@. The relationship between pieces. Quality over quantity, space over clutter.",
                    "Clean lines with precise proportion%@. Consider the relationship between pieces that balance as you move.",
                    "Today's energy favors clean lines with precise proportion%@. The relationship between pieces rather than individual statements.",
                    "Focus on clean lines with precise proportion%@. Create harmony through balanced elements."
                ],
                "expressiveLayered": [
                    "Bold volume balanced with definition%@. Dimension through contrast. Fitted against full, structured against fluid.",
                    "Bold volume balanced with definition%@. Consider dimension through contrast that evolves as you move.",
                    "Today's energy favors bold volume balanced with definition%@. Dimension through contrast rather than uniformity.",
                    "Focus on bold volume balanced with definition%@. Create dimension through contrasting elements."
                ],
                "protective": [
                    "Protective without restriction%@. Forms that create personal space. Soft armor that moves with you, not against you.",
                    "Protective without restriction%@. Consider forms that create personal space that adapts as you move.",
                    "Today's energy favors protective without restriction%@. Forms that create personal space while allowing movement.",
                    "Focus on protective without restriction%@. Create personal space through thoughtful construction."
                ],
                "default": [
                    "Balanced proportions that honor your body's needs today%@. A silhouette that supports your energy. Neither constricting nor obscuring.",
                    "Balanced proportions that honor your body's needs today%@. Consider a silhouette that supports your energy as you move.",
                    "Today's energy favors balanced proportions that honor your body's needs today%@. A silhouette that supports your energy rather than forcing it into a predetermined shape.",
                    "Focus on balanced proportions that honor your body's needs today%@. Create support through thoughtful silhouettes."
                ]
            ]
            
            static let dailyShapeEmphases = [
                ", today emphasizing shoulder definition",
                ", with today's focus on sleeve volume",
                ", highlighting today's waist proportion",
                ", with attention to today's collar structure",
                ", with today's emphasis on sleeve length",
                ", focusing today on horizontal lines",
                ", with today's definition at the hip",
                ", emphasizing today vertical proportions",
                ", with today's attention to neckline shape",
                ", highlighting today's layering proportions",
                ", with today's focus on hem detail",
                ", emphasizing today's balance of fitted and fluid elements"
            ]
        }
        
        // MARK: - Accessories Text
        struct Accessories {
            static let accessoryDescriptions = [
                "%@, and it must %@—%@. %@. %@: %@.",
                "%@ with %@. Items that %@ and %@. %@. %@: %@.",
                "Choose %@ that %@. %@ through %@ and %@. %@: %@.",
                "Accessories that %@ to %@ through the day. %@ that %@. %@: %@."
            ]
            
            static let accessoryWords = [
                "minimalProtective": [
                    "One object only",
                    "mean something",
                    "your protective piece",
                    "A locket, a band, a scent worn like armor. No flash. Just focus",
                    "Fragrance",
                    "vetiver, resin, or something bitter-green"
                ],
                "expressiveEclectic": [
                    "Statement pieces",
                    "personal significance",
                    "invite questions",
                    "create connection",
                    "Focus on one primary focal point balanced by subtle supporting elements",
                    "Fragrance",
                    "spiced citrus, rich amber, or something unexpectedly botanical"
                ],
                "structuredEarthy": [
                    "Natural materials",
                    "with clear purpose",
                    "ground and center",
                    "weight",
                    "texture",
                    "Fragrance",
                    "cedarwood, tobacco, or something mineral-based"
                ],
                "wateryProtective": [
                    "Fluid forms",
                    "move with you",
                    "adapt",
                    "different contexts",
                    "Consider pieces with emotional resonance that anchor your shifting states",
                    "Fragrance",
                    "salt air, clean musk, or something aquatic but warm"
                ],
                "default": [
                    "Intentional selections",
                    "enhance rather than distract",
                    "feel like natural extensions of your energy",
                    "rather than additions",
                    "Choose pieces that resonate with your current state",
                    "Fragrance",
                    "something that resonates with your skin chemistry and emotional state today"
                ]
            ]
            
            static let dailyAccessoryEmphases = [
                " with today's emphasis on wrist elements",
                " focusing today on neck adornment",
                " with special attention today to metals",
                " highlighting today the power of a single element",
                " with today's emphasis on natural materials",
                " focusing today on textural contrast",
                " with today's attention to meaningful objects",
                " considering today the symbolic weight",
                " with today's focus on handcrafted details",
                " emphasizing today personal significance",
                " with today's attention to organic forms",
                " highlighting today the interplay of scale"
            ]
        }
        
        // MARK: - Takeaway Text
        struct Takeaway {
            static let takeawayOptions = [
                "No one else has to get it. But you do. That's the point.",
                "Trust what feels true, not what looks obvious.",
                "Your instinct knows before your mind does. Listen.",
                "The inner voice speaks in textures and weights, not just words.",
                "Balance isn't static. It's a continuous recalibration.",
                "The middle path isn't always halfway between extremes.",
                "Expression is most powerful when it's intentional, not just loud.",
                "Speak through what you choose, not just what you say.",
                "Begin with intention. The rest will follow.",
                "New cycles start with quiet commitment, not grand gestures.",
                "Growth happens in the tension between comfort and challenge.",
                "The path forward reveals itself one step at a time.",
                "Full expression requires both vulnerability and strength.",
                "What you reveal is as important as what you conceal.",
                "Release what no longer serves before seeking what's next.",
                "Completion is just another form of beginning.",
                "Dress for the energy you need, not just the one you have.",
                "Your body knows. Your clothes should listen.",
                "What you wear changes how you move. Choose accordingly.",
                "Today's energy speaks through form. Let your clothes translate.",
                "The most authentic style comes from within, not from outside.",
                "Trust the conversation between your body and your clothes today.",
                "Your physical presence carries a message. Make it intentional.",
                "Style isn't about being seen, but about seeing yourself clearly."
            ]
        }
        
        // MARK: - Daily Signature Text
        struct DailySignature {
            static let dayOfWeekTokens = [
                1: [("illuminated", "texture"), ("radiant", "color_quality"), ("amber gold", "color")], // Sunday
                2: [("reflective", "mood"), ("intuitive", "structure"), ("pearl silver", "color")], // Monday
                3: [("energetic", "mood"), ("dynamic", "structure"), ("ruby red", "color")], // Tuesday
                4: [("communicative", "mood"), ("versatile", "structure"), ("quicksilver", "color")], // Wednesday
                5: [("expansive", "mood"), ("abundant", "structure"), ("royal blue", "color")], // Thursday
                6: [("harmonious", "mood"), ("balanced", "structure"), ("emerald", "color")], // Friday
                7: [("structured", "mood"), ("enduring", "structure"), ("obsidian", "color")] // Saturday
            ]
            
            static let seasonalTokens = [
                "spring": [("emerging", "structure"), ("fresh", "texture")],
                "summer": [("expansive", "structure"), ("vibrant", "color_quality")],
                "autumn": [("layered", "structure"), ("transitional", "texture")],
                "winter": [("protective", "structure"), ("insulating", "texture")]
            ]
            
            static let numerologyTokens = [
                1: [("pioneering", "mood")],
                2: [("receptive", "mood")],
                3: [("expressive", "mood")],
                4: [("structured", "mood")],
                5: [("dynamic", "mood")],
                6: [("harmonious", "mood")],
                7: [("reflective", "mood")],
                8: [("powerful", "mood")],
                9: [("completing", "mood")]
            ]
        }
        
        // MARK: - Daily Variation Text
        struct DailyVariation {
            static let wildcardOptions = [
                "unexpected", "juxtaposed", "nuanced", "transitional",
                "distinctive", "paradoxical", "intuitive", "emergent",
                "responsive", "calibrated", "resonant", "harmonized",
                "textured", "articulated", "considered", "attentive"
            ]
            
            static let dailyFabricOptions = [
                "washed linen", "raw silk", "brushed wool", "supple leather",
                "lightly waxed cotton", "textured knit", "airy gauze",
                "structured denim", "fluid rayon", "crisp poplin",
                "heavyweight jersey", "distressed suede", "lightweight tweed",
                "crisp oxford", "vintage velvet", "laundered chambray",
                "bouclé wool", "burnished leather", "crinkled cotton",
                "technical mesh", "textured lace", "organic hemp",
                "woven jacquard", "structured canvas", "draped georgette"
            ]
            
            static let dailyColorOptions = [
                "washed indigo", "burnt sienna", "faded moss", "rich mahogany",
                "pale chamomile", "misty lavender", "storm grey", "warm terracotta",
                "dusty sage", "deep bordeaux", "weathered denim", "soft ochre",
                "antique ivory", "vintage cognac", "muted juniper", "hazy charcoal",
                "blushed clay", "stained walnut", "aged brass", "smoky quartz",
                "faded damson", "burnished copper", "sea glass", "deep olive",
                "washed saffron", "shadow mauve", "midnight navy", "sunlit amber",
                "cool teal", "sandstone", "dusty plum", "smoked pearl"
            ]
        }
    }
    
    // MARK: - getText Helper (if not already present)
    
    /// Get text from the library by key
    /// - Parameters:
    ///   - key: The text key to look up
    ///   - tokens: Optional tokens for dynamic text selection
    /// - Returns: The text if found, nil otherwise
    static func getText(forKey key: String, tokens: [StyleToken]? = nil) -> String? {
        // This is a simplified implementation - adapt to your existing getText method
        let allDescriptions = Shape.shapeDescriptions
            .merging(Textiles.textileDescriptions) { _, new in new }
            .merging(Patterns.patternDescriptions) { _, new in new }
            .merging(Colors.colorDescriptions) { _, new in new }
            .merging(Accessories.accessoryDescriptions) { _, new in new }
            .merging(Layering.layeringDescriptions) { _, new in new }
        
        if let variants = allDescriptions[key], !variants.isEmpty {
            // If you have token-based selection logic, apply it here
            // Otherwise, return the first variant
            return variants.first
        }
        
        return nil
    }
    
    // MARK: - Axis-Aware Copy Variants - Shape Copy (Action vs Strategy axis)
    
    struct Shape {
        static let shapeDescriptions: [String: [String]] = [
            // Kinetic variant - high action, lower strategy
            "shape_core_kinetic": [
                "Streamlined forms with directional lines that mirror your momentum.",
                "Dynamic silhouettes that move with intention and forward energy.",
                "Shapes that channel drive into purposeful motion.",
            ],
            
            // Grounded variant - high strategy, lower action
            "shape_core_grounded": [
                "Architectural shapes that anchor your energy with quiet control.",
                "Structured silhouettes that ground presence through disciplined form.",
                "Shapes that speak to planning, precision, and thoughtful composition.",
            ],
            
            // Balanced variant - action and strategy in equilibrium
            "shape_core_balanced": [
                "Silhouettes that bridge structure and flow naturally.",
                "Forms that honour both momentum and intention in balanced measure.",
                "Shapes that move between precision and fluidity with ease.",
            ],
            
            // Default fallback
            "shape_core": [
                "Trust your instincts with silhouettes that honour today's energy and movement.",
            ]
        ]
    }
    
    // MARK: - Textiles Copy (Tempo axis)
    
    struct Textiles {
        static let textileDescriptions: [String: [String]] = [
            // Fast variant - high tempo
            "textiles_core_fast": [
                "Crisp weaves, light-handle fabrics that keep energy moving.",
                "Fabrics with snap and vitality—textures that match a quick pace.",
                "Choose materials that flow with rapid rhythm and bright momentum.",
            ],
            
            // Slow variant - low tempo
            "textiles_core_slow": [
                "Soft, fluid fabrics that slow the day's rhythm.",
                "Textiles with weight and warmth that invite pause and reflection.",
                "Materials that ground tempo in tactile comfort and unhurried grace.",
            ],
            
            // Balanced variant - moderate tempo
            "textiles_core_balanced": [
                "Fabrics that adapt to your natural pace—neither rushed nor languid.",
                "Textiles with versatile hand that honour shifting rhythms.",
                "Materials balanced between structure and ease, movement and rest.",
            ],
            
            // Default fallback
            "textiles_core": [
                "Choose fabrics that feel right against your skin and move with your rhythm.",
            ]
        ]
    }
    
    // MARK: - Patterns Copy (Visibility axis)
    
    struct Patterns {
        static let patternDescriptions: [String: [String]] = [
            // Prominent variant - high visibility
            "patterns_core_prominent": [
                "Bold patterns that command attention and express confident presence.",
                "Visual statements that make your energy visible—graphic, striking, unapologetic.",
                "Patterns that amplify rather than whisper, designed to be seen.",
            ],
            
            // Subtle variant - low visibility
            "patterns_core_subtle": [
                "Quiet patterns that reveal themselves slowly—understated elegance.",
                "Visual rhythms that speak in whispers, not shouts.",
                "Patterns that honour introspection and the power of restraint.",
            ],
            
            // Balanced variant - moderate visibility
            "patterns_core_balanced": [
                "Patterns that balance expression with refinement.",
                "Visual interest that neither dominates nor disappears.",
                "Patterns scaled to your comfort between visibility and privacy.",
            ],
            
            // Default fallback
            "patterns_core": [
                "Select patterns that speak to your mood—whether minimal or expressive.",
            ]
        ]
    }
    
    // MARK: - Colours Copy (Visibility axis)
    
    struct Colors {
        static let colorDescriptions: [String: [String]] = [
            // Bold variant - high visibility
            "colors_core_bold": [
                "Today's palette demands presence—rich tones that project confidence.",
                "Colours that announce rather than suggest, bold choices that match your visibility.",
                "Your colour story today is about being seen, not blending in.",
            ],
            
            // Subtle variant - low visibility
            "colors_core_subtle": [
                "A palette of quiet restraint—tones that honour privacy and introspection.",
                "Colours that create sanctuary rather than spectacle.",
                "Today's hues speak in muted tones, offering elegance through understatement.",
            ],
            
            // Balanced variant - moderate visibility
            "colors_core_balanced": [
                "Today's palette leans balanced with tones that reflect your inner rhythm.",
                "Colours that neither shout nor hide—a harmonious middle ground.",
                "Your colour choices today bridge boldness and subtlety naturally.",
            ],
            
            // Default fallback
            "colors_core": [
                "Let today's palette reflect your inner landscape with tones that resonate.",
            ]
        ]
    }
    
    // MARK: - Accessories Copy (Strategy axis)
    
    struct Accessories {
        static let accessoryDescriptions: [String: [String]] = [
            // Structured variant - high strategy
            "accessories_core_structured": [
                "Accessories with purpose and precision—each piece earns its place.",
                "Structured additions that complete the composition with disciplined intent.",
                "Choose accessories that speak to planning: functional, refined, deliberate.",
            ],
            
            // Fluid variant - low strategy
            "accessories_core_fluid": [
                "Accessories chosen by instinct rather than plan—fluid and intuitive.",
                "Pieces that feel right without overthinking: organic additions to your presence.",
                "Let accessories emerge naturally, responding to feeling rather than formula.",
            ],
            
            // Balanced variant - moderate strategy
            "accessories_core_balanced": [
                "Accessories that blend intention with spontaneity.",
                "Pieces chosen with awareness but not rigidity.",
                "Strike balance between thoughtful curation and intuitive addition.",
            ],
            
            // Default fallback
            "accessories_core": [
                "Accessories that add texture and intention to complete your expression.",
            ]
        ]
    }
    
    // MARK: - Layering Copy (Strategy axis)
    
    struct Layering {
        static let layeringDescriptions: [String: [String]] = [
            // Structured variant - high strategy
            "layering_core_structured": [
                "Layer with architectural intention—each piece serving clear purpose.",
                "Build your look through disciplined addition, structure upon structure.",
                "Approach layering as composition: organised, purposeful, controlled.",
            ],
            
            // Fluid variant - low strategy
            "layering_core_fluid": [
                "Layer intuitively, letting pieces find their place organically.",
                "Build your look through feeling rather than formula.",
                "Let layering emerge naturally, responding to comfort and instinct.",
            ],
            
            // Adaptable variant - moderate strategy
            "layering_core_adaptable": [
                "Layer with flexibility—structured enough to function, fluid enough to adapt.",
                "Build your look with both intention and openness to shift.",
                "Approach layering as responsive composition, neither rigid nor random.",
            ],
            
            // Default fallback
            "layering_core": [
                "Layer with awareness, adapting to both temperature and energy.",
            ]
        ]
    }
    
    // MARK: - Moon Phase Text Content
    
    struct MoonPhase {
        
        // MARK: - Phase Descriptions
        struct PhaseDescriptions {
            static let names = [
                "newMoon": "New Moon",
                "waxingCrescent": "Waxing Crescent",
                "firstQuarter": "First Quarter",
                "waxingGibbous": "Waxing Gibbous",
                "fullMoon": "Full Moon",
                "waningGibbous": "Waning Gibbous",
                "lastQuarter": "Last Quarter",
                "waningCrescent": "Waning Crescent"
            ]
        }
        
        // MARK: - Blueprint Tokens
        struct BlueprintTokens {
            static let newMoon = [
                ("seeded", "mood"), ("potential", "structure"), ("minimal", "color")
            ]
            
            static let fullMoon = [
                ("illuminated", "mood"), ("expressive", "structure"), ("vibrant", "color")
            ]
            
            static let quarters = [
                ("balanced", "structure")
            ]
            
            static let waxing = [
                ("growing", "mood")
            ]
            
            static let waning = [
                ("distilling", "mood")
            ]
        }
        
        // MARK: - Daily Vibe Tokens
        struct DailyVibeTokens {
            static let newMoon = [
                ("inward", "mood"), ("seeded", "structure"), ("minimal", "color"), ("quiet", "texture")
            ]
            
            static let waxingCrescent = [
                ("emerging", "structure"), ("intentional", "mood"), ("textured", "texture")
            ]
            
            static let firstQuarter = [
                ("decisive", "mood"), ("structured", "structure"), ("dynamic", "color")
            ]
            
            static let waxingGibbous = [
                ("developing", "structure"), ("refining", "mood"), ("layered", "texture")
            ]
            
            static let fullMoon = [
                ("illuminated", "mood"), ("expressive", "structure"), ("vibrant", "color"), ("visible", "texture")
            ]
            
            static let waningGibbous = [
                ("substantial", "structure"), ("sharing", "mood"), ("rich", "color")
            ]
            
            static let lastQuarter = [
                ("releasing", "mood"), ("resolving", "structure"), ("transitional", "texture")
            ]
            
            static let waningCrescent = [
                ("reflective", "mood"), ("subtle", "color"), ("dissolving", "structure")
            ]
        }
        
        // MARK: - Color Palettes
        struct ColorPalettes {
            static let palettes = [
                "newMoon": ["black", "charcoal", "deep navy", "indigo", "dark plum"],
                "waxingCrescent": ["silver", "pearl", "pale blue", "light gray", "ivory"],
                "firstQuarter": ["white", "cream", "pale yellow", "light blue", "silver"],
                "waxingGibbous": ["gold", "cream", "amber", "honey", "warm yellow"],
                "fullMoon": ["white", "silver", "platinum", "pearl", "luminous blue"],
                "waningGibbous": ["bronze", "copper", "warm gold", "amber", "rust"],
                "lastQuarter": ["pewter", "stone gray", "taupe", "mauve", "dusty rose"],
                "waningCrescent": ["charcoal", "midnight blue", "deep purple", "slate", "obsidian"]
            ]
        }
    }
    
    // MARK: - Weather Text Content
    
    struct Weather {
        
        // MARK: - Temperature Descriptions
        struct Temperature {
            static let descriptions = [
                (5, "frigid", "insulated", "insulated"),
                (10, "cold", "cozy", "cozy"),
                (15, "cool", "layered", "layered"),
                (20, "mild", "versatile", "versatile"),
                (25, "warm", "breathable", "breathable"),
                (30, "hot", "light", "light"),
                (35, "scorching", "minimal", "minimal")
            ]
        }
        
        // MARK: - Condition Descriptions
        struct Conditions {
            static let weatherConditions = [
                "light rain": ("misty", "water-resistant"),
                "drizzle": ("misty", "water-resistant"),
                "heavy rain": ("drenched", "waterproof"),
                "shower": ("drenched", "waterproof"),
                "rain": ("damp", "protected"),
                "overcast": ("muted", "subdued"),
                "cloudy": ("muted", "subdued"),
                "partly cloudy": ("changeable", "adaptable"),
                "snow": ("crisp", "insulated"),
                "ice": ("crisp", "insulated"),
                "fog": ("diffused", "soft"),
                "mist": ("diffused", "soft"),
                "sun": ("bright", "vibrant"),
                "clear": ("bright", "vibrant"),
                "storm": ("dramatic", "protective"),
                "wind": ("anchored", "secure"),
                "breezy": ("anchored", "secure")
            ]
        }
        
        // MARK: - Humidity Descriptions
        struct Humidity {
            static let descriptions = [
                (90, "highly-breathable"),
                (70, "moisture-wicking"),
                (20, "moisture-balancing"),
                (40, "hydrating")
            ]
        }
        
        // MARK: - Daily Variations
        struct DailyVariations {
            static let patternVariations = [
                "responsive", "adaptive", "flexible"
            ]
        }
    }
}
