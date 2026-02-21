import Foundation
import SwiftUI

/// ユーザー設定管理
/// - 通知設定（ON/OFF、時間）
/// - プレミアムステータス
/// - その他のアプリ設定
final class UserSettings: ObservableObject {
    // MARK: - Properties

    private let defaults = UserDefaults.standard

    // MARK: - 通知設定

    /// 通知が有効かどうか
    @Published var notificationEnabled: Bool {
        didSet {
            defaults.set(notificationEnabled, forKey: Keys.notificationEnabled)
        }
    }

    /// 通知時間（デフォルト: 朝7:00）
    @Published var notificationTime: Date {
        didSet {
            defaults.set(notificationTime.timeIntervalSince1970, forKey: Keys.notificationTime)
        }
    }

    // MARK: - プレミアム設定

    /// プレミアムユーザーかどうか
    @Published var isPremiumUser: Bool {
        didSet {
            defaults.set(isPremiumUser, forKey: Keys.isPremiumUser)
        }
    }

    // MARK: - アプリ初回起動

    /// アプリが初回起動かどうか
    @Published var isFirstLaunch: Bool {
        didSet {
            defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch)
        }
    }

    // MARK: - Initializer

    init() {
        // 通知設定
        self.notificationEnabled = defaults.bool(forKey: Keys.notificationEnabled)
        if defaults.object(forKey: Keys.notificationEnabled) == nil {
            self.notificationEnabled = true // デフォルトはON
        }

        // 通知時間（デフォルト: 朝7:00）
        let storedTime = defaults.double(forKey: Keys.notificationTime)
        if storedTime == 0 {
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            self.notificationTime = Calendar.current.date(from: components) ?? Date()
        } else {
            self.notificationTime = Date(timeIntervalSince1970: storedTime)
        }

        // プレミアム設定
        self.isPremiumUser = defaults.bool(forKey: Keys.isPremiumUser)

        // 初回起動
        self.isFirstLaunch = defaults.object(forKey: Keys.isFirstLaunch) == nil ? true : defaults.bool(forKey: Keys.isFirstLaunch)
    }

    // MARK: - Methods

    /// 初回起動フラグを完了にする
    func completeFirstLaunch() {
        isFirstLaunch = false
    }

    /// プレミアムステータスを更新
    func updatePremiumStatus(isPremium: Bool) {
        isPremiumUser = isPremium
    }

    /// 通知時間を更新
    func updateNotificationTime(_ date: Date) {
        notificationTime = date
    }

    /// 通知ON/OFFを切り替え
    func toggleNotification() {
        notificationEnabled.toggle()
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let notificationEnabled = "notificationEnabled"
        static let notificationTime = "notificationTime"
        static let isPremiumUser = "isPremiumUser"
        static let isFirstLaunch = "isFirstLaunch"
    }
}
