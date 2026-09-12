//
//  CelebrationPopSource.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: how a control tells the centre WHERE it was tapped, so the mini confetti
//  pop leaves from the thing that was pressed rather than from the middle of the screen.
//
//  **Nothing uses this yet, by design.** The nine pop sites are `F-CTACelebrations-4`, and E picks
//  the pop's look by LOOKING at a render on a real `TaskRow` before any of them is wired. What is
//  built here is the geometry, which that choice does not affect: a control's GLOBAL centre, which
//  is the only frame of reference the layer drawing the paper can rely on — the row that was tapped
//  and the layer are rarely in the same space, and a `TaskDetail` Form row is drawn by the ROOT
//  layer precisely so row clipping cannot cut the pop in half.
//
//  **No `#available` (§7.1).** `onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0 in
//  the 26.5 SDK, so the floor gets the same code and no tier adds anything.
//

import SwiftUI

/// What a site is handed: one call, which throws the pop from wherever the control currently is.
struct CelebrationPopHandle {
    /// Call inside the same closure as the site's own haptic, so the feel and the paper can never
    /// drift apart.
    let pop: () -> Void
}

/// Wraps a control, tracks its centre, and hands the content a handle to pop from it.
struct CelebrationPopSource<Content: View>: View {
    @ViewBuilder let content: (CelebrationPopHandle) -> Content

    @Environment(\.celebrate) private var celebrate
    @State private var center: CGPoint?

    var body: some View {
        content(CelebrationPopHandle(pop: { celebrate.request(.pop, at: center) }))
            .celebrationPopOrigin { center = $0 }
    }
}

extension View {
    /// Reports this view's centre in GLOBAL coordinates whenever it moves, so a pop thrown from it
    /// lands where the user's thumb was and not where the view used to be.
    func celebrationPopOrigin(_ action: @escaping (CGPoint) -> Void) -> some View {
        onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .global)
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: {
            action($0)
        }
    }
}
