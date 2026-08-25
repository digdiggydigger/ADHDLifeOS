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

    /// Today's inbox card (E's 2026-08-25 note: "no intuitive way to see my captures") — the
    /// count in warn beside a peek of the newest waiting thoughts, in the inbox rows' own visual
    /// language. The whole card is the same door the header's tray icon opens; the icon keeps
    /// its badge for the glance, this carries the content.
    var inboxPeekCard: some View {
        Button {
            isPresentingInbox = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "tray")
                        .foregroundStyle(Color.accentColor)
                    Text("Capture inbox")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(HomeInboxPeek.countLine(inboxCount))
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(inboxCount > 0 ? Color("StateWarn") : Color("LabelSecondary"))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                ForEach(inboxPeek) { capture in
                    inboxPeekRow(capture)
                }
                if let overflow = HomeInboxPeek.overflowLine(total: inboxCount) {
                    Text(overflow)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if inboxCount == 0 {
                    Text("Anything you capture lands here first, so your head doesn't have to hold it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityLabel("Capture inbox, \(HomeInboxPeek.countLine(inboxCount))")
        .accessibilityHint("Opens the inbox for triage")
        .accessibilityIdentifier("homeInboxPeekCard")
    }

    private func inboxPeekRow(_ capture: Capture) -> some View {
        HStack(spacing: 8) {
            Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                .font(.footnote.bold())
                .foregroundStyle(CaptureKindAccent.color(for: capture.kind))
                .frame(width: 20)
            Text(CaptureRowPresentation.primaryText(for: capture))
                .font(.footnote)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(HomeInboxPeek.timeLabel(for: capture))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 24)
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
