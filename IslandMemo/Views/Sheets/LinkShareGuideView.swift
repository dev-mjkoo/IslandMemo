//
//  LinkShareGuideView.swift
//  IslandMemo
//

import SwiftUI

struct LinkShareGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    VStack(spacing: 8) {
                        Text("링크를 더 쉽게 저장해보세요")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text(highlightedDescription())
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                    // 단계별 가이드
                    VStack(spacing: 16) {
                        guideStep(
                            number: "1",
                            title: "다른 앱에서 링크 찾기",
                            description: "Safari, Chrome, YouTube 등 어떤 앱이든 OK",
                            icon: "safari",
                            iconColor: .blue
                        )

                        guideStep(
                            number: "2",
                            title: "공유 버튼 누르기",
                            description: "공유 아이콘을 탭하세요",
                            icon: "square.and.arrow.up",
                            iconColor: .blue
                        )

                        guideStep(
                            number: "3",
                            title: "Island Memo 선택",
                            description: "앱 목록에서 Island Memo를 찾아서 탭",
                            icon: "app.badge.checkmark",
                            iconColor: .green
                        )

                        guideStep(
                            number: "4",
                            title: "자동 저장 완료!",
                            description: "카테고리 선택하고 저장하면 끝",
                            icon: "checkmark.circle.fill",
                            iconColor: .green
                        )
                    }

                    // 팁 박스
                    tipBox

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("더 쉽게 사용하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func highlightedDescription() -> AttributedString {
        var attributed = AttributedString("'복사→붙여넣기 없이' 바로 링크 저장할 수 있어요")

        // '복사→붙여넣기 없이' 부분 강조
        if let range = attributed.range(of: "'복사→붙여넣기 없이'") {
            attributed[range].foregroundColor = .accentColor
            attributed[range].font = .system(size: 15, weight: .bold, design: .rounded)
        }

        return attributed
    }

    private func guideStep(number: String, title: String, description: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 16) {
            // 번호
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Text(number)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(iconColor.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    private var tipBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.yellow)

                Text("중요 Tip")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Text("공유 목록에 Island Memo가 안 보이면\n하단의 '더 보기' 버튼을 눌러서 찾아보세요")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.yellow.opacity(0.15))
                .shadow(color: Color.yellow.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Embeddable Version for MainOnboardingFlow

struct LinkShareGuideContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                VStack(spacing: 8) {
                    Text("링크를 더 쉽게 저장해보세요")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text(highlightedDescription())
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                // 단계별 가이드
                VStack(spacing: 16) {
                    guideStep(
                        number: "1",
                        title: "다른 앱에서 링크 찾기",
                        description: "Safari, Chrome, YouTube 등 어떤 앱이든 OK",
                        icon: "safari",
                        iconColor: .blue
                    )

                    guideStep(
                        number: "2",
                        title: "공유 버튼 누르기",
                        description: "공유 아이콘을 탭하세요",
                        icon: "square.and.arrow.up",
                        iconColor: .blue
                    )

                    guideStep(
                        number: "3",
                        title: "Island Memo 선택",
                        description: "앱 목록에서 Island Memo를 찾아서 탭",
                        icon: "app.badge.checkmark",
                        iconColor: .green
                    )

                    guideStep(
                        number: "4",
                        title: "자동 저장 완료!",
                        description: "카테고리 선택하고 저장하면 끝",
                        icon: "checkmark.circle.fill",
                        iconColor: .green
                    )
                }

                // 팁 박스
                tipBox

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }

    private func highlightedDescription() -> AttributedString {
        var attributed = AttributedString("'복사→붙여넣기 없이' 바로 링크 저장할 수 있어요")

        // '복사→붙여넣기 없이' 부분 강조
        if let range = attributed.range(of: "'복사→붙여넣기 없이'") {
            attributed[range].foregroundColor = .accentColor
            attributed[range].font = .system(size: 15, weight: .bold, design: .rounded)
        }

        return attributed
    }

    private func guideStep(number: String, title: String, description: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 16) {
            // 번호
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Text(number)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(iconColor.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    private var tipBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.yellow)

                Text("중요 Tip")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Text("공유 목록에 Island Memo가 안 보이면\n하단의 '더 보기' 버튼을 눌러서 찾아보세요")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.yellow.opacity(0.15))
                .shadow(color: Color.yellow.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1.5)
        )
    }
}
