//
//  UndoCapsule.swift
//  ADHD LifeOS
//
//  `F-C1-UndoCapsule` — E's round-2b shape **A · Capsule in the disc row** (board `54`, frames in
//  `screenshots/adhd-ux-audit/round-2b-undo-bar/`): *"It sits exactly where the search row is, left
//  of the + disc. Nothing moves and nothing stacks... On Tasks it stands in for the search row
//  until the next action."*
//
//  **The mount is split from the drawing, and that is not ceremony.** `@Environment` does not
//  subscribe to an `ObservableObject`, so a view that read the centre out of the environment and
//  drew from it would show the capsule only when something ELSE happened to redraw the bottom
//  overlay. `CelebrationLayer` / `CelebrationSurfaceLayer` is the precedent this copies exactly.
//
//  **No `#available` site** (§7.1): the card is a plain `Capsule` over `Color.cardSurface`, not a
//  Liquid Glass material, and the symbols are iOS 13 ones. So no gate, no floor branch, and no
//  "Verified paths" line is owed by this file. (E's shape round retired the tab bar's accent wash
//  from behind the Undo control; nothing that replaced it is newer than the floor either.)
//

import SwiftUI
import UIKit

/// The disc row's leading band: the capsule while one is pending, and whatever the screen would
/// otherwise put there the rest of the time.
///
/// **The displacement is the slot's job, not the row's, because only the slot can observe it.**
/// `@Environment` hands over the centre but subscribes to nothing, so a row that read
/// `center.pendingAction` itself would show the capsule only when something else happened to
/// redraw it. Holding both branches here also means the OUTGOING one — Tasks' search row, the
/// Journal's pencil — leaves on the same fade the capsule arrives on, which is §7.2's rule for
/// something that disappears rather than a swap nobody animated.
///
/// Without a centre (previews, snapshots) it is simply the fallback, unwrapped.
struct UndoCapsuleSlot<Fallback: View>: View {
    @ViewBuilder let fallback: () -> Fallback

    @Environment(\.recentActionCenter) private var center: RecentActionCenter?

    var body: some View {
        if let center {
            UndoCapsulePresenter(center: center, fallback: fallback)
        } else {
            fallback()
        }
    }
}

/// The live slot: whatever one action is pending, and the fade it and its fallback trade on.
struct UndoCapsulePresenter<Fallback: View>: View {
    @ObservedObject var center: RecentActionCenter
    @ViewBuilder let fallback: () -> Fallback

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let action = center.pendingAction {
                UndoCapsule(action: action) {
                    Task { await center.undo() }
                }
                // Opacity alone, in BOTH modes. E's shape A moves nothing, so there is no
                // geometry to pin and no pre-animation pose to open on — §7.2's opening-pose rule
                // is met by the design rather than by a `reduceMotion ?` on every offset.
                .transition(.opacity)
            } else {
                fallback()
            }
        }
        // Two branches, one line: a spring normally, a plain ease under Reduce Motion (§5's one
        // exception). Never `nil` — this APPEARS and DISAPPEARS, which §7.2 says is the case a
        // hard cut is wrong for. Keyed on the pending action alone, so the search row's own
        // scope-driven animation in `RootBottomOverlay` is untouched.
        .animation(UndoCapsuleMotion.appearance(reduceMotion: reduceMotion), value: center.pendingAction)
        // `voiceover.md`: report a visible change. The capsule is the LAST element on the screen
        // and on Tasks it replaces the search row, so both halves of what just happened are out of
        // a VoiceOver user's way unless they are told.
        //
        // **`UIAccessibility.post`, and `AccessibilityNotification.Announcement` was considered
        // and left out** (§7.1's filter): it adds only a priority, and an undo offer is not urgent
        // enough to interrupt a higher-priority utterance, so it would show the user nothing this
        // cannot. This API is not deprecated.
        .onChange(of: center.pendingAction) { action in
            guard let action else { return }
            UIAccessibility.post(notification: .announcement, argument: action.accessibilityAnnouncement)
        }
    }
}

/// One pending action, drawn. A pure leaf: it takes the action and the way to reverse it, reads no
/// model and decides nothing, so a render probe can draw every kind at every size.
struct UndoCapsule: View {
    let action: RecentAction
    let onUndo: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isStacked: Bool { UndoCapsuleLayout.isStacked(dynamicTypeSize) }

