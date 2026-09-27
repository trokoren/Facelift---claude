import Foundation

/// Typical local conditions that affect skin: average UV, average humidity and air quality.
///
/// UV and humidity are long-term yearly averages from NASA POWER (public data, no key).
/// If NASA can't be reached, today's values from Open-Meteo are used instead so the screen
/// never comes up empty. Air quality is a ~3-month average from Open-Meteo, whose free tier is non-commercial:
/// move that to a paid plan (or another source) before launch.
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

        let averages = await nasaAverages(lat: lat, lon: lon)
        let today = await openMeteoToday(lat: lat, lon: lon)

        guard let uv = averages?.uv ?? today?.uv,
              let humidity = averages?.humidity ?? today?.humidity else { return nil }

        #if DEBUG
        print("[SkinConditions] NASA averages: uv=\(averages?.uv.description ?? "nil") humidity=\(averages?.humidity.description ?? "nil") | Open-Meteo today: uv=\(today?.uv.description ?? "nil") humidity=\(today?.humidity.description ?? "nil") aqi=\(today?.aqi.description ?? "nil")")
        #endif

        return SkinConditions(
            uvIndex: Int(uv.rounded()),
            humidity: Int(humidity.rounded()),
            usAQI: Int((today?.aqi ?? 0).rounded())
        )
    }

    /// Yearly ("ANN") averages from NASA POWER's climatology endpoint. -999 means no data.
    private static func nasaAverages(lat: String, lon: String) async -> (uv: Double?, humidity: Double?)? {
        guard let url = URL(string: "https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=RH2M,ALLSKY_SFC_UV_INDEX&community=RE&longitude=\(lon)&latitude=\(lat)&format=JSON"),
              let response = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: response.0) as? [String: Any],
              let properties = json["properties"] as? [String: Any],
              let parameters = properties["parameter"] as? [String: Any]
        else { return nil }

        func annual(_ key: String) -> Double? {
            guard let values = parameters[key] as? [String: Any],
                  let value = (values["ANN"] as? NSNumber)?.doubleValue,
                  value > -900 else { return nil }
            return value
        }

        let uv = annual("ALLSKY_SFC_UV_INDEX")
        let humidity = annual("RH2M")
        return (uv == nil && humidity == nil) ? nil : (uv, humidity)
    }

    /// Today's peak UV and average humidity, plus the average air quality over the last ~3 months,
/// from Open-Meteo.
    private static func openMeteoToday(lat: String, lon: String) async -> (uv: Double?, humidity: Double?, aqi: Double?)? {
        guard
            let weatherURL = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=uv_index_max&hourly=relative_humidity_2m&forecast_days=1&timezone=auto"),
            let airURL = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&hourly=us_aqi&past_days=92&forecast_days=1")
        else { return nil }

        var uv: Double?
        var humidity: Double?
        var aqi: Double?

        if let response = try? await URLSession.shared.data(from: weatherURL),
           let weather = try? JSONDecoder().decode(WeatherResponse.self, from: response.0) {
            uv = weather.daily.uvIndexMax.compactMap { $0 }.first
            let hourly = weather.hourly.relativeHumidity.compactMap { $0 }
            if !hourly.isEmpty { humidity = hourly.reduce(0, +) / Double(hourly.count) }
        }
        if let response = try? await URLSession.shared.data(from: airURL),
           let air = try? JSONDecoder().decode(AirResponse.self, from: response.0) {
            let readings = air.hourly.usAQI.compactMap { $0 }
            if !readings.isEmpty { aqi = readings.reduce(0, +) / Double(readings.count) }
        }
        return (uv == nil && humidity == nil && aqi == nil) ? nil : (uv, humidity, aqi)
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
        struct Hourly: Decodable {
            let usAQI: [Double?]
            enum CodingKeys: String, CodingKey { case usAQI = "us_aqi" }
        }
        let hourly: Hourly
    }
}
