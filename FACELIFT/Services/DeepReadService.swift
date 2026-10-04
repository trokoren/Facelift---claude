import Foundation

/// Asks the server (Supabase function "deep-read") for the longer "Dive in" read on each
/// concern. No photo is sent: just the concerns, her scores, skin type and answers.
enum DeepReadService {
    struct Read: Decodable {
        let key: String
        let why: String
        let todo: String
        let expect: String

        private enum CodingKeys: String, CodingKey { case key, why, todo, expect }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            func text(_ k: CodingKeys) -> String { (try? c.decodeIfPresent(String.self, forKey: k)) ?? "" }
            key = text(.key); why = text(.why); todo = text(.todo); expect = text(.expect)
        }
    }

    static func fetch(consult: Consult, measures: [String: Int], context: [String: Any]) async throws -> [Read] {
        guard let url = Backend.functionURL("deep-read") else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Backend.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        let concerns: [[String: Any]] = consult.concerns.map { concern in
            var item: [String: Any] = [
                "key": concern.key, "title": concern.title, "severity": concern.severity,
                "summary": concern.summary, "seen": concern.seen,
            ]
            if let score = measures[concern.key] { item["score"] = score }
            return item
        }
        let body: [String: Any] = [
            "concerns": concerns,
            "skinType": consult.skinType.label,
            "scores": measures,
            "context": context,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        struct Envelope: Decodable { let reads: [Read] }
        return try JSONDecoder().decode(Envelope.self, from: data).reads
    }
}
