//
//  FocusCompletionCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// The card a naturally-finished sprint raises, and the only way to clear it (F-FocusCard-2).
///
/// E's specification, verbatim: *"Full ring + name + time done + Confirm + a celebratory screen
/// animation to signify completion."* The celebration is F-FocusCard-4; everything else is here.
///
/// **Why it floats rather than sitting flush on the tab bar.** The design record described this
/// card as sharing the collapsed running card's "full-bleed flush geometry", but that half of the
/// record was overtaken before this block started: E reversed full-bleed on device, and "flush"
/// is only available to the BOTTOM-most piece of furniture — this card is deliberately not that,
/// because it stacks above a sprint that may already be running. So it takes the EXPANDED card's
/// geometry exactly: 16pt inset, 24pt radius on all four corners, `.regularMaterial`, one accent
/// keyline. Collapsing changes height only, and so does completing.
///
/// **E CHOSE this on 2026-09-09, from three options, before F-FocusCard-3 built the stack on top
/// of it.** It began as a deviation approved by sight; it is settled now, and the stack's peek
/// offsets inherit it.
///
/// **The confirmation is an acknowledgement, not a save.** The record was already written when
/// the countdown ended, so nothing is lost if the user never taps this — Confirm re-saves the
/// same row with `confirmed_at` set. `FocusSessionService.confirmCompletion` carries the why.
struct FocusCompletionCard: View {
    let record: CompletedFocusSession
    /// Whether this sprint JUST finished (F-FocusCard-4) — `true` only for the record the service
    /// stamped, so a card revealed by a Confirm or restored by a relaunch shows the ring at rest.
    var celebrates = false
    let onConfirm: () -> Void

    /// Read HERE and handed down, not read inside the celebration: the value is not available in
    /// an `init`, and the celebration's opening pose is its initial `@State`. Resolved any later,
    /// the pre-animation pose would show for one frame under Reduce Motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// "25m 30s focused · 2 checkpoints" — pure, so the copy is locked by a test rather than by
    /// reading the screen.
    ///
    /// **`FocusTimeFormatting.human(seconds:)`, never `duration(seconds:)`.** `duration` is the
    /// analytics formatter and drops everything below the minute, so a sprint the user extended
    /// by +30s would read "25m" when 25m 30s was banked — the invisible loss this whole card
    /// exists to prevent.
    static func summaryLine(for record: CompletedFocusSession) -> String {
        let focused = "\(FocusTimeFormatting.human(seconds: record.focusedSeconds)) focused"
        guard record.checkpointsReached > 0 else { return focused }
        let checkpoints = record.checkpointsReached == 1
            ? "1 checkpoint"
            : "\(record.checkpointsReached) checkpoints"
        return "\(focused) · \(checkpoints)"
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FocusCompletionCardMetrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 8) {
            completedRing
            summaryColumn
            Spacer(minLength: 0)
            confirmButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, FocusCompletionCardMetrics.paddingVertical)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: cardShape)
        .overlay(cardShape.strokeBorder(Color("StateGo").opacity(0.3), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        .padding(.horizontal, FocusCompletionCardMetrics.inset)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityIdentifier("focusCompletionCard")
    }

    /// The sprint ring at rest: a complete arc in the app's done-green, with a tick where the
    /// countdown used to be. Same instrument as the running card's, one state further on — which
    /// is what makes the completion legible without reading a word of it.
    ///
    /// The tick is drawn by `FocusCompletionCelebration`, which springs it in and radiates the
    /// ring outward when the sprint has just finished, and draws exactly this resting tick
    /// otherwise. `.id(celebrates)` makes a flip of the cue rebuild it in the armed pose, so the
    /// burst cannot be lost to an update that delivered the record a frame before the cue.
    private var completedRing: some View {
        ClosureRing(
            progress: 1,
            size: FocusCompletionCardMetrics.ringSize,
            lineWidth: FocusCompletionCardMetrics.ringLineWidth,
            arcStyle: AnyShapeStyle(Color("StateGo"))
        ) {
            FocusCompletionCelebration(plays: celebrates, reduceMotion: reduceMotion)
                .id(celebrates)
        }
        .accessibilityHidden(true)
    }

    private var summaryColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(record.lifeAreaEmoji)
                    .font(.footnote)
                    // Rigid, and it pairs with the title's `layoutPriority` below — the block-1
                    // lesson. Priority decides who is OFFERED space first, not who may shrink, so
                    // a priority-1 title takes what it wants and SwiftUI honours that by
                    // compressing its priority-0 `Text` siblings to nothing. The emoji vanished
                    // on E's device exactly that way, with every test green.
                    .fixedSize()
                Text(record.taskTitle)
                    .font(.footnote.weight(.bold))
                    .lineLimit(1)
                    // §1's layout safety: without it the trailing `Spacer` yields first and the
                    // title truncates before anything else gives.
                    .layoutPriority(1)
            }
            Text(Self.summaryLine(for: record))
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.taskTitle). \(Self.summaryLine(for: record)).")
    }

    /// §3: a real 44pt target, and a press state that SCALES rather than dimming — raw opacity
    /// filters are prohibited, so this reuses the app's `PressScaleButtonStyle` primitive.
    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text("Confirm")
                .font(.caption.weight(.bold))
                // Rigid for the same reason as the emoji: a `Text` at the default priority beside
                // a priority-1 title is exactly what shipped as a 1pt sliver in block 1.
                .fixedSize()
                .foregroundStyle(Color("OnStateGo"))
                .padding(.horizontal, 16)
                .frame(minHeight: FocusCompletionCardMetrics.confirmMinHeight)
                .background(Color("StateGo"), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Confirm this finished sprint")
        .accessibilityIdentifier("focusCompletionConfirmButton")
    }
}

