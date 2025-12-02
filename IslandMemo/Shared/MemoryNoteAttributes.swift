import ActivityKit
import Foundation
import SwiftUI

// MARK: - Activity Background Color

enum ActivityBackgroundColor: String, Codable, CaseIterable {
    case darkGray = "darkGray"
    case black = "black"
    case navy = "navy"
    case purple = "purple"
    case pink = "pink"
    case orange = "orange"
    case green = "green"
    case blue = "blue"
    case red = "red"

    var color: Color {
        switch self {
        case .darkGray: return Color(white: 0.15)
        case .black: return .black
        case .navy: return Color(red: 0.1, green: 0.15, blue: 0.3)
        case .purple: return Color(red: 0.4, green: 0.2, blue: 0.6)
        case .pink: return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .orange: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .green: return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .blue: return Color(red: 0.2, green: 0.5, blue: 0.8)
        case .red: return Color(red: 0.8, green: 0.2, blue: 0.3)
        }
    }

    var displayName: String {
        switch self {
        case .darkGray: return "다크그레이"
        case .black: return "블랙"
        case .navy: return "네이비"
        case .purple: return "퍼플"
        case .pink: return "핑크"
        case .orange: return "오렌지"
        case .green: return "그린"
        case .blue: return "블루"
        case .red: return "레드"
        }
    }
}

struct MemoryNoteAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var memo: String
        var startDate: Date
        var backgroundColor: ActivityBackgroundColor
    }

    var label: String
}

// MARK: - Preview helpers

extension MemoryNoteAttributes {
    static var preview: MemoryNoteAttributes {
        MemoryNoteAttributes(label: AppStrings.appName)
    }
}

extension MemoryNoteAttributes.ContentState {
    static var sample: MemoryNoteAttributes.ContentState {
        MemoryNoteAttributes.ContentState(memo: AppStrings.sampleMemo, startDate: Date(), backgroundColor: .darkGray)
    }
}

// MARK: - Time Message Helper

extension MemoryNoteAttributes {
    static func getTimeMessage(remaining: TimeInterval) -> (icon: String, text: String, color: Color) {
        let minutes = Int(remaining / 60)

        if remaining < 5 * 60 { // 5분 미만
            return ("exclamationmark.circle.fill", "긴급 • 지금 앱 열어 연장", .red)
        } else if remaining < 30 * 60 { // 5분~30분
            return ("exclamationmark.triangle.fill", "곧 종료 • 지금 연장하세요", .orange)
        } else if remaining < 60 * 60 { // 30분~1시간
            return ("clock.badge.exclamationmark", "\(minutes)분 남음 • 앱에서 연장", .yellow)
        } else { // 1시간 이상 - 타이머만 표시할 것이므로 빈 텍스트
            return ("clock", "", .white)
        }
    }
}
