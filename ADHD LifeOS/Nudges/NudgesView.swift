//
//  NudgesView.swift
//  ADHD LifeOS
//

import SwiftUI

struct NudgesView: View {
    @StateObject private var service: NudgesService
    @State private var expandedNudgeId: UUID?

    init(client: NudgesClientAdapting, notificationSchedulingClient: NudgeNotificationSchedulingAdapting) {
        _service = StateObject(
            wrappedValue: NudgesService(client: client, notificationSchedulingClient: notificationSchedulingClient)
        )
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("nudgesLoadingIndicator")
            case .failed(let message):
                VStack(spacing: 12) {
                    Text("Couldn't load your nudges")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .accessibilityIdentifier("nudgesErrorMessage")
            case .loaded:
                List {
                    addNudgeSection
                    dueSection
                    allNudgesSection
                }
            }
        }
        .navigationTitle("Nudges")
        .task {
            await service.load()
        }
    }

    private var addNudgeSection: some View {
        Section("Add Nudge") {
            TextField("Label", text: $service.newLabel)
                .accessibilityIdentifier("nudgeAddLabelField")

            NudgeScheduleEditor(schedule: $service.newSchedule, idPrefix: "nudgeAdd")

            if let createErrorMessage = service.createErrorMessage {
                Text(createErrorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("nudgeAddErrorMessage")
            }

            Button("Add Nudge") {
                Task { await service.createNudge() }
            }
            .disabled(!service.isNewLabelValid || service.isCreating)
            .accessibilityIdentifier("nudgeAddSubmitButton")
        }
    }

    @ViewBuilder
    private var dueSection: some View {
        let due = service.dueNudges()
        if !due.isEmpty {
            Section("Due") {
                ForEach(due) { nudge in
                    HStack {
                        Text(nudge.label)
                        Spacer()
                        Button("Dismiss") {
                            Task { await service.dismiss(nudge) }
                        }
                        .accessibilityIdentifier("nudgeDismissButton-\(nudge.id)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var allNudgesSection: some View {
        Section("All Nudges") {
            if service.nudges.isEmpty {
                Text("No nudges yet")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("nudgesEmptyState")
            } else {
                ForEach(service.nudges) { nudge in
                    NudgeRowView(
                        nudge: nudge,
                        isExpanded: expandedNudgeId == nudge.id,
                        errorMessage: service.errorMessage,
                        onToggleExpanded: {
                            expandedNudgeId = expandedNudgeId == nudge.id ? nil : nudge.id
                        },
                        onSave: { label, schedule in
                            if await service.update(nudge: nudge, editedLabel: label, editedSchedule: schedule) {
                                expandedNudgeId = nil
                            }
                        },
                        onToggleActive: {
                            await service.toggleActive(nudge)
                        }
                    )
                }
            }
        }
    }
}

/// A time-of-day picker plus a weekday multi-select, bound to a `NudgeSchedule`. Shared between
/// the Add Nudge form and each row's Edit form.
private struct NudgeScheduleEditor: View {
    @Binding var schedule: NudgeSchedule
    let idPrefix: String

    private static let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var timeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: Date())
                    ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                schedule.hour = components.hour ?? schedule.hour
                schedule.minute = components.minute ?? schedule.minute
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                .accessibilityIdentifier("\(idPrefix)TimePicker")

            HStack {
                ForEach(0..<7, id: \.self) { day in
                    let isSelected = schedule.weekdays.contains(day)
                    Button(Self.weekdaySymbols[day]) {
                        if isSelected {
                            schedule.weekdays.remove(day)
                        } else {
                            schedule.weekdays.insert(day)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(isSelected ? .accentColor : .secondary)
                    .accessibilityIdentifier("\(idPrefix)WeekdayToggle-\(day)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

private struct NudgeRowView: View {
    let nudge: Nudge
    let isExpanded: Bool
    let errorMessage: String?
    let onToggleExpanded: () -> Void
    let onSave: (String, NudgeSchedule) async -> Void
    let onToggleActive: () async -> Void

    @State private var label = ""
    @State private var schedule = NudgeSchedule(hour: 9, minute: 0, weekdays: Set(0...6))

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if isExpanded {
                editForm
            }
        }
        .padding(.vertical, 4)
        .opacity(nudge.active ? 1 : 0.5)
    }

    private var header: some View {
        HStack {
            Text(nudge.label)
                .strikethrough(!nudge.active)
            Spacer()
            Button("Edit") {
                label = nudge.label
                schedule = NudgeSchedule.parse(cronString: nudge.schedule)
                    ?? NudgeSchedule(hour: 9, minute: 0, weekdays: Set(0...6))
                onToggleExpanded()
            }
            .accessibilityIdentifier("nudgeEditButton-\(nudge.id)")

            Button(nudge.active ? "Deactivate" : "Reactivate") {
                Task { await onToggleActive() }
            }
            .accessibilityIdentifier("nudgeToggleActiveButton-\(nudge.id)")
        }
    }

    private var editForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Label", text: $label)
                .accessibilityIdentifier("nudgeEditLabelField-\(nudge.id)")

            NudgeScheduleEditor(schedule: $schedule, idPrefix: "nudgeEdit-\(nudge.id)")

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("nudgeEditErrorMessage-\(nudge.id)")
            }

            HStack {
                Button("Cancel") { onToggleExpanded() }
                Button("Save") {
                    Task { await onSave(label, schedule) }
                }
                .accessibilityIdentifier("nudgeEditSaveButton-\(nudge.id)")
            }
        }
    }
}

#if DEBUG
private struct PreviewNudgesClientAdapting: NudgesClientAdapting {
    func fetchNudges() async throws -> [Nudge] {
        [
            Nudge(
                id: UUID(), label: "Take medication", schedule: "0 9 * * *", active: true,
                lastFiredAt: nil, createdAt: Date(), updatedAt: Date()
            ),
            Nudge(
                id: UUID(), label: "Evening walk", schedule: "0 18 * * 1-5", active: false,
                lastFiredAt: Date(), createdAt: Date(), updatedAt: Date()
            )
        ]
    }

    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
        fatalError("unused in preview")
    }
    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        fatalError("unused in preview")
    }
    func markFired(id: UUID) async throws -> Nudge { fatalError("unused in preview") }
}

private struct PreviewNudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {}
    func cancelNotifications(nudgeId: UUID) async {}
    func hasScheduledNotifications(nudgeId: UUID) async -> Bool { false }
}

#Preview {
    NavigationStack {
        NudgesView(
            client: PreviewNudgesClientAdapting(),
            notificationSchedulingClient: PreviewNudgeNotificationSchedulingClient()
        )
    }
}
#endif
