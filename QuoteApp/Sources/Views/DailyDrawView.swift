import SwiftUI

enum DailyCardArtwork: String, CaseIterable {
    case dawn
    case day
    case dusk
    case night

    var assetName: String { "card_\(rawValue)" }

    static func resolve(
        for date: Date = Date(),
        calendar: Calendar = .current,
        forceNight: Bool = false
    ) -> DailyCardArtwork {
        if forceNight { return .night }

        switch calendar.component(.hour, from: date) {
        case 5..<10: return .dawn
        case 10..<17: return .day
        case 17..<21: return .dusk
        default: return .night
        }
    }
}

/// 1日1回、ユーザー自身のタップで言葉を引く課金導線のない起動体験。
struct DailyDrawView: View {
    let quote: Quote
    let isNight: Bool
    let onSave: () -> Void
    let onClose: () -> Void
    let onDeck: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var revealProgress: Double = 0
    @State private var isRevealing = false
    @State private var isRevealed = false
    @State private var saved = false
    @State private var presentedAt = Date()
    @State private var isFloating = false
    @State private var shimmerProgress: CGFloat = -1.2
    @State private var cardLift: CGFloat = 0
    @State private var revealGlowOpacity: Double = 0

    private var cardArtwork: DailyCardArtwork {
        DailyCardArtwork.resolve(for: presentedAt, forceNight: isNight)
    }

