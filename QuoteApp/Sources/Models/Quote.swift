import Foundation
import SwiftData

/// 名言データモデル
/// 要件定義書に基づいた完全なデータ構造
@Model
final class Quote: Codable {
    // MARK: - Properties

    /// 一意識別子
    @Attribute(.unique) var id: String

    /// 日本語の名言本文
    var quoteJa: String

    /// 英語原文（存在する場合）
    var quoteEn: String?

    /// 偉人名
    var author: String

    /// 一行の人物説明
    var authorDescription: String

    /// カテゴリ
    var category: QuoteCategory

    /// ウィジェット用の短縮版（1-2行）
    var punchline: String

    /// 背景画像名
    var backgroundImage: String

    /// プッシュ通知用のフック文言（釣り場理論準拠）
    var pushNotificationHook: String

    /// お気に入り登録フラグ
    var isFavorited: Bool

    /// 最後に表示された日時（重複排除用）
    var lastShownDate: Date?

    /// 作成日時
    var createdAt: Date

    // MARK: - Initializer

    init(
        id: String = UUID().uuidString,
        quoteJa: String,
        quoteEn: String? = nil,
        author: String,
        authorDescription: String,
        category: QuoteCategory,
        punchline: String,
        backgroundImage: String,
        pushNotificationHook: String,
        isFavorited: Bool = false,
        lastShownDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.quoteJa = quoteJa
        self.quoteEn = quoteEn
        self.author = author
        self.authorDescription = authorDescription
        self.category = category
        self.punchline = punchline
        self.backgroundImage = backgroundImage
        self.pushNotificationHook = pushNotificationHook
        self.isFavorited = isFavorited
        self.lastShownDate = lastShownDate
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case quoteJa = "quote_ja"
        case quoteEn = "quote_en"
        case author
        case authorDescription = "author_description"
        case category
        case punchline
        case backgroundImage = "background_image"
        case pushNotificationHook = "push_notification_hook"
        case isFavorited = "is_favorited"
        case lastShownDate = "last_shown_date"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.quoteJa = try container.decode(String.self, forKey: .quoteJa)
        self.quoteEn = try container.decodeIfPresent(String.self, forKey: .quoteEn)
        self.author = try container.decode(String.self, forKey: .author)
        self.authorDescription = try container.decode(String.self, forKey: .authorDescription)
        self.category = try container.decode(QuoteCategory.self, forKey: .category)
        self.punchline = try container.decode(String.self, forKey: .punchline)
        self.backgroundImage = try container.decode(String.self, forKey: .backgroundImage)
        self.pushNotificationHook = try container.decode(String.self, forKey: .pushNotificationHook)
        self.isFavorited = try container.decodeIfPresent(Bool.self, forKey: .isFavorited) ?? false
        self.lastShownDate = try container.decodeIfPresent(Date.self, forKey: .lastShownDate)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(quoteJa, forKey: .quoteJa)
        try container.encodeIfPresent(quoteEn, forKey: .quoteEn)
        try container.encode(author, forKey: .author)
        try container.encode(authorDescription, forKey: .authorDescription)
        try container.encode(category, forKey: .category)
        try container.encode(punchline, forKey: .punchline)
        try container.encode(backgroundImage, forKey: .backgroundImage)
        try container.encode(pushNotificationHook, forKey: .pushNotificationHook)
        try container.encode(isFavorited, forKey: .isFavorited)
        try container.encodeIfPresent(lastShownDate, forKey: .lastShownDate)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - QuoteCategory

/// 名言カテゴリ
enum QuoteCategory: String, Codable, CaseIterable {
    case selfDiscipline = "self_discipline"     // 💪 自己鍛錬
    case awakening = "awakening"                // 🔥 覚醒・行動
    case mindset = "mindset"                    // 🧠 マインドセット
    case battle = "battle"                      // ⚔️ 戦い・勝負
    case morning = "morning"                    // 🌅 朝・習慣

    /// 表示用のアイコン付きテキスト
    var displayText: String {
        switch self {
        case .selfDiscipline:
            return "💪 自己鍛錬"
        case .awakening:
            return "🔥 覚醒・行動"
        case .mindset:
            return "🧠 マインドセット"
        case .battle:
            return "⚔️ 戦い・勝負"
        case .morning:
            return "🌅 朝・習慣"
        }
    }

    /// カテゴリに合った背景画像のプレフィックス
    var backgroundImagePrefix: String {
        switch self {
        case .selfDiscipline:
            return "bg_gym"
        case .awakening:
            return "bg_fire"
        case .mindset:
            return "bg_mountain"
        case .battle:
            return "bg_fight"
        case .morning:
            return "bg_sunrise"
        }
    }
}

// MARK: - Validation & Fallback

extension Quote {
    /// データバリデーション（競合の「空白表示」を絶対に防ぐ）
    var isValid: Bool {
        return !quoteJa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !punchline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// フォールバック名言（データ欠損時の保険）
    static var fallback: Quote {
        Quote(
            id: "fallback_001",
            quoteJa: "行動しろ。考えるのはそのあとだ。",
            quoteEn: "Act. Think later.",
            author: "Unknown",
            authorDescription: "不明",
            category: .awakening,
            punchline: "行動しろ。考えるのはそのあとだ。",
            backgroundImage: "bg_default",
            pushNotificationHook: "今日の名言、シンプルだけど強烈。"
        )
    }
}
