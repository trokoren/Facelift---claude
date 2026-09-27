import MapKit
import Observation

/// Live city autocomplete backed by Apple Maps, so any city works (not just a fixed list).
@Observable
final class CitySearch: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var results: [String] = []

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

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            let names = completer.results.map { result in
                result.subtitle.isEmpty ? result.title : "\(result.title), \(result.subtitle)"
            }
            self.results = Array(names.prefix(6))
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        MainActor.assumeIsolated {
            self.results = []
        }
    }
}
