//
// ZoomablePhotoViewer.swift
// LiveNote
//
// UIScrollView 기반 확대/축소 가능한 이미지 뷰어
//
// ✅ 핵심 기능:
// 1. 핀치 줌이 손가락 중심으로 자연스럽게 동작
// 2. 이미지 변경 시 확대 상태 완전 초기화 (zoomScale 유지 버그 해결)
// 3. 확대 후 중앙 정렬
//
// ⚠️ 버그 원인:
// - SwiftUI에서 UIScrollView를 재사용할 때 zoomScale, contentOffset이 리셋되지 않음
// - onDisappear에만 의존하면 호출 타이밍 불안정
//
// ✅ 해결 방법:
// - imageID를 전달받아 Coordinator에 저장
// - updateUIView에서 imageID 변경 감지 시 명시적으로 리셋
// - setZoomScale(1.0, animated: false) + contentOffset = .zero
//

import SwiftUI
import UIKit

// MARK: - ZoomableScrollView (UIViewRepresentable)

/// UIScrollView를 사용한 확대/축소 가능한 이미지 뷰어
struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage
    let imageID: String  // 이미지 변경 감지용 ID

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear

        // ImageView 생성 및 추가
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        context.coordinator.imageView = imageView
        scrollView.addSubview(imageView)

        // 초기 레이아웃 설정
        context.coordinator.setupImageView(in: scrollView, with: image)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // ✅ 핵심: imageID가 바뀌었는지 확인
        let coordinator = context.coordinator

        if coordinator.currentImageID != imageID {
            print("🔄 이미지 변경 감지: \(coordinator.currentImageID ?? "nil") → \(imageID)")
            print("🖼️ 전달된 이미지 크기: \(image.size)")

            // 1. 이전 확대 상태 완전 초기화
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
            scrollView.contentOffset = .zero

            // 2. 새 이미지로 교체
            coordinator.imageView?.image = image
            coordinator.currentImageID = imageID

            // 3. 레이아웃 재설정
            coordinator.setupImageView(in: scrollView, with: image)

            // 4. 레이아웃 강제 적용
            scrollView.layoutIfNeeded()

            print("✅ 이미지 리셋 완료: zoomScale=\(scrollView.zoomScale), contentOffset=\(scrollView.contentOffset)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        var currentImageID: String?

        func setupImageView(in scrollView: UIScrollView, with image: UIImage) {
            guard let imageView = imageView else {
                print("⚠️ imageView가 nil입니다")
                return
            }

            let scrollViewSize = scrollView.bounds.size
            let imageSize = image.size

            print("📐 scrollViewSize: \(scrollViewSize), imageSize: \(imageSize)")

            // scrollView 크기가 아직 결정되지 않은 경우
            guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else {
                print("⚠️ scrollView 크기가 아직 결정되지 않음, 레이아웃 지연")
                // 다음 레이아웃 사이클에서 다시 시도
                DispatchQueue.main.async {
                    self.setupImageView(in: scrollView, with: image)
                }
                return
            }

            // 이미지가 스크롤뷰에 맞도록 크기 계산
            let widthScale = scrollViewSize.width / imageSize.width
            let heightScale = scrollViewSize.height / imageSize.height
            let scale = min(widthScale, heightScale)

            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale

            print("📏 scale: \(scale), scaledSize: \(scaledWidth) x \(scaledHeight)")

            // ImageView 프레임 설정
            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: scaledWidth,
                height: scaledHeight
            )

            // ScrollView contentSize 설정
            scrollView.contentSize = CGSize(
                width: scaledWidth,
                height: scaledHeight
            )

            // 중앙 정렬
            centerImageView(in: scrollView)
        }

        /// 이미지를 화면 중앙에 배치
        func centerImageView(in scrollView: UIScrollView) {
            guard let imageView = imageView else { return }

            let scrollViewSize = scrollView.bounds.size
            let imageViewSize = imageView.frame.size

            let horizontalInset = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
            let verticalInset = max(0, (scrollViewSize.height - imageViewSize.height) / 2)

            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }

        // MARK: - UIScrollViewDelegate

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // 확대/축소 후 중앙 정렬 유지
            centerImageView(in: scrollView)
        }
    }
}

// MARK: - 사용 예제: FullScreenPhotoViewer

/// 전체화면 사진 뷰어 (Photos 앱 스타일)
struct FullScreenPhotoViewer: View {
    let image: UIImage
    let imageID: String  // UUID.uuidString 등
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZoomableScrollView(image: image, imageID: imageID)
                .ignoresSafeArea()

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - 사용 예제: PhotoSelectionExample

/// 사진 선택 및 확대 예제
struct PhotoSelectionExample: View {
    @State private var selectedImage: UIImage?
    @State private var showFullScreen = false
    @State private var photoID = UUID().uuidString  // ✅ 이미지마다 고유 ID

    var body: some View {
        VStack(spacing: 20) {
            Text("사진 선택 테스트")
                .font(.title)

            // 테스트용 이미지 버튼들
            HStack(spacing: 20) {
                Button("사진 1") {
                    selectedImage = createTestImage(color: .red, text: "Photo 1")
                    photoID = UUID().uuidString  // ✅ 새 ID 생성
                    showFullScreen = true
                }
                .buttonStyle(.bordered)

                Button("사진 2") {
                    selectedImage = createTestImage(color: .blue, text: "Photo 2")
                    photoID = UUID().uuidString  // ✅ 새 ID 생성
                    showFullScreen = true
                }
                .buttonStyle(.bordered)

                Button("사진 3") {
                    selectedImage = createTestImage(color: .green, text: "Photo 3")
                    photoID = UUID().uuidString  // ✅ 새 ID 생성
                    showFullScreen = true
                }
                .buttonStyle(.bordered)
            }

            Text("각 사진을 확대 후 닫고, 다른 사진을 열어보세요.\n이전 확대 상태가 남지 않습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let image = selectedImage {
                FullScreenPhotoViewer(image: image, imageID: photoID)
            }
        }
    }

    // 테스트용 이미지 생성
    private func createTestImage(color: UIColor, text: String) -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let string = text as NSString
            let rect = CGRect(x: 0, y: size.height / 2 - 30, width: size.width, height: 60)
            string.draw(in: rect, withAttributes: attrs)
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoSelectionExample()
}
