//
//  PlaceAppDirectoryBundledTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The curated bundled list, swept whole (F-AppDirectory-1-Directory). Curation is the real
/// work of the block — a wrong scheme teaches E the entire feature lies — so every invariant a
/// test can hold, a test holds. What tests CANNOT prove is that a scheme actually belongs to
/// its app; that part is held by the curation rule (documented schemes only, omit rather than
/// guess) and by block 3's on-device sweep of the declared subset.
final class PlaceAppDirectoryBundledTests: XCTestCase {

    private let entries = PlaceAppDirectoryBundled.entries

    /// The floor, not the ambition. The list is deliberately smaller than "every app with a
    /// rumoured scheme" — block 4's remote top-up exists so it can grow without a release.
    func testBundled_isBigEnoughToFeelLikeADirectory() {
        XCTAssertGreaterThanOrEqual(entries.count, 120)
    }

    /// Every scheme must already be in normalized form — a pick saves it VERBATIM into
    /// `.openApp`, so a scheme `normalizedScheme` would alter could never open.
    func testBundled_everySchemeIsAlreadyNormalized() {
        for entry in entries {
            XCTAssertEqual(
                PlaceActionCatalog.normalizedScheme(entry.scheme), entry.scheme,
                "\(entry.name)'s scheme '\(entry.scheme)' is not in normalized form"
            )
        }
    }

    func testBundled_schemesAreUnique() {
        let schemes = entries.map(\.scheme)
        XCTAssertEqual(schemes.count, Set(schemes).count, "a scheme appears twice")
    }

    /// Duplicate NAMES are a curation smell too — two rows reading "Maps" would make the pick
    /// a coin flip E can't reason about.
    func testBundled_namesAreTrimmedNonEmptyAndUnique() {
        for entry in entries {
            XCTAssertEqual(
                entry.name, entry.name.trimmingCharacters(in: .whitespacesAndNewlines),
                "\(entry.scheme)'s name carries stray whitespace"
            )
            XCTAssertFalse(entry.name.isEmpty, "\(entry.scheme) has an empty name")
        }
        let names = entries.map(\.name)
        XCTAssertEqual(names.count, Set(names).count, "a display name appears twice")
    }

    /// Non-pass-through templates must hold exactly one slot and resolve to something URL-shaped
    /// — the same rule the lenient remote decode enforces, held locally by the sweep.
    func testBundled_everyDestinationTemplateResolves() throws {
        for entry in entries {
            for destination in entry.destinations {
                let slots = destination.template
                    .components(separatedBy: PlaceAppDestinationTemplate.slot).count - 1
                XCTAssertLessThanOrEqual(
                    slots, 1, "\(entry.name)/\(destination.name) has more than one {value} slot"
                )
                guard !destination.isPassThrough else { continue }
                let resolved = try XCTUnwrap(
                    destination.resolved(with: "probe"),
                    "\(entry.name)/\(destination.name) did not resolve"
                )
                XCTAssertNotNil(
                    URL(string: resolved)?.scheme,
                    "\(entry.name)/\(destination.name) resolves to something that is not a URL"
                )
            }
        }
    }

    /// Hosts are matched lowercase against pasted links and must be bare hosts — a stray
    /// "https://" or path would silently never match anything.
    func testBundled_hostsAreLowercasedBareHosts() {
        for entry in entries {
            for host in entry.universalLinkHosts {
                XCTAssertEqual(host, host.lowercased(), "\(entry.name)'s host '\(host)' is not lowercase")
                XCTAssertFalse(host.contains("/"), "\(entry.name)'s host '\(host)' is not a bare host")
                XCTAssertFalse(host.isEmpty, "\(entry.name) has an empty host")
            }
        }
    }

    /// `hidden` is the REMOTE retire mechanism — a bundled entry nobody should see simply
    /// doesn't ship.
    func testBundled_nothingShipsHidden() {
        XCTAssertTrue(entries.allSatisfy { !$0.hidden })
    }

    func testBundled_ranksStayWithinTheHumanScale() {
        XCTAssertTrue(
            entries.allSatisfy { (0...100).contains($0.rank) },
            "a rank outside 0...100 defeats the ordering's legibility"
        )
    }

    /// Continuity with the retired 10-app `PlaceActionCatalog` picker: every scheme E could
    /// pick before must still be findable, or an existing saved action's app has vanished from
    /// the directory that replaced it.
    func testBundled_theOriginalTenAppsAreAllStillHere() {
        let legacy = [
            "music", "maps", "calshow", "comgooglemaps", "instagram",
            "message", "photos-redirect", "spotify", "whatsapp", "youtube"
        ]
        let schemes = Set(entries.map(\.scheme))
        for scheme in legacy {
            XCTAssertTrue(schemes.contains(scheme), "legacy scheme '\(scheme)' fell out of the directory")
        }
    }
}
