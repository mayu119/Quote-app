import SwiftUI
import SwiftData
import UIKit

struct MainQuoteView: View {
    var quote: Quote
    var showSwipeHint: Bool = false
    var isFocused: Bool = false
    var quoteIndex: Int = 1
    var totalQuotes: Int = 15
    var backgroundName: String = "blush_garden"
    var isPremium: Bool = false
    var isLockedPreview: Bool = false
    var streakDays: Int = 1
    var weeklySaveCount: Int = 0
    var topCategoryTitle: String?
    var recommendedPunchline: String?
    var recommendedCategoryTitle: String?
    var activeSpiritualBundle: SpiritualBundle?
    var dailyRitualState: DailyRitualState?
    var todayWordSelection: TodayWordSelection?

    var onSettings: () -> Void
    var onFavorites: () -> Void
    var onArchive: () -> Void
    var onCalendar: () -> Void
    var onCategorySelect: () -> Void
    var onSpiritualBundleSelect: () -> Void
    var onWallpaperSelect: () -> Void
    var onToggleTodayWord: () -> Void
    var onPremium: () -> Void
    var onTutorialVerticalSwipe: (() -> Void)? = nil
    var onTutorialSaveSwipe: (() -> Void)? = nil
    var onTutorialShareSwipe: (() -> Void)? = nil
    var onTutorialShareTap: (() -> Void)? = nil
    var onTutorialLongPress: (() -> Void)? = nil
    var onTutorialToolbarTap: (() -> Void)? = nil
    var isInteractionGuideActive: Bool = false
    var interactionGuideStage: InteractionGuideOverlay.Stage? = nil

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings

    @State private var isLiked = false

    // Animation States
    @State private var isVisible = false
    @State private var hintBounce = false
    @State private var showControls = false

    // Particle Burst
    @State private var particleScale: CGFloat = 0.0
    @State private var particleOpacity: Double = 0.0

    // Text Reveal
    @State private var authorText = ""
    @State private var quoteBlurRadius: CGFloat = 20

    // Tinder Swipe States
    @State private var swipeOffset: CGSize = .zero
    @State private var isDismissed: Bool = false
    @State private var dismissAction: SwipeAction? = nil
    
    // Share Feature States
    @State private var isShareMode = false
    @State private var showNativeShare = false
    @State private var shareFormat: ShareImageFormat = .stories
    @State private var showQuoteInsight = false
    @State private var quoteInsightButtonFrame: CGRect = .zero
    
    // Reflection Flow
    @State private var showReflectionComposer = false
    @State private var reflectionNoteText = ""
    @State private var reflectionPrompt = "なぜこの言葉に心が動いた？"
    @State private var showInsightSuggestion = false
    private let blush = Color(red: 0.90, green: 0.74, blue: 0.83)
    private let warmIvory = Color(red: 0.99, green: 0.94, blue: 0.95)
    private let softGold = Color(red: 0.90, green: 0.78, blue: 0.58)
    private let mysticPlum = Color(red: 0.23, green: 0.14, blue: 0.28)
    private let orchidMist = Color(red: 0.67, green: 0.55, blue: 0.73)
    private let ink = Color(red: 0.22, green: 0.18, blue: 0.22)
    private let mutedInk = Color(red: 0.44, green: 0.39, blue: 0.43)

    enum SwipeAction { case save, archive }

