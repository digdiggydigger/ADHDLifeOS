//
//  LifeAreaReorderPayload.swift
//  ADHD LifeOS
//

import Foundation

/// Pure builder for the `PATCH /life-areas/reorder` body. Kept out of the adapter so the whole of
/// TRAP 1 + TRAP 3 is unit-testable without a network.
///
/// - **TRAP 1 — the payload must be the COMPLETE current set.** `validate_reorder`
///   (`aws-backend/life-os-api/lambda_function.py`) checks set-equality against the user's entire
///   current area set: a missing id, an unknown id, a duplicate, or a non-list all return `400`
///   and nothing is written. So the archived ids must be appended — in their existing relative
///   order (by `sortOrder`) — after the reordered active ids. Sending only the visible active ids
///   would `400` for any user who has archived anything.
/// - **TRAP 3 — DynamoDB keys are case-sensitive.** Every id goes on the wire lowercased via
///   `UUID.lowercaseUUIDString`; `UUID.uuidString` is UPPERCASE and would fail to match rows that
///   visibly exist.
enum LifeAreaReorderPayload {
    /// The complete reorder: `activeInNewOrder` (already in the on-screen order) followed by the
    /// archived areas in their existing relative order. Returns `UUID`s; the adapter lowercases
    /// them for the wire.
    static func completeOrder(activeInNewOrder: [LifeArea], archived: [LifeArea]) -> [UUID] {
        let archivedInRelativeOrder = archived.sorted { $0.sortOrder < $1.sortOrder }
        return (activeInNewOrder + archivedInRelativeOrder).map(\.id)
    }

    /// The lowercased id strings that go into the request body — the exact wire form.
    static func wireIDs(_ order: [UUID]) -> [String] {
        order.map(\.lowercaseUUIDString)
    }
}
