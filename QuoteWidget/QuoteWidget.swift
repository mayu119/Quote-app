import WidgetKit
import SwiftUI

// MARK: - Widget Definition

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日の名言")
        .description("毎日新しい名言があなたを待っています")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Entry

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote
}

// MARK: - Widget Quote Model

struct WidgetQuote {
    let punchline:   String
    let author:      String
    let category:    String
    let categoryJa:  String
    var backgroundImageData: Data? = nil

    static var placeholder: WidgetQuote {
        WidgetQuote(punchline: "考えるな、動け。", author: "Unknown", category: "AWAKENING", categoryJa: "行動覚醒")
    }
    static var fallback: WidgetQuote {
        WidgetQuote(punchline: "行動しろ。考えるのはそのあとだ。", author: "Unknown", category: "AWAKENING", categoryJa: "行動覚醒")
    }
}

// MARK: - Timeline Provider

struct QuoteProvider: TimelineProvider {

    /// App Group 識別子（UserSettings.appGroupID と一致させること）
    private let appGroupID = "group.com.antigravity.QuoteApp"
    private let sharedKey  = "widget_today_quote"

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let quote = context.isPreview ? .placeholder : readSharedQuote()
        completion(QuoteEntry(date: Date(), quote: quote))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let quote = readSharedQuote()
        let entry = QuoteEntry(date: Date(), quote: quote)

        // 翌日朝6時に更新
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 1) + 1
        components.hour = 6; components.minute = 0
        let nextUpdate = Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)

        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Shared UserDefaults

    /// App Group UserDefaults から今日の名言を読む
    /// ※ Xcode の Signing & Capabilities で App Group を追加する必要があります:
    ///   App Target + Widget Target 両方に "group.com.antigravity.QuoteApp" を追加
    private func readSharedQuote() -> WidgetQuote {
        guard let ud   = UserDefaults(suiteName: appGroupID),
              let dict = ud.dictionary(forKey: sharedKey),
              let pl   = dict["punchline"] as? String, !pl.isEmpty,
              let auth = dict["author"] as? String
        else {
            return .fallback
        }
        return WidgetQuote(
            punchline:  pl,
            author:     auth,
            category:   dict["category"] as? String ?? "AWAKENING",
            categoryJa: dict["category_ja"] as? String ?? "行動覚醒",
            backgroundImageData: dict["background_image_data"] as? Data
        )
    }
}

// MARK: - Widget Entry View

struct QuoteWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: QuoteProvider.Entry

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        ZStack {
            if let data = entry.quote.backgroundImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.3), Color.black.opacity(0.7)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            } else {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }

            switch family {
            case .systemSmall:  smallView
            case .systemMedium: mediumView
            case .systemLarge:  largeView
            default:            mediumView
            }
        }
    }

    // MARK: - Small (2×2)

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.quote.categoryJa)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .tracking(2).foregroundColor(accentGold).padding(.bottom, 8)
            Text(entry.quote.punchline)
                .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .lineLimit(5).minimumScaleFactor(0.7)
            Spacer()
            Text("— \(entry.quote.author)")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.5)).lineLimit(1)
        }
        .padding(14)
    }

    // MARK: - Medium (4×2)

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 32, weight: .black)).foregroundColor(accentGold)
                    .shadow(color: accentGold.opacity(0.5), radius: 8)
                Spacer()
                Text(entry.quote.category)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(1).foregroundColor(.white.opacity(0.3))
            }
            .frame(width: 50)
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.quote.punchline)
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .lineLimit(4).minimumScaleFactor(0.7)
                Spacer()
                HStack(spacing: 8) {
                    Rectangle().fill(accentGold).frame(width: 16, height: 1)
                    Text(entry.quote.author.uppercased())
                        .font(.system(size: 10, weight: .bold)).tracking(1.5)
                        .foregroundColor(.white.opacity(0.6)).lineLimit(1)
                }
            }
        }
        .padding(16)
    }

    // MARK: - Large (4×4)

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("ASCENDANCE")
                    .font(.system(size: 9, weight: .black, design: .monospaced)).tracking(4)
                    .foregroundColor(.white.opacity(0.25))
                Spacer()
                Text(entry.quote.categoryJa)
                    .font(.system(size: 9, weight: .black, design: .monospaced)).tracking(2)
                    .foregroundColor(accentGold)
            }
            Spacer()
            Image(systemName: "quote.opening")
                .font(.system(size: 48, weight: .black)).foregroundColor(accentGold.opacity(0.8))
                .shadow(color: accentGold.opacity(0.4), radius: 12)
            Text(entry.quote.punchline)
                .font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                .lineSpacing(8).minimumScaleFactor(0.6)
            Spacer()
            HStack(spacing: 16) {
                Rectangle().fill(Color.white.opacity(0.6)).frame(width: 32, height: 1)
                Text(entry.quote.author.uppercased())
                    .font(.system(size: 12, weight: .black)).tracking(4)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall)  { QuoteWidget() } timeline: { QuoteEntry(date: .now, quote: .placeholder) }
#Preview(as: .systemMedium) { QuoteWidget() } timeline: { QuoteEntry(date: .now, quote: .placeholder) }
#Preview(as: .systemLarge)  { QuoteWidget() } timeline: { QuoteEntry(date: .now, quote: .placeholder) }
