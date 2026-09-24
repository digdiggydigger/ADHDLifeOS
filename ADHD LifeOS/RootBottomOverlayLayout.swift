//
//  RootBottomOverlayLayout.swift
//  ADHD LifeOS
//
//  F-LandscapeFabOverlap. The bug E found on the phone on 2026-09-16: in LANDSCAPE, with an
//  unacknowledged "Sprint finished while you were away" card up, the capture disc rendered on
//  top of the Settings gear and the gear could not be tapped. `RootBottomOverlay` is bottom-
//  aligned and its one column holds the disc row ABOVE the cards, so the disc's top is the
//  container's height less the lift, the cards and the disc — 372 − 100 − 186 − 8 − 60 = 18 on
//  E's landscape iPhone 15 Pro, inside the header's 40pt gear well. The expanded sprint card
//  alone (148) leaves 56, eight points clear, which is why neither landscape nor the card alone
//  ever showed it. The stack does not overflow the screen; it FILLS it.
//

import SwiftUI

/// The pure rule and geometry behind `RootBottomOverlay`'s two arrangements. Kept out of the view
/// body for the reason every presentation type in this app is: view bodies are ~0% covered by
/// design, so a rule left inside one is a rule nothing checks. `RootBottomOverlayLayoutTests`
/// holds every number here, including the bug's own arithmetic.
enum RootBottomOverlayLayout {

    enum Arrangement: Equatable {
        /// The disc row ABOVE the cards in one trailing-aligned column — E's stack (2026-08-19,
        /// 2026-08-25): *"an active sprint PUSHES the disc up rather than letting the timer bar
        /// occlude the disc's controls."* Regular height, always; compact height with nothing up.
        case stacked
        /// The cards in a column BESIDE the disc row, which keeps its resting corner. Compact
        /// height (the landscape iPhone) with anything up: 372pt cannot hold the lift, a card
        /// and the disc in one column without the disc reaching the header. Nothing pushes the
        /// disc and nothing covers it — the column ends where the disc row begins.
        case besideTheDisc
    }

    /// Compact height is the landscape iPhone — the `verticalSizeClass` reading `CaptureFanOverlay`
    /// and `LoginView` already use; an iPad is regular in both orientations and keeps the stack.
    /// With nothing up there is no column to put beside the disc, and a side-by-side arrangement
    /// would hand half the width to an empty one — so the ordinary row stays the ordinary row,
    /// and the search row on Tasks is untouched.
    static func arrangement(isCompactHeight: Bool, hasCards: Bool) -> Arrangement {
        isCompactHeight && hasCards ? .besideTheDisc : .stacked
    }

    // MARK: - The fan (F-FanCardsFade)

    /// What the cards do while the capture fan is open. E's call (2026-09-17), on the finding in
    /// `screenshots/landscape-fab-overlap/09–12`: the bottom overlay sits ABOVE the fan (so the
    /// disc, which becomes the fan's ×, stays crisp and tappable), and the cards rode above the
    /// scrim with it — in portrait the away card hid the LINK and TASK tiles outright. *"Fade the
    /// cards out while the fan's open."*
    ///
    /// Both facets travel together: invisible AND out of the hit-test, or an invisible card would
    /// still take the tap meant for the tile under it. The cards keep their LAYOUT throughout —
    /// this is an opacity, never an `if` — so the timer bar keeps its detail sheet and Stop
    /// confirmation, and nothing else on screen reflows.
    ///
    /// **This used to add "so the × stays exactly where the + was". `F-FanXAtRest` reversed that
    /// (E, 2026-09-17):** the × does move now, to its resting corner, and it moves by `frames`
    /// below rather than by the cards leaving.
    struct CardsPresence: Equatable {
        var opacity: Double
        var acceptsTouches: Bool
    }

    static func cardsPresence(fanIsOpen: Bool) -> CardsPresence {
        fanIsOpen
            ? CardsPresence(opacity: 0, acceptsTouches: false)
            : CardsPresence(opacity: 1, acceptsTouches: true)
    }

    /// The stack's inter-element gap — §2's 8. A literal in the view body until this block; named
    /// because the bug's arithmetic reads it.
    static let spacing: CGFloat = 8

    /// The width to PROPOSE to the cards column. Stacked, the column has the whole width; beside
    /// the disc, it has what the disc row leaves — proposed, not merely placed, so a card that
    /// fills its proposal cannot run under the disc.
    static func cardsWidth(_ arrangement: Arrangement, width: CGFloat, discRow: CGSize) -> CGFloat {
        switch arrangement {
        case .stacked:
            return width
        case .besideTheDisc:
            return max(0, width - discRow.width)
        }
    }

    /// The two pieces' size together within `width`, given the sizes they fitted to.
    ///
    /// Stacked, an empty column spends no spacing — the `if` around the cards in the old body
    /// was not decoration, and an unconditional gap would raise the disc 8pt on every screen.
    static func size(_ arrangement: Arrangement, width: CGFloat, discRow: CGSize, cards: CGSize) -> CGSize {
        switch arrangement {
        case .stacked:
            let column = cards.height > 0 ? spacing + cards.height : 0
            return CGSize(width: width, height: discRow.height + column)
        case .besideTheDisc:
            return CGSize(width: width, height: max(discRow.height, cards.height))
        }
    }

