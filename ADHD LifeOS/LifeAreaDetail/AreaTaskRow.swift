//
//  AreaTaskRow.swift
//  ADHD LifeOS
//

import SwiftUI

/// One task row: effort chip (the next open task's chip carries the identity tint), title with
/// the done strike, the meta line, and the 44pt tick that closes or reopens in place.
struct AreaTaskRow: View {
    let task: TaskItem
    let family: AreaPalette
    let isNextOpen: Bool
    let isToggling: Bool
    let onTick: () -> Void

    private var isDone: Bool { task.status == .done }

    var body: some View {
        HStack(spacing: 8) {
            NavigationLink(value: task) {
                HStack(spacing: 8) {
                    if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                        MomentumChip(
                            text: effort,
                            background: isNextOpen ? family.tint : Color("CardSurfaceSecondary"),
                            foreground: isNextOpen ? family.color : Color("LabelSecondary")
                        )
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.callout)
                            .strikethrough(isDone)
                            .foregroundStyle(isDone ? Color("LabelSecondary") : Color("LabelPrimary"))
                            .lineLimit(2)
                        Text(metaLine)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: onTick) {
                if isToggling {
                    ProgressView()
                } else {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isDone ? Color("StateGo") : Color("LabelTertiary"))
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(isDone ? "Reopen \(task.title)" : "Close \(task.title)")
            .accessibilityIdentifier("lifeAreaDetailTick-\(task.id)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .opacity(isDone ? 0.6 : 1)
    }

    private var metaLine: String {
        if isDone {
            if let completedAt = task.completedAt {
                return "Closed \(completedAt.formatted(date: .omitted, time: .shortened))"
            }
            return "Closed"
        }
        var parts: [String] = []
        if let due = task.dueDate {
            let today = Calendar.current.startOfDay(for: .now)
            let dueDay = Calendar.current.startOfDay(for: due)
            if dueDay < today {
                parts.append("Overdue")
            } else if dueDay == today {
                parts.append("Due today")
            } else {
                parts.append(due.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
            }
        }
        parts.append(task.priority.rawValue.uppercased())
        return parts.joined(separator: " · ")
    }
}
