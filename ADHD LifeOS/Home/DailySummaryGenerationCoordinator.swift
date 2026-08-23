//
//  DailySummaryGenerationCoordinator.swift
//  ADHD LifeOS
//

import Foundation

/// Owns the summary generation that is currently running, so it outlives the card that started it.
///
/// **Why this exists.** Home's `.task` re-runs `HomeService.load()` on every appearance, flipping
/// its load state back through `.loading` and destroying the summary card's whole subtree — the
/// same fact `DailySummaryStore` documents. The generated summary already survives that, because it
/// is a record of the day and lives in storage. The *generation in progress* did not: leaving Home
/// mid-flight and coming back rebuilt the service, which showed "Generate" again with no spinner,
/// and tapping it cost a second model call.
///
/// **Why not a persisted "in flight since" marker.** Two reasons. It cannot deliver the *result* —
/// a rebuilt card would show a spinner and then keep spinning until the user navigated again, which
/// is worse than the bug it replaces. And it would have to guess a staleness timeout to recover
/// from a mid-generation kill, since nothing clears the marker when the process dies. Holding the
/// `Task` needs neither guess: a killed app has no in-flight generation, and an empty coordinator
/// says exactly that.
///
/// **This is not the hoisting E ruled out.** That decision was about where the *summary* lives, and
/// it stands — the summary is still persisted, which is also what fixes cold launch. This is a
/// service-layer object with no place in the view tree, so `HomeView`'s `type_body_length` is
/// untouched.
///
/// Scoped by account for the same reason `DailySummarySnapshot.belongs(to:)` is: a summary quotes
/// task titles and journal reflections, so it is only ever handed to the account that asked for it.
/// `nil` (signed out) is its own scope, not a wildcard.
@MainActor
final class DailySummaryGenerationCoordinator {
    /// The process-lifetime instance the shipping card uses. Everything else — previews, tests —
    /// gets its own, the same way `DailySummaryService`'s store defaults to nothing.
    static let shared = DailySummaryGenerationCoordinator()

    private var inFlight: (userId: String?, task: Task<GeneratedDailySummary, Error>)?

    /// `nonisolated` so it can stand as a default argument on `DailySummaryService.init`, which is
    /// evaluated at the (possibly non-main) call site. Safe: it stores nothing but an empty slot.
    nonisolated init() {}

    func isGenerating(for userId: String?) -> Bool {
        inFlight(for: userId) != nil
    }

    /// The generation already running for `userId`, if any. Never starts one — this is how a
    /// rebuilt card reattaches to work it did not begin.
    func inFlight(for userId: String?) -> Task<GeneratedDailySummary, Error>? {
        guard let inFlight, inFlight.userId == userId else { return nil }
        return inFlight.task
    }

    /// Starts generating for `userId`, or hands back the generation already running for them.
    ///
    /// Joining rather than starting a second call is the whole cost argument: two cards asking at
    /// once — or one card rebuilt mid-flight — pay for one model round trip, not two.
    ///
    /// `work` is responsible for recording the result before it returns. The in-flight slot is
    /// cleared as this task ends, so anything written afterwards could be missed by a card rebuilt
    /// in the gap: it would see neither a running generation nor a stored summary.
    func generation(
        for userId: String?,
        startingWith work: @escaping @MainActor () async throws -> GeneratedDailySummary
    ) -> Task<GeneratedDailySummary, Error> {
        if let existing = inFlight(for: userId) { return existing }
        let task = Task { [weak self] in
            defer { self?.finish(userId: userId) }
            return try await work()
        }
        inFlight = (userId: userId, task: task)
        return task
    }

    /// Clears the slot only if it is still this generation's. A newer one — another account signing
    /// in mid-flight — has already replaced it and must not be cancelled out by its predecessor.
    private func finish(userId: String?) {
        guard let current = inFlight, current.userId == userId else { return }
        inFlight = nil
    }
}
