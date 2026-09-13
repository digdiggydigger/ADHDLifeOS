//
//  CelebrationProbeCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-Surfaces`: the two things about the probe that are decided in SOURCE rather
//  than in behaviour, and that every behavioural test in the block would keep passing without.
//
//  **One: the app must get the REAL probe.** Every test injects one, and the centre's default is the
//  only thing standing between the app and a permanently clear answer. Swapped for
//  `NothingPresentedProbe` — the obvious thing to reach for while debugging — the whole block stops
//  working and not one other test goes red.
//
//  **Two: the simple form E chose is only safe while the claim behind it holds.** The centre
//  consults the probe ONLY when `frontmost` is `.root`, because a surface with its own layer draws
//  perfectly well and would otherwise be held behind itself. That is sound exactly as long as none
//  of those surfaces presents a sheet of its own — which is true today, and is a fact about the
//  tree rather than a rule anyone wrote down. So it is written down here.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationProbeCallSiteTests: XCTestCase {

    /// The centre's default. Read as source because the property is private, and because what this
    /// guards against is someone editing this exact line.
    func testTheCentreDefaultsToTheRealKeyWindowProbe() throws {
        let source = try Self.flattened("Celebrations/CelebrationCenter.swift")
        XCTAssertTrue(
            source.contains("probe: PresentationProbing = KeyWindowPresentationProbe()"),
            "The app's centre no longer walks the key window, so no sheet is ever detected."
        )
        XCTAssertFalse(
            source.contains("NothingPresentedProbe"),
            "The inert probe reached the app: every celebration behind a sheet is invisible again."
        )
    }

    /// The probe is read only from `.root`, and this is why that is enough.
    func testTheProbeIsOnlyConsultedFromTheRootSurface() throws {
        let source = try Self.flattened("Celebrations/CelebrationCenter.swift")
        XCTAssertTrue(
            source.contains("guard frontmost == .root else { return false }"),
            "Without this the routine cover, the search surface and the promote sheet are "
                + "themselves presented controllers, so the probe holds what they could have drawn."
        )
    }

    /// Every file that can be on screen as one of the three surfaces with its own layer. A sheet
    /// presented from any of them would sit above that layer with nothing watching for it.
    private static let surfacesWithTheirOwnLayer = [
        "Places/PlaceRoutineScreen.swift",
        "Places/PlaceRoutineScreen+Opening.swift",
        "Places/PlaceRoutineScreenRows.swift",
        "Places/PlaceRoutineScreenSupport.swift",
        "Places/PlaceRoutineCompletedCard.swift",
        "Places/PlaceRoutineCongratulationView.swift",
        "Tasks/TaskSearchSurface.swift",
        "Capture/CapturePromoteSheet.swift"
    ]

    func testNoSurfaceWithItsOwnLayerPresentsASheetOfItsOwn() throws {
        for file in Self.surfacesWithTheirOwnLayer {
            let source = try Self.flattened(file)
            for presenter in [".sheet(", ".fullScreenCover("] {
                XCTAssertFalse(
                    source.contains(presenter),
                    "\(file) presents \(presenter), so `frontmost` is no longer `.root` when it is "
                        + "up and the probe is not consulted — a celebration draws underneath it. "
                        + "Either track that presentation, or move to the depth-reconciling form."
                )
            }
        }
    }

    // MARK: - Source

    /// The file on one line, comments dropped — `CelebrationMountCallSiteTests`' reader, so an
    /// anchor does not have to know how a call was wrapped or what a comment mentions in passing.
    private static func flattened(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ProbeSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.hasPrefix("//") }
            .joined(separator: " ")
    }

    private enum ProbeSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from."
            }
        }
    }
}
