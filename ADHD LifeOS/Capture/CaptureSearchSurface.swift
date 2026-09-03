//
//  CaptureSearchSurface.swift
//  ADHD LifeOS
//

import SwiftUI

/// The full-screen search surface for the capture inbox — the same shape as `TaskSearchSurface`,
/// and for the same reason: the ROW that opens it is app-level (it shares a line with the capture
/// disc in `RootBottomOverlay`), while the SURFACE is screen-level, because this is where the
/// captures are.
///
/// **Search deliberately looks at the whole inbox, not the visible filter.** The inbox has its own
/// unprocessed/archived filter, and a search that silently obeyed it would answer "no matches" for
/// a capture the user can see they wrote. The result count says how many, and that is the honest
/// contract for a search field: it searches the captures, not the current view of them.
struct CaptureSearchSurface: View {
    @ObservedObject var service: CaptureInboxService
    @ObservedObject var searchModel: AppSearchModel
    let lifeAreas: [LifeArea]
    let allTags: [Tag]
    let onOpen: (Capture) -> Void

    @FocusState private var isFieldFocused: Bool

    private var results: [Capture] {
        CaptureSearchRefinement.apply(captures: service.captures, searchText: searchModel.query)
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
        // The keyboard belongs here, not to the row that opened this — one tap and you are typing.
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
                    AppSearchScope.captures.placeholder ?? "",
                    text: $searchModel.query
                )
                .focused($isFieldFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("captureSearchField")
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
                    .accessibilityIdentifier("captureSearchClearButton")
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
            .accessibilityIdentifier("captureSearchCancelButton")
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

    /// Says what it searches before anything is typed, rather than showing a blank sheet — and it
    /// says the awkward part out loud, because a photo capture with no words in it is findable
    /// only by the placeholder the row displays for it.
    private var prompt: some View {
        message(
            glyph: "magnifyingglass",
            title: "Search your captures",
            detail: "Matches whatever a capture shows in the inbox — its title, its own words, or"
                + " the placeholder a wordless one is listed under."
        )
        .accessibilityIdentifier("captureSearchPrompt")
    }

    private var empty: some View {
        message(
            glyph: "questionmark.circle",
            title: "Nothing matches “\(trimmedQuery)”",
            detail: "Try a shorter word, or part of one."
        )
        .accessibilityIdentifier("captureSearchEmptyState")
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
                Text(CaptureSearchCopy.resultCount(results.count))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("captureSearchResultCount")
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, capture in
                        // The SAME row the inbox draws, so a result cannot come to look like
                        // something other than the thing it is.
                        CaptureRowView(
                            capture: capture,
                            lifeAreas: lifeAreas,
                            tags: CaptureRowPresentation.tags(for: capture, from: allTags),
                            places: service.places
                        ) {
                            searchModel.close()
                            onOpen(capture)
                        }
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
        .scrollDismissesKeyboard(.immediately)
    }
}

/// The result count's wording, out of the view body so it is checkable.
enum CaptureSearchCopy {
    static func resultCount(_ count: Int) -> String {
        count == 1 ? "1 match" : "\(count) matches"
    }
}

extension View {
    /// Presents `CaptureSearchSurface` when the shared model says search opened.
    ///
    /// A modifier rather than a `fullScreenCover` written inline, for one blunt reason:
    /// `CaptureInboxView` sits at SwiftLint's 250-line `type_body_length` ceiling, and this keeps
    /// both the presentation AND the `@EnvironmentObject` that drives it out of that budget. The
    /// model is read here rather than passed in, so the inbox holds no search state of its own.
    func captureSearchSurface(
        service: CaptureInboxService,
        lifeAreas: [LifeArea],
        allTags: [Tag],
        opening inspected: Binding<Capture?>
    ) -> some View {
        modifier(
            CaptureSearchPresentation(
                service: service, lifeAreas: lifeAreas, allTags: allTags, inspected: inspected
            )
        )
    }
}

private struct CaptureSearchPresentation: ViewModifier {
    @ObservedObject var service: CaptureInboxService
    let lifeAreas: [LifeArea]
    let allTags: [Tag]
    /// The inbox's own "which capture is open" state, set straight from a result tap — a binding
    /// rather than a closure so the call site stays one line inside a tight body budget.
    @Binding var inspected: Capture?

    @EnvironmentObject private var searchModel: AppSearchModel

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: searchModel.surfacePresentation) {
            CaptureSearchSurface(
                service: service,
                searchModel: searchModel,
                lifeAreas: lifeAreas,
                allTags: allTags,
                onOpen: { inspected = $0 }
            )
        }
    }
}
