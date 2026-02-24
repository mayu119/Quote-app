import Foundation
import StoreKit

/// アプリ内課金管理サービス（RevenueCat使用）
/// - 無料プラン：1日1名言、広告なし
/// - プレミアムプラン：無制限閲覧、月480円 / 年2,900円
@MainActor
final class PurchaseManager: ObservableObject {
    // MARK: - Singleton

    static let shared = PurchaseManager()

    // MARK: - Published Properties

    @Published var isPremiumUser = false
    @Published var isLoading = false

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case premiumMonthly = "com.quoteapp.premium.monthly"
        case premiumYearly = "com.quoteapp.premium.yearly"

        var displayName: String {
            switch self {
            case .premiumMonthly:
                return "プレミアム（月額）"
            case .premiumYearly:
                return "プレミアム（年額）"
            }
        }

        var displayPrice: String {
            switch self {
            case .premiumMonthly:
                return "¥480/月"
            case .premiumYearly:
                return "¥2,900/年"
            }
        }
    }

    // MARK: - Products

    private(set) var products: [Product] = []

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initializer

    private init() {
        // トランザクションリスナーを開始
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// 商品情報を読み込み
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            print("✅ 商品情報を読み込みました: \(products.count)件")
        } catch {
            print("⚠️ 商品情報の読み込みに失敗しました: \(error)")
        }
    }

    // MARK: - Purchase

    /// 商品を購入
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // トランザクションを検証
            let transaction = try checkVerified(verification)

            // プレミアムステータスを更新
            await updatePremiumStatus()

            // トランザクションを完了
            await transaction.finish()

            print("✅ 購入が完了しました: \(product.displayName)")
            return true

        case .userCancelled:
            print("❌ ユーザーが購入をキャンセルしました")
            return false

        case .pending:
            print("⏳ 購入が保留中です")
            return false

        @unknown default:
            print("⚠️ 不明な購入結果です")
            return false
        }
    }

    // MARK: - Restore Purchases

    /// 購入を復元
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePremiumStatus()
            print("✅ 購入を復元しました")
        } catch {
            print("⚠️ 購入の復元に失敗しました: \(error)")
        }
    }

    // MARK: - Check Premium Status

    /// プレミアムステータスを更新
    func updatePremiumStatus() async {
        var hasPremium = false

        // 全てのサブスクリプションを確認
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // プレミアムプランの確認
                if ProductID.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    hasPremium = true
                    break
                }
            } catch {
                print("⚠️ トランザクションの検証に失敗しました: \(error)")
            }
        }

        isPremiumUser = hasPremium

        // UserSettingsも更新
        UserSettings().updatePremiumStatus(isPremium: hasPremium)

        print(hasPremium ? "✅ プレミアムユーザーです" : "⚠️ 無料ユーザーです")
    }

    // MARK: - Transaction Listener

    /// トランザクションをリスンして自動更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePremiumStatus()
                    await transaction.finish()
                } catch {
                    print("⚠️ トランザクション更新のエラー: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    /// トランザクションを検証
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum PurchaseError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "トランザクションの検証に失敗しました"
        case .productNotFound:
            return "商品が見つかりませんでした"
        }
    }
}
