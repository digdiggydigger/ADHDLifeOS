//
//  PlaceActionsEditorView.swift
//  ADHD LifeOS
//
//  The Place editor's action add/edit sheet (F-PlaceActions-2-Editor). The Actions section
//  itself lives in `PlaceActionsSection.swift` since the block-4 split. Gated to iOS 17 with
//  the rest of the Places feature — see `PlaceMapPicker` for the §7 note.
//

import ContactsUI
import SwiftUI

/// Add or edit one action: direction, kind, and the kind's own details.
@available(iOS 17.0, *)
struct PlaceActionEditorSheet: View {
    /// `nil` when adding.
    let existing: PlaceAction?
    /// For the picker's destination step: the place the editor is already inside, so
    /// "Directions to <place>" needs nothing typed.
    let placeName: String
    let placeCoordinate: PlaceCoordinate?
    let onSave: (PlaceAction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = PlaceActionDraft()
    @State private var hasSeeded = false
    @State private var isPickingContact = false
    @State private var isPickingApp = false
    /// E stepped out to "Something else…" (or is editing an action the directory doesn't
    /// know) — the scheme/name fields show instead of a directory pick.
    @State private var wantsCustomApp = false
    /// The directory the OPEN picker renders: snapshotted when the sheet presents (bundled +
    /// last good remote), so a refresh landing mid-open never reshuffles under E's finger —
    /// it updates what the NEXT open snapshots (F-AppDirectory-4).
    @State private var pickerEntries: [PlaceAppDirectoryEntry] = []

    private var canSave: Bool { PlaceActionValidation.canSave(draft) }

    var body: some View {
        NavigationStack {
            Form {
                whenSection
                whatSection
                detailSection
            }
            .navigationTitle(existing == nil ? "New action" : "Edit action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("actionEditorCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let action = PlaceActionValidation.makeAction(
                            from: draft, id: existing?.id ?? UUID()
                        ) else { return }
                        onSave(action)
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("actionEditorSaveButton")
                }
            }
            .task { seedOnce() }
            .sheet(isPresented: $isPickingContact) {
                ContactPicker { name, phone in
                    draft.contactName = name
                    draft.contactPhone = phone
                }
            }
            .sheet(isPresented: $isPickingApp) {
                PlaceAppPickerView(
                    entries: pickerEntries,
                    placeName: placeName,
                    placeCoordinate: placeCoordinate,
                    onPick: { entry in
                        draft.appScheme = entry.scheme
                        draft.appName = entry.name
                        draft.appLink = ""
                        draft.destinationPick = nil
                        wantsCustomApp = false
                    },
                    onPickLink: { pick in
                        draft.destinationPick = pick
                        draft.appScheme = ""
                        draft.appName = ""
                        draft.appLink = ""
                        wantsCustomApp = false
                    },
                    onCustom: {
                        // A stale directory pick clears so the fields start blank; what E
                        // TYPED under custom earlier survives the round trip through the sheet.
                        if selectedDirectoryApp != nil {
                            draft.appScheme = ""
                            draft.appName = ""
                        }
                        draft.destinationPick = nil
                        wantsCustomApp = true
                    }
                )
            }
        }
    }

    private var whenSection: some View {
        Section {
            Picker("When", selection: $draft.direction) {
                Text("On arrival").tag(PlaceActionDirection.arrival)
                Text("When leaving").tag(PlaceActionDirection.departure)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: draft.direction) { _, _ in Haptics.play(.selection) }
            .accessibilityIdentifier("actionEditorDirectionPicker")
        } header: {
            Text("When").sectionLabel()
        }
    }

    private var whatSection: some View {
        Section {
            Picker("Action", selection: $draft.kindChoice) {
                ForEach(PlaceActionDraft.KindChoice.allCases, id: \.self) { choice in
                    Label(choice.displayName, systemImage: PlaceAppPickerPresentation.kindGlyph(for: choice))
                        .tag(choice)
                }
            }
            .onChange(of: draft.kindChoice) { _, _ in Haptics.play(.selection) }
            .accessibilityIdentifier("actionEditorKindPicker")
        } header: {
            Text("What").sectionLabel()
        }
    }

    @ViewBuilder
    private var detailSection: some View {
        switch draft.kindChoice {
        case .openApp: openAppDetail
        case .openURL: openURLDetail
        case .textContact: textContactDetail
        case .startSprint: startSprintDetail
        case .createCapture: createCaptureDetail
        case .journalLine: journalLineDetail
        case .openScreen: openScreenDetail
        }
    }

    private var openAppDetail: some View {
        PlaceActionAppDetailSection(
            draft: $draft, isPickingApp: $isPickingApp, pickerEntries: $pickerEntries,
            wantsCustomApp: wantsCustomApp
        )
    }

