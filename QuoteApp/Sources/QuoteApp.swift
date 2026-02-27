import SwiftUI
import SwiftData
import WidgetKit
import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        print("✅ Firebase initialized.")
        #endif
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsService.shared.logAppBackground()
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
        // Analytics: セッション開始
        AnalyticsService.shared.logSessionStart(isPremium: userSettings.isPremiumUser)

        // Analytics: 初回起動
        if userSettings.isFirstLaunch {
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            AnalyticsService.shared.logFirstOpen(appVersion: appVersion)
        }

        // 通知権限リクエスト
        do {
            let granted = try await NotificationService.shared.requestAuthorization()
            if granted { print("✅ 通知権限が許可されました") }
            AnalyticsService.shared.logNotificationPermission(granted: granted)
        } catch {
            print("⚠️ 通知権限リクエスト失敗: \(error)")
            AnalyticsService.shared.logNotificationPermission(granted: false)
        }
    }
}
