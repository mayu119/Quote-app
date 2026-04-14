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

    /// 著者名のカタカナ表記（海外著名人向け）
    var authorKana: String?

    /// 一行の人物説明
    var authorDescription: String

    /// 著者の生年
    var authorBirthYear: Int?

    /// 著者の没年
    var authorDeathYear: Int?

    /// 著者の事実ベースの簡単な説明
    var authorFact: String?

    /// 名言の意味の冒頭プレビュー（無料開放分）
    var meaningPreview: String?

    /// 名言の意味・背景の続き（有料開放分）
    var meaningPremium: String?

    /// いつ・どこで語られたかの補足
    var sourceContext: String?

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

    /// お気に入り保存時のメモ
    var favoriteNote: String?

    /// お気に入りに追加した日時
    var favoritedAt: Date?

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
        authorKana: String? = nil,
        authorDescription: String,
        authorBirthYear: Int? = nil,
        authorDeathYear: Int? = nil,
        authorFact: String? = nil,
        meaningPreview: String? = nil,
        meaningPremium: String? = nil,
        sourceContext: String? = nil,
        category: QuoteMediumCategory,
        punchline: String,
        backgroundImage: String,
        pushNotificationHook: String,
        isFavorited: Bool = false,
        favoriteNote: String? = nil,
        favoritedAt: Date? = nil,
        lastShownDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.quoteJa = quoteJa
        self.quoteEn = quoteEn
        self.author = author
        self.authorKana = authorKana
        self.authorDescription = authorDescription
        self.authorBirthYear = authorBirthYear
        self.authorDeathYear = authorDeathYear
        self.authorFact = authorFact
        self.meaningPreview = meaningPreview
        self.meaningPremium = meaningPremium
        self.sourceContext = sourceContext
        self.category = category
        self.punchline = punchline
        self.backgroundImage = backgroundImage
        self.pushNotificationHook = pushNotificationHook
        self.isFavorited = isFavorited
        self.favoriteNote = favoriteNote
        self.favoritedAt = favoritedAt
        self.lastShownDate = lastShownDate
        self.createdAt = createdAt
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case quoteJa = "quote_ja"
        case quoteEn = "quote_en"
        case author
        case authorKana = "author_kana"
        case authorDescription = "author_description"
        case authorBirthYear = "author_birth_year"
        case authorDeathYear = "author_death_year"
        case authorFact = "author_fact"
        case meaningPreview = "meaning_preview"
        case meaningPremium = "meaning_premium"
        case sourceContext = "source_context"
        case category
        case punchline
        case backgroundImage = "background_image"
        case pushNotificationHook = "push_notification_hook"
        case isFavorited = "is_favorited"
        case favoriteNote = "favorite_note"
        case favoritedAt = "favorited_at"
        case lastShownDate = "last_shown_date"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.quoteJa = try container.decode(String.self, forKey: .quoteJa)
        self.quoteEn = try container.decodeIfPresent(String.self, forKey: .quoteEn)
        self.author = try container.decode(String.self, forKey: .author)
        self.authorKana = try container.decodeIfPresent(String.self, forKey: .authorKana)
        self.authorDescription = try container.decode(String.self, forKey: .authorDescription)
        self.authorBirthYear = try container.decodeIfPresent(Int.self, forKey: .authorBirthYear)
        self.authorDeathYear = try container.decodeIfPresent(Int.self, forKey: .authorDeathYear)
        self.authorFact = try container.decodeIfPresent(String.self, forKey: .authorFact)
        self.meaningPreview = try container.decodeIfPresent(String.self, forKey: .meaningPreview)
        self.meaningPremium = try container.decodeIfPresent(String.self, forKey: .meaningPremium)
        self.sourceContext = try container.decodeIfPresent(String.self, forKey: .sourceContext)
        self.category = try container.decode(QuoteMediumCategory.self, forKey: .category)
        self.punchline = try container.decode(String.self, forKey: .punchline)
        self.backgroundImage = try container.decode(String.self, forKey: .backgroundImage)
        self.pushNotificationHook = try container.decode(String.self, forKey: .pushNotificationHook)
        self.isFavorited = try container.decodeIfPresent(Bool.self, forKey: .isFavorited) ?? false
        self.favoriteNote = try container.decodeIfPresent(String.self, forKey: .favoriteNote)
        self.favoritedAt = try container.decodeIfPresent(Date.self, forKey: .favoritedAt)
        self.lastShownDate = try container.decodeIfPresent(Date.self, forKey: .lastShownDate)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(quoteJa, forKey: .quoteJa)
        try container.encodeIfPresent(quoteEn, forKey: .quoteEn)
        try container.encode(author, forKey: .author)
        try container.encodeIfPresent(authorKana, forKey: .authorKana)
        try container.encode(authorDescription, forKey: .authorDescription)
        try container.encodeIfPresent(authorBirthYear, forKey: .authorBirthYear)
        try container.encodeIfPresent(authorDeathYear, forKey: .authorDeathYear)
        try container.encodeIfPresent(authorFact, forKey: .authorFact)
        try container.encodeIfPresent(meaningPreview, forKey: .meaningPreview)
        try container.encodeIfPresent(meaningPremium, forKey: .meaningPremium)
        try container.encodeIfPresent(sourceContext, forKey: .sourceContext)
        try container.encode(category, forKey: .category)
        try container.encode(punchline, forKey: .punchline)
        try container.encode(backgroundImage, forKey: .backgroundImage)
        try container.encode(pushNotificationHook, forKey: .pushNotificationHook)
        try container.encode(isFavorited, forKey: .isFavorited)
        try container.encodeIfPresent(favoriteNote, forKey: .favoriteNote)
        try container.encodeIfPresent(favoritedAt, forKey: .favoritedAt)
        try container.encodeIfPresent(lastShownDate, forKey: .lastShownDate)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - QuoteLargeCategory (大カテゴリ 3種)