    var body: some View {
        ZStack {
            background

            GeometryReader { proxy in
                let cardHeight = min(max(proxy.size.height * 0.70, 460), 580)
                let cardWidth = min(max(proxy.size.width - (WFM.Space.l * 2), 1), 480)

                VStack(spacing: WFM.Space.s) {
                    drawCard(width: cardWidth, height: cardHeight)

                    actions
                        .frame(width: cardWidth)

                    Spacer(minLength: 0)
                }
                .padding(.top, max(proxy.safeAreaInsets.top, WFM.Space.safeTopFallback) + WFM.Space.xs)
                .padding(.bottom, WFM.Space.s)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            presentedAt = Date()
            startAmbientMotion()
            AnalyticsService.shared.logDailyDrawPresented(timeSlot: timeSlot, source: "app_launch")
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isRevealing)
        .sensoryFeedback(.success, trigger: saved)
    }

    private func drawCard(width: CGFloat, height: CGFloat) -> some View {
        Button(action: reveal) {
            ZStack {
                cardBack(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous))
                    .opacity(revealProgress < 0.5 ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(revealProgress * 180),
                        axis: (x: 0, y: 1, z: 0)
                    )

                cardFront(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous))
                    .opacity(revealProgress >= 0.5 ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(-180 + revealProgress * 180),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .frame(width: width, height: height)
            .scaleEffect(isRevealing ? 1.018 : 1)
            .offset(y: cardLift + ((!reduceMotion && !isRevealed) ? (isFloating ? -5 : 5) : 0))
            .rotation3DEffect(
                .degrees((!reduceMotion && !isRevealed) ? (isFloating ? 0.7 : -0.7) : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.65
            )
            .shadow(
                color: .black.opacity(isRevealed ? 0.22 : 0.38),
                radius: isRevealing ? 24 : 16,
                x: 0,
                y: isRevealing ? 18 : 10
            )
        }
        .frame(width: width, height: height)
        .buttonStyle(.plain)
        .allowsHitTesting(!isRevealing && !isRevealed)
        .accessibilityLabel(isRevealed ? "今日の言葉、\(quote.quoteJa)、\(quote.displayAuthor)" : "今日の一枚を引く")
        .accessibilityHint(isRevealed ? "" : "ダブルタップするとカードをめくります")
    }

    private func cardBack(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Image(cardArtwork.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.black.opacity(0.18), .clear, .black.opacity(0.34)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: height)

            if !reduceMotion {
                LinearGradient(
                    colors: [.clear, WFM.ColorToken.nightRoseSoft.opacity(0.28), .white.opacity(0.36), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 86, height: height * 1.12)
                .blur(radius: 12)
                .rotationEffect(.degrees(-12))
                .offset(x: shimmerProgress * 360)
                .blendMode(.screen)
                .accessibilityHidden(true)
            }

            VStack(spacing: WFM.Space.l) {
                Text(isNight ? "夜の一枚" : "今日の一枚")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(WFM.ColorToken.nightTextPrimary.opacity(0.86))
                    .dynamicTypeSize(...DynamicTypeSize.large)

                if dynamicTypeSize.isAccessibilitySize {
                    Text(isNight ? "今日を、\n許して閉じる。" : "今日の私に、\n一枚。")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .foregroundStyle(WFM.ColorToken.nightTextPrimary)
                        .dynamicTypeSize(...DynamicTypeSize.large)
                } else {
                    VerticalTextView(
                        text: isNight ? "今日を、\n許して閉じる。" : "今日の私に、\n一枚。",
                        fontName: "HiraMinProN-W6",
                        fontSize: 29,
                        lineSpacing: WFM.Space.l,
                        textColor: WFM.ColorToken.nightTextPrimary,
                        scalesWithDynamicType: false
                    )
                    .shadow(color: .black.opacity(0.56), radius: 10, x: 0, y: 2)
                }
            }
            .padding(.bottom, WFM.Space.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            VStack(spacing: WFM.Space.xs) {
                Image(systemName: "hand.tap")
                    .font(.body.weight(.light))
                    .foregroundStyle(WFM.ColorToken.nightTextPrimary.opacity(0.82))

                Text("タップして引く")
                    .font(.caption.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(WFM.ColorToken.nightTextPrimary.opacity(0.76))
                    .dynamicTypeSize(...DynamicTypeSize.large)
            }
            .padding(.bottom, WFM.Space.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .accessibilityHidden(true)

            RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            WFM.ColorToken.nightRoseSoft.opacity(0.58),
                            Color.white.opacity(0.16),
                            WFM.ColorToken.accentGold.opacity(0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous)
                .stroke(WFM.ColorToken.nightRoseSoft.opacity(revealGlowOpacity * 0.8), lineWidth: 3)
                .blur(radius: 8)
                .accessibilityHidden(true)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous))
    }

    private func cardFront(width: CGFloat, height: CGFloat) -> some View {
        let layout = verticalLayout(for: CGSize(width: width, height: height))

        return ZStack {
                Image(quote.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .accessibilityHidden(true)

                LinearGradient(
                    colors: [.black.opacity(0.46), .black.opacity(0.72), .black.opacity(0.54)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .frame(width: width, height: height)

                Text(quote.category.displayTitleJa)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(WFM.ColorToken.nightRoseSoft.opacity(0.9))
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.top, WFM.Space.l)
                    .padding(.trailing, WFM.Space.l)
                    .frame(width: width, height: height, alignment: .topTrailing)

                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: WFM.Space.l) {
                        Text(quote.quoteJa)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .lineSpacing(8)
                            .foregroundStyle(WFM.ColorToken.nightTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if quote.hasVisibleAuthorAttribution {
                            Text("—  \(quote.displayAuthor)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(WFM.ColorToken.nightTextSub)
                        }
                    }
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .padding(.horizontal, WFM.Space.xl)
                    .frame(width: width, height: height, alignment: .center)
                } else {
                    VerticalTextView(
                        text: layout.text,
                        fontName: "HiraMinProN-W6",
                        fontSize: layout.fontSize,
                        lineSpacing: 17,
                        textColor: WFM.ColorToken.nightTextPrimary,
                        scalesWithDynamicType: false
                    )
                    .shadow(color: .black.opacity(0.46), radius: 8, x: 0, y: 2)
                    .frame(width: width, height: height, alignment: .center)
                }

                if quote.hasVisibleAuthorAttribution && !dynamicTypeSize.isAccessibilitySize {
                    HStack(alignment: .bottom, spacing: WFM.Space.s) {
                        Rectangle()
                            .fill(WFM.ColorToken.nightRoseSoft.opacity(0.72))
                            .frame(width: 1, height: 38)

                        VerticalTextView(
                            text: quote.displayAuthor,
                            fontName: "HiraginoSans-W6",
                            fontSize: 13,
                            lineSpacing: 0,
                            textColor: WFM.ColorToken.nightTextSub,
                            scalesWithDynamicType: false
                        )
                    }
                    .padding(.leading, WFM.Space.l)
                    .padding(.bottom, WFM.Space.l)
                    .frame(width: width, height: height, alignment: .bottomLeading)
                }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if isRevealed {
            VStack(spacing: WFM.Space.xs) {
                Button {
                    onSave()
                    saved = true
                    AnalyticsService.shared.logDailyDrawSaved(quoteID: quote.id, timeSlot: timeSlot)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDeck() }
                } label: {
                    Label(saved ? "棚に置きました" : "棚に置く", systemImage: saved ? "bookmark.fill" : "bookmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .dynamicTypeSize(...DynamicTypeSize.large)
                .tint(WFM.ColorToken.nightRose)
                .disabled(saved)

                HStack(spacing: WFM.Space.l) {
                    Button("今日はこれだけ") {
                        AnalyticsService.shared.logDailyDrawToDeck(quoteID: quote.id, entryAction: "close")
                        onClose()
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(WFM.ColorToken.nightTextSub)
                    .frame(minHeight: 44)

                    Button("もう少し読む") {
                        AnalyticsService.shared.logDailyDrawToDeck(quoteID: quote.id, entryAction: "deck")
                        onDeck()
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WFM.ColorToken.nightRoseSoft)
                    .frame(minHeight: 44)
                }
                .dynamicTypeSize(...DynamicTypeSize.large)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            Button("今日は引かない") {
                AnalyticsService.shared.logDailyDrawSkipped(timeSlot: timeSlot, source: "app_launch")
                onSkip()
            }
            .font(.subheadline)
            .foregroundStyle(WFM.ColorToken.nightTextSub)
            .frame(minHeight: 44)
            .dynamicTypeSize(...DynamicTypeSize.large)
        }
    }

    private var background: some View {
        GeometryReader { proxy in
            ZStack {
                Image(cardArtwork.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .blur(radius: 30)
                    .scaleEffect(1.16)
                    .opacity(1 - revealProgress)
                    .accessibilityHidden(true)

                Image(quote.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .blur(radius: 24)
                    .scaleEffect(1.12)
                    .opacity(revealProgress)
                    .accessibilityHidden(true)

                WFM.ColorToken.nightScrim.opacity(0.82)
                WFM.ColorToken.nightBase.opacity(isNight ? 0.54 : 0.36)

                RadialGradient(
                    colors: [
                        WFM.ColorToken.nightRoseSoft.opacity(0.12 + revealGlowOpacity * 0.20),
                        .clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 360
                )
                .blendMode(.screen)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.7), value: revealProgress)
    }

    private var timeSlot: String { isNight ? "night" : "day" }

    private func verticalLayout(for size: CGSize) -> (text: String, fontSize: CGFloat) {
        let baseFontSize: CGFloat = dynamicTypeSize.isAccessibilitySize ? 24 : 29
        let availableHeight = size.height * 0.64
        let normalizedText = quote.quoteJa.replacingOccurrences(of: "\n", with: "")
        let totalCount = normalizedText.count
        let heightLimit = max(9, Int(availableHeight / (baseFontSize * 1.12)))
        let columns = min(5, max(3, Int((size.width - 72) / (baseFontSize + 17))))
        let widthLimit = Int(ceil(Double(max(totalCount, 1)) / Double(columns)))
        let folded = JapaneseLineBreaker.fold(normalizedText, maxPerLine: max(heightLimit, widthLimit))
        let longest = folded.components(separatedBy: "\n").map(\.count).max() ?? 1
        let fitted = availableHeight / CGFloat(longest) / 1.12
        return (folded, min(baseFontSize, max(21, fitted)))
    }

    private func reveal() {
        guard !isRevealing, !isRevealed else { return }
        isRevealing = true
        let duration = reduceMotion ? WFM.Motion.reducedRevealDuration : WFM.Motion.revealDuration

        let liftDelay = reduceMotion ? 0 : WFM.Motion.cardLiftDuration
        if !reduceMotion {
            withAnimation(.easeOut(duration: WFM.Motion.cardLiftDuration)) {
                cardLift = -18
                revealGlowOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + liftDelay) {
            withAnimation(.timingCurve(0.32, 0.02, 0.18, 1, duration: duration)) {
                revealProgress = 1
                cardLift = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + liftDelay + duration) {
            isRevealing = false
            withAnimation(WFM.Motion.quick) {
                isRevealed = true
                revealGlowOpacity = 0
            }
            AnalyticsService.shared.logDailyDrawRevealed(
                timeSlot: timeSlot,
                quoteID: quote.id,
                revealMilliseconds: Int((liftDelay + duration) * 1_000)
            )
        }
    }

    private func startAmbientMotion() {
        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: WFM.Motion.cardFloatDuration)
                .repeatForever(autoreverses: true)
        ) {
            isFloating = true
        }

        withAnimation(
            .linear(duration: WFM.Motion.cardShimmerDuration)
                .repeatForever(autoreverses: false)
        ) {
            shimmerProgress = 1.2
        }
    }
}
