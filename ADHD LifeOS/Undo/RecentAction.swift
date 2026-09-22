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
    /// **`F-C2-DraftsToInbox`: text a composer was closed on, filed rather than lost.** E, round
    /// 2: *"A composer closed with text files it into the Capture Inbox as a note. A bar, 'Kept in
    /// your inbox · Reopen', stays until the next action."*
    ///
    /// **The one kind whose control does not reverse anything** — see `actionLabel`. The draft
    /// stays filed and the capsule takes the user TO it (E's Step 0 answer 1: *"Open it in the
    /// inbox"*), which is why this case is what made the capsule's action a property of the kind
    /// rather than a hard-coded word.
    case draftKeptInInbox
    /// **`F-C3-RecentlyDeleted`: a task deleted from its detail screen.** E's Step 0 answer 2:
    /// *"Yes, show the capsule too"* — the capsule at the moment of the delete, on top of the
    /// persistent 30-day list.
    ///
    /// **Its Undo is a RESTORE, not a re-creation**, which is what the soft delete buys: the
    /// document never left, so undoing puts back the same task with its tags, its notes and its
    /// history rather than a new one wearing the same title.
    case taskDeleted
    /// The same for a capture discarded from triage or from capture detail.
    ///
    /// **Two cases rather than one `itemDeleted`, and the header arrow is why.** The two differ
    /// in nothing the capsule draws — same verb, same glyph, same word on the control — but the
    /// Capture Inbox's header ↶ offers a second route to the SAME undo, and it must offer it for
    /// a capture and never for a task. One case could not tell them apart.
    case captureDeleted
    /// **`F-C4-TagsRecentlyDeleted`: a tag deleted from the Tag Editor.** E's call, 2026-09-22,
    /// asked as the third instance of the same question: drop the confirm, add the capsule.
    ///
    /// **It draws identically to the other two deletes, and it is still its own case** — for the
    /// reason `captureDeleted` gives one comment up. A kind names WHAT happened, and the exhaustive
    /// switch in `CaptureInboxUndoSections` is where that matters: a tag delete must never light
    /// the Capture Inbox header's second ↶, and one shared case could not say so.
    ///
    /// **Its Undo carries more weight than a task's.** A tag delete's effect is almost entirely
    /// offscreen — chips vanishing from tasks and captures the user is not looking at — which is
    /// `undo-and-redo.md`'s *"it's crucial to highlight the result… to keep people from thinking
    /// that the action had no effect."* Without this, the whole visible consequence is a row
    /// leaving a list in Settings.
    case tagDeleted
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
        case .draftKeptInInbox:
            return "Kept in your inbox"
        case .taskDeleted, .captureDeleted, .tagDeleted:
            // **"Deleted", not "Task deleted"** — E's Step 0 answer 2 named the capsule as
            // *"Task deleted · Undo"*, but the capsule draws the SUBJECT underneath the verb, so
            // the noun is already on screen one line down. `taskClosed` reads "Closed" for the
            // same reason; putting the type in the verb here would be the only kind that
            // repeated what the line below it says.
            return "Deleted"
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
        case .draftKeptInInbox:
            return "tray.and.arrow.down.fill"
        case .taskDeleted, .captureDeleted, .tagDeleted:
            // The glyph of WHERE it went, the rule the three triage verbs follow — and where it
            // went is Recently Deleted, whose own door on Tools wears this glyph.
            return "trash.fill"
        }
    }

    /// A skip is the one kind that is not a completion and must not read as one.
    var glyphTint: RecentActionGlyphTint {
        switch self {
        case .taskClosed, .nudgeDismissed:
            return .completion
        case .captureSorted, .captureJournalled, .draftKeptInInbox:
            return .accent
        case .captureSkipped, .taskDeleted, .captureDeleted, .tagDeleted:
            // **A delete is neither a completion nor a destination.** The two `.completion` kinds
            // are things the user FINISHED and the three `.accent` ones are places a capture
            // WENT; a soft delete is an item put out of sight. Dressing that as an achievement
            // would be round 8's "progress, never debt" principle inverted — so it takes the
            // quiet tint a skip already wears.
            return .secondary
        }
    }

    /// The word on the capsule's control.
    ///
    /// **Five kinds reverse something and say so; one does not.** A filed draft is KEPT — the
    /// capsule takes the user to it rather than unfiling it — so labelling that control "Undo"
    /// would promise to take back something the app then holds on to. `buttons.md › Content` asks
    /// for a label that says what happens.
    ///
    /// **"Undo" is load-bearing for the five, beyond the copy.** `SignedInJourneyUITests`
    /// addresses this control as `app.buttons["Undo"]`, and UI tests are skipped in the standard
    /// run — so rewording any of them breaks that journey with a green suite and a green build,
    /// which is exactly how `F-C1` shipped it broken once.
    var actionLabel: String {
        switch self {
        case .taskClosed, .nudgeDismissed, .captureSorted, .captureSkipped, .captureJournalled,
             .taskDeleted, .captureDeleted, .tagDeleted:
            return "Undo"
        case .draftKeptInInbox:
            return "Reopen"
        }
    }

    /// The glyph beside that word. It follows the promise: a `uturn` arrow beside "Reopen" would
    /// draw the undo the word declines to offer.
    var actionSystemImage: String {
        switch self {
        case .taskClosed, .nudgeDismissed, .captureSorted, .captureSkipped, .captureJournalled,
             .taskDeleted, .captureDeleted, .tagDeleted:
            return "arrow.uturn.backward"
        case .draftKeptInInbox:
            return "arrow.up.forward.square"
        }
    }
}

