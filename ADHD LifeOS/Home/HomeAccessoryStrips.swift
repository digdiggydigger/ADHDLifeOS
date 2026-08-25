//
//  HomeAccessoryStrips.swift
//  ADHD LifeOS
//
//  Home's reorder list and the v3 Today header, both here for `HomeView.swift`'s length
//  budget. The due-nudges dismiss strip that used to live here was replaced by the v3
//  "Nudges waiting" row (F-V3-Today) — dismissal now happens on the Nudges tab.
//

import SwiftUI

extension HomeView {
    var reorderList: some View {
        List {
            ForEach(arrangeAreas) { area in
                HStack(spacing: 8) {
                    Text(area.colour)
                    Text(area.name)
                        .font(.body)
                }
                .accessibilityIdentifier("homeReorderRow-\(area.id.uuidString)")
            }
            .onMove(perform: moveArrangeAreas)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    /// Today's inbox module, per the Claude Design Today frame — the 📥 avatar row,
    /// "Unprocessed inbox items"-style header with the count, and the "Clear the deck" CTA —
    /// widened after E's follow-up: the first cut was too small to interact with and said too
    /// little. Each peek row is now its own 44pt door straight into that capture, the CTA opens
    /// triage, and the handled line names the day's throughput.
    var inboxPeekCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isPresentingInbox = true
            } label: {
                HStack(spacing: 8) {
                    Text("📥")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(
                            Color.accentColor.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Capture inbox")
                            .font(.headline)
                        Text(
                            inboxCount > 0
                                ? "Waiting for a decision — one at a time."
                                : "Anything you capture lands here first."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    MomentumChip(
                        text: HomeInboxPeek.countLine(inboxCount),
                        background: inboxCount > 0
                            ? Color("StateWarn").opacity(0.16)
                            : Color("CardSurfaceSecondary"),
                        foreground: inboxCount > 0 ? Color("StateWarn") : Color("LabelSecondary")
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Capture inbox, \(HomeInboxPeek.countLine(inboxCount))")
            .accessibilityHint("Opens the inbox for triage")

            ForEach(inboxPeek) { capture in
                inboxPeekRow(capture)
            }
            if let overflow = HomeInboxPeek.overflowLine(total: inboxCount) {
                Text(overflow)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let handled = HomeInboxPeek.handledLine(inboxHandledToday) {
                Label(handled, systemImage: "checkmark.circle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("StateGoVivid"))
                    .accessibilityIdentifier("homeInboxHandledLine")
            }
            if inboxCount > 0 {
                Button("Clear the deck") {
                    isPresentingInbox = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("homeInboxClearDeckButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .accessibilityIdentifier("homeInboxPeekCard")
    }

    /// One waiting capture as a full 44pt door into its detail — the inbox row's visual language
    /// at card scale: the kind's glyph in its tinted tile, the title with room to breathe, and
    /// the caption that says when and how it arrived.
    private func inboxPeekRow(_ capture: Capture) -> some View {
        Button {
            inspectingHomeCapture = capture
        } label: {
            HStack(spacing: 8) {
                Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CaptureKindAccent.color(for: capture.kind))
                    .frame(width: 36, height: 36)
                    .background(
                        CaptureKindAccent.color(for: capture.kind).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(CaptureRowPresentation.primaryText(for: capture))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(CaptureRowPresentation.caption(for: capture))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this capture")
        .accessibilityIdentifier("homeInboxPeekRow-\(capture.id)")
    }

    /// Each completed drag persists immediately (E's per-move decision): reorder `arrangeAreas`
    /// optimistically, then fire ONE serialised bulk reorder carrying the full ordering. TRAP 6's
    /// serialisation + coalescing lives in `HomeService.submitReorder`.
    func moveArrangeAreas(from source: IndexSet, to destination: Int) {
        arrangeAreas.move(fromOffsets: source, toOffset: destination)
        Task { await homeService.submitReorder(activeInNewOrder: arrangeAreas) }
    }

    /// v3's Today header: the date eyebrow over the big title, with the inbox (badged) and
    /// settings controls as 40pt wells — the navigation bar's replacements, so their
    /// accessibility identifiers carry over from the old toolbar items.
    var todayHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                Text("Today")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                isPresentingInbox = true
            } label: {
                headerIconWell(systemImage: "tray")
                    .overlay(alignment: .topTrailing) {
                        if inboxCount > 0 {
                            Text("\(inboxCount)")
                                .font(.caption2.bold())
                                .monospacedDigit()
                                .foregroundStyle(Color("OnStateWarn"))
                                .padding(.horizontal, 4)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(Color("StateWarn"), in: Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
            }
            .accessibilityLabel("Inbox (\(inboxCount))")
            .accessibilityIdentifier("inboxButton")
            Button {
                showSettings = true
            } label: {
                headerIconWell(systemImage: "gearshape")
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("settingsButton")
        }
    }

    func headerIconWell(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(Color("LabelSecondary"))
            .frame(width: 40, height: 40)
            .background(Color.cardSurface, in: Circle())
            .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
            .contentShape(Circle())
    }
}
