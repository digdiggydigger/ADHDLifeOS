//
//  ToolsView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The sixth tab (E's 2026-09-02 call), and the reason the app now draws its own tab bar.
///
/// **Bento cards, not Settings rows** — E's explicit choice when the page was designed. The tab
/// is a destination in its own right, and a grouped `Form` would have read as a second Settings
/// screen rather than the workshop drawer it is meant to be. So it wears Today's and Areas'
/// language: an eyebrow, a large title, and `.bentoCard()` doors.
///
/// **It holds two things and is meant to look like it holds two things.** E asked for the page
/// left sparse so Routines — the declared next arc — has an obvious place to land. There is no
/// filler here on purpose; `ToolsCatalog` pins the count so a third card has to be a decision.
///
/// **The Settings split this completes is ASYMMETRIC, deliberately.** Places left Settings
/// entirely and is reachable only from here. Life Areas gained a door here and **kept** its
/// Settings row, because it is genuinely both a setting and a tool. That is knowingly the
/// opposite of the de-duplication the Captures rethink spent two blocks on, and it is not to be
/// tidied — `ToolsPageCallSiteTests` holds both halves.
///
/// **The clients arrive through the default-param door**, the way `SettingsView` takes the same
/// two. `RootView` holds neither of them — they were constructed inside `SettingsView` — so
/// threading them through `RootView` and `ADHD_LifeOSApp` would add two properties to two files
/// to duplicate what the house pattern already does, and would break the `ToolsView()` call site
/// `AppTabBarCallSiteTests` pins. Tests and previews inject through the same door.
struct ToolsView: View {
    private let placesClient: PlacesClientAdapting
    private let lifeAreaEditorClient: LifeAreaEditorClientAdapting

    init(
        placesClient: PlacesClientAdapting? = nil,
        lifeAreaEditorClient: LifeAreaEditorClientAdapting? = nil
    ) {
        self.placesClient = placesClient ?? FirebasePlacesClientAdapter()
        self.lifeAreaEditorClient = lifeAreaEditorClient ?? FirebaseLifeAreaEditorClientAdapter()
    }

    /// **The iOS 16 floor, answered once.** `PlacesListView` and everything under it are
    /// `@available(iOS 17.0, *)` while this app's deployment target is 16.0, so on a 16.x phone
    /// there is nothing to push to and the card must not be drawn. A hardcoded `true` here would
    /// compile and run perfectly on the 26.5 simulator every build in this project uses.
    private var placesSupported: Bool {
        if #available(iOS 17.0, *) { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Text("The screens you set up once and come back to rarely.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(ToolsCatalog.available(placesSupported: placesSupported)) { entry in
                        card(entry)
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground.ignoresSafeArea())
            // This page scrolls INSIDE the tab bar, so its last card would otherwise sit under
            // the capture disc. The bar's own inset is separate and already applied by RootView.
            .captureDiscClearance()
            // The house pattern for a tab root that draws its own title (Today, Areas, Journal).
            // Pushed screens are unaffected — they bring their own bar.
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Set up once")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text("Tools")
                .font(.largeTitle.bold())
                .tracking(-0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cards

    /// A closure-based `NavigationLink`, matching every other push in this stack. Mixing closure
    /// and value links in one `NavigationStack` silently breaks the push — trap b, confirmed on
    /// device in the Tag Editor block and restated in `LifeAreaEditorListView`.
    private func card(_ entry: ToolsCatalog.Entry) -> some View {
        NavigationLink {
            destination(for: entry.destination)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: entry.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("LabelPrimary"))
                    Text(entry.caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier(entry.accessibilityIdentifier)
    }

    /// Both destinations are PUSHED, so both stay under the capture disc and both ask for the
    /// room — the same call-site clearance `AreasView` applies to its own copy of the Life Areas
    /// editor. (Settings' copy needs none: a sheet covers the disc entirely.)
    @ViewBuilder
    private func destination(for destination: ToolsCatalog.Destination) -> some View {
        switch destination {
        case .places:
            // Gated for the same reason `placesSupported` is: this whole screen is iOS 17+.
            // Unreachable below 17 because the catalog never offers the card there.
            if #available(iOS 17.0, *) {
                PlacesListView(client: placesClient)
                    .captureDiscClearance()
            }
        case .lifeAreas:
            LifeAreaEditorListView(client: lifeAreaEditorClient)
                .captureDiscClearance()
        }
    }
}

#Preview("Tools — Light") {
    ToolsView()
        .preferredColorScheme(.light)
}

#Preview("Tools — Dark") {
    ToolsView()
        .preferredColorScheme(.dark)
}
