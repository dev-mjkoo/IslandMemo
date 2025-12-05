//
//  ControlDock.swift
//  IslandMemo
//

import SwiftUI

struct ControlDock: View {
    @ObservedObject var activityManager: LiveActivityManager
    @Binding var isColorPaletteVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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

        return HStack(spacing: 16) {
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

            // 연장 버튼
            Button {
                HapticManager.medium()
                Task {
                    await activityManager.extendTime()
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColorActive)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(dockBackground)
        )
    }
}
