//
//  AreasComponents.swift
//  ADHD LifeOS
//
//  The Areas tab's section builders and the grid card, split from `AreasView.swift` for its
//  length budgets — same screen, same v3 language.
//

import SwiftUI

extension AreasView {
    var unfiledCard: some View {
        Button {
            isPresentingInbox = true
        } label: {
            HStack(spacing: 8) {
                Text("📥")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unfiled")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("LabelPrimary"))
                    Text(unfiledLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier("areasUnfiledCard")
    }

    var unfiledLine: String {
        switch service.unfiledCount {
        case 0: return "Everything waiting has an area"
        case 1: return "1 capture with no area yet"
        default: return "\(service.unfiledCount) captures with no area yet"
        }
    }

    func doorRow(
        icon: String, title: String, identifier: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color("LabelSecondary"))
                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color("LabelSecondary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    var weekShareSection: some View {
        if momentumPreferences.showCharts, let share = service.weekShare {
            VStack(alignment: .leading, spacing: 8) {
                Text("Where the week went")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { proxy in
                        HStack(spacing: 0) {
                            ForEach(Array(share.segments.enumerated()), id: \.offset) { _, segment in
                                Rectangle()
                                    .fill(AreaPalette.family(for: segment.area).vivid)
                                    .frame(width: proxy.size.width * segment.fraction)
                            }
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 10)
                    Text(share.caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .bentoCard()
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("areasWeekShare")
        }
    }
}

/// One area's card: identity wash, the emoji large, the progress bar and the honest status line
/// in the area's own hue — v3's grid language.
struct AreaGridCard: View {
    let item: AreasGrid.Item
    let isWide: Bool

    var body: some View {
        let family = AreaPalette.family(for: item.momentum.area)
        let status = MomentumScoreboard.areaStatusLine(
            closedThisWeek: item.momentum.closedThisWeek,
            open: item.momentum.open,
            lastClosedAt: item.momentum.lastClosedAt
        )
        NavigationLink(value: item.momentum.area) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.momentum.area.colour)
                        .font(.largeTitle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(family.color)
                }
                Text(item.momentum.area.name)
                    .font(.title3.weight(.semibold))
                    .tracking(-0.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Capsule()
                    .fill(Color("TrackNeutral"))
                    .frame(maxWidth: isWide ? 180 : .infinity)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(family.vivid)
                                .frame(width: proxy.size.width * (item.momentum.rate ?? 0))
                        }
                    }
                Text(status.text)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(statusColor(status.tone, family: family))
                    .fixedSize(horizontal: false, vertical: true)
                Text(AreasGrid.metaLine(
                    taskCount: item.taskCount, logCount: item.logCount, captureCount: item.captureCount
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            // Equal tiles (E's 2026-08-25 note): in a two-up row the paired HStack proposes the
            // taller card's height, and `maxHeight: .infinity` makes BOTH cards accept it — so a
            // one-line status never leaves its neighbour taller. The shared `minHeight` keeps
            // rows uniform with each other; the wide odd-one-out card only needs the floor.
            .frame(
                maxWidth: .infinity,
                minHeight: 160,
                maxHeight: isWide ? nil : .infinity,
                alignment: .topLeading
            )
            .background(family.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(family.vivid.opacity(0.22), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.momentum.area.name), \(status.text)")
        .accessibilityIdentifier("areasCard-\(item.momentum.area.id)")
    }

    private func statusColor(_ tone: MomentumScoreboard.AreaStatusTone, family: AreaPalette) -> Color {
        switch tone {
        case .plain: return Color("LabelSecondary")
        case .clear: return family.color
        case .quiet: return Color("StateWarn")
        }
    }
}

#if DEBUG
#Preview("Card Light") {
    HStack(spacing: 16) {
        AreaGridCard(
            item: AreasGrid.Item(
                momentum: MomentumScoreboard.areaMomentum(
                    areas: [LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)],
                    openTasks: [], allTasks: []
                )[0],
                logCount: 1, captureCount: 0
            ),
            isWide: false
        )
    }
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Card Dark") {
    HStack(spacing: 16) {
        AreaGridCard(
            item: AreasGrid.Item(
                momentum: MomentumScoreboard.areaMomentum(
                    areas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)],
                    openTasks: [], allTasks: []
                )[0],
                logCount: 0, captureCount: 2
            ),
            isWide: false
        )
    }
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}
#endif
