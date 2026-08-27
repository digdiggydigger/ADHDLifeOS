//
//  CaptureValidation.swift
//  ADHD LifeOS
//

import Foundation

enum CaptureValidationError: LocalizedError, Equatable {
    case emptyContent
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Capture content is required."
        case .invalidURL:
            return "Enter a valid URL."
        }
    }
}

struct NormalizedCreateCaptureInput: Equatable, Sendable {
    let content: String
    let kind: CaptureKind
    let title: String?
    let lifeAreaId: UUID?
    let mediaKey: String?
    let mediaContentType: String?
    let thumbnailKey: String?
    /// Set by the service AFTER validation — location is not something to validate, and a missing
    /// stamp is never a reason to refuse a capture.
    var locationStamp: LocationStamp?
}

/// Mirrors the web app's capture validation (trim, reject empty, default kind) so mobile and
/// web share the same capture rules. `kind == .photo` is the one exception to the
/// non-empty-content rule — a photo capture may carry only an image and no caption. `kind == .link`
/// runs URL normalization instead of the plain non-empty check, since its content is a URL.
enum CaptureValidation {
    static let defaultKind: CaptureKind = .note

    static func normalizeCreateCaptureInput(
        content: String,
        kind: CaptureKind,
        title: String? = nil,
        lifeAreaId: UUID? = nil,
        mediaKey: String? = nil,
        mediaContentType: String? = nil,
        thumbnailKey: String? = nil
    ) -> Result<NormalizedCreateCaptureInput, CaptureValidationError> {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent: String
        if kind == .link {
            switch normalizedLinkURLString(from: trimmed) {
            case .success(let url):
                normalizedContent = url
            case .failure(let error):
                return .failure(error)
            }
        } else {
            if kind != .photo {
                guard !trimmed.isEmpty else { return .failure(.emptyContent) }
            }
            normalizedContent = trimmed
        }
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .success(NormalizedCreateCaptureInput(
            content: normalizedContent,
            kind: kind,
            title: (trimmedTitle?.isEmpty ?? true) ? nil : trimmedTitle,
            lifeAreaId: lifeAreaId,
            mediaKey: mediaKey,
            mediaContentType: mediaContentType,
            thumbnailKey: thumbnailKey
        ))
    }

    /// Normalizes free-typed link input into a saveable URL string: adds an `https://` scheme when
    /// none is present, then rejects anything that still isn't a well-formed `http`/`https` URL with
    /// a host (e.g. empty input, bare whitespace, unsupported schemes, unparseable text).
    static func normalizedLinkURLString(from raw: String) -> Result<String, CaptureValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.invalidURL) }

        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"

        guard let components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host,
              !host.isEmpty,
              let normalized = components.string
        else {
            return .failure(.invalidURL)
        }
        return .success(normalized)
    }
}
