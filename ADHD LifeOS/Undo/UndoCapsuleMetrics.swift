//
//  UndoCapsuleMetrics.swift
//  ADHD LifeOS
//
//  `F-C1-UndoCapsule`: the capsule's numbers, its layout rule and its one animation, kept out of
//  the view body for the reason every presentation type in this app is — a SwiftUI body is ~0%
//  covered by design, so a rule left inside one is a rule nothing checks.
//

import SwiftUI

/// E's round-2b shape, as numbers.
enum UndoCapsuleMetrics {
    /// **44 since E's height round, 2026-09-20.** It shipped at 48 with a two-line `.callout`
    /// subject, which drew a **74pt** card — E marked a **45.3pt** band on
    /// `screenshots/undo-capsule/02-…-EDITED.jpg`: *"the UndoCapsule must be made smaller in
    /// height, it looks ugly with the UndoCapsule at the same height as the FAB Icon."* (The
    /// capture disc is 60.) E was shown four shapes rendered on the real screen and chose **two
    /// lines, a size smaller** — board `54`'s arrangement kept, the type stepped down.
    ///
    /// **A floor, not a frame.** A fixed height would clip the stacked layout at accessibility
    /// sizes. 44 is also §3's touch floor, so the capsule is itself exactly one touch target tall.
    static let minHeight: CGFloat = 44

    /// The Undo control's LAYOUT height. **Its TARGET is still 44** — see `undoHitOverflow`.
    ///
    /// Round 7's *"48pt for anything that … undoes"* cannot be drawn inside a 44pt band, and E
    /// chose the trade explicitly over keeping the capsule tall: *"Yes — draw 32, tap 44"*. Round
    /// 7's number was written for a control that owns its space; this one now sits inside one.
    ///
    /// **Since E's shape round this is pure mechanism: nothing is drawn behind the control at
    /// all.** While the chip existed, 32 was a visible pill and a shrunken target had a second
    /// witness on screen. E removed the chip, so these two numbers and the two padding lines that
    /// spend them are the whole of §3's 44pt floor here, and the tests are the only witness left.
    static let undoDrawnHeight: CGFloat = 32

    /// The tab bar's own trick (`AppTabBarMetrics.slotHitOverflow`), applied here: negative
    /// vertical padding around the `contentShape`, so the layout stays the pill's drawn height
    /// while taps a little above and below it still land. §3's 44pt is kept without drawing 44pt.
    static var undoHitOverflow: CGFloat { max(0, (44 - undoDrawnHeight) / 2) }

    /// **Fully rounded since E's shape round, 2026-09-20 — a shape, not a radius number.**
    ///
    /// It shipped wearing `AppSearchRowMetrics.fieldCornerRadius`, on the reasoning that a second
    /// radius beside the row it stands in for would read as a different control in the same slot.
    /// E overruled that on the phone — *"increase the corner radius of the entire UndoCapsule
    /// card"* — and then, shown eight shapes rendered on the real Tasks screen, chose by looking:
    /// *"from the images you've made Option C, 'Fully rounded' looks the best"*.
    ///
    /// **A concrete shape, deliberately not erased.** `strokeBorder` requires an
    /// `InsettableShape`; `AnyShape` is not one, which is what bit the render build.
    /// `UndoCapsuleCardShape` is, so the fill and the border can read the same value.
    static var cardShape: UndoCapsuleCardShape { UndoCapsuleCardShape() }

    /// How round the card is at a given height. **Fully rounded up to the height E chose, and no
    /// rounder above it.**
    ///
    /// **The cap is E's own second call, 2026-09-20, made by looking at the accessibility layout.**
    /// A bare `Capsule` takes its radius from half the card's height, and every frame of the shape
    /// round was rendered at the DEFAULT text size, where the card is 44pt and that radius is a
    /// harmless 22. At Accessibility XL the stacked card measures **194.3pt**: the caps grow to
    /// **97.2pt**, the curve eats the corners the content sits in, and the completion glyph was
    /// drawn **59pt** outside the card's own fill with the ↶ Undo control **30pt** outside it —
    /// measured off the render, not estimated. Shown both shapes on the real screen, E chose the
    /// cap.
    ///
    /// **This is not a compromise on what E approved.** At 44pt `min(44, 44) / 2` IS 22 — the
    /// capsule's own radius — and the two renders of the real Tasks screen came back byte-identical
    /// over the capsule band (max channel delta 0, zero differing pixels). The cap changes the
    /// accessibility layout and nothing else. It is a CEILING, not a fixed corner: a card shorter
    /// than the floor is still fully rounded.
    static func cardCornerRadius(forHeight height: CGFloat) -> CGFloat {
        min(height, minHeight) / 2
    }

