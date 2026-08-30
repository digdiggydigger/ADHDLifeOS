//
//  CaptureFanOverlay.swift
//  ADHD LifeOS
//

import SwiftUI

/// v3's capture fan (F-V3-Capture): five identity-hued discs on a bowed arc leaning out of the
/// FAB, over a scrim — "pick how it arrived". Geometry and stagger live in `CaptureFan` (pure,
/// tested); this view only draws the table. The nearest disc animates in first; Reduce Motion
/// collapses the stagger to a plain fade.
struct CaptureFanOverlay: View {
    let onPick: (CaptureKind) -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color("Scrim")
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)
                    .accessibilityLabel("Dismiss capture fan")
                    .accessibilityAddTraits(.isButton)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What just landed in your head?")
                        .font(.title2.bold())
                        .tracking(-0.5)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 240, alignment: .leading)
                    Text("Pick how it arrived. Everything goes to the inbox — you decide what it is later.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(maxWidth: 250, alignment: .leading)
                }
                .padding(.top, 96)
                .padding(.leading, 16)

                ForEach(CaptureFan.slots, id: \.kind) { slot in
                    disc(slot)
                        .position(
                            x: proxy.size.width - slot.fromTrailing,
                            y: proxy.size.height - slot.fromBottom
                        )
                }
            }
        }
        .onAppear { appeared = true }
    }

    private func disc(_ slot: CaptureFan.Slot) -> some View {
        Button {
            Haptics.play(.light)
            onPick(slot.kind)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: slot.systemImage)
                    .font(.body.weight(.semibold))
                Text(slot.label)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            // Glass tiles, not solids (E's GIF verdict, 2026-08-30: five full-saturation discs
            // "altogether just doesn't look right"). The kind colour moves INTO the glyph and
            // label, over its own ~18% tint on material — the exact language of the app's 44pt
            // card icon tiles, so the open fan finally matches the rest of the app. A hairline
            // ring in the same hue keeps each disc's edge on the scrim.
            .foregroundStyle(Color(slot.fillAssetName))
            .frame(width: 62, height: 62)
            .background(Color(slot.fillAssetName).opacity(0.18), in: Circle())
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(Color(slot.fillAssetName).opacity(0.4), lineWidth: 1))
            .shadow(color: Color("Scrim").opacity(0.5), radius: 8, x: 0, y: 4)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
        .offset(appeared || reduceMotion ? .zero : CGSize(width: 28, height: 26))
        .opacity(appeared ? 1 : 0)
        .animation(
            reduceMotion
                ? .default
                : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
                    .delay(slot.appearanceDelay),
            value: appeared
        )
        .accessibilityLabel("Capture a \(slot.label)")
        .accessibilityIdentifier("captureFan-\(slot.kind.rawValue)")
    }
}

#if DEBUG
#Preview("Fan") {
    ZStack {
        Color.pageBackground.ignoresSafeArea()
        CaptureFanOverlay(onPick: { _ in }, onDismiss: {})
    }
}
#endif
