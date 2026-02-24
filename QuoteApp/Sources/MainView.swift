import SwiftUI
import SwiftData

struct MainQuoteView: View {
    var quote: Quote
    var showSwipeHint: Bool = false
    var isFocused: Bool = false
    var quoteIndex: Int = 1
    var totalQuotes: Int = 15
    var backgroundName: String = "majestic_peak"
    var isPremium: Bool = false

    var onSettings: () -> Void
    var onFavorites: () -> Void
    var onArchive: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isLiked = false

    // Animation States
    @State private var isVisible = false
    @State private var textBlurRadius: CGFloat = 20
    @State private var hintBounce = false
    @State private var showControls = true

    // Idea 4: Breathing Background Scale
    @State private var bgPulse = false

    // Text Reveal States
    @State private var authorText = ""
    @State private var quoteBlurRadius: CGFloat = 20

    // Background Swipe States (removed - using TabView instead)
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. 完全なる暗黒のベースレイヤー (謎の隙間や破綻を100%防止)
                Color.black.ignoresSafeArea()
                
                // 2. 背景画像 (Idea 4: Breathing)
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width + 100, height: proxy.size.height + 100)
                    .blur(radius: 8)
                    .scaleEffect(isVisible ? (bgPulse ? 1.05 : 1.0) : 1.1)
                    .clipped()
                    .opacity(0.85)
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: bgPulse)
                
                // 3. 視線誘導（Chiaroscuro）ラジアルグラデーション
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.6),
                        Color.black.opacity(1.0)
                    ]),
                    center: .center,
                    startRadius: 80,
                    endRadius: proxy.size.height * 0.8
                )

                // 4. 下部グラデーション（ツールバー背景）
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                }
                .ignoresSafeArea()

                // Idea 8: Quote Number Watermark (ナンバリング透かし)
                Text(String(format: "%02d", quoteIndex))
                    .font(.system(size: 200, weight: .black, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.03))
                    .offset(x: 80, y: -40) // 右上に配置
                
                // 5. コンテンツレイヤー (文字・ボタン群)
                contentLayer(proxy: proxy)
                
                // Idea 7: Swipe Progress Indicator (修行の進捗バー)
                progressEdgeBar
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .contentShape(Rectangle())
            // HIG: 画面全体のタップを検知してUIの表示/非表示を切り替える (Tap to Reveal)
            .onTapGesture {
                let impact = UIImpactFeedbackGenerator(style: .soft)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showControls.toggle()
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            isLiked = quote.isFavorited
            if isFocused {
                startEntranceAnimations()
            }
            if showSwipeHint {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    hintBounce = true
                }
            }
            bgPulse.toggle()
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue {
                // Focus Animation
                authorText = ""
                isVisible = false
                showControls = false
                quoteBlurRadius = 20
                startEntranceAnimations()
            } else {
                withAnimation(.easeIn(duration: 0.4)) {
                    isVisible = false
                    showControls = false
                    authorText = ""
                }
            }
        }
    }
    
    // 全てのアニメーションの司令塔
    private func startEntranceAnimations() {
        // 名言のBlur-to-Focusエフェクトと全体のフェードイン
        withAnimation(.easeOut(duration: 1.5)) {
            isVisible = true
        }
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) {
            quoteBlurRadius = 0
        }
        
        // 著者名のTypewriter Reveal (名言を読み終えるタイミングで時差をつけて開始)
        let characters = Array(quote.author.uppercased())
        for (index, char) in characters.enumerated() {
            // ディレイを1.5秒に増やし、さらに一呼吸置く演出に
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + (Double(index) * 0.05)) {
                authorText.append(char)
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred(intensity: 0.3)
            }
        }
    }
    
    @ViewBuilder
    private func contentLayer(proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            // 名言表示コンテナ (没入感重視・要素はそのままに洗練)
            VStack(alignment: .leading, spacing: 40) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 64, weight: .black))
                    .foregroundColor(.white.opacity(0.1)) // 透かし度を下げてさらに上品に
                    .offset(x: -12, y: 20)
                
                // Blur-to-Focus Quote
                Text(quote.quoteJa)
                    .font(.custom("HiraginoSans-W8", size: 40))
                    .fontWeight(.black)
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(14)
                    .minimumScaleFactor(0.4)
                    .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 10)
                    .blur(radius: quoteBlurRadius)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 20) {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 40, height: 1)
                        .scaleEffect(x: isVisible ? 1 : 0, anchor: .leading)
                        .animation(.spring().delay(0.6), value: isVisible)
                    
                    // Typewriter Author
                    Text(authorText)
                        .font(.system(size: 13, weight: .bold))
                        .tracking(6)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: proxy.size.width - 45, alignment: .leading) // 固定幅を持たせてセンターに配置することで、タイプ中のガタつきを防止
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .blur(radius: isVisible ? 0 : 10) // 外側からも少しブラーイン
            
            Spacer()
            
            // 下部ツールエリア (HIG Glassmorphism Toolbar)
            ZStack(alignment: .bottom) {
                // スワイプガイド
                if showSwipeHint && !showControls {
                    VStack(spacing: 6) {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                            .offset(y: hintBounce ? -5 : 5)
                        
                        Text("SWIPE UP")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .transition(.opacity)
                }
                
                // Glass Pill Toolbar
                if showControls {
                    HStack(spacing: 0) {
                        // Idea 5: Heavy Stamping Bookmark (重力スタンプ保存)
                        Button(action: {
                            triggerHeavyHaptic()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { // 強めのバネ
                                isLiked.toggle()
                                quote.isFavorited = isLiked
                                try? modelContext.save()
                            }
                        }) {
                            Image(systemName: isLiked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(isLiked ? .white : .white.opacity(0.85))
                                .scaleEffect(isLiked ? 1.3 : 1.0)
                                .rotationEffect(Angle(degrees: isLiked ? -5 : 0)) // 少し傾ける遊び心
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        divider
                        
                        toolbarButton(icon: "square.and.arrow.up", isActive: false) {
                            triggerHaptic()
                        }
                        
                        divider
                        
                        toolbarButton(icon: "text.book.closed", isActive: false) {
                            triggerHaptic()
                            onFavorites() // Book icon represents Favorites / Collection
                        }
                        
                        divider
                        
                        toolbarButton(icon: "clock.arrow.circlepath", isActive: false) {
                            triggerHaptic()
                            onArchive()
                        }

                        divider

                        toolbarButton(icon: "gearshape", isActive: false) {
                            triggerHaptic()
                            onSettings()
                        }
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark) // 強制的にダークモードの高級ガラスにする
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5) // ガラスの反射エッジ
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, 32) // 両サイドの余白
                    // Apple純正の美しく弾力のある「浮かび上がり」アニメーション
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(height: 60) // 高さを確保してレイアウトシフトを防ぐ
            // ボトムセーフエリアとのバランス (被りを絶対に防ぐ)
            .padding(.bottom, proxy.safeAreaInsets.bottom > 0 ? proxy.safeAreaInsets.bottom + 10 : 35)
        }
    }
    
    // Idea 7: Swipe Progress Indicator (右端の修行プログレスプロット)
    private var progressEdgeBar: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 2, height: geo.size.height * 0.3)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: (geo.size.height * 0.3) * CGFloat(quoteIndex) / CGFloat(totalQuotes))
                            .shadow(color: .white, radius: 4, x: 0, y: 0)
                            .animation(.spring(), value: quoteIndex)
                    }
                }
                .frame(width: 2)
                Spacer()
            }
            .offset(x: isFocused ? 0 : 10)
            .opacity(isFocused ? 1 : 0)
            .animation(.easeOut.delay(0.5), value: isFocused)
        }
        .padding(.trailing, 2)
    }
    
    // ツールバー用の極細仕切り線 (Craft detail)
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 1, height: 24)
    }
    
    // ツールバー用ボタン (Fitts's Law 適用・ヒットエリア巨大化)
    private func toolbarButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(isActive ? .white : .white.opacity(0.85))
                .scaleEffect(isActive ? 1.15 : 1.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // HStack内で均等に広がり、どこを押しても反応する
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
    }
    
    private func triggerHeavyHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
    }
}
