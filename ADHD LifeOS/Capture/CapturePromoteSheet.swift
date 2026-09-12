//
//  CapturePromoteSheet.swift
//  ADHD LifeOS
//
//  B6's deferred promote form: "with the area already decided, it needs a title and a date, and
//  nothing else". The native form carries priority as well (ported behaviour, kept deliberately);
//  the title derives from the capture and the life area arrives from the detail's Filed-in card.
//

import SwiftUI

struct CapturePromoteSheet: View {
    /// **R-e.** This sheet closes itself the moment a promote succeeds, and it draws its own
    /// celebration layer — so without a beat here the Create Task pop is thrown onto a surface that
    /// is already leaving, and the user sees nothing at all. E's design record put the alternative
    /// plainly: hold briefly, or have no pop on Create Task.
    ///
    /// The pop is 1.0 s long, so this shows roughly the first half of it. That is the trade R-e
    /// makes: a sheet that lingers a full second after a create reads as unresponsive.
    static let popHold: TimeInterval = 0.45

    let capture: Capture
    /// The Filed-in card's committed value at the moment the sheet opened — the area the new task
    /// inherits.
    let lifeAreaId: UUID?
    @ObservedObject var service: CaptureInboxService
    /// Runs after a successful promote, once this sheet has dismissed itself — the detail screen
    /// uses it to pop as well, since its capture no longer has an inbox to return to.
    let onPromoted: () -> Void

    @State private var priority: TaskPriority = .p4
    @State private var hasDueDate = false
    @State private var dueDate: Date?
    /// S2's effort chip — lands on the task's `focus_duration_seconds`. `nil` = skipped.
    @State private var effortSeconds: Int?
    /// True from the instant a promote succeeds until this sheet's own scheduled dismiss runs.
    ///
    /// **The hold has to make the sheet inert, not merely late.** `popHold` buys the pop 0.45 s by
    /// SCHEDULING the dismiss, which would otherwise leave a sheet whose work is already committed
    /// sitting there fully interactive: cancel or swipe it away in that window and the orphaned
    /// hold still runs `onPromoted()`, which `CaptureDetailView` uses to pop the detail screen — so
    /// the screen would leave half a second after the user's own dismiss, unasked. Tapping Create
    /// Task again in that window is refused by the service, correctly, but renders the refusal as
    /// an error inside a sheet that is mid-teardown.
    @State private var hasPromoted = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                // 24 between the macro groups (§2): the task's name, the decision card, and
                // the commit row read as three thoughts, not one run-on.
                VStack(alignment: .leading, spacing: 24) {
                    titlePreview
                    form
                    // The partial-failure path must stay reachable: "task created, but couldn't
                    // mark processed" keeps the sheet open with this warning, and the retry tap
                    // goes back through the same service path (`pendingTaskIdsByCapture`).
                    if let warningMessage = service.warningMessage {
                        Label(warningMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color("StateWarn"))
                            .accessibilityIdentifier("capturePromoteWarningMessage")
                    }
                    if let errorMessage = service.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("capturePromoteErrorMessage")
                    }
                    CreateTaskButton(
                        lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate, onCreateTask: promote
                    )
                    .disabled(hasPromoted)
                    Text("The new task inherits this capture's life area, tags and notes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .navigationTitle("Make a task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(hasPromoted)
                        .accessibilityIdentifier("capturePromoteCancelButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
        // Only for the beat the pop needs. A swipe here would land `onPromoted()` on a screen the
        // user has already left.
        .interactiveDismissDisabled(hasPromoted)
        // A sheet sits above the root layer, so a celebration asked for from Create Task needs a
        // layer here to be seen at all. In practice this one draws the POP: a full-screen
        // celebration requested while this sheet is frontmost is HELD by the centre, because the
        // sheet dismisses itself on a successful promote and would cut a 5.4 s burst short.
        .overlay { CelebrationLayer(surface: .promoteSheet) }
    }

    private var titlePreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("New task")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(CaptureRowPresentation.primaryText(for: capture))
                .font(.title3.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            effortRow
            whenRow
            priorityRow
            dueDateRow
        }
        .bentoCard()
    }

