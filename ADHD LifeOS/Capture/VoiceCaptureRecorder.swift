//
//  VoiceCaptureRecorder.swift
//  ADHD LifeOS
//

import AVFoundation
import Combine
import Foundation

/// Wraps `AVAudioRecorder` for the voice-capture composer. Records to a temporary `.m4a` file and
/// hands the URL back to the caller on `stopRecording()` — the caller (`CaptureInboxService`) reads
/// the bytes and drives transcription/upload from there, so this type has no capture-domain
/// knowledge of its own.
@MainActor
final class VoiceCaptureRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var permissionDeniedMessage: String?

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func startRecording() async {
        permissionDeniedMessage = nil

        guard await Self.requestMicrophonePermission() else {
            permissionDeniedMessage = "Microphone access is needed to record a voice note. Enable it in Settings."
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            permissionDeniedMessage = "Couldn't start the audio session."
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            guard audioRecorder.record() else {
                permissionDeniedMessage = "Couldn't start recording."
                return
            }
            recorder = audioRecorder
            recordingURL = url
            isRecording = true
        } catch {
            permissionDeniedMessage = "Couldn't start recording."
        }
    }

    @discardableResult
    func stopRecording() -> URL? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return recordingURL
    }

    private static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
