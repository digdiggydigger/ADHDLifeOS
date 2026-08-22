//
//  DailySummaryService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// Assembles today's raw material. Split from the generator so "what happened today" and "how it
/// is worded" fail independently — a Firestore hiccup and a model outage are different problems
/// and deserve different messages.
protocol DailySummaryDataProviding: Sendable {
    func loadRequest(tone: DailySummaryTone, date: Date) async throws -> DailySummaryRequest
}

/// Screen state for the Daily Executive Summary card.
///
/// Generation is explicit — the card never fires on appear. A summary costs a model round trip and
/// is only meaningful once the day has something in it, so the user asks for it.
@MainActor
final class DailySummaryService: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(GeneratedDailySummary)
        case failed(String)
    }

    @Published private(set) var state: ViewState = .idle
    /// Selected voice. Changing it deliberately does **not** clear an existing summary — that
    /// summary is still a true record of the day; only regenerating replaces it.
    @Published var tone: DailySummaryTone = .energizing {
        didSet { persist() }
    }

    private let provider: any DailySummaryDataProviding
    private let generator: any DailySummaryGenerating
    private let store: (any DailySummaryStoring)?
    private let userId: String?
    /// The last summary that generated successfully — what gets written back, tracked separately
    /// from `state` on purpose. A failed regeneration puts the card into `.failed`, but the summary
    /// already recorded for today is still true and must survive it.
    private var storedSummary: GeneratedDailySummary?

    /// `store` is optional and defaults to nothing, so previews and tests remember nothing and never
    /// touch real defaults; only `live()` wires up persistence. `now` is the moment the restore is
    /// judged against — a stored summary is only reloaded if it belongs to that day.
    init(
        provider: any DailySummaryDataProviding,
        generator: any DailySummaryGenerating,
        store: (any DailySummaryStoring)? = nil,
        userId: String? = nil,
        now: Date = .now
    ) {
        self.provider = provider
        self.generator = generator
        self.store = store
        self.userId = userId
        restore(asOf: now)
    }

    /// The shipping configuration: real Firestore data, the Claude-backed Cloud Function for the
    /// wording **once it has a deployed URL**, and defaults-backed memory so the card outlives the
    /// view.
    ///
    /// Falls back to on-device synthesis while `defaultEndpoint` is `nil` rather than shipping a
    /// button that always errors. The card names which one produced a summary, so the fallback is
    /// visible rather than a silent downgrade.
    static func live() -> DailySummaryService {
        let generator: any DailySummaryGenerating = FirebaseDailySummaryGenerator.defaultEndpoint == nil
            ? StubDailySummaryGenerator()
            : FirebaseDailySummaryGenerator()
        return DailySummaryService(
            provider: FirebaseDailySummaryDataAdapter(),
            generator: generator,
            store: UserDefaultsDailySummaryStore(),
            userId: FirebaseManager.shared.currentUser?.uid
        )
    }

    /// Reloads what this account recorded for today, if anything.
    ///
    /// Runs in `init` rather than from the view's `.task` so a restored summary is there on the
    /// first frame — arriving one frame late would animate in as if it had just been generated.
    private func restore(asOf now: Date) {
        guard let snapshot = store?.read(), snapshot.belongs(to: userId) else { return }
        storedSummary = snapshot.summary(on: now)
        if let storedSummary { state = .loaded(storedSummary) }
        tone = snapshot.tone
    }

    private func persist() {
        store?.write(DailySummarySnapshot(userId: userId, tone: tone, summary: storedSummary))
    }

    /// The clipboard payload, or `nil` when there is nothing to copy.
    var copyText: String? {
        guard case .loaded(let generated) = state else { return nil }
        return DailySummaryCopyFormatter.text(for: generated.content, on: generated.generatedAt)
    }

    var isGenerating: Bool { state == .loading }

    /// Whether a summary already exists, so the button can say "Regenerate" rather than lie.
    var hasSummary: Bool {
        if case .loaded = state { return true }
        return false
    }

    func generate(now: Date = .now) async {
        let requestedTone = tone
        state = .loading
        do {
            let request = try await provider.loadRequest(tone: requestedTone, date: now)
            let content = try await generator.generate(request)
            let generated = GeneratedDailySummary(
                content: content,
                tone: requestedTone,
                generatedAt: now,
                source: generator.source
            )
            state = .loaded(generated)
            storedSummary = generated
            persist()
        } catch {
            state = .failed(
                (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
        }
    }
}

/// Reads today out of Firestore and hands back a ready request.
///
/// Five reads, run concurrently — they are independent, and doing them in sequence would make the
/// button feel broken on a slow connection.
struct FirebaseDailySummaryDataAdapter: DailySummaryDataProviding {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func loadRequest(tone: DailySummaryTone, date: Date) async throws -> DailySummaryRequest {
        async let tasks = manager.fetchTasks()
        async let logs = manager.fetchLogs()
        async let sessions = manager.fetchFocusSessions()
        async let captures = manager.fetchCaptures()
        async let lifeAreas = manager.fetchLifeAreas()

        let (loadedTasks, loadedLogs, loadedSessions, loadedCaptures, loadedAreas) =
            try await (tasks, logs, sessions, captures, lifeAreas)

        // Only untriaged captures count as "offloaded today" — a promoted one has already become
        // a task and would otherwise be counted twice.
        let openCaptures = loadedCaptures.filter { !$0.processed }.count

        return DailySummaryRequest(
            date: date,
            tone: tone,
            tasks: loadedTasks,
            focusSessions: loadedSessions,
            journalEntries: loadedLogs,
            capturesCount: openCaptures,
            lifeAreaNames: Dictionary(
                loadedAreas.map { ($0.id, $0.name) },
                uniquingKeysWith: { first, _ in first }
            )
        )
    }
}
