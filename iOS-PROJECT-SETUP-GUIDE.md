# iOS 프로젝트 기초 공사 가이드

> LiveNote 프로젝트를 기준으로 작성된 iOS 앱 개발 시 기본 설정 가이드입니다.
> 새 프로젝트 시작 시 이 가이드를 Claude에게 제공하면 기본 구조를 빠르게 구축할 수 있습니다.

---

## 📁 디렉토리 구조

```
ProjectName/
├── Constants/              # 상수 관리
│   └── PersistenceKeys.swift
├── Shared/                 # 공유 코드
│   └── Constants.swift     # AppStrings 등
├── Services/               # 비즈니스 로직 & 매니저
│   ├── KeychainManager.swift
│   ├── BiometricAuthManager.swift
│   ├── LocalizationManager.swift
│   ├── FirebaseAnalyticsManager.swift
│   └── ReviewManager.swift
├── Models/                 # 데이터 모델 (SwiftData)
├── Views/                  # SwiftUI 뷰
│   ├── Components/         # 재사용 가능한 컴포넌트
│   └── Sheets/            # 모달/시트
├── Extensions/             # Swift 확장
├── Onboarding/            # 온보딩 관련
└── HapticManager.swift    # 햅틱 피드백 관리
```

---

## 🔧 필수 기초 파일들

### 1. PersistenceKeys.swift

**목적**: 모든 persistence 관련 키를 한 곳에서 중앙 집중식 관리

**특징**:
- 오타 방지 (컴파일 타임 체크)
- 키 재사용 방지
- 변경 영향도 파악 용이
- 문서화 중앙 관리

**구조**:
```swift
enum PersistenceKeys {
    // MARK: - UserDefaults Keys
    enum UserDefaults {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let analyticsEnabled = "analyticsEnabled"
        // ... 기타 UserDefaults 키
    }

    // MARK: - Keychain Keys
    enum Keychain {
        static let categoryLockService = "com.yourapp.category.lock"
        // ... 기타 Keychain 서비스 식별자
    }

    // MARK: - App Group
    enum AppGroup {
        static let identifier = "group.com.yourapp.shared"
    }

    // MARK: - CloudKit
    enum CloudKit {
        static let containerIdentifier = "iCloud.yourapp"
    }

    // MARK: - Firebase Analytics
    enum FirebaseEvents {
        static let userSignedIn = "user_signed_in"
        // ... 기타 이벤트명
    }

    enum FirebaseParameters {
        static let userId = "user_id"
        // ... 기타 파라미터명
    }
}
```

**중요 주의사항**:
⚠️ 출시 후 키 변경 시 사용자 데이터 손실 위험!
- Keychain 키 변경 → 모든 비밀번호 손실
- App Group 변경 → 모든 공유 데이터 손실
- UserDefaults 키 변경 → 사용자 설정 초기화

---

### 2. Constants.swift (AppStrings)

**목적**: 앱 전체에서 사용하는 문자열 상수 관리

**특징**:
- 다국어 지원과 연동
- 하드코딩 방지
- 문자열 재사용 용이

**구조**:
```swift
enum AppStrings {
    // MARK: - App Info
    static var appName: String {
        LocalizationManager.shared.string("앱 이름")
    }

    // MARK: - 공통 버튼
    static var cancel: String {
        LocalizationManager.shared.string("취소")
    }
    static var save: String {
        LocalizationManager.shared.string("저장")
    }

    // MARK: - 플레이스홀더
    static var inputPlaceholder: String {
        LocalizationManager.shared.string("입력하세요")
    }
}
```

---

### 3. KeychainManager.swift

**목적**: iOS Keychain 접근을 추상화하여 안전한 데이터 저장

**패턴**: Singleton

**주요 기능**:
- 비밀번호 저장/가져오기/삭제
- iCloud Keychain 동기화 지원
- 에러 핸들링

**핵심 구현**:
```swift
class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    func savePassword(_ password: String, for key: String) -> Bool {
        // Keychain에 저장
    }

    func getPassword(for key: String) -> String? {
        // Keychain에서 가져오기
    }

    func deletePassword(for key: String) -> Bool {
        // Keychain에서 삭제
    }

    func verifyPassword(_ input: String, for key: String) -> Bool {
        // 비밀번호 검증
    }
}
```

