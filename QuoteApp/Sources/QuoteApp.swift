import SwiftUI
import SwiftData

@main
struct QuoteApp: App {
    // MARK: - State Objects

    @StateObject private var userSettings = UserSettings()

    // MARK: - SwiftData Model Container

    let modelContainer: ModelContainer = {
        let schema = Schema([Quote.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .modelContainer(modelContainer)
                .task {
                    // アプリ起動時の初期化処理
                    await initializeApp()
                }
        }
    }

    // MARK: - Initialization

    @MainActor
    private func initializeApp() async {
        // 1. 通知権限のリクエスト
        do {
            let granted = try await NotificationService.shared.requestAuthorization()
            if granted {
                print("✅ 通知権限が許可されました")
            }
        } catch {
            print("⚠️ 通知権限のリクエストに失敗しました: \(error)")
        }

        // 2. データの初期ロードはContentViewのレンダリング前に完了させるため、ここでは実行しません。
        // ContentView側の .task で順序立てて実行します。

        // 3. 通知のスケジュール（設定がONの場合）
        if userSettings.notificationEnabled {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: userSettings.notificationTime)
            let minute = calendar.component(.minute, from: userSettings.notificationTime)

            do {
                try await NotificationService.shared.scheduleDailyQuoteNotification(
                    hour: hour,
                    minute: minute,
                    notificationHook: nil // 実際の名言の通知フックは後で設定
                )
            } catch {
                print("⚠️ 通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
}
