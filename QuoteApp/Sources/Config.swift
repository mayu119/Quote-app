import Foundation
import SwiftData

/// アプリの設定・環境変数を管理
enum Config {
    // MARK: - RevenueCat

    /// RevenueCat Public API Key
    /// - 本番環境とSandbox環境で自動的に切り替わります
    /// - ダッシュボード: https://app.revenuecat.com/
    static let revenueCatAPIKey: String = {
        // RevenueCatは同一のPublic API Keyで自動的にSandbox/Productionを判別します
        return "appl_UrdbVQDpUVpxmFZPxRpWlBfpbBX"
    }()

    // MARK: - Product IDs

    /// 月額サブスクリプションのProduct ID
    static let monthlyProductID = "com.quoteapp.premium.monthly.22"

    /// 年額サブスクリプションのProduct ID
    static let yearlyProductID = "com.quoteapp.premium.yearly.33"

    /// 言葉のお守り（買い切りギフト）
    static let giftOmamoriProductID = "com.quoteapp.gift.omamori"

    /// Gift APIの本番URL。Cloudflare Workerのデプロイ完了後にtrueへ切り替える。
    static let giftAPIBaseURL = URL(string: "https://quote-gift-api.mayu119.workers.dev")!
    static let enableGiftOmamori = false

    /// Instagram Storiesのsource_applicationに渡す値。
    /// Metaの仕様ではMeta for Developersで発行されるFacebook App ID（数値）が正。
    /// 現在はApple Team IDの暫定値のままで、Meta未登録のため属性計測は効かない。
    static let instagramSourceApplicationID = "9W24U28U8Q"

    // MARK: - Free User Limits

    /// 無料ユーザーの日替わり無料カテゴリ閲覧制限
    static let freeUserCategorySwipeLimit = 10

    /// 無料ユーザー向けロックプレビューの表示位置（11枚目）
    static let freeUserCategoryPreviewIndex = freeUserCategorySwipeLimit

    /// 無料ユーザーのお気に入り登録制限
    static let freeUserFavoriteLimit = 10

    // MARK: - Category Rotation (Free Users)

    /// 無料ユーザーのカテゴリローテーション間隔
    static let freeCategoryRotationInterval: RotationInterval = .daily

    // MARK: - Feature Flags

    /// スピリチュアル儀式導線を一時停止
    static let enableSpiritualRitual = false
}

// MARK: - RotationInterval

/// 無料カテゴリローテーションの更新間隔
enum RotationInterval {
    case daily
    case weekly
}

// MARK: - JapaneseLineBreaker

enum JapaneseLineBreaker {
    private static let prohibitedLineHead: Set<Character> = [
        "、", "。", ",", ".", "，", "．", "・", "：", "；", "!", "！", "?", "？",
        "）", ")", "］", "]", "｝", "}", "〉", "》", "」", "』", "】", "〙", "〗",
        "ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ",
        "ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "っ", "ゃ", "ゅ", "ょ"
    ]

    private static let prohibitedLineEnd: Set<Character> = [
        "（", "(", "［", "[", "｛", "{", "〈", "《", "「", "『", "【", "〘", "〖",
        "“", "\"", "‘"
    ]

    static func fold(_ text: String, maxPerLine: Int) -> String {
        guard maxPerLine > 1 else { return text }

        return text
            .components(separatedBy: "\n")
            .flatMap { foldParagraph($0, maxPerLine: maxPerLine) }
            .joined(separator: "\n")
    }

    private static func foldParagraph(_ paragraph: String, maxPerLine: Int) -> [String] {
        let chars = Array(paragraph)
        guard !chars.isEmpty else { return [""] }

        var result: [String] = []
        var start = 0

        while start < chars.count {
            let remaining = chars.count - start
            if remaining <= maxPerLine {
                result.append(String(chars[start...]))
                break
            }

            var split = start + min(maxPerLine, remaining)

            while split < chars.count, prohibitedLineHead.contains(chars[split]) {
                split += 1
            }

            while split > start + 1, prohibitedLineEnd.contains(chars[split - 1]) {
                split -= 1
            }

            let remainder = chars.count - split
            if remainder == 1 {
                if split < chars.count, !prohibitedLineHead.contains(chars[split]) {
                    split += 1
                } else if split > start + 2 {
                    split -= 1
                }
            }

            while split < chars.count, prohibitedLineHead.contains(chars[split]) {
                split += 1
            }

            while split > start + 1, prohibitedLineEnd.contains(chars[split - 1]) {
                split -= 1
            }

            if split <= start {
                split = min(start + maxPerLine, chars.count)
            }

            result.append(String(chars[start..<split]))
            start = split
        }

        return rebalanceTrailingShortLines(result, maxPerLine: maxPerLine)
    }

    private static func rebalanceTrailingShortLines(_ lines: [String], maxPerLine: Int) -> [String] {
        guard lines.count >= 2 else { return lines }

        var result = lines

        while result.count >= 2 {
            let last = result[result.count - 1]
            let previous = result[result.count - 2]

            let lastChars = Array(last)
            let previousChars = Array(previous)

            let isShortTail = lastChars.count <= 2
                || (lastChars.count == 3 && lastChars.last.map { prohibitedLineHead.contains($0) } == true)

            guard isShortTail else { break }

            if previousChars.count + lastChars.count <= maxPerLine + 2 {
                result[result.count - 2] = previous + last
                result.removeLast()
                continue
            }

            guard previousChars.count >= 2 else { break }

            var borrowedCount = 0
            var newPrevious = previousChars
            var newLast = lastChars

            while newLast.count < 3 && newPrevious.count > 2 {
                newLast.insert(newPrevious.removeLast(), at: 0)
                borrowedCount += 1
            }

            if borrowedCount == 0 { break }

            result[result.count - 2] = String(newPrevious)
            result[result.count - 1] = String(newLast)
        }

        return result
    }
}
