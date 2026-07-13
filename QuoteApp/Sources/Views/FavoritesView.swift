import SwiftUI
import SwiftData

struct FavoritesView: View {
    @ObservedObject var quoteDataService: QuoteDataService
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss

    @State private var favoriteQuotes: [Quote] = []
    @State private var weeklySummary = QuoteDataService.WeeklyFavoriteSummary(favoriteCount: 0, topCategory: nil)
    @State private var isLoading = true
    @State private var selectedQuote: Quote?
    
    // ストーリーモード起動フラグ
    @State private var isStoryMode = false
    @State private var showWeeklyShelf = false
    @State private var showMonthlyReport = false
    @State private var showGiftComposer = false

    private let accentRose = WFM.ColorToken.nightRose
    private let accentPeach = WFM.ColorToken.nightRoseSoft
    private let ink = WFM.ColorToken.nightTextPrimary
    private let cardFill = Color.white.opacity(0.07)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [WFM.ColorToken.nightRaised, WFM.ColorToken.nightHigh, WFM.ColorToken.nightBase],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentRose))
                        .scaleEffect(1.2)
                } else if favoriteQuotes.isEmpty {
                    VStack(spacing: 32) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(accentRose.opacity(0.45))
                        Text("まだ棚に置いた言葉はありません")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(ink)
                            
                        Text("響いた一節を少しずつ集めて、\nあなただけの言葉の棚を育てましょう")
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .foregroundColor(ink.opacity(0.68))
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        shelfOverviewCard
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 18, leading: 24, bottom: 8, trailing: 24))

                        ForEach(favoriteQuotes, id: \.id) { quote in
                            MinimalFavoriteCard(
                                quote: quote,
                                accentRose: accentRose,
                                accentPeach: accentPeach,
                                ink: ink,
                                cardFill: cardFill
                            )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedQuote = quote
                                }
                                // 左スワイプで削除（エッジ：trailingからのスワイプ）
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        removeQuote(quote)
                                    } label: {
                                        Label("REMOVE", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("言葉の棚")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(WFM.ColorToken.nightRaised, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }) {
                        Text("閉じる")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(WFM.ColorToken.nightInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(accentRose)
                            .clipShape(Capsule())
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if Config.enableGiftOmamori, !favoriteQuotes.isEmpty {
                        Button("贈る") { showGiftComposer = true }
                            .font(.system(size: 12, weight: .bold))
                            .accessibilityLabel("棚の言葉をお守りとして贈る")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !favoriteQuotes.isEmpty {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isStoryMode = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text("棚をめくる")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(WFM.ColorToken.nightInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(accentRose)
                            .clipShape(Capsule())
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("月次") { showMonthlyReport = true }
                        .font(.system(size: 12, weight: .bold))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if weeklySummary.favoriteCount > 0 {
                        Button("今週") { showWeeklyShelf = true }
                            .font(.system(size: 12, weight: .bold))
                    }
                }
            }
            .task { loadFavorites() }
            .fullScreenCover(item: $selectedQuote) { quote in
                MinimalQuoteDetailView(quote: quote, quoteDataService: quoteDataService)
                    .onDisappear { loadFavorites() }
            }
            .fullScreenCover(isPresented: $isStoryMode) {
                FavoritesStoryView(quotes: favoriteQuotes)
                    .environmentObject(userSettings)
            }
            .sheet(isPresented: $showWeeklyShelf) {
                WeeklyShelfView().environmentObject(userSettings)
            }
            .sheet(isPresented: $showMonthlyReport) {
                MonthlyReportView().environmentObject(userSettings)
            }
            .sheet(isPresented: $showGiftComposer) {
                GiftComposeView(quotes: favoriteQuotes)
            }
        }
    }

    private func loadFavorites() {
        isLoading = true
        do {
            favoriteQuotes = try quoteDataService.getFavoriteQuotes()
            weeklySummary = try quoteDataService.getWeeklyFavoriteSummary()
        } catch {
            print("⚠️ Error loading favorites: \(error)")
        }
        isLoading = false
    }
    
    private func removeQuote(_ quote: Quote) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        do {
            // お気に入り解除処理（DBから削除もしくはisFavoritedフラグをfalse）
            try quoteDataService.toggleFavorite(quote: quote, isPremium: userSettings.isPremiumUser)
            withAnimation(.spring()) {
                favoriteQuotes.removeAll { $0.id == quote.id }
            }
            AnalyticsService.shared.logFavoriteRemove(
                quoteId: quote.id,
                author: quote.author,
                categoryMedium: quote.category.rawValue,
                totalFavorites: favoriteQuotes.count
            )
        } catch {
            print("⚠️ 削除に失敗しました: \(error)")
        }
    }
}

