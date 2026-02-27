import SwiftUI
import SwiftData

struct FavoritesView: View {
    @ObservedObject var quoteDataService: QuoteDataService
    @EnvironmentObject private var userSettings: UserSettings

    @State private var favoriteQuotes: [Quote] = []
    @State private var isLoading = true
    @State private var selectedQuote: Quote?
    
    // ストーリーモード起動フラグ
    @State private var isStoryMode = false

    let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else if favoriteQuotes.isEmpty {
                    VStack(spacing: 32) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                        Text("SAVED QUOTES IS EMPTY")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .tracking(4).foregroundColor(.white.opacity(0.5))
                            
                        Text("心を動かした言葉を保存して、\nあなただけのインスピレーションの源泉を作りましょう")
                            .font(.system(size: 12, weight: .light))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(favoriteQuotes, id: \.id) { quote in
                            MinimalFavoriteCard(quote: quote, accentGold: accentGold)
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
            .navigationTitle("SAVED")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !favoriteQuotes.isEmpty {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isStoryMode = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text("PLAY")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .tracking(2)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(accentGold)
                            .clipShape(Capsule())
                        }
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
        }
    }

    private func loadFavorites() {
        isLoading = true
        do {
            favoriteQuotes = try quoteDataService.getFavoriteQuotes()
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

// MARK: - Minimal Favorite Card

struct MinimalFavoriteCard: View {
    let quote: Quote
    let accentGold: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white.opacity(0.1))
                .offset(x: -4, y: 4)
            
            Text(quote.quoteJa)
                .font(.custom("HiraginoSans-W6", size: 16))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(10)
                .lineLimit(4)
                
            HStack(spacing: 12) {
                Rectangle().fill(accentGold).frame(width: 20, height: 1)
                Text(quote.author.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(4)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color.white.opacity(0.03) // Base
                LinearGradient(colors: [Color.white.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        // カードとしての質感を強調
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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
                        ? BackgroundService.getDailyBackground()
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
                    
                    // 本体コンテンツ
                    VStack(alignment: .leading, spacing: 40) {
                        Spacer()
                        Image(systemName: "quote.opening")
                            .font(.system(size: 64, weight: .black))
                            .foregroundColor(.white.opacity(0.1))
                            .offset(x: -12, y: 20)
                        
                        Text(quote.quoteJa)
                            .font(.custom("HiraginoSans-W8", size: 36)).fontWeight(.black)
                            .foregroundColor(.white.opacity(0.95))
                            .lineSpacing(14)
                            .minimumScaleFactor(0.4)
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 20) {
                            Rectangle().fill(accentGold).frame(width: 40, height: 1)
                            Text(quote.author.uppercased())
                                .font(.system(size: 13, weight: .bold, design: .monospaced)).tracking(6)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // 下部に余白を設ける
                        Spacer().frame(height: proxy.size.height * 0.15)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                // Close
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.5)).padding()
                    }
                }
                Spacer()
                // Quote Content
                VStack(alignment: .leading, spacing: 40) {
                    Text(quote.quoteJa)
                        .font(.custom("HiraginoSans-W8", size: 36)).fontWeight(.black)
                        .foregroundColor(.white).lineSpacing(14).minimumScaleFactor(0.4)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 20) {
                        Rectangle().fill(Color.white.opacity(0.8)).frame(width: 40, height: 1)
                        Text(quote.author.uppercased())
                            .font(.system(size: 13, weight: .black)).tracking(6)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 30)
                Spacer()
                // Action Buttons
                HStack(spacing: 40) {
                    Button(action: {
                        try? quoteDataService.toggleFavorite(quote: quote, isPremium: userSettings.isPremiumUser)
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "bookmark.slash").font(.system(size: 20, weight: .light))
                            Text("REMOVE").font(.system(size: 10, weight: .bold)).tracking(2)
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                    Button(action: { showShareView = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up").font(.system(size: 20, weight: .light))
                            Text("SHARE").font(.system(size: 10, weight: .bold)).tracking(2)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1.0)) { appear = true } }
        .sheet(isPresented: $showShareView) {
            ShareQuoteView(quote: quote)
        }
    }
}
