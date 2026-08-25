//
//  CaptureInboxView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The capture triage screen — since 2026-08-23 purely the to-triage queue: the Seen and
/// Promoted slices moved to the Captures tab (`CapturesTabView`), so the filter picker this
/// screen carried is gone with them.
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
    let lifeAreas: [LifeArea]
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
    @State var binningCapture: Capture?
    @State var momentumPreferences: MomentumPreferences = .default

    init(
        client: CaptureClientAdapting,
        journalClient: JournalClientAdapting? = nil,
        lifeAreas: [LifeArea]
    ) {
        _service = StateObject(
            wrappedValue: CaptureInboxService(client: client, journalClient: journalClient)
        )
        self.lifeAreas = lifeAreas
        self.captureClient = client
    }

    var body: some View {
        VStack(spacing: 0) {
            purposeHeader
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
        }
        .sheet(item: $promotingCapture) { capture in
            CapturePromoteSheet(
                capture: capture,
                lifeAreaId: capture.lifeAreaId,
                service: service
            ) {
                Task { await service.refresh() }
            }
        }
        .confirmationDialog(
            "Bin this capture?",
            isPresented: Binding(
                get: { binningCapture != nil },
                set: { if !$0 { binningCapture = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Bin it", role: .destructive) {
                if let capture = binningCapture {
                    Task { await service.discard(capture: capture) }
                }
            }
        } message: {
            Text("Deleted for good — there is no archive for binned captures.")
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
            CaptureRefinementMenu(service: service)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("captureInboxPurposeHeader")
    }

    // MARK: - States

    private func loadedState(_ captures: [Capture]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                summaryHeader(captures)

                // v3's triage shape: the FIRST waiting capture as the decision card, the rest
                // queued under "Then" — one decision at a time, not a wall of equals.
                if service.filter == .unprocessed, let top = service.displayedCaptures.first {
                    topCaptureCard(top)
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
        .refreshable {
            await service.refresh()
        }
    }

    /// An empty inbox is the goal state, not an error and not a void — so it reads as an
    /// achievement and points at the one thing worth doing next.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            Text("Inbox clear")
                .font(.title2.bold())
                .tracking(-0.5)
            Text(
                "Nothing waiting to be triaged. Anything you capture lands here first, "
                    + "so your head doesn't have to hold it."
            )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Capture something") {
                isPresentingQuickCapture = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("captureInboxEmptyCaptureButton")
        }
        .padding(24)
        .frame(maxWidth: 420)
        .accessibilityIdentifier("captureInboxEmptyState")
    }

    private func failedState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Couldn't load your inbox", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
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
        CaptureRowView(capture: capture, lifeAreas: lifeAreas) {
            inspectingCapture = capture
        }
    }

}
