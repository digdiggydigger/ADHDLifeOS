//
//  CelebrationSoundTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-7` — E's F5: one soft chime over the FULL-SCREEN celebrations only, behind
//  a "Celebration sounds" switch that is OFF by default.
//
//  **The switch has been live in Settings since `F-CTACelebrations-3` and has never done
//  anything** — it stored a choice nothing read. That is this repo's most-repeated defect shape
//  wearing a preference instead of a helper, so the guards here are about REACHABILITY at least
//  as much as correctness: that a real player reaches the centre, and that the switch is what
//  decides.
//

import AVFoundation
import XCTest
@testable import ADHD_LifeOS

final class CelebrationSoundTests: XCTestCase {

    // MARK: - Doubles

    /// Watches the category being re-asserted without touching the real shared session.
    private final class SpySession: CelebrationAudioSessionConfiguring {
        var activations = 0
        var error: Error?

        func activateAmbientMixing() throws {
            activations += 1
            if let error { throw error }
        }
    }

    private struct SessionFailure: Error {}

    /// 40 ms of silent 16-bit PCM in a WAV container — enough for a real `AVAudioPlayer` to
    /// initialise from, so these tests exercise the actual class rather than a stand-in.
    private func silentWAV(frames: Int = 1_764) -> Data {
        let dataBytes = frames * 2
        var wav = Data()
        func ascii(_ text: String) { wav.append(contentsOf: Array(text.utf8)) }
        func word32(_ value: UInt32) {
            withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) }
        }
        func word16(_ value: UInt16) {
            withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) }
        }
        ascii("RIFF"); word32(UInt32(36 + dataBytes)); ascii("WAVE")
        ascii("fmt "); word32(16); word16(1); word16(1)
        word32(44_100); word32(88_200); word16(2); word16(16)
        ascii("data"); word32(UInt32(dataBytes))
        wav.append(Data(count: dataBytes))
        return wav
    }

    // MARK: - The session, which is the whole reason this is not two lines

    /// **The category is re-asserted before EVERY play, not once at construction.** The voice
    /// recorder's `.playAndRecord` outlives its own deactivation, so a chime that configured the
    /// session once at launch would later play through whatever category was left behind — over
    /// the top of the user's music, or routed to the earpiece.
    func testTheAmbientMixingCategoryIsReassertedBeforeEveryPlay() throws {
        let session = SpySession()
        let sut = CelebrationSoundPlayer(session: session, loadAsset: { _ in self.silentWAV() })

        sut.play()
        sut.play()
        sut.play()

        XCTAssertEqual(
            session.activations, 3,
            "the session was configured fewer times than the chime played — a category set once"
                + " at launch is a category some other feature has since replaced"
        )
    }

    /// `.ambient` is what makes the chime obey the ring/silent switch (E's wish) and duck under
    /// nothing; `.mixWithOthers` is what stops it pausing the user's music. Neither is optional.
    func testTheCategoryIsAmbientAndMixing() {
        let sut = LiveCelebrationAudioSession()

        XCTAssertEqual(sut.category, .ambient, "a chime must never interrupt or duck music")
        XCTAssertTrue(
            sut.options.contains(.mixWithOthers),
            "without .mixWithOthers the first celebration of the day stops whatever the user is"
                + " listening to, which is a far worse bug than a missing chime"
        )
    }

    /// A session that refuses must not take the app down with it, and must not stop the
    /// celebration: the confetti is the feedback, the chime is the garnish.
    func testAFailingSessionIsSwallowedRatherThanThrown() {
        let session = SpySession()
        session.error = SessionFailure()
        let sut = CelebrationSoundPlayer(session: session, loadAsset: { _ in self.silentWAV() })

        sut.play()

        XCTAssertEqual(session.activations, 1, "the play must still have been attempted")
    }

    // MARK: - Degrading to silence

    /// The state any future asset rename or dropped dataset lands in — and the state this block
    /// itself shipped in for one commit, before E picked a chime by ear on 2026-09-13.
    /// **Silence, never a crash and never a throw.**
    func testAMissingAssetDegradesToSilence() {
        let session = SpySession()
        let sut = CelebrationSoundPlayer(session: session, loadAsset: { _ in nil })

        sut.play()

        XCTAssertFalse(
            sut.hasSound,
            "a player with no asset must know it has nothing to play"
        )
        XCTAssertEqual(
            session.activations, 0,
            "with nothing to play there is no reason to touch the audio session at all — a chime"
                + " that reconfigures the session and then plays silence is a side effect with no"
                + " upside"
        )
    }

    /// Data that is not audio is the same case as no data, and arrives the same way: a dataset
    /// holding the wrong file. `AVAudioPlayer(data:)` THROWS here rather than returning nil.
    func testUnplayableDataDegradesToSilence() {
        let sut = CelebrationSoundPlayer(
            session: SpySession(), loadAsset: { _ in Data("not audio".utf8) }
        )

        XCTAssertFalse(sut.hasSound)
        sut.play()
    }

    // MARK: - Allocated once

    /// The design record's rule: one `AVAudioPlayer`, built at construction. Allocating per play
    /// would put a file decode on the main thread at the exact moment the confetti starts.
    func testTheAssetIsReadOnceRatherThanOnEveryPlay() {
        var reads = 0
        let sut = CelebrationSoundPlayer(
            session: SpySession(),
            loadAsset: { _ in
                reads += 1
                return self.silentWAV()
            }
        )

        sut.play()
        sut.play()

        XCTAssertEqual(reads, 1, "the asset is decoded on every play, on the main thread")
    }

    /// The name the dataset must carry. A typo here is silence with no error anywhere, which is
    /// exactly how a missing asset differs from a missing method.
    func testThePlayerLooksForTheAssetTheCatalogIsMeantToHold() {
        var asked: [String] = []
        _ = CelebrationSoundPlayer(session: SpySession(), loadAsset: { name in
            asked.append(name)
            return nil
        })

        XCTAssertEqual(asked, ["CelebrationChime"])
    }

    // MARK: - The real asset, through the real loader

    /// **Every other test in this file injects `loadAsset`, so none of them touches the catalog.**
    /// That leaves the one thing a user actually depends on unproven: that
    /// `NSDataAsset(name: "CelebrationChime")` RESOLVES at runtime and that `AVAudioPlayer`
    /// accepts the CAF bytes the catalog hands back.
    ///
    /// Checking the compiled `Assets.car` with `assetutil` proves the bytes are in the bundle and
    /// nothing more — a dataset can be present and still be unreadable by name, or hold something
    /// `AVAudioPlayer` refuses. The unit-test target HOSTS the app, so the catalog is right there
    /// and this costs nothing.
    ///
    /// If this ever goes red, E's "Celebration sounds" switch is a dead row again and the Settings
    /// footer is lying — which is the exact state this block existed to end.
    func testTheRealCatalogAssetLoadsAndIsPlayable() {
        let sut = CelebrationSoundPlayer(session: SpySession())

        XCTAssertTrue(
            sut.hasSound,
            "the chime did not load from the real asset catalog. Either the"
                + " CelebrationChime.dataset is missing or renamed, or the file inside it is not"
                + " something AVAudioPlayer can decode — and both fail SILENTLY in production."
        )
    }

    // MARK: - The inert one

    /// Previews and tests must never reach `AVAudioSession`.
    func testTheInertPlayerDoesNothingAndSaysSo() {
        let sut = InertCelebrationSoundPlayer()

        XCTAssertFalse(sut.hasSound)
        sut.play()
    }
}
