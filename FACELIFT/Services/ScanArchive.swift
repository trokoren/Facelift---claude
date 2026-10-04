import Foundation

/// Saves her scans (scores, consultations, recommendations; never photos) to a file on this
/// phone, protected while the phone is locked. Placeholder scans are never saved.
enum ScanArchive {
    private static var url: URL? {
        guard let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("scans.json")
    }

    /// Her saved scans, or nil if she has never scanned (or the file can't be read). Empty when
    /// she deleted them all, so placeholders don't come back.
    static func load() -> [Scan]? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode([Scan].self, from: data)
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
            // Only placeholders on screen: keep no file, so placeholders show next launch too.
            // Nothing at all (she deleted everything): save an empty list so they don't return.
            if real.isEmpty && !scans.isEmpty {
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
