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
    /// Injected so previews don't consult UIKit; the default is the real check.
    var checkInstalled: (String?) -> PlaceAppInstallVerdict = { scheme in
        PlaceAppInstallVerdict.verdict(scheme: scheme) {
            UIApplicationSchemeInstallChecker().canOpen($0)
        }
    }

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
        let explainer = showsCustomAppFields
            ? "A scheme opens the app directly; a pasted link opens the app if it's "
              + "installed, or the web page if not. The link wins when both are filled. "
              + base
            : base
        // The verdict line only once something is chosen — an empty editor has nothing to
        // check, and a premature "can't check" would read as a fault.
        guard let verdictLine else { return explainer }
        return verdictLine + "\n\n" + explainer
    }

    /// The three-state honesty line for the chosen app (F-AppDirectory-3), keyed off the
    /// scheme the draft would actually save.
    private var verdictLine: String? {
        guard let scheme = chosenScheme else { return nil }
        return PlaceAppInstallCopy.line(for: checkInstalled(scheme.isEmpty ? nil : scheme))
    }

    /// `nil` when nothing is chosen yet; "" when something is chosen but carries no scheme
    /// (an unrecognised pasted link) — chosen-but-uncheckable, which IS a verdict.
    private var chosenScheme: String? {
        if let pick = draft.destinationPick { return pick.scheme ?? "" }
        if let selectedDirectoryApp { return selectedDirectoryApp.scheme }
        if let typed = PlaceActionCatalog.normalizedScheme(draft.appScheme) { return typed }
        if !draft.appLink.isEmpty { return draft.linkSchemeHint ?? recognisedScheme ?? "" }
        return nil
    }

    private var recognisedScheme: String? {
        guard let link = PlaceActionValidation.normalizedWebAddress(draft.appLink),
              let host = URL(string: link)?.host else { return nil }
        return PlaceAppDirectory.entry(
            claimingHost: host, in: PlaceAppDirectoryBundled.entries
        )?.scheme
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
