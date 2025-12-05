//
//  LinkInputSheet.swift
//  IslandMemo
//

import SwiftUI
import SwiftData

struct LinkInputSheet: View {
    @Binding var linkURL: String?
    @Binding var linkTitle: String
    @Binding var selectedCategory: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.createdAt, order: .reverse) private var storedCategories: [Category]
    @Query(sort: \LinkItem.createdAt, order: .reverse) private var allLinks: [LinkItem]
    @State private var isShowingNewCategoryAlert: Bool = false
    @State private var newCategoryName: String = ""
    @State private var deletingCategoryName: String? = nil
    @State private var deleteConfirmationTask: Task<Void, Never>?

    private var categories: [String] {
        storedCategories.map { $0.name }
    }

    private var canSave: Bool {
        guard let url = linkURL, !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        // 카테고리가 선택되지 않으면 저장 불가
        guard !selectedCategory.isEmpty else {
            return false
        }
        // URL 유효성 검사
        if let urlObj = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)),
           let scheme = urlObj.scheme,
           (scheme == "http" || scheme == "https") {
            return true
        }
        return false
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func addNewCategory(_ name: String) {
        let category = Category(name: name)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(name)' 추가 성공 (iCloud 자동 동기화)")
        } catch {
            print("❌ 카테고리 추가 실패: \(error)")
        }
    }

    private func deleteCategory(_ categoryName: String) {
        // 카테고리에 속한 모든 링크 삭제
        let linksToDelete = allLinks.filter { $0.category == categoryName }
        for link in linksToDelete {
            modelContext.delete(link)
        }

        // 카테고리 삭제
        if let category = storedCategories.first(where: { $0.name == categoryName }) {
            modelContext.delete(category)
        }

        // 삭제된 카테고리가 선택되어 있었다면 다른 카테고리로 변경
        if selectedCategory == categoryName {
            // 삭제되지 않은 첫 번째 카테고리로 변경, 없으면 빈 문자열
            selectedCategory = storedCategories.first(where: { $0.name != categoryName })?.name ?? ""
        }

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(categoryName)' 및 관련 링크 \(linksToDelete.count)개 삭제 성공")
        } catch {
            print("❌ 카테고리 삭제 실패: \(error)")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 링크 URL 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("링크")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        TextField("https://example.com", text: Binding(
                            get: { linkURL ?? "" },
                            set: { linkURL = $0 }
                        ))
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }

                    // 메모 입력 (선택)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모 (선택)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        TextField("메모를 입력하세요", text: $linkTitle)
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
                        Text("카테고리")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // 새 카테고리 추가 버튼 (맨 앞으로 이동)
                                Button {
                                    HapticManager.light()
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

                                ForEach(storedCategories, id: \.name) { category in
                                    let isDeleting = deletingCategoryName == category.name

                                    HStack(spacing: 0) {
                                        // 카테고리 선택 버튼
                                        Button {
                                            HapticManager.light()
                                            selectedCategory = category.name
                                        } label: {
                                            Text(category.name)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(selectedCategory == category.name ? .white : .primary)
                                                .padding(.leading, 14)
                                                .padding(.trailing, 8)
                                                .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)

                                        // 삭제 버튼
                                        Button {
                                            if isDeleting {
                                                // 두 번째 클릭: 실제 삭제
                                                HapticManager.medium()
                                                deleteCategory(category.name)
                                                deletingCategoryName = nil
                                                deleteConfirmationTask?.cancel()
                                            } else {
                                                // 첫 번째 클릭: 확인 상태로 전환
                                                HapticManager.light()
                                                deletingCategoryName = category.name

                                                // 3초 후 자동으로 확인 상태 해제
                                                deleteConfirmationTask?.cancel()
                                                deleteConfirmationTask = Task {
                                                    try? await Task.sleep(for: .seconds(3))
                                                    if !Task.isCancelled {
                                                        deletingCategoryName = nil
                                                    }
                                                }
                                            }
                                        } label: {
                                            Image(systemName: isDeleting ? "trash.fill" : "xmark")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(isDeleting ? .white : .secondary.opacity(0.7))
                                                .frame(width: 16, height: 16)
                                                .padding(.trailing, 10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .background(
                                        Capsule()
                                            .fill(isDeleting ? Color.red : (selectedCategory == category.name ? Color.accentColor : Color(uiColor: .secondarySystemBackground)))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isDeleting)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("링크 붙여넣기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .alert("새 카테고리", isPresented: $isShowingNewCategoryAlert) {
                TextField("예: 🎬 영화", text: $newCategoryName)
                Button("취소", role: .cancel) {
                    newCategoryName = ""
                }
                Button("추가") {
                    if !newCategoryName.isEmpty && !categories.contains(newCategoryName) {
                        addNewCategory(newCategoryName)
                        selectedCategory = newCategoryName
                    }
                    newCategoryName = ""
                }
            } message: {
                Text("카테고리 이름을 입력하세요 (이모지 포함 가능)")
            }
        }
        .task {
            // 카테고리가 하나도 없으면 '기타' 카테고리 생성
            if categories.isEmpty {
                print("⚠️ 카테고리 없음, '기타' 카테고리 생성")
                addNewCategory("📌 기타")
                // 약간의 딜레이 후 선택 (SwiftData 저장 대기)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }

            // reverse order이므로 first가 맨 왼쪽에 보이는 최신 카테고리
            if selectedCategory.isEmpty, !categories.isEmpty {
                selectedCategory = categories.first!
            } else if selectedCategory.isEmpty {
                selectedCategory = "📌 기타"
            }
        }
    }
}
