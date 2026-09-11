//
//  ConfettiPhysicsTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-1's model: where one piece of confetti is at one instant. The numbers are
//  the prototype's E chose from by video (`handoff/SESSION-OPENER-confirm-celebration-design.md`),
//  so these pin the maths that produced what E approved, not a taste of their own.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ConfettiPhysicsTests: XCTestCase {

    private func piece(
        origin: CGPoint = CGPoint(x: 100, y: 200),
        velocity: CGVector = .zero,
        delay: TimeInterval = 0,
        lifetime: TimeInterval = 3,
        spinStart: Double = 0,
        spinRate: Double = 0,
        tumbleRate: Double = 0,
        tumblePhase: Double = 0,
        flutter: Double = 0,
        flutterRate: Double = 0,
        flutterPhase: Double = 0
    ) -> ConfettiPiece {
        ConfettiPiece(
            origin: origin, velocity: velocity, delay: delay, lifetime: lifetime,
            size: CGSize(width: 8, height: 5), shape: .rectangle, colorName: "AreaWorkVivid",
            spinStart: spinStart, spinRate: spinRate, tumbleRate: tumbleRate, tumblePhase: tumblePhase,
            flutterAmplitude: flutter, flutterRate: flutterRate, flutterPhase: flutterPhase
        )
    }

    // MARK: - Launch and life

    /// At the instant it launches a piece is exactly at its origin, unrotated past its start and
    /// fully opaque — flutter included, which is why flutter eases in rather than starting at
    /// full sway.
    func testAPieceIsAtItsOriginTheMomentItLaunches() throws {
        let launched = piece(
            velocity: CGVector(dx: 300, dy: -400), delay: 0.25, spinStart: 1, spinRate: 5,
            flutter: 12, flutterRate: 4, flutterPhase: 1.1
        )
        let state = try XCTUnwrap(
            ConfettiPhysics.state(of: launched, at: 0.25),
            "A piece does not exist at the moment its delay ends."
        )
        XCTAssertEqual(state.position.x, 100, accuracy: 1e-9, "The piece jumped sideways on launch.")
        XCTAssertEqual(state.position.y, 200, accuracy: 1e-9)
        XCTAssertEqual(state.rotation, 1, accuracy: 1e-9)
        XCTAssertEqual(state.opacity, 1, accuracy: 1e-9)
    }

    /// Before its delay and after its life a piece is not drawn at all. The middle is asserted too,
    /// so a model that never draws anything cannot pass.
    func testNothingIsDrawnBeforeItsDelayOrAfterItsLife() {
        let delayed = piece(delay: 0.5, lifetime: 3)
        XCTAssertNil(ConfettiPhysics.state(of: delayed, at: 0.49), "A piece is drawn before its delay.")
        XCTAssertNotNil(ConfettiPhysics.state(of: delayed, at: 2), "A piece in mid-flight is not drawn.")
        XCTAssertNil(ConfettiPhysics.state(of: delayed, at: 3.51), "A piece outlives its lifetime.")
    }

    // MARK: - Flight

    /// The record's closed form, evaluated by hand at one second. This is the test that holds
    /// gravity (520) and drag (2.2) to the values E's prototype used.
    func testTheFlightIsTheRecordsClosedForm() throws {
        let thrown = piece(origin: CGPoint(x: 50, y: 60), velocity: CGVector(dx: 200, dy: -300))
        let state = try XCTUnwrap(ConfettiPhysics.state(of: thrown, at: 1))
        let damping = 1 - exp(-2.2)
        XCTAssertEqual(state.position.x, 50 + 200 / 2.2 * damping, accuracy: 1e-6)
        XCTAssertEqual(
            state.position.y, 60 + (-300 - 520 / 2.2) / 2.2 * damping + 520 / 2.2,
            accuracy: 1e-6,
            "The vertical flight is not the record's drag-damped fall, so pieces rise and land"
                + " differently from what E chose."
        )
    }

    /// Thrown upward, a piece first rises, then gravity wins and it falls past where it started.
    func testGravityWinsSoEveryPieceEventuallyFalls() throws {
        let thrown = piece(velocity: CGVector(dx: 0, dy: -900), lifetime: 10)
        let early = try XCTUnwrap(ConfettiPhysics.state(of: thrown, at: 0.1))
        let late = try XCTUnwrap(ConfettiPhysics.state(of: thrown, at: 3))
        XCTAssertLessThan(early.position.y, 200, "A piece thrown upward did not rise.")
        XCTAssertGreaterThan(late.position.y, 300, "A thrown piece never falls back down the screen.")
    }

    /// Linear drag caps sideways travel at `vₓ / k`: the cannons' fastest piece crosses the screen
    /// and then hangs, instead of flying off the far edge.
    func testDragBoundsHowFarAPieceCanTravelSideways() throws {
        let fired = piece(velocity: CGVector(dx: 1900, dy: 0), lifetime: 10)
        let state = try XCTUnwrap(ConfettiPhysics.state(of: fired, at: 9))
        let travelled = Double(state.position.x) - 100
        XCTAssertLessThan(travelled, 1900 / 2.2, "Sideways travel is not bounded by drag.")
        XCTAssertGreaterThan(travelled, 0.99 * 1900 / 2.2, "Drag stops the piece far short of its bound.")
    }

    // MARK: - Look

    /// Fully opaque until the last 0.7 s of its life, then a linear fade to nothing.
    func testAPieceFadesOnlyOverTheLastSevenTenths() throws {
        let short = piece(lifetime: 3)
        let middle = try XCTUnwrap(ConfettiPhysics.state(of: short, at: 2))
        let halfway = try XCTUnwrap(ConfettiPhysics.state(of: short, at: 2.65))
        let end = try XCTUnwrap(ConfettiPhysics.state(of: short, at: 3))
        XCTAssertEqual(middle.opacity, 1, accuracy: 1e-9, "A piece fades long before its life ends.")
        XCTAssertEqual(halfway.opacity, 0.5, accuracy: 1e-9)
        XCTAssertEqual(end.opacity, 0, accuracy: 1e-9)
    }

    /// Turning over squashes a piece horizontally, floored at 0.15 so it never vanishes edge-on.
    func testTumbleNeverTurnsAPieceFullyEdgeOn() throws {
        let turning = piece(lifetime: 4, tumbleRate: 1, tumblePhase: 0)
        let edgeOn = try XCTUnwrap(ConfettiPhysics.state(of: turning, at: .pi / 2))
        let flat = try XCTUnwrap(ConfettiPhysics.state(of: turning, at: .pi))
        XCTAssertEqual(edgeOn.tumbleScale, 0.15, accuracy: 1e-9, "A piece vanishes when edge-on.")
        XCTAssertEqual(flat.tumbleScale, 1, accuracy: 1e-9)
    }

    /// Sway reaches full strength over the first 0.6 s: half of it at 0.3 s.
    func testFlutterEasesInRatherThanJumping() throws {
        let swaying = piece(flutter: 10, flutterRate: 0, flutterPhase: .pi / 2)
        let easing = try XCTUnwrap(ConfettiPhysics.state(of: swaying, at: 0.3))
        let full = try XCTUnwrap(ConfettiPhysics.state(of: swaying, at: 1))
        XCTAssertEqual(easing.position.x, 105, accuracy: 1e-9, "Sway does not ease in over 0.6 s.")
        XCTAssertEqual(full.position.x, 110, accuracy: 1e-9)
    }
}
