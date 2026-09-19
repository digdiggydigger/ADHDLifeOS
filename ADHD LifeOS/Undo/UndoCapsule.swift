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
//  **No `#available` site** (§7.1): the tint is the tab bar's existing accent wash composed the
//  way `AppTabBar` composes it, not a Liquid Glass material, and the symbol is an iOS 13 one. So
//  no gate, no floor branch, and no "Verified paths" line is owed by this file.
//

import SwiftUI

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
    }
}

/// One pending action, drawn. A pure leaf: it takes the action and the way to reverse it, reads no
/// model and decides nothing, so a render probe can draw every kind at every size.
struct UndoCapsule: View {
    let action: RecentAction
    let onUndo: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    private var isStacked: Bool { UndoCapsuleLayout.isStacked(dynamicTypeSize) }

    var body: some View {
        content
            .padding(.horizontal, UndoCapsuleMetrics.horizontalPadding)
            .padding(.vertical, UndoCapsuleMetrics.verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            // A FLOOR, never `.frame(height:)`: the stacked layout at accessibility sizes is
            // taller than 48 and a fixed frame would clip it.
            .frame(minHeight: UndoCapsuleMetrics.minHeight)
            .background(
                Color.cardSurface,
                in: RoundedRectangle(cornerRadius: UndoCapsuleMetrics.cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UndoCapsuleMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
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
                        .font(.footnote.weight(.semibold))
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
                VStack(alignment: .leading, spacing: UndoCapsuleMetrics.verbToSubjectSpacing) {
                    Text(action.kind.verb)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color("LabelSecondary"))
                        .lineLimit(1)
                    subject
                }
                Spacer(minLength: UndoCapsuleMetrics.undoSpacing)
                undoButton
            }
        }
    }

    private var glyph: some View {
        Image(systemName: action.kind.systemImage)
            .font(.title3)
            .foregroundStyle(Self.tint(action.kind.glyphTint))
    }

    private var subject: some View {
        Text(action.subject)
            .font(.callout)
            .foregroundStyle(Color("LabelPrimary"))
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The standard ↶ and the word, on the tab bar's selected-pill wash — E's round 2b, read
    /// exactly as `AppTabBar` composes it rather than re-derived.
    private var undoButton: some View {
        Button {
            Haptics.play(.light)
            onUndo()
        } label: {
            Label("Undo", systemImage: "arrow.uturn.backward")
                .labelStyle(UndoCapsuleLabelStyle())
                .font(.callout.weight(.semibold))
                .foregroundStyle(.tint)
                .lineLimit(1)
                .padding(.horizontal, UndoCapsuleMetrics.undoHorizontalPadding)
                .frame(minHeight: UndoCapsuleMetrics.undoMinHeight)
                .background(chipTint, in: Capsule(style: .continuous))
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(UndoCapsuleButtonStyle())
        .accessibilityLabel("Undo — \(action.kind.verb), \(action.subject)")
        .accessibilityIdentifier("undoCapsuleButton")
    }

    /// Accent at 12% in light and 20% in dark — the same two numbers the selected tab pill uses,
    /// because E asked for the capsule to be tinted like it.
    private var chipTint: Color {
        Color.accentColor.opacity(
            colorScheme == .dark ? AppTabBarMetrics.chipTintDark : AppTabBarMetrics.chipTintLight
        )
    }

    private static func tint(_ tint: RecentActionGlyphTint) -> Color {
        switch tint {
        case .go: return Color("StateGo")
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
        kind: .taskClosed, subject: "Pay the council tax instalment", undo: {}
    )
    static let journalled = RecentAction(
        kind: .captureJournalled, subject: "Bike repair receipt", undo: {}
    )
    static let sorted = RecentAction(
        kind: .captureSorted(areaLabel: "💼 Work"), subject: "Ask Sam about the spare key", undo: {}
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
