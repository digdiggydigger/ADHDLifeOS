//
//  NotificationPermissionStateTests.swift
//  ADHD LifeOSTests
//

import UserNotifications
import XCTest
@testable import ADHD_LifeOS

/// Pure-mapping tests for `NotificationPermissionState`. No `UNUserNotificationCenter` is ever
/// touched — only the `UNAuthorizationStatus` → state mapping and the state's user-facing
/// `displayText`/icon, matching the `CaptureRowPresentation` precedent of unit-testing the pure
/// presentation seam while leaving the real notification-center adapter untested.
final class NotificationPermissionStateTests: XCTestCase {

    // MARK: - UNAuthorizationStatus mapping

    func testMapping_authorized() {
        XCTAssertEqual(NotificationPermissionState(authorizationStatus: .authorized), .authorized)
    }

    func testMapping_provisional() {
        XCTAssertEqual(NotificationPermissionState(authorizationStatus: .provisional), .provisional)
    }

    func testMapping_ephemeral() {
        XCTAssertEqual(NotificationPermissionState(authorizationStatus: .ephemeral), .ephemeral)
    }

    func testMapping_notDetermined() {
        XCTAssertEqual(NotificationPermissionState(authorizationStatus: .notDetermined), .notDetermined)
    }

    func testMapping_denied() {
        XCTAssertEqual(NotificationPermissionState(authorizationStatus: .denied), .denied)
    }

    /// The mapping never fabricates a `.unknown`: that case exists only for the view's pre-read
    /// loading state and must not come out of an actual authorization-status read.
    func testMapping_neverReturnsUnknown() {
        let statuses: [UNAuthorizationStatus] = [.authorized, .provisional, .ephemeral, .notDetermined, .denied]
        for status in statuses {
            XCTAssertNotEqual(NotificationPermissionState(authorizationStatus: status), .unknown)
        }
    }

    // MARK: - displayText

    func testDisplayText_unknown() {
        XCTAssertEqual(NotificationPermissionState.unknown.displayText, "Checking…")
    }

    func testDisplayText_authorized() {
        XCTAssertEqual(NotificationPermissionState.authorized.displayText, "Allowed")
    }

    func testDisplayText_provisional() {
        XCTAssertEqual(NotificationPermissionState.provisional.displayText, "Allowed (Quiet)")
    }

    func testDisplayText_ephemeral() {
        XCTAssertEqual(NotificationPermissionState.ephemeral.displayText, "Allowed (Temporary)")
    }

    func testDisplayText_notDetermined() {
        XCTAssertEqual(NotificationPermissionState.notDetermined.displayText, "Not requested yet")
    }

    func testDisplayText_denied() {
        XCTAssertEqual(NotificationPermissionState.denied.displayText, "Turned off")
    }

    // MARK: - iconSystemImageName

    func testIconSystemImageName_isNonEmptyForEveryState() {
        let states: [NotificationPermissionState] = [
            .unknown, .authorized, .provisional, .ephemeral, .notDetermined, .denied
        ]
        for state in states {
            XCTAssertFalse(state.iconSystemImageName.isEmpty, "\(state) must have a non-empty SF Symbol name")
        }
    }

    func testIconSystemImageName_authorizedUsesFilledCheckmark() {
        XCTAssertEqual(NotificationPermissionState.authorized.iconSystemImageName, "checkmark.circle.fill")
    }

    func testIconSystemImageName_deniedUsesFilledCross() {
        XCTAssertEqual(NotificationPermissionState.denied.iconSystemImageName, "xmark.circle.fill")
    }

    func testIconSystemImageName_notDeterminedUsesQuestionMark() {
        XCTAssertEqual(NotificationPermissionState.notDetermined.iconSystemImageName, "questionmark.circle")
    }
}
