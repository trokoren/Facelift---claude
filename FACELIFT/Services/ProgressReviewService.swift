import Foundation

/// Asks the server to write her progress review. Numbers only: dates and scores, never photos.
enum ProgressReviewService {
    static func write(scans: [Scan], anchorIndex: Int, reason: String, context: [String: Any]) async throws -> ProgressReview {
        guard let url = Backend.functionURL("progress-review") else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Backend.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        let iso = ISO8601DateFormatter()
        let body: [String: Any] = [
            "reason": reason,
            "anchor_index": anchorIndex,
            "context": context,
            "scans": scans.map { ["date": iso.string(from: $0.date), "overall": $0.overallScore, "measures": $0.measures] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        struct Wrapper: Decodable { let review: ProgressReview }
        return try JSONDecoder().decode(Wrapper.self, from: data).review
    }
}
