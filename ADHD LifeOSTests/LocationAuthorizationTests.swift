//
//  LocationAuthorizationTests.swift
//  ADHD LifeOSTests
//

import CoreLocation
import XCTest
@testable import ADHD_LifeOS

/// What each authorization state actually PERMITS (F-Location-Foundation).
///
/// This exists because the two halves of E's spec need different permissions, and getting that
/// wrong fails silently: tagging where something happened needs only When In Use, while arrival
/// triggering needs Always — both the geofences and the significant-change fallback stop
/// delivering in the background without it. A build that asks for the wrong one, or that
/// registers geofences it can never receive, looks fine and simply never fires.
final class LocationAuthorizationTests: XCTestCase {

    // MARK: - Mapping CoreLocation's status onto ours

    func testState_mapsEveryCoreLocationStatus() {
        XCTAssertEqual(LocationAuthorizationState(status: .notDetermined), .notDetermined)
        XCTAssertEqual(LocationAuthorizationState(status: .denied), .denied)
        XCTAssertEqual(LocationAuthorizationState(status: .restricted), .restricted)
        XCTAssertEqual(LocationAuthorizationState(status: .authorizedWhenInUse), .whenInUse)
        XCTAssertEqual(LocationAuthorizationState(status: .authorizedAlways), .always)
    }

    // MARK: - Tagging (the "where did this happen" half)

    func testTagging_needsWhenInUseOrBetter() {
        XCTAssertFalse(LocationAuthorizationState.notDetermined.allowsTagging)
        XCTAssertFalse(LocationAuthorizationState.denied.allowsTagging)
        XCTAssertFalse(LocationAuthorizationState.restricted.allowsTagging)
        XCTAssertTrue(LocationAuthorizationState.whenInUse.allowsTagging)
        XCTAssertTrue(LocationAuthorizationState.always.allowsTagging)
    }

    // MARK: - Triggering (the "tell me when I arrive" half)

    /// The trap this pins down: When In Use is NOT enough. Geofences registered under it deliver
    /// only while the app is foregrounded, which defeats the entire point of an arrival trigger.
    func testTriggering_needsAlways_whenInUseIsNotEnough() {
        XCTAssertFalse(LocationAuthorizationState.whenInUse.allowsTriggering)
        XCTAssertTrue(LocationAuthorizationState.always.allowsTriggering)
    }

    func testTriggering_isDeniedForEveryUnauthorizedState() {
        XCTAssertFalse(LocationAuthorizationState.notDetermined.allowsTriggering)
        XCTAssertFalse(LocationAuthorizationState.denied.allowsTriggering)
        XCTAssertFalse(LocationAuthorizationState.restricted.allowsTriggering)
    }

    /// The significant-change fallback rides the same permission as the geofences it backstops.
    func testBackgroundWake_matchesTriggering() {
        for state in LocationAuthorizationState.allCases {
            XCTAssertEqual(
                state.allowsBackgroundWake,
                state.allowsTriggering,
                "\(state) disagrees — the fallback and the geofences must need the same grant"
            )
        }
    }

    // MARK: - What to ask for, and when

    /// Never ask for Always up front. iOS shows a weaker prompt and users decline it far more
    /// often; the supported path is When In Use first, then escalate once the feature is in use.
    func testRequest_fromNotDetermined_asksForWhenInUseFirst() {
        XCTAssertEqual(LocationAuthorizationState.notDetermined.nextRequest(wantsTriggering: true), .whenInUse)
        XCTAssertEqual(LocationAuthorizationState.notDetermined.nextRequest(wantsTriggering: false), .whenInUse)
    }

    func testRequest_fromWhenInUse_escalatesOnlyWhenTriggeringIsWanted() {
        XCTAssertEqual(LocationAuthorizationState.whenInUse.nextRequest(wantsTriggering: true), .always)
        XCTAssertNil(LocationAuthorizationState.whenInUse.nextRequest(wantsTriggering: false))
    }

    /// Nothing left to ask for: already granted, or the OS will not show a prompt again.
    func testRequest_isNilWhenThereIsNothingLeftToAsk() {
        XCTAssertNil(LocationAuthorizationState.always.nextRequest(wantsTriggering: true))
        XCTAssertNil(LocationAuthorizationState.denied.nextRequest(wantsTriggering: true))
        XCTAssertNil(LocationAuthorizationState.restricted.nextRequest(wantsTriggering: true))
    }

    /// A denied user can only be helped by Settings — re-prompting does nothing at all.
    func testSettingsIsTheOnlyRouteBack_whenDeniedOrRestricted() {
        XCTAssertTrue(LocationAuthorizationState.denied.requiresSettingsTrip)
        XCTAssertTrue(LocationAuthorizationState.restricted.requiresSettingsTrip)
        XCTAssertFalse(LocationAuthorizationState.notDetermined.requiresSettingsTrip)
        XCTAssertFalse(LocationAuthorizationState.whenInUse.requiresSettingsTrip)
        XCTAssertFalse(LocationAuthorizationState.always.requiresSettingsTrip)
    }
}
