//
//  NudgesView.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

/// The full nudge surface: create, edit, reschedule, pause, and the completion history.
///
/// It lost its tab on 2026-08-28 when Captures took the slot back, and is now pushed from Today's
/// nudges section. It takes the PUSHING screen's service rather than making its own — the
/// `CaptureDetailView` precedent — so dismissing a nudge here and popping back to Today shows one
/// consistent list instead of two services disagreeing about what is due.
struct NudgesView: View {
    @ObservedObject var service: NudgesService
    @State private var expandedNudgeId: UUID?
    @State private var isPresentingAdd = false
    /// The add sheet's height. Starts medium and grows to large when the Custom day row opens.
    @State private var addDetent: PresentationDetent = .medium
    @State private var momentumPreferences: MomentumPreferences = .default

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
        .onReceive(DataChangeSignal.changes) { _ in
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
                        NudgeDueCard(
                            nudge: nudge,
                            showStreaks: momentumPreferences.showStreaks,
                            onDismiss: { await service.dismiss(nudge) }
                        )
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
        // `newNudgeRow` is the last row AND the only way to create a nudge, so with nothing below
        // it to scroll to the disc sat on it permanently — E's report, 2026-08-29.
        .captureDiscClearance()
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
                    .frame(width: 44, height: 44)
                    .background(Color.cardSurface, in: Circle())
                    .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
                    .contentShape(Circle())
            }
            .accessibilityLabel("New nudge")
            .accessibilityIdentifier("nudgeAddButton")
        }
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

    /// The add sheet, rebuilt presets-first (F-NudgePresets).
    ///
    /// What it replaced, and why — E's verdict on the device was "very ugly and awkward to use":
    /// a stock `Form` whose one section repeated the word "Add Nudge" as its header AND its
    /// submit row while the nav bar said "New nudge", so one action wore three labels; a submit
    /// button that rendered as grey placeholder text rather than anything pressable; a full-height
    /// sheet holding a third of a screen of content; and seven day toggles so narrow that every
    /// label wrapped mid-word ("S/un", "M/on", "W/ed").
    private var addSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nudge name")
                            .sectionLabel()
                        TextField("Drink water", text: $service.newLabel)
                            .font(.body)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("nudgeAddLabelField")
                    }
                    .bentoCard()

                    NudgeScheduleEditor(schedule: $service.newSchedule, idPrefix: "nudgeAdd") { showing in
                        // Grow, never shrink. At `.medium` the day row pushes the time picker
                        // below the fold — and setting a time is half the point of this sheet, so
                        // it should not need a scroll. Snapping back down on close would yank the
                        // sheet out from under the thumb for no gain, so this only ever expands.
                        if showing { addDetent = .large }
                    }
                    .bentoCard()

                    if let createErrorMessage = service.createErrorMessage {
                        Text(createErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("nudgeAddErrorMessage")
                    }
                }
                .padding(16)
            }
            .background(Color.pageBackground)
            .navigationTitle("New nudge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresentingAdd = false }
                }
                // The confirming action belongs in the nav bar, where iOS puts it — not buried at
                // the bottom of the form as a row that reads like disabled placeholder text.
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await service.createNudge() {
                                Haptics.play(.solid)
                                isPresentingAdd = false
                            } else {
                                Haptics.play(.error)
                            }
                        }
                    }
                    .font(.body.weight(.semibold))
                    .disabled(!service.isNewLabelValid || service.isCreating)
                    .accessibilityIdentifier("nudgeAddSubmitButton")
                }
            }
        }
        // The content is short with the day row closed, so a full-height sheet left two thirds of
        // the screen empty. It is NOT short with the row open — see the callback above.
        .presentationDetents([.medium, .large], selection: $addDetent)
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
                    .foregroundStyle(Color("StateRisk"))
                    .accessibilityIdentifier("nudgeEditErrorMessage-\(nudge.id)")
            }

            HStack {
                Button("Cancel") { onToggleExpanded() }
                Button("Save") {
                    Haptics.play(.solid)
                    Task { await onSave(label, schedule) }
                }
                .accessibilityIdentifier("nudgeEditSaveButton-\(nudge.id)")
            }
        }
    }
}
