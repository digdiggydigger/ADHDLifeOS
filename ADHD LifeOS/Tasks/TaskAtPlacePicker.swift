//
//  TaskAtPlacePicker.swift
//  ADHD LifeOS
//
//  The at-place picker row (block 4a) — where a task can be DONE, the forward link arrival
//  triggers surface. Its own file (rather than lines in `TaskDetailView`) for that file's
//  length budget; the `LifeAreaPicker` Menu-in-a-Form pattern, minus the archived logic
//  places don't have.
//

import SwiftUI

struct TaskAtPlacePicker: View {
    let places: [Place]
    @Binding var selection: UUID?
    let accessibilityID: String

    /// Stable, name-ordered — the places list is small (20-region budget keeps it so), and
    /// alphabetical is the order the Places screen itself shows.
    private var orderedPlaces: [Place] {
        places.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var selectedLabel: String {
        guard let selection, let place = places.first(where: { $0.id == selection }) else {
            return "None"
        }
        return place.emoji.map { "\($0) \(place.name)" } ?? place.name
    }

    var body: some View {
        Menu {
            Button { selection = nil } label: {
                rowLabel(text: "None", isSelected: selection == nil)
            }
            ForEach(orderedPlaces) { place in
                Button { selection = place.id } label: {
                    rowLabel(
                        text: place.emoji.map { "\($0) \(place.name)" } ?? place.name,
                        isSelected: selection == place.id
                    )
                }
            }
        } label: {
            // `LabeledContent` for the §7 house reason: it reflows at accessibility Dynamic Type
            // sizes instead of clipping into narrow columns.
            LabeledContent("At Place", value: selectedLabel)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier(accessibilityID)
    }

    @ViewBuilder
    private func rowLabel(text: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(text, systemImage: "checkmark")
        } else {
            Text(text)
        }
    }
}

#if DEBUG
private struct TaskAtPlacePickerPreviewHost: View {
    @State private var selection: UUID?
    let places: [Place]

    init(places: [Place], initialSelection: UUID? = nil) {
        self.places = places
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        Form {
            TaskAtPlacePicker(places: places, selection: $selection, accessibilityID: "preview")
        }
    }
}

#Preview("Light") {
    TaskAtPlacePickerPreviewHost(places: [
        Place(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒"
        ),
        Place(
            id: UUID(), name: "The Office",
            coordinate: PlaceCoordinate(latitude: 51.5203, longitude: -0.0986),
            radiusMetres: 200, emoji: "💼"
        )
    ])
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskAtPlacePickerPreviewHost(places: [])
        .preferredColorScheme(.dark)
}
#endif
