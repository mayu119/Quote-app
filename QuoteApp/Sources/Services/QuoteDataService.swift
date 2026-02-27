import Foundation
import SwiftData

/// 名言データ管理サービス
@MainActor
final class QuoteDataService: ObservableObject {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let duplicatePreventionDays: Int = 30

    /// JSONデータを更新したらこの値をインクリメントする
    /// v11: 著者1002人達成・2017件
    private static let currentDataVersion: Int = 11
    private static let dataVersionKey = "quotesDataVersion"

    @Published var quotes: [Quote] = []
    @Published var todayQuote: Quote?

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 初期セットアップ: JSONからロード → SwiftDataに保存
    /// バージョンアップ時はお気に入りを保護しつつフルリフレッシュ
    func loadInitialQuotes() async throws {
        let descriptor = FetchDescriptor<Quote>()
        let existingQuotes = try modelContext.fetch(descriptor)
        let savedVersion = UserDefaults.standard.integer(forKey: Self.dataVersionKey)

        // 重いJSONパースをバックグラウンドスレッドで実行（メインスレッドブロック防止）
        let validQuotes = try await Self.parseQuotesJSON()

        guard !validQuotes.isEmpty else { throw QuoteError.noValidQuotes }

        if existingQuotes.isEmpty {
            // 初回ロード: 全件挿入
            for q in validQuotes { modelContext.insert(q) }
            print("✅ 名言データをロードしました: \(validQuotes.count)件")

        } else if savedVersion < Self.currentDataVersion {
            // バージョンアップ: お気に入りIDを保護してフルリフレッシュ
            let favoritedIds = Set(existingQuotes.filter { $0.isFavorited }.map { $0.id })
            let lastShownMap = Dictionary(uniqueKeysWithValues:
                existingQuotes.compactMap { q -> (String, Date)? in
                    guard let d = q.lastShownDate else { return nil }
                    return (q.id, d)
                }
            )
            for q in existingQuotes { modelContext.delete(q) }
            for q in validQuotes {
                if favoritedIds.contains(q.id) { q.isFavorited = true }
                if let d = lastShownMap[q.id]   { q.lastShownDate = d }
                modelContext.insert(q)
            }
            print("✅ 名言データをv\(Self.currentDataVersion)に更新しました: \(validQuotes.count)件")

        } else {
            // 最新バージョン: 差分のみ追加
            let existingIds = Set(existingQuotes.map { $0.id })
            let newQuotes = validQuotes.filter { !existingIds.contains($0.id) }
            for q in newQuotes { modelContext.insert(q) }
            if !newQuotes.isEmpty {
                print("✅ 名言データに+\(newQuotes.count)件追加しました")
            }
        }

        try modelContext.save()
        UserDefaults.standard.set(Self.currentDataVersion, forKey: Self.dataVersionKey)
        self.quotes = try modelContext.fetch(descriptor)
    }

    /// JSONパースをバックグラウンドスレッドで実行（メインスレッドブロック防止）
    private nonisolated static func parseQuotesJSON() async throws -> [Quote] {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            throw QuoteError.jsonFileNotFound
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let loadedQuotes = try decoder.decode([Quote].self, from: data)
        return loadedQuotes.filter { $0.isValid }
    }

