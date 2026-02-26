import SwiftUI
import SwiftData
import WidgetKit

@main
struct QuoteApp: App {

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
        // 通知権限リクエストのみ（スケジュールは ContentView で名言データ取得後に実行）
        do {
            let granted = try await NotificationService.shared.requestAuthorization()
            if granted { print("✅ 通知権限が許可されました") }
        } catch {
            print("⚠️ 通知権限リクエスト失敗: \(error)")
        }
    }
}
