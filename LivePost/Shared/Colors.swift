import SwiftUI

/// 앱 전체에서 사용하는 색상 상수
struct AppColors {

    // MARK: - Background Colors

    /// 메인 배경 그라데이션 색상
    struct Background {
        /// 다크모드 배경 그라데이션 시작색
        static let darkStart = Color(white: 0.12)
        /// 다크모드 배경 그라데이션 끝색
        static let darkEnd = Color(white: 0.08)
        /// 라이트모드 배경 그라데이션 시작색
        static let lightStart = Color(white: 0.98)
        /// 라이트모드 배경 그라데이션 끝색
        static let lightEnd = Color(white: 0.92)

        /// 배경 그라데이션 색상 배열 반환
        static func gradient(for colorScheme: ColorScheme) -> [Color] {
            colorScheme == .dark
                ? [darkStart, darkEnd]
                : [lightStart, lightEnd]
        }
    }

    // MARK: - Card & Container Colors

    /// 카드 및 컨테이너 배경색
    struct Card {
        /// 카드 배경색
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.white
        }

        /// 카드 배경색 (대체 스타일)
        static func backgroundAlt(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04)
        }

        /// 그림자 색상
        static func shadow(for colorScheme: ColorScheme) -> Color {
            Color.black.opacity(colorScheme == .dark ? 0.5 : 0.12)
        }

        /// 그림자 색상 (약한 버전)
        static func shadowLight(for colorScheme: ColorScheme) -> Color {
            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
        }

        /// 구분선/테두리 색상
        static let stroke = Color.white.opacity(0.12)
    }

    // MARK: - Component Colors

    /// 팔레트 배경색
    struct Palette {
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.black.opacity(0.05)
        }

        static func shadow(for colorScheme: ColorScheme) -> Color {
            Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15)
        }
    }

    /// 토스트 배경색
    struct Toast {
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.12)
                : Color.black.opacity(0.75)
        }
    }

    /// 헤더 색상
    struct Header {
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04)
        }

        static func foreground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.8)
                : Color.black.opacity(0.7)
        }
    }

    /// Dock 배경색
    struct Dock {
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04)
        }
    }

    /// 온보딩 UI 요소 색상
    struct Onboarding {
        /// 가이드 카드 배경색
        static func cardBackground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.03)
        }

        /// 가이드 카드 배경색 (중간 톤)
        static func cardBackgroundMedium(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04)
        }

        /// 가이드 카드 배경색 (강조)
        static func cardBackgroundStrong(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.black.opacity(0.04)
        }

        /// Live Activity 미리보기 기본 배경색
        static let previewBackground = Color(white: 0.15)
    }

    // MARK: - Overlay Colors

    /// 오버레이 색상 (로딩 등)
    struct Overlay {
        static let loading = Color.black.opacity(0.5)
    }

    // MARK: - Button Colors

    /// 버튼 그림자 색상
    struct Button {
        static let shadow = Color.black.opacity(0.3)
    }

    // MARK: - Bottom Sheet Colors

    /// Bottom Sheet 배경색
    struct BottomSheet {
        static func backgroundGradient(for colorScheme: ColorScheme) -> [Color] {
            colorScheme == .dark
                ? [Color.black.opacity(0), Color.black]
                : [Color.white.opacity(0), Color.white]
        }
    }

    // MARK: - Activity Palette Colors

    /// Live Activity 배경 색상 팔레트
    struct ActivityPalette {
        static let darkGray = Color(white: 0.15)
        static let black = Color.black
        static let navy = Color(red: 0.1, green: 0.15, blue: 0.3)
        static let purple = Color(red: 0.4, green: 0.2, blue: 0.6)
        static let pink = Color(red: 0.9, green: 0.4, blue: 0.6)
        static let orange = Color(red: 0.9, green: 0.5, blue: 0.2)
        static let green = Color(red: 0.2, green: 0.6, blue: 0.4)
        static let blue = Color(red: 0.2, green: 0.5, blue: 0.8)
        static let red = Color(red: 0.8, green: 0.2, blue: 0.3)
    }

    // MARK: - Widget Colors

    /// 위젯 색상
    struct Widget {
        static let iconStroke = Color.white.opacity(0.2)
    }
}
