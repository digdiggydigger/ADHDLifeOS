//
//  NudgesViewPreviews.swift
//  ADHD LifeOS
//

import SwiftUI

#if DEBUG
private struct PreviewNudgesClientAdapting: NudgesClientAdapting {
    func fetchNudges() async throws -> [Nudge] {
        [
            Nudge(
                id: UUID(), label: "Take medication", schedule: "0 9 * * *", active: true,
                lastFiredAt: nil, createdAt: Date(), updatedAt: Date()
            ),
            Nudge(
                id: UUID(), label: "Evening walk", schedule: "0 18 * * 1-5", active: false,
                lastFiredAt: Date(), createdAt: Date(), updatedAt: Date()
            )
        ]
    }

    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
        fatalError("unused in preview")
    }
    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        fatalError("unused in preview")
    }
    func markFired(id: UUID, existingCompletionDates: [Date]) async throws -> Nudge {
        fatalError("unused in preview")
    }
}

private struct PreviewNudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {}
    func cancelNotifications(nudgeId: UUID) async {}
    func hasScheduledNotifications(nudgeId: UUID) async -> Bool { false }
}

#Preview {
    NavigationStack {
        NudgesView(
            client: PreviewNudgesClientAdapting(),
            notificationSchedulingClient: PreviewNudgeNotificationSchedulingClient()
        )
    }
}
#endif
