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
    @Binding var pickerEntries: [PlaceAppDirectoryEntry]
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
                // Snapshot NOW, then kick the throttled refresh — a completed fetch feeds
                // the next open, never the one being presented.
                pickerEntries = PlaceAppDirectoryProvider.shared.snapshot()
                isPickingApp = true
                Task { await PlaceAppDirectoryProvider.shared.refreshIfDue() }
            } label: {
                chooserRowLabel
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("actionEditorAppPicker")
            if showsCustomAppFields {
                labeledField("URL scheme") {
                    TextField("spotify", text: $draft.appScheme)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("actionEditorSchemeField")
                }
                labeledField("Or paste a link") {
                    TextField("open.spotify.com/\u{2026}", text: $draft.appLink)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("actionEditorLinkField")
                }
                labeledField("Shown as") {
                    TextField("Optional", text: $draft.appName)
                        .accessibilityIdentifier("actionEditorAppNameField")
                }
            }
        } header: {
            Text("Which app").sectionLabel()
        } footer: {
            Text(customAppFooter)
        }
    }

    /// The chooser reads as what it is: the chosen app's identity — avatar, name, and the
    /// three-state honesty line — with a disclosure chevron saying "tap to change". The old
    /// `LabeledContent("App", value:)` read as a mystery tab bar on E's device (2026-09-02).
    private var chooserRowLabel: some View {
        // Two stacked bands, not one tall HStack: the verdict can run to three lines, and
        // centring a 36pt disc against that floats it into the middle of the row.
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                PlaceAppMonogramDisc(
                    name: selectedAppLabel,
                    systemImage: hasChosenSomething ? nil : "plus.app"
                )
                Text(hasChosenSomething ? selectedAppLabel : "Choose an app\u{2026}")
                    .font(.callout)
                    .foregroundStyle(hasChosenSomething ? Color("LabelPrimary") : Color.accentColor)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            if let verdictLine {
                // Icon + words, never colour alone — the swiftui-pro Label precedent.
                Label(verdictLine, systemImage: verdictGlyph)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    /// A visible label above each custom field — placeholder-only fields read as bare
    /// underlines on E's device, with nothing naming them once filled.
    private func labeledField(
        _ label: String, @ViewBuilder field: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            field()
        }
        .padding(.vertical, 4)
    }

    private var hasChosenSomething: Bool {
        draft.destinationPick != nil || selectedDirectoryApp != nil
            || wantsCustomApp || !draft.appScheme.isEmpty || !draft.appLink.isEmpty
    }

    private var customAppFooter: String {
        showsCustomAppFields
            ? "A scheme opens the app directly; a pasted link falls back to the web page. "
              + "The link wins when both are filled. Arrives as a notification — "
              + "tapping it opens the app."
            : "Arrives as a notification — tapping it opens the app."
    }

    private var verdictGlyph: String {
        switch chosenScheme.map({ checkInstalled($0.isEmpty ? nil : $0) }) {
        case .looksInstalled: return "checkmark.circle"
        case .doesNotLookInstalled: return "info.circle"
        default: return "questionmark.circle"
        }
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
