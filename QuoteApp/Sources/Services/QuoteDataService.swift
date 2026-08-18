import Foundation
import SwiftData
import UIKit

/// 名言データ管理サービス
@MainActor
final class QuoteDataService: ObservableObject {
    struct WeeklyFavoriteSummary {
        let favoriteCount: Int
        let topCategory: QuoteMediumCategory?
    }

    struct WeeklyShelfSummary {
        let quotes: [Quote]
        let topCategory: QuoteMediumCategory?

        var favoriteCount: Int { quotes.count }
        var featuredQuote: Quote? {
            quotes.max { ($0.favoritedAt ?? .distantPast) < ($1.favoritedAt ?? .distantPast) }
        }
    }

    struct MonthlyShelfSummary {
        let quotes: [Quote]
        let topCategory: QuoteMediumCategory?
        let month: Date
        var favoriteCount: Int { quotes.count }
        var bestQuotes: [Quote] { Array(quotes.prefix(3)) }
    }

    struct FavoriteRecommendation {
        let quote: Quote
        let sourceCategory: QuoteMediumCategory?
    }

    // MARK: - Properties

    private let modelContext: ModelContext
    private let duplicatePreventionDays: Int = 30

    /// JSONデータを更新したらこの値をインクリメントする
    /// v29: 300件化(全カテゴリ30件)。Original+107件、カテゴリ再配置13件、重複・不適合7件削除、解説文の使い回し解消
    /// v28: 削除済み引用をお気に入り棚に残す移行を追加
    private static let currentDataVersion: Int = 30
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
            let validIDs = Set(validQuotes.map(\.id))
            // 配信カタログから削除された言葉でも、既に棚へ置いた記録はユーザーのものとして残す。
            // 次の通常配信には混ぜず、Favorites / Archive からだけ見返せる。
            let orphanedFavorites = existingQuotes.filter {
                $0.isFavorited && !validIDs.contains($0.id)
            }
            let favoritedIds = Set(existingQuotes.filter { $0.isFavorited }.map { $0.id })
            let lastShownMap = Dictionary(uniqueKeysWithValues:
                existingQuotes.compactMap { q -> (String, Date)? in
                    guard let d = q.lastShownDate else { return nil }
                    return (q.id, d)
                }
            )
            let favoriteNoteMap = Dictionary(uniqueKeysWithValues:
                existingQuotes.compactMap { quote -> (String, String)? in
                    guard let note = quote.favoriteNote else { return nil }
                    return (quote.id, note)
                }
            )
            let favoritedAtMap = Dictionary(uniqueKeysWithValues:
                existingQuotes.compactMap { q -> (String, Date)? in
                    guard let d = q.favoritedAt else { return nil }
                    return (q.id, d)
                }
            )
            for q in existingQuotes where !orphanedFavorites.contains(where: { $0.id == q.id }) {
                modelContext.delete(q)
            }
            for q in validQuotes {
                if favoritedIds.contains(q.id) { q.isFavorited = true }
                if let note = favoriteNoteMap[q.id] { q.favoriteNote = note }
                if let d = favoritedAtMap[q.id] { q.favoritedAt = d }
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
        
        // ウィジェット用のデータプールを共有AppGroupディレクトリに書き出し
        refreshWidgetPools()
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
        spiritualBundle: SpiritualBundle? = nil,
        preferredCategories: [String] = [],
        affinityScores: [String: Int] = [:]
    ) async throws -> [Quote] {

        let descriptor = FetchDescriptor<Quote>()
        let effectiveLimit = limit > 0 ? limit : Int.max

        var pool = try modelContext.fetch(descriptor)

        // 月替わりOriginalパック: 60件を20件ずつローテーションする。
        // 保存済みの言葉はSwiftDataに残り、ここで「通常配信」から外れるだけ。
        if mediumCategory == nil, largeCategory == nil {
            let activeOriginalIDs = monthlyOriginalPackIDs(from: pool, on: Date())
            pool = pool.filter { $0.author != "Original" || activeOriginalIDs.contains($0.id) }
        }
        
        if let cat = mediumCategory {
            pool = pool.filter { $0.category == cat }
        }
        guard !pool.isEmpty else { return [.fallback] }

        // 大カテゴリフィルタ（中カテゴリ未指定時のみ、post-fetchで絞り込み）
        if let large = largeCategory, mediumCategory == nil {
            pool = pool.filter { $0.category.largeCategory == large }
            if pool.isEmpty { pool = try modelContext.fetch(FetchDescriptor<Quote>()) }
        }

        if let spiritualBundle, mediumCategory == nil, largeCategory == nil {
            let preferredSet = Set(spiritualBundle.preferredCategories)
            let prioritized = pool.filter { preferredSet.contains($0.category) }
            if prioritized.count >= min(5, effectiveLimit) {
                pool = prioritized
            } else if !prioritized.isEmpty {
                let remaining = pool.filter { !preferredSet.contains($0.category) }
                pool = prioritized + remaining
            }
        }

        // 中カテゴリ指定で件数が少ない場合は全体プールにフォールバック
        if mediumCategory != nil && pool.count < 5 {
            pool = try modelContext.fetch(FetchDescriptor<Quote>())
        }

        // ---- Step 1: preferredCategories による 7:3 ミックス ----
        // preferredCategories には大カテゴリ/中カテゴリ両方の rawValue が混在し得る
        if mediumCategory == nil && largeCategory == nil && !preferredCategories.isEmpty {
            let preferred = Set(preferredCategories)
            let preferredPool = pool.filter { q in
                preferred.contains(q.category.rawValue) ||
                preferred.contains(q.category.largeCategory.rawValue)
            }.shuffled()
            let otherPool = pool.filter { q in
                !preferred.contains(q.category.rawValue) &&
                !preferred.contains(q.category.largeCategory.rawValue)
            }.shuffled()

            let preferredCount = Int(Double(effectiveLimit) * 0.7)
            var balanced: [Quote] = []
            balanced.append(contentsOf: preferredPool.prefix(preferredCount))
            balanced.append(contentsOf: otherPool.prefix(effectiveLimit - balanced.count))
            if balanced.count < effectiveLimit {
                let used = Set(balanced.map { $0.id })
                balanced.append(contentsOf: pool.filter { !used.contains($0.id) }.shuffled().prefix(effectiveLimit - balanced.count))
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

        if limit <= 0 {
            for q in pool { q.lastShownDate = today }
            try modelContext.save()
            return pool
        }

        if isPremium {
            let selected = Array(pool.prefix(limit))
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
            quote.favoriteNote = nil
            quote.favoritedAt = nil
            try modelContext.save()
            refreshWidgetPools()
            return
        }
        if !isPremium {
            let favorites = try getFavoriteQuotes()
            if favorites.count >= Config.freeUserFavoriteLimit {
                throw QuoteError.favoriteLimitReached
            }
        }
        quote.isFavorited = true
        quote.favoritedAt = Date()
        try modelContext.save()
        refreshWidgetPools()
    }

    func updateFavoriteNote(for quote: Quote, note: String, isPremium: Bool) throws {
        guard quote.isFavorited else { return }

        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        quote.favoriteNote = trimmed.isEmpty ? nil : trimmed
        try modelContext.save()
    }

    func getFavoriteQuotes() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isFavorited == true },
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getWeeklyFavoriteSummary(referenceDate: Date = Date()) throws -> WeeklyFavoriteSummary {
        let summary = try getWeeklyShelfSummary(referenceDate: referenceDate)
        return WeeklyFavoriteSummary(favoriteCount: summary.favoriteCount, topCategory: summary.topCategory)
    }

    func getWeeklyShelfSummary(referenceDate: Date = Date()) throws -> WeeklyShelfSummary {
        let favorites = try getFavoriteQuotes()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: referenceDate) ?? referenceDate

        let weeklyFavorites = favorites.filter { quote in
            guard let favoritedAt = quote.favoritedAt else { return false }
            return favoritedAt >= calendar.startOfDay(for: weekAgo)
        }

        let topCategory = Dictionary(grouping: weeklyFavorites, by: \.category)
            .max { lhs, rhs in
                if lhs.value.count == rhs.value.count {
                    return lhs.key.rawValue > rhs.key.rawValue
                }
                return lhs.value.count < rhs.value.count
            }?
            .key

        return WeeklyShelfSummary(quotes: weeklyFavorites, topCategory: topCategory)
    }

