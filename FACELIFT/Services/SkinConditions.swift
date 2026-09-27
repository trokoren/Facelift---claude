import Foundation

/// Today's local conditions that affect skin: peak UV, average humidity and air quality.
/// Data comes from Open-Meteo (no API key). Their free tier is for non-commercial use, so switch
/// to a paid Open-Meteo plan or Apple WeatherKit before launch.
struct SkinConditions: Equatable {
    let uvIndex: Int
    let humidity: Int
    let usAQI: Int

    // MARK: UV

    var uvLevel: String {
        switch uvIndex {
        case ..<3: "Low"
        case ..<6: "Moderate"
        case ..<8: "High"
        case ..<11: "Very High"
        default: "Extreme"
        }
    }

    var uvAdvice: String {
        switch uvIndex {
        case ..<3: "SPF is still a smart habit"
        case ..<6: "SPF 30 before heading out"
        case ..<8: "Reapply SPF every 2 hours"
        case ..<11: "Limit midday sun"
        default: "Avoid peak sun exposure"
        }
    }

    // MARK: Humidity

    var humidityLevel: String {
        switch humidity {
        case ..<30: "Dry"
        case ...60: "Comfortable"
        default: "Humid"
        }
    }

    var humidityNote: String {
        switch humidity {
        case ..<30: "Barrier needs extra moisture"
        case ...60: "Optimal for skin barrier"
        default: "Lighter textures work best"
        }
    }

    // MARK: Air quality (US AQI)

    static let pollutionLevels = ["Low", "Moderate", "High", "Very High"]

    var pollutionIndex: Int {
        switch usAQI {
        case ...50: 0
        case ...100: 1
        case ...150: 2
        default: 3
        }
    }

    var pollutionLevel: String { Self.pollutionLevels[pollutionIndex] }

    var pollutionNote: String {
        switch pollutionIndex {
        case 0: "Minimal impact on skin"
        case 1: "Double cleanse at night"
        case 2: "Barrier protection critical"
        default: "Antioxidants + barrier care"
        }
    }
}

enum SkinConditionsService {
    static func fetch(latitude: Double, longitude: Double) async -> SkinConditions? {
        let lat = String(format: "%.4f", latitude)
        let lon = String(format: "%.4f", longitude)
        guard
            let weatherURL = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=uv_index_max&hourly=relative_humidity_2m&forecast_days=1&timezone=auto"),
            let airURL = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=us_aqi")
        else { return nil }

        do {
            let (weatherData, _) = try await URLSession.shared.data(from: weatherURL)
            let (airData, _) = try await URLSession.shared.data(from: airURL)
            let weather = try JSONDecoder().decode(WeatherResponse.self, from: weatherData)
            let air = try JSONDecoder().decode(AirResponse.self, from: airData)

            let hourly = weather.hourly.relativeHumidity.compactMap { $0 }
            guard let uv = weather.daily.uvIndexMax.compactMap({ $0 }).first, !hourly.isEmpty else { return nil }
            let avgHumidity = hourly.reduce(0, +) / Double(hourly.count)

            return SkinConditions(
                uvIndex: Int(uv.rounded()),
                humidity: Int(avgHumidity.rounded()),
                usAQI: Int((air.current.usAQI ?? 0).rounded())
            )
        } catch {
            return nil
        }
    }

    private struct WeatherResponse: Decodable {
        struct Daily: Decodable {
            let uvIndexMax: [Double?]
            enum CodingKeys: String, CodingKey { case uvIndexMax = "uv_index_max" }
        }
        struct Hourly: Decodable {
            let relativeHumidity: [Double?]
            enum CodingKeys: String, CodingKey { case relativeHumidity = "relative_humidity_2m" }
        }
        let daily: Daily
        let hourly: Hourly
    }

    private struct AirResponse: Decodable {
        struct Current: Decodable {
            let usAQI: Double?
            enum CodingKeys: String, CodingKey { case usAQI = "us_aqi" }
        }
        let current: Current
    }
}
