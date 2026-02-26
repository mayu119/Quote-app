import Foundation
import RevenueCat

/// RevenueCat を使ったサブスクリプション管理
@MainActor
final class RevenueCatManager: ObservableObject {

    // MARK: - Singleton
    static let shared = RevenueCatManager()

    // MARK: - Published
    @Published var isPremiumUser = false
    @Published var isLoading = false
    @Published var offerings: Offering?
    @Published var monthlyPackage: Package?
    @Published var yearlyPackage: Package?

    private var isConfigured = false

    private init() {}

    // MARK: - Configure

    /// RevenueCat SDK を初期化する（1回のみ）
    func configure(apiKey: String) {
        guard !isConfigured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true
        print("✅ RevenueCat configured")
    }

    // MARK: - Subscription Status

    /// 現在のサブスクリプション状態を確認
    func checkSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let entitlement = info.entitlements["premium"]
            let premium = entitlement?.isActive ?? false
            self.isPremiumUser = premium
            print(premium ? "✅ プレミアムユーザー" : "⚠️ 無料ユーザー")

            // トライアル期間の検出 → リマインダー通知をスケジュール
            if let ent = entitlement,
               ent.periodType == .trial,
               let expirationDate = ent.expirationDate {
                // UserSettings にトライアル終了日を保存
                await MainActor.run {
                    UserSettings().trialEndDate = expirationDate
                }
                // トライアル終了リマインダーをスケジュール
                try? await NotificationService.shared.scheduleTrialReminders(
                    trialEndDate: expirationDate
                )
                print("📅 トライアル終了日: \(expirationDate)")
            }
        } catch {
            print("⚠️ サブスクリプション状態の確認に失敗: \(error)")
        }
    }

    // MARK: - Offerings

    /// 利用可能なオファリングを取得
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                self.offerings = current
                self.monthlyPackage = current.monthly
                self.yearlyPackage = current.annual
                print("✅ オファリング取得成功")
            }
        } catch {
            print("⚠️ オファリング取得失敗: \(error)")
        }
    }

    // MARK: - Purchase

    /// パッケージを購入
    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            let premium = result.customerInfo.entitlements["premium"]?.isActive ?? false
            self.isPremiumUser = premium
            print(premium ? "✅ 購入完了 → プレミアム" : "⚠️ 購入完了だがプレミアムではない")
            return premium
        } catch {
            if let err = error as? RevenueCat.ErrorCode, err == .purchaseCancelledError {
                print("❌ ユーザーが購入をキャンセル")
                return false
            }
            throw error
        }
    }

    // MARK: - Restore

    /// 購入を復元
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        let info = try await Purchases.shared.restorePurchases()
        let premium = info.entitlements["premium"]?.isActive ?? false
        self.isPremiumUser = premium
        print(premium ? "✅ 復元成功 → プレミアム" : "⚠️ 復元完了だがプレミアムではない")
    }
}
