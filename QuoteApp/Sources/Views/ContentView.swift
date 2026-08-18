import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    @AppStorage("lastDailyDrawPresentedDate") private var lastDailyDrawPresentedDate = ""

    @State private var isLoading = true
    @State private var dailyQuotes: [Quote] = []
    @State private var weeklyFavoriteSummary = QuoteDataService.WeeklyFavoriteSummary(favoriteCount: 0, topCategory: nil)
    @State private var favoriteRecommendation: QuoteDataService.FavoriteRecommendation?

    // シート管理
    @State private var activeSheet: SheetType?

    // フルスクリーンカバー管理（2つを1つのenumで統一 → 競合防止）
    @State private var activeCover: CoverType?

    // スクロール追跡
    @State private var visibleQuoteId: String?
    /// セッション中に既に見た名言ID（戻りスクロールでカウントしないため）
    @State private var seenQuoteIds: Set<String> = []
    @State private var showInteractionGuide = false
    @State private var interactionGuideStage: InteractionGuideOverlay.Stage = .verticalSwipe
    @State private var interactionGuideCompletedCount: Int = 0
    @State private var showInteractionGuideCelebration = false
    @State private var interactionGuideCelebrationMessage: String = ""
    @State private var showStreakRescue = false
    
    /// 日替わり無料カテゴリの1日上限
    private let dailyFreeLimitCategory = Config.freeUserCategorySwipeLimit
    
    /// 現在表示中のカテゴリが日替わり無料カテゴリかどうか
    private var isViewingFreeCategory: Bool {
        guard let medium = selectedMediumCategory else { return false }
        return medium == userSettings.currentFreeMediumCategory
    }

    /// 無料ユーザーの日替わり無料カテゴリ閲覧時のみ制限する
    private var isCategoryLimitedForFreeUser: Bool {
        !userSettings.isPremiumUser && isViewingFreeCategory
    }
    
    /// 現在のモードに応じた上限値
    private var currentLimit: Int {
        isCategoryLimitedForFreeUser ? dailyFreeLimitCategory : 0
    }

    /// 無料カテゴリでは11枚目にロックプレビューを差し込む
    private var currentFetchLimit: Int {
        isCategoryLimitedForFreeUser ? dailyFreeLimitCategory + 1 : 0
    }
    
    /// 現在のモードに応じたスワイプカウント
    private var currentSwipeCount: Int {
        isCategoryLimitedForFreeUser ? userSettings.dailyFreeCategorySwipeCount : 0
    }
    
    /// 現在のモードで制限に達しているか
    private var hasReachedCurrentLimit: Bool {
        isCategoryLimitedForFreeUser && currentSwipeCount >= currentLimit
    }

    private var previewCardIndex: Int {
        Config.freeUserCategoryPreviewIndex
    }

    // カテゴリ管理（選択中のフィルタ）
    @State private var selectedMediumCategory: QuoteMediumCategory? = nil
    @State private var selectedLargeCategory: QuoteLargeCategory? = nil
    @State private var selectedSpiritualBundle: SpiritualBundle? = nil
    @State private var activeRitualBackgroundName: String? = nil
    @State private var isTransitioningCategory = false

    // 背景管理
    @StateObject private var backgroundService = BackgroundService()

    // MARK: - Enums

    enum SheetType: Identifiable {
        case settings, favorites, archive, wallpaperPicker, categoryPicker, calendar
        var id: Int { hashValue }
    }

    /// フルスクリーンカバーを一本化して競合を排除
    enum CoverType: Identifiable {
        case premiumWall(PaywallContext)
        case onboarding
        case dailyDraw(Quote)
        case dailyCheckIn
        case dailyRitual
        case nightWord(Quote)
        var id: String {
            switch self {
            case .premiumWall(let context): return "premium_\(context.rawValue)"
            case .onboarding: return "onboarding"
            case .dailyDraw(let quote): return "daily_draw_\(quote.id)"
            case .dailyCheckIn: return "daily_check_in"
            case .dailyRitual: return "daily_ritual"
            case .nightWord(let quote): return "night_\(quote.id)"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    quoteScrollView(backgroundName: currentBackgroundName)
                }
            }
            .opacity(isTransitioningCategory ? 0.0 : 1.0)

            if isTransitioningCategory {
                Color.black.ignoresSafeArea()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .zIndex(50)
            }

            if showInteractionGuide {
                InteractionGuideOverlay(
                    stage: interactionGuideStage,
                    completedCount: interactionGuideCompletedCount
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(120)
            }

            if showInteractionGuide {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: skipInteractionGuide) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                Text("スキップ")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color(red: 0.20, green: 0.16, blue: 0.20))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.88))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                    Spacer()
                }
                .zIndex(130)
            }

            if showInteractionGuideCelebration {
                guideCelebration
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(140)
            }

            if showStreakRescue {
                streakRescueBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(150)
            }
        }
        .task {
            await initializeCoreData()
        }
        // isFirstLaunch が true になったらオンボーディングを表示
        .onChange(of: userSettings.isFirstLaunch) { _, newValue in
            if newValue && activeCover == nil {
                activeCover = .onboarding
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .favorites:
                FavoritesView(quoteDataService: QuoteDataService(modelContext: modelContext))
            case .archive:
                ArchiveView()
            case .calendar:
                CalendarShelfView()
                    .environmentObject(userSettings)
            case .wallpaperPicker:
                WallpaperPickerView(
                    onPremiumRequired: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            activeCover = .premiumWall(.wallpaper)
                        }
                    }
                )
            case .categoryPicker:
                CategoryPickerView(
                    selectedMediumCategory: $selectedMediumCategory,
                    selectedLargeCategory: $selectedLargeCategory,
                    onSelect: { medium, large in
                        switchCategory(medium: medium, large: large)
                    },
                    onPremiumRequired: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            activeCover = .premiumWall(.categoryLock)
                        }
                    }
                )
                .environmentObject(userSettings)
            }
        }
        // 単一の fullScreenCover で premium / onboarding 両方を管理
        .fullScreenCover(item: $activeCover) { cover in
            switch cover {
            case .premiumWall(let context):
                PremiumView(context: context)
                    .environmentObject(userSettings)
            case .onboarding:
                OnboardingView(onDismiss: {
                    // 初回オンボーディングの処方箋を、その日の最初の一枚として扱う。
                    markDailyDrawPresented()
                    activeCover = nil
                    Task {
                        await reloadDailyQuotesAfterOnboarding()
                    }
                    if !userSettings.hasSeenInteractionGuide {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                showInteractionGuide = true
                            }
                        }
                    }
                })
                    .environmentObject(userSettings)
            case .dailyDraw(let quote):
                DailyDrawView(
                    quote: quote,
                    isNight: isNightTime(),
                    onSave: { saveDailyDrawQuote(quote) },
                    onClose: dismissDailyDrawAndContinue,
                    onDeck: dismissDailyDrawAndContinue,
                    onSkip: dismissDailyDrawAndContinue
                )
            case .dailyCheckIn:
                DailyCheckInView(
                    streakDays: userSettings.currentStreakDays,
                    weeklySaveCount: weeklyFavoriteSummary.favoriteCount,
                    topCategoryTitle: weeklyFavoriteSummary.topCategory?.displayTitleJa,
                    freeCategoryTitle: userSettings.currentFreeMediumCategory.displayTitleJa,
                    recommendation: favoriteRecommendation?.quote.punchline,
                    onStart: {
                        userSettings.markDailyCheckInPresented()
                        activeCover = nil
                    },
                    onPremium: {
                        userSettings.markDailyCheckInPresented()
                        activeCover = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            activeCover = .premiumWall(.general)
                        }
                    }
                )
                .environmentObject(userSettings)
            case .dailyRitual:
                if Config.enableSpiritualRitual {
                    DailyRitualView(
                        selectedBundle: selectedSpiritualBundle,
                        onClose: {
                            activeCover = nil
                        },
                        onPremiumRequired: {
                            activeCover = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                activeCover = .premiumWall(.general)
                            }
                        },
                        onStart: { bundle in
                            activeCover = nil
                            userSettings.saveDailyRitual(bundle: bundle)
                            switchSpiritualBundle(bundle)
                        }
                    )
                    .environmentObject(userSettings)
                }
            case .nightWord(let quote):
                NightWordView(quote: quote) {
                    activeCover = nil
                }
                .environmentObject(userSettings)
            }
        }
    }

    // MARK: - Quote ScrollView

    @ViewBuilder
    private func quoteScrollView(backgroundName: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(dailyQuotes.enumerated()), id: \.element.id) { index, quote in
                    quoteCell(index: index, quote: quote, backgroundName: backgroundName)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleQuoteId)
        .ignoresSafeArea(.all)
        .onChange(of: visibleQuoteId) { oldId, newId in
            guard oldId != newId, let newId else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            // ★ 無料ユーザー: 「まだ見ていない新しい名言」へのスクロールのみカウント増加
            // 戻りスクロールではカウントしない & 制限到達後は増加しない
            if !userSettings.isPremiumUser, oldId != nil,
               !seenQuoteIds.contains(newId), !hasReachedCurrentLimit {
                if isViewingFreeCategory {
                    userSettings.incrementFreeCategorySwipeCount()
                } else {
                    userSettings.incrementSwipeCount()
                }
            }
            seenQuoteIds.insert(newId)
            
                if let idx = dailyQuotes.firstIndex(where: { $0.id == newId }) {
                    let currentQuote = dailyQuotes[idx]

                // Analytics: 名言表示
                AnalyticsService.shared.logQuoteView(
                    quoteId: currentQuote.id,
                    author: currentQuote.author,
                    categoryMedium: currentQuote.category.rawValue,
                    categoryLarge: currentQuote.category.largeCategory.rawValue,
                    quoteIndex: idx + 1,
                    isPremium: userSettings.isPremiumUser
                )

                // Analytics: スワイプ
                if let oldId {
                    AnalyticsService.shared.logQuoteSwipe(
                        fromQuoteId: oldId,
                        toQuoteIndex: idx + 1,
                        swipeCountInSession: idx + 1
                    )
                }

                if showInteractionGuide, interactionGuideStage == .verticalSwipe, oldId != nil {
                    completeInteractionGuideStep(.verticalSwipe, message: "上下スワイプできました")
                }

                // Live Activity (Dynamic Lock Screen) 更新 (プレミアム限定 & 設定ON時)
                if userSettings.isPremiumUser && userSettings.liveActivityEnabled {
                    NotificationService.shared.startDynamicLockScreenActivity(with: NotificationQuote(from: currentQuote))
                }
                
                // 次の背景画像のキャッシュ
                if idx + 1 < dailyQuotes.count {
                    let nextBg = dailyQuotes[idx + 1].backgroundImage
                    let service = backgroundService
                    Task { @MainActor in
                        _ = service.cachedImage(named: nextBg)
                    }
                }
            }
        }
    }

    private var currentBackgroundName: String {
        if let activeRitualBackgroundName {
            return activeRitualBackgroundName
        }
        if userSettings.isPremiumUser {
            return userSettings.selectedBackgrounds.first ?? BackgroundService.backgrounds[0]
        }
        return BackgroundService.getDailyBackground(from: userSettings.selectedBackgrounds)
    }
    
    @ViewBuilder
    private func quoteCell(index: Int, quote: Quote, backgroundName: String) -> some View {
        let isFocused = (visibleQuoteId == quote.id)
        let showSwipeHint = (index == 0 && userSettings.dailySwipeCount == 0 && !userSettings.hasSeenInteractionGuide)
        let quoteIndex = index + 1
        let totalQuotes = dailyQuotes.count
        let isPremium = userSettings.isPremiumUser
        let isLockedPreview = isCategoryLimitedForFreeUser && !isPremium && index == previewCardIndex
        
        MainQuoteView(
            quote: quote,
            showSwipeHint: showSwipeHint,
            isFocused: isFocused,
            quoteIndex: quoteIndex,
            totalQuotes: totalQuotes,
            backgroundName: backgroundName,
            isPremium: isPremium,
            isLockedPreview: isLockedPreview,
            streakDays: userSettings.currentStreakDays,
            weeklySaveCount: weeklyFavoriteSummary.favoriteCount,
            topCategoryTitle: weeklyFavoriteSummary.topCategory?.displayTitleJa,
            recommendedPunchline: favoriteRecommendation?.quote.punchline,
            recommendedCategoryTitle: favoriteRecommendation?.sourceCategory?.displayTitleJa,
            activeSpiritualBundle: selectedSpiritualBundle,
            dailyRitualState: Config.enableSpiritualRitual ? userSettings.dailyRitualState : nil,
            todayWordSelection: userSettings.todayWordSelection,
            onSettings:        { activeSheet = .settings },
            onFavorites:       { activeSheet = .favorites },
            onArchive:         { activeSheet = .archive },
            onCalendar:        { activeSheet = .calendar },
            onCategorySelect:  { activeSheet = .categoryPicker },
            onSpiritualBundleSelect: {
                guard Config.enableSpiritualRitual else { return }
                activeCover = .dailyRitual
            },
            onWallpaperSelect: { activeSheet = .wallpaperPicker },
            onToggleTodayWord: {
                if userSettings.todayWordSelection?.quoteID == quote.id {
                    userSettings.clearTodayWord()
                    if let currentVisibleID = visibleQuoteId,
                       let currentVisibleQuote = dailyQuotes.first(where: { $0.id == currentVisibleID }) {
                        userSettings.writeQuoteToWidget(currentVisibleQuote, backgroundName: backgroundName)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } else {
                    userSettings.saveTodayWord(quote, backgroundName: backgroundName)
                    if let selection = userSettings.todayWordSelection {
                        userSettings.writeTodayWordToWidget(selection)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            },
            onPremium:         {
                activeCover = .premiumWall(isLockedPreview ? .freePreviewLocked : .homeToolbar)
            },
            onFavoriteLimit:   {
                activeCover = .premiumWall(.favoriteLimit)
            },
            onTutorialVerticalSwipe: {
                completeInteractionGuideStep(.verticalSwipe, message: "上下スワイプできました")
            },
            onTutorialSaveSwipe: {
                completeInteractionGuideStep(.saveSwipe, message: "左スワイプで保存できました")
            },
            onTutorialShareSwipe: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                interactionGuideCelebrationMessage = "シェア画面を開けました"
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    showInteractionGuideCelebration = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showInteractionGuideCelebration = false
                    }
                }
            },
            onTutorialShareTap: {
                completeInteractionGuideStep(.shareSwipe, message: "シェア画面を一度タップできました")
            },
            onTutorialLongPress: {
                completeInteractionGuideStep(.longPress, message: "長押しを使えました")
            },
            onTutorialToolbarTap: {
                completeInteractionGuideStep(.toolbar, message: "下のボタンを開けました")
            },
            isInteractionGuideActive: showInteractionGuide,
            interactionGuideStage: interactionGuideStage
        )
        .containerRelativeFrame([.horizontal, .vertical])
        .ignoresSafeArea(.all)
        .scrollTransition(axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1.0 : 1.0 - abs(phase.value) * 0.8)
                .scaleEffect(phase.isIdentity ? 1.0 : 1.0 - abs(phase.value) * 0.05)
        }
        .id(quote.id)
    }

    // MARK: - Data Loading

    private func initializeCoreData() async {
        let dataService = QuoteDataService(modelContext: modelContext)
        do {
            userSettings.refreshDailyEngagement()
            userSettings.clearExpiredTodayWordIfNeeded()
            if Config.enableSpiritualRitual {
                userSettings.clearExpiredDailyRitualIfNeeded()
            }
            try await dataService.loadInitialQuotes()
            
            let fetchLimit = currentFetchLimit
            let quotes = try await dataService.getDailyQuotes(
                limit: fetchLimit,
                isPremium: userSettings.isPremiumUser,
                mediumCategory: selectedMediumCategory,
                largeCategory: selectedLargeCategory,
                spiritualBundle: Config.enableSpiritualRitual ? selectedSpiritualBundle : nil,
                preferredCategories: userSettings.preferredCategories,
                affinityScores: userSettings.categoryAffinityScores
            )
            let drawQuote: Quote?
            if isNightTime() {
                let nightQuotes = try await dataService.getDailyQuotes(
                    limit: 1,
                    isPremium: userSettings.isPremiumUser,
                    mediumCategory: .wantToQuit,
                    largeCategory: nil,
                    spiritualBundle: nil,
                    preferredCategories: userSettings.preferredCategories,
                    affinityScores: userSettings.categoryAffinityScores
                )
                drawQuote = nightQuotes.first ?? quotes.first
            } else {
                drawQuote = quotes.first
            }
            await MainActor.run {
                self.dailyQuotes = quotes
                self.weeklyFavoriteSummary = (try? dataService.getWeeklyFavoriteSummary()) ?? .init(favoriteCount: 0, topCategory: nil)
                self.favoriteRecommendation = try? dataService.getFavoriteRecommendation(excluding: quotes.first?.id)
                self.visibleQuoteId = quotes.first?.id
                self.seenQuoteIds = Set([quotes.first?.id].compactMap { $0 })
                withAnimation(.easeOut(duration: 0.8)) { self.isLoading = false }

                if let first = quotes.first {
                    let bgName = currentBackgroundName
                    userSettings.syncWidgetQuote(defaultQuote: first, backgroundName: bgName)
                    WidgetCenter.shared.reloadAllTimelines()
                }

                #if DEBUG
                let forceDailyDraw = ProcessInfo.processInfo.arguments.contains("-forceDailyDraw")
                #else
                let forceDailyDraw = false
                #endif
                if forceDailyDraw, let drawQuote {
                    activeCover = .dailyDraw(drawQuote)
                } else if userSettings.isFirstLaunch {
                    activeCover = .onboarding
                } else if shouldPresentDailyDraw(), let drawQuote {
                    markDailyDrawPresented()
                    activeCover = .dailyDraw(drawQuote)
                } else if !userSettings.hasSeenInteractionGuide {
                    interactionGuideStage = .verticalSwipe
                    interactionGuideCompletedCount = 0
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        showInteractionGuide = true
                    }
                } else if userSettings.shouldPresentDailyCheckIn() {
                    activeCover = .dailyCheckIn
                }
                if userSettings.lastBrokenStreakDays > 0 {
                    showStreakRescue = true
                }

                if userSettings.isPremiumUser {
                    backgroundService.currentBackgroundIndex = userSettings.selectedBackgroundIndex
                }
            }

            // パーソナライズ通知スケジュール（お気に入りカテゴリ優先）
            await scheduleNotificationsWithQuotes(quotes)
            if weeklyFavoriteSummary.favoriteCount > 0, userSettings.notificationEnabled {
                try? await NotificationService.shared.scheduleWeeklyShelfNotification()
            }
            
            // iOS 26 Dynamic Lock Screen / Live Activity更新 (プレミアム限定 & 設定ON時)
            if userSettings.isPremiumUser, userSettings.liveActivityEnabled, let todayQuote = quotes.first {
                NotificationService.shared.startDynamicLockScreenActivity(with: NotificationQuote(from: todayQuote))
            }

        } catch {
            print("🚨 Failed: \(error)")
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.8)) { self.isLoading = false }
                #if DEBUG
                let forceDailyDraw = ProcessInfo.processInfo.arguments.contains("-forceDailyDraw")
                #else
                let forceDailyDraw = false
                #endif
                if forceDailyDraw, let drawQuote = dailyQuotes.first {
                    activeCover = .dailyDraw(drawQuote)
                } else if userSettings.isFirstLaunch {
                    activeCover = .onboarding
                } else if shouldPresentDailyDraw(), let drawQuote = dailyQuotes.first {
                    markDailyDrawPresented()
                    activeCover = .dailyDraw(drawQuote)
                } else if !userSettings.hasSeenInteractionGuide {
                    interactionGuideStage = .verticalSwipe
                    interactionGuideCompletedCount = 0
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        showInteractionGuide = true
                    }
                } else if userSettings.shouldPresentDailyCheckIn() {
                    activeCover = .dailyCheckIn
                }
            }
        }
    }

    /// オンボーディング完了直後、preferredCategories を反映した初日のデッキに差し替える
    private func reloadDailyQuotesAfterOnboarding() async {
        let dataService = QuoteDataService(modelContext: modelContext)
        do {
            let fetchLimit = currentFetchLimit
            let quotes = try await dataService.getDailyQuotes(
                limit: fetchLimit,
                isPremium: userSettings.isPremiumUser,
                mediumCategory: selectedMediumCategory,
                largeCategory: selectedLargeCategory,
                spiritualBundle: Config.enableSpiritualRitual ? selectedSpiritualBundle : nil,
                preferredCategories: userSettings.preferredCategories,
                affinityScores: userSettings.categoryAffinityScores
            )
            guard !quotes.isEmpty else { return }
            await MainActor.run {
                self.dailyQuotes = quotes
                self.weeklyFavoriteSummary = (try? dataService.getWeeklyFavoriteSummary()) ?? .init(favoriteCount: 0, topCategory: nil)
                self.favoriteRecommendation = try? dataService.getFavoriteRecommendation(excluding: quotes.first?.id)
                self.visibleQuoteId = quotes.first?.id
                self.seenQuoteIds = Set([quotes.first?.id].compactMap { $0 })

                if let first = quotes.first {
                    let bgName = currentBackgroundName
                    userSettings.syncWidgetQuote(defaultQuote: first, backgroundName: bgName)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        } catch {
            print("🚨 Reload after onboarding failed: \(error)")
        }
    }

    private func isNightTime(on date: Date = Date()) -> Bool {
        DailyDrawPolicy.isNight(date)
    }

    private var streakRescueBanner: some View {
        VStack(spacing: WFM.Space.s) {
            Text("昨日までの\(userSettings.lastBrokenStreakDays)日は、消えていません。")
                .font(.headline)
                .foregroundStyle(WFM.ColorToken.nightTextPrimary)
            Text("今日の言葉から、続きを受け取れます。")
                .font(.subheadline)
                .foregroundStyle(WFM.ColorToken.nightTextSub)
            Button(action: {
                if userSettings.isPremiumUser {
                    if userSettings.restoreBrokenStreakIfAvailable(isPremium: true) {
                        withAnimation(WFM.Motion.quick) { showStreakRescue = false }
                    }
                } else {
                    activeCover = .premiumWall(.streakRescue)
                }
            }) {
                Text(userSettings.isPremiumUser ? "続きにする" : "記録を続ける")
                    .foregroundStyle(WFM.ColorToken.nightInk)
            }
            .buttonStyle(.borderedProminent)
            .tint(WFM.ColorToken.nightRose)

            Button("今日はこのまま") {
                userSettings.lastBrokenStreakDays = 0
                withAnimation(WFM.Motion.quick) { showStreakRescue = false }
            }
            .font(.subheadline)
            .foregroundStyle(WFM.ColorToken.nightTextSub)
            .frame(minHeight: 44)
        }
        .padding(WFM.Space.l)
        .frame(maxWidth: .infinity)
        .background(WFM.ColorToken.nightRaised.opacity(0.96), in: RoundedRectangle(cornerRadius: WFM.Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: WFM.Radius.l, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .padding(WFM.Space.m)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func switchCategory(medium: QuoteMediumCategory?, large: QuoteLargeCategory?) {
        guard selectedMediumCategory != medium || selectedLargeCategory != large else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Analytics: カテゴリスイッチ
        AnalyticsService.shared.logCategorySwitch(
            fromMedium: selectedMediumCategory?.rawValue,
            fromLarge: selectedLargeCategory?.rawValue,
            toMedium: medium?.rawValue,
            toLarge: large?.rawValue,
            isPremium: userSettings.isPremiumUser
        )

        selectedMediumCategory = medium
        selectedLargeCategory = large
        selectedSpiritualBundle = nil
        activeRitualBackgroundName = nil
        withAnimation(.easeOut(duration: 0.6)) { isTransitioningCategory = true }
        Task {
            let dataService = QuoteDataService(modelContext: modelContext)
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
                
                let fetchLimit = currentFetchLimit
                let quotes = try await dataService.getDailyQuotes(
                    limit: fetchLimit,
                    isPremium: userSettings.isPremiumUser,
                    mediumCategory: medium,
                    largeCategory: large,
                    spiritualBundle: nil,
                    preferredCategories: userSettings.preferredCategories,
                    affinityScores: userSettings.categoryAffinityScores
                )
                await MainActor.run {
                    self.dailyQuotes = quotes
                    self.weeklyFavoriteSummary = (try? dataService.getWeeklyFavoriteSummary()) ?? .init(favoriteCount: 0, topCategory: nil)
                    self.favoriteRecommendation = try? dataService.getFavoriteRecommendation(excluding: quotes.first?.id)
                    self.visibleQuoteId = quotes.first?.id
                    // ★ カテゴリ切替時は既見セットをリセット（新カテゴリの名言は未見扱い）
                    // ただし制限到達済みなら全て既見扱い（カウントしない）
                    self.seenQuoteIds = hasReachedCurrentLimit
                        ? Set(quotes.map { $0.id })
                        : Set([quotes.first?.id].compactMap { $0 })
                    withAnimation(.easeIn(duration: 1.0)) { self.isTransitioningCategory = false }
                }
            } catch {
                print("🚨 Category Switch Failed: \(error)")
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.8)) { self.isTransitioningCategory = false }
                }
            }
        }
    }

    private func switchSpiritualBundle(_ bundle: SpiritualBundle?) {
        guard Config.enableSpiritualRitual else { return }
        guard selectedSpiritualBundle != bundle else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        selectedSpiritualBundle = bundle
        selectedMediumCategory = nil
        selectedLargeCategory = nil
        activeRitualBackgroundName = bundle?.ritualBackgroundName
        withAnimation(.easeOut(duration: 0.6)) { isTransitioningCategory = true }

        Task {
            let dataService = QuoteDataService(modelContext: modelContext)
            do {
                try await Task.sleep(nanoseconds: 350_000_000)

                let fetchLimit = currentFetchLimit
                let quotes = try await dataService.getDailyQuotes(
                    limit: fetchLimit,
                    isPremium: userSettings.isPremiumUser,
                    mediumCategory: nil,
                    largeCategory: nil,
                    spiritualBundle: bundle,
                    preferredCategories: userSettings.preferredCategories,
                    affinityScores: userSettings.categoryAffinityScores
                )

                await MainActor.run {
                    self.dailyQuotes = quotes
                    self.weeklyFavoriteSummary = (try? dataService.getWeeklyFavoriteSummary()) ?? .init(favoriteCount: 0, topCategory: nil)
                    self.favoriteRecommendation = try? dataService.getFavoriteRecommendation(excluding: quotes.first?.id)
                    self.visibleQuoteId = quotes.first?.id
                    self.seenQuoteIds = hasReachedCurrentLimit
                        ? Set(quotes.map { $0.id })
                        : Set([quotes.first?.id].compactMap { $0 })
                    withAnimation(.easeIn(duration: 0.8)) { self.isTransitioningCategory = false }
                }
            } catch {
                print("🚨 Spiritual Bundle Switch Failed: \(error)")
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.8)) { self.isTransitioningCategory = false }
                }
            }
        }
    }

    private func shouldPresentDailyDraw() -> Bool {
        DailyDrawPolicy.shouldPresent(lastPresentedDate: lastDailyDrawPresentedDate)
    }

    private func markDailyDrawPresented() {
        lastDailyDrawPresentedDate = DailyDrawPolicy.dateKey(for: Date())
    }

    private func saveDailyDrawQuote(_ quote: Quote) {
        guard !quote.isFavorited else { return }
        quote.isFavorited = true
        quote.favoritedAt = Date()
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("🚨 Daily draw save failed: \(error)")
        }
    }

    private func dismissDailyDrawAndContinue() {
        activeCover = nil
        guard !userSettings.hasSeenInteractionGuide else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            interactionGuideStage = .verticalSwipe
            interactionGuideCompletedCount = 0
            withAnimation(WFM.Motion.smooth) { showInteractionGuide = true }
        }
    }

    // MARK: - Notification Scheduling

    /// 名言データからパーソナライズ通知をスケジュール
    private func scheduleNotificationsWithQuotes(_ quotes: [Quote]) async {
        guard userSettings.notificationEnabled else { return }

        let notifQuotes = pickNotificationQuotes(from: quotes)

        // 選出した名言を永続化（SettingsView から再スケジュール時にも使える）
        NotificationService.shared.saveNotificationQuotes(notifQuotes)

        if userSettings.isPremiumUser {
            try? await NotificationService.shared.schedulePremiumNotifications(
                times: userSettings.premiumNotificationTimes,
                quotes: notifQuotes
            )
        } else {
            let cal = Calendar.current
            let h = cal.component(.hour, from: userSettings.notificationTime)
            let m = cal.component(.minute, from: userSettings.notificationTime)
            try? await NotificationService.shared.scheduleDailyNotification(
                hour: h, minute: m,
                quote: notifQuotes.first
            )
        }

        // トライアル終了前リマインダーは出さない方針。旧ビルドで予約済みの分だけ掃除する
        NotificationService.shared.cancelTrialReminders()
    }

    /// お気に入りカテゴリ優先で通知用名言を選出（Unknown除外・質フィルタ付き）
    private func pickNotificationQuotes(from quotes: [Quote], count: Int = 3) -> [NotificationQuote] {
        let preferred = Set(userSettings.preferredCategories)

        // ★ Step 0: Unknown著者・低品質を最初に除外
        var pool = quotes.filter { q in
            q.author != "Unknown" &&
            !q.author.isEmpty &&
            q.punchline.count >= 5 &&
            q.isValid
        }

        // フィルタ後に空なら元の全データへフォールバック（ただしUnknownは除外維持）
        if pool.isEmpty {
            pool = quotes.filter { $0.author != "Unknown" && !$0.author.isEmpty }
        }

        // Step 1: お気に入りカテゴリから優先的に選出
        if !preferred.isEmpty {
            let preferredPool = pool.filter { q in
                preferred.contains(q.category.rawValue) ||
                preferred.contains(q.category.largeCategory.rawValue)
            }
            if !preferredPool.isEmpty { pool = preferredPool }
        }

        // Step 2: お気に入り登録済みをさらに優先
        let favorited = pool.filter { $0.isFavorited }
        if !favorited.isEmpty && favorited.count >= count {
            pool = favorited
        }

        return pool.shuffled().prefix(count).map { NotificationQuote(from: $0) }
    }

    private var guideCelebration: some View {
        VStack {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 0.56, green: 0.73, blue: 0.82))
                    .scaleEffect(showInteractionGuideCelebration ? 1.08 : 0.92)

                Text(interactionGuideCelebrationMessage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.20, green: 0.16, blue: 0.20))

                Text("次の操作へ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.46, green: 0.40, blue: 0.46))
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.10), radius: 20, x: 0, y: 10)
            .scaleEffect(showInteractionGuideCelebration ? 1.0 : 0.92)
            .padding(.bottom, 120)
        }
    }

    private func completeInteractionGuideStep(_ stage: InteractionGuideOverlay.Stage, message: String) {
        guard showInteractionGuide, interactionGuideStage == stage, !showInteractionGuideCelebration else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        interactionGuideCelebrationMessage = message
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            showInteractionGuideCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                showInteractionGuideCelebration = false
            }

            if let next = InteractionGuideOverlay.Stage(rawValue: stage.rawValue + 1) {
                interactionGuideStage = next
                interactionGuideCompletedCount = min(stage.rawValue + 1, InteractionGuideOverlay.Stage.allCases.count)
            } else {
                userSettings.markInteractionGuideSeen()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    showInteractionGuide = false
                }
            }
        }
    }

    private func skipInteractionGuide() {
        guard showInteractionGuide else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        userSettings.markInteractionGuideSeen()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            showInteractionGuideCelebration = false
            showInteractionGuide = false
        }
        interactionGuideCompletedCount = 0
        interactionGuideStage = .verticalSwipe
        interactionGuideCelebrationMessage = ""
    }

}

