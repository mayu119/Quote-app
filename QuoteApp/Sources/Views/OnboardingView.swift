import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void
    @EnvironmentObject private var userSettings: UserSettings
    @State private var currentStep = 0
    @State private var selectedLargeCategories: Set<QuoteLargeCategory> = []
    @State private var showPremiumAtEnd = false
    @State private var isFinished = false

    private let pageBackground = Color(hex: "F1E9E3")
    private let sheetBackground = Color(hex: "FFFCF8")
    private let primaryText = Color(hex: "2F2730")
    private let secondaryText = Color(hex: "7D7280")
    private let accentRose = Color(hex: "EAA3A1")
    private let accentLavender = Color(hex: "8D90A2")
    private let accentSage = Color(hex: "9EB59B")
    private let accentSky = Color(hex: "9FC8D8")
    private let borderColor = Color(hex: "E8DDD6")

    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(
                    colors: [pageBackground, Color(hex: "F7F1EB"), Color(hex: "EFE5DE")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if !isFinished {
                    if showPremiumAtEnd {
                        PremiumView(onDismiss: finishOnboarding)
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 0) {
                            Spacer(minLength: 12)

                            VStack(spacing: 0) {
                                TabView(selection: $currentStep) {
                                    welcomeStep.tag(0)
                                    genreStep.tag(1)
                                    notificationStep.tag(2)
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                                bottomBar
                            }
                            .background(sheetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
                            )
                            .shadow(color: Color(hex: "CDBEB6").opacity(0.35), radius: 28, x: 0, y: 12)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // Analytics: 最初のステップ表示
            AnalyticsService.shared.logOnboardingStepView(stepIndex: 0)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            onboardingHeader(
                eyebrow: "はじめに",
                title: "今の自分に合う言葉を、\n静かに受け取れるように。",
                body: "Words For Meは、偉人の言葉だけでなく、今の自分を整えたり、関係を見直したり、疲れた日に呼吸を戻したりするための言葉を集めるアプリです。"
            )

            VStack(alignment: .leading, spacing: 16) {
                featureCard(
                    icon: "sparkles",
                    title: "今日の気分に近い言葉を届ける",
                    body: "最初に選んだテーマをもとに、読みたい方向へ寄せていきます。",
                    accent: accentRose,
                    tint: Color(hex: "FFF1F4")
                )

                featureCard(
                    icon: "arrow.left.circle.fill",
                    title: "左にスワイプでお気に入り",
                    body: "読み返したい言葉は、左へスワイプするだけで保存できます。",
                    accent: accentLavender,
                    tint: Color(hex: "F3F0FA")
                )

                featureCard(
                    icon: "arrow.right.circle.fill",
                    title: "右にスワイプでシェア",
                    body: "右へスワイプすると、そのままシェア画面へ進めます。",
                    accent: accentSky,
                    tint: Color(hex: "EEF7FB")
                )

                featureCard(
                    icon: "bookmark.fill",
                    title: "言葉の棚をあとで読み返せる",
                    body: "ためた言葉には、ひとことメモも残せます。",
                    accent: accentRose,
                    tint: Color(hex: "FFF1F4")
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private var genreStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            onboardingHeader(
                eyebrow: "好みを選ぶ",
                title: "今ほしい言葉の方向を\n教えてください。",
                body: "複数選択できます。あとから設定でいつでも変えられます。"
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(QuoteLargeCategory.allCases, id: \.self) { large in
                        largeCategoryRow(large: large)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }

    private func largeCategoryRow(large: QuoteLargeCategory) -> some View {
        let isSelected = selectedLargeCategories.contains(large)

        return Button(action: {
            if isSelected {
                selectedLargeCategories.remove(large)
            } else {
                selectedLargeCategories.insert(large)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(large.displayName)
                        .font(.system(size: 18, weight: .bold))

                    Text(onboardingSubtitle(for: large))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? Color.white.opacity(0.78) : secondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Image(systemName: onboardingIcon(for: large))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(onboardingAccent(for: large))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .foregroundColor(isSelected ? .white : primaryText)
            .background(isSelected ? onboardingAccent(for: large) : Color(hex: "F6EFEB"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? onboardingAccent(for: large).opacity(0.15) : borderColor, lineWidth: 1)
            )
            .shadow(color: isSelected ? onboardingAccent(for: large).opacity(0.18) : .clear, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var notificationStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            onboardingHeader(
                eyebrow: "通知",
                title: "思い出したいタイミングで、\n言葉を受け取る。",
                body: "朝に一言ほしい日も、疲れた夕方に支えがほしい日もあります。通知はあとから自由に変えられます。"
            )

            VStack(alignment: .leading, spacing: 16) {
                featureCard(
                    icon: "sun.max.fill",
                    title: "朝のはじまりに",
                    body: "一日の空気を整える言葉を、無理のない温度で届けます。",
                    accent: accentSage,
                    tint: Color(hex: "F6F9EA")
                )

                featureCard(
                    icon: "moon.stars.fill",
                    title: "疲れた夜にも",
                    body: "比較や焦りから少し離れて、自分のペースを戻せる一言を選びます。",
                    accent: accentLavender,
                    tint: Color(hex: "F3F0FA")
                )
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Components

    private var bottomBar: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(currentStep == index ? accentLavender : borderColor)
                        .frame(width: currentStep == index ? 26 : 8, height: 8)
                        .animation(.spring(), value: currentStep)
                }
            }

            Button(action: nextStep) {
                Text(currentStep == 2 ? "はじめる" : "次へ")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentLavender)
                    .clipShape(Capsule())
                    .shadow(color: accentLavender.opacity(0.24), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .padding(.top, 18)
    }

    // MARK: - Actions

    private func nextStep() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if currentStep < 2 {
            // ジャンル選択ステップを終える時に保存（大カテゴリ rawValue を格納）
            if currentStep == 1 {
                let genres = selectedLargeCategories.map { $0.rawValue }
                userSettings.preferredCategories = genres
                // Analytics: ジャンル選択
                AnalyticsService.shared.logOnboardingGenreSelect(genres: genres)
                AnalyticsService.shared.updatePreferredCategories(genres)
            }

            withAnimation(.spring()) {
                currentStep += 1
            }
            // Analytics: ステップ表示
            AnalyticsService.shared.logOnboardingStepView(stepIndex: currentStep + 1)
        } else {
            // 通知権限リクエスト
            Task {
                let status = await NotificationService.shared.getAuthorizationStatus()
                let granted: Bool

                switch status {
                case .notDetermined:
                    granted = (try? await NotificationService.shared.requestAuthorization()) ?? false
                case .authorized, .provisional, .ephemeral:
                    granted = true
                default:
                    granted = false
                }

                // Analytics: オンボーディング完了
                AnalyticsService.shared.logOnboardingComplete(
                    selectedGenreCount: selectedLargeCategories.count,
                    notificationGranted: granted
                )
                await MainActor.run {
                    withAnimation {
                        showPremiumAtEnd = true
                    }
                }
            }
        }
    }

    private func finishOnboarding() {
        withAnimation(.easeOut(duration: 0.25)) {
            isFinished = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            userSettings.completeFirstLaunch()
            onDismiss()
        }
    }

    private func onboardingHeader(eyebrow: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accentLavender)
                .tracking(0.8)

            Text(title)
                .font(.system(size: 31, weight: .bold))
                .foregroundColor(primaryText)
                .lineSpacing(5)

            Text(body)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
                .lineSpacing(4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private func featureCard(icon: String, title: String, body: String, accent: Color, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint)
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(primaryText)
                Text(body)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(secondaryText)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(18)
        .background(Color(hex: "F6EFEB"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func onboardingAccent(for category: QuoteLargeCategory) -> Color {
        switch category {
        case .selfGrowth:
            return accentRose
        case .relationships:
            return accentSky
        case .reset:
            return accentLavender
        }
    }

    private func onboardingIcon(for category: QuoteLargeCategory) -> String {
        switch category {
        case .selfGrowth:
            return "sparkles"
        case .relationships:
            return "heart.fill"
        case .reset:
            return "moon.stars.fill"
        }
    }

    private func onboardingSubtitle(for category: QuoteLargeCategory) -> String {
        switch category {
        case .selfGrowth:
            return "自分の軸や自己肯定感を整えたい"
        case .relationships:
            return "恋愛・家族・人とのつながりを見つめたい"
        case .reset:
            return "疲れた日や比較で揺れた心を休ませたい"
        }
    }
}

#Preview {
    OnboardingView(onDismiss: {})
        .environmentObject(UserSettings())
}
