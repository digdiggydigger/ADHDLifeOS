//
//  LinkPasteNormalization.swift
//  ADHD LifeOS
//

import Foundation

/// What the link composer's paste button does to the clipboard before it lands in the URL field
/// (BUG-b6). Clipboards are messy — a URL copied out of a note arrives with its trailing newline,
/// a share-sheet copy with a stray space — and a URL field must never hold invisible whitespace
/// the user can't see but validation trips over.
enum LinkPasteNormalization {
    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
