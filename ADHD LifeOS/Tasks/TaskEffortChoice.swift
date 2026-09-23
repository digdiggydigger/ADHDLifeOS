//
//  TaskEffortChoice.swift
//  ADHD LifeOS
//

import Foundation

// RED SCAFFOLD — compiles, deliberately wrong. Replaced in the GREEN commit.
enum TaskEffortChoice: Equatable, CaseIterable {
    case fifteen
    case thirty
    case hour

    static let standard: TaskEffortChoice = .hour
    var title: String { "" }
    var seconds: Int { 0 }
}
