//
//  FocusTimerWidgetBundle.swift
//  FocusTimerWidget
//

import SwiftUI
import WidgetKit

@main
struct FocusTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusTimerWidgetLiveActivity()
        // The routine's DISPLAY Activity (F-Routines-5). UNGATED, like the sprint's beside it:
        // ActivityKit sits below this extension's 18 floor, so an availability block here buys nothing — and a
        // conditional inside a `WidgetBundle` body can silently drop the widget from the
        // bundle, which compiles perfectly and simply never registers.
        RoutineLiveActivity()
        FocusStatsWidget()
        LifeAreasWidget()
        QuickCaptureWidget()
    }
}
