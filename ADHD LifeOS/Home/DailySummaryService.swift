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
    /// Stands in when `generator` can't be reached. `nil` disables degrading entirely, which is
    /// what previews, tests, and a build with no endpoint configured all want.
    private let fallbackGenerator: (any DailySummaryGenerating)?
    private let store: (any DailySummaryStoring)?
    private let userId: String?
    /// Holds the generation currently running, so it outlives this card being destroyed and rebuilt
    /// (see `DailySummaryGenerationCoordinator`). Defaults to a private one for the same reason
    /// `store` defaults to nothing: previews and tests must not share process-wide state.
    private let coordinator: DailySummaryGenerationCoordinator
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
        fallbackGenerator: (any DailySummaryGenerating)? = nil,
        store: (any DailySummaryStoring)? = nil,
        userId: String? = nil,
        coordinator: DailySummaryGenerationCoordinator = DailySummaryGenerationCoordinator(),
        now: Date = .now
    ) {
        self.provider = provider
        self.generator = generator
        self.fallbackGenerator = fallbackGenerator
        self.store = store
        self.userId = userId
        self.coordinator = coordinator
        restore(asOf: now)
    }

    /// The shipping configuration: real Firestore data, the Claude-backed Cloud Function for the
    /// wording, on-device synthesis standing behind it, and defaults-backed memory so the card
    /// outlives the view.
    ///
    /// With no deployed URL the on-device synthesis is the generator outright, rather than shipping
    /// a button that always errors; there is nothing for it to stand behind, so no fallback is
    /// wired. **In the shipping build the two are therefore unambiguous:** a card that says
    /// "On-device synthesis" can only mean the function was unreachable, because the endpoint is
    /// configured. That is what keeps the degrade visible rather than silent (E's call, 2026-08-22).
    static func live() -> DailySummaryService {
        let hasEndpoint = FirebaseDailySummaryGenerator.defaultEndpoint != nil
        return DailySummaryService(
            provider: FirebaseDailySummaryDataAdapter(),
            generator: hasEndpoint ? FirebaseDailySummaryGenerator() : StubDailySummaryGenerator(),
            fallbackGenerator: hasEndpoint ? StubDailySummaryGenerator() : nil,
            store: UserDefaultsDailySummaryStore(),
            userId: FirebaseManager.shared.currentUser?.uid,
            coordinator: .shared
        )
    }

    /// Reloads what this account recorded for today, if anything.
    ///
    /// Runs in `init` rather than from the view's `.task` so a restored summary is there on the
    /// first frame — arriving one frame late would animate in as if it had just been generated.
    private func restore(asOf now: Date) {
        // A generation started before this card was rebuilt is still running; showing its spinner
        // here rather than from the view's `.task` is the same first-frame argument as above.
        // `reattachIfGenerating()` is what actually delivers its result.
        if coordinator.isGenerating(for: userId) { state = .loading }
        guard let snapshot = store?.read(), snapshot.belongs(to: userId) else { return }
        storedSummary = snapshot.summary(on: now)
        if let storedSummary, state != .loading { state = .loaded(storedSummary) }
        tone = snapshot.tone
    }

    /// Rejoins a generation that was already running when this card was built, and applies its
    /// result. Called from the view on every appearance; a no-op when nothing is in flight.
    ///
    /// Without this the rebuilt card would show a spinner and keep showing it until the user
    /// navigated away and back — the result would be in storage, but nothing on screen would go
    /// looking for it.
    func reattachIfGenerating() async {
        guard let generation = coordinator.inFlight(for: userId) else { return }
        state = .loading
        await apply(generation)
    }

    /// Words the day, degrading to the on-device synthesis when the model can't be reached.
    ///
    /// A model outage must not cost the user their day: the stand-in is honest — it only ever
    /// restates what actually happened — and the card names the source that produced it, so the
    /// downgrade is labelled rather than hidden.
    ///
    /// If the stand-in fails too, the **model's** error is what surfaces. It is the one that says
    /// what actually broke, and it is the one `describeModelError` already wrote for a reader who
    /// may be able to act on it.
    private func word(
        _ request: DailySummaryRequest
    ) async throws -> (content: DailySummaryContent, source: DailySummarySource) {
        do {
            return (try await generator.generate(request), generator.source)
        } catch {
            guard let fallbackGenerator else { throw error }
            guard let content = try? await fallbackGenerator.generate(request) else { throw error }
            return (content, fallbackGenerator.source)
        }
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

    /// Generates, or joins the generation already running for this account.
    ///
    /// The work goes through the coordinator so it outlives this card: leaving Home mid-flight and
    /// coming back rebuilds the service, and the rebuilt one rejoins rather than paying for a
    /// second model call.
    func generate(now: Date = .now) async {
        let requestedTone = tone
        state = .loading
        let generation = coordinator.generation(for: userId) { [self] in
            // A Firestore failure is NOT caught: the fallback rewords the day, it cannot invent
            // one. With nothing honest to synthesize from, an error is the only truthful answer.
            let request = try await provider.loadRequest(tone: requestedTone, date: now)
            let worded = try await word(request)
            let generated = GeneratedDailySummary(
                content: worded.content,
                tone: requestedTone,
                generatedAt: now,
                source: worded.source
            )
            // Recorded here, inside the generation, rather than after awaiting it: the coordinator
            // clears its in-flight slot as this returns, so a card rebuilt any later would find
            // neither a running generation nor a stored summary.
            remember(generated)
            return generated
        }
        await apply(generation)
    }

    /// Puts the outcome of a generation on screen — whether this service started it or joined one
    /// already running.
    private func apply(_ generation: Task<GeneratedDailySummary, Error>) async {
        do {
            let generated = try await generation.value
            storedSummary = generated
            state = .loaded(generated)
        } catch {
            state = .failed(
                (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
        }
    }

    private func remember(_ generated: GeneratedDailySummary) {
        storedSummary = generated
        persist()
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