    private var windowTopSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. Outer Background (visible when card scales down)
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width + 100, height: proxy.size.height + 100)
                    .blur(radius: isShareMode ? 20 : 0)
                    .opacity(isShareMode ? 0.6 : 0)
                    .scaleEffect(isVisible ? 1.0 : 1.1)
                    .clipped()
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.5), value: isShareMode)
                
                // 2. Main Card content
                ZStack {
                    // 内側背景画像
                    Image(backgroundName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width + 100, height: proxy.size.height + 100)
                        .blur(radius: 4)
                        .scaleEffect(isVisible ? 1.0 : 1.1)
                        .clipped()
                        .opacity(0.85)
                        .allowsHitTesting(false)

                    // 3. Chiaroscuro グラデーション
                    RadialGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.6), .black.opacity(1.0)]),
                        center: .center, startRadius: 80,
                        endRadius: proxy.size.height * 0.8
                    )
                    .allowsHitTesting(false)

                    mysticVeil(proxy: proxy)
                        .allowsHitTesting(false)

                    // 4. 下部グラデーション
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 200)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                    // 5. ナンバリング透かし
                    Text(String(format: "%02d", quoteIndex))
                        .font(.system(size: 200, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.03))
                        .offset(x: 80, y: -40)
                        .allowsHitTesting(false)

                    // 6. 日付ヘッダー
                    VStack {
                        topDateHeader(proxy: proxy)
                        Spacer()
                    }
                    .zIndex(10)

                    if isDismissed {
                        VStack(spacing: 20) {
                            Image(systemName: dismissAction == .save ? "bookmark.fill" : "archivebox.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))
                            VStack(spacing: 8) {
                                Text(dismissAction == .save ? "あなたの棚に置きました" : "アーカイブしました")
                                    .font(.custom("HiraginoSans-W7", size: 22))
                                    .foregroundColor(.white.opacity(0.92))

                                Text("スワイプして次の言葉へ")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                        .background(Color.black.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .transition(.opacity)
                    } else {
                        contentLayer(proxy: proxy)
                            .opacity(1.0 - Double(abs(swipeOffset.width) / (proxy.size.width / 2)))
                        progressEdgeBar
                            .opacity(isShareMode ? 0 : 1.0 - Double(abs(swipeOffset.width) / 100))
                        
                        if !isShareMode {
                            premiumSwipeIndicators(proxy: proxy)
                        }
                    }
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                .clipShape(RoundedRectangle(cornerRadius: isShareMode ? 40 : 0, style: .continuous))
                .scaleEffect(isShareMode ? 0.70 : 1.0)
                .offset(
                    x: isShareMode ? 0 : swipeOffset.width,
                    y: isShareMode ? -40 : swipeOffset.height * 0.2
                )
                .rotationEffect(.degrees(isShareMode ? 0 : Double(swipeOffset.width / 15)))
                .shadow(color: .black.opacity(isShareMode ? 0.6 : 0), radius: 30, x: 0, y: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: isShareMode ? 40 : 0, style: .continuous)
                        .stroke(Color.white.opacity(isShareMode ? 0.2 : 0), lineWidth: 1)
                )
                
                // 3. Gesture View (Top level to always capture full screen)
                HorizontalPanGestureOverlay(
                    ignoredFrames: quoteInsightButtonFrame.isEmpty ? [] : [quoteInsightButtonFrame],
                    onTap: {
                        if isShareMode {
                            triggerHaptic()
                            onTutorialShareTap?()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShareMode = false
                            }
                            return
                        }
                        if isLockedPreview {
                            triggerHaptic()
                            onPremium()
                            return
                        }
                        onTutorialToolbarTap?()
                        guard !isDismissed else { return }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showControls.toggle()
                        }
                    },
                    onLongPress: {
                        onTutorialLongPress?()
                        openQuoteInsight()
                    },
                    onChanged: { translation in
                        guard !isDismissed && !isShareMode && !isLockedPreview else { return }
                        swipeOffset = translation
                    },
                    onEnded: { translation in
                        guard !isDismissed && !isShareMode && !isLockedPreview else { return }
                        let threshold = proxy.size.width * 0.35

                        // Swipe Right → Share Feature (Replaces Archive)
                        if translation.width > threshold {
                            triggerHeavyHaptic()
                            onTutorialShareSwipe?()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShareMode = true
                                showControls = false
                                swipeOffset = .zero
                            }
                        }
                        // Swipe Left → 保存 (Save) または 解除 (Remove)
                        else if translation.width < -threshold {
                            if isLiked {
                                triggerHeavyHaptic()
                                removeFavorite()
                            } else {
                                onTutorialSaveSwipe?()
                                if isInteractionGuideActive, interactionGuideStage == .saveSwipe {
                                    showTutorialFavoriteFeedback()
                                } else {
                                    commitFavoriteAndOpenReflection()
                                }
                            }
                        }
                        // スナップバック
                        else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                swipeOffset = .zero
                            }
                        }
                    },
                    onThresholdHaptic: { triggerDeepHaptic() }
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                
                // 4. Share UI Overlay
                if isShareMode {
                    shareOverlay(proxy: proxy)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .coordinateSpace(name: "MainQuoteViewSpace")
        .ignoresSafeArea(.all)
        .fullScreenCover(isPresented: $showReflectionComposer) {
            ReflectionComposerView(
                quote: quote,
                prompt: reflectionPrompt,
                noteText: $reflectionNoteText,
                onClose: closeReflection,
                onSave: saveReflectionNote
            )
        }
        .sheet(isPresented: $showQuoteInsight) {
            QuoteInsightSheet(
                quote: quote,
                isPremiumUser: userSettings.isPremiumUser,
                onPremium: presentPremiumFromInsight
            )
        }
        .confirmationDialog(
            "この言葉には、もう一段あります",
            isPresented: $showInsightSuggestion,
            titleVisibility: .visible
        ) {
            Button("解説を読む") {
                AnalyticsService.shared.logInsightSuggestionOpen(quoteId: quote.id)
                showQuoteInsight = true
            }
            Button("今はここまで", role: .cancel) {}
        } message: {
            Text("この言葉が生まれた背景と、もう少し深い余韻を読めます。")
        }
        .onAppear {
            isLiked = quote.isFavorited
            if isFocused { startEntranceAnimations() }
            if showSwipeHint {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    hintBounce = true
                }
            }
        }
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                authorText = ""; isVisible = false; showControls = false; quoteBlurRadius = 20
                startEntranceAnimations()
            } else {
                withAnimation(.easeIn(duration: 0.6)) {
                    isVisible = false; showControls = false; authorText = ""; quoteBlurRadius = 30
                }
            }
        }
        .onPreferenceChange(QuoteInsightButtonFramePreferenceKey.self) { frame in
            quoteInsightButtonFrame = frame
        }
    }

    // MARK: - Entrance Animations

    private func startEntranceAnimations() {
        withAnimation(.easeOut(duration: 1.5)) { isVisible = true }
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) { quoteBlurRadius = 0 }
        let characters = Array(quote.displayAuthor)
        for (i, char) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.05) {
                authorText.append(char)
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
            }
        }
    }

    // MARK: - Views

    @ViewBuilder
    private func topDateHeader(proxy: GeometryProxy) -> some View {
        if userSettings.showDateHeader {
            let effectiveTopInset = max(proxy.safeAreaInsets.top, windowTopSafeAreaInset)

            HStack {
                Spacer()
                HStack(spacing: 10) {
                    Text(currentDateString())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundColor(warmIvory.opacity(0.96))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [softGold.opacity(0.82), blush.opacity(0.76)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: 16)

                    Text(quote.category.displayTitleJa)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(warmIvory)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    mysticPlum.opacity(0.72),
                                    orchidMist.opacity(0.28),
                                    mysticPlum.opacity(0.64)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(softGold.opacity(0.24), lineWidth: 1)
                        )
                )
                .shadow(color: mysticPlum.opacity(0.30), radius: 22, x: 0, y: 10)
                Spacer()
            }
            // GeometryReader is extended under the status bar. Keep the compact
            // badge below Dynamic Island and above the quote's reserved top edge.
            .padding(.top, max(effectiveTopInset + 55, 112))
            .opacity(showControls ? 1 : 0)
            .offset(y: showControls ? 0 : -20)
            .blur(radius: showControls ? 0 : 5)
        }
    }

    @ViewBuilder
    private func contentLayer(proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            if userSettings.isVerticalTextMode {
                verticalQuoteContent(proxy: proxy)
            } else {
                horizontalQuoteContent(proxy: proxy)
            }

            Spacer()

            // Toolbar
            ZStack(alignment: .bottom) {
                if showSwipeHint && !showControls {
                    VStack(spacing: 6) {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(blush.opacity(0.85))
                            .offset(y: hintBounce ? -5 : 5)
                        Text("SWIPE UP")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(softGold.opacity(0.70))
                    }
                    .transition(.opacity)
                }

                if isLockedPreview {
                    lockedPreviewFooter
                }

                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    mysticPlum.opacity(0.80),
                                    orchidMist.opacity(0.28),
                                    mysticPlum.opacity(0.68)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(softGold.opacity(0.20), lineWidth: 1)
                        )
                        .shadow(color: mysticPlum.opacity(0.34), radius: 18, x: 0, y: 10)
                    .frame(width: showControls ? proxy.size.width - 64 : 16,
                               height: showControls ? 60 : 16)
                        .opacity(showControls && !isLockedPreview ? 1 : 0)

                    HStack(spacing: 0) {
                        // Bookmark button with particles
                        ZStack {
                            if particleOpacity > 0 {
                                ForEach(0..<12, id: \.self) { i in
                                    let angle = Double(i) * (360.0 / 12.0)
                                    Capsule().fill(blush).frame(width: 2, height: 6)
                                        .offset(y: -20 * particleScale)
                                        .rotationEffect(.degrees(angle))
                                        .opacity(particleOpacity)
                                }
                            }
                            Button(action: {
                                triggerHeavyHaptic()
                                if isLiked {
                                    removeFavorite()
                                } else {
                                    commitFavoriteAndOpenReflection()
                                    withAnimation(.easeOut(duration: 0.6)) {
                                        particleScale = 1.8
                                        particleOpacity = 0.0
                                    }
                                }
                            }) {
                                Image(systemName: isLiked ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(isLiked ? blush : warmIvory.opacity(0.92))
                                    .scaleEffect(isLiked ? 1.3 : 1.0)
                                    .rotationEffect(.degrees(isLiked ? -5 : 0))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if Config.enableSpiritualRitual {
                            divider
                            toolbarButton(icon: "sparkles") { triggerHaptic(); onSpiritualBundleSelect() }
                        }
                        divider
                        toolbarButton(icon: "square.grid.2x2") { triggerHaptic(); onCategorySelect() }
                        divider
                        divider
                        toolbarButton(icon: "calendar") { triggerHaptic(); onCalendar() }
                        divider
                        moreToolbarMenu
                    }
                    .frame(width: proxy.size.width - 64, height: 60)
                    .padding(.horizontal, 10)
                    .opacity(showControls && !isLockedPreview ? 1 : 0)
                    .scaleEffect(showControls && !isLockedPreview ? 1.0 : 0.6)
                    .blur(radius: showControls && !isLockedPreview ? 0 : 5)
                }
                .offset(y: showControls && !isLockedPreview ? 0 : 30)
            }
            .frame(height: 60)
            .padding(.bottom, proxy.safeAreaInsets.bottom > 0 ? proxy.safeAreaInsets.bottom + 45 : 65)
        }
    }

    @ViewBuilder
    private func horizontalQuoteContent(proxy: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            if let dailyRitualState, let bundle = dailyRitualState.bundle {
                dailyRitualBanner(bundle: bundle, state: dailyRitualState)
            }

            VStack(alignment: .leading, spacing: 40) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 64, weight: .black))
                    .foregroundColor(.white.opacity(0.1))
                    .offset(x: -12, y: 20)
                Group {
                    if isLockedPreview {
                        lockedQuoteText
                    } else {
                        Text(quote.quoteJa)
                            .font(.custom("HiraginoSans-W8", size: 40)).fontWeight(.black)
                            .foregroundColor(.white.opacity(0.95)).lineSpacing(14)
                            .minimumScaleFactor(0.4)
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
                            .blur(radius: quoteBlurRadius)
                            .scaleEffect(isVisible ? 1.0 : 0.98)
                            .offset(x: isVisible ? 0 : -10)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if quote.hasVisibleAuthorAttribution {
                    HStack(spacing: 20) {
                        Rectangle().fill(Color.white.opacity(0.8)).frame(width: 40, height: 1)
                            .scaleEffect(x: isVisible ? 1 : 0, anchor: .leading)
                            .animation(.spring().delay(0.6), value: isVisible)
                        Text(isLockedPreview ? quote.displayAuthor : authorText)
                            .font(.system(size: 13, weight: .bold)).tracking(6)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            if showControls {
                quoteInsightButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: proxy.size.width - 45, alignment: .leading)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .blur(radius: isVisible ? 0 : 10)
    }

    @ViewBuilder
    private func verticalQuoteContent(proxy: GeometryProxy) -> some View {
        // --- 名言が長すぎた場合に備えた「文字列自体」の整形処理 ---
        let availableTextHeight = proxy.size.height * 0.45
        let baseFontSize: CGFloat = 34.0

        let totalCharacterCount = quote.quoteJa.filter { $0 != "\n" }.count
        let heightDrivenLimit = max(10, Int(availableTextHeight / (baseFontSize * 1.15)))

        // 高さだけで切ると縦列が増えすぎるため、横幅から「理想の列数」も逆算する
        let preferredColumnCount = min(5, max(4, Int((proxy.size.width - 92) / (baseFontSize + 14))))
        let widthDrivenLimit = Int(ceil(Double(max(totalCharacterCount, 1)) / Double(preferredColumnCount)))
        let maxCharsPerLine = max(heightDrivenLimit, widthDrivenLimit)

        let foldedText = JapaneseLineBreaker.fold(quote.quoteJa, maxPerLine: maxCharsPerLine)
        let maxLineLength = foldedText.components(separatedBy: "\n").map { $0.count }.max() ?? 1

        let calcSize = availableTextHeight / CGFloat(maxLineLength) / 1.15
        let dynamicFontSize = min(baseFontSize, max(24.0, calcSize))

        // 名言と著者名を完全に独立配置させることで、著者名の高さが名言を上へ押し上げる現象を根絶する
        ZStack(alignment: .bottomLeading) {
            if let dailyRitualState, let bundle = dailyRitualState.bundle {
                VStack {
                    dailyRitualBanner(bundle: bundle, state: dailyRitualState)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // 1. 名言本体（中央揃え・高さ変更なし）
            Group {
                if isLockedPreview {
                    lockedQuoteText
                } else {
                    VerticalTextView(
                        text: foldedText,
                        fontName: "HiraMinProN-W6",
                        fontSize: dynamicFontSize,
                        lineSpacing: 18,
                        textColor: .white
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
                    .blur(radius: quoteBlurRadius)
                    .scaleEffect(isVisible ? 1.0 : 0.98)
                    .offset(x: isVisible ? 0 : -10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            // 2. 著者名（左下に添えるだけ。名言の高さを一切邪魔しない）
            Group {
                if quote.hasVisibleAuthorAttribution {
                    HStack(alignment: .bottom, spacing: 14) {
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.65, blue: 0.2))
                            .frame(width: 2, height: 40)
                            .scaleEffect(y: isVisible ? 1 : 0, anchor: .bottom)
                            .animation(.spring().delay(0.6), value: isVisible)

                        ZStack(alignment: .topLeading) {
                            VerticalTextView(
                                text: quote.displayAuthor,
                                fontName: "HiraginoSans-W6",
                                fontSize: 14,
                                lineSpacing: 0,
                                textColor: .clear
                            )

                            VerticalTextView(
                                text: isLockedPreview ? quote.displayAuthor : (authorText.isEmpty ? " " : authorText),
                                fontName: "HiraginoSans-W6",
                                fontSize: 14,
                                lineSpacing: 0,
                                textColor: .white.opacity(0.8)
                            )
                        }
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.bottom, 20)
        }
        .frame(width: proxy.size.width - 40, height: proxy.size.height * 0.75)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .blur(radius: isVisible ? 0 : 10)
        .overlay(alignment: .bottomTrailing) {
            if showControls {
                quoteInsightButton
                    .padding(.trailing, 8)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var lockedQuoteText: some View {
        let quoteFont = Font.custom("HiraginoSans-W8", size: 40).weight(.black)

        return Text(quote.quoteJa)
            .font(quoteFont)
            .foregroundColor(.clear)
            .lineSpacing(14)
            .minimumScaleFactor(0.4)
            .fixedSize(horizontal: false, vertical: true)
            .overlay {
                lockedBlurredGlyphs(font: quoteFont)
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("PREVIEW")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(2.5)
                }
                .foregroundColor(.white.opacity(0.58))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(Capsule())
                .offset(y: -54)
            }
    }

    private func dailyRitualBanner(bundle: SpiritualBundle, state: DailyRitualState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: bundle.symbol)
                    .font(.system(size: 11, weight: .bold))
                Text("TODAY'S INTENTION")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(2.4)
            }
            .foregroundColor(softGold.opacity(0.92))

            Text(state.intention)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(warmIvory)
                .fixedSize(horizontal: false, vertical: true)

            Text("手放す: \(state.release)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.70))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            mysticPlum.opacity(0.72),
                            orchidMist.opacity(0.26),
                            mysticPlum.opacity(0.64)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(softGold.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: mysticPlum.opacity(0.24), radius: 14, x: 0, y: 8)
    }

    private func lockedBlurredGlyphs(font: Font) -> some View {
        ZStack {
            Text(quote.quoteJa)
                .font(font)
                .foregroundColor(.white.opacity(0.18))
                .lineSpacing(14)
                .minimumScaleFactor(0.4)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: 10)

            Text(quote.quoteJa)
                .font(font)
                .foregroundColor(Color.white.opacity(0.26))
                .lineSpacing(14)
                .minimumScaleFactor(0.4)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: 18)
                .scaleEffect(x: 1.03, y: 1.08)

            Text(quote.quoteJa)
                .font(font)
                .foregroundColor(Color(red: 0.84, green: 0.78, blue: 0.64).opacity(0.18))
                .lineSpacing(14)
                .minimumScaleFactor(0.4)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: 24)
                .offset(x: -6, y: -2)

            Text(quote.quoteJa)
                .font(font)
                .foregroundColor(.white.opacity(0.14))
                .lineSpacing(14)
                .minimumScaleFactor(0.4)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: 30)
                .offset(x: 5, y: 3)

            Text(quote.quoteJa)
                .font(font)
                .foregroundColor(.white.opacity(0.08))
                .lineSpacing(14)
                .minimumScaleFactor(0.4)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: 38)
                .scaleEffect(x: 1.08, y: 1.14)
        }
        .compositingGroup()
    }

    private var lockedPreviewFooter: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text("PREVIEW")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.4))

                Text("続きを読む")
                    .font(.custom("HiraginoSans-W8", size: 20))
                    .foregroundColor(.white.opacity(0.96))

                Text("10枚目までは無料")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            Button(action: {
                triggerHaptic()
                onPremium()
            }) {
                HStack(spacing: 10) {
                    Text("PREMIUM で解放")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2.8)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                }
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .transition(.opacity)
    }

    private var progressEdgeBar: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 2, height: geo.size.height * 0.3)
                        Rectangle().fill(Color.white)
                            .frame(width: 2, height: (geo.size.height * 0.3) * CGFloat(quoteIndex) / CGFloat(totalQuotes))
                            .shadow(color: .white, radius: 4).animation(.spring(), value: quoteIndex)
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

    @ViewBuilder
    private var insightPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                insightChip(
                    title: "継続",
                    value: "\(streakDays)日",
                    subtitle: "連続で開いています"
                )

                if weeklySaveCount > 0 {
                    insightChip(
                        title: "今週保存",
                        value: "\(weeklySaveCount)件",
                        subtitle: topCategoryTitle ?? "積み上がっています"
                    )
                }
            }

            if let recommendedPunchline, !recommendedPunchline.isEmpty {
                if isPremium {
                    insightRecommendationCard(
                        title: "あなた向け",
                        body: recommendedPunchline,
                        footnote: recommendedCategoryTitle ?? "保存傾向から選出"
                    )
                } else {
                    Button(action: {
                        triggerHaptic()
                        onPremium()
                    }) {
                        insightRecommendationCard(
                            title: "PRO 提案",
                            body: "保存傾向から、今のあなたに近い一言を毎日提示",
                            footnote: "パーソナルレコメンドを解放"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quoteInsightButton: some View {
        Button(action: openQuoteInsight) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 13, weight: .semibold))
                Text("この言葉を深く知る")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(warmIvory)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.28))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: QuoteInsightButtonFramePreferenceKey.self,
                        value: geometry.frame(in: .named("MainQuoteViewSpace"))
                    )
            }
        )
    }

    private func insightChip(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .tracking(2)
                .foregroundColor(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.95))
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func insightRecommendationCard(title: String, body: String, footnote: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isPremium ? "sparkles" : "crown.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(2.5)
            }
            .foregroundColor(.white.opacity(0.7))

            Text(body)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(3)
                .lineLimit(3)

            Text(footnote)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.14)).frame(width: 1, height: 22)
    }

    private func toolbarButton(icon: String, foreground: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(foreground ?? warmIvory.opacity(0.92))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var moreToolbarMenu: some View {
        Menu {
            Button {
                triggerHaptic()
                onFavorites()
            } label: {
                Label("保存一覧", systemImage: "text.book.closed")
            }

            Button {
                triggerHaptic()
                onArchive()
            } label: {
                Label("アーカイブ", systemImage: "archivebox")
            }

            Button {
                triggerHaptic()
                onWallpaperSelect()
            } label: {
                Label("壁紙", systemImage: "photo.stack")
            }

            Button {
                triggerHaptic()
                onToggleTodayWord()
            } label: {
                Label(
                    todayWordSelection?.quoteID == quote.id ? "今日の言葉を解除" : "今日の言葉にする",
                    systemImage: todayWordSelection?.quoteID == quote.id ? "pin.slash" : "pin"
                )
            }

            if Config.enableSpiritualRitual {
                Button {
                    triggerHaptic()
                    onSpiritualBundleSelect()
                } label: {
                    Label("Ritual", systemImage: "sparkles")
                }
            }

            Button {
                triggerHaptic()
                onSettings()
            } label: {
                Label("設定", systemImage: "gearshape")
            }

            if !isPremium {
                Button {
                    triggerHaptic()
                    onPremium()
                } label: {
                    Label("Premium", systemImage: "crown.fill")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(warmIvory.opacity(0.92))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var premiumToolbarButton: some View {
        Button(action: {
            triggerHaptic()
            onPremium()
        }) {
            VStack(spacing: 2) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("PRO")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(1.5)
            }
            .foregroundColor(softGold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func premiumSwipeIndicators(proxy: GeometryProxy) -> some View {
        let maxOffset = proxy.size.width * 0.4
        let rawProgress = min(1.0, max(0, abs(swipeOffset.width) / maxOffset))
        let heartbeat = 1.0 + sin(rawProgress * .pi * 5) * 0.1

        ZStack {
            if rawProgress > 0 {
                Color.black.opacity(Double(rawProgress) * 0.75).ignoresSafeArea()
            }
            if swipeOffset.width > 0 {
                HStack {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [.white.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: 100))
                            .frame(width: 250 * heartbeat, height: 250 * heartbeat)
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 36 * heartbeat, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .white.opacity(0.5), radius: 10 * rawProgress)
                            Text("SHARE")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .tracking(4).foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.leading, 10).opacity(rawProgress * 1.2)
                    Spacer()
                }
            }
            if swipeOffset.width < 0 {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [(isLiked ? Color.red : Color.orange).opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 120))
                            .frame(width: 250 * heartbeat, height: 250 * heartbeat)
                        VStack(spacing: 12) {
                            Image(systemName: isLiked ? "bookmark.slash.fill" : "bookmark.fill")
                                .font(.system(size: 36 * heartbeat, weight: .ultraLight))
                                .foregroundColor((isLiked ? Color.red : Color.orange).opacity(0.9))
                                .shadow(color: (isLiked ? Color.red : Color.orange).opacity(0.8), radius: 15 * rawProgress)
                            Text(isLiked ? "REMOVE" : "SAVE")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .tracking(4).foregroundColor((isLiked ? Color.red : Color.orange).opacity(0.8))
                        }
                    }
                    .padding(.trailing, 10).opacity(rawProgress * 1.2)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Share Overlay Utils
    
    @ViewBuilder
    private func shareOverlay(proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            VStack(spacing: 30) {
                Text("SHARE QUOTE")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .tracking(6)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                HStack(spacing: 40) {
                    ShareOptionButton(icon: "photo.circle.fill", title: "SAVE IMAGE", color: .white) {
                        triggerHeavyHaptic()
                        showNativeShare = true
                    }
                    ShareOptionButton(icon: "camera.circle.fill", title: "INSTAGRAM", color: .purple) {
                        triggerHeavyHaptic()
                        let success = ShareManager.shared.shareToInstagramStories(
                            quote: quote,
                            quoteIndex: quoteIndex,
                            backgroundName: backgroundName,
                            format: shareFormat,
                            isVertical: userSettings.isVerticalTextMode
                        )
                        if !success {
                            showNativeShare = true
                        }
                    }
                    ShareOptionButton(icon: "ellipsis.circle.fill", title: "MORE", color: .gray) {
                        triggerHeavyHaptic()
                        showNativeShare = true
                    }
                }
                
                Button(action: {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isShareMode = false
                    }
                }) {
                    Text("CANCEL")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
            .padding(.bottom, proxy.safeAreaInsets.bottom > 0 ? proxy.safeAreaInsets.bottom + 20 : 40)
            .padding(.top, 40)
            .frame(width: proxy.size.width)
            .background(
                LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.8), .black], startPoint: .top, endPoint: .bottom)
            )
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showNativeShare) {
            let items = ShareManager.shared.getShareItems(
                quote: quote,
                quoteIndex: quoteIndex,
                backgroundName: backgroundName,
                format: shareFormat,
                isVertical: userSettings.isVerticalTextMode
            )
            NativeShareSheet(activityItems: items)
        }
    }

    @ViewBuilder
    private func mysticVeil(proxy: GeometryProxy) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [blush.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: proxy.size.width * 0.40
                    )
                )
                .frame(width: proxy.size.width * 0.78)
                .offset(x: proxy.size.width * 0.20, y: -proxy.size.height * 0.28)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [orchidMist.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: proxy.size.width * 0.46
                    )
                )
                .frame(width: proxy.size.width * 0.92)
                .offset(x: -proxy.size.width * 0.30, y: proxy.size.height * 0.10)
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    private func triggerHeavyHaptic() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    private func triggerDeepHaptic() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0) }

    private func openQuoteInsight() {
        guard !isDismissed && !isShareMode else { return }
        if isLockedPreview {
            triggerHaptic()
            onPremium()
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showQuoteInsight = true
    }

    private func commitFavoriteAndOpenReflection() {
        let dataService = QuoteDataService(modelContext: modelContext)

        do {
            try dataService.toggleFavorite(quote: quote, isPremium: userSettings.isPremiumUser)
        } catch QuoteError.favoriteLimitReached {
            AnalyticsService.shared.logFavoriteLimitHit(
                currentCount: Config.freeUserFavoriteLimit,
                limit: Config.freeUserFavoriteLimit
            )
            onPremium()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                swipeOffset = .zero
            }
            return
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                swipeOffset = .zero
            }
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
            isLiked = true
            swipeOffset = .zero
            showControls = false
        }

        userSettings.recordSave(category: quote.category)
        let totalFavorites = (try? dataService.getFavoriteQuotes().count) ?? 1
        AnalyticsService.shared.logFavoriteAdd(
            quoteId: quote.id,
            author: quote.author,
            categoryMedium: quote.category.rawValue,
            totalFavorites: totalFavorites
        )

        particleScale = 0.2
        particleOpacity = 1.0
        withAnimation(.easeOut(duration: 0.7)) {
            particleScale = 2.5
            particleOpacity = 0.0
        }

        reflectionNoteText = quote.favoriteNote ?? ""
        reflectionPrompt = reflectionPromptText()
        showReflectionComposer = true
    }

    private func showTutorialFavoriteFeedback() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
            swipeOffset = .zero
            showControls = false
        }

        particleScale = 0.2
        particleOpacity = 1.0
        withAnimation(.easeOut(duration: 0.7)) {
            particleScale = 2.5
            particleOpacity = 0.0
        }
    }

    private func saveReflectionNote() {
        let trimmed = reflectionNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        quote.favoriteNote = trimmed.isEmpty ? nil : trimmed
        try? modelContext.save()
        AnalyticsService.shared.logFavoriteNoteSave(
            quoteId: quote.id,
            noteLength: trimmed.count,
            isPremium: userSettings.isPremiumUser
        )
        closeReflection()
        if ExperimentAssignmentService.shared.recordEligibleInsightSaveAndShouldShow() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AnalyticsService.shared.logInsightSuggestionShown(quoteId: quote.id)
                showInsightSuggestion = true
            }
        }
    }

    private func closeReflection() {
        showReflectionComposer = false
    }

    private func presentPremiumFromInsight() {
        showQuoteInsight = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onPremium()
        }
    }

    private func removeFavorite() {
        let dataService = QuoteDataService(modelContext: modelContext)

        do {
            try dataService.toggleFavorite(quote: quote, isPremium: userSettings.isPremiumUser)
            let totalFavorites = (try? dataService.getFavoriteQuotes().count) ?? 0

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isLiked = false
                swipeOffset = .zero
            }

            userSettings.recordArchive(category: quote.category)
            AnalyticsService.shared.logFavoriteRemove(
                quoteId: quote.id,
                author: quote.author,
                categoryMedium: quote.category.rawValue,
                totalFavorites: totalFavorites
            )
        } catch {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                swipeOffset = .zero
            }
        }
    }

    private func reflectionPromptText() -> String {
        let prompts = [
            "今の自分に、どこが触れた？",
            "今日この言葉を置いておきたい理由は？",
            "あとで開いた自分に、何を残しておく？"
        ]
        return prompts[quoteIndex % prompts.count]
    }

    private func currentDateString() -> String {
        let f = DateFormatter(); f.dateFormat = "M/d"; f.timeZone = .current
        return f.string(from: Date())
    }
}

