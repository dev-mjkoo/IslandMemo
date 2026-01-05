import SwiftUI
import ActivityKit
import Photos
import WidgetKit

struct PhotoActionCard: View {
    @ObservedObject var activityManager: LiveActivityManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PersistenceKeys.UserDefaults.usePhotoInsteadOfCalendar) private var usePhoto: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showPhotoPickerSheet = false
    @State private var showCamera = false
    @State private var showPhotoPreview = false
    @State private var hasPhoto = false
    @State private var isDeleteConfirmationActive = false
    @State private var deleteConfirmationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Background
            if let photoImage = CalendarImageManager.shared.loadOriginalImage() {
                // Photo background - full coverage (original quality)
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipped()

                // Subtle dark overlay for text readability
                Color.black.opacity(0.15)
            } else {
                // No photo - default card background
                AppColors.Card.background(for: colorScheme)
            }

            // Content overlay
            VStack(spacing: 0) {
                // Header with gradient overlay for better text visibility
                ZStack(alignment: .top) {
                    // Gradient overlay when photo exists
                    if hasPhoto {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                    }

                    HStack {
                        Text(LocalizationManager.shared.string("사진"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(hasPhoto ? .white : Color.primary.opacity(0.7))
                            .shadow(color: hasPhoto ? .black.opacity(0.5) : .clear, radius: 3, y: 1)

                        Spacer()

                        // Header buttons when photo exists
                        if hasPhoto {
                            HStack(spacing: 8) {
                                // Change photo button
                                Button {
                                    HapticManager.light()
                                    showPhotoPickerSheet = true
                                } label: {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                                }
                                .buttonStyle(.plain)

                                // Delete button with confirmation
                                Button {
                                    if isDeleteConfirmationActive {
                                        // Second click: actually delete
                                        HapticManager.medium()
                                        deletePhoto()
                                        isDeleteConfirmationActive = false
                                        deleteConfirmationTask?.cancel()
                                    } else {
                                        // First click: activate confirmation
                                        HapticManager.light()
                                        isDeleteConfirmationActive = true

                                        // Auto-reset after 3 seconds
                                        deleteConfirmationTask?.cancel()
                                        deleteConfirmationTask = Task {
                                            try? await Task.sleep(for: .seconds(3))
                                            if !Task.isCancelled {
                                                isDeleteConfirmationActive = false
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: isDeleteConfirmationActive ? "trash.fill" : "trash")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(
                                            isDeleteConfirmationActive
                                            ? Color.red
                                            : Color.white
                                        )
                                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.2), value: isDeleteConfirmationActive)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                }

                // Button below header, left aligned (only show when no photo)
                if !hasPhoto {
                    Button {
                        HapticManager.light()
                        showPhotoPickerSheet = true
                    } label: {
                        HStack {
                            Text(LocalizationManager.shared.string("선택하기"))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                                .shadow(color: hasPhoto ? .black.opacity(0.3) : .clear, radius: 2, y: 1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                }

                Spacer()

                // Emoji at bottom right (only show when no photo)
                if !hasPhoto {
                    HStack {
                        Spacer()
                        Text("📷")
                            .font(.system(size: 32))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(height: 160)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.Card.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.Card.shadow(for: colorScheme), radius: 12, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            HapticManager.light()
            if hasPhoto {
                // Show photo preview directly when photo exists
                showPhotoPreview = true
            } else {
                // Show photo picker when no photo
                showPhotoPickerSheet = true
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoPreview) {
            PhotoPreviewView(image: selectedImage ?? CalendarImageManager.shared.loadOriginalImage())
        }
        .sheet(isPresented: $showPhotoPickerSheet) {
            PhotoPickerSheet(
                selectedImage: $selectedImage,
                showCamera: $showCamera
            )
            .presentationDetents([.height(280), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            updatePhotoMode()
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                print("📸 사진 저장 시작")
                CalendarImageManager.shared.saveImage(image)
                updatePhotoMode()

                // Reset delete confirmation state
                isDeleteConfirmationActive = false
                deleteConfirmationTask?.cancel()

                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 WidgetCenter reloaded")

                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초

                    if activityManager.isActivityRunning {
                        print("⏰ Live Activity 타이머 리셋 (완전 재시작)")
                        await activityManager.extendTime()
                    } else {
                        await updateCurrentActivity()
                    }
                }
            }
        }
        .onChange(of: hasPhoto) { _, newValue in
            if !newValue {
                // Reset delete confirmation when photo is removed
                isDeleteConfirmationActive = false
                deleteConfirmationTask?.cancel()
            }
        }
    }

    private func deletePhoto() {
        print("🗑️ 사진 삭제 시작")
        CalendarImageManager.shared.deleteImage()
        selectedImage = nil
        updatePhotoMode()

        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 WidgetCenter reloaded")

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초

            if activityManager.isActivityRunning {
                print("⏰ Live Activity 타이머 리셋 (달력 모드로 재시작)")
                await activityManager.extendTime()
            } else {
                await updateCurrentActivity()
            }
        }
    }

    private func updatePhotoMode() {
        let photoExists = CalendarImageManager.shared.loadOriginalImage() != nil
        hasPhoto = photoExists
        usePhoto = photoExists
    }

    private func updateCurrentActivity() async {
        guard let activity = activityManager.currentActivity else {
            return
        }

        await activityManager.updateActivity(with: activity.content.state.memo)
    }
}

// 사진 전체화면 미리보기
struct PhotoPreviewView: View {
    let image: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var resetZoom = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                ZoomableImageView(image: image, resetZoom: $resetZoom)
                    .onAppear {
                        resetZoom.toggle()
                    }
            } else {
                Text(LocalizationManager.shared.string("사진을 불러올 수 없습니다"))
                    .foregroundColor(.white)
            }

            // 상단 버튼들
            VStack {
                HStack {
                    // 저장 버튼
                    if let image = image {
                        Button {
                            saveToPhotos(image: image)
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                        }
                    }

                    Spacer()

                    // 닫기 버튼
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .alert(saveAlertMessage, isPresented: $showSaveAlert) {
            Button(LocalizationManager.shared.string("확인"), role: .cancel) {}
        }
    }

    private func saveToPhotos(image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    saveAlertMessage = LocalizationManager.shared.string("사진 라이브러리 접근 권한이 필요합니다")
                    showSaveAlert = true
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        HapticManager.success()
                        saveAlertMessage = LocalizationManager.shared.string("사진이 저장되었습니다")
                    } else {
                        HapticManager.error()
                        saveAlertMessage = LocalizationManager.shared.string("사진 저장에 실패했습니다")
                    }
                    showSaveAlert = true
                }
            }
        }
    }
}

// UIScrollView 기반 줌 가능한 이미지 뷰
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    @Binding var resetZoom: Bool

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100
        scrollView.addSubview(imageView)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if context.coordinator.lastResetValue != resetZoom {
            scrollView.setZoomScale(1.0, animated: false)
            context.coordinator.lastResetValue = resetZoom
            print("🔄 줌 리셋됨")
        }

        guard let imageView = scrollView.viewWithTag(100) as? UIImageView else { return }

        let imageSize = image.size
        let scrollViewSize = scrollView.bounds.size

        guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else { return }

        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let scale = min(widthScale, heightScale)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        imageView.frame = CGRect(
            x: (scrollViewSize.width - scaledWidth) / 2,
            y: (scrollViewSize.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight
        )

        scrollView.contentSize = imageView.frame.size
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var lastResetValue: Bool = false

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(100) else { return }

            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)

            imageView.center = CGPoint(
                x: scrollView.contentSize.width / 2 + offsetX,
                y: scrollView.contentSize.height / 2 + offsetY
            )
        }
    }
}

// 카카오톡 스타일 사진 선택 Sheet
struct PhotoPickerSheet: View {
    @Binding var selectedImage: UIImage?
    @Binding var showCamera: Bool
    @State private var recentPhotos: [PHAsset] = []
    @State private var showFullGrid = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(LocalizationManager.shared.string("최근 사진"))
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // 가로 스크롤 사진 리스트
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 카메라 버튼
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showCamera = true
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }

                    // 최근 사진들
                    ForEach(recentPhotos, id: \.localIdentifier) { asset in
                        RecentPhotoThumbnail(asset: asset) { image in
                            selectedImage = image
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 100)
            .padding(.bottom, 16)

            Divider()

            // 전체보기 버튼
            Button {
                showFullGrid = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    Text(LocalizationManager.shared.string("전체보기"))
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Spacer()
        }
        .onAppear {
            loadRecentPhotos()
        }
        .sheet(isPresented: $showFullGrid) {
            FullPhotoGridView(selectedImage: $selectedImage, onDismissAll: {
                dismiss()
            })
        }
    }

    private func loadRecentPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100

        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photos: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }
        recentPhotos = photos
    }
}

