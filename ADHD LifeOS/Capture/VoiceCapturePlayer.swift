//
//  VoiceCapturePlayer.swift
//  ADHD LifeOS
//

import AVFoundation
import Combine
import Foundation

/// Wraps `AVPlayer` for streaming a voice capture's `mediaURL` from the inbox row. One instance per
/// row (owned by `VoicePlaybackButton`), so playback state never leaks across rows.
@MainActor
final class VoiceCapturePlayer: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    func toggle(url: URL?) {
        guard let url else { return }

        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        if player == nil || (player?.currentItem?.asset as? AVURLAsset)?.url != url {
            removeEndObserver()
            player = AVPlayer(url: url)
            observeEnd()
        }
        player?.seek(to: .zero)
        player?.play()
        isPlaying = true
    }

    private func observeEnd() {
        guard let item = player?.currentItem else { return }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isPlaying = false }
        }
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}