// MARK: - Share UI Components

struct ShareOptionButton: View {
    var icon: String
    var title: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 10)
                
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }
}

struct NativeShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ReflectionComposerView: View {
    let quote: Quote
    let prompt: String
    @Binding var noteText: String
    let onClose: () -> Void
    let onSave: () -> Void
    @FocusState private var isEditorFocused: Bool

    private let pageBackground = Color(hex: "F1E9E3")
    private let sheetBackground = Color(hex: "FFFCF8")
    private let primaryText = Color(hex: "2F2730")
    private let secondaryText = Color(hex: "7D7280")
    private let accentRose = Color(hex: "EAA3A1")
    private let accentLavender = Color(hex: "8D90A2")
    private let borderColor = Color(hex: "E8DDD6")
    private let quoteCardTop = Color(hex: "FFF1F4")
    private let quoteCardBottom = Color(hex: "F6C7D2")
    private let noteFill = Color(hex: "F8F1EC")

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        pageBackground,
                        Color(hex: "F7F1EB"),
                        Color(hex: "EFE5DE")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            HStack {
                                Button(action: onClose) {
                                    Text("あとで")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(primaryText)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 11)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(action: onClose) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryText.opacity(0.82))
                                        .frame(width: 42, height: 42)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(borderColor, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("残した理由")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accentLavender)
                                    .tracking(0.8)

