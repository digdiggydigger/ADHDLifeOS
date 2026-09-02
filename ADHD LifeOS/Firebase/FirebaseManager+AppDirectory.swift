//
//  FirebaseManager+AppDirectory.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// The app-directory catalogue document (F-AppDirectory-4-Remote).
///
/// This is the app's FIRST global read, and it is deliberately NOT in the per-user
/// `Collection` enum: that enum resolves through `users/{uid}`, and routing a shared
/// read-only catalogue through it would teach the next reader that catalogue data is
/// per-user. One named method for one document, the same narrow-wrapper philosophy as
/// `updatePlace(id:fields:)`.
extension FirebaseManager {
    static let appDirectoryDocumentPath = "catalog/app_directory"

    /// The raw entry objects from `/catalog/app_directory`'s `entries` array. A missing
    /// document, or one without the field, is an EMPTY catalogue — only transport and
    /// permission failures throw (rules-unpublished reads as permission-denied, which the
    /// provider treats exactly like offline).
    func fetchAppDirectoryEntryObjects() async throws -> [[String: Any]] {
        let data = try await fetchGlobalDocumentData(path: Self.appDirectoryDocumentPath)
        return data?["entries"] as? [[String: Any]] ?? []
    }
}
