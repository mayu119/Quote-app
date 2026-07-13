import Foundation
import ActivityKit
import UIKit
import UserNotifications

// MARK: - Live Activity Attributes (shared with Widget Extension)
@available(iOS 16.1, *)
public struct QuoteLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var punchline: String
        public var author: String
        public var categoryJa: String

        public init(punchline: String, author: String, categoryJa: String) {
            self.punchline = punchline
            self.author = author
            self.categoryJa = categoryJa
        }
    }
    public init() {}
}


/// 通知用の名言データ（リッチ通知用）
struct NotificationQuote: Codable {
    let quoteJa: String
    let punchline: String
    let author: String
    let authorDescription: String
    let categoryJa: String

    init(quoteJa: String = "", punchline: String, author: String, authorDescription: String = "", categoryJa: String = "") {
        self.quoteJa = quoteJa
        self.punchline = punchline
        self.author = author
        self.authorDescription = authorDescription
        self.categoryJa = categoryJa
    }

    init(from quote: Quote) {
        self.quoteJa = quote.quoteJa
        self.punchline = quote.punchline
        self.author = quote.displayAuthor
        self.authorDescription = quote.authorDescription
        self.categoryJa = quote.category.displayTitleJa
    }

    var isHighQuality: Bool {
        !author.isEmpty &&
        author != "Unknown" &&
        !punchline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        punchline.count >= 5
    }
}

/// ローカル通知管理サービス
/// - 常にリッチ通知（名言 + 著者 + 肩書き）
/// - 釣り場理論フォールバック廃止 → 必ず実在する名言を表示
final class NotificationService: ObservableObject {

    static let shared = NotificationService()
    private init() {}

    // MARK: - Identifiers

    private enum ID {
        static let dailyQuote = "daily_quote_notification"
        static func premiumSlot(_ index: Int) -> String { "\(dailyQuote)_premium_\(index)" }
        static let trialReminder5d = "trial_reminder_5d"
        static let trialReminder3d = "trial_reminder_3d"
        static let trialReminder1d = "trial_reminder_1d"
        static let weeklyShelf = "weekly_shelf_notification"
        static var allPremiumSlots: [String] { (0..<3).map { premiumSlot($0) } }
        static var allTrialReminders: [String] { [trialReminder5d, trialReminder3d, trialReminder1d] }
        static var allQuoteIDs: [String] { [dailyQuote] + allPremiumSlots }
    }

    private static let premiumTimeLabels = ["朝の一言", "昼の名言", "夜の言葉"]
    private static let savedQuotesKey = "notification_saved_quotes"
    private static let notificationModeKey = "notification_copy_mode"

    enum NotificationCopyMode: String {
        case full
        case tease
    }

    /// Keychain install_id + SHA256 で同一端末は常に同じ群に割り当てる。
    private var notificationCopyMode: NotificationCopyMode {
        if let stored = UserDefaults.standard.string(forKey: Self.notificationModeKey),
           let mode = NotificationCopyMode(rawValue: stored) {
            return mode
        }
        let assigned = ExperimentAssignmentService.shared.variant(for: "notification_copy_v2")
        let mode = NotificationCopyMode(rawValue: assigned) ?? .full
        UserDefaults.standard.set(mode.rawValue, forKey: Self.notificationModeKey)
        return mode
    }

    // MARK: - 厳選フォールバック名言（釣り場理論の代わり）

    static let curatedQuotes: [NotificationQuote] = [
        NotificationQuote(
            quoteJa: "私はそのままで、愛される価値がある。",
            punchline: "私はそのままで、愛される価値がある。",
            author: "オリジナル",
            authorDescription: "アプリオリジナル"
        ),
        NotificationQuote(
            quoteJa: "明日はまた新しい一日。\nそして、奇跡は起こると私は信じている。",
            punchline: "明日はまた新しい一日。",
            author: "オードリー・ヘプバーン",
            authorDescription: "女優・人道活動家"
        ),
        NotificationQuote(
            quoteJa: "相手が低く出ても、\n私たちは高くあろう。",
            punchline: "相手に合わせて、自分まで低くならない。",
            author: "ミシェル・オバマ",
            authorDescription: "弁護士・元アメリカ大統領夫人"
        ),
        NotificationQuote(
            quoteJa: "家族は、この世界でいちばん大切なもの。",
            punchline: "家族は、世界でいちばん大切なもの。",
            author: "プリンセス・ダイアナ",
            authorDescription: "イギリス王室 ダイアナ元皇太子妃"
        ),
        NotificationQuote(
            quoteJa: "人を裁いていたら、\n愛する時間がなくなってしまう。",
            punchline: "裁く前に、理解する余白を持つ。",
            author: "マザー・テレサ",
            authorDescription: "修道女・カトリック聖人"
        ),
        NotificationQuote(
            quoteJa: "私は今日、\nやさしさと強さを両方持っていていい。",
            punchline: "私は、やさしさと強さを両方持っていい。",
            author: "オリジナル",
            authorDescription: "アプリオリジナル"
        ),
    ]