                                Text(prompt)
                                    .font(.system(size: 31, weight: .bold))
                                    .foregroundColor(primaryText)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("いまの自分に触れた理由を残しておくと、あとで読み返したときに気持ちの流れまで見えてきます。")
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
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("今日、置いておく言葉")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(primaryText)

                                    ZStack(alignment: .topLeading) {
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(Color.white.opacity(0.94))

                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [quoteCardTop, quoteCardBottom],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(height: 116)
                                            .frame(maxHeight: .infinity, alignment: .top)

                                        Circle()
                                            .fill(Color.white.opacity(0.45))
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

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(quote.quoteJa)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(primaryText)
                                                .lineSpacing(4)
                                                .fixedSize(horizontal: false, vertical: true)

                                            Text(quote.displayAuthor)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(secondaryText)
                                        }
                                        .padding(18)
                                        .padding(.top, 112)
                                    }
                                    .frame(minHeight: 208)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(borderColor, lineWidth: 1)
                                    )
                                    .shadow(color: Color(hex: "D8C8BF").opacity(0.14), radius: 14, x: 0, y: 8)
                                }

                                VStack(alignment: .leading, spacing: 12) {
                                    Text("残した理由")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(primaryText)

                                    Text("長く書かなくて大丈夫です。その瞬間の本音をひとことで残せば十分です。")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(secondaryText)

                                    ZStack(alignment: .topLeading) {
                                        if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Text("例えば: 比べて苦しかったけど、この一言で自分に戻れた")
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
                                            .frame(minHeight: 220)
                                            .padding(12)
                                            .focused($isEditorFocused)
                                    }
                                    .background(noteFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(borderColor, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                }

                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(accentRose)

                                    Text("残した理由は、言葉の棚からあとで書き直せます。")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(secondaryText)
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        }
                        .scrollDismissesKeyboard(.interactively)
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
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if !isEditorFocused {
                        HStack(spacing: 12) {
                            Button(action: onClose) {
                                Text("まずは置いておく")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.92))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button(action: onSave) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "言葉を棚に置く" : "理由を残して置く")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
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
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isEditorFocused = false
                }
                .foregroundColor(primaryText)
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - HorizontalPanGestureOverlay

