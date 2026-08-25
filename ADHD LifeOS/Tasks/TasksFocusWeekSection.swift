//
//  TasksFocusWeekSection.swift
//  ADHD LifeOS
//
//  The concept's `chartsOn` Tasks chart (Concept C, 2026-08-24): focus minutes per trailing day,
//  with today dimmed because it is still accruing, and the honest logged-vs-targeted caption.
//  Self-contained like `FocusAnalyticsSection` — it creates its own service so `TaskListView`
//  gains one line rather than another client, init parameter and task.
//

import SwiftUI

struct TasksFocusWeekSection: View {
    @StateObject private var service: FocusAnalyticsService

    init(reader: FocusHistoryReading? = nil) {
        _service = StateObject(
            wrappedValue: FocusAnalyticsService(reader: reader ?? FirebaseFocusSessionAdapter())
        )
    }

    var body: some View {
        // A real container (VStack), NOT `Group` — the FocusAnalyticsSection lesson (2026-08-19):
        // Group applies `.task` to its child, and an `EmptyView` child never "appears", so the
        // load would never fire and the section would stay empty forever.
        VStack(alignment: .leading, spacing: 8) {
            switch service.state {
            case .loaded(let sessions):
                // No sprints in the window hides the chart entirely: nothing was targeted, so
                // there is nothing to compare — which is not the same claim as a week of zeros.
                if let caption = MomentumWeekCharts.focusCaption(sessions: sessions) {
                    Text("Focus minutes · 7 days")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        WeekBarStrip(
                            fractions: MomentumWeekCharts.barFractions(
                                MomentumWeekCharts.focusMinutesPerDay(sessions: sessions)
                            ),
                            dimLast: true
                        )
                        Text(caption)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bentoCard()
                }
            case .failed(let message):
                // Visible breakage, minimal noise — the FocusAnalyticsSection footnote rule:
                // fully hiding a failed read once made it indistinguishable from "no history".
                Label("Focus history couldn't load: \(message)", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("tasksFocusWeekErrorFootnote")
            case .loading:
                EmptyView()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tasksFocusWeekChart")
        .task { await service.load() }
    }
}

#if DEBUG
private struct PreviewFocusHistory: FocusHistoryReading {
    func fetchHistory() async throws -> [CompletedFocusSession] {
        (0..<5).map { (back: Int) -> CompletedFocusSession in
            let focused: Int = 300 * (back + 1)
            let ended = Date().addingTimeInterval(Double(-back) * 86_400)
            return CompletedFocusSession(
                id: UUID(), taskId: nil, taskTitle: "Sprint", lifeAreaEmoji: "💼",
                plannedSeconds: 1500, focusedSeconds: focused,
                checkpointsReached: 2, completedNaturally: back.isMultiple(of: 2),
                startedAt: ended.addingTimeInterval(-1500),
                endedAt: ended
            )
        }
    }
}

#Preview("Light") {
    TasksFocusWeekSection(reader: PreviewFocusHistory())
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TasksFocusWeekSection(reader: PreviewFocusHistory())
        .padding()
        .preferredColorScheme(.dark)
}
#endif
