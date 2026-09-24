//
//  PlaceMapPicker.swift
//  ADHD LifeOS
//

import MapKit
import SwiftUI

/// Tap the map to drop the pin; the circle shows the radius that will actually be geofenced.
///
/// **The history of the Places gate.** On 2026-08-27 E authorised a §7 deviation: this view, and
/// with it the whole Places feature, was gated to iOS 17 above the project's floor of the time,
/// because `MapProxy.convert(_:from:)` — the only supported way to turn a tap into a map
/// coordinate — arrives in 17, and E chose the modern API over an `MKMapView` bridge. That made
/// Places the app's one "absent" feature (§7.1). On 2026-09-23 E raised the minimum to iOS 18
/// (`F-Floor18`), so the gate is gone and Places is universal; the record of the deviation stays
/// here because it is why the feature was ever optional.
///
/// `MapCircle` renders the radius natively, which matters more than it sounds: the circle IS the
/// trigger boundary, so seeing it at true scale is the difference between a fence that fires
/// where E expects and one that doesn't.
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
