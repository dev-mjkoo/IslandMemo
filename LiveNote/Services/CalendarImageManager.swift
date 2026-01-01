//
// CalendarImageManager.swift
// LiveNote
//
// Live Activity의 달력 영역에 표시할 사진 관리
//

import Foundation
import UIKit
import SwiftUI

final class CalendarImageManager {
    static let shared = CalendarImageManager()

    private init() {}

    /// App Group container URL 가져오기
    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: PersistenceKeys.AppGroup.identifier)
    }

    /// 썸네일 이미지 파일 URL (Live Activity, Dock용)
    private var thumbnailFileURL: URL? {
        containerURL?.appendingPathComponent("calendar_image_thumbnail.jpg")
    }

    /// 원본 이미지 파일 URL (크게 보기용)
    private var originalFileURL: URL? {
        containerURL?.appendingPathComponent("calendar_image_original.jpg")
    }

    /// 레거시 호환성을 위한 이전 파일 URL
    private var legacyImageFileURL: URL? {
        containerURL?.appendingPathComponent(PersistenceKeys.AppGroup.calendarImageFileName)
    }

    // MARK: - 저장

    /// 이미지를 App Group container에 저장 (썸네일 + 원본)
    /// - Parameter image: 저장할 UIImage
    /// - Returns: 성공 여부
    @discardableResult
    func saveImage(_ image: UIImage) -> Bool {
        guard let thumbnailURL = thumbnailFileURL,
              let originalURL = originalFileURL else {
            print("❌ App Group container URL을 찾을 수 없습니다")
            return false
        }

        print("📸 원본 이미지 크기: \(image.size), orientation: \(image.imageOrientation.rawValue)")
        if let cgImage = image.cgImage, let colorSpace = cgImage.colorSpace, let name = colorSpace.name {
            print("📸 색상 공간: \(name as String)")
        }

        // 1. 썸네일 저장 (Live Activity, Dock용 - 120px)
        let thumbnail = resizeAndNormalizeImage(image, targetWidth: 120)
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.6) else {
            print("❌ 썸네일 JPEG 변환 실패")
            return false
        }
        print("📸 썸네일 크기: \(thumbnail.size), 데이터: \(thumbnailData.count) bytes")

        // 2. 원본 저장 (크게 보기용 - 최대 1000px, 고화질)
        let maxWidth: CGFloat = 1000
        let original = image.size.width > maxWidth
            ? resizeAndNormalizeImage(image, targetWidth: maxWidth)
            : resizeAndNormalizeImage(image, targetWidth: image.size.width) // orientation만 정규화
        guard let originalData = original.jpegData(compressionQuality: 0.85) else {
            print("❌ 원본 JPEG 변환 실패")
            return false
        }
        print("📸 원본 크기: \(original.size), 데이터: \(originalData.count) bytes")

        do {
            // 기존 파일 삭제
            if FileManager.default.fileExists(atPath: thumbnailURL.path) {
                try FileManager.default.removeItem(at: thumbnailURL)
            }
            if FileManager.default.fileExists(atPath: originalURL.path) {
                try FileManager.default.removeItem(at: originalURL)
            }

            // 레거시 파일도 삭제 (마이그레이션)
            if let legacyURL = legacyImageFileURL,
               FileManager.default.fileExists(atPath: legacyURL.path) {
                try FileManager.default.removeItem(at: legacyURL)
                print("🗑️  레거시 이미지 삭제")
            }

            // 새 이미지 저장
            try thumbnailData.write(to: thumbnailURL)
            try originalData.write(to: originalURL)
            print("✅ 이미지 저장 성공")
            print("   - 썸네일: \(thumbnailURL.lastPathComponent)")
            print("   - 원본: \(originalURL.lastPathComponent)")
            return true
        } catch {
            print("❌ 이미지 저장 실패: \(error)")
            return false
        }
    }

    // MARK: - 로드

    /// 썸네일 이미지 로드 (Live Activity, Dock용)
    /// - Returns: UIImage 또는 nil
    func loadImage() -> UIImage? {
        guard let thumbnailURL = thumbnailFileURL else {
            return nil
        }

        // 레거시 파일 마이그레이션
        if !FileManager.default.fileExists(atPath: thumbnailURL.path),
           let legacyURL = legacyImageFileURL,
           FileManager.default.fileExists(atPath: legacyURL.path) {
            if let legacyImage = UIImage(contentsOfFile: legacyURL.path) {
                saveImage(legacyImage) // 새로운 형식으로 저장
            }
        }

        guard FileManager.default.fileExists(atPath: thumbnailURL.path) else {
            return nil
        }

        guard let imageData = try? Data(contentsOf: thumbnailURL),
              let image = UIImage(data: imageData) else {
            print("❌ 썸네일 로드 실패")
            return nil
        }

        return image
    }

    /// 원본 이미지 로드 (크게 보기용)
    /// - Returns: UIImage 또는 nil
    func loadOriginalImage() -> UIImage? {
        guard let originalURL = originalFileURL else {
            return nil
        }

        guard FileManager.default.fileExists(atPath: originalURL.path) else {
            // 원본이 없으면 썸네일이라도 반환 (레거시 호환)
            return loadImage()
        }

        guard let imageData = try? Data(contentsOf: originalURL),
              let image = UIImage(data: imageData) else {
            print("❌ 원본 로드 실패")
            return loadImage() // 실패시 썸네일 반환
        }

        return image
    }

    // MARK: - 삭제

    /// 저장된 이미지 삭제 (썸네일 + 원본)
    func deleteImage() {
        // 썸네일 삭제
        if let thumbnailURL = thumbnailFileURL,
           FileManager.default.fileExists(atPath: thumbnailURL.path) {
            try? FileManager.default.removeItem(at: thumbnailURL)
            print("🗑️  썸네일 삭제 완료")
        }

        // 원본 삭제
        if let originalURL = originalFileURL,
           FileManager.default.fileExists(atPath: originalURL.path) {
            try? FileManager.default.removeItem(at: originalURL)
            print("🗑️  원본 삭제 완료")
        }

        // 레거시 파일도 삭제 (마이그레이션)
        if let legacyURL = legacyImageFileURL,
           FileManager.default.fileExists(atPath: legacyURL.path) {
            try? FileManager.default.removeItem(at: legacyURL)
            print("🗑️  레거시 이미지 삭제 완료")
        }
    }

    // MARK: - Helper

    /// 이미지 리사이징 및 orientation 정규화
    /// - HEIC 포맷을 포함한 모든 이미지 포맷 지원
    /// - Display P3 스크린샷도 sRGB로 변환하여 JPEG 호환성 보장
    private func resizeAndNormalizeImage(_ image: UIImage, targetWidth: CGFloat) -> UIImage {
        let scale = targetWidth / image.size.width
        let newHeight = image.size.height * scale
        let newSize = CGSize(width: targetWidth, height: newHeight)

        // sRGB 색상 공간으로 렌더링 (Display P3 스크린샷도 JPEG 호환)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // 1배율로 저장 (이미 targetWidth로 크기 조정됨)
        format.preferredRange = .standard // sRGB 색상 공간 강제

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let normalizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return normalizedImage
    }
}
