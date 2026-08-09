import SwiftUI

struct PrescriptionRevealView: View {
    let focusTitle: String
    let tags: [String]
    let tone: PrescriptionTone
    var quote: Quote? = nil
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var phase = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WFM.ColorToken.nightRaised, WFM.ColorToken.nightHigh, WFM.ColorToken.nightBase],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: WFM.Space.l) {
                Spacer()

                if phase == 0 {
                    VStack(spacing: WFM.Space.m) {
                        Text("あなたの答えから、\n言葉を選んでいます")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        FlowTags(tags: tags)
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: WFM.Space.l) {
                        Text("あなたの処方箋")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(WFM.ColorToken.nightRoseSoft)

                        VStack(alignment: .leading, spacing: WFM.Space.m) {
                            Text(tone.summary(for: focusTitle))
                                .font(.system(size: 17, weight: .regular, design: .serif))
                                .foregroundStyle(.white.opacity(0.94))
                                .lineSpacing(7)

                            if let quote {
                                prescriptionCard(quote)
                            } else {
                                VStack(alignment: .leading, spacing: WFM.Space.m) {
                                    Divider().overlay(.white.opacity(0.18))

                                    Text(tone.quote)
                                        .font(.system(size: 22, weight: .medium, design: .serif))
                                        .foregroundStyle(.white)
                                        .lineSpacing(7)

                                    Text("Words For Me — 最初の一枚")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.58))
                                }
                                .padding(WFM.Space.l)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: WFM.Radius.l, style: .continuous))
                            }
                        }

                        Text("この処方箋を、7日間ぜんぶ受け取れます")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.82))

                        Button(action: onContinue) {
                            Text("処方箋を受け取る")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(WFM.ColorToken.nightInk)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WFM.ColorToken.nightRose)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Button("今はここまでにする", action: onSkip)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(minHeight: 44)
                    .padding(.top, WFM.Space.s)

                Spacer(minLength: WFM.Space.s)
            }
            .padding(.horizontal, WFM.Space.l)
        }
        .onAppear {
            AnalyticsService.shared.logPrescriptionView()
            let delay = reduceMotion ? 0.2 : 1.7
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(reduceMotion ? nil : WFM.Motion.smooth) { phase = 1 }
            }
        }
    }

    private func prescriptionCard(_ quote: Quote) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
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
                    .padding(.top, WFM.Space.m)
                    .padding(.trailing, WFM.Space.m)
                    .frame(width: width, height: height, alignment: .topTrailing)

                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: WFM.Space.m) {
                        Text(quote.quoteJa)
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .lineSpacing(6)
                            .foregroundStyle(WFM.ColorToken.nightTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if quote.hasVisibleAuthorAttribution {
                            Text("—  \(quote.displayAuthor)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(WFM.ColorToken.nightTextSub)
                        }
                    }
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .padding(.horizontal, WFM.Space.l)
                    .frame(width: width, height: height, alignment: .center)
                } else {
                    let layout = verticalLayout(for: CGSize(width: width, height: height), quote: quote)
                    VerticalTextView(
                        text: layout.text,
                        fontName: "HiraMinProN-W6",
                        fontSize: layout.fontSize,
                        lineSpacing: 15,
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
                            .frame(width: 1, height: 32)

                        VerticalTextView(
                            text: quote.displayAuthor,
                            fontName: "HiraginoSans-W6",
                            fontSize: 12,
                            lineSpacing: 0,
                            textColor: WFM.ColorToken.nightTextSub,
                            scalesWithDynamicType: false
                        )
                    }
                    .padding(.leading, WFM.Space.m)
                    .padding(.bottom, WFM.Space.m)
                    .frame(width: width, height: height, alignment: .bottomLeading)
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: WFM.Radius.l, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: WFM.Radius.l, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.32), radius: 20, x: 0, y: 12)
        }
        .frame(height: 320)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quote.quoteJa)、\(quote.displayAuthor)")
    }

    private func verticalLayout(for size: CGSize, quote: Quote) -> (text: String, fontSize: CGFloat) {
        let baseFontSize: CGFloat = dynamicTypeSize.isAccessibilitySize ? 22 : 26
        let availableHeight = size.height * 0.62
        let normalizedText = quote.quoteJa.replacingOccurrences(of: "\n", with: "")
        let totalCount = normalizedText.count
        let heightLimit = max(9, Int(availableHeight / (baseFontSize * 1.12)))
        let columns = min(5, max(3, Int((size.width - 60) / (baseFontSize + 15))))
        let widthLimit = Int(ceil(Double(max(totalCount, 1)) / Double(columns)))
        let folded = JapaneseLineBreaker.fold(normalizedText, maxPerLine: max(heightLimit, widthLimit))
        let longest = folded.components(separatedBy: "\n").map(\.count).max() ?? 1
        let fitted = availableHeight / CGFloat(longest) / 1.12
        return (folded, min(baseFontSize, max(19, fitted)))
    }
}

enum PrescriptionTone {
    case gentle, direct, deep

    func summary(for focus: String) -> String {
        switch self {
        case .gentle:
            return "がんばり方は知っているのに、休み方を自分に許していない。\nあなたに必要なのは、背中を押す言葉より、肩の力を抜く言葉です。"
        case .direct:
            return "「\(focus)」を選んだあなたには、迷いを消すより、次の一歩を具体的にする言葉を選びました。"
        case .deep:
            return "答えを急がず、いまの気持ちを置いておける余白を。\n「\(focus)」を選んだあなたへ、静かに残る言葉を届けます。"
        }
    }

    var quote: String {
        switch self {
        case .gentle: return "今日をここまで運んだだけで、じゅうぶんです。"
        case .direct: return "小さくても、自分で選んだ一歩は、明日の足場になる。"
        case .deep: return "まだ言葉にならない気持ちも、ここに置いていい。"
        }
    }
}

private struct FlowTags: View {
    let tags: [String]
    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: WFM.Space.xs) { tagsView }
            VStack(spacing: WFM.Space.xs) { tagsView }
        }
    }
    @ViewBuilder private var tagsView: some View {
        ForEach(tags.prefix(4), id: \.self) {
            Text($0).font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.84))
                .padding(.horizontal, WFM.Space.s).padding(.vertical, WFM.Space.xs)
                .background(.white.opacity(0.12), in: Capsule())
        }
    }
}
