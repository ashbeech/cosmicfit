//
//  AstrologicalInterpreter.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

struct AstrologicalInterpreter {
    // Interpret natal chart
    static func interpretNatalChart(_ chart: NatalChartCalculator.NatalChart) -> [String: String] {
        var interpretations: [String: String] = [:]
        
        // Interpret Sun sign
        let sunPlanet = chart.planets.first { $0.name == "Sun" }
        if let sun = sunPlanet {
            interpretations["Sun"] = interpretPlanet(name: "Sun", sign: sun.zodiacSign, isRetrograde: sun.isRetrograde)
        }
        
        // Interpret Moon sign
        let moonPlanet = chart.planets.first { $0.name == "Moon" }
        if let moon = moonPlanet {
            interpretations["Moon"] = interpretPlanet(name: "Moon", sign: moon.zodiacSign, isRetrograde: moon.isRetrograde)
        }
        
        // Interpret Ascendant
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        interpretations["Ascendant"] = interpretAscendant(sign: ascSign)
        
        // Interpret Midheaven
        let mcSign = CoordinateTransformations.decimalDegreesToZodiac(chart.midheaven).sign
        interpretations["Midheaven"] = interpretMidheaven(sign: mcSign)
        
        // Interpret other planets
        for planet in chart.planets {
            if planet.name != "Sun" && planet.name != "Moon" {
                interpretations[planet.name] = interpretPlanet(name: planet.name, sign: planet.zodiacSign, isRetrograde: planet.isRetrograde)
            }
        }
        
        // Overall chart interpretation
        interpretations["Overall"] = generateOverallInterpretation(chart: chart)
        
        return interpretations
    }
    
    // Interpret planet in sign
    private static func interpretPlanet(name: String, sign: Int, isRetrograde: Bool) -> String {
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        let retrogradeText = isRetrograde ? " (Retrograde)" : ""
        
        var interpretation = "\(name) in \(signName)\(retrogradeText):\n\n"
        
        // Planet in sign interpretation
        interpretation += planetInSignInterpretation(planet: name, sign: sign)
        
        // Retrograde interpretation if applicable
        if isRetrograde {
            interpretation += "\n\n\(name) Retrograde:\n"
            interpretation += planetRetrogradeInterpretation(planet: name)
        }
        
        return interpretation
    }
    
