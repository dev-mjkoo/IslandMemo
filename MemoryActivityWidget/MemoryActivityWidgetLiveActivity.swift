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
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.cyan)
                .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    DynamicIslandExpandedView(context: context)
                }
            } compactLeading: {
                Image(systemName: "brain.head.profile")
            } compactTrailing: {
                let endDate = context.state.startDate.addingTimeInterval(8 * 60 * 60)
                Text(timerInterval: Date()...endDate, pauseTime: endDate)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "brain.head.profile")
            }
            .keylineTint(Color.cyan)
        }
    }
}

// MARK: - Dynamic Island Expanded View

struct DynamicIslandExpandedView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    private let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간

    private var endDate: Date {
        context.state.startDate.addingTimeInterval(activityDuration)
    }

    private var progress: Double {
        let elapsed = Date().timeIntervalSince(context.state.startDate)
        let progress = elapsed / activityDuration
        return min(max(progress, 0), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(context.state.memo)
                .font(.body)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            ProgressView(value: progress)
                .tint(.cyan)

            if context.isStale {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text(LocalizationManager.shared.string("시간 만료 • 앱에서 새로고침"))
                        .font(.caption2)
                }
            } else {
                HStack {
                    Text(LocalizationManager.shared.string("유효 시간:"))
                        .font(.caption2)

                    Text(timerInterval: Date()...endDate, pauseTime: endDate)
                        .font(.caption2.monospacedDigit())
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Lock Screen View

struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    private let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간

    private var endDate: Date {
        context.state.startDate.addingTimeInterval(activityDuration)
    }

    private var progress: Double {
        let elapsed = Date().timeIntervalSince(context.state.startDate)
        let progress = elapsed / activityDuration
        return min(max(progress, 0), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            // 메모 텍스트
            Text(context.state.memo)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // 프로그레스 바
            ProgressView(value: progress)
                .tint(.white)
        }
        .padding()
    }
}

#Preview("Notification", as: .content, using: MemoryNoteAttributes.preview) {
   MemoryActivityWidgetLiveActivity()
} contentStates: {
    MemoryNoteAttributes.ContentState.sample
}
