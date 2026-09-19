//
//  AuditHeroRenderProbe.swift
//  ADHD LifeOSTests
//
//  THROWAWAY (ADHD UX audit, round 5, E's render permission from round 2b). Renders Today's ONE
//  card (round 3 "C") in three button hierarchies and its other states, with the real tokens. Never
//  committed: deleted as soon as E has chosen; only the images are kept.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class AuditHeroRenderProbe: XCTestCase {

    private static let outDir = "/private/tmp/claude-501/-Users-ethan--E--Claude-Code-v1-GoogleAI-ADHDLifeOS-ADHDLifeOS/583f35f8-93dd-4815-8059-9c715c0409e1/scratchpad/r5-hero"

    func testRenderHeroOptions() throws {
        try FileManager.default.createDirectory(atPath: Self.outDir, withIntermediateDirectories: true)
        _ = ImageRenderer(content: Text("warm-up")).uiImage
        _ = ImageRenderer(content: TodayBody(card: .pinned, style: .startFirst).frame(width: 402)).uiImage
        var count = 0
        for (scheme, s) in [(ColorScheme.light, "L"), (.dark, "D")] {
            for style in HeroStyle.allCases {
                count += try render(TodayBody(card: .pinned, style: style), name: "body-\(style.rawValue)-\(s)", scheme: scheme, size: .large)
            }
        }
        for style in HeroStyle.allCases {
            count += try render(TodayBody(card: .pinned, style: style), name: "body-\(style.rawValue)-A", scheme: .light, size: .accessibility3)
        }
        for state in [CardState.suggested, .resume, .leaveBy, .routineSlot] {
            count += try render(TodayBody(card: state, style: .startFirst), name: "state-\(state.rawValue)-L", scheme: .light, size: .large)
        }
        XCTAssertEqual(count, 3 * 3 + 4)
    }

    private func render<V: View>(_ view: V, name: String, scheme: ColorScheme, size: DynamicTypeSize) throws -> Int {
        let framed = view
            .environment(\.colorScheme, scheme)
            .dynamicTypeSize(size)
            .frame(width: 402)
        var attempt: UIImage?
        for _ in 0..<4 where attempt == nil {
            let renderer = ImageRenderer(content: framed)
            renderer.scale = 3
            renderer.isOpaque = false
            attempt = renderer.uiImage
            if attempt == nil { RunLoop.current.run(until: Date().addingTimeInterval(0.3)) }
        }
        guard let image = attempt, let png = image.pngData() else {
            XCTFail("nothing rendered for \(name)")
            return 0
        }
        XCTAssertGreaterThan(image.size.height, 40, name)
        try png.write(to: URL(fileURLWithPath: "\(Self.outDir)/\(name).png"))
        return 1
    }
}

// MARK: - Tokens-only building blocks

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

private struct Filled: ViewModifier {
    let tint: Color
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .modifier(Tinted(tint: Color("LabelSecondary")))
    }
}

private enum HeroStyle: String, CaseIterable {
    case startFirst = "H1-start-first"
    case equalPair = "H2-equal-pair"
    case routineModel = "H3-routine-model"
}

private enum CardState: String {
    case pinned, suggested, resume, leaveBy, routineSlot
}

// MARK: - Today, round 3 "C": one card, a short then-list, one quiet done line

private struct TodayBody: View {
    let card: CardState
    let style: HeroStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if card == .routineSlot {
                // The real live-routine card is composited into this slot from the sim frame.
                Color.clear.frame(height: 188)
            } else {
                OneCard(state: card, style: style)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("THEN").sectionLabel()
                VStack(spacing: 0) {
                    ThenRow(title: "Renew passport", meta: "🏠 Home · 15 min")
                    Divider().padding(.leading, 16)
                    ThenRow(title: "Pay the council tax instalment", meta: "💰 Money · still open")
                    Divider().padding(.leading, 16)
                    ThenRow(title: "Call Mum back", meta: "💬 Relationships · tomorrow")
                }
                .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
            }
            HStack(spacing: 8) {
                Label("3 done today", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color("LabelSecondary"))
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text("Week review")
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            }
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct ThenRow: View {
    let title: String
    let meta: String
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body)
                Text(meta).font(.footnote).foregroundStyle(Color("LabelSecondary"))
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color("LabelTertiary"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 60)
    }
}

// MARK: - The one card

