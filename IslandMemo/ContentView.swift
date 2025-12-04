// ContentView.swift

import SwiftUI
import ActivityKit
import UIKit
import SwiftData

struct ContentView: View {
    @State private var memo: String = ""
    @StateObject private var activityManager = LiveActivityManager.shared
    @FocusState private var isFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LinkItem.createdAt, order: .reverse) private var savedLinks: [LinkItem]
    @Query(sort: \Category.createdAt, order: .reverse) private var storedCategories: [Category]
    @State private var glowOpacity: Double = 0.3
    @State private var isDeleteConfirmationActive: Bool = false
    @State private var deleteConfirmationTask: Task<Void, Never>?
    @State private var isColorPaletteVisible: Bool = false
    @State private var pastedLink: String? = nil // 붙여넣은 링크 임시 저장
    @State private var linkTitle: String = "" // 링크 제목 (선택)
    @State private var selectedCategory: String = ""
    @State private var isShowingNewCategoryAlert: Bool = false
    @State private var newCategoryName: String = ""
    @State private var isShowingLinksSheet: Bool = false
    @State private var isShowingLinkInputSheet: Bool = false
    @State private var isShowingShortcutGuide: Bool = false
    @State private var hasSeenShortcutGuide: Bool = UserDefaults.standard.bool(forKey: "hasSeenShortcutGuide")
    @State private var autoStartTask: Task<Void, Never>?

    private var categories: [String] {
        storedCategories.map { $0.name }
    }

    private let defaultMessage = AppStrings.inputPlaceholder

    var body: some View {
        ZStack {
            // 배경: 탭하면 키보드 내려감
            background
                .onAppear {
                    // 기본 카테고리 생성
                    initializeDefaultCategories()
                }
                .task {
                    // Activity 복원 시도
                    await activityManager.restoreActivityIfNeeded()

                    if let activity = activityManager.currentActivity {
                        // 복원 성공: 메모 내용 가져오기
                        let content = activity.contentState.memo
                        // 기본 메시지가 아닌 경우만 메모에 표시
                        if content != defaultMessage {
                            memo = content
                        }
                    } else {
                        // Activity가 없으면 기본 메시지로 바로 시작 (메모는 비워둠)
                        await activityManager.startActivity(with: defaultMessage)
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
                controlDock
            }
            .padding(20)
        }
        .overlay(alignment: .bottom) {
            // 색상 팔레트 (동적으로 표시, overlay로 레이아웃 영향 없음)
            if isColorPaletteVisible {
                colorPalette
                    .padding(.bottom, 100) // dock 위에 표시
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: memo) { oldValue, newValue in
            // 기존 자동 시작 태스크 취소
            autoStartTask?.cancel()

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
                            // 첫 시작이고 온보딩을 안 봤으면 온보딩 먼저
                            if !hasSeenShortcutGuide {
                                isShowingShortcutGuide = true
                            } else {
                                await activityManager.startActivity(with: newValue)
                            }
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
        .onChange(of: scenePhase) { _, newPhase in
            // 앱이 active가 되면 날짜 변경 체크
            if newPhase == .active {
                Task {
                    await activityManager.checkDateChangeAndUpdate()

                    // Activity가 없으면 재시작 (8시간 후 종료된 경우 대비)
                    if !activityManager.isActivityRunning {
                        if memo.isEmpty {
                            await activityManager.startActivity(with: defaultMessage)
                        } else {
                            await activityManager.startActivity(with: memo)
                        }
                    }
                }
            }

            // 앱이 백그라운드로 갈 때 메모가 비어있으면 기본 메시지로 업데이트
            if newPhase == .background || newPhase == .inactive {
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
                let content = activity.contentState.memo
                // 기본 메시지가 아닌 경우만 메모에 표시
                if content != defaultMessage {
                    memo = content
                }
            }
        }
        .alert("새 카테고리", isPresented: $isShowingNewCategoryAlert) {
            TextField("예: 🎬 영화", text: $newCategoryName)
            Button("취소", role: .cancel) {
                newCategoryName = ""
            }
            Button("추가") {
                if !newCategoryName.isEmpty && !categories.contains(newCategoryName) {
                    addNewCategory(newCategoryName)
                    selectedCategory = newCategoryName
                }
                newCategoryName = ""
            }
        } message: {
            Text("카테고리 이름을 입력하세요 (이모지 포함 가능)")
        }
        .sheet(isPresented: $isShowingLinksSheet) {
            LinksListView(categories: categories)
        }
        .sheet(isPresented: $isShowingShortcutGuide) {
            ShortcutGuideView {
                // 온보딩을 봤다고 표시
                hasSeenShortcutGuide = true
                UserDefaults.standard.set(true, forKey: "hasSeenShortcutGuide")

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
    }
}

// MARK: - Sections

private extension ContentView {

    // MARK: Background

    var background: some View {
        let colors: [Color]
        if colorScheme == .dark {
            colors = [Color.black, Color(white: 0.08)]
        } else {
            colors = [Color(white: 0.98), Color(white: 0.92)]
        }

        return LinearGradient(
            colors: colors,
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

            // 단축어 가이드 버튼
            Button {
                HapticManager.light()
                isShowingShortcutGuide = true
            } label: {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(headerForeground.opacity(0.3), lineWidth: 1)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(headerForeground)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    var headerBackground: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.06)
        } else {
            return Color.black.opacity(0.04)
        }
    }

    var headerForeground: Color {
        colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7)
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

        // 밝은 배경색인지 확인 (핑크, 오렌지는 밝은 색상)
        let isLightBackground = [ActivityBackgroundColor.pink, .orange].contains(activityManager.selectedBackgroundColor)

        let strokeColor: Color = Color.white.opacity(0.12)
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
                color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.12),
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
                                                            color: Color.black.opacity(0.3),
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)

                    // 구분선
                    Rectangle()
                        .fill(strokeColor)
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // 하단: 링크 영역
                    HStack(spacing: 8) {
                        // 링크 저장하기 버튼
                        Button {
                            HapticManager.medium()
                            handleLinkSaveAction()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 14, weight: .semibold))

                                Text("링크 붙여넣기")
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
                                Text(savedLinks.isEmpty ? "링크 없음" : "\(savedLinks.count)개")
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
                    .padding(.vertical, 16)
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

    // MARK: Color Palette

    var colorPalette: some View {
        let selectedColor = activityManager.selectedBackgroundColor

        let paletteBackground: Color = {
            if colorScheme == .dark {
                return Color.white.opacity(0.08)
            } else {
                return Color.black.opacity(0.05)
            }
        }()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActivityBackgroundColor.allCases, id: \.self) { bgColor in
                    Button {
                        HapticManager.light()
                        activityManager.selectedBackgroundColor = bgColor

                        // 색상 선택 후 팔레트 닫기
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isColorPaletteVisible = false
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(bgColor.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor == bgColor
                                            ? (colorScheme == .dark ? Color.white : Color.black)
                                            : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .shadow(
                                    color: bgColor.color.opacity(0.4),
                                    radius: selectedColor == bgColor ? 6 : 3,
                                    y: 2
                                )

                            if selectedColor == bgColor {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(paletteBackground)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
                    radius: 20, x: 0, y: 10
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: Control Dock

    var controlDock: some View {
        let dockBackground: Color = {
            if colorScheme == .dark {
                return Color.white.opacity(0.06)
            } else {
                return Color.black.opacity(0.04)
            }
        }()

        let iconColorActive: Color = {
            colorScheme == .dark ? .white : .black
        }()

        return HStack(spacing: 0) {
            // Color palette toggle
            Button {
                HapticManager.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isColorPaletteVisible.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(activityManager.selectedBackgroundColor.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(iconColorActive.opacity(0.3), lineWidth: 2)
                        )

                    Image(systemName: isColorPaletteVisible ? "paintpalette.fill" : "paintpalette")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.plain)
            .animation(.none, value: activityManager.selectedBackgroundColor)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(dockBackground)
        )
    }

    private var formattedDate: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let isAsian = preferred.hasPrefix("ko") || preferred.hasPrefix("ja") || preferred.hasPrefix("zh")

        let dateLocale = isAsian ? Locale(identifier: preferred) : Locale(identifier: "en_US")

        return Date.now.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.wide)
                .locale(dateLocale)
        )
    }

    func startGlowAnimation() {
        guard activityManager.isActivityRunning else { return }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 1.0
        }
    }

    // MARK: Link Management

    func handleLinkSaveAction() {
        #if os(iOS)
        // 클립보드에서 URL 가져오기
        if let clipboardString = UIPasteboard.general.string, !clipboardString.isEmpty {
            // URL 검증
            if isValidURL(clipboardString) {
                pastedLink = clipboardString
                linkTitle = "" // 제목 초기화
                print("클립보드 링크 가져옴: \(clipboardString)")
                isShowingLinkInputSheet = true
                return
            }
        }
        #endif

        // 클립보드에 유효한 링크가 없으면 빈 상태로 입력 폼 표시
        pastedLink = ""
        linkTitle = ""
        isShowingLinkInputSheet = true
    }

    func isValidURL(_ string: String) -> Bool {
        if let url = URL(string: string),
           let scheme = url.scheme,
           (scheme == "http" || scheme == "https") {
            return true
        }
        return false
    }

    // MARK: Activity Timer Section

    @ViewBuilder
    func activityTimerSection(activity: Activity<MemoryNoteAttributes>, textColor: Color, secondaryTextColor: Color) -> some View {
        let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간
        // activityStartDate 사용 (항상 최신 값)
        let startDate = activityManager.activityStartDate ?? Date()
        let endDate = startDate.addingTimeInterval(activityDuration)
        let elapsed = Date().timeIntervalSince(startDate)
        let progress = min(max(elapsed / activityDuration, 0), 1.0)
        let remaining = endDate.timeIntervalSinceNow

        // 시간대별 메시지 (통합 함수 사용)
        let timeMessage = MemoryNoteAttributes.getTimeMessage(remaining: remaining)

        VStack(spacing: 6) {
            // 프로그레스 바
            ProgressView(value: progress)
                .tint(timeMessage.color.opacity(0.7))

            // 타이머
            HStack {
                Text(AppStrings.statusOnScreen)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(secondaryTextColor)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: timeMessage.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(timeMessage.color)

                    (Text(endDate, style: .timer) + Text(" 후에 사라짐"))
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(timeMessage.color)

                    Image(systemName: "lock.slash")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(secondaryTextColor.opacity(0.8))
                }
            }
        }
    }

    // MARK: SwiftData 저장

    private func saveLinkWithTitle(title: String?) {
        guard let link = pastedLink else { return }

        let linkItem = LinkItem(url: link, title: title, category: selectedCategory, needsMetadataFetch: false)
        modelContext.insert(linkItem)

        do {
            try modelContext.save()
            print("✅ 링크 저장 성공 (iCloud 자동 동기화)")

            // 백그라운드에서 메타데이터 가져오기
            Task {
                await fetchAndUpdateMetadata(for: linkItem)
            }
        } catch {
            print("❌ 저장 실패: \(error)")
        }

        // 초기화
        pastedLink = nil
        linkTitle = ""
    }

    private func fetchAndUpdateMetadata(for linkItem: LinkItem) async {
        do {
            let metadata = try await LinkMetadataService.shared.fetchMetadata(for: linkItem.url)

            // 메인 스레드에서 업데이트
            await MainActor.run {
                linkItem.metaTitle = metadata.title
                linkItem.metaImageData = metadata.imageData

                do {
                    try modelContext.save()
                    print("✅ 메타데이터 업데이트 성공: \(metadata.title ?? "제목 없음")")
                } catch {
                    print("❌ 메타데이터 저장 실패: \(error)")
                }
            }
        } catch {
            print("⚠️ 메타데이터 가져오기 실패: \(error)")
        }
    }

    // MARK: - Category Management

    private func initializeDefaultCategories() {
        // 중복 카테고리 제거
        removeDuplicateCategories()

        // 기본 카테고리가 없으면 생성
        let defaultCategories = ["💻 개발", "🎨 디자인", "📌 기타"]
        for name in defaultCategories {
            if !categories.contains(name) {
                let category = Category(name: name)
                modelContext.insert(category)
            }
        }

        do {
            try modelContext.save()
            print("✅ 기본 카테고리 초기화 완료")
        } catch {
            print("❌ 카테고리 초기화 실패: \(error)")
        }

        // 카테고리 없는 기존 링크를 '기타' 카테고리로 마이그레이션
        // migrateCategorylessLinks() // 마이그레이션 완료 후 비활성화
    }

    private func migrateCategorylessLinks() {
        var migratedCount = 0

        // 카테고리가 빈 문자열이거나 존재하지 않는 카테고리인 링크 찾기
        for link in savedLinks {
            if link.category.isEmpty || !categories.contains(link.category) {
                link.category = "📌 기타"
                migratedCount += 1
            }
        }

        if migratedCount > 0 {
            do {
                try modelContext.save()
                print("✅ 카테고리 없는 링크 \(migratedCount)개를 '기타' 카테고리로 마이그레이션 완료")
            } catch {
                print("❌ 링크 마이그레이션 실패: \(error)")
            }
        }
    }

    private func removeDuplicateCategories() {
        // 카테고리 이름별로 그룹화
        var seenNames: Set<String> = []
        var duplicates: [Category] = []

        for category in storedCategories {
            if seenNames.contains(category.name) {
                // 중복 발견
                duplicates.append(category)
                print("⚠️ 중복 카테고리 발견: \(category.name)")
            } else {
                seenNames.insert(category.name)
            }
        }

        // 중복된 카테고리 삭제
        for duplicate in duplicates {
            modelContext.delete(duplicate)
        }

        if !duplicates.isEmpty {
            do {
                try modelContext.save()
                print("✅ 중복 카테고리 \(duplicates.count)개 삭제 완료")
            } catch {
                print("❌ 중복 카테고리 삭제 실패: \(error)")
            }
        }
    }

    private func addNewCategory(_ name: String) {
        let category = Category(name: name)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(name)' 추가 성공 (iCloud 자동 동기화)")
        } catch {
            print("❌ 카테고리 추가 실패: \(error)")
        }
    }
}

