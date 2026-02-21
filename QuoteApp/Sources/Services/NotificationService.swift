import Foundation
import UserNotifications

/// ローカル通知管理サービス
/// - 毎日1回の名言通知
/// - 釣り場理論準拠の通知文言
/// - 重複排除と確実な配信
final class NotificationService: ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationService()

    private init() {}

    // MARK: - Authorization

    /// 通知権限をリクエスト
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)

        print(granted ? "✅ 通知権限が許可されました" : "⚠️ 通知権限が拒否されました")
        return granted
    }

    /// 現在の通知権限ステータスを取得
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notification

    /// 毎日の名言通知をスケジュール
    /// - Parameters:
    ///   - hour: 通知時刻（時）
    ///   - minute: 通知時刻（分）
    ///   - notificationHook: 通知文言（釣り場理論準拠）
    func scheduleDailyQuoteNotification(hour: Int, minute: Int, notificationHook: String?) async throws {
        let center = UNUserNotificationCenter.current()

        // 既存の通知をキャンセル
        center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.dailyQuote])

        // 通知内容
        let content = UNMutableNotificationContent()
        content.title = "今日の名言"

        // 釣り場理論準拠の文言を使用（通知フックがない場合はデフォルト）
        if let hook = notificationHook, !hook.isEmpty {
            content.body = hook
        } else {
            content.body = getRandomNotificationHook()
        }

        content.sound = .default
        content.badge = 1

        // 時刻設定
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // 通知リクエスト作成
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.dailyQuote,
            content: content,
            trigger: trigger
        )

        try await center.add(request)

        print("✅ 通知をスケジュールしました: \(hour):\(String(format: "%02d", minute))")
    }

    /// 通知をキャンセル
    func cancelDailyQuoteNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.dailyQuote]
        )
        print("❌ 通知をキャンセルしました")
    }

    /// スケジュール済みの通知を確認
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    // MARK: - Notification Hooks (釣り場理論)

    /// ランダムな通知フック文言を取得
    /// 釣り場理論準拠: 答えを完結させず、開かせる文言
    private func getRandomNotificationHook() -> String {
        let hooks = [
            "今日の名言、読んだ瞬間に鳥肌立った...",
            "昨日と今日の名言を比べてみろ。気づくことがある。",
            "90%の男がスルーする。でもお前は違うと信じてる。",
            "これ、朝イチで読むとマジで変わる。",
            "今日のは、ちょっとヤバい。覚悟して読んでくれ。",
            "こういう名言を知ってるかどうかで差がつく。",
            "毎朝これ読んでるけど、今日のはちょっと違った。",
            "この名言、お前のために選んだ。",
            "シンプルだけど、刺さる。今日の名言。",
            "今日の名言、保存する価値ある。マジで。"
        ]

        return hooks.randomElement() ?? "今日の名言が届きました。"
    }

    // MARK: - Notification Identifiers

    private enum NotificationIdentifier {
        static let dailyQuote = "daily_quote_notification"
    }
}
