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
        case .darkGray: return AppColors.ActivityPalette.darkGray
        case .black: return AppColors.ActivityPalette.black
        case .navy: return AppColors.ActivityPalette.navy
        case .purple: return AppColors.ActivityPalette.purple
        case .pink: return AppColors.ActivityPalette.pink
        case .orange: return AppColors.ActivityPalette.orange
        case .green: return AppColors.ActivityPalette.green
        case .blue: return AppColors.ActivityPalette.blue
        case .red: return AppColors.ActivityPalette.red
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
        MemoryNoteAttributes(label: AppStrings.appMessage)
    }
}

extension MemoryNoteAttributes.ContentState {
    static var sample: MemoryNoteAttributes.ContentState {
        MemoryNoteAttributes.ContentState(memo: AppStrings.sampleMemo, startDate: Date(), backgroundColor: .darkGray)
    }
}

