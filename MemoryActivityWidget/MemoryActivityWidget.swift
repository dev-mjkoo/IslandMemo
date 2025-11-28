import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Calendar Grid View

private struct CalendarGridView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let calendar = Calendar.current
        let currentDate = Date()
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        let today = calendar.component(.day, from: currentDate)

        let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 30

        let lastDayIndex = firstWeekday - 2 + daysInMonth
        let lastWeekStartIndex = (lastDayIndex / 7) * 7
        let numberOfWeeksToShow = (lastWeekStartIndex + 6) / 7 + 1

        VStack(spacing: 2) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(
                            day == "일" ? .red :
                            day == "토" ? .blue :
                            .white.opacity(0.7)
                        )
                }
            }
            .padding(.bottom, 2)

            // 날짜 그리드
            ForEach(0..<numberOfWeeksToShow, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let dayNumber = row * 7 + column + 2 - firstWeekday

                        if dayNumber <= 0 {
                            // 이전 달의 날짜
                            Text("\(daysInPreviousMonth + dayNumber)")
                                .font(.system(size: 9, weight: .regular))
                                .frame(maxWidth: .infinity, minHeight: 14)
                                .foregroundColor(.white.opacity(0.3))
                        } else if dayNumber <= daysInMonth {
                            // 현재 달의 날짜
                            Text("\(dayNumber)")
                                .font(.system(size: 9, weight: today == dayNumber ? .bold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 14)
                                .foregroundColor(
                                    today == dayNumber ? .black :
                                    column == 0 ? .red :
                                    column == 6 ? .blue :
                                    .white
                                )
                                .background(
                                    today == dayNumber ?
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(.white)
                                            .frame(width: 16, height: 13)
                                        : nil
                                )
                        } else if row * 7 + column <= lastWeekStartIndex + 6 {
                            // 다음 달의 날짜
                            Text("\(dayNumber - daysInMonth)")
                                .font(.system(size: 9, weight: .regular))
                                .frame(maxWidth: .infinity, minHeight: 14)
                                .foregroundColor(.white.opacity(0.3))
                        } else {
                            // 빈 공간
                            Text("")
                                .frame(maxWidth: .infinity, minHeight: 14)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MemoryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoryNoteAttributes.self) { context in
            // Lock Screen / Banner Live Activity
            LockScreenView(context: context)
                .activityBackgroundTint(context.state.backgroundColor.color)
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
        HStack(spacing: 12) {
            // 왼쪽: 달력 (50%)
            CalendarGridView()
                .frame(maxWidth: .infinity)

            // 구분선
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1)

            // 오른쪽: 메모 (50%)
            VStack(alignment: .leading, spacing: 8) {
                Text(context.attributes.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.6))

                Text(context.state.memo)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
                    .lineLimit(3)

                Spacer(minLength: 0)

                // 프로그레스 바 + 타이머
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .tint(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))

                        Text(endDate, style: .timer)
                            .font(.system(size: 10, weight: .medium).monospacedDigit())
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.all, 12)
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
