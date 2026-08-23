//
//  FirestoreErrorMapping.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Firestore's own error facts, in one place.
///
/// Only one Firestore failure is worth distinguishing today: a missing document, which the Nudges
/// adapter turns into `NudgesServiceError.notFound` so the UI can say "this nudge no longer exists"
/// rather than showing a generic failure. Everything else collapses.
///
/// `errorDomain` and `notFoundCode` are exposed so a test can build a genuine Firestore-shaped
/// error without importing the SDK (the unit-test target deliberately does not link it — see
/// `FirestoreDocumentCoder`). Hardcoding `"FIRFirestoreErrorDomain"` and `5` in a test would work
/// today and drift silently if either ever changed.
enum FirestoreErrorMapping {
    static var errorDomain: String { FirestoreErrorDomain }
    static var notFoundCode: Int { FirestoreErrorCode.notFound.rawValue }

    /// Whether this is Firestore's "the document does not exist". The domain check is load-bearing:
    /// a code-5 failure from anywhere else is not a missing document, and reporting it as one would
    /// tell the user something was deleted when it wasn't.
    static func isNotFound(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == errorDomain && nsError.code == notFoundCode
    }
}