    func getMonthlyShelfSummary(referenceDate: Date = Date()) throws -> MonthlyShelfSummary {
        let calendar = Calendar.current
        let currentMonth = calendar.dateInterval(of: .month, for: referenceDate) ?? DateInterval(start: referenceDate, duration: 0)
        let previousMonthEnd = calendar.date(byAdding: .second, value: -1, to: currentMonth.start) ?? referenceDate
        let previousMonth = calendar.dateInterval(of: .month, for: previousMonthEnd) ?? currentMonth
        let quotes = try getFavoriteQuotes().filter {
            guard let date = $0.favoritedAt else { return false }
            return previousMonth.contains(date)
        }
        let topCategory = Dictionary(grouping: quotes, by: \.category)
            .max { $0.value.count < $1.value.count }?.key
        return MonthlyShelfSummary(quotes: quotes, topCategory: topCategory, month: previousMonth.start)
    }

    func getFavoriteRecommendation(excluding excludedQuoteID: String? = nil) throws -> FavoriteRecommendation? {
        let favorites = try getFavoriteQuotes()
        guard !favorites.isEmpty else { return nil }

        let sortedFavorites = favorites.sorted { lhs, rhs in
            let lhsScore = favoriteSignalScore(for: lhs)
            let rhsScore = favoriteSignalScore(for: rhs)
            if lhsScore == rhsScore {
                return (lhs.favoritedAt ?? .distantPast) > (rhs.favoritedAt ?? .distantPast)
            }
            return lhsScore > rhsScore
        }

        guard let seed = sortedFavorites.first else { return nil }

        let allQuotes = try modelContext.fetch(FetchDescriptor<Quote>())
        let recommendation = allQuotes.first { candidate in
            candidate.id != excludedQuoteID &&
            candidate.id != seed.id &&
            candidate.category == seed.category
        } ?? allQuotes.first { candidate in
            candidate.id != excludedQuoteID && candidate.id != seed.id
        }

        guard let recommendation else { return nil }

        return FavoriteRecommendation(
            quote: recommendation,
            sourceCategory: seed.category
        )
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

    private func monthlyOriginalPackIDs(from quotes: [Quote], on date: Date) -> Set<String> {
        let originals = quotes
            .filter { $0.author == "Original" }
            .map(\.id)
            .sorted()
        guard !originals.isEmpty else { return [] }
        let packSize = 20
        let packCount = max(1, Int(ceil(Double(originals.count) / Double(packSize))))
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let monthSeed = (components.year ?? 0) * 12 + (components.month ?? 0)
        let packIndex = monthSeed % packCount
        let start = packIndex * packSize
        let end = min(start + packSize, originals.count)
        return Set(originals[start..<end])
    }

    private func favoriteSignalScore(for quote: Quote) -> Int {
        var score = 0
        if let favoritedAt = quote.favoritedAt {
            let daysAgo = Calendar.current.dateComponents([.day], from: favoritedAt, to: Date()).day ?? 0
            score += max(0, 14 - daysAgo)
        }
        if !(quote.favoriteNote?.isEmpty ?? true) {
            score += 10
        }
        return score
    }
    
    // MARK: - Widget Export
    
    /// iOS 17 App Intent: 長押しで選べるウィジェット表示のために各カテゴリのプールを書き出す
    func refreshWidgetPools() {
        let appGroupID = "group.com.antigravity.QuoteApp"
        guard let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else { return }
        
        // 画像はDataとして保持するとJSONが巨大になるので、ファイルパスまたは標準BackgroundNameだけ渡す
        // そしてWidget側で画像を読ませるため、よく使われる背景画像のJPEGをAppGroupディレクトリに書き出しておく
        for bgName in BackgroundService.backgrounds.prefix(10) {
            let bgURL = sharedURL.appendingPathComponent("\(bgName).jpg")
            if !FileManager.default.fileExists(atPath: bgURL.path),
               let image = UIImage(named: bgName),
               let data = image.jpegData(compressionQuality: 0.5) {
                try? data.write(to: bgURL)
            }
        }
        
        func toDict(_ q: Quote) -> [String: String] {
            return [
                "punchline": q.punchline,
                "author": q.author,
                "category": q.category.displayText,
                "category_ja": q.category.displayTitleJa,
                "background_name": q.backgroundImage
            ]
        }
        
        var pools: [String: [[String: String]]] = [:]
        
        // 1. 全体ランダム (50件)
        pools["random"] = self.quotes.shuffled().prefix(50).map { toDict($0) }
        
        // 2. お気に入り
        let favs = self.quotes.filter { $0.isFavorited }
        pools["favorites"] = favs.shuffled().prefix(50).map { toDict($0) }
        
        // 3. 大カテゴリごとのプール
        let selfGrowth = self.quotes.filter { $0.category.largeCategory == .selfGrowth }
        pools["self_growth"] = selfGrowth.shuffled().prefix(30).map { toDict($0) }

        let relationships = self.quotes.filter { $0.category.largeCategory == .relationships }
        pools["relationships"] = relationships.shuffled().prefix(30).map { toDict($0) }

        let reset = self.quotes.filter { $0.category.largeCategory == .reset }
        pools["reset"] = reset.shuffled().prefix(30).map { toDict($0) }

        // 使われているすべての背景画像を抽出してAppGroupディレクトリに保存
        var usedBackgrounds: Set<String> = []
        for pool in pools.values {
            for dict in pool {
                if let bg = dict["background_name"] {
                    usedBackgrounds.insert(bg)
                }
            }
        }
        for bgName in usedBackgrounds {
            let bgURL = sharedURL.appendingPathComponent("\(bgName).jpg")
            if !FileManager.default.fileExists(atPath: bgURL.path),
               let image = UIImage(named: bgName),
               let data = image.jpegData(compressionQuality: 0.5) {
                try? data.write(to: bgURL)
            }
        }

        // ファイルに書き出し
        let jsonURL = sharedURL.appendingPathComponent("widget_pools.json")
        if let data = try? JSONSerialization.data(withJSONObject: pools) {
            try? data.write(to: jsonURL)
        }
    }
}

// MARK: - Errors

enum QuoteError: LocalizedError {
    case jsonFileNotFound, noValidQuotes, emptyQuoteText, favoriteLimitReached, favoriteNoteRequiresPremium

    var errorDescription: String? {
        switch self {
        case .jsonFileNotFound:   return "名言データファイル（quotes.json）が見つかりません。"
        case .noValidQuotes:      return "有効な名言データがありません。"
        case .emptyQuoteText:     return "名言のテキストが空です。"
        case .favoriteLimitReached: return "無料ユーザーはお気に入りを10個まで保存できます。\nプレミアムプランで無制限に保存しましょう。"
        case .favoriteNoteRequiresPremium: return "名言メモはプレミアム機能です。アップグレードすると保存した言葉に自分の文脈を残せます。"
        }
    }
}
