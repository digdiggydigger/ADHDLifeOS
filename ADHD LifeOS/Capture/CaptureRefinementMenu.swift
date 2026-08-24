//
//  CaptureRefinementMenu.swift
//  ADHD LifeOS
//
//  The sort + kind-filter control shared by the Capture Inbox and the Captures tab (E's
//  2026-08-24 direction). One Menu, two sections; the icon fills when any refinement is active
//  so a filtered list can never masquerade as the whole one.
//

import SwiftUI

struct CaptureRefinementMenu: View {
    @ObservedObject var service: CaptureInboxService

    var body: some View {
        Menu {
            Section("Sort") {
                Button {
                    service.sortNewestFirst = true
                } label: {
                    menuRow("Newest first", isSelected: service.sortNewestFirst)
                }
                Button {
                    service.sortNewestFirst = false
                } label: {
                    menuRow("Oldest first", isSelected: !service.sortNewestFirst)
                }
            }
            Section("Show") {
                Button {
                    service.kindFilter = nil
                } label: {
                    menuRow("All kinds", isSelected: service.kindFilter == nil)
                }
                ForEach(CaptureKind.allCases, id: \.self) { kind in
                    Button {
                        service.kindFilter = kind
                    } label: {
                        menuRow(
                            CaptureRowPresentation.kindLabel(for: kind) + "s",
                            isSelected: service.kindFilter == kind
                        )
                    }
                }
            }
        } label: {
            Image(
                systemName: isRefined
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
                .font(.title3)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(isRefined ? "Sort and filter — a filter is active" : "Sort and filter")
        .accessibilityIdentifier("captureRefinementMenu")
    }

    private var isRefined: Bool {
        !service.sortNewestFirst || service.kindFilter != nil
    }

    @ViewBuilder
    private func menuRow(_ text: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(text, systemImage: "checkmark")
        } else {
            Text(text)
        }
    }
}
