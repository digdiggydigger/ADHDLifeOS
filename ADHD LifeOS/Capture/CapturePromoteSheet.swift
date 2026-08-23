//
//  CapturePromoteSheet.swift
//  ADHD LifeOS
//
//  B6's deferred promote form: "with the area already decided, it needs a title and a date, and
//  nothing else". The native form carries priority as well (ported behaviour, kept deliberately);
//  the title derives from the capture and the life area arrives from the detail's Filed-in card.
//

import SwiftUI

struct CapturePromoteSheet: View {
    let capture: Capture
    /// The Filed-in card's committed value at the moment the sheet opened — the area the new task
    /// inherits.
    let lifeAreaId: UUID?
    @ObservedObject var service: CaptureInboxService
    /// Runs after a successful promote, once this sheet has dismissed itself — the detail screen
    /// uses it to pop as well, since its capture no longer has an inbox to return to.
    let onPromoted: () -> Void

    @State private var priority: TaskPriority = .p4
    @State private var hasDueDate = false
    @State private var dueDate: Date?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titlePreview
                    form
                    // The partial-failure path must stay reachable: "task created, but couldn't
                    // mark processed" keeps the sheet open with this warning, and the retry tap
                    // goes back through the same service path (`pendingTaskIdsByCapture`).
                    if let warningMessage = service.warningMessage {
                        Label(warningMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("capturePromoteWarningMessage")
                    }
                    if let errorMessage = service.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("capturePromoteErrorMessage")
                    }
                    CreateTaskButton(
                        lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate, onCreateTask: promote
                    )
                    Text("The new task inherits this capture's life area, tags and notes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .navigationTitle("Make a task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("capturePromoteCancelButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var titlePreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("New task")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(CaptureRowPresentation.primaryText(for: capture))
                .font(.title3.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { option in
                    Text(option.rawValue.uppercased()).tag(option)
                }
            }
            .accessibilityIdentifier("capturePromotePriorityPicker")

            Toggle("Due Date", isOn: $hasDueDate)
                .onChange(of: hasDueDate) { newValue in
                    dueDate = newValue ? (dueDate ?? Date()) : nil
                }
            if hasDueDate {
                DatePicker(
                    "Date",
                    selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }),
                    displayedComponents: .date
                )
            }
        }
        .bentoCard()
    }

    private func promote(lifeAreaId: UUID?, priority: TaskPriority, dueDate: Date?) async -> Bool {
        let succeeded = await service.promoteToTask(
            capture: capture, lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate
        )
        if succeeded {
            dismiss()
            onPromoted()
        }
        return succeeded
    }
}
