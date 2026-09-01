//
//  PlaceActionEditingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The action editor's pure layer (F-PlaceActions-2-Editor): draft validation, the catalogue,
/// and the row labels — including the honesty rule that an unsupported action names itself.
final class PlaceActionEditingTests: XCTestCase {

    private func draft(_ kind: PlaceActionDraft.KindChoice) -> PlaceActionDraft {
        var draft = PlaceActionDraft()
        draft.kindChoice = kind
        return draft
    }

    // MARK: - The normalizer
    // (The 10-entry catalogue that lived here was superseded by `PlaceAppDirectoryBundled`;
    // its uniqueness/normalization sweep now runs in `PlaceAppDirectoryBundledTests`.)

    func testNormalizedScheme_trimsLowercasesAndStripsThePastedTail() {
        XCTAssertEqual(PlaceActionCatalog.normalizedScheme("  Spotify://  "), "spotify")
        XCTAssertEqual(PlaceActionCatalog.normalizedScheme("spotify://playlist/123"), "spotify")
        XCTAssertEqual(PlaceActionCatalog.normalizedScheme("comgooglemaps"), "comgooglemaps")
        XCTAssertNil(PlaceActionCatalog.normalizedScheme("   "))
        XCTAssertNil(PlaceActionCatalog.normalizedScheme("not a scheme"))
    }

    // MARK: - Validation, per kind

    func testOpenApp_needsASchemeAndFallsBackToItForTheName() throws {
        var incomplete = draft(.openApp)
        XCTAssertFalse(PlaceActionValidation.canSave(incomplete))

        incomplete.appScheme = "Spotify://"
        let action = try XCTUnwrap(PlaceActionValidation.makeAction(from: incomplete, id: UUID()))
        guard case .openApp(let scheme, let name) = action.kind else {
            return XCTFail("expected openApp, got \(action.kind)")
        }
        XCTAssertEqual(scheme, "spotify")
        XCTAssertEqual(name, "spotify", "a blank name falls back to the scheme")
    }

    func testOpenURL_promotesABareDomainToHTTPS() throws {
        var web = draft(.openURL)
        web.urlString = "example.com/timesheet"

        let action = try XCTUnwrap(PlaceActionValidation.makeAction(from: web, id: UUID()))
        guard case .openURL(let url) = action.kind else {
            return XCTFail("expected openURL, got \(action.kind)")
        }
        XCTAssertEqual(url, "https://example.com/timesheet")
    }

    /// An app scheme pasted into the website field must be refused, not silently accepted —
    /// it belongs in "Open an app", and two rows meaning the same thing must not behave
    /// differently.
    func testOpenURL_refusesNonWebSchemes() {
        var smuggled = draft(.openURL)
        smuggled.urlString = "spotify://playlist/123"
        XCTAssertFalse(PlaceActionValidation.canSave(smuggled))

        var empty = draft(.openURL)
        empty.urlString = "   "
        XCTAssertFalse(PlaceActionValidation.canSave(empty))
    }

    func testTextContact_needsAPhoneWithADigitAndABody() throws {
        var text = draft(.textContact)
        text.contactPhone = "+44 7700 900123"
        XCTAssertFalse(PlaceActionValidation.canSave(text), "a body is required")

        text.messageBody = "  Here! "
        text.contactName = "  "
        let action = try XCTUnwrap(PlaceActionValidation.makeAction(from: text, id: UUID()))
        guard case .textContact(let name, let phone, let body) = action.kind else {
            return XCTFail("expected textContact, got \(action.kind)")
        }
        XCTAssertEqual(phone, "+44 7700 900123")
        XCTAssertEqual(body, "Here!", "the body is trimmed")
        XCTAssertEqual(name, phone, "a blank name falls back to the number")

        var phoneless = draft(.textContact)
        phoneless.contactPhone = "no digits here"
        phoneless.messageBody = "Hi"
        XCTAssertFalse(PlaceActionValidation.canSave(phoneless))
    }

    /// Empty minutes IS valid — "use my default length" — while out-of-range minutes are not.
    func testStartSprint_emptyMinutesMeansDefault_boundsComeFromThePreference() throws {
        let action = try XCTUnwrap(
            PlaceActionValidation.makeAction(from: draft(.startSprint), id: UUID())
        )
        guard case .startSprint(let minutes) = action.kind else {
            return XCTFail("expected startSprint, got \(action.kind)")
        }
        XCTAssertNil(minutes)

        var tooLong = draft(.startSprint)
        tooLong.sprintMinutes = "121"
        XCTAssertFalse(
            PlaceActionValidation.canSave(tooLong),
            "the range is MomentumPreferences.sprintMinutesRange, not a local guess"
        )

        var fine = draft(.startSprint)
        fine.sprintMinutes = "25"
        XCTAssertTrue(PlaceActionValidation.canSave(fine))
    }

    func testCaptureAndJournal_rejectTrimmedToEmptyText() {
        var capture = draft(.createCapture)
        capture.captureText = "   "
        XCTAssertFalse(PlaceActionValidation.canSave(capture))

        var journal = draft(.journalLine)
        journal.journalBody = "Arrived at the gym"
        XCTAssertTrue(PlaceActionValidation.canSave(journal))
    }

