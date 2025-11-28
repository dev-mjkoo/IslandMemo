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
    private var dismissalTask: Task<Void, Never>?

    private init() {}

    var isActivityRunning: Bool {
        currentActivity != nil
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

        let attributes = MemoryNoteAttributes(label: AppStrings.appName)
        let initialState = MemoryNoteAttributes.ContentState(memo: memo, startDate: Date())

        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil // 로컬 업데이트만 사용
            )
            currentActivity = activity
            print("Activity started: \(activity.id)")

            // 8시간 후 자동 종료 스케줄
            scheduleAutoDismissal()
        } catch {
            print("Failed to start activity: \(error)")
        }
    }

    func updateActivity(with memo: String) async {
        guard let activity = currentActivity else { return }
        await updateActivity(memo: memo, activity: activity)
    }

    private func updateActivity(memo: String,
                                activity: Activity<MemoryNoteAttributes>) async {
        // 기존 startDate 유지
        let startDate = activity.contentState.startDate
        let updatedState = MemoryNoteAttributes.ContentState(memo: memo, startDate: startDate)
        await activity.update(using: updatedState)
        print("Activity updated")
    }

    func endActivity() async {
        guard let activity = currentActivity else { return }

        // 자동 종료 태스크 취소
        dismissalTask?.cancel()
        dismissalTask = nil

        let finalState = MemoryNoteAttributes.ContentState(memo: "", startDate: Date())
        await activity.end(using: finalState, dismissalPolicy: .immediate)
        currentActivity = nil
        print("Activity ended")
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
}
