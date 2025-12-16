
import Foundation
import ActivityKit
import Combine
import FirebaseAnalytics

@MainActor
final class LiveActivityManager: ObservableObject {

    static let shared = LiveActivityManager()

    @Published private(set) var currentActivity: Activity<MemoryNoteAttributes>?
    @Published var selectedBackgroundColor: ActivityBackgroundColor = .darkGray {
        didSet {
            // 색상 변경될 때마다 저장
            saveSelectedColor()
        }
    }
    @Published var activityStartDate: Date? = nil // 실제 startDate 추적
    private var isExtending: Bool = false // 중복 실행 방지 플래그

    private init() {
        // 저장된 색상 불러오기
        loadSelectedColor()

        // 앱 시작 시 실행 중인 Live Activity 복원
        Task {
            await restoreActivityIfNeeded()
        }
    }

    var isActivityRunning: Bool {
        currentActivity != nil
    }

    // MARK: - Activity Restoration

    func restoreActivityIfNeeded() async {
        // 시스템에서 실행 중인 Activity 찾기
        let activities = Activity<MemoryNoteAttributes>.activities
        guard let activity = activities.first else {
            print("No running activity found")
            // 시스템에 Activity가 없으면 currentActivity도 nil로 설정
            if currentActivity != nil {
                currentActivity = nil
                activityStartDate = nil
            }
            return
        }

        // 이미 같은 Activity를 참조 중이면 복원 불필요
        if let current = currentActivity, current.id == activity.id {
            return
        }

        // Activity 상태 복원
        currentActivity = activity
        activityStartDate = activity.content.state.startDate
        selectedBackgroundColor = activity.content.state.backgroundColor

        print("Activity restored from system:")
        print("- Memo: \(activity.content.state.memo)")
        print("- Start Date: \(activity.content.state.startDate)")
        print("- Background Color: \(activity.content.state.backgroundColor.displayName)")
    }

