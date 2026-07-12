import Foundation
import SwiftUI

/// ユーザー設定管理
final class UserSettings: ObservableObject {

    // MARK: - App Group (ウィジェット共有)
    static let appGroupID = "group.com.antigravity.QuoteApp"
    static var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    // MARK: - UserDefaults
    private let defaults = UserDefaults.standard

    // MARK: - 通知設定

    @Published var notificationEnabled: Bool {
        didSet { defaults.set(notificationEnabled, forKey: Keys.notificationEnabled) }
    }

    @Published var liveActivityEnabled: Bool {
        didSet { defaults.set(liveActivityEnabled, forKey: Keys.liveActivityEnabled) }
    }

    @Published var notificationTime: Date {
        didSet { defaults.set(notificationTime.timeIntervalSince1970, forKey: Keys.notificationTime) }
    }

    @Published var premiumNotificationTimes: [Date] {
        didSet {
            let intervals = premiumNotificationTimes.map { $0.timeIntervalSince1970 }
            defaults.set(intervals, forKey: Keys.premiumNotificationTimes)
        }
    }

    /// トライアル終了日（RevenueCat から取得）
    @Published var trialEndDate: Date? {
        didSet {
            if let date = trialEndDate {
                defaults.set(date.timeIntervalSince1970, forKey: Keys.trialEndDate)
            } else {
                defaults.removeObject(forKey: Keys.trialEndDate)
            }
        }
    }

    // MARK: - プレミアム

    @Published var isPremiumUser: Bool {
        didSet {
            defaults.set(isPremiumUser, forKey: Keys.isPremiumUser)
            Self.sharedDefaults?.set(isPremiumUser, forKey: "isPremiumUser_shared")
            Self.sharedDefaults?.synchronize()
        }
    }

    // MARK: - 初回起動

