//
//  AppTabContent.swift
//  ADHD LifeOS
//

import SwiftUI

/// Which tabs have been built, so a tab's screen can be constructed lazily and then KEPT.
///
/// Both halves are load-bearing and pull opposite ways: building every tab at launch would have
/// six screens fetching from Firestore before the user has touched anything, while discarding a
/// tab on the way out would throw away its scroll offset and its `NavigationStack` depth — the
/// exact regression a `switch selectedTab` causes. Built-once-then-kept is what `TabView` did,
/// and it is what `AppTabContent` reproduces.
struct AppTabVisitLog {
    private(set) var builtTabs: Set<AppTab>

    init(initial: AppTab) {
        builtTabs = [initial]
    }

    func isBuilt(_ tab: AppTab) -> Bool {
        builtTabs.contains(tab)
    }

    /// Idempotent, and deliberately one-way — nothing here ever un-builds a tab.
    mutating func select(_ tab: AppTab) {
        builtTabs.insert(tab)
    }
}

/// The app's tab container, in place of SwiftUI's `TabView`.
///
/// **Why not `TabView`.** The plan for this block was to keep `TabView` for content and hide only
/// its bar. That does not survive a sixth tab, and the reason is UIKit rather than SwiftUI:
/// `TabView` is a `UITabBarController`, and past five tabs UIKit moves the overflow into its
/// `moreNavigationController`. Hiding the bar does not undo that — tabs five and six still render
/// INSIDE the More navigation controller, which stamps a "More" back button onto their nav bars
/// and arms an edge-swipe that pops back to a More list the app never shows. Verified on the
/// iPhone 17 Pro simulator (iOS 26.5) with a standalone six-tab probe: with the system bar hidden
/// and `.toolbar(.hidden, for: .tabBar)` applied inside every tab, the accessibility tree still
/// reported `AXUniqueId: "BackButton", AXLabel: "More"` on the sixth tab. Dropping `.tabItem`
/// entirely changed nothing — the fold is on the controller, not on the bar items.
///
/// **Why this is not the `switch selectedTab` the architecture note rules out.** That note is
/// right: a `switch` rebuilds the destination on every change and discards its state. This does
/// not switch — it keeps every visited tab in the hierarchy and merely changes which one is
/// visible, so view identity, and with it scroll position and navigation depth, is preserved. It
/// is not the eager `ZStack` the same note warns about either: `AppTabVisitLog` means an
/// unvisited tab is never constructed at all.
///
/// The same probe confirmed all three properties directly: only the starting tab logged a build
/// at launch; a screen pushed on tab one was still pushed after a round trip through tab six; and
/// a scroll offset on tab six came back to the point (row 0 at y = −377.33 both times).
struct AppTabContent<Content: View>: View {
    let selection: AppTab
    @ViewBuilder var content: (AppTab) -> Content

    @State private var visitLog: AppTabVisitLog

    init(selection: AppTab, @ViewBuilder content: @escaping (AppTab) -> Content) {
        self.selection = selection
        self.content = content
        _visitLog = State(initialValue: AppTabVisitLog(initial: selection))
    }

    var body: some View {
        ZStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                if visitLog.isBuilt(tab) {
                    content(tab)
                        .opacity(tab == selection ? 1 : 0)
                        // Both needed. Without `allowsHitTesting` the invisible tabs still take
                        // taps meant for the visible one; without `accessibilityHidden` VoiceOver
                        // reads all six screens as one page.
                        .allowsHitTesting(tab == selection)
                        .accessibilityHidden(tab != selection)
                        .zIndex(tab == selection ? 1 : 0)
                }
            }
        }
        .onChange(of: selection) { visitLog.select($0) }
    }
}
