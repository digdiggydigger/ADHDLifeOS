//
//  JournalService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class JournalService: ObservableObject {
    enum ListState: Equatable {
        case loading
        case loaded([Log])
        case failed(String)
    }

    @Published private(set) var state: ListState = .loading
    @Published var selectedLifeAreaId: UUID? {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeFeed()
        }
    }
    @Published var composerBody = ""
    @Published var composerType: LogType = .log
    @Published var composerLifeAreaId: UUID?
    /// Journal-only, and seeded to the web composer's own starting selection so a one-tap save
    /// still records something honest. `composerType` gates whether they are sent at all
    /// (`LogValidation` drops them for a quick log), so switching back to Log never smuggles a
    /// mood reading onto a note.
    @Published var composerEnergyLevel: EnergyLevel = .medium
    @Published var composerMoodEmoji: String = JournalMood.defaultEmoji
    @Published private(set) var isCreating = false
    @Published var createErrorMessage: String?
    /// The side streams the timeline interleaves beside the logs (E's 2026-08-25 note; the
    /// fence crossings joined in block 4c). Garnish, never load-bearing: a failed fetch leaves
    /// them empty rather than failing the journal — the same non-blocking posture as the view's
    /// closed-task fetch.
    @Published private(set) var focusSessions: [CompletedFocusSession] = []
    @Published private(set) var captures: [Capture] = []
    @Published private(set) var locationEvents: [LocationEvent] = []
    /// The routine record's runs (F-RoutineRecord-1), already reconciled: a run that lapsed
    /// reads as lapsed here the moment the load decides so, not after the write lands.
    @Published private(set) var routineRuns: [RoutineRunRecord] = []
    /// For the event rows' names — a dangling id reads as no row, never a raw UUID.
    @Published private(set) var places: [Place] = []
    /// The composer's tag selection (E's 2026-08-25 note) — sent with the create, because logs
    /// are append-only and can never be tagged after the fact.
    @Published var composerTagIds: [UUID] = []
    /// The shared tag registry, for the composer chips and the timeline rows' resolution.
    /// Non-blocking like the other side streams.
    @Published private(set) var availableTags: [Tag] = []

    /// The composer's per-entry location switch (E, 2026-08-31) — the captures rule verbatim:
    /// seeded from the global Settings toggle, decisive for THIS entry only, and reset after
    /// every save so a one-off choice never quietly becomes a preference.
    @Published var composerAttachLocation = false
    /// Where the entry WILL say it was written — taken when the composer opens or the switch
    /// turns on, so the subtitle can name the place before anything is saved. Display only: the
    /// save takes its own fresh stamp.
    @Published private(set) var composerLocationPreview: LocationStamp?

    private let client: JournalClientAdapting
    /// Where an entry was written — a closure for the `CaptureInboxService` reason: the default
    /// does the real work, a test hands over a fixed stamp without CoreLocation or Firestore.
    /// The enabled-gate is `composerAttachLocation` now there is a per-entry switch, so the
    /// default is the permission-only `CaptureLocationStamp` — `RecordLocationStamp` re-reads
    /// the global toggle, which would veto an explicit per-entry opt-in.
    private let locationStamp: @MainActor () async -> LocationStamp?
    private(set) var lifeAreas: [LifeArea] = []
    private var logs: [Log] = []
    private var hasLoadedOnce = false

    /// Site 6 of the routine record: the passive endings are derived on THIS load and written
    /// through here. All four are injectable so the rule is pinned without Firestore, a live
    /// run store, or the wall clock; the defaults are the production wiring.
    private let routineRecorder: RoutineRunRecording
    private let liveRoutineRunId: () -> UUID?
    private let now: () -> Date
    private let calendar: Calendar
    /// The in-flight reconciliation writes, held so a test can await them.
    private(set) var reconcileTask: Task<Void, Never>?

    init(
        client: JournalClientAdapting,
        locationStamp: (@MainActor () async -> LocationStamp?)? = nil,
        routineRecorder: RoutineRunRecording? = nil,
        liveRoutineRunId: (() -> UUID?)? = nil,
        now: @escaping () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.routineRecorder = routineRecorder ?? FirebaseRoutineRunRecorder()
        self.liveRoutineRunId = liveRoutineRunId
            ?? { UserDefaultsRoutineRunStore().readLiveRun(now: .now)?.id }
        self.now = now
        self.calendar = calendar
        self.client = client
        self.locationStamp = locationStamp ?? { await CaptureLocationStamp.current() }
    }

    /// Back to the global default — `CaptureInboxService.resetLocationChoice`'s twin, and called
    /// at the same two moments: on load, and after every successful save.
    func resetComposerLocationChoice() {
        composerAttachLocation = CaptureLocationChoice.defaultValue(
            globalEnabled: AppFeedback.locationTaggingEnabled(),
            authorization: CoreLocationFixProvider.shared.authorizationState
        )
    }

    /// Refreshes what the composer's subtitle can promise. Off clears the preview rather than
    /// keeping a stale one — "at The Office" under a switch saying "won't record" is a lie.
    func refreshComposerLocationPreview() async {
        guard composerAttachLocation else {
            composerLocationPreview = nil
            return
        }
        composerLocationPreview = await locationStamp()
    }

    var isComposerBodyValid: Bool {
        if case .success = LogValidation.normalizeCreateLogInput(
            body: composerBody, type: composerType, lifeAreaId: composerLifeAreaId,
            energyLevel: composerEnergyLevel, moodEmoji: composerMoodEmoji
        ) {
            return true
        }
        return false
    }

    func load() async {
        // Quiet reload (SUGG-b4): only the FIRST load may show the loading state — once content
        // is on screen, a refetch (pull, or the app-wide DataChangeSignal) replaces it in place
        // instead of flashing it away.
        if case .loaded = state {} else { state = .loading }
        do {
            async let lifeAreasResult = client.fetchLifeAreas()
            async let logsResult = client.fetchLogs()
            async let sprintsResult = client.fetchFocusSessions()
            async let capturesResult = client.fetchCaptures()
            async let eventsResult = client.fetchLocationEvents()
            async let runsResult = client.fetchRoutineRuns()
            async let placesResult = client.fetchPlaces()
            async let tagsResult = client.fetchAllTags()
            lifeAreas = try await lifeAreasResult
            logs = try await logsResult
            focusSessions = (try? await sprintsResult) ?? []
            captures = (try? await capturesResult) ?? []
            locationEvents = (try? await eventsResult) ?? []
            reconcileRoutineRuns((try? await runsResult) ?? [])
            places = (try? await placesResult) ?? []
            availableTags = (try? await tagsResult) ?? []
            hasLoadedOnce = true
            recomputeFeed()
            resetComposerLocationChoice()
        } catch {
            hasLoadedOnce = false
            state = .failed(Self.message(for: error))
        }
    }

    /// Derives which runs lapsed since anyone last looked, shows them lapsed NOW, and writes
    /// each ending once. The live run is the store's to end, never this method's.
    private func reconcileRoutineRuns(_ fetched: [RoutineRunRecord]) {
        let updates = RoutineRunReconciliation.updates(
            records: fetched, liveRunId: liveRoutineRunId(), now: now(), calendar: calendar
        )
        routineRuns = RoutineRunReconciliation.applying(updates, to: fetched)
        guard !updates.isEmpty else { return }
        let recorder = routineRecorder
        reconcileTask = Task {
            for update in updates {
                switch update {
                case .expired(let runId, let at):
                    try? await recorder.expired(runId: runId, at: at)
                case .ended(let runId, let reason, let at):
                    try? await recorder.ended(runId: runId, reason: reason, at: at)
                }
            }
        }
    }

    @discardableResult
    func createLog() async -> Bool {
        createErrorMessage = nil

        let normalized: NormalizedCreateLogInput
        switch LogValidation.normalizeCreateLogInput(
            body: composerBody, type: composerType, lifeAreaId: composerLifeAreaId,
            energyLevel: composerEnergyLevel, moodEmoji: composerMoodEmoji,
            tagIds: composerTagIds
        ) {
        case .failure(let error):
            createErrorMessage = error.errorDescription
            return false
        case .success(let value):
            normalized = value
        }

        isCreating = true
        defer { isCreating = false }

        // Stamped here, after validation and before the write — the capture rule verbatim: a fix
        // that never arrives must never be why an entry doesn't get written down, so this only
        // ever ADDS fields and has no failure path back to the caller. The switch is the gate,
        // and off means off: no stamp, and no fix requested either.
        var stamped = normalized
        stamped.locationStamp = composerAttachLocation ? await locationStamp() : nil

        do {
            let created = try await client.createLog(stamped)
            logs.append(created)
            recomputeFeed()
            composerBody = ""
            composerType = .log
            composerLifeAreaId = nil
            composerEnergyLevel = .medium
            composerMoodEmoji = JournalMood.defaultEmoji
            composerTagIds = []
            composerLocationPreview = nil
            resetComposerLocationChoice()
            return true
        } catch {
            createErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Creates a tag from the composer (server dedups by name), selects it for the entry being
    /// written, and adds it to the visible list — the same gesture the capture composer has.
    @discardableResult
    func createTagForComposer(name: String) async -> Tag? {
        createErrorMessage = nil
        do {
            let tag = try await client.createTag(name: name)
            if !composerTagIds.contains(tag.id) {
                composerTagIds.append(tag.id)
            }
            if !availableTags.contains(tag) {
                availableTags.append(tag)
            }
            return tag
        } catch {
            createErrorMessage = Self.message(for: error)
            return nil
        }
    }

    private func recomputeFeed() {
        let filtered = LogSorting.filterByLifeArea(logs, lifeAreaId: selectedLifeAreaId)
        state = .loaded(LogSorting.sortByEntryDateDescending(filtered))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
