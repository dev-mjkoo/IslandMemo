import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @AppStorage(PersistenceKeys.UserDefaults.analyticsEnabled) private var analyticsEnabled: Bool = true
    @AppStorage(PersistenceKeys.UserDefaults.photoBlurIntensity, store: UserDefaults(suiteName: PersistenceKeys.AppGroup.identifier)) private var photoBlurIntensity: Double = 1.5
    @State private var showAnalyticsDisableAlert = false
    @ObservedObject var activityManager = LiveActivityManager.shared
    @State private var blurUpdateTask: Task<Void, Never>?

    /// iOS 버전에 따라 사용 가능한 색상 필터링
    /// - iOS 26+: 모든 색상 (glass 포함)
    /// - iOS 26 미만: glass 제외
    private var availableColorsForCurrentOS: [ActivityBackgroundColor] {
        let allColors = ActivityBackgroundColor.availableColors
        if #available(iOS 26.0, *) {
            return allColors  // iOS 26+: glass 포함
        } else {
            return allColors.filter { $0 != .glass }  // iOS 26 미만: glass 제외
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Live Activity 설정 섹션
                Section {
                    // 배경 색상 선택
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationManager.shared.string("배경 색상"))
                            .foregroundStyle(.primary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableColorsForCurrentOS, id: \.self) { bgColor in
                                    Button {
                                        HapticManager.light()

                                        activityManager.selectedBackgroundColor = bgColor

                                        // Live Activity 업데이트
                                        if activityManager.isActivityRunning {
                                            Task {
                                                await activityManager.updateBackgroundColor()
                                            }
                                        }
                                    } label: {
                                        ZStack {
                                            // Glass 색상 특별 처리
                                            if bgColor == .glass {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color.white.opacity(0.3),
                                                                Color.blue.opacity(0.2),
                                                                Color.purple.opacity(0.2)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 44, height: 44)
                                                    .overlay(
                                                        Circle()
                                                            .strokeBorder(
                                                                activityManager.selectedBackgroundColor == bgColor
                                                                ? (colorScheme == .dark ? Color.white : Color.black)
                                                                : Color.white.opacity(0.3),
                                                                lineWidth: activityManager.selectedBackgroundColor == bgColor ? 2.5 : 1.5
                                                            )
                                                    )
                                            } else {
                                                Circle()
                                                    .fill(bgColor.color)
                                                    .frame(width: 44, height: 44)
                                                    .overlay(
                                                        Circle()
                                                            .strokeBorder(
                                                                activityManager.selectedBackgroundColor == bgColor
                                                                ? (colorScheme == .dark ? Color.white : Color.black)
                                                                : (bgColor == .white && colorScheme == .light
                                                                   ? Color.gray.opacity(0.3)
                                                                   : Color.clear),
                                                                lineWidth: activityManager.selectedBackgroundColor == bgColor ? 2.5 : 1.5
                                                            )
                                                    )
                                            }

                                            if activityManager.selectedBackgroundColor == bgColor {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(
                                                        bgColor == .white ? .black :
                                                        bgColor == .glass ? (colorScheme == .dark ? .white : .black) :
                                                        .white
                                                    )
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: 44)

                        // Glass 선택 시 힌트 텍스트
                        if activityManager.selectedBackgroundColor == .glass {
                            HStack(alignment: .top, spacing: 4) {
                                Text("⚠️")
                                    .font(.caption)

                                VStack(alignment: .leading, spacing: 4) {
                                    // 첫 번째 줄: "글래스 효과가 적용되지 않는다면,"
                                    // 두 번째 줄: "아이폰 설정에서 투명도 감소를 꺼주세요"
                                    (
                                        Text(LocalizationManager.shared.string("글래스 효과가 적용되지 않는다면,")) +
                                        Text("\n") +
                                        Text(LocalizationManager.shared.string("아이폰 설정에서")) +
                                        Text(" ") +
                                        Text(LocalizationManager.shared.string("투명도 감소"))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue) +
                                        Text(LocalizationManager.shared.string("를 꺼주세요"))
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    // 세 번째 줄: "'설정 → ...'"
                                    (
                                        Text("'") +
                                        Text(LocalizationManager.shared.string("설정 → 손쉬운 사용 → 디스플레이 및 텍스트 크기")) +
                                        Text("'")
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(0.8))
                                }
                            }
                        }
                    }

                    // 사진 블러 강도
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationManager.shared.string("사진 블러 강도"))
                            .foregroundStyle(.primary)

                        HStack {
                            Text(LocalizationManager.shared.string("없음"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Slider(value: $photoBlurIntensity, in: 0.0...3.0, step: 0.1)
                                .tint(.blue)

                            Text(LocalizationManager.shared.string("강함"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(LocalizationManager.shared.string("잠금화면 사진 표시 시 블러 효과 강도를 조절합니다"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(LocalizationManager.shared.string("메모"))
                }

                // 앱 정보 섹션
                Section {
                    HStack {
                        Text(LocalizationManager.shared.string("앱 이름"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("LiveNote")
                            .foregroundStyle(.primary)
                    }

                    HStack {
                        Text(LocalizationManager.shared.string("버전"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        openPrivacyPolicy()
                    } label: {
                        HStack {
                            Text(LocalizationManager.shared.string("개인정보처리방침"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(LocalizationManager.shared.string("정보"))
                }

                // 분석 데이터 수집 섹션
                Section {
                    Toggle(isOn: Binding(
                        get: { analyticsEnabled },
                        set: { newValue in
                            // 끄려고 할 때만 확인 알림 표시
                            if !newValue && analyticsEnabled {
                                showAnalyticsDisableAlert = true
                            } else {
                                analyticsEnabled = newValue
                                FirebaseAnalyticsManager.shared.setAnalyticsEnabled(newValue)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizationManager.shared.string("분석 데이터 수집"))
                                .foregroundStyle(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizationManager.shared.string("앱 개선을 위해 익명화된 사용 데이터를 수집합니다"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(LocalizationManager.shared.string("메모, 링크 등 사용자가 저장한 데이터는 절대 수집하지 않습니다"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.blue)
                } header: {
                    Text(LocalizationManager.shared.string("개인정보 보호"))
                }
            }
            .navigationTitle(LocalizationManager.shared.string("설정"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(LocalizationManager.shared.string("완료"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .alert(
                LocalizationManager.shared.string("분석 데이터 수집을 끄시겠습니까?"),
                isPresented: $showAnalyticsDisableAlert
            ) {
                Button(LocalizationManager.shared.string("끄기"), role: .destructive) {
                    analyticsEnabled = false
                    FirebaseAnalyticsManager.shared.setAnalyticsEnabled(false)
                }
                Button(LocalizationManager.shared.string("유지하기"), role: .cancel) {}
            } message: {
                Text(LocalizationManager.shared.string("메모, 링크 등 개인 데이터는 수집하지 않으며, 앱 오류 분석과 개선을 위해서만 사용됩니다."))
            }
            .onChange(of: photoBlurIntensity) { _, newValue in
                // ⚠️ 주의: 사진 블러 강도 변경 시 Live Activity 업데이트 필요
                // 1. App Group UserDefaults에 저장 (Live Activity가 읽음)
                // 2. 0.5초 debounce 후 Live Activity 재시작 (extendTime)

                // 이전 Task 취소 (슬라이더를 계속 움직이면 이전 업데이트는 취소)
                blurUpdateTask?.cancel()

                print("🎚️ 블러 강도 변경: \(newValue)")

                // UserDefaults 즉시 저장 (UI 반영용)
                // ⚠️ 반드시 App Group UserDefaults에 저장해야 Live Activity가 읽을 수 있음
                if let groupDefaults = UserDefaults(suiteName: PersistenceKeys.AppGroup.identifier) {
                    groupDefaults.set(newValue, forKey: PersistenceKeys.UserDefaults.photoBlurIntensity)
                    groupDefaults.synchronize()
                    print("💾 App Group에 저장됨: \(newValue)")
                }

                // 새 Task 생성 (0.5초 후 Live Activity 업데이트)
                blurUpdateTask = Task {
                    // 손을 뗀 후 0.5초 대기
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    // Task가 취소되지 않았으면 업데이트 실행
                    guard !Task.isCancelled else {
                        print("⏸️ Live Activity 업데이트 취소됨 (슬라이더 계속 조작 중)")
                        return
                    }

                    if activityManager.isActivityRunning {
                        print("🔄 Live Activity 재시작 중...")
                        await activityManager.extendTime()
                        print("✅ Live Activity 재시작 완료")
                    }
                }
            }
        }
    }

    private func openPrivacyPolicy() {
        let lang = LocalizationManager.shared.currentLanguageCode
        let urlString: String

        switch lang {
        case "ko":
            urlString = "https://buly.kr/2Uk5GiV"
        case "ja":
            urlString = "https://buly.kr/6iiGoIf"
        case "zh":
            urlString = "https://buly.kr/EI4qzNy"
        default: // "en"
            urlString = "https://buly.kr/8embbHE"
        }

        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
}
