//
//  FocusAnalyticsSection.swift
//  ADHD LifeOS
//

import SwiftUI

/// Hosts the two ported focus analytics widgets on Home, owning the single history read they
/// share. Deliberately self-contained (it creates its own service) so `HomeView` gains one line
/// rather than another service, init parameter and `.task`.
///
/// Renders nothing at all while loading or with no history yet: this is a secondary panel below
/// the life areas, and a spinner or empty card there would crowd the screen a new user sees
/// first — the ADHD-focused "minimise visual noise" rule in CLAUDE.md. A FAILED read, however,
/// shows a one-line footnote (changed 2026-08-19): fully hiding real breakage made a history-read
/// failure indistinguishable from "no history", which cost a blind debugging session.
struct FocusAnalyticsSection: View {
    @StateObject private var service: FocusAnalyticsService
    /// Reload trigger: `.task(id:)` re-runs the history fetch whenever this changes. Home feeds
    /// it completed-sprint count + pull-to-refresh count, so both paths share one mechanism.
    private let reloadToken: Int
    /// Handed the history the moment a read LANDS, so Home can publish the Home Screen widget's
    /// snapshot from the same fetch these charts render — one Firestore read, two consumers. Never
    /// called on failure: republishing zeros over a good snapshot would blank the widget for a
    /// transient network error.
    private let onHistoryLoaded: ([CompletedFocusSession]) -> Void

    init(
        reloadToken: Int = 0,
        reader: FocusHistoryReading? = nil,
        onHistoryLoaded: @escaping ([CompletedFocusSession]) -> Void = { _ in }
    ) {
        self.reloadToken = reloadToken
        self.onHistoryLoaded = onHistoryLoaded
        _service = StateObject(
            wrappedValue: FocusAnalyticsService(reader: reader ?? FirebaseFocusSessionAdapter())
        )
    }

    var body: some View {
        // A real container (VStack), NOT `Group`: Group applies `.task` to its child, and while
        // loading that child was `EmptyView` — which never "appears", so the task never fired,
        // the state never left `.loading`, and the section stayed empty forever (found
        // 2026-08-19; masked until then by the unpublished focus_sessions rules). A VStack is a
        // real zero-height layout node, so its `.task` runs unconditionally.
        VStack(spacing: 16) {
            switch service.state {
            case .loaded(let sessions) where !sessions.isEmpty:
                WeeklyFocusSummaryWidget(buckets: FocusAnalytics.currentWeek(sessions: sessions))
                ProductivityTrendChart(buckets: FocusAnalytics.rollingDays(sessions: sessions))
            case .failed(let message):
                // Icon + text (§4), quiet footnote weight — visible breakage, minimal noise.
                Label("Focus history couldn't load: \(message)", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("focusAnalyticsErrorFootnote")
            case .loading, .loaded:
                EmptyView()
            }
        }
        .task(id: reloadToken) {
            await service.load()
            if case .loaded(let sessions) = service.state {
                onHistoryLoaded(sessions)
            }
        }
    }
}