private extension FavoritesView {
    var shelfOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WORD SHELF")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .tracking(2.4)
                        .foregroundColor(accentRose.opacity(0.85))

                    Text("保存ではなく、\n今の自分を置いてきた記録。")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ink)
                        .lineSpacing(5)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentRose.opacity(0.9))
                    .padding(12)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }

            HStack(spacing: 12) {
                shelfMetric(
                    label: "今週置いた言葉",
                    value: "\(weeklySummary.favoriteCount)件"
                )
                shelfMetric(
                    label: "今のテーマ",
                    value: weeklySummary.topCategory?.displayTitleJa ?? "これから"
                )
            }
        }
        .padding(22)
        .background(
            ZStack {
                cardFill
                LinearGradient(
                    colors: [accentPeach.opacity(0.10), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: accentRose.opacity(0.10), radius: 20, x: 0, y: 10)
    }

    func shelfMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ink.opacity(0.5))

            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Minimal Favorite Card

struct MinimalFavoriteCard: View {
    let quote: Quote
    let accentRose: Color
    let accentPeach: Color
    let ink: Color
    let cardFill: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(accentRose.opacity(0.18))
                .offset(x: -4, y: 4)
            
            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W6", size: 16))
                .foregroundColor(ink)
                .lineSpacing(10)
                .lineLimit(4)

            if let favoriteNote = quote.favoriteNote, !favoriteNote.isEmpty {
                Text(favoriteNote)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ink.opacity(0.62))
                    .lineSpacing(4)
                    .lineLimit(2)
            }
                
            HStack(spacing: 12) {
                Rectangle().fill(accentRose.opacity(0.6)).frame(width: 20, height: 1)
                if quote.hasVisibleAuthorAttribution {
                    Text(quote.displayAuthor)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(ink.opacity(0.55))
                }
                Spacer()

                if let favoriteNote = quote.favoriteNote, !favoriteNote.isEmpty {
                    Image(systemName: "note.text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentRose.opacity(0.9))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(ink.opacity(0.22))
            }
        }
        .padding(24)
        .background(
            ZStack {
                cardFill
                LinearGradient(colors: [accentPeach.opacity(0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: accentRose.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

// MARK: - Favorites Story Mode View

struct FavoritesStoryView: View {
    let quotes: [Quote]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var currentIndex = 0
    @State private var timerProgress: CGFloat = 0
    
    // 1枚あたり5秒で自動進行
    let duration: Double = 5.0
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !quotes.isEmpty {
                    let quote = quotes[currentIndex]
                    
                    // 背景画像
                    // 無課金ユーザー: その日の固定背景のみ（さまざまな壁紙を見れるのはプレミアムの特権）
                    // 課金ユーザー: 設定で選んだ壁紙があればそれからランダム、なければ保存時の背景
                    let imageName = !userSettings.isPremiumUser
                        ? BackgroundService.getDailyBackground(from: userSettings.selectedBackgrounds)
                        : (userSettings.selectedBackgrounds.isEmpty ? quote.backgroundImage : userSettings.selectedBackgrounds.randomElement()!)

                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .opacity(0.85)
                        
                    // グラデーション（視認性確保）
                    RadialGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.6), .black.opacity(1.0)]),
                        center: .center, startRadius: 80,
                        endRadius: proxy.size.height * 0.8
                    ).allowsHitTesting(false)
                    
                    let availableTextHeight = proxy.size.height * 0.48
                    let baseFontSize: CGFloat = 34
                    let totalCharacterCount = quote.quoteJa.filter { $0 != "\n" }.count
                    let heightDrivenLimit = max(10, Int(availableTextHeight / (baseFontSize * 1.15)))
                    let preferredColumnCount = min(5, max(4, Int((proxy.size.width - 92) / (baseFontSize + 14))))
                    let widthDrivenLimit = Int(ceil(Double(max(totalCharacterCount, 1)) / Double(preferredColumnCount)))
                    let maxCharsPerLine = max(heightDrivenLimit, widthDrivenLimit)
                    let foldedText = JapaneseLineBreaker.fold(quote.quoteJa, maxPerLine: maxCharsPerLine)
                    let maxLineLength = foldedText.components(separatedBy: "\n").map { $0.count }.max() ?? 1
                    let calcSize = availableTextHeight / CGFloat(maxLineLength) / 1.15
                    let dynamicFontSize = min(baseFontSize, max(24.0, calcSize))

                    // 本体コンテンツ
                    ZStack(alignment: .bottomLeading) {
                        VerticalTextView(
                            text: foldedText,
                            fontName: "HiraMinProN-W6",
                            fontSize: dynamicFontSize,
                            lineSpacing: 18,
                            textColor: .white.opacity(0.95)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                        if quote.hasVisibleAuthorAttribution {
                            HStack(alignment: .bottom, spacing: 14) {
                                Rectangle()
                                    .fill(accentGold)
                                    .frame(width: 2, height: 40)

                                VerticalTextView(
                                    text: quote.displayAuthor,
                                    fontName: "HiraginoSans-W6",
                                    fontSize: 14,
                                    lineSpacing: 0,
                                    textColor: .white.opacity(0.8)
                                )
                            }
                            .padding(.leading, 18)
                            .padding(.bottom, proxy.size.height * 0.12)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, proxy.safeAreaInsets.top + 70)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 70)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // 上部のプログレスインジケーター（Instagram Stories風）
                    VStack {
                        HStack(spacing: 4) {
                            ForEach(0..<quotes.count, id: \.self) { index in
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.3))
                                        if index < currentIndex {
                                            Capsule().fill(Color.white)
                                        } else if index == currentIndex {
                                            Capsule().fill(Color.white)
                                                .frame(width: geo.size.width * timerProgress)
                                        }
                                    }
                                }
                                .frame(height: 2)
                            }
                        }
                        .padding(.top, proxy.safeAreaInsets.top > 0 ? proxy.safeAreaInsets.top : 20)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .zIndex(10)
                    
                    // 左右のタップ領域
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.clear)
                            .frame(width: proxy.size.width * 0.35)
                            .contentShape(Rectangle())
                            .onTapGesture { tapPrevious() }
                            
                        Rectangle().fill(Color.clear)
                            .frame(width: proxy.size.width * 0.65)
                            .contentShape(Rectangle())
                            .onTapGesture { tapNext() }
                    }
                    
                    // 閉じるボタン
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .shadow(color: .black, radius: 4)
                            }
                        }
                        .padding(.top, proxy.safeAreaInsets.top > 0 ? proxy.safeAreaInsets.top + 10 : 30)
                        Spacer()
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            timerProgress += CGFloat(0.05 / duration)
            if timerProgress >= 1.0 {
                tapNext()
            }
        }
        .onAppear {
            currentIndex = 0
            timerProgress = 0
            UIApplication.shared.isIdleTimerDisabled = true // 自動ロック防止
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private func tapNext() {
        if currentIndex < quotes.count - 1 {
            withAnimation(.none) { // サクッと切り替えるためアニメーションはオフ
                currentIndex += 1
                timerProgress = 0
            }
        } else {
            // 一番最後なら閉じる
            dismiss()
        }
    }
    
    private func tapPrevious() {
        if currentIndex > 0 {
            withAnimation(.none) {
                currentIndex -= 1
                timerProgress = 0
            }
        } else {
            // 最初なら進捗だけ0に戻す
            timerProgress = 0
        }
    }
}

