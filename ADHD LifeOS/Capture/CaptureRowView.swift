//
//  CaptureRowView.swift
//  ADHD LifeOS
//
//  One Inbox row. The inline triage accordion this file carried until 2026-08-23 (expand, life
//  area, tags, promote form, secondary exits) is retired — the row is now a tappable summary card
//  that opens `CaptureDetailView`, where all of that lives with room to breathe (design frame B6).
//  The life-area PATCH race machinery moved verbatim to `CaptureFiledInCard`.
//

import SwiftUI

struct CaptureRowView: View {
    let capture: Capture
    let lifeAreas: [LifeArea]
    /// Resolved tags for the chip strip under the meta line. Defaulted empty so surfaces that
    /// don't chip (the Captures-tab archive) construct the row unchanged.
    var tags: [Tag] = []
    /// Named places, for the "where" on the caption line. Defaulted so the archive surface is
    /// unchanged.
    var places: [Place] = []
    /// Pushes the full-screen detail — the row's single action. Leaf controls inside the summary
    /// (voice playback, the photo preview) are Buttons and win their own taps.
    let onOpen: () -> Void

    @State private var isPresentingPhoto = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        layout
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens this capture full screen")
            .accessibilityIdentifier("captureRow-\(capture.id)")
            .fullScreenCover(isPresented: $isPresentingPhoto) {
                CapturePhotoLightbox(
                    url: capture.photoDisplayURL,
                    title: CaptureRowPresentation.primaryText(for: capture)
                )
            }
    }

    /// At accessibility sizes the trailing chip reflows beneath the content (§1 layout safety —
    /// same rule the old promote button followed); the chevron is dropped there, since the whole
    /// row is the button and says so through its trait.
    @ViewBuilder
    private var layout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                summary
                if capture.processed {
                    CapturePromotedChip()
                } else if capture.seen == true {
                    CaptureSeenChip()
                }
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                summary
                Spacer()
                trailing
            }
        }
    }

    private var summary: some View {
        CaptureRowSummary(
            capture: capture,
            lifeAreas: lifeAreas,
            tags: tags,
            places: places,
            isExpanded: false,
            onOpenPhoto: { isPresentingPhoto = true },
            expandedLinkContent: { EmptyView() }
        )
    }

    @ViewBuilder
    private var trailing: some View {
        if capture.processed {
            CapturePromotedChip()
        } else if capture.seen == true {
            CaptureSeenChip()
        } else {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .frame(minWidth: 24, minHeight: 44)
                .accessibilityHidden(true)
        }
    }
}
