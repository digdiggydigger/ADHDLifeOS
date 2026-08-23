//
//  CaptureDetailComponents.swift
//  ADHD LifeOS
//
//  The detail screen's leaf views (design frame B6): the content card, its media banner and notes
//  panel, and the bottom action pair. Split from `CaptureDetailView.swift` so the screen stays
//  inside its length budgets.
//

import SwiftUI

/// B6's media-plus-text card: an edge-to-edge banner when the capture has an image, then the
/// timestamp, the title, a link's source domain, the capture's own words under a "Notes" label,
/// and the AI assessment when one has landed.
struct CaptureDetailContentCard: View {
    let capture: Capture
    let onOpenPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let bannerURL {
                CaptureDetailMediaBanner(
                    url: bannerURL,
                    isPhoto: capture.kind == .photo,
                    onOpen: onOpenPhoto
                )
            }
            VStack(alignment: .leading, spacing: 8) {
                header
                if let domain = CaptureDetailPresentation.sourceDomain(for: capture) {
                    sourceLine(domain)
                }
                if let notes = CaptureRowPresentation.secondaryText(for: capture) {
                    CaptureDetailNotesPanel(text: notes)
                }
                if let assessment = capture.aiAssessment, !assessment.isEmpty {
                    assessmentLine(assessment)
                }
            }
            .padding(16)
        }
        // Clipped to the bento radius so the banner's square corners can't poke past the card's
        // rounded ones — the card itself doesn't clip its content.
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .bentoCard(padding: 0)
    }

    /// The photo itself for a photo capture; the unfurl's thumbnail for a link. Text kinds have no
    /// banner and the card starts at the timestamp.
    private var bannerURL: URL? {
        switch capture.kind {
        case .photo: return capture.photoDisplayURL
        case .link: return capture.linkPreview?.thumbnailURL
        default: return nil
        }
    }

    /// The leading 44pt kind slot is `CaptureRowLeadingSlot`, reused deliberately: it is what
    /// gives a voice capture its playback control on this screen, and it keeps the detail's kind
    /// identity pixel-identical to the row that opened it.
    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            CaptureRowLeadingSlot(capture: capture)
            VStack(alignment: .leading, spacing: 4) {
                Text(CaptureDetailPresentation.timestamp(for: capture.createdAt))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("captureDetailTimestamp")
                Text(CaptureRowPresentation.primaryText(for: capture))
                    .font(.title2.bold())
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("captureDetailTitle")
            }
            .layoutPriority(1)
        }
    }

    /// Tappable when the URL parses — the accent colour is earned by being a real link out.
    @ViewBuilder
    private func sourceLine(_ domain: String) -> some View {
        if let url = CaptureDetailPresentation.sourceURL(for: capture) {
            Link(destination: url) {
                Text(domain)
                    .font(.footnote.weight(.semibold))
            }
            .accessibilityIdentifier("captureDetailSourceDomain")
        }
    }

    private func assessmentLine(_ assessment: String) -> some View {
        Label {
            Text(assessment)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "sparkles")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("captureDetailAIAssessment")
    }
}

/// The edge-to-edge image across the card's top. Only a photo's banner opens the lightbox — a
/// link thumbnail is decoration for a card whose real destination is the source line.
struct CaptureDetailMediaBanner: View {
    let url: URL
    let isPhoto: Bool
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder.overlay(
                        Image(systemName: isPhoto ? "photo" : "link")
                            .foregroundStyle(.secondary)
                    )
                default:
                    placeholder.overlay(ProgressView())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isPhoto)
        .accessibilityLabel(isPhoto ? "Open photo" : "Link preview image")
        .accessibilityIdentifier("captureDetailMediaBanner")
    }

    private var placeholder: some View {
        Rectangle().fill(Color(.tertiarySystemFill))
    }
}

/// B6's inset "Notes" panel — the capture's own words, set apart from the metadata around them.
struct CaptureDetailNotesPanel: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.pageBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("captureDetailNotes")
    }
}

/// B6's bottom pair: the full-width "Make a task" CTA beside the circular archive ("seen")
/// button, with the inheritance promise underneath. A promoted capture swaps the CTA for its
/// status chip, and a capture that is already seen (or promoted) loses the archive button — the
/// undo lives in the overflow menu instead.
struct CaptureDetailActions: View {
    let capture: Capture
    let isArchiving: Bool
    let onMakeTask: () -> Void
    let onArchive: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if capture.processed {
                    CapturePromotedChip()
                        .frame(maxWidth: .infinity)
                } else {
                    Button(action: onMakeTask) {
                        Label("Make a task", systemImage: "checklist")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("captureDetailMakeTaskButton")
                }
                if !capture.processed && capture.seen != true {
                    archiveButton
                }
            }
            if !capture.processed {
                // The one fact worth promising at the moment of promotion, straight from B6.
                Text("The new task inherits this capture's life area and tags.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // 52pt matches B6's circle exactly; it is a control dimension (multiple of 4, over the 44pt
    // floor), not a spacing token.
    private var archiveButton: some View {
        Button(action: onArchive) {
            if isArchiving {
                ProgressView()
                    .frame(width: 52, height: 52)
            } else {
                Image(systemName: "archivebox")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 52, height: 52)
            }
        }
        .background(Color.cardSurface, in: Circle())
        .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 0.5))
        .contentShape(Circle())
        .buttonStyle(.plain)
        .disabled(isArchiving)
        .accessibilityLabel("Mark as seen")
        .accessibilityHint("Moves this capture out of the inbox into the Captures archive")
        .accessibilityIdentifier("captureDetailArchiveButton")
    }
}

#if DEBUG
private struct CaptureDetailComponentsGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CaptureDetailContentCard(
                    capture: Capture(
                        id: UUID(),
                        content: "https://www.swiftpackageindex.com/migration",
                        kind: .link,
                        processed: false,
                        createdAt: Date(),
                        title: "Swift concurrency: migrating at your own pace",
                        status: .inbox,
                        linkPreview: CaptureLinkPreview(
                            url: "https://www.swiftpackageindex.com/migration",
                            title: "Swift concurrency: migrating at your own pace",
                            description: nil,
                            thumbnailURL: nil
                        ),
                        aiAssessment: "Reference material, no action implied."
                    ),
                    onOpenPhoto: {}
                )
                CaptureDetailActions(
                    capture: Capture(id: UUID(), content: "Note", kind: .note, processed: false, createdAt: Date()),
                    isArchiving: false,
                    onMakeTask: {},
                    onArchive: {}
                )
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    CaptureDetailComponentsGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CaptureDetailComponentsGallery()
        .preferredColorScheme(.dark)
}
#endif