/// The three tints the glyph can take, as a pure value so the rule above is testable without a
/// rendered view. `UndoCapsule` maps each to its token; nothing here names a colour.
enum RecentActionGlyphTint: Equatable, Sendable {
    /// The completion green — `StateGo`, the token the app's own tick already wears.
    case completion
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
    /// The action the capsule offers, supplied by the site. `async` because every one of them
    /// reaches the network — a write for the five reversals, a read for `draftKeptInInbox`'s
    /// Reopen.
    ///
    /// **`F-C2-DraftsToInbox` broadened what this means without changing its contract.** It is no
    /// longer always an UNDO: for a filed draft it navigates to the capture instead, and `true`
    /// then means "the user was taken there" rather than "the write was reversed". The property
    /// keeps its name because the `Bool` still answers the only question the capsule asks — did the
    /// offered action land — and every caller that returns `false` still gets the offer back.
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

extension RecentAction {
    /// What VoiceOver is told when the capsule arrives.
    ///
    /// **Why an announcement at all** — `voiceover.md › Best practices`: *"Inform VoiceOver when
    /// visible content or layout changes occur… It's crucial to report visible changes so VoiceOver
    /// and other assistive technologies can help people update their understanding of the
    /// content."* The capsule appears at the very END of the screen's element order, below the tab
    /// bar's row, and on Tasks it takes the search row's place. A sighted user sees both changes at
    /// the moment they close a task; without this, a VoiceOver user is given no sign that an undo
    /// exists at all, and the one affordance this whole block adds is invisible to them.
    ///
    /// It names the same two things the capsule draws, then says what is on offer — Apple's
    /// *"help people predict the results of undoing"* (`undo-and-redo.md › Best practices`) applied
    /// to a surface that has no shake gesture and no Edit menu.
    var accessibilityAnnouncement: String {
        "\(kind.verb). \(subject). \(kind.actionLabel) available."
    }
}

/// Identity, not content: a closure cannot be compared, and two recordings are the same event only
/// if they are literally the same recording.
extension RecentAction: Equatable {
    static func == (lhs: RecentAction, rhs: RecentAction) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind && lhs.subject == rhs.subject
    }
}
