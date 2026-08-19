//
//  FirebaseManager.swift
//  ADHD LifeOS
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

/// The signed-in Firebase user. Firebase UIDs are opaque strings, not UUIDs, so this cannot
/// reuse `AuthUser` (whose `id` is a `UUID`) — migrating `AuthState`/`AuthService` onto this
/// type is a separate step of the Firebase cutover.
struct FirebaseAuthUser: Equatable, Sendable {
    let uid: String
    let email: String?
}

enum FirebaseManagerError: LocalizedError {
    /// Thrown by every Firestore method when no user is signed in — all app data lives in
    /// per-user subcollections, so there is no meaningful unauthenticated read or write.
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to sync data."
        }
    }
}

/// Firebase Auth + Firestore replacement for the Supabase (`Supabase*ClientAdapter`) and AWS
/// (`AWS*ClientAdapter`) networking layers. Reuses the existing domain models and their wire
/// keys unchanged, so the Firestore field names match the snake_case Supabase columns the
/// models' `CodingKeys` were built for.
///
/// Schema — everything is a per-user subcollection under `users/{uid}`, with each document ID
/// being the model's `UUID` string:
/// - `users/{uid}` — profile doc (`email`, `created_at`), written on sign-up.
/// - `users/{uid}/tasks` — `TaskDetail` documents; `TaskItem` is the list projection of the
///   same document (its fields are a strict subset, so both decode from one doc).
/// - `users/{uid}/life_areas` — `LifeArea`. Encoding `LifeArea` here is safe and intended:
///   TRAP 4 in `HomeModels.swift` forbids encoding only against the camelCase AWS backend;
///   snake_case IS this schema.
/// - `users/{uid}/logs` — `Log`, append-only (create/read only), preserving the Supabase
///   RLS design of no update/delete path.
/// - `users/{uid}/captures` — `Capture` (keeps its mixed-case keys as-is).
/// - `users/{uid}/tags` — `Tag`.
/// - `users/{uid}/nudges` — `Nudge`; `schedule` stays the `MIN HOUR * * DOW` cron string.
final class FirebaseManager {
    static let shared = FirebaseManager()

    private let auth: Auth
    private let firestore: Firestore

    private init() {
        // Firestore/Auth trap at first touch if the app never configured Firebase; guarding here
        // keeps the manager usable regardless of launch order once GoogleService-Info.plist exists.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        auth = Auth.auth()
        firestore = Firestore.firestore()
    }

    // MARK: - Auth

    var currentUser: FirebaseAuthUser? {
        auth.currentUser.map { FirebaseAuthUser(uid: $0.uid, email: $0.email) }
    }

