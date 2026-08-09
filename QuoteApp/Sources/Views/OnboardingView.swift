import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void

    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep = 0
    @State private var selectedFocus: QuoteLargeCategory? = nil
    @State private var selectedTopics: Set<QuoteMediumCategory> = []
    @State private var selectedTone: WordTone? = nil
    @State private var selectedAtmosphere: VisualAtmosphere? = nil
    @State private var selectedReminder: ReminderPreference? = nil
    @State private var contentVisible = false
    @State private var showPremiumAtEnd = false
    @State private var showPrescription = false
    @State private var isFinished = false
    @State private var prescriptionQuote: Quote? = nil

    private let pageBackground = Color(hex: "F1E9E3")
    private let sheetBackground = Color(hex: "FFFCF8")
    private let primaryText = Color(hex: "2F2730")
    private let secondaryText = Color(hex: "7D7280")
    private let accentRose = Color(hex: "EAA3A1")
    private let accentLavender = Color(hex: "8D90A2")
    private let accentSage = Color(hex: "9EB59B")
    private let accentSky = Color(hex: "9FC8D8")
    private let borderColor = Color(hex: "E8DDD6")
    private let stepCount = 5

    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(
                    colors: [
                        pageBackground,
                        heroAccent.opacity(0.16),
                        Color(hex: "F7F1EB"),
                        Color(hex: "EFE5DE")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ambientGlow

                if !isFinished {
                    if showPremiumAtEnd {
                        PremiumView(context: .onboarding, onDismiss: finishOnboarding)
                            .transition(.opacity)
                    } else if showPrescription {
                        PrescriptionRevealView(
                            focusTitle: selectedFocus?.displayName ?? "今の自分",
                            tags: previewTags,
                            tone: prescriptionTone,
                            quote: prescriptionQuote,
                            onContinue: {
                                withAnimation(WFM.Motion.quick) {
                                    showPrescription = false
                                    showPremiumAtEnd = true
                                }
                            },
                            onSkip: finishOnboarding
                        )
                        .transition(.opacity)
                    } else {
                        VStack(spacing: 0) {
                            Spacer(minLength: 12)

                            VStack(spacing: 0) {
                                headerBar

                                stepBody
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                                bottomBar
                            }
                            .background(sheetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
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
            contentVisible = true
            AnalyticsService.shared.logOnboardingStepView(stepIndex: currentStep)
        }
        .onChange(of: currentStep) { _, newValue in
            contentVisible = false
            withAnimation(.spring(response: 0.48, dampingFraction: 0.9)) {
                contentVisible = true
            }
            AnalyticsService.shared.logOnboardingStepView(stepIndex: newValue)
        }
    }

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(heroAccent.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 22)
                .offset(x: 150, y: -250)

            Circle()
                .fill(accentRose.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 28)
                .offset(x: -140, y: 260)
        }
        .allowsHitTesting(false)
    }

    private var headerBar: some View {
        VStack(spacing: 18) {
            HStack {
                if currentStep > 0 {
                    Button(action: previousStep) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                    }
                } else {
                    Color.clear.frame(width: 84, height: 40)
                }

                Spacer()

                Text("\(currentStep + 1)/\(stepCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "F6EFEB"))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? heroAccent : borderColor)
                        .frame(width: index == currentStep ? 30 : 8, height: 8)
                        .animation(.spring(response: 0.36, dampingFraction: 0.9), value: currentStep)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    private var stepBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader

                Group {
                    switch currentStep {
                    case 0:
                        focusStep
                    case 1:
                        topicsStep
                    case 2:
                        toneStep
                    case 3:
                        atmosphereStep
                    default:
                        reminderStep
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)

                previewCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentEyebrow)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(heroAccent)
                .tracking(0.8)

            Text(currentTitle)
                .font(.system(size: 31, weight: .bold))
                .foregroundColor(primaryText)
                .lineSpacing(4)

            Text(currentBody)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
                .lineSpacing(4)
        }
    }

    private var focusStep: some View {
        VStack(spacing: 14) {
            ForEach(QuoteLargeCategory.allCases, id: \.self) { category in
                let isSelected = selectedFocus == category
                selectionCard(
                    title: category.displayName,
                    subtitle: focusSubtitle(for: category),
                    icon: focusIcon(for: category),
                    isSelected: isSelected,
                    accent: accent(for: category)
                ) {
                    selectedFocus = category
                    // 大枠が変わったら、その大枠に属さない中カテゴリは外す
                    selectedTopics = Set(selectedTopics.filter { $0.largeCategory == category })
                }
            }
        }
    }

    private var topicsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let selectedFocus {
                Text(mediumOptions(for: selectedFocus).count >= 2
                     ? "2つ以上選ぶと、その方向に寄せた言葉の棚が最初から整います。"
                     : "このテーマだけで、まっすぐ整えます。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(secondaryText)

                VStack(spacing: 12) {
                    ForEach(mediumOptions(for: selectedFocus), id: \.self) { medium in
                        let isSelected = selectedTopics.contains(medium)
                        selectionCard(
                            title: medium.displayTitleJa,
                            subtitle: mediumSubtitle(for: medium),
                            icon: mediumIcon(for: medium),
                            isSelected: isSelected,
                            accent: accent(for: selectedFocus)
                        ) {
                            if isSelected {
                                selectedTopics.remove(medium)
                            } else {
                                selectedTopics.insert(medium)
                            }
                        }
                    }
                }
            }
        }
    }

    private var toneStep: some View {
        VStack(spacing: 14) {
            ForEach(WordTone.allCases, id: \.self) { tone in
                let isSelected = selectedTone == tone
                selectionCard(
                    title: tone.title,
                    subtitle: tone.subtitle,
                    icon: tone.icon,
                    isSelected: isSelected,
                    accent: tone.accent
                ) {
                    selectedTone = tone
                }
            }
        }
    }

    private var atmosphereStep: some View {
        VStack(spacing: 14) {
            ForEach(VisualAtmosphere.allCases, id: \.self) { atmosphere in
                let isSelected = selectedAtmosphere == atmosphere
                Button(action: {
                    selectCard()
                    selectedAtmosphere = atmosphere
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: atmosphere.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)

                            Image(systemName: atmosphere.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white.opacity(0.94))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(atmosphere.title)
                                .font(.system(size: 18, weight: .bold))
                            Text(atmosphere.subtitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isSelected ? Color.white.opacity(0.78) : secondaryText)
                            Text(atmosphere.backgrounds.prefix(2).map(prettyBackgroundName).joined(separator: " / "))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isSelected ? Color.white.opacity(0.72) : secondaryText.opacity(0.88))
                        }

                        Spacer()

                        selectionIndicator(isSelected: isSelected, accent: atmosphere.gradientColors.first ?? accentLavender)
                    }
                    .foregroundColor(isSelected ? .white : primaryText)
                    .padding(18)
                    .background(
                        Group {
                            if isSelected {
                                LinearGradient(
                                    colors: atmosphere.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color(hex: "F6EFEB")
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.14) : borderColor, lineWidth: 1)
                    )
                    .shadow(color: isSelected ? atmosphere.gradientColors.last?.opacity(0.24) ?? .clear : .clear, radius: 16, x: 0, y: 10)
                    .scaleEffect(isSelected ? 1.01 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("通知を使わない場合も、ここで明示的に選んでください。")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryText)

            VStack(spacing: 12) {
                ForEach(ReminderPreference.allCases, id: \.self) { reminder in
                    let isSelected = selectedReminder == reminder
                    selectionCard(
                        title: reminder.title,
                        subtitle: reminder.subtitle,
                        icon: reminder.icon,
                        isSelected: isSelected,
                        accent: reminder.accent
                    ) {
                        selectedReminder = reminder
                    }
                }
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("あなた向けの受け取り方")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryText)

                Spacer()

                Text(previewEyebrow)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(heroAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }

            Text(previewTitle)
                .font(.system(size: 21, weight: .bold))
                .foregroundColor(primaryText)
                .lineSpacing(3)

            Text(previewBody)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryText)
                .lineSpacing(4)

            if !previewTags.isEmpty {
                FlexibleTagLayout(tags: previewTags, accent: heroAccent)
            }
        }
        .padding(20)
        .background(Color(hex: "F8F3EF"))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }

            Button(action: nextStep) {
                Text(currentStep == stepCount - 1 ? "この内容ではじめる" : "次へ")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isCurrentStepValid ? heroAccent : borderColor)
                    .clipShape(Capsule())
                    .shadow(color: isCurrentStepValid ? heroAccent.opacity(0.26) : .clear, radius: 12, x: 0, y: 6)
            }
            .disabled(!isCurrentStepValid)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .padding(.top, 14)
    }

    private var currentEyebrow: String {
        switch currentStep {
        case 0: return "STEP 1"
        case 1: return "STEP 2"
        case 2: return "STEP 3"
        case 3: return "STEP 4"
        default: return "STEP 5"
        }
    }

    private var currentTitle: String {
        switch currentStep {
        case 0:
            return "まず、今の自分に\nいちばん近い方向を選ぶ。"
        case 1:
            return "その中でも、\n特に受け取りたいテーマを選ぶ。"
        case 2:
            return "言葉の温度感を\n決めておきましょう。"
        case 3:
            return "開いた瞬間の空気も、\nあなた寄りに整える。"
        default:
            return "受け取りたい時間を\n明確にしておく。"
        }
    }

    private var currentBody: String {
        switch currentStep {
        case 0:
            return "未選択のまま進めず、最初からあなたの状態に寄せていきます。"
        case 1:
            return "複数選択できます。あとから設定でいつでも変えられます。"
        case 2:
            return "同じテーマでも、寄り添う言葉がいい日と、背中を押されたい日があります。"
        case 3:
            return "背景の空気感もパーソナライズして、ただの名言一覧ではない体験にします。"
        default:
            return "通知を使わない場合もここで選択して、初期体験の曖昧さをなくします。"
        }
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return selectedFocus != nil
        case 1:
            guard let selectedFocus else { return selectedTopics.count >= 2 }
            let required = min(2, mediumOptions(for: selectedFocus).count)
            return selectedTopics.count >= required
        case 2:
            return selectedTone != nil
        case 3:
            return selectedAtmosphere != nil
        default:
            return selectedReminder != nil
        }
    }

    private var validationMessage: String? {
        guard !isCurrentStepValid else { return nil }
        switch currentStep {
        case 0:
            return "まずは今の自分に近い方向をひとつ選んでください。"
        case 1:
            if let selectedFocus, mediumOptions(for: selectedFocus).count < 2 {
                return "このテーマを選んでください。"
            }
            return "テーマを2つ以上選ぶと、最初の言葉がぶれません。"
        case 2:
            return "受け取りたい言葉の温度をひとつ選んでください。"
        case 3:
            return "世界観をひとつ選んで、開いた瞬間の印象を整えます。"
        default:
            return "通知あり/なしを含めて、受け取り方をひとつ選んでください。"
        }
    }

    private var heroAccent: Color {
        if let selectedAtmosphere {
            return selectedAtmosphere.gradientColors.first ?? accentLavender
        }
        if let selectedTone {
            return selectedTone.accent
        }
        if let selectedFocus {
            return accent(for: selectedFocus)
        }
        return accentLavender
    }

    private var previewEyebrow: String {
        selectedTone?.title ?? "PERSONALIZED"
    }

    private var previewTitle: String {
        guard let selectedFocus else {
            return "今の自分に必要な言葉を、最初から曖昧にしない。"
        }

        let toneLabel = selectedTone?.previewPrefix ?? "やわらかく"
        return "\(selectedFocus.displayName)を軸に、\(toneLabel)受け取れる言葉の棚を作ります。"
    }

    private var previewBody: String {
        let sortedTopics = QuoteMediumCategory.allCases.filter { selectedTopics.contains($0) }
        let topicText = sortedTopics.isEmpty
            ? "まだ細かいテーマは未選択です。"
            : sortedTopics.map(\.displayTitleJa).joined(separator: "・") + " を優先して混ぜます。"

        let atmosphereText = selectedAtmosphere?.subtitle ?? "背景の空気感もここで決められます。"
        let reminderText = selectedReminder?.previewText ?? "通知の受け取り方も最後に固定します。"
        return "\(topicText) \(atmosphereText) \(reminderText)"
    }

    private var previewTags: [String] {
        var tags: [String] = []

        if let selectedFocus {
            tags.append(selectedFocus.displayName)
        }

        let sortedTopics = QuoteMediumCategory.allCases.filter { selectedTopics.contains($0) }
        tags.append(contentsOf: sortedTopics.prefix(3).map(\.displayTitleJa))

        if let selectedAtmosphere {
            tags.append(selectedAtmosphere.title)
        }

        if let selectedReminder {
            tags.append(selectedReminder.shortLabel)
        }

        return tags
    }

    private func nextStep() {
        guard isCurrentStepValid else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if currentStep < stepCount - 1 {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                currentStep += 1
            }
            return
        }

        applySelections()

        Task {
            let granted = await requestNotificationIfNeeded()

            AnalyticsService.shared.logOnboardingGenreSelect(genres: userSettings.preferredCategories)
            AnalyticsService.shared.updatePreferredCategories(userSettings.preferredCategories)
            AnalyticsService.shared.logOnboardingComplete(
                selectedGenreCount: userSettings.preferredCategories.count,
                notificationGranted: granted
            )

            let dataService = QuoteDataService(modelContext: modelContext)
            let fetchedQuote = try? await dataService.getDailyQuotes(
                limit: 1,
                isPremium: userSettings.isPremiumUser,
                preferredCategories: userSettings.preferredCategories,
                affinityScores: userSettings.categoryAffinityScores
            ).first

            await MainActor.run {
                prescriptionQuote = fetchedQuote
                withAnimation(.easeInOut(duration: 0.28)) {
                    showPrescription = true
                }
            }
        }
    }

    private var prescriptionTone: PrescriptionTone {
        switch selectedTone {
        case .gentle: return .gentle
        case .direct: return .direct
        case .deep, .none: return .deep
        }
    }

    private func previousStep() {
        guard currentStep > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
            currentStep -= 1
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

    private func applySelections() {
        guard let selectedFocus, let selectedTone, let selectedAtmosphere, let selectedReminder else { return }

        let preferred = [selectedFocus.rawValue] + selectedTopics.map(\.rawValue)
        userSettings.preferredCategories = deduplicated(preferred)
        userSettings.categoryAffinityScores = buildAffinityScores(
            focus: selectedFocus,
            topics: Array(selectedTopics),
            tone: selectedTone
        )
        userSettings.selectedBackgrounds = selectedAtmosphere.backgrounds
        userSettings.selectedBackgroundIndex = 0

        if let reminderDate = selectedReminder.date {
            userSettings.notificationEnabled = true
            userSettings.updateNotificationTime(reminderDate)
        } else {
            userSettings.notificationEnabled = false
        }
    }

    private func requestNotificationIfNeeded() async -> Bool {
        guard let selectedReminder else { return false }
        guard let reminderDate = selectedReminder.date else { return false }

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

        AnalyticsService.shared.logNotificationPermission(granted: granted)

        guard granted else {
            await MainActor.run {
                userSettings.notificationEnabled = false
            }
            return false
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderDate)
        let minute = calendar.component(.minute, from: reminderDate)
        try? await NotificationService.shared.scheduleDailyNotification(hour: hour, minute: minute)
        return true
    }

    private func buildAffinityScores(
        focus: QuoteLargeCategory,
        topics: [QuoteMediumCategory],
        tone: WordTone
    ) -> [String: Int] {
        var scores: [String: Int] = [:]

        let focusMediums = mediumOptions(for: focus)
        for medium in focusMediums {
            scores[medium.rawValue] = 2
        }

        for medium in topics {
            scores[medium.rawValue] = (scores[medium.rawValue] ?? 0) + 6
        }

        for medium in tone.boostCategories {
            scores[medium.rawValue] = (scores[medium.rawValue] ?? 0) + 3
        }

        return scores
    }

    private func mediumOptions(for large: QuoteLargeCategory) -> [QuoteMediumCategory] {
        QuoteMediumCategory.allCases.filter { $0.largeCategory == large }
    }

    private func accent(for category: QuoteLargeCategory) -> Color {
        switch category {
        case .selfGrowth:
            return accentRose
        case .relationships:
            return accentSky
        case .reset:
            return accentLavender
        }
    }

    private func focusSubtitle(for category: QuoteLargeCategory) -> String {
        switch category {
        case .selfGrowth:
            return "自己肯定感や軸を立て直し、前に進むための言葉を集める"
        case .relationships:
            return "恋愛、家族、人間関係の揺れを見つめ直す言葉を優先する"
        case .reset:
            return "疲れた日や比較で沈んだ時に、呼吸を戻す言葉を中心にする"
        }
    }

    private func focusIcon(for category: QuoteLargeCategory) -> String {
        switch category {
        case .selfGrowth:
            return "sparkles"
        case .relationships:
            return "heart.fill"
        case .reset:
            return "moon.stars.fill"
        }
    }

    private func mediumSubtitle(for medium: QuoteMediumCategory) -> String {
        switch medium {
        case .selfLove:
            return "自分を責める流れをやわらげたい"
        case .positive:
            return "沈んだ視点を少し上向きに戻したい"
        case .courage:
            return "一歩踏み出す火種がほしい"
        case .innerStrength:
            return "揺れない芯を作りたい"
        case .loveCrush:
            return "好きな人との距離感や気持ちを見つめたい"
        case .familyLove:
            return "家族との関係をやさしく整えたい"
        case .forMyChild:
            return "大切な存在に向けた視点を持ちたい"
        case .relationships:
            return "人との摩擦や疲れを整理したい"
        case .wantToQuit:
            return "限界を感じる日に立て直したい"
        case .affirmation:
            return "今の自分に入れたい言葉を増やしたい"
        }
    }

    private func mediumIcon(for medium: QuoteMediumCategory) -> String {
        switch medium {
        case .selfLove:
            return "heart.circle.fill"
        case .positive:
            return "sun.max.fill"
        case .courage:
            return "bolt.heart.fill"
        case .innerStrength:
            return "shield.lefthalf.filled"
        case .loveCrush:
            return "sparkles"
        case .familyLove:
            return "house.fill"
        case .forMyChild:
            return "figure.and.child.holdinghands"
        case .relationships:
            return "person.2.fill"
        case .wantToQuit:
            return "cloud.rain.fill"
        case .affirmation:
            return "character.bubble.fill"
        }
    }

    private func prettyBackgroundName(_ name: String) -> String {
        switch name {
        case "blush_garden":
            return "やわらかな庭"
        case "pink_sunrise":
            return "朝焼け"
        case "lavender_morning":
            return "ラベンダー"
        case "sunlit_atrium":
            return "光のアトリウム"
        case "golden_coast":
            return "金色の海辺"
        case "emerald_valley":
            return "エメラルドの谷"
        case "purple_moon":
            return "夜の月"
        case "aurora":
            return "オーロラ"
        case "sakura_lake":
            return "桜の湖"
        default:
            return name.replacingOccurrences(of: "_", with: " ")
        }
    }

    private func selectionCard(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            selectCard()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                action()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.18) : accent.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : secondaryText)
                        .lineSpacing(2)
                }

                Spacer()

                selectionIndicator(isSelected: isSelected, accent: accent)
            }
            .foregroundColor(isSelected ? .white : primaryText)
            .padding(18)
            .background(isSelected ? accent : Color(hex: "F6EFEB"))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.12) : borderColor, lineWidth: 1)
            )
            .shadow(color: isSelected ? accent.opacity(0.22) : .clear, radius: 16, x: 0, y: 10)
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func selectionIndicator(isSelected: Bool, accent: Color) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.white : Color.clear)
                .frame(width: 28, height: 28)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accent)
            } else {
                Circle()
                    .stroke(accent.opacity(0.36), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
    }

    private func selectCard() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

private enum WordTone: String, CaseIterable {
    case gentle
    case direct
    case deep

    var title: String {
        switch self {
        case .gentle:
            return "やさしく受け取りたい"
        case .direct:
            return "背中を押してほしい"
        case .deep:
            return "深く静かに読みたい"
        }
    }

    var subtitle: String {
        switch self {
        case .gentle:
            return "責めるより整える。呼吸が浅い日に合う温度感。"
        case .direct:
            return "少し強めでも、行動に火がつく言葉を優先。"
        case .deep:
            return "答えを急がず、余白のある言葉をじっくり読む。"
        }
    }

    var icon: String {
        switch self {
        case .gentle:
            return "hands.sparkles.fill"
        case .direct:
            return "bolt.fill"
        case .deep:
            return "moon.zzz.fill"
        }
    }

    var accent: Color {
        switch self {
        case .gentle:
            return Color(hex: "D99AA3")
        case .direct:
            return Color(hex: "F09B63")
        case .deep:
            return Color(hex: "8B8AAE")
        }
    }

    var previewPrefix: String {
        switch self {
        case .gentle:
            return "やわらかく"
        case .direct:
            return "少し力強く"
        case .deep:
            return "静かに深く"
        }
    }

    var boostCategories: [QuoteMediumCategory] {
        switch self {
        case .gentle:
            return [.selfLove, .familyLove, .affirmation]
        case .direct:
            return [.courage, .positive, .innerStrength]
        case .deep:
            return [.relationships, .wantToQuit, .affirmation]
        }
    }
}

private enum VisualAtmosphere: String, CaseIterable {
    case softBloom
    case clearLift
    case quietNight

    var title: String {
        switch self {
        case .softBloom:
            return "やわらかい余白"
        case .clearLift:
            return "光が差す感じ"
        case .quietNight:
            return "静かな夜の深さ"
        }
    }

    var subtitle: String {
        switch self {
        case .softBloom:
            return "感情が尖りすぎない、やさしい質感で受け取る。"
        case .clearLift:
            return "沈みすぎず、視界が少し開く方向の空気感。"
        case .quietNight:
            return "ひとりで深く読みたい日に合う静かなトーン。"
        }
    }

    var icon: String {
        switch self {
        case .softBloom:
            return "sparkles"
        case .clearLift:
            return "sun.max.fill"
        case .quietNight:
            return "moon.stars.fill"
        }
    }

    var backgrounds: [String] {
        switch self {
        case .softBloom:
            return ["blush_garden", "pink_sunrise", "lavender_morning", "sakura_lake", "flower_field"]
        case .clearLift:
            return ["sunlit_atrium", "golden_coast", "emerald_valley", "italy_city", "sakura_lake"]
        case .quietNight:
            return ["purple_moon", "aurora", "lighthouse", "fireplace", "rainy_house"]
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .softBloom:
            return [Color(hex: "E5A7B5"), Color(hex: "C88999")]
        case .clearLift:
            return [Color(hex: "F1C06B"), Color(hex: "D7854B")]
        case .quietNight:
            return [Color(hex: "8D90B9"), Color(hex: "5D628C")]
        }
    }
}

private enum ReminderPreference: String, CaseIterable {
    case morning
    case afternoon
    case night
    case off

    var title: String {
        switch self {
        case .morning:
            return "朝に受け取る"
        case .afternoon:
            return "昼に立て直す"
        case .night:
            return "夜に静かに読む"
        case .off:
            return "今は通知を使わない"
        }
    }

    var subtitle: String {
        switch self {
        case .morning:
            return "7:30ごろ。一日の最初の空気を整える。"
        case .afternoon:
            return "12:30ごろ。流れが乱れやすい時間に戻す。"
        case .night:
            return "21:30ごろ。比較や疲れをほどいて締める。"
        case .off:
            return "通知なしで始めて、必要になったらあとから設定する。"
        }
    }

    var icon: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .afternoon:
            return "sun.max.fill"
        case .night:
            return "moon.fill"
        case .off:
            return "bell.slash.fill"
        }
    }

    var accent: Color {
        switch self {
        case .morning:
            return Color(hex: "E6A36A")
        case .afternoon:
            return Color(hex: "D49362")
        case .night:
            return Color(hex: "8C8FB5")
        case .off:
            return Color(hex: "A5A2A8")
        }
    }

    var date: Date? {
        let calendar = Calendar.current
        switch self {
        case .morning:
            return calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())
        case .afternoon:
            return calendar.date(bySettingHour: 12, minute: 30, second: 0, of: Date())
        case .night:
            return calendar.date(bySettingHour: 21, minute: 30, second: 0, of: Date())
        case .off:
            return nil
        }
    }

    var previewText: String {
        switch self {
        case .morning:
            return "朝の最初に言葉を受け取る設定にします。"
        case .afternoon:
            return "昼の立て直しに合わせて言葉を届けます。"
        case .night:
            return "夜に落ち着いて受け取れるように整えます。"
        case .off:
            return "通知なしで始め、読むタイミングは自分で選べます。"
        }
    }

    var shortLabel: String {
        switch self {
        case .morning:
            return "朝"
        case .afternoon:
            return "昼"
        case .night:
            return "夜"
        case .off:
            return "通知なし"
        }
    }
}

private struct FlexibleTagLayout: View {
    let tags: [String]
    let accent: Color

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    tagView(tag)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    tagView(tag)
                }
            }
        }
    }

    private func tagView(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accent.opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    OnboardingView(onDismiss: {})
        .environmentObject(UserSettings())
}
