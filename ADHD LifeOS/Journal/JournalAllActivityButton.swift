//
//  JournalAllActivityButton.swift
//  ADHD LifeOS
//
//  The "All activity" switch (F-RoutineRecord-2, E's call): the one way an ignored or swiped
//  routine offer becomes visible. The compose button's circle, so the header reads as one
//  family; selected state carried by the fill AND the eye glyph, never colour alone.
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
                .font(.body)
                .foregroundStyle(isOn ? AreaPalette.work.onColor : Color("LabelSecondary"))
                .frame(width: 40, height: 40)
                .background(
                    isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.cardSurface),
                    in: Circle()
                )
                .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
                .contentShape(Circle())
        }
        .accessibilityLabel("All activity")
        .accessibilityHint("Shows routine offers you cleared or did not open")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

#Preview("All activity — light and dark") {
    HStack(spacing: 24) {
        JournalAllActivityButton(isOn: .constant(false))
        JournalAllActivityButton(isOn: .constant(true))
            .environment(\.colorScheme, .dark)
    }
    .padding(16)
}
