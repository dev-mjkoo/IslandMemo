//
//  MemoryActivityWidgetControl.swift
//  MemoryActivityWidget
//
//  Created by 구민준 on 11/26/25.
//

import AppIntents
import SwiftUI
import WidgetKit

struct MemoryActivityWidgetControl: ControlWidget {
    @available(iOS 18.0, *)
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "mjkoo.islandmemo.MemoryActivityWidget",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value,
                action: StartTimerIntent()
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

extension MemoryActivityWidgetControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool {
            false
        }

        func currentValue() async throws -> Bool {
            let isRunning = true // Check if the timer is running
            return isRunning
        }
    }
}

struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "잠금화면 표시 시간 연장"
    static let description: IntentDescription = "잠금화면에 표시된 메모의 8시간 타이머를 리셋하여 계속 유지합니다"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Timer is running")
    var value: Bool

    func perform() async throws -> some IntentResult {
        // Live Activity 시간 연장 (8시간 타이머 리셋)
        await MainActor.run {
            Task {
                await LiveActivityManager.shared.extendTime()
                print("✅ 단축어에서 잠금화면 표시 시간 연장 완료")
            }
        }
        return .result()
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
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        // Live Activity 시간 연장 (8시간 타이머 리셋)
        await MainActor.run {
            Task {
                await LiveActivityManager.shared.extendTime()
                print("✅ 단축어에서 잠금화면 표시 시간 연장 완료")
            }
        }
        return .result()
    }
}
