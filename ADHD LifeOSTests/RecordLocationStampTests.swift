//
//  RecordLocationStampTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The enabled-gate for records with no per-record switch (journal entries, closed tasks,
/// finished sprints — block 3's remainder). `LocationStampingTests` proves the stamp maths;
/// each service's own tests prove the stamp reaches its write. This covers the one piece in
/// between that is new: the global Settings toggle is the gate again, and "off" must mean no
/// work at all.
@MainActor
final class RecordLocationStampTests: XCTestCase {

    private final class RecordingPlacesClient: PlacesClientAdapting {
        private(set) var fetchCount = 0

        func fetchPlaces() async throws -> [Place] {
            fetchCount += 1
            return []
        }

        func savePlace(_ place: Place) async throws {}
        func deletePlace(id: UUID) async throws {}
    }

    /// Toggle off: no stamp, and no work either — not a places fetch, not a fix request. The
    /// gate is checked FIRST because it is the cheapest of the three, and a disabled preference
    /// must not cost a Firestore read to honour.
    func testCurrent_withTaggingDisabled_takesNoStampAndDoesNoWork() async {
        let places = RecordingPlacesClient()

        let stamp = await RecordLocationStamp.current(places: places, isEnabled: { false })

        XCTAssertNil(stamp)
        XCTAssertEqual(places.fetchCount, 0, "off must mean no fix is even attempted")
    }
}
