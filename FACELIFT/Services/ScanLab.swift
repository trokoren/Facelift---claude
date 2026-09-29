import Foundation
import Observation

/// Test bench for choosing how scans are read (Claude only vs YouCam + Claude) and how steady
/// each setup's scores are. Only reachable from debug builds. Keeps scores only, never photos.
@Observable
final class ScanLab {
    enum Mode: String, CaseIterable, Identifiable, Codable {
        case claude
        case hybrid4
        case hybrid6

        var id: String { rawValue }

        var title: String {
            switch self {
            case .claude: "Claude only"
            case .hybrid4: "YouCam 4 + Claude"
            case .hybrid6: "YouCam 6 + Claude"
            }
        }

        /// Rough cost per scan at ~4.5 cents per YouCam unit plus ~2 cents for Claude.
        var costNote: String {
            switch self {
            case .claude: "about 2¢ a scan"
            case .hybrid4: "about 20¢ a scan"
            case .hybrid6: "about 29¢ a scan"
            }
        }
    }

    struct Run: Codable, Identifiable {
        var id = UUID()
        let date: Date
        let mode: Mode
        let scores: [String: Int]
        let sources: [String: String]
        let youcamFailed: Bool
    }

    static let shared = ScanLab()

    private static let modeKey = "facelift.lab.mode"
    private static let runsKey = "facelift.lab.runs"

    var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }
    private(set) var runs: [Run] {
        didSet {
            if let data = try? JSONEncoder().encode(runs) {
                UserDefaults.standard.set(data, forKey: Self.runsKey)
            }
        }
    }

    private init() {
        mode = Mode(rawValue: UserDefaults.standard.string(forKey: Self.modeKey) ?? "") ?? .hybrid6
        if let data = UserDefaults.standard.data(forKey: Self.runsKey),
           let saved = try? JSONDecoder().decode([Run].self, from: data) {
            runs = saved
        } else {
            runs = []
        }
    }

    func record(_ report: SkinReport, mode: Mode) {
        let scores = report.concerns.mapValues { Int($0.ui.rounded()) }
        let run = Run(date: Date(), mode: mode, scores: scores, sources: report.sources ?? [:], youcamFailed: report.youcamError != nil)
        runs = Array(([run] + runs).prefix(60))
    }

    func clear() {
        runs = []
    }

    /// How much each marker moved across the runs of one setup (highest minus lowest).
    func spread(for mode: Mode) -> [(marker: String, low: Int, high: Int, source: String)] {
        let selected = runs.filter { $0.mode == mode }
        let markers = Set(selected.flatMap { $0.scores.keys }).sorted()
        return markers.compactMap { marker in
            let values = selected.compactMap { $0.scores[marker] }
            guard let low = values.min(), let high = values.max() else { return nil }
            let source = selected.first { $0.sources[marker] != nil }?.sources[marker] ?? "?"
            return (marker, low, high, source)
        }
    }
}
