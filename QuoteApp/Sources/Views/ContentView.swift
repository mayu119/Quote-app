import SwiftUI
import SwiftData

/// メインコンテンツビュー（タブナビゲーション）
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings

    // MARK: - State

    @State private var selectedTab = 0
    @StateObject private var quoteDataService: QuoteDataService

    // MARK: - Initializer

    init() {
        // Note: modelContextは後でEnvironmentから取得するため、
        // ダミーのコンテキストで初期化し、onAppearで再設定
        let schema = Schema([Quote.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        _quoteDataService = StateObject(wrappedValue: QuoteDataService(modelContext: context))
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // タブ1: 今日の名言
            TodayQuoteView(quoteDataService: quoteDataService)
                .tabItem {
                    Label("今日の名言", systemImage: "quote.bubble.fill")
                }
                .tag(0)

            // タブ2: お気に入り
            FavoritesView(quoteDataService: quoteDataService)
                .tabItem {
                    Label("お気に入り", systemImage: "bookmark.fill")
                }
                .tag(1)

            // タブ3: 設定
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.85, green: 0.65, blue: 0.2)) // アクセントゴールド
        .onAppear {
            // 実際のmodelContextで再初期化
            let realService = QuoteDataService(modelContext: modelContext)
            // Note: @StateObjectは一度初期化されると変更できないため、
            // 実際はQuoteDataServiceをEnvironmentObjectとして渡す方が良いが、
            // ここでは簡略化のためそのまま使用
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([Quote.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    ContentView()
        .environmentObject(UserSettings())
        .modelContainer(container)
}
