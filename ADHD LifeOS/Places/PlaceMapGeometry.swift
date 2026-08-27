//
//  PlaceMapGeometry.swift
//  ADHD LifeOS
//

import Foundation

/// A map span in degrees, kept framework-free so the arithmetic below tests without MapKit
/// (the `PlaceCoordinate` arrangement). Converted at the view boundary.
struct PlaceMapSpan: Equatable, Sendable {
    let latitudeDelta: Double
    let longitudeDelta: Double
}

/// Radius in metres → map span in degrees, so the picker opens with the place's circle at a
/// legible size and re-frames when the radius changes.
///
/// Degrees-per-metre is not constant: longitude degrees shrink toward the poles by cos(latitude),
/// which is both why this needs real arithmetic and where its one dangerous edge lives —
/// cos(90°) is 0, and an unguarded division there yields an infinite span and a blank map.
enum PlaceMapGeometry {
    /// One degree of latitude, near enough everywhere.
    static let metresPerDegreeLatitude: Double = 111_320

    /// Room around the circle so the radius reads as a radius rather than filling the frame.
    static let paddingFactor: Double = 2.5

    /// The ceiling that keeps a high-latitude span finite. 180° is already half the globe — far
    /// past the point where a wider span tells anyone anything.
    static let maximumLongitudeDelta: Double = 180

    static func span(fittingRadiusMetres radius: Double, atLatitude latitude: Double) -> PlaceMapSpan {
        let latitudeDelta = (radius * 2 * paddingFactor) / metresPerDegreeLatitude

        // cos() collapses toward the poles; floor it before dividing so the result stays finite,
        // then clamp, so both the arithmetic and the output are safe.
        let radians = latitude * .pi / 180
        let shrink = max(abs(cos(radians)), 0.000001)
        let longitudeDelta = min(latitudeDelta / shrink, maximumLongitudeDelta)

        return PlaceMapSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
}
