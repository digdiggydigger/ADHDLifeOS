//
//  DailySummaryView.swift
//  ADHD LifeOS
//

import SwiftUI

/// SwiftUI port of the web prototype's `src/components/DailySummaryView.tsx` — its banner card
/// (badge pill, heavy tight-tracked title, mono caption line), tone toolbar, generate action,
/// four-stat metric strip with tinted icon chips, and the generated-summary sections
/// (`DailySummaryResultCard`).
///
/// Deliberate deviations from the React source, per CLAUDE.md:
/// - §4 zero-hex: the web palette (`#FF5B5B` coral, `#1C1C1A` ink, `#F2EFE9` cream) becomes
///   adaptive semantic color — `.tint` accent, `Color.cardSurface` cards, `.primary`/`.secondary`
///   text — so dark mode is free and correct.
/// - The metric strip still shows the four numbers Home already knows; the richer picture
///   (completions, focus minutes, journal energy) now lives in the generated summary below.
/// - The idle state keeps the local `DailySummaryHeadline` synthesis rather than an empty card:
///   honest, always populated, and free. Generating replaces it.
struct DailySummaryView: View {
    let openTaskCount: Int
    let lifeAreaCount: Int
    let inboxCount: Int
    let dueNudgeCount: Int
    @StateObject private var service: DailySummaryService

    private let metricColumns = [
        GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)
    ]

    /// `service` is injectable for previews and tests; production passes nothing and gets the
    /// live configuration. Owned here rather than by `HomeView` because the summary is this
    /// card's concern alone.
    ///
    /// This `@StateObject` is deliberately **not** what makes a summary survive a tab switch — it
    /// can't: `HomeService.load()` re-runs on every appearance and flips Home's load state back
    /// through `.loading`, which destroys this whole subtree and the state object with it. What
    /// survives is the record itself, which `live()` reads back out of `DailySummarySnapshot` (see
    /// `DailySummaryStore.swift`). That also covers a cold launch, which hoisting ownership up to
    /// `RootView` would not have.
    init(
        openTaskCount: Int,
        lifeAreaCount: Int,
        inboxCount: Int,
        dueNudgeCount: Int,
        service: DailySummaryService? = nil
    ) {
        self.openTaskCount = openTaskCount
        self.lifeAreaCount = lifeAreaCount
        self.inboxCount = inboxCount
        self.dueNudgeCount = dueNudgeCount
        _service = StateObject(wrappedValue: service ?? .live())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            bannerCard
            toneToolbar
            metricStrip
            summaryContent
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: service.state
        )
        .task {
            // Rejoins a generation that was already running when this card was rebuilt, so its
            // result lands here rather than only in storage. A no-op when nothing is in flight,
            // which is the common case — this runs on every appearance.
            await service.reattachIfGenerating()
        }
        .accessibilityIdentifier("homeDailySummary")
    }

    // MARK: - Banner (web: light-card 32pt-radius header with badge, black title, muted sub)

    private var bannerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                Text("Today's Highlights")
                    .sectionLabel()
            }
            .foregroundStyle(.tint)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            // Color.accentColor.opacity, not .tint.opacity — ShapeStyle.opacity is iOS 17+, target is 16.
            .background(Color.accentColor.opacity(0.12), in: Capsule())

            Text("Daily Executive Summary")
                .font(.title.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .lineLimit(2)

            Text("Your day at a glance — wins, open loops, and the next smallest step.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.caption.monospaced().weight(.bold))
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .bentoCard()
    }

    // MARK: - Tone toolbar (web: four pill buttons above the generate action)

    private var toneToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Tone")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                generateButton
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DailySummaryTone.allCases) { tone in
                        toneChip(tone)
                    }
                }
                // Inset so a chip's press-scale isn't clipped by the ScrollView bounds.
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, -4)
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: service.tone
        )
    }

    private func toneChip(_ tone: DailySummaryTone) -> some View {
        Button {
            service.tone = tone
        } label: {
            // Label, not a glyph+text HStack: VoiceOver reads it as one element, and the tone is
            // never conveyed by the glyph alone (§4/§7).
            Label(tone.label, systemImage: tone.systemImage)
                .font(.footnote.weight(.semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: service.tone == tone))
        .accessibilityAddTraits(service.tone == tone ? [.isSelected] : [])
    }

    // MARK: - Generate

    /// Secondary emphasis, matching MANAGE on the Active Goal hero — the same `.bordered` style
    /// that screen already uses for "the other action". Home has exactly one primary action
    /// (START SESSION, `.borderedProminent`), and Generate is not it.
    ///
    /// `.bordered` rather than a hand-rolled capsule for three reasons: the neutral fill with an
    /// accent-tinted label stays legible without competing (the earlier coral-on-coral pill still
    /// read as an accent action); the fill is a system material, so light/dark, increased
    /// contrast, and reduce-transparency are all correct for free rather than hand-mapped (§4);
    /// and it makes this button visibly a sibling of MANAGE, which is what it is.
    ///
    /// §3 deviation, reported: this drops the custom `PressScaleButtonStyle` — a view takes one
    /// `buttonStyle`, and `.bordered` brings its own press state. Matching the established
    /// house pattern for a secondary action beats a bespoke scale here, on the §7 precedent
    /// that native controls win where they are already the house pattern.
    private var generateButton: some View {
        Button {
            Task {
                await service.generate()
                // 30. The summary is a wait — the feel lands when it ACTUALLY finishes, and
                // reports which way it went rather than buzzing success at a failed generate.
                if case .failed = service.state {
                    Haptics.play(.error)
                } else {
                    Haptics.play(.success)
                }
            }
        } label: {
            HStack(spacing: 4) {
                if service.isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                } else {
                    Image(systemName: service.hasSummary ? "arrow.clockwise" : "sparkles")
                        .font(.caption.weight(.bold))
                }
                Text(generateButtonTitle)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
            }
            // 44pt is the §3 hit-target floor, not a visual size — the control keeps its compact
            // caption height while the tappable area meets the guideline. (MANAGE uses 32 here;
            // that is a pre-existing miss and deliberately not copied.)
            .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
        .disabled(service.isGenerating)
        .accessibilityIdentifier("generateDailySummaryButton")
    }

    private var generateButtonTitle: String {
        if service.isGenerating { return "Generating…" }
        return service.hasSummary ? "Regenerate" : "Generate"
    }

    // MARK: - Metrics

    private var metricStrip: some View {
        LazyVGrid(columns: metricColumns, spacing: 16) {
            DailyMetricCard(
                value: "\(openTaskCount)", label: "Open Tasks",
                systemImage: "checkmark.circle.fill", tint: Color("StateGo")
            )
            DailyMetricCard(
                value: "\(dueNudgeCount)", label: "Nudges Due",
                systemImage: "flame.fill", tint: Color("StateRisk")
            )
            DailyMetricCard(
                value: "\(lifeAreaCount)", label: "Life Areas",
                systemImage: "square.grid.2x2.fill", tint: Color("AreaAdminVivid")
            )
            DailyMetricCard(
                value: "\(inboxCount)", label: "Ideas Offloaded",
                systemImage: "tray.fill", tint: Color("StateWarn")
            )
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var summaryContent: some View {
        switch service.state {
        case .idle, .loading:
            // The offline synthesis stays put while generating, so the card never goes blank —
            // trading the honest fallback for a spinner would be a downgrade.
            highlightCard
        case .failed(let message):
            DailySummaryFailureCard(message: message)
        case .loaded(let generated):
            DailySummaryResultCard(generated: generated, copyText: service.copyText)
        }
    }

    /// Idle state: the offline synthesis from real counts. Not a placeholder — a true statement.
    private var highlightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 24, height: 24)
                    .background(.tint, in: Circle())
                Text("Daily Highlight")
                    .sectionLabel()
                    .foregroundStyle(.tint)
            }
            Text(
                DailySummaryHeadline.text(
                    openTasks: openTaskCount,
                    lifeAreas: lifeAreaCount,
                    inbox: inboxCount,
                    dueNudges: dueNudgeCount
                )
            )
            .font(.title3.bold())
            .fixedSize(horizontal: false, vertical: true)
        }
        .bentoCard()
        // The web's accent-bordered highlight box keeps its 2pt accent ring on top of the
        // shared hairline.
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 2)
        )
    }
}

