import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Photo View

/// Live Activity에 표시할 사진 뷰
/// ⚠️ 주의사항:
/// 1. 썸네일 이미지 사용 필수 (calendar_image_thumbnail.jpg)
///    - Live Activity는 메모리 제한이 있어 원본 이미지 사용 불가
///    - 썸네일 경로: App Group/calendar_image_thumbnail.jpg
/// 2. App Group 필수
///    - Live Activity는 별도 프로세스로 실행
///    - PersistenceKeys.AppGroup.identifier 사용
/// 3. 레거시 호환성 유지
///    - calendar_image.jpg 존재 시 fallback으로 사용
struct PhotoView: View {
    // Widget에서 App Group UserDefaults 읽기 (블러 강도)
    private var blurIntensity: Double {
        guard let groupDefaults = UserDefaults(suiteName: "group.com.livenote.shared") else {
            print("❌ Widget: App Group UserDefaults 접근 실패")
            return 1.5
        }

        // photoBlurIntensity 키가 존재하는지 확인
        if groupDefaults.object(forKey: "photoBlurIntensity") == nil {
            // 키가 없으면 기본값 1.5 (중간)
            print("📱 Widget: 블러 강도 키 없음, 기본값 1.5 사용")
            return 1.5
        }

        let value = groupDefaults.double(forKey: "photoBlurIntensity")
        print("📱 Widget: 블러 강도 읽음 = \(value)")
        return value
    }

    // 블러 강도에 따른 투명도 계산
    private var imageOpacity: Double {
        // 블러가 없을수록 선명하게 (opacity 높게)
        // 0.0 블러 → 1.0 opacity (완전 선명)
        // 1.0 블러 → 0.7 opacity
        // 3.0 블러 → 0.4 opacity (매우 흐림)
        let minOpacity = 0.4
        let maxOpacity = 1.0
        let normalizedBlur = min(blurIntensity / 3.0, 1.0) // 0.0 ~ 1.0
        let calculatedOpacity = maxOpacity - (normalizedBlur * (maxOpacity - minOpacity))
        print("📊 Widget: 블러 \(blurIntensity) → Opacity \(calculatedOpacity)")
        return calculatedOpacity
    }

    var body: some View {
        // App Group container에서 이미지 로드
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.livenote.shared"
        )

        // 썸네일 이미지 사용 (Live Activity용)
        let thumbnailURL = containerURL?.appendingPathComponent("calendar_image_thumbnail.jpg")
        let legacyURL = containerURL?.appendingPathComponent("calendar_image.jpg")

        // 썸네일 우선, 없으면 레거시 파일 시도
        let imageURL = (thumbnailURL != nil && FileManager.default.fileExists(atPath: thumbnailURL!.path))
            ? thumbnailURL
            : legacyURL
        let fileExists = imageURL != nil && FileManager.default.fileExists(atPath: imageURL!.path)

        if let url = imageURL,
           fileExists,
           let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           let imageData = try? Data(contentsOf: url),
           let image = UIImage(data: imageData) {
            // 이미지 로드 성공
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 130, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .blur(radius: blurIntensity) // 사용자 설정 블러 강도
                .opacity(imageOpacity) // 블러 강도에 따른 투명도
                .id("\(modificationDate.timeIntervalSince1970)-\(blurIntensity)") // 파일 또는 블러 변경 시 재렌더링
        } else {
            // 이미지가 없거나 로드 실패 시 플레이스홀더
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: fileExists ? "exclamationmark.triangle" : "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.5))

                            // 디버그 정보 (실제 배포 시 제거)
                            Text(containerURL == nil ? "No URL" : (fileExists ? "Load fail" : "No file"))
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    )
            }
        }
    }
}

// MARK: - Calendar Grid View

struct CalendarGridView: View {
    let backgroundColor: ActivityBackgroundColor
    @Environment(\.colorScheme) var colorScheme

    private func getWeekdayHeaders() -> [String] {
        let preferred = Locale.preferredLanguages.first ?? "en"

        if preferred.hasPrefix("ko") {
            return ["일", "월", "화", "수", "목", "금", "토"]
        } else if preferred.hasPrefix("ja") {
            return ["日", "月", "火", "水", "木", "金", "土"]
        } else if preferred.hasPrefix("zh") {
            return ["日", "月", "火", "水", "木", "金", "土"]
        } else {
            return ["S", "M", "T", "W", "T", "F", "S"]
        }
    }

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

