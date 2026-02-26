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

    /// カテゴリ（中カテゴリ）
    var category: QuoteMediumCategory

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
        category: QuoteMediumCategory,
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
        self.category = try container.decode(QuoteMediumCategory.self, forKey: .category)
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

// MARK: - QuoteLargeCategory (大カテゴリ 3種)

enum QuoteLargeCategory: String, Codable, CaseIterable {
    case legends        = "legends"        // 偉人・有名人
    case action         = "action"         // 行動・マインドセット
    case life           = "life"           // 人生・感情

    var displayName: String {
        switch self {
        case .legends:       return "偉人・有名人"
        case .action:        return "行動・マインドセット"
        case .life:          return "人生・感情"
        }
    }

    var displayEn: String {
        switch self {
        case .legends:       return "LEGENDS"
        case .action:        return "ACTION"
        case .life:          return "LIFE"
        }
    }
}

// MARK: - QuoteMediumCategory (中カテゴリ 16種)

enum QuoteMediumCategory: String, Codable, CaseIterable {

    // MARK: legends (6)
    case politiciansLeaders   = "politicians_leaders"
    case philosophers         = "philosophers"
    case entrepreneurs        = "entrepreneurs"
    case athletes             = "athletes"
    case artists              = "artists"
    case influencers          = "influencers"

    // MARK: action (5)
    case selfDiscipline       = "self_discipline"
    case awakening            = "awakening"
    case mindset              = "mindset"
    case battle               = "battle"
    case morning              = "morning"

    // MARK: life (5)
    case loveRelationships    = "love_relationships"
    case gratitudeHappiness   = "gratitude_happiness"
    case adversity            = "adversity"
    case timeMortality        = "time_mortality"
    case selfAcceptance       = "self_acceptance"

    // MARK: - Large Category Mapping

    var largeCategory: QuoteLargeCategory {
        switch self {
        case .politiciansLeaders, .philosophers, .entrepreneurs, .athletes, .artists, .influencers:
            return .legends
        case .selfDiscipline, .awakening, .mindset, .battle, .morning:
            return .action
        case .loveRelationships, .gratitudeHappiness, .adversity, .timeMortality, .selfAcceptance:
            return .life
        }
    }

    // MARK: - Fallback Decoder

    /// 不明なカテゴリ値（旧バージョン等）でもクラッシュしないようにフォールバック
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if let category = QuoteMediumCategory(rawValue: rawValue) {
            self = category
        } else {
            // v6以前の旧カテゴリ値をフォールバック
            switch rawValue {
            case "scientists_inventors", "writers_poets", "military_strategists",
                 "eastern_philosophy", "western_philosophy", "stoicism",
                 "religion_spirit", "modern_thought":
                self = .philosophers
            case "tech_entrepreneurs", "investors", "executives_ceo",
                 "startup_founders", "sales_marketing":
                self = .entrepreneurs
            case "ball_sports", "martial_arts", "endurance",
                 "mental_strength", "team_sports":
                self = .athletes
            case "musicians", "film_actors", "novelists",
                 "visual_artists", "comedy_entertainment":
                self = .artists
            case "youtubers", "self_help_coaches", "fitness_health",
                 "lifestyle", "business_influencers":
                self = .influencers
            default:
                print("⚠️ Unknown category '\(rawValue)', falling back to .mindset")
                self = .mindset
            }
        }
    }

    // MARK: - Display

    var displayText: String {
        switch self {
        case .politiciansLeaders:  return "POLITICIANS"
        case .philosophers:        return "PHILOSOPHERS"
        case .entrepreneurs:       return "ENTREPRENEURS"
        case .athletes:            return "ATHLETES"
        case .artists:             return "ARTISTS"
        case .influencers:         return "INFLUENCERS"
        case .selfDiscipline:      return "DISCIPLINE"
        case .awakening:           return "AWAKENING"
        case .mindset:             return "MINDSET"
        case .battle:              return "BATTLE"
        case .morning:             return "MORNING"
        case .loveRelationships:   return "LOVE"
        case .gratitudeHappiness:  return "GRATITUDE"
        case .adversity:           return "ADVERSITY"
        case .timeMortality:       return "TIME"
        case .selfAcceptance:      return "SELF"
        }
    }

    var displayTitleJa: String {
        switch self {
        case .politiciansLeaders:  return "政治家・リーダー"
        case .philosophers:        return "哲学者"
        case .entrepreneurs:       return "起業家"
        case .athletes:            return "アスリート"
        case .artists:             return "アーティスト"
        case .influencers:         return "インフルエンサー"
        case .selfDiscipline:      return "自分を鍛える"
        case .awakening:           return "行動を起こす"
        case .mindset:             return "思考を研ぐ"
        case .battle:              return "勝負に出る"
        case .morning:             return "朝を制する"
        case .loveRelationships:   return "愛・人間関係"
        case .gratitudeHappiness:  return "感謝・幸福"
        case .adversity:           return "逆境・困難"
        case .timeMortality:       return "時間・死生観"
        case .selfAcceptance:      return "自己受容"
        }
    }

    var backgroundImagePrefix: String {
        switch largeCategory {
        case .legends:
            switch self {
            case .politiciansLeaders: return "bg_mountain"
            case .philosophers:       return "bg_mountain"
            case .entrepreneurs:      return "bg_city"
            case .athletes:           return "bg_gym"
            case .artists:            return "bg_art"
            case .influencers:        return "bg_sunrise"
            default:                  return "bg_mountain"
            }
        case .action:
            switch self {
            case .selfDiscipline: return "bg_gym"
            case .awakening:      return "bg_fire"
            case .mindset:        return "bg_mountain"
            case .battle:         return "bg_fight"
            case .morning:        return "bg_sunrise"
            default:              return "bg_default"
            }
        case .life:          return "bg_default"
        }
    }
}

// MARK: - Backward Compatibility

/// 旧 QuoteCategory への後方互換エイリアス
typealias QuoteCategory = QuoteMediumCategory

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
            quoteJa: "ハングリーであれ。愚かであれ。",
            quoteEn: "Stay hungry. Stay foolish.",
            author: "Steve Jobs",
            authorDescription: "Apple共同創業者",
            category: .entrepreneurs,
            punchline: "ハングリーであれ。愚かであれ。",
            backgroundImage: "bg_extra_1",
            pushNotificationHook: "現状に満足していませんか？"
        )
    }
}
