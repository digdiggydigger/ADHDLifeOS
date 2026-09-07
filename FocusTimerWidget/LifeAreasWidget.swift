//
//  LifeAreasWidget.swift
//  FocusTimerWidget
//
//  The Life Areas medium widget (E's 2026-08-25 note): the areas grid's identity — emoji, name,
//  open count — in each area's own hue, straight off the snapshot the app publishes. The palette
//  stems arrive pre-resolved, so the F-V3-AreaColour override recolours the Home Screen the next
//  time the app publishes, without this target knowing the resolver exists.
//

import SwiftUI
import WidgetKit

struct LifeAreasEntry: TimelineEntry {
    let date: Date
    /// `nil` means "the app has never published" — fresh install or unreachable App Group.
    let snapshot: LifeAreasWidgetSnapshot?
}

struct LifeAreasProvider: TimelineProvider {
    private let store = LifeAreasWidgetStore()

    func placeholder(in context: Context) -> LifeAreasEntry {
        LifeAreasEntry(date: Date(), snapshot: LifeAreasWidgetSnapshot.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeAreasEntry) -> Void) {
        completion(LifeAreasEntry(date: Date(), snapshot: store.read()))
    }

    /// One entry; the app reloads this timeline whenever Home's data changes, and nothing here
    /// moves with the clock — a daily refresh guards against a stale App Group read at most.
    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeAreasEntry>) -> Void) {
        let now = Date()
        let entry = LifeAreasEntry(date: now, snapshot: store.read())
        let nextMidnight = Calendar.current.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct LifeAreasWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: LifeAreasWidgetStore.widgetKind, provider: LifeAreasProvider()) { entry in
            LifeAreasWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Life Areas")
        .description("Your life areas and what each one holds, at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct LifeAreasWidgetView: View {
    let snapshot: LifeAreasWidgetSnapshot?

    private var areas: [LifeAreasWidgetSnapshot.Area] { snapshot?.areas ?? [] }

    var body: some View {
        Group {
            if areas.isEmpty {
                emptyState
            } else {
                grid
            }
        }
        .widgetURL(URL(string: "adhdlifeos://widget/areas"))
        .focusWidgetBackground()
    }

    /// Two columns, up to three rows — the snapshot is already capped and ordered.
    private var grid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(Array(areas.enumerated()), id: \.offset) { _, area in
                areaCell(area)
            }
        }
    }

    private func areaCell(_ area: LifeAreasWidgetSnapshot.Area) -> some View {
        HStack(spacing: 4) {
            Text(area.emoji)
                .font(.caption)
            Text(area.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(area.paletteAssetStem))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if area.openCount > 0 {
                Text("\(area.openCount)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color(area.paletteAssetStem))
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(
            Color(area.paletteAssetStem + "Tint"),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(area.name), \(area.openCount) open task\(area.openCount == 1 ? "" : "s")"
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LIFE AREAS")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text("Open LifeOS once and your areas will appear here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#if DEBUG
// Plain view previews: the `#Preview(as: .systemMedium)` widget-timeline macro is iOS 17+ and
// this target's floor is 16.1 — same constraint `FocusStatsWidget` documents.
#Preview("Populated") {
    LifeAreasWidgetView(
        snapshot: LifeAreasWidgetSnapshot(
            generatedAt: .now,
            areas: [
                .init(name: "Work & Career", emoji: "💼", paletteAssetStem: "AreaWork", openCount: 4),
                .init(name: "Health", emoji: "🫀", paletteAssetStem: "AreaHealth", openCount: 2),
                .init(name: "Admin & Home", emoji: "🏠", paletteAssetStem: "AreaAdmin", openCount: 0),
                .init(name: "Growth", emoji: "🌱", paletteAssetStem: "AreaGrowth", openCount: 1),
                .init(name: "Hobbies", emoji: "🎨", paletteAssetStem: "AreaHobby", openCount: 3),
                .init(name: "Money", emoji: "💰", paletteAssetStem: "AreaAdmin", openCount: 0)
            ]
        )
    )
    .frame(width: 329, height: 155)
}

#Preview("Never published") {
    LifeAreasWidgetView(snapshot: nil)
        .frame(width: 329, height: 155)
}
#endif
