//
//  PlaceAddressSearchService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// One address completion, free of MapKit so the state machine below tests without a network.
/// `id` is the handle the MapKit-backed provider uses to find the original completion object
/// again when resolving — keeping the model pure without giving up resolution accuracy.
struct AddressSuggestion: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String

    /// MapKit hands back title and subtitle separately; a suggestion with no subtitle must not
    /// render a dangling comma.
    var displayLine: String {
        let trimmed = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? title : "\(title), \(trimmed)"
    }
}

/// Live autocomplete. Delegate-shaped because that is what `MKLocalSearchCompleter` is.
protocol AddressCompleting: AnyObject {
    var onResults: (([AddressSuggestion]) -> Void)? { get set }
    var onFailure: ((Error) -> Void)? { get set }
    func updateQuery(_ query: String)
    func cancel()
}

/// Turning a chosen completion into an actual coordinate.
protocol AddressResolving {
    func resolve(_ suggestion: AddressSuggestion) async throws -> PlaceCoordinate
}

/// Type an address, pick one, get a coordinate.
///
/// The behaviours here are the ones MapKit does NOT define and a user would notice: not searching
/// on one or two characters, treating "no matches" as information rather than a blank screen, and
/// discarding a late delivery for a query that has already been replaced — the completer fires
/// repeatedly as it refines, so a stale result would otherwise repopulate the list under E.
@MainActor
final class PlaceAddressSearchService: ObservableObject {
    enum State: Equatable {
        case idle
        case searching
        case results
        case noMatches
        case failed(String)
    }

    /// One or two characters match half the country. Searching there burns requests and shows noise.
    static let minimumQueryLength = 3

    @Published private(set) var state: State = .idle
    @Published private(set) var suggestions: [AddressSuggestion] = []

    private let completer: AddressCompleting
    private let resolver: AddressResolving
    /// What we are currently searching for; a delivery that doesn't match it is stale.
    private var activeQuery: String?

    init(completer: AddressCompleting, resolver: AddressResolving) {
        self.completer = completer
        self.resolver = resolver
        self.completer.onResults = { [weak self] results in
            self?.receive(results)
        }
        self.completer.onFailure = { [weak self] error in
            self?.receive(error)
        }
    }

    func updateQuery(_ raw: String) {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= Self.minimumQueryLength else {
            // Covers both "too short" and "cleared": cancel, drop results, go quiet.
            activeQuery = nil
            completer.cancel()
            suggestions = []
            state = .idle
            return
        }
        activeQuery = query
        state = .searching
        completer.updateQuery(query)
    }

    /// Returns the coordinate, or `nil` when it could not be resolved (the message is on `state`).
    func resolve(_ suggestion: AddressSuggestion) async -> PlaceCoordinate? {
        do {
            let coordinate = try await resolver.resolve(suggestion)
            // Collapse the list: suggestions left on screen beside a dropped pin invite tapping a
            // second one by accident.
            activeQuery = nil
            suggestions = []
            state = .idle
            return coordinate
        } catch {
            state = .failed(Self.message(for: error))
            return nil
        }
    }

    // MARK: - Delegate intake

    private func receive(_ results: [AddressSuggestion]) {
        // A delivery for a query E has already replaced (or cleared) is stale — drop it.
        guard activeQuery != nil else { return }
        suggestions = results
        state = results.isEmpty ? .noMatches : .results
    }

    private func receive(_ error: Error) {
        guard activeQuery != nil else { return }
        suggestions = []
        state = .failed(Self.message(for: error))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
