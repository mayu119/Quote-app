import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings

    @State private var isLoading = true
    @State private var dailyQuotes: [Quote] = []

    // シート表示状態
    @State private var activeSheet: SheetType?

    // スクロール追跡とリミット制限
    @State private var visibleQuoteId: String?
    @State private var showPremiumWall = false
    private let dailyFreeLimit = 15

    // 背景管理
    @StateObject private var backgroundService = BackgroundService()

    enum SheetType: Identifiable {
        case settings, favorites, archive
        var id: Int { hashValue }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            } else {
                if userSettings.isPremiumUser {
                    // プレミアムユーザー：TabViewで背景切り替え可能
                    TabView(selection: $backgroundService.currentBackgroundIndex) {
                        ForEach(0..<BackgroundService.backgrounds.count, id: \.self) { bgIndex in
                            quoteScrollView(backgroundName: BackgroundService.backgrounds[bgIndex])
                                .tag(bgIndex)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(.all)
                    .onChange(of: backgroundService.currentBackgroundIndex) { _, newIndex in
                        // 背景変更時のハプティクス
                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()
                        // 選択を保存
                        userSettings.selectedBackgroundIndex = newIndex
                    }
                } else {
                    // 無料ユーザー：日替わり背景のみ
                    quoteScrollView(backgroundName: BackgroundService.getDailyBackground())
                }
            }
        }
        .task {
            await initializeCoreData()
            // 保存された背景インデックスを復元（プレミアムユーザーのみ）
            if userSettings.isPremiumUser {
                backgroundService.currentBackgroundIndex = userSettings.selectedBackgroundIndex
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .favorites:
                let dataService = QuoteDataService(modelContext: modelContext)
                FavoritesView(quoteDataService: dataService)
            case .archive:
                ArchiveView()
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView()
        }
    }

    // MARK: - Quote ScrollView (縦スクロール用)

    @ViewBuilder
    private func quoteScrollView(backgroundName: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(dailyQuotes.enumerated()), id: \.element.id) { index, quote in
                    MainQuoteView(
                        quote: quote,
                        showSwipeHint: (index == 0 && userSettings.dailySwipeCount == 0),
                        isFocused: (visibleQuoteId == quote.id),
                        quoteIndex: index + 1,
                        totalQuotes: dailyQuotes.count,
                        backgroundName: backgroundName,
                        isPremium: userSettings.isPremiumUser,
                        onSettings: { activeSheet = .settings },
                        onFavorites: { activeSheet = .favorites },
                        onArchive: { activeSheet = .archive }
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .ignoresSafeArea(.all)
                    .scrollTransition(axis: .vertical) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1.0 : 0.8)
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                            .offset(y: phase.value * 20)
                    }
                    .id(quote.id)
                }

                // 無料ユーザーの終着点
                if !userSettings.isPremiumUser {
                    premiumWallBlock
                        .containerRelativeFrame([.horizontal, .vertical])
                        .scrollTransition(axis: .vertical) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0.8)
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                                .offset(y: phase.value * 20)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleQuoteId)
        .ignoresSafeArea(.all)
        .onChange(of: visibleQuoteId) { oldId, newId in
            guard oldId != newId, newId != nil else { return }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    // MARK: - Initializer & Loaders

    private func initializeCoreData() async {
        let dataService = QuoteDataService(modelContext: modelContext)

        do {
            try await dataService.loadInitialQuotes()

            let fetchLimit = userSettings.isPremiumUser ? 50 : dailyFreeLimit
            let quotes = try await dataService.getDailyQuotes(limit: fetchLimit, isPremium: userSettings.isPremiumUser)

            await MainActor.run {
                self.dailyQuotes = quotes
                self.visibleQuoteId = quotes.first?.id
                withAnimation(.easeOut(duration: 0.8)) {
                    self.isLoading = false
                }
            }
        } catch {
            print("🚨 Failed: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    // MARK: - Views

    private var premiumWallBlock: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 40) {
                Image(systemName: "lock")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.8))

                Text("DAILY LIMIT REACHED")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(.white)

                Text("本日の閲覧上限(\(dailyFreeLimit)回)に達しました。\nプレミアムプランにアップグレードして\n無制限のインスピレーションを得ましょう")
                    .font(.system(size: 13, weight: .light))
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 40)

                Button(action: { showPremiumWall = true }) {
                    Text("UNLOCK UNLIMITED")
                        .font(.system(size: 12, weight: .black))
                        .tracking(2)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.white)
                }
            }
        }
        .ignoresSafeArea()
    }
}