**중요 주의사항**:
⚠️ Service Identifier 절대 변경 금지!
- `kSecAttrService` 값 변경 시 기존 데이터 접근 불가
- iCloud 동기화: `kSecAttrSynchronizable = true` 사용
- 앱 삭제 후 재설치해도 데이터 유지됨 (iCloud 동기화 시)

**주석 예시**:
```swift
// ⚠️ 경고: 이 파일은 민감한 데이터를 Keychain에 저장합니다.
//         출시 후 변경 시 모든 사용자의 데이터 손실 위험!
//
// 🔴 절대 변경 금지 사항:
// 1. Service Identifier: "com.yourapp.service"
//    - 변경 시 기존에 저장된 모든 데이터 접근 불가
```

---

### 4. HapticManager.swift

**목적**: 햅틱 피드백 중앙 관리

**패턴**: Enum (Namespace로 사용)

**구조**:
```swift
import UIKit

enum HapticManager {
    // MARK: - Impact Feedback
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
```

**사용 예시**:
```swift
HapticManager.light()      // 버튼 탭
HapticManager.success()    // 저장 완료
HapticManager.error()      // 오류 발생
```

---

### 5. LocalizationManager.swift

**목적**: 앱 전체 다국어 지원 관리

**패턴**: Singleton

**특징**:
- 딕셔너리 기반 번역 시스템
- 실시간 언어 전환 지원
- 날짜/시간 포맷 다국어 대응

**핵심 구조**:
```swift
class LocalizationManager {
    static let shared = LocalizationManager()
    private init() {}

    var preferredLanguage: String {
        Locale.preferredLanguages.first ?? "en"
    }

    var currentLanguageCode: String {
        if preferredLanguage.hasPrefix("ko") { return "ko" }
        if preferredLanguage.hasPrefix("ja") { return "ja" }
        if preferredLanguage.hasPrefix("zh") { return "zh" }
        return "en"
    }

    func string(_ key: String) -> String {
        let lang = currentLanguageCode
        return translations[key]?[lang] ?? key
    }

    private let translations: [String: [String: String]] = [
        "저장": [
            "ko": "저장",
            "en": "Save",
            "ja": "保存",
            "zh": "保存"
        ],
        "취소": [
            "ko": "취소",
            "en": "Cancel",
            "ja": "キャンセル",
            "zh": "取消"
        ]
    ]
}
```

**사용 방법**:
```swift
// Constants.swift와 함께 사용
static var saveButton: String {
    LocalizationManager.shared.string("저장")
}

// 직접 사용
Text(LocalizationManager.shared.string("저장"))
```

---

### 6. BiometricAuthManager.swift

**목적**: Face ID / Touch ID / 기기 암호 인증 관리

**패턴**: Singleton

**핵심 구현**:
```swift
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private init() {}

    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = LocalizationManager.shared.string("인증이 필요합니다")

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
```

**사용 예시**:
```swift
BiometricAuthManager.shared.authenticate { success in
    if success {
        // 인증 성공
    } else {
        // 인증 실패
    }
}
```

---

### 7. FirebaseAnalyticsManager.swift

**목적**: Firebase Analytics 이벤트 로깅 중앙 관리

**패턴**: Singleton

**구조**:
```swift
import FirebaseAnalytics

class FirebaseAnalyticsManager {
    static let shared = FirebaseAnalyticsManager()
    private init() {}

    private var isEnabled: Bool {
        UserDefaults.standard.bool(
            forKey: PersistenceKeys.UserDefaults.analyticsEnabled
        )
    }

    func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }
        Analytics.logEvent(event, parameters: parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        guard isEnabled else { return }
        Analytics.setUserProperty(value, forName: name)
    }
}
```

**사용 예시**:
```swift
FirebaseAnalyticsManager.shared.logEvent(
    PersistenceKeys.FirebaseEvents.buttonClicked,
    parameters: [
        PersistenceKeys.FirebaseParameters.buttonName: "save"
    ]
)
```

---

### 8. ReviewManager.swift

**목적**: 앱 리뷰 요청 로직 관리

**패턴**: Singleton