class PassThroughPanView: UIView {
    var ignoredFrames: [CGRect] = []

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // If the view returned is self (meaning it didn't hit a subview)
        if view == self {
            if ignoredFrames.contains(where: { $0.contains(point) }) {
                return nil
            }
            // Ignore touches in the bottom 150 points where the toolbar lives
            if point.y > self.bounds.height - 150 {
                return nil
            }
        }
        return view
    }
}

private struct QuoteInsightButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

struct QuoteInsightSheet: View {
    let quote: Quote
    let isPremiumUser: Bool
    let onPremium: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let ivory = Color(red: 0.98, green: 0.96, blue: 0.94)
    private let rose = Color(red: 0.92, green: 0.82, blue: 0.83)
    private let ink = Color(red: 0.23, green: 0.18, blue: 0.20)
    private let mutedInk = Color(red: 0.43, green: 0.36, blue: 0.39)

    private var previewText: String {
        quote.meaningPreview ?? "この言葉の背景は現在準備中です。"
    }

    private var premiumText: String {
        quote.meaningPremium ?? "続きを準備しています。"
    }

    private var displayPremiumText: String {
        condensedPremiumText(
            premiumText,
            sourceContext: quote.visibleSourceContext
        )
    }

    private var previewSectionTitle: String {
        "この言葉が伝えていること"
    }

