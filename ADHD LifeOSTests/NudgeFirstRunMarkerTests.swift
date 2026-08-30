//
//  NudgeFirstRunMarkerTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The per-ACCOUNT flag behind the first-run nudges door.
///
/// Written after the device-scoped first attempt was caught: a plain `@AppStorage` key meant the
/// second account signed into a phone inherited the first account's answer, so a genuinely new
/// user would never see their first-run door — reintroducing the exact dead end
/// F-FirstNudgeReachable removed, one layer up. The isolation test below is the whole point of
/// this type existing.
final class NudgeFirstRunMarkerTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "NudgeFirstRunMarkerTests"

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    func testUnknownAccount_hasNotHadNudges() {
        XCTAssertFalse(NudgeFirstRunMarker.hasEverHadNudges(uid: "alice", in: defaults))
    }

    func testMarking_persistsForThatAccount() {
        NudgeFirstRunMarker.markHasHadNudges(uid: "alice", in: defaults)

        XCTAssertTrue(NudgeFirstRunMarker.hasEverHadNudges(uid: "alice", in: defaults))
    }

    /// **The reason this type exists.** Two accounts on one device must not share an answer — the
    /// device-scoped version failed exactly here, and it fails silently in the harmful direction:
    /// it SUPPRESSES a new user's door rather than showing a spare one.
    func testTwoAccountsOnOneDevice_doNotShareAnAnswer() {
        NudgeFirstRunMarker.markHasHadNudges(uid: "alice", in: defaults)

        XCTAssertTrue(NudgeFirstRunMarker.hasEverHadNudges(uid: "alice", in: defaults))
        XCTAssertFalse(
            NudgeFirstRunMarker.hasEverHadNudges(uid: "bob", in: defaults),
            "A second account inherited the first account's flag, so a genuinely new user would"
                + " never see the first-run door — the dead end this whole feature removed."
        )
    }

    /// Marking twice is not a state change — the door is gone either way, and a caller should not
    /// have to check before writing.
    func testMarkingTwice_isStable() {
        NudgeFirstRunMarker.markHasHadNudges(uid: "alice", in: defaults)
        NudgeFirstRunMarker.markHasHadNudges(uid: "alice", in: defaults)

        XCTAssertTrue(NudgeFirstRunMarker.hasEverHadNudges(uid: "alice", in: defaults))
    }

    /// The key is namespaced and carries the uid, so it cannot collide with the old device-wide
    /// key or with another feature's flag.
    func testKey_isNamespacedPerAccount() {
        XCTAssertEqual(NudgeFirstRunMarker.key(for: "alice"), "nudges.hasEverHadAny.alice")
        XCTAssertNotEqual(NudgeFirstRunMarker.key(for: "alice"), NudgeFirstRunMarker.key(for: "bob"))
    }
}
