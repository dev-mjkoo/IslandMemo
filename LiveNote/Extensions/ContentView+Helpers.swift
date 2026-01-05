import SwiftUI
import ActivityKit
import SwiftData

extension ContentView {
    // MARK: - Computed Properties

    var formattedDate: String {
        return Date.now.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.wide)
                .locale(LocalizationManager.shared.dateLocale)
        )
    }

    // MARK: - Animation

    func startGlowAnimation() {
        guard activityManager.isActivityRunning else { return }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 1.0
        }
    }

    // MARK: - Link Management

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

        // 클립보드에 유효한 링크가 없으면 토스트 메시지 표시
        toastMessage = LocalizationManager.shared.string("링크를 먼저 복사하세요")
        withAnimation {
            showToast = true
        }

        // 2초 후 토스트 자동 숨김
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showToast = false
            }
        }
    }

    func isValidURL(_ string: String) -> Bool {
        if let url = URL(string: string),
           let scheme = url.scheme,
           (scheme == "http" || scheme == "https") {
            return true
        }
        return false
    }

    // MARK: - Activity Timer Section

    @ViewBuilder
    func activityTimerSection(activity: Activity<MemoryNoteAttributes>, textColor: Color, secondaryTextColor: Color) -> some View {
        let activityDuration: TimeInterval = 8 * 60 * 60 // 8시간
        let startDate = activityManager.activityStartDate ?? Date()
        let endDate = startDate.addingTimeInterval(activityDuration)

        HStack {
            Text(AppStrings.statusOnScreen)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(secondaryTextColor)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(secondaryTextColor.opacity(0.8))

                // TimelineView를 사용해서 1초마다 자동 업데이트
                TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                    let now = context.date
                    let isExpired = now > endDate

                    if isExpired {
                        // 시간 만료 시 "00:00:00" 표시
                        Text("00:00:00")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(textColor.opacity(0.5))
                    } else {
                        // 남은 시간 계산
                        let remaining = endDate.timeIntervalSince(now)
                        let hours = Int(remaining) / 3600
                        let minutes = Int(remaining) / 60 % 60
                        let seconds = Int(remaining) % 60

                        Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(textColor)
                    }
                }

                // 연장 버튼
                Button {
                    HapticManager.medium()
                    Task {
                        await activityManager.extendTime()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(secondaryTextColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - SwiftData 저장

    func saveLinkWithTitle(title: String?) {
        guard let link = pastedLink else { return }

        // selectedCategory(String)에 해당하는 Category 객체 찾기
        let categoryObject = storedCategories.first(where: { $0.name == selectedCategory })

        let linkItem = LinkItem(url: link, title: title, category: categoryObject, needsMetadataFetch: false)
        modelContext.insert(linkItem)

        do {
            try modelContext.save()
            print("✅ 링크 저장 성공 (iCloud 자동 동기화)")
            
            HapticManager.success()
            
            toastMessage = LocalizationManager.shared.string("링크를 저장했습니다")
            withAnimation {
                showToast = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showToast = false
                }
            }

            // Firebase Analytics: 링크 저장
            FirebaseAnalyticsManager.shared.logLinkSaved(category: selectedCategory)

            // 백그라운드에서 메타데이터 가져오기
            Task {
                await fetchAndUpdateMetadata(for: linkItem)
            }

            // 링크 최초 저장 시 온보딩 체크
            if !hasSeenLinkGuide {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowingLinkOnboarding = true
                }
            }
        } catch {
            print("❌ 저장 실패: \(error)")
        }

        // 초기화
        pastedLink = nil
        linkTitle = ""
    }

    func fetchAndUpdateMetadata(for linkItem: LinkItem) async {
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

    func initializeDefaultCategories() {
        // 중복 카테고리 제거
        removeDuplicateCategories()

        // 카테고리가 1개도 없을 때만 기본 카테고리 생성 (언어별)
        guard storedCategories.isEmpty else {
            print("✅ 기존 카테고리 있음 (\(storedCategories.count)개), 기본 카테고리 생성 스킵")
            return
        }

        let lang = LocalizationManager.shared.currentLanguageCode
        let defaultCategoryName: String

        switch lang {
        case "en":
            defaultCategoryName = "📌 Others"
        case "ja":
            defaultCategoryName = "📌 その他"
        case "zh":
            defaultCategoryName = "📌 其他"
        default:
            defaultCategoryName = "📌 기타"
        }

        // 중복 방지: 이미 같은 이름의 카테고리가 있는지 확인
        if storedCategories.contains(where: { $0.name == defaultCategoryName }) {
            print("✅ 기본 카테고리 '\(defaultCategoryName)' 이미 존재, 생성 스킵")
            return
        }

        let category = Category(name: defaultCategoryName)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ 기본 카테고리 초기화 완료 (카테고리 없음 → '\(defaultCategoryName)' 생성)")
        } catch {
            print("❌ 카테고리 초기화 실패: \(error)")
        }

        // 카테고리 없는 기존 링크를 '기타' 카테고리로 마이그레이션
        // migrateCategorylessLinks() // 마이그레이션 완료 후 비활성화
    }

    func migrateCategorylessLinks() {
        var migratedCount = 0

        // "기타" 카테고리 찾기
        let defaultCategory = storedCategories.first(where: { $0.name.contains("기타") || $0.name.contains("Others") || $0.name.contains("その他") || $0.name.contains("其他") })

        // 카테고리가 없는 링크 찾기
        for link in savedLinks {
            if link.category == nil {
                link.category = defaultCategory
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

    // MARK: - Share Extension Link Check

    func checkForShareExtensionLinks() {
        // needsMetadataFetch가 true인 링크 찾기 (Share Extension으로 저장된 링크)
        let shareExtensionLinks = savedLinks.filter { $0.needsMetadataFetch }

        guard !shareExtensionLinks.isEmpty else { return }

        // 링크 온보딩 최초 1회만 표시
        if !hasSeenLinkGuide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowingLinkOnboarding = true
            }
        }

        // 백그라운드에서 메타데이터 가져오기
        for link in shareExtensionLinks {
            Task {
                await fetchAndUpdateMetadata(for: link)

                // 메타데이터 가져온 후 플래그 업데이트
                await MainActor.run {
                    link.needsMetadataFetch = false
                    do {
                        try modelContext.save()
                    } catch {
                        print("❌ needsMetadataFetch 플래그 업데이트 실패: \(error)")
                    }
                }
            }
        }
    }

    func removeDuplicateCategories() {
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

    func addNewCategory(_ name: String) {
        // 중복 체크 (storedCategories를 직접 확인)
        if storedCategories.contains(where: { $0.name == name }) {
            print("⚠️ 카테고리 '\(name)' 이미 존재, 생성 스킵")
            toastMessage = LocalizationManager.shared.string("이미 존재하는 카테고리입니다")
            withAnimation {
                showToast = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showToast = false
                }
            }
            return
        }

        let category = Category(name: name)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(name)' 추가 성공 (iCloud 자동 동기화)")

            // Firebase Analytics: 카테고리 생성
            FirebaseAnalyticsManager.shared.logCategoryCreated(name: name)
        } catch {
            print("❌ 카테고리 추가 실패: \(error)")
        }
    }
}