enum QuoteLargeCategory: String, Codable, CaseIterable {
    case selfGrowth     = "self_growth"
    case relationships  = "relationships"
    case reset          = "reset"

    var displayName: String {
        switch self {
        case .selfGrowth:    return "自分を整える"
        case .relationships: return "愛とつながり"
        case .reset:         return "心を立て直す"
        }
    }

    var displayEn: String {
        switch self {
        case .selfGrowth:    return "SELF"
        case .relationships: return "LOVE"
        case .reset:         return "RESET"
        }
    }
}

// MARK: - QuoteMediumCategory (中カテゴリ 10種)

enum QuoteMediumCategory: String, Codable, CaseIterable {
    case selfLove        = "self_love"
    case positive        = "positive"
    case courage         = "courage"
    case innerStrength   = "inner_strength"
    case loveCrush       = "love_crush"
    case familyLove      = "family_love"
    case forMyChild      = "for_my_child"
    case relationships   = "relationships"
    case wantToQuit      = "want_to_quit"
    case affirmation     = "affirmation"

    // MARK: - Large Category Mapping

    var largeCategory: QuoteLargeCategory {
        switch self {
        case .selfLove, .positive, .courage, .innerStrength, .affirmation:
            return .selfGrowth
        case .loveCrush, .familyLove, .forMyChild, .relationships:
            return .relationships
        case .wantToQuit:
            return .reset
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
            // 旧カテゴリ値を新カテゴリへフォールバック
            switch rawValue {
            case "politicians_leaders", "philosophers", "entrepreneurs", "artists", "influencers":
                self = .innerStrength
            case "athletes", "self_discipline", "awakening", "mindset", "battle", "morning":
                self = .courage
            case "love_relationships":
                self = .loveCrush
            case "gratitude_happiness", "time_mortality":
                self = .positive
            case "adversity":
                self = .wantToQuit
            case "self_acceptance":
                self = .selfLove
            default:
                print("⚠️ Unknown category '\(rawValue)', falling back to .positive")
                self = .positive
            }
        }
    }

    // MARK: - Display

    var displayText: String {
        switch self {
        case .selfLove:        return "SELF LOVE"
        case .positive:        return "POSITIVE"
        case .courage:         return "COURAGE"
        case .innerStrength:   return "INNER"
        case .loveCrush:       return "CRUSH"
        case .familyLove:      return "FAMILY"
        case .forMyChild:      return "TO YOU"
        case .relationships:   return "RELATION"
        case .wantToQuit:      return "RESET"
        case .affirmation:     return "I AM"
        }
    }

    var displayTitleJa: String {
        switch self {
        case .selfLove:        return "自己肯定"
        case .positive:        return "ポジティブ"
        case .courage:         return "勇気が出ない時"
        case .innerStrength:   return "強い自分になる"
        case .loveCrush:       return "好きな人ができた時"
        case .familyLove:      return "家族愛"
        case .forMyChild:      return "大切なあなたへ"
        case .relationships:   return "対人関係"
        case .wantToQuit:      return "もう辞めてしまいたい時"
        case .affirmation:     return "アファメーション"
        }
    }

