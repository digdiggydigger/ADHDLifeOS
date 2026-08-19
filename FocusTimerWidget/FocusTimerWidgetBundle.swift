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
        FocusStatsWidget()
    }
}
