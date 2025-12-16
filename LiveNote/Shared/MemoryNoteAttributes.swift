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
    case teal = "teal"
    case mint = "mint"
    case yellow = "yellow"
    case indigo = "indigo"
    case brown = "brown"

    var color: Color {
        switch self {
        case .darkGray: return AppColors.ActivityPalette.darkGray
        case .black: return AppColors.ActivityPalette.black
        case .navy: return AppColors.ActivityPalette.navy
        case .purple: return AppColors.ActivityPalette.purple
        case .pink: return AppColors.ActivityPalette.pink
        case .orange: return AppColors.ActivityPalette.orange
        case .green: return AppColors.ActivityPalette.green
        case .blue: return AppColors.ActivityPalette.blue
        case .red: return AppColors.ActivityPalette.red
        case .teal: return AppColors.ActivityPalette.teal
        case .mint: return AppColors.ActivityPalette.mint
        case .yellow: return AppColors.ActivityPalette.yellow
        case .indigo: return AppColors.ActivityPalette.indigo
        case .brown: return AppColors.ActivityPalette.brown
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
        case .teal: return "틸"
        case .mint: return "민트"
        case .yellow: return "옐로우"
        case .indigo: return "인디고"
        case .brown: return "브라운"
        }
    }

    /// 팔레트에서 선택 가능한 색상인지 여부
    /// - 나중에 색상을 숨기고 싶으면 여기서 false로 설정
    /// - enum case는 절대 삭제하지 말 것! (기존 사용자 호환성)
    var isAvailableInPalette: Bool {
        switch self {
        case .darkGray: return true
        case .black: return true
        case .navy: return true
        case .purple: return true
        case .pink: return true
        case .orange: return true
        case .green: return true
        case .blue: return true
        case .red: return true
        case .teal: return true
        case .mint: return true
        case .yellow: return true
        case .indigo: return true
        case .brown: return true
        // 나중에 색상을 숨기려면: case .yellow: return false
        }
    }

    /// 팔레트에 표시할 색상 목록 (숨겨진 색상 제외)
    static var availableColors: [ActivityBackgroundColor] {
        allCases.filter { $0.isAvailableInPalette }
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
        MemoryNoteAttributes(label: AppStrings.appMessage)
    }
}

extension MemoryNoteAttributes.ContentState {
    static var sample: MemoryNoteAttributes.ContentState {
        MemoryNoteAttributes.ContentState(memo: AppStrings.sampleMemo, startDate: Date(), backgroundColor: .darkGray)
    }
}

