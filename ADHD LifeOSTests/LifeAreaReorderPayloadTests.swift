//
//  LifeAreaReorderPayloadTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// TRAP 1 + TRAP 3 proof: the reorder payload must be the COMPLETE set (active-first, then archived
/// in their existing relative order), emitted as LOWERCASE id strings, with no duplicates.
final class LifeAreaReorderPayloadTests: XCTestCase {

    private func area(_ name: String, sortOrder: Int, archived: Bool = false) -> LifeArea {
        LifeArea(id: UUID(), name: name, colour: "🎯", sortOrder: sortOrder, archived: archived)
    }

    func testCompleteOrder_activeFirstThenArchivedInRelativeOrder() {
        let one = area("A", sortOrder: 0)
        let two = area("B", sortOrder: 1)
        // archived given out of sortOrder to prove they're re-sorted into relative order:
        let archivedHigh = area("X", sortOrder: 9, archived: true)
        let archivedLow = area("Y", sortOrder: 5, archived: true)

        // active dragged into two, one order:
        let order = LifeAreaReorderPayload.completeOrder(
            activeInNewOrder: [two, one], archived: [archivedHigh, archivedLow]
        )

        XCTAssertEqual(order, [two.id, one.id, archivedLow.id, archivedHigh.id],
                       "active in the given order, then archived by sortOrder")
    }

    func testCompleteOrder_isTheCompleteSetWithNoDuplicates() {
        let one = area("A", sortOrder: 0)
        let two = area("B", sortOrder: 1)
        let archived = area("Z", sortOrder: 2, archived: true)

        let order = LifeAreaReorderPayload.completeOrder(activeInNewOrder: [one, two], archived: [archived])

        XCTAssertEqual(Set(order), [one.id, two.id, archived.id], "every current id present")
        XCTAssertEqual(order.count, Set(order).count, "no duplicates")
    }

    func testWireIDs_areLowercase() {
        let ids = [UUID(), UUID()]
        let wire = LifeAreaReorderPayload.wireIDs(ids)

        XCTAssertEqual(wire, ids.map { $0.uuidString.lowercased() })
        XCTAssertTrue(wire.allSatisfy { $0 == $0.lowercased() })
    }
}
