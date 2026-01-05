// Constants.swift

import Foundation

enum AppStrings {
    // MARK: - App Info
    static var appMessage: String {
        LocalizationManager.shared.string("LIVE NOTE")
    }
    static let appIcon = "📅"

    // MARK: - Status
    static var statusLive: String {
        LocalizationManager.shared.string("LIVE")
    }
    static var statusIdle: String {
        LocalizationManager.shared.string("IDLE")
    }
    static var statusOnScreen: String {
        LocalizationManager.shared.string("ON SCREEN")
    }
    static var statusReady: String {
        LocalizationManager.shared.string("READY")
    }

    // MARK: - Placeholders
    static var inputPlaceholder: String {
        LocalizationManager.shared.string("이 곳을 클릭해 메모 입력")
    }
    static let sampleMemo = "샘플 메모 미리보기"  // 미리보기용이라 번역 불필요
}
