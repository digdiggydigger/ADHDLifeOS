//
//  CaptureLocationStampTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// That the stamp actually reaches the written capture (F-Location-Tagging).
///
/// `LocationStampingTests` proves the stamp is computed correctly; this proves it is not dropped
/// on the floor between the service and the document. That gap is exactly the kind of thing that
/// fails silently — captures keep saving perfectly, and the location is simply never there.
///
/// The other half of the contract, and the more important one: a stamp must never be able to
/// BLOCK a capture. Location is a bonus on a thought that has already been had.
@MainActor
final class CaptureLocationStampTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private func service(
        _ fake: FakeCaptureClientAdapting,
        stamp: LocationStamp?
    ) -> CaptureInboxService {
        CaptureInboxService(client: fake, locationStamp: { stamp })
    }

    func testCreate_carriesTheStampIntoTheWrite() async {
        let fake = FakeCaptureClientAdapting()
        let placeId = UUID()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: placeId))
        sut.content = "Buy milk"

        let created = await sut.createCapture()

        XCTAssertTrue(created)
        XCTAssertEqual(fake.lastCreateCaptureInput?.locationStamp?.coordinate, coordinate)
        XCTAssertEqual(fake.lastCreateCaptureInput?.locationStamp?.placeId, placeId)
    }

    /// Outside every named place the coordinate still travels — "where was I when I thought of
    /// this" is the point, and most thoughts happen away from a saved place.
    func testCreate_withNoMatchingPlace_stillCarriesTheCoordinate() async {
        let fake = FakeCaptureClientAdapting()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: nil))
        sut.content = "Buy milk"

        _ = await sut.createCapture()

        XCTAssertEqual(fake.lastCreateCaptureInput?.locationStamp?.coordinate, coordinate)
        XCTAssertNil(fake.lastCreateCaptureInput?.locationStamp?.placeId)
    }

    // MARK: - The stamp must never block a capture

    /// Tagging off, permission absent, no fix, airplane mode — all arrive here as `nil`, and the
    /// capture must save exactly as it would have. This is the single most important assertion in
    /// the block: a location lookup must never be the reason a thought doesn't get written down.
    func testCreate_withNoStamp_stillSavesTheCapture() async {
        let fake = FakeCaptureClientAdapting()
        let sut = service(fake, stamp: nil)
        sut.content = "Buy milk"

        let created = await sut.createCapture()

        XCTAssertTrue(created, "a missing stamp must never fail a capture")
        XCTAssertEqual(fake.createCaptureCallCount, 1)
        XCTAssertNil(fake.lastCreateCaptureInput?.locationStamp)
        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "Buy milk")
    }

    /// The stamp is additive only: everything else about the capture is unchanged by its presence.
    func testCreate_withAStamp_leavesEveryOtherFieldAlone() async {
        let fake = FakeCaptureClientAdapting()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: nil))
        sut.content = "Buy milk"
        sut.kind = .note

        _ = await sut.createCapture()

        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "Buy milk")
        XCTAssertEqual(fake.lastCreateCaptureInput?.kind, .note)
    }

    /// An invalid capture is still refused, and refused BEFORE a fix is taken — there is no point
    /// spending a GPS request on something that is not going to be written.
    func testCreate_withInvalidContent_isStillRefused() async {
        let fake = FakeCaptureClientAdapting()
        var stampRequests = 0
        let sut = CaptureInboxService(client: fake, locationStamp: {
            stampRequests += 1
            return nil
        })
        sut.content = "   "

        let created = await sut.createCapture()

        XCTAssertFalse(created)
        XCTAssertEqual(fake.createCaptureCallCount, 0)
        XCTAssertEqual(stampRequests, 0, "validation must fail before a fix is requested")
    }

    // MARK: - The model carries it to Firestore

    /// The capture convention is camelCase apart from `created_at`/`tag_ids`, so these three are
    /// camelCase. Asserted because hand-written Firestore payloads are not derived from `Codable`
    /// — a wrong key writes a field nothing reads, and raises nothing.
    func testCapture_encodesTheLocationFieldsWithTheExpectedSpelling() throws {
        let capture = Capture(
            id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date(),
            placeId: UUID(), latitude: 51.5152, longitude: -0.1418
        )

        let data = try JSONEncoder().encode(capture)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNotNil(json["placeId"])
        XCTAssertEqual(json["latitude"] as? Double, 51.5152)
        XCTAssertEqual(json["longitude"] as? Double, -0.1418)
        XCTAssertNil(json["place_id"], "the snake_case spelling must NOT be written")
    }

    /// Every capture written before this shipped has none of these fields; they must decode as
    /// absent rather than failing the whole document.
    func testCapture_decodesADocumentWithNoLocationFields() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000003","content":"Buy milk","kind":"note",\
        "processed":false,"created_at":0}
        """.utf8)

        let decoded = try JSONDecoder().decode(Capture.self, from: legacy)

        XCTAssertNil(decoded.placeId)
        XCTAssertNil(decoded.latitude)
        XCTAssertNil(decoded.longitude)
        XCTAssertEqual(decoded.content, "Buy milk")
    }
}
