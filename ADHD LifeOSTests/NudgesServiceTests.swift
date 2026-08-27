//
//  NudgesServiceTests.swift
//  ADHD LifeOSTests
//

import Combine
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class NudgesServiceTests: XCTestCase {

    private func makeNudge(
        label: String = "Morning check-in",
        schedule: String = "0 9 * * *",
        active: Bool = true,
        lastFiredAt: Date? = nil,
        createdAt: Date = Date()
    ) -> Nudge {
        Nudge(
            id: UUID(), label: label, schedule: schedule, active: active,
            lastFiredAt: lastFiredAt, createdAt: createdAt, updatedAt: createdAt
        )
    }

    func testInitialState_isLoading() {
        let fake = FakeNudgesClientAdapting()
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())

        XCTAssertEqual(sut.state, .loading)
    }

    func testLoad_success_setsLoadedState() async {
        let fake = FakeNudgesClientAdapting()
        let nudge = makeNudge()
        fake.fetchNudgesResult = .success([nudge])
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([nudge]))
        XCTAssertEqual(fake.fetchNudgesCallCount, 1)
    }

    func testLoad_fetchFails_setsFailedState() async {
        let fake = FakeNudgesClientAdapting()
        fake.fetchNudgesResult = .failure(NudgesServiceError.fetchFailed("Network error"))
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testCreateNudge_emptyLabel_isRejectedWithoutNetworkCall() async {
        let fake = FakeNudgesClientAdapting()
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        sut.newLabel = "   "

        let result = await sut.createNudge()

        XCTAssertFalse(result)
        XCTAssertEqual(fake.createNudgeCallCount, 0)
        XCTAssertNotNil(sut.createErrorMessage)
    }

    func testCreateNudge_zeroWeekdaysSelected_isRejectedWithoutNetworkCall() async {
        let fake = FakeNudgesClientAdapting()
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        sut.newLabel = "Drink water"
        sut.newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [])

        let result = await sut.createNudge()

        XCTAssertFalse(result)
        XCTAssertEqual(fake.createNudgeCallCount, 0)
    }

    func testCreateNudge_success_addsToList() async {
        let fake = FakeNudgesClientAdapting()
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        await sut.load()
        sut.newLabel = "Drink water"
        sut.newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [1])

        let result = await sut.createNudge()

        XCTAssertTrue(result)
        XCTAssertEqual(fake.createNudgeCallCount, 1)
        XCTAssertEqual(fake.lastCreateNudgeArguments?.label, "Drink water")
        XCTAssertEqual(sut.nudges.count, 1)
        XCTAssertEqual(sut.newLabel, "", "Label should reset after a successful create")
    }

    func testList_listsAllFetchedNudges() async {
        let fake = FakeNudgesClientAdapting()
        let active = makeNudge(label: "Active")
        let inactive = makeNudge(label: "Inactive", active: false)
        fake.fetchNudgesResult = .success([active, inactive])
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())

        await sut.load()

        XCTAssertEqual(sut.nudges, [active, inactive])
    }

    func testDismiss_setsLastFiredAt_andRemovesFromDueList() async {
        let fake = FakeNudgesClientAdapting()
        let nudge = makeNudge(createdAt: Date(timeIntervalSince1970: 0))
        fake.fetchNudgesResult = .success([nudge])
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        await sut.load()
        XCTAssertFalse(sut.dueNudges(now: Date()).isEmpty, "Precondition: nudge should start due")

        let result = await sut.dismiss(nudge)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.markFiredCallCount, 1)
        XCTAssertTrue(sut.dueNudges(now: Date()).isEmpty)
    }

    func testUpdate_partialFields_success() async {
        let fake = FakeNudgesClientAdapting()
        let nudge = makeNudge(label: "Original")
        fake.fetchNudgesResult = .success([nudge])
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        await sut.load()

        let result = await sut.update(
            nudge: nudge, editedLabel: "Updated", editedSchedule: NudgeSchedule.parse(cronString: nudge.schedule)!
        )

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastUpdateNudgePayload?.label, "Updated")
        XCTAssertNil(fake.lastUpdateNudgePayload?.schedule, "Schedule did not change, should be omitted")
        XCTAssertEqual(sut.nudges.first?.label, "Updated")
    }

    func testUpdate_onNonexistentNudge_surfacesNotFoundError() async {
        let fake = FakeNudgesClientAdapting()
        fake.updateNudgeResult = .failure(NudgesServiceError.notFound)
        let nudge = makeNudge()
        fake.fetchNudgesResult = .success([nudge])
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        await sut.load()

        let result = await sut.update(
            nudge: nudge, editedLabel: "Updated", editedSchedule: NudgeSchedule.parse(cronString: nudge.schedule)!
        )

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, NudgesServiceError.notFound.errorDescription)
    }

    func testToggleActive_viaUpdate_flipsActiveState() async {
        let fake = FakeNudgesClientAdapting()
        let nudge = makeNudge(active: true)
        fake.fetchNudgesResult = .success([nudge])
        let sut = NudgesService(client: fake, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting())
        await sut.load()

        let result = await sut.toggleActive(nudge)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastUpdateNudgePayload?.active, false)
        XCTAssertEqual(sut.nudges.first?.active, false)
    }

    /// SUGG-b4's quiet-reload rule (E's checklist, 2026-08-26): once content is on screen, a
    /// reload — pull-to-refresh or the app-wide DataChangeSignal — must not flash the loading
    /// state over it; fresh data replaces stale data in place.
    func testReloadAfterSuccess_neverFlashesLoading() async {
        let sut = NudgesService(
            client: FakeNudgesClientAdapting(),
            notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting()
        )
        await sut.load()

        var sawLoading = false
        let watcher = sut.$state.dropFirst().sink { state in
            if case .loading = state { sawLoading = true }
        }
        await sut.load()
        watcher.cancel()

        XCTAssertFalse(sawLoading, "a reload over loaded content must not flash .loading")
    }
}
