//
//  CaptureInboxView.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

/// **The Captures tab** — captures' home, and the whole of it.
///
/// It was a tab until F-V3-Areas took the slot; for the five days after that it was a pushed guest
/// screen reachable through five different doors, with its own archive (`CapturesTabView`) behind
/// a sixth. Round 2 of E's captures rethink put it back (2026-08-28): Nudges moved to a section on
/// Today, this took the freed slot, and `CapturesTabView` folded back in as the third segment it
/// always was — the two screens were the same `CaptureInboxService` with different
/// `availableFilters`, and splitting them is exactly what forced the archive to grow its own
/// Inbox door.
///
/// So: one screen, three slices, one way in.
///
/// Design pass, 2026-08-20 — this was the last screen still carrying its pre-token layout. The
/// 2026-08-19 bento pass had explicitly deferred it ("deliberately still a `List`… rebuilding this
/// heavily-tested triage screen's container was judged out of scope for a styling pass"), and this
/// closes that deferral:
/// - §2: the stock `List` becomes `ScrollView` + `LazyVStack` of floating `.bentoCard()` rows, so
///   the screen matches Home and Tasks instead of reading as a settings table.
/// - The empty state was one grey line of text on a blank screen. An empty inbox is the WIN state
///   for an ADHD user, so it now says so and offers the next action instead of describing a void.
/// - A header summarises what is waiting (`CaptureInboxSummary`) before the user reads a row.
///
/// 2026-08-23: the row's inline triage accordion is retired — rows are tappable summaries pushing
/// `CaptureDetailView` (design frame B6), where the triage affordances now live. The life-area
/// race machinery survived the move verbatim, in `CaptureFiledInCard`.
struct CaptureInboxView: View {
    /// Internal, not private: the v3 sections live in `CaptureInboxSections.swift`.
    @StateObject var service: CaptureInboxService
    /// Fetched here rather than handed down: as a tab this screen has no parent holding them.
    /// Internal, not private — the sections file chips with them.
    @State var lifeAreas: [LifeArea] = []
    /// The life areas' owner. `CapturesTabView` fetched its own the same way for the same reason.
    private let homeClient: HomeClientAdapting
    /// Retained so the empty state can offer a capture action of its own — reaching the inbox and
    /// finding it empty is exactly when a user is most likely to want to put something in it.
    private let captureClient: CaptureClientAdapting
    /// The row whose full-screen detail is pushed. Optional-state + `navigationDestination`
    /// (the `TaskListView` precedent) rather than `NavigationLink` rows, because the rows live in
    /// a `LazyVStack` inside Home's existing stack.
    @State var inspectingCapture: Capture?
    @State private var isPresentingQuickCapture = false
    /// The top card's "Task it" — the existing promote sheet over the first waiting capture.
    @State var promotingCapture: Capture?
    @State var momentumPreferences: MomentumPreferences = .default
    /// The one tag fetch every chip strip resolves against (`CaptureRowPresentation.tags(for:from:)`)
    /// — zero per-row fetches. Internal like `inspectingCapture`: the sections file reads it.
    @State var allTags: [Tag] = []
    /// The area chip staged on the top card — see `CaptureTriage.StagedSelection` for why it is
    /// keyed to a capture and why it can be empty.
    @State var sortSelection: CaptureTriage.StagedSelection?

    init(
        client: CaptureClientAdapting,
        journalClient: JournalClientAdapting? = nil,
        homeClient: HomeClientAdapting
    ) {
        _service = StateObject(
            wrappedValue: CaptureInboxService(
                client: client,
                journalClient: journalClient,
                // All three slices on one screen. The decision card and the health chart already
                // gate themselves on `.unprocessed`, so the other two render as plain lists.
                availableFilters: [.unprocessed, .seen, .promoted]
            )
        )
        self.captureClient = client
        self.homeClient = homeClient
    }

