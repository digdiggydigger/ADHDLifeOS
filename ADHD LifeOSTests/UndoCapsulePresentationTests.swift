//
//  UndoCapsulePresentationTests.swift
//  ADHD LifeOSTests
//
//  `F-C1-UndoCapsule`: the words, the glyphs and the geometry E chose in round 2b (board `54`,
//  option **A · Capsule in the disc row**).
//
//  These are pure functions rather than view-body reads for the reason every presentation type in
//  this app is pure: a SwiftUI body is ~0% covered by design, so a rule left inside one is a rule
//  nothing checks.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

final class UndoCapsulePresentationTests: XCTestCase {

    // MARK: - The words (E: "a glyph plus words naming what happened")

    func testEachKindNamesWhatHappenedInOneVerb() {
        XCTAssertEqual(RecentActionKind.taskClosed.verb, "Closed")
        XCTAssertEqual(RecentActionKind.nudgeDismissed.verb, "Done for now")
        XCTAssertEqual(RecentActionKind.captureSkipped.verb, "Skipped")
        XCTAssertEqual(RecentActionKind.captureJournalled.verb, "Journalled")
    }

    /// The area travels in the verb, exactly as the retired inbox bar said it — "Sorted to 💼 Work".
    func testSortingNamesTheAreaItFiledInto() {
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: "💼 Work").verb, "Sorted to 💼 Work")
    }

    /// A deleted area degrades to the bare verb rather than quoting a raw id — the rule the inbox
    /// bar already held, carried over rather than re-decided.
    func testSortingIntoAnAreaThatIsGoneSaysJustSorted() {
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: nil).verb, "Sorted")
    }

    // MARK: - The glyph

    func testACloseAndANudgeCarryTheCompletionGlyphInTheGoTint() {
        for kind in [RecentActionKind.taskClosed, .nudgeDismissed] {
            XCTAssertEqual(kind.systemImage, "checkmark.circle.fill", "\(kind) lost the completion glyph.")
            XCTAssertEqual(kind.glyphTint, .completion, "\(kind) is a completion, so its glyph is the go tint.")
        }
    }

    func testTheThreeTriageVerbsEachCarryTheirOwnGlyph() {
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: nil).systemImage, "tray.full.fill")
        XCTAssertEqual(RecentActionKind.captureJournalled.systemImage, "book.closed.fill")
        XCTAssertEqual(RecentActionKind.captureSkipped.systemImage, "arrow.triangle.2.circlepath")
    }

    /// A skip is not a completion and must not read as one — it is the one kind whose glyph is
    /// quiet. Both others are accented, matching the tab their subject lives on.
    func testASkipIsTheOneQuietGlyph() {
        XCTAssertEqual(RecentActionKind.captureSkipped.glyphTint, .secondary)
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: nil).glyphTint, .accent)
        XCTAssertEqual(RecentActionKind.captureJournalled.glyphTint, .accent)
    }

    // MARK: - The geometry

    /// **Reversed by E's height round, 2026-09-20, not deleted.** It pinned 48 and *"deliberately
    /// NOT the search field's 44"*. E measured the shipped capsule against the 60pt capture disc
    /// and marked a 45.3pt band: *"it looks ugly with the UndoCapsule at the same height as the
    /// FAB Icon."* So the capsule IS the search field's height now, and that is the point rather
    /// than a coincidence — it stands in that row's slot, and 44 is also §3's touch floor.
    func testTheCapsuleIsOneTouchTargetTallAfterEsHeightRound() {
        XCTAssertEqual(UndoCapsuleMetrics.minHeight, 44)
        XCTAssertEqual(
            UndoCapsuleMetrics.minHeight, AppSearchRowMetrics.fieldHeight,
            "The capsule stands in the search row's slot; matching its height is deliberate."
        )
    }

    /// **Reversed by E's shape round, 2026-09-20, not deleted.** It pinned the search row's own
    /// corner, reasoning that *"a second radius beside the row it replaces would read as a
    /// different control in the same slot"*. E overruled that reasoning by LOOKING, on the phone:
    /// *"I also recommend that we remove the blue chip background colour behind the "Undo" Button
    /// and increase the corner radius of the entire UndoCapsule card"* — then, shown eight shapes
    /// rendered on the real Tasks screen, *"from the images you've made Option C, 'Fully rounded'
    /// looks the best"*.
    ///
    /// So the card is fully rounded — **up to the height E chose, and no rounder above it.**
    ///
    /// **The cap is E's own second call, made the same day by looking at the accessibility
    /// layout** (`screenshots/undo-capsule/`'s AX3 frames). A true `Capsule` takes its radius from
    /// half the card's height, and every frame of the shape round was rendered at the DEFAULT text
    /// size, where the card is 44pt and that radius is a harmless 22. At Accessibility XL the
    /// stacked card measures **194.3pt**, so the caps grow to **97.2pt** and the curve eats the
    /// corners the content sits in: the completion glyph was drawn **59pt** outside the card's own
    /// fill and the ↶ Undo control **30pt** outside it — measured, not estimated. Shown both, E
    /// chose the cap.
    ///
    /// **It is not a compromise on what E approved.** At 44pt `min(44, 44) / 2` IS 22, the
    /// capsule's own radius — the two renders of the real screen were byte-identical over the
    /// capsule band (max channel delta 0, zero differing pixels). The cap changes the accessibility
    /// layout and nothing else.
    func testTheCardIsFullyRoundedUpToTheHeightEChoseAndNoRounderAboveIt() {
        XCTAssertEqual(
            UndoCapsuleMetrics.cardCornerRadius(forHeight: UndoCapsuleMetrics.minHeight),
            UndoCapsuleMetrics.minHeight / 2,
            "At the height E approved the card must be a true capsule — the frames E chose from"
                + " were all rendered at this height."
        )

        XCTAssertEqual(
            UndoCapsuleMetrics.cardCornerRadius(forHeight: 194.3), UndoCapsuleMetrics.minHeight / 2,
            "The radius grew with the accessibility layout's height. 194.3pt is the stacked card"
                + " measured at Accessibility XL, where a true capsule's 97.2pt caps drew the glyph"
                + " and the Undo control off the card."
        )

        XCTAssertEqual(
            UndoCapsuleMetrics.cardCornerRadius(forHeight: 30), 15,
            "A card SHORTER than the floor must still be fully rounded — the cap is a ceiling on"
                + " the radius, never a fixed corner."
        )
    }

    /// **Reversed with the height round, then STRENGTHENED by E's shape round — and it is now the
    /// ONLY guard.** Round 7's 48pt cannot be drawn inside a 44pt band, and E chose the trade by
    /// name: *"Yes — draw 32, tap 44"*. So the pill is drawn at 32 and its hit area is grown back
    /// to §3's 44 with the tab bar's own negative-padding trick.
    ///
    /// Until the shape round the drawn 32 was VISIBLE — a tinted chip — so a target that had
    /// quietly shrunk with it had a second witness on screen. **E removed the chip, so nothing on
    /// screen shows the tap target any more** and this assertion is all that stands between §3's
    /// 44pt floor and a silent regression. It is `apple-design`'s one Medium finding on the round
    /// (`buttons.md › Best practices`: *"a button needs a hit region of at least 44x44 pt"*).
    /// `undoDrawnHeight` and `undoHitOverflow` are pure layout mechanism now rather than a pill,
    /// which is why `UndoCapsuleCallSiteTests` also pins the two lines that spend them.
    func testTheUndoControlIsDrawnSmallerThanItsTapTargetAndTheTargetIsStillFortyFour() {
        XCTAssertEqual(UndoCapsuleMetrics.undoDrawnHeight, 32)
        XCTAssertEqual(
            UndoCapsuleMetrics.undoDrawnHeight + 2 * UndoCapsuleMetrics.undoHitOverflow, 44,
            "The drawn pill plus its overflow no longer reaches §3's 44pt touch floor."
        )
        XCTAssertEqual(UndoCapsuleMetrics.undoHitOverflow, 6)
    }

    /// The capsule is exactly one touch target tall, so the control inside it cannot be taller
    /// than the card that holds it — which is what E was looking at when they said it read as the
    /// same size as the disc.
    func testTheDrawnControlFitsInsideTheCardWithItsPaddingToSpare() {
        let spent = UndoCapsuleMetrics.undoDrawnHeight + 2 * UndoCapsuleMetrics.verticalPadding
        XCTAssertLessThanOrEqual(
            spent, UndoCapsuleMetrics.minHeight,
            "The pill and the card's padding come to \(spent)pt, which would push the card past"
                + " \(UndoCapsuleMetrics.minHeight)pt and undo E's height round."
        )
    }

    /// Every padding the capsule spends is on §2's 4/8/16/24 grid. The two sanctioned off-grid
    /// values in this app (`peekStep`, `floatingPaddingHorizontal`) are named waivers for other
    /// controls and do not reach here.
    ///
    /// **This is why E's reclaimed Undo padding is DELETED rather than zeroed** (shape round,
    /// 2026-09-20): 0 is not in the grid, so a zeroed constant would FAIL here rather than lapse,
    /// and the tempting fix — widening the set — would quietly weaken a rule protecting every
    /// other value in the file.
    func testEveryCapsuleSpacingIsOnTheGrid() {
        let grid: Set<CGFloat> = [4, 8, 16, 24]
        for (name, value) in UndoCapsuleMetrics.spacings {
            XCTAssertTrue(grid.contains(value), "`\(name)` is \(value), which is off §2's 4/8/16/24 grid.")
        }
    }

    /// **The bug E fixed, written as geometry: is the content's own corner ON the card?**
    ///
    /// This is the assertion the whole cap exists for, and it is the one a radius number cannot
    /// make. The capsule's content sits `horizontalPadding` in from the leading edge with the
    /// completion glyph near the top, so the card's fill has to reach that point at EVERY height
    /// the layout can take — including the 194.3pt stacked card measured at Accessibility XL,
    /// which is where a true capsule's 97.2pt caps left the glyph 59pt outside its own fill.
    ///
    /// Sampling the drawn path rather than the radius is deliberate: it is the only form of this
    /// test that stays true if the shape is ever rebuilt a different way.
    func testTheContentsOwnCornerSitsOnTheCardAtEveryHeightTheLayoutCanTake() {
        let width: CGFloat = 361   // the capsule's width on an iPhone 17 Pro, measured
        let contentCorner = CGPoint(x: UndoCapsuleMetrics.horizontalPadding, y: 8)

        for height in [UndoCapsuleMetrics.minHeight, 100, 194.3, 260] as [CGFloat] {
            let path = UndoCapsuleMetrics.cardShape.path(
                in: CGRect(x: 0, y: 0, width: width, height: height)
            )
            XCTAssertTrue(
                path.contains(contentCorner),
                "At \(height)pt the card's fill does not reach \(contentCorner) — the corner the"
                    + " completion glyph is drawn in. That is E's Accessibility XL break: the"
                    + " radius grew with the card and the curve ate the content's corner."
            )
        }
    }

    /// **`strokeBorder` draws INSIDE the fill, and that needs a shape that insets itself.**
    /// `AnyShape` is not `InsettableShape`, which is what bit the redesign round's render build;
    /// the house answer is a concrete shape that implements `inset(by:)`. A shape that ignored the
    /// amount would compile, satisfy `strokeBorder`, and quietly stroke ON the card's edge, so the
    /// border would straddle the boundary and read as a half-pixel smudge in both appearances.
    ///
    /// The insets must also ACCUMULATE, because SwiftUI applies `strokeBorder`'s half-line-width
    /// through the same call the view's own inset would come through.
    func testTheBorderInsetsItselfInsideTheFillAndTheInsetsAccumulate() {
        let rect = CGRect(x: 0, y: 0, width: 361, height: UndoCapsuleMetrics.minHeight)

        XCTAssertEqual(
            UndoCapsuleMetrics.cardShape.inset(by: 1).path(in: rect).boundingRect,
            rect.insetBy(dx: 1, dy: 1),
            "The shape ignores its inset, so the card's border straddles the fill's edge instead"
                + " of sitting inside it."
        )
        XCTAssertEqual(
            UndoCapsuleMetrics.cardShape.inset(by: 1).inset(by: 2).path(in: rect).boundingRect,
            rect.insetBy(dx: 3, dy: 3),
            "Insets replace one another rather than accumulating, so a second inset silently"
                + " discards the first."
        )
    }

    /// **E's shape round reclaimed the Undo control's horizontal padding, 16 → 0.** With the chip
    /// gone its 16pt a side was padding the inside of nothing — 32pt of invisible dead space beside
    /// the subject, which is what had been truncating task titles. Spending it on the one line is
    /// what let E keep the 44pt card instead of paying 15pt for a second line.
    ///
    /// This is the metrics half of the guard. The view half is in `UndoCapsuleCallSiteTests`,
    /// because a padding reinstated inline would pass here and still undo E's decision.
    func testTheUndoControlSpendsNoHorizontalPaddingSinceEReclaimedIt() {
        XCTAssertFalse(
            UndoCapsuleMetrics.spacings.contains { $0.name.localizedCaseInsensitiveContains("undoHorizontal") },
            "A horizontal padding is back on the Undo control — the 32pt E reclaimed to widen the"
                + " single subject line."
        )
    }

    // MARK: - The one motion (§7.4: pure logic is tested by CALLING it)

    /// **Found by reading the coverage report, not by a failing test.** The two-branch guard in
    /// `CTAHapticTidyCallSiteTests` matches this function's SOURCE, which kept it at 0% — a string
    /// assertion proves the branch is written, never that it resolves. §7.4 asks for both: the
    /// call-site test for the shape, an ordinary unit test for the answer.
    func testTheArrivalIsASpringNormallyAndAPlainEaseUnderReduceMotion() {
        XCTAssertEqual(
            UndoCapsuleMotion.appearance(reduceMotion: false),
            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
        )
        XCTAssertEqual(UndoCapsuleMotion.appearance(reduceMotion: true), .default)
    }

    /// Never `nil`. §7.2: the capsule APPEARS and DISAPPEARS, which is the case a hard cut is
    /// wrong for — `reduceMotion ? nil : …` is correct only for continuous re-layout.
    func testTheReducedPathIsAFadeRatherThanNoAnimationAtAll() {
        XCTAssertNotEqual(
            UndoCapsuleMotion.appearance(reduceMotion: true),
            UndoCapsuleMotion.appearance(reduceMotion: false),
            "Both modes resolve the same curve, so one of the two branches is doing nothing."
        )
    }

    // MARK: - The inert default

    /// Both halves of the environment default do nothing and neither traps, so a preview or a
    /// snapshot renders a close button with no capsule and no setup.
    func testTheInertRecorderSwallowsBothVerbs() {
        let inert = InertRecentActionRecorder()
        inert.record(RecentAction(kind: .taskClosed, subject: "x", undo: { true }))
        inert.clear()
    }

    // MARK: - What VoiceOver is told (`voiceover.md` — report a visible change)

    /// The capsule is the LAST element on the screen and on Tasks it takes the search row's place,
    /// so a VoiceOver user gets no sign the undo exists unless the arrival is announced. The words
    /// are the two the capsule draws, then the offer.
    func testTheAnnouncementNamesWhatHappenedWhatItHappenedToAndTheOffer() {
        let action = RecentAction(
            kind: .taskClosed, subject: "Pay the council tax instalment", undo: { true }
        )

        XCTAssertEqual(
            action.accessibilityAnnouncement,
            "Closed. Pay the council tax instalment. Undo available."
        )
    }

    /// The area travels into the announcement with the verb, so a sorted capture is as specific
    /// spoken as it is drawn.
    func testTheAnnouncementCarriesTheAreaASortFiledInto() {
        let action = RecentAction(
            kind: .captureSorted(areaLabel: "💼 Work"), subject: "Bike repair receipt", undo: { true }
        )

        XCTAssertEqual(
            action.accessibilityAnnouncement,
            "Sorted to 💼 Work. Bike repair receipt. Undo available."
        )
    }

    // MARK: - The stacked layout at accessibility sizes (E, round 2b)

    func testTheCapsuleStacksAtAccessibilitySizesAndOnlyThere() {
        for size in DynamicTypeSize.allCases {
            XCTAssertEqual(
                UndoCapsuleLayout.isStacked(size), size.isAccessibilitySize,
                "\(size) resolves the wrong layout — E asked for a stacked one at accessibility sizes."
            )
        }
    }
}
