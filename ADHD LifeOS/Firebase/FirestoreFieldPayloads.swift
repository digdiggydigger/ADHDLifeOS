//
//  FirestoreFieldPayloads.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// The hand-written Firestore field dictionaries, extracted out of `FirebaseManager` so they are
/// pure, total, and reachable from a test.
///
/// These are the riskiest strings in the app. They are not derived from `Codable`, so no
/// encode/decode round-trip covers them — each key is a literal typed once — and **a wrong key
/// raises nothing**: the write succeeds against a field nothing reads, and the edit looks like it
/// silently failed. Extracting them from the `async` methods that write them is what makes them
/// assertable without a network or a signed-in user.
///
/// Two conventions live here side by side, and they disagree on purpose:
/// - **Tasks are fully snake_cased** — `life_area_id`, `due_date`, `completed_at`.
/// - **Captures are camelCase apart from `created_at`** — `lifeAreaId`, `mediaURL`. That is what
///   the capture Cloud Function and the iOS Shortcut write, and `Capture` decodes straight off the
///   document.
///
/// Copying either convention onto the other document type is undetectable at runtime, which is why
/// `FirestoreFieldPayloadsTests` asserts the wrong spelling is *absent* as well as the right one
/// being present.
enum FirestoreFieldPayloads {
    /// Task detail's partial update. Honours the delta convention below.
    static func taskUpdate(_ payload: TaskUpdatePayload) -> [String: Any] {
        var fields: [String: Any] = [:]
        if let title = payload.title {
            fields["title"] = title
        }
        if let priority = payload.priority {
            fields["priority"] = priority.rawValue
        }
        setNullable(payload.notes, forKey: "notes", in: &fields)
        setNullable(payload.lifeAreaId, forKey: "life_area_id", in: &fields) { $0.uuidString }
        setNullable(payload.dueDate, forKey: "due_date", in: &fields) { Timestamp(date: $0) }
        if let focusDurationSeconds = payload.focusDurationSeconds {
            fields["focus_duration_seconds"] = focusDurationSeconds
        }
        if let nudgesCount = payload.nudgesCount {
            fields["nudges_count"] = nudgesCount
        }
        return fields
    }

    /// The status flip and its completion stamp, always written together so a task can never be
    /// `done` with a stale stamp or `open` with a live one.
    ///
    /// The stamp is the **client's** clock, not `serverTimestamp()`, on purpose: "completed today"
    /// is day-granular and the day that matters is the user's local one. A server UTC stamp would
    /// file an 11pm completion under tomorrow for anyone east of UTC, and would also disagree with
    /// the optimistic value `TasksService` already put on screen.
    static func taskStatus(_ status: TaskStatus, now: Date) -> [String: Any] {
        [
            "status": status.rawValue,
            "completed_at": TaskCompletionStamp.completedAt(for: status, now: now)
                .map { Timestamp(date: $0) as Any } ?? FieldValue.delete() as Any
        ]
    }

    /// Triage's partial update. `status` and `processed` are two representations of one fact and are
    /// written together — the inbox query filters on `processed`, so a status change that left it
    /// stale would strand a triaged capture in the inbox.
    static func captureUpdate(_ changes: CaptureUpdate) -> [String: Any] {
        var fields: [String: Any] = [:]
        if let status = changes.status {
            fields["status"] = status.rawValue
            fields["processed"] = status == .processed
        }
        if let title = changes.title {
            fields["title"] = title
        }
        setNullable(changes.lifeAreaId, forKey: "lifeAreaId", in: &fields) { $0.uuidString }
        if let seen = changes.seen {
            fields["seen"] = seen
        }
        return fields
    }

    /// A nudge's partial update. Any real change stamps `updated_at` — from the **server** clock,
    /// unlike `nudgeFired` below. An empty payload writes nothing at all, so a no-op edit does not
    /// bump the timestamp.
    static func nudgeUpdate(_ payload: NudgeUpdatePayload) -> [String: Any] {
        var fields: [String: Any] = [:]
        if let label = payload.label {
            fields["label"] = label
        }
        if let schedule = payload.schedule {
            fields["schedule"] = schedule.encode()
        }
        if let active = payload.active {
            fields["active"] = active
        }
        if !fields.isEmpty {
            fields["updated_at"] = FieldValue.serverTimestamp()
        }
        return fields
    }

    /// A nudge firing. Both stamps are the same **client** instant so "last fired" and "last
    /// updated" cannot disagree by a network round trip — deliberately different from
    /// `nudgeUpdate`, which defers to the server clock because it is describing an edit rather
    /// than pinning the moment something happened.
    static func nudgeFired(now: Date) -> [String: Any] {
        let stamp = Timestamp(date: now)
        return ["last_fired_at": stamp, "updated_at": stamp]
    }

    /// The delta convention shared by `TaskUpdatePayload`/`CaptureUpdate`: outer `nil` = field
    /// untouched (no write), `.some(nil)` = explicitly cleared, which Firestore expresses as
    /// `FieldValue.delete()`.
    private static func setNullable<Wrapped>(
        _ change: Wrapped??,
        forKey key: String,
        in fields: inout [String: Any],
        map transform: (Wrapped) -> Any = { $0 as Any }
    ) {
        guard let change else { return }
        fields[key] = change.map(transform) ?? FieldValue.delete() as Any
    }
}
