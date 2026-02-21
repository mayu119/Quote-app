import SwiftUI
import SwiftData

/// メインコンテンツビュー（シンプル版 - quotes.json読み込みテスト用）
struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query private var quotes: [Quote]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("名言アプリ - テスト版")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("読み込まれた名言数: \(quotes.count)")
                    .font(.title2)
                    .foregroundColor(.blue)

                if let firstQuote = quotes.first {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最初の名言:")
                            .font(.headline)

                        Text(firstQuote.quoteJa)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)

                        Text("- \(firstQuote.author)")
                            .font(.caption)
                            .italic()
                    }
                    .padding()
                }

                List {
                    ForEach(quotes.prefix(10)) { quote in
                        VStack(alignment: .leading) {
                            Text(quote.quoteJa)
                                .font(.body)
                            Text(quote.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("QuoteApp")
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([Quote.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    ContentView()
        .modelContainer(container)
}