// MARK: - Link Input Sheet

struct LinkInputSheet: View {
    @Binding var linkURL: String?
    @Binding var linkTitle: String
    @Binding var selectedCategory: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.createdAt, order: .reverse) private var storedCategories: [Category]
    @Query(sort: \LinkItem.createdAt, order: .reverse) private var allLinks: [LinkItem]
    @State private var isShowingNewCategoryAlert: Bool = false
    @State private var newCategoryName: String = ""
    @State private var deletingCategoryName: String? = nil
    @State private var deleteConfirmationTask: Task<Void, Never>?

    private var categories: [String] {
        storedCategories.map { $0.name }
    }

    private var canSave: Bool {
        guard let url = linkURL, !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        // 카테고리가 선택되지 않으면 저장 불가
        guard !selectedCategory.isEmpty else {
            return false
        }
        // URL 유효성 검사
        if let urlObj = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)),
           let scheme = urlObj.scheme,
           (scheme == "http" || scheme == "https") {
            return true
        }
        return false
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func addNewCategory(_ name: String) {
        let category = Category(name: name)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(name)' 추가 성공 (iCloud 자동 동기화)")
        } catch {
            print("❌ 카테고리 추가 실패: \(error)")
        }
    }

    private func deleteCategory(_ categoryName: String) {
        // 카테고리에 속한 모든 링크 삭제
        let linksToDelete = allLinks.filter { $0.category == categoryName }
        for link in linksToDelete {
            modelContext.delete(link)
        }

        // 카테고리 삭제
        if let category = storedCategories.first(where: { $0.name == categoryName }) {
            modelContext.delete(category)
        }

        // 삭제된 카테고리가 선택되어 있었다면 다른 카테고리로 변경
        if selectedCategory == categoryName {
            // 삭제되지 않은 첫 번째 카테고리로 변경, 없으면 빈 문자열
            selectedCategory = storedCategories.first(where: { $0.name != categoryName })?.name ?? ""
        }

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(categoryName)' 및 관련 링크 \(linksToDelete.count)개 삭제 성공")
        } catch {
            print("❌ 카테고리 삭제 실패: \(error)")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 링크 URL 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("링크")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        TextField("https://example.com", text: Binding(
                            get: { linkURL ?? "" },
                            set: { linkURL = $0 }
                        ))
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }

                    // 메모 입력 (선택)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모 (선택)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        TextField("메모를 입력하세요", text: $linkTitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                    }

                    // 카테고리 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("카테고리")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // 새 카테고리 추가 버튼 (맨 앞으로 이동)
                                Button {
                                    HapticManager.light()
                                    isShowingNewCategoryAlert = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(Color(uiColor: .secondarySystemBackground))
                                        )
                                }
                                .buttonStyle(.plain)

                                ForEach(storedCategories, id: \.name) { category in
                                    let isDeleting = deletingCategoryName == category.name

                                    HStack(spacing: 0) {
                                        // 카테고리 선택 버튼
                                        Button {
                                            HapticManager.light()
                                            selectedCategory = category.name
                                        } label: {
                                            Text(category.name)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(selectedCategory == category.name ? .white : .primary)
                                                .padding(.leading, 14)
                                                .padding(.trailing, 8)
                                                .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)

                                        // 삭제 버튼
                                        Button {
                                            if isDeleting {
                                                // 두 번째 클릭: 실제 삭제
                                                HapticManager.medium()
                                                deleteCategory(category.name)
                                                deletingCategoryName = nil
                                                deleteConfirmationTask?.cancel()
                                            } else {
                                                // 첫 번째 클릭: 확인 상태로 전환
                                                HapticManager.light()
                                                deletingCategoryName = category.name

                                                // 3초 후 자동으로 확인 상태 해제
                                                deleteConfirmationTask?.cancel()
                                                deleteConfirmationTask = Task {
                                                    try? await Task.sleep(for: .seconds(3))
                                                    if !Task.isCancelled {
                                                        deletingCategoryName = nil
                                                    }
                                                }
                                            }
                                        } label: {
                                            Image(systemName: isDeleting ? "trash.fill" : "xmark")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(isDeleting ? .white : .secondary.opacity(0.7))
                                                .frame(width: 16, height: 16)
                                                .padding(.trailing, 10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .background(
                                        Capsule()
                                            .fill(isDeleting ? Color.red : (selectedCategory == category.name ? Color.accentColor : Color(uiColor: .secondarySystemBackground)))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isDeleting)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("링크 붙여넣기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .alert("새 카테고리", isPresented: $isShowingNewCategoryAlert) {
                TextField("예: 🎬 영화", text: $newCategoryName)
                Button("취소", role: .cancel) {
                    newCategoryName = ""
                }
                Button("추가") {
                    if !newCategoryName.isEmpty && !categories.contains(newCategoryName) {
                        addNewCategory(newCategoryName)
                        selectedCategory = newCategoryName
                    }
                    newCategoryName = ""
                }
            } message: {
                Text("카테고리 이름을 입력하세요 (이모지 포함 가능)")
            }
        }
        .task {
            // 카테고리가 하나도 없으면 '기타' 카테고리 생성
            if categories.isEmpty {
                print("⚠️ 카테고리 없음, '기타' 카테고리 생성")
                addNewCategory("📌 기타")
                // 약간의 딜레이 후 선택 (SwiftData 저장 대기)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }

            // reverse order이므로 first가 맨 왼쪽에 보이는 최신 카테고리
            if selectedCategory.isEmpty, !categories.isEmpty {
                selectedCategory = categories.first!
            } else if selectedCategory.isEmpty {
                selectedCategory = "📌 기타"
            }
        }
    }
}

// MARK: - Shortcut Guide View

struct ShortcutGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0
    var onDismiss: (() -> Void)? = nil

    private let pages = [
        GuidePage(
            icon: "app.badge",
            title: "잠금화면 표시 자동 연장",
            description: "Apple 정책상 잠금화면에 표시되는\n메모는 8시간 후 자동으로 사라집니다",
            step: "단축어 자동화를 설정하면\n8시간마다 자동으로 타이머가 리셋되어\n메모가 계속 유지됩니다\n\n조금 불편하지만 현재로선\n이 방법이 가장 좋습니다"
        ),
        GuidePage(
            icon: "1.circle.fill",
            title: "단축어 앱 열기",
            description: "iPhone의 '단축어' 앱을\n실행하세요",
            step: "단축어 앱은 모든 iPhone에\n기본으로 설치되어 있습니다"
        ),
        GuidePage(
            icon: "2.circle.fill",
            title: "자동화 탭으로 이동",
            description: "하단의 '자동화' 탭을 탭하고\n'새로운 자동화' 버튼 또는\n우측 상단 '+' 버튼을 탭하세요",
            step: "개인용 자동화 생성을 선택하세요"
        ),
        GuidePage(
            icon: "3.circle.fill",
            title: "특정 시간 선택",
            description: "'특정 시간'을 선택한 후\n8시간 간격으로 시간을 설정하세요",
            step: "예: 오전 8시, 오후 4시, 자정\n(하루 3번 실행)"
        ),
        GuidePage(
            icon: "4.circle.fill",
            title: "동작 추가",
            description: "'동작 추가'를 탭하고\n'앱' 또는 'Island Memo'를 검색하세요",
            step: "Island Memo 앱을 선택하고\n'잠금화면 표시 시간 연장'을\n선택하세요"
        ),
        GuidePage(
            icon: "5.circle.fill",
            title: "실행 설정",
            description: "'즉시 실행' 옵션을\n선택하세요",
            step: "이렇게 하면 자동으로\n백그라운드에서 실행됩니다"
        ),
        GuidePage(
            icon: "checkmark.circle.fill",
            title: "완료!",
            description: "이제 잠금화면 메모가\n자동으로 계속 유지됩니다",
            step: "설정한 시간마다 자동으로\n8시간 타이머가 리셋됩니다"
        )
    ]

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
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))

                    // 하단 버튼
                    VStack(spacing: 12) {
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

                            Button {
                                HapticManager.light()
                                onDismiss?()
                                dismiss()
                            } label: {
                                Text("건너뛰기")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
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
}

struct GuidePageView: View {
    let page: GuidePage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 아이콘
            Image(systemName: page.icon)
                .font(.system(size: 80, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 20)

            // 제목
            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)

            // 설명
            Text(page.description)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)

            // 추가 단계
            if let step = page.step {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 40)

                    Text(step)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.05)
                                      : Color.black.opacity(0.03))
                        )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [LinkItem.self, Category.self], inMemory: true)
}
