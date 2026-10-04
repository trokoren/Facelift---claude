import Foundation

/// Her established skin type. Skin type changes slowly, so it's read fresh on her first scan,
/// then kept steady and re-read every 4th scan (or after 90 days). Saved on this phone.
struct SkinTypeRecord: Codable {
    var label: String
    var explanation: String
    var date: Date
    /// Scans since it was last read.
    var scansSince: Int

    private static let key = "facelift.skinType.v2"

    static func load() -> SkinTypeRecord? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SkinTypeRecord.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    /// True when the next scan should read her skin type fresh.
    static var isDue: Bool {
        guard let record = load() else { return true }
        return record.scansSince >= 3 || Date().timeIntervalSince(record.date) > 90 * 86_400
    }
}
