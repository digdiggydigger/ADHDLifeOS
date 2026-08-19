//
//  FirebaseManager+Seed.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// First-login starter content, so a brand-new user's dashboard never renders completely blank:
/// six life areas (emoji in `colour`, per the app-wide convention), five baseline tags, three
/// starter tasks (one due tomorrow, one pre-tagged), and one welcome journal log.
///
/// Idempotency is two-layered: a `seeded_at` marker on `users/{uid}` short-circuits every later
/// sign-in, and even without the marker no content is written if the user already has life areas
/// (an account that predates the marker must never be re-seeded over). All writes land in one
/// atomic batch, with the marker last in the same batch — so a half-seeded state can't persist.
extension FirebaseManager {
    func seedDefaultContentIfNeeded() async throws {
        let profile = try await userDocument().getDocument()
        guard profile.get("seeded_at") == nil else { return }

        let existingAreas = try await fetchLifeAreas(includeArchived: true)
        if existingAreas.isEmpty {
            try await writeSeedContent()
        } else {
            try await userDocument().setData(["seeded_at": FieldValue.serverTimestamp()], merge: true)
        }
    }

    private func writeSeedContent() async throws {
        let batch = firestoreBatch()
        let encoder = Firestore.Encoder()

        let areas = Self.seedLifeAreas()
        for area in areas {
            try batch.setData(encoder.encode(area), forDocument: collection(.lifeAreas).document(area.id.uuidString))
        }

        let tags = Self.seedTags()
        for tag in tags {
            try batch.setData(encoder.encode(tag), forDocument: collection(.tags).document(tag.id.uuidString))
        }

        let health = areas.first { $0.name == "Health" }
        let growth = areas.first { $0.name == "Growth" }
        let quickWin = tags.first { $0.name == "quick-win" }
        for (task, tagIds) in Self.seedTasks(healthAreaId: health?.id, growthAreaId: growth?.id,
                                            quickWinTagId: quickWin?.id) {
            var data = try encoder.encode(task)
            if !tagIds.isEmpty {
                data["tag_ids"] = tagIds.map(\.uuidString)
            }
            batch.setData(data, forDocument: try collection(.tasks).document(task.id.uuidString))
        }

        let welcome = Self.seedWelcomeLog()
        try batch.setData(encoder.encode(welcome), forDocument: collection(.logs).document(welcome.id.uuidString))

        try batch.setData(
            ["seeded_at": FieldValue.serverTimestamp()],
            forDocument: userDocument(),
            merge: true
        )
        try await batch.commit()
    }

    private static func seedLifeAreas() -> [LifeArea] {
        [
            LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0),
            LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1),
            LifeArea(id: UUID(), name: "Home", colour: "🏠", sortOrder: 2),
            LifeArea(id: UUID(), name: "Money", colour: "💰", sortOrder: 3),
            LifeArea(id: UUID(), name: "Relationships", colour: "💬", sortOrder: 4),
            LifeArea(id: UUID(), name: "Growth", colour: "🌱", sortOrder: 5)
        ]
    }

    private static func seedTags() -> [Tag] {
        ["urgent", "focus", "quick-win", "waiting-on", "someday"].map { Tag(id: UUID(), name: $0) }
    }

    private static func seedTasks(
        healthAreaId: UUID?,
        growthAreaId: UUID?,
        quickWinTagId: UUID?
    ) -> [(TaskDetail, [UUID])] {
        let now = Date()
        let firstTask = TaskDetail(
            id: UUID(),
            lifeAreaId: growthAreaId,
            title: "Check off your first task",
            notes: "Tap the circle to mark this done — small wins count.",
            status: .open,
            priority: .p4,
            dueDate: nil,
            createdAt: now
        )
        let walk = TaskDetail(
            id: UUID(),
            lifeAreaId: healthAreaId,
            title: "Take a 10-minute walk",
            notes: nil,
            status: .open,
            priority: .p3,
            dueDate: now.addingTimeInterval(24 * 3600),
            createdAt: now
        )
        let capture = TaskDetail(
            id: UUID(),
            lifeAreaId: nil,
            title: "Capture three things on your mind",
            notes: "Use Quick Capture — get them out of your head and into the inbox.",
            status: .open,
            priority: .p4,
            dueDate: nil,
            createdAt: now
        )
        return [
            (firstTask, quickWinTagId.map { [$0] } ?? []),
            (walk, []),
            (capture, [])
        ]
    }

    private static func seedWelcomeLog() -> Log {
        let now = Date()
        return Log(
            id: UUID(),
            lifeAreaId: nil,
            type: .journal,
            body: "Welcome to ADHD LifeOS. This journal is append-only on purpose — "
                + "write things down, let them stand, move forward.",
            entryDate: now,
            createdAt: now
        )
    }
}
