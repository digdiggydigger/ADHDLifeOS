//
//  PlaceMapPicker.swift
//  ADHD LifeOS
//

import MapKit
import SwiftUI

/// Tap the map to drop the pin; the circle shows the radius that will actually be geofenced.
///
/// **§7 deviation, reported and authorised by E on 2026-08-27:** this view is gated to iOS 17,
/// above the project's 16.0 floor. On iOS 16 SwiftUI has no supported way to turn a tap into a
/// map coordinate — `MapProxy.convert(_:from:)` arrives in 17 — so true tap-to-drop would need an
/// `MKMapView` wrapped in a `UIViewRepresentable`. E chose the modern API over that bridge. The
/// project target stays 16.0 (raising it would churn the 40-odd `#available` gates across the
/// shipped redesign); only the Places feature is gated, so an iOS 16 device simply never sees it.
///
/// `MapCircle` renders the radius natively, which matters more than it sounds: the circle IS the
/// trigger boundary, so seeing it at true scale is the difference between a fence that fires
/// where E expects and one that doesn't.
@available(iOS 17.0, *)
struct PlaceMapPicker: View {
    @Binding var coordinate: PlaceCoordinate?
    let radiusMetres: Double

    @State private var camera: MapCameraPosition = .automatic
    /// Set once so re-rendering (a radius change, a keyboard) doesn't yank the camera back while
    /// E is panning around looking for the spot.
    @State private var hasFramedInitialCoordinate = false

    var body: some View {
        MapReader { proxy in
            Map(position: $camera) {
                if let coordinate {
                    let center = CLLocationCoordinate2D(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    Marker("", coordinate: center)
                        .tint(Color.accentColor)
                    MapCircle(center: center, radius: radiusMetres)
                        .foregroundStyle(Color.accentColor.opacity(0.18))
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onTapGesture { screenPoint in
                guard let tapped = proxy.convert(screenPoint, from: .local) else { return }
                Haptics.play(.light)
                coordinate = PlaceCoordinate(latitude: tapped.latitude, longitude: tapped.longitude)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 0.5)
        )
        .accessibilityIdentifier("placeMapPicker")
        .accessibilityLabel(coordinate == nil ? "Map. No location chosen yet." : "Map. Location chosen.")
        .accessibilityHint("Tap the map to set this place's location.")
        .task(id: framingKey) { frameIfNeeded() }
    }

    /// Re-frames when the pin moves far, or when the radius changes enough to matter — not on
    /// every keystroke elsewhere in the editor.
    private var framingKey: String {
        guard let coordinate else { return "none" }
        return "\(coordinate.latitude.rounded())-\(coordinate.longitude.rounded())-\(radiusMetres)"
    }

    private func frameIfNeeded() {
        guard let coordinate else { return }
        let span = PlaceMapGeometry.span(
            fittingRadiusMetres: radiusMetres,
            atLatitude: coordinate.latitude
        )
        // Only the FIRST framing snaps; later ones are animated so a radius change reads as a
        // zoom rather than a jump.
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
        )
        if hasFramedInitialCoordinate {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
                camera = .region(region)
            }
        } else {
            camera = .region(region)
            hasFramedInitialCoordinate = true
        }
    }
}
