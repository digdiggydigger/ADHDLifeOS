//
//  CTAHapticTidyCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-1`'s guards: the four haptic tidies and the closure card's spring-in.
//
//  These read the tree rather than calling anything, because there is nothing to call. A feel is
//  chosen inside a `Button`'s action closure and played through `UIFeedbackGenerator`, which
//  cannot be asserted against; what is actually at stake is WHICH feel sits in WHICH closure, and
//  that is a property of the source. The same reasoning as `ConfirmCelebrationCallSiteTests`.
//
//  Every assertion is scoped to its closure, never to the whole file, because three of the four
//  files already contain the target feel at a DIFFERENT site that must not move:
//  `CaptureDetailComponents` plays `.solid` on the notes save, `PlaceEditorView` plays `.solid`
//  when an address suggestion drops the pin, and `FocusTimerBar` plays `.light` on expand/collapse.
//  A whole-file `contains(".light")` on `FocusTimerBar` would be green on a tree where the Stop
//  confirmation buzzes nothing at all.
//

import XCTest
@testable import ADHD_LifeOS

final class CTAHapticTidyCallSiteTests: XCTestCase {

    // MARK: - The four haptic tidies (E: "Tidy all four")

    /// E's principle #5 — celebrate DOING, not ADDING. Sorting a capture is a completion, so it
    /// earns the completion feel; the triage screen has always played `.success` for the same verb
    /// (`CaptureInboxSections.sortedButton`) and the detail screen disagreed with it.
    func testSortingFromTheCaptureDetailScreenPlaysTheSameCompletionFeelAsTriage() throws {
        let closure = try Self.closure(
            in: "Capture/CaptureDetailComponents.swift",
            from: "private var sortedButton: some View {",
            to: "onSort()",
            missing: "The capture detail screen's Sorted button is not where this test expects it."
        )
        XCTAssertTrue(
            closure.contains("Haptics.play(.success)"),
            "Sorted on the capture DETAIL screen does not play the completion feel, so the same"
                + " verb feels different on the two screens that offer it."
        )
        XCTAssertFalse(
            closure.contains("Haptics.play(.solid)"),
            "Sorted on the capture detail screen still plays the committed-write feel."
        )
    }

    /// A nudge dismissed is a thing DONE — the streak it feeds is the app's own evidence of that.
    /// `.light` is the feel for "a minor press that isn't a commitment" (`Theme/Haptics.swift`),
    /// which is the wrong sentence for the button that closes the loop.
    func testDoneForNowPlaysTheCompletionFeelRatherThanAMinorPress() throws {
        let closure = try Self.closure(
            in: "Nudges/NudgeDueCard.swift",
            from: "Button(\"Done for now\") {",
            to: "onDismiss()",
            missing: "The nudge card's Done for now button is not where this test expects it."
        )
        XCTAssertTrue(
            closure.contains("Haptics.play(.success)"),
            "\"Done for now\" does not play the completion feel."
        )
        XCTAssertFalse(
            closure.contains("Haptics.play(.light)"),
            "\"Done for now\" still plays the minor-press feel reserved for non-commitments."
        )
    }

    /// Saving a place is a committed write, so `.solid` — and it must fire only once the write has
    /// LANDED. `onSave` returns false when the write failed, and a buzz on the way in would tell
    /// the user their place was saved at the exact moment it wasn't.
    func testSavingAPlaceBuzzesOnlyOnceTheWriteHasLanded() throws {
        let closure = try Self.closure(
            in: "Places/PlaceEditorView.swift",
            from: "if await onSave(place) {",
            to: "dismiss()",
            missing: "The place editor's save path is not where this test expects it."
        )
        XCTAssertTrue(
            closure.contains("Haptics.play(.solid)"),
            "Saving a place is silent, or buzzes somewhere other than inside the success branch —"
                + " a failed save would then feel exactly like one that landed."
        )
    }

    /// Stopping a sprint is a decision the user is stepping back from, not a completion: E's #5
    /// gives it the minor-press feel. It belongs in the CONFIRMATION's destructive button, which is
    /// where the sprint actually ends — the toolbar's Stop only raises the dialog, and buzzing
    /// there would mark a stop the user may still cancel.
    func testStoppingASprintBuzzesWhenTheConfirmationIsAcceptedRatherThanWhenItIsRaised() throws {
        let closure = try Self.closure(
            in: "Focus/FocusTimerBar.swift",
            from: "Button(FocusStopConfirmation.confirmTitle, role: .destructive) {",
            to: "service.stop()",
            missing: "The stop confirmation's destructive button is not where this test expects it."
        )
        XCTAssertTrue(
            closure.contains("Haptics.play(.light)"),
            "Confirming a sprint stop is silent. The `.light` further down this file is the"
                + " expand/collapse feel on `setCollapsed`, not this one."
        )
    }

    // MARK: - The closure card's spring-in

