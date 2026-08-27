//
//  MapKitAddressProvider.swift
//  ADHD LifeOS
//

import MapKit

/// The real address autocomplete and resolution, over MapKit.
///
/// One type satisfies both seams on purpose: `MKLocalSearchCompleter` hands back
/// `MKLocalSearchCompletion` objects that `MKLocalSearch` can resolve far more accurately than a
/// re-typed string query, but those objects cannot live in the pure `AddressSuggestion` model. So
/// the completions are kept here, keyed by the id the model carries, and the resolver looks the
/// original back up. Pure model, accurate resolution, no compromise on either.
@MainActor
final class MapKitAddressProvider: NSObject, AddressCompleting, AddressResolving {
    /// Shared because `MKLocalSearchCompleter` is a network-backed object worth reusing across
    /// editor presentations, and the editor's `@StateObject` service is what owns the callbacks.
    static let shared = MapKitAddressProvider()

    var onResults: (([AddressSuggestion]) -> Void)?
    var onFailure: ((Error) -> Void)?

    private let completer = MKLocalSearchCompleter()
    /// id → the completion it came from, for accurate resolution.
    private var completions: [UUID: MKLocalSearchCompletion] = [:]

    override init() {
        super.init()
        completer.delegate = self
        // Addresses and points of interest both — "the gym" is as likely a query as a street.
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    func cancel() {
        completer.cancel()
        completer.queryFragment = ""
        completions.removeAll()
    }

    func resolve(_ suggestion: AddressSuggestion) async throws -> PlaceCoordinate {
        let request: MKLocalSearch.Request
        if let completion = completions[suggestion.id] {
            request = MKLocalSearch.Request(completion: completion)
        } else {
            // Fallback for a suggestion whose completion we no longer hold (a cancel raced the
            // tap): a natural-language search on what was shown is less precise but still lands.
            request = MKLocalSearch.Request()
            request.naturalLanguageQuery = suggestion.displayLine
        }

        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw AddressResolutionError.notFound
        }
        let coordinate = item.placemark.coordinate
        return PlaceCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

extension MapKitAddressProvider: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            var suggestions: [AddressSuggestion] = []
            suggestions.reserveCapacity(results.count)
            // Rebuilt each delivery: ids are per-delivery handles, not stable identities, and
            // holding stale completions would resolve a tap to the wrong place.
            completions.removeAll()
            for result in results {
                let id = UUID()
                completions[id] = result
                suggestions.append(
                    AddressSuggestion(id: id, title: result.title, subtitle: result.subtitle)
                )
            }
            onResults?(suggestions)
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            onFailure?(error)
        }
    }
}

enum AddressResolutionError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Couldn't find that address."
        }
    }
}