    /// 今日の名言を取得（重複排除ロジック付き）
    func getTodayQuote() async throws -> Quote {
        let descriptor = FetchDescriptor<Quote>()
        let allQuotes = try modelContext.fetch(descriptor)
        guard !allQuotes.isEmpty else { return Quote.fallback }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -duplicatePreventionDays, to: Date()) ?? Date()
        let available = allQuotes.filter { q in
            guard let last = q.lastShownDate else { return true }
            return last < cutoffDate
        }
        let selected = available.isEmpty ? allQuotes.randomElement()! : available.randomElement()!
        selected.lastShownDate = Date()
        try modelContext.save()
        self.todayQuote = selected
        return selected
    }

    /// 複数の名言を取得（アフィニティスコア反映済み）
    /// - Parameters:
    ///   - mediumCategory: 中カテゴリフィルタ（nilで全体）
    ///   - largeCategory:  大カテゴリフィルタ（mediumCategoryがnilの時のみ有効）
    func getDailyQuotes(
        limit: Int,
        isPremium: Bool,
        mediumCategory: QuoteMediumCategory? = nil,
        largeCategory: QuoteLargeCategory? = nil,
        preferredCategories: [String] = [],
        affinityScores: [String: Int] = [:]
    ) async throws -> [Quote] {

        let descriptor = FetchDescriptor<Quote>()

        var pool = try modelContext.fetch(descriptor)
        
        if let cat = mediumCategory {
            pool = pool.filter { $0.category == cat }
        }
        guard !pool.isEmpty else { return [.fallback] }

        // 大カテゴリフィルタ（中カテゴリ未指定時のみ、post-fetchで絞り込み）
        if let large = largeCategory, mediumCategory == nil {
            pool = pool.filter { $0.category.largeCategory == large }
            if pool.isEmpty { pool = try modelContext.fetch(FetchDescriptor<Quote>()) }
        }

        // 中カテゴリ指定で件数が少ない場合は全体プールにフォールバック
        if mediumCategory != nil && pool.count < 5 {
            pool = try modelContext.fetch(FetchDescriptor<Quote>())
        }

        // ---- Step 1: preferredCategories による 7:3 ミックス ----
        // preferredCategories には大カテゴリ/中カテゴリ両方の rawValue が混在し得る
        if mediumCategory == nil && largeCategory == nil && !preferredCategories.isEmpty {
            let preferred = Set(preferredCategories)
            var preferredPool = pool.filter { q in
                preferred.contains(q.category.rawValue) ||
                preferred.contains(q.category.largeCategory.rawValue)
            }.shuffled()
            var otherPool = pool.filter { q in
                !preferred.contains(q.category.rawValue) &&
                !preferred.contains(q.category.largeCategory.rawValue)
            }.shuffled()

            let preferredCount = Int(Double(limit) * 0.7)
            var balanced: [Quote] = []
            balanced.append(contentsOf: preferredPool.prefix(preferredCount))
            balanced.append(contentsOf: otherPool.prefix(limit - balanced.count))
            if balanced.count < limit {
                let used = Set(balanced.map { $0.id })
                balanced.append(contentsOf: pool.filter { !used.contains($0.id) }.shuffled().prefix(limit - balanced.count))
            }
            pool = balanced
        }

        // ---- Step 2: アフィニティスコアで重み付けソート ----
        if !affinityScores.isEmpty {
            pool = pool.sorted { a, b in
                let sa = affinityScores[a.category.rawValue] ?? 0
                let sb = affinityScores[b.category.rawValue] ?? 0
                return sa > sb
            }
            pool = stableShuffleByScore(pool, scores: affinityScores)
        } else {
            pool = pool.shuffled()
        }

        let calendar = Calendar.current
        let today = Date()

        if isPremium {
            let selected = Array(pool.prefix(limit > 0 ? limit : 50))
            for q in selected { q.lastShownDate = today }
            try modelContext.save()
            return selected
        } else {
            let todaysQuotes = pool.filter { q in
                guard let last = q.lastShownDate else { return false }
                return calendar.isDate(last, inSameDayAs: today)
            }
            if todaysQuotes.count >= limit {
                return Array(todaysQuotes.shuffled().prefix(limit))
            }
            let needed = limit - todaysQuotes.count
            let unshown = pool.filter { q in
                if let last = q.lastShownDate { return !calendar.isDate(last, inSameDayAs: today) }
                return true
            }
            let newOnes = Array(unshown.prefix(needed))
            for q in newOnes { q.lastShownDate = today }
            try modelContext.save()
            return (todaysQuotes + newOnes).shuffled()
        }
    }

    /// お気に入り toggle
    func toggleFavorite(quote: Quote, isPremium: Bool) throws {
        if quote.isFavorited {
            quote.isFavorited = false
            try modelContext.save()
            return
        }
        if !isPremium {
            let favorites = try getFavoriteQuotes()
            if favorites.count >= Config.freeUserFavoriteLimit {
                throw QuoteError.favoriteLimitReached
            }
        }
        quote.isFavorited = true
        try modelContext.save()
    }

    func getFavoriteQuotes() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isFavorited == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 中カテゴリで絞り込み
    func getQuotes(by mediumCategory: QuoteMediumCategory) throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.category == mediumCategory }
    }

    /// 大カテゴリで絞り込み（post-fetch フィルタ）
    func getQuotes(by largeCategory: QuoteLargeCategory) throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.category.largeCategory == largeCategory }
    }

    func getRandomQuote() throws -> Quote {
        let descriptor = FetchDescriptor<Quote>()
        let all = try modelContext.fetch(descriptor)
        return all.isEmpty ? Quote.fallback : all.randomElement() ?? Quote.fallback
    }

    // MARK: - Private Helpers

    /// スコア帯ごとにシャッフル（同スコア内はランダム）
    private func stableShuffleByScore(_ quotes: [Quote], scores: [String: Int]) -> [Quote] {
        var groups: [Int: [Quote]] = [:]
        for q in quotes {
            let s = scores[q.category.rawValue] ?? 0
            groups[s, default: []].append(q)
        }
        return groups.keys.sorted(by: >).flatMap { groups[$0]!.shuffled() }
    }
}

// MARK: - Errors

enum QuoteError: LocalizedError {
    case jsonFileNotFound, noValidQuotes, emptyQuoteText, favoriteLimitReached

    var errorDescription: String? {
        switch self {
        case .jsonFileNotFound:   return "名言データファイル（quotes.json）が見つかりません。"
        case .noValidQuotes:      return "有効な名言データがありません。"
        case .emptyQuoteText:     return "名言のテキストが空です。"
        case .favoriteLimitReached: return "無料ユーザーはお気に入りを10個まで保存できます。\nプレミアムプランで無制限に保存しましょう。"
        }
    }
}
