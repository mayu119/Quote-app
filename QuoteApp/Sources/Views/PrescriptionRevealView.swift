import SwiftUI

struct PrescriptionRevealView: View {
    let focusTitle: String
    let tags: [String]
    let tone: PrescriptionTone
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "211B2A"), Color(hex: "332A3C"), Color(hex: "18151F")],
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
                            .foregroundStyle(Color(hex: "EEC7BE"))

                        VStack(alignment: .leading, spacing: WFM.Space.m) {
                            Text(tone.summary(for: focusTitle))
                                .font(.system(size: 17, weight: .regular, design: .serif))
                                .foregroundStyle(.white.opacity(0.94))
                                .lineSpacing(7)

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

                        Text("この処方箋を、7日間ぜんぶ受け取れます")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.82))

                        Button(action: onContinue) {
                            Text("処方箋を受け取る")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "D99AA3"))
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
}

enum PrescriptionTone {
    case gentle, direct, deep

    func summary(for focus: String) -> String {
        switch self {
        case .gentle:
            return "がんばり方は知っているのに、休み方を自分に許していない。\nあなたに必要なのは、背中を押す言葉より、肩の力を抜く言葉です。"
        case .direct:
            return "「(focus)」を選んだあなたには、迷いを消すより、次の一歩を具体的にする言葉を選びました。"
        case .deep:
            return "答えを急がず、いまの気持ちを置いておける余白を。\n「(focus)」を選んだあなたへ、静かに残る言葉を届けます。"
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