    @Published var isFirstLaunch: Bool {
        didSet { defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch) }
    }

    /// 画面操作ガイドを見たかどうか
    @Published var hasSeenInteractionGuide: Bool {
        didSet { defaults.set(hasSeenInteractionGuide, forKey: Keys.hasSeenInteractionGuide) }
    }

    // MARK: - Habit Tracking

    @Published var currentStreakDays: Int {
        didSet {
            defaults.set(currentStreakDays, forKey: Keys.currentStreakDays)
            Self.sharedDefaults?.set(currentStreakDays, forKey: "currentStreakDays_shared")
            Self.sharedDefaults?.synchronize()
        }
    }

    @Published var longestStreakDays: Int {
        didSet { defaults.set(longestStreakDays, forKey: Keys.longestStreakDays) }
    }

    @Published var lastEngagementDate: String {
        didSet {
            defaults.set(lastEngagementDate, forKey: Keys.lastEngagementDate)
            Self.sharedDefaults?.set(lastEngagementDate, forKey: "lastEngagementDate_shared")
            Self.sharedDefaults?.synchronize()
        }
    }

    @Published var lastCheckInDate: String {
        didSet { defaults.set(lastCheckInDate, forKey: Keys.lastCheckInDate) }
    }

    /// 週1回だけ使える休息日の利用週（ストリークを責めないための救済）
    @Published var restDayWeekKey: String {
        didSet { defaults.set(restDayWeekKey, forKey: Keys.restDayWeekKey) }
    }

    /// 切れた直前の連続日数。失われた記録として保持し、翌日の救済案内に使う。
    @Published var lastBrokenStreakDays: Int {
        didSet { defaults.set(lastBrokenStreakDays, forKey: Keys.lastBrokenStreakDays) }
    }

    // MARK: - 閲覧回数制限

    /// 「すべて」表示時のスワイプカウント（上限10回/日）
    @Published var dailySwipeCount: Int {
        didSet { defaults.set(dailySwipeCount, forKey: Keys.dailySwipeCount) }
    }

    /// 日替わり無料カテゴリのスワイプカウント（上限5回/日）
    @Published var dailyFreeCategorySwipeCount: Int {
        didSet { defaults.set(dailyFreeCategorySwipeCount, forKey: Keys.dailyFreeCategorySwipeCount) }
    }

    @Published var lastSwipeDate: String {
        didSet { defaults.set(lastSwipeDate, forKey: Keys.lastSwipeDate) }
    }

    // MARK: - 背景設定

    @Published var selectedBackgroundIndex: Int {
        didSet { defaults.set(selectedBackgroundIndex, forKey: Keys.selectedBackgroundIndex) }
    }

    @Published var selectedBackgrounds: [String] {
        didSet { defaults.set(selectedBackgrounds, forKey: Keys.selectedBackgrounds) }
    }

    // MARK: - 表示設定

    @Published var showDateHeader: Bool {
        didSet { defaults.set(showDateHeader, forKey: Keys.showDateHeader) }
    }
    
    @Published var isVerticalTextMode: Bool {
        didSet { defaults.set(isVerticalTextMode, forKey: Keys.isVerticalTextMode) }
    }

    // MARK: - パーソナライズ

    /// 優先カテゴリ（QuoteLargeCategory の rawValue を格納）
    @Published var preferredCategories: [String] {
        didSet { defaults.set(preferredCategories, forKey: Keys.preferredCategories) }
    }

    @Published var categoryAffinityScores: [String: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(categoryAffinityScores) {
                defaults.set(data, forKey: Keys.categoryAffinityScores)
            }
        }
    }

    @Published var dailyRitualState: DailyRitualState? {
        didSet {
            if let dailyRitualState,
               let data = try? JSONEncoder().encode(dailyRitualState) {
                defaults.set(data, forKey: Keys.dailyRitualState)
            } else {
                defaults.removeObject(forKey: Keys.dailyRitualState)
            }
        }
    }

    @Published var todayWordSelection: TodayWordSelection? {
        didSet {
            if let todayWordSelection,
               let data = try? JSONEncoder().encode(todayWordSelection) {
                defaults.set(data, forKey: Keys.todayWordSelection)
            } else {
                defaults.removeObject(forKey: Keys.todayWordSelection)
            }
        }
    }

    // MARK: - 無料カテゴリ日次ローテーション

    /// 無料ユーザーが本日アクセス可能な中カテゴリ（日次で自動更新・前日と被らない）
    var currentFreeMediumCategory: QuoteMediumCategory {
        let todayStr = UserSettings.dateString(for: Date())
        if let savedDate = defaults.string(forKey: Keys.freeCategoryDate),
           savedDate == todayStr,
           let rawValue = defaults.string(forKey: Keys.freeCategoryRaw),
           let category = QuoteMediumCategory(rawValue: rawValue) {
            return category
        }
        // 前日のカテゴリを取得して除外
        let previousRaw = defaults.string(forKey: Keys.freeCategoryRaw)
        var pool = QuoteMediumCategory.allCases
        if let prevRaw = previousRaw, let prev = QuoteMediumCategory(rawValue: prevRaw) {
            pool = pool.filter { $0 != prev }
        }
        let newCategory = pool.randomElement() ?? .positive
        defaults.set(todayStr, forKey: Keys.freeCategoryDate)
        defaults.set(newCategory.rawValue, forKey: Keys.freeCategoryRaw)
        return newCategory
    }

    // MARK: - Initializer

    init() {
        let notifEnabled = defaults.object(forKey: Keys.notificationEnabled)
        self.notificationEnabled = notifEnabled == nil ? true : defaults.bool(forKey: Keys.notificationEnabled)

        let liveActEnabled = defaults.object(forKey: Keys.liveActivityEnabled)
        self.liveActivityEnabled = liveActEnabled == nil ? true : defaults.bool(forKey: Keys.liveActivityEnabled)

        let storedTime = defaults.double(forKey: Keys.notificationTime)
        if storedTime == 0 {
            var c = DateComponents(); c.hour = 7; c.minute = 0
            self.notificationTime = Calendar.current.date(from: c) ?? Date()
        } else {
            self.notificationTime = Date(timeIntervalSince1970: storedTime)
        }

        let savedIntervals = defaults.array(forKey: Keys.premiumNotificationTimes) as? [Double] ?? []
        if savedIntervals.isEmpty {
            let cal = Calendar.current
            self.premiumNotificationTimes = [
                cal.date(bySettingHour: 7,  minute: 0, second: 0, of: Date()) ?? Date(),
                cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date(),
                cal.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
            ]
        } else {
            self.premiumNotificationTimes = savedIntervals.map { Date(timeIntervalSince1970: $0) }
        }

        self.isPremiumUser = defaults.bool(forKey: Keys.isPremiumUser)

        let trialEndInterval = defaults.double(forKey: Keys.trialEndDate)
        self.trialEndDate = trialEndInterval > 0 ? Date(timeIntervalSince1970: trialEndInterval) : nil

        self.isFirstLaunch = defaults.object(forKey: Keys.isFirstLaunch) == nil
            ? true : defaults.bool(forKey: Keys.isFirstLaunch)
        self.hasSeenInteractionGuide = defaults.object(forKey: Keys.hasSeenInteractionGuide) == nil
            ? false : defaults.bool(forKey: Keys.hasSeenInteractionGuide)
        let currentStreak = max(1, defaults.integer(forKey: Keys.currentStreakDays))
        self.currentStreakDays = currentStreak
        self.longestStreakDays = max(currentStreak, defaults.integer(forKey: Keys.longestStreakDays))
        self.lastEngagementDate = defaults.string(forKey: Keys.lastEngagementDate) ?? ""
        self.lastCheckInDate = defaults.string(forKey: Keys.lastCheckInDate) ?? ""
        self.restDayWeekKey = defaults.string(forKey: Keys.restDayWeekKey) ?? ""
        self.lastBrokenStreakDays = defaults.integer(forKey: Keys.lastBrokenStreakDays)

        self.preferredCategories = defaults.stringArray(forKey: Keys.preferredCategories) ?? []

        if let data = defaults.data(forKey: Keys.categoryAffinityScores),
           let scores = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.categoryAffinityScores = scores
        } else {
            self.categoryAffinityScores = [:]
        }

        if let data = defaults.data(forKey: Keys.dailyRitualState),
           let state = try? JSONDecoder().decode(DailyRitualState.self, from: data) {
            self.dailyRitualState = state
        } else {
            self.dailyRitualState = nil
        }

        if let data = defaults.data(forKey: Keys.todayWordSelection),
           let selection = try? JSONDecoder().decode(TodayWordSelection.self, from: data) {
            self.todayWordSelection = selection
        } else {
            self.todayWordSelection = nil
        }

        let todayStr = UserSettings.dateString(for: Date())
        let savedDate = defaults.string(forKey: Keys.lastSwipeDate) ?? ""
        if savedDate != todayStr {
            self.dailySwipeCount = 0
            self.dailyFreeCategorySwipeCount = 0
            self.lastSwipeDate = todayStr
            defaults.set(0, forKey: Keys.dailySwipeCount)
            defaults.set(0, forKey: Keys.dailyFreeCategorySwipeCount)
            defaults.set(todayStr, forKey: Keys.lastSwipeDate)
        } else {
            self.dailySwipeCount = defaults.integer(forKey: Keys.dailySwipeCount)
            self.dailyFreeCategorySwipeCount = defaults.integer(forKey: Keys.dailyFreeCategorySwipeCount)
            self.lastSwipeDate = savedDate
        }

        self.selectedBackgroundIndex = defaults.integer(forKey: Keys.selectedBackgroundIndex)
        let savedBgs = defaults.stringArray(forKey: Keys.selectedBackgrounds) ?? []
        let validSavedBackgrounds = savedBgs.filter { BackgroundService.backgrounds.contains($0) }
        self.selectedBackgrounds = validSavedBackgrounds.isEmpty
            ? Array(BackgroundService.backgrounds.prefix(5))
            : validSavedBackgrounds

        self.showDateHeader = defaults.object(forKey: Keys.showDateHeader) == nil
            ? true : defaults.bool(forKey: Keys.showDateHeader)
            
        self.isVerticalTextMode = defaults.object(forKey: Keys.isVerticalTextMode) == nil
            ? true : defaults.bool(forKey: Keys.isVerticalTextMode)

        Self.sharedDefaults?.set(isPremiumUser, forKey: "isPremiumUser_shared")
        Self.sharedDefaults?.set(currentStreakDays, forKey: "currentStreakDays_shared")
        Self.sharedDefaults?.set(lastEngagementDate, forKey: "lastEngagementDate_shared")
        Self.sharedDefaults?.synchronize()
    }

    // MARK: - Methods

    func completeFirstLaunch() { isFirstLaunch = false }
    func markInteractionGuideSeen() { hasSeenInteractionGuide = true }
    func updatePremiumStatus(isPremium: Bool) { isPremiumUser = isPremium }
    func updateNotificationTime(_ date: Date) { notificationTime = date }
    func toggleNotification() { notificationEnabled.toggle() }
    func toggleLiveActivity() { liveActivityEnabled.toggle() }

    func refreshDailyEngagement() {
        let today = Date()
        let todayStr = Self.dateString(for: today)

        guard lastEngagementDate != todayStr else { return }

        let calendar = Calendar.current
        let previousDate = Self.date(from: lastEngagementDate)

        let elapsedDays = previousDate.map {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0), to: calendar.startOfDay(for: today)).day ?? 0
        } ?? 0
        let weekKey = Self.weekKey(for: today)

        if elapsedDays == 1 {
            currentStreakDays += 1
        } else if elapsedDays == 2, restDayWeekKey != weekKey {
            // 週1回の休息日は、空白を「失敗」にしない。
            currentStreakDays += 1
            restDayWeekKey = weekKey
        } else {
            if !lastEngagementDate.isEmpty, currentStreakDays > 1 {
                lastBrokenStreakDays = currentStreakDays
                AnalyticsService.shared.logStreakBroken(days: currentStreakDays)
            }
            currentStreakDays = 1
        }

        longestStreakDays = max(longestStreakDays, currentStreakDays)
        lastEngagementDate = todayStr
    }

    /// 途切れた翌日にだけ提供する救済。過去の最長記録はこの操作をしなくても残る。
    @discardableResult
    func restoreBrokenStreakIfAvailable(isPremium: Bool) -> Bool {
        guard isPremium, lastBrokenStreakDays > 0 else { return false }
        currentStreakDays = max(currentStreakDays, lastBrokenStreakDays + 1)
        longestStreakDays = max(longestStreakDays, currentStreakDays)
        AnalyticsService.shared.logStreakRestore(days: lastBrokenStreakDays)
        lastBrokenStreakDays = 0
        return true
    }

    func shouldPresentDailyCheckIn(on date: Date = Date()) -> Bool {
        lastCheckInDate != Self.dateString(for: date)
    }

    func markDailyCheckInPresented(on date: Date = Date()) {
        lastCheckInDate = Self.dateString(for: date)
    }

    func saveDailyRitual(bundle: SpiritualBundle, on date: Date = Date()) {
        dailyRitualState = DailyRitualState(
            bundleRawValue: bundle.rawValue,
            intention: bundle.shortPrompt,
            release: bundle.ritualReleasePrompt,
            action: bundle.ritualActionPrompt,
            dateString: Self.dateString(for: date)
        )
    }

    func clearExpiredDailyRitualIfNeeded(on date: Date = Date()) {
        guard let dailyRitualState else { return }
        if dailyRitualState.dateString != Self.dateString(for: date) {
            self.dailyRitualState = nil
        }
    }

    func saveTodayWord(_ quote: Quote, backgroundName: String, on date: Date = Date()) {
        todayWordSelection = TodayWordSelection(
            quoteID: quote.id,
            quoteText: quote.quoteJa,
            punchline: quote.punchline,
            author: quote.displayAuthor,
            categoryJa: quote.category.displayTitleJa,
            backgroundName: backgroundName,
            dateString: Self.dateString(for: date)
        )
    }

    func clearTodayWord() {
        todayWordSelection = nil
    }

    func clearExpiredTodayWordIfNeeded(on date: Date = Date()) {
        guard let todayWordSelection else { return }
        if todayWordSelection.dateString != Self.dateString(for: date) {
            self.todayWordSelection = nil
        }
    }

    /// 「すべて」表示時のスワイプカウント増加
    func incrementSwipeCount() {
        let todayStr = UserSettings.dateString(for: Date())
        if lastSwipeDate != todayStr { dailySwipeCount = 1; dailyFreeCategorySwipeCount = 0; lastSwipeDate = todayStr }
        else { dailySwipeCount += 1 }
    }

    /// 日替わり無料カテゴリのスワイプカウント増加
    func incrementFreeCategorySwipeCount() {
        let todayStr = UserSettings.dateString(for: Date())
        if lastSwipeDate != todayStr { dailyFreeCategorySwipeCount = 1; dailySwipeCount = 0; lastSwipeDate = todayStr }
        else { dailyFreeCategorySwipeCount += 1 }
    }

    // MARK: - Affinity (P-23)

    func recordSave(category: QuoteMediumCategory) {
        categoryAffinityScores[category.rawValue, default: 0] += 1
    }

    func recordArchive(category: QuoteMediumCategory) {
        categoryAffinityScores[category.rawValue, default: 0] -= 1
    }

    // MARK: - Widget Shared Data (P-31)

    func seedWidgetFallbackIfNeeded() {
        guard let sharedUD = Self.sharedDefaults else { return }
        if sharedUD.dictionary(forKey: "widget_today_quote") != nil {
            return
        }

        let data: [String: Any] = [
            "punchline": "焦る日ほど、呼吸が戻る言葉をひとつ。",
            "author": "WORDS FOR ME",
            "category": "DAILY WORD",
            "category_ja": "今日の言葉"
        ]
        sharedUD.set(data, forKey: "widget_today_quote")
        sharedUD.synchronize()
    }

    func writeQuoteToWidget(_ quote: Quote, backgroundName: String) {
        guard let sharedUD = Self.sharedDefaults else { return }
        var data: [String: Any] = [
            "punchline":   quote.punchline,
            "author":      quote.displayAuthor,
            "category":    quote.category.displayText,
            "category_ja": quote.category.displayTitleJa,
            "id":          quote.id
        ]
        
        if let image = UIImage(named: backgroundName),
           let imageData = image.jpegData(compressionQuality: 0.5) {
            data["background_image_data"] = imageData
        }
        
        sharedUD.set(data, forKey: "widget_today_quote")
        sharedUD.synchronize()
    }

    func writeTodayWordToWidget(_ selection: TodayWordSelection) {
        guard let sharedUD = Self.sharedDefaults else { return }
        var data: [String: Any] = [
            "punchline": selection.punchline,
            "author": selection.author,
            "category": "TODAY'S WORD",
            "category_ja": "今日の私の言葉",
            "id": selection.quoteID
        ]

        if let image = UIImage(named: selection.backgroundName),
           let imageData = image.jpegData(compressionQuality: 0.5) {
            data["background_image_data"] = imageData
        }

        sharedUD.set(data, forKey: "widget_today_quote")
        sharedUD.synchronize()
    }

    func syncWidgetQuote(defaultQuote quote: Quote, backgroundName: String) {
        if let todayWordSelection {
            writeTodayWordToWidget(todayWordSelection)
        } else {
            writeQuoteToWidget(quote, backgroundName: backgroundName)
        }
    }

    // MARK: - Premium Notification (P-32)

    func updatePremiumNotificationTime(at index: Int, to date: Date) {
        guard index < premiumNotificationTimes.count else { return }
        premiumNotificationTimes[index] = date
    }

    // MARK: - Private

    static func dateString(for date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        return f.string(from: date)
    }

    private static func weekKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
    }

    private static func date(from string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.date(from: string)
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationEnabled      = "notificationEnabled"
        static let liveActivityEnabled      = "liveActivityEnabled"
        static let notificationTime         = "notificationTime"
        static let premiumNotificationTimes = "premiumNotificationTimes"
        static let isPremiumUser            = "isPremiumUser"
        static let isFirstLaunch            = "isFirstLaunch"
        static let currentStreakDays        = "currentStreakDays"
        static let longestStreakDays        = "longestStreakDays"
        static let lastEngagementDate       = "lastEngagementDate"
        static let lastCheckInDate          = "lastCheckInDate"
        static let restDayWeekKey           = "restDayWeekKey"
        static let lastBrokenStreakDays     = "lastBrokenStreakDays"
        static let hasSeenInteractionGuide  = "hasSeenInteractionGuide"
        static let dailySwipeCount              = "dailySwipeCount"
        static let dailyFreeCategorySwipeCount   = "dailyFreeCategorySwipeCount"
        static let lastSwipeDate                = "lastSwipeDate"
        static let selectedBackgroundIndex      = "selectedBackgroundIndex"
        static let selectedBackgrounds          = "selectedBackgrounds"
        static let showDateHeader               = "showDateHeader"
        static let preferredCategories          = "preferredCategories"
        static let categoryAffinityScores       = "categoryAffinityScores"
        static let freeCategoryDate             = "freeCategoryDate"
        static let freeCategoryRaw              = "freeCategoryRaw"
        static let trialEndDate                 = "trialEndDate"
        static let isVerticalTextMode           = "isVerticalTextMode"
        static let dailyRitualState             = "dailyRitualState"
        static let todayWordSelection           = "todayWordSelection"
    }
}
