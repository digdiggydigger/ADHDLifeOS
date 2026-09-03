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
    /// What the current tab searches, or `.none`. Driven by `selectedTab` in RootView rather than
    /// by each screen registering itself: `AppTabContent` keeps every visited tab alive, so
    /// `.onAppear`/`.onDisappear` fire once and then effectively never again.
    var searchScope: AppSearchScope = .none
    /// Opens the full-screen surface. The screen presents it; this only asks.
    var onOpenSearch: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// E's 2026-08-31 margin pass lifted the stack a further 8pt off the tab bar (52 → 60),
    /// matching the trailing margin's 16 → 24 so `CaptureDiscMetrics.clearance` stays one number
    /// for both axes.
    ///
    /// **The claim that used to sit here — that `.bottom` alignment already means the top of the
    /// bar, so the bar's height needs no correction — was WRONG, and it shipped.** This is an
    /// `.overlay(alignment: .bottom)`, and its `.bottom` resolves to the screen's original safe
    /// area even though the bar is applied as a `safeAreaInset` above it. Measured on E's device:
    /// disc frame bottom 758pt against a bar top of 751pt, a 7pt OVERLAP — the disc was sitting on
    /// the bar, not above it. E reported it while approving the search row: *"make sure that you
    /// have added spacing between the top of the menu/nav tab bar and the collapsed pill."*
    ///
    /// So the lift is the gap PLUS the bar, derived in `AppSearchRowMetrics.bottomFurnitureLift`.
    ///
    /// Spelled in `AppSearchRowMetrics` since F-Search-1-Row so a test can hold it: E re-confirmed
    /// this gap by name when approving the search row.
    private static var bottomPadding: CGFloat { AppSearchRowMetrics.bottomFurnitureLift }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // E's layout (2026-09-03): the search field fills the leading width and the capture
            // disc sits at the end of the SAME row, centres aligned. One `HStack` lays both out,
            // so the alignment is by construction rather than two views agreeing on a number.
            //
            // The centres cannot drift: the disc's outer frame stays `discDiameter` square in
            // BOTH states — only the visual capsule shrinks to the pill — so the row's height is
            // the disc's, and the shorter field centres inside it.
            HStack(spacing: AppSearchRowMetrics.rowSpacing) {
                if let placeholder = searchScope.placeholder {
                    AppSearchRow(placeholder: placeholder, action: onOpenSearch)
                }
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                        isFabOpen.toggle()
                    }
                } label: {
                    CaptureDiscLabel(isFabOpen: isFabOpen, showsPill: showsPill)
                }
                .accessibilityLabel(isFabOpen ? "Close capture fan" : "Capture something")
                .accessibilityIdentifier("quickCaptureButton")
            }
            // The disc's own trailing margin, unchanged — E's number, settled over four device
            // passes. The field takes the page's 16pt margin on the leading side.
            .padding(.leading, 16)
            .padding(.trailing, CaptureDiscMetrics.edgeMargin)

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
