//
//  FirestoreDocumentCoder.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// The one place a domain model crosses into or out of a Firestore document.
///
/// Extracted from `FirebaseManager.save` so the codec is reachable from a test. The unit-test
/// target deliberately does **not** link the Firebase SDK — these are static products, and linking
/// one into both the app and the test bundle it hosts realises every Objective-C class twice — so
/// tests reach the real encoder through this type instead of importing `FirebaseFirestore`.
///
/// That indirection buys something the existing model coding tests cannot get: they round-trip
/// through `JSONDecoder`, which is not the codec the app runs on. `Firestore.Encoder` writes a
/// `Date` as a `Timestamp` rather than a number, and documents come back through
/// `DocumentSnapshot.data(as:)`, which runs `Firestore.Decoder`. A model can satisfy the JSON tests
/// and still write the wrong thing to Firestore.
enum FirestoreDocumentCoder {
    /// Encodes a model into the field dictionary Firestore stores.
    static func encode<Model: Encodable>(_ value: Model) throws -> [String: Any] {
        try Firestore.Encoder().encode(value)
    }

    /// Decodes a model from a raw document dictionary. Mirrors `DocumentSnapshot.data(as:)`, which
    /// runs this same decoder over a snapshot's fields — so a document assembled by hand exercises
    /// the production decode path without a network round trip.
    static func decode<Model: Decodable>(_ type: Model.Type, from document: [String: Any]) throws -> Model {
        try Firestore.Decoder().decode(type, from: document)
    }

    /// Unwraps a Firestore `Timestamp` field back to a `Date`, for callers that work in plain
    /// Foundation types and never import the SDK. `nil` when the field is absent or is not a
    /// timestamp — which is itself the interesting answer when checking what a model encoded to.
    static func date(from value: Any?) -> Date? {
        (value as? Timestamp)?.dateValue()
    }

    /// Whether a field value is the "erase this field" sentinel (`FieldValue.delete()`).
    ///
    /// Worth distinguishing rather than checking for `is FieldValue`: `delete()` and
    /// `serverTimestamp()` are the same type, and writing the wrong one stamps a field instead of
    /// erasing it.
    static func isFieldDelete(_ value: Any?) -> Bool {
        (value as? FieldValue)?.isEqual(FieldValue.delete()) ?? false
    }

    /// Whether a field value is the server-clock sentinel (`FieldValue.serverTimestamp()`).
    static func isServerTimestamp(_ value: Any?) -> Bool {
        (value as? FieldValue)?.isEqual(FieldValue.serverTimestamp()) ?? false
    }
}
