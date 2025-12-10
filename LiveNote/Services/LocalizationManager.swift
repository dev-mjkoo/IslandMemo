import Foundation

/// 앱 전체 언어 설정을 관리하는 매니저
class LocalizationManager {

    /// 싱글톤 인스턴스
    static let shared = LocalizationManager()

    private init() {}

    /// 사용자의 선호 언어 (en, ko, ja, zh 등)
    var preferredLanguage: String {
        Locale.preferredLanguages.first ?? "en"
    }

    /// 아시아 언어인지 확인 (한국어, 일본어, 중국어)
    var isAsianLanguage: Bool {
        preferredLanguage.hasPrefix("ko") ||
        preferredLanguage.hasPrefix("ja") ||
        preferredLanguage.hasPrefix("zh")
    }

    /// 날짜/시간 포맷에 사용할 Locale
    /// - 아시아 언어: 해당 언어의 Locale
    /// - 그 외: 영어(en_US)
    var dateLocale: Locale {
        isAsianLanguage ? Locale(identifier: preferredLanguage) : Locale(identifier: "en_US")
    }

    /// 현재 언어 코드 (ko, en, ja, zh 등)
    var currentLanguageCode: String {
        if preferredLanguage.hasPrefix("ko") { return "ko" }
        if preferredLanguage.hasPrefix("ja") { return "ja" }
        if preferredLanguage.hasPrefix("zh") { return "zh" }
        return "en"
    }

    // MARK: - 번역 메서드

    /// 한국어 키를 받아서 현재 언어에 맞는 번역된 문자열 반환
    /// - Parameter key: 한국어 문자열 (예: "저장하기")
    /// - Returns: 번역된 문자열
    func string(_ key: String) -> String {
        let lang = currentLanguageCode
        return translations[key]?[lang] ?? key  // 번역 없으면 한국어 그대로 반환
    }

    // MARK: - 번역 데이터

