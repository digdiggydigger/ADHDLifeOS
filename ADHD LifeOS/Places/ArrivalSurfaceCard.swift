//
//  ArrivalSurfaceCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// The Home arrival card (block 4c, variation B): pinned above the scoreboard when the app opens
/// at a named place with open At-Place tasks. Every row is a door into its task — where Start
/// lives — rather than a separate launch button that could only guess which task you meant.
struct ArrivalSurfaceCard: View {
    let surface: ArrivalSurface
    let onOpenTask: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("📍 \(surface.headline)")
                    .sectionLabel()
                    .foregroundStyle(Color.accentColor)
                Spacer(minLength: 8)
                Text(surface.countLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(surface.tasks) { task in
                row(task)
            }
        }
        .bentoCard()
        .accessibilityIdentifier("homeArrivalCard")
    }

    private func row(_ task: TaskItem) -> some View {
        Button {
            Haptics.play(.light)
            onOpenTask(task)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(Color("LabelPrimary"))
                    .lineLimit(2)
                Spacer(minLength: 8)
                MomentumChip(
                    text: task.priority.rawValue.uppercased(),
                    background: Color("CardSurfaceSecondary"),
                    foreground: task.priority == .p1 ? Color("StateWarn") : Color("LabelSecondary")
                )
                Image(systemName: "chevron.forward")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this task")
        .accessibilityIdentifier("homeArrivalTaskRow-\(task.id)")
    }
}

#if DEBUG
#Preview("Light") {
    ArrivalSurfaceCard(
        surface: ArrivalSurface(
            place: Place(
                id: UUID(), name: "Tesco",
                coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
                radiusMetres: 150, emoji: "🛒"
            ),
            tasks: [
                TaskItem(
                    id: UUID(), lifeAreaId: nil, title: "Buy AA batteries",
                    status: .open, priority: .p1, dueDate: nil
                ),
                TaskItem(
                    id: UUID(), lifeAreaId: nil, title: "Return the parcel",
                    status: .open, priority: .p3, dueDate: nil
                )
            ]
        ),
        onOpenTask: { _ in }
    )
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ArrivalSurfaceCard(
        surface: ArrivalSurface(
            place: Place(
                id: UUID(), name: "The Office",
                coordinate: PlaceCoordinate(latitude: 51.5203, longitude: -0.0986),
                radiusMetres: 200, emoji: "💼"
            ),
            tasks: [
                TaskItem(
                    id: UUID(), lifeAreaId: nil, title: "Hand Sam the signed form",
                    status: .open, priority: .p2, dueDate: nil
                )
            ]
        ),
        onOpenTask: { _ in }
    )
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}
#endif
