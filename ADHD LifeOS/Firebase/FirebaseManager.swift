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
    /// The `FirebaseApp` has no storage bucket configured — `GoogleService-Info.plist` is
    /// missing its `STORAGE_BUCKET`, so media uploads cannot be addressed.
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to sync data."
        case .storageUnavailable:
            return "Media storage isn't configured for this build."
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
        // Best-effort (`try?`): the account exists and the session is live at this point, so a
        // seeding failure (e.g. security rules not yet deployed) must not fail the sign-up —
        // seeding retries on every future sign-in until the `seeded_at` marker lands.
        try? await seedDefaultContentIfNeeded()
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> FirebaseAuthUser {
        let result = try await auth.signIn(withEmail: email, password: password)
        // Same best-effort rationale as `signUp` — and this is the path that seeds accounts
        // created in the Firebase console (there is no in-app sign-up UI).
        try? await seedDefaultContentIfNeeded()
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
    }

    /// Sign in with Apple: exchanges the Apple identity token + raw nonce for a Firebase
    /// session via `OAuthProvider`. Firebase re-hashes `rawNonce` and checks it against the
    /// digest embedded in the token, so a replayed token from another session is rejected.
    ///
    /// First authorization is also account creation (there is no separate Apple sign-up), so
    /// the new-user path mirrors `signUp`: write the `users/{uid}` profile doc and persist the
    /// display name — Apple sends the full name ONLY on that first grant, never again.
    @discardableResult
    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> FirebaseAuthUser {
        let credential = OAuthProvider.credential(providerID: .apple, idToken: idToken, rawNonce: rawNonce)
        let result = try await auth.signIn(with: credential)

        if result.additionalUserInfo?.isNewUser == true {
            // Best-effort like the seeding below: the session is live, so a profile-write
            // failure must not fail the sign-in the user just completed.
            if let displayName, !displayName.isEmpty {
                let change = result.user.createProfileChangeRequest()
                change.displayName = displayName
                try? await change.commitChanges()
            }
            var profile: [String: Any] = ["created_at": FieldValue.serverTimestamp()]
            if let email = result.user.email {
                profile["email"] = email
            }
            if let displayName, !displayName.isEmpty {
                profile["display_name"] = displayName
            }
            try? await firestore.collection("users").document(result.user.uid).setData(profile, merge: true)
        }
        // Same best-effort seeding hook as `signIn`/`signUp` — first Apple sign-in gets the
        // starter content; the `seeded_at` marker makes later calls a single cheap read.
        try? await seedDefaultContentIfNeeded()
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Firestore plumbing (internal so the per-feature `Firebase*ClientAdapter`s and the
    // manager's own extension files can build on it without re-implementing auth scoping)

    /// `CaseIterable` so account deletion can cascade over every per-user collection — a new
    /// collection added here is automatically included in the wipe.
    enum Collection: String, CaseIterable {
        case tasks
        case lifeAreas = "life_areas"
        case logs
        case captures
        case tags
        case nudges
        case reminders
        case focusSessions = "focus_sessions"
    }

    func requireUID() throws -> String {
        guard let uid = auth.currentUser?.uid else { throw FirebaseManagerError.notSignedIn }
        return uid
    }

    /// `firestore` itself is `private` (file-scoped); extension files that need multi-document
    /// atomicity get a batch through this instead of direct client access.
    func firestoreBatch() -> WriteBatch {
        firestore.batch()
    }

    /// The signed-in user's root document (`users/{uid}`) — profile fields and the
    /// `seeded_at` first-login marker live here.
    func userDocument() throws -> DocumentReference {
        firestore.collection("users").document(try requireUID())
    }

    func collection(_ name: Collection) throws -> CollectionReference {
        try userDocument().collection(name.rawValue)
    }

    func fetchAll<Model: Decodable>(
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

    /// Equality-scoped fetch. Deliberately has no `order(by:)` — combining a `whereField` with an
    /// order on a different field requires a Firestore composite index; callers sort client-side.
    func fetchWhere<Model: Decodable>(
        _ type: Model.Type,
        from name: Collection,
        field: String,
        equals value: Any
    ) async throws -> [Model] {
        let snapshot = try await collection(name).whereField(field, isEqualTo: value).getDocuments()
        return try snapshot.documents.map { try $0.data(as: Model.self) }
    }

    func save<Model: Encodable>(_ value: Model, id: UUID, in name: Collection) async throws {
        let data = try Firestore.Encoder().encode(value)
        try await collection(name).document(id.uuidString).setData(data)
    }

    func delete(id: UUID, from name: Collection) async throws {
        try await collection(name).document(id.uuidString).delete()
    }

    func update(id: UUID, fields: [String: Any], in name: Collection) async throws {
        guard !fields.isEmpty else { return }
        try await collection(name).document(id.uuidString).updateData(fields)
    }

    /// Encodes the delta convention shared by `TaskUpdatePayload`/`NudgeUpdatePayload`: outer
    /// `nil` = field untouched (no write), `.some(nil)` = explicitly cleared, which Firestore
    /// expresses as `FieldValue.delete()`.
    static func setNullable<Wrapped>(
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
        if let focusDurationSeconds = payload.focusDurationSeconds {
            fields["focus_duration_seconds"] = focusDurationSeconds
        }
        if let nudgesCount = payload.nudgesCount {
            fields["nudges_count"] = nudgesCount
        }
        try await update(id: id, fields: fields, in: .tasks)
    }

    func setTaskStatus(id: UUID, status: TaskStatus) async throws {
        try await update(id: id, fields: ["status": status.rawValue], in: .tasks)
    }

    func deleteTask(id: UUID) async throws {
        try await delete(id: id, from: .tasks)
    }

    /// Home's badge-count query: only the open tasks, projected down to `TaskSummary`.
    func fetchOpenTaskSummaries() async throws -> [TaskSummary] {
        try await fetchWhere(TaskSummary.self, from: .tasks, field: "status", equals: TaskStatus.open.rawValue)
    }

    /// Server-side scoped to one life area, per `LifeAreaDetailClientAdapting`'s contract.
    /// Unsorted (see `fetchWhere`) — `LifeAreaDetailService` orders for display.
    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        try await fetchWhere(TaskItem.self, from: .tasks, field: "life_area_id", equals: lifeAreaId.uuidString)
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

    /// Server-side scoped to one life area. Unsorted (see `fetchWhere`) — callers order for display.
    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        try await fetchWhere(Log.self, from: .logs, field: "life_area_id", equals: lifeAreaId.uuidString)
    }
}

// MARK: - Captures

extension FirebaseManager {
    func fetchCaptures() async throws -> [Capture] {
        try await fetchAll(Capture.self, from: .captures, orderedBy: "created_at", descending: true)
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        try await collection(.captures).document(id.uuidString).getDocument(as: Capture.self)
    }

    /// The inbox query. Unsorted (see `fetchWhere`) — the adapter orders newest-first client-side.
    func fetchUnprocessedCaptures() async throws -> [Capture] {
        try await fetchWhere(Capture.self, from: .captures, field: "processed", equals: false)
    }

    /// Triage's partial update — never a whole-document overwrite, so the `tag_ids` membership
    /// array (managed in `FirebaseManager+Tags.swift`, not part of `Capture`'s `Codable`) survives.
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws {
        var fields: [String: Any] = [:]
        if let status = changes.status {
            fields["status"] = status.rawValue
            fields["processed"] = status == .processed
        }
        if let title = changes.title {
            fields["title"] = title
        }
        Self.setNullable(changes.lifeAreaId, forKey: "lifeAreaId", in: &fields) { $0.uuidString }
        try await update(id: id, fields: fields, in: .captures)
    }

    func markCaptureProcessed(id: UUID) async throws {
        try await update(
            id: id,
            fields: ["processed": true, "status": CaptureStatus.processed.rawValue],
            in: .captures
        )
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

    func fetchNudge(id: UUID) async throws -> Nudge {
        try await collection(.nudges).document(id.uuidString).getDocument(as: Nudge.self)
    }
}

// MARK: - Focus sessions

extension FirebaseManager {
    /// Append-only in practice: a finished sprint is a historical fact, so nothing updates or
    /// deletes these — the weekly and trend analytics read them straight back.
    func saveFocusSession(_ session: CompletedFocusSession) async throws {
        try await save(session, id: session.id, in: .focusSessions)
    }

    /// Newest-first history, used by the focus analytics views.
    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        try await fetchAll(
            CompletedFocusSession.self, from: .focusSessions, orderedBy: "ended_at", descending: true
        )
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
