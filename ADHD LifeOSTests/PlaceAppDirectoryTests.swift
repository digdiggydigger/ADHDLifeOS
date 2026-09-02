//
//  PlaceAppDirectoryTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The app directory's pure layer (F-AppDirectory-1-Directory): entry decode, merge, search
/// ranking, and destination templates.
///
/// The decode contract mirrors `.unsupported`'s philosophy adapted for a CATALOGUE rather than
/// user data: a malformed entry is dropped per-entry, never fatal — one bad remote row must not
/// cost E the whole directory. The wire spelling is snake_case (the tasks convention).
final class PlaceAppDirectoryTests: XCTestCase {

    private func entry(
        scheme: String, name: String, keywords: [String] = [],
        rank: Int = 0, hidden: Bool = false
    ) -> PlaceAppDirectoryEntry {
        PlaceAppDirectoryEntry(
            scheme: scheme, name: name, keywords: keywords, rank: rank, hidden: hidden
        )
    }

    private func decodeEntries(_ array: [[String: Any]]) throws -> [PlaceAppDirectoryEntry] {
        PlaceAppDirectory.entries(fromJSONArray: try JSONSerialization.data(withJSONObject: array))
    }

    // MARK: - Decode

    func testEntryDecode_readsEveryFieldWithItsSnakeCasedSpelling() throws {
        let decoded = try decodeEntries([[
            "scheme": "spotify",
            "name": "Spotify",
            "keywords": ["music", "podcast"],
            "universal_link_hosts": ["open.spotify.com"],
            "destinations": [["name": "A playlist", "template": "https://open.spotify.com/playlist/{value}"]],
            "rank": 90,
            "hidden": false
        ]])

        XCTAssertEqual(decoded.count, 1)
        let entry = try XCTUnwrap(decoded.first)
        XCTAssertEqual(entry.scheme, "spotify")
        XCTAssertEqual(entry.name, "Spotify")
        XCTAssertEqual(entry.keywords, ["music", "podcast"])
        XCTAssertEqual(entry.universalLinkHosts, ["open.spotify.com"])
        XCTAssertEqual(entry.destinations.first?.name, "A playlist")
        XCTAssertEqual(entry.rank, 90)
        XCTAssertFalse(entry.hidden)
    }

    func testEntryDecode_defaultsEverythingButSchemeAndName() throws {
        let decoded = try decodeEntries([["scheme": "spotify", "name": "Spotify"]])

        let entry = try XCTUnwrap(decoded.first)
        XCTAssertEqual(entry.keywords, [])
        XCTAssertEqual(entry.universalLinkHosts, [])
        XCTAssertEqual(entry.destinations, [])
        XCTAssertEqual(entry.rank, 0)
        XCTAssertFalse(entry.hidden)
    }

    func testEntriesDecode_dropsAMalformedEntryNotTheWholeList() throws {
        let decoded = try decodeEntries([
            ["scheme": "spotify", "name": "Spotify"],
            ["name": "No scheme at all"],
            ["scheme": "youtube", "name": "YouTube"]
        ])

        XCTAssertEqual(decoded.map(\.scheme), ["spotify", "youtube"])
    }

    /// A scheme that isn't already in normalized form is a curation error — accepting it would
    /// save an `.openApp` that can never open. Same rule for a blank name.
    func testEntriesDecode_dropsUnnormalizedSchemesAndBlankNames() throws {
        let decoded = try decodeEntries([
            ["scheme": "Spotify://", "name": "Shouty"],
            ["scheme": "not a scheme", "name": "Spacey"],
            ["scheme": "youtube", "name": "   "],
            ["scheme": "maps", "name": "Apple Maps"]
        ])

        XCTAssertEqual(decoded.map(\.scheme), ["maps"])
    }