// MARK: - Minimal Quote Detail View

struct MinimalQuoteDetailView: View {
    let quote: Quote
    @ObservedObject var quoteDataService: QuoteDataService
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss

    @State private var appear = false
    @State private var showShareView = false
    @State private var showQuoteInsight = false
    @State private var showPremiumView = false
    @State private var noteText = ""
    @State private var noteSaveMessage: String?

    private let pageBackground = WFM.ColorToken.nightBase
    private let sheetBackground = WFM.ColorToken.nightRaised
    private let primaryText = WFM.ColorToken.nightTextPrimary
    private let secondaryText = WFM.ColorToken.nightTextSub
    private let accentRose = WFM.ColorToken.nightRose
    private let accentLavender = Color(hex: "8D90A2")
    private let borderColor = Color.white.opacity(0.12)
    private let quoteCardTop = Color(hex: "FFF1F4")
    private let quoteCardBottom = Color(hex: "F6C7D2")
    private let noteFill = Color.white.opacity(0.06)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [pageBackground, WFM.ColorToken.nightHigh, pageBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            HStack {
                                Button(action: { dismiss() }) {
                                    Text("閉じる")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(primaryText)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 11)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryText.opacity(0.82))
                                        .frame(width: 42, height: 42)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(borderColor, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("置いてきた言葉")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accentLavender)
                                    .tracking(0.8)

                                Text("読み返したい一言を\n今の自分ごと残しておく")
                                    .font(.system(size: 31, weight: .bold))
                                    .foregroundColor(primaryText)
                                    .lineSpacing(5)

                                Text("その時の本音を少しだけ添えておくと、あとで開いたときに自分の輪郭まで戻ってきます。")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryText)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 18)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, max(proxy.safeAreaInsets.top, 16) + 6)
                        .padding(.bottom, 18)

                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 22) {
                                quoteCard

                                favoriteNoteSection

                                if let noteSaveMessage {
                                    Text(noteSaveMessage)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(secondaryText)
                                        .padding(.horizontal, 4)
                                }

                                actionSection
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 110)
                        }
                    }
                    .background(sheetBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 28, x: 0, y: 12)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    .overlay(alignment: .bottom) {
                        bottomActionBar(proxy: proxy)
                    }
                }
            }
        }
        .onAppear {
            noteText = quote.favoriteNote ?? ""
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
        .sheet(isPresented: $showShareView) {
            ShareQuoteView(quote: quote)
        }
        .sheet(isPresented: $showQuoteInsight) {
            QuoteInsightSheet(
                quote: quote,
                isPremiumUser: userSettings.isPremiumUser,
                onPremium: presentPremiumFromInsight
            )
        }
        .fullScreenCover(isPresented: $showPremiumView) {
            PremiumView(context: .favoriteLimit)
                .environmentObject(userSettings)
        }
        .preferredColorScheme(.dark)
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("名言")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(primaryText)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [quoteCardTop.opacity(0.10), quoteCardBottom.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 116)
                    .frame(maxHeight: .infinity, alignment: .top)

                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 56, height: 56)
                    .blur(radius: 10)
                    .offset(x: 10, y: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundColor(accentRose.opacity(0.88))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 20)
                    .padding(.trailing, 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text(quote.quoteJa)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(primaryText)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    if quote.hasVisibleAuthorAttribution {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(accentRose.opacity(0.6))
                                .frame(width: 20, height: 1)

                            Text(quote.displayAuthor)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(secondaryText)
                        }
                    }
                }
                .padding(18)
                .padding(.top, 112)
            }
        }
        .frame(minHeight: 240)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
    }

    private var favoriteNoteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("残した理由")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(primaryText)

            Text("あとで開いた自分に渡すひとこと。短くても十分です。")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryText)
                .lineSpacing(4)

            ZStack(alignment: .topLeading) {
                if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("例えば: あの時、ちゃんと焦っていた自分を受け止められた")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(secondaryText.opacity(0.55))
                        .padding(.top, 18)
                        .padding(.leading, 18)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $noteText)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(primaryText)
                    .font(.system(size: 16, weight: .medium))
                    .frame(minHeight: 160)
                    .padding(12)
            }
            .background(noteFill)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("残した理由を書いておくと、言葉がただの記録ではなく自分の文脈になります。")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryText)
                .lineSpacing(4)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 24)
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アクション")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(primaryText)

            HStack(spacing: 12) {
                detailActionButton(
                    title: "深く知る",
                    subtitle: "背景と意味を読む",
                    icon: "book.closed",
                    fill: Color.white.opacity(0.08),
                    foreground: primaryText
                ) {
                    showQuoteInsight = true
                }

                detailActionButton(
                    title: "シェア",
                    subtitle: "画像で共有",
                    icon: "square.and.arrow.up",
                    fill: Color.white.opacity(0.08),
                    foreground: primaryText
                ) {
                    showShareView = true
                }

                detailActionButton(
                    title: "外す",
                    subtitle: "お気に入り解除",
                    icon: "bookmark.slash",
                    fill: WFM.ColorToken.nightRose.opacity(0.16),
                    foreground: WFM.ColorToken.nightRoseSoft
                ) {
                    try? quoteDataService.toggleFavorite(quote: quote, isPremium: userSettings.isPremiumUser)
                    dismiss()
                }
            }
        }
    }

    private func detailActionButton(
        title: String,
        subtitle: String,
        icon: String,
        fill: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(foreground.opacity(0.66))
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func bottomActionBar(proxy: GeometryProxy) -> some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Text("閉じる")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: saveNote) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                    Text(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "このまま置いておく" : "理由を保存")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(WFM.ColorToken.nightInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentLavender)
                .clipShape(Capsule())
                .shadow(color: accentLavender.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 8)
        .padding(.top, 16)
        .background(
            LinearGradient(
                colors: [sheetBackground.opacity(0.0), sheetBackground.opacity(0.92), sheetBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func saveNote() {
        do {
            try quoteDataService.updateFavoriteNote(for: quote, note: noteText, isPremium: userSettings.isPremiumUser)
            AnalyticsService.shared.logFavoriteNoteSave(
                quoteId: quote.id,
                noteLength: noteText.trimmingCharacters(in: .whitespacesAndNewlines).count,
                isPremium: userSettings.isPremiumUser
            )
            noteSaveMessage = noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "理由を削除しました"
                : "理由を保存しました"
        } catch {
            noteSaveMessage = error.localizedDescription
        }
    }

    private func presentPremiumFromInsight() {
        showQuoteInsight = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPremiumView = true
        }
    }
}