    func testOpenScreen_isAlwaysSaveableAndCarriesTheTabToken() throws {
        var screen = draft(.openScreen)
        screen.screen = .journal

        let action = try XCTUnwrap(PlaceActionValidation.makeAction(from: screen, id: UUID()))
        guard case .openScreen(let token) = action.kind else {
            return XCTFail("expected openScreen, got \(action.kind)")
        }
        XCTAssertEqual(token, "journal")
    }

    func testMakeAction_carriesTheDraftDirection() throws {
        var leaving = draft(.openScreen)
        leaving.direction = .departure

        let action = try XCTUnwrap(PlaceActionValidation.makeAction(from: leaving, id: UUID()))
        XCTAssertEqual(action.direction, .departure)
    }

    // MARK: - Editing round trip

    /// Whatever the sheet saved, reopening it must show the same values — draft → action →
    /// draft is identity for every editable kind.
    func testDraft_survivesTheEditingRoundTrip() throws {
        var original = draft(.textContact)
        original.direction = .departure
        original.contactName = "Ben"
        original.contactPhone = "+44123"
        original.messageBody = "On my way"

        let action = try XCTUnwrap(PlaceActionValidation.makeAction(from: original, id: UUID()))
        let reopened = try XCTUnwrap(PlaceActionDraft(editing: action))

        XCTAssertEqual(reopened.kindChoice, .textContact)
        XCTAssertEqual(reopened.direction, .departure)
        XCTAssertEqual(reopened.contactName, "Ben")
        XCTAssertEqual(reopened.contactPhone, "+44123")
        XCTAssertEqual(reopened.messageBody, "On my way")
    }

    /// An unsupported action cannot be edited by this build — only kept or deleted — so the
    /// sheet must refuse to open for it rather than open blank and save a stripped version.
    func testDraft_refusesToEditAnUnsupportedAction() {
        let future = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .unsupported(rawKind: "play_soundscape", payload: [:])
        )
        XCTAssertNil(PlaceActionDraft(editing: future))
    }

    /// The sheet rebuilds the action from the draft on save — a second stripping hole the
    /// encoder-side capture can't close on its own. A newer build's extra field must survive
    /// this build EDITING the action, not just storing it.
    func testDraft_carriesAStrangerFieldThroughAnEditSave() throws {
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

        let reopened = try XCTUnwrap(PlaceActionDraft(editing: action))
        let saved = try XCTUnwrap(PlaceActionValidation.makeAction(from: reopened, id: action.id))

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any]
        )
        XCTAssertEqual(json["from_the_future"] as? String, "keep me")
        XCTAssertEqual(json["scheme"] as? String, "spotify")
    }

    /// Switching the kind is E deliberately replacing the action — the old kind's future
    /// fields don't ride along onto a kind they were never written for.
    func testDraft_dropsTheStrangerWhenTheKindChanges() throws {
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
        reopened.kindChoice = .openURL
        reopened.urlString = "example.com"
        let saved = try XCTUnwrap(PlaceActionValidation.makeAction(from: reopened, id: action.id))

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any]
        )
        XCTAssertNil(json["from_the_future"])
        XCTAssertEqual(json["kind"] as? String, "open_url")
    }

    // MARK: - Row labels

    func testRowLabels_everyKindNamesItself() {
        let id = UUID()
        func title(_ kind: PlaceAction.Kind) -> String {
            PlaceActionRowLabel.title(for: PlaceAction(id: id, direction: .arrival, kind: kind))
        }

        XCTAssertEqual(title(.openApp(scheme: "spotify", displayName: "Spotify")), "Open Spotify")
        XCTAssertEqual(title(.openURL(urlString: "https://example.com/x")), "Open example.com")
        XCTAssertEqual(
            title(.textContact(contactName: "Ben", phoneNumber: "+44123", messageBody: "Hi")),
            "Text Ben"
        )
        XCTAssertEqual(title(.startSprint(minutes: 25)), "Start a 25-minute sprint")
        XCTAssertEqual(title(.startSprint(minutes: nil)), "Start a sprint (default length)")
        XCTAssertEqual(title(.createCapture(text: "Check the mail")), "Capture \u{201C}Check the mail\u{201D}")
        XCTAssertEqual(title(.openScreen(screen: "today")), "Go to Today")
    }

    /// The honesty rule: an action from a newer build says so, and never renders blank.
    func testRowLabels_unsupportedActionNamesItselfHonestly() {
        let future = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .unsupported(rawKind: "play_soundscape", payload: [:])
        )
        XCTAssertEqual(PlaceActionRowLabel.title(for: future), "Unavailable action (play_soundscape)")
        XCTAssertEqual(PlaceActionRowLabel.subtitle(for: future), "When leaving")
        XCTAssertFalse(PlaceActionRowLabel.unsupportedExplainer.isEmpty)
    }

    func testRowSubtitles_useTheTogglesOwnWords() {
        let arrive = PlaceAction(
            id: UUID(), direction: .arrival, kind: .openScreen(screen: "today")
        )
        XCTAssertEqual(PlaceActionRowLabel.subtitle(for: arrive), "On arrival")
    }

    /// The screen tokens are `AppTab`'s spellings — block 3's router maps them back, so a
    /// renamed case would break routing silently. Pinned here.
    func testScreenTokens_matchTheTabSpellings() {
        XCTAssertEqual(
            PlaceActionScreen.allCases.map(\.rawValue),
            ["today", "tasks", "areas", "journal", "captures"]
        )
    }
}
