//
//  FocusTimerBar.swift
//  ADHD LifeOS
//

import SwiftUI

/// SwiftUI port of the web prototype's `src/components/FocusTimerBar.tsx` — the persistent
/// "Bottom Floating Bar" — rebuilt in the scoreboard's ring language (Concept C S4, 2026-08-24):
/// the countdown ring with the live `MM:SS` in its centre and the checkpoint dots
/// (fired / next / pending) on its dial, the task title, the next-checkpoint caption, and the
/// pause-resume + stop controls, plus the modal's `+30s` / `+5m` extend actions. The web's emoji
/// chip + pill + linear mini-timeline became that one instrument — `ClosureRing`, the same view
/// the Home scoreboard draws — with the dot placement maths in `SprintRingGeometry`.
///
/// **Two states since F-FocusCard-1** (E's annotated screenshot `IMG_8307.jpg`, 2026-09-09). The
/// card the contents are drawn on is this file; the contents themselves are
/// `FocusTimerBarContent`. Expanded, it is the 16pt-inset card above with all four controls.
/// Collapsed, it is full-bleed to both screen edges with rounded TOP corners only, dropped flush
/// onto the tab bar, carrying exactly the ring, the sprint name and Pause. Every sprint starts
/// expanded, and **collapse is cleared only by the Confirm button that arrives in F-FocusCard-2**
/// — not by a tab switch, backgrounding or a relaunch, which is E's stated requirement.
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex: the web's fixed dark card (`dark-card`, white text, `#FF5B5B` accent) becomes
///   `.regularMaterial` over adaptive semantic colour, so the bar reads correctly in both light
///   and dark mode instead of being permanently dark.
/// - The web file's ~500-line in-app "Automated 30s Test Suite" debugger panel is deliberately
///   NOT ported: it is a development harness that asserts the checkpoint maths in the UI. Its
///   assertions live in `FocusCheckpointsTests` / `FocusSessionServiceTests` instead, which is
///   where they belong in a native app.
/// - The full-screen focus modal (timeline inspector, live cadence editor) exists as
///   `FocusSprintDetailView`, presented as a sheet by **long-pressing the card**. It used to be a
///   plain tap on the task row, and the tap now collapses; E chose the long-press over a Details
///   button, over tapping the ring, and over orphaning the view. This bar is that view's only
///   door in the whole app, so VoiceOver gets it as a named action rather than a held gesture.
struct FocusTimerBar: View {
    @ObservedObject var service: FocusSessionService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresentingDetail = false
    @State private var isConfirmingStop = false

    /// Read from the service, not held here: `RootView` is at 399 of 400 lines so a `@StateObject`
    /// has nowhere to live, Confirm resets collapse and Confirm is a service operation, and this
    /// view already `@ObservedObject`s the service — so the "pass a plain `Bool` down" rule, which
    /// exists for leaves that do NOT observe the model, does not apply.
    private var isCollapsed: Bool { service.isCardCollapsed }

    private var cardShape: FocusBarCardShape {
        FocusBarCardShape(
            cornerRadius: FocusBarMetrics.cornerRadius,
            roundsBottomCorners: !isCollapsed
        )
    }

