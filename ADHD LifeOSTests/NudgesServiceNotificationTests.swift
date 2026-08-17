//
//  NudgesServiceNotificationTests.swift
//  ADHD LifeOSTests
//
//  Split out from NudgesServiceTests.swift to keep that file under SwiftLint's
//  type_body_length limit — covers "FEATURE: Nudges Push Notifications"' scheduling wiring.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class NudgesServiceNotificationTests: XCTestCase {

    private func makeNudge(
        label: String = "Morning check-in",
        schedule: String = "0 9 * * *",
        active: Bool = true,
        createdAt: Date = Date()
    ) -> Nudge {
        Nudge(
            id: UUID(), label: label, schedule: schedule, active: active,
            lastFiredAt: nil, createdAt: createdAt, updatedAt: createdAt
        )
    }

    func testCreateNudge_active_schedulesNotifications() async {
        let client = FakeNudgesClientAdapting()
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        sut.newLabel = "Drink water"
        sut.newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [1])

        let result = await sut.createNudge()

        XCTAssertTrue(result)
        XCTAssertEqual(notifications.scheduleNotificationsCallCount, 1)
        XCTAssertEqual(notifications.lastScheduleArguments?.label, "Drink water")
        XCTAssertNil(sut.createErrorMessage)
    }

    func testCreateNudge_inactive_doesNotScheduleNotifications() async {
        let client = FakeNudgesClientAdapting()
        let inactiveCreated = makeNudge(active: false)
        client.createNudgeResult = .success(inactiveCreated)
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        sut.newLabel = "Drink water"
        sut.newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [1])

        _ = await sut.createNudge()

        XCTAssertEqual(notifications.scheduleNotificationsCallCount, 0)
        XCTAssertEqual(notifications.cancelNotificationsCallCount, 1)
    }

    func testUpdate_activeNudgeWithNewSchedule_reschedules() async {
        let client = FakeNudgesClientAdapting()
        let nudge = makeNudge(active: true)
        client.fetchNudgesResult = .success([nudge])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        await sut.load()

        let newSchedule = NudgeSchedule(hour: 18, minute: 30, weekdays: [1, 2])
        _ = await sut.update(nudge: nudge, editedLabel: nudge.label, editedSchedule: newSchedule)

        XCTAssertEqual(
            notifications.scheduleNotificationsCallCount, 2,
            "load's reconciliation schedules once, then update reschedules again — old ones don't linger"
        )
        XCTAssertEqual(notifications.lastScheduleArguments?.schedule, newSchedule)
    }

    func testUpdate_toInactive_cancelsNotifications() async {
        let client = FakeNudgesClientAdapting()
        let nudge = makeNudge(active: true)
        client.fetchNudgesResult = .success([nudge])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        await sut.load()

        _ = await sut.toggleActive(nudge)

        XCTAssertEqual(notifications.cancelNotificationsCallCount, 1)
        XCTAssertEqual(notifications.lastCancelNudgeId, nudge.id)
    }

    func testToggleActive_on_schedules() async {
        let client = FakeNudgesClientAdapting()
        let nudge = makeNudge(active: false)
        client.fetchNudgesResult = .success([nudge])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        await sut.load()

        _ = await sut.toggleActive(nudge)

        XCTAssertEqual(notifications.scheduleNotificationsCallCount, 1)
        XCTAssertEqual(notifications.lastScheduleArguments?.nudgeId, nudge.id)
    }

    func testToggleActive_off_cancels() async {
        let client = FakeNudgesClientAdapting()
        let nudge = makeNudge(active: true)
        client.fetchNudgesResult = .success([nudge])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        await sut.load()

        _ = await sut.toggleActive(nudge)

        XCTAssertEqual(notifications.cancelNotificationsCallCount, 1)
        XCTAssertEqual(notifications.lastCancelNudgeId, nudge.id)
    }

    /// Simulates a nudge whose `active` flag was flipped from the web client between mobile app
    /// launches — `load()`'s reconciliation must schedule/cancel correctly purely from the
    /// freshly-fetched server state, with no dependency on mobile's own prior local state.
    func testLoad_reconciliation_schedulesActiveAndCancelsInactive() async {
        let client = FakeNudgesClientAdapting()
        let active = makeNudge(label: "Active", active: true)
        let inactive = makeNudge(label: "Inactive", active: false)
        client.fetchNudgesResult = .success([active, inactive])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)

        await sut.load()

        XCTAssertEqual(notifications.scheduleNotificationsCallCount, 1)
        XCTAssertEqual(notifications.lastScheduleArguments?.nudgeId, active.id)
        XCTAssertTrue(notifications.cancelNudgeIds.contains(inactive.id))
    }

    func testLoad_permissionDenied_surfacesWarning() async {
        let client = FakeNudgesClientAdapting()
        let nudge = makeNudge(active: true)
        client.fetchNudgesResult = .success([nudge])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        notifications.authorizationGranted = false
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)

        await sut.load()

        XCTAssertEqual(notifications.scheduleNotificationsCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testCreateNudge_permissionDenied_stillCreatesButSurfacesWarning() async {
        let client = FakeNudgesClientAdapting()
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        notifications.authorizationGranted = false
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        sut.newLabel = "Drink water"
        sut.newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [1])

        let result = await sut.createNudge()

        XCTAssertTrue(result, "The nudge is still created even if notification permission is denied")
        XCTAssertEqual(notifications.scheduleNotificationsCallCount, 0)
        XCTAssertNotNil(sut.createErrorMessage)
    }

    /// The in-app due/dismiss system must stay completely untouched by any notification-scheduling
    /// call — `dismiss()` still only calls `markFired`, never notification scheduling methods.
    func testDismiss_doesNotTouchNotificationScheduling() async {
        let client = FakeNudgesClientAdapting()
        let nudge = makeNudge(createdAt: Date(timeIntervalSince1970: 0))
        client.fetchNudgesResult = .success([nudge])
        let notifications = FakeNudgeNotificationSchedulingAdapting()
        let sut = NudgesService(client: client, notificationSchedulingClient: notifications)
        await sut.load()
        let callsAfterLoad = notifications.scheduleNotificationsCallCount + notifications.cancelNotificationsCallCount

        _ = await sut.dismiss(nudge)

        let callsAfterDismiss =
            notifications.scheduleNotificationsCallCount + notifications.cancelNotificationsCallCount
        XCTAssertEqual(callsAfterDismiss, callsAfterLoad, "dismiss() must not schedule or cancel notifications")
    }
}
