//
//  ToolsView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The sixth tab (E's 2026-09-02 call), and the reason the app now draws its own tab bar.
///
/// **Deliberately empty in F-Tools-1-Bar.** This block's whole question is whether six slots feel
/// right on a real screen, and a page full of cards would answer a different one. F-Tools-3-Page
/// fills it with bento cards for Places and the Life Areas editor — and nothing more than those
/// two: E wants the page left sparse so Routines has an obvious home when it arrives.
///
/// What is here is a finished empty state rather than an unimplemented placeholder: opened on
/// device today it says what the tab is for, instead of showing a blank rectangle.
struct ToolsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Nothing here yet")
                    .font(.headline)
                Text("The workshop drawer — the screens you set up once and come back to rarely.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground)
            .accessibilityIdentifier("toolsEmptyState")
            .navigationTitle("Tools")
        }
    }
}

#Preview("Tools — Light") {
    ToolsView()
        .preferredColorScheme(.light)
}

#Preview("Tools — Dark") {
    ToolsView()
        .preferredColorScheme(.dark)
}
