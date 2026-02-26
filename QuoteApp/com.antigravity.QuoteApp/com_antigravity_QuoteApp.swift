import WidgetKit
import SwiftUI

// MARK: - Widget Definition

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        if let data = entry.quote.backgroundImageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .overlay(Color.black.opacity(0.65))
                        } else {
                            Color(red: 0.05, green: 0.05, blue: 0.07)
                        }
                        
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    }
                }
        }
        .contentMarginsDisabled()
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
    let backgroundImageData: Data?

    static var placeholder: WidgetQuote {
        WidgetQuote(punchline: "考えるな、動け。", author: "Unknown", category: "AWAKENING", categoryJa: "行動覚醒", backgroundImageData: nil)
    }
    static var fallback: WidgetQuote {
        WidgetQuote(punchline: "行動しろ。考えるのはそのあとだ。", author: "Unknown", category: "AWAKENING", categoryJa: "行動覚醒", backgroundImageData: nil)
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

    // メインアプリに合わせた高級感のあるアクセント（淡いゴールドや白に近いグレー）
    let accentGold = Color(red: 0.85, green: 0.75, blue: 0.45)

    var body: some View {
        Group {
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
        VStack(alignment: .center, spacing: 0) {
            // カテゴリ（上部）
            Text(entry.quote.category)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(accentGold.opacity(0.8))
                .padding(.bottom, 6)
            
            Rectangle()
                .fill(accentGold)
                .frame(width: 20, height: 1)

            Spacer()

            // 名言
            Text(entry.quote.punchline)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .lineLimit(4)
                .minimumScaleFactor(0.8)

            Spacer()

            // 著者（下部）
            Text(entry.quote.author.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Medium (4×2)

    private var mediumView: some View {
        VStack(alignment: .center, spacing: 0) {
            // カテゴリヘッダー
            Text(entry.quote.category)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(3)
                .foregroundColor(accentGold.opacity(0.8))
                .padding(.bottom, 6)
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 1)

            Spacer()

            // 名言本文（上下のSpacerにより表示領域のど真ん中に配置される）
            Text(entry.quote.punchline)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Spacer()

            // フッター（著者）
            Text(entry.quote.author.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Large (4×4)

    private var largeView: some View {
        VStack(alignment: .center, spacing: 0) {
            // トップヘッダー
            Text("DAILY INSPIRATION")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(4)
                .foregroundColor(.white.opacity(0.4))
                .padding(.bottom, 6)
                
            Text(entry.quote.category)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(accentGold.opacity(0.8))
                .padding(.bottom, 12)
                
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 60, height: 1)

            Spacer()

            // メインコピー（名言）
            Text(entry.quote.punchline)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .lineLimit(6)
                .minimumScaleFactor(0.7)

            Spacer()

            // ボトムライン（著者）
            VStack(spacing: 12) {
                Rectangle()
                    .fill(accentGold)
                    .frame(width: 32, height: 2)
                
                Text(entry.quote.author.uppercased())
                    .font(.system(size: 16, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall)  { QuoteWidget() } timeline: { QuoteEntry(date: .now, quote: .placeholder) }
#Preview(as: .systemMedium) { QuoteWidget() } timeline: { QuoteEntry(date: .now, quote: .placeholder) }
#Preview(as: .systemLarge)  { QuoteWidget() } timeline: { QuoteEntry(date: .now, quote: .placeholder) }
