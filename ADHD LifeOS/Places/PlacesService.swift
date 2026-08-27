//
//  PlacesService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// Owns the places list and every mutation over it.
///
/// Follows the two house contracts that fail invisibly when broken:
/// - **Serialised mutations** (`isMutating`): a second write cannot begin while one is in flight,
///   closing the superseded-response race fixed for Life Areas in `8e19a08`.
/// - **Quiet reload**: `load()` never flips back to `.loading` over already-loaded content, so a
///   `DataChangeSignal` refetch doesn't blank the list under E mid-read.
@MainActor
final class PlacesService: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var places: [Place] = []
    @Published private(set) var isMutating = false
    /// A human-readable failure, never a raw decoding error.
    @Published var errorMessage: String?

    private let client: PlacesClientAdapting

    init(client: PlacesClientAdapting) {
        self.client = client
    }

    func load() async {
        // Quiet reload: only announce loading when there is nothing on screen yet.
        if places.isEmpty, state != .loaded {
            state = .loading
        }
        do {
            places = Self.sorted(try await client.fetchPlaces())
            state = .loaded
        } catch {
            // A failed refetch over content that is already on screen keeps the content; only a
            // cold failure takes the whole screen.
            if places.isEmpty {
                state = .failed(Self.message(for: error))
            } else {
                errorMessage = Self.message(for: error)
            }
        }
    }

    /// Create or update. Returns `true` when the caller should dismiss the editor.
    @discardableResult
    func save(_ place: Place) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        errorMessage = nil
        do {
            try await client.savePlace(place)
            await reload()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// Returns `true` when the delete landed.
    @discardableResult
    func delete(_ place: Place) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        errorMessage = nil
        do {
            try await client.deletePlace(id: place.id)
            await reload()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private func reload() async {
        do {
            places = Self.sorted(try await client.fetchPlaces())
            state = .loaded
        } catch {
            // The mutation itself landed; a reload failure is soft — surface it but keep the
            // screen usable rather than flipping the list into a failed state.
            errorMessage = Self.message(for: error)
        }
    }

    /// Alphabetical, case-insensitive: this list is read and picked from, so alphabetical is the
    /// useful order. Pure and static so it is directly testable.
    static func sorted(_ places: [Place]) -> [Place] {
        places.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
