//
//  FakeVoiceTranscribing.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeVoiceTranscribing: VoiceTranscribing, @unchecked Sendable {
    var transcribeResult: Result<String, Error> = .success("Buy milk")

    private(set) var transcribeCallCount = 0
    private(set) var lastAudioURL: URL?

    func transcribe(audioURL: URL) async throws -> String {
        transcribeCallCount += 1
        lastAudioURL = audioURL
        return try transcribeResult.get()
    }
}
