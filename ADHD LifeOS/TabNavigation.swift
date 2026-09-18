//
//  TabNavigation.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

/// What a tap on the already-selected tab does (E's rule, 2026-09-08): deeper than the tab's
/// top-level page it pops back to that page; at the top-level page it scrolls to the top, the
/// iOS convention `TabView` gave for free and the custom bar lost. Sheets are untouched — they
/// keep their own dismissal (E's call, same day).
enum TabReselectionResponse: Equatable {
    case popToRoot
    case scrollToTop

    static func response(isAtRoot: Bool) -> TabReselectionResponse {
        isAtRoot ? .scrollToTop : .popToRoot
    }

    /// Whether the response also restores the capture disc from its pill (E's GIF, 2026-09-08
    /// evening). A scroll to the top IS "the page scrolled upwards again" — E's sticky-pill rule
    /// of 2026-08-31 — but it is a programmatic scroll, so the pan-driven pill never sees it:
    /// the tab bar, which reads the offset, restored on its own while the pill stayed collapsed
    /// over a page sitting at the top. A pop brings the root page back at its old offset, where
    /// the pill's state is still honest, so it leaves the disc alone.
    var restoresCaptureDisc: Bool {
        self == .scrollToTop
    }
}

/// Where the bar and the six tab roots meet.
///
/// The bar knows only the selection; each tab root knows only its own depth. A simulator probe
/// on 2026-09-08 (iOS 26.5) settled why neither can do the other's job: a root's `NavigationPath`
/// is BLIND to closure-link and flag pushes (`path.count` stays 0 and a path reset pops neither),
/// so nothing outside a root can pop it — only clearing the flag, or resetting a path that holds
/// a value, does. So the re-tap travels DOWN as a count each root watches and answers with its
/// own flags; the depth travels UP so root-level furniture (the search row, block 2) can read it.
@MainActor
final class TabNavigationCoordinator: ObservableObject {
    @Published private(set) var reselectionCounts: [AppTab: Int] = [:]
    @Published private(set) var rootStates: [AppTab: Bool] = [:]

    func reselect(_ tab: AppTab) {
        reselectionCounts[tab, default: 0] += 1
    }

    /// The Journal's pencil disc (`F-JournalPencilDisc`) lives in the root overlay, beside the
    /// capture disc, while the composer it opens is the Journal's private sheet. So a tap travels
    /// DOWN as a count the Journal watches — this type's re-tap shape, and never a re-tap itself:
    /// a request neither scrolls nor pops.
    @Published private(set) var journalEntryRequests = 0

    func requestJournalEntry() {
        journalEntryRequests += 1
    }

    func reselectionCount(for tab: AppTab) -> Int {
        reselectionCounts[tab] ?? 0
    }

    func report(_ tab: AppTab, isAtRoot: Bool) {
        rootStates[tab] = isAtRoot
    }

    /// A tab that has never reported is at its top-level page — the only place an unvisited tab
    /// can be. True by default, or block 2's search row would hide on every tab until each had
    /// been visited.
    func isAtRoot(_ tab: AppTab) -> Bool {
        rootStates[tab] ?? true
    }
}

/// The id every tab's scroll CONTENT ROOT carries, so a re-tap at the top level has something
/// to scroll to. On the padded root, not on a zero-height view inside it: the journey measured
/// a 16pt overshoot with the latter — the anchor sat inside the page's top padding, so bringing
/// it to the edge dragged the page 16pt past where it rests at launch. The root's frame includes
/// its padding, so scrolling IT to the top is exactly offset zero.
enum TabRootScrollAnchor {
    static let id = "tabRootScrollAnchor"
}

