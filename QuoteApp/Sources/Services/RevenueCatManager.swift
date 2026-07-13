import Foundation
import RevenueCat

/// RevenueCat を使ったサブスクリプション管理
@MainActor
final class RevenueCatManager: ObservableObject {

    enum PurchaseError: LocalizedError {
        case notConfigured
        case productsUnavailable
        case entitlementNotActive

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "課金機能の初期化に失敗しました。アプリを再起動してもう一度お試しください。"
            case .productsUnavailable:
                return "購入プランの取得に失敗しました。しばらくしてから再度お試しください。"
            case .entitlementNotActive:
                return "購入情報を確認できませんでした。しばらくしてから購入を復元してください。"
            }
        }
    }

    // MARK: - Singleton
    static let shared = RevenueCatManager()

    // MARK: - Published
    @Published var isPremiumUser = false
    @Published var isLoading = false
    @Published var offerings: Offering?
    @Published var monthlyPackage: Package?
    @Published var yearlyPackage: Package?
    @Published private(set) var introEligibilityByProductID: [String: IntroEligibilityStatus] = [:]

    private var isConfigured = false
    private let sawTrialKey = "analytics_saw_trial"
    private let loggedTrialConvertKey = "analytics_logged_trial_convert"

    private init() {}

    // MARK: - Configure

    /// RevenueCat SDK を初期化する（1回のみ）
    func configure(apiKey: String) {
        guard !isConfigured else { return }
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true
        print("✅ RevenueCat configured")
    }

    // MARK: - Subscription Status

    /// 現在のサブスクリプション状態を確認し isPremiumUser を更新する
    func checkSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let premium = hasActivePremiumAccess(in: info)
            self.isPremiumUser = premium

            logCustomerInfo(info, label: "checkSubscriptionStatus")

            print(premium ? "✅ プレミアムユーザー" : "⚠️ 無料ユーザー")

            // トライアル期間の検出（転換ログ用）。終了前リマインダーは出さない方針
            let entitlement = info.entitlements["premium"]
            if let ent = entitlement,
               ent.periodType == .trial,
               let expirationDate = ent.expirationDate {
                UserDefaults.standard.set(true, forKey: sawTrialKey)
                print("📅 トライアル終了日: \(expirationDate)")
            } else if premium,
                      UserDefaults.standard.bool(forKey: sawTrialKey),
                      !UserDefaults.standard.bool(forKey: loggedTrialConvertKey) {
                let planType = entitlement?.productIdentifier.contains("yearly") == true ? "yearly" : "monthly"
                AnalyticsService.shared.logTrialConvert(planType: planType)
                UserDefaults.standard.set(true, forKey: loggedTrialConvertKey)
            }
        } catch {
            print("⚠️ サブスクリプション状態の確認に失敗: \(error)")
        }
    }

    // MARK: - Offerings

    /// 利用可能なオファリングを取得
    func fetchOfferings() async {
        guard isConfigured else {
            print("⚠️ RevenueCat 未初期化のためオファリング取得をスキップ")
            return
        }

        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            guard let current = fetchedOfferings.current else {
                self.offerings = nil
                self.monthlyPackage = nil
                self.yearlyPackage = nil
                print("⚠️ current offering が存在しません")
                return
            }

            self.offerings = current
            self.monthlyPackage = resolvePackage(
                preferred: current.monthly,
                fallbackFrom: current.availablePackages,
                matching: Config.monthlyProductID
            )
            self.yearlyPackage = resolvePackage(
                preferred: current.annual,
                fallbackFrom: current.availablePackages,
                matching: Config.yearlyProductID
            )
            await refreshIntroEligibility()

            print("✅ オファリング取得成功 (monthly: \(monthlyPackage?.localizedPriceString ?? "nil"), yearly: \(yearlyPackage?.localizedPriceString ?? "nil"))")
        } catch {
            print("⚠️ オファリング取得失敗: \(error)")
        }
    }

    // MARK: - Purchase

    /// パッケージを購入 (元のメソッド・互換性維持)
    func purchase(package: Package) async throws -> Bool {
        let (success, _) = try await purchaseWithCancelStatus(package: package)
        return success
    }

    /// パッケージを購入し、成功フラグとキャンセルされたかどうかの状態を返す
    ///
    /// Apple決済の完了後、RevenueCatで有効な権利を確認できた場合のみ `success: true` を返す。
    func purchaseWithCancelStatus(package: Package) async throws -> (success: Bool, isCancelled: Bool) {
        guard isConfigured else {
            print("❌ purchaseWithCancelStatus: RevenueCat未初期化")
            throw PurchaseError.notConfigured
        }

        let productID = package.storeProduct.productIdentifier
        print("🛒 購入開始: \(productID) (\(package.localizedPriceString))")

        isLoading = true
        defer {
            isLoading = false
            print("🛒 isLoading = false")
        }

        do {
            print("🛒 Purchases.shared.purchase() 呼び出し中...")
            let result = try await Purchases.shared.purchase(package: package)
            print("🛒 Purchases.shared.purchase() 完了 — userCancelled: \(result.userCancelled)")

            // ユーザーがキャンセルした場合
            if result.userCancelled {
                print("❌ ユーザーが購入をキャンセル (userCancelled=true)")
                return (success: false, isCancelled: true)
            }

            // Apple決済成功 → プレミアムとして扱う
            var customerInfo = result.customerInfo
            var entitlementActive = hasActivePremiumAccess(
                in: customerInfo,
                purchasedProductID: productID
            )

            // 決済結果だけでPremiumを開放せず、RevenueCatから最新の権利状態を再取得する。
            // 一時的な通信・同期遅延があっても、未確認の権利をローカルで恒久化しない。
            if !entitlementActive {
                customerInfo = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
                entitlementActive = hasActivePremiumAccess(
                    in: customerInfo,
                    purchasedProductID: productID
                )
            }

            logCustomerInfo(customerInfo, label: "購入直後")

            if !entitlementActive {
                self.isPremiumUser = false
                print("⚠️ Apple決済後もRevenueCatのpremium権利を確認できなかったため、Premiumは開放しない")
                throw PurchaseError.entitlementNotActive
            }

            self.isPremiumUser = true
            print("✅ 購入完了 → プレミアム")
            return (success: true, isCancelled: false)

        } catch {
            let nsError = error as NSError
            print("❌ 購入 catch: domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")

            // RevenueCat SDK v5: キャンセルはエラーとしても来る場合がある
            if let rcError = error as? RevenueCat.ErrorCode, rcError == .purchaseCancelledError {
                print("❌ キャンセル検出 (RevenueCat.ErrorCode)")
                return (success: false, isCancelled: true)
            }
            // StoreKit のキャンセルエラーコード
            if nsError.domain == "SKErrorDomain" && nsError.code == 2 {
                print("❌ キャンセル検出 (SKErrorDomain code 2)")
                return (success: false, isCancelled: true)
            }
            if nsError.domain == "RevenueCat.ErrorCode" && nsError.code == 1 {
                print("❌ キャンセル検出 (RevenueCat.ErrorCode code 1)")
                return (success: false, isCancelled: true)
            }

            print("❌ 購入エラー (未処理): \(error)")
            throw error
        }
    }

    // MARK: - Restore

    /// 購入を復元
    func restorePurchases() async throws {
        guard isConfigured else {
            throw PurchaseError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        let info = try await Purchases.shared.restorePurchases()
        let premium = hasActivePremiumAccess(in: info)
        self.isPremiumUser = premium

        logCustomerInfo(info, label: "復元後")
        print(premium ? "✅ 復元成功 → プレミアム" : "⚠️ 復元完了だがプレミアムではない")
    }

    func refreshPackagesIfNeeded() async {
        if monthlyPackage == nil || yearlyPackage == nil {
            await fetchOfferings()
        } else if introEligibilityByProductID.isEmpty {
            await refreshIntroEligibility()
        }
    }

    func introEligibilityStatus(for package: Package?) -> IntroEligibilityStatus? {
        guard let productID = package?.storeProduct.productIdentifier else { return nil }
        return introEligibilityByProductID[productID]
    }

    // MARK: - Private

    private func resolvePackage(
        preferred: Package?,
        fallbackFrom availablePackages: [Package],
        matching expectedProductID: String
    ) -> Package? {
        if let preferred {
            return preferred
        }

        return availablePackages.first { $0.storeProduct.productIdentifier == expectedProductID }
    }

    private func refreshIntroEligibility() async {
        let products = [monthlyPackage, yearlyPackage].compactMap { $0?.storeProduct }
        guard !products.isEmpty else {
            introEligibilityByProductID = [:]
            return
        }

        let eligibilities = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: products.map(\.productIdentifier)
        )

        introEligibilityByProductID = eligibilities.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value.status
        }

        for product in products {
            let status = introEligibilityByProductID[product.productIdentifier]?.description ?? "nil"
            let hasIntroOffer = product.introductoryDiscount != nil
            print("🧾 Intro eligibility: \(product.productIdentifier) status=\(status) hasIntroOffer=\(hasIntroOffer)")
        }
    }

    private func hasActivePremiumAccess(
        in customerInfo: CustomerInfo,
        purchasedProductID: String? = nil
    ) -> Bool {
        if customerInfo.entitlements["premium"]?.isActive == true {
            return true
        }

        let activeSubscriptionIDs = customerInfo.activeSubscriptions
        if activeSubscriptionIDs.contains(Config.monthlyProductID) ||
            activeSubscriptionIDs.contains(Config.yearlyProductID) {
            return true
        }

        if let purchasedProductID,
           activeSubscriptionIDs.contains(purchasedProductID) {
            return true
        }

        return false
    }

    // MARK: - Debug Logging

    /// customerInfo の中身を詳細にログ出力する（問題切り分け用）
    private func logCustomerInfo(_ info: CustomerInfo, label: String) {
        print("━━━━━━━━━━━ CustomerInfo [\(label)] ━━━━━━━━━━━")
        print("  activeSubscriptions: \(info.activeSubscriptions)")
        print("  allPurchasedProductIdentifiers: \(info.allPurchasedProductIdentifiers)")
        print("  entitlements.all keys: \(Array(info.entitlements.all.keys))")
        for (key, ent) in info.entitlements.all {
            print("  entitlement[\(key)]: isActive=\(ent.isActive), productID=\(ent.productIdentifier), expires=\(String(describing: ent.expirationDate))")
        }
        print("  Config.monthlyProductID: \(Config.monthlyProductID)")
        print("  Config.yearlyProductID: \(Config.yearlyProductID)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