    func startActivity(with memo: String) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled.")
            return
        }

        // 이미 하나 돌고 있으면 그냥 업데이트로 처리
        if let activity = currentActivity {
            await updateActivity(memo: memo, activity: activity)
            return
        }

        // 중복 방지: 시스템에 이미 Activity가 있는지 최종 확인
        let systemActivities = Activity<MemoryNoteAttributes>.activities
        if let existingActivity = systemActivities.first {
            print("⚠️ 시스템에 이미 Activity 존재")

            // 8시간 지났는지 확인
            let elapsed = Date().timeIntervalSince(existingActivity.content.state.startDate)
            let eightHours: TimeInterval = 8 * 60 * 60

            if elapsed >= eightHours {
                print("🔄 8시간 지남, 종료 후 새로 시작하여 타이머 리셋")
                // 기존 것 종료
                await existingActivity.end(nil, dismissalPolicy: .immediate)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
                // 아래로 계속 진행하여 새로 생성
            } else {
                print("✅ 아직 유효함, 복원 후 업데이트만")
                currentActivity = existingActivity
                activityStartDate = existingActivity.content.state.startDate
                selectedBackgroundColor = existingActivity.content.state.backgroundColor
                await updateActivity(memo: memo, activity: existingActivity)
                return
            }
        }

        let attributes = MemoryNoteAttributes(label: AppStrings.appMessage)
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(8 * 60 * 60) // 8시간 후
        let initialState = MemoryNoteAttributes.ContentState(
            memo: memo,
            startDate: startDate,
            backgroundColor: selectedBackgroundColor
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: endDate),
                pushType: nil // 로컬 업데이트만 사용
            )
            currentActivity = activity
            activityStartDate = startDate
            print("Activity started: \(activity.id)")

            // Firebase Analytics: Live Activity 시작
            FirebaseAnalyticsManager.shared.logLiveActivityStarted()
        } catch {
            print("Failed to start activity: \(error)")
        }
    }

    func updateActivity(with memo: String) async {
        guard let activity = currentActivity else { return }
        await updateActivity(memo: memo, activity: activity)
    }

    func updateBackgroundColor() async {
        guard let activity = currentActivity else { return }
        await updateActivity(
            memo: activity.content.state.memo,
            backgroundColor: selectedBackgroundColor,
            activity: activity
        )
    }

    func extendTime() async {
        // 중복 실행 방지
        guard !isExtending else {
            print("⚠️ extendTime() 이미 실행 중, 중복 호출 무시")
            return
        }

        isExtending = true
        defer { isExtending = false }

        // 1단계: 시스템에서 모든 Activity 가져오기 (메모리 상태 무시)
        let systemActivities = Activity<MemoryNoteAttributes>.activities

        print("🔍 시스템 Activity 확인: \(systemActivities.count)개 발견")

        // Activity가 없으면 연장할 게 없으므로 종료
        guard let existingActivity = systemActivities.first else {
            print("⚠️ 연장할 Live Activity가 없습니다")
            return
        }

        // 현재 메모와 색상 저장
        let currentMemo = existingActivity.content.state.memo
        let currentColor = existingActivity.content.state.backgroundColor
        print("💾 기존 내용 저장: \(currentMemo)")

        // 2단계: 시스템의 모든 Activity 종료 (중복 제거)
        print("🗑️  모든 Live Activity 종료 중...")
        for activity in systemActivities {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("   ✅ Activity \(activity.id) 종료")
        }
        currentActivity = nil

        // 3단계: 잠시 대기 (시스템 정리 시간)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기

        // 4단계: 새로운 Activity 시작 (시스템 타이머 완전 리셋)
        print("🆕 Live Activity 재시작 중...")
        let attributes = MemoryNoteAttributes(label: AppStrings.appMessage)
        let newStartDate = Date()
        let newEndDate = newStartDate.addingTimeInterval(8 * 60 * 60) // 8시간 후
        let initialState = MemoryNoteAttributes.ContentState(
            memo: currentMemo,
            startDate: newStartDate,
            backgroundColor: currentColor
        )

        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: newEndDate),
                pushType: nil
            )
            currentActivity = newActivity
            activityStartDate = newStartDate
            print("✅ Live Activity 재시작 완료: 8시간 타이머 리셋")

            // Firebase Analytics: Live Activity 시간 연장
            FirebaseAnalyticsManager.shared.logLiveActivityExtended()
        } catch {
            print("❌ Activity 재시작 실패: \(error)")
        }
    }

    private func updateActivity(memo: String,
                                activity: Activity<MemoryNoteAttributes>) async {
        // 기존 startDate와 backgroundColor 유지
        let startDate = activity.content.state.startDate
        let backgroundColor = activity.content.state.backgroundColor
        let updatedState = MemoryNoteAttributes.ContentState(
            memo: memo,
            startDate: startDate,
            backgroundColor: backgroundColor
        )
        await activity.update(.init(state: updatedState, staleDate: nil))
        print("Activity updated")
    }

    private func updateActivity(memo: String,
                                backgroundColor: ActivityBackgroundColor,
                                activity: Activity<MemoryNoteAttributes>) async {
        // startDate는 유지, memo와 backgroundColor 업데이트
        let startDate = activity.content.state.startDate
        let updatedState = MemoryNoteAttributes.ContentState(
            memo: memo,
            startDate: startDate,
            backgroundColor: backgroundColor
        )
        await activity.update(.init(state: updatedState, staleDate: nil))
        print("Activity updated with new color: \(backgroundColor.displayName)")
    }

    func endActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = MemoryNoteAttributes.ContentState(
            memo: "",
            startDate: Date(),
            backgroundColor: activity.content.state.backgroundColor
        )
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        currentActivity = nil
        activityStartDate = nil
        print("Activity ended")
    }

    // MARK: - Color Persistence

    private func saveSelectedColor() {
        UserDefaults.standard.set(selectedBackgroundColor.rawValue, forKey: "selectedBackgroundColor")
    }

    private func loadSelectedColor() {
        if let rawValue = UserDefaults.standard.string(forKey: "selectedBackgroundColor"),
           let color = ActivityBackgroundColor(rawValue: rawValue) {
            selectedBackgroundColor = color
            print("✅ 저장된 색상 불러옴: \(color.displayName)")
        }
    }
}
