//
//  WeeklyFocusSummaryWidget.swift
//  ADHD LifeOS
//

import Charts
import SwiftUI

/// SwiftUI port of the web prototype's `src/components/WeeklyFocusSummaryWidget.tsx`: the
/// Monday–Sunday focus bar chart with its daily-goal reference line, the minutes/hours toggle,
/// and the stat strip (week total, active days, daily average, streak).
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex: Recharts' fixed palette becomes `.tint` / semantic colour, so both schemes work.
/// - Recharts → **Swift Charts** (`BarMark` + `RuleMark`), native since iOS 16 — no third-party
///   charting, no `ResponsiveContainer` equivalent needed.
/// - The web summed *estimated* minutes off task fields that don't exist in this app's model;
///   this plots **measured** `CompletedFocusSession` time via `FocusAnalytics`.
/// - Its area/bar style switch lives on `ProductivityTrendChart` instead, where a continuous
///   trend actually benefits from an area; a 7-bar week reads better as bars only.
struct WeeklyFocusSummaryWidget: View {
    let buckets: [FocusDayBucket]
    var dailyGoalMinutes: Int = 30

    private enum DisplayUnit: String, CaseIterable, Identifiable {
        case minutes, hours
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    @State private var unit: DisplayUnit = .minutes

    private var totalSeconds: Int { FocusAnalytics.totalFocusedSeconds(buckets) }
    private var activeDays: Int { FocusAnalytics.activeDayCount(buckets) }
    private var averageSeconds: Int { FocusAnalytics.dailyAverageSeconds(buckets) }
    private var streak: Int { FocusAnalytics.currentStreak(buckets) }
    private var goalProgress: Double {
        FocusAnalytics.goalProgress(buckets, dailyGoalMinutes: dailyGoalMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statStrip
            chart
            goalBar
        }
        .bentoCard()
        .accessibilityIdentifier("weeklyFocusSummaryWidget")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Label("This Week's Focus", systemImage: "timer")
                    .font(.caption.monospaced().weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)
                Text(FocusTimeFormatting.duration(seconds: totalSeconds))
                    .font(.title.bold())
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Picker("Unit", selection: $unit) {
                ForEach(DisplayUnit.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 160)
            .accessibilityIdentifier("weeklyFocusUnitPicker")
        }
    }

    private var statStrip: some View {
        HStack(spacing: 8) {
            stat(value: "\(activeDays)/\(max(1, buckets.count))", label: "Active Days")
            stat(value: FocusTimeFormatting.duration(seconds: averageSeconds), label: "Daily Avg")
            stat(value: "\(streak)", label: "Day Streak")
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(label)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var chart: some View {
        Chart {
            ForEach(buckets) { bucket in
                BarMark(
                    x: .value("Day", bucket.date, unit: .day),
                    y: .value(unit.label, chartValue(for: bucket))
                )
                .foregroundStyle(.tint)
                .cornerRadius(4)
            }
            if dailyGoalMinutes > 0 {
                RuleMark(y: .value("Goal", goalValue))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                AxisGridLine()
            }
        }
        .frame(height: 140)
        .accessibilityLabel("Focus time per day this week")
    }

    private var goalBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Weekly goal · \(dailyGoalMinutes)m/day")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((goalProgress * 100).rounded()))%")
                    .font(.caption2.monospaced().weight(.bold))
                    .foregroundStyle(goalProgress >= 1 ? .green : .secondary)
            }
            ProgressView(value: goalProgress)
                .tint(goalProgress >= 1 ? .green : .accentColor)
        }
        .accessibilityElement(children: .combine)
    }

    /// Hours are shown to one decimal so a 45-minute day doesn't flatten to "0".
    private func chartValue(for bucket: FocusDayBucket) -> Double {
        switch unit {
        case .minutes: return Double(bucket.focusedMinutes)
        case .hours: return Double(bucket.focusedSeconds) / 3600
        }
    }

    private var goalValue: Double {
        switch unit {
        case .minutes: return Double(dailyGoalMinutes)
        case .hours: return Double(dailyGoalMinutes) / 60
        }
    }
}

#if DEBUG
/// Deterministic sample week for previews — no `Date()` drift between snapshots.
private func previewBuckets() -> [FocusDayBucket] {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let minutes = [25, 50, 0, 75, 30, 0, 45]
    return minutes.enumerated().map { index, mins in
        FocusDayBucket(
            date: start.addingTimeInterval(TimeInterval(index * 86_400)),
            focusedSeconds: mins * 60,
            sessionCount: mins > 0 ? 2 : 0,
            completedCount: mins > 0 ? 1 : 0
        )
    }
}

#Preview("Light") {
    WeeklyFocusSummaryWidget(buckets: previewBuckets())
        .padding(16)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    WeeklyFocusSummaryWidget(buckets: previewBuckets())
        .padding(16)
        .preferredColorScheme(.dark)
}
#endif
