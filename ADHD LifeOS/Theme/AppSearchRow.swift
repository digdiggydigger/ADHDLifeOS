//
//  AppSearchRow.swift
//  ADHD LifeOS
//

import SwiftUI

/// The search control that sits above the tab bar, sharing its row with the capture disc.
///
/// **It is a Button, not a text field, and that is the arc's biggest simplification.** E chose a
/// full-screen search surface over an in-place filter, which means focus never happens *here* —
/// tapping this opens the surface, and the keyboard belongs to the field up there. So nothing in
/// this row ever becomes first responder, and the tab bar and the capture disc never have to move
/// out of a keyboard's way. A live `TextField` in this position would have dragged all of that
/// back in for no gain.
///
/// It still *looks* like a field, because it has to read as one: a capsule, a magnifier, and the
/// scope's own prompt.
struct AppSearchRow: View {
    let placeholder: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.play(.light)
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("LabelSecondary"))
                Text(placeholder)
                    .font(.callout)
                    .foregroundStyle(Color("LabelSecondary"))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: AppSearchRowMetrics.fieldHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.cardSurface,
                in: RoundedRectangle(
                    cornerRadius: AppSearchRowMetrics.fieldCornerRadius, style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: AppSearchRowMetrics.fieldCornerRadius, style: .continuous
                )
                .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(AppSearchRowStyle())
        .accessibilityLabel(placeholder)
        .accessibilityAddTraits(.isSearchField)
        .accessibilityIdentifier("appSearchRow")
    }
}

/// §3's press state: a real scale, never an opacity filter.
private struct AppSearchRowStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
                value: configuration.isPressed
            )
    }
}

#Preview("Search row — Light") {
    VStack {
        Spacer()
        HStack(spacing: AppSearchRowMetrics.rowSpacing) {
            AppSearchRow(placeholder: "Search tasks") {}
            Circle()
                .fill(Color.accentColor)
                .frame(
                    width: CaptureDiscMetrics.discDiameter,
                    height: CaptureDiscMetrics.discDiameter
                )
        }
        .padding(.horizontal, 16)
    }
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Search row — Dark") {
    VStack {
        Spacer()
        HStack(spacing: AppSearchRowMetrics.rowSpacing) {
            AppSearchRow(placeholder: "Search tasks") {}
            Circle()
                .fill(Color.accentColor)
                .frame(
                    width: CaptureDiscMetrics.discDiameter,
                    height: CaptureDiscMetrics.discDiameter
                )
        }
        .padding(.horizontal, 16)
    }
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}
