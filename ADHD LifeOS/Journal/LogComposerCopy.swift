//
//  LogComposerCopy.swift
//  ADHD LifeOS
//

import Foundation

/// The v3 entry composer's voice (the S1 pattern applied to the journal): say what each type
/// means instead of assuming the Log/Journal split is obvious, and say the append-only rule out
/// loud before the save, not after.
enum LogComposerCopy {
    static let guidance = "One honest line about now is enough."
    static let footer = "Entries are append-only — saved means saved."

    static func explainer(for type: LogType) -> String {
        switch type {
        case .log: return "A quick line, saved as-is — no questions asked."
        case .journal: return "A fuller entry — energy and mood ride along."
        }
    }
}
