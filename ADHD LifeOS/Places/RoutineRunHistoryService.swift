//
//  RoutineRunHistoryService.swift
//  ADHD LifeOS
//
//  Reading the routine record back (F-RoutineRecord-2-Surfaces). Two screens read it — the
//  Journal's day stream and the Tools Routines section — and both loads must reconcile the
//  passive endings the same way, so the reconciler is ONE type shared by both rather than a
//  rule spelled twice.
//

import Combine
import Foundation

/// The read seam — narrow, like every adapter here.
protocol RoutineRunHistoryReading: Sendable {
    func fetchRoutineRuns() async throws -> [RoutineRunRecord]
}

struct FirebaseRoutineRunHistoryAdapter: RoutineRunHistoryReading {
    private let store: RoutineRunsBackingStore

    init(store: RoutineRunsBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchRoutineRuns() async throws -> [RoutineRunRecord] {
        try await store.fetchRoutineRuns()
    }
}

/// Site 6 of the routine record, as one object: derives which fetched runs lapsed since
/// anyone last looked, returns them lapsed NOW so the screen is right immediately, and writes
/// each ending once on a Task nothing waits for — held, so a test can. The live run is the
/// local store's to end, never this object's.
@MainActor
final class RoutineRunReconciler {
    private let recorder: RoutineRunRecording
    private let liveRunId: () -> UUID?
    private let now: () -> Date
    private let calendar: Calendar
    private(set) var writeTask: Task<Void, Never>?

    init(
        recorder: RoutineRunRecording? = nil,
        liveRunId: (() -> UUID?)? = nil,
        now: @escaping () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.recorder = recorder ?? FirebaseRoutineRunRecorder()
        self.liveRunId = liveRunId ?? { UserDefaultsRoutineRunStore().readLiveRun(now: .now)?.id }
        self.now = now
        self.calendar = calendar
    }

    func reconcile(_ fetched: [RoutineRunRecord]) -> [RoutineRunRecord] {
        let updates = RoutineRunReconciliation.updates(
            records: fetched, liveRunId: liveRunId(), now: now(), calendar: calendar
        )
        guard !updates.isEmpty else { return fetched }
        let recorder = self.recorder
        writeTask = Task {
            for update in updates {
                switch update {
                case .expired(let runId, let lapsedAt):
                    try? await recorder.expired(runId: runId, at: lapsedAt)
                case .ended(let runId, let reason, let lapsedAt):
                    try? await recorder.ended(runId: runId, reason: reason, at: lapsedAt)
                }
            }
        }
        return RoutineRunReconciliation.applying(updates, to: fetched)
    }
}

/// The Tools section's read: fetch, reconcile, publish. Garnish like every side stream — a
/// failed fetch is an empty list, never an error the section has to show.
@MainActor
final class RoutineRunHistoryService: ObservableObject {
    @Published private(set) var runs: [RoutineRunRecord] = []

    private let reader: RoutineRunHistoryReading
    private let reconciler: RoutineRunReconciler

    init(reader: RoutineRunHistoryReading, reconciler: RoutineRunReconciler) {
        self.reader = reader
        self.reconciler = reconciler
    }

    /// The production wiring. A function, not a default argument: building the Firebase
    /// adapter touches `FirebaseManager.shared`, which a preview must never do.
    static func live() -> RoutineRunHistoryService {
        RoutineRunHistoryService(reader: FirebaseRoutineRunHistoryAdapter(), reconciler: RoutineRunReconciler())
    }

    /// Previews: reads nothing, writes nothing.
    static func inert() -> RoutineRunHistoryService {
        RoutineRunHistoryService(
            reader: InertRoutineRunHistoryReader(),
            reconciler: RoutineRunReconciler(recorder: InertRoutineRunRecorder(), liveRunId: { nil })
        )
    }

    func load() async {
        let fetched = (try? await reader.fetchRoutineRuns()) ?? []
        runs = reconciler.reconcile(fetched)
    }
}

struct InertRoutineRunHistoryReader: RoutineRunHistoryReading {
    func fetchRoutineRuns() async throws -> [RoutineRunRecord] { [] }
}
