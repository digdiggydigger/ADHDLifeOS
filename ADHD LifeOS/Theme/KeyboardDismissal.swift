//
//  KeyboardDismissal.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

extension View {
    /// BUG-b5 (E's checklist, 2026-08-26): the keyboard must never be a trap. Scrolling drags it
    /// away and a Done button rides above it; the button resigns whatever is focused through the
    /// responder chain, so no screen needs its own FocusState just to close a keyboard.
    ///
    /// Apply ONCE per presentation tree: RootView covers the tabs and everything pushed inside
    /// them, and each sheet/cover whose content takes text wraps its own root — keyboard toolbars
    /// do not cross presentation boundaries, and a nested second application would show two Done
    /// buttons (SwiftUI merges keyboard toolbars from every level of the hierarchy).
    func keyboardDismissal() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
    }
}
