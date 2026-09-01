//
//  PlaceOpenLinkEditingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The editor's paste-a-link path (F-AppDirectory-2-Links): a pasted share-link becomes an
/// `open_link` action — recognised against the directory's universal-link hosts when it can
/// be, named from its host when it can't, and E's own words always win.
final class PlaceOpenLinkEditingTests: XCTestCase {

    private let directory = [
        PlaceAppDirectoryEntry(
            scheme: "spotify", name: "Spotify",
            universalLinkHosts: ["open.spotify.com", "spotify.link"]
        )
    ]

    private func draft() -> PlaceActionDraft {
        var draft = PlaceActionDraft()
        draft.kindChoice = .openApp
        return draft
    }

    private func makeKind(
        _ draft: PlaceActionDraft
    ) throws -> PlaceAction.Kind {
        try XCTUnwrap(
            PlaceActionValidation.makeAction(from: draft, id: UUID(), directory: directory)
        ).kind
    }

    // MARK: - Pasted links

    func testPastedLink_recognisedHostGetsTheDirectoryAppsNameAndScheme() throws {
        var draft = draft()
        draft.appLink = "open.spotify.com/playlist/abc123"

        guard case .openLink(let name, let link, let scheme) = try makeKind(draft) else {
            return XCTFail("a pasted link must save as open_link")
        }
        XCTAssertEqual(link, "https://open.spotify.com/playlist/abc123")
        XCTAssertEqual(name, "Spotify")
        XCTAssertEqual(scheme, "spotify")
    }

    func testPastedLink_unrecognisedHostInfersItsNameFromTheHost() throws {
        var draft = draft()
        draft.appLink = "https://www.example.com/thing"

        guard case .openLink(let name, _, let scheme) = try makeKind(draft) else {
            return XCTFail("a pasted link must save as open_link")
        }
        XCTAssertEqual(name, "example.com", "www. is noise, not a name")
        XCTAssertNil(scheme)
    }

    func testPastedLink_typedNameAlwaysWins() throws {
        var draft = draft()
        draft.appLink = "open.spotify.com/playlist/abc123"
        draft.appName = "Gym playlist"

        guard case .openLink(let name, _, _) = try makeKind(draft) else {
            return XCTFail("a pasted link must save as open_link")
        }
        XCTAssertEqual(name, "Gym playlist")
    }

    /// The link field is the more deliberate act — when it holds anything, it decides the
    /// kind, and it must VALIDATE: silently falling back to the scheme path would save
    /// something other than what E pasted.
    func testPastedLink_winsOverATypedScheme_andCarriesItAsTheHint() throws {
        var draft = draft()
        draft.appScheme = "myapp"
        draft.appLink = "https://myapp.example/x"

        guard case .openLink(_, _, let scheme) = try makeKind(draft) else {
            return XCTFail("the link field decides the kind when filled")
        }
        XCTAssertEqual(scheme, "myapp")
    }

    func testPastedLink_nonWebLinkRefusesToSave() {
        var draft = draft()
        draft.appLink = "spotify://playlist/abc"
        XCTAssertFalse(PlaceActionValidation.canSave(draft, directory: directory))

        draft.appLink = "not a link"
        XCTAssertFalse(PlaceActionValidation.canSave(draft, directory: directory))
    }

    // MARK: - Editing round trip

    func testDraft_editsAnOpenLinkActionAndReproducesIt() throws {
        let action = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .openLink(
                displayName: "Spotify — A playlist",
                link: "https://open.spotify.com/playlist/abc123",
                scheme: "spotify"
            )
        )

        let reopened = try XCTUnwrap(PlaceActionDraft(editing: action))
        XCTAssertEqual(reopened.kindChoice, .openApp)
        XCTAssertEqual(reopened.appName, "Spotify — A playlist")
        XCTAssertEqual(reopened.appLink, "https://open.spotify.com/playlist/abc123")

