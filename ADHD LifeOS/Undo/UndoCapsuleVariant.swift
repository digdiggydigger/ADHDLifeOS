//
//  UndoCapsuleVariant.swift
//  ADHD LifeOS
//
//  **TEMPORARY — E's REDESIGN ROUND, 2026-09-20. Delete this file when the round closes.**
//
//  E looked at `F-C1-UndoCapsule` on the phone (eight frames + a 47s recording, RM off; the RM-on
//  pass passed) and sent the shape back with three changes, verbatim: *"Bringing back a second line
//  is smart. I also recommend that we remove the blue chip background colour behind the "Undo"
//  Button and increase the corner radius of the entire UndoCapsule card."*
//
//  All three are E's call. What is NOT settled is the NUMBERS, so this file exists to draw the
//  candidates on the real screen from ONE build — E's standing permission for throwaway renders
//  (round 2b: *"Throwaway Swift renders… The file is deleted after E chooses, and only the images
//  are kept."*).
//
//  **One axis per variant, all against one base.** The height round's four shapes worked because
//  each varied a single thing; a matrix that moves three at once cannot be read as a delta.
//
//  **It cannot leak.** `active` resolves to `.current` — the shipped shape — outside DEBUG and
//  whenever the environment says nothing, so a release build draws exactly what is on `main`.
//

import SwiftUI

/// The candidates for E's three changes, one axis at a time.
enum UndoCapsuleVariant: String, CaseIterable {
    /// The shipped shape: 44pt, one `.footnote` line, the accent chip, radius 12.
    case current
    /// All three changes at once, with the middle radius: two lines reserved, no chip, radius 20.
    case base
    /// `base`, radius 16 — the on-grid step down.
    case radius16
    /// `base`, fully rounded — a true capsule, matching the tab bar's pill and the + disc.
    case radiusFull
    /// `base`, but the second line is allowed rather than reserved, so the card's height follows
    /// the subject. This is the shape the height round rejected FOR THAT REASON; it is drawn again
    /// because E is bringing the second line back and should see the cost restated.
    case upToTwo
    /// `base`, plus the Undo control's own horizontal padding dropped to 0.
    ///
    /// **Found by rendering, not by reasoning.** `undoHorizontalPadding` is 16 and it was padding
    /// the INSIDE of the chip. With the chip gone it is 32pt of invisible dead space either side of
    /// the word, and the frame that proved it shows "Capture three / things on your mi…" still
    /// truncating on the second line. Reclaiming it gives the subject those 32pt back, which is
    /// what E's "second line" was for.
    case roomy
    /// **E'S CHOSEN SHAPE, 2026-09-20.** Fully rounded (E: *"Option C, 'Fully rounded' looks the
    /// best"*), no chip, the Undo control's padding reclaimed, and the second line ALLOWED rather
    /// than reserved — so a short subject keeps the 44pt card E approved in the height round and a
    /// long one grows to ~53pt, staying clear of the 60pt capture disc. E chose the variable height
    /// over a steady 59pt with the disc's own height named as the cost.
    case chosen

    /// **Read once, and only in DEBUG.** A release build can never be a variant, whatever the
    /// environment says — the render switch is the thing that must not ship, not the shapes.
    ///
    /// `launchEnvironment` is the channel that works: a launch ARGUMENT beginning with `-` is
    /// parsed as a UserDefaults key expecting a value and is swallowed, which cost the height round
    /// two render rounds where every variant photographed the default.
    static let active: UndoCapsuleVariant = {
        #if DEBUG
        let raw = ProcessInfo.processInfo.environment["LIFEOS_UNDO_VARIANT"] ?? ""
        return UndoCapsuleVariant(rawValue: raw) ?? .current
        #else
        return .current
        #endif
    }()

    /// The card's corner. `nil` means fully rounded — a `Capsule`, whose radius is half whatever
    /// height the card ends up at, which a fixed number cannot track.
    var cardCornerRadius: CGFloat? {
        switch self {
        case .current:
            return AppSearchRowMetrics.fieldCornerRadius   // 12 — the search row's own
        case .radius16:
            return 16
        case .base, .upToTwo, .roomy:
            return 20
        case .radiusFull, .chosen:
            return nil
        }
    }

    /// The card's shape, resolved. `AnyShape` is iOS 16.0, so this needs no availability gate.
    var cardShape: AnyShape {
        guard let radius = cardCornerRadius else { return AnyShape(Capsule(style: .continuous)) }
        return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// E: *"remove the blue chip background colour behind the "Undo" Button"*. Every candidate but
    /// the reference drops it.
    var drawsUndoChip: Bool { self == .current }

    /// How many lines the subject may take.
    var subjectLineLimit: Int { self == .current ? 1 : 2 }

    /// Whether the second line's space is HELD when the subject does not need it.
    ///
    /// Reserved keeps the card one height whatever the task is called — the property the height
    /// round was protecting when it went to one line (*"the capsule's height depended on the task's
    /// name"*). Not reserved lets a short subject sit in a shorter card.
    var reservesSecondLine: Bool {
        switch self {
        case .current, .upToTwo, .chosen: return false
        case .base, .radius16, .radiusFull, .roomy: return true
        }
    }

    /// What the Undo control pads itself by. 16 is the shipped value and it lived inside the chip.
    var undoHorizontalPadding: CGFloat {
        (self == .roomy || self == .chosen) ? 0 : UndoCapsuleMetrics.undoHorizontalPadding
    }

    /// Stamped onto the capsule's accessibility identifier so a render PROVES which shape it
    /// photographed. The height round's two lost rounds both looked identical to a design that had
    /// not changed; a frame that cannot name itself is not evidence.
    var identifierSuffix: String { self == .current ? "" : "-\(rawValue)" }
}
