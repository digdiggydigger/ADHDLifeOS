//
//  CelebrationMountCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`'s reachability guards for the ARCHITECTURE E chose: **one drawing layer
//  per presented surface**, not one passthrough `UIWindow` above everything (the design record's
//  ARCH question, E: "One layer per surface").
//
//  That choice has a failure mode a `UIWindow` would not have had, and it is silent: a cover or
//  sheet that hosts a celebration site but mounts no layer simply draws nothing, and every unit
//  test still passes. So these enumerate the mounts, the dismissal notifications and the
//  environment wiring, and they count — a fifth presented surface cannot appear unnoticed.
//
//  **The environment is the second silent failure.** `\.celebrationCenter` defaults to `nil` and
//  `\.celebrate` to an inert requester, deliberately, so no preview, snapshot or test has to
//  provide anything. The cost of that default is that a layer which cannot see the centre is
//  indistinguishable from a quiet one, so the wiring's POSITION is asserted here rather than left
//  to a render.
//
//  **Four presenters, not three.** The design record predicted three `onDismiss`es; the tree has
//  four, because `CapturePromoteSheet` is presented from two places (`CaptureInboxView` and
//  `CaptureDetailView`). The record's count was a miscount, not a design decision.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationMountCallSiteTests: XCTestCase {

    /// Every surface that can host a celebration, and the file that mounts its layer.
    private static let mounts: [(surface: String, file: String)] = [
        (".root", "RootView.swift"),
        (".routineCover", "RootView+Doors.swift"),
        (".tasksSearch", "Tasks/TaskSearchSurface.swift"),
        (".promoteSheet", "Capture/CapturePromoteSheet.swift")
    ]

    /// Every presenter of one of those surfaces, and the surface it dismisses. `onDismiss`, never
    /// `onDisappear`: `PlaceRoutineScreen` records that `onDisappear` is unreliable for that cover.
    private struct Dismissal {
        let surface: String
        let file: String
        let presenter: String
    }

    private static let dismissals = [
        Dismissal(
            surface: ".routineCover", file: "RootView.swift",
            presenter: ".fullScreenCover(item: $presentedRoutineRun"
        ),
        Dismissal(
            surface: ".tasksSearch", file: "Tasks/TaskListView.swift",
            presenter: ".fullScreenCover(isPresented: searchModel.surfacePresentation"
        ),
        Dismissal(
            surface: ".promoteSheet", file: "Capture/CaptureInboxView.swift",
            presenter: ".sheet(item: $promotingCapture"
        ),
        Dismissal(
            surface: ".promoteSheet", file: "Capture/CaptureDetailView.swift",
            presenter: ".sheet(isPresented: $isPresentingPromoteSheet"
        )
    ]

    // MARK: - The four mounts

    func testEverySurfaceThatCanHostACelebrationMountsItsOwnLayer() throws {
        for mount in Self.mounts {
            XCTAssertTrue(
                try Self.appCode(mount.file).contains("CelebrationLayer(surface: \(mount.surface))"),
                "\(mount.file) mounts no celebration layer for \(mount.surface), so a celebration"
                    + " requested while that surface is up draws nothing at all — silently."
            )
        }
    }

    /// The counts are the guard. A fifth cover or sheet that hosts a site would add a mount here
    /// without adding one to `CelebrationSurface`, and nothing else in the suite would notice.
    func testNoSurfaceMountsALayerWithoutBeingOneOfTheFour() throws {
        let occurrences = try Self.appTargetOccurrences(of: "CelebrationLayer(surface:")
        XCTAssertEqual(
            occurrences.count, Self.mounts.count,
            "The app mounts \(occurrences.count) celebration layers, not \(Self.mounts.count)."
                + " Mounted in: \(occurrences.map(\.file).sorted().joined(separator: ", "))."
                + " A new presented surface needs a case on `CelebrationSurface`, a mount, and an"
                + " `onDismiss` — this test, and `CelebrationCenterTests`, are where that is settled."
        )
    }

    // MARK: - The four dismissals

    /// A self-dismissing surface holds a full-screen celebration until it closes (the design's
    /// `held` bursts), and every surface must pop itself off the centre's stack when it goes. A
    /// missed `onDismiss` leaves a dead surface frontmost for the rest of the launch.
    func testEveryPresenterTellsTheCentreWhenItsSurfaceIsDismissed() throws {
        for dismissal in Self.dismissals {
            let presenter = try Self.slice(
                in: dismissal.file,
                from: dismissal.presenter,
                to: ") {",
                missing: "\(dismissal.file) no longer presents \(dismissal.surface) the way this test expects."
            )
            XCTAssertTrue(
                presenter.contains("onDismiss:") && presenter.contains("surfaceDismissed(\(dismissal.surface))"),
                "\(dismissal.file)'s presenter of \(dismissal.surface) never tells the centre it closed,"
                    + " so a held celebration is never released and the surface stays frontmost for ever."
            )
        }
    }

    func testNothingElseInTheAppDismissesASurface() throws {
        let occurrences = try Self.appTargetOccurrences(of: "surfaceDismissed(")
        XCTAssertEqual(
            occurrences.count, Self.dismissals.count,
            "The app reports \(occurrences.count) surface dismissals, not \(Self.dismissals.count)."
                + " Reported in: \(occurrences.map(\.file).sorted().joined(separator: ", "))."
        )
    }

    // MARK: - The wiring

    /// The covers and sheets inherit the centre because the two environment values are applied
    /// OUTSIDE them — further down the modifier chain than the presenters, which is where the
    /// already-working `.environmentObject(searchModel)` sits for the same reason.
    func testTheCentreReachesEveryPresentedSurfaceThroughTheEnvironment() throws {
        let root = try Self.appCode("RootView.swift")
        let requester = try XCTUnwrap(
            root.range(of: ".environment(\\.celebrate, celebrationCenter)"),
            "RootView never puts the centre in the environment as a requester, so every site's"
                + " `\\.celebrate` stays the inert default and nothing is ever requested."
        )
        let centre = try XCTUnwrap(
            root.range(of: ".environment(\\.celebrationCenter, celebrationCenter)"),
            "RootView never puts the centre in the environment for the layers to draw from, so every"
                + " layer sees `nil` and draws nothing."
        )
        let lastCover = try XCTUnwrap(root.range(of: ".fullScreenCover(", options: .backwards))
        XCTAssertLessThan(
            lastCover.lowerBound, requester.lowerBound,
            "The requester is put in the environment INSIDE the covers' chain, so a cover presented"
                + " above it does not inherit it."
        )
        XCTAssertLessThan(
            lastCover.lowerBound, centre.lowerBound,
            "The centre is put in the environment INSIDE the covers' chain, so a cover's own layer"
                + " cannot see it."
        )
    }

    /// The App owns the centre, exactly as it owns `authService`: `RootView.swift` cannot hold a
    /// `@StateObject` for it, because a `@StateObject` cannot live in an extension file and that
    /// file is against the 400-line ceiling. Owned in `RootView` it would also be rebuilt on every
    /// auth-state swap, dropping whatever was in the air.
    func testTheAppOwnsTheCentreAndHandsItToRootView() throws {
        let app = try Self.appCode("ADHD_LifeOSApp.swift")
        XCTAssertTrue(
            app.contains("@StateObject private var celebrationCenter = CelebrationCenter()"),
            "The App does not own the celebration centre, so nothing outlives a tab swap."
        )
        XCTAssertTrue(
            app.contains("celebrationCenter: celebrationCenter"),
            "The App never hands the centre to RootView."
        )
        let root = try Self.appCode("RootView.swift")
        XCTAssertTrue(
            root.contains("@ObservedObject var celebrationCenter: CelebrationCenter"),
            "RootView does not take the centre from its owner."
        )
        XCTAssertFalse(
            root.contains("= CelebrationCenter()"),
            "RootView builds its own celebration centre, so the App's is not the one the app uses."
        )
    }

    /// Four layers share one centre, so four `.task`s would prune the same list four times and
    /// three of them would race. The root layer is the one that is always mounted.
    func testOnlyTheRootLayerRunsTheExpirySweep() throws {
        let layer = try Self.appCode("Celebrations/CelebrationLayer.swift")
        let task = try XCTUnwrap(
            layer.range(of: ".task(id:"), "The layer never schedules the expiry sweep at all."
        )
        let guardLine = try XCTUnwrap(
            layer.range(of: "guard surface == .root else { return }", range: task.upperBound..<layer.endIndex),
            "Every mounted layer prunes the shared burst list, so four surfaces race on one array."
        )
        let prune = try XCTUnwrap(
            layer.range(of: "center.prune(", range: task.upperBound..<layer.endIndex),
            "The expiry sweep prunes nothing."
        )
        XCTAssertLessThan(
            guardLine.lowerBound, prune.lowerBound,
            "The non-root layers are turned away AFTER the prune has already run."
        )
    }

    // MARK: - Reading the tree

    /// Every `.swift` file in the app target that contains `needle`, with its count. Used for the
    /// two "and nothing else" guards, which are what make the enumerations above load-bearing.
    private static func appTargetOccurrences(of needle: String) throws -> [(file: String, count: Int)] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw CelebrationMountSourceError.unreadable(root.path)
        }
        var found: [(file: String, count: Int)] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let code = text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
                .joined(separator: "\n")
            let count = code.components(separatedBy: needle).count - 1
            if count > 0 { found.append((url.lastPathComponent, count)) }
        }
        return found.flatMap { entry in Array(repeating: entry, count: entry.count) }
    }

    private static func slice(
        in relativePath: String, from opening: String, to closing: String, missing: String
    ) throws -> String {
        let source = try appCode(relativePath)
        guard let start = source.range(of: opening) else {
            throw CelebrationMountSourceError.anchorMissing(relativePath, opening, missing)
        }
        guard let end = source.range(of: closing, range: start.upperBound..<source.endIndex) else {
            throw CelebrationMountSourceError.anchorMissing(relativePath, closing, missing)
        }
        return String(source[start.upperBound..<end.lowerBound])
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw CelebrationMountSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum CelebrationMountSourceError: Error, CustomStringConvertible {
        case unreadable(String)
        case anchorMissing(String, String, String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            case .anchorMissing(let file, let anchor, let why):
                return "\(file) does not contain `\(anchor)`. \(why)"
            }
        }
    }
}