    var body: some View {
        VStack(spacing: 0) {
            purposeHeader
            filterPicker
            Group {
                switch service.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("captureInboxLoadingIndicator")
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
        // The purpose header below IS the title, so the bar keeps only its back chevron rather than
        // saying "Inbox" directly above a larger "Capture Inbox". Hiding the bar outright would take
        // the way back with it.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingQuickCapture) {
            QuickCaptureView(client: captureClient) {
                Task { await service.refresh() }
            }
            .keyboardDismissal()
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
            momentumPreferences = UserDefaultsMomentumPreferencesStore().read()
            allTags = await service.fetchAllTags()
            lifeAreas = (try? await homeClient.fetchLifeAreas()) ?? []
        }
        // `refresh()`, not `load()`: the quiet path that never blanks the list mid-read. Tags
        // re-fetch too, so a tag renamed in Settings shows on the triage chips straight away.
        .onReceive(DataChangeSignal.changes) { _ in
            Task {
                await service.refresh()
                allTags = await service.fetchAllTags()
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar.appTabBarClearance() }
        // Triage's failures were being published and rendered NOWHERE on this screen: a Sorted
        // that could not write, or an undo that could not restore, both set `triageErrorMessage`
        // and looked exactly like a button that does nothing. That mattered little while every
        // failure simply left the row in place; it matters now that undo can decline to act and
        // deliberately keep its offer standing.
        .alert(
            "Couldn't do that",
            isPresented: Binding(
                get: { service.triageErrorMessage != nil },
                set: { if !$0 { service.triageErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(service.triageErrorMessage ?? "")
        }
        .sheet(item: $promotingCapture) { capture in
            CapturePromoteSheet(
                capture: capture,
                lifeAreaId: capture.lifeAreaId,
                service: service
            ) {
                Task { await service.refresh() }
            }
            .keyboardDismissal()
        }
    }

    /// The web original's masthead: an eyebrow, the real title, and — the part that matters — a line
    /// saying what this screen is FOR. "Dump thoughts & photos instantly, triage when executive
    /// bandwidth allows" is the promise the whole inbox rests on, and a bare "Inbox" nav title makes
    /// it once again a pile you have to remember the point of.
    ///
    /// Given a purpose line, the nav title becomes a duplicate, so it is hidden (the back button
    /// stays).
    private var purposeHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Capture Inbox")
                .font(.largeTitle.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Spacer()
            undoHeaderButton
            CaptureRefinementMenu(service: service)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("captureInboxPurposeHeader")
    }

    /// The three slices, carried over from `CapturesTabView` with its count-carrying labels. A
    /// tab whose count is not yet known renders its bare title rather than "(0)" — never having
    /// looked is not the same as nothing being there.
    private var filterPicker: some View {
        Picker("Show", selection: filterBinding) {
            ForEach(service.availableFilters) { option in
                Text(tabTitle(for: option)).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityIdentifier("capturesFilterPicker")
    }

    private func tabTitle(for option: CaptureInboxService.Filter) -> String {
        guard let count = service.counts[option] else { return option.title }
        return "\(option.title) (\(count))"
    }

    private var filterBinding: Binding<CaptureInboxService.Filter> {
        Binding(
            get: { service.filter },
            set: { newValue in
                // Switching slices abandons a staged pick: it belonged to a capture on the slice
                // being left, and `StagedSelection` is keyed to that capture anyway.
                sortSelection = nil
                Task { await service.select(filter: newValue) }
            }
        )
    }

    /// Taking a decision back also drops whatever was staged on the card.
    ///
    /// E's 2026-08-28 call: after an undo the area has to be chosen again. Leaving the pick would
    /// let the next tap of Sorted file a capture into an area chosen for a DIFFERENT one — and on
    /// the restored capture it would present a decision E had just said they wanted back.
    func undoLastTriage() async {
        Haptics.play(.light)
        await service.undoLastTriageAction()
        sortSelection = nil
    }

    // MARK: - States

    private func loadedState(_ captures: [Capture]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                summaryHeader(captures)

                // v3's triage shape: the FIRST waiting capture as the decision card, the rest
                // queued under "Then" — one decision at a time, not a wall of equals.
                if service.filter == .unprocessed, let top = service.displayedCaptures.first {
                    topCaptureDecision(top)
                    let rest = Array(service.displayedCaptures.dropFirst())
                    if !rest.isEmpty {
                        Text("Then")
                            .sectionLabel()
                            .foregroundStyle(Color.accentColor)
                        ForEach(rest) { capture in
                            row(for: capture)
                                .bentoCard()
                        }
                    }
                } else {
                    ForEach(service.displayedCaptures) { capture in
                        row(for: capture)
                            .bentoCard()
                    }
                }

                healthSection
            }
            .padding(16)
        }
        // The capture disc floats over the bottom of this scroll view, so the last card — often
        // the Sorted button itself — sat underneath it with nothing below to scroll to (E's
        // screenshots, 2026-08-28). The room to lift it clear, now the shared modifier: this was
        // the only screen that had it, and it was padded INTO the content rather than inset.
        .captureDiscClearance()
        .refreshable {
            await service.refresh()
            allTags = await service.fetchAllTags()
        }
    }

    /// An empty inbox is the goal state, not an error and not a void — so it reads as an
    /// achievement and points at the one thing worth doing next. Empty is unremarkable on the
    /// other two slices, which just say where things will come from; and only the inbox offers a
    /// capture button, because only there is "put something in it" the useful next move.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyGlyph)
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            Text(CaptureInboxSummary.headline(count: 0, filter: service.filter))
                .font(.title2.bold())
                .tracking(-0.5)
            Text(emptyMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if service.filter == .unprocessed {
                Button("Capture something") {
                    isPresentingQuickCapture = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("captureInboxEmptyCaptureButton")
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .accessibilityIdentifier("captureInboxEmptyState")
    }

    private var emptyGlyph: String {
        switch service.filter {
        case .unprocessed: return "tray"
        case .seen: return "checkmark.circle"
        case .promoted: return "text.badge.checkmark"
        }
    }

    private var emptyMessage: String {
        switch service.filter {
        case .unprocessed:
            return "Nothing waiting to be triaged. Anything you capture lands here first, "
                + "so your head doesn't have to hold it."
        case .seen:
            return "Captures you sort move here — filed under a life area, kept, not deleted."
        case .promoted:
            return "Captures you turn into tasks or journal entries show up here."
        }
    }

    private func failedState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Couldn't load your inbox", systemImage: "exclamationmark.triangle.fill")
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
            .accessibilityIdentifier("captureInboxRetryButton")
        }
        .bentoCard()
        .padding(16)
        .accessibilityIdentifier("captureInboxErrorMessage")
    }

    // MARK: - Row

    private func row(for capture: Capture) -> some View {
        CaptureRowView(
            capture: capture,
            lifeAreas: lifeAreas,
            tags: CaptureRowPresentation.tags(for: capture, from: allTags),
            places: service.places
        ) {
            inspectingCapture = capture
        }
    }

}