/// The completion card's dimensions.
///
/// Derived from `FocusBarMetrics` wherever the two cards must agree — they are stacked in the same
/// column and read as one family, so a divergence between them is drift rather than design. The
/// house rule (`CaptureDiscMetrics` / `AppTabBarMetrics`) is that off-grid component dimensions
/// live in a named enum with why-comments; §2's 4/8/16/24 grid governs the spacing.
enum FocusCompletionCardMetrics {
    /// The expanded running card's inset and radius, deliberately identical: this card sits
    /// directly above that one whenever a replacement sprint is already running, and two cards in
    /// one column with different outlines read as a mistake.
    static var inset: CGFloat { FocusBarMetrics.expandedInset }
    static var cornerRadius: CGFloat { FocusBarMetrics.cornerRadius }

    /// The COLLAPSED card's ring, not the expanded one's 64. Nothing is counting down any more,
    /// so the ring is an emblem rather than an instrument to read — and at 44 it matches the
    /// Confirm button beside it, which is what keeps the row a single 44pt band.
    static var ringSize: CGFloat { FocusBarMetrics.collapsedRingSize }
    static var ringLineWidth: CGFloat { FocusBarMetrics.collapsedRingLineWidth }

    /// §2's grid, and the expanded card's own vertical padding.
    static var paddingVertical: CGFloat { FocusBarMetrics.expandedPaddingVertical }

    /// §3's touch floor, spelled as the shared constant rather than as a literal 44.
    static var confirmMinHeight: CGFloat { AppTabBarPresentation.minimumTouchTarget }

    /// The whole card: one 44pt control band inside its padding, so 76.
    ///
    /// Named because F-FocusCard-3's stack draws BLANK bodies for the cards behind the front one,
    /// and a blank body that is not exactly the real card's height reads as a different object
    /// rather than as the same card further back. `testTheCardIsASingle44ptBandInsideItsPadding`
    /// measures the rendered card against this, so the two cannot drift.
    static var height: CGFloat { confirmMinHeight + paddingVertical * 2 }
}

#if DEBUG
private func previewRecord(
    title: String = "Break down Q3 Project Proposal",
    focusedSeconds: Int = 1530,
    checkpoints: Int = 2
) -> CompletedFocusSession {
    CompletedFocusSession(
        id: UUID(), taskId: nil, taskTitle: title, lifeAreaEmoji: "💼",
        plannedSeconds: 1500, focusedSeconds: focusedSeconds, checkpointsReached: checkpoints,
        completedNaturally: true, startedAt: .now, endedAt: .now
    )
}

#Preview("Light") {
    VStack(spacing: 8) {
        FocusCompletionCard(record: previewRecord(), onConfirm: {})
        FocusCompletionCard(
            record: previewRecord(
                title: "A considerably longer sprint name that has to truncate",
                focusedSeconds: 45, checkpoints: 0
            ),
            onConfirm: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 8) {
        FocusCompletionCard(record: previewRecord(), onConfirm: {})
        FocusCompletionCard(
            record: previewRecord(
                title: "A considerably longer sprint name that has to truncate",
                focusedSeconds: 45, checkpoints: 0
            ),
            onConfirm: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
