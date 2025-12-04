//
//  MemoryActivityWidgetControl.swift
//  MemoryActivityWidget
//
//  Created by 구민준 on 11/26/25.
//

import AppIntents
import SwiftUI
import WidgetKit
import ActivityKit

struct MemoryActivityWidgetControl: ControlWidget {
    @available(iOS 18.0, *)
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "mjkoo.islandmemo.MemoryActivityWidget"
        ) {
            ControlWidgetButton(action: ExtendTimerIntent()) {
                Label("시간 연장", systemImage: "clock.arrow.circlepath")
            }
        }
        .displayName("잠금화면 표시 연장")
        .description("Live Activity 8시간 타이머를 리셋합니다")
    }
}

// MARK: - App Shortcuts Provider

struct IslandMemoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExtendTimerIntent(),
            phrases: [
                "\(.applicationName) 잠금화면 표시 연장",
                "\(.applicationName) 시간 연장",
                "\(.applicationName) 타이머 리셋"
            ],
            shortTitle: "잠금화면 표시 연장",
            systemImageName: "clock.arrow.circlepath"
        )
    }
}

// MARK: - Extend Timer Intent (단독 실행용)

struct ExtendTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "잠금화면 표시 시간 연장"
    static var description: IntentDescription = IntentDescription("잠금화면에 표시된 메모의 8시간 타이머를 리셋하여 계속 유지합니다")
    static var openAppWhenRun: Bool = true  // 앱을 열어서 Activity 생성 가능하도록

    @MainActor
    func perform() async throws -> some IntentResult {
        print("🎯 ExtendTimerIntent.perform() 시작!")

        // LiveActivityManager 사용
        await LiveActivityManager.shared.extendTime()
        print("✅ 단축어에서 잠금화면 표시 시간 연장 완료")
        return .result()
    }
}
