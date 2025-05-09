//
//  WeatherService.swift
//  Cosmic Fit
//
//  Fetches current‑day weather from Open‑Meteo
//

import Foundation
import CoreLocation

struct TodayWeather {
    let conditions : String   // e.g. "Partly cloudy"
    let temp       : Double   // °C
    let humidity   : Int      // %
    let windKph    : Double   // km/h
}

enum WeatherError: Error { case badResponse, decode }

final class WeatherService {
    
    static let shared = WeatherService()
    private init() {}
    
    /// Returns the weather summary for **right now / today** at `lat,lon`.
    func fetch(lat: Double, lon: Double) async throws -> TodayWeather {
        let url = URL(string:
            "https://api.open-meteo.com/v1/forecast" +
            "?latitude=\(lat)&longitude=\(lon)" +
            "&current_weather=true" +
            "&hourly=relativehumidity_2m" +
            "&timezone=auto")!
        
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw WeatherError.badResponse
        }
        struct Root: Decodable {
            struct Current: Decodable {
                let temperature: Double
                let windspeed: Double
                let weathercode: Int
                let time: String
            }
            struct Hourly: Decodable {
                let time: [String]
                let relativehumidity_2m: [Int]
            }
            let current_weather: Current
            let hourly: Hourly
        }
        let r = try JSONDecoder().decode(Root.self, from: data)
        
        // pick humidity value whose timestamp matches current weather time
        let idx = r.hourly.time.firstIndex(of: r.current_weather.time) ?? 0
        let humidity = r.hourly.relativehumidity_2m[idx]
        
        return TodayWeather(
            conditions: Self.describe(code: r.current_weather.weathercode),
            temp:       r.current_weather.temperature,
            humidity:   humidity,
            windKph:    r.current_weather.windspeed)
    }
    
    // Open‑Meteo weather‑code → text
    private static func describe(code: Int) -> String {
        switch code {
        case 0:   return "Clear"
        case 1,2: return "Partly cloudy"
        case 3:   return "Overcast"
        case 45,48: return "Fog"
        case 51,53,55: return "Drizzle"
        case 56,57:    return "Freezing drizzle"
        case 61,63,65: return "Rain"
        case 66,67:    return "Freezing rain"
        case 71,73,75: return "Snow"
        case 80,81,82: return "Showers"
        case 95:       return "Thunderstorm"
        case 96,99:    return "Thunderstorm + hail"
        default:       return "Unknown"
        }
    }
}