    // Interpret planet in sign
    private static func planetInSignInterpretation(planet: String, sign: Int) -> String {
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        
        // Basic interpretations for planets in signs
        switch planet {
        case "Sun":
            switch signName {
            case "Aries": return "Your core identity revolves around leadership, initiative, and independence. You express yourself with passion, directness, and may enjoy being first or best."
            case "Taurus": return "Your core identity centers on stability, patience, and appreciation of beauty. You are grounded, practical, and drawn to comfort and security."
            case "Gemini": return "Your core identity is flexible, curious, and communicative. You're mentally active, adaptable, and enjoy gathering and sharing information."
            case "Cancer": return "Your core identity is sensitive, nurturing, and emotionally receptive. You're protective of yourself and others, with strong memory and intuition."
            case "Leo": return "Your core identity revolves around creative self-expression, leadership, and visibility. You seek recognition and have a warm, generous, dramatic approach to life."
            case "Virgo": return "Your core identity centers on analysis, improvement, and service. You're precise, practical, and have a strong desire to be useful and efficient."
            case "Libra": return "Your core identity focuses on relationships, balance, and harmony. You're diplomatic, refined, and have a natural sense of fairness and aesthetics."
            case "Scorpio": return "Your core identity is intense, profound, and transformative. You delve deeply into experiences, value authenticity, and have strong emotional power."
            case "Sagittarius": return "Your core identity revolves around exploration, optimism, and seeking truth. You're philosophical, freedom-loving, and expansive in your outlook."
            case "Capricorn": return "Your core identity centers on ambition, responsibility, and structure. You're disciplined, practical, and have a long-term perspective on achievement."
            case "Aquarius": return "Your core identity revolves around innovation, independence, and humanitarian concerns. You're original, forward-thinking, and value social progress."
            case "Pisces": return "Your core identity is compassionate, intuitive, and boundary-dissolving. You're sensitive to others, spiritually inclined, and creatively inspired."
            default: return "Your Sun in \(signName) reflects your core identity and conscious purpose."
            }
            
        case "Moon":
            switch signName {
            case "Aries": return "Your emotional nature is direct, impulsive, and oriented toward action. You respond quickly to feelings and need independence even in emotional matters."
            case "Taurus": return "Your emotional nature seeks comfort, stability, and sensory satisfaction. You need security and predictability to feel emotionally fulfilled."
            case "Gemini": return "Your emotional nature is adaptable, curious, and intellectually stimulated. You process feelings through conversation and may need variety in emotional experiences."
            case "Cancer": return "Your emotional nature is deeply sensitive, nurturing, and protective. You have strong emotional memory and are highly receptive to the feelings of others."
            case "Leo": return "Your emotional nature is warm, dramatic, and needs recognition. You feel fulfilled when your generosity and creativity are appreciated."
            case "Virgo": return "Your emotional nature is careful, practical, and oriented toward service. You need order and usefulness to feel emotionally satisfied."
            case "Libra": return "Your emotional nature seeks harmony, beauty, and balanced relationships. You feel most fulfilled when in pleasant, cooperative environments."
            case "Scorpio": return "Your emotional nature is intense, deep, and transformative. You need authentic connection and may experience powerful emotional cycles."
            case "Sagittarius": return "Your emotional nature is optimistic, freedom-loving, and expansive. You need inspiration and new horizons to feel emotionally fulfilled."
            case "Capricorn": return "Your emotional nature is reserved, responsible, and goal-oriented. You find emotional security through achievement and maintaining control."
            case "Aquarius": return "Your emotional nature is detached, progressive, and oriented toward group connections. You need intellectual understanding of feelings and value emotional independence."
            case "Pisces": return "Your emotional nature is compassionate, intuitive, and fluid. You absorb the feelings around you and need spiritual or artistic outlets for emotional expression."
            default: return "Your Moon in \(signName) reflects your emotional nature and unconscious patterns."
            }
            
        case "Mercury":
            switch signName {
            case "Aries": return "Your thinking and communication style is direct, quick, and pioneering. You express ideas boldly and may be impatient in conversation or learning."
            case "Taurus": return "Your thinking and communication style is methodical, practical, and sensory-oriented. You process information thoroughly and prefer concrete, useful knowledge."
            case "Gemini": return "Your thinking and communication style is versatile, curious, and quick. You gather diverse information and excel at making connections between ideas."
            case "Cancer": return "Your thinking and communication style is intuitive, empathetic, and protective. You process information through feelings and personal associations."
            case "Leo": return "Your thinking and communication style is expressive, confident, and creative. You communicate with warmth and may have a flair for dramatic speech."
            case "Virgo": return "Your thinking and communication style is analytical, precise, and detail-oriented. You excel at critical thinking and practical problem-solving."
            case "Libra": return "Your thinking and communication style is balanced, diplomatic, and relationship-oriented. You consider multiple perspectives and seek fairness in communication."
            case "Scorpio": return "Your thinking and communication style is penetrating, investigative, and psychologically astute. You look beneath the surface and may communicate with strategic intensity."
            case "Sagittarius": return "Your thinking and communication style is expansive, optimistic, and philosophical. You see the big picture and communicate with enthusiasm and inspiration."
            case "Capricorn": return "Your thinking and communication style is structured, disciplined, and goal-oriented. You communicate with authority and prefer well-organized information."
            case "Aquarius": return "Your thinking and communication style is innovative, objective, and oriented toward larger social concerns. You think outside conventional frameworks."
            case "Pisces": return "Your thinking and communication style is intuitive, imaginative, and receptive. You process information through impressions and may communicate through imagery or metaphor."
            default: return "Your Mercury in \(signName) reflects your communication style and thought processes."
            }
            
        case "Venus":
            switch signName {
            case "Aries": return "You value directness and excitement in relationships and aesthetics. You approach attraction boldly and appreciate spontaneity and dynamic energy."
            case "Taurus": return "You value stability, sensuality, and tangible beauty. In relationships and aesthetics, you appreciate quality, comfort, and lasting enjoyment."
            case "Gemini": return "You value mental connection, variety, and playfulness. In relationships and aesthetics, you appreciate cleverness, communication, and adaptability."
            case "Cancer": return "You value emotional security, nurturing, and nostalgic beauty. In relationships and aesthetics, you appreciate warmth, protection, and sentimental value."
            case "Leo": return "You value romance, drama, and magnificent displays. In relationships and aesthetics, you appreciate generosity, loyalty, and creative expression."
            case "Virgo": return "You value refined taste, practical assistance, and subtle beauty. In relationships and aesthetics, you appreciate attention to detail and genuine usefulness."
            case "Libra": return "You value harmony, partnership, and balanced beauty. In relationships and aesthetics, you appreciate cooperation, diplomacy, and elegant proportions."
            case "Scorpio": return "You value emotional depth, intimacy, and transformative beauty. In relationships and aesthetics, you appreciate intensity, authenticity, and powerful emotions."
            case "Sagittarius": return "You value freedom, optimism, and expansive beauty. In relationships and aesthetics, you appreciate honesty, adventure, and meaningful inspiration."
            case "Capricorn": return "You value commitment, maturity, and timeless beauty. In relationships and aesthetics, you appreciate integrity, status, and enduring quality."
            case "Aquarius": return "You value independence, originality, and progressive beauty. In relationships and aesthetics, you appreciate friendship, innovation, and humanitarian values."
            case "Pisces": return "You value compassion, romance, and transcendent beauty. In relationships and aesthetics, you appreciate sensitivity, imagination, and spiritual connection."
            default: return "Your Venus in \(signName) reflects your relationship style and aesthetic values."
            }
            
        case "Mars":
            switch signName {
            case "Aries": return "You express energy and assert yourself directly and independently. You take initiative easily and approach challenges with courage and determination."
            case "Taurus": return "You express energy and assert yourself steadily and persistently. You mobilize resources effectively and work with determination toward tangible results."
            case "Gemini": return "You express energy and assert yourself through communication and mental agility. You use versatility and quick thinking to pursue goals and overcome obstacles."
            case "Cancer": return "You express energy and assert yourself indirectly and protectively. You use emotional sensitivity and intuition to pursue goals and defend what matters to you."
            case "Leo": return "You express energy and assert yourself dramatically and confidently. You use creativity, leadership, and personal magnetism to achieve objectives."
            case "Virgo": return "You express energy and assert yourself precisely and methodically. You use analytical skills and attention to detail to overcome challenges and improve situations."
            case "Libra": return "You express energy and assert yourself diplomatically and collaboratively. You use charm, fairness, and the ability to see multiple sides to achieve your aims."
            case "Scorpio": return "You express energy and assert yourself intensely and strategically. You use psychological insight and willpower to pursue goals and transform situations."
            case "Sagittarius": return "You express energy and assert yourself enthusiastically and optimistically. You use vision, faith, and a broad perspective to expand possibilities and overcome limitations."
            case "Capricorn": return "You express energy and assert yourself ambitiously and methodically. You use discipline, planning, and perseverance to achieve long-term objectives."
            case "Aquarius": return "You express energy and assert yourself independently and innovatively. You use originality, detachment, and group collaboration to pursue objectives."
            case "Pisces": return "You express energy and assert yourself subtly and intuitively. You use compassion, imagination, and adaptability to navigate challenges and pursue dreams."
            default: return "Your Mars in \(signName) reflects how you assert yourself and express energy."
            }
            
            // Interpretations for outer planets are more generational but still have personal significance
        case "Jupiter":
            switch signName {
            case "Aries": return "You seek growth through initiative, leadership, and independent action. Your optimism is expressed through pioneering new territory and taking risks."
            case "Taurus": return "You seek growth through building resources, stability, and sensory enjoyment. Your optimism is expressed through accumulating value and appreciating life's pleasures."
            case "Gemini": return "You seek growth through learning, communication, and intellectual variety. Your optimism is expressed through gathering knowledge and making connections."
            case "Cancer": return "You seek growth through emotional connection, nurturing, and creating security. Your optimism is expressed through developing intuition and forming family bonds."
            case "Leo": return "You seek growth through creative expression, recognition, and generosity. Your optimism is expressed through sharing your unique gifts and receiving appreciation."
            case "Virgo": return "You seek growth through refinement, service, and practical improvement. Your optimism is expressed through solving problems and developing skills."
            case "Libra": return "You seek growth through relationships, cooperation, and balanced exchange. Your optimism is expressed through creating harmony and appreciating beauty."
            case "Scorpio": return "You seek growth through transformation, deep connection, and psychological insight. Your optimism is expressed through regeneration and uncovering hidden truths."
            case "Sagittarius": return "You seek growth through exploration, higher education, and expanding horizons. Your optimism is expressed through faith, inspiration, and philosophical pursuits."
            case "Capricorn": return "You seek growth through achievement, responsibility, and structured development. Your optimism is expressed through earning status and building lasting foundations."
            case "Aquarius": return "You seek growth through innovation, group collaboration, and humanitarian ideals. Your optimism is expressed through progressive thinking and social reform."
            case "Pisces": return "You seek growth through compassion, spiritual connection, and imagination. Your optimism is expressed through transcending limitations and unifying experiences."
            default: return "Your Jupiter in \(signName) reflects where you seek growth, opportunity, and optimism."
            }
            
        case "Saturn":
            switch signName {
            case "Aries": return "Your life lessons involve developing patience with initiative and tempering impulsiveness with structure. You're learning to channel independent action responsibly."
            case "Taurus": return "Your life lessons involve setting appropriate boundaries with resources and finding security through inner rather than outer stability. You're learning responsible management of possessions and values."
            case "Gemini": return "Your life lessons involve developing mental discipline and communicating with precision and accountability. You're learning to overcome scattered thinking and develop focused expression."
            case "Cancer": return "Your life lessons involve balancing emotional security with necessary independence and developing emotional maturity. You're learning to create inner emotional stability."
            case "Leo": return "Your life lessons involve expressing creativity within appropriate limits and developing humble leadership. You're learning to find recognition through genuine achievement rather than drama."
            case "Virgo": return "Your life lessons involve distinguishing between helpful improvement and excessive criticism. You're learning to develop realistic standards of perfection and practical service."
            case "Libra": return "Your life lessons involve developing self-sufficiency within relationships and creating balanced boundaries. You're learning to take responsibility for harmony without compromising integrity."
            case "Scorpio": return "Your life lessons involve managing intense emotions and power dynamics with maturity. You're learning to transform through controlled release rather than suppression or eruption."
            case "Sagittarius": return "Your life lessons involve tempering optimism with realism and developing structured approaches to growth. You're learning to channel faith and enthusiasm into practical wisdom."
            case "Capricorn": return "Your life lessons involve balancing ambition with personal fulfillment and finding healthy expressions of authority. You're learning to achieve without excessive self-denial."
            case "Aquarius": return "Your life lessons involve innovating within practical frameworks and developing structured approaches to social change. You're learning to balance individualism with responsibility."
            case "Pisces": return "Your life lessons involve establishing boundaries within compassion and creating structure for spiritual pursuits. You're learning to maintain practical grounding amid intuitive experiences."
            default: return "Your Saturn in \(signName) reflects your areas of challenge, responsibility and life lessons."
            }
            
        case "Uranus":
            return "Uranus in \(signName) reflects the area of life where you express your uniqueness, seek freedom, and experience sudden changes or insights. This position is shared by others in your generation and shapes your approach to innovation and liberation."
            
        case "Neptune":
            return "Neptune in \(signName) reflects the area of life where you experience inspiration, dissolution of boundaries, and spiritual connection. This position is shared by others in your generation and shapes your ideals, dreams, and areas of potential confusion."
            
        case "Pluto":
            return "Pluto in \(signName) reflects the area of life where you experience profound transformation, power dynamics, and regeneration. This position is shared by others in your generation and shapes your approach to depth and personal evolution."
            
        case "Ceres":
            return "Ceres in \(signName) reflects how you nurture others and yourself, particularly in relation to physical sustenance and emotional nourishment. It shows your approach to caregiving and receiving care."
            
        case "Pallas":
            return "Pallas in \(signName) reflects your style of creative intelligence, problem-solving abilities, and pattern recognition. It shows where you express wisdom, strategy, and creative thinking."
            
        case "Juno":
            return "Juno in \(signName) reflects your approach to committed partnerships and what you seek in marriage or long-term relationships. It shows patterns in how you relate to significant others."
            
        default:
            return "\(planet) in \(signName) shapes your experience in relation to the qualities of this sign."
        }
    }
    
