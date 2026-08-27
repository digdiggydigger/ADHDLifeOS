//
//  CapturesTabView.swift
//  ADHD LifeOS
//
//  The Captures tab (2026-08-23): the archive of handled captures. Two slices — Seen (archived
//  from the Inbox as "noted, nothing to do") and Promoted (already a task or journal entry) —
//  behind the segmented picker the Inbox used to carry. Everything here is still actionable:
//  rows push the same `CaptureDetailView`, so a seen capture can still become a task, be
//  re-filed, or go back to the Inbox.
//

import SwiftUI

struct CapturesTabView: View {
    @StateObject private var service: CaptureInboxService
    /// Life areas feed the detail's Filed-in card. This tab has no Home parent to hand them down
    /// the way the Inbox does, so it fetches its own through the client that owns them.
    private let homeClient: HomeClientAdapting
    /// Kept for the pushed Capture Inbox, which builds its own service over the same clients.
    private let client: CaptureClientAdapting
    private let journalClient: JournalClientAdapting?
    @State private var lifeAreas: [LifeArea] = []
    @State private var inspectingCapture: Capture?
    /// The inbox entry point E asked for on this tab (2026-08-24) — captures live here, so the
    /// place they arrive should be one tap away, same reachability Home's toolbar gives it.
    @State private var isPresentingInbox = false

    init(
        client: CaptureClientAdapting,
        journalClient: JournalClientAdapting? = nil,
        homeClient: HomeClientAdapting
    ) {
        _service = StateObject(
            wrappedValue: CaptureInboxService(
                client: client, journalClient: journalClient, availableFilters: [.seen, .promoted]
            )
        )
        self.homeClient = homeClient
        self.client = client
        self.journalClient = journalClient
    }

    var body: some View {
        VStack(spacing: 0) {
            purposeHeader
            filterPicker
            Group {
                switch service.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("capturesTabLoadingIndicator")
                case .failed(let message):
                    failedState(message)
                case .loaded(let captures):
                    if captures.isEmpty {
                        emptyState
                    } else {
                        loadedState(captures)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        // Same arrangement as the Inbox: the purpose header IS the title.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isPresentingInbox) {
            CaptureInboxView(client: client, journalClient: journalClient, lifeAreas: lifeAreas)
        }
        .navigationDestination(isPresented: Binding(
            get: { inspectingCapture != nil },
            set: { if !$0 { inspectingCapture = nil } }
        )) {
            if let capture = inspectingCapture {
                CaptureDetailView(captureId: capture.id, lifeAreas: lifeAreas, service: service)
            }
        }
        .task {
            await service.load()
            lifeAreas = (try? await homeClient.fetchLifeAreas()) ?? []
        }
    }

    private var purposeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nothing is lost")
                .sectionLabel()
                .foregroundStyle(Color.accentColor)
            HStack(alignment: .center, spacing: 8) {
                Text("Captures")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Spacer()
                Button {
                    isPresentingInbox = true
                } label: {
                    Image(systemName: "tray")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Capture Inbox")
                .accessibilityIdentifier("capturesTabInboxButton")
                CaptureRefinementMenu(service: service)
            }
            Text("Everything you've seen or promoted — kept, still actionable, out of your inbox.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("capturesTabPurposeHeader")
    }

    /// The Seen / Promoted picker — the Inbox's old two-tab picker, moved here with its
    /// count-carrying labels. A tab whose count is not yet known renders its bare title rather
    /// than "(0)" — never having looked is not the same as nothing being there.
    private var filterPicker: some View {
        Picker("Show", selection: filterBinding) {
            ForEach(service.availableFilters) { option in
                Text(tabTitle(for: option)).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityIdentifier("capturesTabFilterPicker")
    }

    private func tabTitle(for option: CaptureInboxService.Filter) -> String {
        guard let count = service.counts[option] else { return option.title }
        return "\(option.title) (\(count))"
    }

    private var filterBinding: Binding<CaptureInboxService.Filter> {
        Binding(
            get: { service.filter },
            set: { newValue in Task { await service.select(filter: newValue) } }
        )
    }

    // MARK: - States

    private func loadedState(_ captures: [Capture]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                summaryHeader(captures)
                ForEach(service.displayedCaptures) { capture in
                    CaptureRowView(capture: capture, lifeAreas: lifeAreas) {
                        inspectingCapture = capture
                    }
                    .bentoCard()
                }
            }
            .padding(16)
        }
        .refreshable {
            await service.refresh()
        }
    }

    private func summaryHeader(_ captures: [Capture]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(CaptureInboxSummary.headline(count: captures.count, filter: service.filter))
                .font(.title2.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
            let breakdown = CaptureInboxSummary.breakdown(for: captures)
            if !breakdown.isEmpty {
                Text(breakdown)
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("capturesTabSummary")
    }

    /// Empty is unremarkable here — unlike the Inbox, where empty is the win state — so it just
    /// says where things will come from.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: service.filter == .promoted ? "checkmark.circle" : "archivebox")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            Text(CaptureInboxSummary.headline(count: 0, filter: service.filter))
                .font(.title2.bold())
                .tracking(-0.5)
            Text(
                service.filter == .promoted
                    ? "Captures you turn into tasks or journal entries show up here."
                    : "Captures you archive as seen move here from the Inbox — kept, not deleted."
            )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .accessibilityIdentifier("capturesTabEmptyState")
    }

    private func failedState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Couldn't load your captures", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color("StateWarn"))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again") {
                Task { await service.load() }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("capturesTabRetryButton")
        }
        .bentoCard()
        .padding(16)
        .accessibilityIdentifier("capturesTabErrorMessage")
    }
}

#if DEBUG
private struct TabPreviewCaptureClient: CaptureClientAdapting {
    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        fatalError("unused in preview")
    }
    func fetchUnprocessedCaptures() async throws -> [Capture] { [] }
    func fetchCaptures() async throws -> [Capture] { [] }
    func fetchProcessedCaptures() async throws -> [Capture] { [] }
    func fetchSeenCaptures() async throws -> [Capture] {
        [
            Capture(
                id: UUID(), content: "That article about spaced repetition", kind: .link,
                processed: false, createdAt: Date(), seen: true
            ),
            Capture(
                id: UUID(), content: "Gift idea: walking tour", kind: .note,
                processed: false, createdAt: Date(), seen: true
            )
        ]
    }
    func fetchCapture(id: UUID) async throws -> Capture { fatalError("unused in preview") }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        fatalError("unused in preview")
    }
    func markProcessed(captureId: UUID) async throws {}
    func deleteCapture(id: UUID) async throws {}
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        fatalError("unused in preview")
    }
    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        fatalError("unused in preview")
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
}

private struct TabPreviewHomeClient: HomeClientAdapting {
    func fetchAllTasks() async throws -> [TaskItem] { [] }
    func fetchLifeAreas() async throws -> [LifeArea] {
        [LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)]
    }
    func fetchOpenTasks() async throws -> [TaskSummary] { [] }
    func reorder(order: [UUID]) async throws {}
}

#Preview("Light") {
    NavigationStack {
        CapturesTabView(client: TabPreviewCaptureClient(), homeClient: TabPreviewHomeClient())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CapturesTabView(client: TabPreviewCaptureClient(), homeClient: TabPreviewHomeClient())
    }
    .preferredColorScheme(.dark)
}
#endif
