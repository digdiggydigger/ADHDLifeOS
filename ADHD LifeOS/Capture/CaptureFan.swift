//
//  CaptureFan.swift
//  ADHD LifeOS
//

import Foundation

/// `fullScreenCover(item:)` needs an identity; the raw value is stable and unique.
extension CaptureKind: Identifiable {
    var id: String { rawValue }
}

/// The capture fan's pure layout table (F-V3-Capture): v3's bowed arc of five discs leaning out
/// of the FAB — 78pt centres, a gentle bow (the middle disc farthest from the edge), and the
/// stagger REVERSED against distance so the nearest, most-used disc (Task) lands first. Each
/// kind carries its identity hue and its glyph; positions are centre offsets from the
/// bottom-trailing corner of the safe area.
enum CaptureFan {
    struct Slot: Equatable {
        let kind: CaptureKind
        let fromTrailing: CGFloat
        let fromBottom: CGFloat
        let appearanceDelay: Double
        let fillAssetName: String
        let onAssetName: String
        let systemImage: String
        let label: String
    }

    /// Top of the arc first (Note) down to the nearest disc (Task) — v3's draw order.
    static let slots: [Slot] = [
        Slot(kind: .note, fromTrailing: 57, fromBottom: 519, appearanceDelay: 0.16,
             fillAssetName: "AccentColor", onAssetName: "OnAreaWork",
             systemImage: "square.and.pencil", label: "Note"),
        Slot(kind: .voice, fromTrailing: 70, fromBottom: 441, appearanceDelay: 0.12,
             fillAssetName: "AreaGrowthVivid", onAssetName: "OnAreaGrowth",
             systemImage: "waveform", label: "Voice"),
        Slot(kind: .photo, fromTrailing: 75, fromBottom: 363, appearanceDelay: 0.08,
             fillAssetName: "AreaHealthVivid", onAssetName: "OnAreaHealth",
             systemImage: "camera.fill", label: "Photo"),
        Slot(kind: .link, fromTrailing: 70, fromBottom: 285, appearanceDelay: 0.04,
             fillAssetName: "AreaAdminVivid", onAssetName: "OnAreaAdmin",
             systemImage: "link", label: "Link"),
        Slot(kind: .task, fromTrailing: 57, fromBottom: 207, appearanceDelay: 0,
             fillAssetName: "StateGoVivid", onAssetName: "OnStateGo",
             systemImage: "checkmark.circle.fill", label: "Task")
    ]

    /// The landscape fan (F-FanLandscape, E's 2026-08-31 call: "change the direction of the fan
    /// to horizontal pointing to the left"). The portrait arc dies sideways — 519pt of
    /// `fromBottom` puts Note and Voice above a 402pt screen, which is how the landscape sweep
    /// found the composers unreachable. This is the SAME arc rotated onto the horizontal: every
    /// number is the portrait table's with its axes swapped, so the 78pt centres, the bow and
    /// the reverse-frequency stagger survive the rotation, and Task stays nearest the FAB.
    static let horizontalSlots: [Slot] = slots.map { slot in
        Slot(
            kind: slot.kind,
            fromTrailing: slot.fromBottom,
            fromBottom: slot.fromTrailing,
            appearanceDelay: slot.appearanceDelay,
            fillAssetName: slot.fillAssetName,
            onAssetName: slot.onAssetName,
            systemImage: slot.systemImage,
            label: slot.label
        )
    }

    static func slot(for kind: CaptureKind) -> Slot {
        slots.first { $0.kind == kind } ?? slots[0]
    }
}

/// The composer's per-kind voice, straight from the v3 file's CAP table.
enum CaptureComposerCopy {
    static func title(for kind: CaptureKind) -> String {
        switch kind {
        case .note: return "Note"
        case .voice: return "Voice note"
        case .photo: return "Photo"
        case .link: return "Link"
        case .task: return "Task"
        }
    }

    static func hint(for kind: CaptureKind) -> String {
        switch kind {
        case .note: return "Get it out of your head. You can decide what it is later."
        case .voice: return "Say it all — stop when you're done."
        case .photo: return "A whiteboard, a letter, a shelf you keep meaning to fix."
        case .link: return "Paste it in. You can decide what it's for later."
        case .task: return "You already know this is a task. Give it an effort and it lands in Today."
        }
    }

    static func footer(for kind: CaptureKind) -> String {
        switch kind {
        case .note, .photo, .link:
            return "Saves to your inbox — nothing gets scheduled yet."
        case .voice:
            return "Audio and transcript both go to your inbox."
        case .task:
            return "Skips the inbox — this one goes straight to your list."
        }
    }

    static func ctaLabel(for kind: CaptureKind) -> String {
        switch kind {
        case .note: return "Save to inbox"
        case .voice: return "Save recording"
        case .photo: return "Save photo"
        case .link: return "Save link"
        case .task: return "Add to Today"
        }
    }
}
