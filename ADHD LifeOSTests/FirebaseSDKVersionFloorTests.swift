//
//  FirebaseSDKVersionFloorTests.swift
//  ADHD LifeOSTests
//
//  A source-read pin on the Firebase SDK version, and the only kind of test that can hold this
//  claim: the bug it guards is in the SDK's own keychain handling, so no test over this app's
//  values can reach it, and the unit-test target deliberately does not link Firebase at all.
//
//  WHY THE FLOOR EXISTS. firebase-ios-sdk 12.19.0 fixed silent random sign-outs
//  (https://github.com/firebase/firebase-ios-sdk/pull/16505). On a locked device iOS 15+ can
//  return `errSecItemNotFound` from `SecItemCopyMatching` where it means
//  `errSecInteractionNotAllowed`; FirebaseAuth trusted that and wiped the signed-in user.
//  Reporters measured ~1% of recently active users losing their session.
//
//  THIS APP WAS MAXIMALLY EXPOSED. Session restore is a single `currentUser` read
//  (`FirebaseAuthClientAdapter.swift` -> `FirebaseManager.currentUser`) with NO
//  `addStateDidChangeListener` fallback, so one spurious nil lands the user in `.signedOut`.
//  A downgrade below 12.19.1 silently reintroduces that, and nothing else in this suite notices.
//
//  12.18.0 IS DELIBERATELY EXCLUDED as well as everything older: it shipped an app-extension
//  regression (`UIApplication.shared`, firebase-ios-sdk#16583) that 12.19.0 reversed.
//

import XCTest

final class FirebaseSDKVersionFloorTests: XCTestCase {

    /// The lowest Firebase that carries the keychain fix. Raising this is fine; lowering it is
    /// the thing this test exists to stop.
    private static let floor = SemanticVersion(12, 19, 1)

    /// The version that actually ships — `Package.resolved` is what the build resolves to.
    func testTheResolvedFirebaseCarriesTheKeychainLogoutFix() throws {
        let resolved = try Self.repoFile(
            "ADHD LifeOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        )
        let version = try XCTUnwrap(
            Self.resolvedVersion(of: "firebase-ios-sdk", in: resolved),
            "firebase-ios-sdk is not pinned in Package.resolved at all"
        )

        XCTAssertGreaterThanOrEqual(
            version, Self.floor,
            "firebase-ios-sdk is \(version.text), below \(Self.floor.text). Versions before"
                + " 12.19.0 sign users out at random when the device is locked"
                + " (firebase-ios-sdk#16505), and this app has no listener fallback to recover."
        )
    }

    /// The SPM requirement is `upToNextMajorVersion`, so a resolve takes the newest 12.x on its
    /// own. That is exactly why the FLOOR has to be declared too: without it, a
    /// `Package.resolved` reset or a fresh clone can legally land on 12.0.0.
    func testThePackageRequirementCannotResolveBelowTheFix() throws {
        let project = try Self.repoFile("ADHD LifeOS.xcodeproj/project.pbxproj")
        let declared = try XCTUnwrap(
            Self.minimumVersionForFirebase(in: project),
            "no minimumVersion found for the firebase-ios-sdk package reference"
        )

        XCTAssertGreaterThanOrEqual(
            declared, Self.floor,
            "the project declares minimumVersion \(declared.text). A clean resolve could pick"
                + " anything from there upwards, including versions with the sign-out bug."
        )
    }

    /// The control. A string comparison would rank "12.9.0" ABOVE "12.19.1" and this whole file
    /// would pass while sitting on a broken version, so the ordering is asserted directly.
    func testVersionsAreComparedNumericallyRatherThanAsText() {
        XCTAssertLessThan(SemanticVersion(12, 9, 0), SemanticVersion(12, 19, 1))
        XCTAssertLessThan(SemanticVersion(12, 18, 0), SemanticVersion(12, 19, 1))
        XCTAssertLessThan(SemanticVersion(12, 19, 0), SemanticVersion(12, 19, 1))
        XCTAssertGreaterThan(SemanticVersion(12, 20, 0), SemanticVersion(12, 19, 1))
        XCTAssertGreaterThan(SemanticVersion(13, 0, 0), SemanticVersion(12, 19, 1))
        XCTAssertEqual(SemanticVersion(12, 19, 1), SemanticVersion(12, 19, 1))
        XCTAssertTrue("12.9.0" > "12.19.1", "the trap this test is the control for")
    }

    // MARK: - Reading

    private static func resolvedVersion(of identity: String, in json: String) -> SemanticVersion? {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pins = root["pins"] as? [[String: Any]] else { return nil }
        for pin in pins where pin["identity"] as? String == identity {
            guard let state = pin["state"] as? [String: Any],
                  let version = state["version"] as? String else { return nil }
            return SemanticVersion(version)
        }
        return nil
    }

    /// Reads the `minimumVersion` from the XCRemoteSwiftPackageReference whose location is the
    /// firebase repo, rather than the first one in the file.
    private static func minimumVersionForFirebase(in pbxproj: String) -> SemanticVersion? {
        guard let anchor = pbxproj.range(of: "firebase/firebase-ios-sdk") else { return nil }
        let tail = pbxproj[anchor.upperBound...]
        guard let key = tail.range(of: "minimumVersion = ") else { return nil }
        let rest = tail[key.upperBound...]
        guard let end = rest.firstIndex(of: ";") else { return nil }
        return SemanticVersion(String(rest[rest.startIndex..<end])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func repoFile(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw NSError(domain: "FirebaseSDKVersionFloorTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not read \(url.path)."
            ])
        }
        return text
    }
}

/// Dotted version with numeric ordering. Local to this file — nothing else needs it.
struct SemanticVersion: Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(_ text: String) {
        let parts = text.split(separator: ".").map(String.init)
        guard (1...3).contains(parts.count) else { return nil }
        let numbers = parts.compactMap(Int.init)
        guard numbers.count == parts.count else { return nil }
        major = numbers[0]
        minor = numbers.count > 1 ? numbers[1] : 0
        patch = numbers.count > 2 ? numbers[2] : 0
    }

    var text: String { "\(major).\(minor).\(patch)" }
    var description: String { text }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