        VStack(alignment: .leading, spacing: 4) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(Array(getWeekdayHeaders().enumerated()), id: \.offset) { index, day in
                    if backgroundColor == .glass {
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .frame(width: 18)
                            .foregroundStyle(.secondary.opacity(0.9))
                    } else {
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .frame(width: 18)
                            .foregroundColor(backgroundColor.secondaryTextColor.opacity(0.9))
                    }
                }
            }
            .padding(.top, 1)
            .padding(.bottom, 4)

            // 날짜 그리드
            ForEach(0..<numberOfWeeksToShow, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let dayNumber = row * 7 + column + 2 - firstWeekday

                        if dayNumber <= 0 {
                            // 이전 달의 날짜
                            if backgroundColor == .glass {
                                Text("\(daysInPreviousMonth + dayNumber)")
                                    .font(.system(size: 9, weight: .regular))
                                    .frame(width: 18, height: 15)
                                    .foregroundStyle(.secondary.opacity(0.3))
                            } else {
                                Text("\(daysInPreviousMonth + dayNumber)")
                                    .font(.system(size: 9, weight: .regular))
                                    .frame(width: 18, height: 15)
                                    .foregroundColor(backgroundColor.textColor.opacity(0.3))
                            }
                        } else if dayNumber <= daysInMonth {
                            // 현재 달의 날짜
                            if backgroundColor == .glass {
                                Text("\(dayNumber)")
                                    .font(.system(size: 9, weight: today == dayNumber ? .bold : .regular))
                                    .frame(width: 18, height: 15)
                                    .foregroundStyle(today == dayNumber ?
                                        (colorScheme == .dark ? .black : .white) :
                                        .primary)
                                    .background(
                                        today == dayNumber ?
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(colorScheme == .dark ? .white : .black)
                                                .frame(width: 18, height: 16)
                                            : nil
                                    )
                            } else {
                                Text("\(dayNumber)")
                                    .font(.system(size: 9, weight: today == dayNumber ? .bold : .regular))
                                    .frame(width: 18, height: 15)
                                    .foregroundColor(today == dayNumber ? (backgroundColor.isLightColor ? .white : .black) : backgroundColor.textColor)
                                    .background(
                                        today == dayNumber ?
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(backgroundColor.isLightColor ? .black : .white)
                                                .frame(width: 18, height: 16)
                                            : nil
                                    )
                            }
                        } else if row * 7 + column <= lastWeekStartIndex + 6 {
                            // 다음 달의 날짜
                            if backgroundColor == .glass {
                                Text("\(dayNumber - daysInMonth)")
                                    .font(.system(size: 9, weight: .regular))
                                    .frame(width: 18, height: 15)
                                    .foregroundStyle(.secondary.opacity(0.3))
                            } else {
                                Text("\(dayNumber - daysInMonth)")
                                    .font(.system(size: 9, weight: .regular))
                                    .frame(width: 18, height: 15)
                                    .foregroundColor(backgroundColor.textColor.opacity(0.3))
                            }
                        } else {
                            // 빈 공간
                            Text("")
                                .frame(width: 18, height: 15)
                        }
                    }
                }
            }
        }
    }
}

struct MemoryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoryNoteAttributes.self) { context in
            // Lock Screen / Banner Live Activity
            LockScreenView(context: context)
                .activityBackgroundTint(context.state.backgroundColor == .glass ? .clear : context.state.backgroundColor.color)
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

// MARK: - Shared Lock Screen View (재사용 가능)

struct LiveActivityLockScreenPreview: View {
    let label: String
    let memo: String
    let startDate: Date
    let backgroundColor: ActivityBackgroundColor
    let usePhoto: Bool
    let showCalendar: Bool

    private let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간

    private var endDate: Date {
        startDate.addingTimeInterval(activityDuration)
    }

    private func memoFontSize(for text: String) -> CGFloat {
        let length = text.count
        switch length {
        case 0...30:
            return 18
        case 31...60:
            return 16
        case 61...90:
            return 14
        default:
            return 13
        }
    }

    /// 앱 아이콘 가져오기
    private func getAppIcon() -> UIImage? {
        // Widget Assets에 추가된 AppIconSmall 이미지 사용
        return UIImage(named: "AppIconSmall")
    }

