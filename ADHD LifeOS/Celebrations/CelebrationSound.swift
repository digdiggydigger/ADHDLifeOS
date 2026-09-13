//
//  CelebrationSound.swift
//  ADHD LifeOS
//
//  E's F5, from the celebrations design record: **one soft chime over the FULL-SCREEN
//  celebrations only** — the Confirm and the four milestones — behind a "Celebration sounds"
//  switch that is OFF by default. Not the nine in-place pops: E chose "full-screen milestones
//  only" over "no sound" and over sound everywhere.
//
//  **Which celebrations get it is not decided here.** `CelebrationCenter.start` chimes only for a
//  burst whose `isFullScreen` is true, and a request refused by E's Celebrations switch is
//  downgraded to `.pop` — so that switch silences the chime with no second gate, and this file
//  never asks what kind of celebration is playing.
//
//  **The audio session is the whole reason this is not two lines**, and each rule below is a
//  defect it prevents rather than ceremony.
//

import AVFoundation
import Foundation
// `NSDataAsset` — the asset catalog's non-image reader — lives in UIKit on iOS, not Foundation.
import UIKit

/// The seam `CelebrationCenter` is handed. One method, because E asked for one chime.
protocol CelebrationSoundPlaying {
    /// True when there is actually something to play. Lets a caller — and a test — tell "the
    /// switch is off" apart from "the catalog has no chime in it", which sound identical.
    var hasSound: Bool { get }
    func play()
}

/// Previews and tests: reaches no session and holds no player.
///
/// **Deliberately NOT a floor path.** `AVAudioSession.setCategory(_:options:)` and
/// `AVAudioPlayer(data:)` are both available at the app's 16.0 target, so the chime has no
/// `#available` gate and every user gets the same one — there is no tier for this to be the
/// quiet half of. An earlier draft of this comment claimed otherwise and would have sent a
/// reader hunting for a gate that does not exist.
struct InertCelebrationSoundPlayer: CelebrationSoundPlaying {
    var hasSound: Bool { false }
    func play() {}
}

/// What the player needs from `AVAudioSession`, narrowed to one call so a test can watch the
/// category being re-asserted without touching the process-wide singleton — the same per-feature
/// seam rule the Firebase adapters follow.
protocol CelebrationAudioSessionConfiguring {
    func activateAmbientMixing() throws
}

/// The real one. `.ambient` and `.mixWithOthers` are named here rather than at the call site so
/// the two properties a test asserts are the two the app actually uses.
struct LiveCelebrationAudioSession: CelebrationAudioSessionConfiguring {
    /// **`.ambient`, so the chime obeys the ring/silent switch** — E's wish, and the reason this
    /// is not `.playback`, which would sound through a silenced phone.
    let category: AVAudioSession.Category = .ambient
    /// **`.mixWithOthers`, so the first celebration of the day does not stop the user's music.**
    /// Without it the session takes exclusive control and whatever they were listening to pauses.
    let options: AVAudioSession.CategoryOptions = [.mixWithOthers]

    func activateAmbientMixing() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(category, options: options)
        // Never paired with a `setActive(false)`. Deactivating hands the session back and can
        // unduck or resume other audio at a moment that has nothing to do with what the user is
        // listening to; leaving it active costs nothing and the category is re-asserted anyway.
        try session.setActive(true)
    }
}

/// The chime.
final class CelebrationSoundPlayer: CelebrationSoundPlaying {
    /// The dataset the asset catalog must hold. A typo here is silence with no error anywhere —
    /// which is precisely how a missing ASSET differs from a missing method — so the name is a
    /// constant with a test on it rather than a string literal at the load site.
    static let assetName = "CelebrationChime"

    private let session: CelebrationAudioSessionConfiguring
    /// **Built ONCE, at construction.** Allocating per play would put a decode on the main thread
    /// at the exact moment the confetti starts, which is the one moment in the app that must not
    /// stutter.
    private let player: AVAudioPlayer?

    var hasSound: Bool { player != nil }

    init(
        session: CelebrationAudioSessionConfiguring = LiveCelebrationAudioSession(),
        loadAsset: (String) -> Data? = { NSDataAsset(name: $0)?.data }
    ) {
        self.session = session
        // Both failures — no dataset, or a dataset holding something that is not audio — land as
        // `nil` and mean the same thing to every caller: silence. `AVAudioPlayer(data:)` THROWS
        // on unplayable bytes rather than returning nil, so the `try?` is load-bearing.
        self.player = loadAsset(Self.assetName).flatMap { try? AVAudioPlayer(data: $0) }
        player?.prepareToPlay()
    }

    func play() {
        // Nothing to play means nothing to configure: a chime that reconfigures the process's
        // audio session and then plays silence is a side effect with no upside.
        guard let player else { return }
        // **Re-asserted before EVERY play, not once at construction.** The voice recorder's
        // `.playAndRecord` category outlives its own deactivation, so a session configured at
        // launch is a session some later feature has silently replaced — and the chime would
        // then play over the top of the user's music, or out of the earpiece.
        //
        // A session that refuses is swallowed: the confetti is the feedback and the chime is the
        // garnish, so a celebration must never be lost to an audio-routing problem.
        try? session.activateAmbientMixing()
        player.currentTime = 0
        player.play()
    }
}