    private var premiumUnlockItems: [String] {
        [
            "この言葉の解釈を最後まで読めます",
            "この言葉が今の自分にどう響くのかまで読めます",
            "この言葉の背景や込められた意図まで読めます"
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(quote.category.displayTitleJa)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(mutedInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(rose.opacity(0.32)))

                        Text("「\(quote.quoteJa)」")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ink)
                            .lineSpacing(6)

                        if quote.hasVisibleAuthorAttribution {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quote.displayAuthor)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ink)
                                if let authorMetaLine = quote.authorMetaLine {
                                    Text(authorMetaLine)
                                        .font(.system(size: 13))
                                        .foregroundStyle(mutedInk)
                                }
                            }
                        }
                    }

                    insightSection(
                        title: previewSectionTitle,
                        body: previewText,
                        accent: rose
                    )

                    if let sourceContext = quote.visibleSourceContext {
                        insightSection(
                            title: "この言葉が語られた背景",
                            body: sourceContext,
                            accent: Color(red: 0.83, green: 0.87, blue: 0.90)
                        )
                    }

                    if let authorFact = quote.visibleAuthorFact {
                        insightSection(
                            title: "この人はどんな人か",
                            body: authorFact,
                            accent: Color(red: 0.86, green: 0.84, blue: 0.92)
                        )
                    }

                    if isPremiumUser {
                        insightSection(
                            title: "さらに深く読む",
                            body: displayPremiumText,
                            accent: Color(red: 0.90, green: 0.84, blue: 0.72)
                        )
                    } else {
                        lockedPremiumSection
                    }
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [ivory, Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func insightSection(title: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ink)

            Text(body)
                .font(.system(size: 15))
                .foregroundStyle(mutedInk)
                .lineSpacing(7)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.5), lineWidth: 1)
        )
    }

    private func condensedPremiumText(_ text: String, sourceContext: String?) -> String {
        let normalizedSource = normalizeSentence(sourceContext)
        let sentences = splitIntoSentences(text)
            .filter { !$0.isEmpty }
            .filter { normalizeSentence($0) != normalizedSource }

        guard !sentences.isEmpty else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var selected: [String] = []
        var totalCount = 0

        for sentence in sentences {
            if selected.count >= 2 { break }
            if !selected.isEmpty && totalCount + sentence.count > 120 { break }
            selected.append(sentence)
            totalCount += sentence.count
        }

        return selected.isEmpty ? sentences[0] : selected.joined(separator: " ")
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { "。！？!?".contains($0) })
            .map { fragment in
                let trimmed = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "" : trimmed + "。"
            }
    }

    private func normalizeSentence(_ text: String?) -> String {
        guard let text else { return "" }
        return text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "、", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var lockedPremiumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("プレミアムで読める内容")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ink)

            Text("この言葉を今の自分に引き寄せて受け取れるところまで読めます。")
                .font(.system(size: 14))
                .foregroundStyle(mutedInk)
                .lineSpacing(6)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(premiumUnlockItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(rose)
                            .padding(.top, 2)

                        Text(item)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ink)
                            .lineSpacing(5)
                    }
                }
            }

            Text(displayPremiumText)
                .font(.system(size: 15))
                .foregroundStyle(mutedInk.opacity(0.45))
                .lineSpacing(7)
                .redacted(reason: .placeholder)

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onPremium()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("この言葉の解説を全文読む")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ink)
                )
                .foregroundStyle(.white)
            }

            Text("意味の続き、背景、時代文脈までまとめて読めます")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(mutedInk)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(rose.opacity(0.45), lineWidth: 1)
        )
    }
}

