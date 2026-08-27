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
/// `TaskDetailView.swift` for its file budget. Composer parity (E's F-V3-Tasks-rebuild
/// follow-up): EVERY tag the user has renders as a chip, exactly like the create sheet — the
/// attached ones highlighted in accent, a tap toggling membership in place — plus a tap-to-add
/// affordance for brand-new names. Tag edits still apply immediately; the chips reacting in
/// place says so without a footer spelling it out.
struct TaskDetailTagsSection: View {
    let allTags: [Tag]
    let attachedTagIds: Set<UUID>
    @Binding var newTagName: String
    let onToggle: (Tag) async -> Void
    let onAdd: (String) async -> Void

    @State private var isAdding = false
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        Section {
            // Same one-row scrolling chips pattern as `TaskDetailChipsRow` above — the composer's
            // `FlowingChips` flow `Layout` missizes inside a Form row (one stretched chip with its
            // text clipped away, seen on device), so the tags deliberately don't use it here.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags) { tag in
                        tagChip(tag)
                    }
                    addChip
                }
            }
            .listRowSeparator(.hidden)

            if isAdding {
                HStack(spacing: 8) {
                    TextField("New tag", text: $newTagName)
                        .textInputAutocapitalization(.never)
                        .focused($addFieldFocused)
                        .onSubmit { submitNewTag() }
                        .accessibilityIdentifier("taskDetailNewTagField")
                    Button("Add") { submitNewTag() }
                        .font(.subheadline.weight(.semibold))
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("taskDetailAddTagButton")
                }
            }
        } header: {
            Text("Tags")
        }
    }

    /// The create sheet's chip voice: attached = accent, not attached = quiet. One tap toggles.
    private func tagChip(_ tag: Tag) -> some View {
        let attached = attachedTagIds.contains(tag.id)
        return Button {
            Haptics.play(.light)
            Task { await onToggle(tag) }
        } label: {
            Text(tag.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(attached ? AreaPalette.work.onColor : Color("LabelSecondary"))
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background(
                    attached
                        ? AnyShapeStyle(Color.accentColor)
                        : AnyShapeStyle(Color("CardSurfaceSecondary")),
                    in: Capsule()
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(attached ? .isSelected : [])
        .accessibilityLabel(attached ? "Remove tag \(tag.name)" : "Add tag \(tag.name)")
        .accessibilityIdentifier("taskDetailTagChip-\(tag.id)")
    }

    private var addChip: some View {
        Button {
            Haptics.play(.light)
            isAdding = true
            addFieldFocused = true
        } label: {
            Label("Add tag", systemImage: "plus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
                .frame(minHeight: 36)
                .background(Color("CardSurfaceSecondary"), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("taskDetailAddTagChip")
    }

    private func submitNewTag() {
        let name = newTagName
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            await onAdd(name)
            newTagName = ""
        }
    }
}