    var backgroundImagePrefix: String {
        switch largeCategory {
        case .selfGrowth:
            switch self {
            case .selfLove:      return "flower"
            case .positive:      return "sunset"
            case .courage:       return "tokyo"
            case .innerStrength: return "desert"
            case .affirmation:   return "aurora"
            default:             return "sunset"
            }
        case .relationships:
            switch self {
            case .loveCrush:     return "sakura"
            case .familyLove:    return "forest"
            case .forMyChild:    return "house"
            case .relationships: return "ocean"
            default:             return "flower"
            }
        case .reset:
            return "moon"
        }
    }
}

// MARK: - Spiritual Bundles

enum SpiritualBundle: String, Codable, CaseIterable, Identifiable {
    case grounding
    case manifestation
    case heartHealing
    case creativeFlow
    case releaseReset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grounding: return "波を静める"
        case .manifestation: return "流れをひらく"
        case .heartHealing: return "心をやわらげる"
        case .creativeFlow: return "創作の火を灯す"
        case .releaseReset: return "手放して整える"
        }
    }

    var subtitle: String {
        switch self {
        case .grounding:
            return "落ち着きと呼吸を取り戻す言葉"
        case .manifestation:
            return "自分の巡りと可能性に意識を向ける束"
        case .heartHealing:
            return "愛と痛みをやさしくほどくための言葉"
        case .creativeFlow:
            return "直感と表現欲を起こすための言葉"
        case .releaseReset:
            return "執着や疲れを下ろして立て直すための言葉"
        }
    }

    var shortPrompt: String {
        switch self {
        case .grounding: return "静けさに戻る"
        case .manifestation: return "巡りをひらく"
        case .heartHealing: return "心をゆるめる"
        case .creativeFlow: return "表現を起こす"
        case .releaseReset: return "古い重さを降ろす"
        }
    }

    var symbol: String {
        switch self {
        case .grounding: return "moon.stars.fill"
        case .manifestation: return "sparkles"
        case .heartHealing: return "heart.circle.fill"
        case .creativeFlow: return "flame.circle.fill"
        case .releaseReset: return "wind"
        }
    }

    var accentTopHex: String {
        switch self {
        case .grounding: return "#C7B8E5"
        case .manifestation: return "#F0B987"
        case .heartHealing: return "#E6A8B5"
        case .creativeFlow: return "#F28A54"
        case .releaseReset: return "#9BB7B2"
        }
    }

    var accentBottomHex: String {
        switch self {
        case .grounding: return "#6E638C"
        case .manifestation: return "#8A5A3B"
        case .heartHealing: return "#8B5465"
        case .creativeFlow: return "#803F2A"
        case .releaseReset: return "#496864"
        }
    }

    var preferredCategories: [QuoteMediumCategory] {
        switch self {
        case .grounding:
            return [.affirmation, .selfLove, .wantToQuit]
        case .manifestation:
            return [.positive, .affirmation, .innerStrength]
        case .heartHealing:
            return [.loveCrush, .relationships, .familyLove, .selfLove]
        case .creativeFlow:
            return [.courage, .innerStrength, .positive, .affirmation]
        case .releaseReset:
            return [.wantToQuit, .affirmation, .selfLove]
        }
    }

    var ritualBackgroundName: String {
        switch self {
        case .grounding:
            return "purple_moon"
        case .manifestation:
            return "blush_garden"
        case .heartHealing:
            return "sakura_lake"
        case .creativeFlow:
            return "sunlit_atrium"
        case .releaseReset:
            return "lavender_morning"
        }
    }

    var isPremiumOnly: Bool {
        switch self {
        case .grounding, .heartHealing:
            return false
        case .manifestation, .creativeFlow, .releaseReset:
            return true
        }
    }

    var ritualTitle: String {
        switch self {
        case .grounding: return "静けさを取り戻す日"
        case .manifestation: return "巡りをひらく日"
        case .heartHealing: return "心をやわらげる日"
        case .creativeFlow: return "表現の火を灯す日"
        case .releaseReset: return "余分な重さを下ろす日"
        }
    }

    var ritualIntro: String {
        switch self {
        case .grounding:
            return "速く進むより、まず自分の呼吸をそろえることを優先する流れです。"
        case .manifestation:
            return "受け取る準備を整え、閉じていた意識を少しずつひらく流れです。"
        case .heartHealing:
            return "傷んだところを責めず、やわらかく扱い直すための流れです。"
        case .creativeFlow:
            return "正しさより衝動を信じて、表現の熱を戻していく流れです。"
        case .releaseReset:
            return "抱えすぎた思考や感情を手放し、軽く立て直すための流れです。"
        }
    }

    var ritualReleasePrompt: String {
        switch self {
        case .grounding: return "急いで答えを出さなきゃという焦り"
        case .manifestation: return "どうせ無理だと閉じる癖"
        case .heartHealing: return "傷ついたまま強がる態度"
        case .creativeFlow: return "うまくやることへの過剰な緊張"
        case .releaseReset: return "もう要らないのに持ち続けている重さ"
        }
    }

    var ritualActionPrompt: String {
        switch self {
        case .grounding: return "ひとつ深呼吸してから最初の行動を始める"
        case .manifestation: return "受け取りたい未来を一文だけ言葉にする"
        case .heartHealing: return "自分に向ける言葉をひとつだけやさしくする"
        case .creativeFlow: return "完成度より先に3分だけ手を動かす"
        case .releaseReset: return "今日ひとつだけ手放すものを決める"
        }
    }
}

