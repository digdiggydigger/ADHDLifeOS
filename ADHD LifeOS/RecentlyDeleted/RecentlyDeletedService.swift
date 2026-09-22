//
//  RecentlyDeletedService.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the 30-day list's state, and the launch purge.
//
//  **The purge lives here rather than in its own type**, because it needs exactly what this
//  already has — the seam, the clock and the list — and a second type would mean a second place
//  that knows how to ask "is this old enough to destroy". `RecentlyDeletedPurge` is the free
//  function `RootView` calls; it builds one of these and throws it away.
//

import Combine
import Foundation

@MainActor
final class RecentlyDeletedService: ObservableObject {
    /// **One state, not a `state` plus a `content`, and a test drove that out.**
    /// The first shape here published a `.loading/.loaded/.failed` state beside a computed
    /// `content` derived from an `items` array — and on a FAILED load that array is empty, so
    /// `content` answered `.empty`. Nothing was drawing it (the view would have branched on the
    /// state first), but "nothing draws the wrong answer today" is not the same as "the wrong
    /// answer cannot be drawn", and "nothing deleted" over a failed fetch is a confident lie to
    /// someone who has just deleted something they want back. Collapsing the two makes it
    /// unrepresentable — §6's unified screen state, earning its keep.
    enum Screen: Equatable {
        case loading
        case failed(String)
        case rows([RecentlyDeletedPresentation.Row])
        case empty
    }

    @Published private(set) var screen: Screen = .loading
    @Published private(set) var items: [RecentlyDeletedItem] = []
    /// Set while a restore or a permanent delete is in flight, so a row's two buttons can refuse
    /// a second tap. Non-optimistic like every exit in this app — see `discard(capture:)`.
    @Published private(set) var busyItemID: String?
    @Published var errorMessage: String?
    /// Non-`nil` drives the survivor alert — set only when a `.tag` row whose name has been taken
    /// again is asked to restore. `TagEditorService.pendingMergeConflict` is the shape.
    @Published var pendingSurvivorChoice: RecentlyDeletedItem?

    private let client: RecentlyDeletedClientAdapting
    /// Injected so a test can stand at any point in the window, and so the purge is testable
    /// without waiting thirty days. Every read of "now" in this type goes through it.
    private let now: () -> Date

    init(client: RecentlyDeletedClientAdapting, now: @escaping () -> Date = { .now }) {
        self.client = client
        self.now = now
    }

    func load() async {
        do {
            items = try await client.fetchDeleted()
            redraw()
        } catch {
            // Never the empty state on a failure — the `ToolsRoutinesSection` rule, and here it is
            // load-bearing rather than tidy.
            screen = .failed(Self.message(for: error))
        }
    }

    /// Re-derives the screen from the items. Called after every successful read or write, and
    /// never on a failure — a failed write leaves the last good list on screen.
    private func redraw() {
        switch RecentlyDeletedPresentation.content(from: items, now: now()) {
        case .rows(let rows): screen = .rows(rows)
        case .empty: screen = .empty
        }
    }

    /// Puts an item back. Returns whether it landed, so a caller can leave its own affordance
    /// standing on a failure.
    @discardableResult
    func restore(_ item: RecentlyDeletedItem) async -> Bool {
        // **A colliding restore WRITES NOTHING and asks first** (E's Step 0: *"Ask which one
        // survives… One extra tap, no silent merge."*). Returning `false` is not a failure here —
        // it is the caller's signal that its affordance should stay standing, which is exactly
        // what a row whose alert is now open needs.
        if item.collision != nil {
            pendingSurvivorChoice = item
            return false
        }
        return await mutate(item) { try await self.client.restore(item) }
    }

    /// The user picked. **One write, whichever way they picked** — and in one direction there is
    /// no restore at all: keeping the LIVE tag absorbs this row's document and destroys it, which
    /// is still the right outcome for this list, because either way the row is resolved and gone.
    @discardableResult
    func resolveSurvivor(_ item: RecentlyDeletedItem, keepingRestored: Bool) async -> Bool {
        pendingSurvivorChoice = nil
        return await mutate(item) {
            try await self.client.restore(item, keepingRestored: keepingRestored)
        }
    }

    /// Writes nothing and leaves the row where it was: the tag is still deleted, still waiting,
    /// and still restorable once the name is free again.
    func cancelSurvivorChoice() {
        pendingSurvivorChoice = nil
    }

    /// The irreversible one, behind Q10's confirm.
    @discardableResult
    func deleteForever(_ item: RecentlyDeletedItem) async -> Bool {
        await mutate(item) { try await self.client.deleteForever(item) }
    }

    /// E's Step 0 answer 1: *"The app, when you open it"* — everything past the window, destroyed
    /// on launch.
    ///
    /// **Best-effort and silent.** A purge that could not reach the network must not put an error
    /// in front of someone who was opening the app to do something else; the items simply wait for
    /// the next launch, which is the accepted cost E's own question stated. It is also idempotent,
    /// so running it again — a sign-out and back in as another account, say — is correct rather
    /// than merely harmless.
    ///
    /// **`isPurgeable` is asked per item even though the fetch already returned only deleted
    /// ones**, because this is the one irreversible operation in the block and it does not get to
    /// assume its caller filtered correctly.
    func purge() async {
        guard let waiting = try? await client.fetchDeleted() else { return }
        let asOf = now()
        for item in waiting where SoftDelete.isPurgeable(deletedAt: item.deletedAt, asOf: asOf) {
            try? await client.deleteForever(item)
        }
    }

    private func mutate(_ item: RecentlyDeletedItem, _ write: () async throws -> Void) async -> Bool {
        errorMessage = nil
        busyItemID = item.id
        defer { busyItemID = nil }
        do {
            try await write()
            // The row leaves only once the write has landed. An optimistic removal that failed
            // would look exactly like a successful restore while the item was still waiting.
            items.removeAll { $0.id == item.id }
            redraw()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

/// What `RootView` calls once per signed-in appearance.
///
/// A free function rather than a stored service, because nothing on screen consumes its result and
/// `RootView` should not hold a whole `ObservableObject` for a fire-and-forget launch job. The
/// clock is injectable for the same reason the service's is.
enum RecentlyDeletedPurge {
    @MainActor
    static func run(
        client: RecentlyDeletedClientAdapting = FirebaseRecentlyDeletedClientAdapter(),
        now: @escaping () -> Date = { .now }
    ) async {
        await RecentlyDeletedService(client: client, now: now).purge()
    }
}