private struct DailyRitualView: View {
    @EnvironmentObject private var userSettings: UserSettings

    let selectedBundle: SpiritualBundle?
    let onClose: () -> Void
    let onPremiumRequired: () -> Void
    let onStart: (SpiritualBundle) -> Void

    @State private var stage: Int = 0
    @State private var draftBundle: SpiritualBundle = .grounding
    @State private var breathingScale: CGFloat = 0.92
    @State private var breathingGlow: Double = 0.35
    @State private var breathingLineIndex: Int = 0
    @State private var breathingTextVisible = false
    @State private var selectedBundlePulse = false
    @State private var selectedBundleRippleOpacity = 0.0

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let breathingLines = [
        "吸って、ほどいて",
        "少しだけ静けさに戻る",
        "いまの心にやさしく触れる"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ritualBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        if stage == 0 {
                            breathingCard
                        } else if stage == 1 {
                            moodCard
                        } else if stage == 2 {
                            VStack(alignment: .leading, spacing: 18) {
                                sectionHeader(
                                    title: "今日、寄り添いたい流れを選ぶ",
                                    subtitle: "強く変えるより、今の心にしっくり来る整え方をひとつ選びます。"
                                )

                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(SpiritualBundle.allCases) { bundle in
                                        bundleCard(bundle)
                                    }
                                }
                            }
                        } else {
                            ritualSummaryCard(bundle: draftBundle)
                        }

