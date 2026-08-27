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
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draftTagName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(LogComposerCopy.guidance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ComposerTextBox(
                        placeholder: "What's on your mind?",
                        text: $journalService.composerBody,
                        accessibilityID: "logComposerBodyField"
                    )
                    typeSection
                    if journalService.composerType == .journal {
                        JournalEnergyMoodPicker(
                            energyLevel: $journalService.composerEnergyLevel,
                            moodEmoji: $journalService.composerMoodEmoji
                        )
                    }
                    areaSection
                    tagsSection
                    if let errorMessage = journalService.createErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("logComposerErrorMessage")
                    }
                }
                .padding(16)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { footerBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
            ComposerSectionHeader(title: "What kind of entry?")
            HStack(spacing: 8) {
                typeChip(.log, label: "Log")
                typeChip(.journal, label: "Journal")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("logComposerTypePicker")
            Text(LogComposerCopy.explainer(for: journalService.composerType))
                .font(.footnote)
                .foregroundStyle(.secondary)
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
        .buttonStyle(ChoiceChipButtonStyle(isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("logComposerType-\(type.rawValue)")
    }

    @ViewBuilder
    private var areaSection: some View {
        if !lifeAreas.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ComposerSectionHeader(title: "Life area", detail: "optional")
                ComposerAreaChips(
                    lifeAreas: lifeAreas.filter { !$0.archived },
                    noSelectionLabel: "No life area",
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
            ComposerSectionHeader(title: "Tags", detail: "optional")
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
                        Color("CardSurfaceSecondary"),
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
                .foregroundStyle(selected ? AreaPalette.work.onColor : Color("LabelSecondary"))
                .padding(.horizontal, 8)
                .frame(minHeight: 36)
                .background(
                    selected
                        ? AnyShapeStyle(Color.accentColor)
                        : AnyShapeStyle(Color("CardSurfaceSecondary")),
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
            Text(LogComposerCopy.footer)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(journalService.isCreating ? "Saving…" : "Save entry") {
                Task {
                    if await journalService.createLog() {
                        Haptics.play(.solid)
                        onCreated()
                        dismiss()
                    } else {
                        Haptics.play(.error)
                    }
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!journalService.isComposerBodyValid || journalService.isCreating)
            .accessibilityIdentifier("logComposerSubmitButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .composerFooterSurface()
    }
}

#if DEBUG
private struct PreviewJournalClientAdapting: JournalClientAdapting {
    func fetchLifeAreas() async throws -> [LifeArea] { [] }
    func fetchLogs() async throws -> [Log] { [] }
    func fetchFocusSessions() async throws -> [CompletedFocusSession] { [] }
    func fetchCaptures() async throws -> [Capture] { [] }
    func fetchAllTags() async throws -> [Tag] { [Tag(id: UUID(), name: "errands")] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
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