**핵심 구현**:
```swift
import StoreKit

class ReviewManager {
    static let shared = ReviewManager()
    private init() {}

    private let reviewThreshold = 3  // 리뷰 요청 기준 (예: 3회 사용)

    func incrementUsageCount() {
        let currentCount = UserDefaults.standard.integer(
            forKey: PersistenceKeys.UserDefaults.usageCount
        )
        UserDefaults.standard.set(
            currentCount + 1,
            forKey: PersistenceKeys.UserDefaults.usageCount
        )
    }

    func requestReviewIfNeeded() {
        let count = UserDefaults.standard.integer(
            forKey: PersistenceKeys.UserDefaults.usageCount
        )
        let hasRequested = UserDefaults.standard.bool(
            forKey: PersistenceKeys.UserDefaults.hasRequestedReview
        )

        if count >= reviewThreshold && !hasRequested {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                UserDefaults.standard.set(
                    true,
                    forKey: PersistenceKeys.UserDefaults.hasRequestedReview
                )
            }
        }
    }
}
```

---

## 🎯 SwiftData 설정

### SharedModelContainer.swift

**목적**: SwiftData 컨테이너 앱 전체 공유 (Main App, Widget, Share Extension)

**핵심 구현**:
```swift
import SwiftData

actor SharedModelContainer {
    static let shared = SharedModelContainer()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            YourModel.self,
            // ... 기타 모델
        ])

        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(PersistenceKeys.AppGroup.identifier),
            cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

**사용 방법**:
```swift
@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(
                    await SharedModelContainer.shared.container
                )
        }
    }
}
```

---

## 📱 App Extensions 설정

### App Group 설정

1. **Xcode 설정**:
   - Target → Signing & Capabilities → + Capability → App Groups
   - App Group 추가: `group.com.yourapp.shared`
   - Main App, Share Extension, Widget Extension 모두 동일한 Group 추가

2. **PersistenceKeys에 등록**:
   ```swift
   enum AppGroup {
       static let identifier = "group.com.yourapp.shared"
   }
   ```

3. **entitlements 파일 확인**:
   ```xml
   <key>com.apple.security.application-groups</key>
   <array>
       <string>group.com.yourapp.shared</string>
   </array>
   ```

---

## 🔐 보안 관련 주의사항

### Keychain 사용 시

```swift
// ✅ 올바른 방법
let service = PersistenceKeys.Keychain.categoryLockService
KeychainManager.shared.savePassword("password", for: service)

// ❌ 잘못된 방법 (하드코딩)
let service = "com.myapp.lock"  // 오타 위험, 변경 추적 어려움
```

### 중요 주석 추가

모든 Keychain, App Group, CloudKit 관련 파일에는 다음과 같은 경고 주석 추가:

```swift
//
// ⚠️ 경고: 이 파일의 값들은 출시 후 변경 시 사용자 데이터 손실 위험!
//
// 🔴 절대 변경 금지 사항:
// 1. Service Identifier
// 2. Account Key 형식
// 3. iCloud 동기화 설정
//
// 📝 변경이 필요한 경우:
// 1. 마이그레이션 코드 작성
// 2. 기존 데이터를 새 키로 복사
// 3. 사용자에게 재인증 요청 (최후의 수단)
//
```

---

## 📋 새 프로젝트 체크리스트

### 1단계: 디렉토리 생성
- [ ] Constants/
- [ ] Shared/
- [ ] Services/
- [ ] Models/
- [ ] Views/Components/
- [ ] Views/Sheets/
- [ ] Extensions/
- [ ] Onboarding/

### 2단계: 필수 파일 생성
- [ ] PersistenceKeys.swift (모든 키 정의)
- [ ] Constants.swift (AppStrings)
- [ ] HapticManager.swift
- [ ] KeychainManager.swift (필요시)
- [ ] BiometricAuthManager.swift (필요시)
- [ ] LocalizationManager.swift (다국어 지원시)
- [ ] FirebaseAnalyticsManager.swift (분석 사용시)
- [ ] ReviewManager.swift
- [ ] SharedModelContainer.swift (SwiftData 사용시)

### 3단계: 설정
- [ ] App Group 추가 (Extension 사용시)
- [ ] CloudKit 설정 (iCloud 동기화시)
- [ ] Firebase 설정 (Analytics 사용시)
- [ ] Info.plist 권한 추가 (Face ID 등)

### 4단계: 경고 주석 작성
- [ ] Keychain 관련 파일에 경고 주석
- [ ] PersistenceKeys.swift에 경고 주석
- [ ] App Group 관련 파일에 경고 주석

---

## 💡 프로젝트 패턴

### Singleton vs Enum

**Singleton 사용** (상태 관리 필요):
- KeychainManager
- BiometricAuthManager
- LocalizationManager
- FirebaseAnalyticsManager
- ReviewManager

**Enum 사용** (Namespace만 필요):
- HapticManager
- PersistenceKeys
- AppStrings (계산 프로퍼티 사용 시)

### 파일 상단 주석 템플릿

```swift
//
// FileName.swift
// ProjectName
//
// [파일 설명]
//
// ⚠️ 경고: [변경 시 주의사항]
//
// 🔴 절대 변경 금지 사항:
// 1. [항목 1]
// 2. [항목 2]
//
// 📝 변경이 필요한 경우:
// [변경 방법 안내]
//
// 📚 관련 파일:
// - [연관 파일 1]
// - [연관 파일 2]
//

