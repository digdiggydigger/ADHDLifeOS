//
//  FocusBarCollapse.swift
//  ADHD LifeOS
//

import SwiftUI

/// Reads a drag on the focus bar's card as an intent (F-FocusCard-1).
///
/// **Direction-aware, deliberately not a toggle.** E's requirement is *"the ability to swipe up
/// and down to switch between the 2 different states"* — two gestures with two meanings, not one
/// gesture that flips whatever is there. A toggle would collapse an already-collapsed card on a
/// second downward flick, which is the shape of an accidental double-swipe and reads as the card
/// bouncing under the thumb.
enum FocusBarCollapseSwipe {
    /// How far the thumb must travel before the card moves. Below it the drag was a tap that
    /// wandered — and the card's only collapsed control is Pause, which sits directly under it.
    static let threshold: CGFloat = 24

    enum Outcome: Equatable {
        case collapse
        case expand
        case none
    }

    /// `translation` is `DragGesture.Value.translation.height`, so **positive is downward** in
    /// SwiftUI's coordinate space — and down collapses, per the three green arrows on E's
    /// annotated screenshot (`IMG_8307.jpg`).
    ///
    /// The threshold is inclusive: an exclusive `>` leaves exactly one dead value, which on device
    /// reads as an intermittently unresponsive card rather than as an off-by-one.
    static func outcome(forTranslation translation: CGFloat, isCollapsed: Bool) -> Outcome {
        guard abs(translation) >= threshold else { return .none }
        if translation > 0 {
            return isCollapsed ? .none : .collapse
        }
        return isCollapsed ? .expand : .none
    }
}

/// The card's outline: a rounded rectangle with a top radius and a bottom one, the bottom being
/// the half that changes between states and the half that animates.
///
/// **The history matters, because the reasoning that produced the square corners was sound and E
/// overruled the conclusion anyway.** E chose full-bleed-with-rounded-top for the collapsed card
/// over a plain inset and over a squared-off strip; then, told that top-only rounding 100pt above
/// the screen bottom would leave the square bottom corners hanging in mid-air, chose *"Drop it
/// flush to the tab bar"*. So the two were one shape: square bottom corners were correct only
/// because they sat ON the bar, and `FocusBarMetrics.collapsedOffsetY` was what put them there.
///
/// **E reversed the corner half on 2026-09-11 — *"Round them"* — and the flush drop STAYED.**
/// They are separable after all: the card still landed on the bar, and the rounding simply let the
/// page read through the notch where the two met. `F-FocusCard-Corners`, and
/// `screenshots/focus-card-bottom-corners/` is the render E chose the radius from.
///
/// **E reversed the drop too, on 2026-09-17 (`F-CollapsedBarLift`)**, in portrait and landscape:
/// *"Line up with the Disc, But when there are multiple cards being displayed, then maintain the
/// alignment."* The card now sits on the disc's line, 24pt above the bar, with its 24pt radius and a
/// keyline closed on all four sides.
///
/// **`InsettableShape` is not optional here.** The card is drawn twice — `.background` and an
/// `.overlay(...strokeBorder...)` — and `strokeBorder` insets the shape by half the line width so
/// the 1pt border lands *inside* the bounds. A plain `Shape` would force `.stroke`, which centres
/// the line and leaves half of it outside the card, visibly proud of the screen edge in the
/// collapsed state.
struct FocusBarCardShape: Shape, InsettableShape {
    var cornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    /// **The block's second half, and it is honest to say it is currently inert.**
    /// `roundsBottomCorners` was a `Bool`, and a flag cannot tween: mid-spring the corners flipped
    /// from square to round in one frame while the card was still moving. Wiring the radius here
    /// is what lets SwiftUI walk it instead.
    ///
    /// E then chose a collapsed radius EQUAL to the expanded one, so as it stands the two states
    /// do not differ and nothing interpolates — the snap is gone because the difference is gone,
    /// not because this is running. It stays because a `Shape` with a continuous parameter is
    /// supposed to declare it, and because the day the two numbers differ again the corner morphs
    /// rather than jumping. `testTheBottomCornerRadiusIsTheAnimatableData` holds it.
    var animatableData: CGFloat {
        get { bottomCornerRadius }
        set { bottomCornerRadius = newValue }
    }
    /// Accumulated by `inset(by:)`. It shrinks the rect **and** the radius, so an inset copy stays
    /// concentric with the original instead of bulging at the corners.
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = FocusBarCardOutline.path(
            in: bounds,
            topRadius: FocusBarCardOutline.clamped(cornerRadius - insetAmount, in: bounds),
            bottomRadius: FocusBarCardOutline.clamped(bottomCornerRadius - insetAmount, in: bounds)
        )
        // Closing draws the flat bottom RUN — for the fill, and since `F-CollapsedBarLift` for the
        // keyline too, which is `strokeBorder` on this same shape.
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> FocusBarCardShape {
        var inset = self
        inset.insetAmount += amount
        return inset
    }
}

