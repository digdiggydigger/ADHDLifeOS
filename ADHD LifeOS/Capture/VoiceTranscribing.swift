//
//  VoiceTranscribing.swift
//  ADHD LifeOS
//

import Foundation
import Speech

enum VoiceTranscriptionError: LocalizedError, Equatable {
    case permissionDenied
    case recognitionFailed(String)
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition access is needed to transcribe your voice note. Enable it in Settings."
        case .recognitionFailed(let message):
            return message
        case .emptyTranscription:
            return "Couldn't hear anything in that recording. Try again."
        }
    }
}

/// Thin seam over `SFSpeechRecognizer` so `CaptureInboxService` is testable without a mic or
/// speech-recognition hardware/entitlement. Mirrors the codebase's adapter-seam habit
/// (`CaptureClientAdapting`, `AuthClientAdapting`).
protocol VoiceTranscribing: Sendable {
    func transcribe(audioURL: URL) async throws -> String
}

private final class TranscriptionResumeGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var hasResumed = false

    func resumeOnce() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !hasResumed else { return false }
        hasResumed = true
        return true
    }
}

final class SFSpeechVoiceTranscriber: VoiceTranscribing {
    func transcribe(audioURL: URL) async throws -> String {
        let authStatus = await Self.requestAuthorization()
        guard authStatus == .authorized else {
            throw VoiceTranscriptionError.permissionDenied
        }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw VoiceTranscriptionError.recognitionFailed("Speech recognition is unavailable on this device.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let resumeGuard = TranscriptionResumeGuard()
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false

            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    if resumeGuard.resumeOnce() {
                        let failure = VoiceTranscriptionError.recognitionFailed(error.localizedDescription)
                        continuation.resume(throwing: failure)
                    }
                    return
                }
                guard let result, result.isFinal else { return }
                if resumeGuard.resumeOnce() {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    private static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