    // Interpret retrograde planets
    private static func planetRetrogradeInterpretation(planet: String) -> String {
        switch planet {
        case "Mercury":
            return "Mercury retrograde suggests your thinking and communication patterns involve revisiting, reviewing, and reconsidering information. You may process thoughts internally before expressing them, sometimes leading to misunderstandings with others who communicate more directly. This position can indicate a reflective mind that excels at careful analysis and revision."
            
        case "Venus":
            return "Venus retrograde suggests your approach to relationships and values involves a deeper internal process of evaluating what truly matters to you. You may need time to process feelings in relationships and might initially resist intimacy until trust is established. This position can indicate a refined aesthetic sense and ability to recognize authentic value beyond surface appearances."
            
        case "Mars":
            return "Mars retrograde suggests your expression of energy and assertion turns inward before manifesting externally. You may thoroughly process how to act before taking initiative, sometimes appearing hesitant when actually being strategic. This position can indicate a thoughtful approach to action that considers consequences and may lead to unusual effectiveness once you commit to a course."
            
        case "Jupiter":
            return "Jupiter retrograde suggests your path of growth and expansion involves looking within for wisdom rather than seeking it externally. Your philosophical understanding develops through personal reflection and questioning received wisdom. This position can indicate a personally meaningful approach to beliefs and the ability to find your own path to growth."
            
        case "Saturn":
            return "Saturn retrograde suggests your approach to responsibility and structure involves revisiting and redefining limitations based on inner authority rather than external expectations. You may question conventional achievement and develop your own standards of success. This position can indicate a thoughtful approach to boundaries and commitments."
            
        case "Uranus":
            return "Uranus retrograde suggests your expression of individuality and innovation develops through inner awakening rather than outer rebellion. You may appear conventional while harboring revolutionary ideas. This position can indicate a capacity for profound personal insights and unusual self-awareness."
            
        case "Neptune":
            return "Neptune retrograde suggests your connection to spirituality and imagination flows from within rather than being sought in external sources. You may be skeptical of collective dreams while nurturing personal visions. This position can indicate a discriminating approach to ideals and heightened ability to distinguish authentic inspiration from illusion."
            
        case "Pluto":
            return "Pluto retrograde suggests your process of transformation and empowerment involves deep internal regeneration rather than external power dynamics. You may process intense experiences privately before showing their effects. This position can indicate profound capacity for self-renewal and the ability to transform from within."
            
        default:
            return "\(planet) retrograde suggests a more internalized, reflective expression of this planet's energies in your life."
        }
    }
    
