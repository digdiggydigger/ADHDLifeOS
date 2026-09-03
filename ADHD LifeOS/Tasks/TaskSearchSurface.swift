//
//  TaskSearchSurface.swift
//  ADHD LifeOS
//

import SwiftUI

/// The full-screen search surface for Tasks — E's pick over an in-place filter: field at the top,
/// results below, Cancel.
///
/// **The surface is screen-level while the row is app-level, and that split is the point.** The
/// ROW has to line up with the capture disc, which is drawn once in `RootBottomOverlay`, so it
/// lives there and the two are laid out by one `HStack` rather than by agreeing on a number. The
/// SURFACE needs this screen's DATA, and hoisting `TasksService` up to `RootView` to reach it
/// would be a large invasive change for the sake of a text field. So each searchable screen
/// presents its own surface and reads the query from the shared model.
///
/// Filtering goes through `TaskListRefinement.apply(tasks:searchText:)` — the same pure rule the
/// board itself uses. A second filter here would be a second definition of "matches", and they
/// would disagree the first time either changed.
struct TaskSearchSurface: View {
    @ObservedObject var service: TasksService
    @ObservedObject var searchModel: AppSearchModel
    let onInspect: (TaskItem) -> Void

    @FocusState private var isFieldFocused: Bool

    private var results: [TaskItem] {
        TaskListRefinement.apply(tasks: service.tasks, searchText: searchModel.query)
    }

    private var trimmedQuery: String {
        searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            field
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        // The keyboard belongs HERE, not to the row that opened this. Raising it on appear is the
        // whole reason a full-screen surface beats an in-place filter: one tap, and you are typing.
        .task { isFieldFocused = true }
    }

    // MARK: - The field

    private var field: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("LabelSecondary"))
                TextField(
                    AppSearchScope.tasks.placeholder ?? "",
                    text: $searchModel.query
                )
                .focused($isFieldFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("taskSearchField")
                if !searchModel.query.isEmpty {
                    Button {
                        Haptics.play(.light)
                        searchModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityIdentifier("taskSearchClearButton")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: AppSearchRowMetrics.fieldHeight)
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

            Button("Cancel") {
                Haptics.play(.light)
                searchModel.close()
            }
            .font(.callout)
            .frame(minHeight: 44)
            .accessibilityIdentifier("taskSearchCancelButton")
        }
        .padding(16)
    }

    // MARK: - Results

    @ViewBuilder
    private var content: some View {
        if trimmedQuery.isEmpty {
            prompt
        } else if results.isEmpty {
            empty
        } else {
            list
        }
    }

    /// Before anything is typed the surface says what it searches rather than showing a blank
    /// sheet — the same posture as the Tools page's empty state.
    private var prompt: some View {
        message(
            glyph: "magnifyingglass",
            title: "Search your tasks",
            detail: "Matches on the task's title, across every status — not just what the board is showing."
        )
        .accessibilityIdentifier("taskSearchPrompt")
    }

    private var empty: some View {
        message(
            glyph: "questionmark.circle",
            title: "Nothing matches “\(trimmedQuery)”",
            detail: "Try a shorter word, or part of one."
        )
        .accessibilityIdentifier("taskSearchEmptyState")
    }

    private func message(glyph: String, title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: glyph)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                Text(TaskSearchCopy.resultCount(results.count))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("taskSearchResultCount")
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, task in
                        TaskRow(
                            task: task,
                            lifeArea: service.lifeAreas.first { $0.id == task.lifeAreaId },
                            showsSprintStart: false,
                            onClose: { Task { await service.close(task) } },
                            onInspect: {
                                searchModel.close()
                                onInspect(task)
                            }
                        )
                        if index != results.indices.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .background(
                    Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.cardBorder, lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        // The surface covers the tab bar and the capture disc entirely, so it needs neither
        // clearance — the reason sheets are absent from `CaptureDiscClearanceCallSiteTests`.
        .scrollDismissesKeyboardIfAvailable()
    }
}

/// The result count's wording, out of the view body so it is checkable.
enum TaskSearchCopy {
    static func resultCount(_ count: Int) -> String {
        count == 1 ? "1 match" : "\(count) matches"
    }
}

private extension View {
    /// `scrollDismissesKeyboard` is iOS 16+, but the interactive mode this wants reads best with
    /// `.immediately` on a results list. Gated because §7's floor is 16.0 and the modifier's
    /// behaviour is only what we want from 16 up — below that the extension is a no-op.
    @ViewBuilder
    func scrollDismissesKeyboardIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            scrollDismissesKeyboard(.immediately)
        } else {
            self
        }
    }
}
