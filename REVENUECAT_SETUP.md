# RevenueCat セットアップガイド

## 1. RevenueCat Dashboard設定

### ステップ1: プロジェクト作成
1. [RevenueCat Dashboard](https://app.revenuecat.com/)にログイン
2. 新しいプロジェクトを作成
3. APIキーをコピー（Public APIキー）

### ステップ2: App設定
1. **iOS App**を追加
2. Bundle ID を入力: `com.yourcompany.quoteapp`（実際のBundle IDに置き換え）
3. App Store Connect情報を接続

### ステップ3: Product設定
1. **Products**タブに移動
2. 以下の2つのプロダクトを追加:

#### 月額プラン
- **Product ID**: `com.quoteapp.premium.monthly`
- **Type**: Subscription
- **Price**: ¥480

#### 年額プラン
- **Product ID**: `com.quoteapp.premium.yearly`
- **Type**: Subscription
- **Price**: ¥2,900

### ステップ4: Entitlement設定
1. **Entitlements**タブに移動
2. 新しいEntitlementを作成:
   - **Identifier**: `premium`
   - **Name**: Premium Access

3. 作成したEntitlementに両方のプロダクトを紐付け:
   - `com.quoteapp.premium.monthly`
   - `com.quoteapp.premium.yearly`

### ステップ5: Offering設定
1. **Offerings**タブに移動
2. Default Offeringを作成:
   - **Identifier**: `default`
   - **Packages**:
     - Monthly: `com.quoteapp.premium.monthly`
     - Annual: `com.quoteapp.premium.yearly`

---

## 2. Xcodeプロジェクト設定

### Swift Package Managerでインストール

1. Xcodeでプロジェクトを開く
2. **File → Add Package Dependencies...**
3. URLを入力: `https://github.com/RevenueCat/purchases-ios.git`
4. Version: `5.0.0`以上を選択
5. **Add Package**をクリック

### Package.swiftに追加（Swift Package Managerを使用する場合）

```swift
dependencies: [
    .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0")
]
```

---

## 3. QuoteApp.swiftの更新

`QuoteApp.swift`のinitializer内でRevenueCatを初期化:

```swift
import SwiftUI
import SwiftData
import RevenueCat

@main
struct QuoteApp: App {
    @StateObject private var userSettings = UserSettings()

    init() {
        // RevenueCat初期化（アプリ起動時に1回だけ）
        RevenueCatManager.configure(apiKey: "YOUR_REVENUECAT_PUBLIC_API_KEY")
    }

    let modelContainer: ModelContainer = {
        // ... 既存のコード
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .modelContainer(modelContainer)
                .task {
                    await initializeApp()
                }
        }
    }

    @MainActor
    private func initializeApp() async {
        // 1. RevenueCatのサブスクリプションステータスをチェック
        await RevenueCatManager.shared.checkSubscriptionStatus()

        // 2. 商品情報を取得
        await RevenueCatManager.shared.fetchOfferings()

        // 3. 通知権限のリクエスト
        do {
            let granted = try await NotificationService.shared.requestAuthorization()
            if granted {
                print("✅ 通知権限が許可されました")
            }
        } catch {
            print("⚠️ 通知権限のリクエストに失敗しました: \(error)")
        }

        // 4. 名言データの初期ロード
        let context = modelContainer.mainContext
        let dataService = QuoteDataService(modelContext: context)

        do {
            try await dataService.loadInitialQuotes()
        } catch {
            print("⚠️ 名言データのロードに失敗しました: \(error)")
        }

        // 5. 通知のスケジュール（設定がONの場合）
        if userSettings.notificationEnabled {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: userSettings.notificationTime)
            let minute = calendar.component(.minute, from: userSettings.notificationTime)

            do {
                try await NotificationService.shared.scheduleDailyQuoteNotification(
                    hour: hour,
                    minute: minute,
                    notificationHook: nil
                )
            } catch {
                print("⚠️ 通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
}
```

---

## 4. PremiumView.swiftの更新

RevenueCatManagerを使用するように更新:

```swift
import SwiftUI
import RevenueCat

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @EnvironmentObject private var userSettings: UserSettings

    @State private var selectedPackage: Package?
    @State private var showAlert = false
    @State private var alertMessage = ""

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                // ... 既存の背景コード

                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        benefitsSection
                        plansSection
                        purchaseButton
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
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await revenueCatManager.fetchOfferings()
                if let firstPackage = revenueCatManager.getAvailablePackages().first {
                    selectedPackage = firstPackage
                }
            }
            .alert("通知", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // ... 他のセクション（headerSection, benefitsSection等）

    private var plansSection: some View {
        VStack(spacing: 16) {
            Text("プランを選択")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(revenueCatManager.getAvailablePackages(), id: \.identifier) { package in
                RevenueCatPlanCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    accentGold: accentGold
                )
                .onTapGesture {
                    selectedPackage = package
                }
            }
        }
    }

    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchasePackage()
            }
        }) {
            HStack {
                if revenueCatManager.isLoading {
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
        .disabled(selectedPackage == nil || revenueCatManager.isLoading)
    }

    private func purchasePackage() async {
        guard let package = selectedPackage else { return }

        do {
            let success = try await revenueCatManager.purchase(package)
            if success {
                alertMessage = "プレミアムプランを購入しました！"
                showAlert = true

                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            }
        } catch {
            alertMessage = "購入に失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// RevenueCat用のプランカード
struct RevenueCatPlanCard: View {
    let package: Package
    let isSelected: Bool
    let accentGold: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(package.displayPeriod)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(package.storeProduct.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(package.displayPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? accentGold : .white)

                if let savingsText = package.savingsText {
                    Text(savingsText)
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
```

---

## 5. App Store Connect設定

### ステップ1: アプリ内課金の作成
1. App Store Connectにログイン
2. アプリを選択 → **App 内課金**
3. 以下の2つのサブスクリプションを作成:

#### サブスクリプショングループ
- **グループ名**: Premium Subscription

#### 月額プラン
- **参照名**: Premium Monthly
- **プロダクトID**: `com.quoteapp.premium.monthly`
- **価格**: ¥480

#### 年額プラン
- **参照名**: Premium Yearly
- **プロダクトID**: `com.quoteapp.premium.yearly`
- **価格**: ¥2,900

### ステップ2: RevenueCatと連携
1. RevenueCat DashboardでApp Store Connectの情報を入力
2. Shared Secretを設定
3. テストユーザーを追加

---

## 6. テスト方法

### Sandboxテスト
1. **設定 → App Store → Sandboxアカウント**でテストアカウントを追加
2. アプリをビルドして実機にインストール
3. 購入フローをテスト
4. RevenueCat Dashboardで購入履歴を確認

### 確認項目
- ✅ 商品情報が正しく表示される
- ✅ 購入が完了する
- ✅ プレミアムステータスが反映される
- ✅ 購入復元が動作する
- ✅ RevenueCat Dashboardに購入履歴が表示される

---

## 7. トラブルシューティング

### 商品が表示されない
- App Store ConnectでIn-App Purchasesが承認されているか確認
- Bundle IDが一致しているか確認
- Xcodeで**Signing & Capabilities**が正しく設定されているか確認

### 購入がRevenueCatに反映されない
- Shared Secretが正しく設定されているか確認
- RevenueCat DashboardでApp Store Connectの接続状態を確認

### サンドボックス環境でエラー
- テストアカウントでサインインしているか確認
- デバイスの日付・時刻が正しいか確認

---

## 8. 本番環境へのデプロイ

1. **App Store Connect**でサブスクリプションを承認
2. **RevenueCat Dashboard**で本番環境の設定を確認
3. TestFlightでベータテスト
4. App Storeにリリース

---

## 参考リンク

- [RevenueCat公式ドキュメント](https://www.revenuecat.com/docs)
- [iOS SDK クイックスタート](https://www.revenuecat.com/docs/getting-started/quickstart/ios)
- [App Store Connect サブスクリプションガイド](https://developer.apple.com/app-store/subscriptions/)
