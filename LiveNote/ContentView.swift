// ContentView.swift

import SwiftUI
import ActivityKit
import UIKit
import SwiftData

struct ContentView: View {
    @State var memo: String = ""
    @StateObject var activityManager = LiveActivityManager.shared
    @FocusState var isFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @Query(sort: \LinkItem.createdAt, order: .reverse) var savedLinks: [LinkItem]
    @Query(sort: \Category.createdAt, order: .reverse) var storedCategories: [Category]
    @State var glowOpacity: Double = 0.3
    @State var isDeleteConfirmationActive: Bool = false
    @State var deleteConfirmationTask: Task<Void, Never>?
    @State var isColorPaletteVisible: Bool = false
    @State var pastedLink: String? = nil // 붙여넣은 링크 임시 저장
    @State var linkTitle: String = "" // 링크 제목 (선택)
    @State var selectedCategory: String = ""
    @State var isShowingLinksSheet: Bool = false
    @State var isShowingLinkInputSheet: Bool = false
    @State var isShowingShortcutGuide: Bool = false
    @State var hasSeenShortcutGuide: Bool = UserDefaults.standard.bool(forKey: PersistenceKeys.UserDefaults.hasSeenShortcutGuide)
    @State var hasSeenInitialOnboarding: Bool = UserDefaults.standard.bool(forKey: PersistenceKeys.UserDefaults.hasSeenInitialOnboarding)
    @State var hasSeenMemoGuide: Bool = UserDefaults.standard.bool(forKey: PersistenceKeys.UserDefaults.hasSeenMemoGuide)
    @State var hasSeenLinkGuide: Bool = UserDefaults.standard.bool(forKey: PersistenceKeys.UserDefaults.hasSeenLinkGuide)
    @State var isShowingInitialOnboarding: Bool = false
    @State var isShowingMemoOnboarding: Bool = false
    @State var isShowingLinkOnboarding: Bool = false
    @State var autoStartTask: Task<Void, Never>?
    @State var showToast: Bool = false
    @State var toastMessage: String = ""
    @State var isShowingLinkGuide: Bool = false
    @State var isShowingSettings: Bool = false
    @State var showReviewAlert: Bool = false

    var categories: [String] {
        storedCategories.map { $0.name }
    }

    let defaultMessage = AppStrings.inputPlaceholder

