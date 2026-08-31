//
//  JournalLocationStampTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// That the stamp actually reaches the written journal entry (block 3 remainder) — the
/// `CaptureLocationStampTests` contract, applied to logs: the stamp is carried, it never blocks
/// a write, and validation fails before a fix is ever requested.
@MainActor
final class JournalLocationStampTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private func service(_ fake: FakeJournalClientAdapting, stamp: LocationStamp?) -> JournalService {
        JournalService(client: fake, locationStamp: { stamp })
    }

    func testCreateLog_carriesTheStampIntoTheWrite() async {
        let fake = FakeJournalClientAdapting()
        let placeId = UUID()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: placeId))
        sut.composerBody = "Slept badly, still shipped"
        sut.composerAttachLocation = true

        let created = await sut.createLog()

        XCTAssertTrue(created)
        XCTAssertEqual(fake.lastCreateLogInput?.locationStamp?.coordinate, coordinate)
        XCTAssertEqual(fake.lastCreateLogInput?.locationStamp?.placeId, placeId)
    }

    /// A quick `.log` stamps exactly like a `.journal` entry. Energy and mood are journal-only
    /// because the web put them on `JournalEntry` alone; location has no web precedent to
    /// preserve, and "where was I" applies to both kinds of entry equally.
    func testCreateLog_quickLogCarriesTheStampToo() async {
        let fake = FakeJournalClientAdapting()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: nil))
        sut.composerBody = "Quick note"
        sut.composerType = .log
        sut.composerAttachLocation = true

        _ = await sut.createLog()

        XCTAssertEqual(fake.lastCreateLogInput?.type, .log)
        XCTAssertEqual(fake.lastCreateLogInput?.locationStamp?.coordinate, coordinate)
    }

    /// Tagging off, permission absent, no fix — all arrive here as `nil`, and the entry must
    /// save exactly as it would have. A location lookup must never be why a thought doesn't get
    /// written down.
    func testCreateLog_withNoStamp_stillSavesTheEntry() async {
        let fake = FakeJournalClientAdapting()
        let sut = service(fake, stamp: nil)
        sut.composerBody = "Slept badly, still shipped"
        sut.composerAttachLocation = true

        let created = await sut.createLog()

        XCTAssertTrue(created, "a missing stamp must never fail an entry")
        XCTAssertEqual(fake.createLogCallCount, 1)
        XCTAssertNil(fake.lastCreateLogInput?.locationStamp)
        XCTAssertEqual(fake.lastCreateLogInput?.body, "Slept badly, still shipped")
    }

    /// An empty body is still refused, and refused BEFORE a fix is taken — no GPS request for
    /// something that is not going to be written.
    func testCreateLog_withInvalidBody_isStillRefused() async {
        let fake = FakeJournalClientAdapting()
        var stampRequests = 0
        let sut = JournalService(client: fake, locationStamp: {
            stampRequests += 1
            return nil
        })
        sut.composerBody = "   "
        sut.composerAttachLocation = true

        let created = await sut.createLog()

        XCTAssertFalse(created)
        XCTAssertEqual(fake.createLogCallCount, 0)
        XCTAssertEqual(stampRequests, 0, "validation must fail before a fix is requested")
    }

    // MARK: - The per-entry switch (E, 2026-08-31: the captures rule, applied to the composer)

    /// The composer's switch is now the gate, exactly as `CaptureInboxService.attachLocation` is
    /// for captures. Off means OFF: no stamp on the write, and no fix even requested — a control
    /// that says "won't record where you made it" while a fix is quietly taken would be lying.
    func testCreateLog_withLocationChoiceOff_requestsNoFixAndCarriesNoStamp() async {
        let fake = FakeJournalClientAdapting()
        var stampRequests = 0
        let sut = JournalService(client: fake, locationStamp: {
            stampRequests += 1
            return LocationStamp(coordinate: self.coordinate, placeId: UUID())
        })
        sut.composerBody = "Slept badly, still shipped"
        sut.composerAttachLocation = false

        let created = await sut.createLog()

        XCTAssertTrue(created, "declining location must never fail the entry")
        XCTAssertEqual(stampRequests, 0, "off must not cost a fix, let alone record one")
        XCTAssertNil(fake.lastCreateLogInput?.locationStamp)
    }

    // MARK: - The composer's preview ("show me where this will say I was")

    func testRefreshComposerLocationPreview_whenChoiceIsOff_staysEmpty() async {
        let fake = FakeJournalClientAdapting()
        var stampRequests = 0
        let sut = JournalService(client: fake, locationStamp: {
            stampRequests += 1
            return LocationStamp(coordinate: self.coordinate, placeId: UUID())
        })
        sut.composerAttachLocation = false

        await sut.refreshComposerLocationPreview()

        XCTAssertNil(sut.composerLocationPreview)
        XCTAssertEqual(stampRequests, 0, "an off switch must not cost a fix")
    }

    func testRefreshComposerLocationPreview_whenChoiceIsOn_takesAStamp() async {
        let fake = FakeJournalClientAdapting()
        let placeId = UUID()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: placeId))
        sut.composerAttachLocation = true

        await sut.refreshComposerLocationPreview()

        XCTAssertEqual(sut.composerLocationPreview?.placeId, placeId)
    }

    /// Toggling off after a preview was taken must also clear it — a lingering "at the Office"
    /// under a switch that now says "won't record" would contradict the switch.
    func testRefreshComposerLocationPreview_turningOffClearsAnEarlierPreview() async {
        let fake = FakeJournalClientAdapting()
        let sut = service(fake, stamp: LocationStamp(coordinate: coordinate, placeId: UUID()))
        sut.composerAttachLocation = true
        await sut.refreshComposerLocationPreview()
        XCTAssertNotNil(sut.composerLocationPreview)

        sut.composerAttachLocation = false
        await sut.refreshComposerLocationPreview()

        XCTAssertNil(sut.composerLocationPreview)
    }

    // MARK: - The adapter carries it onto the document

    /// The stamp must not be dropped between the normalized input and the appended `Log` — the
    /// gap that fails silently, because entries keep saving perfectly without it.
    func testAdapter_createLog_mapsTheStampOntoTheAppendedLog() async throws {
        let store = FakeJournalBackingStore()
        let adapter = FirebaseJournalClientAdapter(store: store)
        let placeId = UUID()
        var input = NormalizedCreateLogInput(body: "Body", type: .journal, lifeAreaId: nil)
        input.locationStamp = LocationStamp(coordinate: coordinate, placeId: placeId)

        let created = try await adapter.createLog(input)

        XCTAssertEqual(created.placeId, placeId)
        XCTAssertEqual(created.latitude, coordinate.latitude)
        XCTAssertEqual(created.longitude, coordinate.longitude)
        XCTAssertEqual(store.appendedLogs.first?.placeId, placeId)
        XCTAssertEqual(store.appendedLogs.first?.latitude, coordinate.latitude)
        XCTAssertEqual(store.appendedLogs.first?.longitude, coordinate.longitude)
    }

    // MARK: - The model carries it to Firestore

    /// Logs are snake_cased throughout, so `place_id` — not the camelCase spelling captures use.
    /// Asserted both ways because a wrong key writes a field nothing reads, and raises nothing.
    func testLog_encodesTheLocationFieldsWithTheExpectedSpelling() throws {
        let log = Log(
            id: UUID(), lifeAreaId: nil, type: .journal, body: "Body",
            entryDate: Date(), createdAt: Date(),
            placeId: UUID(), latitude: 51.5152, longitude: -0.1418
        )

        let data = try JSONEncoder().encode(log)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNotNil(json["place_id"])
        XCTAssertEqual(json["latitude"] as? Double, 51.5152)
        XCTAssertEqual(json["longitude"] as? Double, -0.1418)
        XCTAssertNil(json["placeId"], "the camelCase spelling belongs to captures, not logs")
    }

    /// Every entry written before this shipped has none of these fields; they must decode as
    /// absent rather than failing the whole document — one bad decode would empty the journal.
    func testLog_decodesADocumentWithNoLocationFields() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000004","type":"journal","body":"Body",\
        "entry_date":0,"created_at":0}
        """.utf8)

        let decoded = try JSONDecoder().decode(Log.self, from: legacy)

        XCTAssertNil(decoded.placeId)
        XCTAssertNil(decoded.latitude)
        XCTAssertNil(decoded.longitude)
        XCTAssertEqual(decoded.body, "Body")
    }
}
