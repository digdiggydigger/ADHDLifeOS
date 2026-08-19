//
//  FirebaseManager+Storage.swift
//  ADHD LifeOS
//

import FirebaseCore
import FirebaseStorage
import Foundation

/// Firebase Storage replacement for the old S3 presigned-PUT capture-media flow. The
/// `CaptureUploadTarget` contract survives unchanged: `mediaKey` is now a Storage object path
/// under the signed-in user, and `uploadURL` is its `gs://` form (which
/// `Storage.reference(forURL:)` resolves natively) rather than a presigned HTTPS URL.
/// `thumbnailKey` is always `nil` — there is no thumbnailer on the blank slate, and
/// `Capture.photoDisplayURL` already falls back to the full-size `mediaURL`.
extension FirebaseManager {
    func makeUploadTarget(kind: CaptureKind, contentType: String) throws -> CaptureUploadTarget {
        let uid = try requireUID()
        let key = "users/\(uid)/captures/\(UUID().lowercaseUUIDString).\(Self.fileExtension(for: contentType))"
        guard let bucket = FirebaseApp.app()?.options.storageBucket, !bucket.isEmpty,
              let uploadURL = URL(string: "gs://\(bucket)/\(key)") else {
            throw FirebaseManagerError.storageUnavailable
        }
        return CaptureUploadTarget(uploadURL: uploadURL, mediaKey: key, thumbnailKey: nil)
    }

    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        _ = try await Storage.storage().reference(forURL: uploadURL.absoluteString)
            .putDataAsync(data, metadata: metadata)
    }

    /// The stable HTTPS URL stored on the capture document as `mediaURL` — resolvable only after
    /// the object has been uploaded, hence the upload-then-create call order in the adapter.
    func downloadURL(forMediaKey key: String) async throws -> URL {
        try await Storage.storage().reference(withPath: key).downloadURL()
    }

    private static func fileExtension(for contentType: String) -> String {
        guard let subtype = contentType.split(separator: "/").last, !subtype.isEmpty else {
            return "bin"
        }
        return subtype == "jpeg" ? "jpg" : String(subtype)
    }
}
