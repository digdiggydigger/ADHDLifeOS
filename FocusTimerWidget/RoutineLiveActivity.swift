//
//  RoutineLiveActivity.swift
//  FocusTimerWidget
//
//  The routine's Lock Screen banner and Dynamic Island (F-Routines-5) — the drift-recovery
//  mechanism by E's own framing: the routine follows you out of the app, so coming back is one
//  tap from wherever you are.
//
//  DISPLAY ONLY. No buttons: interactive App Intents are the settled fast-follow, and they are
//  iOS 17+ against this target's 16.1 floor.
//
//  §4 note: a Live Activity IGNORES the widget target's global accent, so the accent is read
//  from this target's OWN catalog by name (`Color("AccentColor")`) rather than via `.tint` or
//  `Color.accentColor`, both of which render system blue here.
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct RoutineLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            RoutineActivityLockScreenView(state: context.state)
                .padding(16)
                .widgetURL(URL(string: RoutineActivityAttributes.deepLink))
        } dynamicIsland: { context in
            DynamicIsland {
                // Every expanded region carries its own inset. The island crops its content to
                // a rounded shape whose corners cut INWARD, so a view flush to the region edge
                // is clipped by the curve rather than merely tight — on E's device that ate the
                // leading edge of "Next:" and pressed the glyph and the count against the rim.
                DynamicIslandExpandedRegion(.leading) {
                    Text("🧭")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    // Centred (E, round 2). The eyebrow and the place name are one block and
                    // read as the island's title, so they sit on its axis rather than ragging
                    // left against a glyph that is a different size on every place.
                    VStack(alignment: .center, spacing: 4) {
                        Text("ROUTINE")
                            .font(.caption2.weight(.bold))
                            .tracking(0.5)
                            .foregroundStyle(.secondary)
                        Text(context.state.placeName)
                            .font(.footnote.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // The SHORT form: this slot is narrow and clipped the sentence on device.
                    Text(context.state.shortStatusLine)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoutineActivityProgressTrack(progress: context.state.progress)
                        Text(context.state.nextLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    // Shortens the bar as well as unclipping the copy (E asked for both): the
                    // track fills its container, so insetting the container IS the length.
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                // Sized DOWN from the default body size (E's round-2 ask: the pill was taking
                // all the width available to it). The compact island's width is leading +
                // sensor cutout + trailing, and the cutout is fixed by iOS — so the glyph is
                // the only real lever, and an emoji at body size is the widest thing here.
                // The count is deliberately NOT capped to match: clipping it is precisely the
                // regression `2c46ee7` fixed.
                Text("🧭")
                    .font(.caption)
            } compactTrailing: {
                // The count, not the step name: the compact slot clips trailing-aligned text,
                // which is how the sprint's island once ate a leading digit.
                Text("\(context.state.doneCount)/\(context.state.totalCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
            } minimal: {
                Text("🧭")
            }
            // The island's outline (E's field-walk asks, 2026-09-03 then 2026-09-04). A black
            // island on a black background has no definite edge, and `keylineTint` is the ONLY
            // supported way to draw one — the island's shape is not otherwise styleable.
            //
            // AMBER, not the accent: round 2 showed the blue keyline is barely visible in dark
            // mode, because a mid-blue on true black is low-contrast at hairline width. Amber
            // sits far from both the black ground and the blue count, so the edge reads.
            //
            // #FF6B00, E's pick, and the rule that produced it is worth keeping because the
            // obvious theory was WRONG. iOS draws the keyline at roughly 40% of the specified
            // colour and exposes neither width nor alpha, so colour is the only lever — but the
            // lever is NOT luminance. Measured off two device screenshots:
            //
            //     #FFD60A gold   → rendered #342906, G/R 0.79 → olive, the worst of the three
            //     #B4520A copper → rendered #442108, G/R 0.49 → orange, but dim
            //     #FF6B00 vivid  → rendered #662A00, G/R 0.42 → orange, and brighter
            //
            // The gold had the HIGHEST rendered luminance and still looked dullest: as red and
            // green converge the hue collapses to mud. So the rule is push luminance as high as
            // it will go while keeping the channels far apart, and the number that predicts the
            // result is the GREEN-TO-RED RATIO, which is scale-invariant and survives a rescaled
            // screenshot. Judge any future change on the device — the rendered colour is not the
            // specified one, and the simulator will not composite a Live Activity at all.
            //
            // Both appearance variants carry the same value on purpose — the island is always
            // dark whatever the system theme is doing, so a differing light variant would only
            // add a variable to the next tuning pass.
            .keylineTint(Color("IslandKeyline"))
            .widgetURL(URL(string: RoutineActivityAttributes.deepLink))
        }
    }
}

/// The Lock Screen banner. Kept flat and quiet — it is a glance, and its whole job is to say
/// where you are in the list and offer the way back.
@available(iOS 16.1, *)
struct RoutineActivityLockScreenView: View {
    let state: RoutineActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("ROUTINE · \(state.placeName)")
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(Color("AccentColor"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Text(state.statusLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .layoutPriority(1)
            }
            Text(state.nextLine)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            RoutineActivityProgressTrack(progress: state.progress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The shared 0–1 track. A plain capsule rather than `ProgressView` so the fill colour is the
/// catalog accent in both presentations — see the §4 note in this file's header.
@available(iOS 16.1, *)
struct RoutineActivityProgressTrack: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(Color("AccentColor"))
                    .frame(width: geometry.size.width * min(1, max(0, progress)))
            }
        }
        .frame(height: 6)
        .accessibilityLabel("Routine progress")
        .accessibilityValue("\(Int((min(1, max(0, progress)) * 100).rounded())) percent")
    }
}
