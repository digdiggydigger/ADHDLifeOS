//
//  JournalView.swift
//  ADHD LifeOS
//

import SwiftUI

struct JournalView: View {
    @StateObject private var journalService: JournalService
    @State private var isPresentingComposer = false

    init(client: JournalClientAdapting) {
        _journalService = StateObject(wrappedValue: JournalService(client: client))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LifeAreaPicker(
                    title: "Life Area",
                    noSelectionLabel: "All",
                    lifeAreas: journalService.lifeAreas,
                    selection: $journalService.selectedLifeAreaId,
                    accessibilityID: "journalLifeAreaFilter"
                )
                .padding()

                Group {
                    switch journalService.state {
                    case .loading:
                        ProgressView()
                            .accessibilityIdentifier("journalLoadingIndicator")
                    case .loaded(let logs):
                        if logs.isEmpty {
                            emptyState
                        } else {
                            List(logs) { log in
                                LogRowView(log: log, lifeAreas: journalService.lifeAreas)
                                    .listRowBackground(Color.cardSurface)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    case .failed(let message):
                        VStack(spacing: 12) {
                            Text("Couldn't load your journal")
                                .font(.headline)
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .accessibilityIdentifier("journalErrorMessage")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // 2026-08-19 bento token pass: prototype page + card-surface rows (same treatment
            // as Tasks/Inbox).
            .background(Color.pageBackground.ignoresSafeArea())
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingComposer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("journalComposeButton")
                }
            }
            .sheet(isPresented: $isPresentingComposer) {
                LogComposerView(journalService: journalService, lifeAreas: journalService.lifeAreas) {
                    Task { await journalService.load() }
                }
            }
            .task {
                await journalService.load()
            }
        }
    }

    private var emptyState: some View {
        Text("No journal entries match this filter")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("journalEmptyState")
    }
}

private struct LogRowView: View {
    let log: Log
    let lifeAreas: [LifeArea]

    private var lifeAreaName: String? {
        guard let lifeAreaId = log.lifeAreaId else { return nil }
        // A log belonging to an archived (or unknown) area reads as "Unassigned", consistent with
        // the Tasks tab — never the archived area's own name. `lifeAreaId` itself is untouched, so
        // unarchiving restores the name with no data change.
        guard let area = lifeAreas.first(where: { $0.id == lifeAreaId }), !area.archived else {
            return TaskGrouping.unassignedLifeAreaName
        }
        return area.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.type == .journal ? "Journal" : "Log")
                    .sectionLabel()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    // Tertiary fill, not the card surface — the row itself now sits on
                    // `cardSurface`, which would make the chip invisible.
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                Spacer()
                Text(log.entryDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(log.body)
                .font(.body)
            if let lifeAreaName {
                Text(lifeAreaName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
private struct PreviewJournalClientAdapting: JournalClientAdapting {
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)

    func fetchLifeAreas() async throws -> [LifeArea] { [lifeArea] }

    func fetchLogs() async throws -> [Log] {
        [
            Log(
                id: UUID(), lifeAreaId: lifeArea.id, type: .journal,
                body: "Went for a run and felt great afterwards.", entryDate: Date(), createdAt: Date()
            ),
            Log(
                id: UUID(), lifeAreaId: nil, type: .log,
                body: "Took medication at 8am.", entryDate: Date(), createdAt: Date()
            )
        ]
    }

    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
}

#Preview {
    JournalView(client: PreviewJournalClientAdapting())
}
#endif
