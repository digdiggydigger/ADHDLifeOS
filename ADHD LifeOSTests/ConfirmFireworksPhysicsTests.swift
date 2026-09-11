//
//  ConfirmFireworksPhysicsTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-2's model: where a shell and its sparks are at any instant. Pure functions
//  of time, like the confetti, so a frame at `t` is computed rather than accumulated. The numbers
//  are the prototype's E chose from (`handoff/SESSION-OPENER-confirm-celebration-design.md`,
//  "Fireworks").
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ConfirmFireworksPhysicsTests: XCTestCase {

    /// The prototype's window: an iPhone 17 Pro in points.
    private let canvas = CGSize(width: 393, height: 852)

    private func shell(
        launch: TimeInterval = 1,
        apex: CGPoint = CGPoint(x: 0.5, y: 0.3),
        burst: FireworkShell.Burst = .single,
        colorNames: [String] = ["StateWarnVivid"],
        size: FireworkShell.SizeClass = .big
    ) -> FireworkShell {
        FireworkShell(launch: launch, apex: apex, burst: burst, colorNames: colorNames, size: size)
    }

    private func speed(of spark: ConfettiPiece) -> Double {
        hypot(Double(spark.velocity.dx), Double(spark.velocity.dy))
    }

    private func angle(of spark: ConfettiPiece) -> Double {
        atan2(Double(spark.velocity.dy), Double(spark.velocity.dx))
    }

    // MARK: - The shell's rise

    /// 0.55 s plus a quarter-second for the full height: a low burst is a short climb, a high one
    /// a longer one, so the shells read as fired rather than placed.
    func testAShellRisesLongerTheHigherItBursts() {
        let physics = ConfirmFireworksPhysics.self
        XCTAssertEqual(physics.riseDuration(of: shell(apex: CGPoint(x: 0.5, y: 0.30))), 0.725, accuracy: 1e-9)
        XCTAssertEqual(physics.riseDuration(of: shell(apex: CGPoint(x: 0.5, y: 0.14))), 0.765, accuracy: 1e-9)
        XCTAssertEqual(
            physics.burstTime(of: shell(launch: 2.6, apex: CGPoint(x: 0.66, y: 0.24))), 3.34, accuracy: 1e-9,
            "The burst is not the launch plus the rise."
        )
    }

    func testAShellLaunchesJustRightOfItsApexFromNearTheBottomEdge() {
        let fired = shell(apex: CGPoint(x: 0.28, y: 0.30))
        let launch = ConfirmFireworksPhysics.launchPoint(of: fired, canvas: canvas)
        XCTAssertEqual(launch.x, 0.30 * 393, accuracy: 1e-6, "The launch point is not 0.02 W right of the apex.")
        XCTAssertEqual(launch.y, 0.96 * 852, accuracy: 1e-6, "The shell does not launch from 0.96 H.")
        let apex = ConfirmFireworksPhysics.apexPoint(of: fired, canvas: canvas)
        XCTAssertEqual(apex.x, 0.28 * 393, accuracy: 1e-6)
        XCTAssertEqual(apex.y, 0.30 * 852, accuracy: 1e-6)
    }

    /// Eased `1 − (1 − u)²`: fast off the ground, slowing to a hang at the apex. Nothing before
    /// launch and nothing after the burst — the shell is gone the moment its sparks exist.
    func testAShellClimbsEasedFromItsLaunchPointToItsApexThenVanishes() throws {
        let fired = shell(launch: 1, apex: CGPoint(x: 0.5, y: 0.3))   // rises 0.725 s
        let physics = ConfirmFireworksPhysics.self
        XCTAssertNil(physics.shellPosition(of: fired, at: 0.99, canvas: canvas), "A shell shows before it launches.")
        let atLaunch = try XCTUnwrap(physics.shellPosition(of: fired, at: 1, canvas: canvas), "No shell at its launch.")
        XCTAssertEqual(atLaunch.y, 0.96 * 852, accuracy: 1e-6)
        let halfway = try XCTUnwrap(physics.shellPosition(of: fired, at: 1 + 0.725 / 2, canvas: canvas))
        let climb = 0.96 * 852 - 0.3 * 852
        XCTAssertEqual(
            halfway.y, 0.96 * 852 - climb * 0.75, accuracy: 1e-6,
            "The rise is not eased: halfway in time should be three-quarters of the way up."
        )
        XCTAssertEqual(
            halfway.x, 0.52 * 393 - 0.02 * 393 * 0.75, accuracy: 1e-6,
            "The shell does not drift from its launch x to its apex x."
        )
        let atBurst = try XCTUnwrap(physics.shellPosition(of: fired, at: 1.725, canvas: canvas))
        XCTAssertEqual(atBurst.y, 0.3 * 852, accuracy: 1e-6, "The shell is not at its apex when it bursts.")
        XCTAssertNil(physics.shellPosition(of: fired, at: 1.7251, canvas: canvas), "A shell is still drawn after it has burst.")
    }

    // MARK: - The sparks

    func testEachSizeClassBurstsIntoTheRecordsSparkCount() {
        let physics = ConfirmFireworksPhysics.self
        XCTAssertEqual(physics.sparks(of: shell(size: .big), index: 0, canvas: canvas).count, 72)
        XCTAssertEqual(physics.sparks(of: shell(size: .medium), index: 0, canvas: canvas).count, 56)
        XCTAssertEqual(physics.sparks(of: shell(size: .small), index: 0, canvas: canvas).count, 40)
    }

    /// Every spark leaves the apex the moment the shell bursts, lives its class's life, and is a
    /// 2.4 pt dot the confetti model can fly — with no spin, tumble or flutter, which are paper's.
    func testSparksLeaveTheApexAtTheBurstAndLiveTheirClassesLife() {
        let fired = shell(launch: 0.3, apex: CGPoint(x: 0.72, y: 0.22), size: .medium)
        let sparks = ConfirmFireworksPhysics.sparks(of: fired, index: 1, canvas: canvas)
        XCTAssertEqual(sparks.count, 56)
        let apex = ConfirmFireworksPhysics.apexPoint(of: fired, canvas: canvas)
        let burst = ConfirmFireworksPhysics.burstTime(of: fired)
        XCTAssertTrue(sparks.allSatisfy { spark in
            abs(spark.origin.x - apex.x) < 1e-9 && abs(spark.origin.y - apex.y) < 1e-9
                && abs(spark.delay - burst) < 1e-9
                && abs(spark.lifetime - 1.3) < 1e-9
                && spark.size == CGSize(width: 2.4, height: 2.4)
                && spark.flutterAmplitude == 0 && spark.spinRate == 0 && spark.tumbleRate == 0
        }, "A spark is not launched from the apex at the burst with its class's life.")
    }

    /// Class speed × (0.8 + 0.2 × hash): every spark within a fifth of its class, so a ring stays
    /// a ring rather than a smear — and evenly spread around the circle.
    func testSparksSpreadEvenlyAtNearTheirClassSpeed() {
        let sparks = ConfirmFireworksPhysics.sparks(of: shell(size: .small), index: 3, canvas: canvas)
        let speeds = sparks.map(speed)
        XCTAssertTrue(
            speeds.allSatisfy { (220 * 0.8 - 1e-9 ... 220 + 1e-9).contains($0) },
            "A spark is outside 0.8–1.0 × its class speed."
        )
        XCTAssertGreaterThan(
            (speeds.max() ?? 0) - (speeds.min() ?? 0), 10,
            "Every spark flies at the same speed, so the ring is a perfect circle with no life."
        )
        for (index, spark) in sparks.enumerated() {
            XCTAssertEqual(
                angleDistance(angle(of: spark), 2 * Double.pi * Double(index) / 40), 0, accuracy: 1e-6,
                "Spark \(index) is not on its even step."
            )
        }
    }

    func testSingleShellsBurstInOneColourAndTwoToneShellsAlternate() {
        let physics = ConfirmFireworksPhysics.self
        let single = physics.sparks(of: shell(burst: .single, colorNames: ["AreaWorkVivid"]), index: 0, canvas: canvas)
        XCTAssertEqual(Set(single.map(\.colorName)), ["AreaWorkVivid"], "A single shell bursts in more than one colour.")
        let twoTone = physics.sparks(
            of: shell(burst: .twoTone, colorNames: ["AreaGrowthVivid", "AreaHealthVivid"]), index: 0, canvas: canvas
        )
        XCTAssertEqual(twoTone.count, 72)
        XCTAssertEqual(twoTone.filter { $0.colorName == "AreaGrowthVivid" }.count, 36)
        XCTAssertEqual(twoTone.filter { $0.colorName == "AreaHealthVivid" }.count, 36)
        XCTAssertEqual(
            twoTone.prefix(4).map(\.colorName),
            ["AreaGrowthVivid", "AreaHealthVivid", "AreaGrowthVivid", "AreaHealthVivid"],
            "Two-tone sparks do not alternate."
        )
    }

    /// Half the sparks at 0.55× speed in the second colour, stepped half a step round from the
    /// outer ring, so the inner ring sits between the outer's sparks rather than behind them.
    func testARingInRingShellNestsASlowerInnerRingInTheSecondColour() {
        let sparks = ConfirmFireworksPhysics.sparks(
            of: shell(burst: .ringInRing, colorNames: ["AreaHobbyVivid", "AreaAdminVivid"], size: .big),
            index: 2, canvas: canvas
        )
        XCTAssertEqual(sparks.count, 72)
        let outer = sparks.filter { $0.colorName == "AreaHobbyVivid" }
        let inner = sparks.filter { $0.colorName == "AreaAdminVivid" }
        XCTAssertEqual(outer.count, 36, "The outer ring is not half the sparks.")
        XCTAssertEqual(inner.count, 36, "The inner ring is not half the sparks, in the second colour.")
        XCTAssertTrue(outer.map(speed).allSatisfy { (400 * 0.8 - 1e-9 ... 400 + 1e-9).contains($0) })
        XCTAssertTrue(
            inner.map(speed).allSatisfy { (400 * 0.8 * 0.55 - 1e-9 ... 400 * 0.55 + 1e-9).contains($0) },
            "The inner ring is not at 0.55× speed."
        )
        let step = 2 * Double.pi / 36
        for (index, spark) in outer.enumerated() {
            XCTAssertEqual(angleDistance(angle(of: spark), step * Double(index)), 0, accuracy: 1e-6, "Outer spark \(index) is off its step.")
        }
        for (index, spark) in inner.enumerated() {
            XCTAssertEqual(
                angleDistance(angle(of: spark), step * (Double(index) + 0.5)), 0, accuracy: 1e-6,
                "Inner spark \(index) is not offset by half a step."
            )
        }
    }

    func testTheSameShellBurstsTheSameWayEveryTime() {
        let fired = shell(burst: .twoTone, colorNames: ["AreaRedVivid", "StateWarnVivid"], size: .small)
        let physics = ConfirmFireworksPhysics.self
        XCTAssertEqual(physics.sparks(of: fired, index: 7, canvas: canvas), physics.sparks(of: fired, index: 7, canvas: canvas))
        XCTAssertNotEqual(
            physics.sparks(of: fired, index: 7, canvas: canvas), physics.sparks(of: fired, index: 8, canvas: canvas),
            "Two shells' sparks are hashed identically."
        )
    }

    // MARK: - Spark flight, fade and flash

    /// Sparks are lighter than paper: they fly the confetti model at gravity 150 and drag 2.4. The
    /// overload with explicit gravity and drag is what makes that possible; with the defaults it
    /// is exactly the confetti's own flight, so the refactor moved no piece of confetti.
    func testSparksFlyTheConfettiModelAtTheirOwnGravityAndDrag() throws {
        let spark = ConfettiPiece(
            origin: CGPoint(x: 100, y: 300), velocity: CGVector(dx: 200, dy: 0), delay: 0, lifetime: 2,
            size: CGSize(width: 2.4, height: 2.4), shape: .circle, colorName: "AreaWorkVivid",
            spinStart: 0, spinRate: 0, tumbleRate: 0, tumblePhase: 0,
            flutterAmplitude: 0, flutterRate: 0, flutterPhase: 0
        )
        let light = try XCTUnwrap(ConfettiPhysics.state(of: spark, at: 1, gravity: 150, drag: 2.4), "No spark state.")
        let paper = try XCTUnwrap(ConfettiPhysics.state(of: spark, at: 1))
        // Closed form: y = y₀ + (v_y − g/k)/k · (1 − e^(−k t)) + (g/k) t, with v_y = 0.
        let expectedDrop = -(150 / 2.4) / 2.4 * (1 - exp(-2.4)) + (150 / 2.4) * 1
        XCTAssertEqual(light.position.y, 300 + expectedDrop, accuracy: 1e-6, "The spark does not fall under gravity 150 with drag 2.4.")
        XCTAssertEqual(light.position.x, 100 + 200 / 2.4 * (1 - exp(-2.4)), accuracy: 1e-6)
        XCTAssertGreaterThan(paper.position.y, light.position.y, "A spark falls as fast as paper.")
        XCTAssertEqual(
            paper,
            try XCTUnwrap(ConfettiPhysics.state(of: spark, at: 1, gravity: ConfettiPhysics.gravity, drag: ConfettiPhysics.drag)),
            "The confetti's own flight is not the overload at its defaults."
        )
        XCTAssertNil(ConfettiPhysics.state(of: spark, at: 2.01, gravity: 150, drag: 2.4), "A spark outlives its life.")
    }

    /// `(1 − τ/life)^1.4`: bright at the burst, thinning faster than a straight fade so the ring
    /// reads as embers rather than a shrinking disc. Nothing before the burst or after the life.
    func testASparkFadesOnThePowerCurve() {
        let physics = ConfirmFireworksPhysics.self
        XCTAssertEqual(physics.sparkOpacity(life: 1.45, sinceBurst: 0), 1, accuracy: 1e-9, "A spark is not bright at its burst.")
        XCTAssertEqual(physics.sparkOpacity(life: 1.45, sinceBurst: 0.725), pow(0.5, 1.4), accuracy: 1e-9, "The fade is not the 1.4 power curve.")
        XCTAssertEqual(physics.sparkOpacity(life: 1.45, sinceBurst: 1.45), 0, accuracy: 1e-9)
        XCTAssertEqual(physics.sparkOpacity(life: 1.45, sinceBurst: 2), 0, accuracy: 1e-9)
        XCTAssertEqual(physics.sparkOpacity(life: 1.45, sinceBurst: -0.1), 0, accuracy: 1e-9)
    }

    /// The flash: radius 40 → 240 pt and alpha 0.35 → 0 over 0.35 s from the burst; gone after,
    /// and nothing before.
    func testTheBurstFlashSwellsAndFadesOverAThirdOfASecond() throws {
        let physics = ConfirmFireworksPhysics.self
        XCTAssertNil(physics.flash(sinceBurst: -0.01), "The flash shows before the burst.")
        let start = try XCTUnwrap(physics.flash(sinceBurst: 0), "No flash at the burst.")
        XCTAssertEqual(start.radius, 40, accuracy: 1e-9)
        XCTAssertEqual(start.alpha, 0.35, accuracy: 1e-9)
        let middle = try XCTUnwrap(physics.flash(sinceBurst: 0.175))
        XCTAssertEqual(middle.radius, 140, accuracy: 1e-9, "The flash does not swell 40 → 240 pt.")
        XCTAssertEqual(middle.alpha, 0.175, accuracy: 1e-9, "The flash does not fade 0.35 → 0.")
        XCTAssertNil(physics.flash(sinceBurst: 0.35), "The flash is still drawn after it has faded out.")
    }

    // MARK: - The whole display for a canvas

    /// Built once per change to the live list, never per frame: 14 shells and their 880 sparks,
    /// each shell's sparks from its own apex.
    func testAStackClearingDisplayLaunchesEveryShellAndItsSparksOnce() {
        let fireworks = ConfirmFireworks(canvas: canvas)
        XCTAssertEqual(fireworks.shells.count, 14, "The display does not fire the record's schedule.")
        XCTAssertEqual(fireworks.sparks.count, 14, "One spark list per shell.")
        XCTAssertEqual(fireworks.sparks.map(\.count).reduce(0, +), 880)
        for (shell, sparks) in zip(fireworks.shells, fireworks.sparks) {
            let apex = ConfirmFireworksPhysics.apexPoint(of: shell, canvas: canvas)
            XCTAssertTrue(
                sparks.allSatisfy { abs($0.origin.x - apex.x) < 1e-9 && abs($0.origin.y - apex.y) < 1e-9 },
                "A shell's sparks do not leave its apex."
            )
        }
    }

    // MARK: - Helpers

    /// The shortest distance between two angles, in radians.
    private func angleDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let twoPi = 2 * Double.pi
        var difference = (lhs - rhs).truncatingRemainder(dividingBy: twoPi)
        if difference < 0 { difference += twoPi }
        return min(difference, twoPi - difference)
    }
}
