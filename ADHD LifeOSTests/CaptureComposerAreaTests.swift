//
//  CaptureComposerAreaTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 composer's optional life-area chips (F-V3-Capture): the chosen area rides the EXISTING
/// create path (`NormalizedCreateCaptureInput.lifeAreaId` → adapter → document) and resets with
/// the rest of the draft after a successful save.
@MainActor
final class CaptureComposerAreaTests: XCTestCase {
    func testCreateCapture_carriesTheChosenAreaAndResetsIt() async {
        let client = FakeCaptureClientAdapting()
        let service = CaptureInboxService(client: client)
        let areaId = UUID()
        service.content = "Ask the GP about the referral letter"
        service.newCaptureLifeAreaId = areaId

        let created = await service.createCapture()

        XCTAssertTrue(created)
        XCTAssertEqual(client.lastCreateCaptureInput?.lifeAreaId, areaId)
        XCTAssertNil(service.newCaptureLifeAreaId)
    }

    func testCreateCapture_withoutAnArea_staysUnfiled() async {
        let client = FakeCaptureClientAdapting()
        let service = CaptureInboxService(client: client)
        service.content = "Loose thought"

        _ = await service.createCapture()

        XCTAssertNil(client.lastCreateCaptureInput?.lifeAreaId)
    }
}
