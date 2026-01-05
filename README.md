# LiveNote 📅

> LIVE NOTE - 잠금화면에서 항상 볼 수 있는 메모 앱

LiveNote는 iOS Live Activity를 활용하여 중요한 메모를 잠금화면과 Dynamic Island에 항상 표시해주는 앱입니다.

## ✨ 주요 기능

### 📱 Live Activity 잠금화면 표시
- **달력 또는 사진 표시**: 잠금화면에서 달력이나 원하는 사진과 메모를 함께 표시
- **자동 업데이트**: 자정마다 달력이 자동으로 업데이트
- **8시간 타이머**: 메모가 사라지기까지 남은 시간을 실시간으로 표시

### 📸 사진 기능 (NEW)
- **달력 대신 사진 선택**: Live Activity 좌측에 달력 대신 개인 사진 표시
- **블러 강도 조절**: 0~3단계로 사진 블러 효과 조절 (0: 선명, 3: 최대 블러)
- **고화질 크게보기**: 앱 내에서 원본 사진을 확대/축소하며 볼 수 있음
- **썸네일/원본 분리**: Live Activity는 메모리 효율적인 썸네일 사용, 크게보기는 고화질 원본 사용

### ⏰ 스마트 타이머 시스템
- **8시간 자동 유지**: Live Activity가 8시간 동안 잠금화면에 표시
- **연장 기능**: 앱 내 버튼으로 간편하게 8시간 연장
- **단계별 알림**: 남은 시간에 따라 색상과 메시지 변경
  - 🔴 5분 미만: "긴급 • 지금 앱 열어 연장"
  - 🟠 5-30분: "곧 종료 • 지금 연장하세요"
  - 🟡 30-60분: "n분 남음 • 앱에서 연장"

### 🏝️ Dynamic Island 지원
- **Compact View**: 현재 날짜 표시
- **Expanded View**: 전체 날짜, 메모, 타이머 표시
- **Minimal View**: 간소화된 날짜 표시

### 🎨 커스터마이징
- **14가지 배경 색상**: 다크그레이, 블랙, 네이비, 퍼플, 핑크, 오렌지, 그린, 블루, 레드, 틸, 민트, 옐로우, 브라운, 화이트
- **밝은 색상 자동 대응**: 밝은 배경(화이트, 옐로우, 민트 등) 선택 시 텍스트가 자동으로 검정색으로 변경
- **선택한 색상 자동 저장**: 앱 재시작 시에도 유지

### 🔗 링크 관리
- **카드형 UI**: 메모, 링크, 사진을 각각 독립적인 카드로 관리
- **빠른 저장**: 클립보드의 링크를 원터치로 저장
- **카테고리 관리**: 링크를 카테고리별로 정리
- **링크 공유**: 저장된 링크를 다른 앱으로 공유

## 🛠️ 기술 스택

### Core Technologies
- **SwiftUI**: 전체 UI 구현
- **ActivityKit**: Live Activity 및 Dynamic Island 구현
- **SwiftData**: 링크 및 카테고리 데이터 저장
- **WidgetKit**: Widget Extension

### 주요 기능별 기술
- **사진 기능**: CalendarImageManager (썸네일/원본 분리 저장)
- **App Group**: Live Activity와 메인 앱 간 데이터 공유
- **UserDefaults (App Group)**: 사진 블러 강도, 배경 색상 공유
- **UIScrollView**: 사진 크게보기 줌 기능

## 📂 프로젝트 구조

```
LiveNote/
├── LiveNote/
│   ├── ContentView.swift              # 메인 화면
│   ├── LiveActivityManager.swift      # Live Activity 관리
│   │
│   ├── Services/
│   │   ├── CalendarImageManager.swift # 사진 저장/로드 관리
│   │   ├── LocalizationManager.swift  # 다국어 지원
│   │   └── HapticManager.swift        # 햅틱 피드백
│   │
│   ├── Views/
│   │   ├── SettingsView.swift         # 설정 화면
│   │   └── Components/
│   │       ├── PhotoActionCard.swift  # 사진 카드
│   │       └── LinkActionCard.swift   # 링크 카드
│   │
│   ├── Models/
│   │   ├── LinkItem.swift             # 링크 데이터 모델
│   │   └── Category.swift             # 카테고리 데이터 모델
│   │
│   ├── Shared/
│   │   ├── MemoryNoteAttributes.swift # Live Activity 속성
│   │   ├── Colors.swift               # 색상 팔레트
│   │   └── Constants.swift            # 앱 상수
│   │
│   └── Constants/
│       └── PersistenceKeys.swift      # 저장소 키 관리
│
└── MemoryActivityWidget/
    └── MemoryActivityWidget.swift     # Live Activity UI
        ├── PhotoView                  # 사진 표시 뷰
        ├── CalendarGridView          # 달력 표시 뷰
        └── LiveActivityLockScreenPreview
```

## 🔑 핵심 컴포넌트

### LiveActivityManager

Live Activity의 생명주기를 관리하는 싱글톤 매니저입니다.

**주요 기능:**
- `startActivity(with:)`: Live Activity 시작
- `updateActivity(with:)`: 메모 내용 업데이트
- `updateBackgroundColor()`: 배경 색상 변경
- `extendTime()`: 8시간 연장 (기존 Activity 종료 후 새로 생성)
- `endActivity()`: Live Activity 종료
- `restoreActivityIfNeeded()`: 앱 재시작 시 실행 중인 Activity 복원

