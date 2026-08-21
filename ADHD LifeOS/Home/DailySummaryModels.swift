//
//  DailySummaryModels.swift
//  ADHD LifeOS
//

import Foundation

/// The four voices the web original offered, and the one thing on this screen the user actually
/// steers. Raw values travel to the backend and become part of the prompt it builds, so they are
/// a wire contract — renaming a case silently changes the summary's voice.
enum DailySummaryTone: String, Codable, CaseIterable, Identifiable, Sendable {
    case energizing
    case gentle
    case coaching
    case bulleted

    var id: String { rawValue }

    var label: String {
        switch self {
        case .energizing: return "Energizing"
        case .gentle: return "Gentle"
        case .coaching: return "Coaching"
        case .bulleted: return "Bulleted"
        }
    }

    /// Paired with `label` everywhere it appears — never a glyph alone (§4).
    var systemImage: String {
        switch self {
        case .energizing: return "bolt.fill"
        case .gentle: return "leaf.fill"
        case .coaching: return "figure.run"
        case .bulleted: return "list.bullet"
        }
    }
}

/// What a generated summary actually contains — the exact five fields the web's
/// `/api/gemini/daily-summary` returned, kept identical so the Cloud Function replacing it has a
/// contract to hit and the view has one shape to render.
struct DailySummaryContent: Codable, Equatable, Sendable {
    let headline: String
    let dopamineWins: [String]
    let journalReflections: String
    let focusStaminaInsight: String
    let gentleTomorrowKickstart: [String]
}

/// A summary plus the circumstances that produced it, so the card can say where it came from and
/// when — a stale summary presented as fresh is worse than none.
struct GeneratedDailySummary: Equatable, Sendable {
    let content: DailySummaryContent
    let tone: DailySummaryTone
    let generatedAt: Date
    let source: DailySummarySource
}

enum DailySummarySource: String, Equatable, Sendable {
    /// Produced by the Claude-backed Cloud Function.
    case model
    /// Synthesized on-device from real counts — honest, offline, and never claimed to be more.
    case localSynthesis

    var label: String {
        switch self {
        case .model: return "Claude"
        case .localSynthesis: return "On-device synthesis"
        }
    }
}

// MARK: - Request

/// Everything the generator needs about today, derived once from the app's own models.
///
/// The derivation lives in the initialiser rather than the caller so "what counts as today" is
/// decided in exactly one place: completed tasks come through `TaskCompletionStamp` (stamped, and
/// stamped *today*), focus minutes count only sprints that **ended** today, and journal entries
/// are journal-type logs dated today.
struct DailySummaryRequest: Encodable, Equatable, Sendable {
    struct CompletedTask: Encodable, Equatable, Sendable {
        let title: String
        let lifeAreaName: String
        let priority: String
        let focusMinutesLogged: Int
    }

    struct InProgressTask: Encodable, Equatable, Sendable {
        let title: String
        let lifeAreaName: String
    }

    struct JournalEntry: Encodable, Equatable, Sendable {
        let body: String
        let lifeAreaName: String
        let energyLevel: String?
        let moodEmoji: String?
    }

    let date: Date
    let tone: DailySummaryTone
    let focusMinutesTotal: Int
    let capturesCount: Int
    let completedTasks: [CompletedTask]
    let inProgressTasks: [InProgressTask]
    let journalEntries: [JournalEntry]

    /// The web sent at most five in-progress tasks; more is noise in the prompt and cost on the
    /// wire, and the model only needs a sense of what is still open.
    private static let inProgressLimit = 5

    /// What an unassigned task or entry is called in the prompt. Matches the web's `getAreaName`.
    static let unassignedLifeAreaName = "General"

    init(
        date: Date,
        tone: DailySummaryTone,
        tasks: [TaskItem],
        focusSessions: [CompletedFocusSession],
        journalEntries: [Log],
        capturesCount: Int,
        lifeAreaNames: [UUID: String],
        calendar: Calendar = .current
    ) {
        self.date = date
        self.tone = tone
        self.capturesCount = capturesCount

        func areaName(_ id: UUID?) -> String {
            guard let id, let name = lifeAreaNames[id] else { return Self.unassignedLifeAreaName }
            return name
        }

        self.completedTasks = TaskCompletionStamp
            .completedTasks(in: tasks, on: date, calendar: calendar)
            .map { task in
                CompletedTask(
                    title: task.title,
                    lifeAreaName: areaName(task.lifeAreaId),
                    priority: task.priority.rawValue,
                    focusMinutesLogged: (task.focusDurationSeconds ?? 0) / 60
                )
            }

        self.inProgressTasks = tasks
            .filter { $0.status == .open }
            .prefix(Self.inProgressLimit)
            .map { InProgressTask(title: $0.title, lifeAreaName: areaName($0.lifeAreaId)) }

        // Floored to whole minutes on the total, not per sprint: three 40-second sprints are one
        // minute of focus, not zero.
        let secondsToday = focusSessions
            .filter { calendar.isDate($0.endedAt, inSameDayAs: date) }
            .reduce(0) { $0 + $1.focusedSeconds }
        self.focusMinutesTotal = secondsToday / 60

        self.journalEntries = journalEntries
            .filter { $0.type == .journal && calendar.isDate($0.entryDate, inSameDayAs: date) }
            .map { log in
                JournalEntry(
                    body: log.body,
                    lifeAreaName: areaName(log.lifeAreaId),
                    energyLevel: log.energyLevel?.rawValue,
                    moodEmoji: log.moodEmoji
                )
            }
    }

