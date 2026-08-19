//
//  DailySummaryView.swift
//  ADHD LifeOS
//

import SwiftUI

/// SwiftUI port of the web prototype's `src/components/DailySummaryView.tsx` — its banner card
/// (badge pill, heavy tight-tracked title, mono caption line), four-stat metric strip with tinted
/// icon chips, and accent-bordered highlight card.
///
/// Deliberate deviations from the React source, per CLAUDE.md:
/// - §4 zero-hex: the web palette (`#FF5B5B` coral, `#1C1C1A` ink, `#F2EFE9` cream) becomes
///   adaptive semantic color — `.tint` accent, `Color(.secondarySystemBackground)` cards,
///   `.primary`/`.secondary` text — so dark mode is free and correct.
/// - The Gemini generate/tone/copy controls are not ported: the `/api/gemini/daily-summary`
///   backend doesn't exist on iOS, and a dead button is worse than no button. The highlight text
///   is the React file's own offline fallback idea ("Neuro-Synthesis"): synthesized locally from
///   real counts by `DailySummaryHeadline`, so the card is honest and always populated.
/// - The web metrics (completed-today, focus minutes, journal count) rely on model fields the
///   iOS models don't have (`completedAt`, `focusMinutesLogged`, mood) — the strip shows the
///   same visual with the four numbers Home actually knows: open tasks, life areas, inbox
///   ideas, due nudges.
struct DailySummaryView: View {
    let openTaskCount: Int
    let lifeAreaCount: Int
    let inboxCount: Int
    let dueNudgeCount: Int

    private let metricColumns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            bannerCard
            LazyVGrid(columns: metricColumns, spacing: 16) {
                DailyMetricCard(
                    value: "\(openTaskCount)", label: "Open Tasks",
                    systemImage: "checkmark.circle.fill", tint: .green
                )
                DailyMetricCard(
                    value: "\(dueNudgeCount)", label: "Nudges Due",
                    systemImage: "flame.fill", tint: .red
                )
                DailyMetricCard(
                    value: "\(lifeAreaCount)", label: "Life Areas",
                    systemImage: "square.grid.2x2.fill", tint: .indigo
                )
                DailyMetricCard(
                    value: "\(inboxCount)", label: "Ideas Offloaded",
                    systemImage: "tray.fill", tint: .orange
                )
            }
            highlightCard
        }
        .accessibilityIdentifier("homeDailySummary")
    }

    // MARK: - Banner (web: light-card 32pt-radius header with badge, black title, muted sub)

    private var bannerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                Text("Today's Highlights")
                    .sectionLabel()
            }
            .foregroundStyle(.tint)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            // Color.accentColor.opacity, not .tint.opacity — ShapeStyle.opacity is iOS 17+, target is 16.
            .background(Color.accentColor.opacity(0.12), in: Capsule())

            Text("Daily Executive Summary")
                .font(.title.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .lineLimit(2)

            Text("Your day at a glance — wins, open loops, and the next smallest step.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.caption.monospaced().weight(.bold))
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .bentoCard()
    }

    // MARK: - Highlight (web: accent-bordered AI highlight box; here: local synthesis)

    private var highlightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 24, height: 24)
                    .background(.tint, in: Circle())
                Text("Daily Highlight")
                    .sectionLabel()
                    .foregroundStyle(.tint)
            }
            Text(
                DailySummaryHeadline.text(
                    openTasks: openTaskCount,
                    lifeAreas: lifeAreaCount,
                    inbox: inboxCount,
                    dueNudges: dueNudgeCount
                )
            )
            .font(.title3.bold())
            .fixedSize(horizontal: false, vertical: true)
        }
        .bentoCard()
        // The web's accent-bordered highlight box keeps its 2pt accent ring on top of the
        // shared hairline.
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 2)
        )
    }
}

/// One stat card in the metric quick-strip — the web's icon-chip + black number + mono caption
/// row, on the shared card background.
private struct DailyMetricCard: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(label)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .bentoCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}

/// Pure headline synthesis — the local stand-in for the web's Gemini summary, split out so the
/// priority ladder (due nudges → inbox → clean slate → open tasks) is unit-testable without
/// rendering. Deterministic on its inputs; no dates, no randomness.
enum DailySummaryHeadline {
    static func text(openTasks: Int, lifeAreas: Int, inbox: Int, dueNudges: Int) -> String {
        if dueNudges > 0 {
            let noun = dueNudges == 1 ? "1 nudge is" : "\(dueNudges) nudges are"
            return "\(noun) due — a tiny step right now counts."
        }
        if inbox > 0 {
            let phrase = inbox == 1 ? "1 idea captured — triage it" : "\(inbox) ideas captured — triage one"
            return "\(phrase) to clear your head."
        }
        if openTasks == 0 {
            return "A clean slate today. Add one small task to build momentum."
        }
        let tasks = openTasks == 1 ? "1 open task" : "\(openTasks) open tasks"
        let areas = lifeAreas == 1 ? "1 area" : "\(lifeAreas) areas"
        return "\(tasks) across \(areas) — start with the smallest one."
    }
}

#Preview("Light") {
    ScrollView {
        DailySummaryView(openTaskCount: 7, lifeAreaCount: 4, inboxCount: 3, dueNudgeCount: 0)
            .padding(16)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ScrollView {
        DailySummaryView(openTaskCount: 0, lifeAreaCount: 6, inboxCount: 0, dueNudgeCount: 2)
            .padding(16)
    }
    .preferredColorScheme(.dark)
}