// MARK: - Backward Compatibility

/// 旧 QuoteCategory への後方互換エイリアス
typealias QuoteCategory = QuoteMediumCategory

// MARK: - Validation & Fallback

extension Quote {
    var hasVisibleAuthorAttribution: Bool {
        let kana = authorKana?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let hiddenTokens = ["オリジナル", "original"]

        if !kana.isEmpty, hiddenTokens.contains(kana.lowercased()) {
            return false
        }

        if hiddenTokens.contains(rawAuthor.lowercased()) {
            return false
        }

        return !(kana.isEmpty && rawAuthor.isEmpty)
    }

    var displayAuthor: String {
        guard hasVisibleAuthorAttribution else { return "" }
        // author フィールドに漢字・ひらがなが含まれる場合（日本人著者）はそのまま表示
        let containsKanjiOrHiragana = author.unicodeScalars.contains {
            ($0.value >= 0x3041 && $0.value <= 0x3096) || // hiragana
            ($0.value >= 0x4e00 && $0.value <= 0x9fff)    // kanji
        }
        if containsKanjiOrHiragana {
            return author
        }
        if let authorKana, !authorKana.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return authorKana
        }
        return author
    }

    var visibleSourceContext: String? {
        guard let sourceContext else { return nil }
        let trimmed = sourceContext.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if ["アプリオリジナル", "original"].contains(trimmed.lowercased()) {
            return nil
        }
        return trimmed
    }

    var visibleAuthorFact: String? {
        guard let authorFact else { return nil }
        let trimmed = authorFact.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return trimmed
    }

    var authorYearsText: String? {
        switch (authorBirthYear, authorDeathYear) {
        case let (birth?, death?):
            return "\(birth)-\(death)"
        case let (birth?, nil):
            return "\(birth)-"
        default:
            return nil
        }
    }

    var authorMetaLine: String? {
        let description = authorDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let years = authorYearsText

        if let years, !description.isEmpty {
            return "\(years) ・ \(description)"
        }
        if let years {
            return years
        }
        if !description.isEmpty {
            return description
        }
        return nil
    }

    /// データバリデーション（競合の「空白表示」を絶対に防ぐ）
    var isValid: Bool {
        return !quoteJa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !punchline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// フォールバック名言（データ欠損時の保険）
    static var fallback: Quote {
        Quote(
            id: "fallback_001",
            quoteJa: "私は今日、自分を小さく扱わない。",
            author: "Original",
            authorKana: "オリジナル",
            authorDescription: "アプリオリジナルのアファメーション",
            authorBirthYear: nil,
            authorDeathYear: nil,
            authorFact: nil,
            meaningPreview: "自分を後回しにしすぎた日に、自分の価値を思い出すための一文です。",
            meaningPremium: "小さく扱わないとは、完璧でいることではなく、自分の気持ちや境界線を雑にしないことです。今日の選択を少し丁寧にするだけでも、自己肯定感は静かに戻ってきます。",
            sourceContext: "アプリオリジナル",
            category: .affirmation,
            punchline: "私は今日、自分を小さく扱わない。",
            backgroundImage: "sunset",
            pushNotificationHook: "今日の自分を、少しだけ大切にする言葉。"
        )
    }
}

struct DailyRitualState: Codable, Equatable {
    let bundleRawValue: String
    let intention: String
    let release: String
    let action: String
    let dateString: String

    var bundle: SpiritualBundle? {
        SpiritualBundle(rawValue: bundleRawValue)
    }
}
