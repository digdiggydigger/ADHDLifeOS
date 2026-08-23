//
//  FirebaseManager+Emulator.swift
//  ADHD LifeOS
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

/// Applies a resolved `FirebaseEmulatorSettings` to the three SDKs. The decision of *whether* to
/// run against an emulator lives in `FirebaseEmulatorSettings` (pure, tested); this file is only
/// the application of it, and is the part that cannot be unit-tested without linking the SDK
/// into the test bundle — which CLAUDE.md forbids.
extension FirebaseManager {
    /// Must run after `FirebaseApp.configure()` and BEFORE any read or write: Firestore latches
    /// its settings at first use and throws if they are mutated afterwards. `FirebaseManager`'s
    /// `init` is the only caller, immediately after configuring, which is the earliest moment
    /// the app can express this.
    static func pointSDKsAtEmulator(_ settings: FirebaseEmulatorSettings) {
        Auth.auth().useEmulator(withHost: settings.host, port: settings.authPort)
        Storage.storage().useEmulator(withHost: settings.host, port: settings.storagePort)

        // Firestore is configured by hand rather than through `useEmulator(withHost:port:)`,
        // and the reason is not stylistic. Despite the name, that method sets ONLY the host —
        // read `FIRFirestore.mm`: it copies the settings, assigns `host`, and stops. It does
        // NOT disable TLS. The client then speaks TLS to a plaintext emulator and retries
        // forever with `WRONG_VERSION_NUMBER: Invalid certificate verification context`, which
        // reads like a broken emulator install rather than a client misconfiguration and cost
        // this session two debugging rounds. Auth and Storage's same-named methods DO handle
        // their own transport, which is why only this one is spelled out.
        //
        // The memory-only cache is here for correctness too, not tidiness: with the default
        // persistent cache a read can be served locally, so a write that never reached the
        // emulator still reads back as though it had — a deletion test would then pass against
        // data it had failed to delete. It also stops on-disk state leaking between runs.
        let firestoreSettings = FirestoreSettings()
        firestoreSettings.host = settings.firestoreHost
        firestoreSettings.isSSLEnabled = false
        firestoreSettings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = firestoreSettings
    }
}
