//
//  HomeView.swift
//  ADHD LifeOS
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var homeService: HomeService
    @StateObject private var nudgesService: NudgesService
    private let captureClient: CaptureClientAdapting
    private let lifeAreaDetailClient: LifeAreaDetailClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting
    @State private var showSettings = false
    @State private var isPresentingInbox = false
    @State private var inboxCount = 0
    /// Home's mode-scoped reorder state. `isArranging` swaps the grid for an `.onMove` `List` (E's
    /// settled mechanism); `arrangeAreas` is the live, optimistic ordering the drag mutates. This is
    /// NOT the parked `List`→`LazyVStack` container item — it is a new, separate container.
    @State private var isArranging = false
    @State private var arrangeAreas: [LifeArea] = []

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    init(
        authService: AuthService,
        homeClient: HomeClientAdapting,
        captureClient: CaptureClientAdapting,
        nudgesClient: NudgesClientAdapting,
        nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting,
        lifeAreaDetailClient: LifeAreaDetailClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting
    ) {
        self.authService = authService
        self.captureClient = captureClient
        self.lifeAreaDetailClient = lifeAreaDetailClient
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
        _homeService = StateObject(wrappedValue: HomeService(client: homeClient))
        _nudgesService = StateObject(
            wrappedValue: NudgesService(
                client: nudgesClient, notificationSchedulingClient: nudgeNotificationSchedulingClient
            )
        )
    }

    /// The FULL set including archived areas — so the Capture triage picker can grey archived areas
    /// rather than being starved of them (they used to be absent entirely here). The grid itself
    /// still shows active areas only, filtered in `HomeService`.
    private var lifeAreasForPicker: [LifeArea] {
        homeService.lifeAreas
    }

    var body: some View {
        NavigationStack {
            Group {
                switch homeService.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("homeLoadingIndicator")
                case .loaded(let counts):
                    loadedContent(counts: counts)
                case .failed(let message):
                    VStack(spacing: 12) {
                        Text("Couldn't load your life areas")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .accessibilityIdentifier("homeErrorMessage")
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPresentingInbox = true
                    } label: {
                        Label("Inbox (\(inboxCount))", systemImage: "tray")
                    }
                    .accessibilityIdentifier("inboxButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(authService: authService)
            }
            .navigationDestination(isPresented: $isPresentingInbox) {
                CaptureInboxView(client: captureClient, lifeAreas: lifeAreasForPicker)
            }
            .navigationDestination(for: LifeArea.self) { lifeArea in
                LifeAreaDetailView(
                    lifeArea: lifeArea,
                    client: lifeAreaDetailClient,
                    taskDetailClient: taskDetailClient,
                    schedulingClient: schedulingClient
                )
            }
            .onChange(of: isPresentingInbox) { isPresented in
                if !isPresented {
                    Task { await refreshInboxCount() }
                }
            }
            .task {
                await homeService.load()
            }
            .task {
                await refreshInboxCount()
            }
            .task {
                await nudgesService.load()
            }
            .alert(
                "Couldn't save the new order",
                isPresented: Binding(
                    get: { homeService.reorderErrorMessage != nil },
                    set: { if !$0 { homeService.reorderErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(homeService.reorderErrorMessage ?? "")
            }
            .onChange(of: homeService.reorderErrorMessage) { message in
                // A rejected reorder reloads the server's order in `HomeService`; leave arrange mode
                // so the grid reflects that order rather than the one the backend refused.
                if message != nil { isArranging = false }
            }
        }
    }

    /// Active areas share the grid and the reorder list; `HomeService` has already filtered archived
    /// areas out of `counts`, so `counts.map(\.lifeArea)` is exactly the active set.
    @ViewBuilder
    private func loadedContent(counts: [LifeAreaTaskCount]) -> some View {
        let activeAreas = counts.map(\.lifeArea)
        if isArranging {
            VStack(alignment: .leading, spacing: 16) {
                lifeAreasHeader(activeAreas: activeAreas, showArrangeControl: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                reorderList
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DailySummaryView(
                        openTaskCount: counts.reduce(0) { $0 + $1.openTaskCount },
                        lifeAreaCount: counts.count,
                        inboxCount: inboxCount,
                        dueNudgeCount: nudgesService.dueNudges().count
                    )
                    supabaseBridgeWarningBanner
                    dueNudgesStrip
                    // "Arrange" is a reorder affordance over ≥2 cards; hidden below that (§ notes).
                    lifeAreasHeader(activeAreas: activeAreas, showArrangeControl: activeAreas.count >= 2)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(counts) { count in
                            NavigationLink(value: count.lifeArea) {
                                LifeAreaCardView(count: count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
    }

    /// Inline section-header row directly above the grid: a "Life Areas" title and a trailing text
    /// button reading "Arrange" / "Done". Deliberately NOT a toolbar item — the toolbar carries
    /// screen-level navigation (`inboxButton`, `settingsButton`), and a content-mutating mode control
    /// belongs beside the content it mutates. A real text label, never a third competing glyph (§4).
    @ViewBuilder
    private func lifeAreasHeader(activeAreas: [LifeArea], showArrangeControl: Bool) -> some View {
        HStack {
            Text("Life Areas")
                .font(.headline)
            Spacer()
            if showArrangeControl {
                Button(isArranging ? "Done" : "Arrange") {
                    if isArranging {
                        isArranging = false
                        Task { await homeService.load() }
                    } else {
                        arrangeAreas = activeAreas
                        isArranging = true
                    }
                }
                .font(.body.weight(.semibold))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("homeArrangeButton")
            }
        }
    }

    /// The reorder mode's `List` with `.onMove`, forced into edit mode so the drag grabbers appear.
    /// Chosen over a hand-rolled grid drag because `.onMove` supplies native drag, auto-scroll,
    /// haptics and VoiceOver's reorder rotor for free — and can be driven by `idb` for device proof.
    private var reorderList: some View {
        List {
            ForEach(arrangeAreas) { area in
                HStack(spacing: 8) {
                    Text(area.colour)
                    Text(area.name)
                        .font(.body)
                }
                .accessibilityIdentifier("homeReorderRow-\(area.id.uuidString)")
            }
            .onMove(perform: moveArrangeAreas)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    /// Each completed drag persists immediately (E's per-move decision): reorder `arrangeAreas`
    /// optimistically, then fire ONE serialised bulk reorder carrying the full ordering. TRAP 6's
    /// serialisation + coalescing lives in `HomeService.submitReorder`.
    private func moveArrangeAreas(from source: IndexSet, to destination: Int) {
        arrangeAreas.move(fromOffsets: source, toOffset: destination)
        Task { await homeService.submitReorder(activeInNewOrder: arrangeAreas) }
    }

    @ViewBuilder
    private var supabaseBridgeWarningBanner: some View {
        if let warning = authService.supabaseBridgeWarning {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(warning)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("homeSupabaseBridgeWarningBanner")
        }
    }

    @ViewBuilder
    private var dueNudgesStrip: some View {
        let due = nudgesService.dueNudges()
        if !due.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(due) { nudge in
                    HStack {
                        Text(nudge.label)
                        Spacer()
                        Button("Dismiss") {
                            Task { await nudgesService.dismiss(nudge) }
                        }
                        .accessibilityIdentifier("homeDueNudgeDismissButton-\(nudge.id)")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .accessibilityIdentifier("homeDueNudgesStrip")
        }
    }

    private func refreshInboxCount() async {
        inboxCount = (try? await captureClient.fetchUnprocessedCaptures().count) ?? inboxCount
    }
}

/// Pure sizing logic for `LifeAreaCardView`'s emoji glyph, split out so it's unit-testable
/// without a `GeometryReader` host.
enum LifeAreaCardMetrics {
    static let emojiWidthFraction: CGFloat = 0.7

    static func emojiFontSize(forCardWidth width: CGFloat) -> CGFloat {
        width * emojiWidthFraction
    }
}

private struct LifeAreaCardView: View {
    let count: LifeAreaTaskCount

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                Text(count.lifeArea.colour)
                    .font(.system(size: LifeAreaCardMetrics.emojiFontSize(forCardWidth: geometry.size.width)))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .aspectRatio(1, contentMode: .fit)
            Text(count.lifeArea.name)
                .font(.headline)
            Text("\(count.openTaskCount)")
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