    var body: some View {
        content
            .padding(.horizontal, UndoCapsuleMetrics.horizontalPadding)
            .padding(.vertical, UndoCapsuleMetrics.verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            // A FLOOR, never `.frame(height:)`: the stacked layout at accessibility sizes is
            // taller than 48 and a fixed frame would clip it.
            .frame(minHeight: UndoCapsuleMetrics.minHeight)
            // E's shape round: *"Option C, 'Fully rounded'"*. Both sites read the one shape, and
            // it stays a concrete `Capsule` because `strokeBorder` needs an `InsettableShape`.
            .background(Color.cardSurface, in: UndoCapsuleMetrics.cardShape)
            .overlay(UndoCapsuleMetrics.cardShape.strokeBorder(Color.cardBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
            // `.contain`, not `.combine`: combining would fuse the Undo button into the capsule,
            // leaving one element carrying a label and an action together — the button could not
            // be addressed or reached on its own. Same correction the retired inbox bar carried.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("undoCapsule")
    }

    @ViewBuilder
    private var content: some View {
        if isStacked {
            VStack(alignment: .leading, spacing: UndoCapsuleMetrics.stackedSpacing) {
                Label {
                    Text(action.kind.verb)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color("LabelSecondary"))
                } icon: {
                    glyph
                }
                subject
                undoButton
            }
        } else {
            HStack(spacing: UndoCapsuleMetrics.glyphSpacing) {
                glyph
                words
                Spacer(minLength: UndoCapsuleMetrics.undoSpacing)
                // **`layoutPriority`, and it is not belt-and-braces — the first render on the
                // simulator showed "Un…".** In a tight `HStack` SwiftUI compresses whichever child
                // will give, and with a two-line subject beside it the control that gave was the
                // Undo button: the one thing in the capsule that must never be ambiguous. §1's
                // Layout Safety rule names `.layoutPriority(1)` for exactly this. The words take
                // the squeeze instead, which they are already dressed for.
                undoButton
                    .layoutPriority(1)
            }
        }
    }

    /// E's chosen shape (height round, 2026-09-20): board `54`'s two lines, each a size smaller.
    /// The verb was `.footnote` and the subject `.callout`; stepping both down is what lets the
    /// card sit in the 44pt band without dropping either fact or wrapping the title.
    private var words: some View {
        VStack(alignment: .leading, spacing: UndoCapsuleMetrics.verbToSubjectSpacing) {
            Text(action.kind.verb)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color("LabelSecondary"))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            subject
        }
    }

    /// Hidden from VoiceOver: it restates the verb beside it, and unhidden it reads its SF Symbol
    /// name ("checkmark circle fill") before the word the user actually needs.
    private var glyph: some View {
        Image(systemName: action.kind.systemImage)
            .font(.title3)
            .foregroundStyle(Self.tint(action.kind.glyphTint))
            .accessibilityHidden(true)
    }

    private var subject: some View {
        Text(action.subject)
            .font(.footnote)
            .foregroundStyle(Color("LabelPrimary"))
            // ONE line since the height round: a title that wrapped made the card 74pt and one
            // that did not made it ~52, so the capsule's height depended on the task's name.
            // **E re-confirmed it at the shape round** after being shown that a second line costs
            // 15pt on every title: the 32pt reclaimed from the Undo control widens THIS line
            // instead, which is where "Capture three thi…" became "Capture three things on…".
            .lineLimit(isStacked ? 2 : 1)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The action's own glyph and word — ↶ Undo for the five kinds that reverse something, and
    /// **↗ Reopen for a filed draft, which does not** (`F-C2-DraftsToInbox`). Read from the kind
    /// rather than written here, so a control can never offer to take back something the app keeps.
    ///
    /// **Bare since E's shape round, 2026-09-20** — it shipped on the
    /// tab bar's selected-pill wash (E's round 2b) and E removed it by looking, on the phone:
    /// *"remove the blue chip background colour behind the "Undo" Button"*.
    ///
    /// **The chip's own inner padding went with it, and that is the point rather than tidying.**
    /// 16pt a side padding the inside of nothing is 32pt taken from the subject beside it — the
    /// dead space that had been truncating task titles. Spent on the one line instead, it is what
    /// let E keep the 44pt card rather than pay 15pt for a second line. Do not reinstate either.
    private var undoButton: some View {
        Button {
            Haptics.play(.light)
            onUndo()
        } label: {
            Label(action.kind.actionLabel, systemImage: action.kind.actionSystemImage)
                .labelStyle(UndoCapsuleLabelStyle())
                .font(.callout.weight(.semibold))
                .foregroundStyle(.tint)
                .lineLimit(1)
                // Never narrower than the word. `lineLimit(1)` alone permits truncation, which is
                // how "Undo" became "Un…"; this makes the button's width a floor the rest of the
                // row lays out around. It still GROWS with Dynamic Type — the fix is to the
                // horizontal squeeze, not to the type.
                .fixedSize(horizontal: true, vertical: false)
                .frame(minHeight: UndoCapsuleMetrics.undoDrawnHeight)
                // **The tab bar's own trick, and with the chip gone it IS §3 on this control.**
                // The control lays out at 32 so the capsule can be the height E marked; the hit
                // area is grown back to 44 with negative vertical padding around the
                // `contentShape`, exactly as `AppTabBarMetrics.slotHitOverflow` does for a 44pt
                // slot in a shorter card. The layout stays 32; a tap a little above or below it
                // still lands. Nothing on screen shows this any more, so the three lines below are
                // pinned in order by `UndoCapsuleCallSiteTests` and their arithmetic by
                // `UndoCapsulePresentationTests` — between them they are the only witness left.
                .padding(.vertical, UndoCapsuleMetrics.undoHitOverflow)
                .contentShape(Capsule(style: .continuous))
                .padding(.vertical, -UndoCapsuleMetrics.undoHitOverflow)
        }
        .buttonStyle(UndoCapsuleButtonStyle())
        // **The plain word, and it is deliberate.** The capsule is `.contain`, so VoiceOver reads
        // the verb and the subject as their own elements either side of this button — a label that
        // repeated them would say the whole thing twice, and the arrival announcement has already
        // said it once. `buttons.md › Content` asks for a concise, title-style label. It is also
        // what `SignedInJourneyUITests` addresses the control by, and that journey is skipped in
        // the standard run, so a longer label would have broken it silently.
        .accessibilityIdentifier("undoCapsuleButton")
    }

    private static func tint(_ tint: RecentActionGlyphTint) -> Color {
        switch tint {
        case .completion: return Color("StateGo")
        case .accent: return .accentColor
        case .secondary: return Color("LabelSecondary")
        }
    }
}

/// Glyph then words on one line, §2's 8pt apart. `Label`'s default spacing is the system's, which
/// is not on the grid.
private struct UndoCapsuleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: UndoCapsuleMetrics.undoGlyphSpacing) {
            configuration.icon
            configuration.title
        }
    }
}