struct HorizontalPanGestureOverlay: UIViewRepresentable {
    var ignoredFrames: [CGRect] = []
    var onTap: () -> Void
    var onLongPress: () -> Void
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize) -> Void
    var onThresholdHaptic: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassThroughPanView()
        view.backgroundColor = .clear // Fix layout block
        view.ignoredFrames = ignoredFrames
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.cancelsTouchesInView = false; pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false; tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        longPress.cancelsTouchesInView = false; longPress.delegate = context.coordinator
        view.addGestureRecognizer(longPress)
        tap.require(toFail: longPress)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PassThroughPanView else { return }
        view.ignoredFrames = ignoredFrames
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: HorizontalPanGestureOverlay
        var hasTriggeredHaptic = false
        init(_ parent: HorizontalPanGestureOverlay) { self.parent = parent }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) { parent.onTap() }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                parent.onLongPress()
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let t = gesture.translation(in: view)
            let translation = CGSize(width: t.x, height: t.y)
            switch gesture.state {
            case .began: hasTriggeredHaptic = false
            case .changed:
                parent.onChanged(translation)
                let threshold = view.bounds.width * 0.35
                if abs(translation.width) > threshold && !hasTriggeredHaptic {
                    hasTriggeredHaptic = true; parent.onThresholdHaptic()
                } else if abs(translation.width) < threshold { hasTriggeredHaptic = false }
            case .ended, .cancelled, .failed: parent.onEnded(translation)
            default: break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer is UITapGestureRecognizer { return true }
            if gestureRecognizer is UILongPressGestureRecognizer { return true }
            if let pan = gestureRecognizer as? UIPanGestureRecognizer {
                let v = pan.velocity(in: pan.view)
                return abs(v.x) > abs(v.y) * 1.5
            }
            return false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    }
}
