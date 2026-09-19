//
//  AuditComposerRenderProbe.swift
//  ADHD LifeOSTests
//
//  THROWAWAY (ADHD UX audit, round 6, E's render permission from round 2b). Renders three shapes
//  for ONE task composer (both doors open it) with the real tokens. Never committed: deleted as
//  soon as E has chosen; only the images are kept.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class AuditComposerRenderProbe: XCTestCase {

    private static let outDir = "/private/tmp/claude-501/-Users-ethan--E--Claude-Code-v1-GoogleAI-ADHDLifeOS-ADHDLifeOS/583f35f8-93dd-4815-8059-9c715c0409e1/scratchpad/r6-comp"

    func testRenderComposerOptions() throws {
        try FileManager.default.createDirectory(atPath: Self.outDir, withIntermediateDirectories: true)
        var jobs: [(String, AnyView, ColorScheme, DynamicTypeSize)] = []
        for shape in ComposerShape.allCases {
            for (scheme, s) in [(ColorScheme.light, "L"), (.dark, "D")] {
                jobs.append(("\(shape.rawValue)-\(s)", AnyView(Composer(shape: shape)), scheme, .large))
            }
            jobs.append(("\(shape.rawValue)-A", AnyView(Composer(shape: shape)), .light, .accessibility3))
        }
        // Two passes: the first render in a fresh host has failed every time on this machine.
        for _ in 0..<2 {
            for (name, view, scheme, size) in jobs where !FileManager.default.fileExists(atPath: "\(Self.outDir)/\(name).png") {
                _ = try render(view, name: name, scheme: scheme, size: size)
            }
        }
        let missing = jobs.filter { !FileManager.default.fileExists(atPath: "\(Self.outDir)/\($0.0).png") }.map(\.0)
        XCTAssertEqual(missing, [])  // 4 shapes × 3
    }

    private func render<V: View>(_ view: V, name: String, scheme: ColorScheme, size: DynamicTypeSize) throws -> Int {
        let framed = view
            .environment(\.colorScheme, scheme)
            .dynamicTypeSize(size)
            .frame(width: 402, height: 818)
        var attempt: UIImage?
        for _ in 0..<4 where attempt == nil {
            let renderer = ImageRenderer(content: framed)
            renderer.scale = 3
            renderer.isOpaque = true
            attempt = renderer.uiImage
            if attempt == nil { RunLoop.current.run(until: Date().addingTimeInterval(0.3)) }
        }
        guard let image = attempt, let png = image.pngData() else { return 0 }
        try png.write(to: URL(fileURLWithPath: "\(Self.outDir)/\(name).png"))
        return 1
    }
}

private enum ComposerShape: String, CaseIterable {
    case chips = "C1-title-three-chips"
    case nextStep = "C2-title-next-step"
    case folded = "C3-everything-folded"
    case combined = "C4-when-chips-plus-menus"
}

private struct Tinted: ViewModifier {
    let tint: Color
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .foregroundStyle(tint)
            .background(
                tint.opacity(scheme == .dark ? AppTabBarMetrics.chipTintDark : AppTabBarMetrics.chipTintLight),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

private struct Field: View {
    let placeholder: String
    var lines: CGFloat = 3
    var body: some View {
        Text(placeholder)
            .font(.body)
            .foregroundStyle(Color("LabelTertiary"))
            .frame(maxWidth: .infinity, minHeight: 22 * lines + 24, alignment: .topLeading)
            .padding(16)
            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
    }
}

/// A pop-up chip: a menu, not a sheet (Q4's max-1).
private struct MenuChip: View {
    let glyph: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: glyph)
            Text(text)
            Image(systemName: "chevron.up.chevron.down").font(.caption2.weight(.semibold))
        }
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .modifier(Tinted(tint: .accentColor))
    }
}

private struct Composer: View {
    let shape: ComposerShape
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Close")
                    .font(.body)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(Color.cardSurface, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: 1))
                Spacer()
                Text("New task").font(.headline)
                Spacer()
                Color.clear.frame(width: 80, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            VStack(alignment: .leading, spacing: 24) {
                Field(placeholder: "What needs doing?")
                content
            }
            .padding(16)
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                Label("Add task", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }

    @ViewBuilder
    private var content: some View {
        switch shape {
        case .chips:
            VStack(alignment: .leading, spacing: 8) {
                if typeSize.isAccessibilitySize {
                    MenuChip(glyph: "calendar", text: "No date")
                    MenuChip(glyph: "square.grid.2x2", text: "No area")
                    MenuChip(glyph: "timer", text: "15 min")
                } else {
                    HStack(spacing: 8) {
                        MenuChip(glyph: "calendar", text: "No date")
                        MenuChip(glyph: "square.grid.2x2", text: "No area")
                    }
                    MenuChip(glyph: "timer", text: "15 min")
                }
                Text("Next step, tags, place and notes live on the task, for later.")
                    .font(.footnote)
                    .foregroundStyle(Color("LabelSecondary"))
            }
        case .nextStep:
            VStack(alignment: .leading, spacing: 8) {
                Field(placeholder: "First step (optional)", lines: 1)
                Text("No date, no area, 15 min. Change any of it on the task.")
                    .font(.footnote)
                    .foregroundStyle(Color("LabelSecondary"))
            }
        case .combined:
            VStack(alignment: .leading, spacing: 8) {
                Text("WHEN").sectionLabel()
                let when = ["Not yet", "Today", "Tomorrow"]
                if typeSize.isAccessibilitySize {
                    ForEach(when, id: \.self) { chip($0, selected: $0 == "Not yet") }
                    MenuChip(glyph: "calendar", text: "Pick a date")
                } else {
                    HStack(spacing: 8) { ForEach(when, id: \.self) { chip($0, selected: $0 == "Not yet") } }
                    MenuChip(glyph: "calendar", text: "Pick a date")
                }
                Spacer().frame(height: 8)
                if typeSize.isAccessibilitySize {
                    MenuChip(glyph: "square.grid.2x2", text: "No area")
                    MenuChip(glyph: "timer", text: "15 min")
                } else {
                    HStack(spacing: 8) {
                        MenuChip(glyph: "square.grid.2x2", text: "No area")
                        MenuChip(glyph: "timer", text: "15 min")
                    }
                }
            }
        case .folded:
            VStack(alignment: .leading, spacing: 8) {
                Text("WHEN").sectionLabel()
                let when = ["Not yet", "Today", "Tomorrow", "Pick a date"]
                if typeSize.isAccessibilitySize {
                    ForEach(when, id: \.self) { chip($0, selected: $0 == "Not yet") }
                } else {
                    HStack(spacing: 8) { ForEach(when.prefix(3), id: \.self) { chip($0, selected: $0 == "Not yet") } }
                    chip("Pick a date", selected: false)
                }
                HStack(spacing: 4) {
                    Text("More details")
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                    Spacer()
                    Text("area · time · tags · place · notes")
                        .font(.footnote)
                        .foregroundStyle(Color("LabelSecondary"))
                        .lineLimit(1)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(minHeight: 48)
            }
        }
    }

    private func chip(_ text: String, selected: Bool) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(selected ? Color.accentColor : Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: selected ? 0 : 1))
    }
}
