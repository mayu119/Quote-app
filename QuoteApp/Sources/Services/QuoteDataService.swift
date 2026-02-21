import Foundation
import SwiftData

/// 名言データ管理サービス
/// - JSONからの読み込み
/// - SwiftDataへの永続化
/// - ランダム選択（重複排除ロジック付き）
@MainActor
final class QuoteDataService: ObservableObject {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let duplicatePreventionDays: Int = 30 // 30日間は同じ名言を表示しない

    @Published var quotes: [Quote] = []
    @Published var todayQuote: Quote?

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 初期セットアップ：JSONから名言をロードしてSwiftDataに保存
    func loadInitialQuotes() async throws {
        // 既にデータが存在するかチェック
        let descriptor = FetchDescriptor<Quote>()
        let existingQuotes = try modelContext.fetch(descriptor)

        if !existingQuotes.isEmpty {
            print("📚 既存の名言データが存在します: \(existingQuotes.count)件")
            self.quotes = existingQuotes
            return
        }

        // JSONファイルから読み込み
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            throw QuoteError.jsonFileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let loadedQuotes = try decoder.decode([Quote].self, from: data)

        // バリデーション（空文字チェック - 競合の最大弱点を絶対に踏まない）
        let validQuotes = loadedQuotes.filter { $0.isValid }

        if validQuotes.isEmpty {
            throw QuoteError.noValidQuotes
        }

        // SwiftDataに保存
        for quote in validQuotes {
            modelContext.insert(quote)
        }

        try modelContext.save()

        self.quotes = validQuotes
        print("✅ 名言データをロードしました: \(validQuotes.count)件")
    }

    /// 今日の名言を取得（重複排除ロジック付き）
    func getTodayQuote() async throws -> Quote {
        let descriptor = FetchDescriptor<Quote>()
        let allQuotes = try modelContext.fetch(descriptor)

        guard !allQuotes.isEmpty else {
            // フォールバック名言を返す（データ欠損時の保険）
            print("⚠️ 名言データが空です。フォールバック名言を返します。")
            return Quote.fallback
        }

        // 重複排除ロジック：過去N日以内に表示した名言を除外
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -duplicatePreventionDays, to: Date()) ?? Date()

        let availableQuotes = allQuotes.filter { quote in
            if let lastShown = quote.lastShownDate {
                return lastShown < cutoffDate
            }
            return true // まだ一度も表示されていない名言
        }

        let selectedQuote: Quote
        if !availableQuotes.isEmpty {
            selectedQuote = availableQuotes.randomElement()!
        } else {
            // 全ての名言が最近表示済みの場合は、全体からランダム選択
            selectedQuote = allQuotes.randomElement()!
        }

        // 最終表示日時を更新
        selectedQuote.lastShownDate = Date()
        try modelContext.save()

        self.todayQuote = selectedQuote
        return selectedQuote
    }

    /// お気に入りに追加/削除
    func toggleFavorite(quote: Quote) throws {
        quote.isFavorited.toggle()
        try modelContext.save()
    }

    /// お気に入り一覧を取得
    func getFavoriteQuotes() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isFavorited == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// カテゴリ別に名言を取得
    func getQuotes(by category: QuoteCategory) throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// ランダムな名言を取得（ウィジェット用）
    func getRandomQuote() throws -> Quote {
        let descriptor = FetchDescriptor<Quote>()
        let allQuotes = try modelContext.fetch(descriptor)

        guard !allQuotes.isEmpty else {
            return Quote.fallback
        }

        return allQuotes.randomElement() ?? Quote.fallback
    }
}

// MARK: - Errors

enum QuoteError: LocalizedError {
    case jsonFileNotFound
    case noValidQuotes
    case emptyQuoteText

    var errorDescription: String? {
        switch self {
        case .jsonFileNotFound:
            return "名言データファイル（quotes.json）が見つかりません。"
        case .noValidQuotes:
            return "有効な名言データがありません。"
        case .emptyQuoteText:
            return "名言のテキストが空です。"
        }
    }
}
