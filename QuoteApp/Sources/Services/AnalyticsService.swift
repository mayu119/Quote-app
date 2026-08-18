import Foundation
import UIKit
import Security

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// 計測に共通で使う安定識別子と、対象アクションのカウンタを管理する。
final class ExperimentAssignmentService {
    static let shared = ExperimentAssignmentService()

    private let keychainService = "com.antigravity.QuoteApp.experiments"
    private let installAccount = "install_id"
    private let insightCounterKey = "experiment.insight_suggestion_v2.eligible_save_count"

    private init() {}

    lazy var installID: String = {
        if let existing = readInstallID() { return existing }
        let created = UUID().uuidString.lowercased()
        saveInstallID(created)
        return created
    }()

    /// 振り返りメモ保存の3回に1回だけ追加提案を出す。
    func recordEligibleInsightSaveAndShouldShow() -> Bool {
        let next = UserDefaults.standard.integer(forKey: insightCounterKey) + 1
        UserDefaults.standard.set(next, forKey: insightCounterKey)
        return Self.shouldShowInsight(eligibleSaveCount: next)
    }

    static func shouldShowInsight(eligibleSaveCount: Int) -> Bool {
        eligibleSaveCount > 0 && eligibleSaveCount % 3 == 0
    }

    private func readInstallID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: installAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func saveInstallID(_ value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: installAccount
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }
}