// 최근 사진 썸네일
struct RecentPhotoThumbnail: View {
    let asset: PHAsset
    let onSelect: (UIImage) -> Void
    @State private var image: UIImage?

    var body: some View {
        Button {
            loadFullImage()
        } label: {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact

        let size: CGFloat = 100 * UIScreen.main.scale
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: size, height: size),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                self.image = result
            }
        }
    }

    private func loadFullImage() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 2000, height: 2000),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                onSelect(result)
            }
        }
    }
}

// 전체 사진 그리드 뷰
struct FullPhotoGridView: View {
    @Binding var selectedImage: UIImage?
    @State private var allPhotos: [PHAsset] = []
    @Environment(\.dismiss) var dismiss
    let onDismissAll: () -> Void

    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(allPhotos, id: \.localIdentifier) { asset in
                        PhotoGridItem(asset: asset) { image in
                            selectedImage = image
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismissAll()
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.string("사진 선택"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.string("취소")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAllPhotos()
        }
    }

    private func loadAllPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photos: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }
        allPhotos = photos
    }
}

// 그리드 아이템
struct PhotoGridItem: View {
    let asset: PHAsset
    let onSelect: (UIImage) -> Void
    @State private var image: UIImage?

    var body: some View {
        Button {
            loadFullImage()
        } label: {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: (UIScreen.main.bounds.width - 4) / 3, height: (UIScreen.main.bounds.width - 4) / 3)
            .clipped()
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact

        let size = (UIScreen.main.bounds.width - 4) / 3
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                self.image = result
            }
        }
    }

    private func loadFullImage() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 2000, height: 2000),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                onSelect(result)
            }
        }
    }
}

// UIImagePickerController를 SwiftUI에서 사용하기 위한 래퍼
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .camera

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
