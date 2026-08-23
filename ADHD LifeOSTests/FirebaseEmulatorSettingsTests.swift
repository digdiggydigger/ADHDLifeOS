//
//  FirebaseEmulatorSettingsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The failure mode this type exists to prevent is not "the emulator is misconfigured" — it is
/// "the emulator is silently NOT configured, so a destructive test runs against E's real
/// Firestore". `FirebaseManager+AccountDeletion` erases every document the signed-in user owns;
/// pointed at production by accident it would do exactly that, irreversibly.
///
/// So the contract is deliberately unforgiving: emulator mode activates only on an explicit,
/// well-formed host, and ANY malformed input resolves to `nil` (off) rather than falling back to
/// a default. A silent fallback is the dangerous direction — a typo'd port that quietly became
/// 8080 would connect to the wrong emulator, and a typo'd host that quietly became "off" is at
/// least caught by the harness's positive-proof assertion before anything is deleted.
final class FirebaseEmulatorSettingsTests: XCTestCase {
    private let hostKey = "LIFEOS_FIREBASE_EMULATOR_HOST"
    private let authKey = "LIFEOS_FIREBASE_EMULATOR_AUTH_PORT"
    private let firestoreKey = "LIFEOS_FIREBASE_EMULATOR_FIRESTORE_PORT"
    private let storageKey = "LIFEOS_FIREBASE_EMULATOR_STORAGE_PORT"

    // MARK: - Off by default

    /// The production path. An app launched normally has none of these variables, and must not
    /// end up pointed at a loopback address that isn't listening.
    func testResolve_withNoVariables_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [:]))
    }

    func testResolve_withEmptyHost_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: ""]))
    }

    /// A host of only whitespace is a misconfiguration, not a request — trimming it to "" and
    /// then treating "" as a valid host would produce an unusable `":8080"`.
    func testResolve_withWhitespaceOnlyHost_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: "   "]))
    }

    /// Ports alone never activate it. Emulator mode is opt-in on the host specifically, so a
    /// stray port variable left in a scheme cannot switch a production build over.
    func testResolve_withPortsButNoHost_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [firestoreKey: "8080", authKey: "9099"]))
    }

    // MARK: - On, with the Firebase default ports

    func testResolve_withHostOnly_usesFirebaseDefaultPorts() throws {
        let settings = try XCTUnwrap(FirebaseEmulatorSettings.resolve(from: [hostKey: "127.0.0.1"]))

        XCTAssertEqual(settings.host, "127.0.0.1")
        XCTAssertEqual(settings.authPort, 9099)
        XCTAssertEqual(settings.firestorePort, 8080)
        XCTAssertEqual(settings.storagePort, 9199)
    }

    func testResolve_trimsSurroundingWhitespaceFromHost() throws {
        let settings = try XCTUnwrap(FirebaseEmulatorSettings.resolve(from: [hostKey: "  localhost \n"]))

        XCTAssertEqual(settings.host, "localhost")
    }

    func testResolve_overridesEachPortIndependently() throws {
        let settings = try XCTUnwrap(FirebaseEmulatorSettings.resolve(from: [
            hostKey: "127.0.0.1",
            authKey: "19099",
            firestoreKey: "18080",
            storageKey: "19199"
        ]))

        XCTAssertEqual(settings.authPort, 19099)
        XCTAssertEqual(settings.firestorePort, 18080)
        XCTAssertEqual(settings.storagePort, 19199)
    }

    /// One override does not disturb the others — the defaults still apply to the ports the
    /// caller did not mention.
    func testResolve_withOnlyOnePortOverridden_leavesTheOthersAtTheirDefaults() throws {
        let settings = try XCTUnwrap(FirebaseEmulatorSettings.resolve(from: [
            hostKey: "127.0.0.1",
            firestoreKey: "18080"
        ]))

        XCTAssertEqual(settings.firestorePort, 18080)
        XCTAssertEqual(settings.authPort, 9099)
        XCTAssertEqual(settings.storagePort, 9199)
    }

    // MARK: - Malformed ports refuse rather than fall back

    /// The whole point: a bad port must NOT quietly become the default. Connecting to the
    /// default when the author asked for something else is how a test ends up talking to a
    /// different database than the one it thinks it is talking to.
    func testResolve_withNonNumericPort_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: "127.0.0.1", firestoreKey: "eight-oh-eight-oh"]))
    }

    func testResolve_withZeroPort_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: "127.0.0.1", authKey: "0"]))
    }

    func testResolve_withNegativePort_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: "127.0.0.1", storageKey: "-1"]))
    }

    func testResolve_withPortAbove65535_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: "127.0.0.1", firestoreKey: "65536"]))
    }

    /// An empty port variable is malformed input, not an absent one — a scheme that sets the key
    /// to "" meant to set a port and failed, and that deserves the refusal rather than a default.
    func testResolve_withEmptyPortValue_isOff() {
        XCTAssertNil(FirebaseEmulatorSettings.resolve(from: [hostKey: "127.0.0.1", authKey: ""]))
    }

    // MARK: - The Firestore host string

    /// Firestore takes `host:port` as one string (unlike Auth and Storage, which take them
    /// separately), so the joining happens here rather than at each call site.
    func testFirestoreHost_joinsHostAndPort() throws {
        let settings = try XCTUnwrap(FirebaseEmulatorSettings.resolve(from: [
            hostKey: "127.0.0.1",
            firestoreKey: "18080"
        ]))

        XCTAssertEqual(settings.firestoreHost, "127.0.0.1:18080")
    }
}
