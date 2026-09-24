//
//  TaskComposerControls.swift
//  ADHD LifeOS
//
//  The task composer's controls, shared by its two layouts (`F-D2-ComposerKeyboardLayout`): the
//  four "when" segments, the Area and Time menus, and Add. The keyboard bar lays them out in two
//  rows above the keyboard (round 7b's L3); at accessibility sizes the stacked form puts them
//  under the title (L1's, carried in the option E chose). Their geometry is round 7b's probe,
//  which is what E approved by looking at board `64`.
//

import SwiftUI

/// Round 7b's "when" control: four equal segments in one container. The Date segment is E's
/// *"Text, then the date"*. It reads "Date" like its neighbours, with no glyph, and once a day is
/// picked it becomes the selection and shows that day ("Fri 26").
///
/// **The selection recolours in place.** There is no sliding indicator, so nothing here moves and
/// the block adds no Reduce Motion site (§7.2). `ComposerKeyboardBarCallSiteTests` pins that.
struct TaskWhenSegments: View {
    @ObservedObject var service: TaskCreateService
    @Binding var dueChoice: TaskDueChoice
    @State private var isPickingDate = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: TaskComposerMetrics.controlCornerRadius, style: .continuous)
        // Four across while the words fit, one above the next at accessibility sizes, where
        // "Tomorrow" would otherwise shrink past legibility (the board's AX3 column).
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: TaskComposerMetrics.segmentInset))
            : AnyLayout(HStackLayout(spacing: TaskComposerMetrics.segmentInset))
        layout {
            ForEach([TaskDueChoice.notYet, .today, .tomorrow], id: \.self) { choice in
                segment(choice) { choose(choice) }
            }
            segment(.custom) { isPickingDate = true }
                .popover(isPresented: $isPickingDate) { datePicker }
        }
        .padding(TaskComposerMetrics.segmentInset)
        .background(Color.cardSurface, in: shape)
        .overlay(shape.strokeBorder(Color.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func segment(_ choice: TaskDueChoice, action: @escaping () -> Void) -> some View {
        let selected = dueChoice == choice
        return Button(action: action) {
            Text(choice.segmentTitle(selected: dueChoice, dueDate: service.dueDate, asOf: .now))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: TaskComposerMetrics.segmentHeight)
                .contentShape(
                    RoundedRectangle(cornerRadius: TaskComposerMetrics.segmentCornerRadius, style: .continuous)
                )
        }
        .buttonStyle(WhenSegmentButtonStyle(isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("taskCreateDue-\(choice.title)")
    }

    private func choose(_ choice: TaskDueChoice) {
        Haptics.play(.selection)
        dueChoice = choice
        service.dueDate = choice.resolvedDueDate(existing: service.dueDate, asOf: .now)
    }

    /// **A day, not a moment**: E's Step 0 answer, 2026-09-24. A precise time is set on the task's
    /// detail screen (`TaskDetailFormSections`). A pick is stored as that day's start and read back
    /// through `choice(for:)`, so picking today's or tomorrow's day lights THAT segment: one date,
    /// one segment. It closes itself on the pick, because a day is one tap and the segment then
    /// shows it.
    private var datePicker: some View {
        DatePicker(
            "Due",
            selection: Binding(
                get: { TaskDueChoice.custom.resolvedDueDate(existing: service.dueDate, asOf: .now) ?? .now },
                set: { picked in
                    Haptics.play(.selection)
                    let day = TaskDueChoice.pickedDueDate(picked)
                    service.dueDate = day
                    dueChoice = TaskDueChoice.choice(for: day, asOf: .now)
                    isPickingDate = false
                }
            ),
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
        .padding(8)
        // Round 7b and Q4: "a popover or menu, never a sheet". On iPhone a popover adapts to a sheet
        // unless told otherwise. This API is below the 18 floor, so every OS the app runs on gets it.
        .presentationCompactAdaptation(.popover)
        .accessibilityIdentifier("taskCreateDueDatePicker")
    }
}

/// Round 6's area pop-up: the shared `LifeAreaPicker`, drawn as round 7b's tile. Round 10b's empty
/// choice reads "None".
struct TaskComposerAreaMenu: View {
    @ObservedObject var service: TaskCreateService
    var compact: Bool

    var body: some View {
        LifeAreaPicker(
            title: "Area",
            noSelectionLabel: "None",
            lifeAreas: service.offeredLifeAreas,
            selection: $service.lifeAreaId,
            accessibilityID: "taskCreateLifeAreaPicker",
            tileGlyph: "square.grid.2x2",
            tileIsCompact: compact
        )
    }
}

/// Round 6's time pop-up: the fan's three effort choices. 15 min is the default and is always
/// written (`F-D1`, every board E approved).
struct TaskComposerTimeMenu: View {
    @ObservedObject var service: TaskCreateService
    var compact: Bool

    var body: some View {
        Menu {
            ForEach(TaskEffortChoice.allCases, id: \.seconds) { choice in
                Button {
                    service.effort = choice
                } label: {
                    if service.effort == choice {
                        Label(choice.title, systemImage: "checkmark")
                    } else {
                        Text(choice.title)
                    }
                }
            }
        } label: {
            ComposerMenuTile(glyph: "timer", caption: "Time", value: service.effort.title, compact: compact)
        }
        .accessibilityIdentifier("taskCreateTimeMenu")
    }
}

/// Add. It trails the keyboard bar (`toolbars.md › Actions`: "put it on the trailing side"), and
/// is full width and pinned in the stacked form. It is 48pt: round 7's floor for "anything that
/// starts, closes, adds".
struct TaskComposerAddButton: View {
    @ObservedObject var service: TaskCreateService
    var compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(compact ? "Add" : "Add task")
            } icon: {
                if service.isSubmitting {
                    ProgressView()
                } else {
                    Image(systemName: "plus")
                }
            }
        }
        .buttonStyle(ComposerAddButtonStyle(compact: compact))
        .disabled(!service.isTitleValid || service.isSubmitting)
        // "Add task" contains the visible "Add", so Voice Control still finds it by what it shows.
        .accessibilityLabel(service.isSubmitting ? "Adding task" : "Add task")
        .accessibilityIdentifier("taskCreateSubmitButton")
    }
}

