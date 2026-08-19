//
//  ReminderModels.swift
//  ADHD LifeOS
//

import Foundation

/// One of `reminder|calendar|timer|alarm` per the live `poke-ios-bridge` validation, plus
/// `.unknown` for any value not yet recognised — the backing DynamoDB table (`PokeTasks`) is
/// freeform, so a future Poke-side addition must never break decoding.
enum ReminderType: String, Equatable, Sendable {
    case reminder, calendar, timer, alarm, unknown
}

extension ReminderType: Decodable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ReminderType(rawValue: raw) ?? .unknown
    }
}

/// `low|medium|high` per Poke's own priority vocabulary — deliberately **not** the app's
/// `TaskPriority` (`p1`-`p4`); the two are unrelated concepts and must never be coerced onto
/// each other. `.unknown` covers any value not yet recognised, same tolerance as `ReminderType`.
enum ReminderPriority: String, Equatable, Sendable {
    case low, medium, high, unknown
}

extension ReminderPriority: Decodable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ReminderPriority(rawValue: raw) ?? .unknown
    }
}

/// A single item from `GET /task`. Only `task_id`, `created`, and `type` are guaranteed present
/// server-side — every other field is optional and must decode leniently, since `PokeTasks` is a
/// freeform table (`{task_id, created, **body}`) written by Poke, not a fixed app schema.
struct Reminder: Identifiable, Equatable, Sendable {
    let id: String
    let type: ReminderType
    let title: String?
    let notes: String?
    let priority: ReminderPriority?
    let source: String?
    let notification: Bool?
    let createdAt: Date?
    let datetime: Date?

    init(
        id: String,
        type: ReminderType,
        title: String? = nil,
        notes: String? = nil,
        priority: ReminderPriority? = nil,
        source: String? = nil,
        notification: Bool? = nil,
        createdAt: Date? = nil,
        datetime: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.notes = notes
        self.priority = priority
        self.source = source
        self.notification = notification
        self.createdAt = createdAt
        self.datetime = datetime
    }
}

extension Reminder: Decodable {
    private enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case created, type, title, notes, priority, source, notification, datetime
    }

    /// `created` and `datetime` decode as plain strings first, then convert via
    /// `ReminderDateParsing` — both formats lack a timezone offset, so a single
    /// `ISO8601DateFormatter` can't handle either. A value that fails to parse becomes `nil`
    /// rather than throwing, so one bad date never discards the rest of the item or response.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .taskId)
        let type = try container.decode(ReminderType.self, forKey: .type)
        let title = try container.decodeIfPresent(String.self, forKey: .title)
        let notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let priority = try container.decodeIfPresent(ReminderPriority.self, forKey: .priority)
        let source = try container.decodeIfPresent(String.self, forKey: .source)
        let notification = try container.decodeIfPresent(Bool.self, forKey: .notification)
        let createdRaw = try container.decode(String.self, forKey: .created)
        let datetimeRaw = try container.decodeIfPresent(String.self, forKey: .datetime)

        self.init(
            id: id,
            type: type,
            title: title,
            notes: notes,
            priority: priority,
            source: source,
            notification: notification,
            createdAt: ReminderDateParsing.parseCreated(createdRaw),
            datetime: datetimeRaw.flatMap(ReminderDateParsing.parseDatetime)
        )
    }
}

/// The `{count, tasks}` envelope returned by `GET /task`.
struct RemindersResponseEnvelope: Decodable {
    let count: Int
    let tasks: [Reminder]
}

/// Parses `poke-ios-bridge`'s two timestamp fields, which use different formats and neither
/// carries a timezone offset. Both parse (and later render) pinned to UTC — for `created` that's
/// correct because it genuinely is UTC; for `datetime` this is a deliberate choice to treat it as
/// a naive wall-clock value and never shift it, avoiding the BST/UTC off-by-one-hour bug class
/// already documented in `ARCHITECTURE.md` (web's `isNudgeDue` fires an hour late during BST).
/// All members are `nonisolated`: these pure helpers are called from synchronous nonisolated
/// contexts (`Reminder.init(from:)` decoding off the main actor), so under the module's
/// default-MainActor isolation they must opt out explicitly. Plain `nonisolated` is sufficient
/// for the formatter constants too — `DateFormatter` is `Sendable` (and thread-safe for
/// formatting/parsing) in current SDKs, and these are never mutated after init.
enum ReminderDateParsing {
    nonisolated static func parseCreated(_ string: String) -> Date? {
        createdFormatter.date(from: string)
    }

    nonisolated static func parseDatetime(_ string: String) -> Date? {
        datetimeFormatter.date(from: string)
    }

    /// Renders a parsed date back to display text with no device-timezone shift — the formatter
    /// is pinned to UTC, the same zone used to parse, so the digits shown always match the
    /// original string's wall-clock hour exactly.
    nonisolated static func displayString(for date: Date) -> String {
        displayFormatter.string(from: date)
    }

    nonisolated private static func makeFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = dateFormat
        return formatter
    }

    nonisolated private static let createdFormatter =
        makeFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
    nonisolated private static let datetimeFormatter =
        makeFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss")
    nonisolated private static let displayFormatter =
        makeFormatter(dateFormat: "MMM d, yyyy 'at' h:mm a")
}
