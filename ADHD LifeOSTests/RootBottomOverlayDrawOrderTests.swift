//
//  RootBottomOverlayDrawOrderTests.swift
//  ADHD LifeOSTests
//
//  F-FanXAtRest. While the fan is open the × drops into the space the (faded) cards still hold,
//  and the cards are subview 1 — drawn after, so OVER, the disc row. `RootBottomOverlay` raises
//  the disc row with `.zIndex(1)` so the × passes in front of a fading card rather than behind it.
//
//  A call-site test can only prove the modifier is written. Whether a custom `Layout` honours
//  `zIndex` at all is a property of SwiftUI, so this renders the real `RootBottomOverlayArrangement`
//  in both configurations and reads the pixel where the two pieces overlap. The pair is the
//  point: the control (no `zIndex`) must show the cards on top, or the render could not tell the
//  two apart and the positive would be vacuous.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RootBottomOverlayDrawOrderTests: XCTestCase {

    func testARaisedDiscRowDrawsInFrontOfTheCardsWhereTheyOverlap() throws {
        XCTAssertEqual(
            try overlapBrightness(raisesTheDiscRow: true), 0, accuracy: 0.05,
            "`zIndex` on the disc row did not bring it in front of the cards inside the Layout."
        )
    }

    func testWithoutZIndexTheCardsDrawOverTheDiscRow() throws {
        XCTAssertEqual(
            try overlapBrightness(raisesTheDiscRow: false), 1, accuracy: 0.05,
            "The control failed: with no `zIndex` the cards should cover the disc row, so the"
                + " render cannot distinguish the two orders and the test above proves nothing."
        )
    }

    /// Stacked with the fan open: a 60pt black "disc row" and a 100pt white "cards" column in a
    /// 100 × 168 container. The disc row lands at y 108–168, x 40–100, entirely inside the cards'
    /// y 68–168 — so (70, 138) is covered by both, and its colour says which is in front.
    private func overlapBrightness(raisesTheDiscRow: Bool) throws -> CGFloat {
        let view = RootBottomOverlayArrangement(arrangement: .stacked, fanIsOpen: true) {
            Color.black
                .frame(width: 60, height: 60)
                .zIndex(raisesTheDiscRow ? 1 : 0)
            Color.white
                .frame(width: 100, height: 100)
        }
        .frame(width: 100, height: 168)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.cgImage else {
            throw RenderError.nothingRendered
        }
        return try Self.brightness(of: image, column: 70, row: 138)
    }

    /// One pixel, read by drawing the image into a 1 × 1 bitmap. Core Graphics' origin is the
    /// bottom-left, so a top-down `row` is flipped on the way in.
    private static func brightness(of image: CGImage, column: Int, row: Int) throws -> CGFloat {
        var pixel = [UInt8](repeating: 0, count: 4)
        let drawn: Bool = pixel.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.translateBy(x: CGFloat(-column), y: CGFloat(-(image.height - 1 - row)))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard drawn else { throw RenderError.noBitmap }
        return CGFloat(pixel[0]) / 255
    }

    private enum RenderError: Error {
        case nothingRendered
        case noBitmap
    }
}
