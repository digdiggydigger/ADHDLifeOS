//
//  ActiveGoalHeroCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// Home's "Active Goal" hero, ported from the web prototype's bento Card 1 (`HomeView.tsx`
/// `#active-goal-card`): the headline open task with its life area, urgency chip, sprint config,
/// a prominent START SESSION action, and a Manage jump into the task's life area.
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex: the web's fixed dark card + `#FF5B5B` coral becomes an adaptive
///   `secondarySystemBackground` card with `.tint` accents and a §5 soft diffusion shadow.
/// - No fabricated placeholder task: the web invents a demo goal when no tasks exist; here the
///   caller hides the card instead (an ADHD-focused screen should never present fake work).
/// - The web's decorative overall-completion progress bar is dropped: it showed *global* task
///   completion inside a card about ONE task — misleading data, cognitive noise (§ intro).
/// - "Manage Tasks" pushes the task's life-area detail via the existing
///   `navigationDestination(for: LifeArea.self)` route, the native equivalent of the web's
///   `onSelectLifeArea` tab jump. Hidden when the task has no resolvable active area.
struct ActiveGoalHeroCard: View {
    let task: TaskSummary
    /// The task's resolved life area — supplies the header name, Manage destination, and the
    /// sprint's emoji. `nil` for unassigned/archived-area tasks.
    let lifeArea: LifeArea?
    let onStartSession: () -> Void

    private var sprint: (durationSeconds: Int, nudgeCount: Int) {
        let duration = FocusSprintConfiguration.resolvedDuration(explicit: task.focusDurationSeconds)
        return (duration, FocusSprintConfiguration.resolvedNudgeCount(
            explicit: task.nudgesCount, durationSeconds: duration
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            titleAndNotes
            sprintTargetRow
            actionsRow
        }
        .bentoCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeActiveGoalCard")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(lifeArea.map { "Active Goal • \($0.name)" } ?? "Active Goal")
                .sectionLabel()
                .foregroundStyle(.tint)
            Spacer(minLength: 8)
            Text(task.priority.rawValue.uppercased())
                .font(.caption2.monospaced().weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.tertiarySystemFill), in: Capsule())
                .accessibilityLabel("Priority \(task.priority.rawValue)")
        }
    }

    @ViewBuilder
    private var titleAndNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.title3.weight(.semibold))
                .tracking(-0.5)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var sprintTargetRow: some View {
        HStack(spacing: 8) {
            Text("Task Focus Target")
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Label(
                "\(FocusTimeFormatting.human(seconds: sprint.durationSeconds)) sprint · \(sprint.nudgeCount)🔔",
                systemImage: "timer"
            )
            .foregroundStyle(.tint)
            .accessibilityLabel(
                "Focus target \(FocusTimeFormatting.human(seconds: sprint.durationSeconds)), "
                + "\(sprint.nudgeCount == 1 ? "1 nudge" : "\(sprint.nudgeCount) nudges")"
            )
        }
        .font(.caption.monospaced())
    }

    private var actionsRow: some View {
        HStack(spacing: 8) {
            Button(action: onStartSession) {
                Label("Start Session", systemImage: "play.fill")
                    .font(.footnote.monospaced().weight(.bold))
                    .textCase(.uppercase)
                    .frame(minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("homeStartSessionButton")

            if let lifeArea {
                NavigationLink(value: lifeArea) {
                    Text("Manage")
                        .font(.footnote.monospaced().weight(.bold))
                        .textCase(.uppercase)
                        .frame(minHeight: 32)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("homeManageActiveTaskButton")
            }
        }
    }
}

#if DEBUG
#Preview("Hero — Light") {
    NavigationStack {
        ScrollView {
            ActiveGoalHeroCard(
                task: TaskSummary(
                    lifeAreaId: UUID(), status: .open,
                    title: "Break down Q3 project proposal into 15-min micro-steps",
                    priority: .p1, notes: "Primary executive objectives first to avoid fatigue.",
                    focusDurationSeconds: 900, nudgesCount: 2
                ),
                lifeArea: LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0),
                onStartSession: {}
            )
            .padding(16)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Hero — Dark, unassigned") {
    NavigationStack {
        ActiveGoalHeroCard(
            task: TaskSummary(lifeAreaId: nil, status: .open, title: "Water the plants", priority: .p4),
            lifeArea: nil,
            onStartSession: {}
        )
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
#endif
