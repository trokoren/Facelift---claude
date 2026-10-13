import Foundation

/// Backs up her scans to her FACELIFT account (Supabase table `member_scans`), so they follow
/// her to a new iPhone. Scores, consultations and recommendations only: no photos (scans never
/// hold them) and no health answers (those live in her profile, which stays on the phone).
///
/// Only when she's signed in. The phone stays the main copy: every change is saved there first,
/// then uploaded in the background. Signing in on a new phone brings her scans back. Deleting
/// her account erases the backup (the table rows go with the account).
enum ScanSync {
    private static var table: URL? { URL(string: "\(Backend.supabaseURL)/rest/v1/member_scans") }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private struct Row: Codable {
        let user_id: String
        let scan_id: UUID
        let scanned_at: Date
        let data: Scan
    }

    /// Her backed-up scans, or nil if she isn't signed in or the server can't be reached.
    static func fetch() async -> [Scan]? {
        guard let auth = await credentials(),
              var parts = table.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else { return nil }
        parts.queryItems = [
            URLQueryItem(name: "select", value: "user_id,scan_id,scanned_at,data"),
            URLQueryItem(name: "order", value: "scanned_at.desc"),
        ]
        guard let url = parts.url else { return nil }
        var request = baseRequest(url, token: auth.token)
        request.httpMethod = "GET"
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        do {
            return try decoder.decode([Row].self, from: data).map(\.data)
        } catch {
            #if DEBUG
            print("Backed-up scans couldn't be read:", error)
            #endif
            return nil
        }
    }

    /// Adds or updates these scans in her backup.
    @discardableResult
    static func upload(_ scans: [Scan]) async -> Bool {
        let real = scans.filter { !$0.isSample }
        guard !real.isEmpty, let auth = await credentials(),
              var parts = table.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else { return false }
        parts.queryItems = [URLQueryItem(name: "on_conflict", value: "user_id,scan_id")]
        guard let url = parts.url,
              let body = try? encoder.encode(real.map { Row(user_id: auth.userID, scan_id: $0.id, scanned_at: $0.date, data: $0) })
        else { return false }
        var request = baseRequest(url, token: auth.token)
        request.httpMethod = "POST"
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = body
        guard let (data, response) = try? await URLSession.shared.data(for: request) else { return false }
        let ok = (200..<300).contains((response as? HTTPURLResponse)?.statusCode ?? 0)
        #if DEBUG
        if !ok { print("Scan backup failed:", String(data: data, encoding: .utf8) ?? "") }
        #endif
        return ok
    }

    /// Removes scans from her backup. Pass nil to remove all of them.
    static func delete(_ ids: [UUID]?) async {
        guard let auth = await credentials(),
              var parts = table.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else { return }
        var items = [URLQueryItem(name: "user_id", value: "eq.\(auth.userID)")]
        if let ids {
            guard !ids.isEmpty else { return }
            items.append(URLQueryItem(name: "scan_id", value: "in.(\(ids.map(\.uuidString).joined(separator: ",")))"))
        }
        parts.queryItems = items
        guard let url = parts.url else { return }
        var request = baseRequest(url, token: auth.token)
        request.httpMethod = "DELETE"
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Helpers

    private static func credentials() async -> (token: String, userID: String)? {
        guard Backend.isConfigured,
              let userID = Account.shared.user?.id,
              let token = await Account.shared.accessToken() else { return nil }
        return (token, userID)
    }

    private static func baseRequest(_ url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        return request
    }
}
