// ContentView.swift

import SwiftUI

struct ContentView: View {
    @State private var memo: String = ""
    @StateObject private var activityManager = LiveActivityManager.shared
    @FocusState private var isFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 배경: 탭하면 키보드 내려감
            background
                .contentShape(Rectangle())   // 빈 공간도 터치 가능하게
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isFieldFocused = false
                    }
                }

            VStack(spacing: 28) {
                header
                previewCard
                inputField
                Spacer(minLength: 0)
                controlDock
            }
            .padding(20)
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
                                    ? headerDotOn.opacity(0.7)
                                    : .clear,
                                radius: activityManager.isActivityRunning ? 4 : 0
                            )

                        Text(activityManager.isActivityRunning ? "LIVE ACTIVITY" : "IDLE")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundStyle(headerForeground)
                    }
                    .padding(.horizontal, 10)
                )

            Spacer()

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(headerForeground.opacity(0.3), lineWidth: 1)
                .frame(width: 32, height: 32)
                .overlay(
                    Text("기")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(headerForeground)
                )
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
        colorScheme == .dark ? .white : .black
    }

    var headerDotOff: Color {
        .secondary.opacity(0.5)
    }

    // MARK: Preview Card (Live Activity 스타일)

    var previewCard: some View {
        let baseBackground: Color = {
            if colorScheme == .dark {
                return Color.black.opacity(0.85)
            } else {
                return Color.white
            }
        }()

        let strokeColor: Color = {
            if colorScheme == .dark {
                return Color.white.opacity(0.08)
            } else {
                return Color.black.opacity(0.06)
            }
        }()

        return RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(baseBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.12),
                radius: 18, x: 0, y: 12
            )
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Capsule()
                            .fill(strokeColor.opacity(colorScheme == .dark ? 1.0 : 0.7))
                            .frame(width: 28, height: 4)

                        Text("기억해!")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .foregroundStyle(
                                colorScheme == .dark
                                ? Color.white.opacity(0.7)
                                : Color.black.opacity(0.6)
                            )

                        Spacer()
                    }

                    Text(displayMemo)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            colorScheme == .dark
                            ? Color.white
                            : Color.black
                        )
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 0)

                    HStack {
                        Text(activityManager.isActivityRunning ? "ON SCREEN" : "READY")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(
                                colorScheme == .dark
                                ? Color.white.opacity(0.6)
                                : Color.black.opacity(0.45)
                            )

                        Spacer()

                        Image(systemName: "lock.slash")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(
                                colorScheme == .dark
                                ? Color.white.opacity(0.5)
                                : Color.black.opacity(0.35)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            )
            .frame(maxWidth: .infinity, minHeight: 140)
    }

    var displayMemo: String {
        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "한 줄 메모가 잠금 화면과 Dynamic Island에 그대로 고정됩니다."
        }
        return trimmed
    }

    // MARK: Input Field

    var inputField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(
                "",
                text: $memo,
                prompt: Text("메모 입력")
                    .foregroundStyle(.secondary)
            )
            .focused($isFieldFocused)
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundStyle(Color.primary)
            .textInputAutocapitalization(.none)
            .disableAutocorrection(true)

            Rectangle()
                .fill(
                    (isFieldFocused ? Color.primary : Color.secondary)
                        .opacity(isFieldFocused ? 0.6 : 0.25)
                )
                .frame(height: 1)
        }
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

        let iconColorInactive: Color = .secondary.opacity(0.35)

        return HStack(spacing: 32) {

            // Start
            Button {
                Task { await activityManager.startActivity(with: memo) }
            } label: {
                Image(systemName: activityManager.isActivityRunning ? "play.fill" : "play")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        canStart ? iconColorActive : iconColorInactive
                    )
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(!canStart)

            // Update
            Button {
                Task { await activityManager.updateActivity(with: memo) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        activityManager.isActivityRunning ? iconColorActive : iconColorInactive
                    )
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(!activityManager.isActivityRunning)

            // End
            Button {
                Task { await activityManager.endActivity() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        activityManager.isActivityRunning ? iconColorActive : iconColorInactive
                    )
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(!activityManager.isActivityRunning)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(dockBackground)
        )
    }

    var canStart: Bool {
        !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
