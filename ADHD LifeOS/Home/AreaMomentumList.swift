//
//  AreaMomentumList.swift
//  ADHD LifeOS
//
//  Today's life-area rows and the closed-today evidence card, split from
//  `MomentumScoreboardViews.swift` for that file's length budget (F-V3-Today) — still the
//  scoreboard family, same v3 language.
//

import SwiftUI

/// v3's life-area rows — emoji in the identity tint well, the honest status line, and a small
/// progress bar in the identity vivid. Tapping pushes the same LifeAreaDetail the old grid did.
struct AreaMomentumList: View {
    let items: [MomentumScoreboard.AreaMomentum]
    var asOf: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationLink(value: item.area) {
                    row(item)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { Haptics.play(.light) })
                .accessibilityLabel(accessibilityLabel(for: item))
                .accessibilityIdentifier("homeAreaRow-\(item.area.id)")
                if index != items.indices.last {
                    Divider()
                        .padding(.leading, 68)
                }
            }
        }
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
        .accessibilityIdentifier("homeAreaMomentumStrip")
    }

    private func row(_ item: MomentumScoreboard.AreaMomentum) -> some View {
        let family = AreaPalette.family(for: item.area)
        let status = MomentumScoreboard.areaStatusLine(
            closedThisWeek: item.closedThisWeek,
            open: item.open,
            lastClosedAt: item.lastClosedAt,
            asOf: asOf
        )
        return HStack(spacing: 8) {
            Text(item.area.colour)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(family.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.area.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color("LabelPrimary"))
                Text(status.text)
                    .font(.footnote)
                    .foregroundStyle(statusColor(status.tone, family: family))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Capsule()
                .fill(Color("TrackNeutral"))
                .frame(width: 64, height: 8)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(family.vivid)
                        .frame(width: 64 * (item.rate ?? 0))
                }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 72)
        .contentShape(Rectangle())
    }

    private func statusColor(_ tone: MomentumScoreboard.AreaStatusTone, family: AreaPalette) -> Color {
        switch tone {
        case .plain: return Color("LabelSecondary")
        case .clear: return family.color
        case .quiet: return Color("StateWarn")
        }
    }

    private func accessibilityLabel(for item: MomentumScoreboard.AreaMomentum) -> String {
        "\(item.area.name), \(item.closedThisWeek) closed this week, \(item.open) open"
    }
}

/// Today's closed items, named and timestamped — the evidence under the ring, as v3's quiet
/// ✓ rows.
struct MomentumClosedTodayCard: View {
    let tasks: [TaskItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.footnote.bold())
                        .foregroundStyle(Color("StateGoVivid"))
                    Text(task.title)
                        .font(.footnote)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let completedAt = task.completedAt {
                        Text(completedAt.formatted(date: .omitted, time: .shortened))
                            .font(.footnote)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                if index != tasks.indices.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
        .accessibilityIdentifier("homeClosedTodayCard")
    }
}
