//
//  PrimaryActionButtonStyle.swift
//  ADHD LifeOS
//

import SwiftUI

/// A full-width, filled primary call-to-action that scales to `0.97` on press with a spring, so the
/// tap reads as physical rather than as a flat opacity flash (`CLAUDE.md` §3 — explicit primitive
/// press style, no raw opacity; §5 — spring, not linear easing).
///
/// Colours are adaptive/semantic (§4): the fill is the app `accentColor` when enabled and
/// `Color(.secondarySystemFill)` when disabled, and the disabled state is carried by that fill plus a
/// `.secondary` label — **never** `.opacity`. The enabled label is `.white`, the conventional
/// on-accent colour for a filled prominent control (the same contract as the system
/// `.borderedProminent` style already used in `LoginView`), which holds WCAG contrast against the
/// saturated accent in both Light and Dark. The label font is the semantic, Dynamic-Type-scaling
/// `.headline` (§1) so the button reflows at accessibility sizes instead of clipping.
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.secondary))
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.secondarySystemFill)))
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

#if DEBUG
/// Gallery of the promote form's Create Task states: idle, in-flight (progress label + disabled),
/// plain disabled, and the icon+text warning/error message rows. Rendered Light and Dark so the
/// filled fill, the on-accent label, and the disabled secondary fill can all be checked in both.
private struct PrimaryActionButtonStylePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Create Task") {}
                .buttonStyle(PrimaryActionButtonStyle())

            Button {
            } label: {
                HStack(spacing: 8) {
                    ProgressView().tint(.secondary)
                    Text("Creating Task…")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(true)

            Button("Create Task") {}
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(true)

            Label("Couldn't mark the capture processed.", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(Color("StateWarn"))
            Label("Network error. Please try again.", systemImage: "exclamationmark.octagon.fill")
                .foregroundStyle(Color("StateRisk"))
        }
        .padding(16)
    }
}

#Preview("Light") {
    PrimaryActionButtonStylePreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PrimaryActionButtonStylePreview()
        .preferredColorScheme(.dark)
}
#endif

/// The Sorted verb's two faces in ONE style, so the lit and the quiet state cannot drift into two
/// different buttons. E's 2026-08-28 screenshots: enabled and disabled looked identical, so the
/// card never said what was missing — nor when it stopped being missing.
///
/// Lit is the go token, the same green a closed task uses, plus a soft bloom of it. §5 bans muddy
/// shadows and prescribes 0.03 opacity for DEPTH; this is emphasis rather than depth, so the bloom
/// is a deliberate, restrained exception — one colour, one radius, and gone entirely the moment
/// the requirement is not met.
struct SortedButtonStyle: ButtonStyle {
    let isReady: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(isReady ? .semibold : .medium))
            .foregroundStyle(isReady ? Color("OnStateGo") : Color("LabelSecondary"))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background {
                if isReady {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color("StateGo"))
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.cardBorder, lineWidth: 1)
                }
            }
            .shadow(
                color: Color("StateGo").opacity(isReady ? 0.35 : 0),
                radius: isReady ? 12 : 0, x: 0, y: 4
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
                value: configuration.isPressed
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: isReady)
    }
}
