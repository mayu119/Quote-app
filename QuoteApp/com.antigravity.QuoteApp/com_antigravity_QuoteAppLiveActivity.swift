import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct com_antigravity_QuoteAppLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuoteLiveActivityAttributes.self) { context in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "FBF6F1"), Color(hex: "F0E5DB")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text(context.state.categoryJa)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "8E94B8"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.78))
                        .clipShape(Capsule())

                    Text(context.state.punchline)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "2F2730"))
                        .lineSpacing(4)

                    HStack(spacing: 8) {
                        Capsule()
                            .fill(Color(hex: "D7AE68"))
                            .frame(width: 18, height: 3)
                        Text(context.state.author)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "776B78"))
                    }
                }
                .padding(18)
            }
            .activityBackgroundTint(Color(hex: "FBF6F1"))
            .activitySystemActionForegroundColor(Color(hex: "2F2730"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.categoryJa)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "8E94B8"))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Circle()
                        .fill(Color(hex: "E59B9D"))
                        .frame(width: 24, height: 24)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.punchline)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                        Text(context.state.author)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Circle()
                    .fill(Color(hex: "E59B9D"))
                    .frame(width: 18, height: 18)
            } compactTrailing: {
                Text("言葉")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .keylineTint(Color(hex: "E59B9D"))
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