        let saved = try XCTUnwrap(
            PlaceActionValidation.makeAction(from: reopened, id: action.id, directory: directory)
        )
        XCTAssertEqual(saved, action)
    }

    // MARK: - Destination picks

    /// A destination pick carries a CURATED, already-resolved link — which may be a scheme
    /// URL (`comgooglemaps://?daddr=…`), so it must not pass through the https-only
    /// hand-paste validation. It saves verbatim.
    func testDestinationPick_savesVerbatimEvenWhenTheLinkIsASchemeURL() throws {
        var draft = draft()
        draft.destinationPick = PlaceActionDraftLinkPick(
            displayName: "Google Maps — Directions to Gym",
            link: "comgooglemaps://?daddr=51.51520%2C-0.14180",
            scheme: "comgooglemaps"
        )

        guard case .openLink(let name, let link, let scheme) = try makeKind(draft) else {
            return XCTFail("a destination pick must save as open_link")
        }
        XCTAssertEqual(name, "Google Maps — Directions to Gym")
        XCTAssertEqual(link, "comgooglemaps://?daddr=51.51520%2C-0.14180")
        XCTAssertEqual(scheme, "comgooglemaps")
    }

    /// Editing a destination-produced action must reopen SAVEABLE — its scheme link would
    /// fail the hand-paste rule, so the edit seeds the pick carrier, not the paste field.
    func testDraft_editsASchemeLinkActionThroughThePickCarrier() throws {
        let action = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openLink(
                displayName: "Google Maps — Directions to Gym",
                link: "comgooglemaps://?daddr=51.51520%2C-0.14180",
                scheme: "comgooglemaps"
            )
        )

        let reopened = try XCTUnwrap(PlaceActionDraft(editing: action))
        XCTAssertEqual(reopened.destinationPick?.link, "comgooglemaps://?daddr=51.51520%2C-0.14180")
        XCTAssertTrue(reopened.appLink.isEmpty, "a scheme link must not land in the paste field")

        let saved = try XCTUnwrap(
            PlaceActionValidation.makeAction(from: reopened, id: action.id, directory: directory)
        )
        XCTAssertEqual(saved, action)
    }

    // MARK: - Extras follow the WIRE kind, not the editor's menu choice

    /// `open_app` and `open_link` share one KindChoice, so the block-1 seeded-choice rule is
    /// no longer enough: pasting a link into an edited open_app action changes the WIRE kind,
    /// and the old kind's future fields must not ride along.
    func testExtras_dropWhenAnOpenAppEditBecomesAnOpenLink() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_app",
            "scheme": "spotify",
            "display_name": "Spotify",
            "from_the_future": "keep me"
        ]
        let action = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        var reopened = try XCTUnwrap(PlaceActionDraft(editing: action))
        reopened.appLink = "open.spotify.com/playlist/abc123"
        let saved = try XCTUnwrap(
            PlaceActionValidation.makeAction(from: reopened, id: action.id, directory: directory)
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any]
        )
        XCTAssertEqual(json["kind"] as? String, "open_link")
        XCTAssertNil(json["from_the_future"])
    }

    func testExtras_surviveASameKindOpenLinkEdit() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_link",
            "display_name": "Spotify — A playlist",
            "link": "https://open.spotify.com/playlist/abc123",
            "scheme": "spotify",
            "from_the_future": "keep me"
        ]
        let action = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        let reopened = try XCTUnwrap(PlaceActionDraft(editing: action))
        let saved = try XCTUnwrap(
            PlaceActionValidation.makeAction(from: reopened, id: action.id, directory: directory)
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any]
        )
        XCTAssertEqual(json["kind"] as? String, "open_link")
        XCTAssertEqual(json["from_the_future"] as? String, "keep me")
    }

    // MARK: - Host recognition

    func testHostRecognition_matchesCaseInsensitivelyAndMissesHonestly() {
        XCTAssertEqual(
            PlaceAppDirectory.entry(claimingHost: "Open.Spotify.Com", in: directory)?.scheme,
            "spotify"
        )
        XCTAssertNil(PlaceAppDirectory.entry(claimingHost: "example.com", in: directory))
    }
}
