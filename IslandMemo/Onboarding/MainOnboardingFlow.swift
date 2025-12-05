//
//  MainOnboardingFlow.swift
//  IslandMemo
//

import SwiftUI

// MARK: - Initial Onboarding (앱 최초 실행: 1, 8, 9 페이지)

struct InitialOnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0
    var onDismiss: (() -> Void)? = nil

    private let totalPages = 2

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.black, Color(white: 0.08)]
                        : [Color(white: 0.98), Color(white: 0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // TabView - Main Content
                    TabView(selection: $currentPage) {
                        // Page 0: Live Activity Intro
                        LiveActivityIntroView()
                            .tag(0)

                        // Page 1: Link Guide Prompt
                        LinkGuidePromptView()
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom Controls
                    VStack(spacing: 16) {
                        // No skip button - user must complete onboarding
                        Text("")
                            .font(.system(size: 14))
                            .opacity(0)

                        // Page Indicators (dots)
                        HStack(spacing: 8) {
                            ForEach(0..<totalPages, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                            }
                        }
                        .padding(.vertical, 4)

                        // Next/Complete button
                        Button {
                            HapticManager.light()
                            if currentPage == totalPages - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        } label: {
                            Text(currentPage == totalPages - 1 ? "시작하기" : "다음")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func completeOnboarding() {
        onDismiss?()
        dismiss()
    }
}

// MARK: - Memo Onboarding (메모 최초 작성: 2-7 페이지)

struct MemoOnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0
    var onDismiss: (() -> Void)? = nil

    private let totalPages = 6

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.black, Color(white: 0.08)]
                        : [Color(white: 0.98), Color(white: 0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // TabView - Main Content
                    TabView(selection: $currentPage) {
                        // Pages 0-5: Shortcut Guide (6 pages)
                        ForEach(0..<6, id: \.self) { index in
                            ShortcutGuidePageWrapper(pageIndex: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom Controls
                    VStack(spacing: 16) {
                        // No skip button
                        Text("")
                            .font(.system(size: 14))
                            .opacity(0)

                        // Page Indicators (dots)
                        HStack(spacing: 8) {
                            ForEach(0..<totalPages, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                            }
                        }
                        .padding(.vertical, 4)

                        // Next/Complete button
                        Button {
                            HapticManager.light()
                            if currentPage == totalPages - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        } label: {
                            Text(currentPage == totalPages - 1 ? "완료" : "다음")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        completeOnboarding()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        onDismiss?()
        dismiss()
    }
}

// MARK: - Link Onboarding (링크 최초 저장: 9 페이지만)

struct LinkOnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.black, Color(white: 0.08)]
                        : [Color(white: 0.98), Color(white: 0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Single page content
                    LinkShareGuideContentView()

                    // Bottom Controls
                    VStack(spacing: 16) {
                        // Spacer
                        Text("")
                            .font(.system(size: 14))
                            .opacity(0)

                        // No page indicators (single page)

                        // Complete button
                        Button {
                            HapticManager.light()
                            completeOnboarding()
                        } label: {
                            Text("확인")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        completeOnboarding()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        onDismiss?()
        dismiss()
    }
}

// MARK: - Link Guide Prompt View

struct LinkGuidePromptView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)

                // Icon
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Title
                VStack(spacing: 12) {
                    Text("링크 저장 기능도 있어요!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("Safari나 다른 앱에서\n링크를 바로 저장할 수 있어요")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                // Feature highlights
                VStack(spacing: 16) {
                    PromptFeatureRow(
                        icon: "square.and.arrow.up",
                        title: "공유하기로 저장",
                        description: "어떤 앱에서든 링크 공유만 하면 돼요"
                    )

                    PromptFeatureRow(
                        icon: "folder.fill",
                        title: "카테고리 분류",
                        description: "링크를 카테고리별로 정리해요"
                    )

                    PromptFeatureRow(
                        icon: "photo.fill",
                        title: "미리보기 지원",
                        description: "링크 썸네일과 제목을 자동으로 가져와요"
                    )
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Prompt Feature Row Component

struct PromptFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
