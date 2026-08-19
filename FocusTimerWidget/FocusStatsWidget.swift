//
//  FocusStatsWidget.swift
//  FocusTimerWidget
//

import SwiftUI
import WidgetKit

/// The Home Screen widget: the Active Goal plus this week's focus, in small and medium.
///
/// The extension has no Firebase and no network budget, so the provider never fetches — it decodes
/// the snapshot the app published into the shared App Group container (`FocusWidgetSnapshotStore`).
/// A fresh install, an un-provisioned App Group and a payload from a different app version all land
/// on the same honest empty state rather than on fabricated numbers.
///
/// §7 / iOS floor: the widget target's deployment target is **16.1**, so `containerBackground`,
/// `ColorResource`-generated colour symbols and `contentMarginsDisabled` (all iOS 17+) are either
/// gated or avoided. Colours are consumed by catalog NAME (`Color("AccentColor")`) for the same
/// reason — the generated `Color.accent` symbol needs iOS 17.
struct FocusStatsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FocusWidgetSnapshotStore.widgetKind, provider: FocusStatsProvider()) { entry in
            FocusStatsWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Focus")
        .description("Your active goal and this week's focus time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline

struct FocusStatsEntry: TimelineEntry {
    let date: Date
    /// `nil` means "the app has never published" — a fresh install, or an App Group the widget
    /// can't reach. Distinct from a real week of zeros, which is a decoded snapshot.
    let snapshot: FocusWidgetSnapshot?
}

struct FocusStatsProvider: TimelineProvider {
    private let store = FocusWidgetSnapshotStore()

    func placeholder(in context: Context) -> FocusStatsEntry {
        FocusStatsEntry(date: Date(), snapshot: FocusWidgetSnapshot.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusStatsEntry) -> Void) {
        completion(FocusStatsEntry(date: Date(), snapshot: store.read()))
    }

    /// One entry, refreshed at midnight. There is nothing here that changes minute to minute — the
    /// app reloads this timeline the moment its own numbers move (`AppGroupFocusWidgetPublisher`),
    /// so the only *time*-driven change is the week rolling over.
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusStatsEntry>) -> Void) {
        let now = Date()
        let entry = FocusStatsEntry(date: now, snapshot: store.read())
        let nextMidnight = Calendar.current.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Views

struct FocusStatsWidgetView: View {
    let snapshot: FocusWidgetSnapshot?

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemMedium {
                FocusStatsMediumView(snapshot: snapshot)
            } else {
                FocusStatsSmallView(snapshot: snapshot)
            }
        }
        .widgetURL(URL(string: "adhdlifeos://widget/focus"))
        .focusWidgetBackground()
    }
}

