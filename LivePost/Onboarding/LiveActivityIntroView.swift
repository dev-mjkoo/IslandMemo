
import SwiftUI

struct LiveActivityIntroView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatePreview = false
    @State private var typedMemo = ""

    private var fullMemo: String {
        LocalizationManager.shared.string("오늘 할 일\n- 운동하기\n- 책 읽기")
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
                        memo: typedMemo,
                        startDate: Date().addingTimeInterval(-30 * 60), // 30분 전 시작
                        backgroundColor: .darkGray
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

                    Text(LocalizationManager.shared.string("잠금화면 미리보기"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.7))
                }

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            animatePreview = true
            startTypingAnimation()
        }
    }

    private func startTypingAnimation() {
        typedMemo = ""

        Task {
            // 0.8초 대기 (프리뷰 애니메이션 후)
            try? await Task.sleep(nanoseconds: 800_000_000)

            // 한 글자씩 추가
            for (index, character) in fullMemo.enumerated() {
                await MainActor.run {
                    typedMemo.append(character)
                }

                // 글자별 딜레이 (0.08초)
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
        }
    }
}
