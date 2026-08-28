//
//  JournalEnergyMoodPicker.swift
//  ADHD LifeOS
//

import SwiftUI

/// The energy + mood controls a journal entry is written with — the web composer's "Energy Level"
/// select and "Mood Emoji" row, ported.
///
/// One view, used by BOTH journal-writing paths (the Journal composer and the Capture inbox's
/// triage), because a field you can set on one screen and not the other is a field nobody trusts.
///
/// Both controls start pre-selected, exactly as the web does. That is what keeps the inbox's
/// "Log to journal" a ONE-TAP exit: the strip is an adjustment you may make, never a form you must
/// fill in before a thought can leave the inbox.
struct JournalEnergyMoodPicker: View {
    @Binding var energyLevel: EnergyLevel
    @Binding var moodEmoji: String
    /// The chip wardrobe. `nil` is the ordinary app chip — the journal pad passes its own so the
    /// energy and mood rows stop being the loudest blue on a gold page.
    var palette: ComposerChipPalette?
    /// The inbox nests this inside an already-busy row, so it drops the section labels and tightens
    /// the type; the composer shows the full thing.
    var isCompact = false

    /// Whether an unselected chip's sublabel may be dimmed. Only where no ink was handed to us —
    /// on a page with its own ink, alpha is a second, quieter colour, which is the one thing this
    /// screen is not allowed to have.
    private var dimsUnselectedDetail: Bool {
        palette?.softInk == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            energyRow
            moodRow
        }
    }

    // MARK: - Energy

    @ViewBuilder
    private var energyRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isCompact {
                Text("Energy")
                    .sectionLabel()
                    .composerSoftInk(palette?.softInk)
            }

            HStack(spacing: 8) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    Button {
                        Haptics.play(.selection)
                        energyLevel = level
                    } label: {
                        energyChip(level)
                    }
                    .buttonStyle(ChoiceChipButtonStyle(isSelected: energyLevel == level, palette: palette))
                    .accessibilityIdentifier("journalEnergyOption-\(level.rawValue)")
                    .accessibilityLabel("\(level.title) energy, \(level.detail)")
                    .accessibilityAddTraits(energyLevel == level ? [.isSelected] : [])
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: energyLevel)
    }

    /// Glyph AND words on every chip: the selected state is already carried by fill colour, so the
    /// level itself must never depend on reading an emoji (§4).
    private func energyChip(_ level: EnergyLevel) -> some View {
        VStack(spacing: 4) {
            Text(level.glyph)
                .font(.footnote)
            Text(level.title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if !isCompact {
                Text(level.detail)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    // Alpha is hierarchy the pad cannot afford (§4). Measured off E's device,
                    // 2026-08-28: ink at 70% on the day chip renders #7D6A3D = 4.27:1, UNDER the
                    // 4.5 bar, while the same ink at full strength clears 9.47:1 there. The chip's
                    // fill already carries selection — see the note on `energyChip` — so dropping
                    // the dimming costs no signal. A page that hands us no ink keeps its dimming,
                    // so the inbox's triage row is unchanged by construction.
                    .opacity(dimsUnselectedDetail && energyLevel != level ? 0.7 : 1)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
    }

    // MARK: - Mood

    @ViewBuilder
    private var moodRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isCompact {
                Text("Mood")
                    .sectionLabel()
                    .composerSoftInk(palette?.softInk)
            }

            // Scrolls rather than wraps: eight 44pt targets do not fit a narrow row, and shrinking
            // them below 44 would break §3.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(JournalMood.options, id: \.self) { emoji in
                        Button {
                            Haptics.play(.selection)
                            moodEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.body)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(ChoiceChipButtonStyle(isSelected: moodEmoji == emoji, palette: palette))
                        .accessibilityIdentifier("journalMoodOption-\(emoji)")
                        .accessibilityLabel("Mood \(emoji)")
                        .accessibilityAddTraits(moodEmoji == emoji ? [.isSelected] : [])
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: moodEmoji)
    }
}

/// The read-only counterpart: how a written entry shows what it was written with. `nil` on either
/// half simply omits it — an entry from before these fields existed shows neither, and never a
/// fabricated "medium".
struct JournalEnergyMoodBadge: View {
    let energyLevel: EnergyLevel?
    let moodEmoji: String?

    var body: some View {
        if energyLevel != nil || moodEmoji != nil {
            HStack(spacing: 8) {
                if let moodEmoji {
                    Text(moodEmoji)
                        .font(.footnote)
                        .accessibilityLabel("Mood \(moodEmoji)")
                }

                if let energyLevel {
                    Label(energyLevel.chipLabel, systemImage: "bolt.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#if DEBUG
private struct JournalEnergyMoodGallery: View {
    @State private var energy: EnergyLevel = .medium
    @State private var mood = JournalMood.defaultEmoji

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            JournalEnergyMoodPicker(energyLevel: $energy, moodEmoji: $mood)
            JournalEnergyMoodPicker(energyLevel: $energy, moodEmoji: $mood, isCompact: true)
            JournalEnergyMoodBadge(energyLevel: .high, moodEmoji: "🔥")
            JournalEnergyMoodBadge(energyLevel: nil, moodEmoji: nil)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    JournalEnergyMoodGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    JournalEnergyMoodGallery()
        .preferredColorScheme(.dark)
}
#endif