                        HStack(spacing: 12) {
                            if stage > 0 {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                                        stage -= 1
                                    }
                                } label: {
                                    Text("戻る")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white.opacity(0.86))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                primaryAction()
                            } label: {
                                Text(primaryButtonTitle)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.26, green: 0.18, blue: 0.26))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.99, green: 0.94, blue: 0.95),
                                                Color(red: 0.96, green: 0.88, blue: 0.90)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { onClose() }
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .onAppear {
            draftBundle = selectedBundle ?? .grounding
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                breathingScale = 1.08
                breathingGlow = 0.72
            }
            breathingTextVisible = true
            cycleBreathingLines()
        }
    }

    private var ritualBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.08, blue: 0.18),
                    Color(red: 0.24, green: 0.15, blue: 0.26),
                    Color(red: 0.06, green: 0.05, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.92, green: 0.73, blue: 0.84).opacity(0.32), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 130, y: -260)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.93, green: 0.79, blue: 0.60).opacity(0.16), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 180
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -120, y: 180)

            VStack {
                HStack {
                    Spacer()
                    moonHalo
                        .padding(.top, 32)
                        .padding(.trailing, 24)
                }
                Spacer()
            }

            starDust
        }
    }

    private var moonHalo: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 88, height: 88)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.96, blue: 0.88).opacity(0.90),
                            Color(red: 0.93, green: 0.78, blue: 0.61).opacity(0.74)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54, height: 54)
                .shadow(color: Color(red: 0.93, green: 0.78, blue: 0.61).opacity(0.28), radius: 18, x: 0, y: 0)

            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white.opacity(0.82))
                .offset(x: 26, y: -24)
        }
    }

    private var starDust: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.35))
                .offset(x: -140, y: -220)

            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.94, green: 0.81, blue: 0.63).opacity(0.42))
                .offset(x: 110, y: -110)

            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color.white.opacity(0.30))
                .offset(x: 120, y: 90)

            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.92, green: 0.73, blue: 0.84).opacity(0.36))
                .offset(x: -100, y: 220)
        }
    }

    @ViewBuilder
    private func bundleCard(_ bundle: SpiritualBundle) -> some View {
        let isSelected = draftBundle == bundle
        let isLocked = bundle.isPremiumOnly && !userSettings.isPremiumUser

        Button {
            if isLocked {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onPremiumRequired()
                return
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedBundlePulse = true
            selectedBundleRippleOpacity = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                selectedBundlePulse = false
            }
            withAnimation(.easeOut(duration: 0.65)) {
                selectedBundleRippleOpacity = 0
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                draftBundle = bundle
                stage = 3
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Image(systemName: bundle.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Spacer()

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.88))
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(bundle.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(bundle.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(bundle.shortPrompt)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.18))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: bundle.accentTopHex).opacity(isLocked ? 0.46 : 0.94),
                        Color(hex: bundle.accentBottomHex).opacity(isLocked ? 0.72 : 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.34 : 0.14), lineWidth: 1.2)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(selectedBundleRippleOpacity * 0.9), lineWidth: 1.5)
                        .scaleEffect(1.0 + (1.0 - selectedBundleRippleOpacity) * 0.08)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 12)
            .scaleEffect(isSelected && selectedBundlePulse ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "朝のことば儀式",
                subtitle: "まずは何かを決めなくて大丈夫。呼吸がやわらぐところから始めます。"
            )

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 176, height: 176)
                        .scaleEffect(breathingScale)
                        .blur(radius: 2)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.89, blue: 0.92).opacity(breathingGlow),
                                    Color(red: 0.93, green: 0.77, blue: 0.84).opacity(0.32),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 96
                            )
                        )
                        .frame(width: 136, height: 136)
                        .scaleEffect(breathingScale)

                    VStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))

                        Text(breathingLines[breathingLineIndex])
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(breathingTextVisible ? 1 : 0)
                            .animation(.easeInOut(duration: 0.6), value: breathingLineIndex)
                            .animation(.easeInOut(duration: 0.5), value: breathingTextVisible)

                        Text("この数秒だけ、急がなくて大丈夫")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.74))
                    }
                }

                Text("肩や眉間に入っている力を少しゆるめてから、今日の心に触れていきます。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 28)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color(red: 0.92, green: 0.73, blue: 0.84).opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(red: 0.93, green: 0.79, blue: 0.60).opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "いまの心を、そっと見てみる",
                subtitle: "答えを出すというより、今の自分に一番近い感触を選びます。"
            )

            VStack(spacing: 12) {
                moodRow(symbol: "drop.fill", title: "静かになりたい", description: "ざわつきより、落ち着きに戻りたい")
                moodRow(symbol: "sparkles", title: "やわらかく満たしたい", description: "自分の巡りや受け取り感覚をひらきたい")
                moodRow(symbol: "heart.fill", title: "やさしく整えたい", description: "傷んだところを責めずに扱いたい")
            }
            .padding(18)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func ritualSummaryCard(bundle: SpiritualBundle) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "今日の流れを受け取る",
                subtitle: bundle.ritualIntro
            )

            VStack(alignment: .leading, spacing: 14) {
                ritualSummaryRow(label: "今日の意図", value: bundle.shortPrompt)
                ritualSummaryRow(label: "いったん置いていくもの", value: bundle.ritualReleasePrompt)
                ritualSummaryRow(label: "最初の小さな行動", value: bundle.ritualActionPrompt)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: bundle.accentTopHex).opacity(0.90),
                        Color(hex: bundle.accentBottomHex).opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func moodRow(symbol: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.98, green: 0.91, blue: 0.81))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("HiraginoSans-W7", size: 30))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ritualStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.82))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func ritualSummaryRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.68))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryButtonTitle: String {
        switch stage {
        case 0: return "そっと次へ"
        case 1: return "今日の流れを選ぶ"
        case 2: return "この流れを受け取る"
        default: return "この流れで始める"
        }
    }

    private func primaryAction() {
        switch stage {
        case 0:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                stage = 1
            }
        case 1:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                stage = 2
            }
        case 2:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                stage = 3
            }
        default:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onStart(draftBundle)
        }
    }

    private func cycleBreathingLines() {
        for index in 1..<breathingLines.count {
            let delay = Double(index) * 2.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard stage == 0 else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    breathingTextVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                    guard stage == 0 else { return }
                    breathingLineIndex = index
                    withAnimation(.easeInOut(duration: 0.55)) {
                        breathingTextVisible = true
                    }
                }
            }
        }
    }
}

