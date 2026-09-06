//
//  UITestAutofill.swift
//  ADHD LifeOSUITests
//
//  The tab-root "not hittable" defect's actual cause, and its fix (2026-09-06). Its own file
//  because `UITestSession` sits near the 400-line ceiling — the same reason `UITestTabs` and
//  `UITestScrolling` split out.
//

import XCTest

extension UITestSession {
    /// Clears iOS's own AutoFill "Save Password?" sheet if it is interposed over the app.
    /// Returns whether one was dismissed.
    ///
    /// This prompt was the whole of the on-screen "exists at a sane frame, never hittable"
    /// defect (`UIFullRun.xcresult`, 2026-09-06): every journey signs in with fresh random
    /// credentials, so iOS offers to save the password — on its own schedule, observed arriving
    /// more than 15 seconds after sign-in, well past any one-shot wait. While its overlay is up,
    /// hit-tests die across the WHOLE app window, even at points far outside the visible sheet,
    /// which is why the failing set shuffled with timing rather than with the tree and why an
    /// erased simulator reproduced it best (fresh keychain, every password newly saveable).
    ///
    /// **Where it lives in the element tree, learned the hard way twice:** it is a SHEET, not an
    /// alert — so the journeys' `app.alerts` wait never matched it — and it is a REMOTE VIEW
    /// bridged into the APP's own tree (its elements carry another process's pid but hang off
    /// the app's window). SpringBoard's own hierarchy does not contain it, so a first version of
    /// this sweep aimed at `springboard.sheets` matched nothing and the defect sailed through
    /// unswept — verified against both hierarchy attachments in the same failure dump. The app's
    /// tree is the one place it is addressable.
    ///
    /// The retrying helpers call this immediately before each tap attempt, where a standing
    /// prompt would otherwise surface as a raised hittability failure that ends the test. When
    /// no sheet is up this is one existence query — cheap enough for a retry loop. A residual
    /// race remains (the prompt can land between the sweep and the tap); the sweep narrows the
    /// window from iOS's whole schedule to milliseconds.
    ///
    /// "Not Now", never "Save": saving would leave a credential in the simulator keychain that
    /// an erased sim won't have, making runs diverge for reasons a later session couldn't
    /// reconstruct. The label match is broad ("Save Password?" today, "Update Password?" if a
    /// saved credential ever drifts) but anchored to a password sheet with a "Not Now" button,
    /// and the app presents no password-labelled sheet of its own it could eat.
    @MainActor
    @discardableResult
    static func dismissSystemPasswordPromptIfPresent() -> Bool {
        let sheet = XCUIApplication().sheets.matching(
            NSPredicate(format: "label CONTAINS[c] 'password'")
        ).firstMatch
        guard sheet.exists else { return false }
        let notNow = sheet.buttons["Not Now"]
        guard notNow.waitForExistence(timeout: 2) else { return false }
        notNow.tap()
        print("[AUTOFILL] dismissed the system password prompt")
        return true
    }
}
