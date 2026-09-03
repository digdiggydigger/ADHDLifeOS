//
//  AppSearchModel.swift
//  ADHD LifeOS
//

import Combine
import Foundation
import SwiftUI

/// The app-level half of search: which scope is live, what has been typed, and whether the
/// full-screen surface is open.
///
/// **The row is app-level; the surface is screen-level.** The row has to line up with the capture
/// disc, which is drawn once in `RootBottomOverlay`, so putting the field anywhere else would mean
/// two views agreeing on a number instead of one `HStack` laying them out together. The SURFACE
/// needs the screen's data — tasks, and later captures and logs — so each screen presents its own
/// and reads the query from here. That split is what avoids hoisting `TasksService` up to
/// `RootView` for the sake of a text field.
///
/// **Everything that must reset on a tab change resets here.** `AppTabContent` keeps every visited
/// tab alive, so `.onDisappear` is not a signal this app can rely on; `RootView` calls
/// `activate(_:)` from `selectedTab` instead. A query still filtering a list the user typed it on
/// two tabs ago is the same class of bug as a bar stuck mid-morph, and `TabBarScrollActivity`
/// answered it the same way.
@MainActor
final class AppSearchModel: ObservableObject {
    @Published private(set) var scope: AppSearchScope = .none
    @Published var query: String = ""
    @Published private(set) var isPresentingSurface = false

    /// Point the row at a tab's scope. Idempotent: re-activating the scope already live changes
    /// nothing, because a redundant state update would otherwise clear the field mid-type.
    func activate(_ newScope: AppSearchScope) {
        guard newScope != scope else { return }
        scope = newScope
        query = ""
        isPresentingSurface = false
    }

    /// Open the full-screen surface. A no-op without a scope — there would be no results view
    /// behind it, so the cover would present over nothing.
    func open() {
        guard scope.showsRow else { return }
        isPresentingSurface = true
    }

    /// Cancel. Clears the query too: leaving it behind would keep the list filtered by a search
    /// the user has just dismissed.
    func close() {
        isPresentingSurface = false
        query = ""
    }

    /// For `fullScreenCover(isPresented:)`. Dismissing by any route — Cancel, a swipe, a
    /// programmatic close — goes through `close()`, so the query cannot survive a dismissal the
    /// model did not initiate.
    var surfacePresentation: Binding<Bool> {
        Binding(
            get: { self.isPresentingSurface },
            set: { wantsPresented in
                if wantsPresented { self.open() } else { self.close() }
            }
        )
    }
}