/// §3's press state: a real scale, never an opacity filter.
private struct UndoCapsuleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
                value: configuration.isPressed
            )
    }
}

#if DEBUG
private enum UndoCapsulePreviewData {
    static let closed = RecentAction(
        kind: .taskClosed, subject: "Pay the council tax instalment", undo: { true }
    )
    static let journalled = RecentAction(
        kind: .captureJournalled, subject: "Bike repair receipt", undo: { true }
    )
    static let sorted = RecentAction(
        kind: .captureSorted(areaLabel: "💼 Work"), subject: "Ask Sam about the spare key",
        undo: { true }
    )
}

#Preview("Undo capsule — Light") {
    VStack(spacing: 16) {
        UndoCapsule(action: UndoCapsulePreviewData.closed) {}
        UndoCapsule(action: UndoCapsulePreviewData.journalled) {}
        UndoCapsule(action: UndoCapsulePreviewData.sorted) {}
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Undo capsule — Dark") {
    VStack(spacing: 16) {
        UndoCapsule(action: UndoCapsulePreviewData.closed) {}
        UndoCapsule(action: UndoCapsulePreviewData.journalled) {}
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Undo capsule — AX3") {
    UndoCapsule(action: UndoCapsulePreviewData.closed) {}
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground)
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.light)
}
#endif
