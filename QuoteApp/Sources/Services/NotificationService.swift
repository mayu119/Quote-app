import Foundation
import UserNotifications
import ActivityKit
import UIKit

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
        self.author = quote.author
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
        static var allPremiumSlots: [String] { (0..<3).map { premiumSlot($0) } }
        static var allTrialReminders: [String] { [trialReminder5d, trialReminder3d, trialReminder1d] }
        static var allQuoteIDs: [String] { [dailyQuote] + allPremiumSlots }
    }

    private static let premiumTimeLabels = ["朝の一言", "昼の名言", "夜の言葉"]
    private static let savedQuotesKey = "notification_saved_quotes"

    // MARK: - 厳選フォールバック名言（釣り場理論の代わり）

    static let curatedQuotes: [NotificationQuote] = [
        NotificationQuote(
            quoteJa: "ハングリーであれ。愚かであれ。",
            punchline: "ハングリーであれ。愚かであれ。",
            author: "Steve Jobs",
            authorDescription: "Apple共同創業者"
        ),
        NotificationQuote(
            quoteJa: "成功とは、失敗から失敗へと情熱を失わずに進むことだ。",
            punchline: "失敗から失敗へ、情熱を失わずに。",
            author: "Winston Churchill",
            authorDescription: "元英国首相"
        ),
        NotificationQuote(
            quoteJa: "今から20年後、やったことよりもやらなかったことを後悔するだろう。",
            punchline: "やらなかったことを後悔する。",
            author: "Mark Twain",
            authorDescription: "アメリカの小説家"
        ),
        NotificationQuote(
            quoteJa: "想像力は知識よりも重要だ。知識には限界がある。だが想像力は世界を包み込む。",
            punchline: "想像力は知識よりも重要だ。",
            author: "Albert Einstein",
            authorDescription: "理論物理学者"
        ),
        NotificationQuote(
            quoteJa: "為せば成る、為さねば成らぬ何事も。成らぬは人の為さぬなりけり。",
            punchline: "為せば成る。",
            author: "上杉鷹山",
            authorDescription: "米沢藩主"
        ),
        NotificationQuote(
            quoteJa: "人生とは自分を見つけることではない。人生とは自分を創ることだ。",
            punchline: "人生とは自分を創ることだ。",
            author: "George Bernard Shaw",
            authorDescription: "劇作家・ノーベル文学賞"
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
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
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
        
        // 本文に名言全体
        content.body = quote.quoteJa.isEmpty ? quote.punchline : quote.quoteJa

        content.sound = .default
        content.badge = 1
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
    }

    func cancelDailyQuoteNotification() { cancelAllQuoteNotifications() }

    // MARK: - Trial Reminders

    func scheduleTrialReminders(trialEndDate: Date) async throws {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        cancelTrialReminders()

        let reminders: [(String, Int, String, String)] = [
            (ID.trialReminder5d, 5, "無料トライアル終了まで残り5日",
             "プレミアム体験を続けませんか？今なら全機能が使い放題です。"),
            (ID.trialReminder3d, 3, "トライアル終了まで残り3日",
             "お気に入りの名言が、もうすぐ見られなくなります。"),
            (ID.trialReminder1d, 1, "トライアルは明日終了します",
             "最後のチャンスです。今日中にプレミアムプランを選びましょう。"),
        ]

        for (identifier, daysBefore, title, body) in reminders {
            guard let reminderDate = calendar.date(
                byAdding: .day, value: -daysBefore, to: trialEndDate
            ), reminderDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "TRIAL_REMINDER"

            var dc = calendar.dateComponents([.year, .month, .day], from: reminderDate)
            dc.calendar = Calendar.current
            dc.timeZone = TimeZone.current
            dc.hour = 9; dc.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier, content: content, trigger: trigger
            )
            try await center.add(request)
        }
    }

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
                categoryJa: resolved.categoryJa.isEmpty ? "DAILY QUOTE" : resolved.categoryJa
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
}
