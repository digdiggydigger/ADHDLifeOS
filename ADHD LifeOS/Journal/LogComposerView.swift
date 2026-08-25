//
//  LogComposerView.swift
//  ADHD LifeOS
//

import SwiftUI

struct LogComposerView: View {
    @ObservedObject var journalService: JournalService
    let lifeAreas: [LifeArea]
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $journalService.composerType) {
                        Text("Log").tag(LogType.log)
                        Text("Journal").tag(LogType.journal)
                    }
                    .accessibilityIdentifier("logComposerTypePicker")

                    LifeAreaPicker(
                        title: "Life Area",
                        noSelectionLabel: "No life area",
                        lifeAreas: lifeAreas,
                        selection: $journalService.composerLifeAreaId,
                        accessibilityID: "logComposerLifeAreaPicker"
                    )

                    TextField("What's on your mind?", text: $journalService.composerBody, axis: .vertical)
                        .accessibilityIdentifier("logComposerBodyField")
                }

                // Journal entries only — the web keeps energy and mood on `JournalEntry` and a
                // quick log has neither, so offering the controls for a Log would be offering to
                // record something that is then dropped on save.
                if journalService.composerType == .journal {
                    Section {
                        JournalEnergyMoodPicker(
                            energyLevel: $journalService.composerEnergyLevel,
                            moodEmoji: $journalService.composerMoodEmoji
                        )
                    }
                }

                if let errorMessage = journalService.createErrorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("logComposerErrorMessage")
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await journalService.createLog() {
                                onCreated()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!journalService.isComposerBodyValid || journalService.isCreating)
                    .accessibilityIdentifier("logComposerSubmitButton")
                }
            }
        }
    }
}

#if DEBUG
private struct PreviewJournalClientAdapting: JournalClientAdapting {
    func fetchLifeAreas() async throws -> [LifeArea] { [] }
    func fetchLogs() async throws -> [Log] { [] }
    func fetchFocusSessions() async throws -> [CompletedFocusSession] { [] }
    func fetchCaptures() async throws -> [Capture] { [] }
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
}

#Preview {
    LogComposerView(
        journalService: JournalService(client: PreviewJournalClientAdapting()),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)]
    ) {}
}
#endif