import Foundation
```

---

## 🚀 Claude에게 전달할 때

이 가이드를 새 프로젝트에서 사용할 때는 다음과 같이 요청:

```
이 프로젝트에 iOS-PROJECT-SETUP-GUIDE.md의 기초 공사를 진행해줘.
프로젝트 이름은 [YourProjectName]이고,
Bundle Identifier는 [com.yourcompany.yourapp]이야.

필요한 기능:
- [✓] Keychain 사용 (비밀번호 저장)
- [✓] 다국어 지원 (한국어, 영어, 일본어)
- [ ] Firebase Analytics
- [✓] SwiftData (iCloud 동기화)
- [✓] Share Extension
- [ ] Widget Extension

우선 디렉토리 구조부터 만들고,
필수 파일들을 순서대로 생성해줘.
```

---

## 📖 참고사항

### PersistenceKeys의 중요성

출시 후에는 다음 값들을 절대 변경하면 안 됩니다:

1. **Keychain Service Identifier**
   - 변경 시: 모든 사용자의 비밀번호 손실

2. **App Group Identifier**
   - 변경 시: 모든 공유 데이터 손실

3. **CloudKit Container Identifier**
   - 변경 시: 모든 iCloud 동기화 데이터 손실

4. **UserDefaults Keys**
   - 변경 시: 사용자 설정 초기화

### 마이그레이션이 필요한 경우

불가피하게 변경해야 한다면:

```swift
// 1. 새 키로 데이터 복사
if let oldData = getOldData(key: "old.key") {
    saveNewData(oldData, key: "new.key")
}

// 2. 마이그레이션 완료 플래그 저장
UserDefaults.standard.set(true, forKey: "migrated_to_v2")

// 3. 이전 데이터는 일정 기간 유지 (롤백 대비)
```

---

## 🎓 Best Practices

1. **모든 문자열은 LocalizationManager를 통해 관리**
   - 하드코딩 금지
   - 다국어 지원 용이

2. **모든 persistence 키는 PersistenceKeys에 정의**
   - 오타 방지
   - 변경 영향도 파악 용이

3. **민감한 데이터는 반드시 Keychain 사용**
   - UserDefaults는 암호화되지 않음
   - 비밀번호, 토큰 등은 Keychain에 저장

4. **햅틱 피드백은 HapticManager를 통해 일관되게 제공**
   - UX 일관성 유지
   - 재사용 용이

5. **경고 주석을 반드시 작성**
   - 미래의 나 또는 팀원을 위한 안전장치
   - 실수로 인한 데이터 손실 방지

---

## 📝 버전 히스토리

- **v1.0** (2025-12-18): LiveNote 프로젝트 기반 초기 작성
  - 기본 디렉토리 구조 정의
  - 필수 매니저 클래스 템플릿
  - SwiftData 설정 가이드
  - App Group 설정 가이드

---

**마지막 업데이트**: 2025-12-18
**기준 프로젝트**: LiveNote v1.0.0
