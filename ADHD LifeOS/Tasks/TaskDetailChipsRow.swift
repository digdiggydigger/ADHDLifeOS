//
//  TaskDetailChipsRow.swift
//  ADHD LifeOS
//

import SwiftUI

/// v3's S3 header chips — the task's identity at a glance: area in its tint, priority (warn when
/// P1), due date (warn when today), effort in solid motion-blue. Value-fed so it renders the
/// STAGED edits, not the stored task.
struct TaskDetailChipsRow: View {
    let area: LifeArea?
    let priority: TaskPriority
    let dueDate: Date?
    let effortMinutes: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let area {
                    let family = AreaPalette.family(for: area)
                    MomentumChip(
                        text: "\(area.colour) \(area.name)",
                        background: family.tint,
                        foreground: family.color
                    )
                }
                MomentumChip(
                    text: priority.rawValue.uppercased(),
                    background: Color("CardSurfaceSecondary"),
                    foreground: priority == .p1 ? Color("StateWarn") : Color("LabelSecondary")
                )
                if let dueDate {
                    let isToday = Calendar.current.isDateInToday(dueDate)
                    MomentumChip(
                        text: isToday
                            ? "due today"
                            : dueDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)),
                        background: Color("CardSurfaceSecondary"),
                        foreground: isToday ? Color("StateWarn") : Color("LabelSecondary")
                    )
                }
                MomentumChip(
                    text: "\(effortMinutes) min",
                    background: Color.accentColor,
                    foreground: AreaPalette.work.onColor
                )
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    TaskDetailChipsRow(
        area: LifeArea(id: UUID(), name: "Work & Career", colour: "💼", sortOrder: 0),
        priority: .p1,
        dueDate: .now,
        effortMinutes: 25
    )
    .padding(16)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskDetailChipsRow(
        area: LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0),
        priority: .p3,
        dueDate: nil,
        effortMinutes: 15
    )
    .padding(16)
    .preferredColorScheme(.dark)
}
#endif

/// The tags editor as a standalone Form section — value/callback-fed, split from
/// `TaskDetailView.swift` for its file budget. Behaviour unchanged: tag edits apply immediately.
struct TaskDetailTagsSection: View {
    let tags: [Tag]
    @Binding var newTagName: String
    let onAdd: (String) async -> Void
    let onRemove: (Tag) async -> Void

    var body: some View {
        Section {
            ForEach(tags) { tag in
                HStack {
                    Text(tag.name)
                    Spacer()
                    Button("Remove") {
                        Task { await onRemove(tag) }
                    }
                }
            }

            HStack {
                TextField("New tag", text: $newTagName)
                    .accessibilityIdentifier("taskDetailNewTagField")
                Button("Add") {
                    Task {
                        await onAdd(newTagName)
                        newTagName = ""
                    }
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("taskDetailAddTagButton")
            }
        } header: {
            Text("Tags")
        } footer: {
            Text("Adding or removing a tag applies immediately — no Save needed.")
        }
    }
}
