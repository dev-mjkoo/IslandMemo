

import SwiftUI
import ActivityKit
import Photos
import WidgetKit

struct ControlDock: View {
    @ObservedObject var activityManager: LiveActivityManager
    @Binding var isColorPaletteVisible: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PersistenceKeys.UserDefaults.usePhotoInsteadOfCalendar) private var usePhoto: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showPhotoPickerSheet = false
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showPhotoPreview = false
    @State private var hasPhoto = false

    var body: some View {
        let dockBackground: Color = AppColors.Dock.background(for: colorScheme)
        let iconColorActive: Color = colorScheme == .dark ? .white : .black

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

            // Photo button
            Button {
                HapticManager.light()
                showPhotoOptions = true
            } label: {
                photoButtonContent(iconColorActive: iconColorActive)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(dockBackground)
        )
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
        .confirmationDialog(
            "",
            isPresented: $showPhotoOptions,
            titleVisibility: .hidden
        ) {
            Button(LocalizationManager.shared.string("사진 선택")) {
                showPhotoPickerSheet = true
            }

            if hasPhoto {
                Button(LocalizationManager.shared.string("사진 보기")) {
                    showPhotoPreview = true
                }

                Button(LocalizationManager.shared.string("지우기"), role: .destructive) {
                    deletePhoto()
                }
            }

            Button(LocalizationManager.shared.string("취소"), role: .cancel) {}
        }
        .onAppear {
            // 앱 시작 시 사진 자동 감지
            updatePhotoMode()
        }
        .onChange(of: selectedImage) { _, newImage in
            // 사진 선택/촬영 시 저장
            if let image = newImage {
                print("📸 사진 저장 시작")
                CalendarImageManager.shared.saveImage(image)
                updatePhotoMode()

                // WidgetKit 캐시 강제 새로고침
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 WidgetCenter reloaded")

                Task {
                    // 짧은 딜레이 후 Live Activity 재시작 (파일 저장 완료 보장)
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
    }

    /// 사진 버튼 내용
    @ViewBuilder
    private func photoButtonContent(iconColorActive: Color) -> some View {
        ZStack {
            Circle()
                .fill(iconColorActive.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(iconColorActive.opacity(0.3), lineWidth: 2)
                )

            if let image = CalendarImageManager.shared.loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(iconColorActive.opacity(0.3), lineWidth: 2)
                    )
            } else {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColorActive)
            }
        }
    }

    /// 사진 삭제
    private func deletePhoto() {
        print("🗑️ 사진 삭제 시작")
        CalendarImageManager.shared.deleteImage()
        selectedImage = nil
        updatePhotoMode() // 자동 감지

        // WidgetKit 캐시 강제 새로고침
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 WidgetCenter reloaded")

        Task {
            // 짧은 딜레이 후 Live Activity 재시작 (파일 삭제 완료 보장)
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초

            if activityManager.isActivityRunning {
                print("⏰ Live Activity 타이머 리셋 (달력 모드로 재시작)")
                await activityManager.extendTime()
            } else {
                await updateCurrentActivity()
            }
        }
    }

    /// 사진 존재 여부에 따라 자동으로 모드 설정
    private func updatePhotoMode() {
        let photoExists = CalendarImageManager.shared.loadImage() != nil
        hasPhoto = photoExists
        usePhoto = photoExists
    }

    /// 현재 실행 중인 Activity 업데이트 (설정 변경 즉시 반영)
    private func updateCurrentActivity() async {
        guard let activity = activityManager.currentActivity else {
            return
        }

        // 현재 메모 내용으로 업데이트 (usePhoto 설정이 변경됨)
        await activityManager.updateActivity(with: activity.content.state.memo)
    }
}

// 사진 전체화면 미리보기
struct PhotoPreviewView: View {
    let image: UIImage?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                ZoomableImageView(image: image)
            } else {
                Text(LocalizationManager.shared.string("사진을 불러올 수 없습니다"))
                    .foregroundColor(.white)
            }

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
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
    }
}

// UIScrollView 기반 줌 가능한 이미지 뷰 (iOS 사진앱과 동일한 동작)
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100 // imageView를 찾기 위한 태그
        scrollView.addSubview(imageView)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(100) as? UIImageView else { return }

        // 이미지 크기 계산
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

        // 줌 초기화 (뷰가 다시 나타날 때)
        scrollView.zoomScale = 1.0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(image: image)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let image: UIImage

        init(image: UIImage) {
            self.image = image
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(100) else { return }

            // 줌 중에도 이미지가 중앙에 오도록 조정
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
                // 전체보기에서 사진 선택 시 모든 sheet 닫기
                dismiss()
            })
        }
    }

    private func loadRecentPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100 // 더 많은 사진 표시

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
        options.deliveryMode = .opportunistic // 빠르게 로딩 후 고화질로 자동 교체
        options.resizeMode = .exact

        let size: CGFloat = 100 * UIScreen.main.scale // 레티나 해상도
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
                            dismiss() // FullPhotoGridView 닫기
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismissAll() // PhotoPickerSheet도 닫기
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
        options.deliveryMode = .opportunistic // 빠르게 로딩 후 고화질로 자동 교체
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
