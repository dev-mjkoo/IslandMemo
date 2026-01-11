
import SwiftUI

struct LiveActivityIntroView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatePreview = false
    @State private var previewMode: PreviewMode = .calendar

    enum PreviewMode: Int, CaseIterable {
        case calendar = 0
        case photo = 1
        case basic = 2

        var showCalendar: Bool {
            switch self {
            case .calendar: return true
            case .photo: return true
            case .basic: return false
            }
        }

        var usePhoto: Bool {
            switch self {
            case .calendar: return false
            case .photo: return true
            case .basic: return false
            }
        }

        var localizedName: String {
            switch self {
            case .calendar: return LocalizationManager.shared.string("달력 모드")
            case .photo: return LocalizationManager.shared.string("사진 모드")
            case .basic: return LocalizationManager.shared.string("기본 모드")
            }
        }
    }

    private var fullMemo: String {
        LocalizationManager.shared.string("엄마한테 전화하기")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // Title
                VStack(spacing: 12) {
                    Text(LocalizationManager.shared.string("이제 기억할게 있다면"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(LocalizationManager.shared.string("잠금화면에서 바로 작성해보세요!"))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Description
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.string("메모와 달력이 잠금화면에 표시되어"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(LocalizationManager.shared.string("언제든 빠르게 확인할 수 있어요"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Live Activity Preview
                VStack(spacing: 12) {
                    LiveActivityLockScreenPreview(
                        label: AppStrings.appMessage,
                        memo: fullMemo,
                        startDate: Date().addingTimeInterval(-30 * 60), // 30분 전 시작
                        backgroundColor: .darkGray,
                        usePhoto: previewMode.usePhoto,
                        showCalendar: previewMode.showCalendar
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.Onboarding.previewBackground)
                            .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
                    )
                    .padding(.horizontal, 24)
                    .scaleEffect(animatePreview ? 1.0 : 0.95)
                    .opacity(animatePreview ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animatePreview)

                    Text(previewMode.localizedName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                }

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            animatePreview = true
            startModeToggleAnimation()
        }
    }

    private func startModeToggleAnimation() {
        Task {
            // 바로 시작해서 2초마다 달력 → 사진 → 기본 순환
            while true {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        let currentIndex = previewMode.rawValue
                        let nextIndex = (currentIndex + 1) % PreviewMode.allCases.count
                        previewMode = PreviewMode(rawValue: nextIndex) ?? .calendar
                    }
                }

                // 2초 대기
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
}
