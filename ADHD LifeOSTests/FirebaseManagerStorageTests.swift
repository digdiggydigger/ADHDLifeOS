//
//  FirebaseManagerStorageTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `FirebaseManager+Storage` — the capture-media upload path that replaced the old S3
/// presigned-PUT flow.
///
/// The interesting part is that `CaptureUploadTarget`'s contract survived the backend swap with
/// its shape intact but its meaning changed: `uploadURL` is now a `gs://` reference rather than a
/// presigned HTTPS URL, and `mediaKey` is a Storage object path rather than an S3 key. Nothing in
/// the type system marks that difference, so these tests pin it.
///
/// Skips when the Emulator Suite is not running — see `FirebaseEmulatorHarness`.
final class FirebaseManagerStorageTests: XCTestCase {
    private var manager: FirebaseManager { .shared }

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
        try await FirebaseEmulatorHarness.signUpEmptyUser()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    // MARK: - Addressing

    /// Media is scoped under the signed-in user's own prefix, which is what `storage.rules`
    /// keys ownership off — and what account deletion's media sweep lists to erase.
    func testMakeUploadTarget_scopesTheKeyToTheSignedInUser() throws {
        let uid = try XCTUnwrap(manager.currentUser?.uid)

        let target = try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")

        XCTAssertTrue(
            target.mediaKey.hasPrefix("users/\(uid)/captures/"),
            "unexpected media key: \(target.mediaKey)"
        )
    }

    /// A `gs://` URL, not an HTTPS one. `Storage.reference(forURL:)` resolves this natively;
    /// handing it to `URLSession` — as the S3 flow did — would simply fail.
    func testMakeUploadTarget_returnsAGoogleStorageURLForTheSameKey() throws {
        let target = try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")

        XCTAssertEqual(target.uploadURL.scheme, "gs")
        XCTAssertTrue(
            target.uploadURL.absoluteString.hasSuffix("/\(target.mediaKey)"),
            "upload URL \(target.uploadURL) does not address media key \(target.mediaKey)"
        )
    }

    /// There is no thumbnailer on the Firebase blank slate — the old S3 flow had a Lambda for it.
    /// `Capture.photoDisplayURL` falls back to the full-size image, so `nil` here is correct
    /// rather than unfinished.
    func testMakeUploadTarget_neverPromisesAThumbnail() throws {
        let target = try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")

        XCTAssertNil(target.thumbnailKey)
    }

    func testMakeUploadTarget_givesEachCallItsOwnKey() throws {
        let first = try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")
        let second = try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")

        XCTAssertNotEqual(first.mediaKey, second.mediaKey)
    }

    func testMakeUploadTarget_whenSignedOut_throwsNotSignedIn() throws {
        try manager.signOut()

        XCTAssertThrowsError(try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    // MARK: - File extensions

    /// `image/jpeg` becomes `.jpg`, not `.jpeg` — the one content type given an explicit
    /// exception, so the objects match the conventional extension.
    func testMakeUploadTarget_mapsJpegToTheJpgExtension() throws {
        let target = try manager.makeUploadTarget(kind: .photo, contentType: "image/jpeg")

        XCTAssertTrue(target.mediaKey.hasSuffix(".jpg"), "unexpected key: \(target.mediaKey)")
    }

    func testMakeUploadTarget_usesTheSubtypeAsTheExtension() throws {
        let png = try manager.makeUploadTarget(kind: .photo, contentType: "image/png")
        let audio = try manager.makeUploadTarget(kind: .voice, contentType: "audio/m4a")

        XCTAssertTrue(png.mediaKey.hasSuffix(".png"), "unexpected key: \(png.mediaKey)")
        XCTAssertTrue(audio.mediaKey.hasSuffix(".m4a"), "unexpected key: \(audio.mediaKey)")
    }

    /// A content type with no usable subtype still produces an addressable object rather than a
    /// key ending in a bare dot.
    func testMakeUploadTarget_withAnEmptyContentType_fallsBackToBin() throws {
        let target = try manager.makeUploadTarget(kind: .voice, contentType: "")

        XCTAssertTrue(target.mediaKey.hasSuffix(".bin"), "unexpected key: \(target.mediaKey)")
    }

    // MARK: - Round trip

    /// The call order the capture adapter depends on: upload first, then resolve the download
    /// URL. `downloadURL` only answers for an object that already exists, which is why the
    /// adapter cannot create the capture document first.
    func testUploadThenDownloadURL_resolvesTheStoredObject() async throws {
        let target = try manager.makeUploadTarget(kind: .photo, contentType: "image/png")
        let payload = Data("not really a png, but bytes are bytes".utf8)

        try await manager.uploadMedia(to: target.uploadURL, data: payload, contentType: "image/png")

        let url = try await manager.downloadURL(forMediaKey: target.mediaKey)
        XCTAssertTrue(url.scheme == "http" || url.scheme == "https", "unexpected scheme: \(url)")
    }

    /// The failure the adapter's ordering exists to avoid — asking for a URL before anything has
    /// been uploaded is an error, not an empty answer.
    func testDownloadURL_forAnObjectThatWasNeverUploaded_throws() async throws {
        let target = try manager.makeUploadTarget(kind: .photo, contentType: "image/png")

        do {
            _ = try await manager.downloadURL(forMediaKey: target.mediaKey)
            XCTFail("resolved a download URL for an object that does not exist")
        } catch {
            // Expected — raw Storage error; the capture adapter maps it.
        }
    }
}