    /// A destination with no template, or with more than one `{value}` slot, is dropped — but
    /// the ENTRY survives with its good destinations. Lossy at both levels, fatal at neither.
    func testEntryDecode_dropsAMalformedDestinationButKeepsTheEntry() throws {
        let decoded = try decodeEntries([[
            "scheme": "spotify",
            "name": "Spotify",
            "destinations": [
                ["name": "A playlist", "template": "https://open.spotify.com/playlist/{value}"],
                ["name": "No template at all"],
                ["name": "Two slots", "template": "https://x.com/{value}/{value}"]
            ]
        ]])

        let entry = try XCTUnwrap(decoded.first)
        XCTAssertEqual(entry.destinations.map(\.name), ["A playlist"])
    }

    /// Hosts are matched against pasted links, which arrive in every case E's keyboard felt
    /// like — decode lowercases them once so matching never has to.
    func testEntryDecode_lowercasesUniversalLinkHosts() throws {
        let decoded = try decodeEntries([[
            "scheme": "spotify", "name": "Spotify",
            "universal_link_hosts": ["Open.Spotify.com"]
        ]])

        XCTAssertEqual(decoded.first?.universalLinkHosts, ["open.spotify.com"])
    }

    // MARK: - Merge

    // MARK: - Category (F-AppDirectory-Categories)

    func testEntryDecode_readsTheCategory() throws {
        let entry = try XCTUnwrap(
            PlaceAppDirectory.entry(
                fromObject: ["scheme": "nflx", "name": "Netflix", "category": "streaming"]
            )
        )

        XCTAssertEqual(entry.category, .streaming)
    }

    /// Lenient by the same philosophy as the rest of the decode: a remote row naming a group
    /// this build has never heard of still BROWSES, under "More apps", rather than vanishing.
    func testEntryDecode_unknownOrAbsentCategoryLandsInOther() throws {
        let absent = try XCTUnwrap(
            PlaceAppDirectory.entry(fromObject: ["scheme": "nflx", "name": "Netflix"])
        )
        let unknown = try XCTUnwrap(
            PlaceAppDirectory.entry(
                fromObject: ["scheme": "tg", "name": "Telegram", "category": "wingdings"]
            )
        )

        XCTAssertEqual(absent.category, .other)
        XCTAssertEqual(unknown.category, .other)
    }

    func testMerge_withNoRemote_isIdentity() {
        let bundled = [entry(scheme: "spotify", name: "Spotify"), entry(scheme: "maps", name: "Maps")]
        XCTAssertEqual(PlaceAppDirectory.merge(bundled: bundled, remote: []), bundled)
    }

    /// Remote wins WHOLESALE — no per-field merging, so a remote row is exactly what ships and
    /// curation never has to reason about half-overridden entries.
    func testMerge_remoteReplacesABundledEntryInItsPlace() {
        let bundled = [entry(scheme: "spotify", name: "Spotify", rank: 5), entry(scheme: "maps", name: "Maps")]
        let remote = [entry(scheme: "spotify", name: "Spotify Music", rank: 99)]

        let merged = PlaceAppDirectory.merge(bundled: bundled, remote: remote)

        XCTAssertEqual(merged.map(\.scheme), ["spotify", "maps"])
        XCTAssertEqual(merged.first?.name, "Spotify Music")
        XCTAssertEqual(merged.first?.rank, 99)
    }

    func testMerge_remoteOnlyEntriesAppendInRemoteOrder() {
        let bundled = [entry(scheme: "spotify", name: "Spotify")]
        let remote = [entry(scheme: "airbnb", name: "Airbnb"), entry(scheme: "lyft", name: "Lyft")]

        let merged = PlaceAppDirectory.merge(bundled: bundled, remote: remote)

        XCTAssertEqual(merged.map(\.scheme), ["spotify", "airbnb", "lyft"])
    }

    /// Retiring is `hidden: true` on the remote row: the entry stays in the merged list (so a
    /// saved action keeps its display name) but search never offers it again.
    func testMerge_remoteCanRetireABundledEntry() {
        let bundled = [entry(scheme: "deadapp", name: "Dead App"), entry(scheme: "maps", name: "Maps")]
        let remote = [entry(scheme: "deadapp", name: "Dead App", hidden: true)]

        let merged = PlaceAppDirectory.merge(bundled: bundled, remote: remote)

        XCTAssertEqual(merged.count, 2)
        XCTAssertTrue(try XCTUnwrap(merged.first(where: { $0.scheme == "deadapp" })).hidden)
        XCTAssertEqual(PlaceAppDirectorySearch.filter("", in: merged).map(\.scheme), ["maps"])
    }

