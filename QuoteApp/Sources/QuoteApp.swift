import SwiftUI
import SwiftData
import WidgetKit
import UIKit
import UserNotifications
import RevenueCat

#if canImport(FirebaseCore)
import FirebaseCore
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    private func clearBadgeAndDeliveredNotifications(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()

        // iOS 16+ は通知センター経由でバッジを明示的に 0 に戻す
        if #available(iOS 16.0, *) {
            center.setBadgeCount(0)
        } else {
            application.applicationIconBadgeNumber = 0
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        print("✅ Firebase initialized.")
        #endif
        clearBadgeAndDeliveredNotifications(application)
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsService.shared.logAppBackground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // アクティブ化のたびに、残っているバッジと配信済み通知を消す
        clearBadgeAndDeliveredNotifications(application)
    }
}

@main
struct QuoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var userSettings = UserSettings()

    let modelContainer: ModelContainer = {
        let schema = Schema([Quote.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("🚨 ModelContainer initialize error: \(error)")
            // スキーマ変更などでエラーになった場合、古いデータベースを削除して作り直す（開発中のクラッシュ防止）
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            // shm や wal ファイルも一緒に消しておくとなお確実です
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-wal"))
            
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer even after deletion: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .modelContainer(modelContainer)
                .task { await initializeApp() }
        }
    }

    // MARK: - Initialization

    @MainActor
    private func initializeApp() async {
        userSettings.seedWidgetFallbackIfNeeded()
        WidgetCenter.shared.reloadAllTimelines()

        // RevenueCat 初期化
        RevenueCatManager.shared.configure(apiKey: Config.revenueCatAPIKey)
        await RevenueCatManager.shared.checkSubscriptionStatus()
        await RevenueCatManager.shared.fetchOfferings()

        // RevenueCat のプレミアム状態を UserSettings に同期
        userSettings.updatePremiumStatus(isPremium: RevenueCatManager.shared.isPremiumUser)

        // Analytics: セッション開始
        AnalyticsService.shared.logSessionStart(isPremium: userSettings.isPremiumUser)

        // Analytics: 初回起動
        if userSettings.isFirstLaunch {
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            AnalyticsService.shared.logFirstOpen(appVersion: appVersion)
        }
    }
}