    /// The directory entry a pick landed on, if the current scheme is one of its.
    private var selectedDirectoryApp: PlaceAppDirectoryEntry? {
        draft.selectedDirectoryApp(in: PlaceAppDirectoryBundled.entries)
    }

    private var openURLDetail: some View {
        Section {
            TextField("example.com/page", text: $draft.urlString)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("actionEditorURLField")
        } header: {
            Text("Which address").sectionLabel()
        } footer: {
            Text("Arrives as a notification — tapping it opens the page.")
        }
    }

    private var textContactDetail: some View {
        Section {
            Button {
                isPickingContact = true
            } label: {
                LabeledContent(
                    "Contact",
                    value: draft.contactName.isEmpty ? "Choose…" : draft.contactName
                )
            }
            .accessibilityIdentifier("actionEditorContactButton")
            TextField("Phone number", text: $draft.contactPhone)
                .keyboardType(.phonePad)
                .accessibilityIdentifier("actionEditorPhoneField")
            TextField("Message", text: $draft.messageBody, axis: .vertical)
                .accessibilityIdentifier("actionEditorMessageField")
        } header: {
            Text("Who and what").sectionLabel()
        } footer: {
            Text("Arrives as a notification — tapping it opens Messages with this filled in. "
                 + "iOS always leaves the final Send to you.")
        }
    }

    private var startSprintDetail: some View {
        Section {
            TextField("Minutes (blank = your default)", text: $draft.sprintMinutes)
                .keyboardType(.numberPad)
                .accessibilityIdentifier("actionEditorMinutesField")
        } header: {
            Text("How long").sectionLabel()
        } footer: {
            Text("Arrives as a notification — tapping it starts the sprint. "
                 + "Between \(MomentumPreferences.sprintMinutesRange.lowerBound) and "
                 + "\(MomentumPreferences.sprintMinutesRange.upperBound) minutes.")
        }
    }

    private var createCaptureDetail: some View {
        Section {
            TextField("What lands in your inbox", text: $draft.captureText, axis: .vertical)
                .accessibilityIdentifier("actionEditorCaptureField")
        } header: {
            Text("The note").sectionLabel()
        } footer: {
            Text("Runs by itself when the crossing fires — no tap needed.")
        }
    }

    private var journalLineDetail: some View {
        Section {
            TextField("What gets written", text: $draft.journalBody, axis: .vertical)
                .accessibilityIdentifier("actionEditorJournalField")
        } header: {
            Text("The line").sectionLabel()
        } footer: {
            Text("Runs by itself when the crossing fires, stamped with this place.")
        }
    }

    private var openScreenDetail: some View {
        Section {
            Picker("Screen", selection: $draft.screen) {
                ForEach(PlaceActionScreen.allCases, id: \.self) { screen in
                    Text(screen.displayName).tag(screen)
                }
            }
            .accessibilityIdentifier("actionEditorScreenPicker")
        } header: {
            Text("Which screen").sectionLabel()
        } footer: {
            Text("Arrives as a notification — tapping it lands you there.")
        }
    }

    /// Seeds once, like the place editor — `.task` can re-run, and re-seeding mid-edit would
    /// throw away what E typed.
    private func seedOnce() {
        guard !hasSeeded else { return }
        hasSeeded = true
        guard let existing, let seeded = PlaceActionDraft(editing: existing) else { return }
        draft = seeded
        // An open-app action the directory doesn't know is a custom one — its fields must be
        // visible from the first render, never hidden behind a blank-looking pick. Same for a
        // hand-pasted web link (a destination pick shows through its own label instead).
        if case .openApp = existing.kind, selectedDirectoryApp == nil {
            wantsCustomApp = true
        }
        if case .openLink = existing.kind, !draft.appLink.isEmpty {
            wantsCustomApp = true
        }
    }
}

/// The system contact picker. No Contacts permission is needed for a one-off pick — the sheet
/// runs out of process and hands back only what E chose.
private struct ContactPicker: UIViewControllerRepresentable {
    let onPick: (_ name: String, _ phone: String) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // Only contacts that HAVE a number are selectable — a pick that silently produced no
        // phone would make the Save button's refusal unexplainable.
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_ controller: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (_ name: String, _ phone: String) -> Void

        init(onPick: @escaping (_ name: String, _ phone: String) -> Void) {
            self.onPick = onPick
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            guard let phone = contact.phoneNumbers.first?.value.stringValue else { return }
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? phone
            onPick(name, phone)
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Sheet — Light") {
    PlaceActionEditorSheet(
        existing: nil, placeName: "Gym",
        placeCoordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)
    ) { _ in }
        .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Sheet — Dark") {
    PlaceActionEditorSheet(existing: nil, placeName: "Gym", placeCoordinate: nil) { _ in }
        .preferredColorScheme(.dark)
}
#endif