/// The card's silhouette, shared by the fill and the keyline.
///
/// **Two radii, because the collapsed card's bottom corners are their own number.**
/// `UIBezierPath(roundedRect:byRoundingCorners:cornerRadii:)`, which this replaced, applies ONE
/// radius to whichever corners are selected — fine for a flag, useless for a morph, and the morph
/// is half of `F-FocusCard-Corners`.
///
/// Angles follow SwiftUI's flipped Y, the convention the keyline already used: 180° is left, 270°
/// top, 0°/360° right, 90° bottom, and `clockwise: false` walks them in increasing order.
enum FocusBarCardOutline {
    /// A radius that cannot exceed the box it is cutting. Without this a 24pt corner on a card
    /// shorter than 48pt produces a self-crossing path rather than a pill.
    static func clamped(_ radius: CGFloat, in bounds: CGRect) -> CGFloat {
        max(0, min(radius, min(bounds.width, bounds.height) / 2))
    }

    /// From the bottom-left corner's end, up the left side, across the top, and down to the
    /// bottom-right corner's end. **The flat bottom RUN is not part of it**; `FocusBarCardShape`
    /// closes the path to draw one. (An open-path keyline, `FocusBarCardBorder`, used to leave the
    /// run out for the card sitting flush on the tab bar; it was deleted with the flush drop.)
    static func path(in bounds: CGRect, topRadius: CGFloat, bottomRadius: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: bounds.minX + bottomRadius, y: bounds.maxY))
        addCorner(
            to: &path, centre: CGPoint(x: bounds.minX + bottomRadius, y: bounds.maxY - bottomRadius),
            radius: bottomRadius, from: 90, through: 180
        )
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + topRadius))
        addCorner(
            to: &path, centre: CGPoint(x: bounds.minX + topRadius, y: bounds.minY + topRadius),
            radius: topRadius, from: 180, through: 270
        )
        path.addLine(to: CGPoint(x: bounds.maxX - topRadius, y: bounds.minY))
        addCorner(
            to: &path, centre: CGPoint(x: bounds.maxX - topRadius, y: bounds.minY + topRadius),
            radius: topRadius, from: 270, through: 360
        )
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - bottomRadius))
        addCorner(
            to: &path, centre: CGPoint(x: bounds.maxX - bottomRadius, y: bounds.maxY - bottomRadius),
            radius: bottomRadius, from: 0, through: 90
        )
        return path
    }

    /// A zero radius is a real state here — it is the floor of the morph and the shape that
    /// shipped — so it draws the square corner rather than a degenerate arc.
    private static func addCorner(
        to path: inout Path, centre: CGPoint, radius: CGFloat, from: Double, through: Double
    ) {
        guard radius > 0 else { return path.addLine(to: centre) }
        path.addArc(
            center: centre, radius: radius,
            startAngle: .degrees(from), endAngle: .degrees(through), clockwise: false
        )
    }
}

/// The card's dimensions in both states.
///
/// Off-grid component dimensions belong in a named `*Metrics` enum with why-comments — the
/// `CaptureDiscMetrics` / `AppTabBarMetrics` house rule. CLAUDE.md §2's 4/8/16/24 grid governs
/// SPACING, which is why the paddings here are on it and the ring and grabber are not.
enum FocusBarMetrics {
    /// The expanded card's horizontal inset from the screen edges.
    static let expandedInset: CGFloat = 16

    /// The collapsed card's inset — **larger than the expanded card's, which is the point.**
    ///
    /// **E reversed the full-bleed decision on 2026-09-09** after seeing it on device: a
    /// 393pt slab sitting on a 377pt floating pill read as a shelf, not a card. E's words —
    /// *"it should stop being total full-screen-width and become smaller than the nav bar below
    /// it"* — with the width marked as two red lines on `sprint-session-card-collapse-
    /// ideal_example.jpeg`, measured at **41.8pt and 348.7pt** (width 306.8pt on a 393pt screen).
    ///
    /// Those marks land on the first and last tab ICON centres (measured 42.5 / 350.2; the bar's
    /// own constants predict 42.75 / 350.25). **That alignment is NOT what this constant
    /// encodes, and it deliberately is not derived from the slot geometry.** It holds only while
    /// the bar is SCROLLED: at rest the selected tab renders as a pill of intrinsic width
    /// (`maximumRestingPillWidth`), so the six slots are unequal and the outer icon centres move
    /// with the SELECTION — ~34pt with a middle tab selected, ~59pt with Today. Nothing constant
    /// can track that, and morphing with `isFloating` would fix only half of it while
    /// reintroducing the horizontal movement E has been removing.
    ///
    /// So: the WIDTH is the requirement, the alignment was a coincidence of the state E
    /// screenshotted. 44 is E's number to within 1.25pt and sits on §2's grid.
    /// **16 since E's second device pass, 2026-09-09** — *"the width of the collapsed bar can be
    /// extended MORE to the left and the right"*. 44 came from E's red lines but read too narrow
    /// once built. 16 is the EXPANDED card's inset too, so collapsing now changes height only,
    /// not width, and the card still nests inside the bar (361 against 385 at rest, 377 scrolled).
    static let collapsedInset: CGFloat = 16
    static let cornerRadius: CGFloat = 24

