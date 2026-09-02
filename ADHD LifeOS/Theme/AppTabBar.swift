//
//  AppTabBar.swift
//  ADHD LifeOS
//

import SwiftUI

/// The app's tab bar, drawn by us rather than by `TabView`.
///
/// **Why a custom bar exists at all:** a system `TabView` shows at most five `.tabItem`s and
/// folds the rest into a "More" list. E's 2026-09-02 call adds a sixth station (Tools), and
/// burying Journal or Captures behind "More" was never on the table. So the system bar is hidden
/// and this stands in its place — `TabView` still owns the CONTENT, which is what keeps each
/// tab's scroll position and `NavigationStack` depth alive (a `switch selection` would throw
/// both away on every switch).
///
/// **This is Design F, "Minimal Dot"** — E's pick from six concepts, for the resting state: full
/// width, icons only, one accent dot marking position. F-Tools-2-Morph adds the second state (a
/// floating card while the page is moving) and morphs this dot into a chip; the indicator's
/// `matchedGeometryEffect` namespace is here already so that morph has something to travel with.
///
/// §7 conflict, reported knowingly: `ui-ux-pro-max` rates "bottom nav ≤ 5" a HIGH-severity rule
/// and calls six "overloaded nav". **E was shown that before choosing six.**
struct AppTabBar: View {
    @Binding var selection: AppTab
    /// The Captures inbox count. Passed in rather than fetched: RootView owns the single writer,
    /// and a bar that fetched its own would be a second source of truth for one number.
    var captureInboxCount: Int

    @Namespace private var indicatorNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTabBarPresentation.tabs) { slot in
                slotButton(slot)
            }
        }
        .frame(height: AppTabBarMetrics.rowHeight)
        .frame(maxWidth: .infinity)
        // `BarSurface` carries the translucency (6% light / 8% dark); the material behind it is
        // what that translucency reveals, so the bar reads as glass over content rather than as
        // a washed-out white. §5's layer architecture, and the token's first call site — it has
        // been in the catalog unused since the v3 palette landed.
        .background {
            Color.barSurface
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        // A tab bar that grew with Dynamic Type would eat the screen at accessibility sizes —
        // the system's own bar caps for the same reason. Glyphs still scale up to xxxLarge.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(selectionAnimation, value: selection)
    }

    private func slotButton(_ slot: AppTabBarPresentation.Slot) -> some View {
        let isSelected = slot.tab == selection
        let badgeCount = slot.tab == .captures ? captureInboxCount : 0
        return Button {
            selection = slot.tab
        } label: {
            VStack(spacing: AppTabBarMetrics.glyphToIndicatorSpacing) {
                glyph(slot, isSelected: isSelected, badgeCount: badgeCount)
                indicator(isSelected: isSelected)
            }
            .frame(maxWidth: .infinity, minHeight: AppTabBarPresentation.minimumTouchTarget)
            // The whole slot is the target, not just the glyph — six slots on an SE are 62.5pt
            // wide and every point of that should answer a thumb (§3).
            .contentShape(Rectangle())
        }
        .buttonStyle(AppTabBarSlotStyle())
        .accessibilityLabel(
            AppTabBarPresentation.accessibilityLabel(for: slot.label, badgeCount: badgeCount)
        )
        .accessibilityIdentifier(AppTabBarPresentation.accessibilityIdentifier(for: slot))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func glyph(
        _ slot: AppTabBarPresentation.Slot, isSelected: Bool, badgeCount: Int
    ) -> some View {
        Image(systemName: slot.systemImage)
            .font(.title3)
            .foregroundStyle(isSelected ? Color.accentColor : Color.labelSecondary)
            .overlay(alignment: .topTrailing) {
                if let text = AppTabBarPresentation.badgeText(count: badgeCount) {
                    AppTabBarBadge(text: text)
                        .offset(x: AppTabBarMetrics.badgeOffset.width,
                                y: AppTabBarMetrics.badgeOffset.height)
                }
            }
    }

    /// Design F's position mark. The clear spacer holds the row's height whether or not this slot
    /// is the selected one, so the glyphs never shuffle as selection moves.
    private func indicator(isSelected: Bool) -> some View {
        ZStack {
            Color.clear
                .frame(height: AppTabBarMetrics.indicatorDotDiameter)
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(
                        width: AppTabBarMetrics.indicatorDotDiameter,
                        height: AppTabBarMetrics.indicatorDotDiameter
                    )
                    .matchedGeometryEffect(id: AppTabBarMetrics.indicatorID, in: indicatorNamespace)
            }
        }
    }
}

/// The Captures count. A capsule rather than a circle so "99+" still fits without the pill
/// clipping — `minWidth` keeps a single digit round.
private struct AppTabBarBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            // White on StateRisk is ~4.2:1 — the same ratio iOS's own badge ships. Acceptable
            // here because the count is NOT conveyed by the pill alone: the slot's
            // accessibility label carries it in words (§4's real requirement).
            .foregroundStyle(.white)
            // `fixedSize` before the frame, and it is load-bearing: the badge is an OVERLAY on
            // the glyph, so the size it is offered is the GLYPH's ~20pt — which truncated "99+"
            // to "9…" in the first render. Taking its ideal width first is what lets the pill
            // grow past the thing it sits on.
            .fixedSize()
            .padding(.horizontal, 4)
            .frame(minWidth: AppTabBarMetrics.badgeDiameter, minHeight: AppTabBarMetrics.badgeDiameter)
            // `StateRisk`, the app's own "this is overdue / wants you" hue, rather than one of
            // SwiftUI's raw hues — §4 has none of those. It lands within a shade of the
            // systemRed the `.badge()` this replaces used to draw.
            .background(Color("StateRisk"), in: Capsule())
            // The count is on the glyph, not in the reading order: `AppTabBarPresentation`
            // folds it into the slot's own label so VoiceOver hears one element, not two.
            .accessibilityHidden(true)
    }
}

/// §3's press state: a real scale, never an opacity filter.
private struct AppTabBarSlotStyle: ButtonStyle {
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

#Preview("Tab bar — Light") {
    AppTabBarPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Tab bar — Dark") {
    AppTabBarPreviewHost()
        .preferredColorScheme(.dark)
}

/// Selection has to be live for the dot to be worth previewing at all.
private struct AppTabBarPreviewHost: View {
    @State private var selection: AppTab = .today

    var body: some View {
        VStack {
            Spacer()
            AppTabBar(selection: $selection, captureInboxCount: 3)
            AppTabBar(selection: .constant(.tools), captureInboxCount: 0)
            AppTabBar(selection: .constant(.captures), captureInboxCount: 128)
        }
        .background(Color.pageBackground)
    }
}
