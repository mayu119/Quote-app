import SwiftUI
import SwiftData
import UIKit

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
    var onCategorySelect: () -> Void
    var onWallpaperSelect: () -> Void

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

    enum SwipeAction { case save, archive }

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
                            Text(dismissAction == .save ? "SAVED" : "ARCHIVED")
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                                .tracking(4)
                                .foregroundColor(.white.opacity(0.6))
                            Text("スワイプして次へ")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 10)
                        }
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
                    height: (isShareMode && shareFormat == .square) ? proxy.size.width : proxy.size.height
                )
                .clipShape(RoundedRectangle(cornerRadius: isShareMode ? 40 : 0, style: .continuous))
                .scaleEffect(isShareMode ? 0.70 : 1.0)
                .offset(
                    x: isShareMode ? 0 : swipeOffset.width,
                    y: isShareMode ? ((shareFormat == .square) ? 0 : -40) : swipeOffset.height * 0.2
                )
                .rotationEffect(.degrees(isShareMode ? 0 : Double(swipeOffset.width / 15)))
                .shadow(color: .black.opacity(isShareMode ? 0.6 : 0), radius: 30, x: 0, y: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: isShareMode ? 40 : 0, style: .continuous)
                        .stroke(Color.white.opacity(isShareMode ? 0.2 : 0), lineWidth: 1)
                )
                
                // 3. Gesture View (Top level to always capture full screen)
                HorizontalPanGestureOverlay(
                    onTap: {
                        if isShareMode {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShareMode = false
                            }
                            return
                        }
                        guard !isDismissed else { return }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showControls.toggle()
                        }
                    },
                    onChanged: { translation in
                        guard !isDismissed && !isShareMode else { return }
                        swipeOffset = translation
                    },
                    onEnded: { translation in
                        guard !isDismissed && !isShareMode else { return }
                        let threshold = proxy.size.width * 0.35

                        // Swipe Right → Share Feature (Replaces Archive)
                        if translation.width > threshold {
                            triggerHeavyHaptic()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShareMode = true
                                showControls = false
                                swipeOffset = .zero
                            }
                        }
                        // Swipe Left → 保存 (Save)
                        else if translation.width < -threshold {
                            triggerHeavyHaptic()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                isLiked = true
                                quote.isFavorited = true
                                try? modelContext.save()
                                swipeOffset = .zero
                            }
                            userSettings.recordSave(category: quote.category)
                            // パーティクルエフェクト
                            particleScale = 0.2; particleOpacity = 1.0
                            withAnimation(.easeOut(duration: 0.7)) {
                                particleScale = 2.5; particleOpacity = 0.0
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
        .ignoresSafeArea(.all)
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
    }

    // MARK: - Entrance Animations

    private func startEntranceAnimations() {
        withAnimation(.easeOut(duration: 1.5)) { isVisible = true }
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) { quoteBlurRadius = 0 }
        let characters = Array(quote.author.uppercased())
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
            VStack(spacing: 8) {
                Text(currentDateString())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(8).foregroundColor(.white.opacity(0.8))
                    .shadow(color: .white.opacity(0.6), radius: 15)
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: showControls ? 60 : 0, height: 1)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: showControls)
                Text(quote.category.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black)).tracking(4)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.top, proxy.safeAreaInsets.top > 0 ? proxy.safeAreaInsets.top + 60 : 100)
            .opacity(showControls ? 1 : 0)
            .offset(y: showControls ? 0 : -20)
            .blur(radius: showControls ? 0 : 5)
        }
    }

    @ViewBuilder
    private func contentLayer(proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 40) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 64, weight: .black))
                    .foregroundColor(.white.opacity(0.1))
                    .offset(x: -12, y: 20)
                Text(quote.quoteJa)
                    .font(.custom("HiraginoSans-W8", size: 40)).fontWeight(.black)
                    .foregroundColor(.white.opacity(0.95)).lineSpacing(14)
                    .minimumScaleFactor(0.4)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
                    .blur(radius: quoteBlurRadius)
                    .scaleEffect(isVisible ? 1.0 : 0.98)
                    .offset(x: isVisible ? 0 : -10)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 20) {
                    Rectangle().fill(Color.white.opacity(0.8)).frame(width: 40, height: 1)
                        .scaleEffect(x: isVisible ? 1 : 0, anchor: .leading)
                        .animation(.spring().delay(0.6), value: isVisible)
                    Text(authorText)
                        .font(.system(size: 13, weight: .bold)).tracking(6)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: proxy.size.width - 45, alignment: .leading)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .blur(radius: isVisible ? 0 : 10)

            Spacer()

            // Toolbar
            ZStack(alignment: .bottom) {
                if showSwipeHint && !showControls {
                    VStack(spacing: 6) {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                            .offset(y: hintBounce ? -5 : 5)
                        Text("SWIPE UP")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(3).foregroundColor(.white.opacity(0.5))
                    }
                    .transition(.opacity)
                }

                ZStack {
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
                        .frame(width: showControls ? proxy.size.width - 64 : 16,
                               height: showControls ? 60 : 16)
                        .opacity(showControls ? 1 : 0)

                    HStack(spacing: 0) {
                        // Bookmark button with particles
                        ZStack {
                            if particleOpacity > 0 {
                                ForEach(0..<12, id: \.self) { i in
                                    let angle = Double(i) * (360.0 / 12.0)
                                    Capsule().fill(Color.white).frame(width: 2, height: 6)
                                        .offset(y: -20 * particleScale)
                                        .rotationEffect(.degrees(angle))
                                        .opacity(particleOpacity)
                                }
                            }
                            Button(action: {
                                triggerHeavyHaptic()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                                    isLiked.toggle()
                                    quote.isFavorited = isLiked
                                    try? modelContext.save()
                                }
                                if isLiked {
                                    particleScale = 0.2; particleOpacity = 1.0
                                    withAnimation(.easeOut(duration: 0.6)) {
                                        particleScale = 1.8; particleOpacity = 0.0
                                    }
                                }
                            }) {
                                Image(systemName: isLiked ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(isLiked ? .white : .white.opacity(0.85))
                                    .scaleEffect(isLiked ? 1.3 : 1.0)
                                    .rotationEffect(.degrees(isLiked ? -5 : 0))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        divider
                        toolbarButton(icon: "square.grid.2x2") { triggerHaptic(); onCategorySelect() }
                        divider
                        toolbarButton(icon: "text.book.closed") { triggerHaptic(); onFavorites() }
                        divider
                        toolbarButton(icon: "photo.stack") { triggerHaptic(); onWallpaperSelect() }
                        divider
                        toolbarButton(icon: "gearshape") { triggerHaptic(); onSettings() }
                    }
                    .frame(width: proxy.size.width - 64, height: 60)
                    .padding(.horizontal, 10)
                    .opacity(showControls ? 1 : 0)
                    .scaleEffect(showControls ? 1.0 : 0.6)
                    .blur(radius: showControls ? 0 : 5)
                }
                .offset(y: showControls ? 0 : 30)
            }
            .frame(height: 60)
            .padding(.bottom, proxy.safeAreaInsets.bottom > 0 ? proxy.safeAreaInsets.bottom + 45 : 65)
        }
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

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 24)
    }

    private func toolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
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
                            .fill(RadialGradient(colors: [.orange.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 120))
                            .frame(width: 250 * heartbeat, height: 250 * heartbeat)
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 36 * heartbeat, weight: .ultraLight))
                                .foregroundColor(.orange.opacity(0.9))
                                .shadow(color: .orange.opacity(0.8), radius: 15 * rawProgress)
                            Text("SAVE")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .tracking(4).foregroundColor(.orange.opacity(0.8))
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
                
                Picker("Format", selection: $shareFormat) {
                    Text("STORIES").tag(ShareImageFormat.stories)
                    Text("SQUARE").tag(ShareImageFormat.square)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                .colorScheme(.dark)
                
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
                            format: shareFormat
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
                format: shareFormat
            )
            NativeShareSheet(activityItems: items)
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    private func triggerHeavyHaptic() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    private func triggerDeepHaptic() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0) }

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

// MARK: - HorizontalPanGestureOverlay

class PassThroughPanView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // If the view returned is self (meaning it didn't hit a subview)
        if view == self {
            // Ignore touches in the bottom 150 points where the toolbar lives
            if point.y > self.bounds.height - 150 {
                return nil
            }
        }
        return view
    }
}

struct HorizontalPanGestureOverlay: UIViewRepresentable {
    var onTap: () -> Void
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize) -> Void
    var onThresholdHaptic: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassThroughPanView()
        view.backgroundColor = .clear // Fix layout block
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.cancelsTouchesInView = false; pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false; tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: HorizontalPanGestureOverlay
        var hasTriggeredHaptic = false
        init(_ parent: HorizontalPanGestureOverlay) { self.parent = parent }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) { parent.onTap() }

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
            if let pan = gestureRecognizer as? UIPanGestureRecognizer {
                let v = pan.velocity(in: pan.view)
                return abs(v.x) > abs(v.y) * 1.5
            }
            return false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    }
}
