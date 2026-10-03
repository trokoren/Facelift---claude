import Foundation

/// Saves her scans (scores, consultations, recommendations; never photos) to a file on this
/// phone, protected while the phone is locked. Placeholder scans are never saved.
enum ScanArchive {
    private static var url: URL? {
        guard let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("scans.json")
    }

    /// Her saved scans, or nil if she has none yet (or the file can't be read).
    static func load() -> [Scan]? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        do {
            let scans = try JSONDecoder().decode([Scan].self, from: data)
            return scans.isEmpty ? nil : scans
        } catch {
            #if DEBUG
            print("Saved scans couldn't be read:", error)
            #endif
            return nil
        }
    }

    static func save(_ scans: [Scan]) {
        guard let url else { return }
        let real = scans.filter { !$0.isSample }
        do {
            if real.isEmpty {
                try? FileManager.default.removeItem(at: url)
                return
            }
            let data = try JSONEncoder().encode(real)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            #if DEBUG
            print("Scans couldn't be saved:", error)
            #endif
        }
    }
}