    /// The COLLAPSED card's bottom corners.
    ///
    /// **E's direction was *"Round them"* (2026-09-11); the NUMBER is E's pick of 2026-09-13**,
    /// chosen by looking at the four rendered in `screenshots/focus-card-bottom-corners/` — 0 (what
    /// shipped), 8, 16 and 24. E chose **24, matching the top**: one radius everywhere, so the
    /// collapsed card reads as a card rather than as a slab seated on the bar.
    ///
    /// **Spelled as `cornerRadius` rather than as a literal 24**, because what E chose was
    /// *"match the top"* — so if the card's radius ever moves, this follows it instead of
    /// silently becoming a second, different number.
    static let collapsedBottomCornerRadius: CGFloat = cornerRadius

    /// The drag handle. 36x5 is the iOS sheet grabber's own size, so the affordance reads as the
    /// system one users already know rather than as a decoration.
    static let grabberWidth: CGFloat = 36
    static let grabberHeight: CGFloat = 5

    /// **§3's 44pt touch floor for the grabber, WITHOUT the grabber setting the card's height.**
    /// The same trick, and the same lesson, as `AppTabBarMetrics.slotHitOverflow`: pad the hit
    /// shape out to 44 and then take the layout space back with matching negative padding. Give
    /// the capsule a real `.frame(minHeight: 44)` instead and the collapsed card grows by 39pt —
    /// back to roughly the height it was trying to escape.
    static var grabberHitOverflow: CGFloat {
        max(0, (AppTabBarPresentation.minimumTouchTarget - grabberHeight) / 2)
    }

    /// The collapsed card's Pause control — a 44pt square at the card's trailing edge.
    ///
    /// **E's 2026-09-09 layout, second pass**: the chevron is gone from the collapsed card and
    /// Pause moved to the FAR RIGHT, so the glyph grew to carry that position on its own. 44
    /// is `minimumTouchTarget`, so §3 is satisfied by the control's real frame and no
    /// negative-padding overflow is needed here — the row is 44 tall anyway because the ring is.
    static let collapsedPauseSize: CGFloat = AppTabBarPresentation.minimumTouchTarget

    /// The grabber is drawn as an OVERLAY inside the card's top padding rather than as the first
    /// child of the content stack. As a child it cost 5pt of capsule plus 8pt of stack spacing in
    /// BOTH states — 13pt that made the collapsed card taller than the tab bar it sits on, and
    /// pushed the expanded card from its original 148pt to 161pt. As an overlay it costs nothing,
    /// and the expanded card returns to 148pt.
    static let grabberTopInset: CGFloat = 4

    /// 64pt is E's number from 2026-08-24 (56 read cramped on device) and the expanded card keeps
    /// it. 44 collapsed is E's pick of 2026-09-09 from three measured options: it matches Pause's
    /// 44pt touch floor exactly, so the **control row** sets the collapsed card's height and the
    /// ring rides along inside it — which is what makes 73pt reachable at all. 36pt was offered
    /// and rejected as too cramped for the `MM:SS` countdown.
    static let expandedRingSize: CGFloat = 64
    static let collapsedRingSize: CGFloat = 44

    /// The stroke thins with the ring so the countdown keeps its readable inner diameter: 64 − 12
    /// = 52pt expanded, 44 − 8 = 36pt collapsed. At the expanded 6pt the collapsed ring would
    /// leave 32pt, and `24:59` starts scaling down inside it.
    static let expandedRingLineWidth: CGFloat = 6
    static let collapsedRingLineWidth: CGFloat = 4

    /// §2's grid, both of them. 16 → 8 collapsed is a third of the card's total saving.
    static let expandedPaddingVertical: CGFloat = 16
    static let collapsedPaddingVertical: CGFloat = 8

    /// **Where the card's bottom sits, in BOTH states: the disc's line.** Derived, never
    /// hard-coded — `RootBottomOverlay` pads its whole stack up by `bottomFurnitureLift` (the 24pt
    /// gap E measured PLUS the tab bar's own height) and `FocusTimerBar` is the stack's last child.
    ///
    /// **One lift since `F-CollapsedBarLift` (E, 2026-09-17).** There were three more metrics here —
    /// `collapsedBottomLift` (the bar's `rowHeight`), `collapsedDrop` (−32) and `collapsedOffsetY`
    /// (+32, in `.offset`'s downward-positive space) — which existed only to drop the collapsed card
    /// flush onto the tab bar, E's 2026-09-09 call. E reversed that in portrait and landscape: *"Line
    /// up with the Disc, But when there are multiple cards being displayed, then maintain the
    /// alignment."* They are deleted rather than left as named zeros.
    static var bottomLift: CGFloat { AppSearchRowMetrics.bottomFurnitureLift }
}
