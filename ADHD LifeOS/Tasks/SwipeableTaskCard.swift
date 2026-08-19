//
//  SwipeableTaskCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// SwiftUI port of the web prototype's `src/components/SwipeableTaskCard.tsx`: a horizontally
/// draggable task card over a revealed action layer — drag right past the threshold to toggle
/// complete/reopen, drag left to delete — plus the checkbox, life-area badge, colour-coded
/// priority chip, and due-date/details row.
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex: the web coral/ink/cream palette becomes adaptive semantic colour (`.tint`,
///   `.green`, `Color(.secondarySystemBackground)`, `.primary`/`.secondary`), so dark mode is free.
/// - The priority chip is **display-only**, not click-to-cycle: the web cycles low/medium/high,
///   but this app's model is `p1`–`p4` with different semantics — cycling it here would invent a
///   mapping. Tapping the card opens Details, where priority is edited properly.
/// - "Start Focus" is not a standalone button: focus scheduling lives in `TaskDetailView`, so the
///   card's tap-to-inspect leads there rather than duplicating the flow.
/// - Real-time = optimistic write-through: `onToggle`/`onDelete` flip local state immediately and
///   persist via `TasksService` → Firestore, reverting on a failed write. Not a snapshot listener
///   (the app is pull-based), but every swipe is immediately reflected and persisted.
struct SwipeableTaskCard: View {
    let task: TaskItem
    let lifeArea: LifeArea?
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onInspect: () -> Void

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompleted: Bool { task.status == .done }
    private var action: SwipeAction { SwipeAction.resolved(forTranslation: dragOffset) }

    var body: some View {
        ZStack {
            revealLayer
            foregroundCard
                .offset(x: dragOffset)
                .gesture(dragGesture)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("swipeableTaskCard-\(task.id.uuidString)")
        .accessibilityActions {
            Button(isCompleted ? "Reopen task" : "Complete task", action: onToggle)
            Button("Delete task", action: onDelete)
            Button("Open details", action: onInspect)
        }
    }

    // MARK: - Reveal layer (web: absolute action layer behind the card)

    private var revealLayer: some View {
        HStack {
            revealBadge(
                systemImage: isCompleted ? "arrow.uturn.backward" : "checkmark",
                text: isCompleted ? "Reopen" : "Complete",
                visible: action == .complete
            )
            Spacer()
            revealBadge(systemImage: "trash", text: "Delete", visible: action == .delete)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(revealColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var revealColor: Color {
        switch action {
        case .complete: return .green
        case .delete: return .red
        case .none: return Color(.tertiarySystemFill)
        }
    }

    private func revealBadge(systemImage: String, text: String, visible: Bool) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.monospaced().weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .opacity(visible ? 1 : 0)
    }

    // MARK: - Foreground card

    private var foregroundCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? Color.green : Color.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("taskCheckbox-\(task.id.uuidString)")

            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if let lifeArea {
                        Label(lifeArea.name, systemImage: "circle.fill")
                            .labelStyle(LifeAreaBadgeStyle(emoji: lifeArea.colour))
                    }
                    PriorityChip(priority: task.priority)
                }

                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Details", action: onInspect)
                .font(.caption.monospaced().weight(.bold))
                .textCase(.uppercase)
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .frame(minHeight: 44)
                .accessibilityIdentifier("taskDetails-\(task.id.uuidString)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .opacity(isCompleted ? 0.7 : 1)
        .contentShape(Rectangle())
    }

    // MARK: - Drag

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Horizontal only — vertical intent belongs to the enclosing scroll view. Elastic
                // resistance past the threshold, mirroring the web's dragElastic: 0.7.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragOffset = SwipeAction.rubberBanded(value.translation.width)
            }
            .onEnded { value in
                let resolved = SwipeAction.resolved(forTranslation: value.translation.width)
                dragOffset = 0
                switch resolved {
                case .complete: onToggle()
                case .delete: onDelete()
                case .none: break
                }
            }
    }
}

/// The outcome a horizontal drag resolves to. Pure and threshold-driven, split out so the swipe
/// logic is unit-testable without a gesture host — the web card's `handleDragEnd` threshold (75px)
/// lives here.
enum SwipeAction: Equatable {
    case none
    case complete
    case delete

    static let threshold: CGFloat = 75
    static let elasticLimit: CGFloat = 140

    static func resolved(forTranslation translation: CGFloat) -> SwipeAction {
        if translation > threshold { return .complete }
        if translation < -threshold { return .delete }
        return .none
    }

    /// Elastic resistance so the card can be dragged past the threshold but not run off-screen —
    /// full 1:1 tracking up to the threshold, then a damped tail toward `elasticLimit`.
    static func rubberBanded(_ translation: CGFloat) -> CGFloat {
        guard abs(translation) > threshold else { return translation }
        let sign: CGFloat = translation > 0 ? 1 : -1
        let overshoot = abs(translation) - threshold
        let damped = threshold + overshoot * 0.4
        return sign * min(damped, elasticLimit)
    }
}

/// Colour-coded priority chip (display-only). Maps the app's `p1`–`p4` to a warm→cool ramp:
/// p1 highest urgency (red) through p4 lowest (green).
private struct PriorityChip: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.rawValue.uppercased())
            .font(.caption2.monospaced().weight(.bold))
            .foregroundStyle(tint)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(tint.opacity(0.15), in: Capsule())
            .accessibilityLabel("Priority \(priority.rawValue)")
    }

    private var tint: Color {
        switch priority {
        case .p1: return .red
        case .p2: return .orange
        case .p3: return .yellow
        case .p4: return .green
        }
    }
}

/// Life-area badge: the area's emoji (stored in `colour`) plus its name in a pill, matching the
/// web's dot+emoji+name badge.
private struct LifeAreaBadgeStyle: LabelStyle {
    let emoji: String

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
            configuration.title
                .lineLimit(1)
        }
        .font(.caption2.monospaced())
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemFill), in: Capsule())
    }
}

#Preview("Light") {
    ScrollView {
        VStack(spacing: 16) {
            SwipeableTaskCard(
                task: TaskItem(id: UUID(), lifeAreaId: UUID(), title: "Take a 10-minute walk",
                               status: .open, priority: .p1,
                               dueDate: Date().addingTimeInterval(86_400)),
                lifeArea: LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0),
                onToggle: {}, onDelete: {}, onInspect: {}
            )
            SwipeableTaskCard(
                task: TaskItem(id: UUID(), lifeAreaId: nil, title: "Archive last month's receipts",
                               status: .done, priority: .p4, dueDate: nil),
                lifeArea: nil, onToggle: {}, onDelete: {}, onInspect: {}
            )
        }
        .padding(16)
    }
}

#Preview("Dark") {
    SwipeableTaskCard(
        task: TaskItem(id: UUID(), lifeAreaId: UUID(), title: "Draft the quarterly review",
                       status: .open, priority: .p2, dueDate: Date()),
        lifeArea: LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1),
        onToggle: {}, onDelete: {}, onInspect: {}
    )
    .padding(16)
    .preferredColorScheme(.dark)
}
