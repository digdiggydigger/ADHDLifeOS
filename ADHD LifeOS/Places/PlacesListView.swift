//
//  PlacesListView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The places E has defined. Reached from Settings, alongside Life Areas and Tags — the
/// established home for "things you configure once and pick from later".
///
/// Gated to iOS 17 with the rest of the Places feature — see `PlaceMapPicker` for the §7 note.
@available(iOS 17.0, *)
struct PlacesListView: View {
    @StateObject private var service: PlacesService
    @State private var editingPlace: Place?
    @State private var isCreating = false
    @State private var pendingDeletion: Place?

    init(client: PlacesClientAdapting) {
        _service = StateObject(wrappedValue: PlacesService(client: client))
    }

    var body: some View {
        content
            .navigationTitle("Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.play(.light)
                        isCreating = true
                    } label: {
                        Label("Add place", systemImage: "plus")
                    }
                    .accessibilityIdentifier("placesAddButton")
                }
            }
            .sheet(isPresented: $isCreating) {
                PlaceEditorView(existing: nil, onSave: save, isSaving: service.isMutating)
            }
            .sheet(item: $editingPlace) { place in
                PlaceEditorView(existing: place, onSave: save, isSaving: service.isMutating)
            }
            .confirmationDialog(
                "Delete this place?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let place = pendingDeletion {
                        Haptics.play(.solid)
                        Task { await service.delete(place) }
                    }
                    pendingDeletion = nil
                }
                .accessibilityIdentifier("placesConfirmDeleteButton")
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("Anything already tagged with this place keeps its coordinates.")
            }
            .task { await service.load() }
            // The house refresh contract: a screen root subscribes so any write anywhere lands here.
            .onReceive(DataChangeSignal.debouncedPublisher()) { _ in
                Task { await service.load() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch service.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("placesLoadingIndicator")
        case .failed(let message):
            VStack(spacing: 8) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await service.load() } }
                    .buttonStyle(MomentumBorderedButtonStyle(minHeight: 44))
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("placesErrorMessage")
        case .loaded:
            if service.places.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No places yet")
                .font(.headline)
            Text("Add the spots you keep coming back to — home, the office, the gym — "
                 + "and Momentum can tag what happens there.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("placesEmptyState")
    }

    private var list: some View {
        List {
            // Loud ONLY when it matters. Under the cap this is a quiet footer at the bottom; over
            // it, the warning moves to the top where it cannot be scrolled past — because past 20
            // some places silently stop triggering, and that is the one thing E must not discover
            // by noticing a nudge that never came.
            if PlaceMonitoringCapacity.isOverCapacity(placeCount: service.places.count) {
                Label(
                    PlaceMonitoringCapacity.summary(placeCount: service.places.count),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.footnote)
                .foregroundStyle(Color("StateWarn"))
                .accessibilityIdentifier("placesCapacityWarning")
            }
            ForEach(service.places) { place in
                Button {
                    Haptics.play(.light)
                    editingPlace = place
                } label: {
                    PlaceRow(place: place)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("placeRow-\(place.id)")
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Haptics.play(.warning)
                        pendingDeletion = place
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            if let errorMessage = service.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color("StateRisk"))
                    .accessibilityIdentifier("placesInlineError")
            }
            if !PlaceMonitoringCapacity.isOverCapacity(placeCount: service.places.count),
               let summary = PlaceMonitoringCapacity.summaryIfWorthShowing(placeCount: service.places.count) {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("placesCapacityCounter")
            }
        }
    }

    private func save(_ place: Place) async -> Bool {
        await service.save(place)
    }
}

/// One place: identity glyph, name, and the radius that will actually be geofenced.
@available(iOS 17.0, *)
private struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 8) {
            Text(place.emoji ?? "📍")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Color("CardSurfaceSecondary"), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.callout)
                    .foregroundStyle(Color("LabelPrimary"))
                    .lineLimit(1)
                Text("\(Int(place.radiusMetres)) m radius")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }
}
