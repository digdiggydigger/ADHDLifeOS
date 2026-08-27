//
//  CaptureRowDetailViews.swift
//  ADHD LifeOS
//
//  The parts of the web original's Inbox card the native row was missing (E, 2026-08-20: "not up to
//  the same level"): a per-kind accent, the life-area chip, the quoted note/transcript, the voice
//  pill and the real photo thumbnail. The collapsed row now says what a capture IS without being
//  opened — which is the whole job of a triage list.
//

import SwiftUI

/// The colour and glyph that identify a capture's kind at a glance — the web's coral mic / purple
/// camera / amber note.
///
/// System semantic colours, not new tokens: §4 sanctions adaptive system assets, and inventing hex
/// for four one-off accents would bypass the token layer for no gain. Meaning never rests on the
/// colour — the glyph differs per kind and the caption names it in words (§4).
enum CaptureKindAccent {
    static func color(for kind: CaptureKind) -> Color {
        switch kind {
        case .voice: return .accentColor
        case .photo: return .purple
        case .note: return .orange
        case .link: return .blue
        case .task: return .green
        }
    }
}

/// The life area a capture is filed under, as an inline chip beside the title.
///
/// Absent areas simply omit the chip. An archived one still shows — the capture really is filed
/// there, and hiding it would make the row disagree with the triage picker directly beneath it.
struct CaptureLifeAreaChip: View {
    let lifeArea: LifeArea

    var body: some View {
        HStack(spacing: 4) {
            Text(lifeArea.colour)
                .font(.caption2)
            Text(lifeArea.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.cardSurface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Life area \(lifeArea.name)")
    }
}

/// The capture's own words, quoted. An inset panel rather than another grey line, so a thought you
/// dumped reads as a thought and not as metadata — the web renders it italic inside a white card.
struct CaptureQuotedNote: View {
    let text: String
    var lineLimit: Int?

    var body: some View {
        Text(text)
            .font(.caption)
            .italic()
            .foregroundStyle(.secondary)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.pageBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 0.5)
            )
    }
}

/// The voice pill: this row is something you LISTEN to, said before you tap it.
///
/// The web shows a duration here. `Capture` doesn't persist one, so this says what it can rather
/// than inventing a number — flagged in the build report rather than faked.
struct CaptureVoicePill: View {
    var body: some View {
        Label("Voice recording", systemImage: "waveform")
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color.accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
            .accessibilityLabel("Voice recording")
    }
}

/// The photo, at a size you can actually recognise it at.
///
/// The 44pt leading slot is a type indicator; this is the picture. The web uses ~144×96 for exactly
/// this reason — a photo capture whose only preview is a 44pt square is a capture you have to open
/// to triage, which defeats the list.
struct CapturePhotoPreview: View {
    let url: URL?
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder.overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder.overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 144, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open photo")
        .accessibilityIdentifier("capturePhotoPreview")
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.tertiarySystemFill))
    }
}

/// Tag membership as quiet metadata chips under a meta line — surface-secondary, never a tint,
/// because tags are context rather than identity (the life-area chip owns identity). Value-fed
/// and shared: the inbox's triage cards and the journal's log rows both use it.
/// Overflow scrolls sideways like `TaskDetailChipsRow`; the chips themselves are inert, so
/// VoiceOver reads the strip as one "Tags:" element instead of n bare words.
struct TagChipsRow: View {
    let tags: [Tag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    MomentumChip(
                        text: tag.name,
                        background: Color("CardSurfaceSecondary"),
                        foreground: Color("LabelSecondary")
                    )
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tags: \(tags.map(\.name).joined(separator: ", "))")
    }
}

/// Everything a row says about its capture before you touch it: kind slot, title, life-area chip,
/// the quoted note, the voice pill, the photo. Extracted from `CaptureRowView` — the row was over
/// its type-body budget once this grew from two lines to the web original's full card.
struct CaptureRowSummary<ExpandedLinkContent: View>: View {
    let capture: Capture
    let lifeAreas: [LifeArea]
    /// Already resolved by the caller (`CaptureRowPresentation.tags(for:from:)`) — the summary
    /// never fetches. Empty means no chip strip at all, not an empty strip.
    var tags: [Tag] = []
    /// Named places, for showing WHERE a capture happened. Defaulted empty so surfaces that don't
    /// carry them construct the summary unchanged.
    var places: [Place] = []
    let isExpanded: Bool
    let onOpenPhoto: () -> Void
    /// The rich link card, which only the owning row can build — passed in rather than duplicated.
    @ViewBuilder var expandedLinkContent: () -> ExpandedLinkContent

    private var captionLine: String {
        let caption = CaptureRowPresentation.caption(for: capture)
        guard let place = CapturePlaceLabel.label(for: capture, places: places) else { return caption }
        return "\(caption) · \(place)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CaptureRowLeadingSlot(capture: capture)
            VStack(alignment: .leading, spacing: 4) {
                titleLine
                if isExpanded, capture.kind == .link {
                    expandedLinkContent()
                }
                detail
                // The place rides the existing caption line rather than adding a row of its own:
                // it belongs with "when" and it keeps the row dense. Absent entirely when the
                // capture was made outside every named place (E's call).
                Text(captionLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if !tags.isEmpty {
                    TagChipsRow(tags: tags)
                }
            }
            .layoutPriority(1)
        }
    }

    /// Title, then the life-area chip on its own line.
    ///
    /// Inline beside the title (as the web has it, where flex-wrap saves it) the chip was crushed to
    /// "🌱 G" on a real phone row — the title takes priority, and a capsule that has to compete for
    /// a narrow row loses (seen in-simulator, 2026-08-20). Below the title it always reads, and it
    /// is still visually attached to the thing it labels.
    private var titleLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(CaptureRowPresentation.primaryText(for: capture))
                .lineLimit(isExpanded ? nil : 2)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let lifeArea {
                CaptureLifeAreaChip(lifeArea: lifeArea)
                    .fixedSize()
            }
        }
    }

    /// What the web card showed and ours didn't. Collapsed rows cap the quote at two lines so the
    /// list still scans; expanding lifts the cap.
    @ViewBuilder
    private var detail: some View {
        if let secondary = CaptureRowPresentation.secondaryText(for: capture) {
            CaptureQuotedNote(text: secondary, lineLimit: isExpanded ? nil : 2)
        }
        if capture.kind == .voice {
            CaptureVoicePill()
        }
        if capture.kind == .photo, capture.photoDisplayURL != nil {
            CapturePhotoPreview(url: capture.photoDisplayURL, onOpen: onOpenPhoto)
        }
    }

    private var lifeArea: LifeArea? {
        guard let lifeAreaId = capture.lifeAreaId else { return nil }
        return lifeAreas.first { $0.id == lifeAreaId }
    }
}

#if DEBUG
private struct CaptureRowDetailGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(CaptureKind.allCases, id: \.self) { kind in
                    Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: kind))
                        .foregroundStyle(CaptureKindAccent.color(for: kind))
                        .frame(width: 44, height: 44)
                        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            CaptureLifeAreaChip(
                lifeArea: LifeArea(id: UUID(), name: "Growth", colour: "🌱", sortOrder: 0)
            )
            CaptureQuotedNote(text: "The retro idea about standups — the one where nobody talks first.")
            CaptureVoicePill()
            TagChipsRow(tags: [
                Tag(id: UUID(), name: "errands"),
                Tag(id: UUID(), name: "deep-work"),
                Tag(id: UUID(), name: "waiting-on")
            ])
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    CaptureRowDetailGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CaptureRowDetailGallery()
        .preferredColorScheme(.dark)
}
#endif
