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

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onAppear { coordinator.report(tab, isAtRoot: isAtRoot) }
                .onChange(of: isAtRoot) { coordinator.report(tab, isAtRoot: $0) }
                .onChange(of: coordinator.reselectionCount(for: tab)) { _ in
                    switch TabReselectionResponse.response(isAtRoot: isAtRoot) {
                    case .popToRoot:
                        onPopToRoot()
                    case .scrollToTop:
                        withAnimation(
                            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
                        ) {
                            proxy.scrollTo(TabRootScrollAnchor.id, anchor: .top)
                        }
                    }
                }
        }
    }
}

extension View {
    /// Marks a tab's scroll content root as the re-tap's scroll target. Apply AFTER the root's
    /// padding, so the target's top is the content's true top.
    func tabRootScrollAnchor() -> some View {
        id(TabRootScrollAnchor.id)
    }

    /// Wires a tab's root screen to the coordinator: reports whether it is at its top-level page,
    /// and answers a re-tap by popping (via `onPopToRoot`, the root clearing its own pushes) or
    /// by scrolling to its `TabRootScrollAnchor`. Apply INSIDE the tab's `NavigationStack`, on the
    /// root content, next to the `navigationDestination`s whose flags `isAtRoot` reads.
    func tabRoot(_ tab: AppTab, isAtRoot: Bool, onPopToRoot: @escaping () -> Void) -> some View {
        modifier(TabRootModifier(tab: tab, isAtRoot: isAtRoot, onPopToRoot: onPopToRoot))
    }
}
