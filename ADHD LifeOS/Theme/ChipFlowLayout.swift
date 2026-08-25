//
//  ChipFlowLayout.swift
//  ADHD LifeOS
//

import SwiftUI

/// The wrap arithmetic behind the chip flow — pure geometry, so the rules (left-to-right, wrap on
/// overflow, row height from the tallest chip, an oversize chip alone on its row) are unit-tested
/// while the `Layout` below stays a thin caller.
enum ChipFlowArithmetic {
    struct Placement: Equatable {
        let origins: [CGPoint]
        let size: CGSize
    }

    static func placement(of sizes: [CGSize], spacing: CGFloat, maxWidth: CGFloat) -> Placement {
        var origins: [CGPoint] = []
        var cursorX: CGFloat = 0
        var cursorY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for size in sizes {
            if cursorX > 0, cursorX + spacing + size.width > maxWidth {
                cursorY += rowHeight + spacing
                cursorX = 0
                rowHeight = 0
            }
            let originX = cursorX > 0 ? cursorX + spacing : 0
            origins.append(CGPoint(x: originX, y: cursorY))
            cursorX = originX + size.width
            rowHeight = max(rowHeight, size.height)
            widestRow = max(widestRow, cursorX)
        }

        guard !origins.isEmpty else { return Placement(origins: [], size: .zero) }
        // Row Y origins are the row TOP; chips in one row share it, and the total height is the
        // last row's top plus its height.
        return Placement(origins: origins, size: CGSize(width: widestRow, height: cursorY + rowHeight))
    }
}

/// A true content-hugging flow (E's 2026-08-25 note): each chip is exactly as wide as its words
/// and the row wraps when full — replacing the adaptive-grid arrangement whose two rigid columns
/// left a field of empty space around short chips. `Layout` is iOS 16.0, inside the deployment
/// floor.
struct ChipFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let placement = ChipFlowArithmetic.placement(
            of: subviews.map { $0.sizeThatFits(.unspecified) },
            spacing: spacing,
            maxWidth: proposal.width ?? .infinity
        )
        return placement.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placement = ChipFlowArithmetic.placement(
            of: subviews.map { $0.sizeThatFits(.unspecified) },
            spacing: spacing,
            maxWidth: bounds.width
        )
        for (subview, origin) in zip(subviews, placement.origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }
}
