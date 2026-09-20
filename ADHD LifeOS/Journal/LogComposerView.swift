//
//  LogComposerView.swift
//  ADHD LifeOS
//
//  The v3 entry composer (E's 2026-08-25 note): the stock Form became a dedicated S1-style
//  screen — one question at a time, chips over pickers, the append-only rule said before the
//  save. Copy lives in `LogComposerCopy` (pure, tested); the service machinery is unchanged.
//

import SwiftUI

struct LogComposerView: View {
    @ObservedObject var journalService: JournalService
    let lifeAreas: [LifeArea]
    /// `F-C2-DraftsToInbox`: the seam an abandoned entry is filed through. Optional with an inert
    /// default so every preview builds unchanged; the app's one call site is asserted by
    /// `ComposerDraftCallSiteTests`.
    ///
    /// **`var`, not `let`, and that is load-bearing rather than sloppy.** This view has no
    /// hand-written `init`, so it relies on the synthesised memberwise one — and Swift EXCLUDES a
    /// `let` that already carries a default value from that initialiser, since it could never be
    /// assigned. Declared `let` here, the argument simply would not exist and `JournalView` could
    /// not pass it. It must also be declared BEFORE `onCreated`, because the memberwise
    /// initialiser takes its parameters in declaration order and `onCreated` is the trailing
    /// closure at the call site.
    var captureClient: CaptureClientAdapting?
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draftTagName = ""

    /// A composer that SUBMITTED files no draft. `JournalService.createLog` clears `composerBody`
    /// itself on success, so this is belt as well as braces — but it states the intent where a
    /// reader can see it, rather than resting on another type's side effect.
    @State var didSubmit = false