    /// Whether there is anything worth summarising. An empty day gets an honest empty-state rather
    /// than a model round-trip that can only invent things.
    var hasSomethingToSummarise: Bool {
        !completedTasks.isEmpty || !journalEntries.isEmpty
            || focusMinutesTotal > 0 || capturesCount > 0
    }
}

// MARK: - Generation seam

/// The seam between the view and whatever produces a summary. `StubDailySummaryGenerator` stands
/// here until the Claude-backed Cloud Function ships; the view never learns which it got beyond
/// the `source` label it is told to display.
protocol DailySummaryGenerating: Sendable {
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent
    var source: DailySummarySource { get }
}

/// On-device synthesis from the real numbers — the same honesty principle as the existing
/// `DailySummaryHeadline`: it only ever restates what actually happened, in the selected voice.
/// It invents nothing, so an empty day yields no wins rather than a fabricated one.
struct StubDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .localSynthesis }

    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        DailySummaryContent(
            headline: headline(for: request),
            dopamineWins: request.completedTasks.map { win($0, tone: request.tone) },
            journalReflections: reflections(for: request),
            focusStaminaInsight: focusInsight(for: request),
            gentleTomorrowKickstart: kickstart(for: request)
        )
    }

    private func headline(for request: DailySummaryRequest) -> String {
        let wins = request.completedTasks.count
        switch request.tone {
        case .energizing:
            return wins > 0
                ? "\(wins) finished today — that momentum is real."
                : "Nothing finished yet, and the day is still yours."
        case .gentle:
            return wins > 0
                ? "You closed \(wins) today. That was enough."
                : "A quiet day so far, and that is allowed."
        case .coaching:
            return wins > 0
                ? "\(wins) done. Name the next one and you keep the streak."
                : "No completions yet — pick the smallest open loop and start there."
        case .bulleted:
            return wins > 0
                ? "Today: \(wins) completed, \(request.focusMinutesTotal)m focused."
                : "Today: nothing completed yet, \(request.focusMinutesTotal)m focused."
        }
    }

    private func win(_ task: DailySummaryRequest.CompletedTask, tone: DailySummaryTone) -> String {
        switch tone {
        case .bulleted: return "\(task.title) (\(task.lifeAreaName))"
        case .gentle: return "You finished \(task.title)."
        case .coaching: return "\(task.title) — done, in \(task.lifeAreaName)."
        case .energizing: return "Shipped: \(task.title)."
        }
    }

    private func reflections(for request: DailySummaryRequest) -> String {
        guard !request.journalEntries.isEmpty else {
            return "No journal entries today — nothing to reflect back yet."
        }
        let moods = request.journalEntries.compactMap(\.energyLevel)
        let count = request.journalEntries.count
        let noun = count == 1 ? "1 entry" : "\(count) entries"
        guard let dominant = moods.first else {
            return "\(noun) written today."
        }
        return "\(noun) written today, energy running \(dominant)."
    }

    private func focusInsight(for request: DailySummaryRequest) -> String {
        let minutes = request.focusMinutesTotal
        guard minutes > 0 else {
            return "No focus sprints logged today — even five minutes would count."
        }
        return "\(minutes) minute\(minutes == 1 ? "" : "s") of focused work today."
    }

    private func kickstart(for request: DailySummaryRequest) -> [String] {
        var steps: [String] = []
        if let next = request.inProgressTasks.first {
            steps.append("Start with \(next.title) — smallest possible first move.")
        }
        if request.capturesCount > 0 {
            let noun = request.capturesCount == 1 ? "1 capture" : "\(request.capturesCount) captures"
            steps.append("Triage \(noun) waiting in the inbox.")
        }
        if steps.isEmpty {
            steps.append("Add one small task tonight so tomorrow starts with a target.")
        }
        return steps
    }
}

// MARK: - Clipboard

/// The share format, mirroring the web's `handleCopySummary`. Sections with nothing in them are
/// dropped entirely rather than left as a header with empty space under it.
enum DailySummaryCopyFormatter {
    static func text(for content: DailySummaryContent, on date: Date) -> String {
        let day = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        var lines = ["✨ ADHD LifeOS Daily Summary (\(day))", content.headline]

        if !content.dopamineWins.isEmpty {
            lines.append("\n🏆 Dopamine Wins:")
            lines.append(contentsOf: content.dopamineWins.map { "• \($0)" })
        }
        lines.append("\n💭 Reflections:")
        lines.append(content.journalReflections)
        lines.append("\n⚡ Focus & Stamina:")
        lines.append(content.focusStaminaInsight)
        if !content.gentleTomorrowKickstart.isEmpty {
            lines.append("\n🚀 Tomorrow's Kickstart:")
            lines.append(contentsOf: content.gentleTomorrowKickstart.map { "• \($0)" })
        }
        return lines.joined(separator: "\n")
    }
}
