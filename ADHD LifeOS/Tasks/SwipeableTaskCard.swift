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
/// - Colour comes from the 2026-08-19 token layer (`Theme.swift`): the prototype's exact palette
///   as ADAPTIVE named assets (`bentoCard` surface/border, `UrgencyPalette` bands, coral accent),
///   hex confined to the asset catalog — so parity and dark mode both hold.
/// - The priority chip is **display-only**, not click-to-cycle: the web cycles low/medium/high,
///   but this app's model is `p1`–`p4` with different semantics — cycling it here would invent a
///   mapping. Tapping the card opens Details, where priority is edited properly.
/// - The "Start Focus" button IS ported (as "Focus") now that `FocusTimerBar` exists to receive
///   it; it was omitted in the card's first pass purely because there was no destination yet.
/// - Real-time = optimistic write-through: `onToggle`/`onDelete` flip local state immediately and
///   persist via `TasksService` → Firestore, reverting on a failed write. Not a snapshot listener
///   (the app is pull-based), but every swipe is immediately reflected and persisted.
struct SwipeableTaskCard: View {
    let task: TaskItem
    let lifeArea: LifeArea?
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onInspect: () -> Void
    /// Starts a focus sprint for this task. Defaulted so existing call sites and previews that
    /// predate `FocusTimerBar` keep compiling.
    var onStartFocus: () -> Void = {}

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompleted: Bool { task.status == .done }
    private var action: SwipeAction { SwipeAction.resolved(forTranslation: dragOffset) }

    private var resolvedSprint: (durationSeconds: Int, nudgeCount: Int) {
        let duration = FocusSprintConfiguration.resolvedDuration(explicit: task.focusDurationSeconds)
        return (duration, FocusSprintConfiguration.resolvedNudgeCount(
            explicit: task.nudgesCount, durationSeconds: duration
        ))
    }

    private var sprintAccessibilitySummary: String {
        let sprint = resolvedSprint
        let nudges = sprint.nudgeCount == 1 ? "1 nudge" : "\(sprint.nudgeCount) nudges"
        return "Focus sprint \(FocusTimeFormatting.human(seconds: sprint.durationSeconds)), \(nudges)"
    }

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
        .background(revealColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// v3's state palette: complete reveals closure-green, delete reveals risk-red — accent is
    /// motion-blue now and must never colour a destructive surface.
    private var revealColor: Color {
        switch action {
        case .complete: return Color("StateGo")
        case .delete: return Color("StateRisk")
        case .none: return Color("TrackNeutral")
        }
    }

    private func revealBadge(systemImage: String, text: String, visible: Bool) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .opacity(visible ? 1 : 0)
    }

    // MARK: - Foreground card

    private var foregroundCard: some View {
        HStack(alignment: .top, spacing: 8) {
            if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                MomentumChip(
                    text: effort,
                    background: Color("CardSurfaceSecondary"),
                    foreground: Color("LabelSecondary")
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.callout)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? Color("LabelSecondary") : Color("LabelPrimary"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(metaLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel(metaAccessibilityLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Button(action: onToggle) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCompleted ? Color("StateGo") : Color("LabelTertiary"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("taskCheckbox-\(task.id.uuidString)")

                if !isCompleted {
                    Button(action: onStartFocus) {
                        Label("Focus", systemImage: "play.fill")
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(AreaPalette.work.onColor)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.accentColor, in: Capsule())
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("taskStartFocus-\(task.id.uuidString)")
                }
            }
        }
        .bentoCard()
        .opacity(isCompleted ? 0.6 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onInspect)
    }

    /// "💼 Work · P2 · Due today · 2🔔" — one quiet line where the old card stacked pills.
    private var metaLine: String {
        var parts: [String] = []
        if let lifeArea {
            parts.append("\(lifeArea.colour) \(lifeArea.name)")
        }
        parts.append(task.priority.rawValue.uppercased())
        if let dueDate = task.dueDate {
            let today = Calendar.current.startOfDay(for: .now)
            let dueDay = Calendar.current.startOfDay(for: dueDate)
            if dueDay < today {
                parts.append("Overdue")
            } else if dueDay == today {
                parts.append("Due today")
            } else {
                parts.append(dueDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
            }
        }
        parts.append("\(resolvedSprint.nudgeCount)🔔")
        return parts.joined(separator: " · ")
    }

    private var metaAccessibilityLabel: String {
        var parts: [String] = []
        if let lifeArea { parts.append(lifeArea.name) }
        parts.append("Priority \(task.priority.rawValue)")
        parts.append(sprintAccessibilitySummary)
        return parts.joined(separator: ", ")
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
