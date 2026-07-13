import SwiftUI

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

    var body: some View {
        ZStack {
            background

            GeometryReader { proxy in
                VStack(spacing: WFM.Space.s) {
                    drawCard
                        .frame(maxWidth: 520)
                        .frame(maxHeight: .infinity)

                    actions
                        .frame(maxWidth: 520)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, max(proxy.safeAreaInsets.top, WFM.Space.safeTopFallback) + WFM.Space.xs)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, WFM.Space.s))
                .padding(.horizontal, WFM.Space.m)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            AnalyticsService.shared.logDailyDrawPresented(timeSlot: timeSlot, source: "app_launch")
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isRevealing)
        .sensoryFeedback(.success, trigger: saved)
    }

    private var drawCard: some View {
        Button(action: reveal) {
            ZStack {
                cardBack
                    .opacity(revealProgress < 0.5 ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(revealProgress * 180),
                        axis: (x: 0, y: 1, z: 0)
                    )

                cardFront
                    .opacity(revealProgress >= 0.5 ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(-180 + revealProgress * 180),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isRevealing || isRevealed)
        .accessibilityLabel(isRevealed ? "今日の言葉、\(quote.quoteJa)、\(quote.displayAuthor)" : "今日の一枚を引く")
        .accessibilityHint(isRevealed ? "" : "ダブルタップするとカードをめくります")
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [WFM.ColorToken.nightHigh, WFM.ColorToken.nightRaised, WFM.ColorToken.nightBase],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous)
                        .stroke(WFM.ColorToken.nightRoseSoft.opacity(0.28), lineWidth: 1)
                }

            Circle()
                .fill(WFM.ColorToken.nightRose.opacity(0.055))
                .frame(width: 270, height: 270)
                .overlay {
                    Circle()
                        .stroke(WFM.ColorToken.nightRoseSoft.opacity(0.12), lineWidth: 1)
                }
                .accessibilityHidden(true)

            HStack(alignment: .top, spacing: WFM.Space.xl) {
                VerticalTextView(
                    text: isNight ? "夜の一枚" : "今日の一枚",
                    fontName: "HiraginoSans-W6",
                    fontSize: 13,
                    lineSpacing: 0,
                    textColor: WFM.ColorToken.nightTextSub
                )
                .padding(.top, 12)

                VerticalTextView(
                    text: isNight ? "今日を、許して閉じる。" : "今日のあなたに、一枚。",
                    fontName: "HiraMinProN-W6",
                    fontSize: 28,
                    lineSpacing: 0,
                    textColor: WFM.ColorToken.nightTextPrimary
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            VStack(spacing: WFM.Space.xs) {
                Image(systemName: "sparkle")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(WFM.ColorToken.nightRoseSoft.opacity(0.86))

                Text("触れて引く")
                    .font(.caption.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(WFM.ColorToken.nightTextSub)
            }
            .padding(.bottom, WFM.Space.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .accessibilityHidden(true)
        }
        .contentShape(RoundedRectangle(cornerRadius: WFM.Radius.xl, style: .continuous))
    }

    private var cardFront: some View {
        GeometryReader { proxy in
            let layout = verticalLayout(for: proxy.size)

            ZStack {
                Image(quote.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .accessibilityHidden(true)

                LinearGradient(
                    colors: [.black.opacity(0.46), .black.opacity(0.72), .black.opacity(0.54)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                Text(quote.category.displayTitleJa)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(WFM.ColorToken.nightRoseSoft.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.top, WFM.Space.l)
                    .padding(.trailing, WFM.Space.l)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                VerticalTextView(
                    text: layout.text,
                    fontName: "HiraMinProN-W6",
                    fontSize: layout.fontSize,
                    lineSpacing: 17,
                    textColor: WFM.ColorToken.nightTextPrimary
                )
                .shadow(color: .black.opacity(0.46), radius: 8, x: 0, y: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                if quote.hasVisibleAuthorAttribution {
                    HStack(alignment: .bottom, spacing: WFM.Space.s) {
                        Rectangle()
                            .fill(WFM.ColorToken.nightRoseSoft.opacity(0.72))
                            .frame(width: 1, height: 38)

                        VerticalTextView(
                            text: quote.displayAuthor,
                            fontName: "HiraginoSans-W6",
                            fontSize: 13,
                            lineSpacing: 0,
                            textColor: WFM.ColorToken.nightTextSub
                        )
                    }
                    .padding(.leading, WFM.Space.l)
                    .padding(.bottom, WFM.Space.l)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
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
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
        }
    }

    private var background: some View {
        ZStack {
            Image(quote.backgroundImage)
                .resizable()
                .scaledToFill()
                .blur(radius: 24)
                .scaleEffect(1.12)
                .accessibilityHidden(true)

            WFM.ColorToken.nightScrim
            WFM.ColorToken.nightBase.opacity(0.62)
        }
        .ignoresSafeArea()
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
        withAnimation(.easeInOut(duration: duration)) {
            revealProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isRevealing = false
            withAnimation(WFM.Motion.quick) { isRevealed = true }
            AnalyticsService.shared.logDailyDrawRevealed(
                timeSlot: timeSlot,
                quoteID: quote.id,
                revealMilliseconds: Int(duration * 1_000)
            )
        }
    }
}
