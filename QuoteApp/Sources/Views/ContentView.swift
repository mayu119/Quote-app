import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings

    @State private var isLoading = true
    @State private var dailyQuotes: [Quote] = []

    // シート管理
    @State private var activeSheet: SheetType?

    // フルスクリーンカバー管理（2つを1つのenumで統一 → 競合防止）
    @State private var activeCover: CoverType?

    // スクロール追跡
    @State private var visibleQuoteId: String?
    
    private let dailyFreeLimitAll = 10
    private let dailyFreeLimitSpecific = 5
    
    private var currentFreeLimit: Int {
        (selectedMediumCategory == nil && selectedLargeCategory == nil) ? dailyFreeLimitAll : dailyFreeLimitSpecific
    }

    // カテゴリ管理（選択中のフィルタ）
    @State private var selectedMediumCategory: QuoteMediumCategory? = nil
    @State private var selectedLargeCategory: QuoteLargeCategory? = nil
    @State private var isTransitioningCategory = false

    // 背景管理
    @StateObject private var backgroundService = BackgroundService()

    // MARK: - Enums

    enum SheetType: Identifiable {
        case settings, favorites, archive, wallpaperPicker, categoryPicker
        var id: Int { hashValue }
    }

    /// フルスクリーンカバーを一本化して競合を排除
    enum CoverType: Identifiable {
        case premiumWall
        case onboarding
        var id: Int { hashValue }
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
                    if userSettings.isPremiumUser {
                        let bgName = userSettings.selectedBackgrounds.first ?? BackgroundService.backgrounds[0]
                        quoteScrollView(backgroundName: bgName)
                    } else {
                        quoteScrollView(backgroundName: BackgroundService.getDailyBackground())
                    }
                }
            }
            .opacity(isTransitioningCategory ? 0.0 : 1.0)

            if isTransitioningCategory {
                Color.black.ignoresSafeArea()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .zIndex(50)
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
            case .wallpaperPicker:
                WallpaperPickerView()
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
                            activeCover = .premiumWall
                        }
                    }
                )
                .environmentObject(userSettings)
            }
        }
        // 単一の fullScreenCover で premium / onboarding 両方を管理
        .fullScreenCover(item: $activeCover) { cover in
            switch cover {
            case .premiumWall:
                PremiumView()
                    .environmentObject(userSettings)
            case .onboarding:
                OnboardingView(onDismiss: { activeCover = nil })
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

                if !userSettings.isPremiumUser {
                    premiumWallBlock
                        .containerRelativeFrame([.horizontal, .vertical])
                        .scrollTransition(axis: .vertical) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 1.0 - abs(phase.value) * 0.8)
                                .scaleEffect(phase.isIdentity ? 1.0 : 1.0 - abs(phase.value) * 0.05)
                        }
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
            if let idx = dailyQuotes.firstIndex(where: { $0.id == newId }),
               idx + 1 < dailyQuotes.count {
                let nextBg = dailyQuotes[idx + 1].backgroundImage
                let service = backgroundService
                Task { @MainActor in
                    _ = service.cachedImage(named: nextBg)
                }
            }
        }
    }
    
    @ViewBuilder
    private func quoteCell(index: Int, quote: Quote, backgroundName: String) -> some View {
        let isFocused = (visibleQuoteId == quote.id)
        let showSwipeHint = (index == 0 && userSettings.dailySwipeCount == 0)
        let quoteIndex = index + 1
        let totalQuotes = dailyQuotes.count
        let isPremium = userSettings.isPremiumUser
        
        MainQuoteView(
            quote: quote,
            showSwipeHint: showSwipeHint,
            isFocused: isFocused,
            quoteIndex: quoteIndex,
            totalQuotes: totalQuotes,
            backgroundName: backgroundName,
            isPremium: isPremium,
            onSettings:        { activeSheet = .settings },
            onFavorites:       { activeSheet = .favorites },
            onArchive:         { activeSheet = .archive },
            onCategorySelect:  { activeSheet = .categoryPicker },
            onWallpaperSelect: { activeSheet = .wallpaperPicker }
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
            try await dataService.loadInitialQuotes()
            let fetchLimit = userSettings.isPremiumUser ? 50 : currentFreeLimit
            let quotes = try await dataService.getDailyQuotes(
                limit: fetchLimit,
                isPremium: userSettings.isPremiumUser,
                mediumCategory: selectedMediumCategory,
                largeCategory: selectedLargeCategory,
                preferredCategories: userSettings.preferredCategories,
                affinityScores: userSettings.categoryAffinityScores
            )
            await MainActor.run {
                self.dailyQuotes = quotes
                self.visibleQuoteId = quotes.first?.id
                withAnimation(.easeOut(duration: 0.8)) { self.isLoading = false }

                if let first = quotes.first {
                    let bgName = userSettings.isPremiumUser 
                        ? (userSettings.selectedBackgrounds.first ?? BackgroundService.backgrounds[0])
                        : BackgroundService.getDailyBackground()
                    userSettings.writeQuoteToWidget(first, backgroundName: bgName)
                    WidgetCenter.shared.reloadAllTimelines()
                }

                if userSettings.isFirstLaunch {
                    activeCover = .onboarding
                }

                if userSettings.isPremiumUser {
                    backgroundService.currentBackgroundIndex = userSettings.selectedBackgroundIndex
                }
            }

            // パーソナライズ通知スケジュール（お気に入りカテゴリ優先）
            await scheduleNotificationsWithQuotes(quotes)

        } catch {
            print("🚨 Failed: \(error)")
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.8)) { self.isLoading = false }
                if userSettings.isFirstLaunch { activeCover = .onboarding }
            }
        }
    }

    private func switchCategory(medium: QuoteMediumCategory?, large: QuoteLargeCategory?) {
        guard selectedMediumCategory != medium || selectedLargeCategory != large else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedMediumCategory = medium
        selectedLargeCategory = large
        withAnimation(.easeOut(duration: 0.6)) { isTransitioningCategory = true }
        Task {
            let dataService = QuoteDataService(modelContext: modelContext)
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
                let fetchLimit = userSettings.isPremiumUser ? 50 : currentFreeLimit
                let quotes = try await dataService.getDailyQuotes(
                    limit: fetchLimit,
                    isPremium: userSettings.isPremiumUser,
                    mediumCategory: medium,
                    largeCategory: large,
                    preferredCategories: userSettings.preferredCategories,
                    affinityScores: userSettings.categoryAffinityScores
                )
                await MainActor.run {
                    self.dailyQuotes = quotes
                    self.visibleQuoteId = quotes.first?.id
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

    // MARK: - Premium Wall

    private var premiumWallBlock: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 40) {
                Image(systemName: "lock")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.8))
                Text("DAILY LIMIT REACHED")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .tracking(4).foregroundColor(.white)
                Text("本日の閲覧上限(\(currentFreeLimit)回)に達しました。\nプレミアムプランにアップグレードして\n無制限のインスピレーションを得ましょう")
                    .font(.system(size: 13, weight: .light)).lineSpacing(8)
                    .multilineTextAlignment(.center).foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 40)
                Button(action: { activeCover = .premiumWall }) {
                    Text("UNLOCK UNLIMITED")
                        .font(.system(size: 12, weight: .black)).tracking(2)
                        .foregroundColor(.black).padding(.horizontal, 32).padding(.vertical, 16)
                        .background(Color.white)
                }
            }
        }
        .ignoresSafeArea()
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

        // トライアルリマインダー
        if let trialEnd = userSettings.trialEndDate {
            try? await NotificationService.shared.scheduleTrialReminders(trialEndDate: trialEnd)
        }
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

}
