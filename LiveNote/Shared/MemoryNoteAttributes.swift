//
// MemoryNoteAttributes.swift
// LiveNote
//
// ⚠️ 경고: 이 파일은 Live Activity 및 UserDefaults에 저장되는 Codable 타입입니다.
//         출시 후 변경 시 사용자 설정 손실 및 앱 크래시 위험!
//
// 🔴 절대 변경 금지 사항 (ActivityBackgroundColor enum):
// 1. Raw Value 변경 금지
//    - case darkGray = "darkGray" ❌ "dark_gray"로 변경 금지
//    - UserDefaults 키 "selectedBackgroundColor"에 저장됨
//    - Live Activity state에도 저장됨
//
// 2. Enum Case 삭제 금지
//    - 기존 사용자가 해당 색상을 사용 중일 수 있음
//    - 삭제 시 앱 크래시 발생
//    - 숨기려면: isAvailableInPalette에서 false 반환
//
// 3. Codable 준수 유지
//    - 시스템이 자동으로 직렬화/역직렬화
//    - 구조 변경 시 기존 데이터 복원 불가
//
// ✅ 안전하게 변경 가능한 것:
// - 새로운 case 추가 (맨 끝에만)
// - color 계산 속성 수정 (UI 색상 변경)
// - displayName 수정 (표시 이름 변경)
// - isAvailableInPalette로 색상 숨기기/보이기
//
// 📝 새 색상 추가 방법:
// 1. enum 맨 끝에 새 case 추가
// 2. color, displayName, isAvailableInPalette에 케이스 추가
// 3. AppColors.ActivityPalette에 컬러 정의
//
// 📚 관련 파일:
// - LiveActivityManager.swift (색상 저장/로딩)
// - Views/ColorPalette.swift (색상 선택 UI)
// - Services/AppColors.swift (실제 색상 정의)
//

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
    case white = "white"

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
        case .white: return AppColors.ActivityPalette.white
        }
    }

    /// 밝은 색상인지 여부 (어두운 텍스트가 필요한 배경색)
    /// ⚠️ 새 밝은 색상 추가 시 여기에 추가 필수
    /// - Live Activity, 메모 카드의 텍스트 색상이 자동으로 검정색으로 변경됨
    /// - 추가하지 않으면 밝은 배경에 흰 글씨가 되어 가독성 문제 발생
    var isLightColor: Bool {
        switch self {
        case .white, .yellow, .mint, .pink, .orange:
            return true
        default:
            return false
        }
    }

    /// 배경색에 적합한 텍스트 색상
    /// - 밝은 배경: 검정 글씨
    /// - 어두운 배경: 흰 글씨
    var textColor: Color {
        isLightColor ? .black : .white
    }

    /// 배경색에 적합한 보조 텍스트 색상 (약간 투명)
    /// - 밝은 배경: 검정 0.6 투명도
    /// - 어두운 배경: 흰색 0.6 투명도
    var secondaryTextColor: Color {
        isLightColor ? Color.black.opacity(0.6) : Color.white.opacity(0.6)
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
        case .white: return "화이트"
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
        case .indigo: return false  // 숨김 (기존 사용자 호환용)
        case .brown: return true
        case .white: return true
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

        /// 달력 대신 사진 사용 여부
        /// ⚠️ 기본값 변경 금지: false → true로 변경 시 기존 사용자 Live Activity가 사진 표시 시도
        /// - false: 달력 표시 (CalendarGridView)
        /// - true: 사진 표시 (PhotoView, CalendarImageManager 사용)
        var usePhoto: Bool = false
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

