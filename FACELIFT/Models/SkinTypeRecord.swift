import Foundation

/// Her last measured skin type. It's read fresh on every scan; this record lets the next
/// scan say whether it held or changed. Saved on this phone.
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

    /// True when the next scan should read her skin type fresh: every scan, so each reading
    /// reflects the face in front of the camera. The last reading is kept only to say whether
    /// it held ("Confirmed") or moved ("Changed from ...").
    static var isDue: Bool { true }
}
