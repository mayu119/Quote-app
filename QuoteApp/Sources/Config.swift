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
    static let monthlyProductID = "com.quoteapp.premium.monthly"

    /// 年額サブスクリプションのProduct ID
    static let yearlyProductID = "com.quoteapp.premium.yearly"

    // MARK: - Pricing

    /// 月額価格（表示用）
    static let monthlyPrice = "¥600"

    /// 年額価格（表示用）
    static let yearlyPrice = "¥4,800"

    /// 年額の月換算価格（表示用）
    static let yearlyPricePerMonth = "¥400"

    /// 年額の割引率（表示用）
    static let yearlyDiscountRate = "33%"

    // MARK: - Free User Limits

    /// 無料ユーザーの1日あたりの名言閲覧制限
    static let freeUserDailySwipeLimit = 15

    /// 無料ユーザーのお気に入り登録制限
    static let freeUserFavoriteLimit = 10

    // MARK: - Category Rotation (Free Users)

    /// 無料ユーザーのカテゴリローテーション間隔
    static let freeCategoryRotationInterval: RotationInterval = .daily
}

// MARK: - RotationInterval

/// 無料カテゴリローテーションの更新間隔
enum RotationInterval {
    case daily
    case weekly
}
