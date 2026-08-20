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
        .promoteSuccessHaptic(trigger: successHapticTrigger)
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
/// own view so `CaptureRowView` stays within its type-body budget. Media rows keep their existing
/// thumbnail/playback control; link rows with a landed preview thumbnail render it; every other
/// kind gets a centred SF Symbol placeholder in a matching 10pt-radius tile.
struct CaptureRowLeadingSlot: View {
    let capture: Capture

    var body: some View {
        switch capture.kind {
        case .photo:
            photoThumbnail
        case .voice:
            VoicePlaybackButton(url: capture.mediaURL)
        case .link where capture.linkPreview?.thumbnailURL != nil:
            linkThumbnail
        default:
            glyphSlot
        }
    }

    private var glyphSlot: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                    .foregroundStyle(.secondary)
            )
    }

    private var photoThumbnail: some View {
        AsyncImage(url: capture.photoDisplayURL) { phase in
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
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("capturePhotoThumbnail")
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

extension View {
    /// Tactile confirmation when a row expands/collapses (`CLAUDE.md` §3). `sensoryFeedback` is
    /// iOS 17+, while the app's deployment target is iOS 16, so it is applied only where available;
    /// on iOS 16 the row simply renders without the haptic rather than failing to build.
    @ViewBuilder
    func expandCollapseHaptic(trigger: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .solid), trigger: trigger)
        } else {
            self
        }
    }

    /// Success confirmation when a capture is promoted to a task (`CLAUDE.md` §3). `sensoryFeedback`
    /// is iOS 17+, so on iOS 16 the same `trigger` drives a `UIImpactFeedbackGenerator` via
    /// `.onChange` instead — the deployment target stays iOS 16.0 (§7). Fired only on success by the
    /// caller, so a failed create never buzzes as if it confirmed.
    @ViewBuilder
    func promoteSuccessHaptic(trigger: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .solid), trigger: trigger)
        } else {
            self.onChange(of: trigger) { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
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
                .frame(width: 44, height: 44)
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
