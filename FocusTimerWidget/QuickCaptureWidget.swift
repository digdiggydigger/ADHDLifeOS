//
//  QuickCaptureWidget.swift
//  FocusTimerWidget
//
//  The Quick Capture medium widget (E's 2026-08-25 note): the capture fan's five discs, laid
//  flat on the Home Screen. Each disc is a `Link` deep into the composer with that kind already
//  chosen — the same promise as the fan, one screen earlier. Static on purpose: there is nothing
//  to publish, refresh or go stale.
//
//  The disc table mirrors `CaptureFan.slots` (colors, glyphs, labels) and the URL paths spell
//  `CaptureKind.rawValue` — both contracts this target writes by hand because it cannot see the
//  app's types; `AppDeepLinkTests` locks the URL side from the app.
//

import SwiftUI
import WidgetKit

struct QuickCaptureEntry: TimelineEntry {
    let date: Date
}

struct QuickCaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickCaptureEntry {
        QuickCaptureEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickCaptureEntry) -> Void) {
        completion(QuickCaptureEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureEntry>) -> Void) {
        completion(Timeline(entries: [QuickCaptureEntry(date: Date())], policy: .never))
    }
}

struct QuickCaptureWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickCaptureWidget", provider: QuickCaptureProvider()) { _ in
            QuickCaptureWidgetView()
        }
        .configurationDisplayName("Quick Capture")
        .description("Dump a thought without opening the app first — pick its type right here.")
        .supportedFamilies([.systemMedium])
    }
}

struct QuickCaptureWidgetView: View {
    /// The fan's discs, flattened: kind raw value (the URL path segment), label, glyph, and the
    /// same identity hues `CaptureFan.slots` assigns. Task first — the fan's nearest, most-used
    /// disc — reading order instead of arc order.
    private struct Disc {
        let kindRawValue: String
        let label: String
        let systemImage: String
        let fillAssetName: String
        let onAssetName: String
    }

    private let discs: [Disc] = [
        Disc(kindRawValue: "task", label: "Task", systemImage: "checkmark.circle.fill",
             fillAssetName: "StateGoVivid", onAssetName: "OnStateGo"),
        Disc(kindRawValue: "note", label: "Note", systemImage: "square.and.pencil",
             fillAssetName: "AccentColor", onAssetName: "OnAreaWork"),
        Disc(kindRawValue: "voice", label: "Voice", systemImage: "waveform",
             fillAssetName: "AreaGrowthVivid", onAssetName: "OnAreaGrowth"),
        Disc(kindRawValue: "photo", label: "Photo", systemImage: "camera.fill",
             fillAssetName: "AreaHealthVivid", onAssetName: "OnAreaHealth"),
        Disc(kindRawValue: "link", label: "Link", systemImage: "link",
             fillAssetName: "AreaAdminVivid", onAssetName: "OnAreaAdmin")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CAPTURE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 8) {
                ForEach(discs, id: \.kindRawValue) { disc in
                    discLink(disc)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .focusWidgetBackground()
    }

    private func discLink(_ disc: Disc) -> some View {
        Link(destination: URL(string: "adhdlifeos://widget/capture/\(disc.kindRawValue)")!) {
            VStack(spacing: 4) {
                Image(systemName: disc.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(disc.onAssetName))
                    .frame(width: 44, height: 44)
                    .background(Color(disc.fillAssetName), in: Circle())
                Text(disc.label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("Capture a \(disc.label)")
    }
}

#if DEBUG
// Plain view preview: the widget-timeline preview macro is iOS 17+, this target's floor is 16.1.
#Preview("Quick Capture") {
    QuickCaptureWidgetView()
        .frame(width: 329, height: 155)
}
#endif
