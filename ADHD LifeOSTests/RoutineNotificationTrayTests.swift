//
//  RoutineNotificationTrayTests.swift
//  ADHD LifeOSTests
//
//  Found by the routine-record journey (F-RoutineRecord-2): a routine banner in the tray
//  OUTLIVES the session that posted it. Sign out, sign in as someone else, tap it, and the
//  routine STARTS under the new account — its place, its steps — while every record write fails
//  against a document the new account never had. The same family as the run-store leak, one
//  layer out: the tray is app-local state that carries one user's places too.
//

import XCTest
@testable import ADHD_LifeOS

final class RoutineNotificationTrayTests: XCTestCase {

    func testIdentifiersToClear_areTheRoutineBannersAlone() {
        let routine = PlaceRoutineNotificationContent.identifier(placeId: UUID(), kind: .arrival)
        let departure = PlaceRoutineNotificationContent.identifier(placeId: UUID(), kind: .departure)
        let delivered = [
            "focusCheckpoint-1", routine, "placeAction-\(UUID().uuidString)", departure, "arrivalNudge-x-arrival"
        ]

        XCTAssertEqual(
            RoutineNotificationTray.identifiersToClear(from: delivered), [routine, departure],
            "only the routine species is a door into another account's routine; a task nudge"
                + " or a place-action banner is inert under a new session"
        )
    }

    func testIdentifiersToClear_withNothingDelivered_isEmpty() {
        XCTAssertTrue(RoutineNotificationTray.identifiersToClear(from: []).isEmpty)
    }
}