    // Interpret ascendant (rising sign)
    private static func interpretAscendant(sign: Int) -> String {
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        
        switch signName {
        case "Aries":
            return "With Aries rising, you approach life with directness, initiative, and a pioneering spirit. You may appear energetic, independent, and action-oriented to others. Your personal presence conveys confidence and courage, and you tend to meet challenges head-on. This ascendant can give you a youthful appearance or demeanor regardless of age."
            
        case "Taurus":
            return "With Taurus rising, you approach life with steadiness, practicality, and sensory awareness. You may appear stable, reliable, and grounded to others. Your personal presence conveys patience and determination, and you tend to build security through persistence. This ascendant can give you a solid physical presence and natural dignity."
            
        case "Gemini":
            return "With Gemini rising, you approach life with curiosity, adaptability, and mental quickness. You may appear versatile, communicative, and youthful to others. Your personal presence conveys intelligence and sociability, and you tend to engage with your environment through information gathering. This ascendant can give you an animated expression and responsive demeanor."
            
        case "Cancer":
            return "With Cancer rising, you approach life with sensitivity, receptivity, and protective instincts. You may appear nurturing, cautious, and emotionally aware to others. Your personal presence conveys warmth and care, and you tend to create security through emotional connections. This ascendant can give you a sympathetic appearance and responsive facial expressions."
            
        case "Leo":
            return "With Leo rising, you approach life with warmth, self-expression, and natural dignity. You may appear confident, generous, and dramatic to others. Your personal presence conveys charisma and pride, and you tend to make an impression through your authentic self-expression. This ascendant can give you a noble bearing and radiant energy."
            
        case "Virgo":
            return "With Virgo rising, you approach life with attention to detail, practicality, and a desire for improvement. You may appear precise, helpful, and observant to others. Your personal presence conveys competence and discernment, and you tend to interact with your environment by analyzing and refining. This ascendant can give you a neat appearance and alert expressions."
            
        case "Libra":
            return "With Libra rising, you approach life with diplomacy, an awareness of others, and a sense of balance. You may appear gracious, fair-minded, and aesthetically aware to others. Your personal presence conveys harmony and charm, and you tend to engage with your environment through relationship and cooperation. This ascendant can give you a symmetrical appearance and pleasing manners."
            
        case "Scorpio":
            return "With Scorpio rising, you approach life with intensity, perceptiveness, and emotional depth. You may appear mysterious, powerful, and reserved to others. Your personal presence conveys magnetism and determination, and you tend to engage with your environment through strategic observation. This ascendant can give you a penetrating gaze and commanding presence."
            
        case "Sagittarius":
            return "With Sagittarius rising, you approach life with optimism, expansiveness, and a sense of adventure. You may appear enthusiastic, straightforward, and philosophical to others. Your personal presence conveys confidence and inspiration, and you tend to engage with your environment through exploration and seeking meaning. This ascendant can give you an athletic bearing and open expression."
            
        case "Capricorn":
            return "With Capricorn rising, you approach life with discipline, responsibility, and practical ambition. You may appear dignified, serious, and capable to others. Your personal presence conveys authority and reliability, and you tend to engage with your environment through structured achievement. This ascendant can give you a composed demeanor and sometimes a reserved, mature appearance even when young."
            
        case "Aquarius":
            return "With Aquarius rising, you approach life with originality, detachment, and humanitarian awareness. You may appear unique, intellectually oriented, and somewhat unconventional to others. Your personal presence conveys independence and progressive thinking, and you tend to engage with your environment through innovation and social awareness. This ascendant can give you a distinctive appearance or style that sets you apart."
            
        case "Pisces":
            return "With Pisces rising, you approach life with receptivity, compassion, and intuitive awareness. You may appear gentle, dreamy, and impressionable to others. Your personal presence conveys sensitivity and adaptability, and you tend to engage with your environment through empathetic understanding. This ascendant can give you a fluid manner and expressive eyes that reflect your emotional state."
            
        default:
            return "Your Ascendant in \(signName) shapes how you approach new situations and how others perceive you initially."
        }
    }
    
