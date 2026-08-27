//
//  LocationPermissionPromptTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// What the app SAYS about location permission, and what the button does next.
///
/// This is the missing half of location services: the plist usage strings were in place, but
/// nothing ever asked. Every stamp was silently returning nil because authorization was never
/// requested — the whole feature was dark and looked fine.
///
/// The copy is tested because it is the only place the two-stage escalation is explained. Ask for
/// Always cold and iOS shows a weaker prompt that users decline far more often; the supported path
/// is When In Use first, then escalate once places exist and the feature is real to them.
final class LocationPermissionPromptTests: XCTestCase {

    // MARK: - Whether to show anything at all

    /// Nothing to say once the grant already covers what the screen needs.
    func testPrompt_isAbsentWhenAlreadyFullyGranted() {
        XCTAssertNil(LocationPermissionPrompt.prompt(for: .always, wantsTriggering: true))
        XCTAssertNil(LocationPermissionPrompt.prompt(for: .whenInUse, wantsTriggering: false))
    }

    func testPrompt_appearsWhenNothingHasBeenAskedYet() {
        XCTAssertNotNil(LocationPermissionPrompt.prompt(for: .notDetermined, wantsTriggering: false))
    }

    // MARK: - The two-stage ask

    func testPrompt_fromNotDetermined_offersToAskAndTargetsWhenInUse() throws {
        let prompt = try XCTUnwrap(
            LocationPermissionPrompt.prompt(for: .notDetermined, wantsTriggering: true)
        )

        XCTAssertEqual(prompt.action, .request(.whenInUse))
        XCTAssertFalse(prompt.isWarning, "a first ask is an invitation, not a problem")
    }

    /// The escalation is only offered when triggering is actually wanted — otherwise When In Use
    /// is the end of the road and nagging for Always would be asking for power we do not need.
    func testPrompt_fromWhenInUse_offersAlwaysOnlyForTriggering() throws {
        let prompt = try XCTUnwrap(
            LocationPermissionPrompt.prompt(for: .whenInUse, wantsTriggering: true)
        )

        XCTAssertEqual(prompt.action, .request(.always))
        XCTAssertNil(LocationPermissionPrompt.prompt(for: .whenInUse, wantsTriggering: false))
    }

    // MARK: - Refused

    /// Re-prompting a denied user does nothing at all — iOS will not show the sheet again — so the
    /// only honest button is one that opens Settings.
    func testPrompt_whenDenied_sendsToSettingsRatherThanRePrompting() throws {
        let prompt = try XCTUnwrap(
            LocationPermissionPrompt.prompt(for: .denied, wantsTriggering: false)
        )

        XCTAssertEqual(prompt.action, .openSettings)
        XCTAssertTrue(prompt.isWarning)
    }

    /// Restricted is not the user's choice to undo (parental controls, MDM). It must not offer a
    /// button that implies they can fix it by tapping.
    func testPrompt_whenRestricted_explainsRatherThanOffersAnAction() throws {
        let prompt = try XCTUnwrap(
            LocationPermissionPrompt.prompt(for: .restricted, wantsTriggering: false)
        )

        XCTAssertEqual(prompt.action, .none)
        XCTAssertTrue(prompt.isWarning)
    }

    // MARK: - The copy

    /// Each state must say something different — a prompt that reads the same whether you have
    /// been asked, refused, or half-granted tells the reader nothing.
    func testCopy_isDistinctForEveryState() {
        let messages = [
            LocationPermissionPrompt.prompt(for: .notDetermined, wantsTriggering: true),
            LocationPermissionPrompt.prompt(for: .whenInUse, wantsTriggering: true),
            LocationPermissionPrompt.prompt(for: .denied, wantsTriggering: true),
            LocationPermissionPrompt.prompt(for: .restricted, wantsTriggering: true)
        ].compactMap { $0?.message }

        XCTAssertEqual(messages.count, 4)
        XCTAssertEqual(Set(messages).count, 4, "every state needs its own explanation")
    }

    func testCopy_neverPromisesTriggeringOnAWhenInUseGrant() throws {
        let prompt = try XCTUnwrap(
            LocationPermissionPrompt.prompt(for: .whenInUse, wantsTriggering: true)
        )

        // The whole point of the escalation step: say plainly that arrival nudges need the
        // stronger grant, rather than implying they already work.
        XCTAssertTrue(
            prompt.message.lowercased().contains("always"),
            "the escalation must name the grant it needs: \(prompt.message)"
        )
    }

    /// Button titles are what E actually taps; a title that doesn't match the action is a lie.
    func testButtonTitle_matchesTheAction() throws {
        let first = try XCTUnwrap(LocationPermissionPrompt.prompt(for: .notDetermined, wantsTriggering: false))
        let denied = try XCTUnwrap(LocationPermissionPrompt.prompt(for: .denied, wantsTriggering: false))
        let restricted = try XCTUnwrap(LocationPermissionPrompt.prompt(for: .restricted, wantsTriggering: false))

        XCTAssertNotNil(first.buttonTitle)
        XCTAssertEqual(denied.buttonTitle, "Open Settings")
        XCTAssertNil(restricted.buttonTitle, "an unfixable state must not offer a button")
    }
}