struct DailyCheckInView: View {
    let streakDays: Int
    let weeklySaveCount: Int
    let topCategoryTitle: String?
    let freeCategoryTitle: String
    let recommendation: String?
    let onStart: () -> Void
    let onPremium: () -> Void

    @State private var isVisible = false

    private let pageBackground = WFM.ColorToken.nightBase
    private let sheetBackground = WFM.ColorToken.nightRaised
    private let primaryText = WFM.ColorToken.nightTextPrimary
    private let secondaryText = WFM.ColorToken.nightTextSub
    private let accentLavender = Color(hex: "8D90A2")
    private let borderColor = Color.white.opacity(0.12)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [pageBackground, WFM.ColorToken.nightHigh, pageBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.10), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 280, height: 280)
                    .offset(x: proxy.size.width * 0.3, y: -proxy.size.height * 0.22)
                    .blur(radius: 16)

                Circle()
                    .fill(WFM.ColorToken.nightRoseSoft.opacity(0.10))
                    .frame(width: 220, height: 220)
                    .offset(x: -proxy.size.width * 0.34, y: -proxy.size.height * 0.12)
                    .blur(radius: 28)

                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TODAY'S FIRST OPEN")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .tracking(3.2)
                                .foregroundColor(secondaryText.opacity(0.75))

                            Text("今日の言葉を、\n静かに受け取る。")
                                .font(.custom("HiraginoSans-W8", size: 32))
                                .foregroundColor(primaryText)
                                .lineSpacing(7)

                            Text("最初の一枚だけ整えたら、あとはその日の空気に合う言葉へ、そのまま入れます。")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryText)
                                .lineSpacing(4)
                        }

                        featuredCategoryCard

                        HStack(spacing: 12) {
                            metricCard(
                                label: "継続",
                                value: "\(streakDays)日",
                                detail: "続けて開いています"
                            )
                            metricCard(
                                label: "今週保存",
                                value: "\(weeklySaveCount)件",
                                detail: topCategoryTitle ?? "まだこれから"
                            )
                        }

                        if let recommendation, !recommendation.isEmpty {
                            Button(action: onPremium) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("あなたの棚の広がり")
                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                            .tracking(2.4)
                                    }
                                    .foregroundColor(accentLavender)

                                    Text(recommendation)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(primaryText)
                                        .lineSpacing(4)

                                    Text("最近集めた言葉の流れから、今の気分に近い広がりも開けます")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(secondaryText)
                                }
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(borderColor, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 0)

                        Button(action: onStart) {
                            HStack(spacing: 10) {
                                Spacer()
                                Text("今日の言葉を読む")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(WFM.ColorToken.nightInk)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(WFM.ColorToken.nightInk.opacity(0.9))
                                Spacer()
                            }
                            .padding(.vertical, 18)
                            .background(accentLavender)
                            .clipShape(Capsule())
                            .shadow(color: accentLavender.opacity(0.24), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(sheetBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 28, x: 0, y: 12)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                isVisible = true
            }
        }
    }

    private var featuredCategoryCard: some View {
        let palette = categoryPalette(for: freeCategoryTitle)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.06))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.top.opacity(0.10), palette.bottom.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .frame(maxHeight: .infinity, alignment: .top)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 84, height: 84)
                .blur(radius: 10)
                .offset(x: -10, y: -4)

            Image(systemName: palette.symbol)
                .font(.system(size: 38, weight: .regular))
                .foregroundColor(palette.icon)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 22)
                .padding(.trailing, 20)

            VStack(alignment: .leading, spacing: 10) {
                Text("今日の無料カテゴリー")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(2.4)
                    .foregroundColor(primaryText.opacity(0.62))

                Text(freeCategoryTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(primaryText)

                    Text("今日はこのテーマを無料で読めます。気分に近い一枚から、静かに入り込んでください。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(secondaryText)
                    .lineSpacing(3)
            }
            .padding(20)
            .padding(.top, 122)
        }
        .frame(height: 250)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 10)
    }

    private func metricCard(label: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            capsuleLabel(label)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(primaryText)
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
                .lineLimit(2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func capsuleLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(2.4)
            .foregroundColor(secondaryText.opacity(0.85))
    }

    private func categoryPalette(for title: String) -> (top: Color, bottom: Color, icon: Color, symbol: String) {
        switch title {
        case "自己肯定", "自己愛":
            return (Color(hex: "FFF5F2"), Color(hex: "F8D9D6"), Color(hex: "EAA3A1"), "heart.circle.fill")
        case "前向き", "ポジティブ":
            return (Color(hex: "F6F9EA"), Color(hex: "D8E8B6"), Color(hex: "9EB59B"), "sun.max.fill")
        case "勇気":
            return (Color(hex: "F4F0FC"), Color(hex: "D8CFF0"), Color(hex: "8D90A2"), "sparkles")
        case "内なる強さ":
            return (Color(hex: "F7F0EC"), Color(hex: "DDC8C0"), Color(hex: "C78F83"), "mountain.2.fill")
        case "恋愛", "恋":
            return (Color(hex: "FFF1F4"), Color(hex: "F6C7D2"), Color(hex: "EAA3A1"), "heart.fill")
        case "家族愛":
            return (Color(hex: "F4F7EE"), Color(hex: "D7E2C3"), Color(hex: "9EB59B"), "house.fill")
        case "子どもへ":
            return (Color(hex: "FCF4EC"), Color(hex: "F1DDC8"), Color(hex: "C78F83"), "figure.and.child.holdinghands")
        case "人間関係":
            return (Color(hex: "F2F8FA"), Color(hex: "CFE3EA"), Color(hex: "9FC8D8"), "person.2.fill")
        case "もう無理", "リセット":
            return (Color(hex: "F3F0FA"), Color(hex: "D8D2EA"), Color(hex: "8D90A2"), "moon.stars.fill")
        case "アファメーション":
            return (Color(hex: "F1F9FB"), Color(hex: "CAE4EB"), Color(hex: "9FC8D8"), "quote.bubble.fill")
        default:
            return (Color(hex: "F4F0FC"), Color(hex: "E7DDED"), Color(hex: "8D90A2"), "sparkles")
        }
    }
}