    var body: some View {
        // 달력 OFF + 사진 없음 → 메모만 (높이 낮춤)
        if !showCalendar && !usePhoto {
            // 메모만 표시 (왼쪽 없음)
            VStack(alignment: .leading, spacing: 8) {
                if backgroundColor == .glass {
                    HStack(alignment: .center, spacing: 6) {
                        Text(label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(0.6), radius: 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(memo)
                        .font(.system(size: memoFontSize(for: memo), weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    HStack(alignment: .center, spacing: 6) {
                        Text(label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(2)
                            .foregroundColor(backgroundColor.secondaryTextColor)

                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(0.6), radius: 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(memo)
                        .font(.system(size: memoFontSize(for: memo), weight: .bold, design: .rounded))
                        .foregroundColor(backgroundColor.textColor)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            // 기존 레이아웃 (달력/사진 + 메모)
            HStack(alignment: .top, spacing: 0) {
                // 왼쪽: 달력 또는 사진 (showCalendar가 true이거나 사진이 있을 때)
                if showCalendar {
                    if usePhoto {
                        PhotoView()
                            .padding(.trailing, 8)
                    } else {
                        CalendarGridView(backgroundColor: backgroundColor)
                            .padding(.trailing, 8)
                    }
                } else if usePhoto {
                    // 달력 OFF지만 사진이 있으면 사진 표시
                    PhotoView()
                        .padding(.trailing, 8)
                }

                // 구분선 (왼쪽 요소가 있을 때만)
                if showCalendar || usePhoto {
                    if backgroundColor == .glass {
                        Rectangle()
                            .fill(.primary.opacity(0.2))
                            .frame(width: 1)
                    } else {
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 1)
                    }
                }

                // 오른쪽: 메모
                VStack(alignment: .leading, spacing: 8) {
                    if backgroundColor == .glass {
                        HStack(alignment: .center, spacing: 6) {
                            Text(label)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .textCase(.uppercase)
                                .tracking(2)
                                .foregroundStyle(.secondary)

                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.green.opacity(0.6), radius: 6)
                        }

                        Text(memo)
                            .font(.system(size: memoFontSize(for: memo), weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.85)
                        .lineLimit(3)
                    } else {
                        HStack(alignment: .center, spacing: 6) {
                            Text(label)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .textCase(.uppercase)
                                .tracking(2)
                                .foregroundColor(backgroundColor.secondaryTextColor)

                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.green.opacity(0.6), radius: 6)
                        }

                        Text(memo)
                            .font(.system(size: memoFontSize(for: memo), weight: .bold, design: .rounded))
                            .foregroundColor(backgroundColor.textColor)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.85)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.all, 12)
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    var body: some View {
        LiveActivityLockScreenPreview(
            label: context.attributes.label,
            memo: context.state.memo,
            startDate: context.state.startDate,
            backgroundColor: context.state.backgroundColor,
            usePhoto: context.state.usePhoto,
            showCalendar: context.state.showCalendar
        )
    }
}

private struct ExpandedIslandView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    private let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간

    private var endDate: Date {
        context.state.startDate.addingTimeInterval(activityDuration)
    }

    private func formatFullDate() -> String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let isAsian = preferred.hasPrefix("ko") || preferred.hasPrefix("ja") || preferred.hasPrefix("zh")
        let dateLocale = isAsian ? Locale(identifier: preferred) : Locale(identifier: "en_US")

        return Date.now.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.wide)
                .locale(dateLocale)
        )
    }

    var body: some View {
        let formattedDate = formatFullDate()

        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Text(context.state.memo)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // 타이머 (Apple 공식)
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text(endDate, style: .timer)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

private struct CompactLeadingView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    var body: some View {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let day = Calendar.current.component(.day, from: Date())

        let dayText = formatDayText(day: day, locale: preferred)

        Text(dayText)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }

    private func formatDayText(day: Int, locale: String) -> String {
        if locale.hasPrefix("ko") {
            return "\(day)일"
        } else if locale.hasPrefix("ja") {
            return "\(day)日"
        } else if locale.hasPrefix("zh") {
            return "\(day)日"
        } else {
            // 영어: 서수 형식
            let suffix: String
            switch day {
            case 1, 21, 31:
                suffix = "st"
            case 2, 22:
                suffix = "nd"
            case 3, 23:
                suffix = "rd"
            default:
                suffix = "th"
            }
            return "\(day)\(suffix)"
        }
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    var body: some View {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let weekday = Calendar.current.component(.weekday, from: Date())

        let weekdayText = formatWeekdayText(weekday: weekday, locale: preferred)

        ZStack {
            Circle()
                .fill(AppColors.Widget.iconStroke)
                .frame(width: 28, height: 28)

            Text(weekdayText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func formatWeekdayText(weekday: Int, locale: String) -> String {
        if locale.hasPrefix("ko") {
            // 한국어: 일월화수목금토
            let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
            return weekdays[weekday - 1]
        } else if locale.hasPrefix("ja") {
            // 일본어: 日月火水木金土 (한자)
            let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
            return weekdays[weekday - 1]
        } else if locale.hasPrefix("zh") {
            // 중국어: 日月火水木金土 (한자)
            let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
            return weekdays[weekday - 1]
        } else {
            // 영어: MON/TUE/WED/THU/FRI/SAT/SUN
            let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
            return weekdays[weekday - 1]
        }
    }
}

private struct MinimalIslandView: View {
    let context: ActivityViewContext<MemoryNoteAttributes>

    var body: some View {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let day = Calendar.current.component(.day, from: Date())

        let dayText = formatDayText(day: day, locale: preferred)

        Text(dayText)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }

    private func formatDayText(day: Int, locale: String) -> String {
        if locale.hasPrefix("ko") {
            return "\(day)일"
        } else if locale.hasPrefix("ja") {
            return "\(day)日"
        } else if locale.hasPrefix("zh") {
            return "\(day)日"
        } else {
            // 영어: 서수 형식
            let suffix: String
            switch day {
            case 1, 21, 31:
                suffix = "st"
            case 2, 22:
                suffix = "nd"
            case 3, 23:
                suffix = "rd"
            default:
                suffix = "th"
            }
            return "\(day)\(suffix)"
        }
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
