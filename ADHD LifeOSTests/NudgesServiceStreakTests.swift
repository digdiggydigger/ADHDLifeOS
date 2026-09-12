//
//  NudgesServiceStreakTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-5`: E's second full-screen milestone — **a nudge's streak landing on 7**.
//
//  E asked for this one unprompted at F3 ("When dismissing a nudge using the 'Done for now'
//  Button"), and F4 settled which reading it was: full-screen **only** when the streak lands on
//  seven, not on every Done for now. The nudge-specific animation E wants for every dismissal is a
//  later design, parked in the register.
//
//  **R-b: exactly 7.** Whether 14 and 21 also fire is E's call and is parked; a run passing through
//  eight is not a second milestone, and dismissing the same nudge twice in one day is not one
//  either — which is the case the arithmetic has to get right, because `markFired` will happily
//  stamp a second completion on a day that already has one.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class NudgesServiceStreakTests: XCTestCase {

    private let noon = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 3600)

    /// `days` consecutive completion stamps ending YESTERDAY, so today's dismissal extends the run
    /// by exactly one — which is what a dismissal does.
    private func runEndingYesterday(_ days: Int) -> [Date] {
        (1...max(days, 1)).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: noon)
        }
        .prefix(days)
        .map { $0 }
    }

    private func nudge(completions: [Date]) -> Nudge {
        Nudge(
            id: UUID(), label: "Stretch", schedule: "0 9 * * *", active: true,
            completionDates: completions, createdAt: noon, updatedAt: noon
        )
    }

    private func dismissing(
        _ nudge: Nudge, celebrate: RecordingCelebrationRequester
    ) async -> NudgesService {
        let client = FakeNudgesClientAdapting()
        client.fetchNudgesResult = .success([nudge])
        var fired = nudge
        fired.completionDates = (nudge.completionDates ?? []) + [noon]
        client.markFiredResult = .success(fired)
        let service = NudgesService(
            client: client,
            notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting(),
            celebrate: celebrate
        )
        await service.load()
        await service.dismiss(nudge)
        return service
    }

    func testTheSeventhConsecutiveDoneForNowCelebratesTheStreak() async {
        let celebrate = RecordingCelebrationRequester()
        _ = await dismissing(nudge(completions: runEndingYesterday(6)), celebrate: celebrate)

        XCTAssertEqual(celebrate.milestones, [.streakSeven])
    }

    func testTheSixthConsecutiveDoneForNowCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        _ = await dismissing(nudge(completions: runEndingYesterday(5)), celebrate: celebrate)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    /// **R-b, and the reason the milestone is a CROSSING rather than a value.** Day eight is not a
    /// second milestone; 14 and 21 are parked for E.
    func testTheEighthConsecutiveDoneForNowCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        _ = await dismissing(nudge(completions: runEndingYesterday(7)), celebrate: celebrate)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    /// The first Done for now of a run is not a streak at all.
    func testAFirstEverDoneForNowCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        _ = await dismissing(nudge(completions: []), celebrate: celebrate)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    /// **Dismissing the same nudge twice on day seven.** The run is already 7 before the second
    /// tap and still 7 after it, so nothing has landed and nothing celebrates. Without the
    /// before-and-after comparison this is a full-screen celebration on every extra tap, all day.
    func testASecondDoneForNowOnTheSameDayCelebratesNothingAgain() async {
        let celebrate = RecordingCelebrationRequester()
        let alreadySeven = runEndingYesterday(6) + [noon]
        _ = await dismissing(nudge(completions: alreadySeven), celebrate: celebrate)

        XCTAssertTrue(
            celebrate.requested.isEmpty,
            "The streak celebrated again on a day it had already landed on seven."
        )
    }

    /// A run of six that was BROKEN — five days, a gap, then today — is a run of one.
    func testSevenCompletionsThatAreNotConsecutiveCelebrateNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let broken = (2...7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: noon)
        }
        _ = await dismissing(nudge(completions: broken), celebrate: celebrate)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    func testADismissalThatFailedCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let client = FakeNudgesClientAdapting()
        let waiting = nudge(completions: runEndingYesterday(6))
        client.fetchNudgesResult = .success([waiting])
        client.markFiredResult = .failure(NudgesServiceError.notFound)
        let service = NudgesService(
            client: client,
            notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting(),
            celebrate: celebrate
        )
        await service.load()

        await service.dismiss(waiting)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }
}
