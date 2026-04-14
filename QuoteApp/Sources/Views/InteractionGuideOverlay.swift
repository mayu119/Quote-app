import SwiftUI

struct InteractionGuideOverlay: View {
    enum Stage: Int, CaseIterable {
        case verticalSwipe
        case saveSwipe
        case shareSwipe
        case longPress
        case toolbar

        var title: String {
            switch self {
            case .verticalSwipe: return "上下にめくる"
            case .saveSwipe: return "左にスワイプで保存"
            case .shareSwipe: return "右にスワイプして、タップで閉じる"
            case .longPress: return "長押しで深く読む"
            case .toolbar: return "下のボタンで広げる"
            }
        }

        var subtitle: String {
            switch self {
            case .verticalSwipe: return "まずは次の言葉へ進んでみてください。"
            case .saveSwipe: return "お気に入り保存を実際の画面で試します。"
            case .shareSwipe: return "シェア画面を開いたら、一度タップして戻ってください。"
            case .longPress: return "背景や解説を開く操作です。"
            case .toolbar: return "実際のボタンをタップして開きます。"
            }
        }

        var prompt: String {
            switch self {
            case .verticalSwipe: return "カードを上下に動かしてください"
            case .saveSwipe: return "左へスワイプしてください"
            case .shareSwipe: return "右へスワイプして、表示後にタップしてください"
            case .longPress: return "そのまま長押ししてください"
            case .toolbar: return "下のボタンをタップしてください"
            }
        }

        var accent: Color {
            switch self {
            case .verticalSwipe: return Color(red: 0.86, green: 0.55, blue: 0.60)
            case .saveSwipe: return Color(red: 0.58, green: 0.56, blue: 0.68)
            case .shareSwipe: return Color(red: 0.56, green: 0.73, blue: 0.82)
            case .longPress: return Color(red: 0.63, green: 0.72, blue: 0.56)
            case .toolbar: return Color(red: 0.55, green: 0.50, blue: 0.62)
            }
        }
    }

    let stage: Stage
    let completedCount: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.02), Color.black.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    topCard
                        .padding(.horizontal, 20)
                        .padding(.top, proxy.safeAreaInsets.top > 0 ? 12 : 20)

                    Spacer()

                    if stage == .toolbar {
                        bottomCue
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 18) + 14)
                    } else {
                        bottomCue
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 18) + 14)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var topCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("実画面チュートリアル")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2.4)
                        .foregroundColor(stage.accent)

                    Text(stage.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.20, green: 0.16, blue: 0.20))
                }

                Spacer()

                Text("\(completedCount)/\(Stage.allCases.count)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Color(red: 0.46, green: 0.40, blue: 0.46))
            }

            Text(stage.subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.46, green: 0.40, blue: 0.46))
                .lineSpacing(4)

            Capsule()
                .fill(stage.accent.opacity(0.15))
                .frame(height: 10)
                .overlay(
                    Capsule()
                        .fill(stage.accent)
                        .frame(width: barWidth, height: 10),
                    alignment: .leading
                )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
    }

    private var bottomCue: some View {
        VStack(spacing: 12) {
            Text(stage.prompt)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(red: 0.20, green: 0.16, blue: 0.20))
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ForEach(Stage.allCases, id: \.self) { candidate in
                    Capsule()
                        .fill(candidate == stage ? stage.accent : Color.white.opacity(0.36))
                        .frame(width: candidate == stage ? 28 : 8, height: 8)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private var barWidth: CGFloat {
        let count = max(1, Stage.allCases.count)
        let progress = CGFloat(completedCount) / CGFloat(count)
        return max(18, min(180, 180 * progress))
    }
}

#Preview {
    InteractionGuideOverlay(stage: .verticalSwipe, completedCount: 1)
}