    struct Frames: Equatable {
        var discRow: CGRect
        var cards: CGRect
    }

    /// Where each piece goes inside `bounds`, given the sizes they fitted to.
    ///
    /// Stacked: the disc row at the top, trailing-aligned, the cards below it — the
    /// `VStack(alignment: .trailing)` E's position review settled, as frames. Beside the disc:
    /// the disc row in the bottom-trailing corner it rests in, the cards in the column to its
    /// leading side, both on the bottom line.
    ///
    /// **While the capture fan is open (`F-FanXAtRest`, E's shape B, 2026-09-17), the stacked disc
    /// row drops to the bottom line — its resting corner — and the cards stay exactly where they
    /// were.** The fan places its tiles from that corner, 78pt apart, so a disc pushed up by any
    /// card turned into a × sitting on a tile (TASK under the sprint bar in E's frame 19, TASK
    /// under a Confirm card in E's GIF). The cards are invisible and untouchable then
    /// (`cardsPresence`), but they keep their space, so the size is unchanged and nothing reflows.
    /// Beside the disc, and with nothing up, the disc is already on the bottom line.
    static func frames(
        _ arrangement: Arrangement, in bounds: CGRect, discRow: CGSize, cards: CGSize, fanIsOpen: Bool
    ) -> Frames {
        switch arrangement {
        case .stacked:
            let gap = cards.height > 0 ? spacing : 0
            let column = CGRect(
                x: bounds.maxX - cards.width, y: bounds.minY + discRow.height + gap,
                width: cards.width, height: cards.height
            )
            let disc = CGRect(
                x: bounds.maxX - discRow.width, y: fanIsOpen ? bounds.maxY - discRow.height : bounds.minY,
                width: discRow.width, height: discRow.height
            )
            return Frames(discRow: disc, cards: column)
        case .besideTheDisc:
            let disc = CGRect(
                x: bounds.maxX - discRow.width, y: bounds.maxY - discRow.height,
                width: discRow.width, height: discRow.height
            )
            let column = CGRect(
                x: bounds.minX, y: bounds.maxY - cards.height, width: cards.width, height: cards.height
            )
            return Frames(discRow: disc, cards: column)
        }
    }
}

/// The container `RootBottomOverlay` lays its two pieces out with: subview 0 is the disc row,
/// subview 1 the cards column, `arrangement` says which of the two shapes above applies, and
/// `fanIsOpen` whether the × drops to its resting corner (`F-FanXAtRest`).
///
/// **A `Layout` and not a `switch` between a `VStack` and an `HStack`, deliberately.** Changing
/// the container TYPE gives every child a new identity, and `FocusTimerBar` owns the sprint
/// detail sheet's `@State` — so a rotation with that sheet open would dismiss it. A `Layout`
/// whose arrangement is a property keeps the children through the change, and animates it.
///
/// `Layout` sits below the 18 floor, so no `#available` gate is needed (§7.1). The
/// geometry is delegated to `RootBottomOverlayLayout` so it can be unit-tested; nothing here
/// decides a number.
struct RootBottomOverlayArrangement: Layout {
    var arrangement: RootBottomOverlayLayout.Arrangement
    var fanIsOpen: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let width = width(for: proposal, subviews: subviews)
        let fitted = fitted(width: width, subviews: subviews)
        return RootBottomOverlayLayout.size(arrangement, width: width, discRow: fitted.discRow, cards: fitted.cards)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let fitted = fitted(width: bounds.width, subviews: subviews)
        let frames = RootBottomOverlayLayout.frames(
            arrangement, in: bounds, discRow: fitted.discRow, cards: fitted.cards, fanIsOpen: fanIsOpen
        )
        subviews[0].place(at: frames.discRow.origin, proposal: ProposedViewSize(frames.discRow.size))
        subviews[1].place(at: frames.cards.origin, proposal: ProposedViewSize(frames.cards.size))
    }

    /// The overlay proposes its container's exact size, so the width is normally given. SwiftUI
    /// also probes a layout with `.zero` and `.infinity`; with nothing finite to fit into, the
    /// pieces' ideal widths are the honest answer.
    private func width(for proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        if let proposed = proposal.width, proposed.isFinite {
            return proposed
        }
        let discRow = subviews[0].sizeThatFits(.unspecified)
        let cards = subviews[1].sizeThatFits(.unspecified)
        switch arrangement {
        case .stacked:
            return max(discRow.width, cards.width)
        case .besideTheDisc:
            return discRow.width + cards.width
        }
    }

    /// Stacked, the disc row is offered the whole width — the search row inside it fills the
    /// leading side. Beside the disc it takes its ideal width, so the cards column gets the rest.
    private func fitted(width: CGFloat, subviews: Subviews) -> (discRow: CGSize, cards: CGSize) {
        let discRow: CGSize
        switch arrangement {
        case .stacked:
            discRow = subviews[0].sizeThatFits(ProposedViewSize(width: width, height: nil))
        case .besideTheDisc:
            discRow = subviews[0].sizeThatFits(.unspecified)
        }
        let cardsWidth = RootBottomOverlayLayout.cardsWidth(arrangement, width: width, discRow: discRow)
        let cards = subviews[1].sizeThatFits(ProposedViewSize(width: cardsWidth, height: nil))
        return (discRow, cards)
    }
}
