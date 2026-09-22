//
//  DeleteConfirmationCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: which deletes ask first, and which no longer do.
//
//  Its own file because `SoftDeleteCallSiteTests` had reached SwiftLint's ceilings — a LOCATION
//  split. Everything that file's header says applies verbatim: the failure mode of a soft delete
//  is silence, and no behaviour test builds a view body in the standard run.
//

import XCTest
@testable import ADHD_LifeOS

final class DeleteConfirmationCallSiteTests: XCTestCase {

    /// **E's call after the `apple-design` review, and it is Apple's own rule.**
    /// `alerts.md › Best practices`: *"Avoid displaying alerts for common, undoable actions, even
    /// when they're destructive… In comparison, when people take an uncommon destructive action
    /// that they can't undo, it's important to display an alert."* Both confirms existed BECAUSE
    /// delete was irreversible; as of this block it is not. E was shown the trade-off — one tap
    /// instead of two, against losing the sentence that taught the 30-day window at the moment of
    /// the delete — and chose to drop both.
    ///
    /// **"Delete forever" keeps its confirm**, which is the same rule read the other way: that one
    /// is uncommon and genuinely irreversible, and it is Q10's sanctioned friction.
    func testNeitherUndoableDeleteAsksForConfirmationAnyMore() throws {
        for (file, gate) in [
            ("Tasks/TaskDetailView.swift", "showDeleteConfirmation"),
            ("Capture/CaptureDetailView.swift", "isConfirmingDiscard")
        ] {
            let source = try Self.appCode(file)
            XCTAssertFalse(
                source.contains(gate),
                "\(file) still gates its delete behind a confirmation. Deleting is undoable now —"
                    + " 30 days, plus the capsule — so the dialog is the thing `alerts.md` tells"
                    + " you to avoid, and E dropped it deliberately."
            )
            XCTAssertFalse(
                source.contains("confirmationDialog"),
                "\(file) still presents a confirmation dialog on an undoable delete."
            )
        }
    }

    /// The one confirm that STAYS, and the sentence that is only true there.
    func testDeleteForeverKeepsItsConfirmAndItsWarning() throws {
        let screen = try Self.appCode("RecentlyDeleted/RecentlyDeletedView.swift")
        XCTAssertTrue(
            screen.contains("confirmationDialog"),
            "\"Delete forever\" lost its confirm. It is the one delete in this app that cannot be"
                + " undone, which is exactly when `alerts.md` says to ask."
        )
        XCTAssertTrue(screen.contains("RecentlyDeletedPresentation.DeleteForever.message"))
    }

    /// **One action, one word (E's call, 2026-09-22).** The capture's menu said "Discard", the
    /// capsule said "Deleted" and the destination is "Recently Deleted" — three names for one
    /// thing, and the user had to translate to go looking for it. `writing.md › Best practices`:
    /// *"Build language patterns. Consistency builds familiarity."* "Recently Deleted" is the
    /// anchor, because Photos, Notes and Files all use that exact name, so "Delete" is the word
    /// the other two move to.
    func testTheCaptureDeleteUsesTheSameWordAsItsDestination() throws {
        let source = try Self.appCode("Capture/CaptureDetailView.swift")
        XCTAssertTrue(
            source.contains("Label(\"Delete\", systemImage: \"trash\")"),
            "The capture's menu item does not say \"Delete\", so one action still has two names"
                + " between the menu and the capsule that reports it."
        )
        XCTAssertFalse(
            source.contains("\"Discard\""),
            "\"Discard\" survives on the capture surfaces."
        )
    }

    // MARK: - Reading the tree

    /// Comments stripped, because these files document the very names the assertions look for —
    /// the trap that made `ToolsRecentlyDeletedCallSiteTests` match its own explanation.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw DeleteConfirmationSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum DeleteConfirmationSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from."
            }
        }
    }
}
