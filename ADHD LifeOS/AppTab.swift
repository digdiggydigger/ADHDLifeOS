//
//  AppTab.swift
//  ADHD LifeOS
//

/// The tab bar's stations under the hybrid v3 IA, and the selection is state so screens can
/// cross tabs (Today's inbox card → Captures).
///
/// **Six, not five, since E's 2026-09-02 call.** The rule this enum used to state — *"Five stays
/// five: iOS gives five slots before a 'More' tab, and a sixth would bury one of these"* — was
/// true of a SYSTEM `TabView`, which folds everything past the fifth `.tabItem` into a "More"
/// list. It is no longer the constraint the app lives under: F-Tools-1-Bar hides the system bar
/// and draws `AppTabBar` instead, so the slot count is ours to choose. E chose six, and **Tools**
/// is the sixth — a home for Places and the Life Areas editor, deliberately sparse so Routines
/// has somewhere obvious to land.
///
/// What replaces the old rule is arithmetic, not a system limit: six slots on the narrowest
/// supported iPhone (375pt) are 62.5pt each, clear of §3's 44pt touch-target floor.
/// `AppTabBarPresentationTests` pins that, and it is what a seventh tab would have to answer to.
///
/// `CaseIterable` is load-bearing: `AppTabBarPresentation.tabs` is tested for totality over these
/// cases, so a tab added here without a slot in the bar fails rather than silently vanishing —
/// the custom bar is now the ONLY way into a tab.
enum AppTab: Hashable, CaseIterable {
    case today, tasks, areas, journal, captures, tools
}