    // MARK: - Search

    func testSearch_emptyQuery_returnsAllVisibleByRankThenName() {
        let entries = [
            entry(scheme: "b", name: "Beta", rank: 0),
            entry(scheme: "a", name: "Alpha", rank: 0),
            entry(scheme: "c", name: "Chart Topper", rank: 50),
            entry(scheme: "h", name: "Hidden", hidden: true)
        ]

        let result = PlaceAppDirectorySearch.filter("   ", in: entries)

        XCTAssertEqual(result.map(\.name), ["Chart Topper", "Alpha", "Beta"])
    }

    /// The pinned tier order: name prefix > name contains > keyword > scheme. Within a tier,
    /// rank then name — so a query can never bury an exact-feeling match under a keyword hit.
    func testSearch_ranksNamePrefixAboveContainsAboveKeywordAboveScheme() {
        let entries = [
            entry(scheme: "mapmatch", name: "Scheme Only"),
            entry(scheme: "d", name: "Roadmap", keywords: []),
            entry(scheme: "b", name: "Treasure", keywords: ["map"]),
            entry(scheme: "a", name: "Maps", rank: 0)
        ]

        let result = PlaceAppDirectorySearch.filter("map", in: entries)

        XCTAssertEqual(result.map(\.name), ["Maps", "Roadmap", "Treasure", "Scheme Only"])
    }

    func testSearch_isCaseInsensitiveAndTrimsTheQuery() {
        let entries = [entry(scheme: "spotify", name: "Spotify")]

        XCTAssertEqual(PlaceAppDirectorySearch.filter("  SPOT  ", in: entries).count, 1)
    }

    func testSearch_rankBreaksTiesWithinATier() {
        let entries = [
            entry(scheme: "a", name: "Streamer Two", keywords: ["music"], rank: 1),
            entry(scheme: "b", name: "Streamer One", keywords: ["music"], rank: 90)
        ]

        let result = PlaceAppDirectorySearch.filter("music", in: entries)

        XCTAssertEqual(result.map(\.name), ["Streamer One", "Streamer Two"])
    }

    func testSearch_noMatchReturnsEmpty() {
        let entries = [entry(scheme: "spotify", name: "Spotify")]
        XCTAssertEqual(PlaceAppDirectorySearch.filter("zzzz", in: entries), [])
    }

    // MARK: - Destination templates

    func testTemplate_substitutesTheValuePercentEncoded() {
        let template = PlaceAppDestinationTemplate(
            name: "A playlist", template: "https://open.spotify.com/playlist/{value}"
        )

        XCTAssertEqual(
            template.resolved(with: "abc 123/xyz"),
            "https://open.spotify.com/playlist/abc%20123%2Fxyz"
        )
    }

    /// No `{value}` slot means pass-through: E pastes the whole share link and it IS the
    /// destination — the "anything richer" escape hatch that keeps templates to one slot.
    func testTemplate_passThroughHandsBackThePastedValue() {
        let template = PlaceAppDestinationTemplate(name: "Paste a link", template: "")

        XCTAssertTrue(template.isPassThrough)
        XCTAssertEqual(
            template.resolved(with: " https://open.spotify.com/playlist/xyz "),
            "https://open.spotify.com/playlist/xyz"
        )
    }

    func testTemplate_emptyValueResolvesToNil() {
        let slotted = PlaceAppDestinationTemplate(name: "A playlist", template: "https://x.com/{value}")
        XCTAssertNil(slotted.resolved(with: "   "))
        XCTAssertNil(PlaceAppDestinationTemplate(name: "Paste", template: "").resolved(with: ""))
    }
}
