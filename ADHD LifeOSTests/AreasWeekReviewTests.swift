//
//  AreasWeekReviewTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `F-E3-OneCardToday`, round 5b: *"Week review door → 'Both.' Idea 9's line under the 'then' list
/// reads '✓ 3 done today · Week review ›', AND a row sits at the top of the Areas tab."*
///
/// Two doors must open ONE review — the same week, the same counts, and so the same AI summary.
/// Today builds its inputs from state it already holds; Areas builds them from what its own load
/// fetched, plus the two streams it never needed before (focus sessions and nudges), read only when
/// the door is used rather than on every refresh of the tab.
@MainActor
final class AreasWeekReviewTests: XCTestCase {

    private let now = Date()

    private struct Rig {
        let service: AreasService
        let home: FakeHomeClientAdapting
        let capture: FakeCaptureClientAdapting
    }

    private func rig(
        nudges: Result<[Nudge], Error>? = .success([]),
        sessions: Result<[CompletedFocusSession], Error> = .success([]),
        focusGoal: Int? = nil
    ) -> Rig {
        let home = FakeHomeClientAdapting()
        let capture = FakeCaptureClientAdapting()
        let journal = FakeJournalClientAdapting()
        journal.focusSessionsResult = sessions
        var nudgesClient: FakeNudgesClientAdapting?
        if let nudges {
            nudgesClient = FakeNudgesClientAdapting()
            nudgesClient?.fetchNudgesResult = nudges
        }
        var preferences = MomentumPreferences.default
        preferences.focusDailyGoalMinutes = focusGoal
        let service = AreasService(
            homeClient: home, journalClient: journal, captureClient: capture, nudgesClient: nudgesClient,
            preferencesStore: FakePreferencesStore(preferences)
        )
        return Rig(service: service, home: home, capture: capture)
    }

    private func nudge(active: Bool) -> Nudge {
        let created = now.addingTimeInterval(-2 * 86_400)
        return Nudge(
            id: UUID(), label: "Stretch", schedule: "0 9 * * *", active: active,
            completionDates: nil, createdAt: created, updatedAt: created
        )
    }

    private let sprint = CompletedFocusSession(
        id: UUID(), taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼",
        plannedSeconds: 1_500, focusedSeconds: 1_500, checkpointsReached: 0,
        completedNaturally: true, startedAt: Date(timeIntervalSince1970: 0),
        endedAt: Date(timeIntervalSince1970: 1_500)
    )

    func testTheAreasDoorBuildsTheReviewFromWhatTheTabLoaded() async {
        let rig = rig(
            nudges: .success([nudge(active: true), nudge(active: false)]),
            sessions: .success([sprint])
        )
        let (service, home, capture) = (rig.service, rig.home, rig.capture)
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let archived = LifeArea(id: UUID(), name: "Old", colour: "📦", sortOrder: 1, archived: true)
        home.lifeAreasResult = .success([work, archived])
        home.openTasksResult = .success([
            TaskSummary(lifeAreaId: work.id, status: .open), TaskSummary(lifeAreaId: nil, status: .open)
        ])
        let closed = TaskItem(
            id: UUID(), lifeAreaId: work.id, title: "Done", status: .done, priority: .p3, dueDate: nil
        )
        home.allTasksResult = .success([closed])
        capture.fetchUnprocessedCapturesResult = .success([
            Capture(id: UUID(), content: "idea", kind: .note, processed: false, createdAt: now)
        ])

        await service.load()
        let inputs = await service.weekReviewInputs(asOf: now)

        XCTAssertEqual(inputs.tasks, [closed])
        XCTAssertEqual(inputs.lifeAreas, [work, archived])
        XCTAssertEqual(inputs.sessions, [sprint])
        XCTAssertEqual(inputs.inboxCount, 1)
        XCTAssertEqual(inputs.openTaskCount, 2)
        XCTAssertEqual(inputs.areaCount, 1, "Only unarchived areas count, as Today counts them.")
        XCTAssertEqual(inputs.dueNudgeCount, 1, "The paused nudge is not due.")
    }

    /// The streams the review only garnishes with degrade to empty, like every scoreboard input —
    /// a failed session read must not stop the door opening.
    func testAFailedGarnishReadStillOpensTheReview() async {
        let service = rig(nudges: .failure(URLError(.notConnectedToInternet)),
                          sessions: .failure(URLError(.notConnectedToInternet))).service
        await service.load()
        let inputs = await service.weekReviewInputs(asOf: now)
        XCTAssertEqual(inputs.sessions, [])
        XCTAssertEqual(inputs.dueNudgeCount, 0)
    }

    /// `F-E4`: Week review's one chart draws its goal bar only for a SET focus goal, so the Areas
    /// door must carry the same preference Today's does — read when the door is used.
    func testTheAreasDoorCarriesTheFocusGoal() async {
        let unset = rig().service
        await unset.load()
        let noGoal = await unset.weekReviewInputs(asOf: now)
        XCTAssertNil(noGoal.focusDailyGoalMinutes)
        let set = rig(focusGoal: 30).service
        await set.load()
        let withGoal = await set.weekReviewInputs(asOf: now)
        XCTAssertEqual(withGoal.focusDailyGoalMinutes, 30)
    }

    private final class FakePreferencesStore: MomentumPreferencesStoring {
        private var preferences: MomentumPreferences
        init(_ preferences: MomentumPreferences) { self.preferences = preferences }
        func read() -> MomentumPreferences { preferences }
        func write(_ preferences: MomentumPreferences) { self.preferences = preferences }
    }

    func testWithNoNudgesClientNothingIsDue() async {
        let service = rig(nudges: nil).service
        await service.load()
        let inputs = await service.weekReviewInputs(asOf: now)
        XCTAssertEqual(inputs.dueNudgeCount, 0)
    }
}
