

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

    private struct CategoryWithCount: Identifiable {
        let id: String
        let category: String
        let count: Int
    }

    private var categoriesWithLinks: [CategoryWithCount] {
        categories.map { category in
            let count = links.filter { $0.category == category }.count
            return CategoryWithCount(id: category, category: category, count: count)
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
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary.opacity(0.5))

                        Text(LocalizationManager.shared.string("카테고리가 없습니다"))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // 카테고리 그리드 (2열)
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(categoriesWithLinks) { item in
                                categoryCard(category: item.category, count: item.count)
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
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
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
        }
    }

    @ViewBuilder
    func categoryCard(category: String, count: Int) -> some View {
        NavigationLink(destination: CategoryLinksView(category: category)) {
            cardContent(category: category, count: count)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                HapticManager.light()
                editingCategory = category
                editingCategoryNewName = category
            } label: {
                Label(LocalizationManager.shared.string("수정"), systemImage: "pencil")
            }

            Button(role: .destructive) {
                HapticManager.medium()
                deleteCategory(category)
            } label: {
                Label(LocalizationManager.shared.string("삭제"), systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func cardContent(category: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .lineLimit(1)
                .truncationMode(.tail)
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

    private func deleteCategory(_ categoryName: String) {
        // 카테고리에 속한 모든 링크 삭제
        let linksToDelete = links.filter { $0.category == categoryName }
        for link in linksToDelete {
            modelContext.delete(link)
        }

        // 카테고리 삭제
        if let category = storedCategories.first(where: { $0.name == categoryName }) {
            modelContext.delete(category)
        }

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(categoryName)' 및 관련 링크 \(linksToDelete.count)개 삭제 성공")
        } catch {
            print("❌ 카테고리 삭제 실패: \(error)")
        }
    }

    private func renameCategory(from oldName: String, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 빈 문자열 체크
        guard !trimmedName.isEmpty else { return }

        // 중복 체크
        if categories.contains(trimmedName) && trimmedName != oldName {
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

        // 카테고리명 변경
        if let category = storedCategories.first(where: { $0.name == oldName }) {
            category.name = trimmedName
        }

        // 해당 카테고리의 모든 링크 업데이트
        let linksToUpdate = links.filter { $0.category == oldName }
        for link in linksToUpdate {
            link.category = trimmedName
        }

        do {
            try modelContext.save()
            print("✅ 카테고리 '\(oldName)' → '\(trimmedName)' 변경 및 관련 링크 \(linksToUpdate.count)개 업데이트 성공")
        } catch {
            print("❌ 카테고리 변경 실패: \(error)")
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
        allLinks.filter { $0.category == category }
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
