import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var selectedLargeCategories: Set<QuoteLargeCategory> = []
    @State private var showPremiumAtEnd = false

    // アニメーション用State
    @State private var isFinished = false
    @State private var leftDoorOffset: CGFloat = 0
    @State private var rightDoorOffset: CGFloat = 0
    @State private var lightBeamWidth: CGFloat = 0
    @State private var lightBeamOpacity: Double = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. ドア（背景として機能・最後に開く）
                HStack(spacing: 0) {
                    Color.black
                        .frame(width: proxy.size.width / 2)
                        .offset(x: leftDoorOffset)

                    Color.black
                        .frame(width: proxy.size.width / 2)
                        .offset(x: rightDoorOffset)
                }
                .ignoresSafeArea()

                // 2. 開門時の光のビーム
                if lightBeamOpacity > 0 {
                    Rectangle()
                        .fill(Color.white)
                        .shadow(color: .white, radius: 10, x: 0, y: 0)
                        .shadow(color: .white, radius: 40, x: 0, y: 0)
                        .frame(width: lightBeamWidth)
                        .opacity(lightBeamOpacity)
                        .ignoresSafeArea()
                }

                // 3. コンテンツ
                if !isFinished {
                    if showPremiumAtEnd {
                        PremiumView()
                            .transition(.opacity)
                            .overlay(alignment: .topTrailing) {
                                Button(action: finishOnboarding) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding()
                                }
                            }
                    } else {
                        VStack {
                            TabView(selection: $currentStep) {
                                welcomeStep.tag(0)
                                genreStep.tag(1)
                                notificationStep.tag(2)
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                            bottomBar
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Analytics: 最初のステップ表示
            AnalyticsService.shared.logOnboardingStepView(stepIndex: 0)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Text("ASCENDANCE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(10)
                    .foregroundColor(.white.opacity(0.4))

                Text("たった一行が、\n人生を変えた。")
                    .font(.custom("HiraginoSans-W8", size: 44))
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .lineSpacing(10)
            }
            .padding(.horizontal, 32)

            Text("歴史を動かした者たちは、\n例外なく、ある言葉を握りしめていた。")
                .font(.system(size: 15, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(8)

            Spacer()
        }
    }

    private var genreStep: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("FIELD")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(10)
                    .foregroundColor(.white.opacity(0.4))

                Text("何に、\n火がつく。")
                    .font(.custom("HiraginoSans-W8", size: 32))
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .lineSpacing(8)
            }
            .padding(.top, 60)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(QuoteLargeCategory.allCases, id: \.self) { large in
                        largeCategoryRow(large: large)
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()
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
                        .font(.system(size: 15, weight: .bold))
                        .tracking(3)
                    Text(large.displayEn)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .tracking(4)
                        .opacity(0.5)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .foregroundColor(isSelected ? .black : .white)
            .background(isSelected ? Color.white : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }

    private var notificationStep: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Text("DELIVERY")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(10)
                    .foregroundColor(.white.opacity(0.4))

                Text("朝、目を開けた\nその瞬間から。")
                    .font(.custom("HiraginoSans-W8", size: 32))
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .lineSpacing(8)
            }
            .padding(.horizontal, 32)

            Text("一日の最初に届く言葉が、\nその日の判断をすべて変える。")
                .font(.system(size: 15, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(8)

            Spacer()
        }
    }

    // MARK: - Components

    private var bottomBar: some View {
        VStack(spacing: 24) {
            // Indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(currentStep == index ? Color.white : Color.white.opacity(0.2))
                        .frame(width: currentStep == index ? 24 : 8, height: 2)
                        .animation(.spring(), value: currentStep)
                }
            }

            Button(action: nextStep) {
                Text(currentStep == 2 ? "ENTER" : "CONTINUE")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
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
                let granted = (try? await NotificationService.shared.requestAuthorization()) ?? false
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
        withAnimation(.easeOut(duration: 0.6)) {
            isFinished = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                lightBeamWidth = 2
                lightBeamOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred(intensity: 1.0)

                let screenWidth = UIScreen.main.bounds.width
                withAnimation(.easeIn(duration: 0.8)) {
                    leftDoorOffset = -(screenWidth / 2)
                    rightDoorOffset = screenWidth / 2
                    lightBeamWidth = screenWidth * 1.5
                }

                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    lightBeamOpacity = 0.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    userSettings.completeFirstLaunch()
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onDismiss: {})
        .environmentObject(UserSettings())
}