/// Small: the Active Goal it wants you to start, over this week's headline number.
struct FocusStatsSmallView: View {
    let snapshot: FocusWidgetSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let goal = snapshot?.activeGoal {
                FocusWidgetLabel(text: goal.lifeAreaName ?? "Active goal")
                HStack(alignment: .top, spacing: 4) {
                    Text(goal.emoji)
                        .font(.caption)
                    Text(goal.title)
                        .font(.footnote.weight(.bold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                FocusWidgetLabel(text: "This week")
                Text(snapshot == nil ? "Open the app to sync" : "No active goal")
                    .font(.footnote.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            FocusWidgetWeekTotal(week: snapshot?.week)
            FocusWidgetGoalBar(week: snapshot?.week)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Medium: the Active Goal with its sprint plan on the left, the week's shape on the right.
struct FocusStatsMediumView: View {
    let snapshot: FocusWidgetSnapshot?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let goal = snapshot?.activeGoal {
                    FocusWidgetLabel(text: goal.lifeAreaName ?? "Active goal")
                    HStack(alignment: .top, spacing: 4) {
                        Text(goal.emoji)
                            .font(.callout)
                        Text(goal.title)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Label(
                        "\(FocusWidgetFormatting.human(seconds: goal.focusDurationSeconds)) sprint"
                            + " · \(goal.nudgeCount) nudges",
                        systemImage: "timer"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                } else {
                    FocusWidgetLabel(text: "Active goal")
                    Text(snapshot == nil ? "Open the app to sync your focus data." : "Nothing open — enjoy the gap.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                FocusWidgetLabel(text: "This week")
                FocusWidgetWeekTotal(week: snapshot?.week)
                FocusWidgetSparkBars(week: snapshot?.week)
                HStack(spacing: 8) {
                    FocusWidgetStat(value: "\(snapshot?.week.activeDayCount ?? 0)/7", caption: "days")
                    FocusWidgetStat(
                        value: FocusWidgetFormatting.human(seconds: snapshot?.week.dailyAverageSeconds ?? 0),
                        caption: "avg"
                    )
                    FocusWidgetStat(value: "\(snapshot?.week.streak ?? 0)", caption: "streak")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Pieces

/// The prototype's uppercase mono section label, in coral. Consumed by catalog name (see the type
/// doc): the generated colour symbol is iOS 17+ and this target floors at 16.1.
struct FocusWidgetLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.monospaced().weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(Color("AccentColor"))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct FocusWidgetWeekTotal: View {
    let week: FocusWidgetSnapshot.WeekStats?

    private var total: String {
        FocusWidgetFormatting.duration(seconds: week?.focusedSeconds ?? 0)
    }

    var body: some View {
        Text(total)
            .font(.title2.bold())
            .tracking(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel("\(total) focused this week")
    }
}

/// The daily-goal progress bar — the same 30m/day target the in-app weekly widget shows.
struct FocusWidgetGoalBar: View {
    let week: FocusWidgetSnapshot.WeekStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("CardSurface"))
                    Capsule()
                        .fill(Color("AccentColor"))
                        .frame(width: geometry.size.width * (week?.goalProgress ?? 0))
                }
            }
            .frame(height: 6)
            Text("\(week?.activeDayCount ?? 0)/7 days · \(week?.streak ?? 0) streak")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Seven Monday-first bars — the week's shape at a glance, without pulling Swift Charts into an
/// extension that renders one static frame.
struct FocusWidgetSparkBars: View {
    let week: FocusWidgetSnapshot.WeekStats?

    private var days: [Int] { week?.dailyFocusedSeconds ?? Array(repeating: 0, count: 7) }
    private var peak: Int { max(days.max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, seconds in
                Capsule()
                    .fill(seconds > 0 ? Color("AccentColor") : Color("CardSurface"))
                    .frame(height: barHeight(seconds: seconds))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 28, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus time per day this week")
    }

    /// Zero days keep a visible 4pt stub, so the week reads as seven days rather than as a gap.
    private func barHeight(seconds: Int) -> CGFloat {
        guard seconds > 0 else { return 4 }
        return max(4, 28 * CGFloat(seconds) / CGFloat(peak))
    }
}

struct FocusWidgetStat: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// iOS 17 wants widget content to declare its background through `containerBackground`; on 16.1
    /// the widget paints and pads itself. §7: the floor wins, so both paths ship.
    @ViewBuilder
    func focusWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(Color("PageBackground"), for: .widget)
        } else {
            self.padding(16)
                .background(Color("PageBackground"))
        }
    }
}

#if DEBUG
private let previewSnapshot = FocusWidgetSnapshot(
    generatedAt: Date(),
    activeGoal: FocusWidgetSnapshot.ActiveGoal(
        title: "Take a 10-minute walk", lifeAreaName: "Health", emoji: "🫀",
        focusDurationSeconds: 900, nudgeCount: 10
    ),
    week: FocusWidgetSnapshot.WeekStats(
        focusedSeconds: 4_260, sessionCount: 6, activeDayCount: 3, dailyAverageSeconds: 608,
        streak: 2, dailyGoalMinutes: 30, dailyFocusedSeconds: [1_200, 0, 1_860, 0, 1_200, 0, 0]
    )
)

/// Previews the views at real widget dimensions rather than through `#Preview(as:)`, which is an
/// iOS 17+ macro this 16.1 target can't adopt — the same call `FocusTimerWidgetLiveActivity` made.
private struct FocusStatsWidgetGallery: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FocusStatsSmallView(snapshot: previewSnapshot)
                    .padding(16)
                    .frame(width: 158, height: 158)
                    .background(Color("PageBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                FocusStatsSmallView(snapshot: nil)
                    .padding(16)
                    .frame(width: 158, height: 158)
                    .background(Color("PageBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            FocusStatsMediumView(snapshot: previewSnapshot)
                .padding(16)
                .frame(width: 338, height: 158)
                .background(Color("PageBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            FocusStatsMediumView(snapshot: nil)
                .padding(16)
                .frame(width: 338, height: 158)
                .background(Color("PageBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
    }
}

#Preview("Light") {
    FocusStatsWidgetGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusStatsWidgetGallery()
        .preferredColorScheme(.dark)
}
#endif
