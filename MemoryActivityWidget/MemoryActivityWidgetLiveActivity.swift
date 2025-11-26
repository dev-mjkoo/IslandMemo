//
//  MemoryActivityWidgetLiveActivity.swift
//  MemoryActivityWidget
//
//  Created by 구민준 on 11/26/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MemoryActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoryNoteAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.memo)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.memo)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.memo)")
            } minimal: {
                Text(context.state.memo)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

#Preview("Notification", as: .content, using: MemoryNoteAttributes.preview) {
   MemoryActivityWidgetLiveActivity()
} contentStates: {
    MemoryNoteAttributes.ContentState.sample
}
