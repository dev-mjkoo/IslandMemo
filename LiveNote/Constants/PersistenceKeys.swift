//
// PersistenceKeys.swift
// LiveNote
//
// 📌 모든 persistence 관련 키를 한 곳에서 관리
// ⚠️ 이 파일의 값들은 출시 후 변경 시 사용자 데이터 손실 위험!
//
// 목적:
// 1. 오타 방지 (컴파일 타임 체크)
// 2. 키 재사용 방지
// 3. 변경 영향도 파악 용이
// 4. 문서화 중앙 관리
//

import Foundation

/// 앱의 모든 persistence 키를 관리하는 중앙 집중식 상수
enum PersistenceKeys {

    // MARK: - UserDefaults Keys

    /// UserDefaults에 저장되는 모든 키
    /// ⚠️ 출시 후 변경 시 사용자 설정 초기화
    enum UserDefaults {
        /// 온보딩 관련
        static let hasSeenShortcutGuide = "hasSeenShortcutGuide"
        static let hasSeenInitialOnboarding = "hasSeenInitialOnboarding"
        static let hasSeenMemoGuide = "hasSeenMemoGuide"
        static let hasSeenLinkGuide = "hasSeenLinkGuide"

        /// 설정 관련
        static let analyticsEnabled = "analyticsEnabled"
        static let selectedBackgroundColor = "selectedBackgroundColor"

        /// Live Activity 달력 대신 사진 사용 여부
        /// - true: 사진 표시 (PhotoView)
        /// - false: 달력 표시 (CalendarGridView)
        /// ⚠️ CalendarImageManager와 연동됨
        static let usePhotoInsteadOfCalendar = "usePhotoInsteadOfCalendar"

        /// 사진 블러 강도 (0.0 ~ 3.0)
        /// - 0.0: 블러 없음 (선명)
        /// - 3.0: 최대 블러
        /// ⚠️ App Group UserDefaults에 저장 (Live Activity에서 읽음)
        static let photoBlurIntensity = "photoBlurIntensity"

        /// 메모 관련
        static let currentMemo = "currentMemo"

        /// 리뷰 관련
        static let memoWrittenCount = "memoWrittenCount"
        static let hasRequestedReview = "hasRequestedReview"
    }

    // MARK: - Keychain Keys

    /// Keychain 저장소 관련 키
    /// ⚠️ 출시 후 변경 시 모든 비밀번호 손실
    enum Keychain {
        /// 카테고리 잠금 비밀번호를 저장하는 서비스 식별자
        /// - 사용: KeychainManager.swift
        /// - 키 형식: Category.id.uuidString
        static let categoryLockService = "com.livenote.category.lock"
    }

    // MARK: - App Group

    /// App Group 관련 식별자
    /// ⚠️ 출시 후 변경 시 모든 SwiftData 데이터 손실
    enum AppGroup {
        /// Main App, Share Extension, Widget Extension 간 공유
        /// - 사용: SharedModelContainer.swift
        /// - entitlements 파일과 동일해야 함
        static let identifier = "group.com.livenote.shared"

        /// Live Activity에 표시할 이미지 파일명 (레거시)
        /// - App Group container에 저장됨
        /// ⚠️ 현재는 calendar_image_thumbnail.jpg, calendar_image_original.jpg 사용
        /// - 이 파일은 레거시 호환성을 위해 유지
        /// - CalendarImageManager에서 fallback으로 사용
        static let calendarImageFileName = "calendar_image.jpg"
    }

    // MARK: - CloudKit

    /// CloudKit 관련 식별자
    /// ⚠️ 출시 후 변경 시 모든 iCloud 동기화 데이터 손실
    enum CloudKit {
        /// CloudKit Container 식별자
        /// - 사용: SharedModelContainer.swift (자동 설정)
        /// - entitlements 파일에 정의됨
        static let containerIdentifier = "iCloud.mjkoo.livenote"
    }

    // MARK: - Firebase Analytics

    /// Firebase Analytics 이벤트명
    /// ⚠️ 변경 시 분석 데이터 연속성 손실 (기술적으로는 가능)
    enum FirebaseEvents {
        // 메모 관련
        static let memoWritten = "memo_written"
        static let memoDeleted = "memo_deleted"

        // Live Activity 관련
        static let liveActivityStarted = "live_activity_started"
        static let liveActivityEnded = "live_activity_ended"
        static let liveActivityExtended = "live_activity_extended"

        // 링크 관련
        static let linkSaved = "link_saved"
        static let linkOpened = "link_opened"

        // 카테고리 관련
        static let categoryCreated = "category_created"
        static let categoryLocked = "category_locked"
        static let categoryDeleted = "category_deleted"

        // Share Extension
        static let shareExtensionUsed = "share_extension_used"
    }

    /// Firebase Analytics 파라미터명
    enum FirebaseParameters {
        static let characterCount = "character_count"
        static let durationSeconds = "duration_seconds"
        static let category = "category"
        static let lockType = "lock_type"
        static let categoryName = "category_name"
    }

    /// Firebase Analytics User Properties
    enum FirebaseUserProperties {
        static let userLanguage = "user_language"
        static let totalCategories = "total_categories"
        static let totalLinks = "total_links"
    }
}

// MARK: - 사용 예제

/*

 // UserDefaults 사용 예제
 UserDefaults.standard.set(true, forKey: PersistenceKeys.UserDefaults.hasSeenMemoGuide)
 let hasSeen = UserDefaults.standard.bool(forKey: PersistenceKeys.UserDefaults.hasSeenMemoGuide)

 // Keychain 사용 예제
 let service = PersistenceKeys.Keychain.categoryLockService

 // App Group 사용 예제
 let groupIdentifier = PersistenceKeys.AppGroup.identifier

 // Firebase 사용 예제
 Analytics.logEvent(PersistenceKeys.FirebaseEvents.memoWritten, parameters: [
     PersistenceKeys.FirebaseParameters.characterCount: 42
 ])

 */
