//
//  TaskCountdownNudgeControl.swift
//  ADHD LifeOS
//

import SwiftUI

/// Reusable "Nudge me on this reminder" toggle + menu, shared by Task Create (where scheduling is
/// deferred until creation succeeds, since there's no task id yet) and Task Detail (where a fresh
/// selection is applied immediately). Enabled only when `dueDate` is set, per the FEATURE block's
/// acceptance criteria — disabled (and forced to `.none`) otherwise.
struct TaskCountdownNudgeControl: View {
    let dueDate: Date?
    @Binding var selection: NudgeCountdownSelection

    private var isOn: Binding<Bool> {
        Binding(
            get: { selection != .none },
            set: { newValue in selection = newValue ? defaultSelection : .none }
        )
    }

    private var defaultSelection: NudgeCountdownSelection {
        guard let dueDate else { return .none }
        switch TaskCountdownNudgeScheduling.mode(now: Date(), dueDate: dueDate) {
        case .evenDivision:
            return .evenDivision(count: 1)
        case .checkpoint:
            let applicable = TaskCountdownNudgeScheduling.applicableCheckpoints(now: Date(), dueDate: dueDate)
            guard let nearest = applicable.last else { return .none }
            return .checkpoints([nearest])
        }
    }

    var body: some View {
        Section("Nudges") {
            Toggle("Nudge me on this reminder", isOn: isOn)
                .disabled(dueDate == nil)
                .accessibilityIdentifier("taskCountdownNudgeToggle")

            if dueDate != nil, selection != .none {
                menu
            }
        }
    }

    @ViewBuilder
    private var menu: some View {
        if let dueDate {
            switch TaskCountdownNudgeScheduling.mode(now: Date(), dueDate: dueDate) {
            case .evenDivision:
                evenDivisionMenu(dueDate: dueDate)
            case .checkpoint:
                checkpointMenu(dueDate: dueDate)
            }
        }
    }

    private func evenDivisionMenu(dueDate: Date) -> some View {
        let options = TaskCountdownNudgeScheduling.evenDivisionMenuOptions(now: Date(), dueDate: dueDate)
        return Group {
            if options.isEmpty {
                Text("This task is due too soon to schedule nudges.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Nudges", selection: evenDivisionCountBinding) {
                    ForEach(options) { option in
                        Text(option.intervalDescription).tag(option.count)
                    }
                }
                .accessibilityIdentifier("taskCountdownNudgeEvenDivisionPicker")
            }
        }
    }

    private var evenDivisionCountBinding: Binding<Int> {
        Binding(
            get: {
                if case .evenDivision(let count) = selection { return count }
                return 1
            },
            set: { selection = .evenDivision(count: $0) }
        )
    }

    private func checkpointMenu(dueDate: Date) -> some View {
        let applicable = TaskCountdownNudgeScheduling.applicableCheckpoints(now: Date(), dueDate: dueDate)
        return Group {
            if applicable.isEmpty {
                Text("No checkpoints apply before this task's due time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(applicable, id: \.self) { checkpoint in
                    checkpointRow(checkpoint)
                }
            }
        }
    }

    private func checkpointRow(_ checkpoint: NudgeCheckpoint) -> some View {
        Button {
            toggleCheckpoint(checkpoint)
        } label: {
            HStack {
                Text(checkpoint.label)
                Spacer()
                if selectedCheckpoints.contains(checkpoint) {
                    Image(systemName: "checkmark")
                }
            }
        }
        .accessibilityIdentifier("taskCountdownNudgeCheckpoint-\(checkpoint)")
    }

    private var selectedCheckpoints: Set<NudgeCheckpoint> {
        if case .checkpoints(let set) = selection { return set }
        return []
    }

    private func toggleCheckpoint(_ checkpoint: NudgeCheckpoint) {
        var set = selectedCheckpoints
        if set.contains(checkpoint) {
            set.remove(checkpoint)
        } else {
            set.insert(checkpoint)
        }
        selection = set.isEmpty ? .none : .checkpoints(set)
    }
}

#if DEBUG
private struct PreviewContainer: View {
    @State private var selection: NudgeCountdownSelection = .none

    var body: some View {
        Form {
            TaskCountdownNudgeControl(dueDate: Date().addingTimeInterval(3 * 24 * 3600), selection: $selection)
        }
    }
}

#Preview {
    PreviewContainer()
}
#endif