    /// Creates the account and its `users/{uid}` profile document in one call. The profile write
    /// uses `merge: true` so a retried sign-up (e.g. after a network drop mid-call) never
    /// clobbers an existing document.
    @discardableResult
    func signUp(email: String, password: String) async throws -> FirebaseAuthUser {
        let result = try await auth.createUser(withEmail: email, password: password)
        try await firestore.collection("users").document(result.user.uid).setData(
            [
                "email": result.user.email ?? email,
                "created_at": FieldValue.serverTimestamp()
            ],
            merge: true
        )
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> FirebaseAuthUser {
        let result = try await auth.signIn(withEmail: email, password: password)
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Firestore plumbing

    private enum Collection: String {
        case tasks
        case lifeAreas = "life_areas"
        case logs
        case captures
        case tags
        case nudges
    }

    private func collection(_ name: Collection) throws -> CollectionReference {
        guard let uid = auth.currentUser?.uid else { throw FirebaseManagerError.notSignedIn }
        return firestore.collection("users").document(uid).collection(name.rawValue)
    }

    private func fetchAll<Model: Decodable>(
        _ type: Model.Type,
        from name: Collection,
        orderedBy field: String? = nil,
        descending: Bool = false
    ) async throws -> [Model] {
        var query: Query = try collection(name)
        if let field {
            query = query.order(by: field, descending: descending)
        }
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { try $0.data(as: Model.self) }
    }

    private func save<Model: Encodable>(_ value: Model, id: UUID, in name: Collection) async throws {
        let data = try Firestore.Encoder().encode(value)
        try await collection(name).document(id.uuidString).setData(data)
    }

    private func delete(id: UUID, from name: Collection) async throws {
        try await collection(name).document(id.uuidString).delete()
    }

    private func update(id: UUID, fields: [String: Any], in name: Collection) async throws {
        guard !fields.isEmpty else { return }
        try await collection(name).document(id.uuidString).updateData(fields)
    }

    /// Encodes the delta convention shared by `TaskUpdatePayload`/`NudgeUpdatePayload`: outer
    /// `nil` = field untouched (no write), `.some(nil)` = explicitly cleared, which Firestore
    /// expresses as `FieldValue.delete()`.
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

// MARK: - Tasks

extension FirebaseManager {
    func fetchTasks() async throws -> [TaskItem] {
        try await fetchAll(TaskItem.self, from: .tasks, orderedBy: "created_at", descending: true)
    }

    func fetchTaskDetail(id: UUID) async throws -> TaskDetail {
        try await collection(.tasks).document(id.uuidString).getDocument(as: TaskDetail.self)
    }

    func createTask(_ task: TaskDetail) async throws {
        try await save(task, id: task.id, in: .tasks)
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws {
        var fields: [String: Any] = [:]
        if let title = payload.title {
            fields["title"] = title
        }
        if let priority = payload.priority {
            fields["priority"] = priority.rawValue
        }
        Self.setNullable(payload.notes, forKey: "notes", in: &fields)
        Self.setNullable(payload.lifeAreaId, forKey: "life_area_id", in: &fields) { $0.uuidString }
        Self.setNullable(payload.dueDate, forKey: "due_date", in: &fields) { Timestamp(date: $0) }
        try await update(id: id, fields: fields, in: .tasks)
    }

    func setTaskStatus(id: UUID, status: TaskStatus) async throws {
        try await update(id: id, fields: ["status": status.rawValue], in: .tasks)
    }

    func deleteTask(id: UUID) async throws {
        try await delete(id: id, from: .tasks)
    }
}

// MARK: - Life areas

extension FirebaseManager {
    func fetchLifeAreas(includeArchived: Bool = false) async throws -> [LifeArea] {
        let areas = try await fetchAll(LifeArea.self, from: .lifeAreas, orderedBy: "sort_order")
        return includeArchived ? areas : areas.filter { !$0.archived }
    }

    /// Creates or fully overwrites one area — covers rename, recolour, and archive/unarchive.
    func saveLifeArea(_ area: LifeArea) async throws {
        try await save(area, id: area.id, in: .lifeAreas)
    }

    /// Persists a Home-screen reorder as one atomic batch: each area's `sort_order` becomes its
    /// index in `orderedIds`.
    func reorderLifeAreas(orderedIds: [UUID]) async throws {
        let batch = firestore.batch()
        let areas = try collection(.lifeAreas)
        for (index, id) in orderedIds.enumerated() {
            batch.updateData(["sort_order": index], forDocument: areas.document(id.uuidString))
        }
        try await batch.commit()
    }

    func deleteLifeArea(id: UUID) async throws {
        try await delete(id: id, from: .lifeAreas)
    }
}

// MARK: - Logs (append-only)

extension FirebaseManager {
    /// Newest entry first, matching the Journal feed sort.
    func fetchLogs() async throws -> [Log] {
        try await fetchAll(Log.self, from: .logs, orderedBy: "entry_date", descending: true)
    }

    /// The only write for logs — no update or delete exists on purpose (see `LogModels.swift`).
    func appendLog(_ log: Log) async throws {
        try await save(log, id: log.id, in: .logs)
    }
}

// MARK: - Captures

extension FirebaseManager {
    func fetchCaptures() async throws -> [Capture] {
        try await fetchAll(Capture.self, from: .captures, orderedBy: "created_at", descending: true)
    }

    /// Creates or fully overwrites one capture — covers content edits, triage (`status`/
    /// `processed`), and life-area assignment.
    func saveCapture(_ capture: Capture) async throws {
        try await save(capture, id: capture.id, in: .captures)
    }

    func deleteCapture(id: UUID) async throws {
        try await delete(id: id, from: .captures)
    }
}

// MARK: - Tags

extension FirebaseManager {
    func fetchTags() async throws -> [Tag] {
        try await fetchAll(Tag.self, from: .tags, orderedBy: "name")
    }

    func saveTag(_ tag: Tag) async throws {
        try await save(tag, id: tag.id, in: .tags)
    }

    func deleteTag(id: UUID) async throws {
        try await delete(id: id, from: .tags)
    }
}

// MARK: - Nudges

extension FirebaseManager {
    func fetchNudges() async throws -> [Nudge] {
        try await fetchAll(Nudge.self, from: .nudges, orderedBy: "created_at")
    }

    func createNudge(_ nudge: Nudge) async throws {
        try await save(nudge, id: nudge.id, in: .nudges)
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws {
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
        try await update(id: id, fields: fields, in: .nudges)
    }

    func deleteNudge(id: UUID) async throws {
        try await delete(id: id, from: .nudges)
    }
}
