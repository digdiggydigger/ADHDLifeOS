//
//  JournalViewPreviews.swift
//  ADHD LifeOS
//
//  The JournalView previews and their sample client, split from `JournalView.swift` for its
//  file length budget once the sprint and capture rows landed (the `HomeViewPreviews` pattern).
//

import SwiftUI
#if DEBUG
private struct PreviewJournalClientAdapting: JournalClientAdapting {
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)

    func fetchLifeAreas() async throws -> [LifeArea] { [lifeArea] }

    func fetchLogs() async throws -> [Log] {
        [
            Log(
                id: UUID(), lifeAreaId: lifeArea.id, type: .journal,
                body: "Feeling a bit foggy today. Drank tea, set 15-minute timers.",
                entryDate: .now, createdAt: .now,
                energyLevel: .medium, moodEmoji: "⚡"
            )
        ]
    }

    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        [
            CompletedFocusSession(
                id: UUID(), taskId: nil, taskTitle: "Draft the report", lifeAreaEmoji: "🫀",
                plannedSeconds: 1_500, focusedSeconds: 720, checkpointsReached: 1,
                completedNaturally: false,
                startedAt: .now.addingTimeInterval(-4_320), endedAt: .now.addingTimeInterval(-3_600)
            )
        ]
    }

    func fetchLocationEvents() async throws -> [LocationEvent] { [] }

    func fetchPlaces() async throws -> [Place] { [] }

    func fetchCaptures() async throws -> [Capture] {
        [
            Capture(
                id: UUID(), content: "Ask the pharmacy about the refill", kind: .note,
                processed: false, createdAt: .now.addingTimeInterval(-7_200),
                lifeAreaId: lifeArea.id
            )
        ]
    }

    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
    func deleteLog(id: UUID) async throws {}
}

#Preview("Light") {
    JournalView(client: PreviewJournalClientAdapting())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    JournalView(client: PreviewJournalClientAdapting())
        .preferredColorScheme(.dark)
}
#endif
