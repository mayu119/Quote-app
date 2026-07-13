import SwiftUI
import RevenueCat
import UIKit

enum PaywallContext: String {
    case onboarding, favoriteLimit, archive, wallpaper, categoryLock, insight, weeklyShelf, general
}

/// 女性向けの柔らかいプレミアム画面
struct PremiumView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var rcManager = RevenueCatManager.shared
    @EnvironmentObject private var userSettings: UserSettings
    
    /// 外部から終了処理を注入したい場合に使用
    var context: PaywallContext = .general
    var onDismiss: (() -> Void)? = nil

    // MARK: - Legal URLs

    /// Apple 標準 EULA（利用規約）
    private let termsURL = URL(string: "https://mayu119.github.io/Quote-app/terms.html")!
    /// プライバシーポリシー
    private let privacyURL = URL(string: "https://mayu119.github.io/Quote-app/privacy.html")!

    // MARK: - State

    @State private var selectedPackage: Package?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var shouldDismissAfterAlert = false
    @State private var paywallOpenTime = Date()
    @State private var appear = false
    @State private var heroPulse = false
    @State private var planType: PlanType = .yearly

    enum PlanType {
        case yearly, monthly
    }

    // MARK: - Design Tokens
    // 処方箋リビール〜メイン体験と同じ夜の世界観に固定する

    private let panelBg = Color.white.opacity(0.06)
    private let accentRose = WFM.ColorToken.nightRose
    private let accentRoseSoft = WFM.ColorToken.nightRoseSoft
    private let inkOnRose = WFM.ColorToken.nightInk
    private let textPrimary = WFM.ColorToken.nightTextPrimary
    private let textSub = WFM.ColorToken.nightTextSub

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景レイヤー（処方箋リビールと同一グラデで画面遷移を地続きにする）
            LinearGradient(
                colors: [WFM.ColorToken.nightRaised, WFM.ColorToken.nightHigh, WFM.ColorToken.nightBase],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // スクロールコンテンツ
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // 上部ヒーローグラフィック＆権威バッジ
                    heroSection

                    // メインコピー
                    mainCopySection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    // ベネフィット（アンロックリスト）
                    benefitListSection
                        .padding(.top, 40)
                        .padding(.horizontal, 24)

                    // 機能比較
                    comparisonSection
                        .padding(.top, 40)
                        .padding(.horizontal, 24)

                    checkoutSection
                        .padding(.top, 40)
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(safeAreaBottom, 16) + 32)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .preferredColorScheme(.dark)
        .task {
            await rcManager.refreshPackagesIfNeeded()
            updateSelectedPackage(for: .yearly)
        }
        .onAppear {
            paywallOpenTime = Date()
            withAnimation(.easeOut(duration: 0.8)) { appear = true }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                heroPulse = true
            }
        }
        .alert("購入状況", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if shouldDismissAfterAlert {
                    performDismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Hero Artwork

    private var heroSection: some View {
        ZStack {
            // 夜の中に灯る光の玉（処方箋の余韻を引き継ぐランタン）
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentRose, accentRoseSoft.opacity(0.9), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 380, height: 380)
                .blur(radius: 60)
                .scaleEffect(heroPulse ? 1.05 : 0.95)
                .opacity(appear ? 0.55 : 0)
                .offset(y: -40)

            // 下部を夜の背景へ溶かして本文に繋げる
            VStack {
                Spacer()
                LinearGradient(colors: [Color.clear, WFM.ColorToken.nightRaised.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 160)
            }

            // 月桂冠風のバッジ群 (中央下寄り)
            VStack {
                Spacer()
                HStack(spacing: 24) {
                    badgeView(icon: "heart.fill", text: "深く知る")
                }
                .padding(.bottom, 20)
            }
        }
        .frame(height: 380)
    }

    private func badgeView(icon: String, subIcon: Bool = false, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .rotationEffect(.degrees(-45))
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 14))

            VStack(spacing: 4) {
                if subIcon {
                    HStack(spacing: 2) {
                        Text(text.prefix(3))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(textPrimary)
                        Image(systemName: icon)
                            .font(.system(size: 13))
                            .foregroundColor(accentRoseSoft)
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(accentRoseSoft)
                }
                Text(subIcon ? "Apple Store" : text)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(textSub)
            }

            Image(systemName: "leaf.fill")
                .rotationEffect(.degrees(45))
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 14))
        }
    }

    // MARK: - Main Copy

    private var mainCopySection: some View {
        Text(context == .onboarding
             ? "処方箋が決まった記念に、\n7日間、すべての言葉と棚を\n受け取れます"
             : "響いた言葉をただ流さず、\nあなたの文脈として\n静かに残せるように")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
    }

    // MARK: - Benefit List

    private var benefitListSection: some View {
        VStack(spacing: 24) {
            Text("すべての機能をアンロックする")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 28) {
                ForEach(contextualBenefits, id: \.title) { benefit in
                    benefitRow(icon: benefit.icon, title: benefit.title, desc: benefit.description)
                }
            }
        }
        .opacity(appear ? 1 : 0)
    }

    private struct Benefit {
        let icon: String
        let title: String
        let description: String
    }

    private var contextualBenefits: [Benefit] {
        let shelf = Benefit(icon: "star.fill", title: "言葉の棚を無制限に育てる", description: "心に残った一節を好きなだけ残して、あなただけの世界観を少しずつ編めます。")
        let archive = Benefit(icon: "calendar", title: "過ぎた言葉をさかのぼる", description: "あの日に受け取った言葉と、そのときの自分を静かに見返せます。")
        let category = Benefit(icon: "square.grid.2x2", title: "全カテゴリを自由に巡る", description: "自己肯定、恋愛、家族、対人関係まで、その日の気分に近い言葉を自分で選べます。")
        let wallpaper = Benefit(icon: "photo.on.rectangle", title: "背景と空気感を自分好みに", description: "やわらかな光や静かな景色を選んで、言葉を受け取る余白を整えられます。")
        let insight = Benefit(icon: "book.pages.fill", title: "言葉の余韻を最後まで受け取る", description: "実在の言葉でも創作の言葉でも、その意味や背景を最後まで読めます。")
        let leading: Benefit
        switch context {
        case .favoriteLimit: leading = shelf
        case .archive: leading = archive
        case .wallpaper: leading = wallpaper
        case .categoryLock, .onboarding: leading = category
        case .insight: leading = insight
        case .weeklyShelf, .general: leading = shelf
        }
        return [leading] + [shelf, archive, category, wallpaper, insight].filter { $0.title != leading.title }.prefix(3)
    }

    private func benefitRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(textSub)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textPrimary)
                Text(desc)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(textSub)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("無料版との比較")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textPrimary)

                Text("何が変わるのかを、ここで一気に確認できます。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSub)
            }

            VStack(spacing: 0) {
                HStack {
                    Text("機能")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(textSub)
                    Spacer()
                    Text("無料")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(textSub)
                        .frame(width: 78, alignment: .center)
                    Text("PRO")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(accentRoseSoft)
                        .frame(width: 78, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

                VStack(spacing: 0) {
                    compRow(title: "名言の通常スクロール", freeValue: "無制限", proValue: "無制限")
                    compRow(title: "お気に入り保存", freeValue: "10件まで", proValue: "無制限")
                    compRow(title: "日替わり無料ジャンル", freeValue: "1つ解放", proValue: "全カテゴリ")
                    compRow(title: "アーカイブ表示", freeValue: "不可", proValue: "使える")
                    compRow(title: "通知回数", freeValue: "1回 / 日", proValue: "3回 / 日")
                    compRow(title: "Live Activity", freeValue: "不可", proValue: "使える")
                    compRow(title: "壁紙カスタム", freeValue: "固定", proValue: "変更可")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(panelBg)
            )
        }
        .opacity(appear ? 1 : 0)
    }

    private func compRow(title: String, freeValue: String, proValue: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textPrimary)
            Spacer()
            Text(freeValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(textSub)
                .frame(width: 78, alignment: .center)

            Text(proValue)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(accentRoseSoft)
                .frame(width: 78, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 1)
                    , alignment: .bottom
        )
    }

    // MARK: - Checkout Section

    private var checkoutSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("プランを選択")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textPrimary)

                Text("年額、月額の順で選べます。支払い前にいつでも見比べられます。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSub)
            }

            VStack(spacing: 10) {
                planOptionCard(type: .yearly)
                planOptionCard(type: .monthly)
            }

            // 続けるボタン（決済実行）
            Button(action: {
                if !rcManager.isLoading {
                    Task { await purchaseSelectedPackage() }
                }
            }) {
                HStack {
                    if rcManager.isLoading {
                        ProgressView().tint(inkOnRose)
                    } else if selectedPackage == nil {
                        Text("プランを取得中...")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Text(callToActionTitle)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(accentRose)
                .foregroundColor(inkOnRose)
                .cornerRadius(12)
            }
            // 不要なdisabledは外し、Actionの中でハンドリングする
            .opacity(rcManager.isLoading ? 0.7 : 1.0)
            .accessibilityLabel(selectedPackage == nil ? "購入プランを取得中" : callToActionTitle)
            .accessibilityHint("選択中のプランの購入を開始します")

            reassuranceSection

            // 下部の補足テキスト＆リンク
            VStack(spacing: 8) {
                Text(checkoutSupportingText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(textSub)

            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        do {
                                try await rcManager.restorePurchases()
                                let success = rcManager.isPremiumUser
                                userSettings.updatePremiumStatus(isPremium: success)
                                AnalyticsService.shared.logPurchaseRestore(success: success)
                                await MainActor.run {
                                    alertMessage = success ? "購入を復元しました" : "復元対象の購入が見つかりませんでした"
                                    shouldDismissAfterAlert = success
                                    showAlert = true
                                }
                            } catch {
                                await MainActor.run {
                                    alertMessage = "復元に失敗しました: \(error.localizedDescription)"
                                    shouldDismissAfterAlert = false
                                    showAlert = true
                                }
                            }
                        }
                    }) {
                        Text("購入を復元")
                    }
                    Text("・")
                    Button(action: { openURL(termsURL) }) { Text("利用規約") }
                    Text("・")
                    Button(action: { openURL(privacyURL) }) { Text("プライバシー") }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(textSub.opacity(0.8))
            }
            .padding(.top, 4)

            Button(action: dismissPaywallLater) {
                Text("後で見る")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textPrimary.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
            .padding(.top, 8)
            .accessibilityLabel("今は購入しない")
        }
        .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(panelBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    /// 購入前の不安を減らす、事実に基づく案内。
    private var reassuranceSection: some View {
        VStack(alignment: .leading, spacing: WFM.Space.xs) {
            reassuranceRow("いつでも解約できます。手順も簡単です")
            reassuranceRow("解約しても、棚に置いた言葉は消えません")
            if let selectedPackage,
               let discount = eligibleIntroductoryDiscount(for: selectedPackage),
               discount.paymentMode == .freeTrial {
                reassuranceRow("無料期間中に料金はかかりません")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, WFM.Space.xs)
    }

    private func reassuranceRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark")
            .font(WFM.Typography.caption())
            .foregroundColor(textSub)
    }

    private func planOptionCard(type: PlanType) -> some View {
        let isSelected = planType == type
        let isYearly = type == .yearly
        let package = package(for: type)
        let introDiscount = package.flatMap(eligibleIntroductoryDiscount(for:))

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectPlan(type)
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(isYearly ? "プレミアム 年額" : "プレミアム 月額")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(textPrimary)

                            if isYearly {
                                Text("おすすめ")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(inkOnRose)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentRoseSoft)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(isYearly ? "12か月分をまとめて支払い" : "まずは気軽に始めたい方向け")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textSub)
                    }

                    Spacer()

                    Group {
                        if let package {
                            VStack(alignment: .trailing, spacing: 4) {
                                if isYearly,
                                   let introDiscount,
                                   introDiscount.paymentMode == .freeTrial,
                                   let introPeriodText = localizedPeriodText(for: introDiscount) {
                                        Text("\(introPeriodText)無料")
                                            .font(.system(size: 20, weight: .black, design: .rounded))
                                    Text("その後 \(package.localizedPriceString) / 年")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(textSub)
                                } else {
                                    Text(package.localizedPriceString)
                                        .font(.system(size: 22, weight: .black, design: .rounded))
                                    Text(isYearly ? " / 年" : " / 月")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(textSub)
                                }
                            }
                            .foregroundColor(textPrimary)
                        } else {
                            ProgressView()
                                .tint(textPrimary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(planSupportingText(for: type))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textPrimary.opacity(0.88))

                    if let footnote = planFootnote(for: type) {
                        Text(footnote)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textSub.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? accentRoseSoft.opacity(0.16) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? accentRose : Color.white.opacity(0.14),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            )
        }
    }

    private func selectPlan(_ type: PlanType) {
        planType = type
        updateSelectedPackage(for: type)

        if let pkg = selectedPackage {
            AnalyticsService.shared.logPaywallPlanSelect(
                planType: type == .yearly ? "yearly" : "monthly",
                price: pkg.localizedPriceString
            )
        }
    }

    private func dismissPaywallLater() {
        let duration = Int(Date().timeIntervalSince(paywallOpenTime))
        AnalyticsService.shared.logPaywallDismiss(
            trigger: "later",
            timeOnPaywallSec: duration,
            planViewed: selectedPackage?.storeProduct.productIdentifier
        )
        performDismiss()
    }

    private func performDismiss() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func package(for type: PlanType) -> Package? {
        switch type {
        case .yearly:
            rcManager.yearlyPackage
        case .monthly:
            rcManager.monthlyPackage
        }
    }

    private func planSupportingText(for type: PlanType) -> String {
        switch type {
        case .yearly:
            if let introText = introOfferHeadline(for: type) {
                return introText
            }
            return yearlySavingsText ?? "長く使うなら年額プランがいちばんお得"
        case .monthly:
            return "いつでも解約可能。短期で試したい場合はこちら"
        }
    }

    private func planFootnote(for type: PlanType) -> String? {
        switch type {
        case .yearly:
            if let trialFootnote = introOfferFootnote(for: type) {
                return trialFootnote
            }
            return yearlyMonthlyEquivalentText
        case .monthly:
            return "請求は毎月更新されます"
        }
    }

    private var callToActionTitle: String {
        if let introText = introOfferCTA(for: planType) {
            return introText
        }

        return "続ける"
    }

    private var checkoutSupportingText: String {
        if let selectedPackage,
           let discount = eligibleIntroductoryDiscount(for: selectedPackage),
           discount.paymentMode == .freeTrial,
           let durationText = localizedPeriodText(for: discount) {
            return context == .onboarding
                ? "\(durationText)後に\(selectedPackage.localizedPriceString)で自動更新されます"
                : "\(durationText)の無料期間終了後、\(selectedPackage.localizedPriceString)で自動更新されます"
        }

        return planType == .yearly ? "1年分を一括でお支払いします" : "いつでもキャンセル可能"
    }

    private var yearlySavingsText: String? {
        guard
            let monthly = rcManager.monthlyPackage,
            let yearly = rcManager.yearlyPackage
        else {
            return nil
        }

        let savings = monthlyPriceValue(monthly) * 12 - priceValue(yearly)
        guard savings > 0 else { return nil }
        return "月額プラン12か月分より\(formatCurrency(savings))お得"
    }

    private var yearlyMonthlyEquivalentText: String? {
        guard let yearly = rcManager.yearlyPackage else { return nil }
        let monthlyEquivalent = priceValue(yearly) / 12
        guard monthlyEquivalent > 0 else { return nil }
        return "約\(formatCurrency(monthlyEquivalent))/月"
    }

    private func priceValue(_ package: Package) -> Double {
        NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
    }

    private func monthlyPriceValue(_ package: Package) -> Double {
        priceValue(package)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥\(Int(amount))"
    }

    private func introOfferHeadline(for type: PlanType) -> String? {
        guard let package = package(for: type),
              let discount = eligibleIntroductoryDiscount(for: package) else {
            return nil
        }

        guard let durationText = localizedPeriodText(for: discount) else {
            return package.storeProduct.localizedIntroductoryPriceString
        }

        switch discount.paymentMode {
        case .freeTrial:
            return context == .onboarding ? "処方箋が決まった記念に" : "今日からすぐにフル機能を使えます"
        case .payAsYouGo, .payUpFront:
            return "\(discount.localizedPriceString)で\(durationText)"
        @unknown default:
            return package.storeProduct.localizedIntroductoryPriceString
        }
    }

    private func introOfferFootnote(for type: PlanType) -> String? {
        guard let package = package(for: type),
              eligibleIntroductoryDiscount(for: package) != nil else {
            return nil
        }

        return "無料期間終了後は\(package.localizedPriceString) / \(type == .yearly ? "年" : "月")"
    }

    private func introOfferCTA(for type: PlanType) -> String? {
        guard let package = package(for: type),
              let discount = eligibleIntroductoryDiscount(for: package),
              discount.paymentMode == .freeTrial,
              let durationText = localizedPeriodText(for: discount) else {
            return nil
        }

        return context == .onboarding ? "7日間、受け取ってみる" : "\(durationText)無料で始める"
    }

    private func eligibleIntroductoryDiscount(for package: Package) -> StoreProductDiscount? {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return nil
        }

        if let status = rcManager.introEligibilityStatus(for: package) {
            switch status {
            case .ineligible, .noIntroOfferExists:
                return nil
            case .eligible, .unknown:
                break
            @unknown default:
                break
            }
        }

        return discount
    }

    private func localizedPeriodText(for discount: StoreProductDiscount) -> String? {
        let period = discount.subscriptionPeriod
        let totalValue = period.value * max(discount.numberOfPeriods, 1)
        guard totalValue > 0 else { return nil }

        switch period.unit {
        case .day:
            return "\(totalValue)日"
        case .week:
            return "\(totalValue)週間"
        case .month:
            return "\(totalValue)か月"
        case .year:
            return "\(totalValue)年"
        @unknown default:
            return nil
        }
    }
    
    // 安全領域の下部（X系デバイスのホームインジケータ分）
    private var safeAreaBottom: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first?.safeAreaInsets.bottom ?? 0
        }
        return 0
    }

    // MARK: - Logic

    private func updateSelectedPackage(for type: PlanType) {
        switch type {
        case .yearly:
            selectedPackage = rcManager.yearlyPackage
        case .monthly:
            selectedPackage = rcManager.monthlyPackage
        }
    }

    @MainActor
    private func purchaseSelectedPackage() async {
        print("🛒 PremiumView: purchaseSelectedPackage() 開始")
        
        if selectedPackage == nil {
            print("🛒 selectedPackage が nil → refreshPackagesIfNeeded")
            await rcManager.refreshPackagesIfNeeded()
            updateSelectedPackage(for: planType)
        }

        guard let package = selectedPackage else {
            print("❌ selectedPackage が取得できず")
            alertMessage = "購入プランを読み込めませんでした。通信状況を確認して再度お試しください。"
            shouldDismissAfterAlert = false
            showAlert = true
            return
        }
        
        let typeStr = package.storeProduct.productIdentifier.contains("yearly") ? "yearly" : "monthly"
        let startsWithGiftPeriod = eligibleIntroductoryDiscount(for: package)?.paymentMode == .freeTrial
        print("🛒 購入パッケージ: \(package.storeProduct.productIdentifier) (\(package.localizedPriceString))")
        
        AnalyticsService.shared.logPurchaseInitiate(
            planType: typeStr,
            price: package.localizedPriceString,
            trigger: context.rawValue
        )
        
        do {
            print("🛒 rcManager.purchaseWithCancelStatus() 呼び出し中...")
            let (success, isCancelled) = try await rcManager.purchaseWithCancelStatus(package: package)
            print("🛒 結果: success=\(success), isCancelled=\(isCancelled)")
            
            if success {
                // Apple決済成功 → プレミアム付与
                userSettings.updatePremiumStatus(isPremium: true)
                AnalyticsService.shared.logPurchaseSuccess(
                    planType: typeStr,
                    price: package.localizedPriceString,
                    trigger: context.rawValue,
                    totalQuotesViewed: 0,
                    totalFavorites: 0
                )
                if startsWithGiftPeriod {
                    AnalyticsService.shared.logTrialStart(planType: typeStr)
                }
                print("✅ PremiumView: 購入成功アラート表示")
                alertMessage = "プレミアムプランを購入しました！"
                shouldDismissAfterAlert = true
                showAlert = true
            } else if isCancelled {
                // ユーザーが自分でキャンセル → 何も表示しない
                print("🛒 PremiumView: ユーザーキャンセル → UI変更なし")
            } else {
                // success=false, isCancelled=false（通常ありえないが念のため）
                print("⚠️ PremiumView: 予期しない状態 success=false, isCancelled=false")
            }
        } catch {
            // ネットワークエラーなど、決済自体が失敗した場合のみ
            print("❌ PremiumView catch: \(error)")
            AnalyticsService.shared.logPurchaseFail(
                planType: typeStr,
                errorMessage: error.localizedDescription
            )
            alertMessage = "購入に失敗しました: \(error.localizedDescription)"
            shouldDismissAfterAlert = false
            showAlert = true
        }
        print("🛒 PremiumView: purchaseSelectedPackage() 終了")
    }
}
