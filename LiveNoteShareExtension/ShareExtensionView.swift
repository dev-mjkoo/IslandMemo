

import SwiftUI
import SwiftData

struct ShareExtensionView: View {
    let url: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.createdAt, order: .reverse) private var storedCategories: [Category]

    @State private var selectedCategory: String = ""
    @State private var linkTitle: String = ""
    @State private var isShowingNewCategoryAlert: Bool = false
    @State private var newCategoryName: String = ""
    @State private var isSaving: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    private var categories: [String] {
        storedCategories.map { $0.name }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 배경
                LinearGradient(
                    colors: AppColors.Background.gradient(for: colorScheme),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // URL 표시
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.string("링크"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text(url)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                            .lineLimit(3)
                    }

                    // 메모 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.string("메모 (선택)"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        TextField(LocalizationManager.shared.string("메모를 입력하세요"), text: $linkTitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                    }

                    // 카테고리 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.string("카테고리"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // 새 카테고리 추가 버튼 (맨 앞)
                                Button {
                                    isShowingNewCategoryAlert = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(Color(uiColor: .secondarySystemBackground))
                                        )
                                }
                                .buttonStyle(.plain)

                                ForEach(storedCategories) { category in
                                    Button {
                                        selectedCategory = category.name
                                    } label: {
                                        Text(category.name)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(selectedCategory == category.name ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedCategory == category.name ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(LocalizationManager.shared.string("링크 저장"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.string("취소")) {
                        onCancel()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(LocalizationManager.shared.string("저장")) {
                            Task {
                                await saveLink()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedCategory.isEmpty)
                    }
                }
            }
            .alert(LocalizationManager.shared.string("새 카테고리"), isPresented: $isShowingNewCategoryAlert) {
                TextField("예: 🎬 \(LocalizationManager.shared.string("영화"))", text: $newCategoryName)
                Button(LocalizationManager.shared.string("취소"), role: .cancel) {
                    newCategoryName = ""
                }
                Button(LocalizationManager.shared.string("추가")) {
                    let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        if addNewCategory(trimmedName) {
                            selectedCategory = trimmedName
                        }
                    }
                    newCategoryName = ""
                }
            } message: {
                Text(LocalizationManager.shared.string("카테고리 이름을 입력하세요 (이모지 포함 가능)"))
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.9))
                        )
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .task {
            print("📱 Share Extension: 카테고리 \(categories.count)개 로드됨: \(categories)")

            // 카테고리가 하나도 없으면 '기타' 카테고리 생성
            let defaultCategoryName = "📌 \(LocalizationManager.shared.string("기타"))"

            if storedCategories.isEmpty {
                print("⚠️ Share Extension: 카테고리 없음, '기타' 카테고리 생성")
                _ = addNewCategory(defaultCategoryName)
                // 약간의 딜레이 후 선택 (SwiftData 저장 대기)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }

            // reverse order이므로 first가 맨 왼쪽에 보이는 최신 카테고리
            if selectedCategory.isEmpty, !categories.isEmpty {
                selectedCategory = categories.first!
            } else if selectedCategory.isEmpty {
                selectedCategory = defaultCategoryName
            }
        }
    }

    private func saveLink() async {
        isSaving = true

        // selectedCategory(String)에 해당하는 Category 객체 찾기
        let categoryObject = storedCategories.first(where: { $0.name == selectedCategory })

        // 링크만 빠르게 저장, 메타데이터는 나중에 메인 앱에서 가져오기
        let linkItem = LinkItem(
            url: url,
            title: linkTitle.isEmpty ? nil : linkTitle,
            category: categoryObject,
            needsMetadataFetch: true  // 메인 앱에서 메타데이터 가져오도록 플래그 설정
        )

        modelContext.insert(linkItem)

        do {
            try modelContext.save()
            print("✅ Share Extension: 링크 저장 성공 (메타데이터는 메인 앱에서 가져옴)")

            isSaving = false
            onSave()
        } catch {
            print("❌ Share Extension: 저장 실패 - \(error)")
            isSaving = false
        }
    }

    private func addNewCategory(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { return false }

        // 중복 체크 (storedCategories를 직접 확인)
        if storedCategories.contains(where: { $0.name == trimmedName }) {
            print("⚠️ Share Extension: 카테고리 '\(trimmedName)' 이미 존재, 생성 스킵")
            toastMessage = LocalizationManager.shared.string("이미 있는 카테고리명입니다")
            withAnimation {
                showToast = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showToast = false
                }
            }
            return false
        }

        let category = Category(name: trimmedName)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ Share Extension: 카테고리 '\(trimmedName)' 추가 성공")
            return true
        } catch {
            print("❌ Share Extension: 카테고리 추가 실패 - \(error)")
            return false
        }
    }

}