/// Selected is the accent with white text. Unselected is clear on the container, in LabelPrimary
/// like every neighbour, which is round 7b's fix for an accent that meant both "selected" and
/// "opens a picker" (`color.md › Best practices`). The press scale is §3's.
private struct WhenSegmentButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: TaskComposerMetrics.segmentCornerRadius, style: .continuous)
        configuration.label
            .foregroundStyle(isSelected ? Color.white : Color("LabelPrimary"))
            .background(isSelected ? Color.accentColor : Color.clear, in: shape)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// `PrimaryActionButtonStyle`'s states (the accent enabled; a quiet keylined surface disabled) in
/// the composer's 16pt shape, at a width that can trail a row.
private struct ComposerAddButtonStyle: ButtonStyle {
    let compact: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: TaskComposerMetrics.controlCornerRadius, style: .continuous)
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .foregroundStyle(isEnabled ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.secondary))
            .padding(.horizontal, 16)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: TaskComposerMetrics.addHeight)
            .background(isEnabled ? Color.accentColor : Color("CardSurfaceSecondary"), in: shape)
            .overlay {
                if !isEnabled {
                    shape.strokeBorder(Color.cardBorder, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

#if DEBUG
private struct TaskComposerControlsPreview: View {
    @StateObject private var service = TaskCreateService.preview()
    @State private var choice: TaskDueChoice = .notYet

    var body: some View {
        VStack(spacing: 16) {
            TaskWhenSegments(service: service, dueChoice: $choice)
            TaskComposerAreaMenu(service: service, compact: false)
            TaskComposerTimeMenu(service: service, compact: false)
            TaskComposerAddButton(service: service, compact: false) {}
        }
        .padding(16)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    TaskComposerControlsPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskComposerControlsPreview()
        .preferredColorScheme(.dark)
}
#endif
