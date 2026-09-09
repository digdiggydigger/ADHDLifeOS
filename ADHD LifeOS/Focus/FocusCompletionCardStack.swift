//
//  FocusCompletionCardStack.swift
//  ADHD LifeOS
//

import SwiftUI

/// The peeking stack of unconfirmed completion cards (F-FocusCard-3).
///
/// **E raised this themselves**, thinking about a location-triggered Routine that auto-starts a
/// sprint: *"If the user already has an unconfirmed AND completed sprint then possibly a stack
/// could be used here to stack the 'unconfirmed' notification cards."* The presentation E chose is
/// iOS-notification style — newest in front, older ones peeking behind as edges, confirming the
/// top one reveals the next.
///
/// **There is no cap on the DATA and nothing is ever auto-confirmed** — `maxVisible` caps only
/// what is drawn. E ruled out a "confirm all" explicitly, one at a time, so confirmation keeps
/// meaning "I looked at this"; `FocusCompletionCallSiteTests` guards its absence.
struct FocusCompletionCardStack: View {
    /// The service's `unconfirmedCompletions`, **newest first** — block 2 built the array that
    /// way precisely so a card's depth here is its index, with no second ordering to keep in step.
    let records: [CompletedFocusSession]
    let onConfirm: (CompletedFocusSession) -> Void

    var body: some View {
        ZStack {
            // Back to front. `drawOrder` — not `records` — is what puts the newest card on top:
            // `ZStack` draws later children ON TOP, so iterating a newest-first array directly
            // would bury the card the user is meant to act on under the oldest one, with every
            // offset, scale and opacity still perfectly correct.
            ForEach(FocusCompletionStackLayout.drawOrder(for: records)) { layer in
                Group {
                    if layer.isFront {
                        FocusCompletionCard(record: layer.record) { onConfirm(layer.record) }
                    } else {
                        FocusCompletionCardEdge()
                    }
                }
                    // **Anchored at the top**, so a layer's peek is exactly its `yOffset` rather
                    // than that offset minus half the height it lost to the scale. The horizontal
                    // shrink stays centred either way (`UnitPoint.top` is x = 0.5).
                    .scaleEffect(FocusCompletionStackLayout.scale(layer.depth), anchor: .top)
                    .offset(y: FocusCompletionStackLayout.yOffset(layer.depth))
                    .opacity(FocusCompletionStackLayout.opacity(layer.depth))
                    // A card behind must not be reachable and must not be READ. Without these,
                    // VoiceOver announces three Confirm buttons for one visible card, and a tap
                    // near the top edge can land on a record the user cannot see — confirming a
                    // sprint they never looked at, which is the one thing this card exists to
                    // prevent.
                    .allowsHitTesting(layer.isFront)
                    .accessibilityHidden(!layer.isFront)
            }
        }
        // `.offset` moves rendering and hit-testing without touching LAYOUT, so the two peeking
        // edges hang outside this view's frame. `RootBottomOverlay`'s VStack spaces its children
        // by 8, so unreserved they would land on the search row above.
        .padding(.top, FocusCompletionStackLayout.reservedTopPadding(forCount: records.count))
        .accessibilityIdentifier("focusCompletionCardStack")
    }
}

/// A card behind the front one: the same body, blank.
///
/// **The cards behind draw no content, and that is a fix rather than an economy.** The card's
/// background is `.regularMaterial`, which blurs what is behind it rather than hiding it — so the
/// first build of this stack showed the second card's ring and summary line ghosting through the
/// front card as a smudge, worst in dark mode. Only the top edge of a card behind is ever meant to
/// be visible, and that edge carries no information: an iOS notification stack shows blank rounded
/// bodies behind its front notification for the same reason.
///
/// Everything else is the real card's, derived from `FocusCompletionCardMetrics` so the two cannot
/// drift into looking like different objects.
private struct FocusCompletionCardEdge: View {
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FocusCompletionCardMetrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        shape
            .fill(.regularMaterial)
            .frame(height: FocusCompletionCardMetrics.height)
            .overlay(shape.strokeBorder(Color("StateGo").opacity(0.3), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
            .padding(.horizontal, FocusCompletionCardMetrics.inset)
    }
}

/// Where each card in the stack sits, and — deliberately — what order they are DRAWN in.
///
/// The design record names the `ZStack` order as this block's headline trap: get it wrong and the
/// oldest card is in front while every arithmetic assertion still passes. That is only true while
/// the order lives inside a view body, out of a unit test's reach. So it does not live there.
/// `drawOrder(for:)` is pure, the view is a `ForEach` over its output, and the trap becomes an
/// assertion like any other (`FocusCompletionStackLayoutTests`).
enum FocusCompletionStackLayout {
    /// How many layers may DRAW. Ten waiting completions are still ten records — E ruled out any
    /// auto-confirmation — but a tenth drawn edge is noise, not information.
    static let maxVisible = 3

