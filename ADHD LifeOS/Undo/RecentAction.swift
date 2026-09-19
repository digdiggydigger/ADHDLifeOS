//
//  RecentAction.swift
//  ADHD LifeOS
//
//  `F-C1-UndoCapsule` — the ADHD UX audit's arc C, "Nothing lost". E's round 1: *"Every close (the
//  circle, a full swipe, Today's hero) shows the same undo, which stays until the user's next
//  action."* E's round 2, verbatim: *"'Option 1.' But the "bottom bar" Needs A visual overhaul"* —
//  Option 1 being ONE bottom bar everywhere. E's round 2b chose its shape: **A · Capsule in the
//  disc row** (board `54`).
//
//  **This retires "closing is one-way"** (F-V3-Tasks-rebuild, E's addendum) as far as the undo
//  moment goes. The eight comment sites that carried it are annotated rather than deleted, per the
//  house convention — `F-JournalDoorUnpinned`'s stale-comment annotation.
//
//  **What a recorded action carries, and what it deliberately does not.** The WORDS and the way
//  BACK, and nothing else: no client, no id of the thing it touched, no knowledge of which service
//  owns it. The site supplies the reversal as a closure because the site is the only place that
//  knows its own service — which is what lets five unrelated surfaces share one slot without this
//  model learning five data layers.
//

import Foundation

/// What just happened, in the words the capsule names it with.
///
/// One case per close surface E named, plus the three reversible triage verbs the Capture Inbox
/// already had. **"Task it" is still absent, and that is not an oversight** — it opens the promote
/// sheet, a flow the user completes rather than an instant, and the task it creates may already
/// have been edited (`CaptureTriageAction`'s own note, carried here unchanged).
enum RecentActionKind: Equatable, Sendable {
    /// A task closed from the tap-circle, a full swipe, Today's hero, task detail or a life area's
    /// tick — five surfaces, one word, because it is one action wherever it happened.
    case taskClosed
    /// A nudge's "Done for now" (E's Step 0 answer 3: *"Yes, a nudge dismiss gets the capsule"*).
    case nudgeDismissed
    /// `areaLabel` is the area's own "💼 Work", resolved by the SITE at the moment of recording.
    /// Resolved there rather than held as an id so a deleted area degrades to the bare verb
    /// instead of the capsule quoting a raw UUID at the user.
    case captureSorted(areaLabel: String?)
    case captureSkipped
    case captureJournalled
}

extension RecentActionKind {
    /// The capsule's first line: what happened, in one verb.
    ///
    /// **Shorter than the retired inbox bar's sentence, and deliberately.** That bar said
    /// "Skipped — it'll come back round" because it had one line to work with; the capsule carries
    /// the SUBJECT underneath, so the reassurance tail would only push the card taller for no new
    /// information. The reassurance is arc A's to place if E wants it back.
    var verb: String {
        switch self {
        case .taskClosed:
            return "Closed"
        case .nudgeDismissed:
            return "Done for now"
        case .captureSorted(let areaLabel):
            guard let areaLabel else { return "Sorted" }
            return "Sorted to \(areaLabel)"
        case .captureSkipped:
            return "Skipped"
        case .captureJournalled:
            return "Journalled"
        }
    }

    /// The glyph beside the verb. The two completions share the app's completion mark; the three
    /// triage verbs each carry the glyph of where the capture went.
    var systemImage: String {
        switch self {
        case .taskClosed, .nudgeDismissed:
            return "checkmark.circle.fill"
        case .captureSorted:
            return "tray.full.fill"
        case .captureSkipped:
            return "arrow.triangle.2.circlepath"
        case .captureJournalled:
            return "book.closed.fill"
        }
    }

    /// A skip is the one kind that is not a completion and must not read as one.
    var glyphTint: RecentActionGlyphTint {
        switch self {
        case .taskClosed, .nudgeDismissed:
            return .go
        case .captureSorted, .captureJournalled:
            return .accent
        case .captureSkipped:
            return .secondary
        }
    }
}

/// The three tints the glyph can take, as a pure value so the rule above is testable without a
/// rendered view. `UndoCapsule` maps each to its token; nothing here names a colour.
enum RecentActionGlyphTint: Equatable, Sendable {
    case go
    case accent
    case secondary
}

/// One reversible thing the user just did, and the way back.
///
/// `id` is fresh per recording rather than derived from the subject, because the capsule keys its
/// arrival on this value: two closes of tasks that happen to share a title are two separate
/// events, and a capsule that thought otherwise would slide the second one in silently.
struct RecentAction: Identifiable {
    let id: UUID
    let kind: RecentActionKind
    /// What it happened TO — a task's title, a capture's text, a nudge's label. Named by the site,
    /// because only the site knows which of its models is the thing the user was looking at.
    let subject: String
    /// The reversal, supplied by the site. `async` because every one of them is a network write.
    ///
    /// **It answers whether anything was actually reversed, and that is load-bearing.** The Capture
    /// Inbox has always kept its offer standing when an undo could not land — *"nothing happened,
    /// so the offer still stands"*, and for "Journal it" that is a safety argument, not a nicety:
    /// a failed restore must leave the journal entry alone, because it is the only copy of the
    /// thought left. `false` puts the capsule back rather than leaving the user with a failure and
    /// no way to retry.
    let undo: () async -> Bool

    init(id: UUID = UUID(), kind: RecentActionKind, subject: String, undo: @escaping () async -> Bool) {
        self.id = id
        self.kind = kind
        self.subject = subject
        self.undo = undo
    }
}

/// Identity, not content: a closure cannot be compared, and two recordings are the same event only
/// if they are literally the same recording.
extension RecentAction: Equatable {
    static func == (lhs: RecentAction, rhs: RecentAction) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind && lhs.subject == rhs.subject
    }
}
