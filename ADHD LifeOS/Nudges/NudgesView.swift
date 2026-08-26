//
//  NudgesView.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

struct NudgesView: View {
    @StateObject private var service: NudgesService
    @State private var expandedNudgeId: UUID?
    @State private var isPresentingAdd = false
    @State private var momentumPreferences: MomentumPreferences = .default

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
                VStack(spacing: 8) {
                    Text("Couldn't load your nudges")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .accessibilityIdentifier("nudgesErrorMessage")
            case .loaded:
                loadedContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isPresentingAdd) { addSheet.keyboardDismissal() }
        .task {
            await service.load()
            momentumPreferences = UserDefaultsMomentumPreferencesStore().read()
        }
        .onReceive(DataChangeSignal.debouncedPublisher()) { _ in
            Task { await service.load() }
        }
    }

    private var loadedContent: some View {
        let dueIds = Set(service.dueNudges().map(\.id))
        // ONE ForEach, one identity per nudge, content branching on dueness. Two sibling
        // ForEach sharing an id broke the diff when a dismissal moved a nudge between them —
        // the LazyVStack kept rendering the stale due card (caught by the nudge journey's
        // frame capture, 2026-08-25). Due-first ordering by stable partition, never sort.
        let ordered = service.nudges.filter { dueIds.contains($0.id) }
            + service.nudges.filter { !dueIds.contains($0.id) }
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header(dueCount: dueIds.count)
                if let errorMessage = service.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color("StateRisk"))
                        .accessibilityIdentifier("nudgesErrorLine")
                }
                if service.nudges.isEmpty {
                    Text("No nudges yet — a gentle schedule starts with one.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                        .accessibilityIdentifier("nudgesEmptyState")
                }
                ForEach(ordered) { nudge in
                    if dueIds.contains(nudge.id) {
                        dueCard(nudge)
                    } else {
                        NudgeRowView(
                            nudge: nudge,
                            isExpanded: expandedNudgeId == nudge.id,
                            errorMessage: service.errorMessage,
                            onToggleExpanded: {
                                expandedNudgeId = expandedNudgeId == nudge.id ? nil : nudge.id
                            },
                            onSave: { label, schedule in
                                if await service.update(
                                    nudge: nudge, editedLabel: label, editedSchedule: schedule
                                ) {
                                    expandedNudgeId = nil
                                }
                            },
                            onToggleActive: {
                                await service.toggleActive(nudge)
                            }
                        )
                        .bentoCard()
                        .opacity(nudge.active ? 1 : 0.6)
                    }
                }
                recentSection
                newNudgeRow
            }
            .padding(16)
        }
        .refreshable { await service.load() }
    }

    private func header(dueCount: Int) -> some View {
        let scheduled = service.nudges.filter(\.active).count - dueCount
        return HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(dueCount) due · \(max(scheduled, 0)) scheduled")
                    .sectionLabel()
                    .foregroundStyle(dueCount > 0 ? Color("StateWarn") : Color("LabelSecondary"))
                Text("Nudges")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                isPresentingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.body)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 40, height: 40)
                    .background(Color.cardSurface, in: Circle())
                    .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
                    .contentShape(Circle())
            }
            .accessibilityLabel("New nudge")
            .accessibilityIdentifier("nudgeAddButton")
        }
    }

    /// A due nudge as v3's card: the label large, the green "Done for now", and — once the new
    /// stamps have accrued — the streak dots with their honest line.
    private func dueCard(_ nudge: Nudge) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nudge.label)
                .font(.title3.bold())
                .tracking(-0.3)
            Text(NudgeSchedule.summary(cronString: nudge.schedule) ?? nudge.schedule)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if momentumPreferences.showStreaks, let dates = nudge.completionDates, !dates.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(NudgeStreak.weekFlags(dates: dates).enumerated()), id: \.offset) { _, hit in
                        Circle()
                            .fill(hit ? Color("StateGoVivid") : Color("TrackNeutralStrong"))
                            .frame(width: 8, height: 8)
                    }
                }
                .accessibilityHidden(true)
                if let line = NudgeStreak.line(dates: dates) {
                    Text(line)
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            Button("Done for now") {
                Task { await service.dismiss(nudge) }
            }
            .buttonStyle(MomentumSolidButtonStyle(fill: Color("StateGo"), foreground: Color("OnStateGo")))
            .accessibilityLabel("Dismiss \(nudge.label)")
            .accessibilityIdentifier("nudgeDismissButton-\(nudge.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    /// The latest "Done for now" stamps across every nudge — history that only exists now that
    /// completions are stamped. Grows from empty honestly.
    @ViewBuilder
    private var recentSection: some View {
        let recent = service.nudges
            .flatMap { nudge in (nudge.completionDates ?? []).map { (nudge.label, $0) } }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recent.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 8) {
                            Text(entry.1.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text(entry.0)
                                .font(.footnote)
                            Spacer()
                            MomentumChip(
                                text: "done",
                                background: Color("CardSurfaceSecondary"),
                                foreground: Color("StateGo")
                            )
                        }
                    }
                }
                .bentoCard()
            }
            .accessibilityIdentifier("nudgesRecentSection")
        }
    }

    private var newNudgeRow: some View {
        Button {
            isPresentingAdd = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("New nudge — label and schedule")
                    .font(.callout.weight(.medium))
            }
            .foregroundStyle(Color("LabelSecondary"))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("nudgesNewNudgeRow")
    }

    /// The add form, now a sheet — same fields, same identifiers, same service path.
    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Add Nudge") {
                    TextField("Label", text: $service.newLabel)
                        .accessibilityIdentifier("nudgeAddLabelField")

                    NudgeScheduleEditor(schedule: $service.newSchedule, idPrefix: "nudgeAdd")

                    if let createErrorMessage = service.createErrorMessage {
                        Text(createErrorMessage)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("nudgeAddErrorMessage")
                    }

                    Button("Add Nudge") {
                        Task {
                            if await service.createNudge() {
                                isPresentingAdd = false
                            }
                        }
                    }
                    .disabled(!service.isNewLabelValid || service.isCreating)
                    .accessibilityIdentifier("nudgeAddSubmitButton")
                }
            }
            .navigationTitle("New nudge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresentingAdd = false }
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
