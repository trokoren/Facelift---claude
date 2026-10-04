import Foundation

/// Her results, written like a five-minute consult: skin type, what's working, what we're
/// seeing, what to keep an eye on, and her plan. Words come from Claude; every score shown
/// alongside them is a YouCam measurement.
struct Consult: Codable, Hashable {
    struct SkinType: Codable, Hashable {
        let label: String
        let explanation: String
        /// Set on this phone after the scan. "confirmed" or "changed" when this scan re-measured
        /// it and she had an earlier reading; nil on her first reading and on scans in between.
        var status: String?
        /// Her base type before a change ("oily"), for "Changed from oily".
        var previous: String?
        /// When her skin type was last measured, as of this scan.
        var measuredOn: Date?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? ""
            explanation = (try? c.decodeIfPresent(String.self, forKey: .explanation)) ?? ""
            status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
            previous = (try? c.decodeIfPresent(String.self, forKey: .previous)) ?? nil
            measuredOn = (try? c.decodeIfPresent(Date.self, forKey: .measuredOn)) ?? nil
        }

        /// The base type in a label like "Combination, leaning oily".
        static func base(_ label: String) -> String? {
            let lower = label.lowercased()
            return ["combination", "sensitive", "normal", "oily", "dry"]
                .map { ($0, lower.range(of: $0)?.lowerBound) }
                .compactMap { name, at in at.map { (name, $0) } }
                .min { $0.1 < $1.1 }?.0
        }
    }

    struct Strength: Codable, Hashable, Identifiable {
        let title: String
        let detail: String
        var id: String { title }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
            detail = (try? c.decodeIfPresent(String.self, forKey: .detail)) ?? ""
        }
    }

    struct Concern: Codable, Hashable, Identifiable {
        /// The measurement this concern is about (wrinkle, texture, ...).
        let key: String
        let title: String
        /// mild, moderate or notable
        let severity: String
        let summary: String
        let seen: String
        /// The deeper read. Written in the background after results appear; empty until then.
        var why: String
        var todo: String
        var expect: String
        var id: String { key }

        var hasDeepRead: Bool { !why.isEmpty || !todo.isEmpty || !expect.isEmpty }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            func text(_ key: CodingKeys) -> String { (try? c.decodeIfPresent(String.self, forKey: key)) ?? "" }
            key = text(.key)
            title = text(.title)
            severity = text(.severity)
            summary = text(.summary)
            seen = text(.seen)
            why = text(.why)
            todo = text(.todo)
            expect = text(.expect)
        }

        var severityLabel: String {
            switch severity {
            case "mild": "Mild"
            case "moderate": "Moderate"
            default: "Worth addressing"
            }
        }
    }

    struct Note: Codable, Hashable {
        let title: String
        let detail: String

        init(title: String, detail: String) {
            self.title = title
            self.detail = detail
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
            detail = (try? c.decodeIfPresent(String.self, forKey: .detail)) ?? ""
        }
    }

    struct Plan: Codable, Hashable {
        let focus: String
        let morning: [String]
        let evening: [String]

        init(focus: String = "", morning: [String] = [], evening: [String] = []) {
            self.focus = focus
            self.morning = morning
            self.evening = evening
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            focus = (try? c.decodeIfPresent(String.self, forKey: .focus)) ?? ""
            morning = (try? c.decodeIfPresent([String].self, forKey: .morning)) ?? []
            evening = (try? c.decodeIfPresent([String].self, forKey: .evening)) ?? []
        }
    }

    let intro: String
    var skinType: SkinType
    let strengths: [Strength]
    var concerns: [Concern]
    let watch: Note?
    let plan: Plan

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        intro = (try? c.decodeIfPresent(String.self, forKey: .intro)) ?? ""
        skinType = try c.decode(SkinType.self, forKey: .skinType)
        strengths = ((try? c.decodeIfPresent([Strength].self, forKey: .strengths)) ?? []).filter { !$0.title.isEmpty }
        concerns = ((try? c.decodeIfPresent([Concern].self, forKey: .concerns)) ?? []).filter { !$0.title.isEmpty }
        // Usually {title, detail}; sometimes written as one plain sentence.
        var note = (try? c.decodeIfPresent(Note.self, forKey: .watch)) ?? nil
        if note == nil, let text = (try? c.decodeIfPresent(String.self, forKey: .watch)) ?? nil {
            note = Note(title: "", detail: text)
        }
        watch = (note?.title.isEmpty == false || note?.detail.isEmpty == false) ? note : nil
        plan = (try? c.decodeIfPresent(Plan.self, forKey: .plan)) ?? Plan()
    }
}

/// Plain names for the measurements YouCam takes.
enum Measure {
    static let order = ["wrinkle", "dark_circle", "age_spot", "redness", "texture", "pore", "moisture"]

    static func name(_ key: String) -> String {
        switch key {
        case "wrinkle": "Fine lines & wrinkles"
        case "dark_circle": "Dark circles"
        case "age_spot": "Dark spots"
        case "redness": "Redness"
        case "texture": "Texture"
        case "pore": "Pores"
        case "moisture": "Hydration"
        default: key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
