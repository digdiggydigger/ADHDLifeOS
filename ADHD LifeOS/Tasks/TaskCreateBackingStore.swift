//
//  TaskCreateBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseTaskCreateClientAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
///
/// Narrowed to the create alone by `F-D1-ComposerBothDoors`, with the adapter's tag methods.
/// `FirebaseManager` keeps `fetchTags`/`createTagDeduplicating`/`addTagId` — other seams use them.
protocol TaskCreateBackingStore {
    func createTask(_ task: TaskDetail) async throws
}

extension FirebaseManager: TaskCreateBackingStore {}
