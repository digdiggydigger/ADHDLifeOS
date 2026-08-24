//
//  AreasView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The Areas tab (F-V3-Areas): the life area as the unit of navigation. Two-up identity-tinted
/// cards (an odd last card goes full width, as v3 draws Hobbies), the Unfiled card into the
/// triage inbox, the reorder/editor door, and the week-share bar. The Captures ARCHIVE row is an
/// interim door — v3 houses it behind the Inbox in the V3-Inbox block; until then it must not
/// become unreachable when this tab replaces Captures.
struct AreasView: View {
    @ObservedObject var authService: AuthService
    /// Internal, not private: the section builders live in `AreasComponents.swift`.
    @StateObject var service: AreasService
    private let captureClient: CaptureClientAdapting
    private let journalClient: JournalClientAdapting?
    private let homeClient: HomeClientAdapting
    private let lifeAreaDetailClient: LifeAreaDetailClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting
    private let lifeAreaEditorClient: LifeAreaEditorClientAdapting
    private let onStartFocus: ((FocusSprintPlan) -> Void)?
    private let momentumPreferencesStore: MomentumPreferencesStoring

    /// Internal, not private: `AreasComponents.swift` reads these.
    @State var momentumPreferences: MomentumPreferences = .default
    @State private var showSettings = false
    @State var isPresentingInbox = false
    @State private var isPresentingEditor = false
    @State private var isPresentingArchive = false

    init(
        authService: AuthService,
        homeClient: HomeClientAdapting,
        journalClient: JournalClientAdapting?,
        captureClient: CaptureClientAdapting,
        lifeAreaDetailClient: LifeAreaDetailClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        lifeAreaEditorClient: LifeAreaEditorClientAdapting? = nil,
        momentumPreferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) {
        self.authService = authService
        self.homeClient = homeClient
        self.journalClient = journalClient
        self.captureClient = captureClient
        self.lifeAreaDetailClient = lifeAreaDetailClient
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
        self.onStartFocus = onStartFocus
        // Same defaulting pattern as SettingsView: the live adapter unless a test injects one.
        self.lifeAreaEditorClient = lifeAreaEditorClient ?? FirebaseLifeAreaEditorClientAdapter()
        self.momentumPreferencesStore = momentumPreferencesStore
        _service = StateObject(wrappedValue: AreasService(
            homeClient: homeClient, journalClient: journalClient, captureClient: captureClient
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch service.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("areasLoadingIndicator")
                case .loaded(let items):
                    loadedContent(items: items)
                case .failed(let message):
                    VStack(spacing: 8) {
                        Text("Couldn't load your life areas")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .accessibilityIdentifier("areasErrorMessage")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView(authService: authService)
            }
            .navigationDestination(isPresented: $isPresentingInbox) {
                CaptureInboxView(
                    client: captureClient, journalClient: journalClient, lifeAreas: service.lifeAreas
                )
            }
            .navigationDestination(isPresented: $isPresentingEditor) {
                LifeAreaEditorListView(client: lifeAreaEditorClient)
            }
            .navigationDestination(isPresented: $isPresentingArchive) {
                CapturesTabView(
                    client: captureClient, journalClient: journalClient, homeClient: homeClient
                )
            }
            .navigationDestination(for: LifeArea.self) { lifeArea in
                LifeAreaDetailView(
                    lifeArea: lifeArea,
                    client: lifeAreaDetailClient,
                    taskDetailClient: taskDetailClient,
                    schedulingClient: schedulingClient,
                    onStartFocus: onStartFocus
                )
            }
            .task { await service.load() }
            .onAppear { momentumPreferences = momentumPreferencesStore.read() }
            .onChange(of: isPresentingInbox) { presented in
                if !presented { Task { await service.load() } }
            }
            .onChange(of: isPresentingEditor) { presented in
                if !presented { Task { await service.load() } }
            }
        }
    }

    private func loadedContent(items: [AreasGrid.Item]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Text("Every task, note and capture lives in one of these. Tap an area to work inside it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                grid(items: items)
                unfiledCard
                doorRow(
                    icon: "line.3.horizontal", title: "Reorder or add an area",
                    identifier: "areasReorderRow"
                ) { isPresentingEditor = true }
                doorRow(
                    icon: "tray.full", title: "Handled captures",
                    identifier: "areasArchiveRow"
                ) { isPresentingArchive = true }
                weekShareSection
            }
            .padding(16)
        }
        .refreshable { await service.load() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                Text("Areas")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                isPresentingInbox = true
            } label: {
                iconWell(systemImage: "tray")
                    .overlay(alignment: .topTrailing) {
                        if service.inboxCount > 0 {
                            Text("\(service.inboxCount)")
                                .font(.caption2.bold())
                                .monospacedDigit()
                                .foregroundStyle(Color("OnStateWarn"))
                                .padding(.horizontal, 4)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(Color("StateWarn"), in: Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
            }
            .accessibilityLabel("Inbox (\(service.inboxCount))")
            .accessibilityIdentifier("areasInboxButton")
            Button {
                showSettings = true
            } label: {
                iconWell(systemImage: "gearshape")
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("areasSettingsButton")
        }
    }

    private func iconWell(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(Color("LabelSecondary"))
            .frame(width: 40, height: 40)
            .background(Color.cardSurface, in: Circle())
            .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
            .contentShape(Circle())
    }

    /// Two-up rows; an odd count leaves the last card spanning the full width, as v3 draws it.
    private func grid(items: [AreasGrid.Item]) -> some View {
        let pairs = stride(from: 0, to: items.count - (items.count % 2), by: 2).map {
            (items[$0], items[$0 + 1])
        }
        return VStack(spacing: 16) {
            ForEach(pairs, id: \.0.id) { pair in
                HStack(alignment: .top, spacing: 16) {
                    AreaGridCard(item: pair.0, isWide: false)
                    AreaGridCard(item: pair.1, isWide: false)
                }
            }
            if items.count % 2 == 1, let last = items.last {
                AreaGridCard(item: last, isWide: true)
            }
        }
    }
}