    /// How far each layer peeks above the one in front of it. §2's 8pt inter-element step, and it
    /// is the whole peek because the scale is anchored at the top.
    static let peekStep: CGFloat = 8

    /// 5% per layer: at the card's 361pt width that is ~9pt of inset per side, close to the inset
    /// iOS gives its own stacked notifications. It has to stay a depth CUE — a card that shrank
    /// far enough to read as a different object would break the illusion it exists to create.
    static let scaleStep: CGFloat = 0.05

    /// The layers behind fade as well as shrink, because a stack of translucent materials at full
    /// opacity reads as one thick slab rather than as three cards.
    static let opacityStep: Double = 0.15

    /// One card's place in the stack. `id` is the RECORD's, so confirming the front card animates
    /// the rest forward instead of reshuffling identities under `ForEach`.
    struct Layer: Identifiable {
        let record: CompletedFocusSession
        /// The record's index in the service's newest-first array. 0 is the card in front.
        let depth: Int

        var id: UUID { record.id }
        var isFront: Bool { depth == 0 }
    }

    static func isVisible(depth: Int) -> Bool { depth >= 0 && depth < maxVisible }

    /// **Negative is UPWARD**, and upward is the only direction available: this card sits directly
    /// on top of the running timer bar, so a downward peek would hide the older cards behind a
    /// sprint the user may still be running.
    static func yOffset(_ depth: Int) -> CGFloat { -peekStep * CGFloat(depth) }

    static func scale(_ depth: Int) -> CGFloat { 1 - scaleStep * CGFloat(depth) }

    static func opacity(_ depth: Int) -> Double { 1 - opacityStep * Double(depth) }

    /// The layers **back to front**, capped at `maxVisible` — feed this straight to a `ForEach`
    /// inside a `ZStack` and the newest record lands on top.
    static func drawOrder(for records: [CompletedFocusSession]) -> [Layer] {
        Array(
            records.prefix(maxVisible)
                .enumerated()
                .map { Layer(record: $0.element, depth: $0.offset) }
                .reversed()
        )
    }

    /// The layout space the peeks hang outside the stack's own frame — derived from `yOffset`, so
    /// it cannot drift when E moves the peek on device.
    ///
    /// Zero for a lone card: one completion is not a stack, and reserving a peek that is not drawn
    /// would sit it higher than the running card it replaced.
    static func reservedTopPadding(forCount count: Int) -> CGFloat {
        guard count > 1 else { return 0 }
        return -yOffset(min(count, maxVisible) - 1)
    }
}

#if DEBUG
private func stackPreviewRecord(_ title: String, seconds: Int) -> CompletedFocusSession {
    CompletedFocusSession(
        id: UUID(), taskId: nil, taskTitle: title, lifeAreaEmoji: "💼",
        plannedSeconds: 1500, focusedSeconds: seconds, checkpointsReached: 2,
        completedNaturally: true, startedAt: .now, endedAt: .now
    )
}

private let stackPreviewRecords = [
    stackPreviewRecord("Break down Q3 Project Proposal", seconds: 1530),
    stackPreviewRecord("Reply to the planning email", seconds: 600),
    stackPreviewRecord("Read the brief", seconds: 900)
]

#Preview("Light") {
    VStack(spacing: 24) {
        FocusCompletionCardStack(records: stackPreviewRecords, onConfirm: { _ in })
        FocusCompletionCardStack(records: Array(stackPreviewRecords.prefix(1)), onConfirm: { _ in })
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 24) {
        FocusCompletionCardStack(records: stackPreviewRecords, onConfirm: { _ in })
        FocusCompletionCardStack(records: Array(stackPreviewRecords.prefix(1)), onConfirm: { _ in })
    }
    .preferredColorScheme(.dark)
}
#endif
