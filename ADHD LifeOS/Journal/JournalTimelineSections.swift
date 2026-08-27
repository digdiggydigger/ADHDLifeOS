//
//  JournalTimelineSections.swift
//  ADHD LifeOS
//
//  The v3 Journal's day stream and its rows, split from `JournalView.swift` for its length
//  budget once the rows became doors (the `CaptureInboxSections` arrangement). The stream reads
//  newest→oldest top to bottom — days and the entries inside them both — per E's 2026-08-25
//  ordering call.
//

import SwiftUI

extension JournalView {

    func timeline(logs: [Log]) -> some View {
        let days = JournalTimeline.days(
            logs: logs, tasks: filteredTasks,
            sprints: filteredSprints, captures: filteredCaptures,
            locationEvents: journalService.locationEvents, places: journalService.places,
            filter: filter
        )
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                chips
                if days.isEmpty {
                    Text("Nothing here yet — one line about today is enough to start.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                        .accessibilityIdentifier("journalEmptyState")
                }
                ForEach(days) { day in
                    daySection(day)
                }
            }
            .padding(16)
        }
        .refreshable {
            await reload()
        }
    }

    private func daySection(_ day: JournalTimeline.Day) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.headerLine)
                .sectionLabel()
                .foregroundStyle(.secondary)
            ForEach(day.entries) { entry in
                switch entry {
                case .log(let log):
                    logRow(log)
                case .closedTask(let task):
                    closedTaskRow(task)
                case .focusSprint(let sprint):
                    sprintRow(sprint)
                case .capture(let capture):
                    captureRow(capture)
                case .locationEvent(let event):
                    locationEventRow(event)
                }
            }
        }
    }

    /// A fence crossing (block 4c) — deliberately the lightest row here: no card, no door, just
    /// the arrow, the words and the time. Ambience the eye can skip, exactly as designed.
    private func locationEventRow(_ event: LocationEvent) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            timeGutter(event.occurredAt)
            Image(systemName: event.kind == .arrival ? "arrow.forward" : "arrow.backward")
                .font(.footnote.bold())
                .foregroundStyle(Color.accentColor)
            Text(JournalTimeline.locationEventLine(for: event, places: journalService.places) ?? "")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 32)
        .accessibilityElement(children: .combine)
    }

    private func logRow(_ log: Log) -> some View {
        HStack(alignment: .top, spacing: 8) {
            timeGutter(log.entryDate)
                .padding(.top, 16)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(logKindLine(log))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let mood = log.moodEmoji {
                        Text(mood)
                            .font(.footnote)
                    }
                    if let energy = log.energyLevel {
                        MomentumChip(
                            text: energy.rawValue,
                            background: Color("CardSurfaceSecondary"),
                            foreground: Color("LabelSecondary")
                        )
                    }
                }
                Text(log.body)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                let tags = JournalTimeline.tags(for: log, from: journalService.availableTags)
                if !tags.isEmpty {
                    TagChipsRow(tags: tags)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .bentoCard()
        }
    }

    private func closedTaskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            timeGutter(task.completedAt ?? .now)
            Image(systemName: "checkmark")
                .font(.footnote.bold())
                .foregroundStyle(Color("StateGoVivid"))
            Text(task.title)
                .font(.footnote)
                .lineLimit(2)
            Text("task\(areaEmoji(for: task.lifeAreaId).map { " · \($0)" } ?? "")")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .modifier(JournalRowDoor(isOpen: canOpenTasks, hint: "Opens this task") {
            inspectingTaskId = task.id
        })
    }

    /// A finished sprint as a compact fact row, the closed task's sibling: the timer glyph in the
    /// motion accent, the honest minutes (`JournalTimeline.sprintLine`), and the area emoji the
    /// sprint stamped when it ran. Opens its task when the sprint had one.
    private func sprintRow(_ sprint: CompletedFocusSession) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            timeGutter(sprint.endedAt)
            Image(systemName: "timer")
                .font(.footnote.bold())
                .foregroundStyle(Color.accentColor)
            Text(sprint.taskTitle)
                .font(.footnote)
                .lineLimit(2)
            Text("\(JournalTimeline.sprintLine(for: sprint)) · \(sprint.lifeAreaEmoji)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .modifier(
            JournalRowDoor(
                isOpen: canOpenTasks && sprint.taskId != nil,
                hint: "Opens the task this sprint ran on"
            ) {
                inspectingTaskId = sprint.taskId
            }
        )
    }

    /// The capture log's row: the kind's own glyph and tint (the inbox's visual language), the
    /// same primary-text resolution as the inbox row, and a plain "captured" for the meta slot.
    private func captureRow(_ capture: Capture) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            timeGutter(capture.createdAt)
            Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                .font(.footnote.bold())
                .foregroundStyle(CaptureKindAccent.color(for: capture.kind))
            Text(CaptureRowPresentation.primaryText(for: capture))
                .font(.footnote)
                .lineLimit(2)
            Text("captured\(areaEmoji(for: capture.lifeAreaId).map { " · \($0)" } ?? "")")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .modifier(JournalRowDoor(isOpen: canOpenCaptures, hint: "Opens this capture") {
            inspectingCapture = capture
        })
    }

    /// One line, always — 52pt fit "1:01 AM" but wrapped "12:19 AM" into "12:19 a / m"
    /// (E's screenshot, 2026-08-25), so four-digit times get the width they need and scale
    /// before they ever break.
    private func timeGutter(_ date: Date) -> some View {
        Text(date.formatted(date: .omitted, time: .shortened))
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(width: 56, alignment: .leading)
    }

    private func logKindLine(_ log: Log) -> String {
        let kind = log.type == .journal ? "Journal" : "Log"
        guard
            let areaId = log.lifeAreaId,
            let area = journalService.lifeAreas.first(where: { $0.id == areaId }), !area.archived
        else { return kind }
        return "\(kind) · \(area.colour) \(area.name)"
    }

    private func areaEmoji(for areaId: UUID?) -> String? {
        guard let areaId else { return nil }
        return journalService.lifeAreas.first { $0.id == areaId }?.colour
    }
}

/// Row-level tappability that only exists when the door can actually open: an un-openable row
/// (preview, missing client) keeps plain-text semantics instead of a button that goes nowhere.
private struct JournalRowDoor: ViewModifier {
    let isOpen: Bool
    let hint: String
    let action: () -> Void

    func body(content: Content) -> some View {
        if isOpen {
            content
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(hint)
        } else {
            content
        }
    }
}

/// Owns the `CaptureInboxService` for one pushed capture detail, so the service survives the
/// push's re-renders (`navigationDestination` rebuilds its content; a `@StateObject` here keeps
/// one instance for the door's lifetime — the same reason `CapturesTabView` owns its service).
struct JournalCaptureDoor: View {
    let captureId: UUID
    let lifeAreas: [LifeArea]
    @StateObject private var service: CaptureInboxService

    init(
        captureId: UUID,
        lifeAreas: [LifeArea],
        client: CaptureClientAdapting,
        journalClient: JournalClientAdapting?
    ) {
        self.captureId = captureId
        self.lifeAreas = lifeAreas
        _service = StateObject(
            wrappedValue: CaptureInboxService(client: client, journalClient: journalClient)
        )
    }

    var body: some View {
        CaptureDetailView(captureId: captureId, lifeAreas: lifeAreas, service: service)
    }
}
