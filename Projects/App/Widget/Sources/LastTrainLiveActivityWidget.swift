import ActivityKit
import CoreLiveActivity
import SwiftUI
import WidgetKit

/// Phase 9 placeholder — empty lock-screen view and minimal Dynamic Island
/// regions so the extension builds and embeds. Real UI lands in Phase 10.
struct LastTrainLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LastTrainActivityAttributes.self) { _ in
            EmptyView()
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}
