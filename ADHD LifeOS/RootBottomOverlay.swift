//
//  RootBottomOverlay.swift
//  ADHD LifeOS
//
//  Split out of `RootView` in F-Tools-1-Bar. The reason is prosaic — RootView was at 397 of
//  SwiftLint's 400-line ceiling before a sixth tab and a custom bar were added to it — but this
//  stack was the right thing to lift out: it is the app's one persistent bottom furniture (the
//  capture disc, an unacknowledged sprint summary, the running timer), it has nothing to do with
//  tabs, and it reads better named than inlined.
//

import SwiftUI

/// Everything that floats above the tab bar on every tab.
///
/// The three pieces share one `VStack` so an active sprint PUSHES the disc up rather than letting
/// the timer bar occlude the disc's controls (E, 2026-08-19), and the whole stack is trailing-
/// pinned at full width because a `.bottom` overlay would otherwise centre it mid-screen once the
/// timer bar was gone (E's position review, 2026-08-25).
struct RootBottomOverlay: View {
    @Binding var isFabOpen: Bool
    /// The disc's sticky scrolled-down state (F-PillStay). Passed in rather than observed here:
    /// RootView owns the model that the window-level pan observer feeds.
    let showsPill: Bool
    @ObservedObject var focusService: FocusSessionService

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// E's 2026-08-31 margin pass lifted the stack a further 8pt off the tab bar (52 → 60),
    /// matching the trailing margin's 16 → 24 so `CaptureDiscMetrics.clearance` stays one number
    /// for both axes.
    ///
    /// Since F-Tools-1-Bar this is measured from the top of the bar EXPLICITLY. The bar is an
    /// overlay rather than a safe-area inset (see `AppTabContent`), so `.bottom` alignment now
    /// means the bottom of the safe area, not the top of the bar — and without the bar's own
    /// height added, E's 60pt gap would put the disc ON the bar instead of above it.
    private static let liftAboveBar: CGFloat = 60
    private static let bottomPadding = liftAboveBar + AppTabBarMetrics.rowHeight

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    isFabOpen.toggle()
                }
            } label: {
                CaptureDiscLabel(isFabOpen: isFabOpen, showsPill: showsPill)
            }
            .padding(.trailing, CaptureDiscMetrics.edgeMargin)
            .accessibilityLabel(isFabOpen ? "Close capture fan" : "Capture something")
            .accessibilityIdentifier("quickCaptureButton")

            // A sprint that finished while the app was dead announces itself here — above the
            // tab bar on every tab, gone only when acknowledged.
            if let summary = focusService.offlineCompletionSummary {
                OfflineSprintSummaryCard(record: summary) {
                    focusService.acknowledgeOfflineCompletion()
                }
                .padding(.horizontal, 16)
            }

            FocusTimerBar(service: focusService)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.bottom, Self.bottomPadding)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
            value: focusService.isActive
        )
    }
}