    /// 한국어 키 → [언어코드: 번역] 딕셔너리
    private let translations: [String: [String: String]] = [
        // MARK: - 앱 기본
        "DON'T FORGET!": [
            "ko": "DON'T FORGET!",
            "en": "DON'T FORGET!",
            "ja": "忘れないで！",
            "zh": "别忘了！"
        ],

        // MARK: - 상태
        "LIVE": [
            "ko": "LIVE",
            "en": "LIVE",
            "ja": "ライブ",
            "zh": "直播"
        ],
        "IDLE": [
            "ko": "IDLE",
            "en": "IDLE",
            "ja": "待機中",
            "zh": "闲置"
        ],
        "ON SCREEN": [
            "ko": "ON SCREEN",
            "en": "ON SCREEN",
            "ja": "画面に表示中",
            "zh": "在屏幕上"
        ],
        "남은 시간:": [
            "ko": "남은 시간:",
            "en": "Time Left:",
            "ja": "残り時間:",
            "zh": "剩余时间:"
        ],
        "READY": [
            "ko": "READY",
            "en": "READY",
            "ja": "準備完了",
            "zh": "准备就绪"
        ],

        // MARK: - 공통 버튼
        "취소": [
            "ko": "취소",
            "en": "Cancel",
            "ja": "キャンセル",
            "zh": "取消"
        ],
        "저장": [
            "ko": "저장",
            "en": "Save",
            "ja": "保存",
            "zh": "保存"
        ],
        "추가": [
            "ko": "추가",
            "en": "Add",
            "ja": "追加",
            "zh": "添加"
        ],
        "확인": [
            "ko": "확인",
            "en": "OK",
            "ja": "確認",
            "zh": "确定"
        ],
        "다음": [
            "ko": "다음",
            "en": "Next",
            "ja": "次へ",
            "zh": "下一步"
        ],
        "시작하기": [
            "ko": "시작하기",
            "en": "Get Started",
            "ja": "始める",
            "zh": "开始使用"
        ],
        "완료": [
            "ko": "완료",
            "en": "Done",
            "ja": "完了",
            "zh": "完成"
        ],

        // MARK: - 링크 관련
        "링크": [
            "ko": "링크",
            "en": "Link",
            "ja": "リンク",
            "zh": "链接"
        ],
        "링크 저장": [
            "ko": "링크 저장",
            "en": "Save Link",
            "ja": "リンク保存",
            "zh": "保存链接"
        ],
        "링크 붙여넣기": [
            "ko": "링크 붙여넣기",
            "en": "Paste Link",
            "ja": "リンクを貼り付け",
            "zh": "粘贴链接"
        ],
        "저장된 링크": [
            "ko": "저장된 링크",
            "en": "Saved Links",
            "ja": "保存済みリンク",
            "zh": "已保存链接"
        ],
        "링크 저장 기능도 있어요!": [
            "ko": "링크 저장 기능도 있어요!",
            "en": "You can save links too!",
            "ja": "リンク保存機能もあります！",
            "zh": "还能保存链接！"
        ],

        // MARK: - 카테고리
        "카테고리": [
            "ko": "카테고리",
            "en": "Category",
            "ja": "カテゴリ",
            "zh": "分类"
        ],
        "카테고리가 없습니다": [
            "ko": "카테고리가 없습니다",
            "en": "No categories",
            "ja": "カテゴリがありません",
            "zh": "暂无分类"
        ],
        "새 카테고리": [
            "ko": "새 카테고리",
            "en": "New Category",
            "ja": "新しいカテゴリ",
            "zh": "新分类"
        ],
        "카테고리 이름을 입력하세요 (이모지 포함 가능)": [
            "ko": "카테고리 이름을 입력하세요 (이모지 포함 가능)",
            "en": "Enter category name (emoji supported)",
            "ja": "カテゴリ名を入力してください（絵文字対応）",
            "zh": "请输入分类名称（支持表情符号）"
        ],
        "카테고리 분류": [
            "ko": "카테고리 분류",
            "en": "Organize by Category",
            "ja": "カテゴリ分類",
            "zh": "分类整理"
        ],
        "링크를 카테고리별로 정리해요": [
            "ko": "링크를 카테고리별로 정리해요",
            "en": "Organize links by category",
            "ja": "リンクをカテゴリ別に整理",
            "zh": "按分类整理链接"
        ],
        "영화": [
            "ko": "영화",
            "en": "Movies",
            "ja": "映画",
            "zh": "电影"
        ],
        "기타": [
            "ko": "기타",
            "en": "Others",
            "ja": "その他",
            "zh": "其他"
        ],

        // MARK: - 메모
        "메모 (선택)": [
            "ko": "메모 (선택)",
            "en": "Note (Optional)",
            "ja": "メモ（任意）",
            "zh": "备注（可选）"
        ],
        "메모를 입력하세요": [
            "ko": "메모를 입력하세요",
            "en": "Enter a note",
            "ja": "メモを入力してください",
            "zh": "请输入备注"
        ],
        "이 곳을 클릭해 메모 입력": [
            "ko": "이 곳을 클릭해 메모 입력",
            "en": "Tap here to write a note",
            "ja": "ここをタップしてメモを入力",
            "zh": "点击这里输入备注"
        ],

        // MARK: - 온보딩
        "이제 기억할게 있다면": [
            "ko": "이제 기억할게 있다면",
            "en": "Got something to remember?",
            "ja": "覚えておきたいことがあれば",
            "zh": "有什么要记住的？"
        ],
        "잠금화면에서 바로 작성해보세요!": [
            "ko": "잠금화면에서 바로 작성해보세요!",
            "en": "Write it on your lock screen!",
            "ja": "ロック画面で直接入力しましょう！",
            "zh": "在锁屏上直接记录！"
        ],
        "메모와 달력이 잠금화면에 표시되어": [
            "ko": "메모와 달력이 잠금화면에 표시되어",
            "en": "Your notes and calendar appear on your lock screen",
            "ja": "メモとカレンダーがロック画面に表示され",
            "zh": "备忘录和日历显示在锁屏上"
        ],
        "언제든 빠르게 확인할 수 있어요": [
            "ko": "언제든 빠르게 확인할 수 있어요",
            "en": "Check them anytime, instantly",
            "ja": "いつでもすぐに確認できます",
            "zh": "随时快速查看"
        ],
        "잠금화면 미리보기": [
            "ko": "잠금화면 미리보기",
            "en": "Lock Screen Preview",
            "ja": "ロック画面プレビュー",
            "zh": "锁屏预览"
        ],
        "Safari나 다른 앱에서\n링크를 바로 저장할 수 있어요": [
            "ko": "Safari나 다른 앱에서\n링크를 바로 저장할 수 있어요",
            "en": "Save links instantly from Safari\nor any other app",
            "ja": "Safariやほかのアプリからすぐにリンクを保存できます",
            "zh": "从Safari或其他应用\n直接保存链接"
        ],
        "공유하기로 저장": [
            "ko": "공유하기로 저장",
            "en": "Save via Share",
            "ja": "共有で保存",
            "zh": "通过分享保存"
        ],
        "어떤 앱에서든 링크 공유만 하면 돼요": [
            "ko": "어떤 앱에서든 링크 공유만 하면 돼요",
            "en": "Just share a link from any app",
            "ja": "どのアプリからでもリンクを共有するだけ",
            "zh": "从任何应用分享链接即可"
        ],
        "미리보기 지원": [
            "ko": "미리보기 지원",
            "en": "Preview Support",
            "ja": "プレビュー対応",
            "zh": "支持预览"
        ],
        "링크 썸네일과 제목을 자동으로 가져와요": [
            "ko": "링크 썸네일과 제목을 자동으로 가져와요",
            "en": "Automatically fetches thumbnails and titles",
            "ja": "サムネイルとタイトルを自動取得",
            "zh": "自动获取缩略图和标题"
        ],

        // MARK: - 기타
        "링크를 복사해오세요": [
            "ko": "링크를 복사해오세요",
            "en": "Please copy a link first",
            "ja": "リンクをコピーしてください",
            "zh": "请先复制链接"
        ],
        "이미 존재하는 카테고리입니다": [
            "ko": "이미 존재하는 카테고리입니다",
            "en": "Category already exists",
            "ja": "すでに存在するカテゴリです",
            "zh": "分类已存在"
        ],
        "이미 있는 카테고리명입니다": [
            "ko": "이미 있는 카테고리명입니다",
            "en": "Category name already exists",
            "ja": "すでに存在するカテゴリ名です",
            "zh": "分类名称已存在"
        ],
        "개": [
            "ko": "개",
            "en": "",  // 영어는 "items" 같은 단어를 별도로 처리
            "ja": "個",
            "zh": "个"
        ],
        "삭제": [
            "ko": "삭제",
            "en": "Delete",
            "ja": "削除",
            "zh": "删除"
        ],
        "공유": [
            "ko": "공유",
            "en": "Share",
            "ja": "共有",
            "zh": "分享"
        ],
        "카테고리 삭제": [
            "ko": "카테고리 삭제",
            "en": "Delete Categories",
            "ja": "カテゴリ削除",
            "zh": "删除分类"
        ],
        "카테고리 수정": [
            "ko": "카테고리 수정",
            "en": "Edit Category",
            "ja": "カテゴリ編集",
            "zh": "编辑分类"
        ],
        "수정": [
            "ko": "수정",
            "en": "Edit",
            "ja": "編集",
            "zh": "编辑"
        ],

        // MARK: - 온보딩 - 단축어 가이드
        "잠금화면 메모": [
            "ko": "잠금화면 메모",
            "en": "Lock Screen Notes",
            "ja": "ロック画面メモ",
            "zh": "锁屏备忘录"
        ],
        "잠금화면에 표시되는 메모/달력은\n시스템 상 8시간 뒤에 자동으로 꺼집니다": [
            "ko": "잠금화면에 표시되는 메모/달력은\n시스템 상 8시간 뒤에 자동으로 꺼집니다",
            "en": "Notes/calendar on lock screen\nautomatically turn off after 8 hours",
            "ja": "ロック画面のメモ/カレンダーは\nシステム上8時間後に自動的に消えます",
            "zh": "锁屏上的备忘录/日历\n系统会在8小时后自动关闭"
        ],
        "이를 방지하기 위해 단축어 자동화 설정을 추가하면\n24시간 내내 항상 보이게 할 수 있어요": [
            "ko": "이를 방지하기 위해 단축어 자동화 설정을 추가하면\n24시간 내내 항상 보이게 할 수 있어요",
            "en": "Add Shortcuts automation to keep it\nvisible 24/7",
            "ja": "ショートカットの自動化を設定すれば\n24時間ずっと表示できます",
            "zh": "添加快捷指令自动化设置\n可以让它全天候显示"
        ],
        "1단계: 자동화 만들기": [
            "ko": "1단계: 자동화 만들기",
            "en": "Step 1: Create Automation",
            "ja": "ステップ1: 自動化を作成",
            "zh": "第1步: 创建自动化"
        ],
        "1. '단축어' 앱 실행\n2. 하단 '자동화' 탭 선택\n3. 우측 상단 '+' 버튼 클릭\n4. '특정 시간' 클릭": [
            "ko": "1. '단축어' 앱 실행\n2. 하단 '자동화' 탭 선택\n3. 우측 상단 '+' 버튼 클릭\n4. '특정 시간' 클릭",
            "en": "1. Open 'Shortcuts' app\n2. Tap 'Automation' at bottom\n3. Tap '+' button at top right\n4. Select 'Time of Day'",
            "ja": "1. 「ショートカット」アプリを開く\n2. 下部の「オートメーション」タブを選択\n3. 右上の「+」ボタンをタップ\n4. 「特定の時刻」をタップ",
            "zh": "1. 打开\"快捷指令\"应用\n2. 点击底部\"自动化\"标签\n3. 点击右上角\"+\"按钮\n4. 选择\"特定时间\""
        ],
        "2단계: 시간 설정": [
            "ko": "2단계: 시간 설정",
            "en": "Step 2: Set Time",
            "ja": "ステップ2: 時間設定",
            "zh": "第2步: 设置时间"
        ],
        "1. 시간: 00:00 설정\n2. 반복: 매일\n3. '즉시 실행' 선택\n4. '다음' 버튼 클릭": [
            "ko": "1. 시간: 00:00 설정\n2. 반복: 매일\n3. '즉시 실행' 선택\n4. '다음' 버튼 클릭",
            "en": "1. Time: Set to 00:00\n2. Repeat: Daily\n3. Enable 'Run Immediately'\n4. Tap 'Next'",
            "ja": "1. 時刻: 00:00に設定\n2. 繰り返し: 毎日\n3. 「即座に実行」を選択\n4. 「次へ」をタップ",
            "zh": "1. 时间: 设置为00:00\n2. 重复: 每天\n3. 选择\"立即运行\"\n4. 点击\"下一步\""
        ],
        "3단계: 동작 추가": [
            "ko": "3단계: 동작 추가",
            "en": "Step 3: Add Action",
            "ja": "ステップ3: アクションを追加",
            "zh": "第3步: 添加操作"
        ],
        "4단계: 나머지 2개 추가": [
            "ko": "4단계: 나머지 2개 추가",
            "en": "Step 4: Add 2 More",
            "ja": "ステップ4: 残り2つを追加",
            "zh": "第4步: 添加其余2个"
        ],
        "같은 방법으로 08:00, 16:00 자동화 생성": [
            "ko": "같은 방법으로 08:00, 16:00 자동화 생성",
            "en": "Create automations for 08:00 and 16:00\nthe same way",
            "ja": "同じ方法で08:00、16:00の自動化を作成",
            "zh": "用同样方法创建08:00和16:00的自动化"
        ],
        "총 3개 자동화가 만들어지면\n24시간 자동 연장 설정 완료!": [
            "ko": "총 3개 자동화가 만들어지면\n24시간 자동 연장 설정 완료!",
            "en": "Once you create 3 automations,\n24/7 auto-extend is complete!",
            "ja": "合計3つの自動化を作成すれば\n24時間自動延長設定完了！",
            "zh": "创建3个自动化后\n24小时自动延长设置完成！"
        ],
        "설정 완료!": [
            "ko": "설정 완료!",
            "en": "All Set!",
            "ja": "設定完了！",
            "zh": "设置完成！"
        ],
        "이제 메모가 24시간 내내 유지됩니다": [
            "ko": "이제 메모가 24시간 내내 유지됩니다",
            "en": "Your notes will now stay 24/7",
            "ja": "これでメモが24時間維持されます",
            "zh": "现在备忘录将全天候保持"
        ],
        "00시, 08시, 16시마다\n자동으로 잠금화면 표시가 연장돼요": [
            "ko": "00시, 08시, 16시마다\n자동으로 잠금화면 표시가 연장돼요",
            "en": "Lock screen display automatically extends\nat 00:00, 08:00, and 16:00",
            "ja": "0時、8時、16時に自動的に\nロック画面の表示が延長されます",
            "zh": "每天00:00、08:00、16:00\n自动延长锁屏显示"
        ],
        "시간": [
            "ko": "시간",
            "en": "Time",
            "ja": "時刻",
            "zh": "时间"
        ],
        "반복": [
            "ko": "반복",
            "en": "Repeat",
            "ja": "繰り返し",
            "zh": "重复"
        ],
        "매일": [
            "ko": "매일",
            "en": "Daily",
            "ja": "毎日",
            "zh": "每天"
        ],
        "즉시 실행": [
            "ko": "즉시 실행",
            "en": "Run Immediately",
            "ja": "即座に実行",
            "zh": "立即运行"
        ],
        "나의 단축어": [
            "ko": "나의 단축어",
            "en": "My Shortcuts",
            "ja": "マイショートカット",
            "zh": "我的快捷指令"
        ],
        "자동화": [
            "ko": "자동화",
            "en": "Automation",
            "ja": "オートメーション",
            "zh": "自动化"
        ],
        "잠금화면 표시 시간 연장": [
            "ko": "잠금화면 표시 시간 연장",
            "en": "Extend Lock Screen Display",
            "ja": "ロック画面表示時間延長",
            "zh": "延长锁屏显示时间"
        ],
        "단축어 설정 가이드": [
            "ko": "단축어 설정 가이드",
            "en": "Shortcuts Setup Guide",
            "ja": "ショートカット設定ガイド",
            "zh": "快捷指令设置指南"
        ],

        // MARK: - 온보딩 - 링크 공유 가이드
        "더 쉽게 사용하기": [
            "ko": "더 쉽게 사용하기",
            "en": "Use It Easier",
            "ja": "もっと簡単に使う",
            "zh": "更简单地使用"
        ],
        "링크를 더 쉽게 저장해보세요": [
            "ko": "링크를 더 쉽게 저장해보세요",
            "en": "Save links even easier",
            "ja": "もっと簡単にリンクを保存しましょう",
            "zh": "更轻松地保存链接"
        ],
        "다른 앱에서 링크 찾기": [
            "ko": "다른 앱에서 링크 찾기",
            "en": "Find a Link",
            "ja": "ほかのアプリでリンクを探す",
            "zh": "从其他应用找链接"
        ],
        "Safari, Chrome, YouTube 등 어떤 앱이든 OK": [
            "ko": "Safari, Chrome, YouTube 등 어떤 앱이든 OK",
            "en": "Safari, Chrome, YouTube—any app works",
            "ja": "Safari、Chrome、YouTubeなど、どのアプリでもOK",
            "zh": "Safari、Chrome、YouTube等任何应用都可以"
        ],
        "공유 버튼 누르기": [
            "ko": "공유 버튼 누르기",
            "en": "Tap Share Button",
            "ja": "共有ボタンをタップ",
            "zh": "点击分享按钮"
        ],
        "공유 아이콘을 탭하세요": [
            "ko": "공유 아이콘을 탭하세요",
            "en": "Tap the share icon",
            "ja": "共有アイコンをタップしてください",
            "zh": "点击分享图标"
        ],
        "LiveNote 선택": [
            "ko": "LiveNote 선택",
            "en": "Select LiveNote",
            "ja": "LiveNoteを選択",
            "zh": "选择LiveNote"
        ],
        "앱 목록에서 LiveNote를 찾아서 탭": [
            "ko": "앱 목록에서 LiveNote를 찾아서 탭",
            "en": "Find and tap LiveNote in the app list",
            "ja": "アプリ一覧からLiveNoteを探してタップ",
            "zh": "在应用列表中找到并点击LiveNote"
        ],
        "자동 저장 완료!": [
            "ko": "자동 저장 완료!",
            "en": "Auto-saved!",
            "ja": "自動保存完了！",
            "zh": "自动保存完成！"
        ],
        "카테고리 선택하고 저장하면 끝": [
            "ko": "카테고리 선택하고 저장하면 끝",
            "en": "Just pick a category and save",
            "ja": "カテゴリを選んで保存すれば完了",
            "zh": "选择分类并保存即可"
        ],

        // MARK: - 예시 텍스트
        "오늘 할 일\n- 운동하기\n- 책 읽기": [
            "ko": "오늘 할 일\n- 운동하기\n- 책 읽기",
            "en": "Today's Tasks\n- Exercise\n- Read a book",
            "ja": "今日やること\n- 運動する\n- 本を読む",
            "zh": "今日待办\n- 锻炼\n- 读书"
        ],
        "오늘 할 일\n- 디자인 피드백\n- 온보딩 수정": [
            "ko": "오늘 할 일\n- 디자인 피드백\n- 온보딩 수정",
            "en": "Today's Tasks\n- Design feedback\n- Update onboarding",
            "ja": "今日やること\n- デザインフィードバック\n- オンボーディング修正",
            "zh": "今日待办\n- 设计反馈\n- 修改引导"
        ],
        "매일 %@에": [
            "ko": "매일 %@에",
            "en": "Daily at %@",
            "ja": "毎日%@に",
            "zh": "每天%@"
        ],
        "'복사→붙여넣기 없이' 바로 링크 저장할 수 있어요": [
            "ko": "'복사→붙여넣기 없이' 바로 링크 저장할 수 있어요",
            "en": "Save links without copying and pasting",
            "ja": "コピー&ペーストなしでリンクを保存できます",
            "zh": "无需复制粘贴即可保存链接"
        ],
        "복사→붙여넣기 없이": [
            "ko": "복사→붙여넣기 없이",
            "en": "without copying and pasting",
            "ja": "コピー&ペーストなし",
            "zh": "无需复制粘贴"
        ],
        "링크 없음": [
            "ko": "링크 없음",
            "en": "No links",
            "ja": "リンクなし",
            "zh": "无链接"
        ],
        "공유 목록에 LiveNote가 안 보이면\n하단의 '더 보기' 버튼을 눌러서 찾아보세요": [
            "ko": "공유 목록에 LiveNote가 안 보이면\n하단의 '더 보기' 버튼을 눌러서 찾아보세요",
            "en": "If you don't see LiveNote in the share menu\nTap 'More' button at the bottom to find it",
            "ja": "共有メニューにLiveNoteが表示されない場合\n下部の「その他」ボタンをタップして探してください",
            "zh": "如果在分享菜单中看不到LiveNote\n点击底部的\"更多\"按钮查找"
        ],
        "중요 Tip": [
            "ko": "중요 Tip",
            "en": "Important Tip",
            "ja": "重要なヒント",
            "zh": "重要提示"
        ],
        "앱에서 '연장' 버튼을 눌러주세요": [
            "ko": "앱에서 '연장' 버튼을 눌러주세요",
            "en": "Tap 'Extend' in the app",
            "ja": "アプリで「延長」をタップしてください",
            "zh": "在应用中点击\"延长\""
        ],
        "시간 만료 • 앱에서 새로고침": [
            "ko": "시간 만료 • 앱에서 새로고침",
            "en": "Expired • Refresh in app",
            "ja": "時間切れ • アプリで更新",
            "zh": "时间到 • 在应用中刷新"
        ],
        "일 전": [
            "ko": "일 전",
            "en": "d ago",
            "ja": "日前",
            "zh": "天前"
        ],
        "시간 전": [
            "ko": "시간 전",
            "en": "h ago",
            "ja": "時間前",
            "zh": "小时前"
        ],
        "분 전": [
            "ko": "분 전",
            "en": "m ago",
            "ja": "分前",
            "zh": "分钟前"
        ],
        "방금": [
            "ko": "방금",
            "en": "Just now",
            "ja": "たった今",
            "zh": "刚刚"
        ]
    ]