    /// E's #8. Both branches are asserted by string: a test that pinned only the spring would stay
    /// green on a build that dropped the reduced path, which is the failure CLAUDE.md §7.4 exists
    /// to catch. Under Reduce Motion the transition is opacity ALONE, so the card's first frame is
    /// already at final geometry and only the fade travels (§7.2's opening-pose rule).
    func testTheClosureCardSpringsInAndCrossFadesInsteadUnderReduceMotion() throws {
        let sections = try Self.appCode("Home/HomeMomentumSections.swift")
        XCTAssertTrue(
            sections.contains(
                ".transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))"
            ),
            "The closure card has no two-branch transition, so it either pops in unanimated or"
                + " scales under Reduce Motion."
        )
        XCTAssertTrue(
            sections.contains("reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8)"),
            "The card's arrival animation is not the record's spring with a plain ease beside it."
        )
        XCTAssertTrue(
            sections.contains("withAnimation(closureCardAnimation)"),
            "Nothing wraps the write in `withAnimation`, so the transition never runs."
        )
    }

    /// The transition only plays if EVERY write to `celebratedTask` is animated. Three writers move
    /// it today — the celebration card's Next, the close-from-Home success and Undo — so the guard
    /// is that exactly one bare assignment exists, and that it is the one inside the animated
    /// setter.
    ///
    /// Swept over the WHOLE app target, not just the sections file: `celebratedTask` is internal on
    /// `HomeView`, so any of that type's extension files could write it, and a guard that read one
    /// file would have called itself "every write" while watching a third of them.
    func testEveryWriteToTheCelebratedTaskGoesThroughTheAnimatedSetter() throws {
        var bareWrites = 0
        var writingFiles: [String] = []
        for file in try Self.everyAppSourceFile() {
            let occurrences = try Self.appCode(file).components(separatedBy: "celebratedTask = ").count - 1
            if occurrences > 0 {
                bareWrites += occurrences
                writingFiles.append("\(file) x\(occurrences)")
            }
        }
        XCTAssertEqual(
            bareWrites, 1,
            "There are \(bareWrites) bare writes to `celebratedTask` (\(writingFiles.joined(separator: ", ")))"
                + ", not the single one inside `setCelebratedTask`. A writer that bypasses the"
                + " setter makes the card appear or vanish with no animation at all."
        )
        let setter = try Self.closure(
            in: "Home/HomeMomentumSections.swift",
            from: "func setCelebratedTask(",
            to: "celebratedTask = ",
            missing: "There is no `setCelebratedTask`, so the three writers animate individually."
        )
        XCTAssertTrue(
            setter.contains("withAnimation(closureCardAnimation)"),
            "`setCelebratedTask` writes without animating."
        )
        let home = try Self.appCode("Home/HomeView.swift")
        XCTAssertTrue(
            home.contains("@Environment(\\.accessibilityReduceMotion)")
                && home.contains("var reduceMotion"),
            "`HomeView` never reads Reduce Motion, so the sections file cannot resolve it — §7.2's"
                + " rule that the parent reads the setting and passes the resolved value down."
        )
    }

    // MARK: - Reading the tree

    /// The source between two markers, so an assertion lands on ONE closure rather than the file.
    /// Loud on a miss: a guard that quietly matches nothing is the defect these tests exist to
    /// prevent, so a moved anchor fails the test rather than silently passing an empty string.
    private static func closure(
        in relativePath: String,
        from opening: String,
        to closing: String,
        missing: String
    ) throws -> String {
        let source = try appCode(relativePath)
        guard let start = source.range(of: opening) else {
            throw CTAHapticSourceError.anchorMissing(relativePath, opening, missing)
        }
        guard let end = source.range(of: closing, range: start.upperBound..<source.endIndex) else {
            throw CTAHapticSourceError.anchorMissing(relativePath, closing, missing)
        }
        return String(source[start.upperBound..<end.lowerBound])
    }

    /// Every Swift file in the app target, as paths relative to `ADHD LifeOS/`.
    private static func everyAppSourceFile() throws -> [String] {
        let root = appRoot()
        guard let walker = FileManager.default.enumerator(atPath: root.path) else {
            throw CTAHapticSourceError.unreadable(root.path)
        }
        let files = walker.compactMap { $0 as? String }.filter { $0.hasSuffix(".swift") }
        guard files.count > 100 else {
            throw CTAHapticSourceError.unreadable("\(root.path) yielded only \(files.count) Swift files")
        }
        return files
    }

    private static func appRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    /// The same source with every comment line removed, because these files document the very
    /// feels and anti-patterns the assertions look for.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = appRoot().appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw CTAHapticSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum CTAHapticSourceError: Error, CustomStringConvertible {
        case unreadable(String)
        case anchorMissing(String, String, String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            case .anchorMissing(let file, let anchor, let why):
                return "\(file) does not contain `\(anchor)`. \(why)"
            }
        }
    }
}
