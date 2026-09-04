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
                DynamicIslandExpandedRegion(.leading) {
                    Text("🧭")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ROUTINE")
                            .font(.caption2.weight(.bold))
                            .tracking(0.5)
                            .foregroundStyle(.secondary)
                        Text(context.state.placeName)
                            .font(.footnote.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // The SHORT form: this slot is narrow and clipped the sentence on device.
                    Text(context.state.shortStatusLine)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoutineActivityProgressTrack(progress: context.state.progress)
                        Text(context.state.nextLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
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
            // The island's outline, tinted (E's field-walk ask, 2026-09-03): a black island on
            // a dark background has no definite edge, and `keylineTint` is the ONLY supported
            // way to draw one — the island's own shape is not otherwise styleable.
            .keylineTint(Color("AccentColor"))
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
