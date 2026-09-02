//
//  PlaceAppDestinationStep.swift
//  ADHD LifeOS
//
//  One directory app's deep destinations (F-AppDirectory-2-Links). Split out of
//  `PlaceAppPickerView` when that file passed SwiftLint's 400-line ceiling; it was always a
//  self-contained screen, reached now from the row's trailing "more ways in" control rather
//  than by the row tap itself (E's 2026-09-02 call).
//

import SwiftUI

/// One app's destinations: the plain open first (the ADHD-friendly default — skippable in one
/// tap means the DEFAULT is one tap), then the place-prefilled rows, then the type-a-value
/// forms.
@available(iOS 17.0, *)
struct PlaceAppDestinationStep: View {
    let entry: PlaceAppDirectoryEntry
    let placeName: String
    let placeCoordinate: PlaceCoordinate?
    let onJustOpen: () -> Void
    let onPickLink: (PlaceActionDraftLinkPick) -> Void

    @State private var values: [String: String] = [:]

    var body: some View {
        Form {
            Section {
                Button {
                    Haptics.play(.selection)
                    onJustOpen()
                } label: {
                    Label("Just open \(entry.name)", systemImage: "arrow.up.forward.app")
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier("destinationJustOpenButton")
            }
            if placeCoordinate != nil {
                directionsSection
            }
            ForEach(entry.destinations, id: \.self) { destination in
                destinationSection(for: destination)
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The free synergy: this editor already knows where the place IS.
    @ViewBuilder
    private var directionsSection: some View {
        let prefillable = entry.destinations.filter(\.placeCoordinatePrefill)
        if let destination = prefillable.first, let placeCoordinate {
            Section {
                Button {
                    Haptics.play(.selection)
                    let value = PlaceAppDestinationPick.coordinateValue(placeCoordinate)
                    guard let link = destination.resolved(with: value) else { return }
                    onPickLink(
                        PlaceActionDraftLinkPick(
                            displayName: PlaceAppDestinationPick.directionsDisplayName(
                                entry: entry, placeName: placeName
                            ),
                            link: link,
                            scheme: entry.scheme
                        )
                    )
                } label: {
                    Label("Directions to \(placeName)", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier("destinationDirectionsButton")
            } footer: {
                Text("Uses this place's own location — nothing to type.")
            }
        }
    }

    private func destinationSection(for destination: PlaceAppDestinationTemplate) -> some View {
        Section {
            TextField(
                destination.isPassThrough ? "Paste the share link" : "Paste or type it here",
                text: binding(for: destination)
            )
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .accessibilityIdentifier("destinationValueField-\(destination.name)")
            Button {
                Haptics.play(.selection)
                guard let pick = pick(for: destination) else { return }
                onPickLink(pick)
            } label: {
                Text("Add \u{201C}\(destination.name)\u{201D}")
            }
            .disabled(pick(for: destination) == nil)
            .accessibilityIdentifier("destinationAddButton-\(destination.name)")
        } header: {
            Text(destination.name).sectionLabel()
        }
    }

    private func binding(for destination: PlaceAppDestinationTemplate) -> Binding<String> {
        Binding(
            get: { values[destination.name] ?? "" },
            set: { values[destination.name] = $0 }
        )
    }

    private func pick(for destination: PlaceAppDestinationTemplate) -> PlaceActionDraftLinkPick? {
        guard let link = destination.resolved(with: values[destination.name] ?? ""),
              URL(string: link) != nil else { return nil }
        return PlaceActionDraftLinkPick(
            displayName: PlaceAppDestinationPick.displayName(entry: entry, destination: destination),
            link: link,
            scheme: entry.scheme
        )
    }
}