    // MARK: - §2's grid, one name per gap

    /// The page margin, matching `AppSearchRow`'s own.
    static let horizontalPadding: CGFloat = 16
    /// 4 since the height round — 8 top and bottom is a fifth of E's whole band.
    static let verticalPadding: CGFloat = 4
    /// Asset-to-text: the glyph and the verb beside it.
    static let glyphSpacing: CGFloat = 8
    /// Micro positioning: the verb over the subject it names.
    static let verbToSubjectSpacing: CGFloat = 4
    /// Inter-element: the words and the Undo control.
    static let undoSpacing: CGFloat = 8
    /// The stacked (accessibility) layout's row gap.
    static let stackedSpacing: CGFloat = 8
    /// Glyph to word inside the Undo control.
    ///
    /// **There is no `undoHorizontalPadding` beside it any more, and it is DELETED rather than
    /// zeroed** (E's shape round, 2026-09-20). Its 16pt a side padded the INSIDE of the chip E
    /// removed; with nothing drawn behind the control it was 32pt of invisible dead space taken
    /// from the subject next to it, which is what had been truncating task titles. Spending it on
    /// the one line is what let E keep the 44pt card rather than pay 15pt for a second line.
    /// Zeroed, it would FAIL `testEveryCapsuleSpacingIsOnTheGrid` — 0 is not in {4, 8, 16, 24} —
    /// and the tempting fix would weaken a rule protecting every other value here.
    static let undoGlyphSpacing: CGFloat = 8

    /// Every gap the capsule spends, so §2's grid is a property a test can sweep rather than a
    /// convention each new value has to remember.
    static var spacings: [(name: String, value: CGFloat)] {
        [
            ("horizontalPadding", horizontalPadding),
            ("verticalPadding", verticalPadding),
            ("glyphSpacing", glyphSpacing),
            ("verbToSubjectSpacing", verbToSubjectSpacing),
            ("undoSpacing", undoSpacing),
            ("stackedSpacing", stackedSpacing),
            ("undoGlyphSpacing", undoGlyphSpacing)
        ]
    }
}

/// Which way the capsule lays itself out.
enum UndoCapsuleLayout {
    /// E, round 2b: *"a stacked layout at accessibility sizes"*. Pure, so the rule is checked
    /// without a rendered view — the layout itself is then a single `if` over this answer.
    static func isStacked(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }
}

/// The capsule's one motion.
enum UndoCapsuleMotion {
    /// §7.2: something that APPEARS gets a fade under Reduce Motion, never a cut.
    ///
    /// **The opening-pose rule is satisfied by construction here.** E's shape A moves nothing and
    /// stacks nothing — the capsule arrives in the slot the search row was already occupying — so
    /// the geometry is final on the first frame in BOTH modes and only the opacity ever travels.
    /// That is why this is one curve rather than a curve plus a set of pinned offsets.
    static func appearance(reduceMotion: Bool) -> Animation {
        reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    }
}

/// The capsule's card, drawn as a shape rather than a radius number so `UndoCapsuleMetrics`'s one
/// rule decides how round it is at every height (`cardCornerRadius(forHeight:)`).
///
/// **Insettable on purpose.** `strokeBorder` — the only way to stroke a border that sits INSIDE
/// the fill rather than straddling it — requires `InsettableShape`, and `AnyShape` is not one.
/// That is what bit the redesign round's render build, so the shape stays concrete and implements
/// `inset(by:)` itself.
struct UndoCapsuleCardShape: InsettableShape {
    private var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path(
            roundedRect: inset,
            cornerRadius: UndoCapsuleMetrics.cardCornerRadius(forHeight: inset.height),
            style: .continuous
        )
    }

    func inset(by amount: CGFloat) -> UndoCapsuleCardShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
