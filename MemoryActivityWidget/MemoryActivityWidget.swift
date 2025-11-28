import WidgetKit
import SwiftUI
import ActivityKit

struct MemoryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoryNoteAttributes.self) { context in
            // Lock Screen / Banner Live Activity
            LockScreenView(context: context)
                .activityBackgroundTint(.black)  // 전체 배경은 검정
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.center) {
                    ExpandedIslandView(context: context)
                }

            } compactLeading: {
                CompactLeadingView(context: context)

            } compactTrailing: {
                CompactTrailingView(context: context)

            } minimal: {
                MinimalIslandView(context: context)
            }
        }
    }
}

private struct LockScreenView: View {
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
        VStack(alignment: .leading, spacing: 12) {
            Text(context.attributes.label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .textCase(.uppercase)
                .tracking(3)
                .foregroundColor(.white.opacity(0.7))

            Text(context.state.memo)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 0)

            // 프로그레스 바 + 타이머
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(.white)

                HStack {
                    Text("남은 시간:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(endDate, style: .timer)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.all, 16)
    }
}

private struct ExpandedIslandView: View {
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
        VStack(alignment: .leading, spacing: 8) {
            Text(context.attributes.label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(3)

            Text(context.state.memo)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // 프로그레스 바 + 타이머
            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .tint(.white)

                HStack {
                    Text("남은 시간:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text(endDate, style: .timer)
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

private struct CompactLeadingView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    var body: some View {
        Text("기억")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    private let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간

    private var endDate: Date {
        context.state.startDate.addingTimeInterval(activityDuration)
    }

    var body: some View {
        Text(endDate, style: .timer)
            .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
            .lineLimit(1)
            .foregroundColor(.white.opacity(0.9))
    }
}

private struct MinimalIslandView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    var body: some View {
        Circle()
            .strokeBorder(Color.white, lineWidth: 1.5)
            .overlay(
                Text("기")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Live Activity previews

#Preview("Lock Screen", as: .content, using: MemoryNoteAttributes.preview) {
    MemoryActivityWidget()
} contentStates: {
    MemoryNoteAttributes.ContentState.sample
}

#Preview("Dynamic Island – Expanded",
         as: .dynamicIsland(.expanded),
         using: MemoryNoteAttributes.preview
) {
    MemoryActivityWidget()
} contentStates: {
    MemoryNoteAttributes.ContentState.sample
}
