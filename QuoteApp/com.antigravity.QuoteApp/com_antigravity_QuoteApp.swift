import WidgetKit
import SwiftUI

struct QuoteWidget: Widget {
    let kind = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    QuoteWidgetBackground(accent: entry.accentColor)
                }
        }
        .configurationDisplayName("今日の言葉")
        .description("ホーム画面で、やさしく言葉を受け取れます。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let punchline: String
    let author: String
    let categoryJa: String
    let accentColor: Color
    let streakDays: Int
    let checkedInToday: Bool
}

struct QuoteProvider: TimelineProvider {
    private let appGroupID = "group.com.antigravity.QuoteApp"

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(
            date: Date(),
            punchline: "今日は、やさしいほうを選んでいい。",
            author: "Words For Me",
            categoryJa: "今日の言葉",
            accentColor: QuotePalette.accent(for: "今日の言葉"),
            streakDays: 1,
            checkedInToday: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> QuoteEntry {
        if let shared = loadFromPools() {
            return shared
        }

        if let shared = loadFromSharedDefaults() {
            return shared
        }

        return QuoteEntry(
            date: Date(),
            punchline: "今日は、やさしいほうを選んでいい。",
            author: "Words For Me",
            categoryJa: "今日の言葉",
            accentColor: QuotePalette.accent(for: "今日の言葉"),
            streakDays: 1,
            checkedInToday: true
        )
    }

    private func loadFromPools() -> QuoteEntry? {
        guard
            let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID),
            let data = try? Data(contentsOf: sharedURL.appendingPathComponent("widget_pools.json")),
            let pools = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: String]]],
            let pool = pools["random"],
            !pool.isEmpty
        else {
            return nil
        }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let item = pool[day % pool.count]
        let categoryJa = item["category_ja"] ?? "今日の言葉"
        let sharedDefaults = UserDefaults(suiteName: appGroupID)

        return QuoteEntry(
            date: Date(),
            punchline: item["punchline"] ?? "今日は、やさしいほうを選んでいい。",
            author: item["author"] ?? "Words For Me",
            categoryJa: categoryJa,
            accentColor: QuotePalette.accent(for: categoryJa),
            streakDays: max(1, sharedDefaults?.integer(forKey: "currentStreakDays_shared") ?? 1),
            checkedInToday: (sharedDefaults?.string(forKey: "lastEngagementDate_shared") ?? "") == Self.todayString()
        )
    }

    private func loadFromSharedDefaults() -> QuoteEntry? {
        guard
            let sharedDefaults = UserDefaults(suiteName: appGroupID),
            let dict = sharedDefaults.dictionary(forKey: "widget_today_quote"),
            let punchline = dict["punchline"] as? String,
            !punchline.isEmpty
        else {
            return nil
        }

        let categoryJa = dict["category_ja"] as? String ?? "今日の言葉"
        let streakDays = max(1, sharedDefaults.integer(forKey: "currentStreakDays_shared"))
        let checkedInToday = (sharedDefaults.string(forKey: "lastEngagementDate_shared") ?? "") == Self.todayString()

        return QuoteEntry(
            date: Date(),
            punchline: punchline,
            author: dict["author"] as? String ?? "Words For Me",
            categoryJa: categoryJa,
            accentColor: QuotePalette.accent(for: categoryJa),
            streakDays: streakDays,
            checkedInToday: checkedInToday
        )
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }
}

