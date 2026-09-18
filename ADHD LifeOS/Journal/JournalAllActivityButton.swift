//
//  JournalAllActivityButton.swift
//  ADHD LifeOS
//
//  The "All activity" switch (F-RoutineRecord-2, E's call): the one way the routine story —
//  offered, started, finished — becomes visible on the Journal. Selected state carried by the eye
//  glyph AND `.isSelected`, never colour alone.
//
//  **A nav-bar toolbar item since `F-JournalPencilDisc` (2026-09-18)**, alone top right — E's "Keep
//  the nav bar". It drew its own 44pt circle beside the header pencil until then; in the toolbar
//  the chrome is the system's (a glass circle on 26+), so it is glyph-only. E's **"B"**: OFF in the
//  LABEL colour, ON in accent. Spelled explicitly because Step 0 measured the default differing by
//  tier — label colour on 26/27, accent below, where an OFF eye would read as ON.
//

import SwiftUI

struct JournalAllActivityButton: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            Haptics.play(.light)
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "eye" : "eye.slash")
                .foregroundStyle(isOn ? Color.accentColor : Color.primary)
        }
        .accessibilityLabel("All activity")
        .accessibilityHint("Shows your routines — offered, started and finished")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

#Preview("All activity — light") {
    JournalAllActivityPreviewBar()
        .preferredColorScheme(.light)
}

#Preview("All activity — dark") {
    JournalAllActivityPreviewBar()
        .preferredColorScheme(.dark)
}

/// Where it lives: a large-title nav bar, OFF and then ON.
private struct JournalAllActivityPreviewBar: View {
    @State private var isOn = false

    var body: some View {
        NavigationStack {
            Text(isOn ? "All activity on" : "All activity off")
                .font(.footnote)
                .navigationTitle("Journal")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        JournalAllActivityButton(isOn: $isOn)
                    }
                }
        }
    }
}
