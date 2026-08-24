//
//  MomentumScoreboardViews.swift
//  ADHD LifeOS
//
//  Home's Momentum scoreboard sections (Concept C, 2026-08-24): the closure ring, the streak
//  block, the best-next-move card and the areas-moving strip. Structure from the concept, colours
//  strictly from the existing token layer (E's "structure only" call) — the accent carries
//  progress, green appears only where it already meant "done" (status icon + text, never colour
//  alone, §4).
//

import SwiftUI

/// Track + progress arc + whatever belongs in the middle. The same ring draws at 112pt for the
/// day, 52pt per area and 64pt for the focus sprint (S4), so all three read as one instrument.
struct ClosureRing<Center: View>: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    /// What the arc strokes in — accent by default. The sprint ring hands in a muted style while
    /// paused, the same held-state language its old countdown pill used.
    var arcStyle = AnyShapeStyle(Color.accentColor)
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    arcStyle,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            center()
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: progress)
    }
}

/// The scoreboard header: today's closure ring beside the streak (or, with no streak alive, the
/// honest "still open" counterweight — nothing here ever counts a miss).
struct MomentumRingCard: View {
    let closedToday: Int
    let goal: Int
    let streak: Int
    let openCount: Int
    /// Trailing seven days, oldest first — the dot row.
    let weekFlags: [Bool]
    /// The shortest due task's effort ("15 min"), feeding the counterweight line.
    let nextEffortLabel: String?

    var body: some View {
        HStack(spacing: 16) {
            ClosureRing(
                progress: MomentumScoreboard.ringProgress(closed: closedToday, goal: goal),
                size: 112,
                lineWidth: 10
            ) {
                VStack(spacing: 0) {
                    Text("\(closedToday)")
                        .font(.largeTitle.bold())
                        .tracking(-1)
                        .monospacedDigit()
                    Text("of \(goal) closed")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                if streak > 0 {
                    Text("Streak")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streak)")
                            .font(.title.bold())
                            .tracking(-1)
                            .monospacedDigit()
                        Text(streak == 1 ? "day" : "days")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    dotRow
                    Text(streakLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Still open")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(openCount)")
                            .font(.title.bold())
                            .tracking(-1)
                            .monospacedDigit()
                        Text(openCount == 1 ? "item" : "items")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(nextEffortLabel.map { "One of them is \($0)." } ?? "Close one to start a streak.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .bentoCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeMomentumRing")
    }

    private var streakLine: String {
        streak == 1 ? "One day closed. Keep it alive today." : "\(streak) days closed in a row."
    }

    private var dotRow: some View {
        HStack(spacing: 4) {
            ForEach(Array(weekFlags.enumerated()), id: \.offset) { _, closed in
                Circle()
                    .fill(closed ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.tertiarySystemFill)))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }
}

/// The one task Home leads with, and the two things worth doing to it. Replaces the Active Goal
/// hero: same slot, same start-session funnel, plus the concept's close-it-from-here.
struct BestNextMoveCard: View {
    let task: TaskSummary
    let lifeArea: LifeArea?
    let isDueNow: Bool
    let isClosing: Bool
    let showsStartSession: Bool
    let onClose: () -> Void
    let onStartSession: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best next move")
                .sectionLabel()
                .foregroundStyle(Color.accentColor)
            HStack(spacing: 8) {
                if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                    Text(effort)
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
                if let lifeArea {
                    CaptureLifeAreaChip(lifeArea: lifeArea)
                }
                if isDueNow {
                    Text("due today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(task.title)
                .font(.title3.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 8) {
                Button(action: onClose) {
                    if isClosing {
                        ProgressView()
                            .tint(.secondary)
                    } else {
                        Label("Close it", systemImage: "checkmark.circle")
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(isClosing)
                .accessibilityIdentifier("homeCloseTaskButton")
                if showsStartSession {
                    Button(action: onStartSession) {
                        Label("Start session", systemImage: "play.fill")
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
                    .accessibilityIdentifier("homeStartSessionButton")
                }
            }
        }
        .bentoCard()
        .accessibilityIdentifier("homeBestNextMoveCard")
    }
}

/// The moment after a close: named win, running count, a way back. Undo matters because Close-it
/// now lives one tap from the scoreboard — reversibility is what makes that tap safe.
struct ClosureCelebrationCard: View {
    let taskTitle: String
    let closedTodayCount: Int
    let onUndo: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("\(taskTitle) — closed")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            Text(ordinalLine)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button("Undo", action: onUndo)
                    .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("homeUndoCloseButton")
                Button("Next", action: onNext)
                    .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("homeNextMoveButton")
            }
        }
        .bentoCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeClosureCelebration")
    }

    private var ordinalLine: String {
        switch closedTodayCount {
        case 1: return "First today."
        case 2: return "Second today."
        case 3: return "Third today."
        default: return "\(closedTodayCount) closed today."
        }
    }
}

/// Each active area as a mini closure ring — the concept's "totals → rates". Tapping pushes the
/// same LifeAreaDetail the old grid did.
struct AreaMomentumStrip: View {
    let items: [MomentumScoreboard.AreaMomentum]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(value: item.area) {
                        VStack(spacing: 4) {
                            ClosureRing(progress: item.rate ?? 0, size: 52, lineWidth: 5) {
                                Text(item.area.colour)
                                    .font(.title3)
                            }
                            // Named, not just emoji'd (E's 2026-08-24 review): the ring must say
                            // which life it measures without a tap.
                            Text(item.area.name)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(rateLabel(for: item))
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .frame(minWidth: 60, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: item))
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("homeAreaMomentumStrip")
    }

    private func rateLabel(for item: MomentumScoreboard.AreaMomentum) -> String {
        guard let rate = item.rate else { return "quiet" }
        return rate >= 1 ? "clear" : "\(Int((rate * 100).rounded()))%"
    }

    private func accessibilityLabel(for item: MomentumScoreboard.AreaMomentum) -> String {
        "\(item.area.name), \(item.closedThisWeek) closed this week, \(item.open) open"
    }
}

/// Today's closed items, named and timestamped — the evidence under the ring.
struct MomentumClosedTodayCard: View {
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tasks) { task in
                Label {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        if let completedAt = task.completedAt {
                            Text(completedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .bentoCard()
        .accessibilityIdentifier("homeClosedTodayCard")
    }
}

#if DEBUG
private struct MomentumScoreboardGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MomentumRingCard(
                    closedToday: 2, goal: 5, streak: 7, openCount: 3,
                    weekFlags: [true, true, true, true, true, true, false],
                    nextEffortLabel: "15 min"
                )
                BestNextMoveCard(
                    task: TaskSummary(
                        lifeAreaId: nil,
                        status: .open, title: "Sort through mail pile on kitchen counter",
                        priority: .p2, notes: "Trash junk mail immediately. Only keep bills to scan.",
                        dueDate: Date(), focusDurationSeconds: 900
                    ),
                    lifeArea: LifeArea(id: UUID(), name: "Admin", colour: "📝", sortOrder: 0),
                    isDueNow: true, isClosing: false, showsStartSession: true,
                    onClose: {}, onStartSession: {}
                )
                ClosureCelebrationCard(
                    taskTitle: "Sort through mail pile", closedTodayCount: 3, onUndo: {}, onNext: {}
                )
                AreaMomentumStrip(items: MomentumScoreboard.areaMomentum(
                    areas: [
                        LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0),
                        LifeArea(id: UUID(), name: "Health", colour: "🏋️", sortOrder: 1)
                    ],
                    openTasks: [], allTasks: []
                ))
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.dark)
}
#endif
