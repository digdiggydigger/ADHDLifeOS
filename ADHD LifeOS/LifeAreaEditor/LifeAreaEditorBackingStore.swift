//
//  LifeAreaEditorBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseLifeAreaEditorClientAdapter` actually uses, expressed as a
/// protocol so the adapter is testable without a network or a signed-in user.
///
/// **Why a seam exists here at all.** `FirebaseManager` is a `final class` with a `private init`
/// and a `shared` singleton; an adapter holding it concretely cannot be exercised by a test at any
/// price. That left every `Firebase*ClientAdapter` at ~0% coverage — and thin is not the same as
/// trivial, since these adapters hand-build the field dictionaries Firestore writes.
///
/// **Why it is this narrow.** `FirebaseManager` spans ~40 methods across every feature. One
/// protocol over all of them would force each fake to stub work it has nothing to do with, and
/// would let any adapter reach any collection. One small store per adapter keeps each fake honest
/// and mirrors the `*ClientAdapting` split one layer up.
///
/// **Why `fields` stays `[String: Any]`.** A typed payload would hide the literal Firestore key
/// strings, and those are the thing most worth asserting on: a wrong key raises nothing, it writes
/// a field nothing reads. Passing the dictionary through keeps it visible to a recording fake.
protocol LifeAreaEditorBackingStore {
    /// Every area, active and archived — the editor lists archived ones so they can be unarchived.
    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea]
    /// Creates or fully overwrites one area.
    func saveLifeArea(_ area: LifeArea) async throws
    /// Partial update of one area: rename, recolour, archive toggle.
    func updateLifeArea(id: UUID, fields: [String: Any]) async throws
}

extension FirebaseManager: LifeAreaEditorBackingStore {}