    // Interpret midheaven (MC)
    private static func interpretMidheaven(sign: Int) -> String {
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        
        switch signName {
        case "Aries":
            return "With Midheaven in Aries, your career path and public role express through leadership, initiative, and pioneering action. You may be drawn to entrepreneurial ventures, competitive fields, or roles that require courage and independent action. You tend to approach achievement directly and may prefer career paths that offer quick results and new challenges."
            
        case "Taurus":
            return "With Midheaven in Taurus, your career path and public role express through building stability, managing resources, and creating tangible value. You may be drawn to financial sectors, arts that produce physical objects, or fields involving land or natural resources. You tend to approach achievement steadily and may prefer career paths that offer security and lasting rewards."
            
        case "Gemini":
            return "With Midheaven in Gemini, your career path and public role express through communication, information exchange, and versatile skills. You may be drawn to media, education, sales, or any field requiring adaptability and mental agility. You tend to approach achievement through continuous learning and may prefer career paths that offer variety and intellectual stimulation."
            
        case "Cancer":
            return "With Midheaven in Cancer, your career path and public role express through nurturing, protection, and emotional awareness. You may be drawn to healthcare, food industries, family services, or fields involving home and security. You tend to approach achievement through creating supportive environments and may prefer career paths that offer emotional fulfillment and opportunities to care for others."
            
        case "Leo":
            return "With Midheaven in Leo, your career path and public role express through leadership, creative expression, and visibility. You may be drawn to entertainment, management, education, or fields involving children and recreation. You tend to approach achievement through authentic self-expression and may prefer career paths that offer recognition and opportunities to inspire others."
            
        case "Virgo":
            return "With Midheaven in Virgo, your career path and public role express through analysis, improvement, and practical service. You may be drawn to healthcare, technology, research, or fields requiring attention to detail and problem-solving. You tend to approach achievement through developing specialized skills and may prefer career paths that offer opportunities to be useful and implement efficient systems."
            
        case "Libra":
            return "With Midheaven in Libra, your career path and public role express through diplomacy, relationship building, and creating harmony. You may be drawn to law, counseling, arts, or fields involving negotiation and aesthetic judgment. You tend to approach achievement through cooperation and may prefer career paths that offer opportunities to create balance and work with others."
            
        case "Scorpio":
            return "With Midheaven in Scorpio, your career path and public role express through depth, transformation, and strategic influence. You may be drawn to psychology, research, finance, or fields involving crisis management and regeneration. You tend to approach achievement through penetrating insight and may prefer career paths that offer opportunities for profound impact and dealing with hidden aspects of life."
            
        case "Sagittarius":
            return "With Midheaven in Sagittarius, your career path and public role express through expansion, inspiration, and broad vision. You may be drawn to higher education, international business, publishing, or fields involving travel and philosophical understanding. You tend to approach achievement through optimism and may prefer career paths that offer freedom and opportunities to explore new horizons."
            
        case "Capricorn":
            return "With Midheaven in Capricorn, your career path and public role express through ambition, structure, and responsible authority. You may be drawn to business, government, institutional leadership, or fields requiring long-term commitment and strategic planning. You tend to approach achievement through discipline and may prefer career paths that offer status and opportunities to build lasting structures."
            
        case "Aquarius":
            return "With Midheaven in Aquarius, your career path and public role express through innovation, social awareness, and progressive thinking. You may be drawn to technology, humanitarian organizations, scientific research, or fields involving social change and group dynamics. You tend to approach achievement through originality and may prefer career paths that offer intellectual freedom and opportunities to contribute to collective progress."
            
        case "Pisces":
            return "With Midheaven in Pisces, your career path and public role express through compassion, imagination, and spiritual or artistic sensitivity. You may be drawn to arts, healing professions, spiritual counseling, or fields involving empathy and transcendent experiences. You tend to approach achievement through intuition and may prefer career paths that offer opportunities for service and creative or spiritual fulfillment."
            
        default:
            return "Your Midheaven in \(signName) shapes your public role, career path, and approach to achievement."
        }
    }
    
