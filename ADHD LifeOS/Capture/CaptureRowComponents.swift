//
//  CaptureRowComponents.swift
//  ADHD LifeOS
//
//  The Inbox row's leaf views and its two haptic modifiers, split out of `CaptureRowView.swift` in
//  the 2026-08-20 Inbox design pass so that file fits its length budget. Moved verbatim — none of
//  this changed, it just stopped living in the same file as the row.
//

import SwiftUI
import UIKit

/// The Inbox promote form's primary action, extracted so its in-flight `@State` lives here rather
/// than swelling `CaptureRowView`. Full-width filled `PrimaryActionButtonStyle` (§3/§5); while a
/// promote is in flight the label becomes a progress indicator and the button disables, so a second
/// tap is a no-op at the UI layer (the service's in-flight guard is the concurrency backstop). A
/// successful create fires an `#available`-gated haptic; a failure does not.
struct CreateTaskButton: View {
    let lifeAreaId: UUID?
    let priority: TaskPriority
    let dueDate: Date?
    let onCreateTask: (UUID?, TaskPriority, Date?) async -> Bool

    @State private var isCreatingTask = false
    @State private var successHapticTrigger = false

    var body: some View {
        Button {
            Task { await create() }
        } label: {
            if isCreatingTask {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.secondary)
                    Text("Creating Task…")
                }
            } else {
                Text("Create Task")
            }
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(isCreatingTask)
        .haptic(.success, trigger: successHapticTrigger)
        .accessibilityIdentifier("captureCreateTaskButton")
    }

    private func create() async {
        isCreatingTask = true
        let succeeded = await onCreateTask(lifeAreaId, priority, dueDate)
        isCreatingTask = false
        if succeeded {
            successHapticTrigger.toggle()
        }
    }
}

/// The single, always-present 44×44 leading element every collapsed row gets. Extracted into its
/// own view so `CaptureRowView` stays within its type-body budget. Voice rows keep their playback
/// control; link rows with a landed preview thumbnail render it; every other kind gets a centred
/// SF Symbol placeholder in a matching 10pt-radius tile.
///
/// Photo rows deliberately show the GLYPH here, not the picture: the row already renders the photo
/// at a size you can actually see it (`CapturePhotoPreview`), and putting it in both places printed
/// the same image twice (E's inbox, 2026-08-20). The web original does the same — a purple camera
/// in the slot, the photo once, large.
struct CaptureRowLeadingSlot: View {
    let capture: Capture

    var body: some View {
        switch capture.kind {
        case .voice:
            VoicePlaybackButton(url: capture.mediaURL)
        case .link where capture.linkPreview?.thumbnailURL != nil:
            linkThumbnail
        default:
            glyphSlot
        }
    }

    /// Colour-coded per kind, like the web's coral mic / purple camera / amber note — a uniform grey
    /// tile made every row look identical in the one list whose whole job is telling them apart.
    /// The glyph still differs per kind, so nothing is conveyed by colour alone (§4).
    private var glyphSlot: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(CaptureKindAccent.color(for: capture.kind).opacity(0.12))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                    .foregroundStyle(CaptureKindAccent.color(for: capture.kind))
            )
            .accessibilityLabel(CaptureRowPresentation.kindLabel(for: capture.kind))
    }

    private var linkThumbnail: some View {
        AsyncImage(url: capture.linkPreview?.thumbnailURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct VoicePlaybackButton: View {
    let url: URL?
    @StateObject private var player = VoiceCapturePlayer()

    var body: some View {
        Button {
            player.toggle(url: url)
        } label: {
            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.title2)
                // Same tinted tile as every other kind's slot, so a voice row doesn't read as an
                // unfinished one sitting next to them (§4 parity, 2026-08-20 Inbox pass).
                .foregroundStyle(CaptureKindAccent.color(for: .voice))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(CaptureKindAccent.color(for: .voice).opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .accessibilityIdentifier("captureVoicePlaybackButton")
    }
}

/// The rich link preview shown inside an expanded link row: server-unfurled thumbnail, title and
/// description. A leaf view, extracted from `CaptureRowView` in the 2026-08-20 Inbox pass purely to
/// keep that type inside its body-length budget. Rendering is verbatim.
struct CaptureLinkPreviewCard: View {
    let preview: CaptureLinkPreview
    /// Shown when the unfurl produced no title — the raw URL the user captured.
    let fallbackTitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AsyncImage(url: preview.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .overlay(
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("captureLinkThumbnail")

            VStack(alignment: .leading, spacing: 4) {
                Text(preview.title ?? fallbackTitle)
                    .font(.subheadline)
                    .lineLimit(1)
                if let description = preview.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityIdentifier("captureLinkPreviewCard")
    }
}

/// Full-screen preview for a photo capture — the web inbox's lightbox.
///
/// A 44pt thumbnail is enough to recognise a photo and useless for reading one, which is exactly
/// what a photo capture of a whiteboard, a form or a receipt needs. Deliberately plain: a fitted
/// image on black with one obvious way out, so it can never become a place you get stuck.
struct CapturePhotoLightbox: View {
    let url: URL?
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text(title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 8)
                    Button {
                        Haptics.play(.light)
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "xmark")
                            .labelStyle(.titleOnly)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("capturePhotoLightboxCloseButton")
                }
                .padding(.horizontal, 16)

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Label("Couldn't load this photo.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                    default:
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("capturePhotoLightboxImage")
            }
            .padding(.vertical, 16)
        }
        .accessibilityIdentifier("capturePhotoLightbox")
    }
}

/// The Seen slice's status chip — this capture was archived, not actioned. Secondary styling on
/// purpose: "seen" is quieter news than "promoted". Icon + text, never colour alone (§4).
struct CaptureSeenChip: View {
    var body: some View {
        Label("Seen", systemImage: "archivebox")
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .accessibilityIdentifier("captureSeenChip")
    }
}

/// The Promoted tab's status chip, standing in for the Promote button on a capture that has already
/// been triaged. Icon + text, never colour alone (§4).
struct CapturePromotedChip: View {
    var body: some View {
        Label("Promoted", systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.green)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .accessibilityIdentifier("capturePromotedChip")
    }
}
