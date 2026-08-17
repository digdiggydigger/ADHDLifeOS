//
//  TagDedup.swift
//  ADHD LifeOS
//

import Foundation

/// Before inserting a new tag, mobile must check it against the already-fetched tag list by
/// exact (case-sensitive) name match — `tags` has a `unique(user_id, name)` constraint, and
/// the DB comparison is case-sensitive, so this mirrors that exactly rather than guessing at
/// a friendlier case-insensitive rule.
enum TagDedup {
    static func matchExisting(tags: [Tag], name: String) -> Tag? {
        tags.first { $0.name == name }
    }
}