private struct OneCard: View {
    let state: CardState
    let style: HeroStyle
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
            buttons
        }
        .padding(16)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }

    private var eyebrow: String {
        switch state {
        case .pinned: return style == .routineModel ? "NEXT — PINNED" : "NEXT · PINNED"
        case .suggested: return "SUGGESTED · DUE TODAY"
        case .resume: return "PAUSED · 12 MIN IN"
        case .leaveBy: return "LEAVE BY 14:20 · DENTIST"
        case .routineSlot: return ""
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(eyebrow)
                .font(.footnote.weight(.semibold))
                .tracking(1)
                .foregroundStyle(state == .leaveBy ? Color("StateWarn") : Color.accentColor)
            Spacer(minLength: 8)
            if state == .pinned || state == .suggested {
                Image(systemName: state == .pinned ? "pin.fill" : "pin")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .modifier(Tinted(tint: .accentColor))
                    .accessibilityLabel(state == .pinned ? "Unpin" : "Pin")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .leaveBy:
            VStack(alignment: .leading, spacing: 8) {
                Text("1h 50m").font(.largeTitle.monospacedDigit().bold())
                TimeBar(fraction: 0.62)
                Text("A 25-min sprint on 'Reply to Priya' fits before you go.")
                    .font(.subheadline).foregroundStyle(Color("LabelSecondary"))
            }
        case .resume:
            VStack(alignment: .leading, spacing: 8) {
                Text("Reply to Priya about the Q4 roadmap").font(.title3.bold())
                Text("8 min left of 20 · paused at 10:42").font(.subheadline).foregroundStyle(Color("LabelSecondary"))
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                Text("Reply to Priya about the Q4 roadmap")
                    .font(style == .routineModel ? .title2.bold() : .title3.bold())
                Text("Next: say yes to the date, ask who owns the spec")
                    .font(.body)
                HStack(spacing: 8) { Chip(text: "15 min"); Chip(text: "💼 Work") }
                VStack(alignment: .leading, spacing: 4) {
                    TimeBar(fraction: 0.62)
                    Text("1h 50m until you leave for the dentist")
                        .font(.footnote).foregroundStyle(Color("LabelSecondary"))
                }
            }
        }
    }

    private func big(_ title: String, _ glyph: String, _ tint: Color) -> some View {
        Label(title, systemImage: glyph)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .modifier(Filled(tint: tint))
    }

    private func quiet(_ title: String, _ glyph: String, _ tint: Color) -> some View {
        Label(title, systemImage: glyph)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .modifier(Tinted(tint: tint))
    }

    @ViewBuilder
    private var buttons: some View {
        let ax = typeSize.isAccessibilitySize
        switch state {
        case .resume:
            VStack(spacing: 8) {
                big("Resume", "play.fill", .accentColor)
                quiet("End", "stop.fill", Color("StateRisk"))
            }
        case .leaveBy:
            big("Start 25 min", "play.fill", .accentColor)
        case .suggested:
            VStack(spacing: 8) {
                big("Start 15 min", "play.fill", .accentColor)
                if ax {
                    quiet("Close it", "checkmark", Color("StateGo"))
                    quiet("Not this one", "arrow.triangle.2.circlepath", Color("LabelSecondary"))
                } else {
                    HStack(spacing: 8) {
                        quiet("Close it", "checkmark", Color("StateGo"))
                        quiet("Not this one", "arrow.triangle.2.circlepath", Color("LabelSecondary"))
                    }
                }
            }
        default:
            switch style {
            case .startFirst:
                VStack(spacing: 8) {
                    big("Start 15 min", "play.fill", .accentColor)
                    quiet("Close it", "checkmark", Color("StateGo"))
                }
            case .equalPair:
                if ax {
                    VStack(spacing: 8) {
                        big("Start 15 min", "play.fill", .accentColor)
                        big("Close it", "checkmark", Color("StateGo"))
                    }
                } else {
                    HStack(spacing: 8) {
                        big("Start 15 min", "play.fill", .accentColor)
                        big("Close it", "checkmark", Color("StateGo"))
                    }
                }
            case .routineModel:
                VStack(spacing: 8) {
                    big("Start 15 min", "play.fill", .accentColor)
                    Text("Done already? Close it")
                        .font(.subheadline)
                        .foregroundStyle(Color("LabelSecondary"))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }
}

/// Idea 8: time you can see — a bar that shrinks toward the next commitment.
private struct TimeBar: View {
    let fraction: CGFloat
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color("LabelTertiary").opacity(0.35))
                Capsule().fill(Color.accentColor).frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 8)
    }
}
