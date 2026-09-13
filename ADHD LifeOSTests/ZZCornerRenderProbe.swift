//
//  ZZCornerRenderProbe.swift — THROWAWAY. Deleted in the same commit that lands the pick.
//
//  `F-FocusCard-Corners`: renders the collapsed card at four bottom radii so E can choose by
//  looking (the standing "render the thing and send the image" direction).
//

import SwiftUI
import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ZZCornerRenderProbe: XCTestCase {

    private static let radii: [CGFloat] = [0, 8, 16, 24]
    /// A real iPhone 17 Pro screen, so the furniture lays out exactly as it does on E's device.
    /// The interesting 190pt is cropped out afterwards rather than rendered in isolation.
    private static let size = CGSize(width: 393, height: 852)
    private static let cropHeight: CGFloat = 190
    private static let outDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("screenshots/focus-card-bottom-corners")

    func testRenderTheVariants() throws {
        try FileManager.default.createDirectory(
            at: Self.outDir, withIntermediateDirectories: true)

        var lightCrops: [(CGFloat, UIImage)] = []
        var lightFull: [(CGFloat, UIImage)] = []
        for scheme in [UIUserInterfaceStyle.light, .dark] {
            for radius in Self.radii {
                FocusBarMetrics.collapsedBottomCornerRadius = radius
                let full = try render(style: scheme)
                if scheme == .light { lightFull.append((radius, full)) }
                let image = bottomCrop(of: full)
                let name = String(
                    format: "%@-r%02d.jpeg", scheme == .light ? "light" : "dark", Int(radius))
                try write(image, named: name)
                if scheme == .light { lightCrops.append((radius, image)) }
            }
        }
        try write(sheet(of: lightCrops), named: "00-comparison-light.jpeg")
        try write(zoomSheet(of: lightFull), named: "01-corner-zoom-light.jpeg")
        FocusBarMetrics.collapsedBottomCornerRadius = FocusBarMetrics.cornerRadius
    }

    private func render(style: UIUserInterfaceStyle) throws -> UIImage {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.keyWindow
        let service = FocusSessionService()
        service.start(
            taskId: UUID(), taskTitle: "Draft the quarterly review",
            lifeAreaEmoji: "\u{1F4BC}", durationSeconds: 1500, cadence: .count(3))
        service.setCardCollapsed(true)

        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: Self.size)
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: Scene(service: service))
        window.rootViewController?.view.frame = window.bounds
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))

        let renderer = UIGraphicsImageRenderer(size: Self.size)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        previous?.makeKeyAndVisible()
        return image
    }

    /// The bottom of the screen — the card, its corners, and the bar they sit on.
    /// The bottom-LEFT corner alone, blown up 4x. At 1x the difference between these four is a
    /// couple of points of curve tucked against the tab bar; this is the panel that makes it a
    /// choice rather than a squint.
    private func zoomSheet(of fulls: [(CGFloat, UIImage)]) -> UIImage {
        let zoom: CGFloat = 4
        let region = CGRect(
            x: 0, y: Self.size.height - AppTabBarMetrics.rowHeight - 44, width: 108, height: 66)
        let cell = CGSize(width: region.width * zoom, height: region.height * zoom + 24)
        let total = CGSize(width: cell.width * CGFloat(fulls.count), height: cell.height)
        return UIGraphicsImageRenderer(size: total).image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: total))
            for (index, full) in fulls.enumerated() {
                let left = cell.width * CGFloat(index)
                NSAttributedString(
                    string: full.0 == 0 ? " 0pt (today)" : " \(Int(full.0))pt",
                    attributes: [
                        .font: UIFont.boldSystemFont(ofSize: 15), .foregroundColor: UIColor.label
                    ]
                ).draw(at: CGPoint(x: left + 4, y: 3))
                if let cropped = full.1.cgImage?.cropping(
                    to: CGRect(x: region.minX * full.1.scale, y: region.minY * full.1.scale,
                               width: region.width * full.1.scale, height: region.height * full.1.scale)
                ) {
                    UIImage(cgImage: cropped, scale: full.1.scale, orientation: .up).draw(
                        in: CGRect(x: left, y: 24, width: region.width * zoom, height: region.height * zoom))
                }
                UIColor.separator.setFill()
                context.fill(CGRect(x: left, y: 0, width: 1, height: cell.height))
            }
        }
    }

    private func bottomCrop(of image: UIImage) -> UIImage {
        let scale = image.scale
        let rect = CGRect(
            x: 0, y: (Self.size.height - Self.cropHeight) * scale,
            width: Self.size.width * scale, height: Self.cropHeight * scale)
        guard let cropped = image.cgImage?.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }

    /// The four light variants stacked and labelled, so the choice is one image.
    private func sheet(of crops: [(CGFloat, UIImage)]) -> UIImage {
        let strip = CGSize(width: Self.size.width, height: Self.cropHeight + 22)
        let total = CGSize(width: strip.width, height: strip.height * CGFloat(crops.count))
        return UIGraphicsImageRenderer(size: total).image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: total))
            for (index, crop) in crops.enumerated() {
                let top = strip.height * CGFloat(index)
                NSAttributedString(
                    string: crop.0 == 0 ? "  bottom radius 0pt — what ships today"
                                        : "  bottom radius \(Int(crop.0))pt",
                    attributes: [
                        .font: UIFont.boldSystemFont(ofSize: 14),
                        .foregroundColor: UIColor.label
                    ]
                ).draw(at: CGPoint(x: 4, y: top + 3))
                crop.1.draw(in: CGRect(x: 0, y: top + 22, width: Self.size.width, height: Self.cropHeight))
                UIColor.separator.setFill()
                context.fill(CGRect(x: 0, y: top, width: strip.width, height: 1))
            }
        }
    }

    private func write(_ image: UIImage, named: String) throws {
        let data = try XCTUnwrap(image.jpegData(compressionQuality: 0.92))
        try data.write(to: Self.outDir.appendingPathComponent(named))
        print("WROTE \(named) \(data.count / 1024)KB")
    }

    /// The real bottom furniture: the card is the last thing in a stack lifted by
    /// `bottomFurnitureLift`, and its own `collapsedOffsetY` drops it the last 32pt onto the bar.
    private struct Scene: View {
        @ObservedObject var service: FocusSessionService
        @State private var tab: AppTab = .today

        var body: some View {
            ZStack(alignment: .bottom) {
                Color.pageBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        Text(["Review the quarterly numbers", "Email the design team",
                              "Book the venue", "Draft the quarterly review"][index])
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16))
                    }
                    Spacer()
                }
                .padding(16)
                // **Order matters and it is the app's own.** `RootView` mounts the bar as a
                // `.safeAreaInset` (:203) and `RootBottomOverlay` as an `.overlay` (:229) applied
                // AFTER it, so the card draws ABOVE the bar — which is what lets the bar show
                // through the notches a rounded bottom corner leaves.
                AppTabBar(selection: $tab, captureInboxCount: 0)
                VStack(spacing: 0) {
                    Spacer()
                    FocusTimerBar(service: service)
                }
                .padding(.bottom, AppSearchRowMetrics.bottomFurnitureLift)
            }
        }
    }
}
