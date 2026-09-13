//
//  PlaceRoutineCompletionTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-6`'s pure layer — E's R1–R5 Completed flow, and the nine answers E gave
//  on 2026-09-13. Every word, every duration and every spacing the flow needs is a pure
//  function pinned here, so none of it can live in a SwiftUI body where no test can read it.
//
//  **Five of E's nine answers are E's own wording or a reversal of what was offered**, so the
//  strings below are quoted from E rather than derived — including the hyphen-minus in
//  `"4 of 4 done - Ready to finish?"`, which is E's punctuation and not the em dash the rest of
//  this app uses. Do not typographically "improve" it.
//

import XCTest
@testable import ADHD_LifeOS

final class PlaceRoutineCompletionTests: XCTestCase {

    private func step(_ state: RoutineStepState, name: String = "Spotify") -> RoutineRun.Step {
        RoutineRun.Step(
            action: PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: name.lowercased(), displayName: name)
            ),
            state: state
        )
    }

    private func run(_ states: [RoutineStepState], name: String = "Gym 🏋️") -> RoutineRun {
        RoutineRun(
            id: UUID(), placeId: UUID(), direction: .arrival,
            startedAt: Date(timeIntervalSince1970: 1_756_296_000),
            displayName: name, customMessage: nil,
            steps: states.enumerated().map { step($0.element, name: "App\($0.offset)") }
        )
    }

    // MARK: - R-f: which completions earn the celebration

    /// R-f, approved by E as a build default: the celebration needs at least one step the USER
    /// tapped done. A run that resolved itself, or that the user only skipped, still ends and
    /// still records — it just completes quietly (E's answer 1: the congratulation, no
    /// confetti, the ≈2 s beat).
    func testARunWithATappedDoneStepEarnsItsCelebration() {
        XCTAssertTrue(PlaceRoutineProgress.earnedCelebration(run([.autoDone, .done, .skipped])))
    }

    func testARunResolvedOnlyByItsAutomaticStepsCompletesQuietly() {
        XCTAssertFalse(
            PlaceRoutineProgress.earnedCelebration(run([.autoDone, .autoDone])),
            "nothing was done BY the user, so there is nothing of theirs to celebrate"
        )
    }

    func testARunResolvedOnlyBySkippingCompletesQuietly() {
        XCTAssertFalse(
            PlaceRoutineProgress.earnedCelebration(run([.skipped, .skipped, .skipped])),
            "skipping the whole routine is not doing it"
        )
    }

    /// The shape BOTH routine journeys actually reach — one auto step and three skips.
    func testTheJourneysAutoPlusSkippedRunIsDeliberatelyUnearned() {
        XCTAssertFalse(
            PlaceRoutineProgress.earnedCelebration(run([.autoDone, .skipped, .skipped, .skipped])),
            "both UI journeys resolve the gym routine this way, so both get the quiet beat and"
                + " neither may wait on confetti that is never coming"
        )
    }

    func testOneTappedStepAmongAutomaticAndSkippedOnesIsEnough() {
        XCTAssertTrue(
            PlaceRoutineProgress.earnedCelebration(run([.autoDone, .skipped, .done, .skipped])),
            "R-f asks for AT LEAST one tapped step, not for a majority"
        )
    }

    // MARK: - The words (E's answers 2, 3, 5 and 9)

    /// E's answer 3, verbatim, hyphen-minus and all.
    func testTheCompletedCardsTitleIsTheWordingEChose() {
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.completedTitle(for: run([.done, .done, .done, .done])),
            "4 of 4 done - Ready to finish?"
        )
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.completedTitle(for: run([.done, .skipped, .autoDone])),
            "2 of 3 done - Ready to finish?",
            "E's answer 5: done-of-total ALWAYS, so the title can never disagree with the list"
        )
    }

    func testTheGreetingNamesTheUserAndDropsTheNameWhenThereIsNone() {
        XCTAssertEqual(PlaceRoutineCompletionCopy.greeting(for: "Ethan"), "Nice one, Ethan")
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.greeting(for: nil), "Nice one",
            "E's R4 chose the ACCOUNT display name; with no name the greeting drops it rather"
                + " than greeting an empty string"
        )
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.greeting(for: "   "), "Nice one",
            "a whitespace-only display name is no name at all"
        )
    }

    /// E's answer 2 (the summary line) and answer 5 (the count on it).
    func testTheSummaryLineCountsDoneOfTotalSoItCanNeverDisagreeWithTheList() {
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.summary(for: run([.done, .done, .done, .skipped])),
            "Gym 🏋️ routine done — 3 of 4 steps"
        )
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.summary(for: run([.done], name: "Office 💼")),
            "Office 💼 routine done — 1 of 1 steps"
        )
    }

    /// E's answer 4 and answer 9: an auto-done step is distinguished by a WORD, not by a second
    /// glyph — it draws the same accent circle and checkmark the routine screen's rows draw.
    func testEachResolvedStateReadsAsItsOwnWord() {
        XCTAssertEqual(PlaceRoutineCompletionCopy.stateWord(for: .done), "Done")
        XCTAssertEqual(PlaceRoutineCompletionCopy.stateWord(for: .autoDone), "Auto")
        XCTAssertEqual(PlaceRoutineCompletionCopy.stateWord(for: .skipped), "Skipped")
    }

    /// **E's answer 9 forbids `✗` by name** — the app uses `xmark` only as a Close button, so a
    /// cross in a step list would read as "dismiss this", not "you skipped it".
    func testNoStateIsEverWrittenAsACross() {
        let words = RoutineStepState.allCases.map(PlaceRoutineCompletionCopy.stateWord(for:))
        XCTAssertFalse(
            words.contains { $0.contains("✗") || $0.contains("✘") || $0.lowercased().contains("xmark") },
            "the states read \(words); E ruled out a cross for the skipped row"
        )
    }

    /// The Completed card's own words. They live here rather than in the card's body for the
    /// same reason every other string in this file does: a body is the one place no test can
    /// read.
    func testTheCompletedCardNamesItsMomentAndItsButton() {
        XCTAssertEqual(PlaceRoutineCompletionCopy.completedEyebrow, "ALL DONE")
        XCTAssertEqual(
            PlaceRoutineCompletionCopy.completedButton, "Completed",
            "E's R1 named this button, and the journeys tap it by label"
        )
    }

    /// Risk 7 of the plan, and MORE pressing since E reversed R5: the congratulation takes the
    /// screen's Close button away and now stays until dismissed, so for VoiceOver this action is
    /// the only way out and there is no timer to rescue anyone who misses it.
    ///
    /// The word is "Close", not "Skip": with the timer gone there is nothing left to skip.
    func testTheCongratulationOffersANamedWayToCloseIt() {
        XCTAssertEqual(PlaceRoutineCompletionCopy.closeAction, "Close")
        XCTAssertFalse(
            PlaceRoutineCompletionCopy.closeHint.isEmpty,
            "a sighted user gets no button either — the view must SAY that a tap closes it"
        )
    }

    // MARK: - R5 REVERSED, 2026-09-13

    /// **E reversed R5's auto-leave on 2026-09-13**, asked what the 5.4 s timer should do now
    /// that the screen carries a scrollable step list, four clock times, per-step durations and
    /// a comparison. E chose *"Stays until dismissed"*: the celebration plays over it, then it
    /// waits.
    ///
    /// So `PlaceRoutineCongratulationLength` — `hold(for:)` and `quietBeat` — is GONE, and this
    /// test stands where its three did. The three pinned a timer that no longer exists; deleting
    /// them silently would have left no trace of the decision that removed them, which is the
    /// register's rule after the swipe-origin reversal.
    ///
    /// **E's answers 1 and 7 survive, but only in the confetti dimension.** They made R-f's
    /// unearned run and the Celebrations switch being OFF "the same view, just shorter" — the
    /// SHORTER half is now meaningless, and what still distinguishes those cases is that no
    /// confetti plays over them.
    func testTheCongratulationNoLongerHasALengthBecauseEReversedR5() {
        XCTAssertFalse(
            PlaceRoutineCompletionCopy.closeHint.isEmpty,
            "the view now waits for a deliberate dismissal, so it must SAY how to dismiss it —"
                + " there is no timer left to rescue a user who cannot find the way out"
        )
    }

    // MARK: - §7.2: the entrance under Reduce Motion

    func testTheCongratulationSpringsInWhenMotionIsAllowed() {
        XCTAssertEqual(PlaceRoutineCongratulationEntrance.resolve(reduceMotion: false), .spring)
    }

    /// §7.2, and the rule this block is most at risk of getting wrong: under Reduce Motion the
    /// entrance is REPLACED by a fade, never removed. `nil` would be a hard cut, which is the
    /// bug rather than the fix.
    func testReduceMotionReplacesTheEntranceWithAFadeRatherThanRemovingIt() {
        XCTAssertEqual(PlaceRoutineCongratulationEntrance.resolve(reduceMotion: true), .fade)
    }

    // MARK: - E's answer 6: show every step, shrink to fit

    func testAShortRoutineGetsTheRoomiestRowsAndTheFullSizeGlyph() {
        let density = PlaceRoutineCongratulationDensity.forStepCount(4)
        XCTAssertEqual(density.circleSize, 28, "the size PlaceRoutineStepCircle already draws")
        XCTAssertEqual(density.rowSpacing, 16)
        XCTAssertEqual(density.rowHeight, 28)
    }

    /// E: *"showing every step as outlined is appropriate"* — so a long list shrinks rather
    /// than scrolling or truncating. **The glyph has to shrink too**: 20 rows of the hard 28 pt
    /// circle is 560 pt of glyph alone, and `minimumScaleFactor` scales `Text`, never a
    /// `Circle`.
    func testALongerRoutineTightensTheRowsAndShrinksTheGlyph() {
        let short = PlaceRoutineCongratulationDensity.forStepCount(4)
        let medium = PlaceRoutineCongratulationDensity.forStepCount(12)
        let long = PlaceRoutineCongratulationDensity.forStepCount(20)

        XCTAssertLessThan(medium.circleSize, short.circleSize)
        XCTAssertLessThan(long.circleSize, medium.circleSize)
        XCTAssertLessThan(medium.rowSpacing, short.rowSpacing)
        XCTAssertLessThan(long.rowSpacing, medium.rowSpacing)
    }

    /// CLAUDE.md §2: the table may only ever return grid spacings. `12` and `20` are banned,
    /// and a density table is exactly where an unmapped integer would hide.
    func testEverySpacingTheTableCanReturnIsOnTheFourEightSixteenTwentyFourGrid() {
        let offGrid = (0...40).map(PlaceRoutineCongratulationDensity.forStepCount)
            .map(\.rowSpacing)
            .filter { ![4, 8, 16, 24].contains($0) }
        XCTAssertTrue(offGrid.isEmpty, "off-grid spacings: \(offGrid)")
    }

    /// **E reversed answer 6's "no scrolling" on 2026-09-13:** *"Long routines with many steps
    /// should turn the overflow of a long routine steps list into a scrollable."*
    ///
    /// So the 21-step ceiling this test used to name is no longer a ceiling, and
    /// `estimatedHeight`/`listBudget` are gone with it — overflow scrolls instead of clipping.
    /// **The density table stays**, and that is a judgement rather than a given: shrinking means
    /// more steps are visible before anyone has to scroll at all, so the two work together.
    /// Stated at the render for E to overrule.
    func testTheDensityTableStillShrinksSoFewerRoutinesNeedScrollingAtAll() {
        XCTAssertLessThan(
            PlaceRoutineCongratulationDensity.forStepCount(20).rowHeight,
            PlaceRoutineCongratulationDensity.forStepCount(4).rowHeight,
            "shrink-and-scroll was the reading taken of E's reversal: scrolling handles true"
                + " overflow, shrinking keeps more steps on screen before it is needed"
        )
    }
}
