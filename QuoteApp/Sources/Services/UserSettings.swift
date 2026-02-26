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
        didSet { defaults.set(isPremiumUser, forKey: Keys.isPremiumUser) }
    }

    // MARK: - 初回起動

    @Published var isFirstLaunch: Bool {
        didSet { defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch) }
    }

    // MARK: - 閲覧回数制限

    @Published var dailySwipeCount: Int {
        didSet { defaults.set(dailySwipeCount, forKey: Keys.dailySwipeCount) }
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

    // MARK: - 無料カテゴリ日次ローテーション

    /// 無料ユーザーが本日アクセス可能な中カテゴリ（日次で自動更新）
    var currentFreeMediumCategory: QuoteMediumCategory {
        let todayStr = UserSettings.dateString(for: Date())
        if let savedDate = defaults.string(forKey: Keys.freeCategoryDate),
           savedDate == todayStr,
           let rawValue = defaults.string(forKey: Keys.freeCategoryRaw),
           let category = QuoteMediumCategory(rawValue: rawValue) {
            return category
        }
        // 日付が変わった、または未設定: 全40中カテゴリからランダム選択
        let newCategory = QuoteMediumCategory.allCases.randomElement() ?? .awakening
        defaults.set(todayStr, forKey: Keys.freeCategoryDate)
        defaults.set(newCategory.rawValue, forKey: Keys.freeCategoryRaw)
        return newCategory
    }

    // MARK: - Initializer

    init() {
        let notifEnabled = defaults.object(forKey: Keys.notificationEnabled)
        self.notificationEnabled = notifEnabled == nil ? true : defaults.bool(forKey: Keys.notificationEnabled)

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

        self.preferredCategories = defaults.stringArray(forKey: Keys.preferredCategories) ?? []

        if let data = defaults.data(forKey: Keys.categoryAffinityScores),
           let scores = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.categoryAffinityScores = scores
        } else {
            self.categoryAffinityScores = [:]
        }

        let todayStr = UserSettings.dateString(for: Date())
        let savedDate = defaults.string(forKey: Keys.lastSwipeDate) ?? ""
        if savedDate != todayStr {
            self.dailySwipeCount = 0; self.lastSwipeDate = todayStr
            defaults.set(0, forKey: Keys.dailySwipeCount)
            defaults.set(todayStr, forKey: Keys.lastSwipeDate)
        } else {
            self.dailySwipeCount = defaults.integer(forKey: Keys.dailySwipeCount)
            self.lastSwipeDate = savedDate
        }

        self.selectedBackgroundIndex = defaults.integer(forKey: Keys.selectedBackgroundIndex)
        let savedBgs = defaults.stringArray(forKey: Keys.selectedBackgrounds) ?? []
        self.selectedBackgrounds = savedBgs.isEmpty ? Array(BackgroundService.backgrounds.prefix(5)) : savedBgs

        self.showDateHeader = defaults.object(forKey: Keys.showDateHeader) == nil
            ? true : defaults.bool(forKey: Keys.showDateHeader)
    }

    // MARK: - Methods

    func completeFirstLaunch() { isFirstLaunch = false }
    func updatePremiumStatus(isPremium: Bool) { isPremiumUser = isPremium }
    func updateNotificationTime(_ date: Date) { notificationTime = date }
    func toggleNotification() { notificationEnabled.toggle() }

    func incrementSwipeCount() {
        let todayStr = UserSettings.dateString(for: Date())
        if lastSwipeDate != todayStr { dailySwipeCount = 1; lastSwipeDate = todayStr }
        else { dailySwipeCount += 1 }
    }

    // MARK: - Affinity (P-23)

    func recordSave(category: QuoteMediumCategory) {
        categoryAffinityScores[category.rawValue, default: 0] += 1
    }

    func recordArchive(category: QuoteMediumCategory) {
        categoryAffinityScores[category.rawValue, default: 0] -= 1
    }

    // MARK: - Widget Shared Data (P-31)

    func writeQuoteToWidget(_ quote: Quote, backgroundName: String) {
        guard let sharedUD = Self.sharedDefaults else { return }
        var data: [String: Any] = [
            "punchline":   quote.punchline,
            "author":      quote.author,
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

    // MARK: - Premium Notification (P-32)

    func updatePremiumNotificationTime(at index: Int, to date: Date) {
        guard index < premiumNotificationTimes.count else { return }
        premiumNotificationTimes[index] = date
    }

    // MARK: - Private

    private static func dateString(for date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        return f.string(from: date)
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationEnabled      = "notificationEnabled"
        static let notificationTime         = "notificationTime"
        static let premiumNotificationTimes = "premiumNotificationTimes"
        static let isPremiumUser            = "isPremiumUser"
        static let isFirstLaunch            = "isFirstLaunch"
        static let dailySwipeCount          = "dailySwipeCount"
        static let lastSwipeDate            = "lastSwipeDate"
        static let selectedBackgroundIndex  = "selectedBackgroundIndex"
        static let selectedBackgrounds      = "selectedBackgrounds"
        static let showDateHeader           = "showDateHeader"
        static let preferredCategories      = "preferredCategories"
        static let categoryAffinityScores   = "categoryAffinityScores"
        static let freeCategoryDate         = "freeCategoryDate"
        static let freeCategoryRaw          = "freeCategoryRaw"
        static let trialEndDate             = "trialEndDate"
    }
}
