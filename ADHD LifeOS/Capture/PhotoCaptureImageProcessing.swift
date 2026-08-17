//
//  PhotoCaptureImageProcessing.swift
//  ADHD LifeOS
//

import UIKit

/// Client-side downscale + JPEG re-encode for photo captures, so a phone-camera-resolution image
/// doesn't make for a slow upload — the server still generates the canonical thumbnail
/// (`life-os-thumbnailer`), this just keeps the original upload itself reasonably sized.
enum PhotoCaptureImageProcessing {
    static let maxDimension: CGFloat = 2048
    static let jpegCompressionQuality: CGFloat = 0.85

    static func downscaledJPEGData(from data: Data, quality: CGFloat = jpegCompressionQuality) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return downscale(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    /// Pixel dimensions, not points: JPEG bytes carry no scale-factor metadata, so this operates on
    /// `image.size.width/height * image.scale` throughout and renders at a fixed `scale = 1` format
    /// — otherwise a device-scale-3 render would encode 3x more pixels than `maxDimension` implies.
    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let largestSide = max(pixelWidth, pixelHeight)
        guard largestSide > maxDimension else { return image }

        let scale = maxDimension / largestSide
        let newSize = CGSize(width: pixelWidth * scale, height: pixelHeight * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
