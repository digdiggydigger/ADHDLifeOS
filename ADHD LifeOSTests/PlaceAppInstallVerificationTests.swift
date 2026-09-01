//
//  PlaceAppInstallVerificationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Config-time install verification (F-AppDirectory-3-Verify).
///
/// The whole block leans on one iOS fact: `canOpenURL` on an UNDECLARED scheme returns `false`
/// indistinguishably from "not installed" — so the three-state verdict is decided BEFORE the
/// call, and for an undeclared scheme `canOpen` is never consulted at all (the tripwire test).
/// `LSApplicationQueriesSchemes` caps at 50 per build and is compile-time only, which is why
/// the declared list is a curated SUBSET of the directory, pinned against the built product's
/// own Info.plist.
final class PlaceAppInstallVerificationTests: XCTestCase {

    // MARK: - The declared list

    func testDeclared_staysWellUnderTheFiftyCap() {
        XCTAssertLessThanOrEqual(
            PlaceQueryableSchemes.declared.count, 45,
            "headroom under iOS's 50-scheme cap is deliberate — a future need must not evict"
        )
        XCTAssertGreaterThanOrEqual(PlaceQueryableSchemes.declared.count, 30)
    }

    func testDeclared_everySchemeIsUniqueNormalizedAndInTheDirectory() {
        let declared = PlaceQueryableSchemes.declared
        XCTAssertEqual(Set(declared).count, declared.count, "a declared scheme appears twice")
        let bundled = Set(PlaceAppDirectoryBundled.entries.map(\.scheme))
        for scheme in declared {
            XCTAssertEqual(
                PlaceActionCatalog.normalizedScheme(scheme), scheme,
                "'\(scheme)' is not in normalized form"
            )
            XCTAssertTrue(
                bundled.contains(scheme),
                "'\(scheme)' is declared but not in the bundled directory"
            )
        }
    }

    /// The giants must all have a verification slot — they are what E will actually pick.
    func testDeclared_coversTheTopOfTheDirectory() {
        let declared = Set(PlaceQueryableSchemes.declared)
        for scheme in ["spotify", "comgooglemaps", "whatsapp", "youtube", "instagram", "maps"] {
            XCTAssertTrue(declared.contains(scheme), "'\(scheme)' should have a slot")
        }
    }

    /// Drift between the constant and the plist is a RED TEST, not a silent lie: the parity
    /// test reads the BUILT PRODUCT's Info.plist (the test host is the app), set-equal both
    /// ways, and holds the iOS cap.
    func testDeclared_matchesTheBuiltInfoPlist() throws {
        let plist = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String],
            "LSApplicationQueriesSchemes is missing from the built Info.plist"
        )
        XCTAssertEqual(Set(plist), Set(PlaceQueryableSchemes.declared))
        XCTAssertLessThanOrEqual(plist.count, 50, "iOS ignores everything past 50")
    }

    // MARK: - The three-state verdict

    private func failingCanOpen(_ url: URL) -> Bool {
        XCTFail("canOpen must never be consulted for an unverifiable scheme (got \(url))")
        return false
    }

    func testVerdict_declaredSchemeAsksCanOpenAndBelievesIt() {
        var asked: [URL] = []
        let installed = PlaceAppInstallVerdict.verdict(
            scheme: "spotify", declared: ["spotify"],
            canOpen: { asked.append($0); return true }
        )
        XCTAssertEqual(installed, .looksInstalled)
        XCTAssertEqual(asked, [URL(string: "spotify://")!])

        let absent = PlaceAppInstallVerdict.verdict(
            scheme: "spotify", declared: ["spotify"], canOpen: { _ in false }
        )
        XCTAssertEqual(absent, .doesNotLookInstalled)
    }

    /// THE TRIPWIRE: an undeclared scheme's verdict is decided before `canOpen` — calling it
    /// would launder "no queries slot" into "not installed", which is a lie.
    func testVerdict_undeclaredSchemeIsCannotCheck_andNeverAsks() {
        XCTAssertEqual(
            PlaceAppInstallVerdict.verdict(
                scheme: "obscureapp", declared: ["spotify"], canOpen: failingCanOpen
            ),
            .cannotCheck
        )
    }

    /// No scheme at all (an unrecognised pasted link) has nothing to query.
    func testVerdict_nilSchemeIsCannotCheck_andNeverAsks() {
        XCTAssertEqual(
            PlaceAppInstallVerdict.verdict(
                scheme: nil, declared: ["spotify"], canOpen: failingCanOpen
            ),
            .cannotCheck
        )
    }

    /// A scheme that cannot form a URL (defensive — normalization should prevent it) is also
    /// a cannot-check, never a crash and never a false "not installed".
    func testVerdict_unURLableSchemeIsCannotCheck() {
        XCTAssertEqual(
            PlaceAppInstallVerdict.verdict(
                scheme: "not a scheme", declared: ["not a scheme"], canOpen: failingCanOpen
            ),
            .cannotCheck
        )
    }

    // MARK: - The copy (never claims "not installed" when it can't know)

    func testCopy_isPinnedVerbatim() {
        XCTAssertEqual(
            PlaceAppInstallCopy.line(for: .looksInstalled),
            "Installed on this iPhone."
        )
        XCTAssertEqual(
            PlaceAppInstallCopy.line(for: .doesNotLookInstalled),
            "Doesn't look installed. Saving is fine — the tap will say so honestly "
            + "if it can't open."
        )
        XCTAssertEqual(
            PlaceAppInstallCopy.line(for: .cannotCheck),
            "Can't check whether this app is installed. If it isn't, the notification "
            + "tap will tell you."
        )
    }
}
