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
    /// Should the bar be the floating card? `TabBarScrollActivity` answers it, from scroll
    /// POSITION: contract on the way down, hold until the page is back near the top. Defaulted
    /// so the resting bar can still be built (previews, and any caller with no scroll to speak
    /// of) without pretending to know where the page is.
    var isFloating: Bool = false

    @Namespace private var indicatorNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var morphAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    }

    /// The chip's tint needs more body against `CardSurface`'s near-black than against white.
    private var chipTint: Color {
        Color.accentColor.opacity(
            colorScheme == .dark
                ? AppTabBarMetrics.chipTintDark
                : AppTabBarMetrics.chipTintLight
        )
    }

    var body: some View {
        slots
            // A tab bar that grew with Dynamic Type would eat the screen at accessibility sizes —
            // the system's own bar caps for the same reason. Glyphs still scale up to xxxLarge.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .animation(morphAnimation, value: selection)
            .animation(morphAnimation, value: isFloating)
    }

    /// The one row of slots, in whichever container the current state calls for. Deliberately
    /// ONE `ForEach` across both states: the slots keep their view identity through the morph,
    /// which is what lets the indicator travel rather than cross-fade.
    @ViewBuilder
    private var slots: some View {
        let row = HStack(spacing: 0) {
            ForEach(AppTabBarPresentation.tabs) { slot in
                slotButton(slot)
            }
        }
        if isFloating {
            // Design B: a floating card, inset from both edges and lifted off the bottom, so the
            // page reads past it on either side while it is in the way.
            row
                .padding(.vertical, AppTabBarMetrics.floatingPaddingVertical)
                .padding(.horizontal, AppTabBarMetrics.floatingPaddingHorizontal)
                .background(
                    Color.cardSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppTabBarMetrics.floatingCornerRadius, style: .continuous
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: AppTabBarMetrics.floatingCornerRadius, style: .continuous
                    )
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 8)
                .padding(.horizontal, AppTabBarMetrics.floatingInset)
                .padding(.bottom, AppTabBarMetrics.floatingLift)
        } else {
            // Design F: full width, stopping at the bottom of the SAFE AREA rather than running
            // on into the home-indicator strip. E's GIF verdict: that strip was "empty space
            // that is coloured below the tab bar… wasted space", and it measured 53pt.
            //
            // **And no material.** There was an `.ultraThinMaterial` behind `BarSurface` for
            // §5's layer architecture, and it did two things, both bad. It BLED into the safe
            // area — SwiftUI extends a material background to the screen edge even when the view
            // it backs does not — painting the strip below the bar #272B2B against a bar of
            // #1F2028, so the thing E photographed and called a bug read as a second, lighter
            // bar underneath the first. And it was blurring nothing: `AppTabContent` reserves
            // this band, so no content ever passes beneath the resting bar. `BarSurface`'s own
            // 8% translucency over the page is the whole effect, and it is honest about it.
            row
                .frame(height: AppTabBarMetrics.rowHeight)
                .frame(maxWidth: .infinity)
                // `in: Rectangle()` is doing real work: a bare `.background(Color…)` EXTENDS
                // into the safe area — `Color` and shapes do that by design as backgrounds —
                // which is the same bleed the material had, just a shade that happened to match.
                // Filling an explicit shape clips the fill to the bar's own 72pt frame, so the
                // home-indicator strip below it is page, not chrome.
                .background(Color.barSurface, in: Rectangle())
        }
    }

    private func slotButton(_ slot: AppTabBarPresentation.Slot) -> some View {
        let isSelected = slot.tab == selection
        let badgeCount = slot.tab == .captures ? captureInboxCount : 0
        return Button {
            selection = slot.tab
        } label: {
            VStack(spacing: isFloating ? 0 : AppTabBarMetrics.glyphToIndicatorSpacing) {
                glyph(slot, isSelected: isSelected, badgeCount: badgeCount)
                    // Floating, the mark sits BEHIND the glyph rather than under it — the chip
                    // is the indicator, so there is nothing to stack below.
                    .background {
                        if isFloating && isSelected { chip }
                    }
                    .frame(
                        width: isFloating ? AppTabBarMetrics.chipWidth : nil,
                        height: isFloating ? AppTabBarMetrics.chipHeight : nil
                    )
                // The dot's row collapses to nothing while floating, which is what shrinks the
                // bar's height as it contracts.
                if !isFloating {
                    indicator(isSelected: isSelected)
                }
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
            // `.title2` at `.large` scale lands on ~25pt — the size the approved concept drew,
            // and 5pt up on the `.title3` that shipped first. Semantic, so Dynamic Type still
            // moves it (§1); the bar clamps the range rather than fixing the size.
            .font(.title2)
            .imageScale(.large)
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

    /// Design B's position mark — the dot's other form. It shares the dot's
    /// `matchedGeometryEffect` id, which is the whole point: the mark GROWS from one into the
    /// other and slides between slots, rather than one fading out while the other fades in.
    private var chip: some View {
        RoundedRectangle(cornerRadius: AppTabBarMetrics.chipCornerRadius, style: .continuous)
            .fill(chipTint)
            .frame(width: AppTabBarMetrics.chipWidth, height: AppTabBarMetrics.chipHeight)
            .matchedGeometryEffect(id: AppTabBarMetrics.indicatorID, in: indicatorNamespace)
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
