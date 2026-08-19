//
//  FocusAnalyticsSection.swift
//  ADHD LifeOS
//

import SwiftUI

/// Hosts the two ported focus analytics widgets on Home, owning the single history read they
/// share. Deliberately self-contained (it creates its own service) so `HomeView` gains one line
/// rather than another service, init parameter and `.task`.
///
/// Renders nothing at all while loading, on failure, or with no history yet: this is a secondary
/// panel below the life areas, and a spinner or error card there would crowd the screen a new
/// user sees first — the ADHD-focused "minimise visual noise" rule in CLAUDE.md.
struct FocusAnalyticsSection: View {
    @StateObject private var service: FocusAnalyticsService

    init(reader: FocusHistoryReading? = nil) {
        _service = StateObject(
            wrappedValue: FocusAnalyticsService(reader: reader ?? FirebaseFocusSessionAdapter())
        )
    }

    var body: some View {
        Group {
            if case .loaded(let sessions) = service.state, !sessions.isEmpty {
                VStack(spacing: 16) {
                    WeeklyFocusSummaryWidget(buckets: FocusAnalytics.currentWeek(sessions: sessions))
                    ProductivityTrendChart(buckets: FocusAnalytics.rollingDays(sessions: sessions))
                }
            }
        }
        .task {
            await service.load()
        }
    }
}