/// Firebase Analytics イベントロギングサービス
/// 全42イベント + 4ユーザープロパティを一元管理
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {
        installDate = UserDefaults.standard.object(forKey: "analytics_install_date") as? Date ?? {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "analytics_install_date")
            return now
        }()
        sessionCount = UserDefaults.standard.integer(forKey: "analytics_session_count")
    }

    // MARK: - Internal State

    private let installDate: Date
    private var sessionCount: Int
    private var sessionStartTime: Date?
    private var quotesViewedInSession: Int = 0
    private var currentQuoteViewTime: Date?
    private var currentQuoteId: String?

    var daysSinceInstall: Int {
        Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }

    // MARK: - Private Helpers

    private func log(_ name: String, params: [String: Any] = [:]) {
        var enriched = params
        enriched["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        enriched["build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        enriched["install_id"] = ExperimentAssignmentService.shared.installID
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: enriched)
        #endif
        #if DEBUG
        let paramStr = enriched.isEmpty ? "" : " | \(enriched)"
        print("📊 [Analytics] \(name)\(paramStr)")
        #endif
    }

    private func setUserProperty(_ value: String?, forName name: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
    }

    // ============================================================
    // MARK: 1. ライフサイクル系（7件）
    // ============================================================

    /// 初回起動
    func logFirstOpen(appVersion: String) {
        #if canImport(UIKit)
        let model = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion
        #else
        let model = "unknown"
        let osVersion = "unknown"
        #endif
        log("app_first_open", params: [
            "device_model": model,
            "os_version": osVersion,
            "app_version": appVersion
        ])
    }

    /// 毎回の起動
    func logSessionStart(isPremium: Bool) {
        sessionCount += 1
        UserDefaults.standard.set(sessionCount, forKey: "analytics_session_count")
        sessionStartTime = Date()
        quotesViewedInSession = 0

        log("app_session_start", params: [
            "session_number": sessionCount,
            "days_since_install": daysSinceInstall,
            "is_premium": isPremium ? "true" : "false"
        ])
        log("session_start", params: [
            "session_number": sessionCount,
            "days_since_install": daysSinceInstall,
            "is_premium": isPremium ? "true" : "false"
        ])

        // ユーザープロパティ更新
        setUserProperty(isPremium ? "premium" : "free", forName: "user_type")
        setUserProperty("\(daysSinceInstall)", forName: "days_since_install")
    }

    /// バックグラウンドへ（セッション終了）
    func logAppBackground() {
        let duration = sessionStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
        log("app_background", params: [
            "session_duration_sec": duration,
            "quotes_viewed_in_session": quotesViewedInSession
        ])
    }

    /// オンボーディングステップ表示
    func logOnboardingStepView(stepIndex: Int) {
        log("onboarding_step_view", params: [
            "step_index": stepIndex
        ])
    }

    /// オンボーディング ジャンル選択
    func logOnboardingGenreSelect(genres: [String]) {
        log("onboarding_genre_select", params: [
            "selected_genres": genres.joined(separator: ","),
            "genre_count": genres.count
        ])
    }

    /// オンボーディング完了
    func logOnboardingComplete(selectedGenreCount: Int, notificationGranted: Bool) {
        log("onboarding_complete", params: [
            "selected_genre_count": selectedGenreCount,
            "notification_granted": notificationGranted ? "true" : "false"
        ])
    }

    func logPrescriptionView() {
        log("prescription_view", params: [
            "days_since_install": daysSinceInstall,
            "session_number": sessionCount
        ])
    }

    /// 通知権限結果
    func logNotificationPermission(granted: Bool) {
        log("notification_permission", params: [
            "granted": granted ? "true" : "false"
        ])
    }

    // ============================================================
    // MARK: 2. コンテンツ閲覧系（9件）
    // ============================================================

    /// 名言表示（スクロール停止時）
    func logQuoteView(quoteId: String, author: String, categoryMedium: String, categoryLarge: String, quoteIndex: Int, isPremium: Bool) {
        quotesViewedInSession += 1

        // 前の名言の dwell time を自動計測して送信
        flushDwell()

        currentQuoteId = quoteId
        currentQuoteViewTime = Date()

        log("quote_view", params: [
            "quote_id": quoteId,
            "author": author,
            "category_medium": categoryMedium,
            "category_large": categoryLarge,
            "quote_index": quoteIndex,
            "is_premium": isPremium ? "true" : "false"
        ])
    }

    /// 滞在時間の自動送信（3秒以上のみ）
    private func flushDwell() {
        guard let id = currentQuoteId,
              let start = currentQuoteViewTime else { return }
        let seconds = Int(Date().timeIntervalSince(start))
        if seconds >= 3 {
            log("quote_dwell", params: [
                "quote_id": id,
                "dwell_seconds": seconds
            ])
        }
        currentQuoteId = nil
        currentQuoteViewTime = nil
    }

    /// スワイプ（次の名言へ）
    func logQuoteSwipe(fromQuoteId: String, toQuoteIndex: Int, swipeCountInSession: Int) {
        log("quote_swipe", params: [
            "from_quote_id": fromQuoteId,
            "to_quote_index": toQuoteIndex,
            "swipe_count_in_session": swipeCountInSession
        ])
    }

    /// 無料制限到達
    func logDailyLimitReached(swipeCount: Int, categoryMedium: String?, categoryLarge: String?) {
        log("daily_limit_reached", params: [
            "swipe_count": swipeCount,
            "category_medium": categoryMedium ?? "all",
            "category_large": categoryLarge ?? "all"
        ])
    }

    /// カテゴリ切り替え
    func logCategorySwitch(fromMedium: String?, fromLarge: String?, toMedium: String?, toLarge: String?, isPremium: Bool) {
        log("category_switch", params: [
            "from_medium": fromMedium ?? "all",
            "from_large": fromLarge ?? "all",
            "to_medium": toMedium ?? "all",
            "to_large": toLarge ?? "all",
            "is_premium": isPremium ? "true" : "false"
        ])
    }

    /// ロックカテゴリのタップ
    func logCategoryLockedTap(categoryMedium: String?, categoryLarge: String?) {
        log("category_locked_tap", params: [
            "category_medium": categoryMedium ?? "",
            "category_large": categoryLarge ?? ""
        ])
    }

    /// アーカイブ画面表示
    func logArchiveView(isPremium: Bool, quoteCount: Int) {
        log("archive_view", params: [
            "is_premium": isPremium ? "true" : "false",
            "quote_count": quoteCount
        ])
    }

    /// お気に入り一覧表示
    func logFavoritesView(favoriteCount: Int) {
        log("favorites_view", params: [
            "favorite_count": favoriteCount
        ])
    }

    /// 設定画面表示
    func logSettingsView(isPremium: Bool) {
        log("settings_view", params: [
            "is_premium": isPremium ? "true" : "false"
        ])
    }

    // ============================================================
    // MARK: 3. エンゲージメントアクション系（8件）
    // ============================================================

    /// お気に入り追加
    func logFavoriteAdd(quoteId: String, author: String, categoryMedium: String, totalFavorites: Int) {
        log("quote_favorite_add", params: [
            "quote_id": quoteId,
            "author": author,
            "category_medium": categoryMedium,
            "total_favorites": totalFavorites
        ])
        log("quote_saved", params: ["quote_id": quoteId, "source": "deck"])
        setUserProperty("\(totalFavorites)", forName: "total_favorites")
    }

    /// お気に入り解除
    func logFavoriteRemove(quoteId: String, author: String, categoryMedium: String, totalFavorites: Int) {
        log("quote_favorite_remove", params: [
            "quote_id": quoteId,
            "author": author,
            "category_medium": categoryMedium,
            "total_favorites": totalFavorites
        ])
        setUserProperty("\(totalFavorites)", forName: "total_favorites")
    }

    /// お気に入り上限ヒット
    func logFavoriteLimitHit(currentCount: Int, limit: Int) {
        log("quote_favorite_limit_hit", params: [
            "current_count": currentCount,
            "limit": limit
        ])
    }

    /// シェア開始
    func logShareInitiate(quoteId: String, author: String, categoryMedium: String, source: String) {
        log("share_initiate", params: [
            "quote_id": quoteId,
            "author": author,
            "category_medium": categoryMedium,
            "source": source
        ])
    }

    /// シェアフォーマット選択
    func logShareFormatSelect(format: String) {
        log("share_format_select", params: [
            "format": format
        ])
    }

    /// シェア完了
    func logShareComplete(quoteId: String, author: String, categoryMedium: String, destination: String, format: String) {
        log("share_complete", params: [
            "quote_id": quoteId,
            "author": author,
            "category_medium": categoryMedium,
            "destination": destination,
            "format": format
        ])
    }

    /// Instagram Stories直接シェア
    func logShareInstagramStories(quoteId: String, author: String, success: Bool) {
        log("share_instagram_stories", params: [
            "quote_id": quoteId,
            "author": author,
            "success": success ? "true" : "false"
        ])
    }

    /// 壁紙変更
    func logWallpaperChange(wallpaperName: String, isPremium: Bool) {
        log("wallpaper_change", params: [
            "wallpaper_name": wallpaperName,
            "is_premium": isPremium ? "true" : "false"
        ])
    }

    /// 名言メモ保存
    func logFavoriteNoteSave(quoteId: String, noteLength: Int, isPremium: Bool) {
        log("quote_favorite_note_save", params: [
            "quote_id": quoteId,
            "note_length": noteLength,
            "is_premium": isPremium ? "true" : "false"
        ])
        log("reflection_note_saved", params: ["quote_id": quoteId, "note_length": noteLength])
    }

    // ============================================================
    // MARK: 4. マネタイズ系（10件）
    // ============================================================

    /// ペイウォール表示
    func logPaywallView(trigger: String) {
        log("paywall_view", params: [
            "trigger": trigger,
            "days_since_install": daysSinceInstall,
            "session_number": sessionCount
        ])
    }

    /// ペイウォール閉じる
    func logPaywallDismiss(trigger: String, timeOnPaywallSec: Int, planViewed: String?) {
        log("paywall_dismiss", params: [
            "trigger": trigger,
            "time_on_paywall_sec": timeOnPaywallSec,
            "plan_viewed": planViewed ?? "none"
        ])
    }

    /// プラン選択
    func logPaywallPlanSelect(planType: String, price: String) {
        log("paywall_plan_select", params: [
            "plan_type": planType,
            "price": price
        ])
    }

    /// 購入開始
    func logPurchaseInitiate(planType: String, price: String, trigger: String) {
        log("purchase_initiate", params: [
            "plan_type": planType,
            "price": price,
            "trigger": trigger
        ])
    }

    /// 購入成功
    func logPurchaseSuccess(planType: String, price: String, trigger: String, totalQuotesViewed: Int, totalFavorites: Int) {
        log("purchase_success", params: [
            "plan_type": planType,
            "price": price,
            "trigger": trigger,
            "days_since_install": daysSinceInstall,
            "total_quotes_viewed": totalQuotesViewed,
            "total_favorites": totalFavorites
        ])
    }

    /// 購入失敗
    func logPurchaseFail(planType: String, errorMessage: String) {
        log("purchase_fail", params: [
            "plan_type": planType,
            "error_message": String(errorMessage.prefix(100))
        ])
    }

    /// 購入復元
    func logPurchaseRestore(success: Bool) {
        log("purchase_restore", params: [
            "success": success ? "true" : "false"
        ])
    }

    /// トライアル開始
    func logTrialStart(planType: String) {
        log("trial_start", params: [
            "plan_type": planType
        ])
    }

    /// トライアルから継続課金への転換（同一ユーザーで一度だけ送る）
    func logTrialConvert(planType: String) {
        log("trial_convert", params: [
            "plan_type": planType,
            "days_since_install": daysSinceInstall
        ])
    }

    func logRetention(day: Int) {
        log("retention_checkpoint", params: ["day": day])
    }

    func logNightWordView() { log("night_word_view") }
    func logNightNoteSave(quoteId: String) { log("night_note_save", params: ["quote_id": quoteId]) }
    func logDailyDrawPresented(timeSlot: String, source: String) {
        log("daily_draw_presented", params: ["time_slot": timeSlot, "source": source, "algorithm_version": "v1"])
    }
    func logDailyDrawRevealed(timeSlot: String, quoteID: String, revealMilliseconds: Int) {
        log("daily_draw_revealed", params: ["time_slot": timeSlot, "quote_id": quoteID, "reveal_ms": revealMilliseconds])
    }
    func logDailyDrawSaved(quoteID: String, timeSlot: String) {
        log("daily_draw_saved", params: ["quote_id": quoteID, "time_slot": timeSlot])
        log("quote_saved", params: ["quote_id": quoteID, "source": "daily_draw", "time_slot": timeSlot])
    }
    func logDailyDrawToDeck(quoteID: String, entryAction: String) {
        log("daily_draw_to_deck", params: ["quote_id": quoteID, "entry_action": entryAction])
    }
    func logDailyDrawSkipped(timeSlot: String, source: String) {
        log("daily_draw_skipped", params: ["time_slot": timeSlot, "source": source])
    }
    func logInsightSuggestionShown(quoteId: String) { log("insight_suggestion_shown", params: ["quote_id": quoteId]) }
    func logInsightSuggestionOpen(quoteId: String) { log("insight_suggestion_opened", params: ["quote_id": quoteId]) }
    func logStreakBroken(days: Int) { log("streak_broken", params: ["days": days]) }
    func logStreakRestore(days: Int) { log("streak_restore", params: ["days": days]) }

    /// トライアルリマインダー表示
    func logTrialReminderShown(daysRemaining: Int) {
        log("trial_reminder_shown", params: [
            "days_remaining": daysRemaining
        ])
    }

    /// 起動時のサブスク状態確認
    func logSubscriptionStatusCheck(isPremium: Bool, planType: String?, daysSincePurchase: Int?) {
        log("subscription_status_check", params: [
            "is_premium": isPremium ? "true" : "false",
            "plan_type": planType ?? "none",
            "days_since_purchase": daysSincePurchase ?? -1
        ])
    }

    // ============================================================
    // MARK: 5. 通知系（4件）
    // ============================================================

    /// 通知スケジュール登録
    func logNotificationSchedule(timeSlotCount: Int, isPremium: Bool, copyVariant: String) {
        log("notification_schedule", params: [
            "time_slot_count": timeSlotCount,
            "is_premium": isPremium ? "true" : "false"
        ])
        log("notification_scheduled_eligible", params: [
            "time_slot_count": timeSlotCount,
            "experiment_id": "notification_copy_v2",
            "variant": copyVariant
        ])
    }

    /// 通知時間変更
    func logNotificationTimeChange(newHour: Int, newMinute: Int, slotType: String) {
        log("notification_time_change", params: [
            "new_hour": newHour,
            "new_minute": newMinute,
            "slot_type": slotType
        ])
    }

    /// 通知ON/OFF切替
    func logNotificationToggle(enabled: Bool) {
        log("notification_toggle", params: [
            "enabled": enabled ? "true" : "false"
        ])
    }

    /// 通知からアプリ起動
    func logNotificationOpen(notificationType: String, copyVariant: String?) {
        var params: [String: Any] = ["notification_type": notificationType]
        if let copyVariant {
            params["experiment_id"] = "notification_copy_v2"
            params["variant"] = copyVariant
        }
        log("notification_opened", params: params)
    }

    func logNotificationExperiment(mode: String, event: String) {
        log("notification_copy_experiment", params: [
            "mode": mode,
            "event": event,
            "experiment_id": "notification_copy_v2",
            "variant": mode
        ])
    }

    func logOnboardingReturnPromiseView() {
        log("onboarding_return_promise_view")
    }

    func logGift(_ event: String, params: [String: Any] = [:]) {
        log(event, params: params)
    }

    // ============================================================
    // MARK: ユーザープロパティ更新
    // ============================================================

    func updatePreferredCategories(_ categories: [String]) {
        setUserProperty(categories.joined(separator: ","), forName: "preferred_categories")
    }
}
