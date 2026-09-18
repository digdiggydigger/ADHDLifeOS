//
//  CaptureDiscFace.swift
//  ADHD LifeOS
//
//  What the two bottom discs share, spelled ONCE (`F-JournalPencilDisc`, E 2026-09-18). The capture
//  disc had it all inline until the Journal's pencil became its twin: *"use the same glow as the +.
//  So the pair are twins with halos, But with the pencil disc's Background colour gradient
//  direction different."* Two faces that must agree on colours, a halo and a pill curve drift the
//  first time someone tunes one of them, so both read this and `JournalComposeDiscTests` holds the
//  values — including the one difference E asked for, which a later "tidy" would otherwise undo.
//

import SwiftUI

enum CaptureDiscFace {
    /// "Deep field" (E's pick from the 2026-08-30 A/B render round, over an ink FAB): the blue
    /// family survives, but as a CaptureDeep→accent gradient no flat chrome element shares — so the
    /// FAB separates from the tab tint, the CTAs and the Work bars without introducing a new hue.
    /// Both variants' renders live in screenshots/fab-colour-variants/.
    static let colors: [Color] = [Color("CaptureDeep"), Color.accentColor]

    /// Which way the two colours run. The colours are shared; the direction is the one thing the
    /// twins do NOT share.
    struct Direction: Equatable {
        let start: UnitPoint
        let end: UnitPoint

        var gradient: LinearGradient {
            LinearGradient(colors: CaptureDiscFace.colors, startPoint: start, endPoint: end)
        }
    }

    /// The + disc: CaptureDeep at the top, accent at the bottom — as it shipped in 2026-08.
    static let plus = Direction(start: .top, end: .bottom)
    /// The pencil disc, REVERSED by E: *"Can you reverse the DIRECTION that the gradient on the
    /// pencil disc currently points in?"* Accent at the top, CaptureDeep at the bottom.
    static let pencil = Direction(start: .bottom, end: .top)

    /// The motion-blue halo. E's call for the pencil over §5's soft-shadow default, for the same
    /// reason the + has it: it is the capture family's mark, not a depth cue.
    struct Glow: Equatable {
        let opacity: Double
        let radius: CGFloat
        let offsetY: CGFloat
    }

    /// The glow shrinks with the disc — a pill under the full 12pt bloom would still haze the row it
    /// just got out of the way of.
    static func glow(showsPill: Bool) -> Glow {
        showsPill ? Glow(opacity: 0.3, radius: 6, offsetY: 4) : Glow(opacity: 0.5, radius: 12, offsetY: 8)
    }

    /// ASYMMETRIC by E's device verdict (F-PillTune): the shrink keeps the snappy spring because it
    /// must feel tied to the finger, but the regrow — triggered by an UP-scroll rather than a settle
    /// timer (F-PillStay) — is "a slow gradual expanding fade": a long easeOut, no bounce. Read with
    /// the NEW value at re-evaluation, so each direction gets its own curve.
    ///
    /// `nil` under Reduce Motion: the pill is a continuous re-shaping that follows a scroll, the one
    /// case §7.2 leaves to an instant change — the + disc's shipped reading, now the pencil's too.
    static func pillAnimation(showsPill: Bool, reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        return showsPill ? .spring(response: 0.35, dampingFraction: 0.8) : .easeOut(duration: 0.9)
    }
}

extension View {
    /// The halo `CaptureDiscFace.glow` describes, in the accent it has always glowed in.
    func captureDiscHalo(_ glow: CaptureDiscFace.Glow) -> some View {
        shadow(color: Color.accentColor.opacity(glow.opacity), radius: glow.radius, x: 0, y: glow.offsetY)
    }
}
