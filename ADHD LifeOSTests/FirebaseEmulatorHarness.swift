//
//  FirebaseEmulatorHarness.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Shared setup for the only tests in this suite that touch a real Firestore/Auth/Storage:
/// `FirebaseManager`'s own extensions (`+Seed`, `+Tags`, `+AccountDeletion`, `+Storage`). Every
/// other Firebase type is tested through a `*BackingStore` fake and needs none of this.
///
/// Note what is NOT imported here: `FirebaseFirestore`. The test bundle is app-hosted
/// (`BUNDLE_LOADER`), so the SDK is already loaded in the process, and every assertion below
/// goes through `FirebaseManager` methods that return native Swift types. That is what lets
/// these tests exist without linking the SDK into the test target — which CLAUDE.md forbids,
/// because linking a static product into both the app and its hosted test bundle realises every
/// Objective-C class twice.
///
/// ## The interlock
///
/// `deleteAllUserData()` erases every document its signed-in user owns. Pointed at the live
/// project by accident it would do that to E's real account, irreversibly. So no test here runs
/// until emulator mode is *proven* — and the two failure modes get deliberately different
/// treatment:
///
/// - **Emulator not running** → `XCTSkip`. The standard suite must stay green on a machine with
///   no emulator up, since these are integration tests, not unit tests.
/// - **Emulator running but the app is NOT pointed at it** → `XCTFail`, loudly. That is the
///   dangerous state: the tests would otherwise proceed against whatever Firestore the app *is*
///   pointed at, which is production.
enum FirebaseEmulatorHarness {
    /// The password every harness-created account is given, exposed so reauthentication tests
    /// can present the correct one — and, by altering it, a deliberately wrong one.
    static let password = "emulator-password-123"

    /// Probed once per process. The emulator either is or is not up for the duration of a run,
    /// and re-probing per test would add a network round trip to every one of them.
    private actor Probe {
        static let shared = Probe()
        private var cached: Bool?

        func isReachable(_ settings: FirebaseEmulatorSettings) async -> Bool {
            if let cached { return cached }
            let reachable = await Self.ping(settings)
            cached = reachable
            return reachable
        }

        /// The Firestore emulator answers its own root with a plain 200. Any HTTP response at
        /// all proves something is listening; only a transport failure means it is not.
        private static func ping(_ settings: FirebaseEmulatorSettings) async -> Bool {
            guard let url = URL(string: "http://\(settings.host):\(settings.firestorePort)/") else {
                return false
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 2
            do {
                _ = try await URLSession.shared.data(for: request)
                return true
            } catch {
                return false
            }
        }
    }

    /// Call first in every emulator-backed test. Throws `XCTSkip` when the suite is not running,
    /// and fails outright when it is running but the app is aimed somewhere else.
    static func requireEmulator(
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        guard let settings = FirebaseManager.shared.emulatorSettings else {
            // Reaching production is not a thing to skip past quietly. Either the scheme's
            // LIFEOS_FIREBASE_EMULATOR_HOST is missing, or it was malformed and
            // `FirebaseEmulatorSettings.resolve` correctly refused it.
            XCTFail(
                """
                Refusing to run: the app under test is NOT pointed at the Firebase emulator, so \
                these tests would read and write the live project. Check the Test action's \
                \(FirebaseEmulatorSettings.hostKey) environment variable in the shared scheme.
                """,
                file: file,
                line: line
            )
            throw XCTSkip("Emulator mode is not active — see the failure above.")
        }

        guard await Probe.shared.isReachable(settings) else {
            throw XCTSkip(
                """
                Firebase Emulator Suite is not running at \(settings.firestoreHost). \
                Start it with `scripts/emulators.sh`, then re-run. Note firebase-tools needs \
                Java 21+ (this machine keeps it keg-only at /opt/homebrew/opt/openjdk@21, which \
                is why the script sets JAVA_HOME rather than relying on `java` on PATH). \
                See CLAUDE.md's "Firebase emulator" section.
                """
            )
        }
    }

    /// A brand-new signed-in account, seeded exactly as production seeds it — `signUp` runs
    /// `seedDefaultContentIfNeeded()`, and that is the behaviour `+Seed`'s tests are about.
    ///
    /// Each test gets its own account rather than sharing one, so no test can see another's
    /// leftovers and none of them need a teardown wipe to be correct.
    @discardableResult
    static func signUpSeededUser() async throws -> FirebaseAuthUser {
        try? FirebaseManager.shared.signOut()
        return try await FirebaseManager.shared.signUp(
            email: "lifeos-test-\(UUID().uuidString)@example.test",
            password: password
        )
    }

    /// A signed-in account with no content at all — the seed is written and then cleared, so
    /// tests about tags or deletion assert against exactly what they put there.
    ///
    /// This does lean on `deleteAllUserData()` to arrange state for tests of *other* extensions.
    /// That is a deliberate trade: the alternative is a bespoke wipe that could drift from the
    /// real one, and `+AccountDeletion`'s own tests verify this call independently.
    @discardableResult
    static func signUpEmptyUser() async throws -> FirebaseAuthUser {
        let user = try await signUpSeededUser()
        try await FirebaseManager.shared.deleteAllUserData()
        return user
    }

    /// Leaves the emulator without the account the test created. Best-effort: a test that
    /// already deleted its own auth user (as `+AccountDeletion`'s do) has nothing left to remove,
    /// and the emulator is discarded wholesale at the end of a run regardless.
    static func tearDownCurrentUser() async {
        try? await FirebaseManager.shared.deleteAllUserData()
        try? await FirebaseManager.shared.deleteAuthUser()
        try? FirebaseManager.shared.signOut()
    }
}