    // MARK: - Quote Persistence（SettingsView再スケジュール時にも使用）

    /// ContentView で選出した通知用名言を保存
    func saveNotificationQuotes(_ quotes: [NotificationQuote]) {
        if let data = try? JSONEncoder().encode(quotes) {
            UserDefaults.standard.set(data, forKey: Self.savedQuotesKey)
        }
    }

    /// 保存済みの通知用名言を取得（なければ厳選フォールバック）
    func loadSavedNotificationQuotes() -> [NotificationQuote] {
        guard let data = UserDefaults.standard.data(forKey: Self.savedQuotesKey),
              let quotes = try? JSONDecoder().decode([NotificationQuote].self, from: data),
              !quotes.isEmpty else {
            return Self.curatedQuotes.shuffled()
        }
        return quotes
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound]
        let granted = try await center.requestAuthorization(options: options)
        print(granted ? "✅ 通知権限が許可されました" : "⚠️ 通知権限が拒否されました")
        return granted
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Single Daily Notification (Free)

    func scheduleDailyNotification(
        hour: Int,
        minute: Int,
        quote: NotificationQuote? = nil
    ) async throws {
        let center = UNUserNotificationCenter.current()
        cancelAllQuoteNotifications()

        let resolvedQuote = resolveQuote(quote)
        let content = buildRichContent(quote: resolvedQuote, timeLabel: "今日の名言")

        var dc = DateComponents()
        dc.calendar = Calendar.current
        dc.timeZone = TimeZone.current
        dc.hour = hour
        dc.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(
            identifier: ID.dailyQuote, content: content, trigger: trigger
        )

        try await center.add(request)
        print("✅ 通知スケジュール: \(hour):\(String(format: "%02d", minute)) → \(resolvedQuote.author)")
        await debugPrintPending()
    }

    // MARK: - Schedule Premium Notifications (3 Times)

    func schedulePremiumNotifications(
        times: [Date],
        quotes: [NotificationQuote]
    ) async throws {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        cancelAllQuoteNotifications()

        for (index, time) in times.enumerated() {
            let raw = index < quotes.count ? quotes[index] : nil
            let resolvedQuote = resolveQuote(raw)
            let timeLabel = index < Self.premiumTimeLabels.count ? Self.premiumTimeLabels[index] : "プレミアム名言"
            let content = buildRichContent(quote: resolvedQuote, timeLabel: timeLabel)

            var dc = DateComponents()
            dc.calendar = Calendar.current
            dc.timeZone = TimeZone.current
            dc.hour = calendar.component(.hour, from: time)
            dc.minute = calendar.component(.minute, from: time)

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let request = UNNotificationRequest(
                identifier: ID.premiumSlot(index), content: content, trigger: trigger
            )
            try await center.add(request)
        }

        print("✅ プレミアム通知を\(times.count)件スケジュール")
        await debugPrintPending()
    }

    // MARK: - Resolve Quote（nil・低品質 → 保存済み or 厳選名言に置換）

    private func resolveQuote(_ quote: NotificationQuote?) -> NotificationQuote {
        // 渡された名言が高品質ならそのまま使用
        if let q = quote, q.isHighQuality { return q }

        // 保存済みの名言から取得
        let saved = loadSavedNotificationQuotes().filter { $0.isHighQuality }
        if let pick = saved.randomElement() { return pick }

        // 最終フォールバック: 厳選名言
        return Self.curatedQuotes.randomElement()!
    }

    // MARK: - Build Rich Content

