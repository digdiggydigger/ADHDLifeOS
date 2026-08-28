//
//  CollapsibleSectionHeader.swift
//  ADHD LifeOS
//

import SwiftUI

/// The rules behind a collapsible section, in one place because two screens use them (E,
/// 2026-08-28: "a little down and upwards arrow to represent the states of collapsed or
/// uncollapsed"). The Journal's day sections and Today's life-area list share this so the control
/// cannot come to mean "open" on one screen and "close" on the other.
enum CollapsibleSection {
    /// The arrow points AT the content, not at the gesture: expanded points down at the rows
    /// below it, collapsed points up at the header that swallowed them.
    ///
    /// E's call, 2026-08-28, matching the mock-up they approved — and the opposite of the first
    /// cut, which pointed at the action instead. Both readings exist in the wild; this is the one
    /// that was chosen after seeing it. Kept in one place precisely so the choice stays a single
    /// line rather than a spelling repeated at every call site.
    static func chevron(isExpanded: Bool) -> String {
        isExpanded ? "chevron.down" : "chevron.up"
    }

    /// VoiceOver is told the state outright: the glyph carries it visually, and §4 does not allow
    /// meaning to live in a glyph alone.
    static func hint(isExpanded: Bool) -> String {
        isExpanded ? "Expanded. Double tap to collapse." : "Collapsed. Double tap to expand."
    }
}

/// A section header that folds its own content away.
///
/// The whole header is the target, not just the chevron — a 12pt glyph is a poor thing to aim at,
/// and §3's 44pt floor applies to the gesture, not to the ornament that hints at it. `summary` is
/// what survives the fold: collapsing must not amount to hiding, so the header keeps saying how
/// much is behind it (the same promise `CaptureInboxSummary.doorLine` makes for the inbox door).
struct CollapsibleSectionHeader<Trailing: View>: View {
    let title: String
    /// Shown only while collapsed. `nil` folds to the bare title.
    let summary: String?
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                Haptics.play(.light)
                onToggle()
            }, label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .sectionLabel()
                            .foregroundStyle(.secondary)
                        if !isExpanded, let summary {
                            Text(summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Image(systemName: CollapsibleSection.chevron(isExpanded: isExpanded))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 8)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded || summary == nil ? title : "\(title), \(summary ?? "")")
            .accessibilityHint(CollapsibleSection.hint(isExpanded: isExpanded))
            .accessibilityAddTraits(.isButton)
            trailing
        }
        // Declared a container HERE, once, rather than trusting each call site to remember.
        // A bare `.accessibilityIdentifier` on a header like this is INHERITED by everything
        // inside it — which silently renamed both buttons in Today's nudges section, and would
        // have swallowed `homeArrangeButton` the moment this header started carrying it. Three
        // separate instances of that bug this week; the component now makes it impossible.
        .accessibilityElement(children: .contain)
    }
}

extension CollapsibleSectionHeader where Trailing == EmptyView {
    init(title: String, summary: String?, isExpanded: Bool, onToggle: @escaping () -> Void) {
        self.init(
            title: title, summary: summary, isExpanded: isExpanded, onToggle: onToggle,
            trailing: { EmptyView() }
        )
    }
}

#if DEBUG
private struct CollapsibleSectionHeaderPreview: View {
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CollapsibleSectionHeader(
                title: "Your life areas", summary: "5 areas · 3 open",
                isExpanded: expanded, onToggle: { expanded.toggle() }
            )
            if expanded {
                Text("…the section's content…")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bentoCard()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.pageBackground)
    }
}

#Preview("Light") { CollapsibleSectionHeaderPreview().preferredColorScheme(.light) }
#Preview("Dark") { CollapsibleSectionHeaderPreview().preferredColorScheme(.dark) }
#endif
