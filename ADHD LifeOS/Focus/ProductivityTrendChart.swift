//
//  ProductivityTrendChart.swift
//  ADHD LifeOS
//

import Charts
import SwiftUI

/// SwiftUI port of the web prototype's `src/components/ProductivityTrendChart.tsx`: the rolling
/// 7-day trend with its metric switch (focus time / sessions), area-vs-bar style toggle, and the
/// headline stats (7-day total, peak day, streak).
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex, Recharts → **Swift Charts** (`AreaMark` / `BarMark`), same reasoning as
///   `WeeklyFocusSummaryWidget`.
/// - The web's `tasks completed` metric counted task rows by `completedAt`, a field this app's
///   `TaskItem` doesn't carry; the equivalent honest metric here is **focus sessions run**, which
///   is recorded. Focus time remains the primary metric either way.
struct ProductivityTrendChart: View {
    let buckets: [FocusDayBucket]

    private enum Metric: String, CaseIterable, Identifiable {
        case focus, sessions
        var id: String { rawValue }
        var label: String { self == .focus ? "Focus" : "Sessions" }
    }

    private enum ChartStyle: String, CaseIterable, Identifiable {
        case area, bar
        var id: String { rawValue }
        var symbol: String { self == .area ? "chart.xyaxis.line" : "chart.bar.fill" }
    }

    @State private var metric: Metric = .focus
    @State private var style: ChartStyle = .area

    private var peak: FocusDayBucket? { FocusAnalytics.peakDay(buckets) }
    private var totalSeconds: Int { FocusAnalytics.totalFocusedSeconds(buckets) }
    private var totalSessions: Int { FocusAnalytics.totalSessions(buckets) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            summaryLine
            chart
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityIdentifier("productivityTrendChart")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Label("7-Day Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption.monospaced().weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.tint)
            Spacer(minLength: 8)
            Button {
                style = style == .area ? .bar : .area
            } label: {
                Image(systemName: style.symbol)
                    .font(.footnote.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .accessibilityLabel(style == .area ? "Switch to bar chart" : "Switch to area chart")
            .accessibilityIdentifier("trendChartStyleToggle")
        }
    }

    private var summaryLine: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Metric", selection: $metric) {
                ForEach(Metric.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("trendChartMetricPicker")

            HStack(spacing: 8) {
                Text(
                    metric == .focus
                        ? FocusTimeFormatting.duration(seconds: totalSeconds)
                        : "\(totalSessions) sessions"
                )
                .font(.title3.bold())
                if let peak {
                    Text(peakLabel(for: peak))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        Chart(buckets) { bucket in
            if style == .area {
                AreaMark(
                    x: .value("Day", bucket.date, unit: .day),
                    y: .value(metric.label, value(for: bucket))
                )
                .foregroundStyle(.tint.opacity(0.25))
                LineMark(
                    x: .value("Day", bucket.date, unit: .day),
                    y: .value(metric.label, value(for: bucket))
                )
                .foregroundStyle(.tint)
                .interpolationMethod(.catmullRom)
            } else {
                BarMark(
                    x: .value("Day", bucket.date, unit: .day),
                    y: .value(metric.label, value(for: bucket))
                )
                .foregroundStyle(.tint)
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                AxisGridLine()
            }
        }
        .frame(height: 140)
        .accessibilityLabel("\(metric.label) over the last 7 days")
    }

    private func peakLabel(for bucket: FocusDayBucket) -> String {
        let duration = FocusTimeFormatting.duration(seconds: bucket.focusedSeconds)
        let weekday = bucket.date.formatted(.dateTime.weekday(.abbreviated))
        return "· peak \(duration) on \(weekday)"
    }

    private func value(for bucket: FocusDayBucket) -> Double {
        switch metric {
        case .focus: return Double(bucket.focusedMinutes)
        case .sessions: return Double(bucket.sessionCount)
        }
    }
}

#if DEBUG
private func trendPreviewBuckets() -> [FocusDayBucket] {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let minutes = [15, 40, 35, 0, 60, 90, 55]
    return minutes.enumerated().map { index, mins in
        FocusDayBucket(
            date: start.addingTimeInterval(TimeInterval(index * 86_400)),
            focusedSeconds: mins * 60,
            sessionCount: mins > 0 ? max(1, mins / 30) : 0,
            completedCount: mins > 0 ? 1 : 0
        )
    }
}

#Preview("Light") {
    ProductivityTrendChart(buckets: trendPreviewBuckets())
        .padding(16)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProductivityTrendChart(buckets: trendPreviewBuckets())
        .padding(16)
        .preferredColorScheme(.dark)
}
#endif