    private func buildRichContent(quote: NotificationQuote, timeLabel: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // 1・4の装飾（画像・過剰なタイトル）を廃止し、本来のシンプルな構造に
        content.title = timeLabel
        
        // サブタイトルに著者（+肩書き）
        if !quote.authorDescription.isEmpty {
            content.subtitle = "\(quote.author) (\(quote.authorDescription))"
        } else {
            content.subtitle = quote.author
        }
        
        let mode = notificationCopyMode
        if mode == .tease {
            content.body = "まだ言葉にできない気持ちへ。今日の一枚を、引いてみませんか。"
        } else {
            content.body = quote.quoteJa.isEmpty ? quote.punchline : quote.quoteJa
        }
        content.userInfo["copy_mode"] = mode.rawValue
        AnalyticsService.shared.logNotificationExperiment(mode: mode.rawValue, event: "scheduled")

        content.sound = .default
        // バッジは使わない。通知が来るたびにアイコンへ「1」が残るのを防ぐ。
        content.categoryIdentifier = "DAILY_QUOTE"
        
        // 通知のグルーピング (引続き有効)
        content.threadIdentifier = quote.categoryJa.isEmpty ? "daily_quote" : quote.categoryJa

        if #available(iOS 15.0, *) {
            // iOS 15以上: 高い関連性スコアを付与（Dynamic Lock Screen 用）
            content.relevanceScore = 1.0
            content.interruptionLevel = .active
        }

        return content
    }

    // MARK: - Cancel

    func cancelAllQuoteNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ID.allQuoteIDs
        )
        print("🗑 すべての通知スケジュールをキャンセルしました")
    }
    func cancelDailyQuoteNotification() { cancelAllQuoteNotifications() }

    func scheduleWeeklyShelfNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "今週のあなたの棚が整いました"
        content.body = "今週、心に残った言葉を静かに見返せます。"
        content.sound = .default
        var components = DateComponents()
        components.calendar = .current
        components.weekday = 1 // Sunday
        components.hour = 21
        let request = UNNotificationRequest(
            identifier: ID.weeklyShelf,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Trial Reminders

    /// トライアル終了前リマインダーは出さない方針。旧ビルドで予約済みの分の掃除用に残す
    func cancelTrialReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ID.allTrialReminders
        )
    }

    // MARK: - Debug

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    private func debugPrintPending() async {
        let pending = await getPendingNotifications()
        print("📋 登録済み通知: \(pending.count)件")
        for req in pending {
            if let trigger = req.trigger as? UNCalendarNotificationTrigger {
                let dc = trigger.dateComponents
                print("  → [\(req.identifier)] \(dc.hour ?? 0):\(String(format: "%02d", dc.minute ?? 0))")
            }
        }
    }
    
    // MARK: - iOS 26 Dynamic Lock Screen (Live Activities)
    
    /// iOS 26のダイナミックロック画面通知としてLive Activityを開始/更新する
    func startDynamicLockScreenActivity(with quote: NotificationQuote?) {
        let resolved = resolveQuote(quote)
        
        // 既存の同じLive Activityがあれば更新、なければ新規作成
        if #available(iOS 16.1, *) {
            let state = QuoteLiveActivityAttributes.ContentState(
                punchline: resolved.punchline,
                author: resolved.author,
                categoryJa: resolved.categoryJa.isEmpty ? "今日の言葉" : resolved.categoryJa
            )
            
            Task {
                // 既存のActivityを更新
                var hasUpdated = false
                for activity in Activity<QuoteLiveActivityAttributes>.activities {
                    await activity.update(using: state)
                    hasUpdated = true
                    print("✅ Live Activity を更新しました")
                }
                
                // 既存がない場合は新規開始
                if !hasUpdated {
                    let attributes = QuoteLiveActivityAttributes()
                    do {
                        _ = try Activity.request(
                            attributes: attributes,
                            contentState: state,
                            pushType: nil
                        )
                        print("✅ Live Activity を新規開始しました")
                    } catch {
                        print("⚠️ Live Activity 開始失敗: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// 既存のLive Activity（ダイナミックロック画面）を終了する
    func cancelDynamicLockScreenActivity() {
        if #available(iOS 16.1, *) {
            Task {
                for activity in Activity<QuoteLiveActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    print("🗑 Live Activity を終了しました")
                }
            }
        }
    }
}
