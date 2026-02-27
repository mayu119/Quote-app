import SwiftUI
import StoreKit

/// プレミアムプラン購入画面
struct PremiumView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @EnvironmentObject private var userSettings: UserSettings

    // MARK: - State

    @State private var selectedProduct: Product?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var paywallOpenTime = Date()

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // ヘッダー
                        headerSection

                        // 特典
                        benefitsSection

                        // プラン選択
                        plansSection

                        // 購入ボタン
                        purchaseButton

                        // 復元・利用規約
                        footerSection
                    }
                    .padding()
                }
            }
            .navigationTitle("プレミアム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        // Analytics: ペイウォール閉じる
                        let duration = Int(Date().timeIntervalSince(paywallOpenTime))
                        AnalyticsService.shared.logPaywallDismiss(
                            trigger: "manual",
                            timeOnPaywallSec: duration,
                            planViewed: selectedProduct?.id
                        )
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await purchaseManager.loadProducts()
                if let firstProduct = purchaseManager.products.first {
                    selectedProduct = firstProduct
                }
            }
            .alert("通知", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundColor(accentGold)
                .shadow(color: accentGold.opacity(0.5), radius: 20)

            Text("プレミアムで\n全ての名言を解放")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("広告なし、無制限で名言を楽しむ")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 40)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            BenefitRow(
                icon: "infinity",
                title: "過去の名言も無制限閲覧",
                description: "いつでも好きな名言を見返せる"
            )

            BenefitRow(
                icon: "sparkles",
                title: "プレミアム限定名言",
                description: "無料ユーザーには見られない特別な名言"
            )

            BenefitRow(
                icon: "photo.fill",
                title: "フル背景画像",
                description: "シネマティックな高品質背景"
            )

            BenefitRow(
                icon: "bell.fill",
                title: "広告なし",
                description: "集中を妨げる広告は一切なし"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentGold.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var plansSection: some View {
        VStack(spacing: 16) {
            Text("プランを選択")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(purchaseManager.products, id: \.id) { product in
                PlanCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    accentGold: accentGold
                )
                .onTapGesture {
                    selectedProduct = product
                    // Analytics: プラン選択
                    AnalyticsService.shared.logPaywallPlanSelect(
                        planType: product.id.contains("yearly") ? "yearly" : "monthly",
                        price: product.displayPrice
                    )
                }
            }
        }
    }

    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchaseProduct()
            }
        }) {
            HStack {
                if purchaseManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text("プレミアムを始める")
                        .font(.headline)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(accentGold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(selectedProduct == nil || purchaseManager.isLoading)
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            // 購入を復元
            Button(action: {
                Task {
                    await purchaseManager.restorePurchases()
                    let success = userSettings.isPremiumUser
                    AnalyticsService.shared.logPurchaseRestore(success: success)
                    alertMessage = "購入を復元しました"
                    showAlert = true
                }
            }) {
                Text("購入を復元")
                    .font(.subheadline)
                    .foregroundColor(accentGold)
            }

            // 利用規約・プライバシーポリシー
            HStack(spacing: 16) {
                Button("利用規約") {
                    // 利用規約を開く
                }
                .font(.caption)
                .foregroundColor(.gray)

                Text("•")
                    .foregroundColor(.gray)

                Button("プライバシーポリシー") {
                    // プライバシーポリシーを開く
                }
                .font(.caption)
                .foregroundColor(.gray)
            }

            // 注意事項
            Text("サブスクリプションは自動更新されます。キャンセルは設定から可能です。")
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Methods

    private func purchaseProduct() async {
        guard let product = selectedProduct else { return }
        let planType = product.id.contains("yearly") ? "yearly" : "monthly"

        // Analytics: 購入開始
        AnalyticsService.shared.logPurchaseInitiate(
            planType: planType,
            price: product.displayPrice,
            trigger: "paywall"
        )

        do {
            let success = try await purchaseManager.purchase(product)
            if success {
                // Analytics: 購入成功
                AnalyticsService.shared.logPurchaseSuccess(
                    planType: planType,
                    price: product.displayPrice,
                    trigger: "paywall",
                    totalQuotesViewed: 0,
                    totalFavorites: 0
                )

                alertMessage = "プレミアムプランを購入しました！"
                showAlert = true

                // 少し待ってから画面を閉じる
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            }
        } catch {
            // Analytics: 購入失敗
            AnalyticsService.shared.logPurchaseFail(
                planType: planType,
                errorMessage: error.localizedDescription
            )
            alertMessage = "購入に失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(accentGold)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let accentGold: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(product.displayPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? accentGold : .white)

                if product.id.contains("yearly") {
                    Text("約¥242/月")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? accentGold : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    PremiumView()
        .environmentObject(UserSettings())
}
