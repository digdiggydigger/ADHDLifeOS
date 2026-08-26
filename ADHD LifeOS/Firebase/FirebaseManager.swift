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

    /// Non-nil only when `LIFEOS_FIREBASE_EMULATOR_HOST` named a reachable-looking host at
    /// launch — see `FirebaseEmulatorSettings`. Production is always `nil`.
    let emulatorSettings: FirebaseEmulatorSettings?

    /// Positive proof, for tests that are about to destroy data, that this manager is talking to
    /// an emulator and not to the live project. `FirebaseEmulatorHarness` refuses to run without
    /// it — reading `false` here is the difference between wiping a scratch database and wiping
    /// the signed-in user's real one.
    var isUsingEmulator: Bool {
        emulatorSettings != nil
    }

    private init() {
        // Firestore/Auth trap at first touch if the app never configured Firebase; guarding here
        // keeps the manager usable regardless of launch order once GoogleService-Info.plist exists.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        // Before `auth`/`firestore` are captured below, and so before any operation can run:
        // Firestore latches its settings at first use.
        emulatorSettings = FirebaseEmulatorSettings.resolve()
        if let emulatorSettings {
            Self.pointSDKsAtEmulator(emulatorSettings)
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

    /// The signed-in user's Firebase ID token, transparently refreshed when the cached one has
    /// expired. `nil` when there is no stored session at all — which callers must treat as a
    /// forced sign-out, distinct from a *throw*, which means the refresh itself was rejected.
    ///
    /// Exists so `FirebaseAuthClientAdapter` reaches Auth through the manager like every other
    /// call rather than touching `Auth.auth()` directly, which nothing could stub.
    func idToken(forcingRefresh: Bool = false) async throws -> String? {
        guard let user = auth.currentUser else { return nil }
        return try await user.getIDTokenResult(forcingRefresh: forcingRefresh).token
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

    // Every method below posts `DataChangeSignal` AFTER its awaited write, so the signal only
    // announces writes that actually landed. Together with the batch commits in `+LifeAreas`,
    // `+Tags` and `+Seed`, these are ALL the user-data write paths in the app (grep-audited,
    // 2026-08-26; `+AccountDeletion` is deliberately silent — there is no UI left to refresh).

    func save<Model: Encodable>(_ value: Model, id: UUID, in name: Collection) async throws {
        let data = try FirestoreDocumentCoder.encode(value)
        try await collection(name).document(id.uuidString).setData(data)
        DataChangeSignal.post()
    }

    func delete(id: UUID, from name: Collection) async throws {
        try await collection(name).document(id.uuidString).delete()
        DataChangeSignal.post()
    }

    func update(id: UUID, fields: [String: Any], in name: Collection) async throws {
        guard !fields.isEmpty else { return }
        try await collection(name).document(id.uuidString).updateData(fields)
        DataChangeSignal.post()
    }
}
