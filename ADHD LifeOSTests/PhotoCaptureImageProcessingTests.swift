//
//  PhotoCaptureImageProcessingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class PhotoCaptureImageProcessingTests: XCTestCase {

    func testDownscaledJPEGData_largeImage_isDownscaledUnderMaxDimension() {
        let oversized = Self.solidColorImage(size: CGSize(width: 4000, height: 3000))
        guard let originalData = oversized.jpegData(compressionQuality: 1.0) else {
            return XCTFail("Expected to encode fixture image")
        }

        guard let resultData = PhotoCaptureImageProcessing.downscaledJPEGData(from: originalData) else {
            return XCTFail("Expected downscaled data")
        }
        guard let resultImage = UIImage(data: resultData) else {
            return XCTFail("Expected result data to decode as an image")
        }

        let largestSide = max(resultImage.size.width, resultImage.size.height)
        XCTAssertLessThanOrEqual(largestSide, PhotoCaptureImageProcessing.maxDimension)
        XCTAssertLessThan(resultData.count, originalData.count)
    }

    func testDownscaledJPEGData_smallImage_keepsOriginalDimensions() {
        let small = Self.solidColorImage(size: CGSize(width: 200, height: 100))
        guard let originalData = small.jpegData(compressionQuality: 1.0) else {
            return XCTFail("Expected to encode fixture image")
        }

        guard let resultData = PhotoCaptureImageProcessing.downscaledJPEGData(from: originalData) else {
            return XCTFail("Expected downscaled data")
        }
        guard let resultImage = UIImage(data: resultData) else {
            return XCTFail("Expected result data to decode as an image")
        }

        XCTAssertEqual(resultImage.size, small.size)
    }

    func testDownscaledJPEGData_invalidData_returnsNil() {
        let invalidData = Data([0x00, 0x01, 0x02])

        XCTAssertNil(PhotoCaptureImageProcessing.downscaledJPEGData(from: invalidData))
    }

    /// Rendered at scale 1 so `size` (points) matches the actual pixel dimensions once round-tripped
    /// through JPEG, which carries no scale-factor metadata.
    private static func solidColorImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