    @Environment(\.recordAction) var recordAction
    @Environment(\.openCapture) var openCapture

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(LogComposerCopy.guidance)
                        .font(.footnote)
                        .composerSoftInk(softInk)
                    ComposerTextBox(
                        placeholder: "What's on your mind?",
                        placeholderAsset: JournalComposerPalette.placeholderAsset(
                            for: journalService.composerType
                        ),
                        text: $journalService.composerBody,
                        accessibilityID: "logComposerBodyField",
                        surfaceAsset: JournalComposerPalette.writingSurfaceAsset(
                            for: journalService.composerType
                        ),
                        ruled: JournalComposerPalette.isPaper(for: journalService.composerType)
                    )
                    typeSection
                    if journalService.composerType == .journal {
                        JournalEnergyMoodPicker(
                            energyLevel: $journalService.composerEnergyLevel,
                            moodEmoji: $journalService.composerMoodEmoji,
                            palette: chips
                        )
                    }
                    areaSection
                    tagsSection
                    locationSection
                    if let errorMessage = journalService.createErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("logComposerErrorMessage")
                    }
                }
                .padding(16)
                // The pad as an OBJECT rather than as the whole screen. In light mode the chrome
                // behind it is the same gold, so this reads full-bleed exactly as it did before;
                // at night the chrome goes dark and the pad becomes a lit page on a dark desk.
                // That is what buys the night face a real gold instead of a brown: it reuses the
                // day face's gold-and-dark-ink pairing, which already clears AA, rather than
                // hunting in the mid-tone valley where no ink passes.
                .background(
                    Color(JournalComposerPalette.backgroundAsset(for: journalService.composerType)),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                // Set ONCE, on the container: `.secondary` resolves against the environment's
                // foreground, so every label inside — including the ones owned by
                // `ComposerSectionHeader` and `JournalEnergyMoodPicker` — turns warm ink instead
                // of system grey, which on gold read as mud. E: "the text that sits on the yellow
                // background gets lost". Cheaper and far more consistent than threading an ink
                // parameter through three shared components.
                .foregroundStyle(Color(JournalComposerPalette.inkAsset(for: journalService.composerType)))
            }
            // The surface follows the KIND of entry (E, 2026-08-28): a journal entry writes on a
            // gold pad, a log keeps the ordinary page. Springs rather than cuts, because the chips
            // that change it sit right above the background they change and a hard flash between
            // them reads as a glitch; honoured against Reduce Motion like every other transition
            // (§5).
            .background(
                Color(JournalComposerPalette.chromeAsset(for: journalService.composerType))
                    .ignoresSafeArea()
            )
            .animation(
                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
                value: journalService.composerType
            )
            .safeAreaInset(edge: .bottom) { footerBar }
            .task { await journalService.refreshComposerLocationPreview() }
            // **`F-C2-DraftsToInbox`, and this composer's text was the one already half-safe.**
            // It lives on `JournalService`, which outlives the view, so it survived Cancel WITHIN
            // a session and was lost only when the app quit (JRNL-01). Filing it makes that
            // durable — and clearing it afterwards is what stops the same words existing twice,
            // once as a capture and once waiting in the service for the next time this opens.
            .onDisappear { fileDraftIfNeeded() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // **"Close", not "Cancel"** (E, round 2). `sheets.md › Best practices`:
                    // Cancel means *without saving*, and this control no longer discards.
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("logComposerCloseButton")
                }
                ToolbarItem(placement: .principal) {
                    Text("New entry")
                        .font(.headline)
                }
            }
        }
    }

    /// Log or Journal as chips, each explained in plain words underneath — the split is E's own
    /// data model, but "which one do I want" shouldn't need remembering the schema.
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "What kind of entry?", titleAsset: softInk)
            HStack(spacing: 8) {
                typeChip(.log, label: "Log")
                typeChip(.journal, label: "Journal")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("logComposerTypePicker")
            Text(LogComposerCopy.explainer(for: journalService.composerType))
                .font(.footnote)
                .composerSoftInk(softInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func typeChip(_ type: LogType, label: String) -> some View {
        let selected = journalService.composerType == type
        return Button {
            Haptics.play(.selection)
            journalService.composerType = type
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: selected, palette: chips))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("logComposerType-\(type.rawValue)")
    }

    @ViewBuilder
    private var areaSection: some View {
        if !lifeAreas.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ComposerSectionHeader(title: "Life area", detail: "optional", detailAsset: softInk, titleAsset: softInk)
                ComposerAreaChips(
                    lifeAreas: lifeAreas.filter { !$0.archived },
                    noSelectionLabel: "No life area",
                    palette: chips,
                    selection: $journalService.composerLifeAreaId
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("logComposerLifeAreaPicker")
            }
        }
    }

    /// Tags at the point of writing (E's 2026-08-25 note) — and ONLY there: logs are append-only,
    /// so an entry can never be tagged after the fact. Same chips + inline create as the other
    /// composers, riding `JournalService.composerTagIds` into the create payload.
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "Tags", detail: "optional", detailAsset: softInk, titleAsset: softInk)
            if !journalService.availableTags.isEmpty {
                FlowingChips(spacing: 8) {
                    ForEach(journalService.availableTags) { tag in
                        tagChip(tag)
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("New tag", text: $draftTagName)
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 36)
                    .background(
                        Color(chips.quietSurface),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .accessibilityIdentifier("logComposerNewTagField")
                Button("Add") {
                    Task {
                        if await journalService.createTagForComposer(name: draftTagName) != nil {
                            draftTagName = ""
                        }
                    }
                }
                .font(.caption.weight(.semibold))
                .disabled(draftTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("logComposerAddTagButton")
            }
        }
    }

    /// The per-entry location switch (E, 2026-08-31) — the capture composer's control, worn in
    /// this screen's wardrobe, and upgraded to NAME the place it resolves while you're still
    /// writing. Only shown when permission can actually deliver, like captures: a switch that
    /// cannot do anything invites a tap that achieves nothing silently. The subtitle takes
    /// `softInk`, never `.secondary` — on the gold pad `.secondary` is the ink at half alpha,
    /// the exact failure `softInk` exists to prevent.
    @ViewBuilder
    private var locationSection: some View {
        if CaptureLocationChoice.isAvailable(
            authorization: CoreLocationFixProvider.shared.authorizationState
        ) {
            Toggle(isOn: $journalService.composerAttachLocation) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remember where I am")
                            .font(.subheadline)
                        Text(LogComposerCopy.locationSubtitle(
                            attach: journalService.composerAttachLocation,
                            placeLine: JournalTimeline.placeLine(
                                placeId: journalService.composerLocationPreview?.placeId,
                                places: journalService.places
                            )
                        ))
                        .font(.footnote)
                        .composerSoftInk(softInk)
                    }
                } icon: {
                    Image(systemName: journalService.composerAttachLocation
                          ? "location.fill" : "location.slash")
                        .foregroundStyle(
                            Color(journalService.composerAttachLocation
                                  ? chips.selectedFill : chips.quietLabel)
                        )
                }
            }
            .tint(Color(chips.selectedFill))
            .onChange(of: journalService.composerAttachLocation) { _ in
                Haptics.play(.selection)
                Task { await journalService.refreshComposerLocationPreview() }
            }
            .accessibilityIdentifier("logComposerLocationToggle")
        }
    }

    private func tagChip(_ tag: Tag) -> some View {
        let selected = journalService.composerTagIds.contains(tag.id)
        return Button {
            Haptics.play(.light)
            if selected {
                journalService.composerTagIds.removeAll { $0 == tag.id }
            } else {
                journalService.composerTagIds.append(tag.id)
            }
        } label: {
            Text(tag.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(selected ? chips.selectedLabel : chips.quietLabel))
                .padding(.horizontal, 8)
                .frame(minHeight: 36)
                .background(
                    Color(selected ? chips.selectedFill : chips.quietSurface),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("logComposerTagChip-\(tag.id)")
    }

    private var footerBar: some View {
        VStack(spacing: 8) {
            // The footer hangs off `.safeAreaInset`, OUTSIDE the container that sets the page's
            // ink, so it inherits nothing and has to be handed one explicitly. Left alone it was a
            // cool system grey on warm gold at 2.47:1 — and only by DAY: at night it lands on the
            // near-black chrome and measures 6.12:1, so a dark-only check passes it. It was the
            // last cool grey left on this screen (E's device shots, 2026-08-28).
            //
            // And it takes the CHROME ink, not the page's — this bar sits on the desk. The page
            // ink here measures 1.33:1 at night. See `chromeInkAsset(for:)`.
            Text(LogComposerCopy.footer)
                .font(.caption2)
                .composerSoftInk(chromeInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(journalService.isCreating ? "Saving…" : "Save entry") {
                Task {
                    if await journalService.createLog() {
                        didSubmit = true
                        Haptics.play(.solid)
                        onCreated()
                        dismiss()
                    } else {
                        Haptics.play(.error)
                    }
                }
            }
            .buttonStyle(PrimaryActionButtonStyle(palette: chips))
            .disabled(!journalService.isComposerBodyValid || journalService.isCreating)
            .accessibilityIdentifier("logComposerSubmitButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .modifier(ComposerFooterBackground(type: journalService.composerType))
    }
}

#if DEBUG
private struct PreviewJournalClientAdapting: JournalClientAdapting {
    func fetchLifeAreas() async throws -> [LifeArea] { [] }
    func fetchLogs() async throws -> [Log] { [] }
    func fetchFocusSessions() async throws -> [CompletedFocusSession] { [] }
    func fetchCaptures() async throws -> [Capture] { [] }
    func fetchLocationEvents() async throws -> [LocationEvent] { [] }
    func fetchRoutineRuns() async throws -> [RoutineRunRecord] { [] }
    func fetchPlaces() async throws -> [Place] { [] }
    func fetchAllTags() async throws -> [Tag] { [Tag(id: UUID(), name: "errands")] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
    func deleteLog(id: UUID) async throws {}
}

#Preview("Light") {
    LogComposerView(
        journalService: JournalService(client: PreviewJournalClientAdapting()),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]
    ) {}
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LogComposerView(
        journalService: JournalService(client: PreviewJournalClientAdapting()),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]
    ) {}
    .preferredColorScheme(.dark)
}
#endif
