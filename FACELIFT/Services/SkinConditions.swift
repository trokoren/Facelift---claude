import Foundation

/// Typical local conditions that affect skin: midday UV, humidity and air quality.
///
/// Built into the app (`Resources/climate.json`, made once by `tools/climate/build_climate.py`),
/// so the screen is instant and works offline. Her city gets the nearest city in the table.
/// UV is the typical midday UV index averaged over the year and humidity the yearly average
/// (both NASA POWER). Air quality is the EPA's median AQI for her metro area (US only; nil
/// elsewhere, and the card is hidden).
struct SkinConditions: Equatable {
    let uvIndex: Int
    let humidity: Int
    let usAQI: Int?

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
        switch usAQI ?? 0 {
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
    /// Farther than this from every city in the table, we show nothing rather than guess.
    private static let maxDistanceKm = 400.0

    static func fetch(latitude: Double, longitude: Double) async -> SkinConditions? {
        lookup(latitude: latitude, longitude: longitude)
    }

    static func lookup(latitude: Double, longitude: Double) -> SkinConditions? {
        guard let nearest = cities.min(by: {
            distanceKm(latitude, longitude, $0.lat, $0.lon) < distanceKm(latitude, longitude, $1.lat, $1.lon)
        }), distanceKm(latitude, longitude, nearest.lat, nearest.lon) <= maxDistanceKm else { return nil }
        return SkinConditions(uvIndex: Int(nearest.uv.rounded()), humidity: nearest.humidity, usAQI: nearest.aqi)
    }

    private struct City {
        let lat: Double
        let lon: Double
        let uv: Double
        let humidity: Int
        let aqi: Int?
    }

    /// Rows: [name, region, country, lat, lon, uv_midday_year, uv_midday_peak_month, humidity, aqi].
    private static let cities: [City] = {
        guard let url = Bundle.main.url(forResource: "climate", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["cities"] as? [[Any]] else { return [] }
        return rows.compactMap { row in
            guard row.count >= 9,
                  let lat = (row[3] as? NSNumber)?.doubleValue,
                  let lon = (row[4] as? NSNumber)?.doubleValue,
                  let uv = (row[5] as? NSNumber)?.doubleValue,
                  let humidity = (row[7] as? NSNumber)?.intValue else { return nil }
            return City(lat: lat, lon: lon, uv: uv, humidity: humidity, aqi: (row[8] as? NSNumber)?.intValue)
        }
    }()

    private static func distanceKm(_ aLat: Double, _ aLon: Double, _ bLat: Double, _ bLon: Double) -> Double {
        let p = Double.pi / 180
        let h = pow(sin((bLat - aLat) * p / 2), 2) + cos(aLat * p) * cos(bLat * p) * pow(sin((bLon - aLon) * p / 2), 2)
        return 12742 * asin(min(1, sqrt(h)))
    }
}