    var body: some View {
        ZStack {
            // 배경: 탭하면 키보드 내려감
            background
                .onAppear {
                    // Firebase Analytics: 기본 활성화 (처음 실행 시)
                    if UserDefaults.standard.object(forKey: "analyticsEnabled") == nil {
                        // 처음 설치하는 경우 기본으로 활성화
                        UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.analyticsEnabled)
                        FirebaseAnalyticsManager.shared.setAnalyticsEnabled(true)
                    } else {
                        // 기존 사용자는 저장된 설정 적용
                        let isEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.UserDefaults.analyticsEnabled)
                        FirebaseAnalyticsManager.shared.setAnalyticsEnabled(isEnabled)
                    }

                    // 블러 강도: 기본값 1.5 (중간) 설정 (처음 실행 시)
                    if let groupDefaults = UserDefaults(suiteName: PersistenceKeys.AppGroup.identifier) {
                        if groupDefaults.object(forKey: PersistenceKeys.UserDefaults.photoBlurIntensity) == nil {
                            // 처음 설치하는 경우 기본값 1.5 (0.0~3.0 중간)
                            groupDefaults.set(1.5, forKey: PersistenceKeys.UserDefaults.photoBlurIntensity)
                            groupDefaults.synchronize()
                        }
                    }

                    // Firebase Analytics: 앱 열기
                    FirebaseAnalyticsManager.shared.logAppOpen()
                    FirebaseAnalyticsManager.shared.setUserLanguage(LocalizationManager.shared.currentLanguageCode)

                    // 최초 온보딩 체크 (앱 처음 설치)
                    if !hasSeenInitialOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isShowingInitialOnboarding = true
                        }
                    }
                }
                .task {
                    // Activity 복원 시도
                    await activityManager.restoreActivityIfNeeded()

                    if let activity = activityManager.currentActivity {
                        // 복원 성공: 메모 내용 가져오기
                        let content = activity.content.state.memo
                        // 기본 메시지가 아닌 경우만 메모에 표시
                        if content != defaultMessage {
                            memo = content
                        }
                    } else {
                        // Activity가 없을 때: 저장된 메모 복원 시도
                        if let savedMemo = activityManager.loadSavedMemo(), !savedMemo.isEmpty {
                            // 저장된 메모가 있으면 복원하고 Activity 시작
                            memo = savedMemo
                            await activityManager.startActivity(with: savedMemo)
                        } else {
                            // 저장된 메모도 없으면 기본 메시지로 시작
                            await activityManager.startActivity(with: defaultMessage)
                        }
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // 앱이 foreground로 돌아올 때 체크
                    if newPhase == .active {
                        // Share Extension으로 저장된 링크가 있는지 체크
                        checkForShareExtensionLinks()
                    }
                }

            // 빈 공간 터치용 (버튼들을 피하기 위해 분리)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isFieldFocused = false
                    }
                    if isColorPaletteVisible {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isColorPaletteVisible = false
                        }
                    }
                }
                .allowsHitTesting(isFieldFocused || isColorPaletteVisible) // 키보드나 팔레트 있을 때만 터치 받기

            VStack(spacing: 28) {
                header
                previewCard
                Spacer(minLength: 0)
                ControlDock(activityManager: activityManager, isColorPaletteVisible: $isColorPaletteVisible)
            }
            .padding(20)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 12) {
                // 토스트 메시지
                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 색상 팔레트 (동적으로 표시, overlay로 레이아웃 영향 없음)
                if isColorPaletteVisible {
                    ColorPalette(activityManager: activityManager, isVisible: $isColorPaletteVisible)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.bottom, 100) // dock 위에 표시
        }
        .onChange(of: memo) { oldValue, newValue in
            // 기존 자동 시작 태스크 취소
            autoStartTask?.cancel()

            // 메모 최초 작성 체크 (비어있던 메모에 처음 입력)
            let isFirstMemoInput = oldValue.isEmpty && !newValue.isEmpty

            // 메모 최초 작성 시 카운트 증가 및 리뷰 요청 체크
            if isFirstMemoInput {
                let shouldShowReview = ReviewManager.shared.incrementMemoCount()
                if shouldShowReview {
                    // 약간의 딜레이 후 리뷰 Alert 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showReviewAlert = true
                    }
                }
            }

            // 메모 변경 시 App Group UserDefaults에 저장
            if newValue.isEmpty {
                // 메모가 비워지면 저장된 메모도 삭제
                activityManager.clearSavedMemo()
            } else {
                // 메모 내용 저장
                activityManager.saveMemo(newValue)
            }

            if activityManager.isActivityRunning {
                // 이미 실행 중이면 업데이트
                if newValue.isEmpty {
                    // 메모가 비워지면 즉시 기본 메시지로 전환 (동기적으로)
                    Task { @MainActor in
                        await activityManager.updateActivity(with: defaultMessage)
                    }
                } else {
                    // 메모 내용으로 업데이트
                    Task { @MainActor in
                        await activityManager.updateActivity(with: newValue)
                    }
                }
            } else {
                // Activity가 없을 때
                if newValue.isEmpty {
                    // 메모가 비어있으면 기본 메시지로 시작
                    Task { @MainActor in
                        await activityManager.startActivity(with: defaultMessage)
                    }
                } else {
                    // 메모가 있으면 0.5초 후 자동 시작 (디바운스)
                    autoStartTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초

                        if !Task.isCancelled && !newValue.isEmpty {
                            // Activity 먼저 시작
                            await activityManager.startActivity(with: newValue)
                        }
                    }
                }
            }

            // 메모가 비워지면 확인 상태 리셋
            if newValue.isEmpty {
                isDeleteConfirmationActive = false
                deleteConfirmationTask?.cancel()
            }
        }
        .onChange(of: isFieldFocused) { _, isFocused in
            if !isFocused {
                // 키보드가 내려가면 확인 상태 리셋
                isDeleteConfirmationActive = false
                deleteConfirmationTask?.cancel()

                // 키보드가 내려갈 때 메모 온보딩 체크
                if !memo.isEmpty && !hasSeenMemoGuide {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowingMemoOnboarding = true
                    }
                }
            } else {
                // 키보드가 올라오면 팔레트 닫기
                if isColorPaletteVisible {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isColorPaletteVisible = false
                    }
                }
            }
        }
        .onChange(of: activityManager.selectedBackgroundColor) { _, _ in
            // Live Activity가 동작 중이면 색상 즉시 업데이트
            if activityManager.isActivityRunning {
                Task {
                    await activityManager.updateBackgroundColor()
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // 앱이 active가 되면 Activity 복원
            if newPhase == .active {
                Task {
                    // 단축어 등에서 연장한 경우 대비하여 항상 복원 시도
                    await activityManager.restoreActivityIfNeeded()
                }
            }

            // 앱이 백그라운드로 갈 때 메모가 비어있으면 기본 메시지로 업데이트
            if newPhase == .background {
                if activityManager.isActivityRunning && memo.isEmpty {
                    Task {
                        await activityManager.updateActivity(with: defaultMessage)
                    }
                }
            }
        }
        .onChange(of: activityManager.currentActivity?.id) { _, _ in
            // Activity가 복원되거나 변경되면 메모 동기화
            if let activity = activityManager.currentActivity, memo.isEmpty {
                let content = activity.content.state.memo
                // 기본 메시지가 아닌 경우만 메모에 표시
                if content != defaultMessage {
                    memo = content
                }
            }
        }
        .sheet(isPresented: $isShowingLinksSheet) {
            LinksListView(categories: categories)
        }
        .sheet(isPresented: $isShowingShortcutGuide) {
            ShortcutGuideView {
                // 온보딩을 봤다고 표시
                hasSeenShortcutGuide = true
                UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.hasSeenShortcutGuide)

                // 온보딩 완료 후 메모가 있으면 자동 시작
                if !memo.isEmpty && !activityManager.isActivityRunning {
                    Task {
                        await activityManager.startActivity(with: memo)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingLinkInputSheet) {
            LinkInputSheet(
                linkURL: $pastedLink,
                linkTitle: $linkTitle,
                selectedCategory: $selectedCategory,
                onSave: {
                    saveLinkWithTitle(title: linkTitle.isEmpty ? nil : linkTitle)
                    isShowingLinkInputSheet = false
                },
                onCancel: {
                    pastedLink = nil
                    linkTitle = ""
                    isShowingLinkInputSheet = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingLinkGuide) {
            LinkShareGuideView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingInitialOnboarding) {
            InitialOnboardingFlow {
                // 완료 플래그 설정
                hasSeenInitialOnboarding = true
                UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.hasSeenInitialOnboarding)
            }
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $isShowingMemoOnboarding) {
            MemoOnboardingFlow {
                // 완료 플래그 설정
                hasSeenMemoGuide = true
                UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.hasSeenMemoGuide)

                // 레거시 플래그도 설정 (호환성)
                hasSeenShortcutGuide = true
                UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.hasSeenShortcutGuide)

                // 온보딩 완료 후 메모로 Activity 시작
                if !memo.isEmpty && !activityManager.isActivityRunning {
                    Task {
                        await activityManager.startActivity(with: memo)
                    }
                }
            }
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $isShowingLinkOnboarding) {
            LinkOnboardingFlow {
                // 완료 플래그 설정
                hasSeenLinkGuide = true
                UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.hasSeenLinkGuide)
            }
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .alert(
            LocalizationManager.shared.string("앱이 마음에 드시나요?"),
            isPresented: $showReviewAlert
        ) {
            Button(LocalizationManager.shared.string("리뷰 작성하기")) {
                ReviewManager.shared.markReviewRequested()
                ReviewManager.shared.openAppStoreReview()
            }
            Button(LocalizationManager.shared.string("나중에"), role: .cancel) {
                // 나중에 버튼을 눌러도 다시 표시하지 않도록 기록
                ReviewManager.shared.markReviewRequested()
            }
        } message: {
            Text(LocalizationManager.shared.string("이 앱에는 광고도 없고 수익도 못 내요.\n리뷰 하나면 충분히 힘날 것 같아요 🥺"))
        }
    }
}

// MARK: - Sections

extension ContentView {

    // MARK: Background

    var background: some View {
        LinearGradient(
            colors: AppColors.Background.gradient(for: colorScheme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    var header: some View {
        HStack {
            Capsule()
                .fill(headerBackground)
                .frame(height: 32)
                .overlay(
                    HStack(spacing: 8) {
                        Circle()
                            .fill(activityManager.isActivityRunning ? headerDotOn : headerDotOff)
                            .frame(width: 8, height: 8)
                            .shadow(
                                color: activityManager.isActivityRunning
                                    ? headerDotOn.opacity(glowOpacity)
                                    : headerDotOff.opacity(0.5),
                                radius: activityManager.isActivityRunning ? 6 : 4
                            )

                            Text(activityManager.isActivityRunning ? AppStrings.statusLive : AppStrings.statusIdle)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .tracking(2)
                                .textCase(.uppercase)
                                .foregroundStyle(headerForeground)
                    }
                    .padding(.horizontal, 10)
                )
                .onAppear {
                    startGlowAnimation()
                }
                .onChange(of: activityManager.isActivityRunning) { _, isRunning in
                    if isRunning {
                        startGlowAnimation()
                    } else {
                        glowOpacity = 0.3
                    }
                }

            Spacer()

            // 달력 버튼
            Button {
                HapticManager.light()
                if let url = URL(string: "calshow://") {
                    openURL(url)
                }
            } label: {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(headerForeground.opacity(0.3), lineWidth: 1)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(AppStrings.appIcon)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(headerForeground)
                    )
            }
            .buttonStyle(.plain)

            // 설정 버튼
            Button {
                HapticManager.light()
                isShowingSettings = true
            } label: {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(headerForeground.opacity(0.3), lineWidth: 1)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(headerForeground)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    var headerBackground: Color {
        AppColors.Header.background(for: colorScheme)
    }

    var headerForeground: Color {
        AppColors.Header.foreground(for: colorScheme)
    }

    var headerDotOn: Color {
        .green
    }

    var headerDotOff: Color {
        .red
    }

    // MARK: Preview Card (Live Activity 스타일)

    var previewCard: some View {
        let baseBackground: Color = activityManager.selectedBackgroundColor.color
        let strokeColor: Color = AppColors.Card.stroke
        let textColor: Color = .white
        let secondaryTextColor: Color = .white.opacity(0.7)

        return RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(baseBackground)
            .animation(.easeInOut(duration: 0.2), value: baseBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(
                color: AppColors.Card.shadow(for: colorScheme),
                radius: 18, x: 0, y: 12
            )
            .overlay(
                VStack(alignment: .leading, spacing: 0) {
                    // 상단: 메모 영역
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Capsule()
                                .fill(strokeColor)
                                .frame(width: 28, height: 4)

                            Text(formattedDate)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(secondaryTextColor)

                            Spacer()

                            // 단축어 가이드 버튼
                            Button {
                                HapticManager.light()
                                isShowingShortcutGuide = true
                            } label: {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(secondaryTextColor.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }

                        ZStack(alignment: .topLeading) {
                            if memo.isEmpty && !isFieldFocused {
                                Text(AppStrings.inputPlaceholder)
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundStyle(textColor.opacity(0.3))
                                    .padding(.top, 8)
                            }

                            TextEditor(text: $memo)
                                .focused($isFieldFocused)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(textColor)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .textInputAutocapitalization(.sentences)
                                .padding(.trailing, isFieldFocused && !memo.isEmpty ? 40 : 0)

                            // Clear button
                            if isFieldFocused && !memo.isEmpty {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button {
                                            if isDeleteConfirmationActive {
                                                // 두 번째 클릭: 진짜 삭제
                                                HapticManager.medium()
                                                memo = ""
                                                isDeleteConfirmationActive = false
                                                deleteConfirmationTask?.cancel()
                                            } else {
                                                // 첫 번째 클릭: 확인 상태로 전환
                                                HapticManager.light()
                                                isDeleteConfirmationActive = true

                                                // 3초 후 자동으로 확인 상태 해제
                                                deleteConfirmationTask?.cancel()
                                                deleteConfirmationTask = Task {
                                                    try? await Task.sleep(for: .seconds(3))
                                                    if !Task.isCancelled {
                                                        isDeleteConfirmationActive = false
                                                    }
                                                }
                                            }
                                        } label: {
                                            Image(systemName: isDeleteConfirmationActive ? "trash.fill" : "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(
                                                    isDeleteConfirmationActive
                                                    ? Color.red.opacity(0.9)
                                                    : textColor.opacity(0.5)
                                                )
                                                .contentTransition(.symbolEffect(.replace))
                                                .padding(6)
                                                .background(
                                                    Circle()
                                                        .fill(baseBackground)
                                                        .shadow(
                                                            color: AppColors.Button.shadow,
                                                            radius: 4, x: 0, y: 2
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.easeInOut(duration: 0.2), value: isDeleteConfirmationActive)
                                    }
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                        .frame(minHeight: 60)

                        // TimelineView로 감싸서 1초마다 isActivityRunning 재평가
                        TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                            if activityManager.isActivityRunning, let activity = activityManager.currentActivity {
                                activityTimerSection(activity: activity, textColor: textColor, secondaryTextColor: secondaryTextColor)
                            } else {
                                HStack {
                                    Text(AppStrings.statusReady)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(secondaryTextColor)

                                    Spacer()

                                    Image(systemName: "lock.slash")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(secondaryTextColor.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)

                    // 구분선
                    Rectangle()
                        .fill(strokeColor)
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // 하단: 링크 영역
                    VStack(spacing: 0) {
                        // 링크 섹션 헤더
                        HStack(spacing: 0) {
                            Text(LocalizationManager.shared.string("링크 저장"))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(secondaryTextColor)

                            Spacer()

                            // 링크 가이드 버튼
                            Button {
                                HapticManager.light()
                                isShowingLinkGuide = true
                            } label: {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(secondaryTextColor.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                    HStack(spacing: 8) {
                        // 링크 저장하기 버튼
                        Button {
                            HapticManager.medium()
                            handleLinkSaveAction()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 14, weight: .semibold))

                                Text(LocalizationManager.shared.string("링크 붙여넣기"))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(textColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(strokeColor)
                            )
                        }
                        .buttonStyle(.plain)

                        // 저장된 링크 보기 버튼
                        Button {
                            HapticManager.medium()
                            isShowingLinksSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(savedLinks.isEmpty ? LocalizationManager.shared.string("링크 없음") : "\(savedLinks.count)\(LocalizationManager.shared.countSuffix())")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(secondaryTextColor.opacity(0.7))
                            }
                            .foregroundStyle(textColor.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(strokeColor.opacity(0.6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    }
                }
            )
            .frame(maxWidth: .infinity, minHeight: 140)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 1.0)
                    .onEnded { _ in
                        // 롱프레스로 Live Activity 종료
                        if activityManager.isActivityRunning {
                            HapticManager.medium()
                            Task {
                                await activityManager.endActivity()
                                memo = ""
                            }
                        }
                    }
            )
    }

}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [LinkItem.self, Category.self], inMemory: true)
}