private struct QuoteWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteEntry

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月"
        return formatter.string(from: entry.date)
    }

    private var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date)
    }

    private var weeklyLoginCount: Int {
        min(7, max(0, entry.streakDays))
    }

    private var displayedPunchline: String {
        switch family {
        case .systemSmall:
            return QuoteTextFormatter.condensed(entry.punchline, maxCharacters: 48)
        case .systemMedium:
            return QuoteTextFormatter.condensed(entry.punchline, maxCharacters: 58)
        case .systemLarge:
            return QuoteTextFormatter.condensed(entry.punchline, maxCharacters: 110)
        default:
            return QuoteTextFormatter.condensed(entry.punchline, maxCharacters: 58)
        }
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallLayout
        case .systemMedium:
            mediumLayout
        case .systemLarge:
            largeLayout
        default:
            mediumLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            categoryPill
            Text(displayedPunchline)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(QuotePalette.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            authorRow
        }
        .padding(16)
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                categoryPill
                Text(displayedPunchline)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(QuotePalette.ink)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                authorRow
            }

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(entry.accentColor.opacity(0.18))
                .overlay {
                    VStack(spacing: 10) {
                        Circle()
                            .fill(entry.accentColor.opacity(0.9))
                            .frame(width: 54, height: 54)
                            .overlay(
                                Image(systemName: "quote.bubble.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        Text("Words For Me")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(QuotePalette.subtle)
                    }
                }
                .frame(width: 92)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("連続")
                                .font(.system(size: 22, weight: .bold))
                            Text("\(entry.streakDays)日")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(QuotePalette.ink)

                        Text("今週 \(weeklyLoginCount)/7日ログイン")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(QuotePalette.subtle)
                    }

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            Circle()
                                .fill(index < weeklyLoginCount ? Color(hex: "DEB15A") : Color(hex: "E9E2DB"))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                VStack(spacing: 4) {
                    Text(monthLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "D9AE58"))

                    Text(dayNumber)
                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                        .foregroundStyle(QuotePalette.ink)

                    Text(weekdayLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(QuotePalette.ink)
                        .padding(.bottom, 10)
                }
                .frame(width: 140)
                .background(Color.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 18) {
                Text(displayedPunchline)
                    .font(.system(size: 33, weight: .bold))
                    .foregroundStyle(QuotePalette.ink)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 10) {
                        Capsule()
                            .fill(Color(hex: "D9AE58"))
                            .frame(width: 28, height: 4)
                        Text(localizedAuthor)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(QuotePalette.ink)
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 0)
        }
        .padding(28)
        .background(Color.white.opacity(0.62))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
    }

    private var categoryPill: some View {
        Text(entry.categoryJa)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(entry.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.78))
            .clipShape(Capsule())
    }

    private var authorRow: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(entry.accentColor)
                .frame(width: 18, height: 3)
            Text(localizedAuthor)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(QuotePalette.subtle)
                .lineLimit(1)
        }
    }

    private var localizedAuthor: String {
        let normalizedAuthor = entry.author
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if ["original", "オリジナル", "アプリオリジナル"].contains(normalizedAuthor) {
            return "Words For Me"
        }

        let mappings: [String: String] = [
            "Marcus Aurelius": "マルクス・アウレリウス",
            "Barbara Bush": "バーバラ・ブッシュ",
            "Oprah Winfrey": "オプラ・ウィンフリー"
        ]
        if let mapped = mappings[entry.author] {
            return mapped
        }

        guard entry.author.unicodeScalars.allSatisfy(\.isASCII) else {
            return entry.author
        }

        let mutable = NSMutableString(string: entry.author) as CFMutableString
        if CFStringTransform(mutable, nil, "Latin-Katakana" as CFString, false) {
            return mutable as String
        }

        return entry.author
    }
}

private struct QuoteWidgetBackground: View {
    let accent: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FBF6F1"), Color(hex: "F1E7DE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 180, height: 180)
                .offset(x: 72, y: -72)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white.opacity(0.34))
                .blur(radius: 10)
                .padding(8)
        }
    }
}

private enum QuotePalette {
    static let ink = Color(hex: "2F2730")
    static let subtle = Color(hex: "776B78")

    static func accent(for category: String) -> Color {
        if category.contains("愛") || category.contains("大切") || category.contains("好き") {
            return Color(hex: "E59B9D")
        }
        if category.contains("整") || category.contains("自己") {
            return Color(hex: "8E94B8")
        }
        if category.contains("立て直") || category.contains("辞め") || category.contains("疲") {
            return Color(hex: "D7AE68")
        }
        return Color(hex: "B38CC8")
    }
}

private enum QuoteTextFormatter {
    static func condensed(_ text: String, maxCharacters: Int) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.count > maxCharacters else { return normalized }

        let sentences = normalized.split(whereSeparator: { "。.!?！？".contains($0) })
        if let first = sentences.first, !first.isEmpty, first.count <= maxCharacters {
            return first.trimmingCharacters(in: .whitespacesAndNewlines) + "。"
        }

        let shortened = String(normalized.prefix(maxCharacters))
        if let lastPause = shortened.lastIndex(where: { "、。,.!?！？ ".contains($0) }) {
            let candidate = shortened[..<lastPause].trimmingCharacters(in: .whitespacesAndNewlines)
            if candidate.count >= maxCharacters / 2 {
                return candidate + "…"
            }
        }

        return shortened.trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
