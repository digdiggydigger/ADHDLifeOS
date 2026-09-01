//
//  PlaceActionAppDetailSection.swift
//  ADHD LifeOS
//
//  The action editor's "Which app" section, split from `PlaceActionsEditorView.swift` when
//  the block-2 link field tipped the sheet over the 250-line type bar. Gated to iOS 17 with
//  the rest of the Places feature.
//

import SwiftUI

extension PlaceActionDraft {
    /// The directory entry the current scheme is a pick of, if any.
    func selectedDirectoryApp(in entries: [PlaceAppDirectoryEntry]) -> PlaceAppDirectoryEntry? {
        entries.first(where: { $0.scheme == appScheme })
    }
}

/// The pick row plus, on the custom path, the scheme / pasted-link / shown-as fields.
@available(iOS 17.0, *)
struct PlaceActionAppDetailSection: View {
    @Binding var draft: PlaceActionDraft
    @Binding var isPickingApp: Bool
    let wantsCustomApp: Bool

    var body: some View {
        Section {
            Button {
                isPickingApp = true
            } label: {
                LabeledContent("App", value: selectedAppLabel)
            }
            .accessibilityIdentifier("actionEditorAppPicker")
            if showsCustomAppFields {
                TextField("URL scheme (like spotify)", text: $draft.appScheme)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("actionEditorSchemeField")
                TextField("Or paste a link (like open.spotify.com/\u{2026})", text: $draft.appLink)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("actionEditorLinkField")
                TextField("Shown as (optional)", text: $draft.appName)
                    .accessibilityIdentifier("actionEditorAppNameField")
            }
        } header: {
            Text("Which app")
        } footer: {
            Text(customAppFooter)
        }
    }

    private var customAppFooter: String {
        let base = "Arrives as a notification — tapping it opens the app. "
            + "If the app isn't installed, nothing can open."
        guard showsCustomAppFields else { return base }
        return "A scheme opens the app directly; a pasted link opens the app if it's "
            + "installed, or the web page if not. The link wins when both are filled. "
            + base
    }

    private var selectedDirectoryApp: PlaceAppDirectoryEntry? {
        draft.selectedDirectoryApp(in: PlaceAppDirectoryBundled.entries)
    }

    private var selectedAppLabel: String {
        if let pick = draft.destinationPick { return pick.displayName }
        if let selectedDirectoryApp { return selectedDirectoryApp.name }
        if wantsCustomApp || !draft.appScheme.isEmpty || !draft.appLink.isEmpty {
            return "Custom"
        }
        return "Choose\u{2026}"
    }

    /// Custom fields show when E stepped out of the directory — or when the action being
    /// edited carries a scheme or link the directory doesn't know, which must never render as
    /// a blank pick with its fields hidden. A destination pick shows as itself, fields away.
    private var showsCustomAppFields: Bool {
        guard draft.destinationPick == nil else { return false }
        if wantsCustomApp { return true }
        if !draft.appLink.isEmpty { return true }
        return !draft.appScheme.isEmpty && selectedDirectoryApp == nil
    }
}