    // MARK: - 포맷 문자열 메서드

    /// 카테고리 삭제 버튼 텍스트 (숫자 포함)
    func deleteCategoriesText(count: Int) -> String {
        let lang = currentLanguageCode
        switch lang {
        case "ko": return "\(count)개 카테고리 삭제"
        case "ja": return "\(count)個のカテゴリを削除"
        case "zh": return "删除\(count)个分类"
        default: return "Delete \(count) \(count == 1 ? "Category" : "Categories")"
        }
    }

    /// "개" 단위 (언어별)
    func countSuffix() -> String {
        let lang = currentLanguageCode
        switch lang {
        case "ko": return "개"
        case "ja": return "個"
        case "zh": return "个"
        default: return ""  // 영어는 없음
        }
    }

    /// 타이머 텍스트가 앞에 오는지 뒤에 오는지 확인
    func isTimerFirst() -> Bool {
        let lang = currentLanguageCode
        return lang == "en"  // 영어만 타이머가 앞에 옴
    }

    /// 타이머 텍스트 (타이머 제외)
    func timerSuffixText() -> String {
        let lang = currentLanguageCode
        switch lang {
        case "ko": return " 후에 사라짐"
        case "ja": return " 後に消えます"
        case "zh": return " 后消失"
        default: return " until gone"
        }
    }

    /// 타이머 텍스트 (앞에 붙는 경우 - 영어)
    func timerPrefixText() -> String {
        let lang = currentLanguageCode
        switch lang {
        case "en": return "Gone in "
        default: return ""
        }
    }

    /// Step 3 설명 (앱 이름 포함)
    func step3Description(appName: String) -> String {
        let lang = currentLanguageCode
        switch lang {
        case "ko": return "1. 검색창에 '\(appName)' 입력\n2. '\(string("잠금화면 표시 시간 연장"))' 선택"
        case "en": return "1. Enter '\(appName)' in search\n2. Select '\(string("잠금화면 표시 시간 연장"))'"
        case "ja": return "1. 検索欄に「\(appName)」を入力\n2. 「\(string("잠금화면 표시 시간 연장"))」を選択"
        case "zh": return "1. 在搜索栏输入\"\(appName)\"\n2. 选择\"\(string("잠금화면 표시 시간 연장"))\""
        default: return "1. Enter '\(appName)' in search\n2. Select '\(string("잠금화면 표시 시간 연장"))'"
        }
    }
}
