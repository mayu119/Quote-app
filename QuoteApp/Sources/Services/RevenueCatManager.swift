import Foundation
import RevenueCat

/// RevenueCat課金管理サービス
/// - 無料プラン：1日1名言、広告なし
/// - プレミアムプラン：無制限閲覧、月480円 / 年2,900円
@MainActor
final class RevenueCatManager: ObservableObject {
    // MARK: - Singleton

    static let shared = RevenueCatManager()

    // MARK: - Published Properties

    @Published var isPremiumUser = false
    @Published var isLoading = false
    @Published var offerings: Offerings?

    // MARK: - Constants

    private let entitlementID = "premium" // RevenueCat Dashboardで設定したEntitlement ID

    // MARK: - Initializer

    private init() {
        // RevenueCat初期化はQuoteApp.swiftで行う
    }

    // MARK: - Setup

    /// RevenueCatの初期設定
    /// - Parameter apiKey: RevenueCat APIキー
    static func configure(apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)

        // ユーザー属性の設定（オプション）
        Purchases.shared.attribution.setAttributes([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])

        print("✅ RevenueCatを初期化しました")
    }

    // MARK: - Fetch Offerings

    /// 商品情報を取得
    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            offerings = try await Purchases.shared.offerings()
            print("✅ 商品情報を取得しました: \(offerings?.current?.availablePackages.count ?? 0)件")
        } catch {
            print("⚠️ 商品情報の取得に失敗しました: \(error)")
        }
    }

    // MARK: - Purchase

    /// パッケージを購入
    func purchase(_ package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            await checkSubscriptionStatus()

            print("✅ 購入が完了しました")
            return true
        } catch let error as ErrorCode {
            switch error {
            case .purchaseCancelledError:
                print("❌ ユーザーが購入をキャンセルしました")
                return false
            default:
                print("⚠️ 購入エラー: \(error.localizedDescription)")
                throw error
            }
        }
    }

    // MARK: - Restore Purchases

    /// 購入を復元
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await Purchases.shared.restorePurchases()
            await checkSubscriptionStatus()
            print("✅ 購入を復元しました")
        } catch {
            print("⚠️ 購入の復元に失敗しました: \(error)")
            throw error
        }
    }

    // MARK: - Check Subscription Status

    /// サブスクリプションステータスを確認
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasPremium = customerInfo.entitlements[entitlementID]?.isActive == true

            isPremiumUser = hasPremium

            // UserSettingsも更新
            UserSettings().updatePremiumStatus(isPremium: hasPremium)

            print(hasPremium ? "✅ プレミアムユーザーです" : "⚠️ 無料ユーザーです")
        } catch {
            print("⚠️ ステータスの確認に失敗しました: \(error)")
            isPremiumUser = false
        }
    }

    // MARK: - Get Available Packages

    /// 利用可能なパッケージを取得
    func getAvailablePackages() -> [Package] {
        return offerings?.current?.availablePackages ?? []
    }

    /// 月額プランを取得
    func getMonthlyPackage() -> Package? {
        return offerings?.current?.monthly
    }

    /// 年額プランを取得
    func getAnnualPackage() -> Package? {
        return offerings?.current?.annual
    }
}

// MARK: - Package Extensions

extension Package {
    /// 表示用の価格文字列
    var displayPrice: String {
        return storeProduct.localizedPriceString
    }

    /// 表示用の期間文字列
    var displayPeriod: String {
        switch storeProduct.subscriptionPeriod?.unit {
        case .month:
            return "月額"
        case .year:
            return "年額"
        default:
            return ""
        }
    }

    /// お得度の計算（年額の場合）
    var savingsText: String? {
        guard storeProduct.subscriptionPeriod?.unit == .year,
              let yearlyPrice = storeProduct.price as? Decimal else {
            return nil
        }

        let monthlyEquivalent = yearlyPrice / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = storeProduct.priceFormatter?.locale ?? Locale.current

        let monthlyString = formatter.string(from: monthlyEquivalent as NSNumber) ?? ""
        return "約\(monthlyString)/月"
    }
}