    // Generate overall chart interpretation
    private static func generateOverallInterpretation(chart: NatalChartCalculator.NatalChart) -> String {
        // Get core placements
        let sunPlanet = chart.planets.first { $0.name == "Sun" }
        let moonPlanet = chart.planets.first { $0.name == "Moon" }
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        
        guard let sun = sunPlanet, let moon = moonPlanet else {
            return "This chart shows your unique astrological blueprint, with each placement reflecting different aspects of your personality and life experience."
        }
        
        let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sun.zodiacSign)
        let moonSignName = CoordinateTransformations.getZodiacSignName(sign: moon.zodiacSign)
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascSign)
        
        var interpretation = "Your natal chart reveals a complex interplay of cosmic energies at the moment of your birth. "
        
        // Add "big three" summary
        interpretation += "With your Sun in \(sunSignName), Moon in \(moonSignName), and \(ascSignName) rising, you combine "
        
        // Add element balance
        let elementBalance = analyzeElementBalance(chart: chart)
        interpretation += "Your chart shows \(elementBalance).\n\n"
        
        // Add modality balance
        let modalityBalance = analyzeModalityBalance(chart: chart)
        interpretation += modalityBalance + "\n\n"
        
        return interpretation
    }
    
    // Helper function to analyze element balance
    private static func analyzeElementBalance(chart: NatalChartCalculator.NatalChart) -> String {
        var fireCount = 0
        var earthCount = 0
        var airCount = 0
        var waterCount = 0
        
        // Count elements for major planets only
        for planet in chart.planets {
            // Skip outer planets for elemental balance
            if ["Uranus", "Neptune", "Pluto"].contains(planet.name) {
                continue
            }
            
            let element = getElement(sign: planet.zodiacSign)
            
            switch element {
            case "Fire": fireCount += 1
            case "Earth": earthCount += 1
            case "Air": airCount += 1
            case "Water": waterCount += 1
            default: break
            }
        }
        
        // Add ascendant to the count
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascElement = getElement(sign: ascSign)
        
        switch ascElement {
        case "Fire": fireCount += 1
        case "Earth": earthCount += 1
        case "Air": airCount += 1
        case "Water": waterCount += 1
        default: break
        }
        
        // Determine elemental emphasis
        var elementalBalance = "a balance of elemental energies"
        let total = fireCount + earthCount + airCount + waterCount
        let threshold = total / 4
        
        var strongElements: [String] = []
        var weakElements: [String] = []
        
        if fireCount > threshold + 1 {
            strongElements.append("Fire (initiative, enthusiasm, and self-expression)")
        } else if fireCount < threshold - 1 {
            weakElements.append("Fire (may need to cultivate courage and enthusiasm)")
        }
        
        if earthCount > threshold + 1 {
            strongElements.append("Earth (practicality, reliability, and groundedness)")
        } else if earthCount < threshold - 1 {
            weakElements.append("Earth (may need to develop practical structure)")
        }
        
        if airCount > threshold + 1 {
            strongElements.append("Air (intellectual perspective, communication, and social connection)")
        } else if airCount < threshold - 1 {
            weakElements.append("Air (may need to cultivate mental clarity and objectivity)")
        }
        
        if waterCount > threshold + 1 {
            strongElements.append("Water (emotional depth, intuition, and empathy)")
        } else if waterCount < threshold - 1 {
            weakElements.append("Water (may need to develop emotional awareness)")
        }
        
        if !strongElements.isEmpty {
            elementalBalance = "an emphasis on " + strongElements.joined(separator: " and ")
        }
        
        if !weakElements.isEmpty {
            elementalBalance += " with less emphasis on " + weakElements.joined(separator: " and ")
        }
        
        return elementalBalance
    }
    
    // Helper function to get element from sign
    private static func getElement(sign: Int) -> String {
        switch sign {
        case 1, 5, 9: return "Fire"
        case 2, 6, 10: return "Earth"
        case 3, 7, 11: return "Air"
        case 4, 8, 12: return "Water"
        default: return "Unknown"
        }
    }
    
    // Helper function to analyze modality balance
    private static func analyzeModalityBalance(chart: NatalChartCalculator.NatalChart) -> String {
        var cardinalCount = 0
        var fixedCount = 0
        var mutableCount = 0
        
        // Count modalities for major planets only
        for planet in chart.planets {
            // Skip outer planets for modality balance
            if ["Uranus", "Neptune", "Pluto"].contains(planet.name) {
                continue
            }
            
            let modality = getModality(sign: planet.zodiacSign)
            
            switch modality {
            case "Cardinal": cardinalCount += 1
            case "Fixed": fixedCount += 1
            case "Mutable": mutableCount += 1
            default: break
            }
        }
        
        // Add ascendant to the count
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascModality = getModality(sign: ascSign)
        
        switch ascModality {
        case "Cardinal": cardinalCount += 1
        case "Fixed": fixedCount += 1
        case "Mutable": mutableCount += 1
        default: break
        }
        
        // Determine modality emphasis
        var modalityBalance = "You express a balance between initiating change, maintaining stability, and adapting to circumstances."
        let total = cardinalCount + fixedCount + mutableCount
        let threshold = total / 3
        
        var strongModalities: [String] = []
        var weakModalities: [String] = []
        
        if cardinalCount > threshold + 1 {
            strongModalities.append("Cardinal qualities (initiative, leadership, and pioneering action)")
        } else if cardinalCount < threshold - 1 {
            weakModalities.append("Cardinal qualities (may need to develop more initiative)")
        }
        
        if fixedCount > threshold + 1 {
            strongModalities.append("Fixed qualities (persistence, stability, and determination)")
        } else if fixedCount < threshold - 1 {
            weakModalities.append("Fixed qualities (may need to develop more consistency)")
        }
        
        if mutableCount > threshold + 1 {
            strongModalities.append("Mutable qualities (adaptability, flexibility, and responsiveness)")
        } else if mutableCount < threshold - 1 {
            weakModalities.append("Mutable qualities (may need to develop more adaptability)")
        }
        
        if !strongModalities.isEmpty {
            modalityBalance = "Your chart emphasizes " + strongModalities.joined(separator: " and ")
        }
        
        if !weakModalities.isEmpty {
            modalityBalance += " with less emphasis on " + weakModalities.joined(separator: " and ")
        }
        
        return modalityBalance
    }
    
    // Helper function to get modality from sign
    private static func getModality(sign: Int) -> String {
        switch sign {
        case 1, 4, 7, 10: return "Cardinal"
        case 2, 5, 8, 11: return "Fixed"
        case 3, 6, 9, 12: return "Mutable"
        default: return "Unknown"
        }
    }
    
    // Generate specific guidance based on chart elements
    static func generateGuidance(chart: NatalChartCalculator.NatalChart) -> String {
        var guidance = "Based on your natal chart, here are some areas for growth and development:\n\n"
        
        // Find Sun, Moon, and Ascendant
        let sunPlanet = chart.planets.first { $0.name == "Sun" }
        let moonPlanet = chart.planets.first { $0.name == "Moon" }
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        
        // Add guidance for Sun sign
        if let sun = sunPlanet {
            guidance += "• With your Sun in \(CoordinateTransformations.getZodiacSignName(sign: sun.zodiacSign)), focus on developing your "
            
            switch sun.zodiacSign {
            case 1: guidance += "courage, initiative, and leadership abilities. Take time for self-assertion and independent action."
            case 2: guidance += "patience, reliability, and practical skills. Cultivate stability and appreciate sensory pleasures mindfully."
            case 3: guidance += "communication skills, mental agility, and curiosity. Seek diverse learning experiences and social connections."
            case 4: guidance += "emotional intelligence, nurturing capabilities, and sense of security. Honor your sensitivity and create a supportive home base."
            case 5: guidance += "creativity, self-expression, and generosity. Make time for play and activities that bring joy and recognition."
            case 6: guidance += "analytical skills, attention to detail, and service orientation. Refine your abilities and create healthy routines."
            case 7: guidance += "diplomatic skills, aesthetic awareness, and partnership abilities. Seek balance and cultivate meaningful relationships."
            case 8: guidance += "emotional depth, transformative capacity, and psychological insight. Embrace change and explore what lies beneath the surface."
            case 9: guidance += "vision, optimism, and philosophical understanding. Seek knowledge and experiences that expand your horizons."
            case 10: guidance += "discipline, ambition, and organizational skills. Work toward long-term goals and develop your sense of authority."
            case 11: guidance += "originality, humanitarian awareness, and collaborative skills. Connect with groups and causes that support your vision for the future."
            case 12: guidance += "compassion, imagination, and spiritual awareness. Make time for retreat and activities that transcend ordinary boundaries."
            default: guidance += "unique qualities and authentic self-expression."
            }
            
            guidance += "\n\n"
        }
        
        // Add guidance for Moon sign
        if let moon = moonPlanet {
            guidance += "• With your Moon in \(CoordinateTransformations.getZodiacSignName(sign: moon.zodiacSign)), nurture your emotional well-being by "
            
            switch moon.zodiacSign {
            case 1: guidance += "allowing yourself space for spontaneous emotional expression and physical activity to process feelings."
            case 2: guidance += "creating stable routines and comfortable environments that provide sensory satisfaction and security."
            case 3: guidance += "expressing your feelings through conversation and seeking intellectual understanding of your emotional patterns."
            case 4: guidance += "honoring your deep sensitivity, creating private space for emotional processing, and connecting with close family or chosen family."
            case 5: guidance += "engaging in creative self-expression, play, and receiving appreciation from others."
            case 6: guidance += "creating order in your environment, being of service to others, and maintaining healthy routines."
            case 7: guidance += "cultivating harmonious relationships, aesthetic experiences, and balanced emotional exchanges."
            case 8: guidance += "allowing for emotional depth, transformative experiences, and authentic intimacy."
            case 9: guidance += "finding inspiring activities, philosophical frameworks for understanding emotions, and maintaining optimism."
            case 10: guidance += "setting and achieving goals, creating structure, and developing emotional maturity and self-sufficiency."
            case 11: guidance += "connecting with friends and groups, exploring unconventional emotional expression, and maintaining some detachment."
            case 12: guidance += "creating time for solitude, spiritual practice, and artistic or imaginative activities."
            default: guidance += "honoring your unique emotional needs and patterns."
            }
            
            guidance += "\n\n"
        }
        
        // Add guidance for Ascendant
        guidance += "• With your \(CoordinateTransformations.getZodiacSignName(sign: ascSign)) Ascendant, develop your personal approach by "
        
        switch ascSign {
        case 1: guidance += "embracing direct action, physical energy, and courage in new situations. Be mindful of impulsiveness."
        case 2: guidance += "cultivating patience, reliability, and sensory awareness. Be mindful of potential stubbornness or resistance to change."
        case 3: guidance += "expressing curiosity, communication skills, and adaptability. Be mindful of potential scattered energy or superficiality."
        case 4: guidance += "honoring your sensitivity, protective instincts, and emotional receptivity. Be mindful of potential defensiveness or withdrawal."
        case 5: guidance += "expressing warmth, creativity, and natural leadership. Be mindful of potential drama or excessive need for attention."
        case 6: guidance += "developing analytical skills, helpfulness, and attention to detail. Be mindful of potential criticism or worry."
        case 7: guidance += "cultivating diplomacy, relationship skills, and aesthetic awareness. Be mindful of potential indecisiveness or dependency."
        case 8: guidance += "embracing intensity, psychological depth, and transformative capacity. Be mindful of potential secretiveness or control issues."
        case 9: guidance += "expressing optimism, honesty, and broad vision. Be mindful of potential overconfidence or restlessness."
        case 10: guidance += "developing responsibility, structured approach, and perseverance. Be mindful of potential rigidity or excessive seriousness."
        case 11: guidance += "cultivating originality, progressive thinking, and humanitarian awareness. Be mindful of potential detachment or eccentricity."
        case 12: guidance += "honoring sensitivity, compassion, and intuitive awareness. Be mindful of potential boundary issues or escapism."
        default: guidance += "embracing your authentic way of presenting yourself to the world."
        }
        
        // Add overall balance guidance
        guidance += "\n\n• Overall balance: " + getBalanceGuidance(chart: chart)
        
        return guidance
    }
    
    // Helper function to generate balance guidance
    private static func getBalanceGuidance(chart: NatalChartCalculator.NatalChart) -> String {
        // Simplified analysis of elemental balance
        var fireCount = 0
        var earthCount = 0
        var airCount = 0
        var waterCount = 0
        
        // Count elements for planets
        for planet in chart.planets where !["Uranus", "Neptune", "Pluto"].contains(planet.name) {
            let element = getElement(sign: planet.zodiacSign)
            
            switch element {
            case "Fire": fireCount += 1
            case "Earth": earthCount += 1
            case "Air": airCount += 1
            case "Water": waterCount += 1
            default: break
            }
        }
        
        // Generate guidance based on elemental balance
        var guidance = "Consider ways to balance your elemental energies. "
        
        if fireCount < 2 {
            guidance += "You may benefit from cultivating more Fire energy through physical activity, creative passion, and developing courage and initiative. "
        }
        
        if earthCount < 2 {
            guidance += "You may benefit from cultivating more Earth energy through practical activities, creating structure, and developing patience and reliability. "
        }
        
        if airCount < 2 {
            guidance += "You may benefit from cultivating more Air energy through intellectual pursuits, social connection, and developing communication skills and objectivity. "
        }
        
        if waterCount < 2 {
            guidance += "You may benefit from cultivating more Water energy through emotional awareness, intuitive development, and creating deeper connections with others. "
        }
        
        return guidance
    }
}
