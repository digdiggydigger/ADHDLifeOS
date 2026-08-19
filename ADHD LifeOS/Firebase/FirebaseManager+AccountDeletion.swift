//
//  FirebaseManager+AccountDeletion.swift
//  ADHD LifeOS
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

/// Mechanics of full account erasure (App Store 5.1.1(v)). This layer stays domain-neutral —
/// raw Firebase errors propagate, and `FirebaseAccountDeletionAdapter` maps them (including the
/// `requiresRecentLogin` distinction) into `AccountDeletionError`, matching the manager/adapter
/// split used by auth sign-in.
///
/// ORDERING CONTRACT: callers must run `deleteAllUserData()` to completion BEFORE
/// `deleteAuthUser()` — the security rules scope every document to the signed-in owner, so once
/// the auth user is gone the remaining data is unreachable by anyone but a console admin.
extension FirebaseManager {
    /// The signed-in user's strongest reauthentication proof, from their linked providers.
    func accountReauthMethod() -> AccountReauthMethod? {
        guard let user = Auth.auth().currentUser else { return nil }
        let providers = Set(user.providerData.map(\.providerID))
        return providers.contains("apple.com") ? .apple : .password
    }

    /// Deletes every document in every per-user collection (batched), sweeps capture media in
    /// Storage best-effort, then removes the `users/{uid}` profile doc (and with it the
    /// `seeded_at` marker, so any later account starts from a fresh seed).
    ///
    /// NOTE: requires the 2026-08-19 rules revision that allows owner DELETE on `logs` —
    /// under the earlier append-only rules the journal cascade is rejected and this throws,
    /// which correctly aborts deletion before the auth account is touched.
    func deleteAllUserData() async throws {
        let uid = try requireUID()
        for name in Collection.allCases {
            try await deleteAllDocuments(in: name)
        }
        await deleteCaptureMedia(uid: uid)
        try await userDocument().delete()
    }

    func deleteAuthUser() async throws {
        guard let user = Auth.auth().currentUser else { throw FirebaseManagerError.notSignedIn }
        try await user.delete()
    }

    func reauthenticateWithPassword(_ password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw FirebaseManagerError.notSignedIn
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        _ = try await user.reauthenticate(with: credential)
    }

    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws {
        guard let user = Auth.auth().currentUser else { throw FirebaseManagerError.notSignedIn }
        let credential = OAuthProvider.credential(providerID: .apple, idToken: idToken, rawNonce: rawNonce)
        _ = try await user.reauthenticate(with: credential)
    }

    /// Firestore batches cap at 500 writes; the chunking keeps arbitrarily large collections
    /// deletable in one pass.
    private func deleteAllDocuments(in name: Collection) async throws {
        let references = try await collection(name).getDocuments().documents.map(\.reference)
        var start = 0
        while start < references.count {
            let end = min(start + 500, references.count)
            let batch = firestoreBatch()
            for reference in references[start..<end] {
                batch.deleteDocument(reference)
            }
            try await batch.commit()
            start = end
        }
    }

    /// Best-effort: capture media blobs are worth sweeping, but a Storage hiccup (or unpublished
    /// storage rules) must not block the Firestore + Auth erasure the guideline actually requires.
    private func deleteCaptureMedia(uid: String) async {
        guard let listing = try? await Storage.storage()
            .reference(withPath: "users/\(uid)/captures").listAll() else { return }
        for item in listing.items {
            try? await item.delete()
        }
    }
}
