//
//  HomeAccessoryStrips.swift
//  ADHD LifeOS
//
//  Today's header and the nudges-failure note, here for `HomeView.swift`'s length budget. The
//  reorder list, the inbox peek and the nudges door that lived here left Today with round 3's
//  Structure C (`F-E3-OneCardToday`): life areas and the inbox peek to their tabs, and the nudges
//  manager's door to Tools.
//

import SwiftUI

extension HomeView {
    /// Since `F-E3-OneCardToday` the "then" list shows this: a failed load would otherwise read
    /// exactly like a clean schedule with nothing due, and a reminder would silently never come.
    func nudgesFailureCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Couldn't load your nudges", systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color("StateWarn"))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeNudgesFailureCard")
    }

    /// v3's Today header: the date eyebrow over the big title, with settings as a 40pt well.
    ///
    /// The badged inbox tray well that sat beside it is gone: Captures is a tab now, the tab
    /// carries the badge, and a header icon that merely selected another tab was the third of
    /// five doors into one queue (round 2's audit).
    var todayHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                Text("Today")
                    .accessibilityIdentifier("homeTitle")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                headerIconWell(systemImage: "gearshape")
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("settingsButton")
        }
    }

    func headerIconWell(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(Color("LabelSecondary"))
            .frame(width: 40, height: 40)
            .background(Color.cardSurface, in: Circle())
            .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
            .contentShape(Circle())
    }
}