    /// The one chip the whole sheet wears (E's verdict on the first cut, 2026-08-31: "it looks
    /// horrible"). `ChoiceChipButtonStyle` styles only the BACKGROUND — the sprint planner pads
    /// its own labels, and this sheet passed bare `Button("10 min")`s, so the fill hugged the
    /// text and the selected state read as a text highlight. Equal-width 44pt labels give the
    /// style something chip-shaped to wrap (§3's target is the VISIBLE control, not an
    /// invisible frame around a sliver).
    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: isSelected))
    }

    /// S2's chips: an effort estimate the new task keeps as its sprint target, and coarse
    /// due-date presets (the exact-date picker below still takes any date).
    private var effortRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Effort")
                .sectionLabel()
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach([600, 900, 1800], id: \.self) { seconds in
                    chip(
                        MomentumScoreboard.effortLabel(seconds: seconds) ?? "",
                        isSelected: effortSeconds == seconds
                    ) {
                        effortSeconds = effortSeconds == seconds ? nil : seconds
                    }
                }
                chip("Unsure", isSelected: effortSeconds == nil) {
                    effortSeconds = nil
                }
            }
            .accessibilityIdentifier("capturePromoteEffortChips")
        }
    }

    private var whenRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When")
                .sectionLabel()
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                chip("Today", isSelected: isDueSet(daysFromNow: 0)) { setDue(daysFromNow: 0) }
                chip("Tomorrow", isSelected: isDueSet(daysFromNow: 1)) { setDue(daysFromNow: 1) }
                chip("Someday", isSelected: !hasDueDate) {
                    hasDueDate = false
                    dueDate = nil
                }
            }
            .accessibilityIdentifier("capturePromoteWhenChips")
        }
    }

    /// P1–P4 as the same chips as everything above — the first cut left the default `Picker`
    /// outside any `Form`, which renders as a bare "P4 ⌄" floating with no label at all.
    private var priorityRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .sectionLabel()
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(TaskPriority.allCases, id: \.self) { option in
                    chip(option.rawValue.uppercased(), isSelected: priority == option) {
                        priority = option
                    }
                }
            }
            .accessibilityIdentifier("capturePromotePriorityPicker")
        }
    }

    /// The refinement under the When presets: an exact calendar date. The toggle mirrors the
    /// chips (Someday clears it; Today/Tomorrow set it), so it carries a label that says what
    /// it really is rather than a second spelling of "due".
    private var dueDateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Due date")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Toggle(isOn: $hasDueDate) {
                Text("Exact day")
                    .font(.subheadline)
            }
            .onChange(of: hasDueDate) { newValue in
                dueDate = newValue ? (dueDate ?? Date()) : nil
            }
            if hasDueDate {
                DatePicker(
                    "Date",
                    selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }),
                    displayedComponents: .date
                )
                .font(.subheadline)
            }
        }
    }

    private func setDue(daysFromNow: Int) {
        hasDueDate = true
        dueDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())
    }

    private func isDueSet(daysFromNow: Int) -> Bool {
        guard hasDueDate, let dueDate else { return false }
        let target = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
        return Calendar.current.isDate(dueDate, inSameDayAs: target)
    }

    private func promote(lifeAreaId: UUID?, priority: TaskPriority, dueDate: Date?) async -> Bool {
        let succeeded = await service.promoteToTask(
            capture: capture, lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate,
            focusDurationSeconds: effortSeconds
        )
        if succeeded {
            // Before the hold, not inside it: the window this closes is the whole of the hold.
            hasPromoted = true
            // Scheduled rather than awaited: `create(popping:)` is still waiting on this call to
            // return before it pops, so holding the await here would delay the paper by the hold
            // instead of the dismiss, and the sheet would still be gone first.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Self.popHold * 1_000_000_000))
                dismiss()
                onPromoted()
            }
        }
        return succeeded
    }
}
