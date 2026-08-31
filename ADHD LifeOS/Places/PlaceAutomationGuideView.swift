//
//  PlaceAutomationGuideView.swift
//  ADHD LifeOS
//
//  The "Make this automatic" walkthrough sheet (F-PlaceActions-4-Shortcuts). The words come
//  from `PlaceAutomationGuide`, pure and pinned; this view only lays them out and holds the one
//  step we can take for E — opening Apple's Shortcuts app. Gated to iOS 17 with the rest of the
//  Places UI (E's standing authorisation).
//

import SwiftUI

@available(iOS 17.0, *)
struct PlaceAutomationGuideView: View {
    let guide: PlaceAutomationGuide

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(guide.intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                            stepRow(number: index + 1, text: step)
                        }
                    }

                    Text(guide.afterword)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(guide.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("automationGuideDoneButton")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.play(.solid)
                    if let url = URL(string: PlaceAutomationGuide.shortcutsAppURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .accessibilityIdentifier("automationGuideOpenShortcutsButton")
            }
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(number)")
                .font(.footnote.bold().monospacedDigit())
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
@available(iOS 17.0, *)
private var previewGuide: PlaceAutomationGuide? {
    PlaceAutomationGuide.make(
        for: PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        ),
        placeName: "Home"
    )
}

@available(iOS 17.0, *)
#Preview("Guide — Light") {
    if let guide = previewGuide {
        PlaceAutomationGuideView(guide: guide)
            .preferredColorScheme(.light)
    }
}

@available(iOS 17.0, *)
#Preview("Guide — Dark") {
    if let guide = previewGuide {
        PlaceAutomationGuideView(guide: guide)
            .preferredColorScheme(.dark)
    }
}
#endif
