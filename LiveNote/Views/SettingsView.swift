import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @AppStorage(PersistenceKeys.UserDefaults.analyticsEnabled) private var analyticsEnabled: Bool = true
    @State private var showAnalyticsDisableAlert = false

    var body: some View {
        NavigationView {
            List {
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
