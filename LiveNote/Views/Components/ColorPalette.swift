

import SwiftUI

struct ColorPalette: View {
    @ObservedObject var activityManager: LiveActivityManager
    @Binding var isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let selectedColor = activityManager.selectedBackgroundColor

        let paletteBackground: Color = AppColors.Palette.background(for: colorScheme)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActivityBackgroundColor.availableColors, id: \.self) { bgColor in
                    Button {
                        HapticManager.light()
                        activityManager.selectedBackgroundColor = bgColor

                        // 색상 선택 후 팔레트 닫기
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isVisible = false
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
                    color: AppColors.Palette.shadow(for: colorScheme),
                    radius: 20, x: 0, y: 10
                )
        )
        .padding(.horizontal, 20)
    }
}
