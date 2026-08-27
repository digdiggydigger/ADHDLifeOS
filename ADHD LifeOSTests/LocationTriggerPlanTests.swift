//
//  LocationTriggerPlanTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Which places deserve one of iOS's 20 silent region slots, and with which crossing directions
/// (block 4b). The plan is pure so every gate — the master switch, the Always grant, the
/// per-place toggles, the 20-slot budget — is pinned without CoreLocation.
final class LocationTriggerPlanTests: XCTestCase {

    private func place(
        name: String = "Tesco",
        latitude: Double = 51.5152,
        arrival: Bool = false,
        departure: Bool = false
    ) -> Place {
        Place(
            id: UUID(), name: name,
            coordinate: PlaceCoordinate(latitude: latitude, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnArrival: arrival, nudgeOnDeparture: departure
        )
    }

    // MARK: - The gates

    func testRegions_killSwitchOffPlansNothing() {
        let plan = LocationTriggerPlan.regions(
            places: [place(arrival: true)], around: nil,
            authorization: .always, isEnabled: false
        )

        XCTAssertTrue(plan.isEmpty)
    }

    /// When In Use is NOT enough — regions registered under it deliver only in the foreground,
    /// which defeats an arrival trigger entirely. Registering them anyway would be the silent
    /// failure the permission split exists to prevent.
    func testRegions_whenInUsePlansNothing() {
        let plan = LocationTriggerPlan.regions(
            places: [place(arrival: true)], around: nil,
            authorization: .whenInUse, isEnabled: true
        )

        XCTAssertTrue(plan.isEmpty)
    }

    func testRegions_onlyNudgingPlacesGetASlot() {
        let nudging = place(name: "Tesco", arrival: true)
        let quiet = place(name: "The Park")

        let plan = LocationTriggerPlan.regions(
            places: [quiet, nudging], around: nil,
            authorization: .always, isEnabled: true
        )

        XCTAssertEqual(plan.map(\.placeId), [nudging.id])
    }

    /// The crossing directions mirror the per-place toggles exactly — a departure-only place must
    /// not fire on arrival.
    func testRegions_directionsMirrorTheToggles() {
        let departureOnly = place(arrival: false, departure: true)

        let plan = LocationTriggerPlan.regions(
            places: [departureOnly], around: nil,
            authorization: .always, isEnabled: true
        )

        XCTAssertEqual(plan.first?.notifyOnEntry, false)
        XCTAssertEqual(plan.first?.notifyOnExit, true)
        XCTAssertEqual(plan.first?.radiusMetres, 150)
    }

    /// The 20-slot budget applies to NUDGING places only, nearest first — quiet places must not
    /// crowd out a fence that would actually fire.
    func testRegions_respectsTheRegionBudgetNearestFirst() {
        let here = PlaceCoordinate(latitude: 51.5, longitude: -0.14)
        let nudging = (0..<25).map { index in
            place(name: "P\(index)", latitude: 51.5 + Double(index) * 0.01, arrival: true)
        }

        let plan = LocationTriggerPlan.regions(
            places: nudging.shuffled(), around: here,
            authorization: .always, isEnabled: true
        )

        XCTAssertEqual(plan.count, PlaceGeometry.regionMonitoringLimit)
        // Nearest-first: the 20 lowest latitudes are the 20 nearest to `here`.
        XCTAssertEqual(
            Set(plan.map(\.placeId)),
            Set(nudging.prefix(PlaceGeometry.regionMonitoringLimit).map(\.id))
        )
    }

    // MARK: - Reconcile

    /// Every planned region is (re)started — registering the same identifier REPLACES the region,
    /// which is how a radius or direction edit takes effect — and only regions that fell out of
    /// the plan are stopped.
    func testReconcile_startsThePlanAndStopsOnlyTheStale() {
        let kept = place(arrival: true)
        let stale = UUID()
        let plan = LocationTriggerPlan.regions(
            places: [kept], around: nil, authorization: .always, isEnabled: true
        )

        let actions = LocationTriggerPlan.reconcile(currentIds: [kept.id, stale], planned: plan)

        XCTAssertEqual(actions.start.map(\.placeId), [kept.id])
        XCTAssertEqual(actions.stopIds, [stale])
    }

    // MARK: - The model carries the toggles to Firestore

    func testPlace_encodesTheNudgeTogglesWithTheExpectedSpelling() throws {
        let toggled = place(arrival: true, departure: false)

        let data = try JSONEncoder().encode(toggled)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["nudge_on_arrival"] as? Bool, true)
        XCTAssertEqual(json["nudge_on_departure"] as? Bool, false)
        XCTAssertNil(json["nudgeOnArrival"], "places are snake_cased throughout")
    }

    /// Every place saved before block 4 has neither key: it decodes as a quiet place, never as a
    /// failed document.
    func testPlace_decodesALegacyDocumentAsQuiet() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000009","name":"Tesco","latitude":51.5152,\
        "longitude":-0.1418,"radius_metres":150,"created_at":0}
        """.utf8)

        let decoded = try JSONDecoder().decode(Place.self, from: legacy)

        XCTAssertFalse(decoded.nudgeOnArrival)
        XCTAssertFalse(decoded.nudgeOnDeparture)
        XCTAssertFalse(decoded.anyNudgeEnabled)
    }

    func testPlace_editorPreservesTheTogglesThroughMakePlace() {
        let made = PlaceEditorValidation.makePlace(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnArrival: true, nudgeOnDeparture: true
        )

        XCTAssertEqual(made?.nudgeOnArrival, true)
        XCTAssertEqual(made?.nudgeOnDeparture, true)
    }
}
