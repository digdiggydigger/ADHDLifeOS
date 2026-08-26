//
//  TaskRow.swift
//  ADHD LifeOS
//

import SwiftUI

/// The v3 Tasks page's dense row (F-V3-Tasks-rebuild, Option A of the b11 proposal): effort chip,
/// title over the one-line `TaskRowPresentation` meta, and a 44pt tap-circle that closes the task.
/// Due-today rows add a small ▶ that launches a focus sprint (E's b11 call: sprint-starting is a
/// today thing — other buckets stay quiet). The whole row opens the detail screen.
///
/// What the old `SwipeableTaskCard` had that this deliberately does not:
/// - No reopen: a closed row's check is display-only (E's addendum — closing is one-way).
/// - No swipe-left delete: delete lives on the detail screen now. Swipe-RIGHT-to-close survives
///   as a bonus gesture on open rows, resolved by the pure `TaskRowSwipe` below.
struct TaskRow: View {
    let task: TaskItem
    let lifeArea: LifeArea?
    /// True only for the Momentum board's Due-today bucket.
    let showsSprintStart: Bool
    let onClose: () -> Void
    let onInspect: () -> Void
    var onStartFocus: () -> Void = {}

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isClosed: Bool { task.status == .done }

    var body: some View {
        ZStack {
            revealLayer
            rowContent
                .offset(x: dragOffset)
                .gesture(isClosed ? nil : dragGesture)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("taskRow-\(task.id.uuidString)")
        .accessibilityActions {
            if !isClosed {
                Button("Close task", action: onClose)
                if showsSprintStart {
                    Button("Start focus sprint", action: onStartFocus)
                }
            }
            Button("Open details", action: onInspect)
        }
    }

    // MARK: - Row

    private var rowContent: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                    MomentumChip(
                        text: effort,
                        background: Color("CardSurfaceSecondary"),
                        foreground: Color("LabelSecondary")
                    )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.callout)
                        .strikethrough(isClosed)
                        .foregroundStyle(isClosed ? Color("LabelSecondary") : Color("LabelPrimary"))
                        .lineLimit(2)
                    Text(TaskRowPresentation.metaLine(task: task, lifeArea: lifeArea))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel(TaskRowPresentation.accessibilityLabel(task: task, lifeArea: lifeArea))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onInspect)

            if showsSprintStart && !isClosed {
                Button(action: onStartFocus) {
                    Image(systemName: "play.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start focus sprint")
                .accessibilityIdentifier("taskStartFocus-\(task.id.uuidString)")
            }

            if isClosed {
                // Display-only: closed is closed (no reopen path anywhere in the app).
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color("StateGo"))
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            } else {
                Button(action: onClose) {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(Color("LabelTertiary"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close task")
                .accessibilityIdentifier("taskCheckbox-\(task.id.uuidString)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .background(Color.cardSurface)
        .opacity(isClosed ? 0.6 : 1)
    }

    // MARK: - Swipe-right-to-close (bonus gesture)

    private var revealLayer: some View {
        HStack {
            Label("Close", systemImage: "checkmark")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .opacity(TaskRowSwipe.closes(forTranslation: dragOffset) ? 1 : 0)
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dragOffset > 0 ? Color("StateGo") : Color.cardSurface)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Horizontal only — vertical intent belongs to the enclosing scroll view.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragOffset = TaskRowSwipe.rubberBanded(value.translation.width)
            }
            .onEnded { value in
                let closes = TaskRowSwipe.closes(forTranslation: value.translation.width)
                dragOffset = 0
                if closes { onClose() }
            }
    }
}

/// The bonus gesture's outcome, pure and threshold-driven so it is unit-testable without a
/// gesture host. Right-only: there is no left action any more (delete moved to the detail
/// screen), so leftward drags don't move the row at all.
enum TaskRowSwipe {
    static let threshold: CGFloat = 75
    static let elasticLimit: CGFloat = 140

    static func closes(forTranslation translation: CGFloat) -> Bool {
        translation > threshold
    }

    /// 1:1 tracking up to the threshold, then a damped tail toward `elasticLimit`; leftward
    /// translations pin to zero.
    static func rubberBanded(_ translation: CGFloat) -> CGFloat {
        guard translation > 0 else { return 0 }
        guard translation > threshold else { return translation }
        let damped = threshold + (translation - threshold) * 0.4
        return min(damped, elasticLimit)
    }
}

#if DEBUG
#Preview("Light") {
    VStack(spacing: 0) {
        TaskRow(
            task: TaskItem(
                id: UUID(), lifeAreaId: UUID(), title: "Break down Q3 proposal into micro-steps",
                status: .open, priority: .p1, dueDate: .now, focusDurationSeconds: 1500
            ),
            lifeArea: LifeArea(id: UUID(), name: "Work & Career", colour: "💼", sortOrder: 0),
            showsSprintStart: true,
            onClose: {}, onInspect: {}
        )
        Divider().padding(.leading, 16)
        TaskRow(
            task: TaskItem(
                id: UUID(), lifeAreaId: UUID(), title: "Drink 500ml water & stretch",
                status: .done, priority: .p3, dueDate: nil, focusDurationSeconds: 600,
                completedAt: .now
            ),
            lifeArea: LifeArea(id: UUID(), name: "Health", colour: "🏋️", sortOrder: 1),
            showsSprintStart: false,
            onClose: {}, onInspect: {}
        )
    }
    .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(16)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskRow(
        task: TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Clean audio equipment & organize cables",
            status: .open, priority: .p3, dueDate: Date().addingTimeInterval(86_400)
        ),
        lifeArea: LifeArea(id: UUID(), name: "Hobbies", colour: "🎨", sortOrder: 2),
        showsSprintStart: false,
        onClose: {}, onInspect: {}
    )
    .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(16)
    .preferredColorScheme(.dark)
}
#endif
