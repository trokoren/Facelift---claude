import Foundation

/// The deeper progress review she opens from "Your progress update". Written in the background
/// after a scan, only when one is due (see `AppStore.progressReviewReason`). Saved on this phone.
struct ProgressReview: Codable, Hashable {
    struct Change: Codable, Hashable, Identifiable {
        let area: String
        let note: String
        var id: String { area }
    }

    var date: Date = Date()
    /// The newest scan this review covers, and how many real scans existed then.
    var scanID: UUID = UUID()
    var scanCount: Int = 0
    let title: String
    let summary: String
    let changes: [Change]
    let steady: String
    let focus: String
    let next: String

    private enum CodingKeys: String, CodingKey { case date, scanID, scanCount, title, summary, changes, steady, focus, next }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func text(_ key: CodingKeys) -> String { (try? c.decodeIfPresent(String.self, forKey: key)) ?? "" }
        date = (try? c.decodeIfPresent(Date.self, forKey: .date)) ?? Date()
        scanID = (try? c.decodeIfPresent(UUID.self, forKey: .scanID)) ?? UUID()
        scanCount = (try? c.decodeIfPresent(Int.self, forKey: .scanCount)) ?? 0
        title = text(.title)
        summary = text(.summary)
        changes = ((try? c.decodeIfPresent([Change].self, forKey: .changes)) ?? []).filter { !$0.note.isEmpty }
        steady = text(.steady)
        focus = text(.focus)
        next = text(.next)
    }
}
