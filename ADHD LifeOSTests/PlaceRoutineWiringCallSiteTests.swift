//
//  PlaceRoutineWiringCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-6`'s C6: the guards that say the block's five BUILT pieces are actually
//  reachable. Its own file rather than more of `PlaceRoutineCompletionCallSiteTests`, which was
//  at the 250-line type-body bar — and the split is the honest one, because these read the
//  SCREEN while that file reads the leaves.
//
//  **Every guard here exists because C1–C5 deliberately shipped its pieces unreachable for one
//  commit each.** `PlaceRoutineCompletedCard`, `PlaceRoutineCongratulationView`,
//  `PlaceRoutineCongratulationEntrance` and the `.routineFinished` celebration kind were all
//  written, unit-tested, correct and called by NOTHING. That shape is this repo's most repeated
//  defect (six recorded instances), so the commit that wires them up is also the commit that
//  makes the wiring assertable.
//
//  Source is read with comment lines stripped and flattened to one line, the `*CallSiteTests`
//  house shape, so no guard can go green on a claim that only appears in a comment.
//

import XCTest

final class PlaceRoutineWiringCallSiteTests: XCTestCase {

    // MARK: - C6: the wiring — five pieces that were built and reachable by nothing

    /// C5 landed `PlaceRoutineCompletedCard` tested, correct and mounted by NOTHING, on purpose
    /// and for exactly one commit. This is the guard that says the commit happened: without it
    /// the card is this repo's most-repeated defect shape (six recorded instances) shipped
    /// deliberately.
    func testTheCompletedCardTakesTheNextStepSlotOnceNothingIsPending() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        XCTAssertTrue(
            screen.contains("PlaceRoutineCompletedCard(run: run, onComplete: complete(from:))"),
            "the Completed card is mounted by nothing, so E's R1 tap does not exist for a user"
        )
        XCTAssertTrue(
            screen.contains("} else if PlaceRoutineProgress.isFullyResolved(run) {"),
            "the card must take the slot the next-step card would have had — a card ADDED"
                + " beside a live next step would offer to finish a routine mid-way"
        )
    }

    /// The congratulation itself had no mount either. E has approved it by render; a render is
    /// not a call site.
    func testTheScreenSwapsItsOwnBodyForTheCongratulation() throws {
        XCTAssertTrue(
            try flattened("Places/PlaceRoutineScreen.swift")
                .contains("PlaceRoutineCongratulationView("),
            "E overruled \"close the screen and celebrate over the app\" — the screen's own body"
                + " is REPLACED by the congratulation, so the screen has to build it"
        )
    }

    /// **The swap is a `ZStack` and that is load-bearing rather than stylistic.** A `Group`
    /// re-runs `.task` when its branch changes, which would restart the Live Activity moments
    /// after `complete()` ended it — and NO other test could see that, because
    /// `RoutineActivityCallSiteTests` only asserts the `.task` string exists.
    func testTheBodySwapCannotRestartTheLiveActivityItJustEnded() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        XCTAssertTrue(screen.contains("ZStack {"), "the swap must not be a Group")
        XCTAssertEqual(
            screen.components(separatedBy: ".task {").count - 1, 1,
            "the screen starts its Activity more than once — hang `.task` on the ZStack, never"
                + " inside a branch, or finishing the routine starts a new Activity"
        )
    }

    /// §7.2 and §7.4: which entrance is a pure function of Reduce Motion, resolved by the
    /// SCREEN and applied as the branch's transition. `PlaceRoutineCongratulationEntrance` was
    /// unit-tested from the day it was written and called by nothing.
    func testTheScreenResolvesTheEntranceFromReduceMotion() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        XCTAssertTrue(
            screen.contains("PlaceRoutineCongratulationEntrance.resolve(reduceMotion: reduceMotion)"),
            "the entrance enum is decided by nobody, so Reduce Motion changes nothing on screen"
        )
        XCTAssertTrue(
            screen.contains(".transition(entrance.transition)"),
            "the resolved entrance never reaches a branch, so the swap is a hard cut"
        )
    }

    /// §7.2's rule for this block, stated as a guard: the reduced path REPLACES the motion with
    /// a fade and never removes the feedback. `withAnimation(nil)` — or `reduceMotion ? nil :`
    /// around the swap — is the hard cut the section exists to forbid, and it is the shape 19 of
    /// the app's 20 RM-guarded sites had when the policy was written.
    ///
    /// **This file's ONE `reduceMotion ? nil` is correct and must stay.** `apply(_:at:)` moves a
    /// step between the three cards, which is the continuous re-layout `nil` is right for — the
    /// tween IS the motion there and the instant change loses nothing. The count guard exists
    /// because the two cases are one line apart in the same type and read identically; the first
    /// draft of this test banned the pattern outright and reddened on the legitimate site.
    func testTheReducedSwapFadesRatherThanCuttingHard() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        XCTAssertTrue(
            screen.contains("withAnimation(entrance.animation) { confirmedAt = now }"),
            "the swap must run under the RESOLVED animation — both cases of which are non-nil"
        )
        let swap = try slice(
            of: "Places/PlaceRoutineScreen.swift",
            from: "private func complete(from origin: CGPoint?)", to: "private func leaveScreen()"
        )
        XCTAssertFalse(
            swap.contains("nil"),
            "the congratulation's swap is an APPEARANCE, not the continuous re-layout `nil` is"
                + " right for — a hard cut here is §7.2's named bug"
        )
        XCTAssertEqual(
            screen.components(separatedBy: "reduceMotion ? nil").count - 1, 1,
            "a second `reduceMotion ? nil` has appeared. Exactly one is sanctioned — the step"
                + " re-layout in `apply(_:at:)`. Anything that appears, disappears or celebrates"
                + " fades instead."
        )
    }

    /// E's R1, as the one guard that says it: **nothing is recorded and nothing celebrates
    /// without the tap.** Closing a fully-resolved checklist must leave the run live, which is
    /// why `leaveScreen()` no longer ends anything and why the journey now asserts the Today
    /// card SURVIVES a Close.
    func testOnlyTheCompletedTapEndsTheRun() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        let complete = try XCTUnwrap(
            screen.range(of: "private func complete(from origin: CGPoint?)"),
            "the Completed tap has no handler"
        )
        let leave = try XCTUnwrap(screen.range(of: "private func leaveScreen()"))
        let ending = try XCTUnwrap(
            screen.range(of: "store.end(runId: run.id)"),
            "nothing ends the local run"
        )
        XCTAssertTrue(
            complete.lowerBound < ending.lowerBound && ending.lowerBound < leave.lowerBound,
            "the run is ended somewhere other than the Completed tap. E's R1: a user who"
                + " resolves every step and closes the screen has NOT finished the routine, and"
                + " their card must still be on Today"
        )
        XCTAssertEqual(
            screen.components(separatedBy: "reason: .completed").count - 1, 1,
            "completion is recorded from more than one place, so leaving the screen can still"
                + " write the ending E's R1 reserved for the tap"
        )
    }

    /// The origin is the Completed BUTTON's measured centre, handed up by the card — the ring
    /// pattern, because `CelebrationPopSource`'s handle only ever requests `.pop`. Requesting at
    /// `nil` would throw the paper from the middle of the screen instead of the thing pressed.
    /// (That the milestone is asked for from exactly ONE place is
    /// `CelebrationMilestoneCallSiteTests`' half of this.)
    func testTheRoutineMilestoneLeavesFromTheButtonThatWasPressed() throws {
        XCTAssertTrue(
            try flattened("Places/PlaceRoutineScreen.swift")
                .contains("celebrate.request(.milestone(.routineFinished), at: origin)"),
            "the routine's milestone is requested without the origin the Completed card measured"
                + " and handed up, so it leaves from the centre of the screen"
        )
    }

    /// The confirmed moment is read four times by the detail block and once by the clock line.
    /// Read from `body` as `.now` it would tick — and since E reversed R5 this view can be on
    /// screen indefinitely, so it would tick VISIBLY.
    func testTheConfirmedMomentIsCapturedOnceRatherThanReadFromTheBody() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        XCTAssertTrue(
            screen.contains("@State private var confirmedAt: Date?"),
            "the confirmed moment must be captured in state at the tap"
        )
        XCTAssertFalse(
            screen.contains("confirmedAt: .now"),
            "the congratulation is handed a live clock, so its four times drift apart as it sits"
        )
    }

    /// The same `Date` reaches the RECORD and the greeting, so the Journal row and the
    /// on-screen "Confirmed 1:00 pm" can never disagree by the width of a Task hop.
    func testTheRecordAndTheGreetingShareOneMoment() throws {
        XCTAssertTrue(
            try flattened("Places/PlaceRoutineScreen.swift").contains("let now = Date.now"),
            "the ending is timestamped separately from the moment the greeting shows"
        )
    }

    /// E's R5 rewrote what the screen does on backgrounding: it used to END a fully-resolved run
    /// and dismiss itself. Under R1 that would finish a routine the user never confirmed —
    /// silently, while they were in another app.
    func testBackgroundingNoLongerFinishesTheRoutineBehindTheUsersBack() throws {
        let screen = try flattened("Places/PlaceRoutineScreen.swift")
        XCTAssertFalse(
            screen.contains("scenePhase"),
            "the scenePhase hook survives, so switching apps with every step resolved still ends"
                + " the run — the exact thing E's R1 reserved for the Completed tap"
        )
    }

    // MARK: - Reading the tree

    private func flattened(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw WiringSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    /// One member's body, so a guard about `complete(from:)` cannot be answered by a line in
    /// `apply(_:at:)` — the mistake this file's own §7.2 guard made on its first run.
    private func slice(of relativePath: String, from opening: String, to closing: String) throws -> String {
        let source = try flattened(relativePath)
        let start = try XCTUnwrap(source.range(of: opening), "no \(opening) in \(relativePath)")
        let end = try XCTUnwrap(
            source.range(of: closing, range: start.upperBound..<source.endIndex),
            "no \(closing) after \(opening) in \(relativePath)"
        )
        return String(source[start.upperBound..<end.lowerBound])
    }

    private enum WiringSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`) — if the file has not been written yet, that is the point."
            }
        }
    }
}
