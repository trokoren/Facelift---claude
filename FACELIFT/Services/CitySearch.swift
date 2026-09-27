import MapKit
import Observation

/// Live city autocomplete backed by Apple Maps, so any city works (not just a fixed list).
@Observable
final class CitySearch: NSObject, MKLocalSearchCompleterDelegate {
    struct Suggestion: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let subtitle: String
        let completion: MKLocalSearchCompletion

        /// "Denver, CO, United States"
        var fullName: String { subtitle.isEmpty ? title : "\(title), \(subtitle)" }
    }

    private(set) var results: [Suggestion] = []

    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.addressFilter = MKAddressFilter(including: [.locality])
    }

    func update(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            completer.cancel()
            results = []
            return
        }
        completer.queryFragment = trimmed
    }

    /// Latitude/longitude for a picked suggestion.
    func coordinate(for suggestion: Suggestion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        request.resultTypes = .address
        guard let response = try? await MKLocalSearch(request: request).start(),
              let item = response.mapItems.first else { return nil }
        return item.placemark.coordinate
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            self.results = completer.results.prefix(6).map {
                Suggestion(title: $0.title, subtitle: $0.subtitle, completion: $0)
            }
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        MainActor.assumeIsolated {
            self.results = []
        }
    }
}
