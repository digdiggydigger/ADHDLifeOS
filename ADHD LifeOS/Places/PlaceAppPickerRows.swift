//
//  PlaceAppPickerRows.swift
//  ADHD LifeOS
//
//  The shared row furniture of the app-directory design pass: the monogram avatar disc and
//  the directory row label, used by both the picker sheet and the action editor's chooser
//  row so the two screens stay in visual lockstep. Gated to iOS 17 with the rest of Places.
//

import SwiftUI

/// The app's identity mark: a 36pt rounded square carrying the name's initial. Quiet by
/// design — every disc is the same secondary surface, because colour in this app carries
/// state or life-area identity and an app row is neither.
@available(iOS 17.0, *)
struct PlaceAppMonogramDisc: View {
    let name: String
    /// A glyph instead of the initial — the custom row's dashed square, the chooser's
    /// unchosen state.
    var systemImage: String?
    /// 36 stays the default so the action editor's identity row is untouched; the picker's
    /// dense rows pass `RowMetrics.discSize`.
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color("CardSurfaceSecondary"))
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(PlaceAppPickerPresentation.monogram(for: name))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color("LabelPrimary"))
                    // The disc is fixed but the type is not: at accessibility sizes the
                    // initial would otherwise push past its own corners (§1).
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// One directory row: avatar, name, and the quiet positive-only installed check
/// (F-AppDirectory-3 — a negative mark on 150 rows would be noise).
///
/// A dumb renderer: it draws the tick whenever told to, which is why the previews below still
/// show one. Its only real caller decides via
/// `PlaceAppPickerPresentation.showsInstalledCheck`, and that switch is OFF (E, 2026-09-02) —
/// so in the running app no directory row currently carries a tick.
@available(iOS 17.0, *)
struct PlaceAppDirectoryRowLabel: View {
    let entry: PlaceAppDirectoryEntry
    let looksInstalled: Bool

    var body: some View {
        HStack(spacing: 8) {
            PlaceAppMonogramDisc(
                name: entry.name, size: PlaceAppPickerPresentation.RowMetrics.discSize
            )
            Text(entry.name)
                .font(.callout)
                .foregroundStyle(Color("LabelPrimary"))
                .lineLimit(1)
            if looksInstalled {
                Image(systemName: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Installed on this iPhone")
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, PlaceAppPickerPresentation.RowMetrics.verticalPadding)
        .frame(minHeight: PlaceAppPickerPresentation.RowMetrics.minimumHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Rows — Light") {
    List {
        PlaceAppDirectoryRowLabel(
            entry: PlaceAppDirectoryEntry(scheme: "spotify", name: "Spotify"), looksInstalled: true
        )
        PlaceAppDirectoryRowLabel(
            entry: PlaceAppDirectoryEntry(scheme: "whatsapp", name: "WhatsApp"), looksInstalled: false
        )
        HStack(spacing: 8) {
            PlaceAppMonogramDisc(name: "", systemImage: "square.dashed")
            Text("Something else\u{2026}")
        }
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Rows — Dark") {
    List {
        PlaceAppDirectoryRowLabel(
            entry: PlaceAppDirectoryEntry(scheme: "spotify", name: "Spotify"), looksInstalled: true
        )
        PlaceAppDirectoryRowLabel(
            entry: PlaceAppDirectoryEntry(scheme: "zoomus", name: "Zoom"), looksInstalled: false
        )
    }
    .preferredColorScheme(.dark)
}
#endif
