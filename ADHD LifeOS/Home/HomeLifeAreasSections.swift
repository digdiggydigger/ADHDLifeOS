//
//  HomeLifeAreasSections.swift
//  ADHD LifeOS
//
//  HomeView's life-areas section — the collapsible header, the Arrange control and the rows —
//  split out of `HomeMomentumSections.swift` so that file stays inside SwiftLint's 400-line
//  budget (it was at 399 when `F-CTACelebrations-1` needed room for the closure card's spring-in).
//
//  NOT to be confused with `HomeLifeAreasSection.swift`, singular, which holds the pure
//  `HomeLifeAreasSection` logic enum (`collapsedLine`, `showsArrangeControl`) that this file's
//  views call. Views here, decisions there.
//

import SwiftUI

extension HomeView {
    /// The reorder-mode toggle, as the collapsible header's trailing control. Arrange mode is
    /// still reached from here and nowhere else.
    @ViewBuilder
    func arrangeControl(activeAreas: [LifeArea], isVisible: Bool) -> some View {
        if isVisible {
            arrangeButton(activeAreas: activeAreas)
        }
    }

    /// The plain (non-folding) header, still used by ARRANGE mode, where the section is forced
    /// open and a fold control would be a contradiction.
    ///
    /// Deliberately NOT a toolbar item — the toolbar carries screen-level navigation, and a
    /// content-mutating mode control belongs beside the content it mutates. A real text label,
    /// never a third competing glyph (§4).
    func lifeAreasHeader(activeAreas: [LifeArea], showArrangeControl: Bool) -> some View {
        HStack {
            Text("Your life areas")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Spacer()
            if showArrangeControl {
                arrangeButton(activeAreas: activeAreas)
            }
        }
    }

    func arrangeButton(activeAreas: [LifeArea]) -> some View {
        Button {
            // 27. Arrange mode is a mode change, not a write — light either way.
            Haptics.play(.light)
            if isArranging {
                isArranging = false
                Task { await homeService.load() }
            } else {
                arrangeAreas = activeAreas
                isArranging = true
            }
        } label: {
            Label(
                isArranging ? "Done" : "Arrange",
                systemImage: isArranging ? "checkmark" : "arrow.up.arrow.down"
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(isArranging ? AreaPalette.work.onColor : Color.accentColor)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
                isArranging ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.cardSurface),
                in: Capsule()
            )
            .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: isArranging ? 0 : 1))
            .contentShape(Capsule())
        }
        .accessibilityIdentifier("homeArrangeButton")
    }

    /// v3's life-areas block: the caps header with the Arrange control, the explainer, and the
    /// rows themselves — and, since E's 2026-08-28 note, a fold.
    ///
    /// This is the tallest thing on Today, and folding it is how the rest of the screen comes back
    /// within reach; the nudges section below it already sits under the fold on a 6.3" phone. The
    /// header keeps saying what it hid, so collapsing is not the same as losing it.
    ///
    /// The state is a stored preference rather than `@State`: you fold this because you do not
    /// want to see it, and having it spring back open on the next launch would defeat the point.
    /// Arrange mode force-expands — reordering rows you cannot see is not a mode worth allowing.
    @ViewBuilder
    func lifeAreasSection(activeAreas: [LifeArea]) -> some View {
        let items = MomentumScoreboard.areaMomentum(
            areas: activeAreas, openTasks: homeService.openTasks, allTasks: homeService.allTasks
        )
        let isExpanded = !lifeAreasCollapsed || isArranging
        CollapsibleSectionHeader(
            title: "Your life areas",
            summary: HomeLifeAreasSection.collapsedLine(items: items),
            isExpanded: isExpanded,
            onToggle: { lifeAreasCollapsed.toggle() },
            trailing: {
                arrangeControl(
                    activeAreas: activeAreas,
                    isVisible: HomeLifeAreasSection.showsArrangeControl(
                        areaCount: activeAreas.count, isExpanded: isExpanded
                    )
                )
            }
        )
        .accessibilityIdentifier("homeLifeAreasHeader")
        if isExpanded {
            Text("How many of each area's tasks you have closed this week. Tap one to work inside it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            AreaMomentumList(items: items)
        }
    }
}
