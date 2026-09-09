//
//  FocusBarCollapse.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

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

/// The card's outline: a rounded rectangle whose BOTTOM corners round only when the card is
/// floating.
///
/// E chose full-bleed-with-rounded-top for the collapsed card over a plain inset and over a
/// squared-off strip; then, told that top-only rounding 100pt above the screen bottom would leave
/// the square bottom corners hanging in mid-air, chose *"Drop it flush to the tab bar"*. So the
/// two decisions are one shape: square bottom corners are only correct because they sit ON the
/// bar, and `FocusBarMetrics.collapsedOffsetY` is what puts them there.
///
/// **`InsettableShape` is not optional here.** The card is drawn twice — `.background` and an
/// `.overlay(...strokeBorder...)` — and `strokeBorder` insets the shape by half the line width so
/// the 1pt border lands *inside* the bounds. A plain `Shape` would force `.stroke`, which centres
/// the line and leaves half of it outside the card, visibly proud of the screen edge in the
/// collapsed state.
struct FocusBarCardShape: Shape, InsettableShape {
    var cornerRadius: CGFloat
    var roundsBottomCorners: Bool
    /// Accumulated by `inset(by:)`. It shrinks the rect **and** the radius, so an inset copy stays
    /// concentric with the original instead of bulging at the corners.
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = max(0, cornerRadius - insetAmount)
        let corners: UIRectCorner = roundsBottomCorners ? .allCorners : [.topLeft, .topRight]
        return Path(
            UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
        )
    }

    func inset(by amount: CGFloat) -> FocusBarCardShape {
        var inset = self
        inset.insetAmount += amount
        return inset
    }
}

/// The card's dimensions in both states.
///
/// Off-grid component dimensions belong in a named `*Metrics` enum with why-comments — the
/// `CaptureDiscMetrics` / `AppTabBarMetrics` house rule. CLAUDE.md §2's 4/8/16/24 grid governs
/// SPACING, which is why the paddings here are on it and the ring and grabber are not.
enum FocusBarMetrics {
    /// The expanded card's horizontal inset from the screen edges. The collapsed card takes 0 —
    /// E: *"the full-screen-width card sizing is important."*
    static let expandedInset: CGFloat = 16
    static let cornerRadius: CGFloat = 24

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

    /// **Derived, never hard-coded.** `RootBottomOverlay` pads its whole stack up by
    /// `bottomFurnitureLift` (the 32pt gap E measured PLUS the tab bar's own height), and
    /// `FocusTimerBar` is that stack's last child — so the expanded card's bottom sits 100pt up.
    static var expandedBottomLift: CGFloat { AppSearchRowMetrics.bottomFurnitureLift }

    /// Flush means clearing the tab bar and *nothing more*. Spelling it as the bar's own
    /// `rowHeight` rather than as the literal 68 keeps it correct when the bar's chip height or
    /// lift changes — the drift `AppSearchRowMetrics` was written to end.
    static var collapsedBottomLift: CGFloat { AppTabBarMetrics.rowHeight }

    /// The change in LIFT, so it is negative: the collapsed card is lifted 32pt LESS than the
    /// expanded one. Equal to `-AppSearchRowMetrics.gapAboveTabBar`, but expressed as the
    /// difference between the two lifts so the pair cannot drift apart.
    static var collapsedDrop: CGFloat { collapsedBottomLift - expandedBottomLift }

    /// The same 32pt in `.offset(y:)`'s convention, where **positive is downward**. Exactly one
    /// negation exists in this file and this is it — the call site reads
    /// `.offset(y: collapsedOffsetY)` and cannot get the sign wrong by hand.
    ///
    /// **It must be `.offset`, not negative bottom padding.** `FocusTimerBar` is the LAST child of
    /// `RootBottomOverlay`'s VStack; negative bottom padding there shrinks the stack and drags the
    /// search row and the capture disc down 32pt with it. `.offset` moves rendering and
    /// hit-testing without touching layout.
    static var collapsedOffsetY: CGFloat { -collapsedDrop }
}