    var body: some View {
        if let session = service.session {
            FocusTimerBarContent(
                session: session,
                isCollapsed: isCollapsed,
                checkpointBanner: service.checkpointBanner,
                reduceMotion: reduceMotion,
                onToggleCollapse: { setCollapsed(!isCollapsed) },
                onTogglePause: { service.togglePause() },
                onExtend: { service.addSeconds($0) },
                onRequestStop: { isConfirmingStop = true }
            )
            .padding(.horizontal, 16)
            .padding(
                .vertical,
                isCollapsed
                    ? FocusBarMetrics.collapsedPaddingVertical
                    : FocusBarMetrics.expandedPaddingVertical
            )
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: cardShape)
            .overlay(cardShape.strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
            // Tap-anywhere is one of the four affordances E chose, so the whole card — including
            // the slack between its controls — has to be hit-testable. Child buttons still win
            // their own taps; this only catches what they do not.
            .contentShape(Rectangle())
            .padding(.horizontal, isCollapsed ? 0 : FocusBarMetrics.expandedInset)
            // The flush drop. `.offset` and NOT negative bottom padding: this view is the LAST
            // child of `RootBottomOverlay`'s VStack, and negative padding there would shrink the
            // stack and drag the search row and the capture disc down 32pt with it.
            .offset(y: isCollapsed ? FocusBarMetrics.collapsedOffsetY : 0)
            .onTapGesture { setCollapsed(!isCollapsed) }
            .onLongPressGesture(minimumDuration: 0.45) { openDetail() }
            // **`.simultaneousGesture`, never `.gesture`.** A plain `.gesture(DragGesture(...))`
            // on the card wins the hit test over its children and swallows Pause's taps — which
            // collapsed would leave a card whose only remaining control is dead.
            .simultaneousGesture(
                DragGesture(minimumDistance: 12).onEnded { value in
                    switch FocusBarCollapseSwipe.outcome(
                        forTranslation: value.translation.height, isCollapsed: isCollapsed
                    ) {
                    case .collapse: setCollapsed(true)
                    case .expand: setCollapsed(false)
                    case .none: break
                    }
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: session.isPaused)
            .animation(
                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
                value: service.isCardCollapsed
            )
            .accessibilityIdentifier("focusTimerBar")
            // A held gesture is a poor door for VoiceOver, and this is the app's only route to the
            // sprint view. Both routes go through `openDetail()` so there is exactly one writer.
            .accessibilityAction(named: Text("Open the full sprint view")) { openDetail() }
            .sheet(isPresented: $isPresentingDetail) {
                FocusSprintDetailView(service: service)
            }
            // The same guard the modal's Complete & stop has (E, 2026-08-20): this Stop is the one
            // most likely to be mis-tapped — it sits beside +5m in a bar that is always on screen.
            .confirmationDialog(
                FocusStopConfirmation.title,
                isPresented: $isConfirmingStop,
                titleVisibility: .visible
            ) {
                Button(FocusStopConfirmation.confirmTitle, role: .destructive) {
                    Task { await service.stop() }
                }
                Button(FocusStopConfirmation.cancelTitle, role: .cancel) {}
            } message: {
                Text(FocusStopConfirmation.message(for: session))
            }
        }
    }

    /// `.light` is the sanctioned expand/collapse feel (`Theme/Haptics.swift`: *"a minor press
    /// that isn't a commitment: chip toggles, expand/collapse"*), precedent
    /// `Theme/CollapsibleSectionHeader.swift`. Haptics.swift deliberately excludes scroll-driven
    /// morphs; this is a deliberate tap, swipe or button press, so it qualifies.
    private func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        Haptics.play(.light)
        service.setCardCollapsed(collapsed)
    }

    /// The single writer of `isPresentingDetail`. The task row used to be a `Button` that opened
    /// the sheet itself; left in place it would win the hit test over the card's `.onTapGesture`
    /// across most of the card, so tapping the ring or the name would raise a sheet instead of
    /// collapsing.
    private func openDetail() {
        isPresentingDetail = true
    }
}

#if DEBUG
/// Preview-only service pre-loaded with a mid-flight sprint, so every preview renders the card in
/// its interesting state rather than empty.
@MainActor
private func previewService(collapsed: Bool = false) -> FocusSessionService {
    let service = FocusSessionService()
    service.start(
        taskId: UUID(), taskTitle: "Draft the quarterly review",
        lifeAreaEmoji: "💼", durationSeconds: 1500, cadence: .count(3)
    )
    service.setCardCollapsed(collapsed)
    return service
}

#Preview("Light") {
    FocusTimerBar(service: previewService())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusTimerBar(service: previewService())
        .preferredColorScheme(.dark)
}

#Preview("Collapsed — light") {
    FocusTimerBar(service: previewService(collapsed: true))
        .preferredColorScheme(.light)
}

#Preview("Collapsed — dark") {
    FocusTimerBar(service: previewService(collapsed: true))
        .preferredColorScheme(.dark)
}
#endif