private struct TabRootModifier: ViewModifier {
    let tab: AppTab
    let isAtRoot: Bool
    let onPopToRoot: () -> Void
    @EnvironmentObject private var coordinator: TabNavigationCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Filled by the locator `tabRootScrollAnchor()` plants in this tab's scroll content, so the
    /// re-tap can reach the page's `UIScrollView` (`F-JournalPencilDisc`).
    @State private var scrollHandle = TabRootScrollHandle()

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .environment(\.tabRootScrollHandle, scrollHandle)
                .onAppear { coordinator.report(tab, isAtRoot: isAtRoot) }
                .onChange(of: isAtRoot) { coordinator.report(tab, isAtRoot: $0) }
                .onChange(of: coordinator.reselectionCount(for: tab)) { _ in
                    switch TabReselectionResponse.response(isAtRoot: isAtRoot) {
                    case .popToRoot:
                        onPopToRoot()
                    case .scrollToTop:
                        scrollToTop(proxy)
                    }
                }
        }
    }

    /// iOS 26+: a page whose large title collapsed gets it back (`TabRootLargeTitleReTap`); every
    /// other page — and every page below 26 — gets the shipped scroll, untouched. §7.1's DEGRADED
    /// shape: the floor lands the content at its top under an inline title, plainer, not absent.
    private func scrollToTop(_ proxy: ScrollViewProxy) {
        if #available(iOS 26.0, *) {
            if !TabRootLargeTitleReTap.restore(scrollHandle.scrollView, reduceMotion: reduceMotion) {
                scrollToAnchor(proxy)
            }
        } else {
            scrollToAnchor(proxy)
        }
    }

    /// The shipped re-tap (E, 2026-09-08). Instant under Reduce Motion: a scroll to the top is
    /// re-positioning, not an appearance.
    private func scrollToAnchor(_ proxy: ScrollViewProxy) {
        withAnimation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
        ) {
            proxy.scrollTo(TabRootScrollAnchor.id, anchor: .top)
        }
    }
}

/// The anchor's two jobs: the id the shipped scroll aims at, and — since `F-JournalPencilDisc` —
/// a locator the large-title re-tap finds the page's scroll view by.
private struct TabRootScrollAnchorModifier: ViewModifier {
    @Environment(\.tabRootScrollHandle) private var handle

    func body(content: Content) -> some View {
        content
            .id(TabRootScrollAnchor.id)
            .background(TabRootScrollLocator(handle: handle))
    }
}

/// The Journal's half of the pencil disc's request. Its own modifier rather than an
/// `@EnvironmentObject` on `JournalView`, so the Journal's whole body is not re-evaluated every
/// time any tab reports its depth or is re-tapped.
private struct JournalEntryRequestListener: ViewModifier {
    let onRequest: () -> Void
    @EnvironmentObject private var coordinator: TabNavigationCoordinator

    func body(content: Content) -> some View {
        content.onChange(of: coordinator.journalEntryRequests) { _ in onRequest() }
    }
}

extension View {
    /// Runs `action` each time the pencil disc asks for a new journal entry.
    func onJournalEntryRequest(perform action: @escaping () -> Void) -> some View {
        modifier(JournalEntryRequestListener(onRequest: action))
    }

    /// Marks a tab's scroll content root as the re-tap's scroll target. Apply AFTER the root's
    /// padding, so the target's top is the content's true top.
    func tabRootScrollAnchor() -> some View {
        modifier(TabRootScrollAnchorModifier())
    }

    /// Wires a tab's root screen to the coordinator: reports whether it is at its top-level page,
    /// and answers a re-tap by popping (via `onPopToRoot`, the root clearing its own pushes) or
    /// by scrolling to its `TabRootScrollAnchor`. Apply INSIDE the tab's `NavigationStack`, on the
    /// root content, next to the `navigationDestination`s whose flags `isAtRoot` reads.
    func tabRoot(_ tab: AppTab, isAtRoot: Bool, onPopToRoot: @escaping () -> Void) -> some View {
        modifier(TabRootModifier(tab: tab, isAtRoot: isAtRoot, onPopToRoot: onPopToRoot))
    }
}