**연장 메커니즘:**
```swift
// 기존 Activity 완전 종료
await activity.end(nil, dismissalPolicy: .immediate)

// 새 startDate로 Activity 재생성 (시스템 8시간 제한 리셋)
let newActivity = try Activity.request(
    attributes: attributes,
    contentState: initialState,
    pushType: nil
)
```

### MemoryNoteAttributes

Live Activity의 데이터 구조를 정의합니다.

```swift
struct MemoryNoteAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var memo: String
        var startDate: Date        // 타이머 계산 기준
        var backgroundColor: ActivityBackgroundColor
        var usePhoto: Bool = false // 달력 대신 사진 사용 여부
    }
    var label: String
}
```

**ActivityBackgroundColor 특징:**
- `isLightColor`: 밝은 색상 자동 판별
- `textColor`: 배경에 맞는 텍스트 색상 (밝은 배경 → 검정, 어두운 배경 → 흰색)
- `secondaryTextColor`: 보조 텍스트 색상 (투명도 포함)

### CalendarImageManager

사진 저장 및 로드를 관리하는 싱글톤 매니저입니다.

**주요 기능:**
- **썸네일 생성**: Live Activity용 200px 썸네일 (메모리 효율)
- **원본 저장**: 크게보기용 최대 1000px 원본 (고화질)
- **App Group 저장**: Live Activity와 파일 공유
- **레거시 호환**: 기존 사진 파일 자동 마이그레이션

**저장 위치:**
- 썸네일: `App Group/calendar_image_thumbnail.jpg`
- 원본: `App Group/calendar_image_original.jpg`

### PhotoActionCard & LinkActionCard

카드형 UI 컴포넌트입니다.

**PhotoActionCard:**
- 사진 선택/변경/삭제
- 사진 크게보기
- 이중 확인 삭제 (메모와 동일한 패턴)

**LinkActionCard:**
- 링크 빠른 저장 (클립보드 감지)
- 저장된 링크 목록 보기

## 🚀 시작하기

### 요구사항
- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+

### 설치 및 실행

1. 저장소 클론
```bash
git clone https://github.com/YOUR_USERNAME/livenote.git
cd livenote
```

2. Xcode에서 프로젝트 열기
```bash
open LiveNote.xcodeproj
```

3. App Group 설정
   - Xcode에서 Signing & Capabilities 탭 열기
   - App Groups에 `group.com.livenote.shared` 추가
   - MemoryActivityWidget 타겟에도 동일하게 추가

4. 시뮬레이터 또는 실제 기기에서 실행

### Live Activity 테스트

Live Activity는 **실제 기기**에서만 제대로 테스트할 수 있습니다.

1. 앱 실행 후 메모 입력
2. 잠금화면에서 Live Activity 확인
3. Dynamic Island 지원 기기(iPhone 14 Pro 이상)에서 확장 UI 확인
4. 설정에서 사진 선택 후 Live Activity에 반영되는지 확인

## 🔄 주요 업데이트 이력

### v1.1.0 (Latest)
- ✅ **사진 기능 추가**: 달력 대신 사진 표시 가능
- ✅ **사진 블러 조절**: 0~3단계 블러 강도 설정
- ✅ **카드형 UI 재설계**: PhotoActionCard, LinkActionCard 분리
- ✅ **밝은 색상 지원**: 화이트 등 밝은 배경에 자동으로 검정 글씨
- ✅ **색상 팔레트 확장**: 14가지 색상 지원
- ✅ **썸네일/원본 분리**: 메모리 효율성 및 고화질 크게보기

### v1.0.0
- ✅ Live Activity 기본 구현
- ✅ 달력 표시 기능
- ✅ 8시간 타이머 시스템
- ✅ Dynamic Island 지원
- ✅ 색상 커스터마이징
- ✅ 연장 버튼
- ✅ 자정 자동 업데이트

## ⚠️ 개발자 주의사항

### 파일명 변경 금지
다음 파일명들은 변경 시 기존 사용자 데이터가 손실됩니다:
- `calendar_image_thumbnail.jpg` (Live Activity용 썸네일)
- `calendar_image_original.jpg` (크게보기용 원본)

### UserDefaults 키 변경 금지
`PersistenceKeys.swift`에 정의된 모든 키는 출시 후 변경 금지입니다:
- `selectedBackgroundColor`
- `usePhotoInsteadOfCalendar`
- `photoBlurIntensity`

### App Group 필수
Live Activity는 별도 프로세스로 실행되므로 App Group이 필수입니다:
- App Group Identifier: `group.com.livenote.shared`
- 메인 앱과 MemoryActivityWidget 모두에 추가 필요

### 새 밝은 색상 추가 시
`ActivityBackgroundColor.isLightColor`에 반드시 추가해야 합니다.
- 추가하지 않으면 밝은 배경에 흰 글씨가 되어 가독성 문제 발생

## 💡 알려진 제한사항

### iOS Live Activity 제한
- **8시간 최대 표시 시간**: iOS 시스템 제한으로 8시간 이후 자동 종료
  - 해결방법: 앱 내 연장 버튼으로 연장
- **잠깐 깜빡임**: 연장 시 기존 Activity를 종료하고 새로 생성하므로 순간적으로 사라질 수 있음
  - 이유: 시스템 8시간 제한을 완전히 리셋하기 위함

### 사진 기능
- **메모리 제한**: Live Activity는 썸네일(200px)만 사용
- **파일 크기**: 원본 이미지는 최대 1000px로 자동 리사이징

## 🤝 기여하기

이슈 및 PR은 언제나 환영합니다!

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 👨‍💻 개발자

Developed by [@minjunkoo](https://github.com/minjunkoo)

---

Made with ❤️ using SwiftUI & ActivityKit
