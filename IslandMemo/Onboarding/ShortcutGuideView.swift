//
//  ShortcutGuideView.swift
//  IslandMemo
//

import SwiftUI

// MARK: - Shortcut Guide View

struct ShortcutGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0
    var onDismiss: (() -> Void)? = nil

    private let pages = GuidePage.allPages

    var body: some View {
        NavigationView {
            ZStack {
                // 배경
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.black, Color(white: 0.08)]
                        : [Color(white: 0.98), Color(white: 0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // TabView
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            GuidePageView(page: pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // 하단 UI: Page Dots → 다음 버튼
                    VStack(spacing: 16) {
                        // 건너뛰기 제거 (빈 공간으로 대체)
                        Text("")
                            .font(.system(size: 14))
                            .opacity(0)

                        // Page Dots
                        HStack(spacing: 8) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                            }
                        }
                        .padding(.vertical, 4)

                        // 다음/완료 버튼
                        if currentPage == pages.count - 1 {
                            Button {
                                HapticManager.medium()
                                onDismiss?()
                                dismiss()
                            } label: {
                                Text("완료")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.accentColor)
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                HapticManager.light()
                                withAnimation {
                                    currentPage += 1
                                }
                            } label: {
                                HStack {
                                    Text("다음")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("단축어 설정 가이드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        onDismiss?()
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
}

struct GuidePage {
    let icon: String
    let title: String
    let description: String
    let step: String?

    // 공유 pages 배열
    static let allPages: [GuidePage] = [
        GuidePage(
            icon: "liveactivity",
            title: "잠금화면 메모",
            description: "잠금화면에 표시되는 메모/달력은\n시스템 상 8시간 뒤에 자동으로 꺼집니다",
            step: "이를 방지하기 위해 단축어 자동화 설정을 추가하면\n24시간 내내 항상 보이게 할 수 있어요"
        ),
        GuidePage(
            icon: "text",
            title: "1단계: 자동화 만들기",
            description: "1. '단축어' 앱 실행\n2. 하단 '자동화' 탭 선택\n3. 우측 상단 '+' 버튼 클릭\n4. '특정 시간' 클릭",
            step: nil
        ),
        GuidePage(
            icon: "image_step2",
            title: "2단계: 시간 설정",
            description: "1. 시간: 00:00 설정\n2. 반복: 매일\n3. '즉시 실행' 선택\n4. '다음' 버튼 클릭",
            step: nil
        ),
        GuidePage(
            icon: "text",
            title: "3단계: 동작 추가",
            description: "1. 검색창에 '\(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Island Memo")' 입력\n2. '잠금화면 표시 시간 연장' 선택",
            step: nil
        ),
        GuidePage(
            icon: "step4",
            title: "4단계: 나머지 2개 추가",
            description: "같은 방법으로 08:00, 16:00 자동화 생성",
            step: "총 3개 자동화가 만들어지면\n24시간 자동 연장 설정 완료!"
        ),
        GuidePage(
            icon: "checkmark.circle.fill",
            title: "설정 완료!",
            description: "이제 메모가 24시간 내내 유지됩니다",
            step: "00시, 08시, 16시마다\n자동으로 잠금화면 표시가 연장돼요"
        )
    ]
}

struct GuidePageView: View {
    let page: GuidePage
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIcon = false
    @State private var typedMemo = ""

    private let fullMemo = "오늘 할 일\n- 디자인 피드백\n- 온보딩 수정"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // 제목
                Text(page.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)

                // Step indicator (1,2,3,4단계만)
                if page.icon == "text" || page.icon == "image_step2" || page.icon == "step4" {
                    stepIndicatorView
                        .padding(.bottom, 16)
                }

                // 설명 (AttributedString으로 강조 처리)
                descriptionView
                    .padding(.horizontal, currentStep > 0 ? 24 : 40)
                    .padding(.bottom, 24)

                // 추가 단계 (step이 있으면 먼저 표시)
                if let step = page.step {
                    stepView(step)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }

                // 첫 페이지(liveactivity)는 아래쪽에 프리뷰 표시
                if page.icon == "liveactivity" {
                    Spacer(minLength: 20)
                }

                // 아이콘 + 시각적 데모
                visualDemo
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animateIcon = true
                        }
                    }
                    .padding(.bottom, 24)

                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    // 현재 단계 계산
    private var currentStep: Int {
        if page.title.contains("1단계") {
            return 1
        } else if page.title.contains("2단계") {
            return 2
        } else if page.title.contains("3단계") {
            return 3
        } else if page.title.contains("4단계") {
            return 4
        } else {
            return 0
        }
    }

    // Step Indicator (1→2→3→4 단계 표시 - 사각형 스타일)
    @ViewBuilder
    private var stepIndicatorView: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { step in
                // 사각형 바
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(height: 8)
            }
        }
        .padding(.horizontal, 40)
    }

    // 설명 텍스트 (강조 포함)
    @ViewBuilder
    private var descriptionView: some View {
        // 1,2,3,4단계는 카드 스타일로
        if currentStep > 0 {
            VStack(spacing: 12) {
                // 2단계(시간 설정)는 특별 처리: 1-3번을 하나의 카드로, 4번을 별도 카드로
                if page.title.contains("2단계") {
                    let steps = page.description.split(separator: "\n")

                    // 첫 번째 카드: 1-3번 합침
                    multiStepCard(number: 1, texts: Array(steps.prefix(3)))

                    // 두 번째 카드: 4번
                    if steps.count > 3 {
                        stepCard(number: 2, text: String(steps[3]))
                    }
                } else {
                    // 다른 단계는 기본 처리
                    let steps = page.description.split(separator: "\n")
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, stepText in
                        stepCard(number: index + 1, text: String(stepText))
                    }
                }
            }
        } else {
            // 첫 페이지는 기존 스타일 유지
            Text(highlightedDescription())
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
    }

    // 여러 단계를 하나의 카드로 (2단계 전용)
    @ViewBuilder
    private func multiStepCard(number: Int, texts: [Substring]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 번호
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            // 여러 줄 텍스트 (구분선 포함)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(texts.enumerated()), id: \.offset) { index, text in
                    Text(highlightKeywords(removeNumberPrefix(String(text))))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(2)
                        .padding(.vertical, 6)

                    // 마지막 아이템 제외하고 구분선
                    if index < texts.count - 1 {
                        Divider()
                            .background(Color.secondary.opacity(0.2))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // 단계별 카드 (링크 온보딩 스타일)
    @ViewBuilder
    private func stepCard(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            // 번호
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            // 텍스트 (번호 제거, 키워드 강조)
            Text(highlightKeywords(removeNumberPrefix(text)))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(2)

            // 1단계 첫 번째 카드에만 단축어 앱 바로가기 화살표
            if page.title.contains("1단계") && number == 1 {
                Button {
                    HapticManager.light()
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // "1. " 또는 "2. " 같은 번호 prefix 제거
    private func removeNumberPrefix(_ text: String) -> String {
        // "1. " 형식 제거
        if let range = text.range(of: "^[0-9]+\\.\\s*", options: .regularExpression) {
            return String(text[range.upperBound...])
        }
        return text
    }

    // 키워드 강조
    private func highlightKeywords(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        // GuidePage.allPages에서 사용하는 것과 정확히 동일한 방식으로 앱 이름 가져오기
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Island Memo"
        let quotedAppName = "'\(appName)'"

        // 앱 이름 먼저 강조
        if let range = attributed.range(of: quotedAppName) {
            attributed[range].foregroundColor = .accentColor
            attributed[range].font = .system(size: 14, weight: .semibold, design: .rounded)
        }

        let keywords = [
            "'단축어'", "'자동화'", "'+'", "'특정 시간'",
            "00:00", "매일", "'즉시 실행'", "'다음'",
            "'잠금화면 표시 시간 연장'",
            "08:00", "16:00", "3개"
        ]

        for keyword in keywords {
            if let range = attributed.range(of: keyword) {
                attributed[range].foregroundColor = .accentColor
                attributed[range].font = .system(size: 14, weight: .semibold, design: .rounded)
            }
        }

        return attributed
    }

    // 강조해야 할 부분들을 AttributedString으로 처리
    private func highlightedDescription() -> AttributedString {
        var attributed = AttributedString(page.description)

        // 강조할 키워드들
        let highlights = [
            "'단축어'", "'자동화'", "'+'",
            "'특정 시간'",
            "00:00", "매일", "'즉시 실행'", "'다음'",
            "'잠금화면 표시 시간 연장'",
            "08:00", "16:00", "3개"
        ]

        for highlight in highlights {
            if let range = attributed.range(of: highlight) {
                attributed[range].foregroundColor = .accentColor
                attributed[range].font = .system(size: 16, weight: .bold, design: .rounded)
            }
        }

        return attributed
    }

    // 추가 단계 뷰
    @ViewBuilder
    private func stepView(_ step: String) -> some View {
        Text(highlightedStep(step))
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.black.opacity(0.04))
            )
    }

    private func highlightedStep(_ step: String) -> AttributedString {
        var attributed = AttributedString(step)

        let stepHighlights = [
            "08:00", "16:00", "3개", "24시간"
        ]

        for highlight in stepHighlights {
            if let range = attributed.range(of: highlight) {
                attributed[range].foregroundColor = .accentColor
                attributed[range].font = .system(size: 14, weight: .bold, design: .rounded)
            }
        }

        return attributed
    }

    @ViewBuilder
    private var visualDemo: some View {
        switch page.icon {
        case "liveactivity":
            // Live Activity UI 미리보기
            liveActivityDemo
        case "text":
            // 텍스트 전용 페이지 - 아이콘 없음
            EmptyView()
        case "image_step2":
            // 2단계 UI 시뮬레이션
            timeSettingUIDemo
        case "step4":
            // 4단계: 3개 자동화 리스트 시뮬레이션
            automationListDemo
        default:
            // 기본 아이콘
            Image(systemName: page.icon)
                .font(.system(size: 80, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 20)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
        }
    }

    // MARK: - Demo Views

    private var timeSettingUIDemo: some View {
        VStack(spacing: 16) {
            // 시간 선택 카드
            VStack(spacing: 12) {
                Text("시간")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    Text("00")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    Text(":")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor.opacity(0.5))
                    Text("00")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )

            // 반복 + 즉시 실행 카드
            VStack(spacing: 0) {
                // 반복: 매일
                HStack {
                    Text("반복")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("매일")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.accentColor)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .padding(16)

                Divider()

                // 즉시 실행
                HStack {
                    Text("즉시 실행")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .scaleEffect(animateIcon ? 1.2 : 1.0)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 350)
    }

    private var liveActivityDemo: some View {
        // 실제 Live Activity UI 재사용
        LiveActivityLockScreenPreview(
            label: AppStrings.appMessage,
            memo: typedMemo,
            startDate: Date().addingTimeInterval(-30 * 60), // 30분 전 시작 (7시간 30분 남음)
            backgroundColor: .darkGray
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.15))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
        )
        .padding(.horizontal, 32)
        .scaleEffect(animateIcon ? 1.02 : 1.0)
        .onAppear {
            if page.icon == "liveactivity" {
                startTypingAnimation()
            }
        }
    }

    private var shortcutAppDemo: some View {
        VStack(spacing: 24) {
            // 단축어 앱 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.gradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.blue.opacity(0.4), radius: 12, y: 8)

                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)

            // 하단 탭 바 시뮬레이션
            HStack(spacing: 50) {
                VStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("나의 단축어")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                VStack(spacing: 6) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                    Text("자동화")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .scaleEffect(animateIcon ? 1.08 : 1.0)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 50)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )

            // + 버튼 (펄스 효과)
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(animateIcon ? 1.4 : 1.0)
                    .opacity(animateIcon ? 0 : 0.5)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 8)
            }
        }
        .padding(.vertical, 20)
    }

    private var timeSettingDemo: some View {
        VStack(spacing: 28) {
            // 시간 표시
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .frame(height: 100)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                Text("00:00")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 40)

            // 화살표
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))

            // 동작 추가 버튼
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                Text("Island Memo")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentColor.gradient)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 6)
            )
            .scaleEffect(animateIcon ? 1.04 : 1.0)

            // 잠금화면 표시 시간 연장 액션
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                Text("잠금화면 표시 시간 연장")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    private var automationListDemo: some View {
        VStack(spacing: 0) {
            // 3개 자동화 리스트
            ForEach(Array(["00:00", "08:00", "16:00"].enumerated()), id: \.offset) { index, time in
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // 시계 아이콘
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 40, height: 40)

                            Image(systemName: "clock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        // 화살표
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.5))

                        // 앱 아이콘 (Bundle에서 가져오기)
                        if let appIcon = getAppIcon() {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .cornerRadius(9)
                        } else {
                            // Fallback: 기본 아이콘
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "app.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }

                        // 텍스트
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: NSLocalizedString("매일 %@에", comment: ""), time))
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.primary)
                            Text(NSLocalizedString("잠금화면 표시 시간 연장", comment: ""))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Chevron
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))

                    // 마지막 아이템이 아니면 구분선
                    if index < 2 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
        }
        .cornerRadius(10)
        .padding(.horizontal, 24)
        .scaleEffect(animateIcon ? 1.005 : 1.0)
        .padding(.vertical, 20)
    }

    // 앱 아이콘 가져오기
    private func getAppIcon() -> UIImage? {
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }

    // 타이핑 애니메이션
    private func startTypingAnimation() {
        typedMemo = ""

        Task {
            // 0.8초 대기 (프리뷰 애니메이션 후)
            try? await Task.sleep(nanoseconds: 800_000_000)

            // 한 글자씩 추가
            for character in fullMemo {
                await MainActor.run {
                    typedMemo.append(character)
                }

                // 글자별 딜레이 (0.08초)
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
        }
    }
}

// MARK: - Embeddable Version for MainOnboardingFlow

struct ShortcutGuidePageWrapper: View {
    let pageIndex: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GuidePageView(page: GuidePage.allPages[pageIndex])
    }
}
