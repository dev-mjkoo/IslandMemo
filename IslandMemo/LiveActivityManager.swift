//
//  LiveActivityManager.swift
//  islandmemo
//
//  Created by 구민준 on 11/26/25.
//

import Foundation
import ActivityKit
import Combine

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
    private var dismissalTask: Task<Void, Never>?
    private var midnightUpdateTask: Task<Void, Never>?
    private var lastUpdateDate: Date?

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
        activityStartDate = activity.contentState.startDate
        selectedBackgroundColor = activity.contentState.backgroundColor
        lastUpdateDate = Date()

        print("Activity restored from system:")
        print("- Memo: \(activity.contentState.memo)")
        print("- Start Date: \(activity.contentState.startDate)")
        print("- Background Color: \(activity.contentState.backgroundColor.displayName)")

        // 자동 종료 스케줄 (남은 시간 계산)
        scheduleAutoDismissal()

        // 자정 업데이트 스케줄
        scheduleMidnightUpdate()
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
            let elapsed = Date().timeIntervalSince(existingActivity.contentState.startDate)
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
                activityStartDate = existingActivity.contentState.startDate
                selectedBackgroundColor = existingActivity.contentState.backgroundColor
                lastUpdateDate = Date()
                await updateActivity(memo: memo, activity: existingActivity)

                // 스케줄 재설정
                scheduleAutoDismissal()
                scheduleMidnightUpdate()
                return
            }
        }

        let attributes = MemoryNoteAttributes(label: AppStrings.appMessage)
        let startDate = Date()
        let initialState = MemoryNoteAttributes.ContentState(
            memo: memo,
            startDate: startDate,
            backgroundColor: selectedBackgroundColor
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil // 로컬 업데이트만 사용
            )
            currentActivity = activity
            activityStartDate = startDate
            lastUpdateDate = Date()
            print("Activity started: \(activity.id)")

            // 8시간 후 자동 종료 스케줄
            scheduleAutoDismissal()

            // 자정 자동 업데이트 스케줄
            scheduleMidnightUpdate()
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
            memo: activity.contentState.memo,
            backgroundColor: selectedBackgroundColor,
            activity: activity
        )
    }

    func extendTime() async {
        // 1단계: 시스템에서 모든 Activity 가져오기 (메모리 상태 무시)
        let systemActivities = Activity<MemoryNoteAttributes>.activities

        print("🔍 시스템 Activity 확인: \(systemActivities.count)개 발견")

        // 현재 메모와 색상 저장 (기본값 설정)
        var currentMemo = AppStrings.inputPlaceholder
        var currentColor = selectedBackgroundColor

        // 시스템에 Activity가 있으면 내용 가져오기
        if let existingActivity = systemActivities.first {
            currentMemo = existingActivity.contentState.memo
            currentColor = existingActivity.contentState.backgroundColor
            print("💾 기존 내용 저장: \(currentMemo)")
        }

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
        let initialState = MemoryNoteAttributes.ContentState(
            memo: currentMemo,
            startDate: newStartDate,
            backgroundColor: currentColor
        )

        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = newActivity
            activityStartDate = newStartDate
            lastUpdateDate = Date()
            print("✅ Live Activity 재시작 완료: 8시간 타이머 리셋")

            // 8시간 후 자동 종료 스케줄
            scheduleAutoDismissal()

            // 자정 자동 업데이트 스케줄
            scheduleMidnightUpdate()
        } catch {
            print("❌ Activity 재시작 실패: \(error)")
        }
    }

    private func updateActivity(memo: String,
                                activity: Activity<MemoryNoteAttributes>) async {
        // 기존 startDate와 backgroundColor 유지
        let startDate = activity.contentState.startDate
        let backgroundColor = activity.contentState.backgroundColor
        let updatedState = MemoryNoteAttributes.ContentState(
            memo: memo,
            startDate: startDate,
            backgroundColor: backgroundColor
        )
        await activity.update(using: updatedState)
        print("Activity updated")
    }

    private func updateActivity(memo: String,
                                backgroundColor: ActivityBackgroundColor,
                                activity: Activity<MemoryNoteAttributes>) async {
        // startDate는 유지, memo와 backgroundColor 업데이트
        let startDate = activity.contentState.startDate
        let updatedState = MemoryNoteAttributes.ContentState(
            memo: memo,
            startDate: startDate,
            backgroundColor: backgroundColor
        )
        await activity.update(using: updatedState)
        print("Activity updated with new color: \(backgroundColor.displayName)")
    }

    func endActivity() async {
        guard let activity = currentActivity else { return }

        // 자동 종료 태스크 취소
        dismissalTask?.cancel()
        dismissalTask = nil

        // 자정 업데이트 태스크 취소
        midnightUpdateTask?.cancel()
        midnightUpdateTask = nil

        let finalState = MemoryNoteAttributes.ContentState(
            memo: "",
            startDate: Date(),
            backgroundColor: activity.contentState.backgroundColor
        )
        await activity.end(using: finalState, dismissalPolicy: .immediate)
        currentActivity = nil
        activityStartDate = nil
        lastUpdateDate = nil
        print("Activity ended")
    }

    func checkDateChangeAndUpdate() async {
        guard let activity = currentActivity,
              let lastDate = lastUpdateDate else { return }

        let calendar = Calendar.current
        let today = Date()

        // 날짜가 바뀌었는지 체크
        if !calendar.isDate(lastDate, inSameDayAs: today) {
            // 날짜가 바뀌었으면 업데이트 (내용은 그대로, state만 업데이트해서 UI 리프레시)
            let updatedState = MemoryNoteAttributes.ContentState(
                memo: activity.contentState.memo,
                startDate: activity.contentState.startDate,
                backgroundColor: activity.contentState.backgroundColor
            )
            await activity.update(using: updatedState)
            lastUpdateDate = today
            print("Activity updated due to date change")
        }
    }

    // MARK: - Private Methods

    private func scheduleAutoDismissal() {
        dismissalTask?.cancel()

        dismissalTask = Task {
            // 8시간 대기
            try? await Task.sleep(nanoseconds: 8 * 60 * 60 * 1_000_000_000)

            // 태스크가 취소되지 않았으면 자동 종료
            if !Task.isCancelled {
                await endActivity()
                print("Activity auto-dismissed after 8 hours")
            }
        }
    }

    private func scheduleMidnightUpdate() {
        midnightUpdateTask?.cancel()

        midnightUpdateTask = Task {
            while !Task.isCancelled {
                // 다음 자정까지의 시간 계산
                let calendar = Calendar.current
                let now = Date()

                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                      let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
                    return
                }

                let timeUntilMidnight = midnight.timeIntervalSince(now)

                // 자정까지 대기
                try? await Task.sleep(nanoseconds: UInt64(timeUntilMidnight * 1_000_000_000))

                if !Task.isCancelled {
                    // 자정이 되면 날짜 업데이트
                    await checkDateChangeAndUpdate()
                    print("Activity updated at midnight")
                }
            }
        }
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
