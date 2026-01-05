

import SwiftUI
import SwiftData
import UIKit

struct LinksListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LinkItem.createdAt, order: .reverse) private var links: [LinkItem]
    @Query(sort: \Category.createdAt, order: .reverse) private var storedCategories: [Category]

    let categories: [String]

    @State private var editingCategory: String? = nil
    @State private var editingCategoryNewName: String = ""
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var authenticatedCategory: String? = nil
    @State private var isAuthenticating: Bool = false
    @State private var showLockTypeSelection: Bool = false
    @State private var lockingCategory: String? = nil
    @State private var showPasswordSheet: Bool = false
    @State private var showPasswordInputSheet: Bool = false
    @State private var passwordInputCategory: String? = nil
    @State private var passwordInputAction: PasswordInputAction = .navigate
    @State private var deletingCategory: String? = nil
    @State private var isShowingNewCategoryAlert: Bool = false
    @State private var newCategoryName: String = ""

    enum PasswordInputAction {
        case navigate
        case unlock
        case delete
    }

    private struct CategoryWithCount: Identifiable {
        let id: UUID
        let category: String
        let count: Int
        let isLocked: Bool
    }

    private var categoriesWithLinks: [CategoryWithCount] {
        storedCategories.map { categoryObj in
            let count = links.filter { $0.category?.id == categoryObj.id }.count
            return CategoryWithCount(
                id: categoryObj.id,
                category: categoryObj.name,
                count: count,
                isLocked: categoryObj.isLocked
            )
        }
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

                if categoriesWithLinks.isEmpty {
                    // 빈 상태
                    Button {
                        HapticManager.light()
                        isShowingNewCategoryAlert = true
                    } label: {
                        Text(LocalizationManager.shared.string("새로운 카테고리 추가하기"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    // 카테고리 그리드 (2열)
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(categoriesWithLinks) { item in
                                categoryCard(category: item.category, count: item.count, isLocked: item.isLocked)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.string("저장된 링크"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !categoriesWithLinks.isEmpty {
                        Button {
                            HapticManager.light()
                            isShowingNewCategoryAlert = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .alert(LocalizationManager.shared.string("카테고리 수정"), isPresented: Binding(
                get: { editingCategory != nil },
                set: { if !$0 { editingCategory = nil } }
            )) {
                TextField(LocalizationManager.shared.string("카테고리"), text: $editingCategoryNewName)
                Button(LocalizationManager.shared.string("취소"), role: .cancel) {
                    editingCategory = nil
                    editingCategoryNewName = ""
                }
                Button(LocalizationManager.shared.string("저장")) {
                    if let oldName = editingCategory {
                        renameCategory(from: oldName, to: editingCategoryNewName)
                    }
                    editingCategory = nil
                    editingCategoryNewName = ""
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
            .alert(LocalizationManager.shared.string("잠금 방식 선택"), isPresented: $showLockTypeSelection) {
                Button(LocalizationManager.shared.string("Face ID/기기 암호")) {
                    if let category = lockingCategory {
                        authenticateAndLock(category: category)
                    }
                    lockingCategory = nil
                }
                Button(LocalizationManager.shared.string("별도 암호 설정")) {
                    showPasswordSheet = true
                }
                Button(LocalizationManager.shared.string("취소"), role: .cancel) {
                    lockingCategory = nil
                }
            } message: {
                Text(LocalizationManager.shared.string("카테고리를 어떻게 잠그시겠습니까?"))
            }
            .sheet(isPresented: $showPasswordSheet) {
                if let category = lockingCategory {
                    PasswordSetupSheet(
                        categoryName: category,
                        onSave: { password in
                            setLockWithPassword(for: category, password: password)
                            showPasswordSheet = false
                            lockingCategory = nil
                        },
                        onCancel: {
                            showPasswordSheet = false
                            lockingCategory = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showPasswordInputSheet) {
                if let category = passwordInputCategory {
                    PasswordInputSheet(
                        categoryName: category,
                        onSuccess: {
                            if passwordInputAction == .navigate {
                                // 인증 성공: 카테고리로 이동
                                authenticatedCategory = category
                            } else if passwordInputAction == .unlock {
                                // 인증 성공: 잠금 해제
                                toggleLock(for: category)
                            } else if passwordInputAction == .delete {
                                // 인증 성공: 바로 삭제
                                deleteCategory(category)
                            }
                            showPasswordInputSheet = false
                            passwordInputCategory = nil
                        },
                        onCancel: {
                            showPasswordInputSheet = false
                            passwordInputCategory = nil
                        }
                    )
                }
            }
            .alert(LocalizationManager.shared.string("카테고리 삭제"), isPresented: Binding(
                get: { deletingCategory != nil },
                set: { if !$0 { deletingCategory = nil } }
            )) {
                Button(LocalizationManager.shared.string("취소"), role: .cancel) {
                    deletingCategory = nil
                }
                Button(LocalizationManager.shared.string("삭제"), role: .destructive) {
                    if let categoryName = deletingCategory {
                        // 카테고리 객체 찾기
                        if let categoryObj = storedCategories.first(where: { $0.name == categoryName }) {
                            if categoryObj.isLocked {
                                // 잠금된 카테고리: 인증 후 삭제
                                if categoryObj.lockType == "password" {
                                    showPasswordInputSheet(for: categoryName, action: .delete)
                                } else {
                                    // Face ID 인증 후 삭제
                                    authenticateAndDeleteDirectly(category: categoryName)
                                }
                            } else {
                                // 잠금 안 된 카테고리: 바로 삭제
                                deleteCategory(categoryName)
                            }
                        }
                    }
                    deletingCategory = nil
                }
            } message: {
                Text(LocalizationManager.shared.string("카테고리와 모든 링크가 삭제됩니다. 계속하시겠습니까?"))
            }
            .alert(LocalizationManager.shared.string("새 카테고리"), isPresented: $isShowingNewCategoryAlert) {
                TextField("예: 🎬 \(LocalizationManager.shared.string("영화"))", text: $newCategoryName)
                Button(LocalizationManager.shared.string("취소"), role: .cancel) {
                    newCategoryName = ""
                }
                Button(LocalizationManager.shared.string("추가")) {
                    addNewCategory(newCategoryName)
                    newCategoryName = ""
                }
            } message: {
                Text(LocalizationManager.shared.string("카테고리 이름을 입력하세요 (이모지 포함 가능)"))
            }
        }
    }

    @ViewBuilder
    func categoryCard(category: String, count: Int, isLocked: Bool) -> some View {
        let lockType = storedCategories.first(where: { $0.name == category })?.lockType ?? "biometric"

        Button {
            if isLocked {
                // 잠긴 카테고리: 타입에 따라 인증
                if lockType == "password" {
                    // 별도 암호 인증
                    showPasswordInputSheet(for: category, action: .navigate)
                } else {
                    // Face ID/기기 암호 인증
                    authenticateAndNavigate(to: category)
                }
            } else {
                // 잠기지 않은 카테고리: 바로 이동
                authenticatedCategory = category
            }
        } label: {
            cardContent(category: category, count: count, isLocked: isLocked)
        }
        .buttonStyle(.plain)
        .background(
            NavigationLink(
                destination: CategoryLinksView(category: category),
                isActive: Binding(
                    get: { authenticatedCategory == category },
                    set: { if !$0 { authenticatedCategory = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        .contextMenu {
            Button {
                HapticManager.light()
                editingCategory = category
                editingCategoryNewName = category
            } label: {
                Label(LocalizationManager.shared.string("수정"), systemImage: "pencil")
            }

            Button {
                HapticManager.light()
                if isLocked {
                    // 잠금 해제: 타입에 따라 인증
                    if lockType == "password" {
                        showPasswordInputSheet(for: category, action: .unlock)
                    } else {
                        authenticateAndUnlock(category: category)
                    }
                } else {
                    // 잠금 설정: 타입 선택
                    lockingCategory = category
                    showLockTypeSelection = true
                }
            } label: {
                Label(
                    isLocked ? LocalizationManager.shared.string("잠금 해제") : LocalizationManager.shared.string("잠금 설정"),
                    systemImage: isLocked ? "lock.open" : "lock"
                )
            }

            Button(role: .destructive) {
                HapticManager.medium()
                // 잠금 여부 상관없이 삭제 확인 alert 먼저 표시
                deletingCategory = category
            } label: {
                Label(LocalizationManager.shared.string("삭제"), systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func cardContent(category: String, count: Int, isLocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text(category)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("links")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))

                Text("•")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.Card.background(for: colorScheme))
                .shadow(
                    color: AppColors.Card.shadowLight(for: colorScheme),
                    radius: 8, x: 0, y: 2
                )
        )
    }

    private func authenticateAndNavigate(to category: String) {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        BiometricAuthManager.shared.authenticate { success in
            isAuthenticating = false

            if success {
                // 인증 성공: 카테고리 화면으로 이동
                authenticatedCategory = category
            } else {
                // 인증 실패: 토스트 메시지
                toastMessage = LocalizationManager.shared.string("인증에 실패했습니다")
                withAnimation {
                    showToast = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }

    private func authenticateAndUnlock(category: String) {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        BiometricAuthManager.shared.authenticate { success in
            isAuthenticating = false

            if success {
                // 인증 성공: 잠금 해제
                toggleLock(for: category)
            } else {
                // 인증 실패: 토스트 메시지
                toastMessage = LocalizationManager.shared.string("인증에 실패했습니다")
                withAnimation {
                    showToast = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }

    private func authenticateAndLock(category: String) {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        BiometricAuthManager.shared.authenticate { success in
            isAuthenticating = false

            if success {
                // 인증 성공: 잠금 설정
                setLock(for: category, type: "biometric")
            } else {
                // 인증 실패: 토스트 메시지
                toastMessage = LocalizationManager.shared.string("인증에 실패했습니다")
                withAnimation {
                    showToast = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }

    private func authenticateAndDelete(category: String) {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        BiometricAuthManager.shared.authenticate { success in
            isAuthenticating = false

            if success {
                // 인증 성공: 삭제 확인 alert 표시
                deletingCategory = category
            } else {
                // 인증 실패: 토스트 메시지
                toastMessage = LocalizationManager.shared.string("인증에 실패했습니다")
                withAnimation {
                    showToast = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }

    private func authenticateAndDeleteDirectly(category: String) {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        BiometricAuthManager.shared.authenticate { success in
            isAuthenticating = false

            if success {
                // 인증 성공: 바로 삭제
                deleteCategory(category)
            } else {
                // 인증 실패: 토스트 메시지
                toastMessage = LocalizationManager.shared.string("인증에 실패했습니다")
                withAnimation {
                    showToast = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }

    private func showPasswordInputSheet(for category: String, action: PasswordInputAction) {
        passwordInputCategory = category
        passwordInputAction = action
        showPasswordInputSheet = true
    }

    private func setLock(for categoryName: String, type: String) {
        if let category = storedCategories.first(where: { $0.name == categoryName }) {
            category.isLocked = true
            category.lockType = type

            do {
                try modelContext.save()
                print("✅ 카테고리 '\(categoryName)' 잠금 설정: \(type)")

                // Firebase Analytics: 카테고리 잠금
                FirebaseAnalyticsManager.shared.logCategoryLocked(lockType: type)
            } catch {
                print("❌ 카테고리 잠금 설정 실패: \(error)")
            }
        }
    }

    private func setLockWithPassword(for categoryName: String, password: String) {
        // 카테고리 객체 찾기
        guard let category = storedCategories.first(where: { $0.name == categoryName }) else { return }

        // Keychain에 암호 저장 (UUID 사용)
        let success = KeychainManager.shared.savePassword(password, for: category.id)

        if success {
            // 카테고리 잠금 설정
            setLock(for: categoryName, type: "password")
        } else {
            toastMessage = LocalizationManager.shared.string("암호 저장에 실패했습니다")
            withAnimation {
                showToast = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showToast = false
                }
            }
        }
    }

    private func toggleLock(for categoryName: String) {
        if let category = storedCategories.first(where: { $0.name == categoryName }) {
            let wasLocked = category.isLocked
            category.isLocked = false

            // 암호 타입이었으면 Keychain에서 삭제 (UUID 사용)
            if wasLocked && category.lockType == "password" {
                _ = KeychainManager.shared.deletePassword(for: category.id)
            }

            do {
                try modelContext.save()
                print("✅ 카테고리 '\(categoryName)' 잠금 해제")
            } catch {
                print("❌ 카테고리 잠금 해제 실패: \(error)")
            }
        }
    }

    private func deleteCategory(_ categoryName: String) {
        // 카테고리 객체 찾기
        guard let category = storedCategories.first(where: { $0.name == categoryName }) else { return }

        // 카테고리 삭제 (cascade delete 설정으로 인해 관련 링크도 자동 삭제됨)
        let linksCount = links.filter { $0.category?.id == category.id }.count
        modelContext.delete(category)

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(categoryName)' 및 관련 링크 \(linksCount)개 삭제 성공 (cascade)")

            // 삭제 완료 토스트 메시지
            toastMessage = LocalizationManager.shared.string("카테고리가 삭제되었습니다")
            withAnimation {
                showToast = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showToast = false
                }
            }
        } catch {
            print("❌ 카테고리 삭제 실패: \(error)")
        }
    }

    private func addNewCategory(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { return }

        // 중복 체크 (storedCategories를 직접 확인)
        if storedCategories.contains(where: { $0.name == trimmedName }) {
            print("⚠️ 카테고리 '\(trimmedName)' 이미 존재, 생성 스킵")
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
            return
        }

        let category = Category(name: trimmedName)
        modelContext.insert(category)

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(trimmedName)' 추가 성공 (iCloud 자동 동기화)")

            // Firebase Analytics: 카테고리 생성
            FirebaseAnalyticsManager.shared.logCategoryCreated(name: trimmedName)
        } catch {
            print("❌ 카테고리 추가 실패: \(error)")
        }
    }

    private func renameCategory(from oldName: String, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 빈 문자열 체크
        guard !trimmedName.isEmpty else { return }

        // 중복 체크 (storedCategories를 직접 확인)
        if trimmedName != oldName && storedCategories.contains(where: { $0.name == trimmedName }) {
            print("⚠️ 카테고리 '\(trimmedName)' 이미 존재, 변경 불가")
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
            return
        }

        // 같은 이름이면 아무것도 안 함
        if trimmedName == oldName {
            return
        }

        // 카테고리명 변경 (UUID 관계이므로 링크 업데이트 불필요)
        if let category = storedCategories.first(where: { $0.name == oldName }) {
            let linksCount = links.filter { $0.category?.id == category.id }.count
            category.name = trimmedName

            do {
                try modelContext.save()
                print("✅ 카테고리 '\(oldName)' → '\(trimmedName)' 변경 성공 (연결된 링크 \(linksCount)개 자동 유지)")
            } catch {
                print("❌ 카테고리 변경 실패: \(error)")
            }
        }
    }
}

// MARK: - Category Links View

struct CategoryLinksView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LinkItem.createdAt, order: .reverse) private var allLinks: [LinkItem]

    let category: String

    @State private var sharingURL: URL? = nil
    @State private var hasFetchedMetadata: Bool = false  // 메타데이터 가져왔는지 추적

    private var links: [LinkItem] {
        allLinks.filter { $0.category?.name == category }
    }

    private var pendingLinksCount: Int {
        links.filter { $0.needsMetadataFetch }.count
    }

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: AppColors.Background.gradient(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if links.isEmpty {
                // 빈 상태
                VStack(spacing: 12) {
                    Text(LocalizationManager.shared.string("저장된 링크가 없습니다"))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(LocalizationManager.shared.string("링크를 복사하고 앱으로 돌아오세요"))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(links) { link in
                        linkCard(link)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: $sharingURL) { url in
            ShareSheet(url: url)
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: pendingLinksCount) {
            // pendingLinksCount가 변경될 때만 실행 (새 링크 추가 시)
            guard pendingLinksCount > 0 && !hasFetchedMetadata else { return }
            await fetchPendingMetadata()
            hasFetchedMetadata = true
        }
        .onChange(of: pendingLinksCount) { oldValue, newValue in
            // 새로운 pending 링크가 추가되면 다시 fetch 가능하도록
            if newValue > 0 && newValue > oldValue {
                hasFetchedMetadata = false
            }
        }
    }

    @ViewBuilder
    func linkCard(_ link: LinkItem) -> some View {
        HStack(spacing: 12) {
                // 썸네일 이미지 또는 기본 아이콘
                ZStack {
                    if let imageData = link.metaImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "link")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary.opacity(0.7))
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }

                    // 메타데이터 로딩 중 표시
                    if link.needsMetadataFetch {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.Overlay.loading)
                            .frame(width: 60, height: 60)

                        ProgressView()
                            .tint(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // 우선순위: 메타 제목 > 도메인 (메인 타이틀)
                    if let metaTitle = link.metaTitle, !metaTitle.isEmpty {
                        Text(metaTitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(extractDomain(from: link.url))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .lineLimit(1)
                    }

                    // 사용자 입력 제목 (추가 설명)
                    if let title = link.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // URL과 날짜를 한 줄에 표시
                    HStack(spacing: 4) {
                        Text(link.url)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .layoutPriority(-1)

                        Text("·")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .fixedSize()

                        Text(formatRelativeDate(link.createdAt))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.7))
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.Card.background(for: colorScheme))
                .shadow(
                    color: AppColors.Card.shadowLight(for: colorScheme),
                    radius: 8, x: 0, y: 2
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            if let url = URL(string: link.url) {
                openURL(url)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // 삭제 (빨강)
            Button(role: .destructive) {
                HapticManager.medium()
                deleteLink(link)
            } label: {
                Label(LocalizationManager.shared.string("삭제"), systemImage: "trash.fill")
            }

            // 공유 (파랑)
            Button {
                HapticManager.light()
                if let url = URL(string: link.url) {
                    sharingURL = url
                }
            } label: {
                Label(LocalizationManager.shared.string("공유"), systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }

    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        // 1주일 이내: 상대적 시간 표시
        if let day = components.day, day < 7 {
            if day > 0 {
                return "\(day)\(LocalizationManager.shared.string("일 전"))"
            } else if let hour = components.hour, hour > 0 {
                return "\(hour)\(LocalizationManager.shared.string("시간 전"))"
            } else if let minute = components.minute, minute > 0 {
                return "\(minute)\(LocalizationManager.shared.string("분 전"))"
            } else {
                return LocalizationManager.shared.string("방금")
            }
        }

        // 1주일 이후: yyyy.MM.dd 형식
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    private func deleteLink(_ link: LinkItem) {
        modelContext.delete(link)
        do {
            try modelContext.save()
            print("✅ 링크 삭제 성공")
        } catch {
            print("❌ 삭제 실패: \(error)")
        }
    }

    private func fetchPendingMetadata() async {
        // 메타데이터가 필요한 링크들만 필터링
        let pendingLinks = links.filter { $0.needsMetadataFetch }

        guard !pendingLinks.isEmpty else { return }

        print("🔍 메타데이터 필요한 링크 \(pendingLinks.count)개 발견, 가져오는 중...")

        // 각 링크에 대해 메타데이터 가져오기 (동시에 최대 3개씩)
        await withTaskGroup(of: Void.self) { group in
            for link in pendingLinks.prefix(3) {  // 한 번에 최대 3개만
                group.addTask {
                    await fetchMetadataForLink(link)
                }
            }
        }
    }

    private func fetchMetadataForLink(_ link: LinkItem) async {
        do {
            let metadata = try await LinkMetadataService.shared.fetchMetadata(for: link.url)

            // 메인 스레드에서 업데이트
            await MainActor.run {
                link.metaTitle = metadata.title
                link.metaImageData = metadata.imageData
                link.needsMetadataFetch = false  // 플래그 해제

                do {
                    try modelContext.save()
                    print("✅ 메타데이터 업데이트 성공: \(metadata.title ?? link.url)")
                } catch {
                    print("❌ 메타데이터 저장 실패: \(error)")
                }
            }
        } catch {
            print("⚠️ 메타데이터 가져오기 실패 (\(link.url)): \(error)")
            // 실패해도 플래그는 해제 (무한 재시도 방지)
            await MainActor.run {
                link.needsMetadataFetch = false
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    LinksListView(categories: ["💻 개발", "🎨 디자인", "📌 기타"])
        .modelContainer(for: [LinkItem.self, Category.self], inMemory: true)
}
