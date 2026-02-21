import WidgetKit
import SwiftUI
import SwiftData

/// ホーム画面ウィジェット
/// - Small（2×2）/ Medium（4×2）の2種類
/// - 1日1回更新
/// - 短縮版パンチラインを表示
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日の名言")
        .description("毎日新しい名言があなたを待っています")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Entry

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote
}

// MARK: - Widget Quote Model

struct WidgetQuote {
    let punchline: String
    let author: String
    let category: String
    let categoryEmoji: String

    static var placeholder: WidgetQuote {
        WidgetQuote(
            punchline: "考えるな、動け。",
            author: "Unknown",
            category: "覚醒・行動",
            categoryEmoji: "🔥"
        )
    }

    static var fallback: WidgetQuote {
        WidgetQuote(
            punchline: "行動しろ。考えるのはそのあとだ。",
            author: "Unknown",
            category: "覚醒・行動",
            categoryEmoji: "🔥"
        )
    }
}

// MARK: - Timeline Provider

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let entry = QuoteEntry(date: Date(), quote: .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        Task {
            let quote = await fetchTodayQuote()
            let entry = QuoteEntry(date: Date(), quote: quote)

            // 次の更新は翌日の朝6時
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 6
            components.minute = 0

            let nextUpdate = Calendar.current.date(from: components) ?? tomorrow

            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    // MARK: - Fetch Quote

    @MainActor
    private func fetchTodayQuote() async -> WidgetQuote {
        do {
            // SwiftDataコンテナを作成
            let schema = Schema([WidgetQuoteData.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = modelContainer.mainContext

            // ランダムな名言を取得（簡略版）
            let descriptor = FetchDescriptor<WidgetQuoteData>()
            let quotes = try context.fetch(descriptor)

            guard let randomQuote = quotes.randomElement() else {
                return .fallback
            }

            return WidgetQuote(
                punchline: randomQuote.punchline,
                author: randomQuote.author,
                category: randomQuote.categoryDisplay,
                categoryEmoji: randomQuote.categoryEmoji
            )
        } catch {
            print("⚠️ ウィジェット：名言取得エラー: \(error)")
            return .fallback
        }
    }
}

// MARK: - Widget Quote Data (SwiftData Model for Widget)

@Model
final class WidgetQuoteData {
    var id: String
    var punchline: String
    var author: String
    var categoryDisplay: String
    var categoryEmoji: String

    init(id: String, punchline: String, author: String, categoryDisplay: String, categoryEmoji: String) {
        self.id = id
        self.punchline = punchline
        self.author = author
        self.categoryDisplay = categoryDisplay
        self.categoryEmoji = categoryEmoji
    }
}

// MARK: - Widget Entry View

struct QuoteWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: QuoteProvider.Entry

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // コンテンツ
            if family == .systemSmall {
                smallWidgetView
            } else {
                mediumWidgetView
            }
        }
    }

    // MARK: - Small Widget

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // カテゴリバッジ
            Text(entry.quote.categoryEmoji)
                .font(.title3)

            Spacer()

            // パンチライン
            Text(entry.quote.punchline)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundColor(.white)
                .lineLimit(4)
                .minimumScaleFactor(0.7)

            Spacer()

            // 偉人名
            Text("— \(entry.quote.author)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .padding(16)
    }

    // MARK: - Medium Widget

    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            // 左側: 装飾
            VStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(accentGold)
                    .shadow(color: accentGold.opacity(0.5), radius: 8)

                Spacer()

                Text(entry.quote.categoryEmoji)
                    .font(.title)
            }
            .frame(width: 60)

            // 右側: テキスト
            VStack(alignment: .leading, spacing: 12) {
                // パンチライン
                Text(entry.quote.punchline)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)

                Spacer()

                // 偉人名
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(accentGold)
                        .frame(width: 20, height: 2)

                    Text(entry.quote.author.uppercased())
                        .font(.caption)
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: .now, quote: .placeholder)
}

#Preview(as: .systemMedium) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: .now, quote: .placeholder)
}