/// One stat card in the metric quick-strip — the web's icon-chip + black number + mono caption
/// row, on the shared card background.
private struct DailyMetricCard: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(
                    tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(label)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .bentoCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}

/// Pure headline synthesis — the offline stand-in shown before the user generates anything, split
/// out so the priority ladder (due nudges → inbox → clean slate → open tasks) is unit-testable
/// without rendering. Deterministic on its inputs; no dates, no randomness.
enum DailySummaryHeadline {
    static func text(openTasks: Int, lifeAreas: Int, inbox: Int, dueNudges: Int) -> String {
        if dueNudges > 0 {
            let noun = dueNudges == 1 ? "1 nudge is" : "\(dueNudges) nudges are"
            return "\(noun) due — a tiny step right now counts."
        }
        if inbox > 0 {
            let phrase = inbox == 1
                ? "1 idea captured — triage it"
                : "\(inbox) ideas captured — triage one"
            return "\(phrase) to clear your head."
        }
        if openTasks == 0 {
            return "A clean slate today. Add one small task to build momentum."
        }
        let tasks = openTasks == 1 ? "1 open task" : "\(openTasks) open tasks"
        let areas = lifeAreas == 1 ? "1 area" : "\(lifeAreas) areas"
        return "\(tasks) across \(areas) — start with the smallest one."
    }
}

#if DEBUG
/// Preview-only provider: no Firestore, one fixed day's worth of material.
private struct PreviewDailySummaryDataProvider: DailySummaryDataProviding {
    func loadRequest(tone: DailySummaryTone, date: Date) async throws -> DailySummaryRequest {
        DailySummaryRequest(
            date: date, tone: tone,
            tasks: [
                TaskItem(
                    id: UUID(), lifeAreaId: nil, title: "Ship the capture fix",
                    status: .done, priority: .p1, dueDate: nil, completedAt: date
                ),
                TaskItem(
                    id: UUID(), lifeAreaId: nil, title: "Draft the summary prompt",
                    status: .open, priority: .p2, dueDate: nil
                )
            ],
            focusSessions: [], journalEntries: [], capturesCount: 2,
            lifeAreaNames: [:]
        )
    }
}

@MainActor
private func previewSummaryService() -> DailySummaryService {
    DailySummaryService(
        provider: PreviewDailySummaryDataProvider(),
        generator: StubDailySummaryGenerator()
    )
}
#endif

#Preview("Light") {
    ScrollView {
        DailySummaryView(
            openTaskCount: 7, lifeAreaCount: 4, inboxCount: 3, dueNudgeCount: 0,
            service: previewSummaryService()
        )
        .padding(16)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ScrollView {
        DailySummaryView(
            openTaskCount: 0, lifeAreaCount: 6, inboxCount: 2, dueNudgeCount: 2,
            service: previewSummaryService()
        )
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
