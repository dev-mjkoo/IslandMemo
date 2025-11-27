// ContentView.swift

import SwiftUI

struct ContentView: View {
    @State private var memo: String = ""
    @StateObject private var activityManager = LiveActivityManager.shared
    @FocusState private var isFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var glowOpacity: Double = 0.3
    @State private var isDeleteConfirmationActive: Bool = false
    @State private var deleteConfirmationTask: Task<Void, Never>?

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
                Spacer(minLength: 0)
                controlDock
            }
            .padding(20)
            .onChange(of: memo) { _, newValue in
                if activityManager.isActivityRunning {
                    Task {
                        await activityManager.updateActivity(with: newValue)
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
                }
            }
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
            ZStack {
                // Glow effect for status capsule
                if activityManager.isActivityRunning {
                    Capsule()
                        .stroke(headerForeground, lineWidth: 2)
                        .frame(height: 32)
                        .blur(radius: 6)
                        .opacity(glowOpacity)
                }

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

                            Text(activityManager.isActivityRunning ? AppStrings.statusLive : AppStrings.statusIdle)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .tracking(2)
                                .textCase(.uppercase)
                                .foregroundStyle(headerForeground)
                        }
                        .padding(.horizontal, 10)
                    )
            }
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
                return Color(white: 0.15)
            } else {
                return Color.white
            }
        }()

        let strokeColor: Color = {
            if colorScheme == .dark {
                return Color.white.opacity(0.12)
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

                        Text(formattedDate)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                colorScheme == .dark
                                ? Color.white.opacity(0.7)
                                : Color.black.opacity(0.6)
                            )

                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        if memo.isEmpty {
                            Text(AppStrings.inputPlaceholder)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.3)
                                    : Color.black.opacity(0.3)
                                )
                                .padding(.top, 8)
                        }

                        TextEditor(text: $memo)
                            .focused($isFieldFocused)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                colorScheme == .dark
                                ? Color.white
                                : Color.black
                            )
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .textInputAutocapitalization(.none)
                            .disableAutocorrection(true)

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

                                            // Live Activity 종료
                                            if activityManager.isActivityRunning {
                                                Task {
                                                    await activityManager.endActivity()
                                                }
                                            }
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
                                                ? (colorScheme == .dark ? Color.red.opacity(0.9) : Color.red.opacity(0.7))
                                                : (colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.3))
                                            )
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.2), value: isDeleteConfirmationActive)
                                }
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                    .frame(minHeight: 80)

                    Spacer(minLength: 0)

                    HStack {
                        Text(activityManager.isActivityRunning ? AppStrings.statusOnScreen : AppStrings.statusReady)
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
                HapticManager.medium()
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

            // End activity
            Button {
                HapticManager.medium()
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
}

// MARK: - Preview

#Preview {
    ContentView()
}
