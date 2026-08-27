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
    /// Named places, for the "where" beside the timestamp. Defaulted so the preview and any
    /// surface without them construct this unchanged.
    var places: [Place] = []
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
                if let transcript = CaptureDetailPresentation.transcript(for: capture) {
                    // The transcript at reading size, labelled — never squeezed into a headline.
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transcript")
                            .sectionLabel()
                            .foregroundStyle(.secondary)
                        Text(transcript)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .accessibilityIdentifier("captureDetailTranscript")
                } else if let quote = CaptureRowPresentation.secondaryText(for: capture) {
                    CaptureQuotedNote(text: quote)
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

    /// "When", then "where" when there was a named one — the same pairing the rows use, so the
    /// detail says the same thing in the same order as the row that opened it.
    private var timestampLine: String {
        let stamp = CaptureDetailPresentation.timestamp(for: capture.createdAt)
        guard let place = CapturePlaceLabel.label(for: capture, places: places) else { return stamp }
        return "\(stamp) · \(place)"
    }

    /// The leading 44pt kind slot is `CaptureRowLeadingSlot`, reused deliberately: it is what
    /// gives a voice capture its playback control on this screen, and it keeps the detail's kind
    /// identity pixel-identical to the row that opened it.
    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            CaptureRowLeadingSlot(capture: capture)
            VStack(alignment: .leading, spacing: 4) {
                Text(timestampLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("captureDetailTimestamp")
                Text(CaptureDetailPresentation.headline(for: capture))
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

/// B6's "Notes" panel, now the user's own annotation — editable free text on any capture kind,
/// because a photo, voice memo or link has its main text slot already taken by the caption,
/// transcript or URL. The capture's own words render separately as an unlabeled quote in the
/// content card above.
struct CaptureDetailNotesEditor: View {
    /// Returns the server's updated capture, or `nil` on failure (the error surfaces through the
    /// service's `triageErrorMessage`, rendered in the Filed-in card below).
    let onSave: (String) async -> Capture?

    @State private var text: String
    /// What the server last accepted — the Save button only appears while the field differs.
    @State private var savedText: String
    @State private var isSaving = false

    init(capture: Capture, onSave: @escaping (String) async -> Capture?) {
        self.onSave = onSave
        _text = State(initialValue: capture.notes ?? "")
        _savedText = State(initialValue: capture.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .sectionLabel()
                .foregroundStyle(.secondary)
            TextField("Add a note to this capture", text: $text, axis: .vertical)
                .lineLimit(2...6)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("captureDetailNotesField")
            if isDirty {
                Button {
                    Haptics.play(.solid)
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.secondary)
                    } else {
                        Text(trimmed.isEmpty ? "Clear note" : "Save note")
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(isSaving)
                .accessibilityIdentifier("captureDetailNotesSaveButton")
            }
        }
        .bentoCard()
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDirty: Bool {
        trimmed != savedText
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        if let updated = await onSave(text) {
            savedText = updated.notes ?? ""
            text = savedText
        }
    }
}

/// B6's bottom pair: the full-width "Make a task" CTA beside the circular **Sorted** button,
/// with the inheritance promise underneath. A promoted capture swaps the CTA for its status chip,
/// and a capture that is already sorted (or promoted) loses the Sorted button — the way back
/// lives in the overflow menu instead.
///
/// Sorted here obeys the same requirement as Sorted on the triage card: it cannot fire without a
/// life area (`CaptureDetailPresentation.canSort`). It used to be an `archivebox` that wrote the
/// same state with no requirement at all — see A3 there.
struct CaptureDetailActions: View {
    let capture: Capture
    /// Whether an area has been chosen in the Filed-in card above. The button is present but
    /// unavailable without one, so the missing decision is visible rather than the exit absent.
    let canSort: Bool
    let isSorting: Bool
    let onMakeTask: () -> Void
    let onSort: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if capture.processed {
                    CapturePromotedChip()
                        .frame(maxWidth: .infinity)
                } else {
                    Button {
                        Haptics.play(.success)
                        onMakeTask()
                    } label: {
                        Label("Make a task", systemImage: "checklist")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("captureDetailMakeTaskButton")
                }
                if !capture.processed && capture.seen != true {
                    sortedButton
                }
            }
            if !capture.processed {
                // The one fact worth promising at the moment of promotion, straight from B6.
                Text("The new task inherits this capture's life area, tags and notes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // 52pt matches B6's circle exactly; it is a control dimension (multiple of 4, over the 44pt
    // floor), not a spacing token.
    private var sortedButton: some View {
        Button {
            Haptics.play(.solid)
            onSort()
        } label: {
            if isSorting {
                ProgressView()
                    .frame(width: 52, height: 52)
            } else {
                // The triage card's glyph, deliberately: one verb, one mark. `archivebox` said
                // "filed away" for a state the rest of the app calls Sorted.
                Image(systemName: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canSort ? Color("StateGo") : Color.secondary)
                    .frame(width: 52, height: 52)
            }
        }
        .background(Color.cardSurface, in: Circle())
        .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 0.5))
        .contentShape(Circle())
        .buttonStyle(.plain)
        .disabled(isSorting || !canSort)
        .accessibilityLabel("Sorted")
        .accessibilityHint(CaptureDetailPresentation.sortHint(canSort: canSort))
        .accessibilityIdentifier("captureDetailSortedButton")
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
                CaptureDetailNotesEditor(
                    capture: Capture(
                        id: UUID(), content: "Note", kind: .note, processed: false, createdAt: Date(),
                        notes: "Read before the Thursday architecture review."
                    ),
                    onSave: { _ in nil }
                )
                // Both faces of Sorted, side by side: unavailable until an area is chosen, then
                // live — the same pairing `SortedButtonStyle` renders on the triage card.
                CaptureDetailActions(
                    capture: Capture(id: UUID(), content: "Note", kind: .note, processed: false, createdAt: Date()),
                    canSort: false,
                    isSorting: false,
                    onMakeTask: {},
                    onSort: {}
                )
                CaptureDetailActions(
                    capture: Capture(id: UUID(), content: "Note", kind: .note, processed: false, createdAt: Date()),
                    canSort: true,
                    isSorting: false,
                    onMakeTask: {},
                    onSort: {}
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
