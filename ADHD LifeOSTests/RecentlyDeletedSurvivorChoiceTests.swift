//
//  RecentlyDeletedSurvivorChoiceTests.swift
//  ADHD LifeOSTests
//
//  `F-C4-TagsRecentlyDeleted`: the alert E's Step 0 asked for — *"Ask which one survives
//  (Recommended)… One extra tap, no silent merge."*
//
//  **Its own file rather than more of `RecentlyDeletedPresentationTests`**, which is at 300 lines
//  against SwiftLint's 400 ceiling, and because this is one decision with two shapes rather than
//  another copy switch.
//

import XCTest
@testable import ADHD_LifeOS

final class RecentlyDeletedSurvivorChoiceTests: XCTestCase {

    // MARK: - Two spellings: a real choice

    /// **The case difference is what makes this a choice rather than a confirmation.**
    /// `fetchTag(named:)` collides case-insensitively and the app renders the stored case, so
    /// these are one collision with two spellings, and the survivor decides which one the user is
    /// left reading. `alerts.md › Buttons` asks for titles that "describe the result of selecting
    /// the button", which here means quoting the actual name each one keeps.
    func testWhenTheSpellingsDifferBothSurvivorsAreOfferedByName() {
        let alert = RecentlyDeletedPresentation.SurvivorChoice.alert(
            restoredName: "errand", liveName: "Errand"
        )

        XCTAssertEqual(alert.keepRestoredTitle, "Keep “errand”")
        XCTAssertEqual(alert.keepLiveTitle, "Keep “Errand”")
        XCTAssertNotEqual(
            alert.keepRestoredTitle, alert.keepLiveTitle,
            "two buttons reading the same words is the thing `alerts.md › Buttons` rules out"
        )
    }

    // MARK: - One spelling: a disclosure, not a choice

    /// **When the two names are identical there is nothing to choose, and offering a choice
    /// anyway would be a lie told with two buttons.** Both routes end with one tag of that name on
    /// every item; the survivor is a document id the user cannot see. So the alert collapses to
    /// what the ask is actually worth here — telling them a merge is about to happen, and letting
    /// them decline. E's *"no silent merge"* is satisfied either way.
    func testWhenTheSpellingsMatchTheAlertOffersOneActionRatherThanTwoIdenticalOnes() {
        let alert = RecentlyDeletedPresentation.SurvivorChoice.alert(
            restoredName: "errand", liveName: "errand"
        )

        XCTAssertNil(
            alert.keepLiveTitle,
            "the alert offers two buttons whose titles are word-for-word identical"
        )
        XCTAssertEqual(alert.keepRestoredTitle, "Merge")
    }

    /// Case is the ONLY thing that can differ — the collision itself is case-insensitive — so the
    /// comparison that decides the shape must be case-SENSITIVE or it would never see a difference.
    func testTheShapeTurnsOnAnExactComparisonNotACaseInsensitiveOne() {
        let differing = RecentlyDeletedPresentation.SurvivorChoice.alert(
            restoredName: "ERRAND", liveName: "errand"
        )
        XCTAssertNotNil(
            differing.keepLiveTitle,
            "the comparison folded case, so a real difference in spelling was treated as none"
        )
    }

    // MARK: - What the alert says

    func testTheAlertNamesTheTagAndSaysWhatAMergeDoes() {
        let alert = RecentlyDeletedPresentation.SurvivorChoice.alert(
            restoredName: "errand", liveName: "Errand"
        )

        // The title names the tag that ALREADY EXISTS — the live one — which is
        // `TagEditorPresentation.mergeAlertTitle(conflictingName:)`'s rule, and the right one:
        // the surprise being reported is that the name is taken, not that a restore was asked for.
        XCTAssertEqual(alert.title, "“Errand” already exists")
        XCTAssertTrue(
            alert.message.contains("errand") && alert.message.contains("Errand"),
            "the message must show BOTH spellings — they are what the two buttons choose between"
        )
        XCTAssertTrue(
            alert.message.contains("one tag"),
            "the message does not say the two become one, which is the whole thing the user is"
                + " being asked to agree to"
        )
        XCTAssertEqual(alert.cancelTitle, "Cancel")
        XCTAssertFalse(
            alert.message.contains("can't be undone"),
            "a merge on restore is irreversible, but that sentence is reserved for Delete Forever"
                + " in this screen — see `RecentlyDeletedPresentation.DeleteForever`"
        )
    }
}
